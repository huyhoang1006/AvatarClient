extends Node
## Autoload GameState: trạng thái toàn cục của người chơi + quest + túi đồ.

signal stamina_changed(value: float)
signal inventory_changed
signal quest_changed

const MAX_STAMINA := 100.0

# ---- Định nghĩa vật phẩm ----
# icon: đường dẫn sheet; frame: frame trong strip ngang; food: hồi stamina khi ăn
const ITEMS := {
	"chia_khoa": {"name": "Chìa khóa nhà cũ", "icon": "res://assets/ui/item_chiakhoa_codai_16.png", "frame": 0, "fw": 16, "food": 0},
	"co_dai": {"name": "Cỏ dại", "icon": "res://assets/ui/item_chiakhoa_codai_16.png", "frame": 1, "fw": 16, "food": 2},
	"liem": {"name": "Liềm cùn", "icon": "res://assets/art/assets/liem_32x32.png", "frame": 0, "fw": 32, "food": 0},
	"cuoc_chim": {"name": "Cuốc chim", "icon": "res://assets/art/assets/cuoc_chim.png", "frame": 0, "fw": 32, "food": 0},
	"binh_tuoi": {"name": "Bình tưới nước", "icon": "res://assets/art/assets/binh_nuoc_tuoi_cay.png", "frame": 0, "fw": 32, "food": 0},
	"hat_cai": {"name": "Hạt giống Cải Ngọt", "icon": "res://assets/art/farmmap/hat_giong.png", "frame": 0, "fw": 32, "food": 0},
	"banh_phu_the": {"name": "Bánh phu thê", "icon": "res://assets/art/food/banh_phu_the.png", "frame": 1, "fw": 32, "food": 30},
	"mi_tom": {"name": "Mỳ tôm Hảo Hán", "icon": "res://assets/art/mi_tom.png", "frame": 0, "fw": 32, "food": 30},
	"khoai_lang": {"name": "Khoai lang đất", "icon": "res://assets/art/food/khoai_lang.png", "frame": 0, "fw": 32, "food": 15},
	"khoai_tay": {"name": "Khoai tây mọc mầm", "icon": "res://assets/art/food/khoai_tay_nay_mam.png", "frame": 0, "fw": 32, "food": 5, "debuff": "Đau bụng nhẹ"},
	"gao_nep": {"name": "Gạo nếp tẻ", "icon": "res://assets/art/food/01_hat_gao.png", "frame": 0, "fw": 32, "food": 2},
	"rau_cai": {"name": "Rau cải ngọt", "icon": "res://assets/art/tree/cay_cai_ngot.png", "frame": 2, "fw": 32, "food": 8},
	"mi_chin": {"name": "Mì nấu chín nóng hổi", "icon": "res://assets/ui_pixel/mi_chin_24.png", "frame": 0, "fw": 24, "food": 50},
	"trung": {"name": "Trứng gà ta", "icon": "res://assets/ui_pixel/trung_16.png", "frame": 0, "fw": 16, "food": 20},
	"hat_muong": {"name": "Hạt rau muống", "icon": "res://assets/art/farmmap/hat_giong.png", "frame": 1, "fw": 32, "food": 0},
	"thoc_giong": {"name": "Thóc giống (đã ngâm)", "icon": "res://assets/art/tree/thoc_giong_32x32.png", "frame": 0, "fw": 32, "food": 0},
}

var player_name := "Đức"
var day := 1
var stamina := MAX_STAMINA
var inventory := {}          # id -> số lượng
var flags := {}              # cờ cốt truyện: npc_met, breaker_fixed, chest_looted, sign_read, colan_done, garden_done, grass_day1_done
var water := 0               # nước trong bình tưới
var water_max := 5           # dung tích bình (5 -> 8 sau minigame thông vòi Ngày 5)

# Ruộng bền vững qua ngày: 8 ô. Mỗi ô: {tilled, type ("cai"/"muong"/"thoc"/""), stage, watered}
# 5 ô đầu mở từ Ngày 2, 3 ô cuối mở Ngày 5.
var farm: Array = []

