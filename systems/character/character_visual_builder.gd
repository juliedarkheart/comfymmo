extends RefCounted
class_name CharacterVisualBuilder

## Builds a cozy chibi character out of Polygon2D children from an appearance
## dictionary (see CharacterAppearance). Shared by the player avatar and the
## villagers so every person in Hearthvale speaks the same visual language:
## big round head, small soft body, dot eyes with a sparkle, blush, and chunky
## readable hair/outfit silhouettes. Origin is at the feet (y = 0), facing the
## camera; callers flip the parent's scale.x for left/right facing.

const OUTLINE_DARKEN := 0.25

## Smooth ellipse polygon — the core anti-blocky primitive.
static func ellipse(center: Vector2, rx: float, ry: float, segments: int = 16) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var a: float = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func _add_poly(parent: Node2D, points: PackedVector2Array, color: Color, name_hint: String = "") -> Polygon2D:
	var node: Polygon2D = Polygon2D.new()
	if not name_hint.is_empty():
		node.name = name_hint
	node.polygon = points
	node.color = color
	parent.add_child(node)
	return node

static func _add_ellipse(parent: Node2D, center: Vector2, rx: float, ry: float, color: Color, name_hint: String = "") -> Polygon2D:
	return _add_poly(parent, ellipse(center, rx, ry), color, name_hint)

static func build(parent: Node2D, appearance: Dictionary) -> void:
	var look: Dictionary = CharacterAppearance.normalized(appearance)
	var skin: Color = CharacterAppearanceRegistry.skin_value(String(look["skin_tone"]))
	var hair: Color = CharacterAppearanceRegistry.color_value(String(look["hair_color"]))
	var outfit: Color = CharacterAppearanceRegistry.color_value(String(look["outfit_color"]))

	_build_feet(parent, outfit)
	_build_hair_back(parent, String(look["hair_style"]), hair)
	_build_body(parent, String(look["outfit_style"]), outfit, skin)
	_build_head(parent, skin)
	_build_hair_front(parent, String(look["hair_style"]), hair)
	_build_face(parent, String(look["face_style"]))
	_build_accessory(parent, String(look["accessory"]))

static func _build_feet(parent: Node2D, outfit: Color) -> void:
	var boot: Color = outfit.darkened(OUTLINE_DARKEN)
	_add_ellipse(parent, Vector2(-6, -2), 5.0, 3.5, boot, "FootLeft")
	_add_ellipse(parent, Vector2(6, -2), 5.0, 3.5, boot, "FootRight")

static func _build_body(parent: Node2D, outfit_style: String, outfit: Color, skin: Color) -> void:
	var trim: Color = outfit.darkened(OUTLINE_DARKEN)
	var cream: Color = CharacterAppearanceRegistry.color_value("cream")

	match outfit_style:
		"village_dress":
			# Swishy A-line dress with a cream collar and hem trim.
			_add_poly(parent, PackedVector2Array([
				Vector2(0, -28), Vector2(9, -25), Vector2(13, -14), Vector2(17, -2),
				Vector2(9, 1), Vector2(0, 2), Vector2(-9, 1), Vector2(-17, -2),
				Vector2(-13, -14), Vector2(-9, -25),
			]), outfit, "Torso")
			_add_poly(parent, PackedVector2Array([
				Vector2(-16, -3), Vector2(16, -3), Vector2(15, 0), Vector2(-15, 0),
			]), cream, "HemTrim")
			_add_ellipse(parent, Vector2(0, -26), 4.5, 2.5, cream, "Collar")
		"mushroom_sweater":
			# Chunky sweater with a little mushroom motif on the front.
			_add_ellipse(parent, Vector2(0, -15), 14.0, 13.0, outfit, "Torso")
			_add_poly(parent, PackedVector2Array([
				Vector2(-13, -7), Vector2(13, -7), Vector2(12, -4), Vector2(-12, -4),
			]), trim, "SweaterBand")
			_add_poly(parent, TerrainShapes.dome(Vector2(0, -15), 4.0, 3.2, 8), CharacterAppearanceRegistry.color_value("terracotta"), "MushroomCap")
			_add_poly(parent, PackedVector2Array([
				Vector2(-1.4, -15), Vector2(1.4, -15), Vector2(1.4, -11), Vector2(-1.4, -11),
			]), cream, "MushroomStem")
		"gardener_jacket":
			# Sturdy open jacket over a cream shirt, with patch pockets.
			_add_ellipse(parent, Vector2(0, -15), 12.0, 12.0, cream, "Torso")
			_add_poly(parent, PackedVector2Array([
				Vector2(-13, -26), Vector2(-5, -24), Vector2(-4, 0), Vector2(-13, -3),
			]), outfit, "JacketLeft")
			_add_poly(parent, PackedVector2Array([
				Vector2(5, -24), Vector2(13, -26), Vector2(13, -3), Vector2(4, 0),
			]), outfit, "JacketRight")
			_add_ellipse(parent, Vector2(-8, -8), 2.6, 2.6, trim, "PocketLeft")
			_add_ellipse(parent, Vector2(8, -8), 2.6, 2.6, trim, "PocketRight")
		"cozy_tunic":
			# Soft A-line tunic: rounded torso flaring to a little skirt.
			_add_poly(parent, PackedVector2Array([
				Vector2(0, -28), Vector2(10, -25), Vector2(14, -14), Vector2(15, -4),
				Vector2(8, 0), Vector2(0, 1), Vector2(-8, 0), Vector2(-15, -4),
				Vector2(-14, -14), Vector2(-10, -25),
			]), outfit, "Torso")
			_add_poly(parent, PackedVector2Array([
				Vector2(-12, -12), Vector2(12, -12), Vector2(13, -9), Vector2(-13, -9),
			]), trim, "Belt")
		"forest_apron":
			# Warm base clothes with a big friendly apron front.
			_add_ellipse(parent, Vector2(0, -14), 13.0, 13.0, CharacterAppearanceRegistry.color_value("warm_brown"), "Torso")
			_add_poly(parent, PackedVector2Array([
				Vector2(-9, -22), Vector2(9, -22), Vector2(11, -4), Vector2(0, 0), Vector2(-11, -4),
			]), outfit, "ApronFront")
			_add_ellipse(parent, Vector2(0, -10), 4.0, 3.0, trim, "ApronPocket")
		_:
			# starter_overalls: cream shirt with a chunky overall bib + straps.
			_add_ellipse(parent, Vector2(0, -15), 13.0, 12.0, cream, "Torso")
			_add_poly(parent, PackedVector2Array([
				Vector2(-9, -18), Vector2(9, -18), Vector2(12, -4), Vector2(0, 0), Vector2(-12, -4),
			]), outfit, "OverallBib")
			_add_poly(parent, PackedVector2Array([
				Vector2(-9, -18), Vector2(-6, -18), Vector2(-9, -25), Vector2(-12, -24),
			]), outfit, "StrapLeft")
			_add_poly(parent, PackedVector2Array([
				Vector2(6, -18), Vector2(9, -18), Vector2(12, -24), Vector2(9, -25),
			]), outfit, "StrapRight")
			_add_ellipse(parent, Vector2(-5, -16), 1.6, 1.6, trim, "ButtonLeft")
			_add_ellipse(parent, Vector2(5, -16), 1.6, 1.6, trim, "ButtonRight")

	# Little round mitten hands at the sides, always over the outfit.
	_add_ellipse(parent, Vector2(-13, -13), 4.0, 4.5, skin, "HandLeft")
	_add_ellipse(parent, Vector2(13, -13), 4.0, 4.5, skin, "HandRight")

