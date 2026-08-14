class_name GrowthCycleComponent
extends Node

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Germination
@export_range(5,365) var days_until_harvest: int = 7

signal crop_maturity
signal crop_harvesting

var is_watered: bool
var starting_day: int = 0


func _ready() -> void:
	DayAndNightCycleManager.time_tick_day.connect(on_time_tick_day)


func on_time_tick_day(day: int) -> void:
	if is_watered:
		if starting_day == 0:
			starting_day = day
		growth_states(starting_day, day)
		harvest_state(starting_day, day)


func growth_states(first_day: int, current_day: int) -> void:
	if current_growth_state >= DataTypes.GrowthStates.Maturity:
		return

	var growth_days_passed: int = current_day - first_day
	var state_index: int = growth_days_passed + 1

	current_growth_state = state_index as DataTypes.GrowthStates

	if current_growth_state == DataTypes.GrowthStates.Maturity:
		crop_maturity.emit()


func harvest_state(first_day: int, current_day: int) -> void:
	if current_growth_state == DataTypes.GrowthStates.Harvesting:
		return

	var days_passed: int = current_day - first_day
	if days_passed >= days_until_harvest:
		current_growth_state = DataTypes.GrowthStates.Harvesting
		crop_harvesting.emit()


func get_current_growth_state() -> DataTypes.GrowthStates:
	return current_growth_state
