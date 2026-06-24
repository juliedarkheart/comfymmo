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
# LimeZu sheet id when the body sprite is region/animation-driven (else "" = single idle frame).
var _sheet_id: String = ""
# Layered mode: stack of layer sprites (body, eyes, outfit, hair, accessory)
var _layered_mode := false
var _layer_sprites: Dictionary = {}

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
	_layered_mode = false
	_layer_sprites.clear()
	_sheet_id = ""

	# Try layered rendering first (Character Generator parts if available)
	if CharacterPartLibrary.layered_ready() and appearance.has("body_presentation"):
		_build_layered_sprites(appearance)
		if _layered_mode:
			_ensure_held_tool_attachment()
			_apply_frame()
			_refresh_held_tool()
			return

	# Fall back to full-body sheet rendering
	# Wire the appearance data into the player profile BEFORE building the sprite,
	# so the body_presentation (sheet) and outfit_color (tint) take effect immediately.
	# Player profile is the source of truth for the LimeZu actor sprite.
	CharacterProfileRegistry.apply_player_appearance(appearance)

	# Keep this call path explicit: validation checks all actor visuals still route
	# through CharacterArtRegistry before falling back to generated polygons.
	if CharacterArtRegistry.apply_sprite(self, CharacterArtRegistry.PLAYER):
		_sprite = get_child(get_child_count() - 1) as Sprite2D
		_sheet_id = String(_sprite.get_meta("actor_sheet_id", "")) if _sprite != null else ""
		# Apply the palette tint directly from the appearance data so changes
		# are visible immediately (not just on next boot).
		if _sprite != null:
			var outfit_color_id := String(appearance.get("outfit_color", ""))
			if not outfit_color_id.is_empty():
				var tint := Color.WHITE.lerp(CharacterAppearanceRegistry.color_value(outfit_color_id), 0.32)
				_sprite.modulate = tint
	else:
		CharacterVisualBuilder.build(self, appearance)
		_sheet_id = ""
	_ensure_held_tool_attachment()
	_apply_frame()
	_refresh_held_tool()

## Build the layered sprite stack from the curated Character Generator parts.
## Maps appearance slots (outfit_style, hair_style, accessory) to layer textures.
## Falls back to full-body rendering if any required layer is missing.
func _build_layered_sprites(appearance: Dictionary) -> void:
	# Map appearance fields to curated layer part ids (body = skin/body via presentation map).
	var body_part_id := CharacterPartLibrary.presentation_body(String(appearance.get("body_presentation", "neutral")))
	var eyes_part_id := String(appearance.get("eyes", "eyes_02"))
	var hair_part_id := String(appearance.get("hair_style", ""))
	var outfit_part_id := String(appearance.get("outfit_style", ""))
	var acc_part_id := String(appearance.get("accessory", ""))

	if body_part_id.is_empty():
		return  # no valid body part → fallback

	# Build layer sprites (z_index: body=0, eyes=1, outfit=2, hair=3, accessory=4)
	var part_map := {
		"body": [body_part_id, 0],
		"eyes": [eyes_part_id, 1],
		"outfit": [outfit_part_id, 2],
		"hair": [hair_part_id, 3],
		"accessory": [acc_part_id, 4],
	}

	var any_ok := false
	for layer_name in CharacterPartLibrary.LAYER_ORDER:
		var pair := part_map.get(layer_name, ["", 0]) as Array
		var pid := String(pair[0])
		var z := int(pair[1])
		if pid.is_empty() or pid == "none" or pid == "acc_none":
			continue  # skip empty/none layers

		var entry := CharacterPartLibrary.part_entry(pid)
		if entry.is_empty():
			if layer_name == "body":
				return  # body is required
			continue

		var tex := CharacterPartLibrary.resolve_texture(String(entry.get("file", "")))
		if tex == null:
			if layer_name == "body":
				return
			continue

		var sprite := Sprite2D.new()
		sprite.name = "Layer_%s" % layer_name
		sprite.texture = tex
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.region_enabled = true
		sprite.z_index = z
		sprite.scale = Vector2(2, 2)  # 16px → 32px display
		# Tag with the LimeZu source path + actor category so the visual audit/validation
		# classify the layered player as limezu_raw (a LimeZu-family actor), not procedural.
		sprite.set_meta("visual_source_path", CharacterPartLibrary.CG_ROOT + String(entry.get("file", "")))
		sprite.set_meta("visual_category", "actor")
		sprite.set_meta("visual_id", CharacterArtRegistry.PLAYER)  # categorized as "player avatar"
		sprite.set_meta("limezu_logical_id", "character.layered.%s" % pid)
		add_child(sprite)
		_layer_sprites[layer_name] = sprite
		any_ok = true

	if any_ok:
		_layered_mode = true
		# Feet at origin: every layer is centred and sits half the scaled 16x32 frame above (0,0)
		# so they line up exactly (all share the same cell, pasted at the same spot).
		var frame_h := 32.0 * 2.0  # 16x32 frame * x2 display scale
		for layer_sprite in _layer_sprites.values():
			(layer_sprite as Sprite2D).position = Vector2(0, -frame_h * 0.5)

