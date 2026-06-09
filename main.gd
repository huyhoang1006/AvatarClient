extends Control

@onready var logo = $LogoContainer
@onready var background = $Background

@onready var login_ui = $Login
@onready var register_ui = $Register

@onready var register_button = $Login/CenterContainer/Panel/MarginContainer/VBoxContainer/RegisterButton

@onready var back_to_login_button = $Register/CenterContainer/Panel/MarginContainer/VBoxContainer/LoginButton


func _ready():

	# Ẩn login
	login_ui.modulate.a = 0

	# Ẩn register
	register_ui.visible = false

	# Ẩn background
	background.modulate.a = 0

	# Connect button
	register_button.pressed.connect(
		_on_register_button_pressed
	)

	back_to_login_button.pressed.connect(
		_on_back_to_login_pressed
	)

	play_intro()


func play_intro():

	var tween = create_tween()

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

	# Hiện UI Login
	tween.tween_property(
		login_ui,
		"modulate:a",
		1.0,
		1.0
	)


func _on_register_button_pressed():

	login_ui.visible = false
	register_ui.visible = true


func _on_back_to_login_pressed():

	register_ui.visible = false
	login_ui.visible = true
