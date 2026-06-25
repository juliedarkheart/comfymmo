extends CanvasLayer

## Character appearance panel (F9). Provides dev-unlocked access to compatible
## Modern Interiors layered parts. Hair/Outfit are stored as split style+color
## (e.g. hair_style="hair_22", hair_color="04") and resolved to a combined layer
## texture id at render time.

const PANEL_TITLE := "Character | F9"
const WARDROBE_TITLE := "Wardrobe | F9"

const SLOTS: Array = [
	{"key": "body_presentation", "label": "Skin Tone"},
	{"key": "eyes",             "label": "Eyes"},
	{"key": "hair_style",       "label": "Hair Style"},
	{"key": "hair_color",       "label": "Hair Color"},
	{"key": "outfit_style",     "label": "Outfit"},
	{"key": "outfit_color",     "label": "Outfit Color"},
	{"key": "accessory",        "label": "Accessory"},
]

var _avatar_visual: Node = null
var _save_system: LocalSaveSystem = null
var _profile_manager: LocalProfileManager = null
var _appearance: Dictionary = CharacterAppearance.default_appearance()
var _value_labels: Dictionary = {}
var _title_label: Label = null
var _layered_ready := false
var _rng := RandomNumberGenerator.new()

var _hair_style_base := ""
var _outfit_style_base := ""

@onready var _rows: VBoxContainer = $Panel/Rows
@onready var _panel: PanelContainer = $Panel

func _ready() -> void:
	visible = false
	CozyUITheme.apply_panel(_panel)
	_layered_ready = CharacterPartLibrary.layered_ready()
	_rng.randomize()
	_build_rows()
	_refresh_labels()

func setup(avatar_visual: Node, save_system: LocalSaveSystem, profile_manager: LocalProfileManager = null) -> void:
	_avatar_visual = avatar_visual
	_save_system = save_system
	_profile_manager = profile_manager
	if _save_system != null:
		_appearance = _save_system.get_player_appearance()
	_derive_split_state()
	_refresh_labels()

func open_panel(as_wardrobe: bool = false) -> void:
	if _title_label != null:
		_title_label.text = WARDROBE_TITLE if as_wardrobe else PANEL_TITLE
	visible = true
	_refresh_labels()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_character_creator"):
		return
	_toggle_panel()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _toggle_panel() -> void:
	visible = not visible
	if visible:
		_layered_ready = CharacterPartLibrary.layered_ready()
		_derive_split_state()
		_refresh_labels()

func _build_rows() -> void:
	_title_label = Label.new()
	_title_label.text = PANEL_TITLE
	CozyUITheme.apply_heading_label(_title_label, 18)
	_rows.add_child(_title_label)

	for slot in SLOTS:
		_build_slot_row(String(slot["key"]), String(slot["label"]), true)

	var heading := Label.new()
	heading.text = "  (body layer IS the skin tone)"
	CozyUITheme.apply_secondary_label(heading, 10)
	heading.add_theme_color_override("font_color", Color("#8a5a3a80"))
	_rows.add_child(heading)

	var sep := HSeparator.new()
	_rows.add_child(sep)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	_rows.add_child(preset_row)
	var preset_label := Label.new()
	preset_label.text = "Preset:"
	preset_label.custom_minimum_size = Vector2(50, 0)
	CozyUITheme.apply_body_label(preset_label, 12)
	preset_row.add_child(preset_label)
	for pre in _list_presets():
		var btn := Button.new()
		btn.text = String(pre.get("label", pre.get("id","?")))
		btn.pressed.connect(_apply_preset.bind(pre))
		CozyUITheme.apply_button(btn)
		preset_row.add_child(btn)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	_rows.add_child(btns)

	var rnd_btn := Button.new()
	rnd_btn.text = "Randomize"
	rnd_btn.pressed.connect(_on_randomize_pressed)
	CozyUITheme.apply_button(rnd_btn)
	btns.add_child(rnd_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset Julie"
	reset_btn.pressed.connect(_on_reset_pressed)
	CozyUITheme.apply_button(reset_btn)
	btns.add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void: visible = false)
	CozyUITheme.apply_close_button(close_btn)
	btns.add_child(close_btn)