## Map body_presentation value to a layer part id from the curated set.
func _body_part_for(presentation: String) -> String:
	match String(presentation):
		"feminine": return "body_02"
		"masculine": return "body_05"
		_: return "body_01"  # neutral + default

func _process(delta: float) -> void:
	if _animation_state.begins_with("walk"):
		_walk_phase += delta * 7.0
		position.y = sin(_walk_phase) * 3.0
		rotation = sin(_walk_phase * 0.5) * 0.025
		_apply_frame()   # cycle the directional walk frame(s) under the bob
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
	# Mirror the body only for SIDE (left/right); never flip the up/down poses.
	if facing_direction == FACING_SIDE:
		if not is_zero_approx(side_sign):
			_last_side_sign = -1.0 if side_sign < 0.0 else 1.0
		scale.x = _last_side_sign
	else:
		scale.x = 1.0
	_apply_frame()
	_refresh_held_tool_pose()

func set_animation_state(state: String, _movement_vector: Vector2 = Vector2.ZERO) -> void:
	match state:
		STATE_IDLE_UP, STATE_IDLE_SIDE, STATE_WALK_DOWN, STATE_WALK_UP, STATE_WALK_SIDE:
			_animation_state = state
		_:
			_animation_state = STATE_IDLE_DOWN
	_apply_frame()

## Swap the body sprite's region to the current facing/walk frame.
## In layered mode, ALL layer sprites get the same region_rect for grid sync.
func _apply_frame() -> void:
	if _layered_mode:
		var rect := _layered_frame_rect()
		for sprite in _layer_sprites.values():
			(sprite as Sprite2D).region_rect = Rect2(rect)
		return
	if _sprite == null or not is_instance_valid(_sprite) or _sheet_id.is_empty():
		return
	if not _sprite.region_enabled:
		return
	var frame_index: int = int(_walk_phase) if _animation_state.begins_with("walk") else 0
	_sprite.region_rect = Rect2(CharacterAnimationRegistry.region_for(_sheet_id, _animation_state, frame_index))

## Get the shared 16x32 cell for the current facing/animation state in layered mode. All layers
## use this SAME region (pasted at origin), so they stay composited. Cells are the reviewed
## interiors-generator frames (idle down=(0,0), up=(1,0); down walk = a 2-frame front step).
func _layered_frame_rect() -> Rect2i:
	var idx: int = int(_walk_phase) if _animation_state.begins_with("walk") else 0
	return CharacterAnimationRegistry.generator_region_for(_animation_state, idx)

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
	var target_size := 18.0
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
	# Data-driven hand socket per facing (CharacterAnimationRegistry) so the tool sits on the
	# hand instead of floating, and draws behind the body when the character faces away (up).
	var socket: Dictionary = CharacterAnimationRegistry.hand_socket(facing_direction)
	_held_tool_attachment.position = socket.get("pos", Vector2(6, -13)) as Vector2
	_held_tool_attachment.rotation = float(socket.get("rot", 0.18))
	_held_tool_attachment.z_index = -1 if bool(socket.get("behind", false)) else 3
