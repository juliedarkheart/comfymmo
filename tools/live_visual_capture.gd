extends SceneTree

## Local screenshot capture for the LIVE main scene (the pivoted LimeZu opening).
## COMMIT-SAFE (code only). Boots scenes/main.tscn, lets the world build + the player
## spawn for several frames, then saves a PNG to the gitignored review folder. The
## screenshot contains licensed art, so it must stay local (never committed).
##
## Headless has no rendering device (blank image), so run WITHOUT --headless:
##   & 'E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe' --path E:\GitHub\comfymmo \
##       --script res://tools/live_visual_capture.gd

const OUT_DIR := "res://licensed_assets/limezu/review_screenshots"
const OUT_FILE := OUT_DIR + "/live_limezu_opening.png"
const AFTER_FILE := OUT_DIR + "/live_limezu_opening_after_polish.png"
const OLD_VISUAL_CLEANUP_FILE := OUT_DIR + "/live_limezu_opening_after_old_visual_cleanup.png"
const LAYERING_CLEANUP_FILE := OUT_DIR + "/live_limezu_opening_after_layering_cleanup.png"
# This pass: clean LimeZu flat UI rewrite + bottom-board cleanup.
const UI_REWRITE_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_ui_rewrite.png"
const UI_REWRITE_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_ui_rewrite.png"
const AREA_EXPANSION_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_area_expansion.png"
const AREA_EXPANSION_WALK_EAST_FILE := OUT_DIR + "/live_limezu_walk_east_after_area_expansion.png"
const AREA_EXPANSION_WALK_SOUTH_FILE := OUT_DIR + "/live_limezu_walk_south_after_area_expansion.png"
const AREA_EXPANSION_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_area_expansion.png"
const PLAYABILITY_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_playability_ui_alignment.png"
const PLAYABILITY_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_playability_ui_alignment.png"
const PLAYABILITY_BUILD_MENU_FILE := OUT_DIR + "/live_limezu_build_menu_after_playability_ui_alignment.png"
const PLAYABILITY_FARM_PROMPT_FILE := OUT_DIR + "/live_limezu_farm_prompt_after_playability_ui_alignment.png"
# This pass: Stardew/cozy-survival LimeZu UI reconstruction (asset-backed 9-patch UI).
const STARDEW_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_stardew_ui.png"
const STARDEW_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_stardew_ui.png"
const STARDEW_BUILD_FILE := OUT_DIR + "/live_limezu_build_menu_after_stardew_ui.png"
const STARDEW_PROMPT_FILE := OUT_DIR + "/live_limezu_prompt_after_stardew_ui.png"
# This pass: UI polish + generator pipeline + collision/interaction alignment.
const POLISH_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_ui_generator_polish.png"
const POLISH_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_ui_generator_polish.png"
const POLISH_BUILD_FILE := OUT_DIR + "/live_limezu_build_after_ui_generator_polish.png"
const POLISH_PROMPT_FILE := OUT_DIR + "/live_limezu_prompt_after_ui_generator_polish.png"
const POLISH_FARM_FILE := OUT_DIR + "/live_limezu_farm_interact_after_ui_generator_polish.png"
# This pass: inventory/hotbar icon-centering + scaffold left-menu polish.
const ICON_ALIGN_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_icon_alignment.png"
const ICON_ALIGN_HOTBAR_FILE := OUT_DIR + "/live_limezu_hotbar_after_icon_alignment.png"
const LEFT_MENU_FILE := OUT_DIR + "/live_limezu_left_menu_after_polish.png"
# This pass: top-left Hearthvale status-card HUD polish.
const HUD_POLISH_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_hud_polish.png"
const HUD_POLISH_CLOSEUP_FILE := OUT_DIR + "/live_limezu_hud_closeup_after_hud_polish.png"
const HUD_POLISH_INVENTORY_FILE := OUT_DIR + "/live_limezu_inventory_after_hud_polish.png"
# This pass: collision / interaction / farm playability alignment.
const COLLISION_OPENING_FILE := OUT_DIR + "/live_limezu_opening_after_collision_interaction.png"
const COLLISION_FARM_FILE := OUT_DIR + "/live_limezu_farm_prompt_after_collision_interaction.png"
const COLLISION_BUILD_FILE := OUT_DIR + "/live_limezu_build_after_collision_interaction.png"
const COLLISION_ADMIN_FILE := OUT_DIR + "/live_limezu_admin_after_collision_interaction.png"
const COLLISION_DEBUG_FILE := OUT_DIR + "/live_limezu_collision_debug_after_collision_interaction.png"
# This pass: asset-aware collision metadata + minimap truth.
const MINIMAP_TRUTH_FILE := OUT_DIR + "/live_limezu_minimap_truth_pass.png"
const ASSET_COLLISION_FILE := OUT_DIR + "/live_limezu_asset_collision_overlay.png"
const BARN_COLLISION_FILE := OUT_DIR + "/live_limezu_barn_collision_debug.png"
const FARM_META_FILE := OUT_DIR + "/live_limezu_farm_prompt_asset_metadata.png"
# This pass: placed-object instance collision + minimap integration.
const PLACED_COLLISION_FILE := OUT_DIR + "/live_limezu_placed_object_collision_overlay.png"
const PLACED_MINIMAP_FILE := OUT_DIR + "/live_limezu_placed_object_minimap.png"
const BUILD_INSTANCE_FILE := OUT_DIR + "/live_limezu_build_after_instance_collision.png"
const MINIMAP_INSTANCE_FILE := OUT_DIR + "/live_limezu_minimap_after_instance_collision.png"
const MINIMAP_SCHEMATIC_FILE := OUT_DIR + "/live_limezu_minimap_schematic.png"
const MINIMAP_SCHEMATIC_CLOSEUP_FILE := OUT_DIR + "/live_limezu_minimap_schematic_closeup.png"
const OVERLAY_LEGEND_FILE := OUT_DIR + "/live_limezu_overlay_legend.png"
const FARM_OVERLAY_ALIGNMENT_FILE := OUT_DIR + "/live_limezu_farm_overlay_alignment.png"
const COLLISION_OVERLAY_ALIGNMENT_FILE := OUT_DIR + "/live_limezu_collision_overlay_alignment.png"
const PIXEL_BARN_COLLISION_FILE := OUT_DIR + "/live_limezu_barn_pixel_collision_overlay.png"
const PIXEL_TREE_COLLISION_FILE := OUT_DIR + "/live_limezu_tree_pixel_collision_overlay.png"
const PIXEL_FENCE_COLLISION_FILE := OUT_DIR + "/live_limezu_fence_pixel_collision_overlay.png"
const PIXEL_MINIMAP_FILE := OUT_DIR + "/live_limezu_minimap_after_pixel_collision.png"
const PIXEL_FARM_PROMPT_FILE := OUT_DIR + "/live_limezu_farm_prompt_after_pixel_collision.png"
const DEPTH_FRONT_FILE := OUT_DIR + "/live_limezu_player_in_front_of_tree.png"
const DEPTH_BEHIND_FILE := OUT_DIR + "/live_limezu_player_behind_tree.png"
const NPC_BODY_COLLISION_FILE := OUT_DIR + "/live_limezu_npc_body_collision.png"
const WALK_ANIMATION_FILE := OUT_DIR + "/live_limezu_player_walk_animation.png"
const HELD_TOOL_VISUAL_FILE := OUT_DIR + "/live_limezu_held_tool_visual.png"
const PLACED_YSORT_OVERLAY_FILE := OUT_DIR + "/live_limezu_placed_object_ysort_overlay.png"
const QUICKBAR_ASSIGNED_FILE := OUT_DIR + "/live_limezu_quickbar_assigned.png"
const QUICKBAR_EMPTY_UNEQUIPPED_FILE := OUT_DIR + "/live_limezu_quickbar_empty_unequipped.png"
const HELD_TOOL_AFTER_QUICKBAR_FILE := OUT_DIR + "/live_limezu_held_tool_after_quickbar.png"
const QUICKBAR_ASSIGN_FILE := OUT_DIR + "/live_limezu_inventory_quickbar_assign.png"
const GENERATED_TOOL_ICONS_REVIEW_FILE := OUT_DIR + "/live_limezu_generated_tool_icons_review.png"
const GENERATED_TOOL_ICONS_SOURCE := "res://licensed_assets/limezu/generator_outputs/hearthvale_generated/review/hearthvale_icon_preview.png"

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("[live-capture] main scene failed to load")
		quit(1)
		return
	get_root().add_child(scene.instantiate())
	for _i in range(40):
		await process_frame
	_close_review_overlays()
	for _i in range(5):
		await process_frame
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var gd := FileAccess.open(abs_dir + "/.gdignore", FileAccess.WRITE)
	if gd != null:
		gd.store_string("Local licensed review screenshots. Do not import.\n")
		gd.close()
	# 1) Opening view (HUD/minimap/toolbelt over the world, all panels closed).
	var opening_img: Image = _grab_image()
	if opening_img == null:
		push_warning("[live-capture] no renderable image (likely --headless). Run WITHOUT --headless.")
		quit(0)
		return
	if opening_img.save_png(OUT_FILE) == OK:
		opening_img.save_png(AFTER_FILE)
		opening_img.save_png(OLD_VISUAL_CLEANUP_FILE)
		opening_img.save_png(LAYERING_CLEANUP_FILE)
		opening_img.save_png(UI_REWRITE_OPENING_FILE)
		opening_img.save_png(AREA_EXPANSION_OPENING_FILE)
		opening_img.save_png(PLAYABILITY_OPENING_FILE); opening_img.save_png(STARDEW_OPENING_FILE); opening_img.save_png(POLISH_OPENING_FILE); opening_img.save_png(ICON_ALIGN_HOTBAR_FILE); opening_img.save_png(HUD_POLISH_OPENING_FILE); opening_img.save_png(COLLISION_OPENING_FILE); opening_img.save_png(MINIMAP_TRUTH_FILE); opening_img.save_png(PLACED_MINIMAP_FILE); opening_img.save_png(MINIMAP_INSTANCE_FILE); opening_img.save_png(MINIMAP_SCHEMATIC_FILE); opening_img.save_png(PIXEL_MINIMAP_FILE); opening_img.get_region(Rect2i(940, 8, 332, 184)).save_png(OUT_DIR + "/live_limezu_minimap_closeup_truth.png"); opening_img.get_region(Rect2i(940, 8, 332, 184)).save_png(MINIMAP_SCHEMATIC_CLOSEUP_FILE); opening_img.get_region(Rect2i(0, 0, 360, 230)).save_png(HUD_POLISH_CLOSEUP_FILE)
		print("[live-capture] saved ", OUT_FILE)
		print("[live-capture] saved ", UI_REWRITE_OPENING_FILE)
		print("[live-capture] saved ", AREA_EXPANSION_OPENING_FILE)
		print("[live-capture] saved ", PLAYABILITY_OPENING_FILE)
	else:
		push_warning("[live-capture] failed to save opening screenshot")
	var player: Node2D = _find_player()
	var start_position: Vector2 = player.global_position if player != null else Vector2.ZERO
	if player != null:
		await _capture_player_offset(player, start_position, Vector2(360, 0), AREA_EXPANSION_WALK_EAST_FILE)
		await _capture_player_offset(player, start_position, Vector2(0, 320), AREA_EXPANSION_WALK_SOUTH_FILE)
		await _capture_player_depth_pose(player, Vector2i(3, 11), Vector2(0, 52), DEPTH_FRONT_FILE)
		await _capture_player_depth_pose(player, Vector2i(3, 11), Vector2(0, -30), DEPTH_BEHIND_FILE)
		await _capture_player_walk_pose(player, start_position + Vector2(80, 16), WALK_ANIMATION_FILE)
		await _capture_held_tool_pose(player, start_position + Vector2(92, 42), HELD_TOOL_VISUAL_FILE)
		await _capture_quickbar_assigned(player, start_position + Vector2(70, 26), QUICKBAR_ASSIGNED_FILE)
		await _capture_held_tool_pose(player, start_position + Vector2(92, 42), HELD_TOOL_AFTER_QUICKBAR_FILE)
		await _capture_quickbar_empty(player, start_position + Vector2(70, 26), QUICKBAR_EMPTY_UNEQUIPPED_FILE)
		player.global_position = start_position
		_reset_player_camera(player)
		for _i in range(8):
			await process_frame
	else:
		push_warning("[live-capture] player not found; skipped east/south area captures")
	# 2) Inventory view (opens the full inventory panel so its UI can be reviewed).
	if _open_inventory_panel():
		for _i in range(8):
			await process_frame
		var inv_img: Image = _grab_image()
		if inv_img != null and inv_img.save_png(UI_REWRITE_INVENTORY_FILE) == OK:
			inv_img.save_png(AREA_EXPANSION_INVENTORY_FILE)
			inv_img.save_png(PLAYABILITY_INVENTORY_FILE); inv_img.save_png(STARDEW_INVENTORY_FILE); inv_img.save_png(POLISH_INVENTORY_FILE); inv_img.save_png(ICON_ALIGN_INVENTORY_FILE); inv_img.save_png(HUD_POLISH_INVENTORY_FILE); inv_img.save_png(QUICKBAR_ASSIGN_FILE)
			print("[live-capture] saved ", UI_REWRITE_INVENTORY_FILE)
			print("[live-capture] saved ", AREA_EXPANSION_INVENTORY_FILE)
			print("[live-capture] saved ", PLAYABILITY_INVENTORY_FILE)
		else:
			push_warning("[live-capture] failed to save inventory screenshot")
	else:
		push_warning("[live-capture] inventory panel not found; skipped inventory capture")
	_close_review_overlays()
	for _i in range(5):
		await process_frame
	if _open_build_menu_panel():
		for _i in range(8):
			await process_frame
		var build_img: Image = _grab_image()
		if build_img != null and build_img.save_png(PLAYABILITY_BUILD_MENU_FILE) == OK:
			print("[live-capture] saved ", PLAYABILITY_BUILD_MENU_FILE); build_img.save_png(STARDEW_BUILD_FILE); build_img.save_png(POLISH_BUILD_FILE); build_img.save_png(BUILD_INSTANCE_FILE); build_img.save_png(COLLISION_BUILD_FILE); print("[live-capture] saved ", STARDEW_BUILD_FILE)
		else:
			push_warning("[live-capture] failed to save build menu screenshot")
	else:
		push_warning("[live-capture] build menu panel not found; skipped build menu capture")
	_close_review_overlays()
	for _i in range(5):
		await process_frame
	if _open_admin_panel():
		for _i in range(8):
			await process_frame
		var admin_img: Image = _grab_image()
		if admin_img != null and admin_img.save_png(LEFT_MENU_FILE) == OK:
			admin_img.save_png(COLLISION_ADMIN_FILE)
			print("[live-capture] saved ", LEFT_MENU_FILE)
		else:
			push_warning("[live-capture] failed to save left-menu screenshot")
		_close_review_overlays()
	if player != null:
		var farm_pos: Vector2 = _farm_prompt_position()
		if farm_pos != Vector2.INF:
			player.global_position = farm_pos
			_reset_player_camera(player)
			for _i in range(18):
				await process_frame
			var farm_img: Image = _grab_image()
			if farm_img != null and farm_img.save_png(PLAYABILITY_FARM_PROMPT_FILE) == OK:
				print("[live-capture] saved ", PLAYABILITY_FARM_PROMPT_FILE); farm_img.save_png(STARDEW_PROMPT_FILE); farm_img.save_png(POLISH_PROMPT_FILE); farm_img.save_png(POLISH_FARM_FILE); farm_img.save_png(COLLISION_FARM_FILE); farm_img.save_png(FARM_META_FILE); farm_img.save_png(PIXEL_FARM_PROMPT_FILE); print("[live-capture] saved ", STARDEW_PROMPT_FILE)
			else:
				push_warning("[live-capture] failed to save farm prompt screenshot")
	_close_review_overlays()
	for _i in range(4):
		await process_frame
	if _enable_collision_debug():
		if player != null:
			player.global_position = start_position
			_reset_player_camera(player)
		for _i in range(8):
			await process_frame
		var dbg_img: Image = _grab_image()
		if dbg_img != null and dbg_img.save_png(COLLISION_DEBUG_FILE) == OK:
			dbg_img.save_png(ASSET_COLLISION_FILE); dbg_img.save_png(PLACED_COLLISION_FILE)
			dbg_img.get_region(Rect2i(700, 0, 580, 540)).save_png(BARN_COLLISION_FILE)
			dbg_img.save_png(OVERLAY_LEGEND_FILE)
			dbg_img.get_region(Rect2i(0, 120, 640, 560)).save_png(FARM_OVERLAY_ALIGNMENT_FILE)
			dbg_img.get_region(Rect2i(600, 0, 680, 560)).save_png(COLLISION_OVERLAY_ALIGNMENT_FILE)
			dbg_img.get_region(Rect2i(600, 0, 680, 560)).save_png(PIXEL_BARN_COLLISION_FILE)
			dbg_img.get_region(Rect2i(0, 190, 680, 470)).save_png(PIXEL_TREE_COLLISION_FILE)
			dbg_img.get_region(Rect2i(360, 0, 560, 220)).save_png(PIXEL_FENCE_COLLISION_FILE)
			print("[live-capture] saved ", COLLISION_DEBUG_FILE)
		if player != null:
			await _capture_npc_body_collision(player, NPC_BODY_COLLISION_FILE)
			await _capture_placed_object_ysort_overlay(player, PLACED_YSORT_OVERLAY_FILE)
	_copy_generated_icon_review()
	quit(0)

