extends CanvasLayer

@onready var save_game_button: Button = $MarginContainer/VBoxContainer/SaveGameButton
@onready var resume_game_button: Button = $MarginContainer/VBoxContainer/ResumeGameButton


func _ready() -> void:
	save_game_button.disabled = !GameManager.game_in_progress
	save_game_button.focus_mode = Control.FOCUS_ALL if GameManager.game_in_progress else Control.FOCUS_NONE
	resume_game_button.disabled = !GameManager.game_in_progress
	resume_game_button.focus_mode = Control.FOCUS_ALL if GameManager.game_in_progress else Control.FOCUS_NONE
	
	
func _on_new_game_button_pressed() -> void:
	GameManager.new_game()
	queue_free()
	
	
func _on_load_game_button_pressed() -> void:
	GameManager.load_game()
	queue_free()


func _on_save_game_button_pressed() -> void:
	SaveGameManager.save_game()


func _on_resume_game_button_pressed() -> void:
	GameManager.resume_game()
	queue_free()


func _on_exit_game_button_pressed() -> void:
	GameManager.exit_game()
