class_name GrowthCycleComponent
extends Node

const MINUTES_PER_HOUR: int = 60

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Germination
## Số ngày ĐƯỢC TƯỚI cần để chín. Bị Crop.gd ghi đè từ CropData khi chạy.
@export_range(1, 365) var days_until_harvest: int = 7
## 0 = tưới theo ngày (nước cạn khi sang ngày mới) — giống Stardew.
## > 0 = nước bay hơi sau ngần này giờ trong game.
@export_range(0, 48) var watering_interval_hours: int = 0

signal growth_state_changed(state: DataTypes.GrowthStates)
signal watered_changed(watered: bool)
signal crop_maturity
signal crop_harvesting

var is_watered: bool = false
## Đếm số ngày cây THỰC SỰ được tưới, không phải số ngày trôi qua.
var watered_days: int = 0
var last_watered_minutes: int = -1


func _ready() -> void:
	DayAndNightCycleManager.time_tick.connect(on_time_tick)
	DayAndNightCycleManager.time_tick_day.connect(on_time_tick_day)


## Gọi hàm này để tưới, đừng gán thẳng is_watered từ bên ngoài.
func water() -> void:
	if is_watered:
		return

	is_watered = true
	last_watered_minutes = current_total_minutes()
	watered_changed.emit(true)


func dry_out() -> void:
	if not is_watered:
		return

	is_watered = false
	watered_changed.emit(false)


func current_total_minutes() -> int:
	return int(DayAndNightCycleManager.time / DayAndNightCycleManager.GAME_MINUTE_DURATION)


func on_time_tick(_day: int, _hour: int, _minute: int) -> void:
	# chỉ dùng khi bật chế độ tưới theo giờ
	if not is_watered or watering_interval_hours <= 0:
		return

	var minutes_since_watered: int = current_total_minutes() - last_watered_minutes
	if minutes_since_watered >= watering_interval_hours * MINUTES_PER_HOUR:
		dry_out()


func on_time_tick_day(_day: int) -> void:
	if not is_watered:
		return

	watered_days += 1
	advance_growth()

	# chế độ theo ngày: nước cạn khi sang ngày mới
	if watering_interval_hours <= 0:
		dry_out()


func advance_growth() -> void:
	if watered_days >= days_until_harvest:
		if set_growth_state(DataTypes.GrowthStates.Harvesting):
			crop_harvesting.emit()
		return

	var state_index: int = mini(watered_days, DataTypes.GrowthStates.Maturity)
	if set_growth_state(state_index as DataTypes.GrowthStates):
		if current_growth_state == DataTypes.GrowthStates.Maturity:
			crop_maturity.emit()


## Trả về true nếu trạng thái thực sự đổi
func set_growth_state(state: DataTypes.GrowthStates) -> bool:
	if current_growth_state == state:
		return false

	current_growth_state = state
	growth_state_changed.emit(state)
	return true


func get_current_growth_state() -> DataTypes.GrowthStates:
	return current_growth_state
