extends SceneBase
## Trong nhà ông ngoại:
##  Ngày 1: tối om -> sửa cầu dao (minigame Tháp Hà Nội) -> ngủ
##  Ngày 2: rương lương thực
##  Ngày 4: dựng BẾP CỦI, nấu mì chín
##  Ngủ = chuyển ngày (2->3->4->5); hết Ngày 5 = màn tổng kết HẾT DEMO.

var darkness: CanvasModulate
var breaker: Sprite2D
var red_light: AnimatedSprite2D
var breaker_it: Interactable
var chest_emote: Sprite2D
var bep: AnimatedSprite2D
var bep_ghost: Sprite2D


func _build() -> void:
	add_bg("res://assets/maps/nha_bg.png")
	add_borders()
	add_wall(Rect2(0, 0, 640, 100))  # tường sau

	# Nội thất
	Art.sprite(Art.frame("res://assets/art/assets/tu_che.png", 0, 64), Vector2(320, 165), self).scale = Vector2(1.4, 1.4)
	var chan := Art.sprite(Art.frame("res://assets/art/householditems/chan_bat.png", 0, 128), Vector2(160, 175), self)
	chan.scale = Vector2(0.75, 0.75)
	Art.sprite(Art.tex("res://assets/art/oil_lamp/den_dau_1.png"), Vector2(410, 150), self).scale = Vector2(0.8, 0.8)
	Art.sprite(Art.frame("res://assets/art/assets/chum_nuoc.png", 0, 64), Vector2(70, 290), self)
	add_wall(Rect2(120, 120, 330, 50))

	# Giường
	var bed := Art.sprite(Art.tex("res://assets/art/bed/giuong_1.png"), Vector2(560, 300), self)
	bed.scale = Vector2(1.3, 1.3)
	add_wall(Rect2(520, 230, 80, 60))
	var bed_it := Interactable.make(Vector2(555, 315), 58, Hud.ICON_MOON, self)
	bed_it.activated.connect(_use_bed)

	# Cầu dao điện trên tường phải
	var fixed: bool = GameState.flags.get("breaker_fixed", false)
	breaker = Art.sprite(
		Art.frame("res://assets/art/assets/caudaodien.png" if fixed else "res://assets/art/assets/caugiaodienbroken.png", 0, 64),
		Vector2(520, 118), self)
	breaker.scale = Vector2(0.9, 0.9)
	if not fixed:
		red_light = AnimatedSprite2D.new()
		red_light.sprite_frames = Art.frames("res://assets/ui/den_bao_do_8_2f.png", {"blink": [0, 1, 3, true]}, 8)
		red_light.position = Vector2(520, 80)
		red_light.scale = Vector2(2.2, 2.2)
		red_light.play("blink")
		add_child(red_light)
		breaker_it = Interactable.make(Vector2(520, 130), 55, Hud.ICON_HAND, self)
		breaker_it.activated.connect(_open_minigame)

	# Cửa ra sân
	var door := Interactable.make(Vector2(320, 400), 50, Hud.ICON_DOOR, self)
	door.activated.connect(func(): goto_scene("res://scenes/scene_san.tscn"))

	# Rương tiếp tế — Ngày 2
	if GameState.day == 2 and not GameState.flags.get("chest_looted", false):
		var chest := Art.sprite(Art.frame("res://assets/art/assets/cai_ruong_go_boc_sat_ri_set.png", 0, 64), Vector2(430, 170), self)
		chest.scale = Vector2(1.1, 1.1)
		chest_emote = add_emote(Vector2(430, 115))
		var chest_it := Interactable.make(Vector2(430, 180), 52, Hud.ICON_HAND, self)
		chest_it.activated.connect(func(): _open_chest(chest, chest_it))

	# BẾP CỦI — góc trái (mở từ Ngày 4)
	if GameState.day >= 4:
		if GameState.flags.get("bep_ok", false):
			_dat_bep()
		else:
			bep_ghost = Art.sprite(Art.frame("res://assets/ui_pixel/bep_cui_32_2f.png", 0, 32), Vector2(140, 320), self)
			bep_ghost.scale = Vector2(1.6, 1.6)
			bep_ghost.modulate = Color(1, 1, 1, 0.35)
			add_emote(Vector2(140, 275))
		var bep_it := Interactable.make(Vector2(140, 325), 50, Hud.ICON_HAND, self)
		bep_it.activated.connect(_dung_bep)

	# Bóng tối Ngày 1 (chưa sửa điện)
	if GameState.day == 1 and not fixed:
		darkness = CanvasModulate.new()
		darkness.color = Color(0.13, 0.13, 0.22)
		add_child(darkness)
		var light := PointLight2D.new()
		light.texture = Art.tex("res://assets/ui/light_radial.png")
		light.texture_scale = 1.4
		light.energy = 1.1
		player.add_child(light)
		var rl := PointLight2D.new()
		rl.texture = Art.tex("res://assets/ui/light_radial.png")
		rl.texture_scale = 0.5
		rl.energy = 0.9
		rl.color = Color(1, 0.25, 0.2)
		rl.position = Vector2(520, 90)
		add_child(rl)

	player.position = Vector2(320, 360)
	hud.set_day_time("Ngày 1 — 18:45" if GameState.day == 1 else "Ngày %d — 05:05" % GameState.day)


