extends HomesteadController
class_name OverworldController

## The continuous overworld controller. It inherits the full homestead gameplay
## stack (farming, placement, mailbox, rest, mood/day, creatures, inventory,
## comfort, save) unchanged, then adds the village and forest content — villagers,
## notice board, shrine, and their ambient creatures — into the same single scene.
## No outdoor scene swapping happens; this is one continuous world.
##
## INHERITANCE NOTE (transitional): `extends HomesteadController` was the low-risk
## way to reuse the proven gameplay stack during the pivot away from paged regions.
## It is stable and intentionally kept for now. The eventual cleaner shape is a
## shared `OutdoorAreaController` base (or component systems) that both the overworld
## and any future authored area build on; do NOT attempt that refactor casually —
## it must preserve every system here. See docs/overworld_architecture.md.

const MARIBEL_SCENE := preload("res://scenes/villagers/maribel_tock.tscn")
const BRAM_SCENE := preload("res://scenes/villagers/bram_nettle.tscn")
# Constant names kept; values now come from ContentIds (stable, save-compatible).
const VILLAGE_REGION_ID := ContentIds.AREA_VILLAGE_SQUARE
const FOREST_REGION_ID := ContentIds.AREA_FOREST_EDGE
const MARIBEL_INTRO_FLAG := ContentIds.FLAG_MARIBEL_INTRO_SEEN
const MARIBEL_COUNT_FLAG := ContentIds.FLAG_MARIBEL_VISIT_COUNT
const BRAM_INTRO_FLAG := ContentIds.FLAG_BRAM_INTRO_SEEN
const BRAM_COUNT_FLAG := ContentIds.FLAG_BRAM_VISIT_COUNT
const NOTICE_SEEN_FLAG := ContentIds.FLAG_NOTICE_BOARD_SEEN
const SHRINE_SEEN_FLAG := ContentIds.FLAG_ADVENTURE_MARKER_SEEN

var _villager_data: Dictionary = {}

func _ready() -> void:
	super._ready()
	var player: AvatarController = _find_player()
	_apply_overworld_camera(player)
	_spawn_village_content(player)
	_spawn_forest_content(player)
	_setup_dev_overlay(player)

func _setup_dev_overlay(player: AvatarController) -> void:
	var camera: AvatarCamera = get_camera(player)

	# A world-space layer (origin-aligned, drawn above props) that holds temporary
	# dev markers. It carries no collision and is never saved.
	var marker_layer: Node2D = Node2D.new()
	marker_layer.name = "DevMarkerLayer"
	marker_layer.z_index = 200
	map.add_child(marker_layer)

	var editor: OverworldEditorSystem = OverworldEditorSystem.new()
	editor.name = "OverworldEditorSystem"
	add_child(editor)
	editor.setup(player, camera, marker_layer)

func _find_player() -> AvatarController:
	# Player lookup is now a shared OutdoorAreaController helper (phase-1 seam).
	return get_player_avatar(gameplay_layer)

func _apply_overworld_camera(player: AvatarController) -> void:
	if player == null:
		return
	var camera: AvatarCamera = get_camera(player)
	if camera != null:
		camera.apply_region_view(map.get_camera_zoom(), map.get_camera_limits())

