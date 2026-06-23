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

## Original, committable Hearthvale top-down object/decor sprites. In the live
## top-down game these are preferred over the legacy 96x48 prototype placeholders
## under art/objects/ (and over legacy art/tiles/ art for terrain-placeables), so
## a clean checkout still reads as a coherent top-down world. Order:
## licensed Sprout -> Hearthvale top-down generated -> legacy placeholder -> missing.
const HEARTHVALE_OBJECT_ROOT := "res://art/generated/hearthvale/objects/"
const HEARTHVALE_TERRAIN_ROOT := "res://art/generated/hearthvale/terrain/"
const LEGACY_OBJECT_ROOT := "res://art/objects/"
const LEGACY_TILE_ROOT := "res://art/tiles/"
const HEARTHVALE_GENERATED_ICON_ROOT := "res://licensed_assets/limezu/generator_outputs/hearthvale_generated/item_icons/"

const LIMEZU_ICON_IDS := {
	ContentIds.ITEM_CARROT: "icon.carrot",
	ResourceIds.MATERIAL_WOOD: "icon.wood",
	ResourceIds.COMPONENT_SEED_PACKET: "icon.seed",
	ContentIds.ITEM_PLACEHOLDER_SEED_PACKET: "icon.seed",
	ItemIds.TOOL_WORN_AXE: "icon.tool_axe",
	ItemIds.TOOL_WATERING_CAN: "icon.tool_watering_can",
	ItemIds.TOOL_BASIC_SHOVEL: "icon.tool_shovel",
}

const HEARTHVALE_GENERATED_ICON_PATHS := {
	ItemIds.TOOL_WORN_AXE: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_axe_16px.png",
	ItemIds.TOOL_WORN_PICKAXE: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_pickaxe_16px.png",
	ItemIds.TOOL_WORN_HOE: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_hoe_16px.png",
	ItemIds.TOOL_WATERING_CAN: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_watering_can_16px.png",
	ItemIds.TOOL_SIMPLE_HAMMER: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_generic_tool_16px.png",
	ItemIds.TOOL_BASIC_SHOVEL: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_shovel_16px.png",
	ResourceIds.COMPONENT_SEED_PACKET: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_generic_seed_16px.png",
	ContentIds.ITEM_PLACEHOLDER_SEED_PACKET: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_generic_seed_16px.png",
	ContentIds.ITEM_TURNIP: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_turnip_16px.png",
	ContentIds.ITEM_BERRY: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_berry_16px.png",
	ResourceIds.MATERIAL_WOOD: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_log_16px.png",
	ResourceIds.MATERIAL_STONE: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_stone_16px.png",
	ResourceIds.MATERIAL_FIBER: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_leaf_16px.png",
	ResourceIds.MATERIAL_CLAY: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_clay_16px.png",
	ItemIds.WEARABLE_LEAF_CLIP: HEARTHVALE_GENERATED_ICON_ROOT + "item_icon_wearable_leaf_clip_16px.png",
}

static func _hearthvale_object_path(mapped_path: String) -> String:
	var candidate: String = ""
	if mapped_path.begins_with(LEGACY_OBJECT_ROOT):
		candidate = HEARTHVALE_OBJECT_ROOT + mapped_path.substr(LEGACY_OBJECT_ROOT.length())
	elif mapped_path.begins_with(LEGACY_TILE_ROOT):
		candidate = HEARTHVALE_TERRAIN_ROOT + mapped_path.get_file()
	if not candidate.is_empty() and FileAccess.file_exists(candidate):
		return candidate
	return ""

static func resolve_path(mapped_path: String, force_allow_sprout: bool = false) -> String:
	var override_path: String = ArtActivation.override_for(
		mapped_path,
		force_allow_sprout or LiveVisualPolicy.should_auto_use_sprout_visuals()
	)
	if not override_path.is_empty():
		return override_path
	var hearthvale_path: String = _hearthvale_object_path(mapped_path)
	if not hearthvale_path.is_empty():
		return hearthvale_path
	if FileAccess.file_exists(mapped_path):
		return mapped_path
	return FALLBACK_PATH

static func source_of(resolved_path: String) -> String:
	if resolved_path == FALLBACK_PATH:
		return "missing"
	if resolved_path.begins_with("res://licensed_assets/"):
		if resolved_path.contains("/generator_outputs/hearthvale_generated/"):
			return "hearthvale_generated_local"
		return "licensed_modified" if resolved_path.contains("/modified/") else "licensed"
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
	# Decoration-only ids (no legacy placeholder) — original Hearthvale top-down
	# sprites the world map drawers use instead of procedural polygons.
	"pine": "res://art/generated/hearthvale/objects/nature/pine.png",
	"mushroom": "res://art/generated/hearthvale/objects/nature/mushroom.png",
	"grass_tuft": "res://art/generated/hearthvale/objects/nature/grass_tuft.png",
	"stump": "res://art/generated/hearthvale/objects/nature/stump.png",
}

static func required_ids() -> Array[String]:
	return REQUIRED_OBJECT_IDS.duplicate()

static func normalize_id(object_id: String) -> String:
	return String(object_id).strip_edges().to_lower()

static func has_art_id(object_id: String) -> bool:
	return OBJECT_PATHS.has(normalize_id(object_id))

static func texture_path(object_id: String, force_allow_sprout: bool = false) -> String:
	return resolve_path(String(OBJECT_PATHS.get(normalize_id(object_id), FALLBACK_PATH)), force_allow_sprout)

static func texture(object_id: String, force_allow_sprout: bool = false) -> Texture2D:
	return load(texture_path(object_id, force_allow_sprout)) as Texture2D

static func generated_icon_path_for_item(item_id: String) -> String:
	var path: String = String(HEARTHVALE_GENERATED_ICON_PATHS.get(normalize_id(item_id), ""))
	return path if not path.is_empty() and FileAccess.file_exists(path) else ""

static func limezu_icon_id_for_item(item_id: String) -> String:
	var limezu_id: String = String(LIMEZU_ICON_IDS.get(normalize_id(item_id), ""))
	if limezu_id.is_empty() or not LimeZuArtRegistry.has_asset(limezu_id):
		return ""
	return limezu_id

static func icon_texture_for_item(item_id: String) -> Texture2D:
	if item_id.is_empty():
		return null
	var limezu_id := limezu_icon_id_for_item(item_id)
	if not limezu_id.is_empty():
		return LimeZuArtRegistry.resolve_texture(limezu_id)
	var generated_path := generated_icon_path_for_item(item_id)
	if not generated_path.is_empty():
		return _load_unimported_png(generated_path)
	var path := texture_path(item_id)
	if path == FALLBACK_PATH:
		return null
	return load(path) as Texture2D

static func icon_source_for_item(item_id: String) -> String:
	if item_id.is_empty():
		return "empty"
	if not limezu_icon_id_for_item(item_id).is_empty():
		return "limezu"
	var generated_path := generated_icon_path_for_item(item_id)
	if not generated_path.is_empty():
		return source_of(generated_path)
	var path := texture_path(item_id)
	return source_of(path)

static func _load_unimported_png(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)

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
	if LiveVisualPolicy.live_limezu_slice():
		return 0
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
