extends Control

@export var normal_speed: int = 5
@export var fast_speed: int = 100
@export var cheetah_speed: int = 200 

func _ready() -> void:
	DayAndNightCycleManager.time_tick.connect(on_time_tick)


func on_time_tick(day: int, hour: int, minute: int) -> void:
	%DayLabel.text = "Day " + str(day)
	%TimeLabel.text = "%02d:%02d" % [hour, minute]


func _on_normal_speed_button_pressed() -> void:
	DayAndNightCycleManager.game_speed = normal_speed


func _on_fast_speed_button_pressed() -> void:
	DayAndNightCycleManager.game_speed = fast_speed


func _on_cheetah_speed_button_pressed() -> void:
	DayAndNightCycleManager.game_speed = cheetah_speed
