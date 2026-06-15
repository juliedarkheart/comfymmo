extends RefCounted
class_name DecorVisuals

## Procedural cute visuals for the decor placeable set, one drawer per content
## id, built from the same soft-ellipse language as the rest of the world
## (TerrainShapes.ellipse/dome). Shared by every PlaceableDecor scene so adding
## a decor item is: ContentIds id + registry entries + a drawer here + a tiny
## scene. Origin is the tile center; shapes sit roughly within one iso tile.

const WOOD := Color("#c89a64")
const WOOD_DARK := Color("#8a5e3c")
const WOOD_LIGHT := Color("#e0bf8a")
const STONE := Color("#a8a49c")
const CREAM := Color("#f2e4c8")
const PINK := Color("#e8a0b4")
const LEAF := Color("#6f9c5f")
const LEAF_LIGHT := Color("#8cba74")

static func _poly(parent: Node2D, points: PackedVector2Array, color: Color) -> void:
	var node: Polygon2D = Polygon2D.new()
	node.polygon = points
	node.color = color
	parent.add_child(node)

static func _ellipse(parent: Node2D, center: Vector2, rx: float, ry: float, color: Color, segments: int = 14) -> void:
	_poly(parent, TerrainShapes.ellipse(center, rx, ry, segments), color)

static func _shadow(parent: Node2D, rx: float = 15.0) -> void:
	_ellipse(parent, Vector2(0, 1), rx, rx * 0.4, Color(0.16, 0.12, 0.08, 0.2))

