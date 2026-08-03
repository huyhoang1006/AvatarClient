extends Node2D

const NEXT_SCENE = "res://scenes/login_screen.tscn"
const DISPLAY_TIME = 1.5
const FADE_TIME = 0.5

func _ready():
	$Logo.modulate.a = 0

	var tween_in = create_tween()
	tween_in.tween_property($Logo, "modulate:a", 1.0, FADE_TIME)
	await tween_in.finished

	await get_tree().create_timer(DISPLAY_TIME).timeout

	var tween_out = create_tween()
	tween_out.tween_property($Logo, "modulate:a", 0.0, FADE_TIME)
	await tween_out.finished

	get_tree().change_scene_to_file(NEXT_SCENE)
