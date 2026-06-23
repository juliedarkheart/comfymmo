extends CanvasLayer
class_name MissingAssetsScreen

## Diagnostic screen kept for manual/debug use only. Missing licensed art packs are
## no longer allowed to block runtime boot; WorldRegionManager logs non-blocking
## fallback warnings and mounts the playable overworld.

const TITLE := "Optional visual assets missing"
const BODY := "Some preferred local licensed art packs are missing or inactive. Hearthvale should still boot with LimeZu when ready, then generated/procedural fallback visuals.\n\nLicensed packs remain local-only under licensed_assets/ and are never committed. Missing packs may reduce visual quality, but they must not block the playable homestead."

var _missing: Array[String] = []
var _built := false

func setup(missing: Array) -> void:
	_missing.clear()
	for item in missing:
		_missing.append(String(item))
	_build()

func _ready() -> void:
	if not _built:
		_build()

func _build() -> void:
	if _built:
		return
	_built = true
	layer = 90

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color("#2b2622")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	CozyUITheme.apply_panel(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 26)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(CozyUITheme.heading(TITLE, 22))

	var body := Label.new()
	body.text = BODY
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(560, 0)
	CozyUITheme.apply_body_label(body, 14)
	column.add_child(body)

	if not _missing.is_empty():
		column.add_child(CozyUITheme.heading("Missing or inactive:", 15))
		var list := Label.new()
		var lines: Array[String] = []
		for item in _missing:
			lines.append("· %s" % item)
		list.text = "\n".join(lines)
		list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.custom_minimum_size = Vector2(560, 0)
		CozyUITheme.apply_secondary_label(list, 12)
		column.add_child(list)