func _after_fade() -> void:
	match GameState.day:
		1:
			if not GameState.flags.get("breaker_fixed", false):
				hud.toast("Trong nhà tối om... Tiếng dế kêu văng vẳng.")
				await get_tree().create_timer(1.2).timeout
				hud.toast("Góc tường bên phải có điểm sáng đỏ nhấp nháy!")
		2:
			if not GameState.flags.get("woke_toast", false):
				GameState.flags["woke_toast"] = true
				hud.toast("Ò ó o o...! 🐓 Một buổi sáng trong lành ở quê.")
		3:
			if not GameState.flags.get("woke3", false):
				GameState.flags["woke3"] = true
				hud.toast("Ngày 3! Hôm qua ông Trưởng Thôn hẹn ghé xem tình hình... Ra VƯỜN xem sao.")
		4:
			if not GameState.flags.get("woke4", false):
				GameState.flags["woke4"] = true
				await hud.dialog([
					["", "Ngày 4. Ăn sống mãi cũng chán tận cổ rồi...\nGóc nhà kia trống trải — hay là DỰNG CÁI BẾP CỦI nhỉ?\nMà đôi gà ngoài vườn cũng phải cho ăn tử tế (gạo nếp của ông còn kia)."],
				])
				GameState.start_quest("KHÓI BẾP ĐẦU TIÊN", [
					["Dựng bếp củi trong nhà", 1],
					["Nấu một bát mì chín", 1],
					["Cho gà ăn gạo nếp", 2],
					["Tưới 5 luống cải", 5],
				])
				hud.toast("Nhận nhiệm vụ: KHÓI BẾP ĐẦU TIÊN!")
		5:
			if not GameState.flags.get("woke5", false):
				GameState.flags["woke5"] = true
				hud.toast("Ngày 5! Ngoài vườn nghe tiếng gà rộn ràng khác thường...")


# ---------- Minigame cầu dao (Ngày 1) ----------
func _open_minigame() -> void:
	player.busy = true
	hud.modal_open = true
	var mg := preload("res://scenes/minigame_hanoi.gd").new()
	add_child(mg)
	mg.solved.connect(_on_breaker_fixed)
	mg.closed.connect(func():
		player.busy = false
		hud.modal_open = false)


func _on_breaker_fixed() -> void:
	player.busy = false
	hud.modal_open = false
	GameState.flags["breaker_fixed"] = true
	hud.flash(Color(1, 1, 0.85), 0.85, 0.6)
	breaker.texture = Art.frame("res://assets/art/assets/caudaodien.png", 0, 64)
	if red_light:
		red_light.queue_free()
	if breaker_it:
		breaker_it.enabled = false
	if darkness:
		var tw := create_tween()
		tw.tween_property(darkness, "color", Color(1.0, 0.96, 0.88), 1.2)
	hud.toast("CẠCH! Bóng đèn sợi đốt bừng sáng, xua tan bóng tối!")
	GameState.quest_progress(1)
	hud.set_day_time("Ngày 1 — 20:00")
	await get_tree().create_timer(1.5).timeout
	hud.toast("Căn nhà cũ lộ rõ: giường tre, tủ chè, chạn bát... Ngủ sớm thôi.")


