extends Control
## Intro kiểu VIDEO CHUYỂN CẢNH TỰ ĐỘNG — tranh tràn toàn màn hình,
## tự lật sang cảnh kế tiếp (hiệu ứng gập như lật trang), chữ kể chuyện
## hiện dần như phụ đề phim. Chạm/Space để qua nhanh, có nút Bỏ qua.
##
## THÊM CẢNH MỚI RẤT DỄ:
##   1. Thả file PNG vào  res://assets/intro_pages/  (tên bắt đầu bằng số để xếp
##      thứ tự, ví dụ "06_canh_moi.png"). Muốn tranh động: export strip ngang
##      các frame vuông (vd 2 frame 200x200 -> file 400x200) — tự chạy animation.
##   2. (Tuỳ chọn) Thêm caption vào pages.json. Không thêm cũng được —
##      cảnh vẫn hiện, tiêu đề lấy từ tên file.

const PAGES_DIR := "res://assets/intro_pages/"
const AUTO_HOLD := 3.2          # giây đứng lại sau khi chữ chạy xong rồi mới tự lật

var pages: Array = []            # [{tex, frames, title, text}]
var idx := 0
var flipping := false
var _ended := false
var _page_token := 0

var stage: Control              # toàn bộ cảnh (ảnh + chữ) — dùng để gập khi lật
var pic_clip: Control
var pic: TextureRect
var title_label: Label
var text_label: Label
var dots_label: Label
var hint_label: Label
var frame_timer: Timer
var cur_frame := 0


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

	_load_pages()
	_build_stage()

	if pages.is_empty():
		_finish()
		return
	await get_tree().process_frame   # đợi layout có kích thước thật
	_show_page(0, true)


# ---------- Nạp danh sách cảnh: pages.json + tự quét folder ----------
func _load_pages() -> void:
	var listed := {}
	var json_text := FileAccess.get_file_as_string(PAGES_DIR + "pages.json")
	if json_text != "":
		var data = JSON.parse_string(json_text)
		if data is Array:
			for e in data:
				if e is Dictionary and e.has("img"):
					var entry := _make_page(str(e["img"]), str(e.get("title", "")), str(e.get("text", "")))
					if not entry.is_empty():
						pages.append(entry)
						listed[str(e["img"])] = true
	var extra: Array[String] = []
	var dir := DirAccess.open(PAGES_DIR)
	if dir:
		for fn in dir.get_files():
			var name := fn.trim_suffix(".import").trim_suffix(".remap")
			if not name.to_lower().ends_with(".png"):
				continue
			if name.begins_with("_") or listed.has(name):
				continue
			if not extra.has(name):
				extra.append(name)
	extra.sort()
	for name in extra:
		var nice := name.get_basename().substr(name.get_basename().find("_") + 1).replace("_", " ").capitalize()
		var entry := _make_page(name, nice, "")
		if not entry.is_empty():
			pages.append(entry)


func _make_page(img: String, title: String, text: String) -> Dictionary:
	var tex := load(PAGES_DIR + img) as Texture2D
	if tex == null:
		push_warning("intro: không load được " + img)
		return {}
	var w := tex.get_width()
	var h := tex.get_height()
	var frames := 1
	if h > 0 and w % h == 0 and w / h >= 2:
		frames = w / h
	return {"tex": tex, "frames": frames, "title": title, "text": text}


# ---------- Dựng màn trình chiếu ----------
func _build_stage() -> void:
	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	# Ảnh toàn màn hình (clip phần thừa khi Ken Burns)
	pic_clip = Control.new()
	pic_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic_clip.clip_contents = true
	pic_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(pic_clip)
	pic = TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic_clip.add_child(pic)

	# Dải tối mờ dưới màn hình cho chữ dễ đọc
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.82)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	grad.gradient = g
	grad.fill_from = Vector2(0.5, 0.0)
	grad.fill_to = Vector2(0.5, 1.0)
	var shade := TextureRect.new()
	shade.texture = grad
	shade.anchor_top = 0.55
	shade.anchor_bottom = 1.0
	shade.anchor_right = 1.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(shade)

	# Chữ kể chuyện (như phụ đề phim)
	title_label = Label.new()
	title_label.anchor_left = 0.08
	title_label.anchor_right = 0.92
	title_label.anchor_top = 0.66
	title_label.anchor_bottom = 0.66
	title_label.offset_bottom = 46
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.99, 0.85, 0.5))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(title_label)

	text_label = Label.new()
	text_label.anchor_left = 0.08
	text_label.anchor_right = 0.92
	text_label.anchor_top = 0.66
	text_label.anchor_bottom = 0.97
	text_label.offset_top = 52
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 21)
	text_label.add_theme_color_override("font_color", Color(0.97, 0.95, 0.9))
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	text_label.add_theme_constant_override("shadow_offset_x", 2)
	text_label.add_theme_constant_override("shadow_offset_y", 2)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(text_label)

	# Chấm tiến trình các cảnh
	dots_label = Label.new()
	dots_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dots_label.position = Vector2(-80, 16)
	dots_label.custom_minimum_size = Vector2(160, 0)
	dots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots_label.add_theme_font_size_override("font_size", 16)
	dots_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	dots_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(dots_label)

	hint_label = Label.new()
	hint_label.text = "Chạm để qua nhanh ►"
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.position = Vector2(-210, -34)
	hint_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hint_label)
	var htw := create_tween().set_loops()
	htw.tween_property(hint_label, "modulate:a", 0.3, 1.0)
	htw.tween_property(hint_label, "modulate:a", 1.0, 1.0)

	# Timer cho tranh nhiều frame
	frame_timer = Timer.new()
	frame_timer.wait_time = 0.45
	frame_timer.timeout.connect(_next_anim_frame)
	add_child(frame_timer)

	# Click toàn màn hình để qua nhanh
	var clicker := Button.new()
	clicker.flat = true
	clicker.focus_mode = Control.FOCUS_NONE
	clicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	clicker.pressed.connect(_flip_next)
	add_child(clicker)

	# Nút bỏ qua (nằm trên clicker)
	var skip := Button.new()
	skip.text = "Bỏ qua ►"
	skip.focus_mode = Control.FOCUS_NONE
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.position = Vector2(-140, 18)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.custom_minimum_size = Vector2(120, 44)
	skip.pressed.connect(_finish)
	add_child(skip)


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("interact") or (ev is InputEventKey and ev.pressed and ev.keycode == KEY_ENTER):
		_flip_next()


