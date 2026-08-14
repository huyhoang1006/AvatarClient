extends Node

signal give_crop_seeds
signal feel_the_animals

func action_give_crop_seeds() -> void:
	give_crop_seeds.emit()


func action_feed_animals() -> void:
	feel_the_animals.emit()
