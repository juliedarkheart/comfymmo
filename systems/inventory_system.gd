extends Node
class_name InventorySystem

signal inventory_changed()

var object_registry: ObjectRegistry
var _items: Dictionary = {}

func configure(target_object_registry: ObjectRegistry) -> void:
	object_registry = target_object_registry

func load_from_data(data: Dictionary) -> void:
	var item_quantities: Variant = data.get("items", {})
	_items.clear()
	if typeof(item_quantities) != TYPE_DICTIONARY:
		return

	for item_id in item_quantities.keys():
		_items[String(item_id)] = int(item_quantities[item_id])

func export_state() -> Dictionary:
	return {
		"items": _items,
	}

func add_item(item_id: String, quantity: int = 1) -> void:
	if quantity <= 0:
		return

	_items[item_id] = get_quantity(item_id) + quantity
	inventory_changed.emit()

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or get_quantity(item_id) < quantity:
		return false

	_items[item_id] = get_quantity(item_id) - quantity
	if int(_items[item_id]) <= 0:
		_items.erase(item_id)
	inventory_changed.emit()
	return true

func get_quantity(item_id: String) -> int:
	return int(_items.get(item_id, 0))

func get_count(item_id: String) -> int:
	return get_quantity(item_id)

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_quantity(item_id) >= quantity
