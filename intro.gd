extends Node2D

@onready var side_view = $SideView
@onready var top_view = $TopView
@onready var anim_player = $AnimationPlayer


func _ready():
	anim_player.play("intro")

	if side_view:
		side_view.play("working")

	if top_view:
		top_view.play("working")
