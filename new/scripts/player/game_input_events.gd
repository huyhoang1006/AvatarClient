class_name GameInputEvents

static var direction: Vector2

static func movement_input() -> Vector2:
	direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	return direction



static func is_movement_input() -> bool:
	if direction 	== Vector2.ZERO:
		return false
	else:
		return true

static func use_tool() -> bool:
	var use_tool_value: bool = Input.is_action_just_pressed("hit")
	
	return use_tool_value
	
	
