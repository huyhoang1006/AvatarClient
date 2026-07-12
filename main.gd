extends Control

@onready var logo = $LogoContainer
@onready var background = $Background
@onready var fade = $Fade
@onready var start_button = $StartButton

@onready var login_ui = $Login
@onready var register_ui = $Register

@onready var register_button = $Login/CenterContainer/Panel/MarginContainer/VBoxContainer/RegisterButton

@onready var back_to_login_button = $Register/CenterContainer/Panel/MarginContainer/VBoxContainer/LoginButton


func _ready():

	# Ẩn hết UI ban đầu
	login_ui.visible = false
	register_ui.visible = false
	start_button.visible = false
	background.modulate.a = 0

	# Connect button
	register_button.pressed.connect(
		_on_register_button_pressed
	)

	back_to_login_button.pressed.connect(
		_on_back_to_login_pressed
	)

	start_button.pressed.connect(
		_on_start_pressed
	)

	play_intro()


func play_intro():

	var tween = create_tween()

	# Fade từ đen ra
	fade.modulate.a = 1.0
	tween.tween_property(
		fade,
		"modulate:a",
		0.0,
		0.5
	)

	# Hiện logo
	logo.modulate.a = 0

	tween.tween_property(
		logo,
		"modulate:a",
		1.0,
		1.5
	)

	# Chờ
	tween.tween_interval(1.5)

	# Logo mờ dần
	tween.tween_property(
		logo,
		"modulate:a",
		0.0,
		1.2
	)

	# Background hiện
	tween.tween_property(
		background,
		"modulate:a",
		1.0,
		1.2
	)

	# Hiện nút Start
	start_button.modulate.a = 0
	start_button.visible = true
	tween.tween_property(
		start_button,
		"modulate:a",
		1.0,
		1.0
	)


func _on_start_pressed():
	if GameState.session_logged_in:
		# Đã đăng nhập -> vào game luôn
		var err := get_tree().change_scene_to_file("res://intro.tscn")
		if err != OK:
			push_error("Lỗi chuyển scene intro: %d" % err)
	else:
		# Chưa đăng nhập -> hiện form login
		start_button.visible = false
		login_ui.visible = true
		login_ui.modulate.a = 1.0


func _on_register_button_pressed():

	login_ui.visible = false
	register_ui.visible = true


func _on_back_to_login_pressed():

	register_ui.visible = false
	login_ui.visible = true
