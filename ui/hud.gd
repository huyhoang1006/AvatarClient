extends CanvasLayer
class_name Hud
## HUD MOBA-style dùng chung cho các scene gameplay:
## joystick ảo, nút trung tâm đổi icon, thanh stamina, quest tracker,
## hộp thoại, toast, túi đồ, bảng xác nhận / tổng kết, fade & flash.

signal action_pressed
signal dialog_finished
signal _dialog_advance
signal _confirm_result(ok: bool)
signal _panel_closed

const BTN_STRIP := "res://assets/ui/ui_moba_nut_trung_tam.png"
const ICON_CUT := 0
const ICON_HAND := 1
const ICON_DOOR := 2
const ICON_WATER := 3
const ICON_MOON := 4
const ICON_NEXT := 5

var root: Control
var dialog_open := false
var modal_open := false

var _stam_fill: ColorRect
var _stam_label: Label
var _day_label: Label
var _status_icon: TextureRect
var _quest_title: Label
var _quest_steps: VBoxContainer
var _quest_panel: PanelContainer
var _dialog_panel: PanelContainer
var _dialog_name: Label
var _dialog_text: Label
var _dialog_lines: Array = []
var _dialog_idx := 0
var _toast_box: VBoxContainer
var _joy_base: Control
var _joy_knob: Control
var _joy_active := false
var _joy_center := Vector2.ZERO
var joy_vector := Vector2.ZERO
var _action_btn: TextureButton
var _eat_btn: Button
var _eat_icon: TextureRect
var _eat_count: Label
var _bag_panel: PanelContainer
var _water_label: Label
var _fade_rect: ColorRect
var _flash_rect: ColorRect
var _modal_holder: Control


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f := SystemFont.new()
	f.font_names = ["Arial"]
	var emoji := SystemFont.new()
	emoji.font_names = ["Segoe UI Emoji"]
	var sym := SystemFont.new()
	sym.font_names = ["Segoe UI Symbol"]
	f.fallbacks = [emoji, sym]
	var th := Theme.new()
	th.default_font = f
	th.default_font_size = 16
	root.theme = th
	add_child(root)

	_build_topleft()
	_build_quest()
	_build_joystick()
	_build_actions()
	_build_dialog()
	_build_toasts()
	_build_overlays()

	GameState.stamina_changed.connect(func(_v): _refresh_stamina())
	GameState.quest_changed.connect(_refresh_quest)
	GameState.inventory_changed.connect(_refresh_eat_slot)
	_refresh_stamina()
	_refresh_quest()
	_refresh_eat_slot()


# ================= TOP-LEFT: avatar + stamina + ngày giờ =================
func _build_topleft() -> void:
	var box := PanelContainer.new()
	box.position = Vector2(14, 12)
	box.add_theme_stylebox_override("panel", _sb9("dark"))
	root.add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)

	_day_label = Label.new()
	_day_label.text = "Ngày 1"
	_day_label.add_theme_font_size_override("font_size", 15)
	_day_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.79))
	v.add_child(_day_label)

	var bar_bg := TextureRect.new()
	bar_bg.texture = Art.tex("res://assets/ui_pixel/stamina_khung_64x12_x3.png")
	bar_bg.custom_minimum_size = Vector2(192, 36)
	v.add_child(bar_bg)
	_stam_fill = ColorRect.new()
	_stam_fill.position = Vector2(6, 6)
	_stam_fill.size = Vector2(180, 24)
	_stam_fill.color = Color(0.44, 0.81, 0.31)
	bar_bg.add_child(_stam_fill)
	_stam_label = Label.new()
	_stam_label.add_theme_font_size_override("font_size", 13)
	_stam_label.position = Vector2(72, 7)
	_stam_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_stam_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_stam_label.add_theme_constant_override("shadow_offset_x", 1)
	_stam_label.add_theme_constant_override("shadow_offset_y", 1)
	bar_bg.add_child(_stam_label)

	_status_icon = TextureRect.new()
	_status_icon.texture = Art.frame("res://assets/ui/icon_trang_thai_16.png", 0, 16)
	_status_icon.custom_minimum_size = Vector2(24, 24)
	_status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_status_icon.visible = false
	v.add_child(_status_icon)


