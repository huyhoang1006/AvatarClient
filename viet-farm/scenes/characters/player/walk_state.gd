extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

## Tốc độ đi bộ. Đây cũng là mốc để tính tốc độ animation (= speed_scale 1.0).
@export var speed: int = 50
@export var run_speed: int = 90

## Chỉ dùng khi muốn animation cố tình nhanh/chậm hơn tốc độ thật.
## 1.0 = khớp hoàn toàn với tốc độ di chuyển → không trượt chân.
@export_range(0.5, 2.0, 0.05) var anim_speed_tuning: float = 1.0

## Frame 0 của các animation walk_* trùng khít với pose đứng yên (idle_*),
## nên nhấp nhẹ một cái là nhân vật trượt đi mà chân không nhúc nhích.
## Bắt đầu từ frame 1 để bước chân nhìn thấy được ngay từ frame đầu.
## Đặt 0 nếu sau này vẽ lại sprite và frame 0 đã là pose bước chân.
@export var walk_start_frame: int = 1

var _just_entered: bool = false


func _on_enter() -> void:
	_just_entered = true


func _on_physics_process(_delta: float) -> void:
	if not player.control_enabled:
		player.velocity = Vector2.ZERO
		return

	var direction: Vector2 = GameInputEvents.movement_input()
	var move_speed: float = current_move_speed()

	player.play_directional("walk", direction)
	animated_sprite_2d.speed_scale = animation_speed_scale(move_speed)

	# phải đặt SAU play(), vì play() luôn kéo frame về 0
	if _just_entered:
		_just_entered = false
		animated_sprite_2d.frame = walk_start_frame

	if direction != Vector2.ZERO:
		player.player_direction = direction
		player.update_fishing_rod_visual()

	player.velocity = direction * move_speed
	player.move_and_slide()


func current_move_speed() -> float:
	var move_speed: float = float(run_speed if Input.is_action_pressed("run") else speed)

	if player.is_in_water() and not player.is_jumping:
		move_speed *= player.swim_speed_scale

	return move_speed


## Tốc độ animation suy ra từ tốc độ di chuyển thật, không gõ tay.
## Chạy nhanh → chân nhanh theo. Lội nước chậm → chân chậm theo.
func animation_speed_scale(move_speed: float) -> float:
	return (move_speed / maxf(float(speed), 1.0)) * anim_speed_tuning


func _on_next_transitions() -> void:
	if not GameInputEvents.is_movement_input():
		transition.emit("Idle")


func _on_exit() -> void:
	animated_sprite_2d.stop()
	animated_sprite_2d.speed_scale = 1.0
