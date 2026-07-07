extends Control
## INTRO CUTSCENE dựng trong engine (kiểu Stardew Valley / Harvest Town):
##   1. Văn phòng đêm (tranh map_1 — 2 frame tự animate)
##   2. Tin dữ (tranh map_6, ánh chiều thoi thóp)
##   3. CHUYẾN XE VỀ QUÊ — dựng thật trong engine: trời rạng sáng, đồng lúa,
##      xe khách nhún nhảy, cột điện + vạch đường lướt về sau, khói bụi
##   4. Ngõ làng (tranh map_9 — chính là shot nhân vật đứng đầu ngõ)
##   5. VỀ TỚI NHÀ — nền nhà ông ngoại, nhân vật xách balo TỰ ĐI BỘ vào sân
##   6. Title card "LÀNG QUÊ IT"
## Tự chạy hết, chạm = qua cảnh nhanh, có nút Bỏ qua.

var _ended := false
var _scene_token := 0

var holder: Control          # chứa nội dung từng cảnh
var title_label: Label
var text_label: Label
var shade: TextureRect
var skip_btn: Button

# các node cuộn trong cảnh xe khách: [{node, speed, wrap_x}]
var _scrollers: Array = []
var _scroll_active := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var f := SystemFont.new()
	f.font_names = ["Arial"]
	var th := Theme.new()
	th.default_font = f
	theme = th

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.02, 0.03)
	add_child(bg)

	holder = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)

	_build_subtitles()

	# chạm để qua cảnh
	var clicker := Button.new()
	clicker.flat = true
	clicker.focus_mode = Control.FOCUS_NONE
	clicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	clicker.pressed.connect(func(): _scene_token += 1)
	add_child(clicker)

	skip_btn = Button.new()
	skip_btn.text = "Bỏ qua ►"
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.position = Vector2(-140, 18)
	skip_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip_btn.custom_minimum_size = Vector2(120, 44)
	skip_btn.pressed.connect(_finish)
	add_child(skip_btn)

	await get_tree().process_frame
	_run()


func _build_subtitles() -> void:
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.85)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	grad.gradient = g
	grad.fill_from = Vector2(0.5, 0.0)
	grad.fill_to = Vector2(0.5, 1.0)
	shade = TextureRect.new()
	shade.texture = grad
	shade.anchor_top = 0.62
	shade.anchor_bottom = 1.0
	shade.anchor_right = 1.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	title_label = Label.new()
	title_label.anchor_left = 0.08
	title_label.anchor_right = 0.92
	title_label.anchor_top = 0.72
	title_label.anchor_bottom = 0.72
	title_label.offset_bottom = 44
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.99, 0.85, 0.5))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)

	text_label = Label.new()
	text_label.anchor_left = 0.08
	text_label.anchor_right = 0.92
	text_label.anchor_top = 0.72
	text_label.anchor_bottom = 0.98
	text_label.offset_top = 48
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.9))
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	text_label.add_theme_constant_override("shadow_offset_x", 2)
	text_label.add_theme_constant_override("shadow_offset_y", 2)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)


# ---------- chạy tuần tự các cảnh ----------
func _run() -> void:
	var steps := [_scene_office, _scene_letter, _scene_bus, _scene_lane, _scene_house, _scene_title]
	for step in steps:
		if _ended:
			return
		await step.call()
		if _ended:
			return
		_clear()
	_finish()


func _clear() -> void:
	_scroll_active = false
	_scrollers.clear()
	for c in holder.get_children():
		c.queue_free()
	title_label.text = ""
	text_label.text = ""


## chờ `secs` giây, kết thúc sớm nếu người chơi chạm / bỏ qua
func _hold(secs: float) -> void:
	var tok := _scene_token
	var t := 0.0
	while t < secs and tok == _scene_token and not _ended:
		await get_tree().process_frame
		t += get_process_delta_time()


func _caption(title: String, text: String) -> void:
	title_label.text = title
	text_label.text = text
	text_label.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(text_label, "visible_ratio", 1.0, maxf(0.5, text.length() * 0.025))


