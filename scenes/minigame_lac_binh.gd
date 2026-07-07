extends CanvasLayer
class_name MinigameLacBinh
## Minigame "LẮC BÌNH THÔNG VÒI" (Ngày 5): con trượt chạy qua lại trên thanh nhịp,
## chạm khi nó nằm trong VÙNG XANH = 1 lần lắc chuẩn. Cần 8 lần CHUẨN LIÊN TIẾP.
## Sau mỗi lần chuẩn: vùng xanh co 10%, con trượt nhanh thêm 5%. Hụt = mất combo.

signal solved(stars: int)
signal closed

const CAN_HIT := 8
const BAR_W := 440.0

var combo := 0
var misses := 0
var speed := 260.0          # px/giây
var zone_w := 120.0         # bề rộng vùng xanh
var cursor_x := 0.0
var dir := 1.0
var playing := true

var panel: Control
var binh: TextureRect
var bar: Control
var zone: ColorRect
var cursor: ColorRect
var combo_label: Label
var hint_label: Label


func _ready() -> void:
	layer = 20
	var f := SystemFont.new()
	f.font_names = ["Arial"]

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	add_child(dim)

	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(560, 420)
	panel.position = Vector2(-280, -210)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/ui_pixel/panel_dark_9_x3.png")
	for m in ["texture_margin_left", "texture_margin_right", "texture_margin_top", "texture_margin_bottom"]:
		sb.set(m, 21.0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var title := Label.new()
	title.text = "LẮC BÌNH THÔNG VÒI — bình tưới của ông ngoại"
	title.add_theme_font_override("font", f)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	title.custom_minimum_size = Vector2(560, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 14)
	panel.add_child(title)

	hint_label = Label.new()
	hint_label.text = "CHẠM khi con trượt vào VÙNG XANH. Cần %d nhịp chuẩn LIÊN TIẾP!" % CAN_HIT
	hint_label.add_theme_font_override("font", f)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	hint_label.custom_minimum_size = Vector2(560, 0)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.position = Vector2(0, 46)
	panel.add_child(hint_label)

	# bình tưới to giữa màn (nghiêng 30 độ như kịch bản)
	binh = TextureRect.new()
	binh.texture = Art.frame("res://assets/art/assets/binh_nuoc_tuoi_cay.png", 0, 32)
	binh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	binh.stretch_mode = TextureRect.STRETCH_SCALE
	binh.size = Vector2(128, 128)
	binh.position = Vector2(216, 90)
	binh.pivot_offset = Vector2(64, 64)
	binh.rotation_degrees = 30
	binh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(binh)

	combo_label = Label.new()
	combo_label.add_theme_font_override("font", f)
	combo_label.add_theme_font_size_override("font_size", 22)
	combo_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.45))
	combo_label.custom_minimum_size = Vector2(560, 0)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.position = Vector2(0, 232)
	panel.add_child(combo_label)
	_update_combo()

	# thanh nhịp
	bar = Control.new()
	bar.position = Vector2((560 - BAR_W) / 2.0, 280)
	bar.size = Vector2(BAR_W, 36)
	panel.add_child(bar)
	var bar_bg := ColorRect.new()
	bar_bg.size = Vector2(BAR_W, 36)
	bar_bg.color = Color(0.12, 0.1, 0.07)
	bar.add_child(bar_bg)
	var bar_vien := ColorRect.new()
	bar_vien.size = Vector2(BAR_W, 3)
	bar_vien.color = Color(0.62, 0.5, 0.36)
	bar.add_child(bar_vien)
	zone = ColorRect.new()
	zone.color = Color(0.35, 0.75, 0.3, 0.9)
	bar.add_child(zone)
	cursor = ColorRect.new()
	cursor.size = Vector2(8, 36)
	cursor.color = Color(0.99, 0.9, 0.55)
	bar.add_child(cursor)
	_dat_zone()

	# nút LẮC to + chạm cả màn hình đều tính
	var lac := Button.new()
	lac.text = "LẮC!!"
	lac.focus_mode = Control.FOCUS_NONE
	lac.add_theme_font_size_override("font_size", 22)
	lac.custom_minimum_size = Vector2(180, 52)
	lac.position = Vector2(190, 340)
	lac.pressed.connect(_tap)
	panel.add_child(lac)

	var quit := Button.new()
	quit.text = "Thoát"
	quit.focus_mode = Control.FOCUS_NONE
	quit.position = Vector2(462, 348)
	quit.size = Vector2(80, 38)
	quit.pressed.connect(func():
		closed.emit()
		queue_free())
	panel.add_child(quit)


