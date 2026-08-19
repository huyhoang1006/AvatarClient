extends CheckButton

@export var texture_on: Texture2D
@export var texture_off: Texture2D

@onready var _bg: TextureRect = get_node("../%s%s" % [name, "Bg"])

func _ready() -> void:
	toggled.connect(_on_toggled)
	_update_visual()

func _on_toggled(_pressed: bool) -> void:
	_update_visual()

func _update_visual() -> void:
	if _bg == null:
		return
	_bg.texture = texture_on if button_pressed else texture_off
