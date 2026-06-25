extends RefCounted
class_name CharacterAppearance

## The tiny appearance data model: a plain Dictionary of stable ids, one key
## per slot. Runtime/default-only for now — appearance is NOT written to saves
## yet (see docs/character_customization.md for the planned `player.appearance`
## integration). Anything reading appearance data should go through
## `normalized()` so unknown or missing ids degrade safely to defaults,
## which is also what makes future save integration backward-compatible.

const DEFAULT := {
	"body_presentation": "neutral",
	"body_style": "cozy_default",
	"skin_tone": "peach",
	"hair_style": "hair_22",
	"hair_color": "01",
	"outfit_style": "outfit_14",
	"outfit_color": "01",
	"accessory": "none",
	"face_style": "happy",
}

static func default_appearance() -> Dictionary:
	# In layered mode the default is the curated Julie look (a neutral-feminine cozy avatar,
	# never forced masculine). Falls back to the legacy full-body default on a clean checkout.
	if CharacterPartLibrary.layered_ready():
		var jd: Dictionary = CharacterPartLibrary.julie_default()
		if not jd.is_empty():
			var merged: Dictionary = DEFAULT.duplicate()
			for k in jd.keys():
				merged[k] = jd[k]
			return merged
	return DEFAULT.duplicate()

## Returns a complete appearance dict: every slot present, every id valid.
## Unknown ids (e.g. from a future save written by a newer build) fall back
## to the first valid option in the current registry for that slot, so layered
## and legacy registries each degrade to their own first available choice.
static func normalized(data: Dictionary) -> Dictionary:
	var result: Dictionary = default_appearance()
	if data.is_empty():
		return result

	var validators: Dictionary = {
		"body_presentation": CharacterAppearanceRegistry.body_presentations(),
		"body_style": CharacterAppearanceRegistry.body_styles(),
		"skin_tone": CharacterAppearanceRegistry.skin_tones(),
		"accessory": CharacterAppearanceRegistry.accessories(),
		"face_style": CharacterAppearanceRegistry.face_styles(),
		"eyes": CharacterAppearanceRegistry.eyes(),
	}
	for slot in validators.keys():
		var options: Dictionary = validators[slot] as Dictionary
		var candidate: String = String(data.get(slot, ""))
		if CharacterAppearanceRegistry.has_option(options, candidate):
			result[slot] = candidate
		elif not options.is_empty():
			# Fall back to the default value if it's still valid, otherwise first
			# registry option (e.g. layered IDs when legacy defaults are unavailable).
			var def_val := String(default_appearance().get(slot, ""))
			if CharacterAppearanceRegistry.has_option(options, def_val):
				result[slot] = def_val
			else:
				result[slot] = String(options.keys()[0])
	if CharacterPartLibrary.layered_ready():
		_normalize_split_part(result, data, "hair", CharacterAppearanceRegistry.hair_styles())
		_normalize_split_part(result, data, "outfit", CharacterAppearanceRegistry.outfit_styles())
	else:
		_normalize_legacy_option(result, data, "hair_style", CharacterAppearanceRegistry.hair_styles())
		_normalize_legacy_option(result, data, "hair_color", CharacterAppearanceRegistry.palette())
		_normalize_legacy_option(result, data, "outfit_style", CharacterAppearanceRegistry.outfit_styles())
		_normalize_legacy_option(result, data, "outfit_color", CharacterAppearanceRegistry.palette())
	return result

static func _normalize_split_part(result: Dictionary, data: Dictionary, slot_prefix: String, style_options: Dictionary) -> void:
	var style_key := "%s_style" % slot_prefix
	var color_key := "%s_color" % slot_prefix
	var candidate_style := String(data.get(style_key, result.get(style_key, "")))
	var candidate_color := String(data.get(color_key, ""))
	var split := CharacterPartLibrary.split_id(candidate_style)
	if split.size() == 3:
		candidate_style = "%s_%s" % [split[0], split[1]]
		if candidate_color.is_empty() or not String(candidate_color).is_valid_int():
			candidate_color = String(split[2])
	if not CharacterAppearanceRegistry.has_option(style_options, candidate_style):
		var def_style := CharacterPartLibrary.split_base_from_part_id(String(default_appearance().get(style_key, "")))
		candidate_style = def_style if CharacterAppearanceRegistry.has_option(style_options, def_style) else String(style_options.keys()[0])
	var valid_color := CharacterPartLibrary.valid_color_for_style(candidate_style, candidate_color)
	result[style_key] = candidate_style
	result[color_key] = valid_color

static func _normalize_legacy_option(result: Dictionary, data: Dictionary, slot: String, options: Dictionary) -> void:
	var candidate := String(data.get(slot, result.get(slot, "")))
	if CharacterAppearanceRegistry.has_option(options, candidate):
		result[slot] = candidate
	elif not options.is_empty():
		result[slot] = String(options.keys()[0])
