extends CanvasLayer
class_name MinigameHanoi
## Minigame "Tháp Cầu Chì Sứ" — Tower of Hanoi 3 lõi sứ.
## Chạm trục để nhấc lõi trên cùng, chạm trục khác để đặt xuống.

signal solved
signal closed

const DISC_W := [128.0, 96.0, 68.0]       # to -> nhỏ (bề rộng texture lõi sứ x4)
const DISC_TEX := ["res://assets/ui_pixel/mg_loi_su_to.png", "res://assets/ui_pixel/mg_loi_su_vua.png", "res://assets/ui_pixel/mg_loi_su_nho.png"]

var pegs := [[0, 1, 2], [], []]           # đáy -> đỉnh, chứa size index (0 to nhất)
var lifted := -1                           # peg đang nhấc lõi (-1 = không)
var moves := 0
var panel: Control
var disc_nodes := {}                       # size -> Panel
var moves_label: Label
var peg_x := [120.0, 300.0, 480.0]
var base_y := 330.0


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
	panel.custom_minimum_size = Vector2(600, 440)
	panel.size = Vector2(600, 440)
	panel.position = Vector2(-300, -220)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/ui_pixel/panel_dark_9_x3.png")
	sb.texture_margin_left = 21
	sb.texture_margin_right = 21
	sb.texture_margin_top = 21
	sb.texture_margin_bottom = 21
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	# bảng gỗ pixel làm nền khu xếp lõi sứ
	var board := TextureRect.new()
	board.texture = load("res://assets/ui_pixel/mg_bang_go_120x84.png")
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.size = Vector2(480, 336)
	board.position = Vector2(60, 84)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(board)

	var title := Label.new()
	title.text = "BẢNG ĐIỆN CŨ — THÁP CẦU CHÌ SỨ"
	title.add_theme_font_override("font", f)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	title.position = Vector2(0, 14)
	title.custom_minimum_size = Vector2(600, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var hint := Label.new()
	hint.text = "Xếp cả 3 lõi sứ sang trục C, từ Lớn đến Nhỏ, để đóng mạch điện.\nMỗi lần chỉ chuyển 1 lõi. KHÔNG đặt lõi to lên lõi nhỏ.\n(Tư duy logic của dân IT chắc giải nhanh thôi!)"
	hint.add_theme_font_override("font", f)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	hint.position = Vector2(30, 44)
	panel.add_child(hint)

	moves_label = Label.new()
	moves_label.add_theme_font_override("font", f)
	moves_label.add_theme_font_size_override("font_size", 14)
	moves_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	moves_label.position = Vector2(30, 390)
	panel.add_child(moves_label)
	_update_moves()

	# 3 trục đồng pixel + nhãn A B C + nút bấm phủ trục
	for i in range(3):
		var rod := TextureRect.new()
		rod.texture = load("res://assets/ui_pixel/mg_truc_16x56.png")
		rod.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rod.stretch_mode = TextureRect.STRETCH_SCALE
		rod.size = Vector2(64, 224)
		rod.position = Vector2(peg_x[i] + 30 - 32, base_y + 38 - 224)
		rod.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(rod)
		var lbl := Label.new()
		lbl.text = ["A", "B", "C"][i]
		lbl.add_theme_font_override("font", f)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.55))
		lbl.position = Vector2(peg_x[i] + 24, base_y + 40)
		panel.add_child(lbl)
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(peg_x[i] - 60 + 30, base_y - 150)
		btn.size = Vector2(120, 200)
		btn.pressed.connect(func(): _tap_peg(i))
		panel.add_child(btn)

	# 3 lõi sứ pixel
	for size in range(3):
		var d := TextureRect.new()
		d.texture = load(DISC_TEX[size])
		d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		d.stretch_mode = TextureRect.STRETCH_SCALE
		d.size = Vector2(DISC_W[size], 40)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(d)
		disc_nodes[size] = d
	_layout_discs()

	var quit := Button.new()
	quit.text = "Thoát"
	quit.focus_mode = Control.FOCUS_NONE
	quit.position = Vector2(500, 385)
	quit.size = Vector2(80, 38)
	quit.pressed.connect(func():
		closed.emit()
		queue_free())
	panel.add_child(quit)


func _disc_pos(peg: int, height: int, size: int, is_lifted := false) -> Vector2:
	var x: float = peg_x[peg] + 30.0 - DISC_W[size] / 2.0
	var y: float = base_y + 30.0 - (height + 1) * 42.0
	if is_lifted:
		y = base_y - 170
	return Vector2(x, y)


func _layout_discs() -> void:
	for p in range(3):
		for h in range(pegs[p].size()):
			var size: int = pegs[p][h]
			var target := _disc_pos(p, h, size, lifted == p and h == pegs[p].size() - 1)
			var d: TextureRect = disc_nodes[size]
			var tw := d.create_tween()
			tw.tween_property(d, "position", target, 0.12).set_trans(Tween.TRANS_QUAD)


func _tap_peg(i: int) -> void:
	if lifted == -1:
		if pegs[i].is_empty():
			return
		lifted = i
		_layout_discs()
		return
	if lifted == i:
		lifted = -1
		_layout_discs()
		return
	# thử đặt lõi từ peg `lifted` sang peg i
	var moving: int = pegs[lifted][pegs[lifted].size() - 1]
	if not pegs[i].is_empty():
		var top: int = pegs[i][pegs[i].size() - 1]
		if moving < top:  # moving to hơn (size index nhỏ = to)
			_shake(disc_nodes[moving])
			return
	pegs[lifted].pop_back()
	pegs[i].push_back(moving)
	lifted = -1
	moves += 1
	_update_moves()
	_layout_discs()
	if pegs[2].size() == 3:
		await get_tree().create_timer(0.25).timeout
		solved.emit()
		queue_free()


func _shake(d: Control) -> void:
	var orig := d.position
	var tw := d.create_tween()
	tw.tween_property(d, "position:x", orig.x + 8, 0.05)
	tw.tween_property(d, "position:x", orig.x - 8, 0.05)
	tw.tween_property(d, "position:x", orig.x, 0.05)


func _update_moves() -> void:
	moves_label.text = "Số bước: %d (tối thiểu 7)" % moves
