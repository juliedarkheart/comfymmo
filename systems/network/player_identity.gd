extends RefCounted
class_name PlayerIdentity

## Builds and sanitizes the join payload a client sends to the server. This is
## PROTOTYPE identity for private playtests: a locally generated profile id and
## display name, no passwords, no secrets, no account auth. The server treats
## all of it as untrusted display data and normalizes it on receipt.

const MAX_DISPLAY_NAME_LENGTH := 24
const DEFAULT_DISPLAY_NAME := "Villager"
const USERNAME_MIN_LENGTH := 3
const USERNAME_MAX_LENGTH := 20

## Username rules: the persistent handle a profile registers on a server.
## Lowercase a-z, 0-9, underscore, hyphen; 3-20 chars; case-insensitive
## uniqueness per server. NOT authentication — anyone with (or faking) the
## profile_id can use it; see docs/server_identity.md for the trust model.
static func sanitize_username(raw: String) -> String:
	var cleaned: String = ""
	for character in raw.strip_edges().to_lower():
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_" or character == "-":
			cleaned += character
	return cleaned.substr(0, USERNAME_MAX_LENGTH)

static func is_valid_username(raw: String) -> bool:
	var cleaned: String = sanitize_username(raw)
	return cleaned == raw.strip_edges().to_lower() and cleaned.length() >= USERNAME_MIN_LENGTH

## Fallback username derived from a display name ("Villager" -> "villager").
static func username_from_display_name(display_name: String) -> String:
	var derived: String = sanitize_username(display_name)
	if derived.length() < USERNAME_MIN_LENGTH:
		derived = "villager"
	return derived

static func build_join_payload(profile: Dictionary) -> Dictionary:
	var username: String = sanitize_username(String(profile.get("username", "")))
	if username.length() < USERNAME_MIN_LENGTH:
		username = username_from_display_name(String(profile.get("display_name", DEFAULT_DISPLAY_NAME)))
	return {
		"profile_id": String(profile.get("profile_id", "")),
		"username": username,
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

	var username: String = sanitize_username(String(payload.get("username", "")))
	if username.length() < USERNAME_MIN_LENGTH:
		username = username_from_display_name(display_name)

	return {
		"profile_id": String(payload.get("profile_id", "")).substr(0, 64),
		"username": username,
		"display_name": display_name,
		"appearance": CharacterAppearance.normalized(appearance),
	}
