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
	"hair_style": "round_bob",
	"hair_color": "warm_brown",
	"outfit_style": "starter_overalls",
	"outfit_color": "moss_green",
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
		"hair_style": CharacterAppearanceRegistry.hair_styles(),
		"hair_color": CharacterAppearanceRegistry.palette(),
		"outfit_style": CharacterAppearanceRegistry.outfit_styles(),
		"outfit_color": CharacterAppearanceRegistry.palette(),
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
	return result
