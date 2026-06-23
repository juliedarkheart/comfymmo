extends Node
class_name WorldRegionManager

## Boot + future instance loader. Its ONLY current job is to load the single
## continuous overworld at startup (`_load_starting_region` -> "overworld").
##
## IMPORTANT: outdoor traversal is now continuous walking in ONE scene. It must NEVER
## scene-swap. Do not re-add outdoor Area2D transitions or per-area region swapping —
## that paged model was deliberately retired (see docs/overworld_architecture.md).
##
## The deferred-swap + cooldown + fade machinery below is intentionally kept for
## FUTURE non-outdoor instances only: dungeons, caves, interiors, and special towns.
## Those will request `transition_to_region(<instance_id>)`; returning loads the
## overworld again. The legacy paged region scenes remain registered solely as
## fallbacks / interior templates and are not used for outdoor play.

const OVERWORLD_SCENE := preload("res://scenes/world/overworld.tscn")
# Legacy paged outdoor regions, kept as fallbacks / future interior templates. They
# are no longer the outdoor world — the continuous overworld replaces outdoor paging.
const HOMESTEAD_REGION_SCENE := preload("res://scenes/world/regions/homestead/homestead_region.tscn")
const VILLAGE_SQUARE_REGION_SCENE := preload("res://scenes/world/regions/village_square/village_square_region.tscn")
const FOREST_EDGE_REGION_SCENE := preload("res://scenes/world/regions/forest_edge/forest_edge_region.tscn")
const OVERWORLD_REGION_ID := "overworld"
const TRANSITION_COOLDOWN_MSEC: int = 400

var save_system: LocalSaveSystem
var _region_definitions: Dictionary = {}
var _active_region: Node
var _region_root: Node
var _transition_cooldown_until_msec: int = 0
var _last_transition_from_region_id: String = ""
var _last_transition_to_region_id: String = ""
var _transition_pending: bool = false
var _pending_region_id: String = ""
var _pending_spawn_id: String = ""
var _transition_overlay: ColorRect

const TRANSITION_FADE_PEAK: float = 0.5
const TRANSITION_FADE_TIME: float = 0.32

func _ready() -> void:
	save_system = LocalSaveSystem.new()
	save_system.name = "LocalSaveSystem"
	add_child(save_system)

	_region_root = Node.new()
	_region_root.name = "RegionRoot"
	add_child(_region_root)

	_build_transition_overlay()
	_register_default_regions()
	_load_starting_region()

func _build_transition_overlay() -> void:
	# A persistent full-screen veil that lives above the swapped region scenes (so it
	# survives the swap) and renders over their HUDs. It is normally fully
	# transparent and ignores input; a brief fade masks the instant region cut so
	# travel reads as walking through, not a teleport.
	var overlay_layer: CanvasLayer = CanvasLayer.new()
	overlay_layer.name = "TransitionOverlayLayer"
	overlay_layer.layer = 100
	add_child(overlay_layer)

	_transition_overlay = ColorRect.new()
	_transition_overlay.name = "TransitionOverlay"
	_transition_overlay.color = Color(0.05, 0.05, 0.08)
	_transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.modulate.a = 0.0
	overlay_layer.add_child(_transition_overlay)

func _play_transition_fade() -> void:
	if _transition_overlay == null:
		return

	_transition_overlay.modulate.a = TRANSITION_FADE_PEAK
	var tween: Tween = create_tween()
	tween.tween_property(_transition_overlay, "modulate:a", 0.0, TRANSITION_FADE_TIME)

func transition_to_region(region_id: String, spawn_id: String = "default") -> void:
	# This is reached from an Area2D body_entered callback during Godot's physics
	# query flush. Unloading/loading scenes and spawning the player body here would
	# mutate physics state mid-flush ("Can't change this state while flushing
	# queries"). So we only validate + queue here, and perform the actual swap in a
	# deferred call that runs after the flush completes.
	var now_msec: int = Time.get_ticks_msec()
	var source_region_id: String = _get_active_region_id()

	# Debounce the immediate bounce-back across a freshly crossed region edge.
	if (
		now_msec < _transition_cooldown_until_msec
		and source_region_id == _last_transition_to_region_id
		and region_id == _last_transition_from_region_id
	):
		return

	if not _region_definitions.has(region_id):
		push_warning("Unknown region id: %s" % region_id)
		return

	# Ignore extra requests (e.g. a second overlapping trigger in the same flush)
	# while a transition is already queued or running.
	if _transition_pending:
		return

	_pending_region_id = region_id
	_pending_spawn_id = spawn_id
	_transition_pending = true
	call_deferred("_process_pending_transition")

