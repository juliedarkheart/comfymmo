extends RefCounted
class_name PlayerProgression

## XP/level model shared by overall player level AND every skill track (one
## curve for both, kept deliberately simple — see docs/progression.md). Levels
## are always DERIVED from XP, never stored, so there is no level field to
## migrate and no way for them to disagree.

# Cumulative XP required for levels 1..10.
const LEVEL_THRESHOLDS: Array[int] = [0, 25, 60, 110, 180, 270, 380, 510, 660, 830]
const MAX_LEVEL := 10

static func level_for_xp(xp: int) -> int:
	var level: int = 1
	for index in range(LEVEL_THRESHOLDS.size()):
		if xp >= LEVEL_THRESHOLDS[index]:
			level = index + 1
	return mini(level, MAX_LEVEL)

## XP still needed for the next level; -1 at max level.
static func xp_to_next(xp: int) -> int:
	var level: int = level_for_xp(xp)
	if level >= MAX_LEVEL:
		return -1
	return LEVEL_THRESHOLDS[level] - xp

static func progress_text(xp: int) -> String:
	var level: int = level_for_xp(xp)
	if level >= MAX_LEVEL:
		return "Level %d (max)" % level
	return "Level %d  ·  %d XP (%d to next)" % [level, xp, xp_to_next(xp)]
