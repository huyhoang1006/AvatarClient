class_name NonPlayableCharacter
extends CharacterBody2D

@export var min_walk_cycle: int = 2
@export var max_walk_cycle: int = 6

var walk_cycles: int 
var current_walk_cycle: int

func randomize_walk_cycles() -> void:
	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)
