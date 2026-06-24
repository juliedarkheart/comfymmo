extends RefCounted
class_name CharacterPartLibrary

## Maps CharacterAppearance option ids -> LimeZu Modern Interiors "Character_Generator" LAYER
## files so the player avatar renders as composited layers (body + eyes + outfit + hair +
## accessory) that ACTUALLY change when the editor changes a field. The generator parts all share
## one 16x32 frame grid and are designed to stack in the order body -> eyes -> outfit -> hair ->
## accessory (per the pack's HOW_TO guide).
##
## Pure data + path resolution; textures load via Image (the extracted PNGs). Clean-checkout safe:
## when the pack is absent, available() is false and the avatar falls back to the farmer sprite /
## generated body. This is a SMALL real vertical slice — full per-part catalogs are future scope.

const CG := "res://licensed_assets/limezu/modern_interiors/extracted/moderninteriors-win/2_Characters/Character_Generator/"
const FRAME := Vector2i(16, 32)

# Layer z-order (relative); held tool (z 3 on the AvatarVisual) + name label stay separate.
const Z_BODY := 0
const Z_EYES := 1
const Z_OUTFIT := 2
const Z_HAIR := 3
const Z_ACCESSORY := 4

# Skin tone -> full body sheet.
const BODY_BY_SKIN := {
	"peach": "Bodies/16x16/Body_01.png",
	"honey": "Bodies/16x16/Body_05.png",
	"umber": "Bodies/16x16/Body_08.png",
}
const DEFAULT_BODY := "Bodies/16x16/Body_01.png"
const EYES := "Eyes/16x16/Eyes_01.png"

# Appearance hair_style id -> Hairstyle GROUP number (each group has 7 colour variants _01.._07).
const HAIR_GROUP := {
	"round_bob": 1, "fluffy_short": 3, "soft_curls": 7,
	"leafy_pigtails": 10, "cozy_bun": 12, "wavy_shag": 5,
}
# Appearance outfit_style id -> Outfit GROUP number (each group has colour variants).
const OUTFIT_GROUP := {
	"starter_overalls": 1, "cozy_tunic": 3, "forest_apron": 5,
	"village_dress": 8, "mushroom_sweater": 10, "gardener_jacket": 6,
}
# Palette colour id -> generator colour-variant index (1..7).
const COLOR_VARIANT := {
	"blush_pink": 1, "moss_green": 2, "sky_blue": 3, "warm_brown": 4, "lavender": 5,
	"cream": 6, "terracotta": 7, "butter_yellow": 1, "berry_red": 7, "pond_blue": 3,
	"lilac": 5, "soft_black": 4, "warm_white": 6,
}
# Accessory/hat appearance id -> generator accessory file ("" = no layer = hat off).
const ACCESSORY_FILE := {
	"none": "",
	"tiny_hat": "Accessories/16x16/Accessory_11_Beanie_01.png",
	"acorn_cap": "Accessories/16x16/Accessory_04_Snapback_01.png",
	"round_glasses": "Accessories/16x16/Accessory_15_Glasses_01.png",
	"flower_pin": "Accessories/16x16/Accessory_15_Glasses_03.png",
	"leaf_clip": "",
}

# Body/presentation presets -> default appearance overrides. The player default (Julie) is
# neutral-feminine, never forced masculine.
const PRESENTATION_PRESETS := {
	"feminine": {"hair_style": "leafy_pigtails", "outfit_style": "village_dress", "skin_tone": "peach"},
	"neutral": {"hair_style": "wavy_shag", "outfit_style": "gardener_jacket", "skin_tone": "honey"},
	"masculine": {"hair_style": "fluffy_short", "outfit_style": "starter_overalls", "skin_tone": "umber"},
}

static func _abs(rel: String) -> String:
	return CG + rel

static func _exists(rel: String) -> bool:
	if rel.is_empty():
		return false
	return FileAccess.file_exists(_abs(rel))

## True when the layered generator pack is installed (else the avatar uses the farmer fallback).
static func available() -> bool:
	return _exists(DEFAULT_BODY) and _exists(EYES)

static func _color_variant(color_id: String) -> int:
	return int(COLOR_VARIANT.get(color_id, 1))

static func _hair_rel(appearance: Dictionary) -> String:
	var group: int = int(HAIR_GROUP.get(String(appearance.get("hair_style", "")), 1))
	return "Hairstyles/16x16/Hairstyle_%02d_%02d.png" % [group, _color_variant(String(appearance.get("hair_color", "warm_brown")))]

static func _outfit_rel(appearance: Dictionary) -> String:
	var group: int = int(OUTFIT_GROUP.get(String(appearance.get("outfit_style", "")), 1))
	return "Outfits/16x16/Outfit_%02d_%02d.png" % [group, _color_variant(String(appearance.get("outfit_color", "moss_green")))]

static func _body_rel(appearance: Dictionary) -> String:
	return String(BODY_BY_SKIN.get(String(appearance.get("skin_tone", "peach")), DEFAULT_BODY))

static func _accessory_rel(appearance: Dictionary) -> String:
	return String(ACCESSORY_FILE.get(String(appearance.get("accessory", "none")), ""))

## Ordered render layers for an appearance: [{res_path, z, layer, rel}]. Missing parts (e.g. a
## hairstyle colour variant that doesn't exist) are skipped so the avatar still renders.
static func layers_for(appearance: Dictionary) -> Array:
	var out: Array = []
	var plan := [
		[_body_rel(appearance), Z_BODY, "body"],
		[EYES, Z_EYES, "eyes"],
		[_outfit_rel(appearance), Z_OUTFIT, "outfit"],
		[_hair_rel(appearance), Z_HAIR, "hair"],
		[_accessory_rel(appearance), Z_ACCESSORY, "accessory"],
	]
	for entry in plan:
		var rel: String = String(entry[0])
		if rel.is_empty() or not _exists(rel):
			continue
		out.append({"res_path": _abs(rel), "z": int(entry[1]), "layer": String(entry[2]), "rel": rel})
	return out

## A stable signature of the rendered layer set — changes whenever any visible part changes, so
## validation/smoke can prove the editor actually alters the avatar (not just the saved data).
static func signature(appearance: Dictionary) -> String:
	var parts: Array = []
	for layer in layers_for(appearance):
		parts.append((layer["rel"] as String).get_file())
	return "|".join(parts)

## Load a layer texture (Image-based; works for the .gdignored extracted PNGs). null when absent.
static func layer_texture(res_path: String) -> Texture2D:
	if res_path.is_empty():
		return null
	var img := Image.new()
	var abs_path := ProjectSettings.globalize_path(res_path) if res_path.begins_with("res://") else res_path
	if img.load(abs_path) != OK or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)

## Presentation default overrides (feminine/neutral/masculine). Empty for unknown ids.
static func presentation_defaults(presentation: String) -> Dictionary:
	return (PRESENTATION_PRESETS.get(String(presentation), {}) as Dictionary).duplicate()

static func presentation_ids() -> Array:
	return PRESENTATION_PRESETS.keys()
