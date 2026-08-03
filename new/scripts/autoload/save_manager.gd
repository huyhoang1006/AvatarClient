extends Node

const SAVE_PATH = "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> Dictionary:
	if not has_save():
		return {}

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("Lỗi đọc save file: " + json.get_error_message())
		return {}

	return json.data

func save_game(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func create_new_game() -> Dictionary:
	var fresh_data = {
		"current_day": 1,
		"flags": {},
		"relationship": {},
	}
	save_game(fresh_data)
	return fresh_data
