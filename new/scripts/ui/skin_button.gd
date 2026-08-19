extends Button

@export var press_offset := Vector2(0, 1)
@export var hover_overlay_alpha := 0.18
@export var press_overlay_alpha := 0.32
@export var disabled_modulate_alpha := 0.5

var _overlay: Control
var _is_pressed_down := false
var _offset_applied := false
var _last_disabled := false

func _ready() -> void:
	_last_disabled = disabled

	_setup_overlay()
	_update_disabled_visual()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _setup_overlay() -> void:
	var normal_style := get_theme_stylebox("normal")

	if normal_style is StyleBoxTexture:
		var nine_patch := NinePatchRect.new()
		nine_patch.texture = normal_style.texture
		nine_patch.patch_margin_left = normal_style.texture_margin_left
		nine_patch.patch_margin_top = normal_style.texture_margin_top
		nine_patch.patch_margin_right = normal_style.texture_margin_right
		nine_patch.patch_margin_bottom = normal_style.texture_margin_bottom
		_overlay = nine_patch
	else:
		var texture_rect := TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_overlay = texture_rect

	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate = Color(1, 1, 1, 0)

	var overlay_material := CanvasItemMaterial.new()
	overlay_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_overlay.material = overlay_material

	add_child(_overlay)

func _process(_delta: float) -> void:
	if disabled != _last_disabled:
		_last_disabled = disabled
		_update_disabled_visual()

func _update_disabled_visual() -> void:
	if disabled:
		modulate = Color(1, 1, 1, disabled_modulate_alpha)
		_overlay.modulate.a = 0.0
		if _offset_applied:
			position -= press_offset
			_offset_applied = false
		_is_pressed_down = false
	else:
		modulate = Color(1, 1, 1, 1)

func _on_mouse_entered() -> void:
	if disabled or _is_pressed_down:
		return
	_overlay.modulate.a = hover_overlay_alpha

func _on_mouse_exited() -> void:
	if disabled or _is_pressed_down:
		return
	_overlay.modulate.a = 0.0

func _on_button_down() -> void:
	if disabled:
		return
	_is_pressed_down = true
	_overlay.modulate.a = press_overlay_alpha
	if not _offset_applied:
		position += press_offset
		_offset_applied = true

func _on_button_up() -> void:
	if disabled:
		return
	_is_pressed_down = false
	if _offset_applied:
		position -= press_offset
		_offset_applied = false

	if get_global_rect().has_point(get_global_mouse_position()):
		_overlay.modulate.a = hover_overlay_alpha
	else:
		_overlay.modulate.a = 0.0
