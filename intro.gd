extends Node2D

@onready var side_view = $SideView
@onready var top_view = $TopView
@onready var anim_player = $AnimationPlayer
@onready var working_view = $working
@onready var map2 = $map2
@onready var bus = $bus
@onready var map_9 = $map_9

# ---- Lời kể ----
var narration_label: Label
var narration_bg: ColorRect
var skip_button: Button

# ---- Nhạc nền ----
var music_player: AudioStreamPlayer

# Các mốc lời kể: [thời_gian_bắt_đầu, thời_gian_kết_thúc, nội_dung]
# Đồng bộ với animation "intro" (50s) trong intro.tscn
var timeline := [
	[0.0, 4.0, ""],
	# --- CẢNH: Bàn làm việc thành phố (SideView + TopView) ---
	[4.0, 7.0, "Ngày ngày ngồi trước màn hình…\ngiữa bốn bức tường chật chội."],
	# --- CẢNH: Em bé chào đời, lớn lên ---
	[7.0, 10.0, "Chợt nhớ ngày xưa…\ntiếng cười trẻ thơ vang vọng cánh đồng."],
	# --- CẢNH: Nhân vật 5 tuổi ---
	[10.0, 11.5, "Tuổi thơ lớn lên giữa\nlũy tre làng, giếng nước, sân đình."],
	# --- CẢNH: Tốt nghiệp, rời xa quê ---
	[11.5, 14.2, "Lớn lên, rời làng lên phố…\nmang theo bao hoài bão bỏ ngỏ."],
	# --- CẢNH: Màn hình tối (UI hiện) ---
	[14.2, 16.0, ""],
	# --- CẢNH: Làm việc mệt mài (working scene) ---
	[16.0, 20.0, "Bao năm bon chen, áo cơm…\nquay cuồng trong guồng quay vô tận."],
	# --- CẢNH: Bình minh lên (dawn) ---
	[20.0, 22.5, "Rồi một ngày, tôi nhận ra…\nmình khao khát một bình minh khác."],
	# --- CẢNH: Bản đồ (map2) ---
	[22.5, 28.0, "Quyết định gác lại tất cả…\ntrở về nơi mình đã từng bước đi."],
	# --- CẢNH: Xe buýt về quê (bus) ---
	[28.0, 36.0, "Chuyến xe chiều đưa tôi rời phố thị…\ntrở về với tuổi thơ, với làng quê yêu dấu."],
	# --- CẢNH: Chuyển cảnh (UI hiện) ---
	[36.0, 40.0, ""],
	# --- CẢNH: Làng quê hiện ra (map9) ---
	[40.0, 44.0, "Và rồi… làng quê hiện ra.\nYên bình, thân thương như chưa hề xa cách."],
	[44.0, 50.0, "Đất không phụ người chăm…\nMột chương mới bắt đầu."],
]


func _ready():
	_setup_music()
	_setup_narration()
	anim_player.play("intro")
	anim_player.animation_finished.connect(_on_intro_done)
	if side_view:
		side_view.play("working")
	if top_view:
		top_view.play("open")
	if working_view:
		working_view.play("working")
	if map2:
		map2.play("map2")
	if bus:
		bus.play("Bus")
	if map_9:
		map_9.play("map9")


