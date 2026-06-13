extends RefCounted
class_name SkillProgression

## The progression data model: {total_xp: int, skills: {skill_id: xp}}.
## Lives at `player.progression` offline and inside known_profiles on the
## server. `normalized()` is the single entry point for reading any stored
## shape — including the older flat `{xp: N}` shape from the first crafting
## pass, which migrates into total_xp losslessly.

static func default_progression() -> Dictionary:
	var skills: Dictionary = {}
	for skill_id in ProgressionRegistry.SKILL_IDS:
		skills[skill_id] = 0
	return {"total_xp": 0, "skills": skills}

static func normalized(data: Dictionary) -> Dictionary:
	var result: Dictionary = default_progression()
	if data.is_empty():
		return result
	# Back-compat: the first progression pass stored a flat `xp` key.
	if data.has("total_xp"):
		result["total_xp"] = maxi(0, int(data.get("total_xp", 0)))
	elif data.has("xp"):
		result["total_xp"] = maxi(0, int(data.get("xp", 0)))
	var raw_skills: Variant = data.get("skills", {})
	if typeof(raw_skills) == TYPE_DICTIONARY:
		for skill_id in (raw_skills as Dictionary).keys():
			if ProgressionRegistry.SKILL_IDS.has(String(skill_id)):
				(result["skills"] as Dictionary)[String(skill_id)] = maxi(0, int((raw_skills as Dictionary)[skill_id]))
	return result

## Pure grant: returns a NEW normalized progression dict plus level-up info.
## {progression, player_levelled: bool, new_player_level, skill_levelled: bool,
##  new_skill_level} — callers turn level-ups into toasts/broadcasts.
static func grant(data: Dictionary, skill_id: String, skill_xp: int, total_xp: int) -> Dictionary:
	var progression: Dictionary = normalized(data)
	var skills: Dictionary = progression["skills"] as Dictionary

	var old_player_level: int = PlayerProgression.level_for_xp(int(progression["total_xp"]))
	var old_skill_level: int = PlayerProgression.level_for_xp(int(skills.get(skill_id, 0)))

	progression["total_xp"] = int(progression["total_xp"]) + maxi(0, total_xp)
	if ProgressionRegistry.SKILL_IDS.has(skill_id):
		skills[skill_id] = int(skills.get(skill_id, 0)) + maxi(0, skill_xp)

	var new_player_level: int = PlayerProgression.level_for_xp(int(progression["total_xp"]))
	var new_skill_level: int = PlayerProgression.level_for_xp(int(skills.get(skill_id, 0)))
	return {
		"progression": progression,
		"player_levelled": new_player_level > old_player_level,
		"new_player_level": new_player_level,
		"skill_levelled": new_skill_level > old_skill_level,
		"new_skill_level": new_skill_level,
	}

static func skill_xp(data: Dictionary, skill_id: String) -> int:
	return int((normalized(data)["skills"] as Dictionary).get(skill_id, 0))

static func skill_level(data: Dictionary, skill_id: String) -> int:
	return PlayerProgression.level_for_xp(skill_xp(data, skill_id))

static func player_level(data: Dictionary) -> int:
	return PlayerProgression.level_for_xp(int(normalized(data)["total_xp"]))

## {skill_id: level} snapshot for unlock checks.
static func skill_levels(data: Dictionary) -> Dictionary:
	var levels: Dictionary = {}
	var skills: Dictionary = normalized(data)["skills"] as Dictionary
	for skill_id in skills.keys():
		levels[skill_id] = PlayerProgression.level_for_xp(int(skills[skill_id]))
	return levels
