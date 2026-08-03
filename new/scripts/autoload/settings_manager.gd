extends Node

const SETTINGS_PATH = "user://settings.json"
const BASE_WIDTH = 384
const BASE_HEIGHT = 256

const SCALE_OPTIONS = [2, 3, 4]

var current_scale_index := 1  # mặc định x3
var is_fullscreen := false

func _ready() -> void:
	load_settings()
	apply_current_settings()

func apply_scale(index: int) -> void:
	current_scale_index = clamp(index, 0, SCALE_OPTIONS.size() - 1)
	apply_current_settings()
	save_settings()

func apply_fullscreen(enabled: bool) -> void:
	is_fullscreen = enabled
	apply_current_settings()
	save_settings()

func apply_current_settings() -> void:
	var window = get_window()

	if is_fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		var multiplier = SCALE_OPTIONS[current_scale_index]
		window.size = Vector2i(BASE_WIDTH * multiplier, BASE_HEIGHT * multiplier)
		window.move_to_center()

func save_settings() -> void:
	var data = {
		"scale_index": current_scale_index,
		"fullscreen": is_fullscreen,
	}
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK:
		return

	var data: Dictionary = json.data
	current_scale_index = data.get("scale_index", 1)
	is_fullscreen = data.get("fullscreen", false)
