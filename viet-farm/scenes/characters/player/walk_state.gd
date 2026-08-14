extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D 
@export var speed: int = 50

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	var direction: Vector2 = GameInputEvents.movement_input()
	
	var in_water := player.is_in_water()
	var anim: String = current_walk_anim(direction)
	animated_sprite_2d.play(anim)
	
	if direction != Vector2.ZERO:
		player.player_direction = direction
		player.update_fishing_rod_visual()
	
	var move_speed := float(speed)
	if in_water:
		move_speed *= player.swim_speed_scale
	
	player.velocity = direction * move_speed
	player.move_and_slide()


func _on_next_transitions() -> void:
	if !GameInputEvents.is_movement_input():
		transition.emit("Idle")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	animated_sprite_2d.stop()


func current_walk_anim(direction: Vector2) -> String:
	if direction == Vector2.UP:
		return "walk_back"
	elif direction == Vector2.RIGHT:
		return "walk_right"
	elif direction == Vector2.DOWN:
		return "walk_front"
	elif direction == Vector2.LEFT:
		return "walk_left"
	return "walk_front"
