extends Node
## Chạy headless để kiểm tra lưu trữ local của GameState:
##   godot --headless --path <project> res://tests/test_save.tscn
##
## Kiểm cả trường hợp mất điện giữa lúc ghi (file save.json hỏng) thì có rơi về
## bản .bak được không.

var _passed := 0
var _failed := 0


func _ready() -> void:
	_clean()

	_test_save_and_reload()
	_test_survives_corrupt_save()
	_test_fresh_detection()

	print("")
	print("=== KET QUA: %d dat, %d hong ===" % [_passed, _failed])
	_clean()
	get_tree().quit(1 if _failed > 0 else 0)


# ---------- Các bài test ----------

func _test_save_and_reload() -> void:
	print("\n--- test 1: ghi xuong dia roi nap lai ---")
	_fill_sample_state()
	_check("save_local() thanh cong", GameState.save_local())
	_check("file save.json ton tai", FileAccess.file_exists(GameState.SAVE_PATH))

	# Giả lập mở lại game: xoá sạch trong RAM rồi nạp từ đĩa
	GameState.reset()
	_check("sau reset, day ve 1", GameState.day == 1)

	_check("load_local() doc duoc", GameState.load_local())
	_check("day  = 4", GameState.day == 4, str(GameState.day))
	_check("water = 3", GameState.water == 3, str(GameState.water))
	_check("stamina = 55.5", is_equal_approx(GameState.stamina, 55.5), str(GameState.stamina))
	_check("inventory.hat_cai = 7", int(GameState.inventory.get("hat_cai", 0)) == 7, str(GameState.inventory))
	_check("flags.breaker_fixed", bool(GameState.flags.get("breaker_fixed", false)))
	_check("quest.title giu nguyen", str(GameState.quest.get("title", "")) == "LUONG RAU DAU TIEN")
	_check("farm[1].stage = 2 (kieu int)", GameState.farm[1]["stage"] == 2 and typeof(GameState.farm[1]["stage"]) == TYPE_INT)
	_check("farm[1].watered = true", GameState.farm[1]["watered"] == true)
	_check("farm van du 8 o", GameState.farm.size() == 8, str(GameState.farm.size()))


func _test_survives_corrupt_save() -> void:
	print("\n--- test 2: save.json hong (mat dien giua luc ghi) ---")
	_fill_sample_state()
	GameState.save_local()          # lan 1: tao save.json
	GameState.day = 9
	GameState.save_local()          # lan 2: save.json cu -> .bak, ghi ban moi

	_check("co file .bak", FileAccess.file_exists(GameState.BACKUP_PATH))

	# Ghi rac de len save.json, y het truong hop ghi do dang thi mat dien
	var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	f.store_string('{"version":1,"state":{"day":')
	f.close()

	GameState.reset()
	_check("van nap duoc (roi ve .bak)", GameState.load_local())
	_check("lay duoc ban .bak, day = 4", GameState.day == 4, str(GameState.day))


func _test_fresh_detection() -> void:
	print("\n--- test 3: is_fresh() quyet dinh lay ban server hay ban local ---")
	GameState.reset()
	_check("vua reset -> is_fresh() = true", GameState.is_fresh())

	GameState.add_item("hat_cai", 1)
	_check("co do trong tui -> is_fresh() = false", not GameState.is_fresh())

	GameState.reset()
	GameState.day = 3
	_check("sang ngay 3 -> is_fresh() = false", not GameState.is_fresh())


# ---------- Tiện ích ----------

func _fill_sample_state() -> void:
	GameState.reset()
	GameState.day = 4
	GameState.water = 3
	GameState.set_stamina(55.5)
	GameState.add_item("hat_cai", 7)
	GameState.flags["breaker_fixed"] = true
	GameState.start_quest("LUONG RAU DAU TIEN", [["Cuoc dat", 5], ["Gieo hat", 5]])
	GameState.farm[1] = {"tilled": true, "type": "cai", "stage": 2, "watered": true}


func _clean() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	for name in ["save.json", "save.json.bak", "save.json.tmp"]:
		if dir.file_exists(name):
			dir.remove(name)


func _check(label: String, ok: bool, extra: String = "") -> void:
	if ok:
		_passed += 1
		print("  OK    %s" % label)
	else:
		_failed += 1
		print("  HONG  %s %s" % [label, ("(thuc te: %s)" % extra) if extra != "" else ""])
