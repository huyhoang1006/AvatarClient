extends Control

@onready var username_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/Username
@onready var password_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/Password
@onready var eye_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/EyeButton
@onready var login_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/LoginButton

var is_password_hidden := true

# tài khoản cố định
const FIXED_USERNAME = "admin"
const FIXED_PASSWORD = "123456"


func _ready() -> void:

	password_input.secret = true

	eye_button.texture_normal = preload("res://eye_closed.png")

	eye_button.pressed.connect(_on_eye_button_pressed)

	login_button.pressed.connect(_on_login_pressed)


func _on_eye_button_pressed() -> void:

	is_password_hidden = !is_password_hidden

	password_input.secret = is_password_hidden

	if is_password_hidden:
		eye_button.texture_normal = preload("res://eye_closed.png")
	else:
		eye_button.texture_normal = preload("res://eye_open.png")


func _on_login_pressed() -> void:

	var username = username_input.text
	var password = password_input.text

	if username == FIXED_USERNAME and password == FIXED_PASSWORD:

		print("Đăng nhập thành công")

		get_tree().change_scene_to_file(
			"res://intro.tscn"
		)

	else:
		print("Sai tài khoản hoặc mật khẩu")