func _dat_zone() -> void:
	# vùng xanh đặt ngẫu nhiên (không sát mép)
	zone.size = Vector2(zone_w, 36)
	zone.position = Vector2(randf_range(30.0, BAR_W - zone_w - 30.0), 0)


func _process(delta: float) -> void:
	if not playing:
		return
	cursor_x += speed * dir * delta
	if cursor_x >= BAR_W - 8:
		cursor_x = BAR_W - 8
		dir = -1.0
	elif cursor_x <= 0:
		cursor_x = 0
		dir = 1.0
	cursor.position.x = cursor_x


func _unhandled_input(ev: InputEvent) -> void:
	# chạm bất kỳ đâu (ngoài nút) cũng tính là lắc
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_tap()
		get_viewport().set_input_as_handled()
	elif ev.is_action_pressed("interact"):
		_tap()
		get_viewport().set_input_as_handled()


func _tap() -> void:
	if not playing:
		return
	var trung_zone := cursor_x + 4 >= zone.position.x and cursor_x + 4 <= zone.position.x + zone.size.x
	if trung_zone:
		combo += 1
		# bình giật + "ọc ọc": tăng độ khó
		var tw := binh.create_tween()
		tw.tween_property(binh, "rotation_degrees", 42.0, 0.06)
		tw.tween_property(binh, "rotation_degrees", 30.0, 0.08)
		zone_w = maxf(zone_w * 0.9, 46.0)
		speed *= 1.05
		if combo == 4:
			hint_label.text = "Nghe tiếng KHỤC rồi... Sắp thông! GIỮ NHỊP!"
		if combo >= CAN_HIT:
			_thanh_cong()
			return
		_dat_zone()
	else:
		misses += 1
		combo = 0
		hint_label.text = "Hụt nhịp! Nước sánh tung toé... làm lại từ đầu combo."
		var tw := binh.create_tween()
		tw.tween_property(binh, "rotation_degrees", 18.0, 0.06)
		tw.tween_property(binh, "rotation_degrees", 30.0, 0.1)
	_update_combo()


func _update_combo() -> void:
	combo_label.text = "Combo: %d / %d" % [combo, CAN_HIT]


func _thanh_cong() -> void:
	playing = false
	# "BỤP!" — nước phun rẻ quạt
	var nuoc := CPUParticles2D.new()
	nuoc.amount = 40
	nuoc.lifetime = 0.8
	nuoc.one_shot = true
	nuoc.position = Vector2(binh.position.x + 20, binh.position.y + 30)
	nuoc.direction = Vector2(-0.6, -1)
	nuoc.spread = 35
	nuoc.initial_velocity_min = 160
	nuoc.initial_velocity_max = 300
	nuoc.gravity = Vector2(0, 500)
	nuoc.scale_amount_min = 2.5
	nuoc.scale_amount_max = 4.5
	nuoc.color = Color(0.45, 0.75, 1.0, 0.95)
	panel.add_child(nuoc)
	nuoc.emitting = true
	combo_label.text = "BỤP!! THÔNG VÒI RỒI!"
	var stars := 3 if misses == 0 else (2 if misses <= 2 else 1)
	await get_tree().create_timer(1.2).timeout
	solved.emit(stars)
	queue_free()
