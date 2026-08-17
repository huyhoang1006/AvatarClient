extends Node

const EXTERIOR_NODES: Array[String] = [
	"GameTilemap",
	"FieldCursorComponent",
	"CropsCursorComponent",
	"CropFields",
	"ChickenPen",
	"CowPen",
	"Cows",
	"Chickens",
	"Houses",
	"Guide",
	"ChickenRewardBox",
	"CowRewardBox",
]

var is_inside: bool = false


func enter_house() -> void:
	if is_inside:
		return
	var interior: Node2D = find_interior()
	if interior == null:
		return
	set_exterior_visible(false)
	interior.visible = true
	var background: CanvasLayer = interior.get_node_or_null("../Background") as CanvasLayer
	if background:
		background.visible = true
	var player: Node2D = get_player()
	if player:
		var spawn: Marker2D = interior.get_node_or_null("SpawnPoint")
		player.global_position = spawn.global_position if spawn else interior.global_position
	is_inside = true


func exit_house() -> void:
	if not is_inside:
		return
	var interior: Node2D = find_interior()
	if interior == null:
		return
	interior.visible = false
	var background: CanvasLayer = interior.get_node_or_null("../Background") as CanvasLayer
	if background:
		background.visible = false
	set_exterior_visible(true)
	var player: Node2D = get_player()
	if player:
		var exit_spawn: Marker2D = find_house_exit_spawn()
		if exit_spawn:
			player.global_position = exit_spawn.global_position
	is_inside = false


func find_interior() -> Node2D:
	var level: Node = get_tree().current_scene
	if level == null:
		return null
	return level.find_child("HouseInterior", true, false) as Node2D


func find_house_exit_spawn() -> Marker2D:
	var level: Node = get_tree().current_scene
	if level == null:
		return null
	return level.find_child("HouseExitSpawn", true, false) as Marker2D


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func set_exterior_visible(visible: bool) -> void:
	var level: Node = get_tree().current_scene
	var level_1: Node = level.find_child("Level1", true, false) if level != null else null
	if level_1 == null:
		return
	for node_name in EXTERIOR_NODES:
		var node: Node = level_1.get_node_or_null(node_name)
		if node == null:
			continue
		if node is CanvasItem:
			node.visible = visible
		else:
			node.process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED
