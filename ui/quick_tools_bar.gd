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
]
const TOOL_GLYPHS := {
	"worn_axe": "Axe", "worn_pickaxe": "Pick", "worn_hoe": "Hoe",
	"watering_can": "Can", "simple_hammer": "Hammer", "basic_shovel": "Shovel",
}

var _get_count: Callable = Callable()
var _chips: Dictionary = {}

@onready var _strip: VBoxContainer = $Panel/Strip

func setup(get_count: Callable) -> void:
	_get_count = get_count
	_build_chips()
	refresh()

func _build_chips() -> void:
	for tool_id in TOOL_ORDER:
		var chip: Label = Label.new()
		chip.custom_minimum_size = Vector2(72, 26)
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_theme_font_size_override("font_size", 13)
		_strip.add_child(chip)
		_chips[tool_id] = chip

func refresh() -> void:
	if not _get_count.is_valid():
		return
	for tool_id in TOOL_ORDER:
		var owned: bool = int(_get_count.call(tool_id)) > 0
		var chip: Label = _chips[tool_id]
		chip.text = String(TOOL_GLYPHS.get(tool_id, tool_id))
		chip.add_theme_color_override("font_color", Color("#f5f0e6") if owned else Color(0.6, 0.56, 0.5, 0.6))
