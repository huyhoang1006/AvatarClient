class_name Crop
extends Node2D

## Script dùng chung cho MỌI loại cây trồng.
## Muốn thêm giống mới: nhân bản scene + gán 1 file CropData (.tres).

@export var data: CropData

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var flowering_particles: GPUParticles2D = $FloweringParticles
@onready var growth_cycle_component: GrowthCycleComponent = $GrowthCycleComponent
@onready var hurt_component: HurtComponent = $HurtComponent


func _ready() -> void:
	watering_particles.emitting = false
	flowering_particles.emitting = false

	if data == null:
		push_warning("%s: chưa gán CropData trong Inspector" % name)
		return

	# thông số lấy từ .tres, ghi đè giá trị đặt trong scene
	growth_cycle_component.days_until_harvest = data.days_until_harvest
	growth_cycle_component.watering_interval_hours = data.watering_interval_hours

	hurt_component.hurt.connect(on_hurt)
	growth_cycle_component.growth_state_changed.connect(on_growth_state_changed)
	growth_cycle_component.crop_maturity.connect(on_crop_maturity)
	growth_cycle_component.crop_harvesting.connect(on_crop_harvesting)

	# đồng bộ hình ảnh với trạng thái hiện tại (quan trọng khi load save)
	var state: DataTypes.GrowthStates = growth_cycle_component.get_current_growth_state()
	on_growth_state_changed(state)
	if state >= DataTypes.GrowthStates.Maturity:
		flowering_particles.emitting = true


func on_growth_state_changed(state: DataTypes.GrowthStates) -> void:
	sprite_2d.frame = data.frame_offset + state


func on_hurt(_hit_damage: int) -> void:
	if growth_cycle_component.is_watered:
		return

	growth_cycle_component.water()

	watering_particles.emitting = true
	await get_tree().create_timer(data.watering_effect_duration).timeout

	if is_instance_valid(self):
		watering_particles.emitting = false


func on_crop_maturity() -> void:
	flowering_particles.emitting = true


func on_crop_harvesting() -> void:
	spawn_harvest()
	queue_free()


func spawn_harvest() -> void:
	if data == null or data.harvest_scene == null:
		return

	var parent: Node = get_parent()
	if parent == null:
		return

	var harvest: Node2D = data.harvest_scene.instantiate() as Node2D
	if harvest == null:
		return

	var spawn_position: Vector2 = global_position
	parent.add_child.call_deferred(harvest)
	harvest.set_deferred("global_position", spawn_position)
