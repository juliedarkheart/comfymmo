extends RefCounted
class_name CharacterProfileRegistry

## Per-actor VISUAL IDENTITY profiles (character-identity pass). Each named actor gets a
## DISTINCT LimeZu-family look — a base character sheet (Farmer_1 / Farmer_2 / Body_2) plus a
## subtle palette tint — so the player, Farmer Rowan, and the villagers are no longer the same
## farmer clone. The player's tint is derived from the saved CharacterAppearance customization,
## so the player's identity comes from a profile/customization object, not a hardcoded fallback.
##
## Pure data + helpers; NO licensed media. Clean-checkout safe: a profile only NAMES a LimeZu
## logical id + a tint; texture resolution + fallback live in the registries, so a checkout
## without the licensed packs still boots (CharacterArtRegistry falls back to generated art).

# LimeZu character base sheets (idle frame). Farmer_2 / Body_2 fall back to Farmer_1 when a
# partial pack lacks them, so uniqueness degrades gracefully (tint still differentiates).
const SHEET_FARMER_1 := "character.farmer_idle"
const SHEET_FARMER_2 := "character.farmer2_idle"
const SHEET_BODY_2 := "character.body2_idle"

const _DEFAULT := {
	"display_name": "Villager", "role": "villager",
	"sheet": SHEET_FARMER_1, "palette_variant": "classic", "palette": "#ffffff",
	"hair_style": "round_bob", "outfit_style": "starter_overalls", "accessory": "none",
	"scale_mult": 1.0, "name_offset_y": 0,
}

## Stable, hand-tuned identities for the named actors in the current slice. Player + Rowan use
## DIFFERENT base sheets so they can never collapse to the same signature; villagers vary by
## sheet AND tint. Tints are pale (near-white) so they read as outfit/lighting, not recoloured skin.
const DATA := {
	"player": {
		"display_name": "Julie", "role": "player",
		"sheet": SHEET_FARMER_2, "palette_variant": "garden", "palette": "#dCEacb",
		"hair_style": "wavy_shag", "outfit_style": "gardener_jacket", "accessory": "flower_pin",
	},
	"rowan": {
		"display_name": "Farmer Rowan", "role": "farmer_mentor",
		"sheet": SHEET_FARMER_1, "palette_variant": "classic", "palette": "#ffffff",
		"hair_style": "fluffy_short", "outfit_style": "starter_overalls", "accessory": "acorn_cap",
	},
	"maribel_tock": {
		"display_name": "Maribel Tock", "role": "villager",
		"sheet": SHEET_FARMER_1, "palette_variant": "meadow", "palette": "#cdebd2",
		"hair_style": "soft_curls", "outfit_style": "village_dress", "accessory": "leaf_clip",
	},
	"bram_nettle": {
		"display_name": "Bram Nettle", "role": "villager",
		"sheet": SHEET_FARMER_2, "palette_variant": "dusk", "palette": "#cdd6f0",
		"hair_style": "wavy_shag", "outfit_style": "forest_apron", "accessory": "round_glasses",
	},
	"land_clerk": {
		"display_name": "Hazel", "role": "clerk",
		"sheet": SHEET_BODY_2, "palette_variant": "lilac", "palette": "#e6d6f0",
		"hair_style": "cozy_bun", "outfit_style": "cozy_tunic", "accessory": "round_glasses",
	},
	"remote_player": {
		"display_name": "Visitor", "role": "remote_player",
		"sheet": SHEET_FARMER_2, "palette_variant": "berry", "palette": "#f0cdd6",
		"hair_style": "round_bob", "outfit_style": "cozy_tunic", "accessory": "none",
	},
	"generic_villager_1": {
		"display_name": "Villager", "role": "villager",
		"sheet": SHEET_FARMER_1, "palette_variant": "butter", "palette": "#f6ecc6",
		"hair_style": "round_bob", "outfit_style": "cozy_tunic", "accessory": "none",
	},
	"generic_villager_2": {
		"display_name": "Villager", "role": "villager",
		"sheet": SHEET_BODY_2, "palette_variant": "pond", "palette": "#cfe6ef",
		"hair_style": "leafy_pigtails", "outfit_style": "forest_apron", "accessory": "leaf_clip",
	},
}

