extends Node2D
class_name ResourceNode

## A gatherable spot in the world: a wood pile, a stone outcrop, a fiber bush,
## or a clay pit. Visual + yield data; the area controller registers the
## interaction and adds the materials to the inventory. Nodes regenerate on a
## short cooldown (dimmed while recovering) instead of depleting — cozy, never
## punishing. Offline the cooldown is local; connected, the server enforces its
## own per-node cooldown and this one just mirrors it visually.

# Hand tier (no tool — the soft-lock-safe starter sources).
const TYPE_WOOD := "wood_source"        # fallen branches
const TYPE_STONE := "stone_source"      # loose pebbles
const TYPE_FIBER := "fiber_source"      # wild fiber bush
const TYPE_CLAY := "clay_source"        # soft clay patch
# Tool tier (better yields, requires a starter tool).
const TYPE_TREE := "tree_source"        # chop with axe
const TYPE_BOULDER := "boulder_source"  # mine with pickaxe
const TYPE_CLAY_DEPOSIT := "clay_deposit_source"  # dig with shovel

var resource_type: String = TYPE_WOOD
var cooldown_seconds: float = ResourceSpawnRegistry.COOLDOWN_SECONDS
var _ready_at_msec: int = 0

static func definitions() -> Dictionary:
	return {
		TYPE_WOOD: {"material_id": ResourceIds.MATERIAL_WOOD, "min": 1, "max": 2, "prompt": "Press F to gather fallen branches", "verb": "gather", "required_tool": ""},
		TYPE_STONE: {"material_id": ResourceIds.MATERIAL_STONE, "min": 1, "max": 2, "prompt": "Press F to gather pebbles", "verb": "pick up", "required_tool": ""},
		TYPE_FIBER: {"material_id": ResourceIds.MATERIAL_FIBER, "min": 1, "max": 3, "prompt": "Press F to gather fiber", "verb": "snip", "required_tool": ""},
		TYPE_CLAY: {"material_id": ResourceIds.MATERIAL_CLAY, "min": 1, "max": 2, "prompt": "Press F to scoop soft clay", "verb": "scoop", "required_tool": ""},
		TYPE_TREE: {"material_id": ResourceIds.MATERIAL_WOOD, "min": 2, "max": 4, "prompt": "Press F to chop tree", "verb": "chop", "required_tool": ItemIds.TOOL_WORN_AXE},
		TYPE_BOULDER: {"material_id": ResourceIds.MATERIAL_STONE, "min": 2, "max": 4, "prompt": "Press F to mine boulder", "verb": "mine", "required_tool": ItemIds.TOOL_WORN_PICKAXE},
		TYPE_CLAY_DEPOSIT: {"material_id": ResourceIds.MATERIAL_CLAY, "min": 2, "max": 3, "prompt": "Press F to dig clay deposit", "verb": "dig", "required_tool": ItemIds.TOOL_BASIC_SHOVEL},
	}

func get_required_tool() -> String:
	return String(get_definition().get("required_tool", ""))

func configure(target_type: String) -> void:
	resource_type = target_type
	_build_visual()

func get_definition() -> Dictionary:
	return definitions().get(resource_type, definitions()[TYPE_WOOD]) as Dictionary

func get_prompt() -> String:
	return String(get_definition().get("prompt", "Press F to gather"))

func is_ready() -> bool:
	return Time.get_ticks_msec() >= _ready_at_msec

func remaining_seconds() -> int:
	return maxi(0, int(ceilf(float(_ready_at_msec - Time.get_ticks_msec()) / 1000.0)))

## Dim the node and start the regeneration window. Visual only — gameplay
## validity is checked via is_ready() (offline) or by the server (connected).
func start_cooldown() -> void:
	_ready_at_msec = Time.get_ticks_msec() + int(cooldown_seconds * 1000.0)
	modulate = Color(1.0, 1.0, 1.0, 0.45)
	var timer: SceneTreeTimer = get_tree().create_timer(cooldown_seconds)
	timer.timeout.connect(_on_cooldown_finished)

func _on_cooldown_finished() -> void:
	if is_instance_valid(self):
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func roll_yield(rng: RandomNumberGenerator) -> Dictionary:
	var definition: Dictionary = get_definition()
	return {
		"material_id": String(definition.get("material_id", ResourceIds.MATERIAL_WOOD)),
		"amount": rng.randi_range(int(definition.get("min", 1)), int(definition.get("max", 2))),
		"verb": String(definition.get("verb", "gather")),
	}

