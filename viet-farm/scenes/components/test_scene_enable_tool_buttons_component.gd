extends Node

func _ready() -> void:
	call_deferred("enable_tool_buttons")


func enable_tool_buttons() -> void:
	ToolManager.enable_all()
