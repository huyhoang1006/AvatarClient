extends Node2D

const GAME_DIALOGUE_BALLOON = preload("res://dialogue/game_dialogue_balloon.tscn")

@export var dialogue_start_command: String = "start_table"

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableLabelComponent

var in_range: bool = false


func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()


func on_interactable_activated() -> void:
	in_range = true
	interactable_label_component.show()


func on_interactable_deactivated() -> void:
	in_range = false
	interactable_label_component.hide()


func _unhandled_input(event: InputEvent) -> void:
	if in_range and event.is_action_pressed("show_dialogue"):
		var balloon: BaseGameDialogueBalloon = GAME_DIALOGUE_BALLOON.instantiate()
		get_tree().root.add_child(balloon)
		balloon.start(load("res://dialogue/conversations/house_furniture.dialogue"), dialogue_start_command)
