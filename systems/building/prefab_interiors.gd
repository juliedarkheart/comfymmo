extends RefCounted
class_name PrefabInteriors

## Prefab structure → interior metadata. ONLY prefab shells (cottage, shed,
## workshop, barn) have interiors; freeform modular player builds (walls, roofs,
## floors) deliberately do NOT — a custom shape can't be cleanly mapped into a
## fixed interior (see docs/interiors_strategy.md).
##
## Interiors are prototype-grade: a separate instanced "room view" overlay, not
## a physical space inside the overworld. The player never leaves their world
## position, so exiting returns them exactly where they entered (beside the
## prefab). Owner-safe by construction offline (it's your own placed object);
## decoration/persistence and multiplayer interior sync are documented future
## work.

const TEMPLATE_COTTAGE := "cottage"
const TEMPLATE_SHED := "shed"
const TEMPLATE_WORKSHOP := "workshop"
const TEMPLATE_BARN := "barn"
const VALID_TEMPLATES: Array[String] = [
	TEMPLATE_COTTAGE,
	TEMPLATE_SHED,
	TEMPLATE_WORKSHOP,
	TEMPLATE_BARN,
]

static func _map() -> Dictionary:
	return {
		ContentIds.PLACEABLE_COTTAGE_SHELL: {
			"has_interior": true, "template": TEMPLATE_COTTAGE,
			"interior_scene_id": "interior_cottage", "title": "Cozy Cottage",
		},
		ContentIds.PLACEABLE_STORAGE_SHED: {
			"has_interior": true, "template": TEMPLATE_SHED,
			"interior_scene_id": "interior_shed", "title": "Storage Shed",
		},
		ContentIds.PLACEABLE_WORKSHOP_HUT: {
			"has_interior": true, "template": TEMPLATE_WORKSHOP,
			"interior_scene_id": "interior_workshop", "title": "Workshop",
		},
		ContentIds.PLACEABLE_BARN_SHELL: {
			"has_interior": true, "template": TEMPLATE_BARN,
			"interior_scene_id": "interior_barn", "title": "Barn",
		},
	}

static func parse_metadata_dict(raw: Dictionary) -> Dictionary:
	if not bool(raw.get("has_interior", false)):
		return {}
	var template_id: String = String(raw.get("template", "")).strip_edges()
	var interior_scene_id: String = String(raw.get("interior_scene_id", "")).strip_edges()
	var title: String = String(raw.get("title", "")).strip_edges()
	if not VALID_TEMPLATES.has(template_id):
		return {}
	if interior_scene_id.is_empty() or title.is_empty():
		return {}
	return {
		"has_interior": true,
		"template": template_id,
		"interior_scene_id": interior_scene_id,
		"title": title,
	}

static func all_metadata() -> Dictionary:
	var result: Dictionary = {}
	for placeable_id_variant in _map().keys():
		var placeable_id: String = String(placeable_id_variant)
		var parsed: Dictionary = parse_metadata_dict(_map().get(placeable_id, {}) as Dictionary)
		if not parsed.is_empty():
			result[placeable_id] = parsed
	return result

static func has_interior(placeable_id: String) -> bool:
	return not metadata(placeable_id).is_empty()

static func metadata(placeable_id: String) -> Dictionary:
	return parse_metadata_dict(_map().get(placeable_id, {}) as Dictionary)

static func template_of(placeable_id: String) -> String:
	return String(metadata(placeable_id).get("template", ""))

static func title_of(placeable_id: String) -> String:
	return String(metadata(placeable_id).get("title", ""))
