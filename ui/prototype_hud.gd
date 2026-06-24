extends CanvasLayer

@onready var _day_label: Label = $Panel/Rows/DayRow/DayLabel
@onready var _comfort_label: Label = $Panel/Rows/ComfortRow/ComfortLabel
@onready var _carrot_label: Label = $Panel/Rows/InvRow/CarrotLabel
@onready var _turnip_label: Label = $Panel/Rows/InvRow/TurnipLabel
@onready var _berry_label: Label = $Panel/Rows/InvRow/BerryLabel
@onready var _materials_label: Label = $Panel/Rows/MaterialsLabel
@onready var _identity_label: Label = $Panel/Rows/IdentityLabel
@onready var _area_label: Label = $Panel/Rows/AreaLabel
@onready var _mode_label: Label = $Panel/Rows/ModeLabel
@onready var _controls_label: Label = $Panel/Rows/ControlsLabel

var _controls_text: String = "Esc Menu | I Inv | B Build | E Edit\nM Map | H Help | F11 Window"
var _mood_display: String = "Morning"
var _day_number: int = 1
var _current_mode_name: String = "Explore"
var _current_help_text: String = "Explore"
var _survival_text: String = "Comfort: 100"
var _interaction_prompt_text: String = ""
var _inventory_text: String = "Carrots: 0 | Turnips: 0 | Berries: 0"
var _inventory_counts: Dictionary = {
	"carrot": 0,
	"turnip": 0,
	"berry": 0,
}
var _mailbox_open: bool = false
var _message_panel_open: bool = false
var _inventory_panel_open: bool = false

func _ready() -> void:
	_apply_style()
	_apply_compact_normal_layout()
	_compose_card()
	set_mood(WorldMood.DEFAULT_MOOD)
	_hide_interaction_prompt()
	hide_mailbox()
	DisplaySettings.apply_saved()

## Compose the flat label stack into a tiered status card: re-enable the small cozy
## day/comfort icons for visual rhythm, and add thin wood dividers under the title and
## before the secondary (area/mode) block for clear hierarchy. Runs after the compact
## layout (which hides the meaningless crop-count icons), so only day/comfort show.
func _compose_card() -> void:
	_enable_row_icon("Panel/Rows/DayRow/DayIcon", 18)
	_enable_row_icon("Panel/Rows/ComfortRow/ComfortIcon", 18)
	_insert_hud_divider_after(get_node_or_null("Panel/Rows/TitleLabel"))
	_insert_hud_divider_after(_materials_label)

func _enable_row_icon(path: String, px: int) -> void:
	var node: TextureRect = get_node_or_null(path) as TextureRect
	if node == null:
		return
	if LiveVisualPolicy.live_limezu_slice():
		# SEMANTIC LimeZu-family icons (a day/calendar + a comfort/heart token), never
		# an empty UI slot frame (that read as a blank/missing HUD icon).
		var limezu_icon_id := "icon.day" if path.contains("DayIcon") else "icon.comfort"
		if LimeZuArtRegistry.has_asset(limezu_icon_id):
			node.texture = LimeZuArtRegistry.resolve_texture(limezu_icon_id)
			node.visible = node.texture != null
			node.custom_minimum_size = Vector2(28, 28)
			node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			return
		# No semantic LimeZu icon resolved — hide the decorative icon rather than
		# show a blank slot.
		node.visible = false
		return
	node.visible = true
	node.custom_minimum_size = Vector2(px, px)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _insert_hud_divider_after(node: Node) -> void:
	if node == null or node.get_parent() == null:
		return
	var rows: Node = node.get_parent()
	var divider: ColorRect = ColorRect.new()
	divider.color = Color(LimeZuUITheme.PANEL_BORDER.r, LimeZuUITheme.PANEL_BORDER.g, LimeZuUITheme.PANEL_BORDER.b, 0.5)
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(divider)
	rows.move_child(divider, node.get_index() + 1)