static func _build_head(parent: Node2D, skin: Color) -> void:
	_add_ellipse(parent, Vector2(0, -40), 15.0, 14.0, skin, "Head")

static func _build_hair_back(parent: Node2D, hair_style: String, hair: Color) -> void:
	var back: Color = hair.darkened(0.12)
	match hair_style:
		"soft_curls":
			_add_ellipse(parent, Vector2(0, -41), 17.0, 16.0, back, "HairBack")
			for cx: float in [-15.0, -11.0, 11.0, 15.0]:
				_add_ellipse(parent, Vector2(cx, -31), 4.5, 4.5, back, "Curl")
		"fluffy_short":
			_add_ellipse(parent, Vector2(0, -44), 16.0, 13.0, back, "HairBack")
		"leafy_pigtails":
			_add_ellipse(parent, Vector2(0, -43), 15.5, 14.0, back, "HairBack")
			for px: float in [-17.0, 17.0]:
				_add_ellipse(parent, Vector2(px, -36), 5.5, 7.5, back, "Pigtail")
				_add_ellipse(parent, Vector2(px, -43), 3.0, 3.0, CharacterAppearanceRegistry.color_value("moss_green"), "PigtailLeaf")
		"cozy_bun":
			_add_ellipse(parent, Vector2(0, -42), 16.0, 15.0, back, "HairBack")
			_add_ellipse(parent, Vector2(0, -58), 7.0, 6.0, back, "Bun")
		"wavy_shag":
			_add_ellipse(parent, Vector2(0, -41), 17.5, 16.5, back, "HairBack")
			for wave_data in [Vector2(-14, -28), Vector2(-7, -25), Vector2(7, -25), Vector2(14, -28)]:
				_add_ellipse(parent, wave_data, 4.0, 5.0, back, "Wave")
		_:
			# round_bob: a soft helmet that peeks out under the jawline.
			_add_ellipse(parent, Vector2(0, -42), 16.5, 15.5, back, "HairBack")

