extends Node2D

## LimeZu visual spike — an evaluation-only curated homestead slice built from REAL
## LimeZu Modern Farm assets (resolved via LimeZuArtRegistry, never hardcoded paths,
## never Sprout, never generated filler). It exists to judge whether the LimeZu
## "Modern" ecosystem should become Hearthvale's main visual direction. Run it
## directly in Godot (Run Current Scene) or via tools/visual_spike_capture.gd.
##
## Pixel scale is uniform: every 16px LimeZu source is drawn at x3 (48px cells) with
## nearest filtering, so the slice reads as one coherent pixel-art screen. Assets are
## bottom-anchored to the tile grid and z-ordered by row. If an id is unmapped it is
## silently skipped (no marker) unless DEBUG_MARKERS is on. See docs/limezu_visual_spike.md.

const TILE := 48          # screen px per logical cell (16px art x SCALE)
const SCALE := 3.0        # 16px LimeZu art -> 48px
const GRID_W := 22
const GRID_H := 16
const DEBUG_MARKERS := false   # dev only: show magenta markers for unmapped ids

const SPIKE_IDS := {
	"terrain": ["terrain.grass", "terrain.dirt_path", "terrain.tilled_soil", "terrain.water"],
	"object": ["object.barn", "object.tree", "object.tree_small", "object.fence_horizontal",
		"object.fence_vertical", "object.fence_post", "object.flower", "object.flower2",
		"object.flower3", "object.crate", "object.sign"],
	"crop": ["crop.carrot", "crop.carrot_stage1", "crop.cauliflower", "crop.watermelon"],
	"animal": ["animal.chicken", "animal.cow"],
	"character": ["character.farmer_idle"],
	"icon": ["icon.carrot", "icon.seed", "icon.wood", "icon.tool_axe", "icon.tool_watering_can",
		"icon.tool_shovel", "icon.egg", "icon.cheese"],
}

var _ground: Node2D = null
var _objects: Node2D = null

func _ready() -> void:
	LimeZuArtRegistry.reload()
	_build_background()
	_ground = _layer("Ground")
	_objects = _layer("Objects")
	_build_terrain()
	_build_crops()
	_build_objects()
	_build_actors()
	_build_camera()
	_build_hud_mock()
	_build_inventory_mock()
	_print_spike_report()
	if not LimeZuArtRegistry.is_available():
		_build_missing_banner()

