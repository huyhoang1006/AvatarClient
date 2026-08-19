class_name MapTransition
extends Area2D

@export var target_level: String
@export var target_spawn: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		SceneManager.load_level(target_level, target_spawn)