func set_day_time(text: String) -> void:
	_day_label.text = text


func show_status(icon_idx: int, on: bool) -> void:
	_status_icon.texture = Art.frame("res://assets/ui/icon_trang_thai_16.png", icon_idx, 16)
	_status_icon.visible = on


func _refresh_stamina() -> void:
	var pct := GameState.stamina / GameState.MAX_STAMINA
	_stam_fill.size.x = 180 * pct
	_stam_label.text = "%d/100" % int(GameState.stamina)
	if pct > 0.5:
		_stam_fill.color = Color(0.44, 0.81, 0.31)
	elif pct > 0.2:
		_stam_fill.color = Color(0.84, 0.76, 0.29)
	else:
		_stam_fill.color = Color(0.84, 0.38, 0.29)


# ================= QUEST TRACKER =================
func _build_quest() -> void:
	_quest_panel = PanelContainer.new()
	_quest_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_panel.position = Vector2(-14, 12)
	_quest_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_quest_panel.add_theme_stylebox_override("panel", _sb9("dark"))
	root.add_child(_quest_panel)
	var v := VBoxContainer.new()
	_quest_panel.add_child(v)
	_quest_title = Label.new()
	_quest_title.add_theme_font_size_override("font_size", 15)
	_quest_title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	v.add_child(_quest_title)
	_quest_steps = VBoxContainer.new()
	v.add_child(_quest_steps)
	_quest_panel.visible = false


func _refresh_quest() -> void:
	var q: Dictionary = GameState.quest
	_quest_panel.visible = not q.is_empty()
	if q.is_empty():
		return
	_quest_title.text = "❗ " + str(q["title"])
	for c in _quest_steps.get_children():
		c.queue_free()
	for st in q["steps"]:
		var l := Label.new()
		var done: bool = int(st["have"]) >= int(st["need"])
		l.text = ("✔ " if done else "• ") + "%s (%d/%d)" % [st["text"], st["have"], st["need"]]
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color",
			Color(0.55, 0.85, 0.45) if done else Color(0.93, 0.9, 0.82))
		_quest_steps.add_child(l)
	# nháy nhẹ khi quest đổi
	var tw := create_tween()
	_quest_panel.modulate = Color(1.4, 1.3, 1.0)
	tw.tween_property(_quest_panel, "modulate", Color.WHITE, 0.4)


# ================= JOYSTICK =================
func _build_joystick() -> void:
	_joy_base = Control.new()
	_joy_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joy_base.position = Vector2(40, -220)
	_joy_base.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_joy_base.custom_minimum_size = Vector2(180, 180)
	_joy_base.size = Vector2(180, 180)
	_joy_base.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_joy_base)

	var base_circle := TextureRect.new()
	base_circle.texture = Art.tex("res://assets/ui_pixel/joystick_de_48_x3.png")
	base_circle.position = Vector2(18, 18)
	base_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_base.add_child(base_circle)

	_joy_knob = TextureRect.new()
	(_joy_knob as TextureRect).texture = Art.tex("res://assets/ui_pixel/joystick_num_20_x3.png")
	_joy_knob.position = Vector2(90, 90) - Vector2(30, 30)
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_base.add_child(_joy_knob)

	_joy_base.gui_input.connect(_joy_input)


func _joy_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			_joy_active = ev.pressed
			_joy_center = Vector2(90, 90)
			if ev.pressed:
				var v: Vector2 = ev.position - _joy_center
				if v.length() > 70:
					v = v.normalized() * 70
				joy_vector = v / 70.0
				_joy_knob.position = _joy_center + v - Vector2(30, 30)
			else:
				joy_vector = Vector2.ZERO
				_joy_knob.position = Vector2(90, 90) - Vector2(30, 30)
	elif ev is InputEventMouseMotion and _joy_active:
		var v: Vector2 = ev.position - _joy_center
		if v.length() > 70:
			v = v.normalized() * 70
		joy_vector = v / 70.0
		_joy_knob.position = _joy_center + v - Vector2(30, 30)


