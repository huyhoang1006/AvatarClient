extends OptionButton

@export var popup_bg: Texture2D
@export var popup_texture_margin := Vector4i(6, 6, 6, 6)
@export var popup_content_margin := Vector4i(4, 4, 4, 4)
@export var popup_expand_margin := Vector4i(0, 0, 0, 0)

@export var item_hover_color := Color(1, 1, 1, 0.15)
@export var font_color := Color(0.3, 0.18, 0.08)
@export var font_hover_color := Color(1, 1, 1)
@export var font_size := 10

@export var item_v_separation := 2
@export var item_h_separation := 4
@export var item_start_padding := 8
@export var item_end_padding := 8

func _ready() -> void:
	_skin_popup()

func _skin_popup() -> void:
	var popup := get_popup()
	popup.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	if popup_bg != null:
		var panel_style := StyleBoxTexture.new()
		panel_style.texture = popup_bg

		panel_style.texture_margin_left = popup_texture_margin.x
		panel_style.texture_margin_top = popup_texture_margin.y
		panel_style.texture_margin_right = popup_texture_margin.z
		panel_style.texture_margin_bottom = popup_texture_margin.w

		panel_style.content_margin_left = popup_content_margin.x
		panel_style.content_margin_top = popup_content_margin.y
		panel_style.content_margin_right = popup_content_margin.z
		panel_style.content_margin_bottom = popup_content_margin.w

		panel_style.expand_margin_left = popup_expand_margin.x
		panel_style.expand_margin_top = popup_expand_margin.y
		panel_style.expand_margin_right = popup_expand_margin.z
		panel_style.expand_margin_bottom = popup_expand_margin.w

		popup.add_theme_stylebox_override("panel", panel_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = item_hover_color
	hover_style.set_corner_radius_all(2)
	popup.add_theme_stylebox_override("hover", hover_style)

	popup.add_theme_color_override("font_color", font_color)
	popup.add_theme_color_override("font_hover_color", font_hover_color)
	popup.add_theme_font_size_override("font_size", font_size)

	popup.add_theme_constant_override("v_separation", item_v_separation)
	popup.add_theme_constant_override("h_separation", item_h_separation)
	popup.add_theme_constant_override("item_start_padding", item_start_padding)
	popup.add_theme_constant_override("item_end_padding", item_end_padding)

func remove_radio_indicators() -> void:
	var popup := get_popup()
	for i in range(popup.item_count):
		popup.set_item_as_radio_checkable(i, false)
