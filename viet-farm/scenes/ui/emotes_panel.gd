extends Panel

@onready var emote_idle_timer: Timer = $Emote/EmoteIdleTimer


func _ready() -> void:
	InventoryManager.inventory_updated.connect(on_inventory_changed)


func _on_emote_idle_timer_timeout() -> void:
	pass


func on_inventory_changed(_collectable_name: String, _collectable_count: int) -> void:
	pass


func play_talking_animation(_character: String) -> void:
	pass
