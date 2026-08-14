extends StaticBody2D

signal gate_toggled(is_open: bool)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_left: Sprite2D = $SpriteLeft
@onready var sprite_right: Sprite2D = $SpriteRight
@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var interactable_label_component: Control = $InteractableLabelComponent

var in_range: bool = false
var is_open: bool = false


func _ready() -> void:
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	on_interactable_deactivated()


func on_interactable_activated() -> void:
	in_range = true
	interactable_label_component.show()


func on_interactable_deactivated() -> void:
	in_range = false
	interactable_label_component.hide()


func _unhandled_input(event: InputEvent) -> void:
	if in_range and event.is_action_pressed("show_dialogue"):
		set_open(not is_open)


func set_open(open: bool) -> void:
	is_open = open
	collision_shape_2d.disabled = is_open
	sprite_left.visible = not is_open
	sprite_right.visible = not is_open
	gate_toggled.emit(is_open)
