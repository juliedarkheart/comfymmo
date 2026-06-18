extends CanvasLayer

## Left-side quick tools strip: one chip per starter tool (axe, pickaxe, hoe,
## watering can, hammer, shovel) showing ownership at a glance — bright when
## owned, dimmed when missing. Refreshed by the controller on inventory/server
## changes via a count getter. Ownership-only for now (the game checks owning a
## tool, not an "active" selection); hotkeys 1–6 are documented future work so
## they can't clash with existing keys.

const TOOL_ORDER: Array[String] = [
	ItemIds.TOOL_WORN_AXE, ItemIds.TOOL_WORN_PICKAXE, ItemIds.TOOL_WORN_HOE,
	ItemIds.TOOL_WATERING_CAN, ItemIds.TOOL_SIMPLE_HAMMER, ItemIds.TOOL_BASIC_SHOVEL,
	ContentIds.ITEM_CARROT, ItemIds.QUEST_LAND_TOKEN,
]
const TOOL_GLYPHS := {
	"worn_axe": "Axe", "worn_pickaxe": "Pick", "worn_hoe": "Hoe",
	"watering_can": "Can", "simple_hammer": "Build", "basic_shovel": "Dig",
	"carrot": "Food", "land_token": "Land",
}

var _get_count: Callable = Callable()
var _chips: Dictionary = {}

@onready var _strip: BoxContainer = $Panel/Strip

func _ready() -> void:
	CozyUITheme.apply_hud_panel($Panel)
	var title: Label = get_node_or_null("Panel/Strip/ToolsTitle") as Label
	if title != null:
		title.visible = false

func setup(get_count: Callable) -> void:
	_get_count = get_count
	_build_chips()
	refresh()

func _build_chips() -> void:
	for i in range(TOOL_ORDER.size()):
		var tool_id: String = TOOL_ORDER[i]
		var chip: Label = Label.new()
		chip.custom_minimum_size = Vector2(70, 46)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.clip_text = false
		chip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		CozyUITheme.apply_body_label(chip, 11, true)
		_strip.add_child(chip)
		_chips[tool_id] = chip

func refresh() -> void:
	if not _get_count.is_valid():
		return
	var live_limezu: bool = LiveVisualPolicy.live_limezu_slice()
	for i in range(TOOL_ORDER.size()):
		var tool_id: String = TOOL_ORDER[i]
		var owned: bool = int(_get_count.call(tool_id)) > 0
		var chip: Label = _chips[tool_id]
		chip.text = "%d\n%s%s" % [
			i + 1,
			String(TOOL_GLYPHS.get(tool_id, tool_id)),
			" *" if owned else "",
		]
		# Owned tools use the plain slot; missing ones use the dimmed/blocked slot. (Gold
		# "selected" styling is reserved for an actual selection, not mere ownership.)
		chip.add_theme_stylebox_override("normal", CozyUITheme.slot_box(i == 0, not owned))
		var owned_color: Color = LimeZuUITheme.readable_text_color() if live_limezu else CozyUITheme.INK
		var missing_color: Color = LimeZuUITheme.disabled_text_color() if live_limezu else CozyUITheme.INK_SOFT
		chip.add_theme_color_override("font_color", owned_color if owned else missing_color)
