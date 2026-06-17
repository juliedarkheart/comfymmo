extends SceneTree

## Local screenshot capture for the LimeZu visual spike. COMMIT-SAFE (code only).
## Loads the spike, lets it build for a few frames, then saves a PNG to the gitignored
## licensed_assets/limezu/review_screenshots/ folder for local review. The screenshot
## contains licensed art, so it MUST stay local (never committed).
##
## NOTE: in --headless mode Godot has no rendering device, so the viewport image is
## usually blank/null; this guards against that and prints manual instructions. For a
## real screenshot, run WITHOUT --headless:
##   & 'E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe' --path E:\GitHub\comfymmo \
##       --script res://tools/visual_spike_capture.gd
## or open scenes/visual_spikes/limezu_homestead_slice.tscn and Run Current Scene.

const OUT_DIR := "res://licensed_assets/limezu/review_screenshots"
const OUT_FILE := OUT_DIR + "/limezu_homestead_slice.png"

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/visual_spikes/limezu_homestead_slice.tscn") as PackedScene
	if scene == null:
		push_error("[capture] spike scene failed to load")
		quit(1)
		return
	var root_node: Node = scene.instantiate()
	get_root().add_child(root_node)
	for _i in range(12):
		await process_frame
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	# Keep Godot from importing screenshots that land here.
	var gdignore := FileAccess.open(abs_dir + "/.gdignore", FileAccess.WRITE)
	if gdignore != null:
		gdignore.store_string("Local licensed review screenshots. Do not import.\n")
		gdignore.close()
	var vp: Viewport = get_root()
	var tex: Texture2D = vp.get_texture() if vp != null else null
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty() or img.get_width() == 0:
		push_warning("[capture] no renderable image (likely --headless). Run WITHOUT --headless or open the scene in the editor and Run Current Scene.")
		quit(0)
		return
	var err := img.save_png(OUT_FILE)
	if err == OK:
		print("[capture] saved local screenshot: ", OUT_FILE)
	else:
		push_warning("[capture] failed to save screenshot (err %d)" % err)
	quit(0)
