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

# ---- Lưu trữ local ----
# File trên máy mới là bản gốc; server chỉ là bản sao lưu. Nhờ vậy game chơi được
# khi không có mạng, và khi đồng bộ thì bản local đè lên bản server.
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.json.bak"
const TMP_PATH := "user://save.json.tmp"
const SAVE_VERSION := 1

## true nếu lúc khởi động đã đọc được save từ đĩa. Dùng để quyết định khi đồng bộ:
## có dữ liệu cũ trên máy thì đẩy lên đè server, không có thì lấy bản server về.
var loaded_from_local := false


func _ready() -> void:
	_setup_input()
	if farm.is_empty():
		for i in range(8):
			farm.append({"tilled": false, "type": "", "stage": 0, "watered": false})
	loaded_from_local = load_local()


# ---------- Lưu / nạp trên đĩa ----------
## Ghi ra file tạm rồi mới đổi tên, và giữ lại một bản .bak. Mất điện đúng lúc đang
## ghi thì cùng lắm hỏng file tạm, save cũ vẫn còn nguyên.
func save_local() -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"state": to_dict(),
	}

	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("GameState: khong mo duoc file tam (ma %d)" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(payload))
	f.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.file_exists("save.json"):
		if dir.file_exists("save.json.bak"):
			dir.remove("save.json.bak")
		dir.rename("save.json", "save.json.bak")
	if dir.rename("save.json.tmp", "save.json") != OK:
		push_error("GameState: khong doi ten duoc file save")
		return false
	return true


func has_local_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


## Nạp save từ đĩa. Nếu file chính hỏng thì thử bản .bak. Trả về false nếu không có gì đọc được.
func load_local() -> bool:
	for p in [SAVE_PATH, BACKUP_PATH]:
		var state := _read_save_file(p)
		if not state.is_empty():
			from_dict(state)
			return true
	return false


func _read_save_file(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var raw := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("GameState: %s khong phai JSON hop le, bo qua" % p)
		return {}
	var d: Dictionary = parsed
	if not d.get("state", null) is Dictionary:
		push_warning("GameState: %s thieu field 'state', bo qua" % p)
		return {}
	return d["state"]


## Chưa chơi gì cả — dùng để biết có nên lấy tiến trình từ server về không.
func is_fresh() -> bool:
	return day <= 1 and inventory.is_empty() and flags.is_empty() and quest.is_empty()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_local()


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


# ---------- Đồng bộ với server ----------
## Gói toàn bộ tiến trình để gửi lên AvatarServer.
func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"day": day,
		"stamina": stamina,
		"water": water,
		"water_max": water_max,
		"inventory": inventory.duplicate(true),
		"flags": flags.duplicate(true),
		"quest": quest.duplicate(true),
		"farm": farm.duplicate(true),
	}


## Nạp tiến trình server trả về. Field nào thiếu thì giữ nguyên giá trị đang có.
## Số qua JSON có thể về dạng float nên ép kiểu lại hết, tránh việc gameplay
## so sánh stage/số lượng bị lệch.
func from_dict(d: Dictionary) -> void:
	player_name = str(d.get("player_name", player_name))
	day = int(d.get("day", day))
	water = int(d.get("water", water))
	water_max = int(d.get("water_max", water_max))

	var inv = d.get("inventory", null)
	if inv is Dictionary:
		inventory = {}
		for id in inv:
			var n := int(inv[id])
			if n > 0:
				inventory[str(id)] = n

	if d.get("flags", null) is Dictionary:
		flags = (d["flags"] as Dictionary).duplicate(true)

	if d.get("quest", null) is Dictionary:
		quest = (d["quest"] as Dictionary).duplicate(true)
		for st in quest.get("steps", []):
			st["need"] = int(st.get("need", 0))
			st["have"] = int(st.get("have", 0))

	var f = d.get("farm", null)
	if f is Array and (f as Array).size() == farm.size():
		for i in range(farm.size()):
			var src: Dictionary = f[i] if f[i] is Dictionary else {}
			farm[i] = {
				"tilled": bool(src.get("tilled", false)),
				"type": str(src.get("type", "")),
				"stage": int(src.get("stage", 0)),
				"watered": bool(src.get("watered", false)),
			}

	set_stamina(float(d.get("stamina", stamina)))
	inventory_changed.emit()
	quest_changed.emit()


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
