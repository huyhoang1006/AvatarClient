extends SceneBase
## Mảnh vườn sau nhà — trung tâm farming Ngày 2→5:
##  Ngày 2: Cô Lan cho đồ nghề, trồng 5 ô cải (quest MẢNH VƯỜN CỦA ÔNG)
##  Ngày 3: Trưởng Thôn ghé xem — sửa CHUỒNG GÀ, nhận 2 gà con, tưới rau
##  Ngày 4: cho gà ăn gạo nếp (+ bếp trong nhà), tưới rau
##  Ngày 5: nhặt TRỨNG, hái 5 CẢI CHÍN, minigame LẮC BÌNH THÔNG VÒI,
##          ngâm thóc ở chum, gieo rau muống + thóc vào 8 ô, tưới hết
## Trạng thái ruộng nằm trong GameState.farm (bền vững qua ngày).

const WEED_POS := [
	Vector2(350, 300), Vector2(420, 260), Vector2(500, 300), Vector2(580, 270),
	Vector2(380, 420), Vector2(460, 450), Vector2(560, 420), Vector2(640, 350),
	Vector2(320, 360), Vector2(610, 460),
]
# 8 ô ruộng: 5 ô hàng trên (mở Ngày 2) + 3 ô hàng dưới (mở Ngày 5)
const CELL_POS := [
	Vector2(400, 350), Vector2(448, 350), Vector2(496, 350), Vector2(544, 350), Vector2(592, 350),
	Vector2(424, 398), Vector2(472, 398), Vector2(520, 398),
]
const STAM_WEED := 6.0
const STAM_HOE := 12.0
const STAM_PLANT := 2.0
const STAM_WATER := 3.0

var cell_nodes := []        # [{dat: Sprite2D, cay: Sprite2D, it: Interactable}]
var colan: AnimatedSprite2D
var truong_thon: AnimatedSprite2D
var tt_emote: Sprite2D
var chuong: Sprite2D
var chuong_it: Interactable
var binh_ong: Sprite2D      # bình tưới của ông (Ngày 5, tắc vòi)


