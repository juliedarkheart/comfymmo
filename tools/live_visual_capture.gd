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
		opening_img.save_png(PLAYABILITY_OPENING_FILE)
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
			inv_img.save_png(PLAYABILITY_INVENTORY_FILE)
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
			print("[live-capture] saved ", PLAYABILITY_BUILD_MENU_FILE)
		else:
			push_warning("[live-capture] failed to save build menu screenshot")
	else:
		push_warning("[live-capture] build menu panel not found; skipped build menu capture")
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
				print("[live-capture] saved ", PLAYABILITY_FARM_PROMPT_FILE)
			else:
				push_warning("[live-capture] failed to save farm prompt screenshot")
	quit(0)

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