func _build_slot_row(key: String, label_text: String, _available: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_rows.add_child(row)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(76, 0)
	CozyUITheme.apply_body_label(name_label, 12)
	row.add_child(name_label)

	var prev_button := Button.new()
	prev_button.text = "<"
	prev_button.custom_minimum_size = Vector2(34, 28)
	prev_button.pressed.connect(_cycle_slot.bind(key, -1))
	CozyUITheme.apply_button(prev_button)
	row.add_child(prev_button)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(150, 0)
	CozyUITheme.apply_secondary_label(value_label, 11)
	row.add_child(value_label)
	_value_labels[key] = value_label

	var next_button := Button.new()
	next_button.text = ">"
	next_button.custom_minimum_size = Vector2(34, 28)
	next_button.pressed.connect(_cycle_slot.bind(key, 1))
	CozyUITheme.apply_button(next_button)
	row.add_child(next_button)

## Derive _hair_style_base / _outfit_style_base from the combined IDs in the save.
func _derive_split_state() -> void:
	if _layered_ready:
		var h := String(_appearance.get("hair_style", ""))
		var hs := CharacterPartLibrary.split_id(h)
		if hs.size() == 3:
			_hair_style_base = "%s_%s" % [hs[0], hs[1]]
			_appearance["hair_style"] = _hair_style_base
			if String(_appearance.get("hair_color", "")).is_empty() or not CharacterPartLibrary.colors_for_style_base(_hair_style_base).has(String(_appearance.get("hair_color", ""))):
				_appearance["hair_color"] = hs[2]
		else:
			_hair_style_base = h
			_appearance["hair_color"] = CharacterPartLibrary.valid_color_for_style(_hair_style_base, String(_appearance.get("hair_color", "")))
		var o := String(_appearance.get("outfit_style", ""))
		var os := CharacterPartLibrary.split_id(o)
		if os.size() == 3:
			_outfit_style_base = "%s_%s" % [os[0], os[1]]
			_appearance["outfit_style"] = _outfit_style_base
			if String(_appearance.get("outfit_color", "")).is_empty() or not CharacterPartLibrary.colors_for_style_base(_outfit_style_base).has(String(_appearance.get("outfit_color", ""))):
				_appearance["outfit_color"] = os[2]
		else:
			_outfit_style_base = o
			_appearance["outfit_color"] = CharacterPartLibrary.valid_color_for_style(_outfit_style_base, String(_appearance.get("outfit_color", "")))

func _slot_option_ids(key: String) -> Array:
	match key:
		"body_presentation":
			return CharacterAppearanceRegistry.body_presentations().keys()
		"eyes":
			return CharacterAppearanceRegistry.eyes().keys()
		"hair_style":
			if _layered_ready:
				var bases := CharacterPartLibrary.style_bases_for_category("hairstyles")
				bases.sort()
				return bases
			return CharacterAppearanceRegistry.hair_styles().keys()
		"hair_color":
			return CharacterPartLibrary.colors_for_style_base(_hair_style_base)
		"outfit_style":
			if _layered_ready:
				var bases := CharacterPartLibrary.style_bases_for_category("outfits")
				bases.sort()
				return bases
			return CharacterAppearanceRegistry.outfit_styles().keys()
		"outfit_color":
			return CharacterPartLibrary.colors_for_style_base(_outfit_style_base)
		"accessory":
			return CharacterAppearanceRegistry.layered_accessory_ids()
	return []

func _cycle_slot(key: String, direction: int) -> void:
	var options: Array = _slot_option_ids(key)
	if options.is_empty():
		return
	match key:
		"hair_style":
			var idx := options.find(_hair_style_base)
			idx = wrapi(idx + direction, 0, options.size())
			_hair_style_base = String(options[idx])
			_appearance["hair_style"] = _hair_style_base
			_appearance["hair_color"] = CharacterPartLibrary.valid_color_for_style(_hair_style_base, String(_appearance.get("hair_color", "")))
			_apply_appearance()
			return
		"hair_color":
			var colors := _slot_option_ids("hair_color")
			if colors.size() == 0: return
			var cidx := colors.find(String(_appearance.get("hair_color", "")))
			cidx = wrapi(cidx + direction, 0, colors.size())
			_appearance["hair_color"] = String(colors[cidx])
			_appearance["hair_style"] = _hair_style_base
			_apply_appearance()
			return
		"outfit_style":
			var oidx := options.find(_outfit_style_base)
			oidx = wrapi(oidx + direction, 0, options.size())
			_outfit_style_base = String(options[oidx])
			_appearance["outfit_style"] = _outfit_style_base
			_appearance["outfit_color"] = CharacterPartLibrary.valid_color_for_style(_outfit_style_base, String(_appearance.get("outfit_color", "")))
			_apply_appearance()
			return
		"outfit_color":
			var ocolors := _slot_option_ids("outfit_color")
			if ocolors.size() == 0: return
			var ocidx := ocolors.find(String(_appearance.get("outfit_color", "")))
			ocidx = wrapi(ocidx + direction, 0, ocolors.size())
			_appearance["outfit_color"] = String(ocolors[ocidx])
			_appearance["outfit_style"] = _outfit_style_base
			_apply_appearance()
			return

	var current_index: int = options.find(_appearance.get(key, ""))
	var next_index: int = wrapi(current_index + direction, 0, options.size())
	_appearance[key] = String(options[next_index])
	_apply_appearance()

func _on_reset_pressed() -> void:
	var def := CharacterPartLibrary.julie_default()
	if def.is_empty():
		_appearance = CharacterAppearance.default_appearance()
	else:
		for k in def.keys():
			_appearance[k] = def[k]
	_derive_split_state()
	_apply_appearance()

func _on_randomize_pressed() -> void:
	var hair_bases := _slot_option_ids("hair_style")
	if hair_bases.size() > 0:
		_hair_style_base = String(hair_bases[_rng.randi() % hair_bases.size()])
		var hcolors := CharacterPartLibrary.colors_for_style_base(_hair_style_base)
		if hcolors.size() > 0:
			_appearance["hair_color"] = String(hcolors[_rng.randi() % hcolors.size()])
		_appearance["hair_style"] = _hair_style_base

	var outfit_bases := _slot_option_ids("outfit_style")
	if outfit_bases.size() > 0:
		_outfit_style_base = String(outfit_bases[_rng.randi() % outfit_bases.size()])
		var ocolors := CharacterPartLibrary.colors_for_style_base(_outfit_style_base)
		if ocolors.size() > 0:
			_appearance["outfit_color"] = String(ocolors[_rng.randi() % ocolors.size()])
		_appearance["outfit_style"] = _outfit_style_base

	var body_opts := _slot_option_ids("body_presentation")
	if body_opts.size() > 0:
		_appearance["body_presentation"] = String(body_opts[_rng.randi() % body_opts.size()])
	var eye_opts := _slot_option_ids("eyes")
	if eye_opts.size() > 0:
		_appearance["eyes"] = String(eye_opts[_rng.randi() % eye_opts.size()])
	var acc_opts := _slot_option_ids("accessory")
	if acc_opts.size() > 0:
		_appearance["accessory"] = String(acc_opts[_rng.randi() % acc_opts.size()])
	_apply_appearance()

func _apply_preset(preset: Dictionary) -> void:
	for k in preset.keys():
		if _appearance.has(k) or k == "eyes":
			_appearance[k] = preset[k]
	_derive_split_state()
	_apply_appearance()

func _apply_appearance() -> void:
	_appearance = CharacterAppearance.normalized(_appearance)
	# Re-derive after normalization strips unknown keys
	_derive_split_state()
	if _avatar_visual != null and _avatar_visual.has_method("rebuild"):
		_avatar_visual.call("rebuild", _appearance)
	if _save_system != null:
		_save_system.set_player_appearance(_appearance)
	if _profile_manager != null:
		_profile_manager.set_active_appearance(_appearance)
	_refresh_labels()

func _refresh_labels() -> void:
	for slot in SLOTS:
		var key: String = String(slot["key"])
		if not _value_labels.has(key):
			continue
		var label: Label = _value_labels[key]
		var opts: Array = _slot_option_ids(key)
		var val := ""
		var idx := -1
		var friendly := ""
		match key:
			"hair_style":
				val = _hair_style_base
				idx = opts.find(val)
				friendly = CharacterPartLibrary.hair_style_label(val)
			"hair_color":
				val = String(_appearance.get("hair_color", ""))
				idx = opts.find(val)
				friendly = CharacterPartLibrary.color_label(val)
			"outfit_style":
				val = _outfit_style_base
				idx = opts.find(val)
				friendly = CharacterPartLibrary.outfit_style_label(val)
			"outfit_color":
				val = String(_appearance.get("outfit_color", ""))
				idx = opts.find(val)
				friendly = CharacterPartLibrary.color_label(val)
			_:
				val = String(_appearance.get(key, ""))
				idx = opts.find(val)
				friendly = val.capitalize() if not val.is_empty() else ""
		var display := "?"
		if opts.size() > 0 and idx >= 0:
			display = "%s  %d/%d" % [friendly if not friendly.is_empty() else val, idx + 1, opts.size()]
		elif not val.is_empty():
			display = friendly if not friendly.is_empty() else val.capitalize()
		label.text = display

func _list_presets() -> Array:
	var m := CharacterPartLibrary.manifest()
	var presets: Dictionary = m.get("presets", {}) as Dictionary
	var out: Array = []
	for pid in presets.keys():
		var entry: Dictionary = presets[pid] as Dictionary
		var copy := entry.duplicate(true)
		copy["id"] = pid
		out.append(copy)
	return out