func _build() -> void:
	add_bg("res://assets/maps/vuon_bg.png")
	add_borders()

	# Cổng về sân (mép trên)
	Art.sprite(Art.tex("res://assets/ui/cong_rao_tre_64x48.png"), Vector2(480, 52), self)
	var gate := Interactable.make(Vector2(480, 60), 52, Hud.ICON_DOOR, self)
	gate.activated.connect(func(): goto_scene("res://scenes/scene_san.tscn"))

	# Biển gỗ ông ngoại
	Art.sprite(Art.tex("res://assets/ui/bien_go_ong_ngoai_32x48.png"), Vector2(310, 260), self).scale = Vector2(1.4, 1.4)
	var sign := Interactable.make(Vector2(310, 265), 46, Hud.ICON_HAND, self)
	sign.activated.connect(_read_sign)
	if GameState.day == 2 and not GameState.flags.get("sign_read", false):
		add_emote(Vector2(310, 200))

	# Đá tảng + gỗ mục
	for e in [[0, Vector2(700, 260)], [1, Vector2(340, 500)], [0, Vector2(650, 520)], [1, Vector2(750, 380)]]:
		var pr := Art.sprite(Art.frame("res://assets/ui/prop_vuon_da_go_32.png", e[0], 32), e[1], self)
		pr.scale = Vector2(1.5, 1.5)

	# Giếng + chum nước ngâm thóc
	Art.sprite(Art.frame("res://assets/art/assets/gieng64x64.png", 0, 64), Vector2(800, 480), self)
	add_wall(Rect2(772, 440, 56, 30))
	var well := Interactable.make(Vector2(800, 490), 56, Hud.ICON_WATER, self)
	well.activated.connect(_fill_can)
	Art.sprite(Art.frame("res://assets/art/assets/chum_nuoc.png", 0, 64), Vector2(722, 500), self)
	var chum_it := Interactable.make(Vector2(722, 505), 46, Hud.ICON_HAND, self)
	chum_it.activated.connect(_ngam_thoc)

	# Chuồng gà: xập xệ -> cải tạo sau Ngày 3
	var chuong_ok: bool = GameState.flags.get("chuong_ok", false)
	chuong = Art.sprite(Art.frame(
		"res://assets/art/chuong_chuong_ga/chuong_ga_duoc_cai_tao_64x64.png" if chuong_ok
		else "res://assets/art/chuong_chuong_ga/chuong_ga_sap_xe_64x64.png", 0, 64), Vector2(850, 230), self)
	chuong.scale = Vector2(1.4, 1.4)
	add_wall(Rect2(810, 170, 80, 50))
	chuong_it = Interactable.make(Vector2(850, 240), 52, Hud.ICON_HAND, self)
	chuong_it.activated.connect(_dung_chuong)

	# Gà con chạy quanh vườn (sau khi sửa chuồng)
	if chuong_ok:
		_spawn_ga(Vector2(820, 300))
		_spawn_ga(Vector2(880, 330))

	# Trứng chờ nhặt (sáng hôm sau khi cho gà ăn đủ)
	if GameState.flags.get("trung_cho", false) and not GameState.flags.get("trung_da_nhat", false):
		var trung := Art.sprite(Art.tex("res://assets/ui_pixel/trung_16.png"), Vector2(812, 280), self)
		trung.scale = Vector2(1.6, 1.6)
		add_emote(Vector2(812, 250))
		var trung_it := Interactable.make(Vector2(812, 285), 46, Hud.ICON_HAND, self)
		trung_it.activated.connect(func():
			GameState.flags["trung_da_nhat"] = true
			GameState.flags["trung_cho"] = false
			trung.queue_free()
			trung_it.enabled = false
			give_items([["trung", 2]])
			hud.toast("Gà nhà đẻ trứng rồi!! Công cho ăn gạo nếp không uổng 🥚"))

	# Cỏ dại: Ngày 2 đủ 10 bụi; từ Ngày 3 mỗi ngày mọc lại 6 bụi (nguyên liệu + đồ ăn)
	if GameState.day == 2:
		if not GameState.flags.get("garden_weeds_done", false):
			for pos in WEED_POS:
				_spawn_weed(pos)
	elif not GameState.flags.get("weeds_d%d" % GameState.day, false):
		GameState.flags["weeds_d%d" % GameState.day] = true
		GameState.flags["weeds_d%d_alive" % GameState.day] = 6
	if GameState.day >= 3 and int(GameState.flags.get("weeds_d%d_alive" % GameState.day, 0)) > 0:
		for i in range(int(GameState.flags.get("weeds_d%d_alive" % GameState.day, 0))):
			_spawn_weed(WEED_POS[i % WEED_POS.size()] + Vector2(randf_range(-14, 14), randf_range(-10, 10)))

	# 8 ô ruộng từ GameState.farm
	for i in range(CELL_POS.size()):
		_spawn_cell(i)
	_refresh_cells()

	# NPC theo ngày
	if GameState.day == 3 and not GameState.flags.get("ngay3_intro", false):
		_spawn_truong_thon(Vector2(760, 270))
	elif GameState.day == 5 and not GameState.flags.get("ngay5_intro", false):
		_spawn_truong_thon(Vector2(380, 280))

	player.position = Vector2(480, 120)
	hud.set_day_time("Ngày %d — buổi sáng" % GameState.day)
	hud.update_water()

	# vào lại vườn khi quest CHUỒNG GÀ đang chạy -> đồng bộ lại bộ đếm cỏ
	if GameState.day == 3 and not GameState.quest.is_empty() 			and str(GameState.quest.get("title", "")) == "CHUỒNG GÀ CŨ":
		GameState.inventory_changed.connect(_dem_co_lam_o)
		_dem_co_lam_o()


func _after_fade() -> void:
	match GameState.day:
		2:
			if not GameState.flags.get("garden_intro", false):
				GameState.flags["garden_intro"] = true
				hud.toast("Mảnh vườn rộng ngập cỏ dại, đá tảng và gỗ mục...")
				await get_tree().create_timer(1.4).timeout
				hud.toast("Góc vườn có tấm biển gỗ bám rêu. Lại gần xem thử?")
		3:
			if truong_thon:
				hud.toast("Ông Trưởng Thôn đứng cạnh cái chuồng gà cũ từ bao giờ!")
		5:
			if GameState.flags.get("trung_cho", false):
				hud.toast("Sáng Ngày 5! Nghe tiếng gà cục ta cục tác rộn cả chuồng...")
			elif truong_thon:
				hud.toast("Ông Trưởng Thôn lại ghé, tay xách theo cái gì kia...")


