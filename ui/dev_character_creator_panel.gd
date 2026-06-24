extends CanvasLayer

## Dev-only character appearance panel (F9). Cycles through every option in
## CharacterAppearanceRegistry, applies changes live to the player via
## AvatarVisual.rebuild(), and persists the result to the local save under
## `player.appearance` (backward-compatible: old saves simply lack the key and
## load defaults). This is a prototype tool, not the final character creator —
## no gameplay state, modes, or interactions are touched while it is open.

const PANEL_TITLE := "Character (dev) | F9"
const WARDROBE_TITLE := "Wardrobe | F9"

## Slot order and labels for the generated rows. Option ids come from the
## registry at build time so new options appear here automatically.
## AVAILABILITY note: hair_style, hair_color, skin_tone, outfit_style, and accessory
## are DISABLED on full-body LimeZu sheets — they do not change the rendered sprite.
## Only body_presentation (sheet selection) and outfit_color (palette tint) are real.
const SLOTS: Array = [
	{"key": "body_presentation", "label": "Body", "available": true},
	{"key": "outfit_color", "label": "Palette", "available": true},
	{"key": "outfit_style", "label": "Outfit", "available": false, "reason": "baked into full-body sheet"},
	{"key": "hair_style", "label": "Hair Style", "available": false, "reason": "baked into full-body sheet"},
	{"key": "hair_color", "label": "Hair Color", "available": false, "reason": "baked into full-body sheet"},
	{"key": "skin_tone", "label": "Skin Tone", "available": false, "reason": "baked into full-body sheet"},
	{"key": "accessory", "label": "Accessory", "available": false, "reason": "baked into full-body sheet"},
]

var _avatar_visual: Node = null
var _save_system: LocalSaveSystem = null
var _profile_manager: LocalProfileManager = null
var _appearance: Dictionary = CharacterAppearance.default_appearance()
var _value_labels: Dictionary = {}
var _title_label: Label = null

@onready var _rows: VBoxContainer = $Panel/Rows
@onready var _panel: PanelContainer = $Panel

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
	CozyUITheme.apply_panel(_panel)
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
	CozyUITheme.apply_heading_label(_title_label, 18)
	_rows.add_child(_title_label)

	# Check layered part availability: if the curated manifest exists and layout is verified,
	# enable hair/outfit/accessory. If manifest exists but layout isn't verified, show needs-review.
	var layered_ready := CharacterPartLibrary.layered_ready()
	var needs_review := CharacterPartLibrary.needs_layout_review()

	for slot in SLOTS:
		var key: String = String(slot["key"])
		# Availability: in LAYERED mode body/hair/outfit/accessory are real (they swap layers);
		# the palette tint is disabled because tinting a layered composite would recolour skin too
		# (colour comes from the chosen outfit/hair part). In full-body fallback mode, keep the
		# SLOTS defaults (only body_presentation + outfit_color tint are real).
		var available: bool = bool(slot.get("available", true))
		if layered_ready:
			match key:
				"body_presentation", "hair_style", "outfit_style", "accessory":
					available = true
				"outfit_color", "hair_color", "skin_tone":
					available = false
		var reason: String = String(slot.get("reason", ""))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_rows.add_child(row)

		var name_label: Label = Label.new()
		name_label.text = String(slot["label"])
		name_label.custom_minimum_size = Vector2(96, 0)
		CozyUITheme.apply_body_label(name_label, 12)
		row.add_child(name_label)

		var prev_button: Button = Button.new()
		prev_button.text = "<"
		prev_button.custom_minimum_size = Vector2(34, 28)
		prev_button.disabled = not available
		prev_button.pressed.connect(_cycle_slot.bind(key, -1))
		CozyUITheme.apply_button(prev_button)
		row.add_child(prev_button)

		var value_label: Label = Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.custom_minimum_size = Vector2(122, 0)
		CozyUITheme.apply_secondary_label(value_label, 12)
		row.add_child(value_label)
		_value_labels[key] = value_label

		var next_button: Button = Button.new()
		next_button.text = ">"
		next_button.custom_minimum_size = Vector2(34, 28)
		next_button.disabled = not available
		next_button.pressed.connect(_cycle_slot.bind(key, 1))
		CozyUITheme.apply_button(next_button)
		row.add_child(next_button)

		# Unavailable note for disabled slots
		if not available:
			var note_label: Label = Label.new()
			if needs_review:
				note_label.text = "(needs layout review)"
			elif not layered_ready:
				note_label.text = "(unavailable)"
			else:
				note_label.text = "(needs review)"
			note_label.custom_minimum_size = Vector2(160, 0)
			CozyUITheme.apply_secondary_label(note_label, 10)
			note_label.add_theme_color_override("font_color", Color("#8a5a3a80"))
			row.add_child(note_label)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_rows.add_child(footer)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(_on_reset_pressed)
	CozyUITheme.apply_button(reset_button)
	footer.add_child(reset_button)

	var close_button: Button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void: visible = false)
	CozyUITheme.apply_close_button(close_button)
	footer.add_child(close_button)

func _slot_option_ids(key: String) -> Array:
	match key:
		"body_presentation":
			return CharacterAppearanceRegistry.body_presentations().keys()
		"hair_style":
			return CharacterAppearanceRegistry.hair_styles().keys()
		"hair_color", "outfit_color":
			return CharacterAppearanceRegistry.palette().keys()
		"skin_tone":
			return CharacterAppearanceRegistry.skin_tones().keys()
		"outfit_style":
			return CharacterAppearanceRegistry.outfit_styles().keys()
		"accessory":
			# Only renderable accessories (layered parts) so no control does nothing.
			return CharacterAppearanceRegistry.layered_accessory_ids()
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
	for slot in SLOTS:
		var key: String = String(slot["key"])
		if not _value_labels.has(key):
			continue
		var label: Label = _value_labels[key]
		if bool(slot.get("available", true)):
			label.text = String(_appearance.get(key, "")).capitalize()
		else:
			label.text = "(unavailable)"