func _enable_collision_debug() -> bool:
	var root := get_root()
	if root == null:
		return false
	for node in root.find_children("Map", "Node2D", true, false):
		if node.has_method("set_collision_debug"):
			node.call("set_collision_debug", true)
			return true
	return false

func _grab_image() -> Image:
	var tex: Texture2D = get_root().get_texture() if get_root() != null else null
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty() or img.get_width() == 0:
		return null
	return img

func _capture_player_offset(player: Node2D, start_position: Vector2, offset: Vector2, file_path: String) -> void:
	player.global_position = start_position + offset
	_reset_player_camera(player)
	for _i in range(16):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save area screenshot: %s" % file_path)

func _capture_player_depth_pose(player: Node2D, tree_tile: Vector2i, offset: Vector2, file_path: String) -> void:
	var map_node := _find_map()
	if map_node == null or not map_node.has_method("grid_to_world"):
		return
	player.global_position = (map_node.call("grid_to_world", tree_tile) as Vector2) + Vector2(0, 16) + offset
	_set_player_animation_state(player, AvatarVisual.STATE_IDLE_DOWN, AvatarVisual.FACING_DOWN)
	_reset_player_camera(player)
	for _i in range(18):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save depth screenshot: %s" % file_path)

func _capture_player_walk_pose(player: Node2D, world_pos: Vector2, file_path: String) -> void:
	player.global_position = world_pos
	_set_player_animation_state(player, AvatarVisual.STATE_WALK_SIDE, AvatarVisual.FACING_SIDE, 1.0)
	_reset_player_camera(player)
	for _i in range(24):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save walk screenshot: %s" % file_path)