# ---------- Rương tiếp tế (Ngày 2) ----------
func _open_chest(chest: Sprite2D, it: Interactable) -> void:
	it.enabled = false
	if chest_emote:
		chest_emote.queue_free()
		chest_emote = null
	var anim := AnimatedSprite2D.new()
	anim.sprite_frames = Art.frames("res://assets/art/assets/animate_mo_ruong_go_boc_sat.png", {"open": [0, 14, 18, false]}, 64)
	anim.position = chest.position + Vector2(0, -32)
	anim.scale = chest.scale
	add_child(anim)
	chest.visible = false
	anim.play("open")
	await anim.animation_finished
	await hud.summary("📦 RƯƠNG LƯƠNG THỰC CỦA ÔNG", [
		"• Mỳ tôm Hảo Hán ×4  (+30 Stamina — nhai sống rôm rốp cực cuốn)",
		"• Khoai lang đất ×4  (+15 Stamina — hơi sượng nhưng chắc bụng)",
		"• Khoai tây mọc mầm ×3  (+5 Stamina, dính [Đau bụng nhẹ])",
		"• Gạo nếp tẻ ×2  (+2 Stamina — nhai sống mẻ răng, để dành sau này có bếp thì hơn)",
	], "Lấy hết")
	give_items([["mi_tom", 4], ["khoai_lang", 4], ["khoai_tay", 3], ["gao_nep", 2]])
	GameState.flags["chest_looted"] = true


# ---------- BẾP CỦI (Ngày 4+) ----------
func _dat_bep() -> void:
	if bep_ghost and is_instance_valid(bep_ghost):
		bep_ghost.queue_free()
		bep_ghost = null
	bep = AnimatedSprite2D.new()
	bep.sprite_frames = Art.frames("res://assets/ui_pixel/bep_cui_32_2f.png", {"chay": [0, 1, 4, true]}, 32)
	bep.position = Vector2(140, 320)
	bep.offset = Vector2(0, -16)
	bep.scale = Vector2(1.6, 1.6)
	bep.play("chay")
	add_child(bep)


func _dung_bep() -> void:
	if not GameState.flags.get("bep_ok", false):
		# dựng bếp: cần 5 cỏ khô nhóm lửa
		if int(GameState.inventory.get("co_dai", 0)) < 5:
			hud.toast("Cần 5 nắm cỏ khô để nhóm lửa. Ra vườn chém thêm đi!")
			return
		if GameState.is_exhausted():
			hud.toast("Bạn quá đói để làm việc này!")
			return
		GameState.remove_item("co_dai", 5)
		GameState.use_stamina(10)
		await player.swing_tool(Art.frame("res://assets/art/assets/bua_32x32.png", 0, 32))
		GameState.flags["bep_ok"] = true
		_dat_bep()
		hud.flash(Color(1, 0.7, 0.3), 0.35)
		hud.toast("Kê đá, chất củi, nhóm cỏ khô... BẾP ĐỎ LỬA RỒI! 🔥")
		if GameState.day == 4:
			GameState.quest_progress(0)
		return
	# bếp đã đỏ lửa: nấu mì
	var ok := await hud.confirm("Nấu một bát mì chín nóng hổi?\n(cần 1 Mỳ tôm sống — ăn sẽ hồi +50 Stamina)", "Nấu!", "Thôi")
	if not ok:
		return
	if not GameState.has_item("mi_tom"):
		hud.toast("Hết mì tôm sống rồi...")
		return
	GameState.remove_item("mi_tom")
	await get_tree().create_timer(0.8).timeout
	give_items([["mi_chin", 1]])
	hud.toast("Nước sôi sùng sục... thơm điếc mũi! Bát mì đầu tiên ở quê 🍜")
	if GameState.day == 4 and not GameState.quest.is_empty() and not GameState.quest_step_done(1):
		GameState.quest_progress(1)


