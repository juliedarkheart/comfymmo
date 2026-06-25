extends SceneTree

## Smoke test for the actual rendered avatar facing state. It does not stop at
## `facing_direction == "down"`; it instantiates AvatarVisual and inspects the
## visible sprite/layer region, flip_h state, and parent scale after side->down.
##
## Run: Godot --headless --path . --script res://tools/smoke_avatar_facing.gd

const EXPECT_IDLE_DOWN := Rect2i(48, 0, 16, 32)      # generator col3,row0 = front/camera
const EXPECT_IDLE_UP := Rect2i(16, 0, 16, 32)        # generator col1,row0 = back
const EXPECT_IDLE_SIDE := Rect2i(0, 0, 16, 32)       # generator col0,row0 = side/right
const EXPECT_WALK_UP_FIRST := Rect2i(128, 32, 16, 32)
const EXPECT_WALK_SIDE_FIRST := Rect2i(192, 32, 16, 32)
const EXPECT_WALK_DOWN_FIRST := Rect2i(288, 32, 16, 32)

func _initialize() -> void:
	var ok := true
	CharacterPartLibrary.reload()
	var layered := CharacterPartLibrary.layered_ready()
	print("  INFO  layered_ready = %s" % layered)

	# Registry-level assertions: the front/down cell must be visually distinct from side.
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_IDLE_DOWN, 0) == EXPECT_IDLE_DOWN,
		"layered idle_down uses front/camera cell col3,row0") and ok
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_IDLE_UP, 0) == EXPECT_IDLE_UP,
		"layered idle_up uses back cell col1,row0") and ok
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_IDLE_SIDE, 0) == EXPECT_IDLE_SIDE,
		"layered idle_side uses side/right cell col0,row0") and ok
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_IDLE_DOWN, 0)
			!= CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_IDLE_SIDE, 0),
		"down/front frame is not the same visual cell as side") and ok
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_WALK_DOWN, 0) == EXPECT_WALK_DOWN_FIRST,
		"layered walk_down starts on front/camera walk band") and ok
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_WALK_SIDE, 0) == EXPECT_WALK_SIDE_FIRST,
		"layered walk_side starts on side/left walk band") and ok
	ok = _expect(CharacterAnimationRegistry.generator_region_for(AvatarVisual.STATE_WALK_UP, 0) == EXPECT_WALK_UP_FIRST,
		"layered walk_up starts on back/up walk band") and ok

	var avatar := AvatarVisual.new()
	get_root().add_child(avatar)
	await process_frame

	if layered:
		ok = _expect(bool(avatar._layered_mode), "AvatarVisual uses live layered path") and ok
		ok = _expect(_layer_sprite(avatar) != null, "layered body/first sprite exists") and ok

		# Left -> Down: this is the exact live regression. Parent scale must not stay -1,
		# down must select the front band, and every layer flip must be cleared.
		avatar.set_facing_direction(AvatarVisual.FACING_SIDE, -1.0)
		avatar.set_animation_state(AvatarVisual.STATE_WALK_SIDE, Vector2.LEFT)
		await process_frame
		ok = _expect(is_equal_approx(avatar.scale.x, 1.0), "left side keeps AvatarVisual parent scale.x stable") and ok
		ok = _expect(_rect_in(_layer_rect(avatar), CharacterAnimationRegistry.generator_walk_frames("side")), "left side uses side walk band before flip") and ok
		var left_flip := _any_layer_flipped(avatar)
		ok = _expect(not left_flip, "left side uses unflipped side visual") and ok

		avatar.set_facing_direction(AvatarVisual.FACING_SIDE, 1.0)
		avatar.set_animation_state(AvatarVisual.STATE_WALK_SIDE, Vector2.RIGHT)
		await process_frame
		var right_flip := _any_layer_flipped(avatar)
		ok = _expect(_rect_in(_layer_rect(avatar), CharacterAnimationRegistry.generator_walk_frames("side")), "right side uses side walk band before flip") and ok
		ok = _expect(right_flip, "right side mirrors layers with flip_h") and ok
		ok = _expect(left_flip != right_flip, "left and right side visuals use opposite flip states") and ok

		avatar.set_facing_direction(AvatarVisual.FACING_SIDE, -1.0)
		avatar.set_animation_state(AvatarVisual.STATE_WALK_SIDE, Vector2.LEFT)
		await process_frame

		avatar.set_facing_direction(AvatarVisual.FACING_DOWN, 0.0)
		avatar.set_animation_state(AvatarVisual.STATE_WALK_DOWN, Vector2.DOWN)
		await process_frame
		ok = _expect(is_equal_approx(avatar.scale.x, 1.0), "Left->Down leaves parent scale.x at 1") and ok
		ok = _expect(_rect_in(_layer_rect(avatar), CharacterAnimationRegistry.generator_walk_frames("down")), "Left->Down switches to front walk band") and ok
		ok = _expect(not _any_layer_flipped(avatar), "Left->Down clears all layer flip_h") and ok
		ok = _expect(not _rect_in(_layer_rect(avatar), CharacterAnimationRegistry.generator_walk_frames("side")), "Left->Down is not still using side walk band") and ok

		# Right -> Down idle: no side flip should remain and idle down must be the distinct front cell.
		avatar.set_facing_direction(AvatarVisual.FACING_SIDE, 1.0)
		avatar.set_animation_state(AvatarVisual.STATE_WALK_SIDE, Vector2.RIGHT)
		await process_frame
		ok = _expect(_any_layer_flipped(avatar), "right side uses flip_h") and ok

		avatar.set_facing_direction(AvatarVisual.FACING_DOWN, 0.0)
		avatar.set_animation_state(AvatarVisual.STATE_IDLE_DOWN, Vector2.ZERO)
		await process_frame
		ok = _expect(_layer_rect(avatar) == EXPECT_IDLE_DOWN, "Right->Down idle uses front/camera frame") and ok
		ok = _expect(not _any_layer_flipped(avatar), "Right->Down clears all layer flip_h") and ok
		ok = _expect(is_equal_approx(avatar.scale.x, 1.0), "Right->Down leaves parent scale.x at 1") and ok

		avatar.set_facing_direction(AvatarVisual.FACING_UP, 0.0)
		avatar.set_animation_state(AvatarVisual.STATE_IDLE_UP, Vector2.ZERO)
		await process_frame
		ok = _expect(_layer_rect(avatar) == EXPECT_IDLE_UP, "Up idle uses back-facing frame") and ok
		ok = _expect(not _any_layer_flipped(avatar), "Up clears all layer flip_h") and ok

		# The live player scene must use this same AvatarVisual path. This catches
		# controller/scene wiring regressions that a bare AvatarVisual test would miss.
		var player_scene: PackedScene = load("res://scenes/avatar/player_avatar.tscn") as PackedScene
		ok = _expect(player_scene != null, "player_avatar scene loads for live-path facing check") and ok
		if player_scene != null:
			var player := player_scene.instantiate()
			get_root().add_child(player)
			await process_frame
			player.set_physics_process(false)
			var body := player.get_node_or_null("Body") as AvatarVisual
			ok = _expect(body != null, "player_avatar Body is AvatarVisual") and ok
			if body != null:
				ok = _expect(bool(body._layered_mode), "player_avatar Body uses layered renderer") and ok
				player.call("_update_visual_state", Vector2.LEFT)
				await process_frame
				ok = _expect(_rect_in(_layer_rect(body), CharacterAnimationRegistry.generator_walk_frames("side")),
					"live player Left selects side walk band") and ok
				var live_left_flip := _any_layer_flipped(body)
				ok = _expect(not live_left_flip, "live player Left uses unflipped side visual") and ok
				player.call("_update_visual_state", Vector2.ZERO)
				await process_frame
				ok = _expect(String(player.facing_direction) == AvatarVisual.FACING_SIDE, "live player Left release keeps controller facing side") and ok
				ok = _expect(body.facing_direction == AvatarVisual.FACING_SIDE, "live player Left release keeps Body facing side") and ok
				ok = _expect(body._animation_state == AvatarVisual.STATE_IDLE_SIDE, "live player Left release chooses side idle state") and ok
				ok = _expect(_layer_rect(body) == EXPECT_IDLE_SIDE, "live player Left release selects side idle frame, not default down") and ok
				var live_left_idle_flip := _any_layer_flipped(body)
				ok = _expect(live_left_idle_flip, "live player Left release mirrors the right-facing side idle") and ok
				ok = _expect(is_equal_approx(body.scale.x, 1.0), "live player Left release keeps Body scale.x at 1") and ok
				ok = _expect(live_left_flip != live_left_idle_flip, "live player Left walk/idle use the reviewed opposite flip rules") and ok
				player.call("_update_visual_state", Vector2.RIGHT)
				await process_frame
				var live_right_flip := _any_layer_flipped(body)
				ok = _expect(_rect_in(_layer_rect(body), CharacterAnimationRegistry.generator_walk_frames("side")),
					"live player Right selects side walk band") and ok
				ok = _expect(live_right_flip, "live player Right mirrors layers") and ok
				ok = _expect(live_left_flip != live_right_flip, "live player Left and Right use opposite flip states") and ok
				player.call("_update_visual_state", Vector2.ZERO)
				await process_frame
				ok = _expect(String(player.facing_direction) == AvatarVisual.FACING_SIDE, "live player Right release keeps controller facing side") and ok
				ok = _expect(body.facing_direction == AvatarVisual.FACING_SIDE, "live player Right release keeps Body facing side") and ok
				ok = _expect(body._animation_state == AvatarVisual.STATE_IDLE_SIDE, "live player Right release chooses side idle state") and ok
				ok = _expect(_layer_rect(body) == EXPECT_IDLE_SIDE, "live player Right release selects side idle frame, not default down") and ok
				var live_right_idle_flip := _any_layer_flipped(body)
				ok = _expect(not live_right_idle_flip, "live player Right release uses unflipped side idle") and ok
				ok = _expect(is_equal_approx(body.scale.x, 1.0), "live player Right release keeps Body scale.x at 1") and ok
				ok = _expect(live_right_flip != live_right_idle_flip, "live player Right walk/idle use the reviewed opposite flip rules") and ok
				ok = _expect(live_left_idle_flip != live_right_idle_flip, "live player Left and Right release use opposite side-idle flip states") and ok
				player.call("_update_visual_state", Vector2.LEFT)
				await process_frame
				player.call("_update_visual_state", Vector2.DOWN)
				await process_frame
				ok = _expect(is_equal_approx(body.scale.x, 1.0), "live player Left->Down keeps Body scale.x at 1") and ok
				var live_down_rect := _layer_rect(body)
				ok = _expect(_rect_in(live_down_rect, CharacterAnimationRegistry.generator_walk_frames("down")),
					"live player Left->Down selects front walk band (%s)" % [live_down_rect]) and ok
				ok = _expect(not _rect_in(live_down_rect, CharacterAnimationRegistry.generator_walk_frames("side")),
					"live player Left->Down is not still side (%s)" % [live_down_rect]) and ok
				ok = _expect(not _any_layer_flipped(body), "live player Left->Down clears layer flip_h") and ok
				player.call("_update_visual_state", Vector2.RIGHT)
				await process_frame
				player.call("_update_visual_state", Vector2.DOWN)
				await process_frame
				var live_right_down_rect := _layer_rect(body)
				ok = _expect(_rect_in(live_right_down_rect, CharacterAnimationRegistry.generator_walk_frames("down")),
					"live player Right->Down selects front walk band (%s)" % [live_right_down_rect]) and ok
				ok = _expect(not _any_layer_flipped(body), "live player Right->Down clears layer flip_h") and ok
				player.call("_update_visual_state", Vector2.ZERO)
				await process_frame
				ok = _expect(String(player.facing_direction) == AvatarVisual.FACING_DOWN, "live player Down release keeps controller facing down") and ok
				ok = _expect(body.facing_direction == AvatarVisual.FACING_DOWN, "live player Down release keeps Body facing down") and ok
				ok = _expect(body._animation_state == AvatarVisual.STATE_IDLE_DOWN, "live player Down release chooses front idle state") and ok
				ok = _expect(_layer_rect(body) == EXPECT_IDLE_DOWN, "live player Down release selects front/camera idle frame") and ok
				ok = _expect(not _any_layer_flipped(body), "live player Down release clears side flip") and ok
				player.call("_update_visual_state", Vector2.UP)
				await process_frame
				ok = _expect(_rect_in(_layer_rect(body), CharacterAnimationRegistry.generator_walk_frames("up")),
					"live player Up selects back walk band") and ok
				player.call("_update_visual_state", Vector2.ZERO)
				await process_frame
				ok = _expect(String(player.facing_direction) == AvatarVisual.FACING_UP, "live player Up release keeps controller facing up") and ok
				ok = _expect(body.facing_direction == AvatarVisual.FACING_UP, "live player Up release keeps Body facing up") and ok
				ok = _expect(body._animation_state == AvatarVisual.STATE_IDLE_UP, "live player Up release chooses back idle state") and ok
				ok = _expect(_layer_rect(body) == EXPECT_IDLE_UP, "live player Up release selects back idle frame") and ok
				ok = _expect(not _any_layer_flipped(body), "live player Up release clears side flip") and ok
				player.call("_update_visual_state", Vector2.DOWN)
				await process_frame
				player.call("_update_visual_state", Vector2.ZERO)
				await process_frame
				player.call("_update_visual_state", Vector2.LEFT)
				await process_frame
				ok = _expect(String(player.facing_direction) == AvatarVisual.FACING_SIDE, "live player Down release -> Left changes facing to side") and ok
				ok = _expect(_rect_in(_layer_rect(body), CharacterAnimationRegistry.generator_walk_frames("side")),
					"live player Down release -> Left selects side walk band") and ok
				ok = _expect(not _any_layer_flipped(body), "live player Down release -> Left uses left side flip state") and ok
			player.queue_free()
			await process_frame
	else:
		# Clean-checkout fallback: no layered assets, so the full-body renderer must at least
		# keep side mirroring local to the sprite and clear it when Down is selected.
		ok = _expect(not bool(avatar._layered_mode), "clean checkout uses fallback full-body renderer") and ok
		avatar.set_facing_direction(AvatarVisual.FACING_SIDE, -1.0)
		avatar.set_animation_state(AvatarVisual.STATE_WALK_SIDE, Vector2.LEFT)
		await process_frame
		avatar.set_facing_direction(AvatarVisual.FACING_DOWN, 0.0)
		avatar.set_animation_state(AvatarVisual.STATE_IDLE_DOWN, Vector2.ZERO)
		await process_frame
		ok = _expect(is_equal_approx(avatar.scale.x, 1.0), "fallback Down clears parent scale.x") and ok
		if avatar._sprite != null:
			ok = _expect(not (avatar._sprite as Sprite2D).flip_h, "fallback Down clears sprite flip_h") and ok

	avatar.queue_free()
	await process_frame

	print("%s" % ("PASS: smoke_avatar_facing" if ok else "FAIL: smoke_avatar_facing"))
	quit(0 if ok else 1)

func _layer_sprite(avatar: AvatarVisual) -> Sprite2D:
	if avatar._layer_sprites.has("body"):
		return avatar._layer_sprites["body"] as Sprite2D
	for sprite in avatar._layer_sprites.values():
		return sprite as Sprite2D
	return null

func _layer_rect(avatar: AvatarVisual) -> Rect2i:
	var sprite := _layer_sprite(avatar)
	if sprite == null:
		return Rect2i()
	return Rect2i(sprite.region_rect)

func _any_layer_flipped(avatar: AvatarVisual) -> bool:
	for sprite in avatar._layer_sprites.values():
		if (sprite as Sprite2D).flip_h:
			return true
	return false

func _rect_in(rect: Rect2i, rects: Array[Rect2i]) -> bool:
	for candidate in rects:
		if rect == candidate:
			return true
	return false

func _expect(condition: bool, label: String) -> bool:
	if condition:
		print("  OK   %s" % label)
	else:
		printerr("  FAIL %s" % label)
	return condition