func _build_visual() -> void:
	# LimeZu live mode: gather spots use a LimeZu sprite (kept visible + interactable)
	# instead of the procedural pile, so the opening view has no generated/procedural art.
	if LiveVisualPolicy.live_limezu_slice():
		_build_limezu_visual()
		return
	var shadow: Polygon2D = Polygon2D.new()
	shadow.polygon = TerrainShapes.ellipse(Vector2(0, 1), 15.0, 6.0)
	shadow.color = Color(0.16, 0.12, 0.08, 0.2)
	add_child(shadow)
	match resource_type:
		TYPE_STONE:
			TerrainShapes.add_ellipse(self, Vector2(-4, -4), 10.0, 7.5, Color("#a8a49c"))
			TerrainShapes.add_ellipse(self, Vector2(7, -2), 7.0, 5.0, Color("#bab6ad"))
			TerrainShapes.add_ellipse(self, Vector2(-6, -8), 4.0, 2.5, Color("#cdc9bf"), 10)
		TYPE_FIBER:
			TerrainShapes.add_ellipse(self, Vector2(0, -7), 13.0, 9.5, Color("#7da964"))
			TerrainShapes.add_ellipse(self, Vector2(-4, -10), 6.0, 4.0, Color("#9cc47e"))
			for tuft_x: float in [-8.0, 0.0, 8.0]:
				TerrainShapes.add_polygon(self, PackedVector2Array([
					Vector2(tuft_x - 1, -12), Vector2(tuft_x + 1, -12), Vector2(tuft_x, -19),
				]), Color("#8cba74"))
		TYPE_CLAY:
			TerrainShapes.add_ellipse(self, Vector2(0, -1), 14.0, 7.5, Color("#b07a5a"))
			TerrainShapes.add_ellipse(self, Vector2(0, -2), 9.0, 4.5, Color("#c08a64"))
			TerrainShapes.add_ellipse(self, Vector2(3, -3), 4.0, 2.0, Color("#9c6a4c"), 10)
		TYPE_TREE:
			# A sturdy chopping tree: thick trunk, full canopy, an axe notch.
			TerrainShapes.add_polygon(self, PackedVector2Array([
				Vector2(-6, 0), Vector2(6, 0), Vector2(8, -26), Vector2(-8, -26),
			]), Color("#8a5e3c"))
			TerrainShapes.add_ellipse(self, Vector2(0, -40), 22.0, 17.0, Color("#5f8c56"))
			TerrainShapes.add_ellipse(self, Vector2(-8, -46), 11.0, 8.0, Color("#8cba74"))
			TerrainShapes.add_polygon(self, PackedVector2Array([
				Vector2(4, -10), Vector2(9, -13), Vector2(9, -7),
			]), Color("#e0bf8a"))
		TYPE_BOULDER:
			TerrainShapes.add_ellipse(self, Vector2(0, -6), 16.0, 12.0, Color("#9a968e"))
			TerrainShapes.add_ellipse(self, Vector2(-5, -10), 7.0, 4.5, Color("#bab6ad"))
			TerrainShapes.add_ellipse(self, Vector2(6, -3), 5.0, 3.5, Color("#857f76"), 10)
			TerrainShapes.add_ellipse(self, Vector2(3, -13), 4.0, 2.0, Color("#7da964"), 8)
		TYPE_CLAY_DEPOSIT:
			TerrainShapes.add_ellipse(self, Vector2(0, -3), 17.0, 9.0, Color("#a06a48"))
			TerrainShapes.add_ellipse(self, Vector2(-4, -6), 8.0, 4.0, Color("#b07a5a"))
			TerrainShapes.add_ellipse(self, Vector2(6, -2), 6.0, 3.0, Color("#8a5a3c"), 10)
		_:
			for log_data in [Vector2(-7, -4), Vector2(1, -4), Vector2(9, -4), Vector2(-3, -10), Vector2(5, -10)]:
				TerrainShapes.add_ellipse(self, log_data, 5.0, 4.2, Color("#c89a64"), 10)
				TerrainShapes.add_ellipse(self, log_data, 2.6, 2.2, Color("#e0bf8a"), 8)

## LimeZu gather-spot visual: a small tree for wood/tree/fiber, a flower cluster for
## stone/clay (no LimeZu rock yet). Bottom-anchored at the node origin, y-sorted.
func _build_limezu_visual() -> void:
	var logical_id: String = "object.tree_small"
	if resource_type in [TYPE_STONE, TYPE_BOULDER, TYPE_CLAY, TYPE_CLAY_DEPOSIT]:
		logical_id = "object.flower"
	if not LimeZuArtRegistry.has_asset(logical_id):
		return
	var source_path: String = LimeZuArtRegistry.texture_path(logical_id)
	var tex: Texture2D = LimeZuArtRegistry.resolve_texture(logical_id)
	if tex == null:
		return
	var sc: float = LiveVisualPolicy.LIMEZU_DISPLAY_SCALE
	var s := Sprite2D.new()
	s.name = "ResourceLimeZu_%s" % logical_id.replace(".", "_")
	s.texture = tex
	s.centered = false
	s.position = Vector2(-tex.get_width() * sc * 0.5, -tex.get_height() * sc)
	s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.set_meta("limezu_logical_id", logical_id)
	s.set_meta("visual_source_path", source_path)
	add_child(s)