# ================= ACTION BUTTONS (góc phải dưới) =================
func _build_actions() -> void:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	holder.position = Vector2(-260, -240)
	holder.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(240, 220)
	root.add_child(holder)

	_action_btn = TextureButton.new()
	_action_btn.texture_normal = Art.frame(BTN_STRIP, ICON_HAND, 40)
	_action_btn.ignore_texture_size = true
	_action_btn.stretch_mode = TextureButton.STRETCH_SCALE
	_action_btn.custom_minimum_size = Vector2(80, 80)
	_action_btn.size = Vector2(80, 80)
	_action_btn.position = Vector2(130, 108)
	_action_btn.focus_mode = Control.FOCUS_NONE
	_action_btn.pressed.connect(func(): action_pressed.emit())
	holder.add_child(_action_btn)

	# Ô ăn nhanh
	_eat_btn = Button.new()
	_eat_btn.custom_minimum_size = Vector2(64, 64)
	_eat_btn.position = Vector2(40, 130)
	_eat_btn.add_theme_stylebox_override("normal", _sb9("slot"))
	_eat_btn.add_theme_stylebox_override("hover", _sb9("slot_chon"))
	_eat_btn.add_theme_stylebox_override("pressed", _sb9("slot_chon"))
	_eat_btn.focus_mode = Control.FOCUS_NONE
	_eat_btn.pressed.connect(_on_eat_pressed)
	holder.add_child(_eat_btn)
	_eat_icon = TextureRect.new()
	_eat_icon.custom_minimum_size = Vector2(40, 40)
	_eat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_eat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_eat_icon.position = Vector2(12, 12)
	_eat_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eat_btn.add_child(_eat_icon)
	_eat_count = Label.new()
	_eat_count.position = Vector2(42, 40)
	_eat_count.add_theme_font_size_override("font_size", 13)
	_eat_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eat_btn.add_child(_eat_count)

	# Nút túi đồ
	var bag := Button.new()
	bag.text = "🎒"
	bag.custom_minimum_size = Vector2(52, 52)
	bag.position = Vector2(170, 30)
	bag.add_theme_font_size_override("font_size", 24)
	bag.add_theme_stylebox_override("normal", _sb9("slot"))
	bag.add_theme_stylebox_override("hover", _sb9("slot_chon"))
	bag.focus_mode = Control.FOCUS_NONE
	bag.pressed.connect(_toggle_bag)
	holder.add_child(bag)

	_water_label = Label.new()
	_water_label.position = Vector2(40, 100)
	_water_label.add_theme_font_size_override("font_size", 14)
	_water_label.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	_water_label.visible = false
	holder.add_child(_water_label)


func set_action_icon(idx: int) -> void:
	if idx < 0:
		_action_btn.visible = false
	else:
		_action_btn.visible = true
		_action_btn.texture_normal = Art.frame(BTN_STRIP, idx, 40)


func update_water() -> void:
	_water_label.visible = GameState.has_item("binh_tuoi")
	_water_label.text = "💧 %d/%d" % [GameState.water, GameState.water_max]


func _first_food() -> String:
	for id in ["banh_phu_the", "mi_tom", "khoai_lang", "khoai_tay", "co_dai", "gao_nep"]:
		if GameState.has_item(id):
			return id
	return ""


func _refresh_eat_slot() -> void:
	var id := _first_food()
	if id == "":
		_eat_icon.texture = null
		_eat_count.text = ""
	else:
		var def: Dictionary = GameState.ITEMS[id]
		_eat_icon.texture = Art.frame(def["icon"], def["frame"], def["fw"])
		_eat_count.text = str(GameState.inventory.get(id, 0))
	update_water()


