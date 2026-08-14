extends Node

const GAME_MENU_SCREEN = preload("res://scenes/ui/game_menu_screen.tscn")

var game_in_progress : bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_menu"):
		show_game_menu_scene()
		
		
func new_game() -> void:
	reset_game_state()
	game_in_progress = true


func load_game() -> void:
	reset_game_state()		  
	SaveGameManager.load_game()
	game_in_progress = true


func resume_game() -> void:
	pass


func exit_game() -> void:
	get_tree().quit()


func reset_game_state() -> void:
	SceneManager.load_main_scene_container()
	SceneManager.load_level("level1")
	

func show_game_menu_scene() -> void:
	var game_menu_scene_instance = GAME_MENU_SCREEN.instantiate()
	get_tree().root.add_child(game_menu_scene_instance)
