extends SceneBase
## Trong nhà bố mẹ — nhà ba gian có bàn thờ tổ tiên. Ngày 1: đoàn tụ,
## ăn cơm mẹ nấu, nhận chìa khóa nhà ông ngoại.

const SCALE := 1.55

var father: Sprite2D
var mother: Sprite2D


func _build() -> void:
	# Nội thất ba gian (768x256) phóng to làm map
	var bg := Sprite2D.new()
	bg.texture = Art.tex("res://assets/art/maps/nha_ba_gian.png")
	bg.centered = false
	bg.scale = Vector2(SCALE, SCALE)
	bg.z_index = -10
	bg.y_sort_enabled = false
	add_child(bg)
	map_size = Vector2(768, 256) * SCALE   # 1190 x 397
	add_borders()
	add_wall(Rect2(0, 0, map_size.x, 236))  # tường + hàng cột (đi lại ở sàn gạch)

	cam.zoom = Vector2(1.9, 1.9)

	# Bàn thờ tổ tiên (giữa nhà — nằm sẵn trong tranh nền)
	var altar := Interactable.make(Vector2(map_size.x * 0.5, 250), 55, Hud.ICON_HAND, self)
	altar.activated.connect(func():
		hud.dialog([["", "Bàn thờ tổ tiên... mùi nhang trầm quen thuộc.\nẢnh ông ngoại vẫn cười hiền như ngày nào.\n(Thắp một nén nhang, lòng tự nhiên nhẹ hẳn.)"]]))

	# Bố mẹ đứng giữa nhà
	father = Art.sprite(Art.frame("res://assets/art/characters/father.png", 1, 64), Vector2(map_size.x * 0.4, 330), self)
	father.scale = Vector2(1.4, 1.4)
	mother = Art.sprite(Art.frame("res://assets/art/characters/mother.png", 3, 64), Vector2(map_size.x * 0.6, 330), self)
	mother.scale = Vector2(1.4, 1.4)
	var parents_it := Interactable.make(Vector2(map_size.x * 0.5, 330), 85, Hud.ICON_HAND, self)
	parents_it.activated.connect(_talk_parents)

	# Mâm cơm Bắc Bộ giữa nhà (2 frame)
	var mam := AnimatedSprite2D.new()
	mam.sprite_frames = Art.frames("res://assets/art/food/mam_com_bac_bo_128x128.png", {"idle": [0, 1, 2, true]}, 128)
	mam.position = Vector2(map_size.x * 0.5, 360)
	mam.scale = Vector2(0.9, 0.9)
	mam.play("idle")
	add_child(mam)

	# Cửa ra ngõ (mép dưới)
	var door := Interactable.make(Vector2(map_size.x * 0.5, map_size.y - 12), 55, Hud.ICON_DOOR, self)
	door.activated.connect(func():
		GameState.flags["from_bome"] = true
		goto_scene("res://scenes/scene_ngo.tscn"))

	player.position = Vector2(map_size.x * 0.5, map_size.y - 40)
	hud.set_day_time("Ngày %d — %s" % [GameState.day, "15:15" if GameState.day == 1 else "buổi sáng"])


func _after_fade() -> void:
	if GameState.day == 1 and not GameState.flags.get("met_parents", false):
		await get_tree().create_timer(0.4).timeout
		_talk_parents()


func _talk_parents() -> void:
	if GameState.day == 1 and not GameState.flags.get("met_parents", false):
		await hud.dialog([
			["Bố", "Thằng Đức!? Trời đất... mày về thật đấy à con? Sao không gọi trước để bố ra bến đón!"],
			[GameState.player_name, "Con... con muốn về bất ngờ cho vui ạ. Con chào bố mẹ."],
			["Mẹ", "Về là tốt rồi, hỏi han gì nhiều! Gầy rộc đi thế này cơ mà... Ngồi xuống ăn cơm đã, mẹ vừa dọn mâm xong, toàn món con thích."],
		])
		GameState.set_stamina(GameState.stamina + 25)
		hud.toast("Bữa cơm mẹ nấu... +25 Stamina ❤")
		await get_tree().create_timer(1.0).timeout
		await hud.dialog([
			["Bố", "Chuyện trên phố thế nào bố không hỏi. Nghỉ ngơi đi đã. À mà... căn nhà gỗ cũ của ông ngoại bên kia ngõ vẫn để nguyên đấy."],
			["Bố", "Ông mất rồi nhưng bố vẫn tin căn nhà đấy hợp với mày hơn là cái phòng trọ chật chội trên phố. Chìa khóa đây — sang mà dọn dẹp ở tạm."],
		])
		give_items([["chia_khoa", 1]])
		await hud.dialog([
			["Mẹ", "Cầm thêm cặp bánh phu thê lót dạ này. Sân bên đấy cỏ mọc um tùm lắm đấy, dọn dẹp mệt thì ăn mà lấy sức."],
			["Mẹ", "Tối sang ăn cơm với bố mẹ nghe chưa!"],
		])
		give_items([["banh_phu_the", 2]])
		GameState.flags["met_parents"] = true
		GameState.quest_progress(0)
		hud.toast("Giờ ra cổng CUỐI NGÕ (bên phải) sang nhà ông ngoại nhé!")
	elif GameState.day == 1:
		await hud.dialog([["Mẹ", "Sang bên nhà ông ngoại dọn dẹp đi con, tối về ăn cơm."]])
	else:
		await hud.dialog([
			["Bố", "Sáng sớm đã dậy rồi cơ à? Khá! Ra dáng nông dân rồi đấy."],
			["Mẹ", "Vườn bên đấy đất tốt lắm, chịu khó chăm là có rau ăn ngay thôi con."],
		])