func _setup_narration():
	# CanvasLayer riêng — layer cao (128) để luôn ở trên UI chính, trên Face overlay
	var cl := CanvasLayer.new()
	cl.layer = 128
	add_child(cl)

	# Nền mờ phía sau chữ
	narration_bg = ColorRect.new()
	narration_bg.color = Color(0, 0, 0, 0.5)
	narration_bg.anchor_left = 0.0
	narration_bg.anchor_top = 1.0
	narration_bg.anchor_right = 0.0
	narration_bg.anchor_bottom = 1.0
	narration_bg.offset_left = 6
	narration_bg.offset_top = -115
	narration_bg.offset_right = 370
	narration_bg.offset_bottom = -12
	cl.add_child(narration_bg)

	# Nhãn lời kể
	narration_label = Label.new()
	narration_label.anchor_left = 0.0
	narration_label.anchor_top = 1.0
	narration_label.anchor_right = 0.0
	narration_label.anchor_bottom = 1.0
	narration_label.offset_left = 20
	narration_label.offset_top = -100
	narration_label.offset_right = 360
	narration_label.offset_bottom = -20
	narration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narration_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85, 0.95))
	narration_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	narration_label.add_theme_constant_override("shadow_offset_x", 1)
	narration_label.add_theme_constant_override("shadow_offset_y", 1)
	narration_label.add_theme_font_size_override("font_size", 18)
	narration_label.text = ""
	cl.add_child(narration_label)

	# Nút bỏ qua intro — góc trên bên phải
	skip_button = Button.new()
	skip_button.text = "Bỏ qua ▶"
	skip_button.anchor_left = 1.0
	skip_button.anchor_top = 0.0
	skip_button.anchor_right = 1.0
	skip_button.anchor_bottom = 0.0
	skip_button.offset_left = -120
	skip_button.offset_top = 12
	skip_button.offset_right = -12
	skip_button.offset_bottom = 48
	skip_button.add_theme_color_override("font_color", Color(0.95, 0.85, 0.7, 0.8))
	skip_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	skip_button.add_theme_color_override("font_pressed_color", Color(0.8, 0.7, 0.5, 1))
	skip_button.add_theme_font_size_override("font_size", 16)
	skip_button.add_theme_stylebox_override("normal", _make_skip_sb(Color(0, 0, 0, 0.4)))
	skip_button.add_theme_stylebox_override("hover", _make_skip_sb(Color(0, 0, 0, 0.6)))
	skip_button.add_theme_stylebox_override("pressed", _make_skip_sb(Color(0, 0, 0, 0.7)))
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.pressed.connect(_skip_intro)
	cl.add_child(skip_button)


func _setup_music():
	music_player = AudioStreamPlayer.new()
	music_player.name = "IntroMusic"
	music_player.stream = preload("res://assets/audio/intro_music.mp3")
	music_player.volume_db = -12.0  # hơi nhỏ để không lấn lời kể
	add_child(music_player)
	music_player.play()


func _make_skip_sb(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _process(_delta):
	if not anim_player or not anim_player.is_playing():
		return
	var t: float = anim_player.current_animation_position
	var new_text := ""
	for seg in timeline:
		if t >= seg[0] and t < seg[1]:
			new_text = seg[2]
			break
	if narration_label.text != new_text:
		# reset alpha về 0 trước, nếu có chữ thì fade in
		narration_bg.modulate.a = 0.0
		narration_label.modulate.a = 0.0
		narration_bg.visible = new_text != ""
		narration_label.text = new_text
		if new_text != "":
			var tw := create_tween().set_trans(Tween.TRANS_SINE)
			tw.tween_property(narration_bg, "modulate:a", 1.0, 0.4)
			tw.parallel().tween_property(narration_label, "modulate:a", 1.0, 0.4)


func _on_intro_done(_anim_name: String) -> void:
	# Fade out narration & nhạc rồi chuyển
	var tw := create_tween()
	tw.tween_property(narration_bg, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(narration_label, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(music_player, "volume_db", -80.0, 0.5)
	tw.tween_callback(func():
		music_player.stop()
		get_tree().change_scene_to_file("res://scenes/char_select.tscn"))


func _skip_intro() -> void:
	# Dừng animation, ẩn narration, tắt nhạc, chuyển ngay
	if anim_player and anim_player.is_playing():
		anim_player.stop()
	if music_player and music_player.playing:
		music_player.stop()
	narration_bg.visible = false
	narration_label.text = ""
	skip_button.visible = false
	get_tree().change_scene_to_file("res://scenes/char_select.tscn")