# ---------- NGỦ / CHUYỂN NGÀY ----------
func _use_bed() -> void:
	match GameState.day:
		1:
			if not GameState.flags.get("breaker_fixed", false):
				hud.toast("Tối om thế này sao ngủ được... Sửa cái cầu dao đã! (điểm đỏ nhấp nháy)")
				return
			if not await hud.confirm("Ngủ để lưu lại trò chơi và chuyển sang Ngày 2?"):
				return
			await _chuyen_ngay("🌙 NGÀY 1 HOÀN THÀNH", [
				"Về tới quê, nhận nhà cũ của ông ngoại.",
				"Dọn sạch sân gạch đỏ, sửa xong cầu dao điện.",
				"Ngày mai: khám phá mảnh vườn sau nhà...",
			])
		2:
			if not GameState.flags.get("garden_done", false):
				hud.toast("Vườn còn dang dở, chưa đến lúc ngủ. (xem nhiệm vụ góc phải)")
				return
			if not GameState.flags.get("chest_looted", false):
				hud.toast("Bụng đói meo... Hình như cạnh tủ chè có cái rương gỗ thì phải?")
				return
			if not await hud.confirm("Kết thúc Ngày 2?"):
				return
			await _chuyen_ngay("🌙 NGÀY 2 HOÀN THÀNH", [
				"5 luống cải đã gieo và tưới nước — nhớ TƯỚI MỖI NGÀY cho cải lớn!",
				"Thức ăn trong rương đủ sống qua mấy hôm tới.",
				"Ngày mai: nghe nói ông Trưởng Thôn sẽ ghé 'kiểm tra tình hình'...",
			])
		3:
			if not GameState.flags.get("ngay3_done", false):
				hud.toast("Chuồng gà với luống rau còn dở (xem nhiệm vụ góc phải)!")
				return
			if not await hud.confirm("Kết thúc Ngày 3?"):
				return
			await _chuyen_ngay("🌙 NGÀY 3 HOÀN THÀNH", [
				"Chuồng gà như mới + đôi gà con lon ton ngoài vườn.",
				"Cải lớn thêm một nấc — xanh dần rồi đấy.",
				"Ngày mai: dựng cái bếp cho ra dáng một MÁI NHÀ.",
			])
		4:
			if not GameState.flags.get("ngay4_done", false):
				hud.toast("Bếp núc, gà qué, rau cỏ còn dở dang (xem nhiệm vụ góc phải)!")
				return
			if not await hud.confirm("Kết thúc Ngày 4?"):
				return
			await _chuyen_ngay("🌙 NGÀY 4 HOÀN THÀNH", [
				"Khói bếp đầu tiên bốc lên từ căn nhà của ông.",
				"Gà no căng diều — nghe đồn mai có quà sáng 🥚",
				"Và cải... mai là CHÍN RỒI!",
			])
		5:
			if not GameState.flags.get("ngay5_done", false):
				hud.toast("Việc Ngày 5 chưa xong (xem nhiệm vụ góc phải)! Cố nốt nào.")
				return
			if not await hud.confirm("Kết thúc Ngày 5 và xem tổng kết?"):
				return
			await hud.fade_out(0.8)
			await hud.summary("🌾 NGÀY 5 HOÀN THÀNH", [
				"Hái mẻ cải đầu tiên — 'đất không phụ người chăm'.",
				"Bình tưới của ông ngoại lại phun nước ngon lành (8 nước!).",
				"Rau muống và vụ lúa đầu tiên đã nằm dưới đất chờ lên.",
			], "Tổng kết 5 ngày")
			await hud.summary("🎉 HẾT DEMO — 5 NGÀY VỀ QUÊ", [
				"✔ Ngày 1: Đoàn tụ bố mẹ, dọn sân, sửa điện (Tháp Cầu Chì Sứ)",
				"✔ Ngày 2: Cô Lan cho đồ nghề, trồng 5 luống cải",
				"✔ Ngày 3: Sửa chuồng, nhận đôi gà con",
				"✔ Ngày 4: Bếp đỏ lửa, bát mì chín đầu tiên",
				"✔ Ngày 5: Hái cải, thông bình của ông, gieo rau muống + lúa",
				"",
				"Sắp tới: chợ làng, câu cá ao nhà, Tết Nguyên Đán...",
				"Cảm ơn đã chơi LÀNG QUÊ IT!",
			], "Về màn hình chính")
			GameState.reset()
			get_tree().change_scene_to_file("res://main.tscn")


## fade -> qua ngày (cây lớn nếu đã tưới) -> bảng tổng kết -> tỉnh dậy trong nhà
func _chuyen_ngay(title: String, lines: Array) -> void:
	await hud.fade_out(0.8)
	GameState.sleep_next_day()
	await hud.summary(title, lines, "Sang Ngày %d" % GameState.day)
	get_tree().change_scene_to_file("res://scenes/scene_nha.tscn")
