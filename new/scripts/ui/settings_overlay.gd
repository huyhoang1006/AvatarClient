extends CanvasLayer

@onready var root: Control = $Root
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var language_option: OptionButton = %LanguageOption
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var ambient_slider: HSlider = %AmbientSlider
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SfxValueLabel
@onready var ambient_value_label: Label = %AmbientValueLabel
@onready var reset_button: Button = %ResetButton
@onready var apply_button: Button = %ApplyButton
@onready var back_button: Button = %BackButton

var _saved_snapshot: Dictionary = {}

func _ready() -> void:
	for res in SettingsManager.RESOLUTIONS:
		resolution_option.add_item(res["label"])
	resolution_option.remove_radio_indicators()
	for lang in LanguageManager.AVAILABLE_LANGUAGES:
		language_option.add_item(lang["name"])
	language_option.remove_radio_indicators()

	if SettingsManager.is_mobile():
		resolution_option.get_parent().get_parent().visible = false
		fullscreen_toggle.get_parent().get_parent().visible = false

	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)

	music_slider.value_changed.connect(_on_music_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_value_changed)
	ambient_slider.value_changed.connect(_on_ambient_value_changed)

func open() -> void:
	_saved_snapshot = SettingsManager.get_current_snapshot()
	_load_snapshot_into_ui(_saved_snapshot)
	root.visible = true
	get_tree().paused = true

func close() -> void:
	root.visible = false
	get_tree().paused = false

func _load_snapshot_into_ui(data: Dictionary) -> void:
	resolution_option.selected = data.get("resolution_index", 0)
	fullscreen_toggle.button_pressed = data.get("fullscreen", false)

	var lang_code = data.get("language", "vi")
	var lang_index = LanguageManager.AVAILABLE_LANGUAGES.find_custom(func(l): return l["code"] == lang_code)
	language_option.selected = max(lang_index, 0)

	music_slider.value = data.get("music_volume", 0.8)
	sfx_slider.value = data.get("sfx_volume", 0.8)
	ambient_slider.value = data.get("ambient_volume", 0.8)

	_on_music_value_changed(music_slider.value)
	_on_sfx_value_changed(sfx_slider.value)
	_on_ambient_value_changed(ambient_slider.value)

func _collect_snapshot_from_ui() -> Dictionary:
	return {
		"resolution_index": resolution_option.selected,
		"fullscreen": fullscreen_toggle.button_pressed,
		"language": LanguageManager.AVAILABLE_LANGUAGES[language_option.selected]["code"],
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value,
		"ambient_volume": ambient_slider.value,
	}

func _on_reset_pressed() -> void:
	_load_snapshot_into_ui(SettingsManager.get_defaults_snapshot())

func _on_apply_pressed() -> void:
	var data = _collect_snapshot_from_ui()
	SettingsManager.commit_settings(data)
	_saved_snapshot = data

func _on_back_pressed() -> void:
	close()

func _on_music_value_changed(value: float) -> void:
	music_value_label.text = "%d%%" % round(value * 100)

func _on_sfx_value_changed(value: float) -> void:
	sfx_value_label.text = "%d%%" % round(value * 100)

func _on_ambient_value_changed(value: float) -> void:
	ambient_value_label.text = "%d%%" % round(value * 100)
