extends SceneBase
## Sân gạch đỏ trước nhà — Ngày 1 (chiều) & Ngày 2 (sáng sớm).

const GRASS_POS := [
	Vector2(300, 220), Vector2(380, 300), Vector2(340, 420), Vector2(430, 380),
	Vector2(520, 350), Vector2(560, 240), Vector2(620, 300), Vector2(650, 420),
	Vector2(500, 450), Vector2(420, 240),
]

var npc: AnimatedSprite2D
var npc_emote: Sprite2D
var npc_it: Interactable
var yard_trigger_done := false
var gate_emote: Sprite2D


func _build() -> void:
	add_bg("res://assets/maps/san_gach_bg.png")
	add_borders()

	# Nhà của ông ngoại (houses/farmHome.png — ảnh nhà mới)
	var house := Art.sprite(Art.tex("res://assets/art/houses/farmhome.png"), Vector2(480, 248), self)
	house.scale = Vector2(1.5, 1.5)
	house.z_index = 0
	add_wall(Rect2(346, 110, 268, 100))
	var door := Interactable.make(Vector2(480, 256), 46, Hud.ICON_DOOR, self)
	door.activated.connect(_enter_house)

	# Giếng
	Art.sprite(Art.frame("res://assets/art/assets/gieng64x64.png", 0, 64), Vector2(760, 400), self)
	add_wall(Rect2(732, 360, 56, 30))

	# Bụi tre
	for pos in [Vector2(120, 180), Vector2(170, 320), Vector2(880, 200)]:
		var b := Art.sprite(Art.tex("res://assets/art/tree/bui_tre.png"), pos, self)
		b.scale = Vector2(1.5, 1.5)

	# Hàng rào tre dưới + cổng hở giữa
	for x in range(240, 705, 32):
		if x >= 448 and x < 512:
			continue
		Art.sprite(Art.frame("res://assets/ui/hang_rao_tre_32.png", 0, 32), Vector2(x + 16, 612), self)
	add_wall(Rect2(240, 596, 208, 10))
	add_wall(Rect2(512, 596, 194, 10))

	# Cổng rào tre bên trái (sang vườn sau — mở Ngày 2)
	Art.sprite(Art.tex("res://assets/ui/cong_rao_tre_64x48.png"), Vector2(48, 350), self)
	var gate := Interactable.make(Vector2(48, 350), 52, Hud.ICON_HAND, self)
	gate.activated.connect(_use_garden_gate)

	# Cổng dưới quay lại ngõ xóm
	var ngo_gate := Interactable.make(Vector2(480, 622), 42, Hud.ICON_DOOR, self)
	ngo_gate.activated.connect(func():
		GameState.flags["from_san"] = true
		goto_scene("res://scenes/scene_ngo.tscn"))

	# Cỏ dại trên sân (Ngày 1)
	if not GameState.flags.get("grass_day1_done", false):
		for pos in GRASS_POS:
			_spawn_grass(pos)

	# NPC Trưởng Thôn (ẩn tới khi bước vào giữa sân)
	if GameState.day == 1 and not GameState.flags.get("npc_met", false):
		npc = AnimatedSprite2D.new()
		npc.sprite_frames = Art.frames("res://assets/art/characters/truong_thon_64_5f.png", {
			"hut_thuoc": [0, 3, 2, true], "vay_tay": [4, 4, 2, true],
		}, 64)
		npc.offset = Vector2(0, -32)
		npc.position = Vector2(480, 565)
		npc.scale = Vector2(1.15, 1.15)
		npc.play("hut_thuoc")
		add_child(npc)
		npc.visible = false
		npc_it = Interactable.make(Vector2(480, 565), 62, Hud.ICON_HAND, self)
		npc_it.enabled = false
		npc_it.activated.connect(_talk_truong_thon)

	# Vị trí xuất hiện của player
	if GameState.flags.get("from_ngo", false):
		GameState.flags["from_ngo"] = false
		player.position = Vector2(480, 520)
	elif GameState.day == 1:
		player.position = Vector2(480, 330)
	else:
		player.position = Vector2(480, 300)
	hud.set_day_time("Ngày 1 — 15:30" if GameState.day == 1 else "Ngày %d — sáng sớm" % GameState.day)

	GameState.stamina_changed.connect(_tired_tip)


func _after_fade() -> void:
	if GameState.day == 1 and not GameState.flags.get("npc_met", false):
		hud.toast("Sân gạch đỏ của nhà ông ngoại... cỏ mọc um tùm cả rồi.")
	elif GameState.day == 2 and not GameState.flags.get("garden_seen", false):
		hud.toast("Ò ó o o...! Trời còn tờ mờ sáng. Bên trái sân hình như có cánh cổng?")
		gate_emote = add_emote(Vector2(48, 300))


func _process(delta: float) -> void:
	super._process(delta)
	# Trigger: bước tới giữa sân → Trưởng Thôn xuất hiện ngoài cổng
	if GameState.day == 1 and not yard_trigger_done and npc \
			and not GameState.flags.get("npc_met", false) \
			and player.position.distance_to(Vector2(480, 380)) < 80:
		yard_trigger_done = true
		npc.visible = true
		npc_emote = add_emote(Vector2(480, 495))
		npc_it.enabled = true
		hud.toast("Có ai vừa bước vào cổng sân kìa!")