# ============================================================
#  NPC TRƯỞNG THÔN (Ngày 3 & Ngày 5)
# ============================================================
func _spawn_truong_thon(pos: Vector2) -> void:
	truong_thon = AnimatedSprite2D.new()
	truong_thon.sprite_frames = Art.frames("res://assets/art/characters/truong_thon_64_5f.png", {
		"hut_thuoc": [0, 3, 2, true], "vay_tay": [4, 4, 2, true],
	}, 64)
	truong_thon.offset = Vector2(0, -32)
	truong_thon.position = pos
	truong_thon.scale = Vector2(1.15, 1.15)
	truong_thon.play("hut_thuoc")
	add_child(truong_thon)
	tt_emote = add_emote(pos + Vector2(0, -75))
	var it := Interactable.make(pos, 66, Hud.ICON_HAND, self)
	it.activated.connect(_talk_truong_thon)


func _talk_truong_thon() -> void:
	if tt_emote and is_instance_valid(tt_emote):
		tt_emote.queue_free()
		tt_emote = null
	if GameState.day == 3 and not GameState.flags.get("ngay3_intro", false):
		GameState.flags["ngay3_intro"] = true
		await hud.dialog([
			["Ông Trưởng Thôn", "Đấy! Tao bảo mai tao qua là tao qua. Ơ hơ, vườn tược ra dáng phết rồi đấy thằng cu!"],
			["Ông Trưởng Thôn", "Mà này, cái chuồng gà của ông mày sập xệ quá thể. Sửa lại đi — tao thấy nhà bà Sáu có đàn gà con mới nở, tao xin cho mày một đôi."],
			[GameState.player_name, "Sửa chuồng thì cháu cần gì hả bác?"],
			["Ông Trưởng Thôn", "Gom lấy 10 nắm cỏ khô mà lót ổ, xong lấy búa gõ lại mấy tấm ván. Cỏ thì đầy vườn, chém là có. Nhanh tay lên, gà không chờ được lâu đâu!"],
		])
		GameState.start_quest("CHUỒNG GÀ CŨ", [
			["Gom cỏ dại làm ổ (có trong túi)", 10],
			["Sửa lại chuồng gà", 1],
			["Tưới 5 luống cải", 5],
		])
		GameState.inventory_changed.connect(_dem_co_lam_o)
		_dem_co_lam_o()
		hud.toast("Nhận nhiệm vụ: CHUỒNG GÀ CŨ!")
	elif GameState.day == 5 and not GameState.flags.get("ngay5_intro", false):
		GameState.flags["ngay5_intro"] = true
		await hud.dialog([
			["Ông Trưởng Thôn", "Chà chà! Cải nhà mày lên xanh mởn rồi kìa, hái được rồi đấy! Đúng là 'đất không phụ người chăm' — y lời ông ngoại mày."],
			["Ông Trưởng Thôn", "Hôm nay tao mang cho mày cái này... Bình tưới CỦA ÔNG NGOẠI MÀY đấy. Ông gửi tao giữ trước khi mất. Mà lâu quá vòi nó két đất, tắc tịt rồi."],
			[GameState.player_name, "Bình của ông... Cháu cảm ơn bác. Để cháu thông lại vòi ạ."],
			["Ông Trưởng Thôn", "Lắc theo nhịp tao chỉ là thông! Với cầm thêm nắm hạt rau muống với vốc thóc giống này. Thóc nhớ NGÂM vào chum nước trước — 'ba sôi hai lạnh' nghe con!"],
		])
		give_items([["hat_muong", 5], ["thoc_giong", 3]])
		GameState.start_quest("LUỐNG RAU ĐẦU TIÊN", [
			["Hái 5 cây cải chín", 5],
			["Thông vòi bình tưới của ông (minigame)", 1],
			["Ngâm thóc ở chum nước", 1],
			["Gieo rau muống + thóc (8 ô)", 8],
			["Tưới nước cả 8 ô", 8],
		])
		hud.toast("Nhận nhiệm vụ: LUỐNG RAU ĐẦU TIÊN!")
		# đặt bình tưới của ông xuống đất cạnh trưởng thôn
		binh_ong = Art.sprite(Art.frame("res://assets/art/assets/binh_nuoc_tuoi_cay.png", 0, 32), Vector2(340, 320), self)
		binh_ong.scale = Vector2(1.6, 1.6)
		add_emote(Vector2(340, 285))
		var bit := Interactable.make(Vector2(340, 325), 48, Hud.ICON_HAND, self)
		bit.activated.connect(func(): _mo_minigame_binh(bit))
	else:
		var loi := "Gà con nuôi khéo vào, lớn đẻ trứng ăn không hết đâu!" if GameState.day == 3 \
			else "Lắc cái bình cho thông vòi đi, rồi gieo hết chỗ hạt tao đưa nhé!"
		await hud.dialog([["Ông Trưởng Thôn", loi]])