func _on_eat_pressed() -> void:
	var id := _first_food()
	if id == "":
		toast("Không có gì để ăn cả...")
		return
	var msg := GameState.eat(id)
	if msg != "":
		toast("Ăn %s: %s" % [GameState.item_name(id), msg])


func _toggle_bag() -> void:
	if _bag_panel and is_instance_valid(_bag_panel):
		_bag_panel.queue_free()
		_bag_panel = null
		return
	_bag_panel = PanelContainer.new()
	_bag_panel.set_anchors_preset(Control.PRESET_CENTER)
	_bag_panel.add_theme_stylebox_override("panel", _sb9("dark"))
	root.add_child(_bag_panel)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(320, 0)
	_bag_panel.add_child(v)
	var title := Label.new()
	title.text = "🎒 TÚI ĐỒ"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	v.add_child(title)
	if GameState.inventory.is_empty():
		var l := Label.new()
		l.text = "(trống)"
		v.add_child(l)
	for id in GameState.inventory:
		var def: Dictionary = GameState.ITEMS.get(id, {})
		var h := HBoxContainer.new()
		v.add_child(h)
		var ic := TextureRect.new()
		ic.texture = Art.frame(def.get("icon", ""), def.get("frame", 0), def.get("fw", 32))
		ic.custom_minimum_size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(ic)
		var l := Label.new()
		l.text = "%s ×%d" % [GameState.item_name(id), GameState.inventory[id]]
		l.custom_minimum_size = Vector2(190, 0)
		h.add_child(l)
		if int(def.get("food", 0)) > 0:
			var eat := Button.new()
			eat.text = "Ăn (+%d)" % int(def["food"])
			eat.pressed.connect(func():
				var msg := GameState.eat(id)
				if msg != "":
					toast("Ăn %s: %s" % [GameState.item_name(id), msg])
				_toggle_bag()
				_toggle_bag())
			h.add_child(eat)
	var close := Button.new()
	close.text = "Đóng"
	close.pressed.connect(_toggle_bag)
	v.add_child(close)


# ================= DIALOG =================
func _build_dialog() -> void:
	_dialog_panel = PanelContainer.new()
	_dialog_panel.anchor_left = 0.14
	_dialog_panel.anchor_right = 0.86
	_dialog_panel.anchor_top = 1.0
	_dialog_panel.anchor_bottom = 1.0
	_dialog_panel.offset_top = -170
	_dialog_panel.offset_bottom = -34
	_dialog_panel.add_theme_stylebox_override("panel", _sb9("paper"))
	root.add_child(_dialog_panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 10)
	_dialog_panel.add_child(m)
	var v := VBoxContainer.new()
	m.add_child(v)
	_dialog_name = Label.new()
	_dialog_name.add_theme_font_size_override("font_size", 17)
	_dialog_name.add_theme_color_override("font_color", Color(0.66, 0.24, 0.18))
	v.add_child(_dialog_name)
	_dialog_text = Label.new()
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.add_theme_font_size_override("font_size", 19)
	_dialog_text.add_theme_color_override("font_color", Color(0.16, 0.12, 0.09))
	_dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_dialog_text)

	var next := Button.new()
	next.text = "►"
	next.focus_mode = Control.FOCUS_NONE
	next.custom_minimum_size = Vector2(56, 40)
	next.add_theme_font_size_override("font_size", 20)
	next.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	next.position = Vector2(-70, -50)
	next.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	next.grow_vertical = Control.GROW_DIRECTION_BEGIN
	next.pressed.connect(func(): _dialog_advance.emit())
	_dialog_panel.add_child(next)
	_dialog_panel.visible = false


## lines: Array các [tên, câu thoại]. Gọi: await hud.dialog(...)
func dialog(lines: Array) -> void:
	dialog_open = true
	_dialog_lines = lines
	_dialog_idx = 0
	_dialog_panel.visible = true
	_show_dialog_line()
	while _dialog_idx < _dialog_lines.size():
		await _dialog_advance
		_dialog_idx += 1
		if _dialog_idx < _dialog_lines.size():
			_show_dialog_line()
	_dialog_panel.visible = false
	dialog_open = false
	dialog_finished.emit()


