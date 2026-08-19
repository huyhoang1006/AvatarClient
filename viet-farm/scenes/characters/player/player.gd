class_name Player
extends CharacterBody2D

@onready var hit_component: HitComponent = %HitComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing_rod_sprite: Sprite2D = $FishingRodSprite
@onready var water_splash: Sprite2D = $WaterSplash

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var swim_speed_scale: float = 0.6
@export var jump_height: float = 14.0
@export var jump_duration: float = 0.45

const WALK_SHEET := preload("res://assets/game/characters/walk_clean.png")
const IDLE_SHEET := preload("res://assets/game/characters/idle_grid.png")
const FRAME_W := 192
const FRAME_H := 256
const WALK_COLS := 8
const DIRECTIONS := ["front", "back", "left", "right"]

var control_enabled: bool = true

var player_direction: Vector2

var water_layer: TileMapLayer
var is_swimming: bool = false
var is_jumping: bool = false
var pond_area: Area2D

func _ready() -> void:
	ToolManager.tool_selected.connect(on_tool_selected)
	call_deferred("find_water_layer")
	on_tool_selected(ToolManager.selected_tool)
	_setup_animations()


func _setup_animations() -> void:
	var sf := SpriteFrames.new()

	for row in range(DIRECTIONS.size()):
		var dir: String = DIRECTIONS[row]
		var idle_tex := _make_frame(IDLE_SHEET, Rect2(row * FRAME_W, 0, FRAME_W, FRAME_H))

		sf.add_animation("idle_" + dir)
		sf.set_animation_loop("idle_" + dir, true)
		sf.add_frame("idle_" + dir, idle_tex)

		sf.add_animation("walk_" + dir)
		sf.set_animation_loop("walk_" + dir, true)
		sf.set_animation_speed("walk_" + dir, 8.0)
		for col in range(WALK_COLS):
			sf.add_frame("walk_" + dir, _make_frame(WALK_SHEET, Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)))

		for tool in ["chopping", "tilling", "watering"]:
			sf.add_animation(tool + "_" + dir)
			sf.set_animation_loop(tool + "_" + dir, false)
			sf.add_frame(tool + "_" + dir, idle_tex)

	animated_sprite_2d.sprite_frames = sf
	animated_sprite_2d.scale = Vector2(0.125, 0.125)
	animated_sprite_2d.play("idle_front")


func _make_frame(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = region
	return at


func find_water_layer() -> void:
	var level := get_tree().current_scene.find_child("Level1", true, false)
	if level:
		water_layer = level.get_node_or_null("GameTilemap/Water")
		pond_area = level.get_node_or_null("Pond/PondArea")


func is_in_water() -> bool:
	if is_jumping:
		return false
	if water_layer != null:
		var cell := water_layer.local_to_map(water_layer.to_local(global_position))
		if water_layer.get_cell_source_id(cell) != -1:
			return true
	if pond_area != null and pond_area.has_overlapping_bodies():
		for body in pond_area.get_overlapping_bodies():
			if body == self:
				return true
	return false


func _physics_process(_delta: float) -> void:
	update_water_visuals()
	if Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()


func start_jump() -> void:
	is_jumping = true
	var tween := create_tween()
	var base := animated_sprite_2d.position.y
	tween.tween_property(animated_sprite_2d, "position:y", base - jump_height, jump_duration * 0.4)
	tween.tween_property(animated_sprite_2d, "position:y", base, jump_duration * 0.6)
	tween.tween_callback(func() -> void: is_jumping = false)


func update_water_visuals() -> void:
	var in_water := is_in_water()
	if in_water != is_swimming:
		is_swimming = in_water
		water_splash.visible = in_water
	if is_swimming:
		water_splash.position = Vector2(0, 10)
		water_splash.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)


func update_fishing_rod_visual() -> void:
	if not is_node_ready():
		return
	fishing_rod_sprite.visible = current_tool == DataTypes.Tools.FishingRod
	if not fishing_rod_sprite.visible:
		return
	match player_direction:
		Vector2.UP:
			fishing_rod_sprite.position = Vector2(-10, -12)
			fishing_rod_sprite.rotation = 0.6
		Vector2.DOWN:
			fishing_rod_sprite.position = Vector2(8, -6)
			fishing_rod_sprite.rotation = 0.0
		Vector2.LEFT:
			fishing_rod_sprite.position = Vector2(-12, -8)
			fishing_rod_sprite.rotation = 1.4
			fishing_rod_sprite.flip_v = false
		Vector2.RIGHT:
			fishing_rod_sprite.position = Vector2(12, -8)
			fishing_rod_sprite.rotation = -1.4
		_:
			fishing_rod_sprite.position = Vector2(8, -6)
			fishing_rod_sprite.rotation = 0.0


func on_tool_selected(tool: DataTypes.Tools) -> void:
	current_tool = tool
	hit_component.current_tool = tool
	update_fishing_rod_visual()
