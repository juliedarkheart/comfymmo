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
const DEV_CHARACTER_CREATOR_SCENE := preload("res://ui/dev_character_creator_panel.tscn")
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

	# Saved appearance + the dev character creator (F9). The avatar built its
	# default look in _ready; rebuild with the persisted appearance (old saves
	# without the key resolve to the same default, so this is a no-op for them).
	var avatar_visual: Node = null
	if player != null:
		avatar_visual = player.get_node_or_null("Body")
	if avatar_visual != null and avatar_visual.has_method("rebuild"):
		avatar_visual.call("rebuild", save_system.get_player_appearance())

	var creator_panel: CanvasLayer = DEV_CHARACTER_CREATOR_SCENE.instantiate() as CanvasLayer
	creator_panel.name = "DevCharacterCreatorPanel"
	add_child(creator_panel)
	creator_panel.call("setup", avatar_visual, save_system)

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
	register_world_interactable(
		"ow_maribel", maribel, ContentIds.INTERACTION_VILLAGER, "Press F to talk to Maribel",
		_talk_villager.bind("ow_maribel")
	)
	_villager_data["ow_maribel"] = {
		"villager": maribel, "intro": MARIBEL_INTRO_FLAG, "count": MARIBEL_COUNT_FLAG,
		"passage": Callable(self, "_maribel_passage_line"),
	}

	var bram: SimpleVillager = BRAM_SCENE.instantiate() as SimpleVillager
	bram.position = c + Vector2(60, 452)
	gameplay_layer.add_child(bram)
	register_world_interactable(
		"ow_bram", bram, ContentIds.INTERACTION_VILLAGER, "Press F to talk to Bram",
		_talk_villager.bind("ow_bram")
	)
	_villager_data["ow_bram"] = {
		"villager": bram, "intro": BRAM_INTRO_FLAG, "count": BRAM_COUNT_FLAG,
		"passage": Callable(self, "_bram_passage_line"),
	}

	var notice: Node2D = _build_notice_marker(c + Vector2(176, 160))
	register_world_interactable(
		"ow_notice", notice, ContentIds.INTERACTION_NOTICE_BOARD, "Press F to read notice board",
		_open_notice_board
	)

	var rabbit: MossRabbit = MossRabbit.new()
	rabbit.position = c + Vector2(-10, 360)
	gameplay_layer.add_child(rabbit)
	rabbit.configure_creature(player)
	register_world_interactable(
		"ow_village_rabbit", rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
		_handle_creature_observe.bind("ow_village_rabbit")
	)
	_ambient_creatures["ow_village_rabbit"] = rabbit

func _spawn_forest_content(player: AvatarController) -> void:
	var c: Vector2 = OverworldMap.FOREST_OFFSET
	var shrine: Node2D = _build_shrine_marker(c + Vector2(136, 166))
	register_world_interactable(
		"ow_shrine", shrine, ContentIds.INTERACTION_SHRINE_MARKER, "Press F to inspect shrine",
		_open_shrine
	)

	var rabbit_positions: Array[Vector2] = [Vector2(32, 304), Vector2(192, 448), Vector2(-64, 448)]
	for i in range(rabbit_positions.size()):
		var rabbit: MossRabbit = MossRabbit.new()
		rabbit.position = c + rabbit_positions[i]
		gameplay_layer.add_child(rabbit)
		rabbit.configure_creature(player)
		var rabbit_id: String = "ow_forest_rabbit_%d" % i
		register_world_interactable(
			rabbit_id, rabbit, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
			_handle_creature_observe.bind(rabbit_id)
		)
		_ambient_creatures[rabbit_id] = rabbit

	var moth_positions: Array[Vector2] = [Vector2(224, 336), Vector2(-128, 320)]
	for i in range(moth_positions.size()):
		var moth: LanternMoth = LanternMoth.new()
		moth.position = c + moth_positions[i]
		gameplay_layer.add_child(moth)
		moth.configure_creature(player)
		var moth_id: String = "ow_forest_moth_%d" % i
		register_world_interactable(
			moth_id, moth, ContentIds.INTERACTION_AMBIENT_CREATURE, "Press F to observe",
			_handle_creature_observe.bind(moth_id)
		)
		_ambient_creatures[moth_id] = moth