func _spawn_village_content(player: AvatarController) -> void:
	var c: Vector2 = OverworldMap.VILLAGE_OFFSET
	var maribel: SimpleVillager = MARIBEL_SCENE.instantiate() as SimpleVillager
	maribel.position = c + Vector2(128, 218)
	gameplay_layer.add_child(maribel)
	interactable_system.register_interactable("ow_maribel", maribel, ContentIds.INTERACTION_VILLAGER, "Press F to talk to Maribel")
	_villager_data["ow_maribel"] = {
		"villager": maribel, "intro": MARIBEL_INTRO_FLAG, "count": MARIBEL_COUNT_FLAG,
		"passage": Callable(self, "_maribel_passage_line"),
	}

	var bram: SimpleVillager = BRAM_SCENE.instantiate() as SimpleVillager
	bram.position = c + Vector2(60, 452)
	gameplay_layer.add_child(bram)
	interactable_system.register_interactable("ow_bram", bram, ContentIds.INTERACTION_VILLAGER, "Press F to talk to Bram")
	_villager_data["ow_bram"] = {
		"villager": bram, "intro": BRAM_INTRO_FLAG, "count": BRAM_COUNT_FLAG,
		"passage": Callable(self, "_bram_passage_line"),
	}

	var notice: Node2D = _build_notice_marker(c + Vector2(176, 160))
	interactable_system.register_interactable("ow_notice", notice, ContentIds.INTERACTION_NOTICE_BOARD, "Press F to read notice board")

	var rabbit: MossRabbit = MossRabbit.new()
	rabbit.position = c + Vector2(-10, 360)
	gameplay_layer.add_child(rabbit)
	rabbit.configure_creature(player)
	interactable_system.register_interactable("ow_village_rabbit", rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe")
	_ambient_creatures["ow_village_rabbit"] = rabbit

func _spawn_forest_content(player: AvatarController) -> void:
	var c: Vector2 = OverworldMap.FOREST_OFFSET
	var shrine: Node2D = _build_shrine_marker(c + Vector2(136, 166))
	interactable_system.register_interactable("ow_shrine", shrine, ContentIds.INTERACTION_SHRINE_MARKER, "Press F to inspect shrine")

	var rabbit_positions: Array[Vector2] = [Vector2(32, 304), Vector2(192, 448), Vector2(-64, 448)]
	for i in range(rabbit_positions.size()):
		var rabbit: MossRabbit = MossRabbit.new()
		rabbit.position = c + rabbit_positions[i]
		gameplay_layer.add_child(rabbit)
		rabbit.configure_creature(player)
		var rabbit_id: String = "ow_forest_rabbit_%d" % i
		interactable_system.register_interactable(rabbit_id, rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe")
		_ambient_creatures[rabbit_id] = rabbit

	var moth_positions: Array[Vector2] = [Vector2(224, 336), Vector2(-128, 320)]
	for i in range(moth_positions.size()):
		var moth: LanternMoth = LanternMoth.new()
		moth.position = c + moth_positions[i]
		gameplay_layer.add_child(moth)
		moth.configure_creature(player)
		var moth_id: String = "ow_forest_moth_%d" % i
		interactable_system.register_interactable(moth_id, moth, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe")
		_ambient_creatures[moth_id] = moth

func _on_interaction_requested(interactable_id: String, interaction_type: String) -> void:
	match interaction_type:
		ContentIds.INTERACTION_VILLAGER, ContentIds.INTERACTION_NOTICE_BOARD, ContentIds.INTERACTION_SHRINE_MARKER:
			if _observe_panel_open or _rest_panel_open or _is_mailbox_open() or _decorating_mode_active:
				return
			if interaction_type == ContentIds.INTERACTION_VILLAGER:
				_talk_villager(interactable_id)
			elif interaction_type == ContentIds.INTERACTION_NOTICE_BOARD:
				_open_notice_board()
			else:
				_open_shrine()
		_:
			super._on_interaction_requested(interactable_id, interaction_type)

func _talk_villager(interactable_id: String) -> void:
	var data: Dictionary = _villager_data.get(interactable_id, {})
	if data.is_empty():
		return
	var villager: SimpleVillager = data["villager"]
	var flags: Dictionary = save_system.get_region_flags(VILLAGE_REGION_ID)
	if not bool(flags.get(data["intro"], false)):
		_open_observe_panel(villager.villager_name, villager.first_visit_text)
		save_system.set_region_flag(VILLAGE_REGION_ID, data["intro"], true)
		return
	var visit_count: int = int(flags.get(data["count"], 0))
	var line: String = villager.get_repeat_line(visit_count)
	var passage: Callable = data["passage"]
	if passage.is_valid() and visit_count % 2 == 1:
		line = passage.call(save_system.get_day_count(), save_system.get_current_mood())
	_open_observe_panel(villager.villager_name, line)
	save_system.set_region_flag(VILLAGE_REGION_ID, data["count"], visit_count + 1)

func _open_notice_board() -> void:
	_open_observe_panel("Village Notice Board", "Welcome to the village square. Plans, errands, and little celebrations get pinned here.")
	if not bool(save_system.get_region_flags(VILLAGE_REGION_ID).get(NOTICE_SEEN_FLAG, false)):
		save_system.set_region_flag(VILLAGE_REGION_ID, NOTICE_SEEN_FLAG, true)

func _open_shrine() -> void:
	var seen: bool = bool(save_system.get_region_flags(FOREST_REGION_ID).get(SHRINE_SEEN_FLAG, false))
	var body: String = "The marker still hums softly." if seen else "The path beyond is quiet... for now."
	_open_observe_panel("Old Shrine", body)
	if not seen:
		save_system.set_region_flag(FOREST_REGION_ID, SHRINE_SEEN_FLAG, true)

func _bram_passage_line(day_count: int, mood_id: String) -> String:
	match WorldMood.normalize(mood_id):
		WorldMood.MORNING:
			return "Day %d already. Mornings like this, the flowerbeds near tend themselves." % day_count
		WorldMood.DUSK:
			return "Quiet evenings are good for the nerves. Rest easy when the day is done."
		_:
			return "Feels like a slow sort of afternoon. No hurry in it."

func _maribel_passage_line(day_count: int, mood_id: String) -> String:
	match WorldMood.normalize(mood_id):
		WorldMood.MORNING:
			return "Day %d on the calendar. Each morning I pin up a little hope and see what stays." % day_count
		WorldMood.DUSK:
			return "Dusk again. We have kept the small things %d days now, you and I." % day_count
		_:
			return "A gentle afternoon. I tidy the notices and let the hours wander."

func _build_notice_marker(world_pos: Vector2) -> Node2D:
	var marker: Node2D = Node2D.new()
	marker.position = world_pos
	gameplay_layer.add_child(marker)
	for px in [-16, 16]:
		var post: Polygon2D = Polygon2D.new()
		post.position = Vector2(px, 0)
		post.color = Color("#a8754a")
		post.polygon = PackedVector2Array([Vector2(-4, -36), Vector2(4, -36), Vector2(4, 10), Vector2(-4, 10)])
		marker.add_child(post)
	var board: Polygon2D = Polygon2D.new()
	board.position = Vector2(0, -26)
	board.color = Color("#d8b572")
	board.polygon = PackedVector2Array([Vector2(-28, -18), Vector2(28, -18), Vector2(28, 18), Vector2(-28, 18)])
	marker.add_child(board)
	var paper: Polygon2D = Polygon2D.new()
	paper.position = Vector2(0, -26)
	paper.color = Color("#faeecd")
	paper.polygon = PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(14, 10), Vector2(-14, 10)])
	marker.add_child(paper)
	return marker

func _build_shrine_marker(world_pos: Vector2) -> Node2D:
	var marker: Node2D = Node2D.new()
	marker.position = world_pos
	gameplay_layer.add_child(marker)
	var stone: Polygon2D = Polygon2D.new()
	stone.position = Vector2(0, 4)
	stone.color = Color("#8b8f88")
	stone.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-14, -10), Vector2(0, -14), Vector2(14, -10), Vector2(26, 0), Vector2(14, 12), Vector2(0, 16), Vector2(-14, 12)])
	marker.add_child(stone)
	var body: Polygon2D = Polygon2D.new()
	body.position = Vector2(0, -20)
	body.color = Color("#aab0a3")
	body.polygon = PackedVector2Array([Vector2(-18, 10), Vector2(-18, -8), Vector2(-8, -22), Vector2(8, -22), Vector2(18, -8), Vector2(18, 10), Vector2(8, 18), Vector2(-8, 18)])
	marker.add_child(body)
	var glow: Polygon2D = Polygon2D.new()
	glow.position = Vector2(0, -28)
	glow.color = Color(0.93, 0.87, 0.59, 0.85)
	glow.polygon = PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)])
	marker.add_child(glow)
	return marker
