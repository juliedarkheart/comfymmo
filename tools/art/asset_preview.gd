extends Control

## In-editor asset preview. Open this scene and press F6 (Run Current Scene) to
## see the ACTIVE art the registries resolve — terrain tiles (with a small
## isometric tessellation cluster), objects/prefabs, and UI/tool icons — each
## labeled with its id and source tier (generated / external / missing). This is
## the visual companion to the art/review/ contact sheets, so assets are judged
## in-engine instead of guessed headlessly. It reads only the art registries and
## never changes game state. See docs/asset_review_workflow.md.

const ICON_IDS: Array[String] = [
	"wood", "stone", "fiber", "clay", "carrot",
	"worn_axe", "worn_pickaxe", "worn_hoe", "watering_can", "simple_hammer",
	"basic_shovel", "land_token", "build_tool", "delete", "rotate", "paint",
]

func _ready() -> void:
	var rows: VBoxContainer = $Scroll/Rows
	rows.add_theme_constant_override("separation", 12)
	var active: int = ArtActivation.active_count()
	_add_title(rows, "Hearthvale Asset Preview")
	_add_note(rows, "Showing ACTIVE art. %d external override(s) active; everything else uses the cozy generated placeholders. Run with F6." % active)

	_add_heading(rows, "Isometric tessellation (terrain tiles)")
	rows.add_child(_iso_cluster())

	_add_terrain_section(rows, "Terrain tiles", TerrainArtRegistry.required_ids())
	_add_object_section(rows, "Objects & prefabs", ObjectArtRegistry.required_ids())
	_add_object_section(rows, "UI / tool icons", ICON_IDS)

# --- sections ---------------------------------------------------------------

func _add_terrain_section(parent: VBoxContainer, title: String, ids: Array) -> void:
	_add_heading(parent, title)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for id_variant in ids:
		var id: String = String(id_variant)
		var path: String = TerrainArtRegistry.texture_path(id)
		grid.add_child(_tile(load(path) as Texture2D, id, TerrainArtRegistry.source_of(path)))

func _add_object_section(parent: VBoxContainer, title: String, ids: Array) -> void:
	_add_heading(parent, title)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for id_variant in ids:
		var id: String = String(id_variant)
		var path: String = ObjectArtRegistry.texture_path(id)
		grid.add_child(_tile(load(path) as Texture2D, id, ObjectArtRegistry.source_of(path)))

func _tile(texture: Texture2D, id: String, source: String) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(104, 116)
	var frame := PanelContainer.new()
	CozyUITheme.apply_slot(frame, source == "external")
	box.add_child(frame)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = Vector2(88, 72)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(rect)
	var name_label := Label.new()
	name_label.text = id if id.length() <= 16 else id.substr(0, 15) + "…"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUITheme.apply_secondary_label(name_label, 10)
	box.add_child(name_label)
	var src_label := Label.new()
	src_label.text = source
	src_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	src_label.add_theme_font_size_override("font_size", 9)
	src_label.add_theme_color_override("font_color",
		CozyUITheme.BAD if source == "missing" else (CozyUITheme.HONEY if source == "external" else CozyUITheme.GOOD))
	box.add_child(src_label)
	return box

## A 4x4 isometric cluster of terrain tiles, to judge how they tessellate.
func _iso_cluster() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(640, 230)
	var biomes: Array[String] = ["meadow", "forest", "orchard", "creekside", "hilltop", "grove", "town", "farmland"]
	var origin := Vector2(300, 30)
	for y in range(4):
		for x in range(4):
			var biome: String = biomes[(x + y * 4) % biomes.size()]
			var rect := TextureRect.new()
			rect.texture = TerrainArtRegistry.texture(biome)
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			rect.position = origin + Vector2((x - y) * 32, (x + y) * 16)
			rect.z_index = x + y
			holder.add_child(rect)
	return holder

# --- helpers ----------------------------------------------------------------

func _add_title(parent: VBoxContainer, text: String) -> void:
	var label := CozyUITheme.heading(text, 24)
	parent.add_child(label)

func _add_heading(parent: VBoxContainer, text: String) -> void:
	parent.add_child(CozyUITheme.heading(text, 16))

func _add_note(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_body_label(label, 12)
	parent.add_child(label)
