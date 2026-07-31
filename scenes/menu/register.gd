extends Control

@onready var username_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBoxContainer/Username
@onready var password_input: LineEdit = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/Password
@onready var eye_button: TextureButton = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/EyeButton
@onready var register_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/RegisterButton

var is_password_hidden := true
var _busy := false
var status_label: Label


func _ready() -> void:
	password_input.secret = true
	eye_button.texture_normal = preload("res://assets/ui/eye_closed.png") # 👈 SỬA Ở ĐÂY
	eye_button.pressed.connect(_on_eye_button_pressed)
	register_button.pressed.connect(_on_register_pressed)

	password_input.text_submitted.connect(func(_t): _on_register_pressed())
	username_input.text_submitted.connect(func(_t): _on_register_pressed())

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 20)
	status_label.visible = false
	$CenterContainer/Panel/MarginContainer/VBoxContainer.add_child(status_label)


func _on_eye_button_pressed() -> void:
	is_password_hidden = !is_password_hidden
	password_input.secret = is_password_hidden
	eye_button.texture_normal = preload("res://assets/ui/eye_closed.png") if is_password_hidden else preload("res://assets/ui/eye_open.png")


func _on_register_pressed() -> void:
	if _busy:
		return

	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()

	# Kiểm tra trước ở client cho khớp luật của server, đỡ phải đi một vòng mạng.
	if username.length() < 3 or username.length() > 64:
		_show_status("Tên tài khoản phải từ 3 đến 64 ký tự", true)
		return
	if not RegEx.create_from_string("^[a-zA-Z0-9_]+$").search(username):
		_show_status("Tên tài khoản chỉ được chứa chữ, số và dấu gạch dưới", true)
		return
	if password.length() < 6:
		_show_status("Mật khẩu phải từ 6 ký tự trở lên", true)
		return

	_set_busy(true)
	_show_status("Đang tạo tài khoản...", false)

	var res: Dictionary = await AvatarClient.register(username, password)
	if not bool(res.get("ok", false)):
		_show_status(str(res.get("message", "Đăng ký thất bại")), true)
		_set_busy(false)
		return

	# Server trả sẵn accessToken nên đăng ký xong là vào game luôn.
	_show_status("Tạo tài khoản thành công!", false)
	await AvatarClient.await_ready(5.0)

	GameState.session_logged_in = true
	var err := get_tree().change_scene_to_file("res://scenes/intro/intro.tscn")
	if err != OK:
		_show_status("Lỗi mở intro (mã %d) — báo dev!" % err, true)
		_set_busy(false)
		push_error("change_scene intro loi: %d" % err)


func _set_busy(v: bool) -> void:
	_busy = v
	register_button.disabled = v
	username_input.editable = not v
	password_input.editable = not v


func _show_status(msg: String, is_error: bool) -> void:
	status_label.text = msg
	status_label.add_theme_color_override(
		"font_color",
		Color(0.9, 0.2, 0.15) if is_error else Color(0.35, 0.6, 0.35)
	)
	status_label.visible = true
