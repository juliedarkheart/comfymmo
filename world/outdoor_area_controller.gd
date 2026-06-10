extends Node2D
class_name OutdoorAreaController

## Thin shared base for outdoor area controllers — phase 1 of the structural refactor
## that will eventually let OverworldController stop extending HomesteadController.
##
## It holds ONLY generic, gameplay-free helpers: sibling-system lookups, player/camera
## lookups, a safe HUD call wrapper, and input-handled marking. It owns NO gameplay —
## no farming, placement, mailbox, rest, mood/day, villager, creature, shrine, or save
## logic. Those still live in HomesteadController.
##
## Current (transitional) chain:
##   OverworldController -> HomesteadController -> OutdoorAreaController -> Node2D
##
## `extends Node2D` is deliberate (NOT BaseRegionController): the overworld is a
## continuous scene that must never be treated as a swappable region, and the
## Homestead/Overworld controllers were already Node2D-based. Extending the region
## machinery here would change WorldRegionManager's boot wiring, which phase 1 avoids.
## See docs/overworld_architecture.md.

## Sibling-system lookups (mirror BaseRegionController's `_get_region_*`, public names).
func get_hud() -> CanvasLayer:
	return get_node_or_null("HUD") as CanvasLayer

func get_save_system() -> LocalSaveSystem:
	return get_node_or_null("LocalSaveSystem") as LocalSaveSystem

func get_interactable_system() -> InteractableSystem:
	return get_node_or_null("InteractableSystem") as InteractableSystem

## Finds the spawned player avatar inside a gameplay layer (the only AvatarController).
func get_player_avatar(in_layer: Node) -> AvatarController:
	if in_layer == null:
		return null
	for child in in_layer.get_children():
		if child is AvatarController:
			return child as AvatarController
	return null

func get_camera(player: Node) -> AvatarCamera:
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as AvatarCamera

## Safe HUD call: invokes `method` only if the HUD exists and exposes it.
func call_hud(method: String, args: Array = []) -> void:
	OutdoorControllerHelpers.call_if_has(get_hud(), method, args)

func _mark_input_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

# --- Observe / message panel lifecycle (generic) ------------------------------
# A small modal "world message" panel used for creature-observe text, villager
# dialogue, notice board, and the shrine. The generic state + open/close live here;
# subclasses provide area-specific input suspension through the hooks below. WHEN to
# open and the message TEXT stay in the controllers (content-specific). Behaviour is
# identical to the prior inline HomesteadController implementation.

var _observe_panel_open: bool = false

func is_observe_panel_open() -> bool:
	return _observe_panel_open

func _open_observe_panel(title: String, body: String, footer: String = "") -> void:
	_observe_panel_open = true
	var interactable: InteractableSystem = get_interactable_system()
	if interactable != null:
		interactable.set_interactions_enabled(false)
	_set_area_input_suspended(true)
	if footer.is_empty():
		call_hud("show_message_panel", [title, body])
	else:
		call_hud("show_message_panel", [title, body, footer])

func _close_observe_panel() -> void:
	_observe_panel_open = false
	call_hud("hide_message_panel")
	var interactable: InteractableSystem = get_interactable_system()
	if interactable != null:
		interactable.set_interactions_enabled(_area_interactions_enabled())
	_set_area_input_suspended(false)

## Hook: suspend/resume area-specific input while a panel is open (e.g. building
## placement). Default is a no-op; an area with placement overrides this.
func _set_area_input_suspended(_suspended: bool) -> void:
	pass

## Hook: whether proximity interactions should re-enable when a panel closes. Default
## true; an area with a decorating/edit mode overrides this to stay disabled there.
func _area_interactions_enabled() -> bool:
	return true

# --- World interactable registration (generic plumbing) ------------------------
# A thin wrapper over InteractableSystem registration that also remembers an
# optional per-id callback (bound at registration, invoked with no args) and an
# optional data dictionary. The base owns NO gameplay: content controllers still
# decide what to register, the prompt/type/id strings, and what the callbacks do.
# Mirrors BaseRegionController.register_region_interactable's callback pattern.

var _world_interactable_callbacks: Dictionary = {}
var _world_interactable_data: Dictionary = {}

func register_world_interactable(
	interactable_id: String,
	node: Node2D,
	interaction_type: String,
	prompt: String,
	callback: Callable = Callable(),
	data: Dictionary = {}
) -> bool:
	if interactable_id.is_empty() or node == null:
		return false

	var interactable: InteractableSystem = get_interactable_system()
	if interactable == null:
		return false

	interactable.register_interactable(interactable_id, node, interaction_type, prompt)
	if callback.is_valid():
		_world_interactable_callbacks[interactable_id] = callback
	if not data.is_empty():
		_world_interactable_data[interactable_id] = data
	return true

func unregister_world_interactable(interactable_id: String) -> void:
	if interactable_id.is_empty():
		return

	var interactable: InteractableSystem = get_interactable_system()
	if interactable != null:
		interactable.unregister_interactable(interactable_id)
	_world_interactable_callbacks.erase(interactable_id)
	_world_interactable_data.erase(interactable_id)

func has_world_interactable(interactable_id: String) -> bool:
	return _world_interactable_callbacks.has(interactable_id) or _world_interactable_data.has(interactable_id)

func get_world_interactable_data(interactable_id: String) -> Dictionary:
	var entry: Variant = _world_interactable_data.get(interactable_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	return entry as Dictionary

## Invokes the registered callback for an id, if any. Returns true when handled.
## Callers apply their own guards (panels/modes) BEFORE dispatching, exactly as the
## previous inline match dispatch did.
func _dispatch_world_interactable(interactable_id: String) -> bool:
	var callback: Callable = _world_interactable_callbacks.get(interactable_id, Callable()) as Callable
	if callback.is_valid():
		callback.call()
		return true
	return false