static func build(parent: Node2D, decor_id: String) -> void:
	_shadow(parent)
	match decor_id:
		ContentIds.PLACEABLE_ROUND_TABLE:
			_poly(parent, PackedVector2Array([Vector2(-2.5, -4), Vector2(2.5, -4), Vector2(3, 0), Vector2(-3, 0)]), WOOD_DARK)
			_ellipse(parent, Vector2(0, -14), 16.0, 9.0, WOOD)
			_ellipse(parent, Vector2(0, -15.5), 12.0, 6.5, WOOD_LIGHT)
		ContentIds.PLACEABLE_COZY_CHAIR:
			_poly(parent, PackedVector2Array([Vector2(-8, -22), Vector2(-3, -24), Vector2(-2, -8), Vector2(-8, -7)]), WOOD)
			_ellipse(parent, Vector2(-5, -24), 4.5, 3.5, WOOD_LIGHT)
			_ellipse(parent, Vector2(1, -9), 8.5, 5.5, PINK)
			_poly(parent, PackedVector2Array([Vector2(-5, -5), Vector2(-3, -5), Vector2(-3, 1), Vector2(-5, 1)]), WOOD_DARK)
			_poly(parent, PackedVector2Array([Vector2(5, -5), Vector2(7, -5), Vector2(7, 1), Vector2(5, 1)]), WOOD_DARK)
		ContentIds.PLACEABLE_GARDEN_ARCH:
			_poly(parent, PackedVector2Array([Vector2(-15, 0), Vector2(-11, 0), Vector2(-11, -30), Vector2(-15, -30)]), WOOD)
			_poly(parent, PackedVector2Array([Vector2(11, 0), Vector2(15, 0), Vector2(15, -30), Vector2(11, -30)]), WOOD)
			_poly(parent, TerrainShapes.dome(Vector2(0, -30), 16.0, 10.0, 10), LEAF)
			_ellipse(parent, Vector2(-8, -34), 2.4, 2.4, PINK, 8)
			_ellipse(parent, Vector2(6, -36), 2.4, 2.4, Color("#cdb4dd"), 8)
		ContentIds.PLACEABLE_PICNIC_BLANKET:
			_poly(parent, PackedVector2Array([Vector2(0, -12), Vector2(22, 0), Vector2(0, 12), Vector2(-22, 0)]), CREAM)
			_poly(parent, PackedVector2Array([Vector2(0, -8), Vector2(14, 0), Vector2(0, 8), Vector2(-14, 0)]), PINK)
			_poly(parent, PackedVector2Array([Vector2(0, -4), Vector2(7, 0), Vector2(0, 4), Vector2(-7, 0)]), CREAM)
		ContentIds.PLACEABLE_BIRDHOUSE:
			_poly(parent, PackedVector2Array([Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(1.5, -22), Vector2(-1.5, -22)]), WOOD_DARK)
			_poly(parent, PackedVector2Array([Vector2(-8, -22), Vector2(8, -22), Vector2(8, -36), Vector2(-8, -36)]), WOOD_LIGHT)
			_poly(parent, TerrainShapes.dome(Vector2(0, -36), 10.0, 7.0, 8), PINK)
			_ellipse(parent, Vector2(0, -29), 2.6, 2.6, WOOD_DARK, 8)
		ContentIds.PLACEABLE_FENCE_SEGMENT:
			for px: float in [-14.0, 14.0]:
				_poly(parent, PackedVector2Array([Vector2(px - 2, 0), Vector2(px + 2, 0), Vector2(px + 2, -16), Vector2(px - 2, -16)]), WOOD)
				_ellipse(parent, Vector2(px, -16), 3.0, 2.2, WOOD_LIGHT, 8)
			_poly(parent, PackedVector2Array([Vector2(-16, -12), Vector2(16, -12), Vector2(16, -9), Vector2(-16, -9)]), WOOD_LIGHT)
			_poly(parent, PackedVector2Array([Vector2(-16, -5), Vector2(16, -5), Vector2(16, -2), Vector2(-16, -2)]), WOOD_LIGHT)
		ContentIds.PLACEABLE_PATH_LANTERN:
			_ellipse(parent, Vector2(0, -2), 7.0, 4.0, STONE)
			_poly(parent, PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, -16), Vector2(-2, -16)]), STONE)
			_ellipse(parent, Vector2(0, -20), 6.0, 5.5, Color(0.99, 0.9, 0.61, 0.95))
			_ellipse(parent, Vector2(0, -20), 11.0, 9.0, Color(0.98, 0.89, 0.57, 0.2))
			_poly(parent, TerrainShapes.dome(Vector2(0, -24), 7.0, 4.0, 8), STONE)
		ContentIds.PLACEABLE_BERRY_BASKET:
			_poly(parent, PackedVector2Array([Vector2(-11, -12), Vector2(11, -12), Vector2(9, 0), Vector2(-9, 0)]), WOOD)
			_poly(parent, PackedVector2Array([Vector2(-12, -14), Vector2(12, -14), Vector2(11, -10), Vector2(-11, -10)]), WOOD_DARK)
			for berry_data in [Vector2(-5, -15), Vector2(0, -17), Vector2(5, -15)]:
				_ellipse(parent, berry_data, 3.4, 3.4, Color("#d87fa0"), 8)
		ContentIds.PLACEABLE_WOOD_PILE:
			for log_data in [Vector2(-8, -4), Vector2(0, -4), Vector2(8, -4), Vector2(-4, -11), Vector2(4, -11)]:
				_ellipse(parent, log_data, 5.0, 4.2, WOOD, 10)
				_ellipse(parent, log_data, 2.6, 2.2, WOOD_LIGHT, 8)
		ContentIds.PLACEABLE_SIGNPOST:
			_poly(parent, PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(2, -26), Vector2(-2, -26)]), WOOD_DARK)
			_poly(parent, PackedVector2Array([Vector2(-14, -26), Vector2(12, -26), Vector2(16, -21), Vector2(12, -16), Vector2(-14, -16)]), WOOD_LIGHT)
			_poly(parent, PackedVector2Array([Vector2(-10, -23), Vector2(6, -23), Vector2(6, -21.5), Vector2(-10, -21.5)]), WOOD_DARK)
			_poly(parent, PackedVector2Array([Vector2(-10, -19.5), Vector2(2, -19.5), Vector2(2, -18), Vector2(-10, -18)]), WOOD_DARK)
		ContentIds.PLACEABLE_DECOR_SHRUB:
			_ellipse(parent, Vector2(0, -10), 12.0, 11.0, LEAF)
			_ellipse(parent, Vector2(-3, -14), 6.0, 4.5, LEAF_LIGHT)
			_ellipse(parent, Vector2(5, -7), 2.0, 2.0, PINK, 8)
		ContentIds.PLACEABLE_TEA_TABLE:
			_poly(parent, PackedVector2Array([Vector2(-2, -4), Vector2(2, -4), Vector2(2.5, 0), Vector2(-2.5, 0)]), WOOD_DARK)
			_ellipse(parent, Vector2(0, -12), 13.0, 7.5, WOOD_LIGHT)
			_ellipse(parent, Vector2(-4, -14), 3.2, 2.4, CREAM, 8)
			_ellipse(parent, Vector2(4, -13), 2.6, 2.0, PINK, 8)
		ContentIds.PLACEABLE_BENCH:
			_poly(parent, PackedVector2Array([Vector2(-16, -10), Vector2(16, -10), Vector2(16, -6), Vector2(-16, -6)]), WOOD_LIGHT)
			_poly(parent, PackedVector2Array([Vector2(-16, -18), Vector2(16, -18), Vector2(16, -15), Vector2(-16, -15)]), WOOD)
			for px: float in [-12.0, 12.0]:
				_poly(parent, PackedVector2Array([Vector2(px - 2, -6), Vector2(px + 2, -6), Vector2(px + 2, 1), Vector2(px - 2, 1)]), WOOD_DARK)
		ContentIds.PLACEABLE_FLOWER_BED:
			_poly(parent, PackedVector2Array([Vector2(0, -12), Vector2(20, 0), Vector2(0, 12), Vector2(-20, 0)]), Color("#6f4c2c"))
			_poly(parent, PackedVector2Array([Vector2(0, -9), Vector2(16, 0), Vector2(0, 9), Vector2(-16, 0)]), Color("#8a5e3c"))
			for flower_data in [
				[Vector2(-7, -1), PINK], [Vector2(0, -4), Color("#f2d469")],
				[Vector2(7, -1), Color("#cdb4dd")], [Vector2(0, 3), CREAM],
			]:
				_ellipse(parent, flower_data[0], 2.6, 2.6, flower_data[1], 8)
		ContentIds.PLACEABLE_TINY_POND:
			_ellipse(parent, Vector2(0, 0), 19.0, 11.0, STONE)
			_ellipse(parent, Vector2(0, 0), 15.0, 8.0, Color("#7db5cf"))
			_ellipse(parent, Vector2(-4, -2), 4.0, 1.8, Color(0.92, 0.97, 1.0, 0.7), 8)
			_ellipse(parent, Vector2(7, 2), 3.0, 2.2, LEAF_LIGHT, 8)
		ContentIds.PLACEABLE_WORKBENCH:
			# Sturdy work table with a saw cut, a hammer, and a vice block.
			for px: float in [-13.0, 13.0]:
				_poly(parent, PackedVector2Array([Vector2(px - 2, -4), Vector2(px + 2, -4), Vector2(px + 2, 2), Vector2(px - 2, 2)]), WOOD_DARK)
			_poly(parent, PackedVector2Array([Vector2(-17, -16), Vector2(17, -16), Vector2(18, -10), Vector2(-18, -10)]), WOOD)
			_poly(parent, PackedVector2Array([Vector2(-17, -17), Vector2(17, -17), Vector2(17, -15), Vector2(-17, -15)]), WOOD_LIGHT)
			_poly(parent, PackedVector2Array([Vector2(-8, -19), Vector2(-5, -19), Vector2(-5, -16), Vector2(-8, -16)]), STONE)
			_poly(parent, PackedVector2Array([Vector2(4, -22), Vector2(6, -22), Vector2(6, -16), Vector2(4, -16)]), WOOD_DARK)
			_ellipse(parent, Vector2(5, -23), 3.0, 2.0, STONE, 8)
		ContentIds.PLACEABLE_GARDEN_TABLE:
			# Potting table: soil tray, a little pot, and a hanging towel.
			for px: float in [-12.0, 12.0]:
				_poly(parent, PackedVector2Array([Vector2(px - 2, -4), Vector2(px + 2, -4), Vector2(px + 2, 2), Vector2(px - 2, 2)]), WOOD_DARK)
			_poly(parent, PackedVector2Array([Vector2(-16, -15), Vector2(16, -15), Vector2(17, -9), Vector2(-17, -9)]), WOOD_LIGHT)
			_poly(parent, PackedVector2Array([Vector2(-13, -18), Vector2(-2, -18), Vector2(-2, -14), Vector2(-13, -14)]), Color("#8a5e3c"))
			_ellipse(parent, Vector2(8, -18), 4.0, 3.0, Color("#c87858"), 10)
			_ellipse(parent, Vector2(8, -21), 3.0, 2.2, LEAF, 8)
			_poly(parent, PackedVector2Array([Vector2(12, -14), Vector2(16, -14), Vector2(16, -6), Vector2(12, -6)]), PINK)
		# --- Structure shells (exterior-only; door sign reads "soon") ----------
		ContentIds.PLACEABLE_COTTAGE_SHELL:
			_shell(parent, CREAM, Color("#c97a6a"), true)
		ContentIds.PLACEABLE_STORAGE_SHED:
			_shell(parent, WOOD, WOOD_DARK, false)
		ContentIds.PLACEABLE_WORKSHOP_HUT:
			_shell(parent, WOOD_LIGHT, Color("#8a8e9c"), false)
			_ellipse(parent, Vector2(24, -28), 4.0, 4.0, STONE, 8)
		ContentIds.PLACEABLE_BARN_SHELL:
			_shell(parent, Color("#c0625a"), Color("#8a4a44"), true)
			_poly(parent, PackedVector2Array([Vector2(-10, -26), Vector2(10, -26), Vector2(10, -24), Vector2(-10, -24)]), CREAM)
		ContentIds.PLACEABLE_GREENHOUSE_SHELL:
			_shell(parent, Color(0.75, 0.88, 0.92, 0.85), Color("#9cc47e"), false)
		ContentIds.PLACEABLE_WELL:
			_ellipse(parent, Vector2(0, -2), 14.0, 8.0, STONE)
			_ellipse(parent, Vector2(0, -3), 9.0, 5.0, Color("#7db5cf"))
			for px: float in [-10.0, 10.0]:
				_poly(parent, PackedVector2Array([Vector2(px - 1.5, -4), Vector2(px + 1.5, -4), Vector2(px + 1.5, -26), Vector2(px - 1.5, -26)]), WOOD_DARK)
			_poly(parent, TerrainShapes.dome(Vector2(0, -26), 14.0, 7.0, 10), Color("#c97a6a"))
		# --- Modular pieces ------------------------------------------------------
		ContentIds.PLACEABLE_WOOD_WALL:
			_poly(parent, PackedVector2Array([Vector2(-16, -2), Vector2(16, -2), Vector2(16, -30), Vector2(-16, -30)]), WOOD)
			for line_y: float in [-21.0, -12.0]:
				_poly(parent, PackedVector2Array([Vector2(-16, line_y), Vector2(16, line_y), Vector2(16, line_y + 1.5), Vector2(-16, line_y + 1.5)]), WOOD_DARK)
		ContentIds.PLACEABLE_WOOD_DOOR_WALL:
			_poly(parent, PackedVector2Array([Vector2(-16, -2), Vector2(16, -2), Vector2(16, -30), Vector2(-16, -30)]), WOOD)
			var door_points: PackedVector2Array = TerrainShapes.dome(Vector2(0, -14), 7.0, 8.0)
			door_points.append(Vector2(7, -2))
			door_points.append(Vector2(-7, -2))
			_poly(parent, door_points, WOOD_DARK)
			_ellipse(parent, Vector2(3.5, -10), 1.2, 1.2, Color("#d4a84a"), 8)
		ContentIds.PLACEABLE_STONE_WALL:
			_poly(parent, PackedVector2Array([Vector2(-16, -2), Vector2(16, -2), Vector2(16, -28), Vector2(-16, -28)]), STONE)
			for stone_data in [Vector2(-9, -22), Vector2(5, -18), Vector2(-3, -9), Vector2(10, -8)]:
				_ellipse(parent, stone_data, 4.5, 3.0, Color("#bab6ad"), 8)
		ContentIds.PLACEABLE_FLOOR_DECK:
			_poly(parent, PackedVector2Array([Vector2(0, -14), Vector2(26, 0), Vector2(0, 14), Vector2(-26, 0)]), WOOD_LIGHT)
			_poly(parent, PackedVector2Array([Vector2(-13, -7), Vector2(13, 7), Vector2(11, 8.5), Vector2(-15, -5.5)]), WOOD)
		ContentIds.PLACEABLE_STONE_FOUNDATION:
			_poly(parent, PackedVector2Array([Vector2(0, -14), Vector2(26, 0), Vector2(0, 14), Vector2(-26, 0)]), STONE)
			_poly(parent, PackedVector2Array([Vector2(0, -10), Vector2(19, 0), Vector2(0, 10), Vector2(-19, 0)]), Color("#bab6ad"))
		ContentIds.PLACEABLE_WOODEN_PILLAR:
			_poly(parent, PackedVector2Array([Vector2(-3.5, 0), Vector2(3.5, 0), Vector2(3.5, -34), Vector2(-3.5, -34)]), WOOD)
			_ellipse(parent, Vector2(0, -35), 6.0, 2.5, WOOD_LIGHT, 8)
			_ellipse(parent, Vector2(0, 0), 6.5, 3.0, WOOD_DARK, 8)
		# --- Terrain overlays (flat iso diamonds, drawn under props) -------------
		ContentIds.PLACEABLE_DIRT_PATH:
			_terrain_tile(parent, Color("#b08a5e"), Color("#9c764e"))
		ContentIds.PLACEABLE_STONE_PATH:
			_terrain_tile(parent, Color("#a8a49c"), Color("#948f86"))
		ContentIds.PLACEABLE_GRASS_PATCH:
			_terrain_tile(parent, Color("#80ad68"), Color("#6c9954"))
		ContentIds.PLACEABLE_FLOWER_MEADOW:
			_terrain_tile(parent, Color("#80ad68"), Color("#6c9954"))
			for flower_data in [[Vector2(-8, 0), PINK], [Vector2(2, -4), Color("#f2d469")], [Vector2(8, 3), Color("#cdb4dd")]]:
				_ellipse(parent, flower_data[0], 2.2, 2.2, flower_data[1], 8)
		ContentIds.PLACEABLE_PLAZA_TILE:
			_terrain_tile(parent, Color("#cdbb93"), Color("#b5a47e"))
		ContentIds.PLACEABLE_FOREST_FLOOR:
			_terrain_tile(parent, Color("#5d7a4c"), Color("#4e6940"))
			_ellipse(parent, Vector2(5, 1), 3.0, 1.6, Color("#8cba74"), 8)
		_:
			# Unknown id: visible placeholder so a registry mistake is obvious.
			_ellipse(parent, Vector2(0, -8), 10.0, 10.0, Color("#c25448"))

