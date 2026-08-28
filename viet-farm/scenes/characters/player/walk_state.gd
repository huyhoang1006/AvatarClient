extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

## Tốc độ đi bộ. Đây cũng là mốc để tính tốc độ animation (= speed_scale 1.0).
@export var speed: int = 100
@export var run_speed: int = 180

@export_group("Quán tính")
## Số giây để đạt tốc độ tối đa. Đo từ game tham chiếu: 0,17 s.
@export_range(0.0, 1.0, 0.01) var accel_time: float = 0.17
## Số giây để dừng hẳn sau khi thả phím. Đo được: 0,13 s.
@export_range(0.0, 1.0, 0.01) var brake_time: float = 0.13

@export_group("Animation")
## Chỉ dùng khi muốn animation cố tình nhanh/chậm hơn tốc độ thật.
@export_range(0.5, 2.0, 0.05) var anim_speed_tuning: float = 1.0
## Frame 0 của walk_* trùng pose đứng yên, nhấp nhẹ sẽ thấy trượt.
@export var walk_start_frame: int = 1
## Nhún người khi đi. Đo từ game tham chiếu: ~6,7% chiều cao nhân vật.
@export var walk_bob_height: float = 4.0

var _just_entered: bool = false


func _on_enter() -> void:
	_just_entered = true


func _on_physics_process(delta: float) -> void:
	if not player.control_enabled:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, brake_rate() * delta)
		player.move_and_slide()
		return

	var direction: Vector2 = GameInputEvents.movement_input()

	if direction != Vector2.ZERO:
		var target: Vector2 = direction * current_move_speed()
		player.velocity = player.velocity.move_toward(target, accel_rate() * delta)
		player.player_direction = direction
		player.update_fishing_rod_visual()
	else:
		# đã thả phím — trượt chậm dần thay vì dừng khựng
		player.velocity = player.velocity.move_toward(Vector2.ZERO, brake_rate() * delta)

	player.play_directional("walk", direction)

	# phải đặt SAU play(), vì play() luôn kéo frame về 0
	if _just_entered:
		_just_entered = false
		animated_sprite_2d.frame = walk_start_frame

	animated_sprite_2d.speed_scale = animation_speed_scale(player.velocity.length())
	apply_walk_bob()

	player.move_and_slide()


func current_move_speed() -> float:
	var move_speed: float = float(run_speed if Input.is_action_pressed("run") else speed)

	if player.is_in_water() and not player.is_jumping:
		move_speed *= player.swim_speed_scale

	return move_speed


## px/giây². Suy ra từ thời gian, nên đổi speed không phải chỉnh lại.
func accel_rate() -> float:
	return float(speed) / maxf(accel_time, 0.01)


func brake_rate() -> float:
	return float(speed) / maxf(brake_time, 0.01)


## Tốc độ animation bám vận tốc thật — trượt chậm dần thì chân cũng chậm dần.
func animation_speed_scale(current_speed: float) -> float:
	return (current_speed / maxf(float(speed), 1.0)) * anim_speed_tuning


## Nhún 2 lần mỗi chu kỳ đi — mỗi bước chân một lần.
func apply_walk_bob() -> void:
	var total: int = animated_sprite_2d.sprite_frames.get_frame_count(animated_sprite_2d.animation)
	if total <= 0:
		return

	var phase: float = float(animated_sprite_2d.frame) / float(total)
	animated_sprite_2d.offset.y = -roundf(walk_bob_height * absf(sin(phase * TAU)))


func _on_next_transitions() -> void:
	if GameInputEvents.is_movement_input():
		return

	# chưa dừng hẳn thì ở lại Walk cho trượt nốt
	if player.velocity.length() > 1.0:
		return

	transition.emit("Idle")


func _on_exit() -> void:
	player.velocity = Vector2.ZERO
	animated_sprite_2d.stop()
	animated_sprite_2d.speed_scale = 1.0
	animated_sprite_2d.offset.y = 0.0
