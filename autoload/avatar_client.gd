extends Node
## Autoload AvatarClient: cầu nối duy nhất giữa game và AvatarServer.
##
## HTTP dùng cho đăng ký/đăng nhập, WebSocket dùng cho đồng bộ tiến trình.
## Lưu ý protocol: chiều client → server BẮT BUỘC bọc {"event": ..., "data": {...}}
## (đó là cách NestJS WsAdapter route message — gửi sai key thì server bỏ qua im lặng),
## còn chiều server → client trả thẳng object có field "type".

signal login_succeeded(user: Dictionary)
signal login_failed(message: String)
signal register_succeeded(user: Dictionary)
signal register_failed(message: String)
signal state_loaded          ## đồng bộ với server xong (đẩy lên hoặc lấy về)
signal connection_changed(online: bool)
signal session_expired       ## token đã lưu không còn dùng được, cần đăng nhập lại
signal oauth_browser_opened(url: String)

const API_HOST := "http://localhost:3000"
const WS_HOST := "ws://localhost:3000/ws"

const AUTO_SAVE_SECONDS := 30.0
const RECONNECT_SECONDS := 5.0

## Token lưu ở đây để lần sau mở game khỏi đăng nhập lại. Đây là file thường,
## không mã hoá — ai vào được máy thì đọc được, giống mọi game offline khác.
const AUTH_PATH := "user://auth.json"

var token: String = ""
var current_user: Dictionary = {}
var is_online: bool = false

var _ws := WebSocketPeer.new()
var _authenticated := false
var _ws_was_open := false
var _want_connection := false

var _auto_save_timer: Timer
var _reconnect_timer: Timer
var _poll_timer: Timer
var _device_code := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_SECONDS
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)
	# Chạy ngay từ đầu, không đợi đăng nhập — save xuống đĩa phải hoạt động cả khi offline.
	_auto_save_timer.start()

	_reconnect_timer = Timer.new()
	_reconnect_timer.wait_time = RECONNECT_SECONDS
	_reconnect_timer.one_shot = true
	_reconnect_timer.timeout.connect(_try_reconnect)
	add_child(_reconnect_timer)

	_poll_timer = Timer.new()
	_poll_timer.wait_time = 2.0
	_poll_timer.timeout.connect(_poll_device_code)
	add_child(_poll_timer)

	# Còn token của lần chơi trước thì vào thẳng game, khỏi bắt đăng nhập lại.
	if _load_token():
		GameState.session_logged_in = true
		connect_ws()


# ============================================================
# HTTP: đăng ký / đăng nhập
# ============================================================

## Trả về {"ok": bool, "message": String}. Thành công thì token đã được lưu và WS đang kết nối.
func login(username: String, password: String) -> Dictionary:
	var res := await _http_post("/auth/login", {"username": username, "password": password})
	if res.has("accessToken"):
		_apply_login(res)
		login_succeeded.emit(current_user)
		return {"ok": true, "message": ""}
	var msg := _error_message(res)
	login_failed.emit(msg)
	return {"ok": false, "message": msg}


## Đăng ký xong là đăng nhập luôn — server trả sẵn accessToken.
func register(username: String, password: String) -> Dictionary:
	var res := await _http_post("/auth/register", {"username": username, "password": password})
	if res.has("accessToken"):
		_apply_login(res)
		register_succeeded.emit(current_user)
		return {"ok": true, "message": ""}
	var msg := _error_message(res)
	register_failed.emit(msg)
	return {"ok": false, "message": msg}


## Đăng nhập Google/Facebook bằng device code flow:
##   1. xin code từ server
##   2. mở trình duyệt để người chơi chọn Google hay Facebook và đăng nhập
##   3. poll 2 giây/lần cho tới khi server báo xong
##
## Không cần truyền provider — trang web mà server trả về đã có sẵn nút chọn.
func login_with_oauth() -> Dictionary:
	var res := await _http_post("/auth/device/start", {"mode": "login"})
	if not res.has("deviceCode"):
		var msg := _error_message(res)
		login_failed.emit(msg)
		return {"ok": false, "message": msg}

	var url := str(res.get("verificationUri", ""))
	oauth_browser_opened.emit(url)
	OS.shell_open(url)

	_device_code = str(res["deviceCode"])
	_poll_timer.start()
	return {"ok": true, "message": "Hoàn tất đăng nhập trên trình duyệt vừa mở"}


