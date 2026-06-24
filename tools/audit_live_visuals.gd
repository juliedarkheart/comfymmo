extends SceneTree

## Dev-only LimeZu live-visual source audit (Task 1 of the visual-quarantine pass).
##
## For every logical id the live homestead opening actually spawns — plus the HUD
## status icons and the core UI ids — print the resolved texture path, its source
## tier (VisualSourceReport.classify_texture), the on-disk dimensions, and whether
## the tier is allowed in normal LimeZu live mode. Pure resolver inspection: it does
## NOT instantiate the heavy overworld scene, so it is deterministic and headless-safe.
##
## Run:
##   godot --headless --path . --script res://tools/audit_live_visuals.gd

const LIVE_WORLD_IDS: Array[String] = [
	# terrain / ground
	"terrain.grass", "terrain.dirt_path", "terrain.tilled_soil",
	# props / buildings / trees / fences placed by overworld_map._build_limezu_slice
	"object.barn", "object.tree", "object.tree_small",
	"object.fence_horizontal", "object.fence_vertical", "object.fence_post",
	"object.flower", "object.flower2", "object.flower3",
	"object.crate", "object.sign",
	# crops (FarmPlot live sprites)
	"crop.carrot", "crop.carrot_stage1",
	# actors / creatures
	"character.farmer_idle", "animal.chicken", "animal.cow",
]
const HUD_ICON_IDS: Array[String] = ["icon.day", "icon.comfort", "icon.carrot", "icon.wood"]
const UI_IDS: Array[String] = ["ui.panel", "ui.inventory_panel", "ui.slot", "ui.slot_selected", "ui.button", "ui.close"]

func _init() -> void:
	LimeZuArtRegistry.reload()
	GeneratorAssetResolver.reload()
	print("\n================ LIMEZU LIVE VISUAL SOURCE AUDIT ================")
	var disallowed: int = 0
	disallowed += _audit_section("WORLD (terrain / props / actors)", LIVE_WORLD_IDS, true)
	disallowed += _audit_section("HUD STATUS ICONS", HUD_ICON_IDS, true)
	disallowed += _audit_section("UI FRAMES", UI_IDS, false)
	_audit_object_contracts()
	var actor_dupes: int = _audit_actor_identities()
	_audit_animation_terrain_collision()
	print("================================================================")
	print("DISALLOWED visible world/HUD sources: %d (target 0, farm-plot procedural exempt)" % disallowed)
	print("DUPLICATE named-actor signatures: %d (target 0)" % actor_dupes)
	var pass_ok: bool = disallowed == 0 and actor_dupes == 0
	print("AUDIT live visuals: %s" % ("PASS" if pass_ok else "REVIEW"))
	quit(0 if pass_ok else 1)

## Actor identity audit (character-identity pass): per named actor, the profile id, base sheet,
## source tier, palette, and a uniqueness SIGNATURE (sheet+palette). Flags duplicate signatures
## among named actors and a player/Rowan clash — proving the actor-cloning bug is fixed.
func _audit_actor_identities() -> int:
	print("\n-- ACTOR IDENTITIES (uniqueness) --")
	var required := CharacterProfileRegistry.required_profile_ids()
	var all_ids: Array = required.duplicate()
	for extra in ["remote_player", "generic_villager_1", "generic_villager_2"]:
		if not all_ids.has(extra):
			all_ids.append(extra)
	var required_sigs := {}
	var dupes: int = 0
	for actor_id in all_ids:
		var sheet: String = CharacterProfileRegistry.sheet_id(actor_id)
		var path: String = LimeZuArtRegistry.texture_path(sheet)
		var tier: String = VisualSourceReport.classify_texture(path)
		var sig: String = CharacterProfileRegistry.signature(actor_id)
		var is_required: bool = required.has(actor_id)
		var clash: bool = is_required and required_sigs.has(sig)
		if clash:
			dupes += 1
		if is_required:
			required_sigs[sig] = actor_id
		print("  %s%-20s %-16s %-22s tier=%-14s sig=%s" % [
			("!! " if clash else "OK "), actor_id, CharacterProfileRegistry.display_name(actor_id),
			sheet, tier, sig,
		])
	var player_sig: String = CharacterProfileRegistry.signature("player")
	var rowan_sig: String = CharacterProfileRegistry.signature("rowan")
	print("  player vs rowan: %s" % ("DISTINCT" if player_sig != rowan_sig else "!! IDENTICAL"))
	if player_sig == rowan_sig:
		dupes += 1
	return dupes

