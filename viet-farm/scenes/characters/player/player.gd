class_name Player
extends CharacterBody2D

## Hướng → hậu tố tên animation. "idle" + "_front" = "idle_front"
const DIRECTION_SUFFIX: Dictionary = {
	Vector2.UP: "back",
	Vector2.DOWN: "front",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right",
}

## Hướng → vị trí vùng va chạm khi vung công cụ
const TOOL_HIT_OFFSET: Dictionary = {
	Vector2.UP: Vector2(0, -18),
	Vector2.DOWN: Vector2(0, 3),
	Vector2.LEFT: Vector2(-9, 0),
	Vector2.RIGHT: Vector2(9, 0),
}

## Hướng → vị trí và góc xoay cần câu
const FISHING_ROD_POSITION: Dictionary = {
	Vector2.UP: Vector2(-10, -12),
	Vector2.DOWN: Vector2(8, -6),
	Vector2.LEFT: Vector2(-12, -8),
	Vector2.RIGHT: Vector2(12, -8),
}

const FISHING_ROD_ROTATION: Dictionary = {
	Vector2.UP: 0.6,
	Vector2.DOWN: 0.0,
	Vector2.LEFT: 1.4,
	Vector2.RIGHT: -1.4,
}

@onready var hit_component: HitComponent = %HitComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing_rod_sprite: Sprite2D = $FishingRodSprite
@onready var water_splash: Sprite2D = $WaterSplash

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var swim_speed_scale: float = 0.6
@export var jump_height: float = 14.0
@export var jump_duration: float = 0.45

var control_enabled: bool = true

var player_direction: Vector2

var water_layer: TileMapLayer
var is_swimming: bool = false
var is_jumping: bool = false


func _ready() -> void:
	ToolManager.tool_selected.connect(on_tool_selected)
	call_deferred("find_water_layer")
	on_tool_selected(ToolManager.selected_tool)


func _physics_process(_delta: float) -> void:
	update_water_visuals()

	if Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()


# --- hướng nhìn -------------------------------------------------------------

## Hậu tố animation cho một hướng. Vector2.ZERO = dùng hướng đang đứng.
func direction_suffix(direction: Vector2 = Vector2.ZERO) -> String:
	var dir: Vector2 = direction if direction != Vector2.ZERO else player_direction
	return DIRECTION_SUFFIX.get(dir, "front")


## Phát animation theo hướng: play_directional("walk") → play("walk_left")
func play_directional(prefix: String, direction: Vector2 = Vector2.ZERO) -> void:
	animated_sprite_2d.play("%s_%s" % [prefix, direction_suffix(direction)])


func tool_hit_offset() -> Vector2:
	return TOOL_HIT_OFFSET.get(player_direction, TOOL_HIT_OFFSET[Vector2.DOWN])


func update_fishing_rod_visual() -> void:
	if not is_node_ready():
		return

	fishing_rod_sprite.visible = current_tool == DataTypes.Tools.FishingRod
	if not fishing_rod_sprite.visible:
		return

	fishing_rod_sprite.position = FISHING_ROD_POSITION.get(player_direction, FISHING_ROD_POSITION[Vector2.DOWN])
	fishing_rod_sprite.rotation = FISHING_ROD_ROTATION.get(player_direction, 0.0)


# --- nước và nhảy -----------------------------------------------------------

func find_water_layer() -> void:
	var level: Node = get_tree().current_scene.find_child("Level1", true, false)
	if level:
		water_layer = level.get_node_or_null("GameTilemap/Water")


func is_in_water() -> bool:
	if water_layer == null:
		return false

	var cell: Vector2i = water_layer.local_to_map(water_layer.to_local(global_position))
	return water_layer.get_cell_source_id(cell) != -1


func start_jump() -> void:
	is_jumping = true

	var tween := create_tween()
	var base: float = animated_sprite_2d.position.y
	tween.tween_property(animated_sprite_2d, "position:y", base - jump_height, jump_duration * 0.4)
	tween.tween_property(animated_sprite_2d, "position:y", base, jump_duration * 0.6)
	tween.tween_callback(func() -> void: is_jumping = false)


func update_water_visuals() -> void:
	var in_water: bool = is_in_water()

	if in_water != is_swimming:
		is_swimming = in_water
		water_splash.visible = in_water

	if is_swimming:
		water_splash.position = Vector2(0, 10)
		water_splash.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)


# --- công cụ ----------------------------------------------------------------

func on_tool_selected(tool: DataTypes.Tools) -> void:
	current_tool = tool
	hit_component.current_tool = tool
	update_fishing_rod_visual()