func _poll_device_code() -> void:
	if _device_code.is_empty():
		_poll_timer.stop()
		return

	var res := await _http_post("/auth/device/poll", {"deviceCode": _device_code})
	match str(res.get("status", "")):
		"pending":
			pass                       # người chơi chưa xong trên trình duyệt
		"ready":
			_poll_timer.stop()
			_device_code = ""
			_apply_login(res)
			login_succeeded.emit(current_user)
		"expired":
			_poll_timer.stop()
			_device_code = ""
			login_failed.emit("Hết hạn đăng nhập — vui lòng thử lại")
		_:
			# Lỗi mạng giữa chừng thì cứ poll tiếp, đừng bỏ cuộc ngay.
			if res.has("_netError"):
				return
			_poll_timer.stop()
			_device_code = ""
			login_failed.emit(_error_message(res))


func logout() -> void:
	_want_connection = false
	token = ""
	current_user = {}
	_authenticated = false
	_ws_was_open = false
	_reconnect_timer.stop()
	_poll_timer.stop()
	_device_code = ""
	_forget_token()
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.close()
	_set_online(false)


func is_logged_in() -> bool:
	return not token.is_empty()


## Chờ đồng bộ xong với server. Trả về false nếu quá hạn — khi đó cứ vào game,
## autoload vẫn tự kết nối lại ngầm và tiến trình vẫn được ghi xuống đĩa.
func await_ready(timeout_seconds: float = 5.0) -> bool:
	var elapsed := 0.0
	while elapsed < timeout_seconds:
		if _authenticated:
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return _authenticated


# ============================================================
# WebSocket
# ============================================================

func connect_ws() -> void:
	if token.is_empty():
		return

	# connect_to_url() trả ERR_ALREADY_IN_USE nếu socket đang mở, và client sẽ kẹt
	# ở kết nối cũ (token cũ). close() là bất đồng bộ nên thay hẳn peer cho chắc.
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.close()
		_ws = WebSocketPeer.new()

	_want_connection = true
	_ws_was_open = false
	var err := _ws.connect_to_url(WS_HOST + "?token=" + token)
	if err != OK:
		push_error("AvatarClient: WS connect that bai (ma %d)" % err)
		_reconnect_timer.start()


## Đẩy tiến trình hiện tại lên Redis (nhanh, không ghi Postgres).
func patch_state(partial: Dictionary = {}) -> void:
	if not _authenticated:
		return
	var payload := partial if not partial.is_empty() else GameState.to_dict()
	_send("patch", {"state": payload})


## Ép server flush từ Redis xuống Postgres.
func save_now() -> void:
	if not _authenticated:
		return
	_send("save")


## Điểm lưu duy nhất nên gọi từ gameplay: ghi xuống đĩa trước (luôn chạy, kể cả
## chưa đăng nhập), rồi mới đẩy lên server nếu đang online.
func save_progress() -> void:
	GameState.save_local()
	if not _authenticated:
		return
	patch_state()
	save_now()


func _send(event: String, data: Dictionary = {}) -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({"event": event, "data": data}))


func _process(_delta: float) -> void:
	_ws.poll()
	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _ws_was_open:
			_ws_was_open = true
			# Query ?token= chỉ để guard đọc được JWT; phải gửi auth thì server
			# mới nạp profile và trả về "welcome".
			_send("auth", {"token": token})
		while _ws.get_available_packet_count() > 0:
			_handle_packet(_ws.get_packet().get_string_from_utf8())

	elif state == WebSocketPeer.STATE_CLOSED and _ws_was_open:
		# Mất kết nối thì vẫn chơi tiếp bình thường, chỉ là save xuống đĩa thôi.
		_ws_was_open = false
		_authenticated = false
		_set_online(false)
		if _want_connection:
			_reconnect_timer.start()