## nền tranh phủ kín màn hình; strip nhiều frame vuông -> tự animate
func _backdrop(path: String, zoom_from := 1.0, zoom_to := 1.06) -> TextureRect:
	var tex := load(path) as Texture2D
	var frames := 1
	var h := tex.get_height()
	if h > 0 and tex.get_width() % h == 0 and tex.get_width() / h >= 2:
		frames = tex.get_width() / h
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := holder.size
	var s: float = maxf(vs.x / h, vs.y / h)
	tr.size = Vector2(h, h) * s
	tr.position = (vs - tr.size) / 2.0
	tr.pivot_offset = tr.size / 2.0
	holder.add_child(tr)
	if frames <= 1:
		tr.texture = tex
	else:
		var fi := [0]
		tr.texture = _frame_of(tex, 0)
		var timer := Timer.new()
		timer.wait_time = 0.5
		timer.autostart = true
		timer.timeout.connect(func():
			fi[0] = (fi[0] + 1) % frames
			tr.texture = _frame_of(tex, fi[0]))
		tr.add_child(timer)
	tr.scale = Vector2(zoom_from, zoom_from)
	var tw := tr.create_tween()
	tw.tween_property(tr, "scale", Vector2(zoom_to, zoom_to), 8.0)
	return tr


func _frame_of(tex: Texture2D, i: int) -> AtlasTexture:
	var h := tex.get_height()
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(i * h, 0, h, h)
	return at


# ================= CÁC CẢNH =================
func _scene_office() -> void:
	_backdrop("res://assets/art/intro_game/map_1.png", 1.0, 1.1)
	_caption("Hà Nội — 2 giờ sáng", "7 năm code thuê. Tăng ca. Cơm hộp. Deadline.\n\"Cố thêm năm nữa rồi tính...\" — anh tự nhủ vậy suốt 7 năm.")
	await _hold(6.0)


func _scene_letter() -> void:
	var bd := _backdrop("res://assets/art/intro_game/map_6.png", 1.1, 1.0)
	# ánh chiều thoi thóp: nhấp nháy ấm nhẹ (tween gắn vào node để tự hủy khi đổi cảnh)
	var tw := bd.create_tween().set_loops()
	tw.tween_property(bd, "modulate", Color(1.06, 0.98, 0.9), 1.4)
	tw.tween_property(bd, "modulate", Color.WHITE, 1.4)
	_caption("Tin dữ", "Công ty cắt giảm nhân sự.\nPhòng trọ tăng giá. Người yêu nói lời chia tay.\nVà căn nhà của ông ngoại ở Bắc Ninh... sắp phải bán.")
	await _hold(6.5)


