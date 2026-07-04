extends SceneBase
## Ngõ xóm — điểm đến đầu tiên của Ngày 1: nhà bố mẹ, ao cá, bọn trẻ con.

var kid1: Sprite2D
var kid2: Sprite2D
var dog: AnimatedSprite2D
var fish_jump: AnimatedSprite2D
var house_emote: Sprite2D


func _build() -> void:
	add_bg("res://assets/maps/ngo_xom_bg.png")
	add_borders()

	# Nhà bố mẹ (bản nhà gỗ đã tách nền xám)
	var house := Art.sprite(Art.tex("res://assets/art/houses/nha_go_cutout.png"), Vector2(448, 246), self)
	house.scale = Vector2(1.15, 1.15)
	add_wall(Rect2(320, 110, 256, 110))
	var door := Interactable.make(Vector2(448, 252), 50, Hud.ICON_DOOR, self)
	door.activated.connect(_enter_bome)
	if not GameState.flags.get("met_parents", false):
		house_emote = add_emote(Vector2(448, 100))

	# Ao cá nhà (khung cỏ + cầu gỗ) + cá vàng thỉnh thoảng nhảy
	var ao := Art.sprite(Art.frame("res://assets/art/ao.png", 2, 256), Vector2(170, 640), self)
	ao.y_sort_enabled = false
	ao.z_index = -5
	add_wall(Rect2(60, 470, 220, 150))
	var ao_it := Interactable.make(Vector2(180, 470), 60, Hud.ICON_HAND, self)
	ao_it.activated.connect(func():
		hud.dialog([["", "Ao cá ông ngoại đào từ hồi mình còn bé tí. Cá vẫn quẫy ầm ầm...\n(Học được nghề câu là có cái ăn dài dài đây.)"]]))
	fish_jump = AnimatedSprite2D.new()
	fish_jump.sprite_frames = Art.frames("res://assets/art/animals_fish/fish_jump_from_pond.png", {"jump": [0, 6, 10, false]}, 108)
	fish_jump.position = Vector2(185, 505)
	fish_jump.visible = false
	fish_jump.z_index = 2
	add_child(fish_jump)
	var fish_timer := Timer.new()
	fish_timer.wait_time = 5.5
	fish_timer.autostart = true
	fish_timer.timeout.connect(_do_fish_jump)
	add_child(fish_timer)

	# Bụi tre + cây trang trí
	for pos in [Vector2(60, 150), Vector2(880, 140), Vector2(840, 560)]:
		var b := Art.sprite(Art.tex("res://assets/art/tree/bui_tre.png"), pos, self)
		b.scale = Vector2(1.5, 1.5)

	# Gà bới đất trước sân
	for pos in [Vector2(560, 270), Vector2(620, 300)]:
		var ga := AnimatedSprite2D.new()
		ga.sprite_frames = Art.frames("res://assets/art/animals_ga_co/ga_trong_32x32.png", {"idle": [0, 2, 4, true]}, 32)
		ga.position = pos
		ga.offset = Vector2(0, -16)
		ga.scale = Vector2(1.4, 1.4)
		ga.play("idle")
		add_child(ga)

	# 2 nhóc chạy đuổi nhau dọc ngõ + chó đuổi theo
	kid1 = Art.sprite(Art.tex("res://assets/art/characters/con_trai_truong_thon.png"), Vector2(150, 370), self)
	kid2 = Art.sprite(Art.tex("res://assets/art/characters/ong_ban_thoi_tho_au.png"), Vector2(230, 385), self)
	dog = AnimatedSprite2D.new()
	dog.sprite_frames = Art.frames("res://assets/art/animals_dog/dog_run.png", {"run": [0, 8, 12, true]}, 64)
	dog.position = Vector2(300, 380)
	dog.offset = Vector2(0, -28)
	dog.play("run")
	add_child(dog)
	_run_kids_loop()
	var kid_it := Interactable.make(Vector2(400, 375), 70, Hud.ICON_HAND, self)
	kid_it.activated.connect(func():
		hud.dialog([
			["Nhóc tì", "A! Chú là con bác Bảy mới về đúng không? Bà cháu bảo chú làm 'ai ti' trên phố oách lắm!"],
			["Nhóc tì", "Chơi đuổi bắt với bọn cháu không chú? Thua thì phải mua kẹo mút đó nha!!"],
			[GameState.player_name, "(Haha... lâu lắm rồi mới nghe tiếng trẻ con hò reo thế này.)"],
		]))

	# Cổng cuối ngõ sang sân nhà ông ngoại
	Art.sprite(Art.tex("res://assets/ui/cong_rao_tre_64x48.png"), Vector2(912, 360), self)
	var gate := Interactable.make(Vector2(912, 365), 55, Hud.ICON_DOOR, self)
	gate.activated.connect(_go_san)

	# Vị trí xuất hiện
	if GameState.flags.get("from_san", false):
		GameState.flags["from_san"] = false
		player.position = Vector2(850, 370)
	elif GameState.flags.get("from_bome", false):
		GameState.flags["from_bome"] = false
		player.position = Vector2(448, 300)
	else:
		player.position = Vector2(60, 370)
	hud.set_day_time("Ngày %d — %s" % [GameState.day, "15:00" if GameState.day == 1 else "buổi sáng"])


func _after_fade() -> void:
	if GameState.day == 1 and not GameState.flags.get("ngo_intro", false):
		GameState.flags["ngo_intro"] = true
		hud.toast("Đầu ngõ nhà mình... 11 năm rồi mới về lại.")
		GameState.start_quest("VỀ NHÀ", [["Vào chào bố mẹ", 1], ["Sang nhà ông ngoại (cổng cuối ngõ)", 1]])
		await get_tree().create_timer(1.6).timeout
		hud.toast("Nhà bố mẹ có dấu ❗ kìa — vào chào trước đã!")


func _run_kids_loop() -> void:
	# 2 nhóc + chó chạy qua lại dọc ngõ, lật hướng ở 2 đầu
	var tw := create_tween().set_loops()
	tw.tween_callback(func(): _face_kids(false))
	tw.tween_property(kid1, "position:x", 620.0, 4.0)
	tw.parallel().tween_property(kid2, "position:x", 700.0, 4.0)
	tw.parallel().tween_property(dog, "position:x", 780.0, 4.0)
	tw.tween_callback(func(): _face_kids(true))
	tw.tween_property(kid1, "position:x", 150.0, 4.0)
	tw.parallel().tween_property(kid2, "position:x", 230.0, 4.0)
	tw.parallel().tween_property(dog, "position:x", 300.0, 4.0)


func _face_kids(left: bool) -> void:
	kid1.flip_h = left
	kid2.flip_h = left
	dog.flip_h = left


func _do_fish_jump() -> void:
	fish_jump.visible = true
	fish_jump.frame = 0
	fish_jump.play("jump")
	await fish_jump.animation_finished
	fish_jump.visible = false


func _enter_bome() -> void:
	goto_scene("res://scenes/scene_nha_bome.tscn")


func _go_san() -> void:
	if not GameState.flags.get("met_parents", false):
		hud.toast("Về đến nơi mà chưa chào bố mẹ thì hơi kỳ... Vào nhà trước đã!")
		return
	if GameState.day == 1 and GameState.quest_step_done(0) and not GameState.quest_step_done(1):
		GameState.quest_progress(1)
	GameState.flags["from_ngo"] = true
	goto_scene("res://scenes/scene_san.tscn")
