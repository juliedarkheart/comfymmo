extends RefCounted
class_name CharacterAppearance

## The tiny appearance data model: a plain Dictionary of stable ids, one key
## per slot. Runtime/default-only for now — appearance is NOT written to saves
## yet (see docs/character_customization.md for the planned `player.appearance`
## integration). Anything reading appearance data should go through
## `normalized()` so unknown or missing ids degrade safely to defaults,
## which is also what makes future save integration backward-compatible.

const DEFAULT := {
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
	return DEFAULT.duplicate()

## Returns a complete appearance dict: every slot present, every id valid.
## Unknown ids (e.g. from a future save written by a newer build) fall back
## to the default for that slot instead of erroring.
static func normalized(data: Dictionary) -> Dictionary:
	var result: Dictionary = default_appearance()
	if data.is_empty():
		return result

	var validators: Dictionary = {
		"body_style": CharacterAppearanceRegistry.body_styles(),
		"skin_tone": CharacterAppearanceRegistry.skin_tones(),
		"hair_style": CharacterAppearanceRegistry.hair_styles(),
		"hair_color": CharacterAppearanceRegistry.palette(),
		"outfit_style": CharacterAppearanceRegistry.outfit_styles(),
		"outfit_color": CharacterAppearanceRegistry.palette(),
		"accessory": CharacterAppearanceRegistry.accessories(),
		"face_style": CharacterAppearanceRegistry.face_styles(),
	}
	for slot in validators.keys():
		var candidate: String = String(data.get(slot, ""))
		if CharacterAppearanceRegistry.has_option(validators[slot] as Dictionary, candidate):
			result[slot] = candidate
	return result