func _apply_style() -> void:
	CozyUITheme.apply_hud_panel($Panel)
	CozyUITheme.apply_hud_panel($InteractionPrompt)
	CozyUITheme.apply_hud_panel($MailboxPanel)
	CozyUITheme.apply_hud_panel($InventoryPanel)
	for label in [
		_day_label, _comfort_label, _carrot_label, _turnip_label, _berry_label,
		_materials_label, _identity_label, _area_label, _mode_label, _controls_label,
		$InteractionPrompt/Label, $MailboxPanel/Margin/MailboxLabel,
		$InventoryPanel/Margin/InventoryLabel,
	]:
		CozyUITheme.apply_body_label(label as Label, 11, true)
	CozyUITheme.apply_heading_label($Panel/Rows/TitleLabel, 14)
	# Hierarchy: title (gold) -> primary status (day/comfort/materials, body) -> secondary
	# (area + mode, muted) so the card reads as grouped tiers, not one flat text run.
	CozyUITheme.apply_secondary_label(_area_label, 11)
	CozyUITheme.apply_secondary_label(_mode_label, 11)
	# The area + controls lines are the longest; wrap them inside the panel so they never
	# clip past the border on the fixed-width compact card (300px) regardless of skin.
	for wrap_label in [_area_label, _controls_label, _mode_label]:
		if wrap_label != null:
			wrap_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _apply_compact_normal_layout() -> void:
	$Panel.custom_minimum_size = Vector2(304, 0)
	$Panel.set_meta("normal_hud_role", "compact_status_card")
	_identity_label.visible = false
	# Keep the default HUD a clean status card: the full control list lives in Help (H) /
	# the system menu, so the long controls hint is hidden here (its text is preserved for
	# the F11 flash + validation). This is the "no long control hints in the HUD" rule.
	if _controls_label != null:
		_controls_label.visible = false
	# The bare-number crop row reads as a meaningless "0  0  0" once its old prototype
	# icons are hidden, so the whole row is hidden in normal play. Crop counts stay in
	# the inventory panel (I); the HUD keeps the compact build-materials line.
	var inv_row: CanvasItem = get_node_or_null("Panel/Rows/InvRow") as CanvasItem
	if inv_row != null:
		inv_row.visible = false
	for node_path in [
		"Panel/Rows/DayRow/DayIcon",
		"Panel/Rows/ComfortRow/ComfortIcon",
		"Panel/Rows/InvRow/InvIcon",
		"Panel/Rows/InvRow/CarrotIcon",
		"Panel/Rows/InvRow/TurnipIcon",
		"Panel/Rows/InvRow/BerryIcon",
	]:
		var node := get_node_or_null(node_path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplaySettings.toggle_fullscreen()
		set_interaction_prompt("")
		if _mode_label != null:
			_flash_controls("Window: %s (F11 to toggle)" % (
				"Fullscreen" if fullscreen else "Windowed (bordered)"
			))
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _flash_controls(text: String) -> void:
	if _controls_label != null:
		_controls_label.text = text
		_controls_label.visible = true
		var timer: SceneTreeTimer = get_tree().create_timer(2.5)
		timer.timeout.connect(func() -> void:
			if _controls_label != null:
				_controls_label.text = _controls_text
				_controls_label.visible = false
		)

func set_identity_line(text: String) -> void:
	if _identity_label != null:
		_identity_label.text = text
		_identity_label.visible = false

func set_area_line(text: String) -> void:
	if _area_label != null:
		_area_label.text = "Area: %s" % text

func set_mood(mood_id: String) -> void:
	_mood_display = WorldMood.display_name(mood_id)
	var mood_tint: ColorRect = get_node_or_null("MoodTint") as ColorRect
	if mood_tint != null:
		mood_tint.color = WorldMood.tint_color(mood_id)
	_refresh_text()

func set_day(day_count: int) -> void:
	_day_number = maxi(1, day_count)
	_refresh_text()

func set_mode_text(mode_name: String, help_text: String) -> void:
	_current_mode_name = mode_name
	_current_help_text = _compact_help_text(help_text)
	_refresh_text()

func _compact_help_text(help_text: String) -> String:
	var text := help_text.strip_edges()
	if text.is_empty():
		return "Explore"
	text = text.replace("Press ", "")
	text = text.replace("Use ", "")
	return text.substr(0, 34) + ("..." if text.length() > 34 else "")

func set_interaction_prompt(prompt_text: String) -> void:
	_interaction_prompt_text = prompt_text
	if _interaction_prompt_text.is_empty() or _mailbox_open or _message_panel_open:
		_hide_interaction_prompt()
		return

	$InteractionPrompt.visible = true
	$InteractionPrompt/Label.text = _interaction_prompt_text

func set_inventory_text(inventory_text: String) -> void:
	_inventory_text = inventory_text
	_refresh_text()

func set_inventory_counts(counts: Dictionary) -> void:
	_inventory_counts = {
		"carrot": int(counts.get("carrot", 0)),
		"turnip": int(counts.get("turnip", 0)),
		"berry": int(counts.get("berry", 0)),
	}
	_inventory_text = "Carrots: %d | Turnips: %d | Berries: %d" % [
		int(_inventory_counts.get("carrot", 0)),
		int(_inventory_counts.get("turnip", 0)),
		int(_inventory_counts.get("berry", 0)),
	]
	_refresh_text()
	if _inventory_panel_open:
		$InventoryPanel/Margin/InventoryLabel.text = _format_inventory_panel_text()

func set_survival_text(survival_text: String) -> void:
	_survival_text = survival_text
	_refresh_text()

func set_materials_text(materials_text: String) -> void:
	if _materials_label != null:
		_materials_label.text = materials_text

func toggle_inventory_panel() -> void:
	if _inventory_panel_open:
		hide_inventory_panel()
		return
	show_inventory_panel()

func show_inventory_panel() -> void:
	_inventory_panel_open = true
	$InventoryPanel.visible = true
	$InventoryPanel/Margin/InventoryLabel.text = _format_inventory_panel_text()

func hide_inventory_panel() -> void:
	_inventory_panel_open = false
	$InventoryPanel.visible = false
	$InventoryPanel/Margin/InventoryLabel.text = ""

func is_inventory_panel_open() -> bool:
	return _inventory_panel_open

func show_mailbox(messages: Array[Dictionary]) -> void:
	_mailbox_open = true
	_hide_interaction_prompt()
	$MailboxPanel.visible = true
	$MailboxPanel/Margin/MailboxLabel.text = _format_mailbox_text(messages)

func show_message_panel(title: String, body: String, footer: String = "Esc to close") -> void:
	_message_panel_open = true
	_hide_interaction_prompt()
	$MailboxPanel.visible = true
	var lines: Array[String] = [title, ""]
	if not body.is_empty():
		lines.append(body)
		lines.append("")
	lines.append(footer)
	$MailboxPanel/Margin/MailboxLabel.text = "\n".join(lines)

func hide_mailbox() -> void:
	_mailbox_open = false
	$MailboxPanel.visible = false
	$MailboxPanel/Margin/MailboxLabel.text = ""
	if not _interaction_prompt_text.is_empty():
		set_interaction_prompt(_interaction_prompt_text)

func hide_message_panel() -> void:
	_message_panel_open = false
	$MailboxPanel.visible = false
	$MailboxPanel/Margin/MailboxLabel.text = ""
	if not _interaction_prompt_text.is_empty():
		set_interaction_prompt(_interaction_prompt_text)

func is_mailbox_open() -> bool:
	return _mailbox_open

func _refresh_text() -> void:
	if _day_label == null:
		return
	_day_label.text = "Day %d | %s" % [_day_number, _mood_display]
	_comfort_label.text = _survival_text
	_carrot_label.text = str(int(_inventory_counts.get("carrot", 0)))
	_turnip_label.text = str(int(_inventory_counts.get("turnip", 0)))
	_berry_label.text = str(int(_inventory_counts.get("berry", 0)))
	# Avoid the "Explore | Explore" duplicate when the mode name and its help hint match.
	if _current_help_text.is_empty() or _current_help_text == _current_mode_name:
		_mode_label.text = _current_mode_name
	else:
		_mode_label.text = "%s | %s" % [_current_mode_name, _current_help_text]
	_controls_label.text = _controls_text

func _hide_interaction_prompt() -> void:
	$InteractionPrompt.visible = false
	$InteractionPrompt/Label.text = ""

func _format_mailbox_text(messages: Array[Dictionary]) -> String:
	var new_count: int = 0
	for message in messages:
		if not bool(message.get("seen", false)):
			new_count += 1

	var lines: Array[String] = [
		"Mailbox (%s new)" % new_count,
		"",
	]
	for message in messages:
		var seen_label: String = "[Done]" if bool(message.get("completed", false)) else ("[Seen]" if bool(message.get("seen", false)) else "[New]")
		var title: String = String(message.get("title", message.get("label", "")))
		var body: String = String(message.get("body", ""))
		lines.append("- %s %s" % [seen_label, title])
		if not body.is_empty():
			lines.append("  %s" % body)
	lines.append("")
	lines.append("Esc to close")
	return "\n".join(lines)

func _format_inventory_panel_text() -> String:
	return "\n".join([
		"Inventory",
		"",
		"Carrots: %d" % int(_inventory_counts.get("carrot", 0)),
		"Turnips: %d" % int(_inventory_counts.get("turnip", 0)),
		"Berries: %d" % int(_inventory_counts.get("berry", 0)),
		"",
		"I or Esc to close",
	])
