extends CanvasLayer

@onready var _day_label: Label = $Panel/Rows/DayRow/DayLabel
@onready var _comfort_label: Label = $Panel/Rows/ComfortRow/ComfortLabel
@onready var _carrot_label: Label = $Panel/Rows/InvRow/CarrotLabel
@onready var _turnip_label: Label = $Panel/Rows/InvRow/TurnipLabel
@onready var _berry_label: Label = $Panel/Rows/InvRow/BerryLabel
@onready var _mode_label: Label = $Panel/Rows/ModeLabel
@onready var _controls_label: Label = $Panel/Rows/ControlsLabel

var _controls_text: String = "Move: WASD/Arrows | Eat: C | Inv: I | Time: T | Zoom: PgUp/PgDn (R reset) | Dev: F10"
var _mood_display: String = "Morning"
var _day_number: int = 1
var _current_mode_name: String = "Explore"
var _current_help_text: String = "Move with WASD or arrow keys. B to place. E to edit."
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
	set_mood(WorldMood.DEFAULT_MOOD)
	_hide_interaction_prompt()
	hide_mailbox()

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
	_current_help_text = help_text
	_refresh_text()

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
	# The status panel is icon rows now: day/time, comfort, and per-crop counts
	# each have their own labeled row, then the active mode + help, then the
	# dimmer global controls reference at the bottom.
	if _day_label == null:
		return
	_day_label.text = "Day %d  ·  %s" % [_day_number, _mood_display]
	_comfort_label.text = _survival_text
	_carrot_label.text = str(int(_inventory_counts.get("carrot", 0)))
	_turnip_label.text = str(int(_inventory_counts.get("turnip", 0)))
	_berry_label.text = str(int(_inventory_counts.get("berry", 0)))
	_mode_label.text = "Mode: %s — %s" % [_current_mode_name, _current_help_text]
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
		"I to close",
	])
