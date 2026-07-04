extends Control
## Màn chọn nhân vật sau intro: 3 nhân vật, chọn xong vào Ngày 1.

const CHARS := [
	{"name": "Nam", "img": "res://assets/art/characters/nam.png"},
	{"name": "Dũng", "img": "res://assets/art/characters/dung.png"},
	{"name": "A Hoàng", "img": "res://assets/art/characters/a_hoang.png"},
]

var selected := 0
var cards: Array[PanelContainer] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var f := SystemFont.new()
	f.font_names = ["Arial"]
	var th := Theme.new()
	th.default_font = f
	theme = th

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.09, 0.08, 0.07)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", 24)
	add_child(v)

	var title := Label.new()
	title.text = "CHỌN NHÂN VẬT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	v.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)

	for i in range(CHARS.size()):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(220, 340)
		row.add_child(card)
		cards.append(card)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(cv)
		var pic := TextureRect.new()
		pic.texture = load(CHARS[i]["img"])
		pic.custom_minimum_size = Vector2(190, 270)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cv.add_child(pic)
		var nm := Label.new()
		nm.text = CHARS[i]["name"]
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 22)
		cv.add_child(nm)
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(func(): _select(i))
		card.add_child(btn)

	var start := Button.new()
	start.text = "BẮT ĐẦU VỀ QUÊ ►"
	start.focus_mode = Control.FOCUS_NONE
	start.custom_minimum_size = Vector2(280, 56)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 20)
	start.pressed.connect(_start_game)
	v.add_child(start)

	_select(0)


func _select(i: int) -> void:
	selected = i
	for k in range(cards.size()):
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.16, 0.13, 0.1)
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(4)
		sb.border_color = Color(0.95, 0.78, 0.35) if k == i else Color(0.3, 0.25, 0.2)
		cards[k].add_theme_stylebox_override("panel", sb)


func _start_game() -> void:
	GameState.reset()
	GameState.player_name = CHARS[selected]["name"]
	get_tree().change_scene_to_file("res://scenes/scene_ngo.tscn")
