extends PlaceableCrate
class_name PlaceableMailbox

@onready var slot_glow: Polygon2D = $SlotGlow
@onready var flag: Polygon2D = $Flag

var _has_new_mail: bool = false

func get_interaction_type() -> String:
	return ContentIds.INTERACTION_MAILBOX

func set_has_new_mail(is_active: bool) -> void:
	_has_new_mail = is_active
	_apply_mail_visual_state()

func set_preview_mode(is_preview: bool) -> void:
	super.set_preview_mode(is_preview)
	_apply_mail_visual_state()

func set_placed_visual() -> void:
	super.set_placed_visual()
	_apply_mail_visual_state()

func set_selected(is_selected: bool) -> void:
	super.set_selected(is_selected)
	_apply_mail_visual_state()

func _apply_mail_visual_state() -> void:
	if slot_glow == null or flag == null:
		return

	if _is_preview:
		flag.visible = false
		slot_glow.visible = true
		slot_glow.color = Color(0.976471, 0.890196, 0.596078, 0.55)
		return

	flag.visible = _has_new_mail
	slot_glow.visible = true
	slot_glow.color = Color(0.976471, 0.890196, 0.596078, 0.95) if _has_new_mail else Color(0.976471, 0.890196, 0.596078, 0.28)
