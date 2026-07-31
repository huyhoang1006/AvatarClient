extends Node2D
class_name SceneBase
## Khung chung cho các scene gameplay: HUD + Player + Camera + hệ thống
## auto-lock mục tiêu gần nhất + nút trung tâm theo ngữ cảnh.

var hud: Hud
var player: Player
var cam: Camera2D
var interactables: Array[Interactable] = []
var lock_ring: AnimatedSprite2D
var current_target: Interactable = null
var map_size := Vector2(960, 640)
var _was_exhausted := false


func _ready() -> void:
	y_sort_enabled = true

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action)

	player = Player.new()
	player.hud = hud
	add_child(player)

	cam = Camera2D.new()
	cam.zoom = Vector2(1.6, 1.6)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)

	lock_ring = AnimatedSprite2D.new()
	var sf := Art.frames("res://assets/ui/ui_target_indicator.png", {"pulse": [2, 3, 4, true]}, 32)
	lock_ring.sprite_frames = sf
	lock_ring.play("pulse")
	lock_ring.visible = false
	lock_ring.z_index = 3
	add_child(lock_ring)

	_build()
	_apply_cam_limits()
	hud.set_action_icon(-1)
	await hud.fade_in(0.5)
	_after_fade()


## override ở scene con
func _build() -> void:
	pass


## override: chạy sau khi fade-in xong (cutscene mở màn...)
func _after_fade() -> void:
	pass


func _apply_cam_limits() -> void:
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(map_size.x)
	cam.limit_bottom = int(map_size.y)


func _process(_delta: float) -> void:
	_update_target()
	_watch_exhaustion()


func _update_target() -> void:
	var best: Interactable = null
	var best_d := 1e9
	for it in interactables:
		if not is_instance_valid(it) or not it.enabled:
			continue
		var d := player.position.distance_to(it.position)
		if d <= it.radius and d < best_d:
			best_d = d
			best = it
	current_target = best
	if best and not (hud.dialog_open or hud.modal_open):
		lock_ring.visible = true
		lock_ring.position = best.position
		hud.set_action_icon(best.icon_index)
	else:
		lock_ring.visible = false
		hud.set_action_icon(-1)


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("interact") and not hud.dialog_open and not hud.modal_open:
		_on_action()
		return
	# CHẠM/CLICK THẲNG vào NPC / đồ vật để tương tác (kiểu Harvest Town)
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT 			and not hud.dialog_open and not hud.modal_open and not player.busy:
		var wp := get_global_mouse_position()
		var best: Interactable = null
		var best_d := 1e9
		for it in interactables:
			if not is_instance_valid(it) or not it.enabled:
				continue
			var d := wp.distance_to(it.position)
			if d < maxf(34.0, it.radius * 0.7) and d < best_d:
				best_d = d
				best = it
		if best:
			if player.position.distance_to(best.position) <= best.radius:
				best.activate()
			else:
				hud.toast("Lại gần hơn chút nữa rồi chạm nhé...")
			get_viewport().set_input_as_handled()


func _on_action() -> void:
	if current_target and not player.busy and not hud.dialog_open and not hud.modal_open:
		current_target.activate()


func _watch_exhaustion() -> void:
	var ex := GameState.is_exhausted()
	if ex and not _was_exhausted:
		hud.flash(Color(1, 0.15, 0.15), 0.45)
		hud.show_status(0, true)
		hud.toast("Kiệt sức! Ăn gì đó ngay đi...")
	elif not ex and _was_exhausted:
		hud.show_status(0, false)
	_was_exhausted = ex


# ---------- Helpers dựng map ----------
func add_bg(path: String) -> void:
	var s := Sprite2D.new()
	s.texture = Art.tex(path)
	s.centered = false
	s.z_index = -10
	s.y_sort_enabled = false
	add_child(s)
	map_size = s.texture.get_size()


func add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = rect.size
	cs.shape = sh
	body.position = rect.position + rect.size / 2.0
	body.add_child(cs)
	add_child(body)


func add_borders(margin := 12.0) -> void:
	add_wall(Rect2(-40, -40, map_size.x + 80, 40 + margin))
	add_wall(Rect2(-40, map_size.y - margin, map_size.x + 80, 40 + margin))
	add_wall(Rect2(-40, 0, 40 + margin, map_size.y))
	add_wall(Rect2(map_size.x - margin, 0, 40 + margin, map_size.y))


## "!" nhấp nhô trên đầu NPC; trả về node để hide
func add_emote(target_pos: Vector2, parent: Node = self) -> Sprite2D:
	var e := Sprite2D.new()
	e.texture = Art.frame("res://assets/ui/emote_16.png", 0, 16)
	e.position = target_pos
	e.scale = Vector2(1.6, 1.6)
	e.z_index = 20
	parent.add_child(e)
	var tw := e.create_tween().set_loops()
	tw.tween_property(e, "position:y", target_pos.y - 8, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(e, "position:y", target_pos.y, 0.4).set_trans(Tween.TRANS_SINE)
	return e


## Item bay về người chơi rồi vào túi
func fly_item(icon: Texture2D, from: Vector2, id: String, n := 1) -> void:
	var s := Sprite2D.new()
	s.texture = icon
	s.position = from
	s.z_index = 15
	add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "position", from + Vector2(0, -22), 0.18)
	tw.tween_property(s, "position", player.position + Vector2(0, -24), 0.28)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(s, "scale", Vector2(0.4, 0.4), 0.28)
	tw.tween_callback(func():
		s.queue_free()
		GameState.add_item(id, n))


func give_items(items: Array) -> void:
	# items: [[id, count], ...] — toast từng món kiểu hệ thống
	for it in items:
		GameState.add_item(it[0], it[1])
		hud.toast("[Nhận được: %s x%d]" % [GameState.item_name(it[0]), it[1]])


func goto_scene(path: String) -> void:
	await hud.fade_out(0.5)
	get_tree().change_scene_to_file(path)
