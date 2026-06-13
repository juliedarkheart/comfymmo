extends RefCounted
class_name MaterialInventory

## A plain material pouch: id -> count. Two users:
## - The SERVER keeps one per connected player (server-authoritative costs).
## - Validation/tests use it standalone.
## The OFFLINE client does NOT use this class -- offline materials are ordinary
## items in InventorySystem so they persist through the existing player save.

var _counts: Dictionary = {}

static func from_dictionary(data: Dictionary) -> MaterialInventory:
	var inventory: MaterialInventory = MaterialInventory.new()
	for key in data.keys():
		var amount: int = int(data[key])
		if amount > 0 and ResourceIds.is_storable(String(key)):
			inventory._counts[String(key)] = amount
	return inventory

static func starter_pack() -> MaterialInventory:
	# Friendly first-join grant so new multiplayer players can build something
	# right away before they find the gathering spots.
	return from_dictionary({
		ResourceIds.MATERIAL_WOOD: 10,
		ResourceIds.MATERIAL_STONE: 6,
		ResourceIds.MATERIAL_FIBER: 6,
		ResourceIds.MATERIAL_CLAY: 4,
	})

func to_dictionary() -> Dictionary:
	return _counts.duplicate()

func get_count(material_id: String) -> int:
	return int(_counts.get(material_id, 0))

func add(material_id: String, amount: int) -> void:
	if amount <= 0 or not ResourceIds.is_storable(material_id):
		return
	_counts[material_id] = get_count(material_id) + amount

func can_afford(cost: Dictionary) -> bool:
	for material_id in cost.keys():
		if get_count(String(material_id)) < int(cost[material_id]):
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for material_id in cost.keys():
		var key: String = String(material_id)
		_counts[key] = get_count(key) - int(cost[material_id])
		if int(_counts[key]) <= 0:
			_counts.erase(key)
	return true
