extends CanvasLayer

## Crafting panel: recipe rows with live affordability, per-recipe Craft
## buttons, and friendly lock/denial text. Opened by interacting with a placed
## station ("Press F to craft") or with K for hand-crafting. The panel itself
## owns no game state — it asks the controller for counts/level/stations and
## delegates crafting through callables, so offline and server modes share one
## UI. Esc or Close hides it. Mouse-driven; movement keys keep working
## (consistent with the wardrobe panel — documented dev/prototype behaviour).

var _get_count: Callable = Callable()        # (item_id) -> int
var _get_level: Callable = Callable()        # () -> int
var _get_stations: Callable = Callable()     # () -> Array of nearby station ids
var _do_craft: Callable = Callable()         # (recipe_id) -> void (result arrives via refresh/status)
var _get_skills: Callable = Callable()       # () -> {skill_id: level}

var _rows: Dictionary = {}
var _status_label: Label = null
var _header_label: Label = null

@onready var _root_rows: VBoxContainer = $Panel/Rows
@onready var _recipe_list: VBoxContainer = $Panel/Rows/Scroll/RecipeList

func setup(get_count: Callable, get_level: Callable, get_stations: Callable, do_craft: Callable, get_skills: Callable = Callable()) -> void:
	_get_count = get_count
	_get_level = get_level
	_get_stations = get_stations
	_do_craft = do_craft
	_get_skills = get_skills

func _ready() -> void:
	visible = false
	_build_static_rows()
	_build_recipe_rows()

func open_panel() -> void:
	visible = true
	set_status("")
	refresh()

func close_panel() -> void:
	visible = false

func is_open() -> bool:
	return visible

func set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_panel()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _build_static_rows() -> void:
	var title: Label = Label.new()
	title.text = "Crafting  —  Esc to close"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#f8de9a"))
	_root_rows.add_child(title)
	_root_rows.move_child(title, 0)

	_header_label = Label.new()
	_header_label.add_theme_font_size_override("font_size", 13)
	_header_label.add_theme_color_override("font_color", Color(0.87, 0.79, 0.68, 0.9))
	_root_rows.add_child(_header_label)
	_root_rows.move_child(_header_label, 1)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color("#d9c89a"))
	_root_rows.add_child(_status_label)

func _build_recipe_rows() -> void:
	for recipe_variant in CraftingRegistry.player_recipes():
		var recipe: Dictionary = recipe_variant as Dictionary
		var recipe_id: String = String(recipe["recipe_id"])

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_recipe_list.add_child(row)

		var info: Label = Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_theme_font_size_override("font_size", 14)
		row.add_child(info)

		var craft_button: Button = Button.new()
		craft_button.text = "Craft"
		craft_button.custom_minimum_size = Vector2(64, 0)
		craft_button.pressed.connect(_on_craft_pressed.bind(recipe_id))
		row.add_child(craft_button)

		_rows[recipe_id] = {"info": info, "button": craft_button}

func _on_craft_pressed(recipe_id: String) -> void:
	if _do_craft.is_valid():
		_do_craft.call(recipe_id)
	refresh()

func refresh() -> void:
	if _get_level.is_valid() and _header_label != null:
		var level: int = int(_get_level.call())
		var stations: Array = _get_stations.call() if _get_stations.is_valid() else []
		var station_text: String = "hand crafting only" if stations.is_empty() else "near: %s" % ", ".join(
			stations.map(func(s): return String(s).capitalize())
		)
		_header_label.text = "Level %d  ·  %s" % [level, station_text]

	for recipe_id in _rows.keys():
		var recipe: Dictionary = CraftingRegistry.get_recipe(String(recipe_id))
		var widgets: Dictionary = _rows[recipe_id]
		var info: Label = widgets["info"]
		var craft_button: Button = widgets["button"]

		var check: Dictionary = {"ok": false, "reason": ""}
		if _get_count.is_valid() and _get_level.is_valid() and _get_stations.is_valid():
			var skill_levels: Dictionary = _get_skills.call() if _get_skills.is_valid() else {}
			check = CraftingSystem.check(
				String(recipe_id), _get_count, int(_get_level.call()), _get_stations.call(), skill_levels
			)
		var craftable: bool = bool(check.get("ok", false))
		craft_button.disabled = not craftable

		var suffix: String = "" if craftable else "  —  %s" % String(check.get("reason", ""))
		info.text = "%s x%d  (%s)%s" % [
			String(recipe["display_name"]), int(recipe["output_amount"]),
			CraftingRegistry.inputs_text(recipe), suffix,
		]
		info.add_theme_color_override(
			"font_color",
			Color("#f5f0e6") if craftable else Color(0.96, 0.93, 0.85, 0.55)
		)