static func _build_hair_front(parent: Node2D, hair_style: String, hair: Color) -> void:
	match hair_style:
		"soft_curls":
			for puff: Vector2 in [Vector2(-9, -52), Vector2(0, -55), Vector2(9, -52)]:
				_add_ellipse(parent, puff, 6.5, 5.5, hair, "FringePuff")
		"fluffy_short":
			for puff: Vector2 in [Vector2(-10, -50), Vector2(-3, -54), Vector2(5, -53), Vector2(11, -49)]:
				_add_ellipse(parent, puff, 6.0, 5.0, hair, "FluffPuff")
		"leafy_pigtails":
			_add_poly(parent, PackedVector2Array([
				Vector2(-14, -45), Vector2(-12, -51), Vector2(-5, -55), Vector2(3, -55),
				Vector2(11, -52), Vector2(14, -45), Vector2(7, -48), Vector2(-4, -49),
			]), hair, "SideFringe")
		"cozy_bun":
			_add_poly(parent, PackedVector2Array([
				Vector2(-15, -44), Vector2(-13, -50), Vector2(-7, -54), Vector2(0, -55),
				Vector2(7, -54), Vector2(13, -50), Vector2(15, -44),
				Vector2(8, -48), Vector2(0, -49), Vector2(-8, -48),
			]), hair, "BunFringe")
		"wavy_shag":
			for puff: Vector2 in [Vector2(-11, -50), Vector2(-4, -54), Vector2(4, -54), Vector2(11, -50)]:
				_add_ellipse(parent, puff, 5.5, 5.0, hair, "ShagPuff")
		_:
			# round_bob fringe: smooth cap over the top of the head.
			_add_poly(parent, PackedVector2Array([
				Vector2(-15, -44), Vector2(-14, -50), Vector2(-9, -54), Vector2(0, -56),
				Vector2(9, -54), Vector2(14, -50), Vector2(15, -44),
				Vector2(10, -47), Vector2(0, -48), Vector2(-10, -47),
			]), hair, "Fringe")

static func _build_face(parent: Node2D, _face_style: String) -> void:
	var eye: Color = Color("#3e2c1e")
	var blush: Color = Color(0.93, 0.64, 0.64, 0.85)
	# Big friendly dot eyes with a white sparkle.
	for ex: float in [-5.5, 5.5]:
		_add_ellipse(parent, Vector2(ex, -41), 2.4, 3.0, eye, "Eye")
		_add_ellipse(parent, Vector2(ex + 0.9, -42), 0.9, 0.9, Color(1, 1, 1, 0.95), "EyeSparkle")
	_add_ellipse(parent, Vector2(-9.5, -36), 2.8, 1.8, blush, "BlushLeft")
	_add_ellipse(parent, Vector2(9.5, -36), 2.8, 1.8, blush, "BlushRight")
	# Tiny soft smile.
	_add_poly(parent, PackedVector2Array([
		Vector2(-2.5, -34.5), Vector2(0, -33), Vector2(2.5, -34.5), Vector2(0, -32),
	]), eye, "Smile")

static func _build_accessory(parent: Node2D, accessory: String) -> void:
	match accessory:
		"leaf_clip":
			var leaf: Color = CharacterAppearanceRegistry.color_value("moss_green")
			_add_poly(parent, PackedVector2Array([
				Vector2(-15, -50), Vector2(-10, -53), Vector2(-8, -49), Vector2(-12, -47),
			]), leaf, "LeafClip")
			_add_ellipse(parent, Vector2(-11.5, -50), 1.2, 1.2, leaf.darkened(0.3), "LeafClipDot")
		"tiny_hat":
			var felt: Color = CharacterAppearanceRegistry.color_value("terracotta")
			_add_ellipse(parent, Vector2(0, -55), 11.0, 4.0, felt.darkened(0.2), "HatBrim")
			_add_ellipse(parent, Vector2(0, -60), 7.0, 5.5, felt, "HatCrown")
		"flower_pin":
			var petal: Color = CharacterAppearanceRegistry.color_value("blush_pink")
			for petal_offset in [Vector2(-2.4, 0), Vector2(2.4, 0), Vector2(0, -2.4), Vector2(0, 2.4)]:
				_add_ellipse(parent, Vector2(11, -51) + petal_offset, 2.0, 2.0, petal, "Petal")
			_add_ellipse(parent, Vector2(11, -51), 1.6, 1.6, CharacterAppearanceRegistry.color_value("butter_yellow"), "FlowerHeart")
		"round_glasses":
			var rim_color: Color = Color("#5a4030")
			for gx: float in [-5.5, 5.5]:
				_add_ellipse(parent, Vector2(gx, -41), 4.6, 4.6, rim_color, "GlassRim")
				_add_ellipse(parent, Vector2(gx, -41), 3.4, 3.4, Color(0.95, 0.97, 1.0, 0.55), "GlassLens")
			_add_poly(parent, PackedVector2Array([
				Vector2(-1.5, -42), Vector2(1.5, -42), Vector2(1.5, -40.8), Vector2(-1.5, -40.8),
			]), rim_color, "GlassBridge")
		"acorn_cap":
			var acorn: Color = CharacterAppearanceRegistry.color_value("warm_brown")
			_add_poly(parent, TerrainShapes.dome(Vector2(0, -53), 12.0, 7.0, 10), acorn, "AcornCap")
			_add_ellipse(parent, Vector2(0, -53), 12.5, 2.5, acorn.darkened(0.2), "AcornBrim")
			_add_poly(parent, PackedVector2Array([
				Vector2(-1.2, -60), Vector2(1.2, -60), Vector2(2, -65), Vector2(-0.5, -65),
			]), acorn.darkened(0.25), "AcornStem")
		_:
			pass
