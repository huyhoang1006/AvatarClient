extends Control

@onready var image = $TextureRect

var current_image := 1
var _ended := false


func _ready() -> void:
	# Nút bỏ qua intro
	var f := SystemFont.new()
	f.font_names = ["Arial"]
	var skip := Button.new()
	skip.text = "Bỏ qua ►"
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_override("font", f)
	skip.add_theme_font_size_override("font_size", 18)
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.position = Vector2(-150, -70)
	skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skip.custom_minimum_size = Vector2(130, 48)
	skip.pressed.connect(_goto_next)
	add_child(skip)

	play_intro()


func play_intro() -> void:
	while current_image <= 18 and not _ended:
		# LƯU Ý: thư mục là "intro_game" (chữ thường) — res:// phân biệt hoa thường khi export
		var path := "res://intro_game/%d.png" % current_image
		image.texture = load(path)
		current_image += 1
		await get_tree().create_timer(2.5).timeout
	_goto_next()


func _goto_next() -> void:
	if _ended:
		return
	_ended = true
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")