# ---------- Cỏ dại ----------
func _spawn_grass(pos: Vector2) -> void:
	var g := Art.sprite(Art.tex("res://assets/art/tree/tall_grass_32.png"), pos, self)
	g.scale = Vector2(1.5, 1.5)
	var it := Interactable.make(pos, 44, Hud.ICON_CUT, self)
	it.activated.connect(func(): _cut_grass(g, it))


func _cut_grass(g: Sprite2D, it: Interactable) -> void:
	if not GameState.has_item("liem"):
		hud.toast("Cỏ cứng quá, tay không nhổ chẳng nổi. Cần một cái liềm...")
		return
	if GameState.is_exhausted():
		hud.toast("Bạn quá đói để làm việc này!")
		return
	it.enabled = false
	GameState.use_stamina(12)
	await player.swing_tool(Art.frame("res://assets/art/assets/liem_32x32.png", 0, 32))
	var tw := create_tween()
	tw.tween_property(g, "scale", Vector2(0.1, 0.1), 0.15)
	tw.tween_callback(g.queue_free)
	var stubble := Art.sprite(Art.frame("res://assets/ui_pixel/co_3_trang_thai_32.png", 1, 32), g.position, self)
	stubble.scale = Vector2(1.5, 1.5)
	stubble.z_index = -4
	stubble.y_sort_enabled = false
	fly_item(Art.frame("res://assets/ui/item_chiakhoa_codai_16.png", 1, 16), g.position, "co_dai")
	interactables.erase(it)
	it.queue_free()
	GameState.quest_progress(0)
	if GameState.quest_step_done(0) and not GameState.flags.get("grass_day1_done", false):
		GameState.flags["grass_day1_done"] = true
		hud.set_day_time("Ngày 1 — 18:30")
		hud.toast("Sân sạch bong! Trời chập choạng tối rồi, vào nhà thôi.")


func _tired_tip(_v: float) -> void:
	if GameState.day == 1 and GameState.is_tired() and not GameState.is_exhausted() \
			and not GameState.flags.get("tired_tip", false) \
			and GameState.flags.get("npc_met", false):
		GameState.flags["tired_tip"] = true
		hud.dialog([["", "Thể lực suy kiệt! Hãy bấm Ô TRÒN XANH (góc phải dưới) để ăn Bánh Phu Thê hồi sức."]])


# ---------- NPC Trưởng Thôn ----------
func _talk_truong_thon() -> void:
	npc_it.enabled = false
	if npc_emote:
		npc_emote.queue_free()
		npc_emote = null
	await hud.dialog([
		["Ông Trưởng Thôn", "Ô kìa! Thằng cháu nhà ông Bảy về rồi đấy à? Nghe bọn trẻ hò reo ngoài ngõ là tao đoán ngay. Lâu lắm mới thấy cái sân này có bóng người!"],
		[GameState.player_name, "Cháu chào bác ạ. Cháu vừa qua chào bố mẹ cháu xong, giờ sang dọn nhà ông ngoại ở tạm."],
		["Ông Trưởng Thôn", "Mặt mũi nhợt nhạt thế kia, chắc lại ngồi máy tính nhiều chứ gì. Mà cái sân gạch này rậm rạp quá rồi — cầm lấy cái liềm cùn này mà dọn dẹp lấy lối đi lại."],
	])
	give_items([["liem", 1]])
	await hud.dialog([
		["Ông Trưởng Thôn", "Dọn cỏ mệt đấy, đói thì ăn tạm cái bánh mẹ mày đưa. Xong xuôi thì vào nhà nghỉ sớm — tối ở quê nhiều muỗi lắm. Mai tao qua xem tình hình."],
	])
	GameState.flags["npc_met"] = true
	npc.play("vay_tay")
	get_tree().create_timer(1.6).timeout.connect(func():
		if is_instance_valid(npc):
			npc.play("hut_thuoc"))
	GameState.start_quest("VIỆC ĐẦU TIÊN", [["Dọn cỏ sân gạch", 10], ["Sửa cầu dao điện", 1]])
	hud.toast("Nhận nhiệm vụ mới! (xem góc phải trên)")
	hud.set_day_time("Ngày 1 — 15:30")


# ---------- Cửa nhà & cổng vườn ----------
func _enter_house() -> void:
	if not GameState.has_item("chia_khoa"):
		hud.toast("Cửa khóa chặt. Chắc phải hỏi ai đó quanh đây...")
		return
	if npc and is_instance_valid(npc) and npc.visible:
		var tw := create_tween()
		tw.tween_property(npc, "modulate:a", 0.0, 0.8)
	goto_scene("res://scenes/scene_nha.tscn")


func _use_garden_gate() -> void:
	if GameState.day == 1:
		hud.toast("Cổng rào tre xộc xệch dẫn ra sau nhà... Trời tối rồi, mai hẵng khám phá.")
		return
	if gate_emote and is_instance_valid(gate_emote):
		gate_emote.queue_free()
	GameState.flags["garden_seen"] = true
	goto_scene("res://scenes/scene_vuon.tscn")
