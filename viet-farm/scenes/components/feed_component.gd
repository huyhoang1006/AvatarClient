class_name FeedComponent
extends Area2D

signal food_receive(area: Area2D)


func _on_area_entered(area: Area2D) -> void:
	food_receive.emit(area)