func _dem_co_lam_o() -> void:
	# bước "gom 10 cỏ": đồng bộ theo số cỏ trong túi
	if GameState.day == 3 and not GameState.quest.is_empty() \
			and str(GameState.quest.get("title", "")) == "CHUỒNG GÀ CŨ":
		var have: int = mini(int(GameState.inventory.get("co_dai", 0)), 10)
		GameState.quest["steps"][0]["have"] = have
		GameState.quest_changed.emit()


# ============================================================
#  CHUỒNG GÀ (sửa Ngày 3 — cho ăn Ngày 4+)
# ============================================================
func _dung_chuong() -> void:
	if not GameState.flags.get("chuong_ok", false):
		if GameState.day < 3:
			hud.dialog([["", "Cửa chuồng kẹt cứng. Có lẽ mình nên dọn sạch khu này trước, biết đâu vài hôm nữa lại có việc dùng đến."]])
			return
		if GameState.quest.is_empty() or str(GameState.quest.get("title", "")) != "CHUỒNG GÀ CŨ":
			hud.toast("Chuồng gà cũ của ông... hỏi ông Trưởng Thôn xem sửa thế nào.")
			return
		if int(GameState.inventory.get("co_dai", 0)) < 10:
			hud.toast("Chưa đủ 10 cỏ làm ổ! Chém thêm cỏ mọc quanh vườn đi.")
			return
		if GameState.is_exhausted():
			hud.toast("Bạn quá đói để làm việc này!")
			return
		GameState.remove_item("co_dai", 10)
		GameState.use_stamina(15)
		await player.swing_tool(Art.frame("res://assets/art/assets/bua_32x32.png", 0, 32))
		hud.flash(Color(0.9, 0.8, 0.5), 0.3)
		chuong.texture = Art.frame("res://assets/art/chuong_chuong_ga/chuong_ga_duoc_cai_tao_64x64.png", 0, 64)
		GameState.flags["chuong_ok"] = true
		GameState.quest_progress(1)
		hud.toast("Cạch cạch cạch... Chuồng gà như mới! 🐔")
		_spawn_ga(Vector2(820, 300))
		_spawn_ga(Vector2(880, 330))
		await hud.dialog([
			["Ông Trưởng Thôn", "Được được! Đây, đôi gà con nhà bà Sáu. Cho nó ăn GẠO NẾP là nhanh lớn nhất — hình như trong rương của ông mày còn thì phải?"],
		])
		_check_ngay_done()
	else:
		# chuồng đã sửa: cho gà ăn (Ngày 4+)
		if GameState.day < 4:
			hud.toast("Đôi gà con rúc vào ổ cỏ mới, kêu chiêm chiếp. Cưng phết!")
			return
		var fed: int = int(GameState.flags.get("ga_fed", 0))
		if fed >= 2:
			hud.toast("Gà no căng diều rồi. Mai chắc chắn có trứng!")
			return
		if not GameState.has_item("gao_nep"):
			hud.toast("Hết gạo nếp cho gà... (rương của ông có đấy)")
			return
		GameState.remove_item("gao_nep")
		GameState.flags["ga_fed"] = fed + 1
		hud.toast("Rắc gạo nếp... đôi gà mổ lấy mổ để! (%d/2)" % (fed + 1))
		if GameState.day == 4 and not GameState.quest.is_empty():
			GameState.quest_progress(2)
			_check_ngay_done()