func _capture_held_tool_pose(player: Node2D, world_pos: Vector2, file_path: String) -> void:
	_set_quickbar_assignments(LocalSaveSystem.default_quickbar_slots(), 3)
	player.global_position = world_pos
	_set_player_animation_state(player, AvatarVisual.STATE_IDLE_SIDE, AvatarVisual.FACING_SIDE, 1.0)
	_reset_player_camera(player)
	for _i in range(18):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save held-tool screenshot: %s" % file_path)

func _capture_quickbar_assigned(player: Node2D, world_pos: Vector2, file_path: String) -> void:
	_set_quickbar_assignments(LocalSaveSystem.default_quickbar_slots(), 0)
	player.global_position = world_pos
	_set_player_animation_state(player, AvatarVisual.STATE_IDLE_DOWN, AvatarVisual.FACING_DOWN)
	_reset_player_camera(player)
	for _i in range(16):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save assigned quickbar screenshot: %s" % file_path)

func _capture_quickbar_empty(player: Node2D, world_pos: Vector2, file_path: String) -> void:
	var slots: Array[String] = LocalSaveSystem.default_quickbar_slots()
	slots[8] = ""
	_set_quickbar_assignments(slots, 8)
	player.global_position = world_pos
	_set_player_animation_state(player, AvatarVisual.STATE_IDLE_DOWN, AvatarVisual.FACING_DOWN)
	_reset_player_camera(player)
	for _i in range(16):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save empty quickbar screenshot: %s" % file_path)

