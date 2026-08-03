extends Node

const SETTINGS_PATH = "user://language.json"

const AVAILABLE_LANGUAGES = [
	{"code": "vi", "name": "Tiếng Việt"},
	{"code": "en", "name": "English"},
]

var current_language := "vi"

func _ready() -> void:
	load_language()
	apply_language()

func set_language(code: String) -> void:
	current_language = code
	apply_language()
	save_language()

func apply_language() -> void:
	TranslationServer.set_locale(current_language)

func save_language() -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"language": current_language}))
	file.close()

func load_language() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK:
		return
	current_language = json.data.get("language", "vi")