## Generic 2x2 structure shell, centered on the footprint midpoint (world
## offset (0, 16) from the origin tile): wall slab, domed roof, shut door with
## a tiny "interior coming soon" sign plate. Exterior only — never enterable.
static func _shell(parent: Node2D, wall: Color, roof: Color, has_chimney: bool) -> void:
	_ellipse(parent, Vector2(0, 32), 56.0, 18.0, Color(0.16, 0.12, 0.08, 0.18))
	_poly(parent, PackedVector2Array([
		Vector2(-46, 30), Vector2(46, 30), Vector2(52, 22), Vector2(52, -12),
		Vector2(-52, -12), Vector2(-52, 22),
	]), wall)
	_poly(parent, TerrainShapes.dome(Vector2(0, -12), 58.0, 34.0, 14), roof)
	_poly(parent, PackedVector2Array([Vector2(-56, -14), Vector2(56, -14), Vector2(52, -8), Vector2(-52, -8)]), Color("#e8cfa8"))
	if has_chimney:
		_poly(parent, PackedVector2Array([Vector2(26, -50), Vector2(36, -50), Vector2(36, -28), Vector2(26, -31)]), Color("#c99181"))
	var shell_door: PackedVector2Array = TerrainShapes.dome(Vector2(0, 18), 8.0, 9.0)
	shell_door.append(Vector2(8, 30))
	shell_door.append(Vector2(-8, 30))
	_poly(parent, shell_door, WOOD_DARK)
	_poly(parent, PackedVector2Array([Vector2(-6, 12), Vector2(6, 12), Vector2(6, 16), Vector2(-6, 16)]), CREAM)

static func _terrain_tile(parent: Node2D, base: Color, edge: Color) -> void:
	_poly(parent, PackedVector2Array([Vector2(0, -16), Vector2(30, 0), Vector2(0, 16), Vector2(-30, 0)]), edge)
	_poly(parent, PackedVector2Array([Vector2(0, -13), Vector2(26, 0), Vector2(0, 13), Vector2(-26, 0)]), base)