func _capture_npc_body_collision(player: Node2D, file_path: String) -> void:
	var npc := _find_first_villager()
	if npc == null:
		return
	player.global_position = npc.global_position + Vector2(26, 10)
	_set_player_animation_state(player, AvatarVisual.STATE_IDLE_SIDE, AvatarVisual.FACING_SIDE, -1.0)
	_reset_player_camera(player)
	for _i in range(16):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save NPC collision screenshot: %s" % file_path)

func _capture_placed_object_ysort_overlay(player: Node2D, file_path: String) -> void:
	var map_node := _find_map()
	if map_node == null or not map_node.has_method("grid_to_world"):
		return
	var gameplay := map_node.get_node_or_null("GameplayLayer") as Node2D
	if gameplay == null:
		return
	var scene := load("res://scenes/buildings/decor/placeable_bench.tscn") as PackedScene
	if scene == null:
		return
	var placed := scene.instantiate() as PlaceableCrate
	if placed == null:
		return
	var tile := Vector2i(8, 12)
	placed.name = "CapturePlacedYSortBench"
	placed.position = map_node.call("grid_to_world", tile) as Vector2
	placed.set_meta("debug_collision_kind", "proxy")
	placed.set_meta("debug_collision_asset", "capture_only")
	placed.set_meta("debug_footprint_tiles", [tile])
	gameplay.add_child(placed)
	placed.set_placed_visual()
	player.global_position = placed.global_position + Vector2(0, 34)
	_set_player_animation_state(player, AvatarVisual.STATE_IDLE_DOWN, AvatarVisual.FACING_DOWN)
	_reset_player_camera(player)
	for _i in range(18):
		await process_frame
	var img: Image = _grab_image()
	if img != null and img.save_png(file_path) == OK:
		print("[live-capture] saved ", file_path)
	else:
		push_warning("[live-capture] failed to save placed-object overlay screenshot: %s" % file_path)
	placed.queue_free()

