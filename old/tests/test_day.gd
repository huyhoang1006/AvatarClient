extends Node
## Test headless: dung TEST_DAY=3/4/5 de mo phong trang thai tung ngay roi vao vuon.

func _ready() -> void:
	GameState.reset()
	var d := 3
	if OS.get_environment("TEST_DAY") != "":
		d = int(OS.get_environment("TEST_DAY"))
	GameState.day = d
	for it in [["liem", 1], ["cuoc_chim", 1], ["binh_tuoi", 1], ["co_dai", 12], ["gao_nep", 2]]:
		GameState.add_item(it[0], it[1])
	if d >= 4:
		GameState.flags["chuong_ok"] = true
	if d == 5:
		GameState.flags["ga_fed"] = 2
		GameState.flags["trung_cho"] = true
		for i in range(5):
			GameState.farm[i] = {"tilled": true, "type": "cai", "stage": 3, "watered": false}
	get_tree().change_scene_to_file.call_deferred("res://scenes/scene_vuon.tscn")
