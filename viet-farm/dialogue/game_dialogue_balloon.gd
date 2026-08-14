extends BaseGameDialogueBalloon

@onready var emotes_panel: Panel = $Balloon/Panel/MarginContainer/HBoxContainer/EmotesPanel

func _ready() -> void:	
	DialogueManager.got_dialogue.connect(on_dialog_line)
	
	
func on_dialog_line(line: DialogueLine) -> void:
	emotes_panel.play_talking_animation(line.character)
	
	
#func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
#	super.start(dialogue_resource, title, extra_game_states)
#	emotes_panel.play_talking_animation()
	

#func next(next_id: String) -> void:
#	super.next(next_id)
#	emotes_panel.play_talking_animation()
		
