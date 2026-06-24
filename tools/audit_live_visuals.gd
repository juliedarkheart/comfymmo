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
	print("================================================================")
	print("DISALLOWED visible world/HUD sources: %d (target 0, farm-plot procedural exempt)" % disallowed)
	print("AUDIT live visuals: %s" % ("PASS" if disallowed == 0 else "REVIEW"))
	quit(0 if disallowed == 0 else 1)

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
