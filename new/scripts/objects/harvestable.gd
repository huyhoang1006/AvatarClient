class_name Harvestable
extends Sprite2D

## Script dùng chung cho MỌI vật thể chặt/đập được.
## Muốn thêm loại mới: tạo scene mới + gán 1 file HarvestableData (.tres).

@export var data: HarvestableData

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent


func _ready() -> void:
	if data == null:
		push_warning("%s: chưa gán HarvestableData trong Inspector" % name)
		return

	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damage_reached)


func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	shake()


func shake() -> void:
	if material == null:
		return

	material.set_shader_parameter("shake_intensity", data.shake_intensity)
	await get_tree().create_timer(data.shake_duration).timeout

	# node có thể đã bị phá huỷ trong lúc chờ
	if is_instance_valid(self) and material != null:
		material.set_shader_parameter("shake_intensity", 0.0)


func on_max_damage_reached() -> void:
	spawn_drops()
	queue_free()


func spawn_drops() -> void:
	if data == null or data.drop_scene == null:
		return

	var parent: Node = get_parent()
	if parent == null:
		return

	var spawn_position: Vector2 = global_position

	for i in data.drop_count:
		var drop: Node2D = data.drop_scene.instantiate() as Node2D
		if drop == null:
			continue

		var offset := Vector2.ZERO
		if data.drop_spread > 0.0:
			offset = Vector2(
				randf_range(-data.drop_spread, data.drop_spread),
				randf_range(-data.drop_spread, data.drop_spread)
			)

		# add_child trước, set vị trí sau — cả hai đều deferred nên chạy đúng thứ tự
		parent.add_child.call_deferred(drop)
		drop.set_deferred("global_position", spawn_position + offset)
