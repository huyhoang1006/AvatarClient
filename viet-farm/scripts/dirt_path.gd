extends Sprite2D

@export var scroll_speed: float = 24.0

const PERIOD := 64.0

var _vertical := false

func _ready() -> void:
	_vertical = texture.get_height() > texture.get_width()
	region_enabled = true
	if _vertical:
		region_rect = Rect2(0, 0, texture.get_width(), texture.get_height() - PERIOD)
	else:
		region_rect = Rect2(0, 0, texture.get_width() - PERIOD, texture.get_height())

func _process(delta: float) -> void:
	if _vertical:
		region_rect.position.y = fmod(region_rect.position.y + scroll_speed * delta, PERIOD)
	else:
		region_rect.position.x = fmod(region_rect.position.x + scroll_speed * delta, PERIOD)
