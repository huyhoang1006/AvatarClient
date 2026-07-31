extends Control

@onready var username_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBoxContainer/Username
@onready var password_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/Password
@onready var eye_button: TextureButton = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/EyeButton
@onready var login_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/LoginButton

var is_password_hidden := true
var _busy := false
var status_label: Label
var offline_button: Button
var oauth_button: Button
var _oauth_in_progress := false


func _ready() -> void:
	password_input.secret = true
	eye_button.texture_normal = preload("res://assets/ui/eye_closed.png")
	eye_button.pressed.connect(_on_eye_button_pressed)
	login_button.pressed.connect(_on_login_pressed)

	# Enter ở ô nào cũng bấm Login
	password_input.text_submitted.connect(func(_t): _on_login_pressed())
	username_input.text_submitted.connect(func(_t): _on_login_pressed())

	# Nhãn trạng thái (trước đây lỗi chỉ in ra console, không ai thấy)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 20)
	status_label.visible = false
	$CenterContainer/Panel/MarginContainer/VBoxContainer.add_child(status_label)

	oauth_button = Button.new()
	oauth_button.text = "Đăng nhập bằng Google / Facebook"
	oauth_button.pressed.connect(_on_oauth_pressed)
	$CenterContainer/Panel/MarginContainer/VBoxContainer.add_child(oauth_button)

	# Offline mới là lối chơi chính — đăng nhập chỉ để sao lưu và tham gia sự kiện.
	offline_button = Button.new()
	offline_button.text = "Chơi offline (không cần tài khoản)"
	offline_button.pressed.connect(_on_offline_pressed)
	$CenterContainer/Panel/MarginContainer/VBoxContainer.add_child(offline_button)

	# OAuth chạy qua trình duyệt nên kết quả về bằng signal, không await được.
	AvatarClient.login_succeeded.connect(_on_oauth_succeeded)
	AvatarClient.login_failed.connect(_on_oauth_failed)


func _on_eye_button_pressed() -> void:
	is_password_hidden = !is_password_hidden
	password_input.secret = is_password_hidden
	eye_button.texture_normal = preload("res://assets/ui/eye_closed.png") if is_password_hidden else preload("res://assets/ui/eye_open.png")


func _on_login_pressed() -> void:
	if _busy:
		return

	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()

	if username.is_empty() or password.is_empty():
		_show_status("Nhập đầy đủ tài khoản và mật khẩu", true)
		return

	_set_busy(true)
	_show_status("Đang đăng nhập...", false)

	var res: Dictionary = await AvatarClient.login(username, password)
	if not bool(res.get("ok", false)):
		_show_status(str(res.get("message", "Đăng nhập thất bại")), true)
		_set_busy(false)
		return

	_show_status("Đang tải tiến trình...", false)
	if not await AvatarClient.await_ready(5.0):
		push_warning("Login: chua dong bo duoc voi server, vao game o che do offline tam thoi")

	GameState.session_logged_in = true
	var err := get_tree().change_scene_to_file("res://scenes/intro/intro.tscn")
	if err != OK:
		_show_status("Lỗi mở intro (mã %d) — báo dev!" % err, true)
		_set_busy(false)
		push_error("change_scene intro loi: %d" % err)


func _on_oauth_pressed() -> void:
	if _busy:
		return
	_set_busy(true)
	_oauth_in_progress = true
	_show_status("Đang mở trình duyệt...", false)

	var res: Dictionary = await AvatarClient.login_with_oauth()
	if not bool(res.get("ok", false)):
		_oauth_in_progress = false
		_show_status(str(res.get("message", "Không bắt đầu được đăng nhập")), true)
		_set_busy(false)
		return
	_show_status(str(res.get("message", "")), false)


func _on_oauth_succeeded(_user: Dictionary) -> void:
	if not _oauth_in_progress:
		return                      # đăng nhập bằng mật khẩu tự xử lý luồng của nó
	_oauth_in_progress = false
	_show_status("Đăng nhập thành công!", false)
	await AvatarClient.await_ready(5.0)
	GameState.session_logged_in = true
	var err := get_tree().change_scene_to_file("res://scenes/intro/intro.tscn")
	if err != OK:
		_show_status("Lỗi mở intro (mã %d) — báo dev!" % err, true)
		_set_busy(false)


func _on_oauth_failed(message: String) -> void:
	if not _oauth_in_progress:
		return
	_oauth_in_progress = false
	_show_status(message, true)
	_set_busy(false)


func _on_offline_pressed() -> void:
	if _busy:
		return
	GameState.session_logged_in = true
	var err := get_tree().change_scene_to_file("res://scenes/intro/intro.tscn")
	if err != OK:
		_show_status("Lỗi mở intro (mã %d) — báo dev!" % err, true)
		push_error("change_scene intro loi: %d" % err)


func _set_busy(v: bool) -> void:
	_busy = v
	login_button.disabled = v
	offline_button.disabled = v
	oauth_button.disabled = v
	username_input.editable = not v
	password_input.editable = not v


func _show_status(msg: String, is_error: bool) -> void:
	status_label.text = msg
	status_label.add_theme_color_override(
		"font_color",
		Color(0.9, 0.2, 0.15) if is_error else Color(0.35, 0.6, 0.35)
	)
	status_label.visible = true
