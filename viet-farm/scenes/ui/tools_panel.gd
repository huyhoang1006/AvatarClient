extends PanelContainer

const TOOL_BUTTONS := {
	DataTypes.Tools.AxeWood: &"ToolAxe",
	DataTypes.Tools.TillGround: &"ToolTilling",
	DataTypes.Tools.WaterCrops: &"ToolWateringCan",
	DataTypes.Tools.PlantCorn: &"ToolCorn",
	DataTypes.Tools.PlantTomato: &"ToolTomato",
	DataTypes.Tools.FishingRod: &"ToolFishingRod",
}


func _ready() -> void:
	ToolManager.enable_tool.connect(on_enable_tool_button)
	ToolManager.tool_selected.connect(on_tool_selected)

	on_tool_selected(ToolManager.selected_tool)


func _on_tool_axe_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.AxeWood)


func _on_tool_tilling_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.TillGround)


func _on_tool_watering_can_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.WaterCrops)


func _on_tool_corn_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.PlantCorn)


func _on_tool_tomato_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.PlantTomato)


func _on_tool_fishing_rod_pressed() -> void:
	ToolManager.select_tool(DataTypes.Tools.FishingRod)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		ToolManager.select_tool(DataTypes.Tools.None)


func on_tool_selected(tool: DataTypes.Tools) -> void:
	for tool_type: DataTypes.Tools in TOOL_BUTTONS:
		var button: Button = get_node("%" + TOOL_BUTTONS[tool_type])
		var is_selected := tool == tool_type
		button.theme_type_variation = &"ToolButtonSelected" if is_selected else &"ToolButton"


func on_enable_tool_button(tool: DataTypes.Tools) -> void:
	if tool == DataTypes.Tools.TillGround:
		%ToolTilling.disabled = false

	if tool == DataTypes.Tools.WaterCrops:
		%ToolWateringCan.disabled = false

	if tool == DataTypes.Tools.PlantTomato:
		%ToolTomato.disabled = false

	if tool == DataTypes.Tools.PlantCorn:
		%ToolCorn.disabled = false
