extends CharacterBody2D
class_name Player
## Nhân vật chính: di chuyển joystick/WASD, animation walk từ sheet Aseprite,
## vung công cụ, trạng thái mệt (chậm + mồ hôi) / kiệt sức.

const SHEET := "res://assets/art/characters/mc_full.png"
const BASE_SPEED := 170.0

var hud: Hud
var busy := false          # đang thoại / vung công cụ / modal
var anim: AnimatedSprite2D
var tool_sprite: Sprite2D
var sweat: CPUParticles2D
var facing := 1            # 1 phải, -1 trái


func _ready() -> void:
	z_index = 5
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10
	shape.shape = circle
	shape.position = Vector2(0, -8)
	add_child(shape)

	anim = AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames(SHEET, {
		"idle": [0, 0, 5, true],
		"walk": [1, 9, 10, true],
		"met": [10, 11, 3, true],
	}, 64)
	anim.offset = Vector2(0, -32)
	anim.play("idle")
	add_child(anim)

	tool_sprite = Sprite2D.new()
	tool_sprite.position = Vector2(14, -30)
	tool_sprite.visible = false
	add_child(tool_sprite)

	sweat = CPUParticles2D.new()
	sweat.amount = 6
	sweat.lifetime = 0.7
	sweat.position = Vector2(0, -52)
	sweat.direction = Vector2(0, 1)
	sweat.spread = 40
	sweat.initial_velocity_min = 20
	sweat.initial_velocity_max = 45
	sweat.gravity = Vector2(0, 90)
	sweat.scale_amount_min = 2.0
	sweat.scale_amount_max = 3.5
	sweat.color = Color(0.5, 0.75, 1.0, 0.9)
	sweat.emitting = false
	add_child(sweat)


func _physics_process(_delta: float) -> void:
	if busy or (hud and (hud.dialog_open or hud.modal_open)):
		velocity = Vector2.ZERO
		anim.play("idle")
		move_and_slide()
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if hud and hud.joy_vector.length() > 0.15:
		dir = hud.joy_vector
	if dir.length() > 1.0:
		dir = dir.normalized()

	var speed := BASE_SPEED
	if GameState.is_exhausted():
		speed *= 0.3
	elif GameState.is_tired():
		speed *= 0.55
	sweat.emitting = GameState.is_tired()

	velocity = dir * speed
	move_and_slide()

	if dir.length() > 0.05:
		anim.play("walk")
		if absf(dir.x) > 0.1:
			facing = 1 if dir.x > 0 else -1
			anim.flip_h = facing < 0
	else:
		# đứng yên: kiệt sức thì gập người thở (frame mệt)
		anim.play("met" if GameState.is_exhausted() or GameState.is_tired() else "idle")


## Vung công cụ: hiện sprite tool xoay 1 nhịp rồi ẩn
func swing_tool(tool_tex: Texture2D) -> void:
	busy = true
	tool_sprite.texture = tool_tex
	tool_sprite.visible = true
	tool_sprite.position = Vector2(14 * facing, -34)
	tool_sprite.flip_h = facing < 0
	tool_sprite.rotation_degrees = -70 * facing
	var tw := create_tween()
	tw.tween_property(tool_sprite, "rotation_degrees", 70.0 * facing, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished
	tool_sprite.visible = false
	busy = false


## Đứng nhai 1 nhịp (ăn)
func eat_pause() -> void:
	busy = true
	var tw := create_tween()
	tw.tween_property(anim, "scale", Vector2(1.06, 0.94), 0.12)
	tw.tween_property(anim, "scale", Vector2(1, 1), 0.12)
	tw.set_loops(3)
	await get_tree().create_timer(0.7).timeout
	anim.scale = Vector2.ONE
	busy = false