# ---------- Hiển thị cảnh + tự lật ----------
func _show_page(i: int, first := false) -> void:
	idx = i
	_page_token += 1
	var token := _page_token
	var p: Dictionary = pages[i]
	cur_frame = 0
	_set_pic_frame(p, 0)
	frame_timer.stop()
	if int(p["frames"]) > 1:
		frame_timer.start()

	title_label.text = str(p["title"])
	text_label.text = str(p["text"])
	var dots := ""
	for k in range(pages.size()):
		dots += "●" if k <= i else "○"
		dots += " "
	dots_label.text = dots.strip_edges()

	# chữ hiện dần
	text_label.visible_ratio = 0.0
	var type_time := maxf(0.6, str(p["text"]).length() * 0.028)
	var tw := create_tween()
	tw.tween_property(text_label, "visible_ratio", 1.0, type_time)

	# Ken Burns toàn màn hình: phủ kín + trượt/zoom chậm, đảo hướng chẵn/lẻ
	var vs := pic_clip.size
	var tex_h: float = (p["tex"] as Texture2D).get_height()
	var s: float = maxf(vs.x / tex_h, vs.y / tex_h) * 1.14
	pic.size = Vector2(tex_h, tex_h) * s
	var over := pic.size - vs
	var from_pos := Vector2(-over.x * 0.1, -over.y * 0.9) if i % 2 == 0 else Vector2(-over.x * 0.9, -over.y * 0.1)
	var to_pos := Vector2(-over.x * 0.9, -over.y * 0.1) if i % 2 == 0 else Vector2(-over.x * 0.1, -over.y * 0.9)
	pic.position = from_pos
	var kb := create_tween()
	kb.tween_property(pic, "position", to_pos, type_time + AUTO_HOLD + 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if first:
		stage.modulate.a = 0.0
		var otw := create_tween()
		otw.tween_property(stage, "modulate:a", 1.0, 0.8)

	# TỰ LẬT: chờ chữ chạy xong + AUTO_HOLD giây rồi tự sang cảnh kế
	_auto_flip(token, type_time + AUTO_HOLD)


func _auto_flip(token: int, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if token != _page_token or _ended or flipping:
		return
	_flip_next()


func _set_pic_frame(p: Dictionary, frame_i: int) -> void:
	var tex: Texture2D = p["tex"]
	if int(p["frames"]) <= 1:
		pic.texture = tex
		return
	var h := tex.get_height()
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(frame_i * h, 0, h, h)
	pic.texture = at


func _next_anim_frame() -> void:
	var p: Dictionary = pages[idx]
	cur_frame = (cur_frame + 1) % int(p["frames"])
	_set_pic_frame(p, cur_frame)


func _flip_next() -> void:
	if flipping or _ended:
		return
	# chữ đang chạy dở -> hiện hết trước, chưa lật
	if text_label.visible_ratio < 1.0:
		text_label.visible_ratio = 1.0
		return
	if idx >= pages.size() - 1:
		_finish()
		return
	flipping = true
	_page_token += 1   # hủy auto-flip đang chờ
	stage.pivot_offset = stage.size / 2.0
	var tw := create_tween()
	tw.tween_property(stage, "scale:x", 0.02, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(stage, "modulate", Color(0.55, 0.53, 0.5), 0.26)
	await tw.finished
	_show_page(idx + 1)
	var tw2 := create_tween()
	tw2.tween_property(stage, "scale:x", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(stage, "modulate", Color.WHITE, 0.28)
	await tw2.finished
	flipping = false


func _finish() -> void:
	if _ended:
		return
	_ended = true
	var fade := ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.6)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")
