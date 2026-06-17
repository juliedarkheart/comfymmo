extends RefCounted
class_name ObjectArtRegistry

## Centralized lookup for placeable/object/icon sprites. It is intentionally
## data-like so final art can replace placeholders without changing gameplay.

const FALLBACK_PATH := "res://art/placeholders/missing.png"
const OBJECT_SPRITE_SIZE := Vector2i(96, 96)
const ICON_SIZE := Vector2i(64, 64)

## Activated external derivatives live under this root, but are only used when
## ALSO listed in art/active_art_manifest.json (see ArtActivation). Resolution
## order: activated external derivative -> generated placeholder -> missing.
const EXTERNAL_ACTIVE_ROOT := "res://art/generated/from_external/active/"

static func resolve_path(mapped_path: String) -> String:
	var override_path: String = ArtActivation.override_for(mapped_path)
	if not override_path.is_empty():
		return override_path
	if FileAccess.file_exists(mapped_path):
		return mapped_path
	return FALLBACK_PATH

static func source_of(resolved_path: String) -> String:
	if resolved_path == FALLBACK_PATH:
		return "missing"
	if resolved_path.begins_with("res://licensed_assets/"):
		return "licensed"
	if resolved_path.begins_with(EXTERNAL_ACTIVE_ROOT):
		return "external"
	return "generated"

const REQUIRED_OBJECT_IDS: Array[String] = [
	"tree",
	"fruit_tree",
	"rock",
	"bush",
	"flower_patch",
	"water_edge",
	ContentIds.PLACEABLE_CRATE,
	ContentIds.PLACEABLE_MAILBOX,
	ContentIds.PLACEABLE_SIGNPOST,
	ContentIds.PLACEABLE_FENCE_SEGMENT,
	ContentIds.PLACEABLE_FENCE_GATE,
	ContentIds.PLACEABLE_WORKBENCH,
	ContentIds.PLACEABLE_COTTAGE_SHELL,
	ContentIds.PLACEABLE_STORAGE_SHED,
	ContentIds.PLACEABLE_WOOD_WALL,
	ContentIds.PLACEABLE_WOOD_DOOR_WALL,
	ContentIds.PLACEABLE_WOOD_WINDOW_WALL,
	ContentIds.PLACEABLE_STONE_WALL,
	ContentIds.PLACEABLE_FLOOR_DECK,
	ContentIds.PLACEABLE_STONE_FOUNDATION,
	ContentIds.PLACEABLE_WOODEN_PILLAR,
	ContentIds.PLACEABLE_ROOF_CAP,
	ContentIds.PLACEABLE_STEPS,
	ResourceIds.MATERIAL_WOOD,
	ResourceIds.MATERIAL_STONE,
	ResourceIds.MATERIAL_FIBER,
	ResourceIds.MATERIAL_CLAY,
	ItemIds.TOOL_WORN_AXE,
	ItemIds.TOOL_WORN_PICKAXE,
	ItemIds.TOOL_WORN_HOE,
	ItemIds.TOOL_WATERING_CAN,
	ItemIds.TOOL_SIMPLE_HAMMER,
	ItemIds.TOOL_BASIC_SHOVEL,
	ItemIds.QUEST_LAND_TOKEN,
]

