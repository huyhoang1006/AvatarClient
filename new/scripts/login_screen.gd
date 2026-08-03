extends Control

@onready var platform_login_button: Button = $BottomCenter/BottomPanel/PlatformLoginButton
@onready var guest_button: Button = $BottomCenter/BottomPanel/GuestButton

const NEXT_SCENE = "res://scenes/main_menu.tscn"

var _busy := false

func _ready() -> void:
	guest_button.pressed.connect(_on_guest_pressed)

func _on_guest_pressed() -> void:
	if _busy:
		return

	_set_busy(true)
	GameState.session_logged_in = true
	_goto_next_scene()

func _goto_next_scene() -> void:
	var err := get_tree().change_scene_to_file(NEXT_SCENE)
	if err != OK:
		push_error("change_scene loi: %d" % err)
		_set_busy(false)

func _set_busy(v: bool) -> void:
	_busy = v
	guest_button.disabled = v