func _process_pending_transition() -> void:
	if not _transition_pending:
		return

	var region_id: String = _pending_region_id
	var spawn_id: String = _pending_spawn_id

	var source_region_id: String = _get_active_region_id()

	save_system.set_current_region_id(region_id)

	if _active_region != null and is_instance_valid(_active_region):
		_region_root.remove_child(_active_region)
		_active_region.queue_free()

	# Runs outside the physics flush, so adding the destination scene (and the
	# player CharacterBody2D it spawns in _ready) is safe.
	_load_region(region_id, spawn_id)
	_play_transition_fade()

	_last_transition_from_region_id = source_region_id
	_last_transition_to_region_id = region_id
	_transition_cooldown_until_msec = Time.get_ticks_msec() + TRANSITION_COOLDOWN_MSEC

	_transition_pending = false
	_pending_region_id = ""
	_pending_spawn_id = ""

func _load_starting_region() -> void:
	# Outdoor traversal is now one continuous overworld; it never scene-swaps. Only
	# future instances (dungeons, caves, interiors) will use region swapping. Any
	# legacy outdoor current_region_id resolves to the overworld.
	#
	# Visual provider readiness is advisory, not a boot gate. Preferred local packs
	# may be missing/corrupt; the registries fall through to generated/procedural
	# assets so the playable homestead always boots.
	if LiveVisualPolicy.limezu_is_live_provider():
		var limezu_status := LimeZuArtRegistry.readiness()
		var limezu_tier := String(limezu_status.get("tier", LimeZuArtRegistry.READINESS_ABSENT))
		var reason := LimeZuArtRegistry.missing_reason()
		if bool(limezu_status.get("usable_for_live", false)):
			if limezu_tier != LimeZuArtRegistry.READINESS_FULL_LIVE_SLICE and not reason.is_empty():
				push_warning("[visual-provider] %s" % reason)
		elif not reason.is_empty():
			push_warning("[visual-fallback] LimeZu live assets unavailable: %s" % reason)
	var sprout_requirement: Dictionary = SproutAssetRequirement.check()
	if not bool(sprout_requirement["ok"]):
		push_warning("[visual-fallback] %s" % String(sprout_requirement["summary"]))
	_load_region(OVERWORLD_REGION_ID, "default")

func _show_missing_assets_screen(missing: Array) -> void:
	var screen := MissingAssetsScreen.new()
	screen.name = "MissingAssetsScreen"
	_region_root.add_child(screen)
	screen.setup(missing)
	_active_region = null

func _get_active_region_id() -> String:
	if _active_region != null and is_instance_valid(_active_region) and _active_region is BaseRegionController:
		return (_active_region as BaseRegionController).get_region_id()
	return OVERWORLD_REGION_ID

func _load_region(region_id: String, spawn_id: String) -> void:
	var region_definition: RegionDefinition = _region_definitions.get(region_id, null) as RegionDefinition
	if region_definition == null or region_definition.scene == null:
		return

	var region: Node = region_definition.scene.instantiate()
	# BaseRegionController instances (future dungeons/interiors) get the region id,
	# entry spawn, and transition wiring. The continuous overworld is a plain
	# controller that never requests outdoor transitions, so it skips this.
	if region is BaseRegionController:
		var base_region: BaseRegionController = region as BaseRegionController
		base_region.set_region_id(region_definition.region_id)
		base_region.set_entry_spawn_id(spawn_id)
		base_region.region_transition_requested.connect(_on_region_transition_requested)
	_region_root.add_child(region)
	_active_region = region

func _on_region_transition_requested(target_region_id: String, target_spawn_id: String) -> void:
	transition_to_region(target_region_id, target_spawn_id)

func _register_default_regions() -> void:
	_register_region(OVERWORLD_REGION_ID, "Overworld", OVERWORLD_SCENE)
	# Legacy paged regions remain registered as fallbacks / interior templates.
	_register_region("homestead", "Homestead", HOMESTEAD_REGION_SCENE)
	_register_region("village_square", "Village Square", VILLAGE_SQUARE_REGION_SCENE)
	_register_region("forest_edge", "Forest Edge", FOREST_EDGE_REGION_SCENE)

func _register_region(region_id: String, display_name: String, scene: PackedScene) -> void:
	var region_definition: RegionDefinition = RegionDefinition.new()
	region_definition.region_id = region_id
	region_definition.display_name = display_name
	region_definition.scene = scene
	_region_definitions[region_id] = region_definition
