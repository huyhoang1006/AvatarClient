class_name Player
extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

## Cho phép tắt điều khiển tạm thời (lúc ngủ, lúc xem hội thoại...)
var control_enabled: bool = true

## Hướng nhân vật đang quay mặt. Có thể là hướng chéo.
var player_direction: Vector2 = Vector2.DOWN


## Hậu tố animation cho một hướng. Vector2.ZERO = lấy hướng đang đứng.
## Đi chéo thì lấy trục lệch nhiều hơn: (0.7, -0.7) -> "back"
func direction_suffix(direction: Vector2 = Vector2.ZERO) -> String:
	var dir: Vector2 = direction if direction != Vector2.ZERO else player_direction

	if dir == Vector2.ZERO:
		return "front"

	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0.0 else "left"

	return "front" if dir.y > 0.0 else "back"


## Phát animation theo hướng: play_directional("walk") -> play("walk_left")
func play_directional(prefix: String, direction: Vector2 = Vector2.ZERO) -> void:
	animated_sprite_2d.play("%s_%s" % [prefix, direction_suffix(direction)])


## Quy mọi hướng (kể cả chéo) về đúng 1 trong 4 hướng chẵn.
## Chưa dùng tới, để sẵn cho lúc làm công cụ: vùng đánh trúng, vị trí cầm đồ.
func cardinal_direction() -> Vector2:
	if player_direction == Vector2.ZERO:
		return Vector2.DOWN

	if absf(player_direction.x) > absf(player_direction.y):
		return Vector2.RIGHT if player_direction.x > 0.0 else Vector2.LEFT

	return Vector2.DOWN if player_direction.y > 0.0 else Vector2.UP
