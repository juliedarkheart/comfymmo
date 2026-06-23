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
	var actors: Dictionary = {}
	for id_variant in CharacterArtRegistry.required_character_ids() + CharacterArtRegistry.required_creature_ids():
		var path: String = CharacterArtRegistry.texture_path(String(id_variant))
		var src: String = CharacterArtRegistry.source_of(path)
		actors[src] = int(actors.get(src, 0)) + 1
	return {
		"mode": mode,
		"terrain": terrain,
		"terrain_legacy_in_live": terrain_legacy,
		"objects": objects,
		"object_legacy_in_live": object_legacy,
		"ui": ui,
		"actors": actors,
	}

## How many ids in each registry still resolve to a GENERATED (dev/temporary) tier
## in the live projection — i.e. art the player sees that has no reviewed Sprout
## option yet. Optional Sprout comparisons want these to stay low and documented.
static func generated_fallback_counts(mode: String = WorldProjection.DEFAULT_MODE) -> Dictionary:
	var summary: Dictionary = registry_summary(mode)
	return {
		"terrain": int((summary["terrain"] as Dictionary).get("generated", 0)),
		"objects": int((summary["objects"] as Dictionary).get("generated", 0)),
		"ui": int((summary["ui"] as Dictionary).get("generated", 0)),
		"actors": int((summary["actors"] as Dictionary).get("generated", 0)),
	}

## True when the registries resolve NO legacy old art in the live projection.
static func is_clean(mode: String = WorldProjection.DEFAULT_MODE) -> bool:
	var summary: Dictionary = registry_summary(mode)
	return (summary["terrain_legacy_in_live"] as Array).is_empty() \
		and (summary["object_legacy_in_live"] as Array).is_empty() \
		and not (summary["actors"] as Dictionary).has("missing")

## What a live map scene actually spawned: counts of registry sprites vs raw
## procedural Polygon2D nodes, and any sprite still using a legacy texture.
static func scene_summary(map: Node) -> Dictionary:
	var terrain_sprites: int = 0
	var object_sprites: int = 0
	var actor_sprites: int = 0
	var legacy_textures: Array[String] = []
	if map != null:
		for node in map.find_children("*", "Sprite2D", true, false):
			var sprite: Sprite2D = node as Sprite2D
			if not _is_visible_canvas_item(sprite):
				continue
			var path: String = _sprite_source_path(sprite)
			if String(sprite.name).begins_with("TerrainArt"):
				terrain_sprites += 1
			elif String(sprite.name).begins_with("CharacterArt"):
				actor_sprites += 1
			else:
				object_sprites += 1
			if path.begins_with("res://art/tiles/") or path.begins_with("res://art/objects/"):
				legacy_textures.append(path)
	var polygons: int = map.find_children("*", "Polygon2D", true, false).size() if map != null else 0
	return {
		"terrain_sprites": terrain_sprites,
		"object_sprites": object_sprites,
		"actor_sprites": actor_sprites,
		"polygon_nodes": polygons,
		"legacy_textures": legacy_textures,
	}

## Soft budget for procedural Polygon2D nodes the live scene may still draw in normal
## play (signs, plot boundaries, the wardrobe mirror — no reviewed Sprout option yet).
## Above this we warn so the count is tracked, not silently creeping back up.
const PROCEDURAL_POLYGON_BUDGET := 600

## Classify a texture path into a source tier for the live-opening audit.
static func classify_texture(path: String) -> String:
	var p := String(path).to_lower()
	if p.is_empty():
		return "procedural"
	if p.contains("/missing"):
		return "missing"
	if p.contains("licensed_assets/limezu"):
		return "limezu_generated_local" if (p.contains("generator_outputs") or p.contains("generated_candidates")) else "limezu"
	if p.contains("licensed_assets/sprout"):
		return "sprout"
	if p.contains("art/generated/hearthvale"):
		return "generated"
	if p.contains("art/objects") or p.contains("art/tiles") or p.contains("fable_cute") or p.contains("assets/generated"):
		return "legacy"
	return "other"

## Walk a live map node and tally every Sprite2D by source tier, plus Polygon2D count.
## Used by validation to hard-block Sprout/generated/legacy visuals in the LimeZu opening.
static func live_opening_sources(map: Node) -> Dictionary:
	var tiers: Dictionary = {}
	if map != null:
		for node in map.find_children("*", "Sprite2D", true, false):
			var s := node as Sprite2D
			if not _is_visible_canvas_item(s):
				continue
			var path: String = _sprite_source_path(s)
			var tier := classify_texture(path)
			tiers[tier] = int(tiers.get(tier, 0)) + 1
	return tiers

## Tally visible Sprite2D/Polygon2D sources whose tile position falls inside the
## named small LimeZu playable area. This is intentionally structural: it proves the
## bounded area is not leaking Sprout/legacy sprites without requiring pixel tests.
static func live_area_sources(map: Node, tile_bounds: Rect2i) -> Dictionary:
	var tiers: Dictionary = {}
	if map == null:
		return tiers
	for node in map.find_children("*", "Sprite2D", true, false):
		var s := node as Sprite2D
		if not _is_visible_canvas_item(s) or not _node_in_tile_bounds(map, s, tile_bounds):
			continue
		var path: String = _sprite_source_path(s)
		var tier := classify_texture(path)
		tiers[tier] = int(tiers.get(tier, 0)) + 1
	for node in map.find_children("*", "Polygon2D", true, false):
		var p := node as Polygon2D
		if not _is_visible_canvas_item(p) or not _node_in_tile_bounds(map, p, tile_bounds):
			continue
		tiers["procedural"] = int(tiers.get("procedural", 0)) + 1
	return tiers

