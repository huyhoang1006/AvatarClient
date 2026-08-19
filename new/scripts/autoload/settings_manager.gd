extends Node

const SETTINGS_PATH = "user://settings.json"

const RESOLUTIONS = [
	# 4:3
	{"label": "4:3 - 800x600",    "width": 800,  "height": 600},
	{"label": "4:3 - 1024x768",   "width": 1024, "height": 768},
	{"label": "4:3 - 1600x1200",  "width": 1600, "height": 1200},

	# 5:4
	{"label": "5:4 - 1280x1024",  "width": 1280, "height": 1024},

	# 16:10
	{"label": "16:10 - 1280x800",   "width": 1280, "height": 800},
	{"label": "16:10 - 1440x900",   "width": 1440, "height": 900},
	{"label": "16:10 - 1680x1050",  "width": 1680, "height": 1050},
	{"label": "16:10 - 1920x1200",  "width": 1920, "height": 1200},
	{"label": "16:10 - 2560x1600",  "width": 2560, "height": 1600},

	# 16:9
	{"label": "16:9 - 1280x720",   "width": 1280, "height": 720},
	{"label": "16:9 - 1366x768",   "width": 1366, "height": 768},
	{"label": "16:9 - 1600x900",   "width": 1600, "height": 900},
	{"label": "16:9 - 1920x1080",  "width": 1920, "height": 1080},
	{"label": "16:9 - 2560x1440",  "width": 2560, "height": 1440},
	{"label": "16:9 - 3840x2160",  "width": 3840, "height": 2160},

	# 21:9 (Ultrawide)
	{"label": "21:9 - 2560x1080",  "width": 2560, "height": 1080},
	{"label": "21:9 - 3440x1440",  "width": 3440, "height": 1440},

	# 32:9 (Super Ultrawide)
	{"label": "32:9 - 3840x1080",  "width": 3840, "height": 1080},
	{"label": "32:9 - 5120x1440",  "width": 5120, "height": 1440},
]

const DEFAULTS := {
	"resolution_index": 12,
	"fullscreen": false,
	"language": "vi",
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"ambient_volume": 1.0,
}

var current_resolution_index: int = DEFAULTS["resolution_index"]
var is_fullscreen: bool = DEFAULTS["fullscreen"]
var music_volume: float = DEFAULTS["music_volume"]
var sfx_volume: float = DEFAULTS["sfx_volume"]
var ambient_volume: float = DEFAULTS["ambient_volume"]

func _ready() -> void:
	load_settings()
	apply_all()

func is_mobile() -> bool:
	return OS.has_feature("mobile")

func apply_all() -> void:
	_apply_window()
	_apply_audio()

func _apply_window() -> void:
	if is_mobile():
		return
	var window = get_window()
	if is_fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.unresizable = false
		var res = RESOLUTIONS[current_resolution_index]
		window.size = Vector2i(res["width"], res["height"])
		window.move_to_center()
		window.unresizable = true

func _apply_audio() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("Ambient", ambient_volume)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("Không tìm thấy Audio Bus tên: " + bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear_value))
	AudioServer.set_bus_mute(idx, linear_value <= 0.001)

func commit_settings(data: Dictionary) -> void:
	current_resolution_index = data.get("resolution_index", current_resolution_index)
	is_fullscreen = data.get("fullscreen", is_fullscreen)
	music_volume = data.get("music_volume", music_volume)
	sfx_volume = data.get("sfx_volume", sfx_volume)
	ambient_volume = data.get("ambient_volume", ambient_volume)

	if data.has("language"):
		LanguageManager.set_language(data["language"])

	apply_all()
	save_settings()

func get_current_snapshot() -> Dictionary:
	return {
		"resolution_index": current_resolution_index,
		"fullscreen": is_fullscreen,
		"language": LanguageManager.current_language,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume,
	}

func get_defaults_snapshot() -> Dictionary:
	var snapshot = DEFAULTS.duplicate()
	snapshot["language"] = "vi"
	return snapshot

func save_settings() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(get_current_snapshot()))
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
	current_resolution_index = data.get("resolution_index", DEFAULTS["resolution_index"])
	is_fullscreen = data.get("fullscreen", DEFAULTS["fullscreen"])
	music_volume = data.get("music_volume", DEFAULTS["music_volume"])
	sfx_volume = data.get("sfx_volume", DEFAULTS["sfx_volume"])
	ambient_volume = data.get("ambient_volume", DEFAULTS["ambient_volume"])
