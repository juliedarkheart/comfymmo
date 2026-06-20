extends Node2D
class_name FarmPlot

## Drives one farm tile's visual from FarmingSystem state.
##
## The live world is TOP-DOWN (Sprout-curated or LimeZu), so the old iso-diamond
## scene polygons — soil AND the sprout/leaf crop shapes — are ALWAYS hidden and
## replaced by clean top-down nodes "LiveLimeZuSoil" + "LiveLimeZuCrop", driven by
## the REAL FarmingSystem stages (empty / tilled_soil / planted_seed /
## crop_stage_1..3). The previous script matched planted_dry/planted_watered/grown,
## which FarmingSystem._normalize_plot_state() converts AWAY, so nothing ever
## changed on screen and the legacy diamond soil leaked into the live view.

const OLD_POLYGONS := [
	"SoilRim", "SoilBase", "FurrowTop", "FurrowMid", "FurrowBottom",
	"SoilHighlight", "MoistureOverlay", "SproutSmall", "SproutLarge",
	"GrownLeaves", "CropAccent",
]

var plot_id: String = ""

var _bed: Polygon2D = null          # untilled garden-bed cue (empty -> findable)
var _soil: Node2D = null            # LiveLimeZuSoil: tilled furrowed soil
var _moist: Polygon2D = null        # watered tint
var _ready_ring: Line2D = null      # harvest-ready highlight
var _crop: Node2D = null            # LiveLimeZuCrop: per-stage crop shapes
var _crop_small: Polygon2D = null
var _crop_large: Polygon2D = null
var _crop_mature: Polygon2D = null
var _crop_accent: Polygon2D = null
var _built: bool = false

func _ready() -> void:
	_build_visuals()
	_hide_old_polygons()

func set_plot_state(plot_data: Dictionary) -> void:
	_build_visuals()
	var stage: String = String(plot_data.get("stage", FarmingSystem.STAGE_EMPTY))
	var is_nearby: bool = bool(plot_data.get("is_nearby", false))
	var crop_id: String = String(plot_data.get("crop_id", "carrot"))
	var watered: bool = bool(plot_data.get("watered", false))
	_apply(stage, is_nearby, crop_id, watered)

func _apply(stage: String, is_nearby: bool, crop_id: String, watered: bool) -> void:
	_hide_old_polygons()
	if _soil == null:
		return
	var tilled: bool = stage != FarmingSystem.STAGE_EMPTY
	var mature: bool = stage == FarmingSystem.STAGE_CROP_STAGE_3 or stage == FarmingSystem.STAGE_GROWN
	var has_crop: bool = stage in [
		FarmingSystem.STAGE_PLANTED_SEED, FarmingSystem.STAGE_PLANTED_DRY,
		FarmingSystem.STAGE_CROP_STAGE_1, FarmingSystem.STAGE_CROP_STAGE_2,
		FarmingSystem.STAGE_PLANTED_WATERED, FarmingSystem.STAGE_CROP_STAGE_3,
		FarmingSystem.STAGE_GROWN,
	]
	# Ground: untilled bed cue when empty; dark furrowed soil once hoed.
	_bed.visible = not tilled
	_soil.visible = tilled
	_moist.visible = tilled and watered
	_ready_ring.visible = mature and is_nearby
	# Crop: container visible whenever a crop exists; the right stage shape shows.
	_crop.visible = has_crop
	_apply_crop_palette(crop_id)
	_crop_small.visible = stage in [FarmingSystem.STAGE_PLANTED_SEED, FarmingSystem.STAGE_PLANTED_DRY, FarmingSystem.STAGE_CROP_STAGE_1]
	_crop_large.visible = stage in [FarmingSystem.STAGE_CROP_STAGE_2, FarmingSystem.STAGE_PLANTED_WATERED]
	_crop_mature.visible = mature
	_crop_accent.visible = mature