func _layer(node_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	add_child(n)
	return n

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Backdrop"
	bg.color = Color("#6f9352")
	bg.position = Vector2(-TILE * 4, -TILE * 4)
	bg.size = Vector2((GRID_W + 8) * TILE, (GRID_H + 8) * TILE)
	bg.z_index = -200
	add_child(bg)

# --- world composition ------------------------------------------------------

func _build_terrain() -> void:
	# Calm grass base across the whole slice.
	for ty in range(GRID_H):
		for tx in range(GRID_W):
			_ground_tile("terrain.grass", Vector2i(tx, ty), -20)
	# A short dirt path across the front of the barn, linking the garden to the yard.
	var path: Array[Vector2i] = []
	for x in range(6, 14):
		path.append(Vector2i(x, 13))
	for y in range(13, 16):
		path.append(Vector2i(10, y))
	for tile in path:
		_ground_tile("terrain.dirt_path", tile, -18)
	# Compact tilled field (4x3) for crops, tidy rectangular bed (front-left).
	for ty in range(10, 13):
		for tx in range(3, 7):
			_ground_tile("terrain.tilled_soil", Vector2i(tx, ty), -16)

func _build_crops() -> void:
	var crops := ["crop.carrot", "crop.carrot_stage1", "crop.cauliflower", "crop.watermelon"]
	var i := 0
	for ty in range(10, 13):
		for tx in range(3, 7):
			_object_sprite(crops[i % crops.size()], Vector2i(tx, ty), 0, 40)
			i += 1

func _build_objects() -> void:
	# Focal farm building (big), back-centre but fully on-screen (base near row 12).
	_object_sprite("object.barn", Vector2i(8, 12))
	# Garden fences around the tilled bed (front-left).
	for tx in range(2, 8):
		_object_sprite("object.fence_horizontal", Vector2i(tx, 9))
	for ty in range(10, 13):
		_object_sprite("object.fence_vertical", Vector2i(2, ty))
	_object_sprite("object.fence_post", Vector2i(7, 12))
	# Trees framing the corners/sides (kept clear of the barn footprint x8..16).
	_object_sprite("object.tree", Vector2i(0, 13))
	_object_sprite("object.tree", Vector2i(20, 12))
	_object_sprite("object.tree_small", Vector2i(1, 5))
	_object_sprite("object.tree_small", Vector2i(20, 6))
	# Cozy detail: scattered flowers (deterministic placement) in open grass.
	for spot in [Vector2i(4, 14), Vector2i(2, 7), Vector2i(18, 14), Vector2i(19, 9),
			Vector2i(16, 15), Vector2i(3, 4), Vector2i(6, 15)]:
		_object_sprite(["object.flower", "object.flower2", "object.flower3"][(spot.x + spot.y) % 3], spot)
	# Props near the garden / yard.
	_object_sprite("object.crate", Vector2i(15, 14))
	_object_sprite("object.sign", Vector2i(7, 13))

func _build_actors() -> void:
	_object_sprite("animal.chicken", Vector2i(6, 13))
	_object_sprite("animal.cow", Vector2i(13, 14))
	_object_sprite("character.farmer_idle", Vector2i(8, 14))

func _build_camera() -> void:
	var cam := Camera2D.new()
	cam.position = Vector2(480, 432)
	cam.zoom = Vector2(1.3, 1.3)
	add_child(cam)
	cam.make_current()

## A 1-tile ground sprite drawn top-left-anchored on the grid.
func _ground_tile(id: String, tile: Vector2i, z: int) -> void:
	if not LimeZuArtRegistry.has_asset(id):
		if DEBUG_MARKERS:
			_ground.add_child(_marker(id, Vector2(tile.x * TILE, tile.y * TILE)))
		return
	var s := Sprite2D.new()
	s.texture = LimeZuArtRegistry.resolve_texture(id)
	s.centered = false
	s.position = Vector2(tile.x * TILE, tile.y * TILE)
	s.scale = Vector2(SCALE, SCALE)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = z
	_ground.add_child(s)

## An object/actor sprite, bottom-anchored to `base_tile` and z-ordered by row so
## taller things overlap correctly for the screenshot.
func _object_sprite(id: String, base_tile: Vector2i, z_bonus: int = 0, z_base: int = 100) -> void:
	if not LimeZuArtRegistry.has_asset(id):
		if DEBUG_MARKERS:
			_objects.add_child(_marker(id, Vector2(base_tile.x * TILE, base_tile.y * TILE)))
		return
	var tex := LimeZuArtRegistry.resolve_texture(id)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var h := tex.get_height() * SCALE
	# Bottom of the sprite sits on the bottom edge of base_tile.
	s.position = Vector2(base_tile.x * TILE, (base_tile.y + 1) * TILE - h)
	s.scale = Vector2(SCALE, SCALE)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = z_base + base_tile.y + z_bonus
	_objects.add_child(s)

func _marker(id: String, pos: Vector2) -> Node2D:
	var holder := Node2D.new()
	holder.position = pos
	holder.z_index = 800
	var rect := ColorRect.new()
	rect.color = Color(0.9, 0.2, 0.6, 0.4)
	rect.size = Vector2(TILE - 4, TILE - 4)
	holder.add_child(rect)
	var label := Label.new()
	label.text = id
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	holder.add_child(label)
	return holder

# --- UI mocks ---------------------------------------------------------------

func _build_hud_mock() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var panel := _ui_panel_or_card("ui.panel", Vector2(14, 14), Vector2(214, 90))
	layer.add_child(panel)
	var col := VBoxContainer.new()
	col.position = Vector2(14, 12)
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	for line in ["Day 1 · Morning", "Comfort 100", "Mode: Explore"]:
		col.add_child(_ui_label(line, 15))
	col.add_child(_ui_label("LimeZu spike · %d ids active" % LimeZuArtRegistry.list_active_ids().size(), 11))

func _build_inventory_mock() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	# Compact right-side window. Uses a real Modern UI panel if one is mapped, else a
	# clean cozy frame (NOT debug). Item icons are real LimeZu Modern Farm icons.
	var win := _ui_panel_or_card("ui.panel", Vector2(1300, 110), Vector2(280, 340))
	layer.add_child(win)
	var rows := VBoxContainer.new()
	rows.position = Vector2(16, 14)
	rows.custom_minimum_size = Vector2(248, 0)
	rows.add_theme_constant_override("separation", 8)
	win.add_child(rows)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(248, 0)
	rows.add_child(header)
	var title := _ui_label("Inventory", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "X" if not LimeZuArtRegistry.has_asset("ui.close") else ""
	if LimeZuArtRegistry.has_asset("ui.close"):
		close.icon = LimeZuArtRegistry.resolve_texture("ui.close")
	close.pressed.connect(func() -> void: get_tree().quit())
	header.add_child(close)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	rows.add_child(grid)
	var items := [
		["icon.carrot", 12], ["icon.seed", 6], ["icon.wood", 34], ["icon.tool_axe", 1],
		["icon.tool_watering_can", 1], ["icon.tool_shovel", 1], ["icon.egg", 9], ["icon.cheese", 3],
	]
	for item in items:
		grid.add_child(_ui_slot(String(item[0]), int(item[1])))

func _ui_card(pos: Vector2, sz: Vector2) -> Control:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = sz
	panel.size = sz
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.13, 0.10, 0.93)
	style.set_border_width_all(2)
	style.border_color = Color(0.85, 0.69, 0.48, 0.9)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _ui_panel_or_card(ui_id: String, pos: Vector2, sz: Vector2) -> Control:
	if LimeZuArtRegistry.has_asset(ui_id):
		var nine := NinePatchRect.new()
		nine.texture = LimeZuArtRegistry.resolve_texture(ui_id)
		nine.patch_margin_left = 8
		nine.patch_margin_right = 8
		nine.patch_margin_top = 8
		nine.patch_margin_bottom = 8
		nine.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		nine.position = pos
		nine.size = sz
		return nine
	return _ui_card(pos, sz)

func _ui_slot(icon_id: String, count: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(58, 58)
	if LimeZuArtRegistry.has_asset("ui.slot"):
		var frame := NinePatchRect.new()
		frame.texture = LimeZuArtRegistry.resolve_texture("ui.slot")
		frame.set_patch_margin(SIDE_LEFT, 6)
		frame.set_patch_margin(SIDE_RIGHT, 6)
		frame.set_patch_margin(SIDE_TOP, 6)
		frame.set_patch_margin(SIDE_BOTTOM, 6)
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.size = Vector2(58, 58)
		slot.add_child(frame)
	else:
		var box := ColorRect.new()
		box.color = Color(0.96, 0.92, 0.82, 0.14)
		box.size = Vector2(58, 58)
		slot.add_child(box)
		var border := ReferenceRect.new()
		border.editor_only = false
		border.border_color = Color(0.85, 0.69, 0.48, 0.7)
		border.border_width = 1.0
		border.size = Vector2(58, 58)
		slot.add_child(border)
	if LimeZuArtRegistry.has_asset(icon_id):
		var icon := TextureRect.new()
		icon.texture = LimeZuArtRegistry.resolve_texture(icon_id)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = Vector2(9, 7)
		icon.size = Vector2(40, 40)
		slot.add_child(icon)
	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.position = Vector2(32, 38)
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.79))
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	count_label.add_theme_constant_override("outline_size", 3)
	slot.add_child(count_label)
	return slot

func _ui_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.79))
	return label

func _build_missing_banner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var panel := _ui_card(Vector2(40, 40), Vector2(560, 90))
	layer.add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	col.add_child(_ui_label("LimeZu spike — assets not active", 18))
	var body := Label.new()
	body.text = LimeZuArtRegistry.missing_reason()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520, 0)
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
	col.add_child(body)

# --- report -----------------------------------------------------------------

func _print_spike_report() -> void:
	var total := 0
	var resolved := 0
	var missing: Array[String] = []
	for cat in SPIKE_IDS.keys():
		var ids: Array = SPIKE_IDS[cat]
		var r := LimeZuArtRegistry.resolved_count(ids)
		total += ids.size()
		resolved += r
		missing.append_array(LimeZuArtRegistry.missing_ids(ids))
		print("[limezu-spike] %s: %d/%d real" % [cat, r, ids.size()])
	print("[limezu-spike] TOTAL %d/%d spike ids resolve to real LimeZu art (mostly_real=%s)"
		% [resolved, total, resolved >= total * 0.6])
	if not missing.is_empty():
		print("[limezu-spike] unmapped (skipped, no marker in default view): ", missing)
