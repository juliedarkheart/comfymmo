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

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("[live-capture] main scene failed to load")
		quit(1)
		return
	get_root().add_child(scene.instantiate())
	for _i in range(40):
		await process_frame
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var gd := FileAccess.open(abs_dir + "/.gdignore", FileAccess.WRITE)
	if gd != null:
		gd.store_string("Local licensed review screenshots. Do not import.\n")
		gd.close()
	var tex: Texture2D = get_root().get_texture() if get_root() != null else null
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty() or img.get_width() == 0:
		push_warning("[live-capture] no renderable image (likely --headless). Run WITHOUT --headless.")
		quit(0)
		return
	if img.save_png(OUT_FILE) == OK:
		print("[live-capture] saved ", OUT_FILE)
	else:
		push_warning("[live-capture] failed to save screenshot")
	quit(0)