func _hide_old_polygons() -> void:
	for node_name in OLD_POLYGONS:
		var node := get_node_or_null(node_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = false

func _build_visuals() -> void:
	if _built:
		return
	_built = true
	# Untilled garden bed cue (empty): a light cleared-dirt square, clearly NOT soil.
	_bed = Polygon2D.new()
	_bed.name = "LiveBedCue"
	_bed.polygon = _square(14.0)
	_bed.color = Color("#b89a6e")
	_bed.z_index = -2
	_bed.visible = false
	add_child(_bed)
	# Tilled soil (LiveLimeZuSoil): base + lighter top + furrow lines, top-down.
	_soil = Node2D.new()
	_soil.name = "LiveLimeZuSoil"
	_soil.z_index = -2
	_soil.visible = false
	add_child(_soil)
	var soil_base := Polygon2D.new()
	soil_base.polygon = _square(15.0)
	soil_base.color = Color("#6f4a29")
	_soil.add_child(soil_base)
	var soil_top := Polygon2D.new()
	soil_top.polygon = _square(13.0)
	soil_top.color = Color("#8a5e36")
	_soil.add_child(soil_top)
	for fy in [-7.0, 0.0, 7.0]:
		var furrow := Polygon2D.new()
		furrow.polygon = PackedVector2Array([Vector2(-12, fy - 1.0), Vector2(12, fy - 1.0), Vector2(12, fy + 1.0), Vector2(-12, fy + 1.0)])
		furrow.color = Color("#5d3f24")
		_soil.add_child(furrow)
	# Watered tint.
	_moist = Polygon2D.new()
	_moist.name = "LiveSoilMoisture"
	_moist.polygon = _square(13.0)
	_moist.color = Color(0.30, 0.46, 0.62, 0.42)
	_moist.z_index = -1
	_moist.visible = false
	add_child(_moist)
	# Crop container (LiveLimeZuCrop) with per-stage shapes drawn on the soil.
	_crop = Node2D.new()
	_crop.name = "LiveLimeZuCrop"
	_crop.visible = false
	add_child(_crop)
	_crop_small = Polygon2D.new()
	_crop_small.position = Vector2(0, -6)
	_crop_small.polygon = PackedVector2Array([Vector2(0, -10), Vector2(4, -3), Vector2(0, 6), Vector2(-4, -3)])
	_crop_small.visible = false
	_crop.add_child(_crop_small)
	_crop_large = Polygon2D.new()
	_crop_large.position = Vector2(0, -8)
	_crop_large.polygon = PackedVector2Array([Vector2(0, -14), Vector2(7, -4), Vector2(3, 10), Vector2(-3, 10), Vector2(-7, -4)])
	_crop_large.visible = false
	_crop.add_child(_crop_large)
	_crop_mature = Polygon2D.new()
	_crop_mature.position = Vector2(0, -10)
	_crop_mature.polygon = PackedVector2Array([Vector2(0, -14), Vector2(5, -9), Vector2(11, -7), Vector2(9, -2), Vector2(12, 4), Vector2(6, 6), Vector2(0, 10), Vector2(-6, 6), Vector2(-12, 4), Vector2(-9, -2), Vector2(-11, -7), Vector2(-5, -9)])
	_crop_mature.visible = false
	_crop.add_child(_crop_mature)
	_crop_accent = Polygon2D.new()
	_crop_accent.position = Vector2(0, -2)
	_crop_accent.polygon = PackedVector2Array([Vector2(0, -8), Vector2(5.5, -6), Vector2(8, 0), Vector2(5.5, 6), Vector2(0, 8), Vector2(-5.5, 6), Vector2(-8, 0), Vector2(-5.5, -6)])
	_crop_accent.visible = false
	_crop.add_child(_crop_accent)
	# Harvest-ready highlight ring.
	_ready_ring = Line2D.new()
	_ready_ring.name = "LiveReadyRing"
	_ready_ring.closed = true
	_ready_ring.width = 2.0
	_ready_ring.default_color = Color(1.0, 0.86, 0.36, 0.95)
	_ready_ring.points = _square(15.0)
	_ready_ring.z_index = 2
	_ready_ring.visible = false
	add_child(_ready_ring)

func _square(h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])

func _apply_crop_palette(crop_id: String) -> void:
	match crop_id:
		"turnip":
			_crop_small.color = Color("#7cba65")
			_crop_large.color = Color("#95cf79")
			_crop_mature.color = Color("#5ca55c")
			_crop_accent.color = Color("#c7a0e5")
		"berry":
			_crop_small.color = Color("#68b36a")
			_crop_large.color = Color("#7fcb83")
			_crop_mature.color = Color("#4f9158")
			_crop_accent.color = Color("#d85f8d")
		_:
			_crop_small.color = Color("#73b156")
			_crop_large.color = Color("#8ac964")
			_crop_mature.color = Color("#57b144")
			_crop_accent.color = Color("#e09b47")