func _spawn_ga(pos: Vector2) -> void:
	var ga := AnimatedSprite2D.new()
	ga.sprite_frames = Art.frames("res://assets/art/animals_ga_co/ga_trong_32x32.png", {"idle": [0, 2, 4, true]}, 32)
	ga.position = pos
	ga.offset = Vector2(0, -16)
	ga.scale = Vector2(1.1, 1.1)
	ga.play("idle")
	add_child(ga)
	_ga_wander(ga, pos)


func _ga_wander(ga: AnimatedSprite2D, home: Vector2) -> void:
	# gà lon ton loanh quanh chuồng
	var tw := ga.create_tween().set_loops()
	for i in range(4):
		var dest := home + Vector2(randf_range(-50, 50), randf_range(-30, 40))
		tw.tween_property(ga, "position", dest, randf_range(1.2, 2.2))
		tw.tween_interval(randf_range(0.4, 1.2))


# ============================================================
#  MINIGAME LẮC BÌNH (Ngày 5)
# ============================================================
func _mo_minigame_binh(bit: Interactable) -> void:
	if GameState.flags.get("binh_thong", false):
		return
	player.busy = true
	hud.modal_open = true
	var mg := preload("res://scenes/minigame_lac_binh.gd").new()
	add_child(mg)
	mg.solved.connect(func(stars: int):
		player.busy = false
		hud.modal_open = false
		GameState.flags["binh_thong"] = true
		GameState.water_max = 8
		GameState.quest_progress(1)
		bit.enabled = false
		if binh_ong:
			binh_ong.queue_free()
		hud.update_water()
		hud.flash(Color(0.5, 0.8, 1.0), 0.5)
		hud.toast("BỤP! Vòi thông rồi — bình của ông chứa được 8 nước! %s" % "⭐".repeat(stars))
		_check_ngay_done())
	mg.closed.connect(func():
		player.busy = false
		hud.modal_open = false)


func _ngam_thoc() -> void:
	if GameState.day < 5 or GameState.quest.is_empty() \
			or str(GameState.quest.get("title", "")) != "LUỐNG RAU ĐẦU TIÊN":
		hud.toast("Chum nước mưa trong vắt của ông ngoại.")
		return
	if GameState.flags.get("thoc_ngam", false):
		hud.toast("Thóc ngâm đủ rồi, đem gieo được luôn!")
		return
	if not GameState.has_item("thoc_giong"):
		hud.toast("Chưa có thóc giống để ngâm.")
		return
	GameState.flags["thoc_ngam"] = true
	GameState.quest_progress(2)
	hud.toast("Ngâm thóc 'ba sôi hai lạnh'... Thóc căng mẩy, sẵn sàng nảy mầm!")
	_check_ngay_done()


# ============================================================
#  CỎ DẠI
# ============================================================
func _spawn_weed(pos: Vector2) -> void:
	var g := Art.sprite(Art.tex("res://assets/art/tree/tall_grass_32.png"), pos, self)
	g.scale = Vector2(1.4, 1.4)
	g.modulate = Color(0.9, 1.0, 0.85)
	var it := Interactable.make(pos, 42, Hud.ICON_CUT, self)
	it.activated.connect(func(): _cut_weed(g, it))


func _cut_weed(g: Sprite2D, it: Interactable) -> void:
	if GameState.day == 2 and GameState.quest.is_empty():
		hud.toast("Khoan đã... xem tấm biển gỗ kia trước đã.")
		return
	if not GameState.has_item("liem"):
		hud.toast("Cần liềm để dọn cỏ!")
		return
	if GameState.is_exhausted():
		hud.toast("Bạn quá đói để làm việc này!")
		return
	it.enabled = false
	GameState.use_stamina(STAM_WEED)
	await player.swing_tool(Art.frame("res://assets/art/assets/liem_32x32.png", 0, 32))
	var tw := create_tween()
	tw.tween_property(g, "scale", Vector2(0.1, 0.1), 0.15)
	tw.tween_callback(g.queue_free)
	var stubble := Art.sprite(Art.frame("res://assets/ui_pixel/co_3_trang_thai_32.png", 1, 32), g.position, self)
	stubble.scale = Vector2(1.4, 1.4)
	stubble.z_index = -4
	stubble.y_sort_enabled = false
	fly_item(Art.frame("res://assets/ui/item_chiakhoa_codai_16.png", 1, 16), g.position, "co_dai")
	interactables.erase(it)
	it.queue_free()
	if GameState.day >= 3:
		var key := "weeds_d%d_alive" % GameState.day
		GameState.flags[key] = maxi(int(GameState.flags.get(key, 0)) - 1, 0)
	if GameState.day == 2:
		GameState.quest_progress(0)
		if GameState.quest_step_done(0):
			GameState.flags["garden_weeds_done"] = true
		_check_ngay_done()


