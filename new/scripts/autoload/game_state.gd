extends Node

var current_day: int = 1
var flags: Dictionary = {}
var relationship: Dictionary = {}
var session_logged_in: bool = false

func load_from_save(data: Dictionary) -> void:
	current_day = data.get("current_day", 1)
	flags = data.get("flags", {})
	relationship = data.get("relationship", {})

func to_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"flags": flags,
		"relationship": relationship,
	}

func save_progress() -> void:
	SaveManager.save_game(to_save_data())

func reset() -> void:
	current_day = 1
	flags = {}
	relationship = {}
	session_logged_in = false
