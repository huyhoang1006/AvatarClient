extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

## Công cụ đang cầm → state chuyển sang khi bấm chuột.
## Thêm công cụ mới chỉ cần thêm 1 dòng ở đây.
const TOOL_STATES: Dictionary = {
	DataTypes.Tools.AxeWood: "Chopping",
	DataTypes.Tools.TillGround: "Tilling",
	DataTypes.Tools.WaterCrops: "Watering",
	DataTypes.Tools.FishingRod: "Fishing",
}


func _on_physics_process(_delta: float) -> void:
	player.play_directional("idle")


func _on_next_transitions() -> void:
	GameInputEvents.movement_input()

	if GameInputEvents.is_movement_input():
		transition.emit("Walk")
		return

	if GameInputEvents.use_tool() and TOOL_STATES.has(player.current_tool):
		transition.emit(TOOL_STATES[player.current_tool])


func _on_enter() -> void:
	player.update_fishing_rod_visual()


func _on_exit() -> void:
	animated_sprite_2d.stop()
