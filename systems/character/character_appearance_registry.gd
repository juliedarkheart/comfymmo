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
		"butter_yellow": Color("#f2d469"),
		"berry_red": Color("#c94f55"),
		"pond_blue": Color("#6aa8c0"),
		"lilac": Color("#c9aee0"),
		"soft_black": Color("#4a4248"),
		"warm_white": Color("#f5f0e6"),
	}

static func skin_tones() -> Dictionary:
	return {
		"peach": Color("#f2c9a8"),
		"honey": Color("#d9a877"),
		"umber": Color("#9c6b4a"),
	}

## Body/skin tone options from the layered parts when available.
## Bodies are skin tones, not gendered presentations — wardrobe labels them "Peach", "Fair", etc.
static func body_presentations() -> Dictionary:
	# In layered mode, bodies are skin tone variants from the curated manifest
	if CharacterPartLibrary.layered_ready():
		var layered: Dictionary = {}
		for pid in CharacterPartLibrary.part_ids_for_category("bodies"):
			var entry := CharacterPartLibrary.part_entry(pid)
			var label := String(entry.get("skin_tone_label", pid.capitalize().replace("_", " ")))
			layered[pid] = {"display_name": label}
		if not layered.is_empty():
			return layered
	# Full-body fallback: feminine/masculine/neutral
	return {
		"feminine": {"display_name": "Feminine"},
		"masculine": {"display_name": "Masculine"},
		"neutral": {"display_name": "Neutral"},
	}

static func body_styles() -> Dictionary:
	return {
		"cozy_default": {"display_name": "Cozy"},
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

## --- Layered part mappings (Character Generator parts when available) ---

## Layer-friendly hairstyle ids mapped from CharacterPartLibrary if available.
## Falls back to the original hair_styles when the curated manifest is absent.
static func hair_styles() -> Dictionary:
	if CharacterPartLibrary.layered_ready():
		var layered: Dictionary = {}
		for pid in CharacterPartLibrary.style_bases_for_category("hairstyles"):
			layered[String(pid)] = {
				"display_name": CharacterPartLibrary.hair_style_label(String(pid)),
				"metadata": {"unlock_status": "dev_unlocked", "dev_available": true},
			}
		if not layered.is_empty():
			return layered
	return {
		"round_bob": {"display_name": "Round Bob"},
		"fluffy_short": {"display_name": "Fluffy Short"},
		"soft_curls": {"display_name": "Soft Curls"},
		"leafy_pigtails": {"display_name": "Leafy Pigtails"},
		"cozy_bun": {"display_name": "Cozy Bun"},
		"wavy_shag": {"display_name": "Wavy Shag"},
	}

## Layer-friendly outfit ids mapped from CharacterPartLibrary if available.
static func outfit_styles() -> Dictionary:
	if CharacterPartLibrary.layered_ready():
		var layered: Dictionary = {}
		for pid in CharacterPartLibrary.style_bases_for_category("outfits"):
			layered[String(pid)] = {
				"display_name": CharacterPartLibrary.outfit_style_label(String(pid)),
				"metadata": {"unlock_status": "dev_unlocked", "dev_available": true},
			}
		if not layered.is_empty():
			return layered
	return {
		"starter_overalls": {"display_name": "Starter Overalls"},
		"cozy_tunic": {"display_name": "Cozy Tunic"},
		"forest_apron": {"display_name": "Forest Apron"},
		"village_dress": {"display_name": "Village Dress"},
		"mushroom_sweater": {"display_name": "Mushroom Sweater"},
		"gardener_jacket": {"display_name": "Gardener Jacket"},
	}

## All VALID accessory appearance ids = the legacy wearable-crafting accessories (kept so the
## wearable system + save migration still validate) PLUS the layered Character_Generator
## accessories when available. The F9 editor only exposes the RENDERABLE layered ones
## (layered_accessory_ids) so it never shows a control that does nothing.
static func accessories() -> Dictionary:
	var base: Dictionary = {
		"none": {"display_name": "None"},
		"leaf_clip": {"display_name": "Leaf Clip"},
		"tiny_hat": {"display_name": "Tiny Hat"},
		"flower_pin": {"display_name": "Flower Pin"},
		"round_glasses": {"display_name": "Round Glasses"},
		"acorn_cap": {"display_name": "Acorn Cap"},
	}
	if CharacterPartLibrary.layered_ready():
		for pid in CharacterPartLibrary.part_ids_for_category("accessories"):
			if pid != "acc_none":
				var entry := CharacterPartLibrary.part_entry(pid)
				base[pid] = {
					"display_name": String(entry.get("label", String(pid).capitalize().replace("_", " "))),
					"metadata": CharacterPartLibrary.dev_metadata_for_part(pid),
				}
	return base

## Renderable accessory ids for the layered editor: None + the curated Character_Generator
## accessory parts (each maps to a real layer). Falls back to the legacy set when not layered.
static func layered_accessory_ids() -> Array:
	if not CharacterPartLibrary.layered_ready():
		return accessories().keys()
	var ids: Array = ["none"]
	for pid in CharacterPartLibrary.part_ids_for_category("accessories"):
		if pid != "acc_none":
			ids.append(pid)
	return ids

## Eye options from the curated layered parts (when available), else a single default.
static func eyes() -> Dictionary:
	if CharacterPartLibrary.layered_ready():
		var layered: Dictionary = {}
		for pid in CharacterPartLibrary.part_ids_for_category("eyes"):
			layered[pid] = {"display_name": String(pid).capitalize().replace("_", " ")}
		if not layered.is_empty():
			return layered
	return {"eyes_02": {"display_name": "Default Eyes"}}

## The LimeZu base sheet id mapped from a body_presentation option.
## Falls back to Farmer_2 when the presentation id is unknown or missing.
## NOTE: the only full-body fallback presentation sheets are the CLOTHED Farmer_1 /
## Farmer_2. Body_2 (character.body2_idle) is a BARE base body, so it must NEVER be a
## player-facing presentation sprite (it once rendered as a bald pink figure) — it
## stays a raw body layer for the layered compositor only. Presentation variety here
## comes from the palette tint, not a bare silhouette.
static func body_presentation_sheet(presentation_id: String) -> String:
	match String(presentation_id):
		"masculine":
			return "character.farmer_idle"  # classic farmer (clothed)
		"feminine":
			return "character.farmer2_idle" # clothed alternate (never the bare Body_2)
		_:
			return "character.farmer2_idle" # neutral / default (clothed)
