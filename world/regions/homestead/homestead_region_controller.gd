extends BaseRegionController
class_name HomesteadRegionController

const TARGET_REGION_ID: String = "village_square"
const TARGET_SPAWN_ID: String = "from_homestead"

@onready var region_content: Node2D = $RegionContent
@onready var village_transition_area: Area2D = $VillageTransitionArea
@onready var region_transition_system: RegionTransitionSystem = $RegionTransitionSystem

func _ready() -> void:
	region_transition_system.transition_requested.connect(_on_transition_requested)
	village_transition_area.body_entered.connect(_on_village_transition_body_entered)
	call_deferred("_finalize_region_setup")

func _finalize_region_setup() -> void:
	var map: HomesteadMap = region_content.get_node_or_null("Map") as HomesteadMap
	var player: AvatarController = region_content.get_node_or_null("Map/GameplayLayer/PlayerAvatar") as AvatarController

	if map != null and player != null:
		player.position = map.get_spawn_position(get_entry_spawn_id())
		var camera: AvatarCamera = player.get_node_or_null("Camera2D") as AvatarCamera
		if camera != null:
			camera.apply_region_view(map.get_camera_zoom(), map.get_camera_limits())

func _on_village_transition_body_entered(body: Node) -> void:
	if not body is AvatarController:
		return

	region_transition_system.request_transition(TARGET_REGION_ID, TARGET_SPAWN_ID)

func _on_transition_requested(target_region_id: String, target_spawn_id: String) -> void:
	request_region_transition(target_region_id, target_spawn_id)
