extends RefCounted
class_name CharacterAppearanceRegistry

## Registry of every character-appearance option the game knows about. Stable
## string ids (never display names) are the contract: saves, scenes, and the
## visual builder all refer to options by id, so renaming a display label is
## always safe and removing an id never is. Purely data — no nodes, no saves.

const FALLBACK_COLOR := Color("#8a5a3a")
const FALLBACK_SKIN := Color("#f2c9a8")

## Shared pastel palette used for hair, outfits, and accessories.
static func palette() -> Dictionary:
	return {
		"blush_pink": Color("#e8a0b4"),
		"moss_green": Color("#7da964"),
		"sky_blue": Color("#8ab8d8"),
		"warm_brown": Color("#8a5a3a"),
		"lavender": Color("#b49ad0"),
		"cream": Color("#f2e4c8"),
		"terracotta": Color("#c87858"),
	}

static func skin_tones() -> Dictionary:
	return {
		"peach": Color("#f2c9a8"),
		"honey": Color("#d9a877"),
		"umber": Color("#9c6b4a"),
	}

static func body_styles() -> Dictionary:
	return {
		"cozy_default": {"display_name": "Cozy"},
	}

static func hair_styles() -> Dictionary:
	return {
		"round_bob": {"display_name": "Round Bob"},
		"fluffy_short": {"display_name": "Fluffy Short"},
		"soft_curls": {"display_name": "Soft Curls"},
	}

static func outfit_styles() -> Dictionary:
	return {
		"starter_overalls": {"display_name": "Starter Overalls"},
		"cozy_tunic": {"display_name": "Cozy Tunic"},
		"forest_apron": {"display_name": "Forest Apron"},
	}

static func accessories() -> Dictionary:
	return {
		"none": {"display_name": "None"},
		"leaf_clip": {"display_name": "Leaf Clip"},
		"tiny_hat": {"display_name": "Tiny Hat"},
	}

static func face_styles() -> Dictionary:
	return {
		"happy": {"display_name": "Happy"},
	}

static func color_value(color_id: String) -> Color:
	return palette().get(color_id, FALLBACK_COLOR)

static func skin_value(skin_id: String) -> Color:
	return skin_tones().get(skin_id, FALLBACK_SKIN)

static func has_option(options: Dictionary, option_id: String) -> bool:
	return options.has(option_id)
