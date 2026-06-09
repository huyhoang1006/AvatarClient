extends Control

@onready var password_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/Password
@onready var eye_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/PasswordContainer/EyeButton

var is_password_hidden := true


func _ready() -> void:
	password_input.secret = true
	eye_button.texture_normal = preload("res://eye_closed.png") # 👈 SỬA Ở ĐÂY
	eye_button.pressed.connect(_on_eye_button_pressed)


func _on_eye_button_pressed():
	is_password_hidden = !is_password_hidden

	password_input.secret = is_password_hidden

	if is_password_hidden:
		eye_button.texture_normal = preload("res://eye_closed.png")
	else:
		eye_button.texture_normal = preload("res://eye_open.png")