func _audit_section(title: String, ids: Array[String], enforce: bool) -> int:
	print("\n-- %s --" % title)
	var bad: int = 0
	for id in ids:
		var path: String = LimeZuArtRegistry.texture_path(id)
		var tier: String = VisualSourceReport.classify_texture(path)
		var allowed: bool = VisualSourceReport.LIMEZU_SOURCE_TIERS.has(tier)
		var dims: String = _dims(path)
		var flag: String = "OK " if allowed else "!! "
		if enforce and not allowed:
			bad += 1
		print("  %s%-26s %-20s %-8s  %s" % [flag, id, tier, dims, _short(path)])
	return bad

## Object contract audit (Task 2): per asset id, the category + collision (blocks_player) +
## interaction kind/prompt/response, so a physical prop is never a silent walk-through object.
func _audit_object_contracts() -> void:
	print("\n-- OBJECT CONTRACTS (category / blocks / interaction) --")
	for id in AssetWorldMetadata.DATA.keys():
		var asset_id: String = String(id)
		var category: String = AssetWorldMetadata.object_category(asset_id)
		var blocks: bool = AssetWorldMetadata.is_blocking(asset_id)
		var interactive: bool = AssetWorldMetadata.interaction_enabled(asset_id)
		var kind: String = AssetWorldMetadata.interaction_kind(asset_id)
		var prompt: String = AssetWorldMetadata.interaction_prompt(asset_id)
		print("  %-24s cat=%-9s blocks=%-5s F=%-5s kind=%-26s %s" % [
			asset_id, category, str(blocks), str(interactive), kind,
			("\"%s\"" % prompt) if not prompt.is_empty() else "",
		])

## Animation/facing, held-tool socket, terrain direct ids, and cow/sign/fence/tree collision
## (animation/terrain pass, Task 8) — so the audit catches missing facing, missing tool sockets,
## terrain gaps, and walk-through animals/signs.
func _audit_animation_terrain_collision() -> void:
	print("\n-- ANIMATION / FACING / SOCKET --")
	for sid in ["character.farmer_idle", "character.farmer2_idle", "character.body2_idle"]:
		print("  sheet %-24s wired=%-5s reviewed_dirs=%s walk_down_frames=%d" % [
			sid, str(CharacterAnimationRegistry.has_sheet(sid)),
			str(CharacterAnimationRegistry.reviewed_directions(sid)),
			CharacterAnimationRegistry.walk_frames(sid, "down").size(),
		])
	for facing in ["down", "up", "side"]:
		var s: Dictionary = CharacterAnimationRegistry.hand_socket(facing)
		print("  hand_socket %-5s pos=%s behind=%s present=%s" % [facing, str(s.get("pos")), str(s.get("behind")), str(CharacterAnimationRegistry.has_hand_socket(facing))])
	print("-- TERRAIN DIRECT IDS --")
	for t in ["terrain.grass", "terrain.dirt_path", "terrain.tilled_soil"]:
		var tier: String = VisualSourceReport.classify_texture(LimeZuArtRegistry.texture_path(t))
		print("  %-22s tier=%-14s allowed=%s" % [t, tier, str(LiveVisualPolicy.is_allowed_live_tier(tier))])
	print("-- COLLISION (blocks_player) --")
	for c in ["animal.cow", "object.sign", "object.fence_horizontal", "object.tree", "object.barn", "object.crate", "animal.chicken", "object.flower"]:
		print("  %-22s blocks=%-5s shapes=%s" % [c, str(AssetWorldMetadata.is_blocking(c)), str(AssetWorldMetadata.has_asset_collision_shapes(c))])

func _dims(path: String) -> String:
	if path.is_empty():
		return "-"
	var abs: String = ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var img := Image.new()
	if img.load(abs) != OK or img.is_empty():
		return "?"
	return "%dx%d" % [img.get_width(), img.get_height()]

func _short(path: String) -> String:
	if path.is_empty():
		return "(missing/empty)"
	var parts := path.split("/")
	return ".../" + parts[parts.size() - 1] if parts.size() > 2 else path
