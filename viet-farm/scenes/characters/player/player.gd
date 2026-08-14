class_name Player
extends CharacterBody2D

@onready var hit_component: HitComponent = %HitComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing_rod_sprite: Sprite2D = $FishingRodSprite
@onready var water_splash: Sprite2D = $WaterSplash

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var swim_speed_scale: float = 0.6

var player_direction: Vector2

var water_layer: TileMapLayer
var is_swimming: bool = false

func _ready() -> void:
	ToolManager.tool_selected.connect(on_tool_selected)
	call_deferred("find_water_layer")
	on_tool_selected(ToolManager.selected_tool)


func find_water_layer() -> void:
	var level := get_tree().current_scene.find_child("Level1", true, false)
	if level:
		water_layer = level.get_node_or_null("GameTilemap/Water")


func is_in_water() -> bool:
	if water_layer == null:
		return false
	var cell := water_layer.local_to_map(water_layer.to_local(global_position))
	return water_layer.get_cell_source_id(cell) != -1


func _physics_process(_delta: float) -> void:
	update_water_visuals()


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
