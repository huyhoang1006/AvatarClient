extends Node2D

@export var pen_interior_size := Vector2i(7, 4)
@export var navigation_layers := 1
@export var gate_on_bottom := true
@export var gate_cell := -1

const FENCE_TILE := preload("res://assets/game/tilesets/Fences.png")
const GATE := preload("res://scenes/objects/animal_pen/pen_gate.tscn")
const TILE := 16
const REGION_STRAIGHT := Rect2(32, 0, 16, 16)
const REGION_POST := Rect2(0, 0, 16, 16)


func _ready() -> void:
	build_fences()
	build_navigation()


func build_fences() -> void:
	var w := pen_interior_size.x
	var h := pen_interior_size.y
	add_h_wall(0, w + 2, 0)
	add_h_wall(0, w + 2, h + 1, true)
	add_v_wall(0, 1, h)
	add_v_wall(w + 1, 1, h)
	add_post(0, 0)
	add_post(w + 1, 0)
	add_post(0, h + 1)
	add_post(w + 1, h + 1)


func add_h_wall(start_x: int, count: int, gy: int, is_bottom: bool = false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var gate_cells := 0
	var first_gate_cell := -1
	if is_bottom and gate_on_bottom and gate_cell >= 0:
		gate_cells = 2
		first_gate_cell = gate_cell
	if gate_cells == 0:
		add_h_collision(body, start_x, count, gy)
	else:
		add_h_collision(body, start_x, first_gate_cell, gy)
		add_h_collision(body, first_gate_cell + gate_cells, count - (first_gate_cell + gate_cells), gy)
	var gate: StaticBody2D = null
	for i in count:
		var cx := start_x + i
		if gate_cells > 0 and cx >= first_gate_cell and cx < first_gate_cell + gate_cells:
			if gate == null:
				gate = GATE.instantiate()
				gate.position = Vector2((first_gate_cell + 1) * TILE, gy * TILE)
				add_child(gate)
			continue
		body.add_child(make_sprite(REGION_STRAIGHT, Vector2((start_x + i + 0.5) * TILE, gy * TILE)))
	add_child(body)


func add_h_collision(body: StaticBody2D, start_x: int, cell_count: int, gy: int) -> void:
	if cell_count <= 0:
		return
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(cell_count * TILE, 14.0)
	col.shape = rect
	col.position = Vector2((start_x + cell_count * 0.5) * TILE, gy * TILE)
	body.add_child(col)


func add_v_wall(gx: int, start_y: int, count: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14.0, count * TILE)
	col.shape = rect
	col.position = Vector2(gx * TILE, (start_y + count * 0.5) * TILE)
	body.add_child(col)
	for i in count:
		var spr := make_sprite(REGION_STRAIGHT, Vector2(gx * TILE, (start_y + i + 0.5) * TILE))
		spr.rotation = PI / 2.0
		body.add_child(spr)
	add_child(body)


func add_post(gx: int, gy: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14.0, 14.0)
	col.shape = rect
	col.position = Vector2(gx * TILE, gy * TILE)
	body.add_child(col)
	body.add_child(make_sprite(REGION_POST, Vector2(gx * TILE, gy * TILE)))
	add_child(body)


func make_sprite(region: Rect2, pos: Vector2) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = FENCE_TILE
	spr.region_enabled = true
	spr.region_rect = region
	spr.position = pos
	return spr


func build_navigation() -> void:
	var region := NavigationRegion2D.new()
	region.navigation_layers = navigation_layers
	var poly := NavigationPolygon.new()
	var w := float(pen_interior_size.x * TILE)
	var h := float(pen_interior_size.y * TILE)
	var tl := Vector2(TILE, TILE)
	var top_right := Vector2(TILE + w, TILE)
	var br := Vector2(TILE + w, TILE + h)
	var bl := Vector2(TILE, TILE + h)
	poly.vertices = PackedVector2Array([tl, top_right, br, bl])
	poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_polygon = poly
	add_child(region)
