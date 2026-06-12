extends RefCounted
class_name PlayerIdentity

## Builds and sanitizes the join payload a client sends to the server. This is
## PROTOTYPE identity for private playtests: a locally generated profile id and
## display name, no passwords, no secrets, no account auth. The server treats
## all of it as untrusted display data and normalizes it on receipt.

const MAX_DISPLAY_NAME_LENGTH := 24
const DEFAULT_DISPLAY_NAME := "Villager"

static func build_join_payload(profile: Dictionary) -> Dictionary:
	return {
		"profile_id": String(profile.get("profile_id", "")),
		"display_name": String(profile.get("display_name", DEFAULT_DISPLAY_NAME)),
		"appearance": CharacterAppearance.normalized(
			profile.get("appearance", {}) if typeof(profile.get("appearance")) == TYPE_DICTIONARY else {}
		),
	}

## Server-side sanitation: never trust the wire. Unknown appearance ids fall
## back per-slot, names are length-clamped and never empty.
static func normalized(payload: Dictionary) -> Dictionary:
	var display_name: String = String(payload.get("display_name", "")).strip_edges()
	if display_name.is_empty():
		display_name = DEFAULT_DISPLAY_NAME
	display_name = display_name.substr(0, MAX_DISPLAY_NAME_LENGTH)

	var raw_appearance: Variant = payload.get("appearance", {})
	var appearance: Dictionary = {}
	if typeof(raw_appearance) == TYPE_DICTIONARY:
		appearance = raw_appearance as Dictionary

	return {
		"profile_id": String(payload.get("profile_id", "")).substr(0, 64),
		"display_name": display_name,
		"appearance": CharacterAppearance.normalized(appearance),
	}