func _handle_packet(raw: String) -> void:
	var msg = JSON.parse_string(raw)
	if not msg is Dictionary:
		return

	match str(msg.get("type", "")):
		"welcome":
			_authenticated = true
			_set_online(true)
			# Server nhét state khôi phục vào field "ttl".
			var restored = msg.get("ttl", null)
			if GameState.loaded_from_local or not GameState.is_fresh():
				# Máy này đã có tiến trình — bản local là bản gốc, đẩy lên đè server.
				save_progress()
			elif restored is Dictionary:
				# Máy trắng (cài mới / đổi máy): lấy bản server về rồi ghi xuống đĩa.
				GameState.from_dict(restored)
				GameState.save_local()
				GameState.loaded_from_local = true
			state_loaded.emit()
		"saved":
			pass
		"patched":
			pass
		"pong":
			pass
		"event_start":
			print("[AvatarClient] Event bat dau: %s" % str(msg.get("name", "")))
		"event_end":
			print("[AvatarClient] Event ket thuc: %s" % str(msg.get("code", "")))
		"error":
			var m := str(msg.get("message", ""))
			push_error("[AvatarClient] Server bao loi: %s" % m)
			# Token hết hạn hoặc bị thu hồi: bỏ token đã lưu và ngừng reconnect,
			# nếu không client sẽ quay vòng mãi với một token chết.
			if m.contains("token") or m.contains("Token"):
				logout()
				session_expired.emit()


func _try_reconnect() -> void:
	if _want_connection and not token.is_empty():
		connect_ws()


func _on_auto_save() -> void:
	save_progress()


func _set_online(v: bool) -> void:
	if is_online != v:
		is_online = v
		connection_changed.emit(v)


func _notification(what: int) -> void:
	# Cố gắng đẩy nốt lên server khi đóng game. Không đảm bảo gửi kịp — nhưng save
	# xuống đĩa thì GameState lo, nên mất mạng lúc này cũng không mất tiến trình.
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _authenticated:
		save_progress()
		_ws.poll()


# ============================================================
# Nội bộ: HTTP helper
# ============================================================

func _apply_login(res: Dictionary) -> void:
	token = str(res.get("accessToken", ""))
	current_user = res.get("user", {}) if res.get("user", null) is Dictionary else {}
	_store_token()
	connect_ws()


# ---- Ghi nhớ đăng nhập ----

func _store_token() -> void:
	var f := FileAccess.open(AUTH_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("AvatarClient: khong luu duoc token, lan sau phai dang nhap lai")
		return
	f.store_string(JSON.stringify({"token": token, "user": current_user}))
	f.close()


func _load_token() -> bool:
	if not FileAccess.file_exists(AUTH_PATH):
		return false
	var f := FileAccess.open(AUTH_PATH, FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return false
	var saved := str((parsed as Dictionary).get("token", ""))
	if saved.is_empty():
		return false

	token = saved
	var u = (parsed as Dictionary).get("user", null)
	current_user = u if u is Dictionary else {}
	return true


func _forget_token() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("auth.json"):
		dir.remove("auth.json")


# Không đặt tên là _get/_set: trùng với virtual method của Object, Godot báo lỗi parse.
func _http_post(path: String, body: Dictionary, extra_headers: Array = []) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, path, body, extra_headers)


func _http_get(path: String, extra_headers: Array = []) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, path, {}, extra_headers)


func _request(method: int, path: String, body: Dictionary, extra_headers: Array) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)

	var headers := ["Content-Type: application/json"]
	headers.append_array(extra_headers)
	var payload := JSON.stringify(body) if method != HTTPClient.METHOD_GET else ""

	var err := http.request(API_HOST + path, headers, method, payload)
	if err != OK:
		# request() lỗi thì signal request_completed không bao giờ bắn — phải thoát ngay,
		# nếu không await sẽ treo vĩnh viễn.
		http.queue_free()
		return {"_netError": err}

	var res: Array = await http.request_completed
	http.queue_free()
	return _parse_response(res)


func _parse_response(res: Array) -> Dictionary:
	var result: int = res[0]
	var code: int = res[1]
	var raw_body: PackedByteArray = res[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return {"_netError": result}

	var parsed = JSON.parse_string(raw_body.get_string_from_utf8())
	if parsed is Dictionary:
		var d: Dictionary = parsed
		if code >= 400:
			d["_httpStatus"] = code
		return d
	return {"_httpStatus": code}


func _error_message(res: Dictionary) -> String:
	if res.has("_netError"):
		return "Không kết nối được máy chủ — kiểm tra server đã chạy chưa"

	if res.has("message"):
		var m = res["message"]
		if m is String:
			return m
		if m is Array and (m as Array).size() > 0:
			return str((m as Array)[0])

	if res.has("_httpStatus"):
		return "Lỗi máy chủ (HTTP %d)" % int(res["_httpStatus"])
	return "Lỗi không xác định"
