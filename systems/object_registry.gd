extends Node
class_name ObjectRegistry

const PLACEABLE_CRATE_SCENE := preload("res://scenes/buildings/placeable_crate.tscn")
const PLACEABLE_MAILBOX_SCENE := preload("res://scenes/buildings/placeable_mailbox.tscn")
const PLACEABLE_STOOL_SCENE := preload("res://scenes/buildings/placeable_stool.tscn")
const PLACEABLE_LANTERN_SCENE := preload("res://scenes/buildings/placeable_lantern.tscn")
const PLACEABLE_PLANTER_SCENE := preload("res://scenes/buildings/placeable_planter.tscn")

var _placeable_catalog: Dictionary = {}
var _placeable_ids: Array[String] = []
var _item_definitions: Dictionary = {}

func _ready() -> void:
	_register_defaults()

func has_placeable(placeable_id: String) -> bool:
	return _placeable_catalog.has(placeable_id)

func get_placeable_data(placeable_id: String) -> PlaceableObjectData:
	if not _placeable_catalog.has(placeable_id):
		return null

	return _placeable_catalog[placeable_id] as PlaceableObjectData

func get_placeable_ids() -> Array[String]:
	var placeable_ids: Array[String] = []
	placeable_ids.append_array(_placeable_ids)
	return placeable_ids

func get_item_definition(item_id: String) -> Dictionary:
	if not _item_definitions.has(item_id):
		return {}

	return _item_definitions[item_id] as Dictionary

func get_item_ids() -> Array[String]:
	var item_ids: Array[String] = []
	for item_id in _item_definitions.keys():
		item_ids.append(String(item_id))
	return item_ids

func _register_defaults() -> void:
	if not _placeable_ids.is_empty():
		return

	# Ids come from ContentIds (stable, save-compatible). Values are unchanged.
	_register_placeable(ContentIds.PLACEABLE_CRATE, "Wooden Crate", Vector2i.ONE, PLACEABLE_CRATE_SCENE)
	_register_placeable(ContentIds.PLACEABLE_MAILBOX, "Cozy Mailbox", Vector2i.ONE, PLACEABLE_MAILBOX_SCENE)
	_register_placeable(ContentIds.PLACEABLE_STOOL, "Small Stool", Vector2i.ONE, PLACEABLE_STOOL_SCENE)
	_register_placeable(ContentIds.PLACEABLE_LANTERN, "Porch Lantern", Vector2i.ONE, PLACEABLE_LANTERN_SCENE)
	_register_placeable(ContentIds.PLACEABLE_PLANTER, "Cozy Planter", Vector2i.ONE, PLACEABLE_PLANTER_SCENE)

	# Cozy decor set: scene paths + display names come from ContentRegistry so
	# the catalog, registry metadata, and build costs stay in lockstep.
	for decor_id in ContentIds.DECOR_PLACEABLE_IDS:
		var entry: Dictionary = ContentRegistry.placeables().get(decor_id, {}) as Dictionary
		if entry.is_empty():
			push_warning("Decor placeable missing from ContentRegistry: %s" % decor_id)
			continue
		var scene: PackedScene = load(String(entry.get("scene_path", ""))) as PackedScene
		if scene == null:
			push_warning("Decor placeable scene failed to load: %s" % decor_id)
			continue
		_register_placeable(decor_id, String(entry.get("display_name", decor_id)), ContentRegistry.placeable_footprint(decor_id), scene)

	_item_definitions[ContentIds.ITEM_PLACEHOLDER_SEED_PACKET] = {
		"id": ContentIds.ITEM_PLACEHOLDER_SEED_PACKET,
		"display_name": "Placeholder Seed Packet",
		"tags": ["placeholder", "farming"],
	}
	_item_definitions[ContentIds.ITEM_MAIL_TOKEN] = {
		"id": ContentIds.ITEM_MAIL_TOKEN,
		"display_name": "Mail Token",
		"tags": ["placeholder", "task"],
	}
	_item_definitions[ContentIds.ITEM_CARROT] = {
		"id": ContentIds.ITEM_CARROT,
		"display_name": "Carrot",
		"tags": ["farming", "crop", "food"],
	}
	_item_definitions[ContentIds.ITEM_TURNIP] = {
		"id": ContentIds.ITEM_TURNIP,
		"display_name": "Turnip",
		"tags": ["farming", "crop", "food"],
	}
	_item_definitions[ContentIds.ITEM_BERRY] = {
		"id": ContentIds.ITEM_BERRY,
		"display_name": "Berry",
		"tags": ["farming", "crop", "food"],
	}

func _register_placeable(placeable_id: String, display_name: String, footprint: Vector2i, scene: PackedScene) -> void:
	var placeable_data: PlaceableObjectData = PlaceableObjectData.new()
	placeable_data.id = placeable_id
	placeable_data.display_name = display_name
	placeable_data.footprint = footprint
	placeable_data.scene = scene
	_placeable_catalog[placeable_id] = placeable_data
	_placeable_ids.append(placeable_id)
