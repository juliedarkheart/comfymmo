extends RefCounted
class_name CharacterArtRegistry

## Centralized lookup for live character and creature sprites. The old
## CharacterVisualBuilder remains available as a legacy/dev fallback, but normal
## actors should ask here so the screen does not mix stock/prototype polygon
## bodies with the top-down terrain/object art.

const FALLBACK_PATH := "res://art/placeholders/missing.png"
const CHARACTER_ROOT := "res://art/generated/hearthvale/characters/"
const CREATURE_ROOT := "res://art/generated/hearthvale/creatures/"
const CHARACTER_SCALE := Vector2(0.55, 0.55)
const CREATURE_SCALE := Vector2(0.58, 0.58)

const PLAYER := "player"
const REMOTE_PLAYER := "remote_player"
const MARIBEL := "maribel_tock"
const BRAM := "bram_nettle"
const ROWAN := "rowan"
const LAND_CLERK := "land_clerk"

const MOSS_RABBIT := "moss_rabbit"
const LANTERN_MOTH := "lantern_moth"
const STUMP_TURTLE := "stump_turtle"

const REQUIRED_CHARACTER_IDS: Array[String] = [
	PLAYER,
	REMOTE_PLAYER,
	MARIBEL,
	BRAM,
	ROWAN,
	LAND_CLERK,
]

const REQUIRED_CREATURE_IDS: Array[String] = [
	MOSS_RABBIT,
	LANTERN_MOTH,
	STUMP_TURTLE,
]

const CHARACTER_PATHS := {
	PLAYER: CHARACTER_ROOT + "player.png",
	REMOTE_PLAYER: CHARACTER_ROOT + "remote_player.png",
	MARIBEL: CHARACTER_ROOT + "maribel_tock.png",
	BRAM: CHARACTER_ROOT + "bram_nettle.png",
	ROWAN: CHARACTER_ROOT + "rowan.png",
	LAND_CLERK: CHARACTER_ROOT + "land_clerk.png",
}

const CREATURE_PATHS := {
	MOSS_RABBIT: CREATURE_ROOT + "moss_rabbit.png",
	LANTERN_MOTH: CREATURE_ROOT + "lantern_moth.png",
	STUMP_TURTLE: CREATURE_ROOT + "stump_turtle.png",
}

static func required_character_ids() -> Array[String]:
	return REQUIRED_CHARACTER_IDS.duplicate()

static func required_creature_ids() -> Array[String]:
	return REQUIRED_CREATURE_IDS.duplicate()

static func normalize_id(visual_id: String) -> String:
	return String(visual_id).strip_edges().to_lower()

static func texture_path(visual_id: String) -> String:
	var normalized_id: String = normalize_id(visual_id)
	var mapped: String = String(CHARACTER_PATHS.get(normalized_id, CREATURE_PATHS.get(normalized_id, FALLBACK_PATH)))
	if FileAccess.file_exists(mapped):
		return mapped
	return FALLBACK_PATH

static func texture(visual_id: String) -> Texture2D:
	return load(texture_path(visual_id)) as Texture2D

static func source_of(resolved_path: String) -> String:
	if resolved_path == FALLBACK_PATH:
		return "missing"
	if resolved_path.begins_with(CHARACTER_ROOT) or resolved_path.begins_with(CREATURE_ROOT):
		return "generated"
	return "external"

static func visual_for(visual_id: String) -> Dictionary:
	var normalized_id: String = normalize_id(visual_id)
	var path: String = texture_path(normalized_id)
	return {
		"id": normalized_id,
		"path": path,
		"texture": load(path) as Texture2D,
		"fallback": path == FALLBACK_PATH,
		"source": source_of(path),
		"anchor": anchor_offset(normalized_id),
	}

static func make_sprite(visual_id: String) -> Sprite2D:
	var visual: Dictionary = visual_for(visual_id)
	var tex: Texture2D = visual.get("texture", null) as Texture2D
	if tex == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = "CharacterArt_%s" % String(visual.get("id", "unknown"))
	sprite.texture = tex
	sprite.centered = true
	sprite.position = visual.get("anchor", Vector2.ZERO) as Vector2
	sprite.scale = sprite_scale(String(visual.get("id", visual_id)))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	return sprite

static func apply_sprite(parent: Node2D, visual_id: String) -> bool:
	var sprite := make_sprite(visual_id)
	if sprite == null:
		return false
	parent.add_child(sprite)
	return true

static func anchor_offset(visual_id: String) -> Vector2:
	var normalized_id: String = normalize_id(visual_id)
	if REQUIRED_CREATURE_IDS.has(normalized_id):
		return Vector2(0, -21)
	return Vector2(0, -25)

static func sprite_scale(visual_id: String) -> Vector2:
	var normalized_id: String = normalize_id(visual_id)
	return CREATURE_SCALE if REQUIRED_CREATURE_IDS.has(normalized_id) else CHARACTER_SCALE