func _show_dialog_line() -> void:
	var line: Array = _dialog_lines[_dialog_idx]
	_dialog_name.text = str(line[0])
	_dialog_name.visible = str(line[0]) != ""
	_dialog_text.text = str(line[1])


func _unhandled_input(ev: InputEvent) -> void:
	if not dialog_open:
		return
	# đang thoại: nhấn E/Space HOẶC chạm bất kỳ đâu = qua câu tiếp
	if ev.is_action_pressed("interact") 			or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		_dialog_advance.emit()
		get_viewport().set_input_as_handled()


# ================= TOAST =================
func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.position = Vector2(-240, 70)
	_toast_box.custom_minimum_size = Vector2(480, 0)
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)


func toast(msg: String, secs := 2.6) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb9("dark"))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = msg
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.97, 0.94, 0.85))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	_toast_box.add_child(p)
	var tw := create_tween()
	tw.tween_interval(secs)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


# ================= OVERLAYS: fade / flash / confirm / summary =================
func _build_overlays() -> void:
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash_rect)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade_rect)

	_modal_holder = Control.new()
	_modal_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_modal_holder)


func flash(col := Color(1, 0.2, 0.2), strength := 0.5, secs := 0.35) -> void:
	_flash_rect.color = Color(col.r, col.g, col.b, strength)
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.0, secs)


func fade_out(secs := 0.6) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, secs)
	await tw.finished


func fade_in(secs := 0.6) -> void:
	_fade_rect.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, secs)
	await tw.finished


## await hud.confirm("...") -> bool
func confirm(msg: String, yes := "Đồng Ý", no := "Hủy") -> bool:
	modal_open = true
	var p := _modal_panel()
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(380, 0)
	v.add_theme_constant_override("separation", 16)
	(p.get_meta("inner") as Control).add_child(v)
	var l := Label.new()
	l.text = msg
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 18)
	v.add_child(l)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
	for pair in [[yes, true], [no, false]]:
		var b := Button.new()
		b.text = pair[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(120, 42)
		b.pressed.connect(func(): _confirm_result.emit(pair[1]))
		h.add_child(b)
	var result: bool = await _confirm_result
	p.queue_free()
	modal_open = false
	return result


## await hud.summary("NGÀY 1 HOÀN THÀNH", ["dòng 1", "dòng 2"], "Tiếp tục")
func summary(title: String, lines: Array, btn_text := "Tiếp tục") -> void:
	modal_open = true
	var p := _modal_panel()
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(460, 0)
	v.add_theme_constant_override("separation", 10)
	(p.get_meta("inner") as Control).add_child(v)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	v.add_child(t)
	for line in lines:
		var l := Label.new()
		l.text = str(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 17)
		v.add_child(l)
	var b := Button.new()
	b.text = btn_text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(160, 44)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): _panel_closed.emit())
	v.add_child(b)
	await _panel_closed
	p.queue_free()
	modal_open = false


func _modal_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.add_theme_stylebox_override("panel", _sb9("dark"))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	p.add_child(m)
	_modal_holder.add_child(p)
	var inner := m
	# child sẽ được add vào margin container
	p.set_meta("inner", inner)
	return p


## StyleBox 9-slice pixel (go-tre): kind = "paper" | "dark" | "slot" | "slot_chon"
func _sb9(kind: String) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	var paths := {
		"paper": "res://assets/ui_pixel/panel_paper_9_x3.png",
		"dark": "res://assets/ui_pixel/panel_dark_9_x3.png",
		"slot": "res://assets/ui_pixel/slot_24_x3.png",
		"slot_chon": "res://assets/ui_pixel/slot_24_chon_x3.png",
	}
	sb.texture = Art.tex(paths[kind])
	var m := 21.0
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


# helper: panel con thêm vào modal đúng chỗ
func _style(bg: Color, radius := 6, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
