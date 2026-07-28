extends Node
## Test tích hợp luồng đăng nhập — CẦN SERVER ĐANG CHẠY ở localhost:3000.
##
##   godot --headless --path <project> res://tests/test_login_flow.tscn
##
## Kiểm 3 thứ:
##   1. Các node path trong login.tscn / register.tscn có đúng không (lỗi hay gặp nhất)
##   2. Đăng ký + kết nối WebSocket + đồng bộ có chạy không
##   3. Khi máy đã có tiến trình thì bản local có thắng bản server không

var _passed := 0
var _failed := 0


func _ready() -> void:
	_clean()
	await _test_scene_wiring()
	await _test_register_and_sync()
	await _test_local_wins()
	await _test_token_persistence()
	await _test_oauth_device_flow()

	print("")
	print("=== KET QUA: %d dat, %d hong ===" % [_passed, _failed])
	_clean()
	get_tree().quit(1 if _failed > 0 else 0)


# ---------- 1. Node path trong scene ----------

func _test_scene_wiring() -> void:
	print("\n--- test 1: node path trong scene ---")

	var login = preload("res://login.tscn").instantiate()
	add_child(login)
	await get_tree().process_frame

	_check("login: o Username ton tai", login.username_input != null)
	_check("login: o Password ton tai", login.password_input != null)
	_check("login: nut con mat ton tai", login.eye_button != null)
	_check("login: nut Login ton tai", login.login_button != null)
	_check("login: nhan trang thai da them", login.status_label != null)
	_check("login: nut choi offline da them", login.offline_button != null)
	_check("login: nut OAuth da them", login.oauth_button != null)
	_check("login: nut offline da noi signal",
		login.offline_button != null and login.offline_button.pressed.get_connections().size() > 0)
	_check("login: password dang bi che", login.password_input.secret == true)
	login.queue_free()

	var reg = preload("res://register.tscn").instantiate()
	add_child(reg)
	await get_tree().process_frame

	_check("register: o Username ton tai", reg.username_input != null)
	_check("register: o Password ton tai", reg.password_input != null)
	_check("register: nut Register ton tai", reg.register_button != null)
	_check("register: nhan trang thai da them", reg.status_label != null)
	reg.queue_free()
	await get_tree().process_frame


# ---------- 2. Đăng ký + đồng bộ ----------

var _account := ""

func _test_register_and_sync() -> void:
	print("\n--- test 2: dang ky + ket noi WebSocket ---")

	_account = "ui_%d" % (Time.get_unix_time_from_system() as int)
	var res: Dictionary = await AvatarClient.register(_account, "secret123")
	_check("register() tra ve ok", bool(res.get("ok", false)), str(res.get("message", "")))
	if not bool(res.get("ok", false)):
		print("  (bo qua cac buoc sau vi khong dang ky duoc — server co dang chay khong?)")
		return

	_check("da co token", AvatarClient.is_logged_in())
	var ready_ok: bool = await AvatarClient.await_ready(8.0)
	_check("WebSocket auth xong", ready_ok)
	_check("trang thai online", AvatarClient.is_online)


# ---------- 3. Local thắng server ----------

func _test_local_wins() -> void:
	print("\n--- test 3: may da co tien trinh -> ban local thang ---")
	if not AvatarClient.is_logged_in():
		print("  (bo qua — chua dang nhap duoc)")
		return

	# Đẩy "tiến trình cũ" lên server rồi ngắt kết nối
	GameState.reset()
	GameState.day = 8
	GameState.add_item("trung", 4)
	AvatarClient.save_progress()
	await _wait(1.5)

	var token_giu := AvatarClient.token
	AvatarClient.logout()
	await _wait(0.5)

	# Máy này giờ có tiến trình KHÁC (mới hơn) — đây là bản phải thắng
	GameState.reset()
	GameState.day = 2
	GameState.add_item("hat_cai", 99)
	GameState.save_local()
	GameState.loaded_from_local = true

	# Đăng nhập lại vào đúng tài khoản đó
	AvatarClient.token = token_giu
	AvatarClient.connect_ws()
	var ok: bool = await AvatarClient.await_ready(8.0)
	_check("ket noi lai duoc", ok)
	await _wait(1.5)

	_check("day van la 2 (ban local), khong bi server ghi de 8",
		GameState.day == 2, "day=%d" % GameState.day)
	_check("tui do van la ban local (hat_cai=99)",
		int(GameState.inventory.get("hat_cai", 0)) == 99, str(GameState.inventory))
	_check("khong bi dinh do cu cua server (trung)",
		not GameState.inventory.has("trung"), str(GameState.inventory))


# ---------- 4. Nhớ đăng nhập ----------

func _test_token_persistence() -> void:
	print("\n--- test 4: nho dang nhap giua cac lan mo game ---")
	# Đăng ký tài khoản riêng: test 3 đã logout nên phải đi qua _apply_login() thật
	# thì mới kiểm được là đăng nhập có ghi token xuống đĩa hay không.
	_clean()
	var acc := "tok_%d" % (Time.get_unix_time_from_system() as int)
	var res: Dictionary = await AvatarClient.register(acc, "secret123")
	if not bool(res.get("ok", false)):
		print("  (bo qua — khong dang ky duoc: %s)" % str(res.get("message", "")))
		return

	_check("file auth.json da duoc tao", FileAccess.file_exists(AvatarClient.AUTH_PATH))

	# Giả lập mở lại game: quên token trong RAM rồi đọc lại từ đĩa
	var token_cu := AvatarClient.token
	AvatarClient.token = ""
	_check("doc lai duoc token tu dia", AvatarClient._load_token())
	_check("token khop voi ban da luu", AvatarClient.token == token_cu)

	AvatarClient.logout()
	_check("logout xoa file auth.json", not FileAccess.file_exists(AvatarClient.AUTH_PATH))


# ---------- 5. OAuth device flow ----------

func _test_oauth_device_flow() -> void:
	print("\n--- test 5: xin device code cho OAuth ---")
	var res := await AvatarClient._http_post("/auth/device/start", {"mode": "login"})
	_check("device/start tra ve deviceCode", res.has("deviceCode"), str(res))
	if res.has("deviceCode"):
		_check("co verificationUri de mo trinh duyet",
			str(res.get("verificationUri", "")).begins_with("http"), str(res.get("verificationUri", "")))
		var p := await AvatarClient._http_post("/auth/device/poll", {"deviceCode": res["deviceCode"]})
		_check("poll tra ve pending khi chua xong",
			str(p.get("status", "")) == "pending", str(p))


# ---------- Tiện ích ----------

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _clean() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	for n in ["save.json", "save.json.bak", "save.json.tmp", "auth.json"]:
		if dir.file_exists(n):
			dir.remove(n)


func _check(label: String, ok: bool, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  OK    %s" % label)
	else:
		_failed += 1
		print("  HONG  %s %s" % [label, ("(%s)" % extra) if extra != "" else ""])
