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
		print("[live-capture] saved ", OUT_FILE)
		print("[live-capture] saved ", UI_REWRITE_OPENING_FILE)
	else:
		push_warning("[live-capture] failed to save opening screenshot")
	# 2) Inventory view (opens the full inventory panel so its UI can be reviewed).
	if _open_inventory_panel():
		for _i in range(8):
			await process_frame
		var inv_img: Image = _grab_image()
		if inv_img != null and inv_img.save_png(UI_REWRITE_INVENTORY_FILE) == OK:
			print("[live-capture] saved ", UI_REWRITE_INVENTORY_FILE)
		else:
			push_warning("[live-capture] failed to save inventory screenshot")
	else:
		push_warning("[live-capture] inventory panel not found; skipped inventory capture")
	quit(0)

func _grab_image() -> Image:
	var tex: Texture2D = get_root().get_texture() if get_root() != null else null
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty() or img.get_width() == 0:
		return null
	return img

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

func _close_review_overlays() -> void:
	var root := get_root()
	if root == null:
		return
	for node in root.find_children("*", "CanvasLayer", true, false):
		if node.has_method("close"):
			node.call("close")
		elif node.has_method("close_panel"):
			node.call("close_panel")