# Quest hiện tại: {"title": String, "steps": [{"text": String, "need": int, "have": int}]}
var quest := {}

# Trạng thái phiên đăng nhập (không bị reset)
var session_logged_in := false


func _ready() -> void:
	_setup_input()
	if farm.is_empty():
		for i in range(8):
			farm.append({"tilled": false, "type": "", "stage": 0, "watered": false})


func reset() -> void:
	day = 1
	stamina = MAX_STAMINA
	inventory = {}
	flags = {}
	quest = {}
	water = 0
	water_max = 5
	farm = []
	for i in range(8):
		farm.append({"tilled": false, "type": "", "stage": 0, "watered": false})


# ---------- Túi đồ ----------
func add_item(id: String, n: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + n
	inventory_changed.emit()


func remove_item(id: String, n: int = 1) -> bool:
	if int(inventory.get(id, 0)) < n:
		return false
	inventory[id] = int(inventory[id]) - n
	if inventory[id] <= 0:
		inventory.erase(id)
	inventory_changed.emit()
	return true


func has_item(id: String) -> bool:
	return int(inventory.get(id, 0)) > 0


func item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


## Ăn 1 món; trả về mô tả hiệu ứng ("" nếu thất bại)
func eat(id: String) -> String:
	var def: Dictionary = ITEMS.get(id, {})
	if int(def.get("food", 0)) <= 0 or not remove_item(id):
		return ""
	set_stamina(stamina + def["food"])
	var msg := "+%d Stamina" % int(def["food"])
	if def.has("debuff"):
		msg += "  [%s]" % def["debuff"]
	return msg


# ---------- Stamina ----------
func set_stamina(v: float) -> void:
	stamina = clampf(v, 0.0, MAX_STAMINA)
	stamina_changed.emit(stamina)


func use_stamina(cost: float) -> bool:
	if stamina <= 0.0:
		return false
	set_stamina(stamina - cost)
	return true


func is_tired() -> bool:
	return stamina < 20.0


func is_exhausted() -> bool:
	return stamina <= 0.0


# ---------- Quest ----------
func start_quest(title: String, steps: Array) -> void:
	var s := []
	for st in steps:
		s.append({"text": st[0], "need": st[1], "have": 0})
	quest = {"title": title, "steps": s}
	quest_changed.emit()


func quest_progress(idx: int, n: int = 1) -> void:
	if quest.is_empty() or idx >= quest["steps"].size():
		return
	var st: Dictionary = quest["steps"][idx]
	st["have"] = mini(int(st["have"]) + n, int(st["need"]))
	quest_changed.emit()


func quest_step_done(idx: int) -> bool:
	if quest.is_empty() or idx >= quest["steps"].size():
		return false
	var st: Dictionary = quest["steps"][idx]
	return int(st["have"]) >= int(st["need"])


func quest_done() -> bool:
	if quest.is_empty():
		return false
	for st in quest["steps"]:
		if int(st["have"]) < int(st["need"]):
			return false
	return true


# ---------- Ngủ / qua ngày ----------
func sleep_next_day() -> void:
	day += 1
	set_stamina(MAX_STAMINA)
	# qua đêm: ô nào ĐÃ TƯỚI thì cây lớn thêm 1 giai đoạn (cải chín ở stage 3)
	for cell in farm:
		if str(cell["type"]) != "" and bool(cell["watered"]):
			cell["stage"] = mini(int(cell["stage"]) + 1, 3)
		cell["watered"] = false
	# gà được cho ăn đủ hôm trước -> sáng hôm sau có trứng chờ ở chuồng
	if int(flags.get("ga_fed", 0)) >= 2 and not flags.get("trung_da_nhat", false):
		flags["trung_cho"] = true


# ---------- Input map (tạo bằng code để khỏi sửa project.godot) ----------
func _setup_input() -> void:
	var defs := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE],
	}
	for action in defs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in defs[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
