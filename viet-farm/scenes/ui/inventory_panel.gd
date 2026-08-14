extends PanelContainer

@onready var labels = {
	"log": %LogLabel,
	"stone": %StoneLabel,	
	"egg": %EggLabel,	
	"milk": %MilkLabel,	
	"corn": %CornLabel,	
	"tomato": %TomatoLabel,
	"fish": %FishLabel
}

func _ready() -> void:
	InventoryManager.inventory_updated.connect(on_inventory_updated)


func on_inventory_updated(collectable_name: String, quantity: int) -> void:
	if labels.has(collectable_name):
		labels[collectable_name].text = str(quantity)