# ============================================================
#  8 Ô RUỘNG (đọc/ghi GameState.farm)
# ============================================================
func _spawn_cell(i: int) -> void:
	var pos: Vector2 = CELL_POS[i]
	var dat := Sprite2D.new()
	dat.position = pos
	dat.scale = Vector2(1.5, 1.5)
	dat.z_index = -5
	dat.y_sort_enabled = false
	add_child(dat)
	var cay := Sprite2D.new()
	cay.position = pos + Vector2(0, -6)
	cay.scale = Vector2(1.3, 1.3)
	add_child(cay)
	var it := Interactable.make(pos, 40, Hud.ICON_HAND, self)
	it.activated.connect(func(): _dung_o(i))
	cell_nodes.append({"dat": dat, "cay": cay, "it": it})


## vẽ lại toàn bộ ô ruộng theo GameState.farm
func _refresh_cells() -> void:
	for i in range(cell_nodes.size()):
		var cell: Dictionary = GameState.farm[i]
		var n: Dictionary = cell_nodes[i]
		var dat: Sprite2D = n["dat"]
		var cay: Sprite2D = n["cay"]
		if not bool(cell["tilled"]):
			dat.visible = false
			cay.visible = false
			continue
		dat.visible = true
		dat.texture = Art.frame("res://assets/ui/ruong_4_trang_thai_32.png", 2 if bool(cell["watered"]) else 1, 32)
		var loai := str(cell["type"])
		if loai == "":
			cay.visible = false
			continue
		cay.visible = true
		var stage := int(cell["stage"])
		if loai == "cai":
			if stage <= 0:
				cay.texture = Art.frame("res://assets/art/farmmap/hat_giong.png", 5, 32)   # mầm
			else:
				cay.texture = Art.frame("res://assets/art/tree/cay_cai_ngot.png", mini(stage - 1, 2), 32)
		elif loai == "muong":
			cay.texture = Art.frame("res://assets/art/farmmap/hat_giong.png", 5, 32)
			cay.modulate = Color(0.75, 1.0, 0.75)
		elif loai == "thoc":
			cay.texture = Art.frame("res://assets/art/tree/thoc_giong_32x32.png", 1, 32)


## bước tưới của quest hôm nay nằm ở index nào
func _tuoi_step() -> int:
	match GameState.day:
		2: return 3
		3: return 2
		4: return 3
		5: return 4
	return -1