static func _is_visible_canvas_item(item: CanvasItem) -> bool:
	return item != null and item.visible and (not item.is_inside_tree() or item.is_visible_in_tree())

static func _sprite_source_path(sprite: Sprite2D) -> String:
	if sprite == null:
		return ""
	if sprite.has_meta("visual_source_path"):
		return String(sprite.get_meta("visual_source_path"))
	if sprite.texture == null:
		return ""
	if sprite.texture.has_meta("source_path"):
		return String(sprite.texture.get_meta("source_path"))
	return sprite.texture.resource_path

static func _node_in_tile_bounds(map: Node, node: Node, tile_bounds: Rect2i) -> bool:
	var tile_variant: Variant = _node_tile(node)
	if tile_variant is Vector2i:
		return tile_bounds.has_point(tile_variant as Vector2i)
	if map.has_method("world_to_grid") and node is Node2D and map is Node2D:
		var map_node := map as Node2D
		var node_2d := node as Node2D
		var local_pos: Vector2 = map_node.to_local(node_2d.global_position)
		var tile: Vector2i = map.call("world_to_grid", local_pos)
		return tile_bounds.has_point(tile)
	return false

static func _node_tile(node: Node) -> Variant:
	if node == null:
		return null
	if node.has_meta("tile"):
		return node.get_meta("tile")
	var parent := node.get_parent()
	if parent != null and parent.has_meta("tile"):
		return parent.get_meta("tile")
	return null

static func print_report(map: Node = null, mode: String = WorldProjection.DEFAULT_MODE) -> void:
	var r: Dictionary = registry_summary(mode)
	print("[visual-source] projection=", r["mode"], " (legacy iso is fallback only)")
	print("[visual-source] terrain tiers=", r["terrain"], " legacy_in_live=", r["terrain_legacy_in_live"])
	print("[visual-source] object tiers=", r["objects"], " legacy_in_live=", r["object_legacy_in_live"])
	print("[visual-source] ui tiers=", r["ui"])
	print("[visual-source] actor tiers=", r["actors"])
	# Sprout is optional/reference-only; report readiness without blocking boot.
	var sprout: Dictionary = SproutAssetRequirement.check()
	print("[visual-source] sprout_optional_required=", SproutAssetRequirement.REQUIRED,
		" status=", sprout["summary"])
	var provider_status: Dictionary = ArtProviderRegistry.status()
	print("[visual-source] selected_provider=", provider_status.get("selected_live_provider", ""),
		" limezu_tier=", provider_status.get("limezu_readiness_tier", ""),
		" limezu_resolved=", provider_status.get("limezu_resolved_live_count", 0), "/",
		provider_status.get("limezu_required_live_count", 0),
		" sprout_ready=", provider_status.get("sprout_ready", false))
	if String(provider_status.get("selected_live_provider", "")) == ArtProviderRegistry.PROVIDER_GENERATED \
			and not String(provider_status.get("limezu_missing_reason", "")).is_empty():
		push_warning("[visual-source] generated fallback selected: %s" % String(provider_status.get("limezu_missing_reason", "")))
	# Curated demo slice: opening view frames the composed homestead; the broad
	# overworld visual layers (wilderness scatter, far connecting roads) are suppressed
	# in normal play. The gameplay/data world is unchanged underneath.
	print("[visual-source] curated_slice=", LiveVisualPolicy.CURATED_SLICE,
		" opening_zoom=", LiveVisualPolicy.CURATED_SLICE_ZOOM if LiveVisualPolicy.CURATED_SLICE else LiveVisualPolicy.OVERWORLD_WIDE_ZOOM)
	# Provider readiness: LimeZu is preferred when ready, otherwise generated/procedural
	# fallbacks keep the world playable. Sprout remains optional/reference-only.
	print("[visual-source] art_providers=", provider_status)
	print("[visual-source] limezu_spike active_ids=", LimeZuArtRegistry.list_active_ids().size(),
		" by_category=", LimeZuArtRegistry.list_active_ids_by_category().keys())
	if not bool(sprout["ok"]):
		push_warning("[visual-source] Optional Sprout assets missing/inactive: %s" % str(sprout["missing"]))
	print("[visual-source] generated_dev_fallback (used only when LimeZu is absent/incomplete)=",
		generated_fallback_counts(mode))
	if not is_clean(mode):
		push_warning("[visual-source] LIVE sprout_topdown is resolving LEGACY old art for some ids (see lists)")
	if map != null:
		var s: Dictionary = scene_summary(map)
		print("[visual-source] live scene: terrain_sprites=", s["terrain_sprites"],
			" object_sprites=", s["object_sprites"], " actor_sprites=", s["actor_sprites"],
			" procedural_polygons=", s["polygon_nodes"])
		if not (s["legacy_textures"] as Array).is_empty():
			push_warning("[visual-source] live scene has %d sprite(s) on legacy textures" % (s["legacy_textures"] as Array).size())
		if int(s["polygon_nodes"]) > PROCEDURAL_POLYGON_BUDGET:
			push_warning("[visual-source] live scene draws %d procedural polygons (budget %d) — quarantine more props"
				% [int(s["polygon_nodes"]), PROCEDURAL_POLYGON_BUDGET])
		# Live-opening source-purity audit (LimeZu mode forbids Sprout/legacy visuals).
		var opening: Dictionary = live_opening_sources(map)
		print("[visual-source] live opening sources=", opening)
		if LiveVisualPolicy.live_limezu_slice():
			for forbidden in ["sprout", "legacy"]:
				if int(opening.get(forbidden, 0)) > 0:
					push_warning("[visual-source] LimeZu opening still has %d '%s' sprite(s)!" % [int(opening[forbidden]), forbidden])
