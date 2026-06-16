extends CanvasLayer

signal select_requested()
signal move_requested()
signal rotate_requested()
signal delete_requested()
signal cancel_requested()

@onready var _mode_label: Label = $Panel/Margin/Rows/ModeLabel
@onready var _selection_label: Label = $Panel/Margin/Rows/SelectionLabel
@onready var _feedback_label: Label = $Panel/Margin/Rows/FeedbackLabel
@onready var _controls_label: Label = $Panel/Margin/Rows/ControlsLabel
@onready var _select_button: Button = $Panel/Margin/Rows/ButtonsTop/SelectButton
@onready var _move_button: Button = $Panel/Margin/Rows/ButtonsTop/MoveButton
@onready var _rotate_button: Button = $Panel/Margin/Rows/ButtonsTop/RotateButton
@onready var _delete_button: Button = $Panel/Margin/Rows/ButtonsBottom/DeleteButton
@onready var _cancel_button: Button = $Panel/Margin/Rows/ButtonsBottom/CancelButton

func _ready() -> void:
	visible = false
	CozyUITheme.apply_panel($Panel)
	CozyUITheme.apply_heading_label(_mode_label, 16)
	CozyUITheme.apply_body_label(_selection_label, 13)
	CozyUITheme.apply_secondary_label(_controls_label, 12)
	for button in [_select_button, _move_button, _rotate_button, _delete_button, _cancel_button]:
		CozyUITheme.apply_button(button)
	CozyUITheme.apply_danger_button(_delete_button)
	CozyUITheme.apply_close_button(_cancel_button)
	_select_button.pressed.connect(func() -> void: select_requested.emit())
	_move_button.pressed.connect(func() -> void: move_requested.emit())
	_rotate_button.pressed.connect(func() -> void: rotate_requested.emit())
	_delete_button.pressed.connect(func() -> void: delete_requested.emit())
	_cancel_button.pressed.connect(func() -> void: cancel_requested.emit())

func set_active(is_active: bool) -> void:
	visible = is_active

func set_mode_text(mode_name: String) -> void:
	if _mode_label != null:
		_mode_label.text = mode_name

func set_selection_text(text: String) -> void:
	if _selection_label != null:
		_selection_label.text = text

func set_controls_text(text: String) -> void:
	if _controls_label != null:
		_controls_label.text = text

func set_feedback_text(text: String, is_error: bool = false) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text = text
	_feedback_label.modulate = Color("#f7d38a") if not is_error else Color("#f4a69b")

func set_button_states(can_select: bool, can_move: bool, can_rotate: bool, can_delete: bool, can_cancel: bool) -> void:
	_select_button.disabled = not can_select
	_move_button.disabled = not can_move
	_rotate_button.disabled = not can_rotate
	_delete_button.disabled = not can_delete
	_cancel_button.disabled = not can_cancel