func _scene_bus() -> void:
	var vs := holder.size
	# --- bầu trời rạng sáng ---
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT  # dai mau cung
	g.colors = PackedColorArray([
		Color(0.45, 0.56, 0.78), Color(0.55, 0.62, 0.76), Color(0.68, 0.66, 0.72),
		Color(0.85, 0.72, 0.62), Color(0.98, 0.77, 0.58), Color(0.99, 0.9, 0.7),
	])
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.58, 0.76, 0.9])
	grad.gradient = g
	grad.width = 8
	grad.height = 48
	grad.fill_from = Vector2(0.5, 0.0)
	grad.fill_to = Vector2(0.5, 1.0)
	var sky := TextureRect.new()
	sky.texture = grad
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.size = Vector2(vs.x, vs.y * 0.62)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(sky)
	# mặt trời sớm
	var sun := TextureRect.new()
	sun.texture = load("res://assets/ui/light_radial.png")
	sun.modulate = Color(1.0, 0.9, 0.6, 0.95)
	sun.size = Vector2(260, 260)
	sun.position = Vector2(vs.x * 0.68, vs.y * 0.18)
	sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(sun)
	# --- đồi xa ---
	var hills := Polygon2D.new()
	hills.polygon = PackedVector2Array([
		Vector2(0, vs.y * 0.62), Vector2(vs.x * 0.18, vs.y * 0.42), Vector2(vs.x * 0.38, vs.y * 0.62),
		Vector2(vs.x * 0.52, vs.y * 0.38), Vector2(vs.x * 0.75, vs.y * 0.62),
		Vector2(vs.x * 0.88, vs.y * 0.46), Vector2(vs.x, vs.y * 0.62),
	])
	hills.color = Color(0.36, 0.46, 0.5)
	holder.add_child(hills)
	# --- dải đồng lúa ---
	for band in [[0.62, 0.72, Color(0.55, 0.68, 0.33)], [0.72, 0.8, Color(0.47, 0.6, 0.27)]]:
		var r := ColorRect.new()
		r.position = Vector2(0, vs.y * band[0])
		r.size = Vector2(vs.x, vs.y * (band[1] - band[0]))
		r.color = band[2]
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(r)
	# hàng cây xa cuộn chậm (parallax)
	for i in range(8):
		var tree := ColorRect.new()
		tree.color = Color(0.22, 0.35, 0.26)
		tree.size = Vector2(46, 26)
		tree.position = Vector2(i * 200.0, vs.y * 0.585)
		tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tree)
		_scrollers.append({"node": tree, "speed": 60.0, "wrap": vs.x + 260.0})
	# --- mặt đường ---
	var road := ColorRect.new()
	road.position = Vector2(0, vs.y * 0.8)
	road.size = Vector2(vs.x, vs.y * 0.2)
	road.color = Color(0.32, 0.31, 0.33)
	road.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(road)
	# vạch kẻ đường lướt nhanh
	for i in range(7):
		var dash := ColorRect.new()
		dash.color = Color(0.92, 0.88, 0.66)
		dash.size = Vector2(70, 8)
		dash.position = Vector2(i * 240.0, vs.y * 0.9)
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(dash)
		_scrollers.append({"node": dash, "speed": 520.0, "wrap": vs.x + 320.0})
	# cột điện lướt qua
	for i in range(3):
		var pole := Control.new()
		pole.position = Vector2(i * 560.0, 0)
		pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(pole)
		var post := ColorRect.new()
		post.color = Color(0.28, 0.22, 0.18)
		post.size = Vector2(10, vs.y * 0.34)
		post.position = Vector2(0, vs.y * 0.47)
		pole.add_child(post)
		var bar := ColorRect.new()
		bar.color = Color(0.28, 0.22, 0.18)
		bar.size = Vector2(46, 8)
		bar.position = Vector2(-18, vs.y * 0.49)
		pole.add_child(bar)
		_scrollers.append({"node": pole, "speed": 380.0, "wrap": vs.x + 620.0})
	_scroll_active = true

	# --- XE KHÁCH ---
	var bus := TextureRect.new()
	bus.texture = load("res://assets/ui/xe_khach_ve_que_96x48.png")
	bus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bus.stretch_mode = TextureRect.STRETCH_SCALE
	bus.size = Vector2(96, 48) * 4.4
	bus.position = Vector2(-bus.size.x, vs.y * 0.795 - bus.size.y)
	bus.pivot_offset = bus.size / 2.0
	bus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bus)
	# bụi sau bánh xe
	var dust := CPUParticles2D.new()
	dust.amount = 22
	dust.lifetime = 0.9
	dust.position = Vector2(bus.size.x * 0.08, bus.size.y * 0.95)
	dust.direction = Vector2(-1, -0.25)
	dust.spread = 22
	dust.initial_velocity_min = 60
	dust.initial_velocity_max = 130
	dust.gravity = Vector2(0, -12)
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 5.0
	dust.color = Color(0.75, 0.7, 0.62, 0.5)
	bus.add_child(dust)
	# xe chạy vào giữa màn hình (tween gắn vào node bus để tự hủy khi đổi cảnh)
	var enter := bus.create_tween()
	enter.tween_property(bus, "position:x", vs.x * 0.3, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# nhún nhảy theo ổ gà
	var bob := bus.create_tween().set_loops()
	bob.tween_property(bus, "position:y", vs.y * 0.795 - bus.size.y - 4, 0.22).set_trans(Tween.TRANS_SINE)
	bob.tween_property(bus, "position:y", vs.y * 0.795 - bus.size.y, 0.22).set_trans(Tween.TRANS_SINE)
	var sway := bus.create_tween().set_loops()
	sway.tween_property(bus, "rotation_degrees", 0.8, 0.35).set_trans(Tween.TRANS_SINE)
	sway.tween_property(bus, "rotation_degrees", -0.8, 0.35).set_trans(Tween.TRANS_SINE)

	_caption("Sáng hôm sau", "Anh lên chuyến xe sớm nhất về Bắc Ninh.\nMột mình. Không báo ai.")
	await _hold(7.5)
	if _ended:
		return
	# xe chạy vụt đi trước khi chuyển cảnh
	var exit_tw := bus.create_tween()
	exit_tw.tween_property(bus, "position:x", vs.x + 80.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _hold(0.9)


func _scene_lane() -> void:
	_backdrop("res://assets/art/intro_game/map_9.png", 1.12, 1.0)
	_caption("", "Con ngõ vẫn y như ngày anh rời đi, năm 18 tuổi.")
	await _hold(4.5)


func _scene_house() -> void:
	# nền: cảnh nhà ông ngoại (bản cảnh đầy đủ - có tre, cây, sân đất)
	_backdrop("res://assets/art/houses/nha_go_canh.png", 1.0, 1.05)
	var vs := holder.size
	# NHÂN VẬT TỰ ĐI BỘ vào sân, nhỏ dần theo chiều sâu
	var mc := AnimatedSprite2D.new()
	mc.sprite_frames = Art.frames("res://assets/art/characters/animatewalkingmaincharacter.png", {
		"walk": [1, 9, 10, true],
	}, 64)
	mc.play("walk")
	mc.position = Vector2(vs.x * 0.16, vs.y + 40)
	mc.scale = Vector2(4.2, 4.2)
	holder.add_child(mc)
	var tw := mc.create_tween()
	tw.tween_property(mc, "position", Vector2(vs.x * 0.47, vs.y * 0.66), 4.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(mc, "scale", Vector2(2.6, 2.6), 4.6)
	tw.tween_callback(func():
		mc.stop()
		mc.frame = 0)
	_caption("Nhà của ông", "\"Đất không phụ người chăm\" — ông từng nói vậy.\nGiờ chỉ còn căn nhà này... đợi anh về.")
	await _hold(7.0)


func _scene_title() -> void:
	var t1 := Label.new()
	t1.text = "LÀNG QUÊ IT"
	t1.set_anchors_preset(Control.PRESET_CENTER)
	t1.grow_horizontal = Control.GROW_DIRECTION_BOTH
	t1.grow_vertical = Control.GROW_DIRECTION_BOTH
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 64)
	t1.add_theme_color_override("font_color", Color(0.99, 0.85, 0.5))
	t1.modulate.a = 0.0
	holder.add_child(t1)
	var t2 := Label.new()
	t2.text = "— Chương 1: Về Quê —"
	t2.set_anchors_preset(Control.PRESET_CENTER)
	t2.grow_horizontal = Control.GROW_DIRECTION_BOTH
	t2.position.y += 60
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 22)
	t2.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	t2.modulate.a = 0.0
	holder.add_child(t2)
	var tw := create_tween()
	tw.tween_property(t1, "modulate:a", 1.0, 1.0)
	tw.tween_property(t2, "modulate:a", 1.0, 0.7)
	await _hold(3.4)


# cuộn thế giới trong cảnh xe khách
func _process(delta: float) -> void:
	if not _scroll_active:
		return
	for s in _scrollers:
		var n: Control = s["node"]
		if not is_instance_valid(n):
			continue
		n.position.x -= s["speed"] * delta
		if n.position.x < -140.0:
			n.position.x += s["wrap"]


func _finish() -> void:
	if _ended:
		return
	_ended = true
	_scroll_active = false
	var fade := ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.6)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")
