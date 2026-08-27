extends Control

## Hệ số nhân so với tốc độ chuẩn (Stardew). 1.0 = nhịp thật của game.
@export var normal_speed_multiplier: float = 1.0
## Dùng để test, không phải tốc độ chơi thật
@export var fast_speed_multiplier: float = 20.0
## Dùng để test, không phải tốc độ chơi thật
@export var cheetah_speed_multiplier: float = 40.0


func _ready() -> void:
	DayAndNightCycleManager.time_tick.connect(on_time_tick)


func on_time_tick(day: int, hour: int, minute: int) -> void:
	%DayLabel.text = "Day " + str(day)
	%TimeLabel.text = "%02d:%02d" % [hour, minute]


func set_speed_multiplier(multiplier: float) -> void:
	DayAndNightCycleManager.game_speed = DayAndNightCycleManager.NORMAL_GAME_SPEED * multiplier


func _on_normal_speed_button_pressed() -> void:
	set_speed_multiplier(normal_speed_multiplier)


func _on_fast_speed_button_pressed() -> void:
	set_speed_multiplier(fast_speed_multiplier)


func _on_cheetah_speed_button_pressed() -> void:
	set_speed_multiplier(cheetah_speed_multiplier)
