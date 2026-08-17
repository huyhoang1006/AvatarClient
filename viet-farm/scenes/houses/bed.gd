extends Node2D

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableLabelComponent
@onready var sleep_position: Marker2D = $SleepPosition
@onready var wake_position: Marker2D = $WakePosition

var in_range: bool = false
var is_sleeping: bool = false


func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()


func on_interactable_activated() -> void:
	in_range = true
	interactable_label_component.show()


func on_interactable_deactivated() -> void:
	in_range = false
	interactable_label_component.hide()


func _unhandled_input(event: InputEvent) -> void:
	if in_range and not is_sleeping and event.is_action_pressed("show_dialogue"):
		start_sleep()


func start_sleep() -> void:
	is_sleeping = true
	var player: Player = get_tree().get_first_node_in_group("player")
	if player:
		player.control_enabled = false
		player.player_direction = Vector2.UP
		player.global_position = sleep_position.global_position

	var fade := create_fade_overlay()
	await fade_to(fade, 1.0)

	DayAndNightCycleManager.advance_to_next_day()
	SaveGameManager.save_game()

	await get_tree().create_timer(0.5).timeout

	if player:
		player.global_position = wake_position.global_position
		player.control_enabled = true

	await fade_to(fade, 0.0)
	fade.queue_free()
	is_sleeping = false


func create_fade_overlay() -> CanvasLayer:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	var rect := ColorRect.new()
	rect.name = "FadeRect"
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(rect)
	get_tree().root.add_child(canvas_layer)
	return canvas_layer


func fade_to(canvas_layer: CanvasLayer, alpha: float) -> void:
	var rect: ColorRect = canvas_layer.get_node("FadeRect")
	var tween := create_tween()
	tween.tween_property(rect, "color:a", alpha, 0.6)
	await tween.finished