const OBJECT_PATHS := {
	"tree": "res://art/objects/nature/tree.png",
	"fruit_tree": "res://art/objects/nature/fruit_tree.png",
	"rock": "res://art/objects/nature/rock.png",
	"bush": "res://art/objects/nature/bush.png",
	"flower_patch": "res://art/objects/nature/flower_patch.png",
	"water_edge": "res://art/objects/nature/water_edge.png",
	"crop_carrot": "res://art/objects/nature/crop_carrot.png",
	ContentIds.ITEM_CARROT: "res://art/objects/nature/crop_carrot.png",
	ContentIds.PLACEABLE_CRATE: "res://art/objects/building/crate.png",
	ContentIds.PLACEABLE_MAILBOX: "res://art/objects/decor/mailbox.png",
	ContentIds.PLACEABLE_SIGNPOST: "res://art/objects/decor/sign.png",
	ContentIds.PLACEABLE_FENCE_SEGMENT: "res://art/objects/decor/fence.png",
	ContentIds.PLACEABLE_FENCE_CORNER: "res://art/objects/decor/fence.png",
	ContentIds.PLACEABLE_FENCE_GATE: "res://art/objects/decor/gate.png",
	ContentIds.PLACEABLE_WORKBENCH: "res://art/objects/building/workbench.png",
	ContentIds.PLACEABLE_COTTAGE_SHELL: "res://art/objects/building/prefab_cottage.png",
	ContentIds.PLACEABLE_STORAGE_SHED: "res://art/objects/building/prefab_shed.png",
	ContentIds.PLACEABLE_WORKSHOP_HUT: "res://art/objects/building/prefab_shed.png",
	ContentIds.PLACEABLE_BARN_SHELL: "res://art/objects/building/prefab_shed.png",
	ContentIds.PLACEABLE_GREENHOUSE_SHELL: "res://art/objects/building/prefab_cottage.png",
	ContentIds.PLACEABLE_WELL: "res://art/objects/building/well.png",
	ContentIds.PLACEABLE_WOOD_WALL: "res://art/objects/building/wall.png",
	ContentIds.PLACEABLE_WOOD_DOOR_WALL: "res://art/objects/building/door_wall.png",
	ContentIds.PLACEABLE_WOOD_WINDOW_WALL: "res://art/objects/building/window_wall.png",
	ContentIds.PLACEABLE_STONE_WALL: "res://art/objects/building/stone_wall.png",
	ContentIds.PLACEABLE_FLOOR_DECK: "res://art/objects/building/floor.png",
	ContentIds.PLACEABLE_STONE_FOUNDATION: "res://art/objects/building/foundation.png",
	ContentIds.PLACEABLE_WOODEN_PILLAR: "res://art/objects/building/post.png",
	ContentIds.PLACEABLE_ROOF_CAP: "res://art/objects/building/roof.png",
	ContentIds.PLACEABLE_STEPS: "res://art/objects/building/stairs.png",
	ContentIds.PLACEABLE_DIRT_PATH: "res://art/tiles/paths/dirt_path.png",
	ContentIds.PLACEABLE_STONE_PATH: "res://art/tiles/paths/stone_path.png",
	ContentIds.PLACEABLE_GRASS_PATCH: "res://art/tiles/biomes/meadow.png",
	ContentIds.PLACEABLE_FLOWER_MEADOW: "res://art/tiles/biomes/orchard.png",
	ContentIds.PLACEABLE_PLAZA_TILE: "res://art/tiles/paths/stone_path.png",
	ContentIds.PLACEABLE_FOREST_FLOOR: "res://art/tiles/biomes/forest.png",
	ResourceIds.MATERIAL_WOOD: "res://art/ui/icons/wood.png",
	ResourceIds.MATERIAL_STONE: "res://art/ui/icons/stone.png",
	ResourceIds.MATERIAL_FIBER: "res://art/ui/icons/fiber.png",
	ResourceIds.MATERIAL_CLAY: "res://art/ui/icons/clay.png",
	ItemIds.TOOL_WORN_AXE: "res://art/ui/icons/worn_axe.png",
	ItemIds.TOOL_WORN_PICKAXE: "res://art/ui/icons/worn_pickaxe.png",
	ItemIds.TOOL_WORN_HOE: "res://art/ui/icons/worn_hoe.png",
	ItemIds.TOOL_WATERING_CAN: "res://art/ui/icons/watering_can.png",
	ItemIds.TOOL_SIMPLE_HAMMER: "res://art/ui/icons/simple_hammer.png",
	ItemIds.TOOL_BASIC_SHOVEL: "res://art/ui/icons/basic_shovel.png",
	ItemIds.QUEST_LAND_TOKEN: "res://art/ui/icons/land_token.png",
	"build_tool": "res://art/ui/icons/build_tool.png",
	"delete": "res://art/ui/icons/delete.png",
	"rotate": "res://art/ui/icons/rotate.png",
}

static func required_ids() -> Array[String]:
	return REQUIRED_OBJECT_IDS.duplicate()

static func normalize_id(object_id: String) -> String:
	return String(object_id).strip_edges().to_lower()

static func has_art_id(object_id: String) -> bool:
	return OBJECT_PATHS.has(normalize_id(object_id))

static func texture_path(object_id: String) -> String:
	return resolve_path(String(OBJECT_PATHS.get(normalize_id(object_id), FALLBACK_PATH)))

static func texture(object_id: String) -> Texture2D:
	return load(texture_path(object_id)) as Texture2D

static func visual_for(object_id: String) -> Dictionary:
	var normalized_id: String = normalize_id(object_id)
	var path: String = texture_path(normalized_id)
	return {
		"id": normalized_id,
		"path": path,
		"texture": load(path) as Texture2D,
		"fallback": path == FALLBACK_PATH,
		"anchor": anchor_offset(normalized_id),
		"sprite_size": ICON_SIZE if _is_icon_id(normalized_id) else OBJECT_SPRITE_SIZE,
	}

static func make_sprite(object_id: String) -> Sprite2D:
	var visual: Dictionary = visual_for(object_id)
	var tex: Texture2D = visual.get("texture", null) as Texture2D
	if tex == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = "RegistryArtSprite"
	sprite.texture = tex
	sprite.centered = true
	sprite.position = visual.get("anchor", Vector2.ZERO) as Vector2
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = _z_index_for(normalize_id(object_id))
	return sprite

static func apply_sprite(parent: Node2D, object_id: String) -> bool:
	var sprite := make_sprite(object_id)
	if sprite == null:
		return false
	parent.add_child(sprite)
	return true

static func anchor_offset(object_id: String) -> Vector2:
	var normalized_id: String = normalize_id(object_id)
	if _is_terrain_placeable(normalized_id):
		return Vector2.ZERO
	if normalized_id == ContentIds.PLACEABLE_FLOOR_DECK or normalized_id == ContentIds.PLACEABLE_STONE_FOUNDATION:
		return Vector2(0, -16)
	if _is_icon_id(normalized_id):
		return Vector2.ZERO
	return Vector2(0, -30)

static func _z_index_for(object_id: String) -> int:
	if _is_terrain_placeable(object_id):
		return -2
	return 1

static func _is_terrain_placeable(object_id: String) -> bool:
	return [
		ContentIds.PLACEABLE_DIRT_PATH,
		ContentIds.PLACEABLE_STONE_PATH,
		ContentIds.PLACEABLE_GRASS_PATCH,
		ContentIds.PLACEABLE_FLOWER_MEADOW,
		ContentIds.PLACEABLE_PLAZA_TILE,
		ContentIds.PLACEABLE_FOREST_FLOOR,
	].has(object_id)

static func _is_icon_id(object_id: String) -> bool:
	return ResourceIds.is_storable(object_id) or ItemIds.is_equipment(object_id) or [
		"build_tool",
		"delete",
		"rotate",
	].has(object_id)