func _find_player() -> Node2D:
	var root := get_root()
	if root == null:
		return null
	for node in root.find_children("*", "AvatarController", true, false):
		if node is Node2D:
			return node as Node2D
	for node in root.find_children("*", "CharacterBody2D", true, false):
		if node is AvatarController:
			return node as Node2D
	return null

func _find_map() -> Node:
	var root := get_root()
	if root == null:
		return null
	for node in root.find_children("Map", "Node2D", true, false):
		return node
	return null

func _find_first_villager() -> Node2D:
	var root := get_root()
	if root == null:
		return null
	for node in root.find_children("*", "Node2D", true, false):
		if node is SimpleVillager:
			return node as Node2D
	return null

func _set_player_animation_state(player: Node2D, state: String, facing: String, side_sign: float = 0.0) -> void:
	var body := player.get_node_or_null("Body")
	if body != null and body.has_method("set_facing_direction"):
		body.call("set_facing_direction", facing, side_sign)
	if body != null and body.has_method("set_animation_state"):
		body.call("set_animation_state", state, Vector2.RIGHT if state == AvatarVisual.STATE_WALK_SIDE else Vector2.ZERO)

func _select_hotbar_index(index: int) -> void:
	var root := get_root()
	if root == null:
		return
	for node in root.find_children("QuickToolsBar", "CanvasLayer", true, false):
		if node.has_method("select_hotbar_index"):
			node.call("select_hotbar_index", index)
			return

