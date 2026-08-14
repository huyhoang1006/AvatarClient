extends Node

var inventory: Dictionary = Dictionary()

signal inventory_updated(collectable_name: String, quantity: int)

func add_collectable(collectable_name: String) -> void:
	inventory.get_or_add(collectable_name)
	
	if inventory[collectable_name] == null:
		inventory[collectable_name] = 1
	else:
		inventory[collectable_name] += 1
	
	inventory_updated.emit(collectable_name, inventory[collectable_name])


func remove_collectable(collectable_name: String) -> void:
	if inventory[collectable_name] == null:
		inventory[collectable_name] = 0
	else:
		if inventory[collectable_name] > 0:
			inventory[collectable_name] -= 1
	
	inventory_updated.emit(collectable_name, inventory[collectable_name])
