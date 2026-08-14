extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var fish_scene: PackedScene = preload("res://scenes/objects/fish.tscn")

var cast_done: bool = false


func _on_process(_delta: float) -> void:
	pass


func _on_physics_process(_delta: float) -> void:
	pass


func _on_next_transitions() -> void:
	if cast_done:
		transition.emit("Idle")


func _on_enter() -> void:
	animated_sprite_2d.play("idle_front")
	cast_done = false
	player.fishing_rod_sprite.visible = true
	cast_animation()
	await get_tree().create_timer(1.5).timeout
	if is_active() and player.is_in_water():
		spawn_fish()
	cast_done = true


func _on_exit() -> void:
	animated_sprite_2d.stop()
	player.update_fishing_rod_visual()


func cast_animation() -> void:
	var rod: Sprite2D = player.fishing_rod_sprite
	var original_pos: Vector2 = rod.position
	var tween := create_tween()
	tween.tween_property(rod, "rotation", rod.rotation + 0.8, 0.3)
	tween.tween_property(rod, "rotation", rod.rotation - 0.8, 0.3)
	tween.tween_property(rod, "position", original_pos, 0.3)
	tween.tween_callback(func(): rod.rotation = 0.0)


func spawn_fish() -> void:
	var fish: Node2D = fish_scene.instantiate()
	fish.global_position = player.global_position + player.player_direction * 20
	get_tree().current_scene.add_child(fish)
	var tween := create_tween()
	tween.tween_property(fish, "position", fish.position + Vector2(0, -10), 0.3)
	tween.tween_property(fish, "position", fish.position, 0.3)


func is_active() -> bool:
	return player.current_tool == DataTypes.Tools.FishingRod
