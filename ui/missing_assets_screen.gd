extends CanvasLayer
class_name MissingAssetsScreen

## Shown by WorldRegionManager INSTEAD of the live overworld when the required
## Sprout Lands pack is missing/inactive (see systems/visual/sprout_asset_requirement.gd).
## Intentionally plain and code-drawn: it is a diagnostic, not part of the cozy live
## visual style, so it must never depend on the Sprout UI it is reporting as absent.

const TITLE := "Sprout assets required"
const BODY := "Hearthvale's live visual build is designed around the licensed Sprout Lands pack (local-only, never committed). It is missing or not activated, so the cozy top-down world will not load.\n\nInstall and activate the Sprout pack under licensed_assets/sprout_lands/ (see docs/licensed_asset_policy.md), then relaunch. A clean checkout without Sprout is no longer a playable visual target — this screen is intentional, not a crash."

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
