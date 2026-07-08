extends Control

@onready var username_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/Username
@onready var password_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/Password
@onready var eye_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/EyeButton
@onready var login_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/LoginButton

var is_password_hidden := true
var error_label: Label

# tài khoản cố định
const FIXED_USERNAME = "admin"
const FIXED_PASSWORD = "123456"


func _ready() -> void:
	password_input.secret = true
	eye_button.texture_normal = preload("res://eye_closed.png")
	eye_button.pressed.connect(_on_eye_button_pressed)
	login_button.pressed.connect(_on_login_pressed)

	# bản demo: điền sẵn tài khoản để test nhanh
	username_input.text = FIXED_USERNAME
	password_input.text = FIXED_PASSWORD

	# nhấn Enter ở ô mật khẩu / tài khoản = bấm Login
	password_input.text_submitted.connect(func(_t): _on_login_pressed())
	username_input.text_submitted.connect(func(_t): _on_login_pressed())

	# nhãn báo lỗi đỏ (trước đây lỗi chỉ in ra console, không ai thấy)
	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.15))
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.visible = false
	$CenterContainer/Panel/MarginContainer/VBoxContainer.add_child(error_label)


func _on_eye_button_pressed() -> void:
	is_password_hidden = !is_password_hidden
	password_input.secret = is_password_hidden
	if is_password_hidden:
		eye_button.texture_normal = preload("res://eye_closed.png")
	else:
		eye_button.texture_normal = preload("res://eye_open.png")


func _on_login_pressed() -> void:
	var username: String = username_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()

	if username == FIXED_USERNAME and password == FIXED_PASSWORD:
		print("Đăng nhập thành công")
		var err := get_tree().change_scene_to_file("res://intro.tscn")
		if err != OK:
			error_label.text = "Lỗi mở intro (mã %d) — báo dev!" % err
			error_label.visible = true
			push_error("change_scene intro loi: %d" % err)
	else:
		error_label.text = "Sai tài khoản hoặc mật khẩu! (demo: admin / 123456)"
		error_label.visible = true
		print("Sai tài khoản hoặc mật khẩu")