# Interaction dispatch is fully inherited now: villagers, notice board, shrine, and
# creatures were registered with bound callbacks via register_world_interactable, so
# HomesteadController._on_interaction_requested's default branch dispatches them
# after the same four panel/mode guards this controller previously duplicated.

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
	# Cozy village notice board: warm frame, little domed roof cap, and a few
	# colorful pinned notes.
	var marker: Node2D = Node2D.new()
	marker.position = world_pos
	gameplay_layer.add_child(marker)
	for px in [-18, 18]:
		var post: Polygon2D = Polygon2D.new()
		post.position = Vector2(px, 0)
		post.color = Color("#a8754a")
		post.polygon = PackedVector2Array([Vector2(-3.5, -40), Vector2(3.5, -40), Vector2(3.5, 10), Vector2(-3.5, 10)])
		marker.add_child(post)
	var frame: Polygon2D = Polygon2D.new()
	frame.position = Vector2(0, -28)
	frame.color = Color("#a8754a")
	frame.polygon = PackedVector2Array([Vector2(-30, -20), Vector2(30, -20), Vector2(30, 20), Vector2(-30, 20)])
	marker.add_child(frame)
	var board: Polygon2D = Polygon2D.new()
	board.position = Vector2(0, -28)
	board.color = Color("#e0bf8a")
	board.polygon = PackedVector2Array([Vector2(-26, -16), Vector2(26, -16), Vector2(26, 16), Vector2(-26, 16)])
	marker.add_child(board)
	var roof: Polygon2D = Polygon2D.new()
	roof.polygon = TerrainShapes.dome(Vector2(0, -48), 34.0, 12.0, 12)
	roof.color = Color("#c97a6a")
	marker.add_child(roof)
	for note_data in [
		[Vector2(-14, -32), Color("#faeecd")],
		[Vector2(2, -26), Color("#e8a0b4")],
		[Vector2(15, -33), Color("#9fc4e8")],
	]:
		var note: Polygon2D = Polygon2D.new()
		note.position = note_data[0]
		note.color = note_data[1]
		note.polygon = PackedVector2Array([Vector2(-6, -7), Vector2(6, -7), Vector2(6, 7), Vector2(-6, 7)])
		marker.add_child(note)
		var pin: Polygon2D = Polygon2D.new()
		pin.position = note_data[0] + Vector2(0, -6)
		pin.color = Color("#c25448")
		pin.polygon = PackedVector2Array([Vector2(0, -1.5), Vector2(1.5, 0), Vector2(0, 1.5), Vector2(-1.5, 0)])
		marker.add_child(pin)
	return marker

func _build_shrine_marker(world_pos: Vector2) -> Node2D:
	# Gentle old shrine: mossy mound, rounded weathered stone, and a soft warm
	# glow with a halo — mysterious but friendly.
	var marker: Node2D = Node2D.new()
	marker.position = world_pos
	gameplay_layer.add_child(marker)
	var mound: Polygon2D = Polygon2D.new()
	mound.color = Color("#7da964")
	mound.polygon = TerrainShapes.ellipse(Vector2(0, 10), 28.0, 10.0, 16)
	marker.add_child(mound)
	var stone: Polygon2D = Polygon2D.new()
	stone.color = Color("#8b8f88")
	stone.polygon = TerrainShapes.ellipse(Vector2(0, 2), 24.0, 12.0, 16)
	marker.add_child(stone)
	var body: Polygon2D = Polygon2D.new()
	body.color = Color("#aab0a3")
	body.polygon = TerrainShapes.ellipse(Vector2(0, -20), 17.0, 21.0, 16)
	marker.add_child(body)
	var moss_cap: Polygon2D = Polygon2D.new()
	moss_cap.color = Color("#7da964")
	moss_cap.polygon = TerrainShapes.dome(Vector2(0, -36), 12.0, 6.0, 10)
	marker.add_child(moss_cap)
	var halo: Polygon2D = Polygon2D.new()
	halo.color = Color(0.95, 0.89, 0.62, 0.25)
	halo.polygon = TerrainShapes.ellipse(Vector2(0, -24), 13.0, 13.0, 16)
	marker.add_child(halo)
	var glow: Polygon2D = Polygon2D.new()
	glow.color = Color(0.95, 0.89, 0.62, 0.9)
	glow.polygon = TerrainShapes.ellipse(Vector2(0, -24), 6.5, 7.5, 12)
	marker.add_child(glow)
	return marker