func _dung_o(i: int) -> void:
	var cell: Dictionary = GameState.farm[i]
	# 3 ô hàng dưới khoá tới Ngày 5
	if i >= 5 and GameState.day < 5:
		hud.toast("Dải đất này cứng khô nứt nẻ... chưa vội, làm 5 ô trên trước.")
		return
	if GameState.day == 2 and GameState.quest.is_empty():
		hud.toast("Xem tấm biển gỗ ở góc vườn trước đã...")
		return

	# ---- 1. CHƯA CUỐC ----
	if not bool(cell["tilled"]):
		if not GameState.has_item("cuoc_chim"):
			hud.toast("Đất cứng lắm, cần một cái cuốc.")
			return
		if GameState.is_exhausted():
			hud.toast("Bạn quá đói để làm việc này!")
			return
		GameState.use_stamina(STAM_HOE)
		await player.swing_tool(Art.frame("res://assets/art/assets/cuoc_chim.png", 0, 32))
		cell["tilled"] = true
		hud.flash(Color(0.8, 0.6, 0.3), 0.12, 0.15)
		if GameState.day == 2:
			GameState.quest_progress(1)
		_refresh_cells()
		return

	var loai := str(cell["type"])

	# ---- 2. ĐẤT TRỐNG ĐÃ CUỐC -> GIEO ----
	if loai == "":
		if GameState.day == 2 or GameState.day == 3 or GameState.day == 4:
			if not GameState.has_item("hat_cai"):
				hud.toast("Hết hạt cải rồi!")
				return
			GameState.remove_item("hat_cai")
			GameState.use_stamina(STAM_PLANT)
			await player.swing_tool(Art.frame("res://assets/art/farmmap/hat_giong.png", 0, 32))
			cell["type"] = "cai"
			cell["stage"] = 0
			if GameState.day == 2:
				GameState.quest_progress(2)
		elif GameState.day >= 5:
			# ô 0-4 gieo rau muống, ô 5-7 gieo thóc (đã ngâm)
			if i < 5:
				if not GameState.has_item("hat_muong"):
					hud.toast("Hết hạt rau muống!")
					return
				GameState.remove_item("hat_muong")
				cell["type"] = "muong"
			else:
				if not GameState.flags.get("thoc_ngam", false):
					hud.toast("Thóc phải NGÂM ở chum nước trước đã ('ba sôi hai lạnh' mà)!")
					return
				if not GameState.has_item("thoc_giong"):
					hud.toast("Hết thóc giống!")
					return
				GameState.remove_item("thoc_giong")
				cell["type"] = "thoc"
			GameState.use_stamina(STAM_PLANT)
			await player.swing_tool(Art.frame("res://assets/art/farmmap/hat_giong.png", 0, 32))
			cell["stage"] = 0
			GameState.quest_progress(3)
		_refresh_cells()
		_check_ngay_done()
		return

	# ---- 3. CẢI CHÍN (Ngày 5) -> HÁI ----
	if loai == "cai" and int(cell["stage"]) >= 3 and GameState.day >= 5:
		GameState.use_stamina(2)
		fly_item(Art.frame("res://assets/art/tree/cay_cai_ngot.png", 2, 32), CELL_POS[i], "rau_cai")
		cell["type"] = ""
		cell["stage"] = 0
		cell["watered"] = false
		GameState.quest_progress(0)
		hud.toast("Hái cải ngọt! Cây nhà lá vườn chính hiệu 🌱")
		_refresh_cells()
		_check_ngay_done()
		return

	# ---- 4. CÓ CÂY -> TƯỚI ----
	if not bool(cell["watered"]):
		if not GameState.has_item("binh_tuoi"):
			hud.toast("Cần bình tưới nước.")
			return
		if GameState.water <= 0:
			hud.toast("Bình cạn khô! Ra GIẾNG múc nước đã.")
			return
		if GameState.is_exhausted():
			hud.toast("Bạn quá đói để làm việc này!")
			return
		GameState.water -= 1
		hud.update_water()
		GameState.use_stamina(STAM_WATER)
		await player.swing_tool(Art.frame("res://assets/art/assets/binh_nuoc_nghieng.png", 2, 32))
		cell["watered"] = true
		var b := _tuoi_step()
		if b >= 0:
			GameState.quest_progress(b)
		_refresh_cells()
		_check_ngay_done()
	else:
		match loai:
			"cai":
				hud.toast("Cải tưới rồi, đang lớn từng ngày. Mai lại tưới tiếp nhé!")
			"muong":
				hud.toast("Rau muống gieo hôm nay, dăm bữa là bò kín luống!")
			"thoc":
				hud.toast("Thóc đã gieo... vụ lúa đầu tiên của mình bắt đầu từ đây.")


func _fill_can() -> void:
	if not GameState.has_item("binh_tuoi"):
		hud.toast("Giếng nước trong veo... nhưng chưa có gì để múc.")
		return
	GameState.water = GameState.water_max
	hud.update_water()
	hud.toast("Thả gàu múc nước... Bình đầy! 💧 %d/%d" % [GameState.water, GameState.water_max])


# ============================================================
#  CÔ LAN + BIỂN GỖ (Ngày 2 — giữ nguyên flow cũ)
# ============================================================
func _read_sign() -> void:
	await hud.dialog([["", "Tấm biển gỗ bám rêu, nét chữ khắc đã mòn:\n\"Đất không phụ người chăm\" — Ông Ngoại."]])
	if GameState.day != 2 or GameState.flags.get("sign_read", false):
		return
	GameState.flags["sign_read"] = true
	await get_tree().create_timer(0.6).timeout
	_colan_arrives()


