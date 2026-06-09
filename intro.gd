extends Control

@onready var image = $TextureRect

var current_image = 1


func _ready():
	play_intro()


func play_intro():

	while current_image <= 18:

		var path = "res://Intro_game/%d.png" % current_image

		print(path)

		image.texture = load(path)

		current_image += 1

		await get_tree().create_timer(2.5).timeout

	print("INTRO DONE")
