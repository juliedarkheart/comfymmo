extends SceneTree

## Headless smoke for the animation / terrain / collision pass: the player's character sheet has
## directional facing + walk frames, held-tool sockets exist per facing, the terrain direct ids
## resolve to an allowed LimeZu-family tier, and cows/signs/fences carry blocking collision.
## Pure registry/data checks — it never touches a player save.
##
##   Godot --headless --path . --script res://tools/smoke_animation_terrain_contracts.gd

func _initialize() -> void:
	var ok: bool = true

	# --- 1) Player animation profile + sheet ---------------------------------
	var player_sheet: String = CharacterProfileRegistry.sheet_id("player")
	ok = _expect(CharacterAnimationRegistry.has_sheet(player_sheet), "player sheet '%s' has animation data" % player_sheet) and ok
	for sid in ["character.farmer_idle", "character.farmer2_idle", "character.body2_idle"]:
		ok = _expect(CharacterAnimationRegistry.has_sheet(sid), "sheet '%s' wired" % sid) and ok

	# --- 2) Idle + walk frames select for all four facings -------------------
	for facing in ["down", "up", "side"]:
		var idle: Rect2i = CharacterAnimationRegistry.idle_rect(player_sheet, facing)
		ok = _expect(idle.size == CharacterAnimationRegistry.FRAME, "idle frame for '%s' is one 16x32 cell" % facing) and ok
		var walk: Array = CharacterAnimationRegistry.walk_frames(player_sheet, facing)
		ok = _expect(walk.size() >= 1, "walk frames exist for '%s' (%d)" % [facing, walk.size()]) and ok
	# left/right = side (mirrored front); a movement state for each direction resolves a region.
	for state in ["walk_down", "walk_up", "walk_side", "idle_down", "idle_up", "idle_side"]:
		var r: Rect2i = CharacterAnimationRegistry.region_for(player_sheet, state, 0)
		ok = _expect(r.size.x == 16 and r.size.y == 32, "region resolves for state '%s'" % state) and ok
	ok = _expect(CharacterAnimationRegistry.reviewed_directions(player_sheet).has("down") \
		and CharacterAnimationRegistry.reviewed_directions(player_sheet).has("up"), "down+up are reviewed-wired facings") and ok

	# --- 3) Held-tool hand socket per facing ---------------------------------
	for facing in ["down", "up", "side"]:
		ok = _expect(CharacterAnimationRegistry.has_hand_socket(facing), "hand socket exists for '%s'" % facing) and ok
		var s: Dictionary = CharacterAnimationRegistry.hand_socket(facing)
		ok = _expect(s.has("pos") and s.has("rot") and s.has("behind"), "hand socket '%s' has pos/rot/behind" % facing) and ok
	ok = _expect(bool(CharacterAnimationRegistry.hand_socket("up").get("behind", false)), "up-facing tool draws behind the body") and ok

	# --- 4) Terrain direct ids resolve to allowed LimeZu-family tiers ---------
	for terrain_id in ["terrain.grass", "terrain.dirt_path", "terrain.tilled_soil"]:
		var tier: String = VisualSourceReport.classify_texture(LimeZuArtRegistry.texture_path(terrain_id))
		ok = _expect(LiveVisualPolicy.is_allowed_live_tier(tier), "terrain '%s' is LimeZu-family (%s)" % [terrain_id, tier]) and ok
	ok = _expect(LimeZuArtRegistry.texture_path("terrain.grass") != LimeZuArtRegistry.texture_path("terrain.dirt_path"),
		"grass tile is distinct from the path tile") and ok

	# --- 5) Cow / sign / fence / tree collision contracts --------------------
	for solid_id in ["animal.cow", "object.sign", "object.fence_horizontal", "object.tree", "object.barn"]:
		ok = _expect(AssetWorldMetadata.is_blocking(solid_id) and AssetWorldMetadata.has_asset_collision_shapes(solid_id),
			"'%s' blocks + has collision shapes" % solid_id) and ok
	# Decor stays pass-through (chicken + flowers).
	ok = _expect(not AssetWorldMetadata.is_blocking("animal.chicken"), "chicken stays pass-through (ambient)") and ok
	ok = _expect(not AssetWorldMetadata.is_blocking("object.flower"), "flowers stay pass-through (decor)") and ok

	print("SMOKE animation/terrain/collision: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _expect(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
