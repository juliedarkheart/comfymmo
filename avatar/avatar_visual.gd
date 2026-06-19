extends Node2D
class_name AvatarVisual

## The player's visual body. Live gameplay uses a registry-backed top-down sprite so
## actors share the same visual source as terrain/objects. The older polygon
## CharacterVisualBuilder is kept as a safe dev fallback if the sprite cannot load.
##
## This script is presentation-only: selected hotbar state may show a tiny held-tool
## icon, but it does not add RPG equipment slots or change tool gameplay.

const FACING_DOWN := "down"
const FACING_UP := "up"
const FACING_SIDE := "side"

const STATE_IDLE_DOWN := "idle_down"
const STATE_IDLE_UP := "idle_up"
const STATE_IDLE_SIDE := "idle_side"
const STATE_WALK_DOWN := "walk_down"
const STATE_WALK_UP := "walk_up"
const STATE_WALK_SIDE := "walk_side"

const HELD_TOOL_LIMEZU_IDS := {
	ItemIds.TOOL_WORN_AXE: "icon.tool_axe",
	ItemIds.TOOL_WATERING_CAN: "icon.tool_watering_can",
	ItemIds.TOOL_BASIC_SHOVEL: "icon.tool_shovel",
}

var selected_hotbar_index: int = -1
var selected_item_id: String = ""
var held_visual_id: String = ""
var facing_direction: String = FACING_DOWN

var _sprite: Sprite2D = null
var _held_tool_attachment: Node2D = null
var _held_tool_sprite: Sprite2D = null
var _animation_state: String = STATE_IDLE_DOWN
var _walk_phase: float = 0.0
var _last_side_sign: float = 1.0

func _ready() -> void:
	rebuild(CharacterAppearance.default_appearance())
	set_process(true)

func rebuild(appearance: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_sprite = null
	_held_tool_attachment = null
	_held_tool_sprite = null

	# Keep this call path explicit: validation checks all actor visuals still route
	# through CharacterArtRegistry before falling back to generated polygons.
	if CharacterArtRegistry.apply_sprite(self, CharacterArtRegistry.PLAYER):
		_sprite = get_child(get_child_count() - 1) as Sprite2D
	else:
		CharacterVisualBuilder.build(self, appearance)
	_ensure_held_tool_attachment()
	_refresh_held_tool()

func _process(delta: float) -> void:
	if _animation_state.begins_with("walk"):
		_walk_phase += delta * 9.0
		position.y = sin(_walk_phase) * 1.8
		rotation = sin(_walk_phase * 0.5) * 0.025
		return
	_walk_phase = 0.0
	position = position.move_toward(Vector2.ZERO, delta * 18.0)
	rotation = move_toward(rotation, 0.0, delta * 8.0)

func set_facing_direction(direction: String, side_sign: float = 0.0) -> void:
	match direction:
		FACING_UP, FACING_SIDE:
			facing_direction = direction
		_:
			facing_direction = FACING_DOWN
	if not is_zero_approx(side_sign):
		_last_side_sign = -1.0 if side_sign < 0.0 else 1.0
	scale.x = _last_side_sign
	_refresh_held_tool_pose()

func set_animation_state(state: String, _movement_vector: Vector2 = Vector2.ZERO) -> void:
	match state:
		STATE_IDLE_UP, STATE_IDLE_SIDE, STATE_WALK_DOWN, STATE_WALK_UP, STATE_WALK_SIDE:
			_animation_state = state
		_:
			_animation_state = STATE_IDLE_DOWN

func set_held_tool_contract(hotbar_index: int, item_id: String, visual_id: String = "") -> void:
	selected_hotbar_index = hotbar_index
	selected_item_id = item_id
	held_visual_id = visual_id if not visual_id.is_empty() else held_visual_id_for_item(item_id)
	_refresh_held_tool()

func clear_held_tool() -> void:
	set_held_tool_contract(-1, "", "")

func get_animation_state() -> String:
	return _animation_state

func get_held_tool_contract() -> Dictionary:
	return {
		"selected_hotbar_index": selected_hotbar_index,
		"selected_item_id": selected_item_id,
		"held_visual_id": held_visual_id,
		"facing_direction": facing_direction,
	}

static func held_visual_id_for_item(item_id: String) -> String:
	if item_id.is_empty() or not ItemIds.is_tool_item(item_id):
		return ""
	if LiveVisualPolicy.live_limezu_slice():
		var limezu_id: String = String(HELD_TOOL_LIMEZU_IDS.get(item_id, ""))
		if not limezu_id.is_empty() and LimeZuArtRegistry.has_asset(limezu_id):
			return limezu_id
	return item_id

func _ensure_held_tool_attachment() -> void:
	if _held_tool_attachment != null and is_instance_valid(_held_tool_attachment):
		return
	_held_tool_attachment = Node2D.new()
	_held_tool_attachment.name = "HeldToolAttachment"
	_held_tool_attachment.z_index = 3
	add_child(_held_tool_attachment)

func _refresh_held_tool() -> void:
	_ensure_held_tool_attachment()
	var tex: Texture2D = _resolve_held_tool_texture()
	if selected_item_id.is_empty() or held_visual_id.is_empty() or tex == null:
		if _held_tool_sprite != null:
			_held_tool_sprite.visible = false
		return
	if _held_tool_sprite == null or not is_instance_valid(_held_tool_sprite):
		_held_tool_sprite = Sprite2D.new()
		_held_tool_sprite.name = "HeldToolSprite"
		_held_tool_sprite.centered = true
		_held_tool_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_held_tool_attachment.add_child(_held_tool_sprite)
	_held_tool_sprite.texture = tex
	var max_dim: float = maxf(float(tex.get_width()), float(tex.get_height()))
	var target_size := 24.0
	var scale_f := target_size / maxf(max_dim, 1.0)
	_held_tool_sprite.scale = Vector2(scale_f, scale_f)
	_held_tool_sprite.visible = true
	_refresh_held_tool_pose()

func _resolve_held_tool_texture() -> Texture2D:
	if held_visual_id.is_empty():
		return null
	if held_visual_id.begins_with("icon.") and LimeZuArtRegistry.has_asset(held_visual_id):
		return LimeZuArtRegistry.resolve_texture(held_visual_id)
	return ObjectArtRegistry.icon_texture_for_item(selected_item_id)

func _refresh_held_tool_pose() -> void:
	if _held_tool_attachment == null:
		return
	match facing_direction:
		FACING_UP:
			_held_tool_attachment.position = Vector2(-8, -17)
			_held_tool_attachment.rotation = -0.25
			_held_tool_attachment.z_index = -1
		FACING_SIDE:
			_held_tool_attachment.position = Vector2(18, -10)
			_held_tool_attachment.rotation = 0.45
			_held_tool_attachment.z_index = 3
		_:
			_held_tool_attachment.position = Vector2(11, -7)
			_held_tool_attachment.rotation = 0.18
			_held_tool_attachment.z_index = 3