func _set_quickbar_assignments(assignments: Array, selected_index: int) -> void:
	var root := get_root()
	if root == null:
		return
	for node in root.find_children("QuickToolsBar", "CanvasLayer", true, false):
		if node.has_method("set_quickbar_assignments"):
			node.call("set_quickbar_assignments", assignments, selected_index, false)
			return

func _copy_generated_icon_review() -> void:
	if not FileAccess.file_exists(GENERATED_TOOL_ICONS_SOURCE):
		push_warning("[live-capture] generated icon review sheet missing; run hearthvale_icon_generator.py --preview")
		return
	var img := Image.new()
	if img.load(GENERATED_TOOL_ICONS_SOURCE) != OK:
		push_warning("[live-capture] failed to load generated icon review sheet")
		return
	if img.save_png(GENERATED_TOOL_ICONS_REVIEW_FILE) == OK:
		print("[live-capture] saved ", GENERATED_TOOL_ICONS_REVIEW_FILE)
	else:
		push_warning("[live-capture] failed to save generated icon review screenshot")

func _reset_player_camera(player: Node2D) -> void:
	if player == null:
		return
	for node in player.find_children("*", "Camera2D", true, false):
		if node.has_method("reset_smoothing"):
			node.call("reset_smoothing")

## Open the full inventory panel so its UI can be captured. Targets the CanvasLayer
## named "InventoryPanel" specifically (other panels — crafting, land, build — also
## expose open_panel/is_open, so a name match avoids opening the wrong one). Returns
## true if the inventory panel was opened.
func _open_inventory_panel() -> bool:
	var root := get_root()
	if root == null:
		return false
	for node in root.find_children("InventoryPanel", "CanvasLayer", true, false):
		if node.has_method("open_panel"):
			node.call("open_panel")
			return true
	return false

func _open_admin_panel() -> bool:
	var root := get_root()
	if root == null:
		return false
	for node in root.find_children("AdminPanel", "CanvasLayer", true, false):
		if node.has_method("toggle_panel"):
			node.set("visible", false)
			node.call("toggle_panel")
			return true
	return false

func _open_build_menu_panel() -> bool:
	var root := get_root()
	if root == null:
		return false
	for node in root.find_children("BuildMenuPanel", "CanvasLayer", true, false):
		if node.has_method("open_panel"):
			node.call("open_panel")
			return true
	return false

func _farm_prompt_position() -> Vector2:
	var root := get_root()
	if root == null:
		return Vector2.INF
	for node in root.find_children("Map", "Node2D", true, false):
		if node.has_method("grid_to_world"):
			return node.call("grid_to_world", Vector2i(2, 12)) as Vector2
	return Vector2.INF

func _close_review_overlays() -> void:
	var root := get_root()
	if root == null:
		return
	for node in root.find_children("*", "CanvasLayer", true, false):
		if node.has_method("close"):
			node.call("close")
		elif node.has_method("close_panel"):
			node.call("close_panel")