func _colan_arrives() -> void:
	hud.toast("Bíp bíp!! 🛵 Có tiếng còi xe máy ngoài cổng!")
	colan = AnimatedSprite2D.new()
	colan.sprite_frames = Art.frames("res://assets/art/people/co_lan.png", {
		"walk": [0, 4, 8, true], "idle": [0, 0, 5, true],
	}, 64)
	colan.position = Vector2(480, 70)
	colan.offset = Vector2(0, -32)
	add_child(colan)
	colan.play("walk")
	var target := player.position + Vector2(56, 0)
	player.busy = true
	var tw := create_tween()
	tw.tween_property(colan, "position", target, 1.6)
	await tw.finished
	colan.play("idle")
	player.busy = false
	await hud.dialog([
		["Cô Lan", "Trời đất ơi, thằng cháu nhà ông Bảy nay lớn tồng ngồng thế này rồi à! Mới sáng sớm đã ra ngắm đất rồi, tính làm nông dân giống ông ngoại mày hả?"],
		[GameState.player_name, "Dạ cháu chào cô. Vườn bỏ hoang phí quá nên cháu tính dọn lại trồng ít rau ạ."],
		["Cô Lan", "Đất nhà mày là đất thịt, tốt lắm đấy. Ngày xưa ông ngoại mày trồng rau xanh mướt cả làng ra xin. Đây, cô cho cái Cuốc, cái Bình tưới cũ với mấy hạt cải ngọt. Trồng thử xem có mát tay không!"],
	])
	give_items([["cuoc_chim", 1], ["binh_tuoi", 1], ["hat_cai", 5]])
	GameState.start_quest("MẢNH VƯỜN CỦA ÔNG", [
		["Dọn cỏ dại trong vườn", 10],
		["Cuốc đất tơi xốp", 5],
		["Trồng hạt Cải Ngọt", 5],
		["Tưới nước luống rau", 5],
	])
	hud.toast("Nhận nhiệm vụ: MẢNH VƯỜN CỦA ÔNG!")
	hud.set_day_time("Ngày 2 — 06:30")
	hud.update_water()
	colan.play("walk")
	colan.flip_h = true
	var tw2 := create_tween()
	tw2.tween_property(colan, "position", Vector2(480, 60), 1.6)
	tw2.parallel().tween_property(colan, "modulate:a", 0.0, 1.6)
	tw2.tween_callback(colan.queue_free)


# ============================================================
#  HOÀN THÀNH NGÀY
# ============================================================
func _check_ngay_done() -> void:
	if not GameState.quest_done():
		return
	match GameState.day:
		2:
			if not GameState.flags.get("garden_done", false):
				GameState.flags["garden_done"] = true
				hud.set_day_time("Ngày 2 — 12:00")
				hud.toast("MẢNH VƯỜN CỦA ÔNG: Hoàn thành! Về nhà kiếm gì ăn rồi nghỉ thôi.")
		3:
			if not GameState.flags.get("ngay3_done", false):
				GameState.flags["ngay3_done"] = true
				if truong_thon and is_instance_valid(truong_thon):
					truong_thon.play("vay_tay")
					var tw := create_tween()
					tw.tween_interval(1.2)
					tw.tween_property(truong_thon, "modulate:a", 0.0, 1.0)
				hud.toast("CHUỒNG GÀ CŨ: Hoàn thành! Chiều rồi — về nhà nghỉ thôi.")
		4:
			if not GameState.flags.get("ngay4_done", false):
				GameState.flags["ngay4_done"] = true
				hud.toast("KHÓI BẾP ĐẦU TIÊN: Hoàn thành! Về giường đánh một giấc nào.")
		5:
			if not GameState.flags.get("ngay5_done", false):
				GameState.flags["ngay5_done"] = true
				if truong_thon and is_instance_valid(truong_thon):
					truong_thon.play("vay_tay")
					var tw := create_tween()
					tw.tween_interval(1.2)
					tw.tween_property(truong_thon, "modulate:a", 0.0, 1.0)
				hud.toast("LUỐNG RAU ĐẦU TIÊN: Hoàn thành! Về ngủ để xem thành quả 5 ngày nào!")
