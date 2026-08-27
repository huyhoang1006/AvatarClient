class_name ToolActionState
extends NodeState

## State dùng chung cho MỌI hành động dùng công cụ: cày, tưới, chặt, cuốc...
## Thêm hành động mới = thêm 1 node vào StateMachine rồi điền animation_prefix,
## KHÔNG cần viết script mới.

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

## Tiền tố tên animation: "tilling" → phát "tilling_front", "tilling_left"...
@export var animation_prefix: String = ""

## Vùng va chạm bật lên trong lúc hành động.
## Để trống nếu hành động không đánh trúng gì (ví dụ cày đất).
@export var hit_component_collision_shape: CollisionShape2D


func _ready() -> void:
	if hit_component_collision_shape == null:
		return

	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = Vector2.ZERO


func _on_next_transitions() -> void:
	if GameInputEvents.use_tool():
		transition.emit("Idle")
		return

	if not animated_sprite_2d.is_playing():
		transition.emit("Idle")


func _on_enter() -> void:
	player.play_directional(animation_prefix)

	if hit_component_collision_shape == null:
		return

	hit_component_collision_shape.position = player.tool_hit_offset()
	hit_component_collision_shape.disabled = false


func _on_exit() -> void:
	animated_sprite_2d.stop()

	if hit_component_collision_shape == null:
		return

	hit_component_collision_shape.disabled = true
