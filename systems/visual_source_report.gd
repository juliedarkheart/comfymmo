extends RefCounted
class_name VisualSourceReport

## Dev-only visual source audit. Reports which art tier each registry resolves to
## in a given projection, and (optionally) what a live map scene actually spawned,
## so a human can tell at a glance whether the world is rendering licensed Sprout /
## licensed_modified Sprout / generated Hearthvale top-down / legacy / missing art.
## Console-only (printed once on startup); never spams the HUD. The overworld
## controller prints it on boot; tools/validate_project.gd calls the registry part.

## Per-registry tier counts for `mode`, plus any required id that still resolves to
## LEGACY old art (res://art/tiles/ diamonds or res://art/objects/ placeholders)
## while in a sprout-compatible (live) projection — those are the regressions.
static func registry_summary(mode: String = WorldProjection.DEFAULT_MODE) -> Dictionary:
	var live: bool = WorldProjection.is_sprout_compatible(mode)
	var terrain: Dictionary = {}
	var terrain_legacy: Array[String] = []
	for id_variant in TerrainArtRegistry.required_ids():
		var id: String = String(id_variant)
		var path: String = TerrainArtRegistry.texture_path(id, mode)
		var src: String = TerrainArtRegistry.source_of(path)
		terrain[src] = int(terrain.get(src, 0)) + 1
		if live and src == "generated" and path.begins_with(TerrainArtRegistry.LEGACY_TILE_ROOT):
			terrain_legacy.append(id)
	var objects: Dictionary = {}
	var object_legacy: Array[String] = []
	for id_variant in ObjectArtRegistry.required_ids():
		var id: String = String(id_variant)
		var path: String = ObjectArtRegistry.texture_path(id)
		var src: String = ObjectArtRegistry.source_of(path)
		objects[src] = int(objects.get(src, 0)) + 1
		if path.begins_with(ObjectArtRegistry.LEGACY_OBJECT_ROOT) or path.begins_with(ObjectArtRegistry.LEGACY_TILE_ROOT):
			object_legacy.append(id)
	var ui: Dictionary = {}
	for id_variant in UIArtRegistry.required_ids():
		var path: String = UIArtRegistry.texture_path(String(id_variant))
		var src: String = UIArtRegistry.source_of(path)
		ui[src] = int(ui.get(src, 0)) + 1
	return {
		"mode": mode,
		"terrain": terrain,
		"terrain_legacy_in_live": terrain_legacy,
		"objects": objects,
		"object_legacy_in_live": object_legacy,
		"ui": ui,
	}

## True when the registries resolve NO legacy old art in the live projection.
static func is_clean(mode: String = WorldProjection.DEFAULT_MODE) -> bool:
	var summary: Dictionary = registry_summary(mode)
	return (summary["terrain_legacy_in_live"] as Array).is_empty() \
		and (summary["object_legacy_in_live"] as Array).is_empty()

## What a live map scene actually spawned: counts of registry sprites vs raw
## procedural Polygon2D nodes, and any sprite still using a legacy texture.
static func scene_summary(map: Node) -> Dictionary:
	var terrain_sprites: int = 0
	var object_sprites: int = 0
	var legacy_textures: Array[String] = []
	if map != null:
		for node in map.find_children("*", "Sprite2D", true, false):
			var sprite: Sprite2D = node as Sprite2D
			var path: String = sprite.texture.resource_path if sprite.texture != null else ""
			if String(sprite.name).begins_with("TerrainArt"):
				terrain_sprites += 1
			else:
				object_sprites += 1
			if path.begins_with("res://art/tiles/") or path.begins_with("res://art/objects/"):
				legacy_textures.append(path)
	var polygons: int = map.find_children("*", "Polygon2D", true, false).size() if map != null else 0
	return {
		"terrain_sprites": terrain_sprites,
		"object_sprites": object_sprites,
		"polygon_nodes": polygons,
		"legacy_textures": legacy_textures,
	}

static func print_report(map: Node = null, mode: String = WorldProjection.DEFAULT_MODE) -> void:
	var r: Dictionary = registry_summary(mode)
	print("[visual-source] projection=", r["mode"], " (legacy iso is fallback only)")
	print("[visual-source] terrain tiers=", r["terrain"], " legacy_in_live=", r["terrain_legacy_in_live"])
	print("[visual-source] object tiers=", r["objects"], " legacy_in_live=", r["object_legacy_in_live"])
	print("[visual-source] ui tiers=", r["ui"])
	if not is_clean(mode):
		push_warning("[visual-source] LIVE sprout_topdown is resolving LEGACY old art for some ids (see lists)")
	if map != null:
		var s: Dictionary = scene_summary(map)
		print("[visual-source] live scene: terrain_sprites=", s["terrain_sprites"],
			" object_sprites=", s["object_sprites"], " procedural_polygons=", s["polygon_nodes"])
		if not (s["legacy_textures"] as Array).is_empty():
			push_warning("[visual-source] live scene has %d sprite(s) on legacy textures" % (s["legacy_textures"] as Array).size())
