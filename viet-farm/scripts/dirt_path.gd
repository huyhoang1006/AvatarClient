extends Sprite2D

@export var scroll_speed: float = 24.0

const PERIOD := 64.0

func _ready() -> void:
	region_enabled = true
	region_rect = Rect2(0, 0, texture.get_width() - PERIOD, texture.get_height())

func _process(delta: float) -> void:
	region_rect.position.x = fmod(region_rect.position.x + scroll_speed * delta, PERIOD)
