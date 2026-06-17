extends Node2D
class_name FarmPlot

@onready var soil_base: Polygon2D = $SoilBase
@onready var soil_highlight: Polygon2D = $SoilHighlight
@onready var moisture_overlay: Polygon2D = $MoistureOverlay
@onready var sprout_small: Polygon2D = $SproutSmall
@onready var sprout_large: Polygon2D = $SproutLarge
@onready var grown_leaves: Polygon2D = $GrownLeaves
@onready var crop_accent: Polygon2D = $CropAccent

var plot_id: String = ""

func _ready() -> void:
	_hide_limezu_old_soil_visuals()

func set_plot_state(plot_data: Dictionary) -> void:
	var stage: String = String(plot_data.get("stage", "empty"))
	var is_nearby: bool = bool(plot_data.get("is_nearby", false))
	var crop_id: String = String(plot_data.get("crop_id", "carrot"))
	_apply_stage_visuals(stage, is_nearby, crop_id)

func _apply_stage_visuals(stage: String, is_nearby: bool, crop_id: String) -> void:
	soil_highlight.visible = is_nearby
	moisture_overlay.visible = false
	sprout_small.visible = false
	sprout_large.visible = false
	grown_leaves.visible = false
	crop_accent.visible = false

	_apply_crop_palette(crop_id)

	match stage:
		"planted_dry":
			sprout_small.visible = true
		"planted_watered":
			moisture_overlay.visible = true
			sprout_large.visible = true
		"grown":
			moisture_overlay.visible = true
			grown_leaves.visible = true
			crop_accent.visible = true
		_:
			pass
	_hide_limezu_old_soil_visuals()

func _hide_limezu_old_soil_visuals() -> void:
	if not LiveVisualPolicy.live_limezu_slice():
		return
	# LimeZu live mode draws tilled soil in the map layer. Keep this node alive for
	# farming data/interactions, but suppress the old iso-style soil marks.
	for soil_name in ["SoilRim", "SoilBase", "FurrowTop", "FurrowMid", "FurrowBottom", "SoilHighlight", "MoistureOverlay"]:
		var node := get_node_or_null(soil_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = false

func _apply_crop_palette(crop_id: String) -> void:
	match crop_id:
		"turnip":
			sprout_small.color = Color("#7cba65")
			sprout_large.color = Color("#95cf79")
			grown_leaves.color = Color("#5ca55c")
			crop_accent.color = Color("#c7a0e5")
		"berry":
			sprout_small.color = Color("#68b36a")
			sprout_large.color = Color("#7fcb83")
			grown_leaves.color = Color("#4f9158")
			crop_accent.color = Color("#d85f8d")
		_:
			sprout_small.color = Color("#73b156")
			sprout_large.color = Color("#8ac964")
			grown_leaves.color = Color("#57b144")
			crop_accent.color = Color("#e09b47")
