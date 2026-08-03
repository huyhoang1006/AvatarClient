extends Control

@onready var continue_button: Button = $MenuCenter/MenuButtons/ContinueButton
@onready var new_game_button: Button = $MenuCenter/MenuButtons/NewGameButton
@onready var settings_button: Button = $MenuCenter/MenuButtons/SettingsButton
@onready var quit_button: Button = $MenuCenter/MenuButtons/QuitButton

func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_continue_pressed() -> void:
	var data = SaveManager.load_game()
	GameState.load_from_save(data)
	_goto_hub()

func _on_new_game_pressed() -> void:
	var data = SaveManager.create_new_game()
	GameState.load_from_save(data)
	_goto_hub()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings_screen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _goto_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/hub.tscn")
