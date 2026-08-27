class_name DayNightCycleComponent
extends CanvasModulate

@export var initial_day: int = 1:
	set(id):
		initial_day = id
		DayAndNightCycleManager.initial_day = id
		DayAndNightCycleManager.set_initial_time()

## 6 giờ sáng — giống Stardew, và khớp với giờ thức dậy sau khi ngủ (bed.gd)
@export var initial_hour: int = 6:
	set(ih):
		initial_hour = ih
		DayAndNightCycleManager.initial_hour = ih
		DayAndNightCycleManager.set_initial_time()

@export var initial_minute: int = 0:
	set(im):
		initial_minute = im
		DayAndNightCycleManager.initial_minute = im
		DayAndNightCycleManager.set_initial_time()

@export var day_night_gradient_texture: GradientTexture2D


func _ready() -> void:
	DayAndNightCycleManager.initial_day = initial_day
	DayAndNightCycleManager.initial_hour = initial_hour
	DayAndNightCycleManager.initial_minute = initial_minute
	DayAndNightCycleManager.set_initial_time()

	DayAndNightCycleManager.game_time.connect(on_game_time)


func on_game_time(time: float) -> void:
	var sample_value: float = 0.5 * (sin(time - PI * 0.5) + 1)
	color = day_night_gradient_texture.gradient.sample(sample_value)
