extends Control

@onready var login_button: Button = $PanelCenter/PanelBox/LoginButton
@onready var guest_button: Button = $PanelCenter/PanelBox/GuestButton
@onready var settings_button: Button = $PanelCenter/PanelBox/SettingsButton
@onready var quit_button: Button = $PanelCenter/PanelBox/QuitButton
@onready var fade_in_overlay: ColorRect = $FadeInOverlay

const NEXT_SCENE = "res://scenes/main_menu.tscn"
var _busy := false

func _ready() -> void:
	fade_in_overlay.color.a = 1.0
	fade_in_overlay.visible = true
	
	guest_button.pressed.connect(_on_guest_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	fade_in_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween()
	tween.tween_property(fade_in_overlay, "color:a", 0.0, 0.8)

func _on_guest_pressed() -> void:
	if _busy:
		return
	_busy = true
	GameState.session_logged_in = true
	var err := get_tree().change_scene_to_file(NEXT_SCENE)
	if err != OK:
		push_error("change_scene loi: %d" % err)
		_busy = false

func _on_settings_pressed() -> void:
	SettingsOverlay.open()

func _on_quit_pressed() -> void:
	get_tree().quit()