## Named actors a release must keep visually distinct (validation + smoke read this).
const REQUIRED_PROFILE_IDS: Array[String] = ["player", "rowan", "maribel_tock", "bram_nettle", "land_clerk"]

# Optional player customization override (from the saved CharacterAppearance). Static so the
# player's live sprite reflects saved customization without a global save singleton.
static var _player_appearance: Dictionary = {}

static func required_profile_ids() -> Array[String]:
	return REQUIRED_PROFILE_IDS.duplicate()

static func has(actor_id: String) -> bool:
	return DATA.has(_norm(actor_id))

static func _norm(actor_id: String) -> String:
	return String(actor_id).strip_edges().to_lower()

## Full profile for an actor id (default-merged). For "player" the palette + a couple of
## descriptive slots are overridden from the saved CharacterAppearance when present.
static func profile_for(actor_id: String) -> Dictionary:
	var id := _norm(actor_id)
	var merged: Dictionary = _DEFAULT.duplicate(true)
	if DATA.has(id):
		for key in (DATA[id] as Dictionary).keys():
			merged[key] = (DATA[id] as Dictionary)[key]
	if id == "player" and not _player_appearance.is_empty():
		merged = _apply_appearance(merged, _player_appearance)
	return merged

## Bridge the saved CharacterAppearance customization onto the player profile: the outfit colour
## becomes the live palette tint, and body_presentation determines the LimeZu base sheet.
## Hair/outfit/accessory slots are mirrored for the audit (not rendered on full-body sheets).
static func _apply_appearance(profile: Dictionary, appearance: Dictionary) -> Dictionary:
	var out := profile.duplicate(true)
	# Body presentation -> base sheet (the only visible customization on full-body sheets)
	var bp := String(appearance.get("body_presentation", ""))
	if not bp.is_empty() and CharacterAppearanceRegistry.body_presentations().has(bp):
		out["sheet"] = CharacterAppearanceRegistry.body_presentation_sheet(bp)
		out["palette_variant"] = "custom_%s" % bp
	# Outfit colour -> palette tint (the second visible customization)
	var outfit_color_id := String(appearance.get("outfit_color", ""))
	if not outfit_color_id.is_empty():
		# Pale tint: blend white toward the chosen outfit colour so the sprite reads as a
		# different outfit without washing out into a solid colour.
		var tint := Color.WHITE.lerp(CharacterAppearanceRegistry.color_value(outfit_color_id), 0.32)
		out["palette"] = tint.to_html(false)
		out["palette_variant"] = "custom_%s" % outfit_color_id
	for slot_pair in [["hair_style", "hair_style"], ["outfit_style", "outfit_style"], ["accessory", "accessory"]]:
		if appearance.has(slot_pair[1]):
			out[slot_pair[0]] = String(appearance[slot_pair[1]])
	return out

static func sheet_id(actor_id: String) -> String:
	return String(profile_for(actor_id).get("sheet", SHEET_FARMER_1))

static func palette_color(actor_id: String) -> Color:
	return Color(String(profile_for(actor_id).get("palette", "#ffffff")))

static func display_name(actor_id: String) -> String:
	return String(profile_for(actor_id).get("display_name", "Villager"))

static func scale_mult(actor_id: String) -> float:
	return float(profile_for(actor_id).get("scale_mult", 1.0))

## A stable identity signature (base sheet + palette) used by the audit/validation to prove no
## two visible named actors share the exact same look.
static func signature(actor_id: String) -> String:
	var p := profile_for(actor_id)
	return "%s|%s" % [String(p.get("sheet", "")), String(p.get("palette", "")).to_lower()]

## Apply / clear the player's saved customization (call before the player's live sprite builds,
## or rebuild the avatar visual afterwards). Empty dict reverts to the default Julie profile.
static func apply_player_appearance(appearance: Dictionary) -> void:
	_player_appearance = (appearance as Dictionary).duplicate(true) if appearance != null else {}

static func clear_player_appearance() -> void:
	_player_appearance = {}
