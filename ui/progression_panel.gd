extends CanvasLayer

## Progression panel (P): player level + every skill with XP-to-next. Reads a
## snapshot through a controller callable (local save offline, server
## progression when connected) and owns no state itself. Esc or P closes.

var _get_snapshot: Callable = Callable()
var _player_label: Label = null
var _skill_labels: Dictionary = {}

@onready var _rows: VBoxContainer = $Panel/Rows

func setup(get_snapshot: Callable) -> void:
	_get_snapshot = get_snapshot

func _ready() -> void:
	visible = false
	_build_rows()

func toggle_panel() -> void:
	visible = not visible
	if visible:
		refresh()

func is_open() -> bool:
	return visible

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
	var title: Label = Label.new()
	title.text = "Progression  —  P / Esc to close"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#f8de9a"))
	_rows.add_child(title)

	_player_label = Label.new()
	_player_label.add_theme_font_size_override("font_size", 16)
	_player_label.add_theme_color_override("font_color", Color("#f5f0e6"))
	_rows.add_child(_player_label)

	for skill_id in ProgressionRegistry.SKILL_IDS:
		var row: Label = Label.new()
		row.add_theme_font_size_override("font_size", 14)
		row.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 0.95))
		_rows.add_child(row)
		_skill_labels[skill_id] = row

	var hint: Label = Label.new()
	hint.text = "XP: gather, mine, farm, craft, build, chat with villagers,\nwatch creatures, finish mailbox tasks."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.87, 0.79, 0.68, 0.75))
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
