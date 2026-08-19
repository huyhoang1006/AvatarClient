class_name MapBounds
extends Node2D

@export var bounds_size: Vector2 = Vector2(1254, 1254)
@export var wall_thickness: float = 16.0
@export var apply_camera_limits: bool = true


func _ready() -> void:
	build_walls()
	if apply_camera_limits:
		set_camera_limits()


func build_walls() -> void:
	var s := bounds_size
	var t := wall_thickness
	_add_wall(Vector2(s.x * 0.5, -t * 0.5), Vector2(s.x + t * 2.0, t))
	_add_wall(Vector2(s.x * 0.5, s.y + t * 0.5), Vector2(s.x + t * 2.0, t))
	_add_wall(Vector2(-t * 0.5, s.y * 0.5), Vector2(t, s.y))
	_add_wall(Vector2(s.x + t * 0.5, s.y * 0.5), Vector2(t, s.y))


func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	col.position = pos
	body.add_child(col)

	add_child(body)


func set_camera_limits() -> void:
	call_deferred("_apply_camera_limits")


func _apply_camera_limits() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(bounds_size.x)
	camera.limit_bottom = int(bounds_size.y)
