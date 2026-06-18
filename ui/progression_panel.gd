extends CanvasLayer

## Progression panel (P): player level + every skill with XP-to-next. Reads a
## snapshot through a controller callable (local save offline, server
## progression when connected) and owns no state itself. Esc or P closes.

var _get_snapshot: Callable = Callable()
var _player_label: Label = null
var _skill_labels: Dictionary = {}

@onready var _rows: VBoxContainer = $Panel/Rows
@onready var _panel: PanelContainer = $Panel

func setup(get_snapshot: Callable) -> void:
	_get_snapshot = get_snapshot

func _ready() -> void:
	visible = false
	CozyUITheme.apply_panel(_panel)
	_build_rows()

func toggle_panel() -> void:
	visible = not visible
	if visible:
		refresh()

func is_open() -> bool:
	return visible

func close_panel() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("cancel_action"):
		visible = false
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _build_rows() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_rows.add_child(header)

	var title: Label = Label.new()
	title.text = "Progress"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUITheme.apply_heading_label(title, 18)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close_panel)
	CozyUITheme.apply_close_button(close_button)
	header.add_child(close_button)

	_player_label = Label.new()
	CozyUITheme.apply_body_label(_player_label, 13)
	_rows.add_child(_player_label)

	for skill_id in ProgressionRegistry.SKILL_IDS:
		var row: Label = Label.new()
		CozyUITheme.apply_body_label(row, 12)
		_rows.add_child(row)
		_skill_labels[skill_id] = row

	var hint: Label = Label.new()
	hint.text = "XP: gather, mine, farm, craft, build,\nchat, watch creatures, finish tasks."
	CozyUITheme.apply_secondary_label(hint, 11)
	_rows.add_child(hint)

func refresh() -> void:
	if not _get_snapshot.is_valid():
		return
	var progression: Dictionary = SkillProgression.normalized(_get_snapshot.call() as Dictionary)
	_player_label.text = PlayerProgression.progress_text(int(progression["total_xp"]))
	for skill_id in _skill_labels.keys():
		var xp: int = SkillProgression.skill_xp(progression, String(skill_id))
		var to_next: int = PlayerProgression.xp_to_next(xp)
		var suffix: String = "max" if to_next < 0 else "%d to next" % to_next
		(_skill_labels[skill_id] as Label).text = "%s  —  Lv %d  (%d XP, %s)" % [
			ProgressionRegistry.skill_display_name(String(skill_id)),
			PlayerProgression.level_for_xp(xp), xp, suffix,
		]
