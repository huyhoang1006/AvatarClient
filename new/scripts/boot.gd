extends Control

const NEXT_SCENE = "res://scenes/login_screen.tscn"
const FADE_IN_TIME = 0.8
const DISPLAY_TIME = 1.5
const FADE_OUT_TIME = 0.8

func _ready() -> void:
	$BlackBase.visible = true
	$BlackBase.color.a = 1.0

	var tween_in = create_tween()
	tween_in.tween_property($BlackBase, "color:a", 0.0, FADE_IN_TIME)
	await tween_in.finished

	await get_tree().create_timer(DISPLAY_TIME).timeout

	var tween_out = create_tween()
	tween_out.tween_property($BlackBase, "color:a", 1.0, FADE_OUT_TIME)
	await tween_out.finished

	get_tree().change_scene_to_file(NEXT_SCENE)
