extends CanvasLayer

## Dev-only character appearance panel (F9). Cycles through every option in
## CharacterAppearanceRegistry, applies changes live to the player via
## AvatarVisual.rebuild(), and persists the result to the local save under
## `player.appearance` (backward-compatible: old saves simply lack the key and
## load defaults). This is a prototype tool, not the final character creator —
## no gameplay state, modes, or interactions are touched while it is open.

const PANEL_TITLE := "Character (dev)  —  F9 to close"
const WARDROBE_TITLE := "Wardrobe  —  F9 to close"

## Slot order and labels for the generated rows. Option ids come from the
## registry at build time so new options appear here automatically.
const SLOTS: Array = [
	{"key": "hair_style", "label": "Hair Style"},
	{"key": "hair_color", "label": "Hair Color"},
	{"key": "skin_tone", "label": "Skin Tone"},
	{"key": "outfit_style", "label": "Outfit"},
	{"key": "outfit_color", "label": "Outfit Color"},
	{"key": "accessory", "label": "Accessory"},
]

var _avatar_visual: Node = null
var _save_system: LocalSaveSystem = null
var _profile_manager: LocalProfileManager = null
var _appearance: Dictionary = CharacterAppearance.default_appearance()
var _value_labels: Dictionary = {}
var _title_label: Label = null

@onready var _rows: VBoxContainer = $Panel/Rows

func setup(avatar_visual: Node, save_system: LocalSaveSystem, profile_manager: LocalProfileManager = null) -> void:
	_avatar_visual = avatar_visual
	_save_system = save_system
	_profile_manager = profile_manager
	if _save_system != null:
		_appearance = _save_system.get_player_appearance()
	_refresh_labels()

## Player-facing entry point (wardrobe mirror). Same panel, friendlier title.
func open_panel(as_wardrobe: bool = false) -> void:
	if _title_label != null:
		_title_label.text = WARDROBE_TITLE if as_wardrobe else PANEL_TITLE
	visible = true
	_refresh_labels()

func _ready() -> void:
	visible = false
	_build_rows()
	_refresh_labels()

func _input(event: InputEvent) -> void:
	# Same early-input pattern as the F10 dev overlay: `_input` runs before all
	# `_unhandled_input` handlers, so gameplay systems can never starve the
	# toggle. The "toggle_character_creator" InputMap action is bound to both
	# logical and physical F9, which also covers laptop Fn-layer keyboards that
	# deliver a remapped logical keycode.
	if not event.is_action_pressed("toggle_character_creator"):
		return
	_toggle_panel()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _toggle_panel() -> void:
	visible = not visible
	if visible:
		if _avatar_visual == null or not is_instance_valid(_avatar_visual):
			push_warning("Character creator: no avatar visual wired; preview will not update")
		_refresh_labels()
	print("Character creator panel %s" % ("opened" if visible else "closed"))

func _build_rows() -> void:
	_title_label = Label.new()
	_title_label.text = PANEL_TITLE
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color("#f8de9a"))
	_rows.add_child(_title_label)

	for slot in SLOTS:
		var key: String = String(slot["key"])
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_rows.add_child(row)

		var name_label: Label = Label.new()
		name_label.text = String(slot["label"])
		name_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(name_label)

		var prev_button: Button = Button.new()
		prev_button.text = "<"
		prev_button.custom_minimum_size = Vector2(34, 0)
		prev_button.pressed.connect(_cycle_slot.bind(key, -1))
		row.add_child(prev_button)

		var value_label: Label = Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.custom_minimum_size = Vector2(140, 0)
		row.add_child(value_label)
		_value_labels[key] = value_label

		var next_button: Button = Button.new()
		next_button.text = ">"
		next_button.custom_minimum_size = Vector2(34, 0)
		next_button.pressed.connect(_cycle_slot.bind(key, 1))
		row.add_child(next_button)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_rows.add_child(footer)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset Default"
	reset_button.pressed.connect(_on_reset_pressed)
	footer.add_child(reset_button)

	var close_button: Button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void: visible = false)
	footer.add_child(close_button)

func _slot_option_ids(key: String) -> Array:
	match key:
		"hair_style":
			return CharacterAppearanceRegistry.hair_styles().keys()
		"hair_color", "outfit_color":
			return CharacterAppearanceRegistry.palette().keys()
		"skin_tone":
			return CharacterAppearanceRegistry.skin_tones().keys()
		"outfit_style":
			return CharacterAppearanceRegistry.outfit_styles().keys()
		"accessory":
			return CharacterAppearanceRegistry.accessories().keys()
		_:
			return []

func _cycle_slot(key: String, direction: int) -> void:
	var options: Array = _slot_option_ids(key)
	if options.is_empty():
		return
	var current_index: int = options.find(_appearance.get(key, ""))
	var next_index: int = wrapi(current_index + direction, 0, options.size())
	_appearance[key] = String(options[next_index])
	_apply_appearance()

func _on_reset_pressed() -> void:
	_appearance = CharacterAppearance.default_appearance()
	_apply_appearance()

func _apply_appearance() -> void:
	_appearance = CharacterAppearance.normalized(_appearance)
	if _avatar_visual != null and _avatar_visual.has_method("rebuild"):
		_avatar_visual.call("rebuild", _appearance)
	if _save_system != null:
		_save_system.set_player_appearance(_appearance)
	# Keep the active profile in step with the save (documented precedence:
	# the wardrobe writes both so they never fight).
	if _profile_manager != null:
		_profile_manager.set_active_appearance(_appearance)
	_refresh_labels()

func _refresh_labels() -> void:
	for key in _value_labels.keys():
		var label: Label = _value_labels[key]
		label.text = String(_appearance.get(key, "")).capitalize()
