extends SceneTree

# The continuous overworld is the main outdoor scene. The legacy paged region scenes
# are kept here too so we catch it early if they ever stop parsing.
const RESOURCE_PATHS: Array[String] = [
	"res://scenes/main.tscn",
	"res://scenes/world/overworld.tscn",
	"res://world/overworld_controller.gd",
	"res://world/overworld_map.gd",
	"res://world/outdoor_area_controller.gd",
	"res://world/homestead_controller.gd",
	"res://world/homestead_map.gd",
	"res://world/terrain_shapes.gd",
	"res://world/iso_map_helpers.gd",
	"res://world/outdoor_controller_helpers.gd",
	"res://systems/world/world_projection.gd",
	"res://systems/world/asset_world_metadata.gd",
	"res://systems/visual/live_visual_policy.gd",
	"res://systems/visual/sprout_asset_requirement.gd",
	"res://ui/missing_assets_screen.gd",
	"res://systems/art/terrain_art_registry.gd",
	"res://systems/art/object_art_registry.gd",
	"res://systems/art/character_art_registry.gd",
	"res://systems/art/ui_art_registry.gd",
	"res://systems/art/art_activation.gd",
	"res://systems/art/limezu_art_registry.gd",
	"res://systems/art/art_provider_registry.gd",
	"res://scenes/visual_spikes/limezu_homestead_slice.tscn",
	"res://tools/art/asset_preview.tscn",
	"res://systems/content/content_ids.gd",
	"res://systems/content/content_registry.gd",
	"res://systems/world_region_manager.gd",
	"res://systems/local_save_system.gd",
	"res://systems/game_state_manager.gd",
	"res://systems/dev_tool_state.gd",
	"res://systems/overworld_editor_system.gd",
	"res://systems/world_builder_overlay.gd",
	"res://systems/parcel_preview.gd",
	"res://systems/dev_world_marker.gd",
	# Large-world architecture + cozy UI + day/night (this design-correction pass).
	"res://systems/world/biome_registry.gd",
	"res://systems/world/world_chunk.gd",
	"res://systems/world/world_chunk_registry.gd",
	"res://systems/world/world_generation.gd",
	"res://systems/world/world_area_registry.gd",
	"res://systems/world/day_night_cycle.gd",
	"res://ui/cozy_ui_theme.gd",
	"res://systems/admin/moderation_models.gd",
	"res://systems/admin/audit_log.gd",
	"res://systems/character/character_appearance.gd",
	"res://systems/character/character_appearance_registry.gd",
	"res://systems/character/character_visual_builder.gd",
	"res://avatar/avatar_visual.gd",
	"res://villagers/simple_villager.gd",
	"res://villagers/bram_villager.gd",
	"res://creatures/ambient_creature.gd",
	"res://creatures/moss_rabbit.gd",
	"res://creatures/lantern_moth.gd",
	"res://creatures/stump_turtle.gd",
	"res://ui/dev_character_creator_panel.tscn",
	# Persistent-world pass: resources, building, profiles, network, server.
	"res://systems/resources/resource_ids.gd",
	"res://systems/resources/material_inventory.gd",
	"res://systems/resources/resource_node.gd",
	"res://systems/building/build_costs.gd",
	"res://buildings/decor_visuals.gd",
	"res://buildings/placeable_decor.gd",
	"res://systems/profile/local_profile.gd",
	"res://systems/profile/local_profile_manager.gd",
	"res://systems/network/network_mode.gd",
	"res://systems/network/network_messages.gd",
	"res://systems/network/player_identity.gd",
	"res://systems/network/remote_player.gd",
	"res://systems/network/network_session.gd",
	"res://server/server_config.gd",
	"res://server/server_save_system.gd",
	"res://server/server_world_state.gd",
	"res://server/server_player_state.gd",
	"res://server/hearthvale_server.gd",
	"res://server/server_main.tscn",
	"res://ui/network_connect_panel.tscn",
	"res://systems/network/chat_message.gd",
	"res://systems/resources/resource_spawn_registry.gd",
	"res://ui/chat_panel.tscn",
	"res://systems/crafting/crafting_recipe.gd",
	"res://systems/crafting/crafting_registry.gd",
	"res://systems/crafting/crafting_system.gd",
	"res://systems/progression/player_progression.gd",
	"res://systems/progression/skill_progression.gd",
	"res://systems/progression/progression_registry.gd",
	"res://ui/crafting_panel.tscn",
	"res://ui/progression_panel.tscn",
	"res://systems/items/item_ids.gd",
	"res://systems/land/land_plot.gd",
	"res://systems/land/land_registry.gd",
	"res://systems/land/land_claim_system.gd",
	"res://systems/admin/admin_permissions.gd",
	# Usability repair pass: display, inventory, nameplate, land panels.
	"res://ui/display_settings.gd",
	"res://ui/nameplate.gd",
	"res://ui/inventory_panel.tscn",
	"res://ui/land_panel.tscn",
	# Land/HUD/admin repair pass.
	"res://ui/prototype_hud.tscn",
	"res://ui/minimap_panel.tscn",
	"res://ui/quick_tools_bar.tscn",
	"res://ui/admin_panel.tscn",
	"res://ui/world_space_hint.tscn",
	# Build-UI / interiors / map pass.
	"res://systems/building/build_categories.gd",
	"res://systems/building/prefab_interiors.gd",
	"res://ui/build_menu_panel.tscn",
	"res://ui/build_edit_toolbar.tscn",
	"res://ui/interior_view.tscn",
	"res://ui/system_menu.tscn",
	"res://scenes/world/homestead.tscn",
	"res://scenes/world/regions/homestead/homestead_region.tscn",
	"res://scenes/world/regions/village_square/village_square_region.tscn",
	"res://scenes/world/regions/forest_edge/forest_edge_region.tscn",
	"res://systems/region_transition_system.gd",
	"res://world/regions/homestead/homestead_region_controller.gd",
	"res://world/regions/village_square/village_square_region_controller.gd",
	"res://world/regions/forest_edge/forest_edge_region_controller.gd",
]

const VISUAL_DOC_CHECKS := {
	"res://docs/visual_identity.md": ["cozy 2D isometric", "storybook", "plot boundary", "no harsh debug"],
	"res://docs/ui_style_guide.md": ["cozy_ui_theme.gd", "Close", "selected", "unavailable", "UIArtRegistry"],
	"res://docs/world_art_direction.md": ["meadow", "forest", "creekside", "sprout_topdown", "minimap", "hearthvale"],
	"res://docs/building_art_direction.md": ["foundation", "wall", "prefab", "modular", "interiors"],
	"res://docs/graphics_pipeline.md": ["terrain_art_registry.gd", "object_art_registry.gd", "fallback", "sprout_topdown", "generated/hearthvale"],
	"res://docs/asset_credits.md": ["no third-party assets", "CC0", "art/external", "license"],
	"res://docs/asset_review_workflow.md": ["contact sheet", "active_art_manifest.json", "art/review", "not auto-wired"],
	"res://docs/licensed_asset_policy.md": ["Cup Nooble", "non-redistributable", "licensed_assets/", "ArtActivation", "licensed_modified"],
	"res://docs/examples/sprout_animation_manifest.example.json": ["Catalog only", "animations_inventory.json", "No combat"],
	"res://docs/examples/sprout_audio_inventory.example.json": ["Catalog only", "audio_inventory.json", "No runtime audio"],
}

const REQUIRED_ART_DIRS: Array[String] = [
	"res://art/tiles",
	"res://art/tiles/terrain",
	"res://art/tiles/biomes",
	"res://art/tiles/paths",
	"res://art/tiles/water",
	"res://art/objects",
	"res://art/objects/building",
	"res://art/objects/nature",
	"res://art/objects/decor",
	"res://art/characters",
	"res://art/creatures",
	"res://art/ui",
	"res://art/ui/icons",
	"res://art/placeholders",
	"res://art/generated",
	"res://art/generated/hearthvale/characters",
	"res://art/generated/hearthvale/creatures",
	"res://art/generated/from_external",
	"res://art/external",
	"res://art/review",
	"res://tools/art",
]

const REQUIRED_GENERATED_PNGS: Array[String] = [
	"res://art/placeholders/missing.png",
	"res://art/tiles/biomes/meadow.png",
	"res://art/tiles/biomes/forest.png",
	"res://art/tiles/biomes/orchard.png",
	"res://art/tiles/biomes/creekside.png",
	"res://art/tiles/biomes/riverbank.png",
	"res://art/tiles/biomes/hilltop.png",
	"res://art/tiles/biomes/grove.png",
	"res://art/tiles/biomes/town.png",
	"res://art/tiles/biomes/farmland.png",
	"res://art/tiles/biomes/farmer_training.png",
	"res://art/tiles/paths/dirt_path.png",
	"res://art/tiles/paths/stone_path.png",
	"res://art/tiles/paths/tilled_soil.png",
	"res://art/tiles/paths/plot_boundary.png",
	"res://art/tiles/paths/plot_corner.png",
	"res://art/tiles/water/water.png",
	"res://art/tiles/water/creek.png",
	"res://art/tiles/water/water_edge.png",
	"res://art/tiles/terrain/grass_to_path.png",
	"res://art/tiles/terrain/grass_to_water.png",
	"res://art/tiles/terrain/grass_to_farmland.png",
	"res://art/tiles/terrain/biome_soft_edge.png",
	"res://art/tiles/terrain/path_edge.png",
	"res://art/tiles/terrain/water_edge.png",
	"res://art/objects/nature/tree.png",
	"res://art/objects/nature/fruit_tree.png",
	"res://art/objects/nature/rock.png",
	"res://art/objects/nature/bush.png",
	"res://art/objects/nature/flower_patch.png",
	"res://art/objects/nature/water_edge.png",
	"res://art/objects/nature/crop_carrot.png",
	"res://art/objects/decor/fence.png",
	"res://art/objects/decor/gate.png",
	"res://art/objects/decor/sign.png",
	"res://art/objects/decor/mailbox.png",
	"res://art/objects/building/foundation.png",
	"res://art/objects/building/floor.png",
	"res://art/objects/building/wall.png",
	"res://art/objects/building/stone_wall.png",
	"res://art/objects/building/door_wall.png",
	"res://art/objects/building/window_wall.png",
	"res://art/objects/building/roof.png",
	"res://art/objects/building/post.png",
	"res://art/objects/building/workbench.png",
	"res://art/objects/building/storage_chest.png",
	"res://art/objects/building/crate.png",
	"res://art/objects/building/prefab_cottage.png",
	"res://art/objects/building/prefab_shed.png",
	"res://art/objects/building/well.png",
	"res://art/objects/building/stairs.png",
	"res://art/ui/icons/wood.png",
	"res://art/ui/icons/stone.png",
	"res://art/ui/icons/fiber.png",
	"res://art/ui/icons/clay.png",
	"res://art/ui/icons/carrot.png",
	"res://art/ui/icons/worn_axe.png",
	"res://art/ui/icons/worn_pickaxe.png",
	"res://art/ui/icons/worn_hoe.png",
	"res://art/ui/icons/watering_can.png",
	"res://art/ui/icons/simple_hammer.png",
	"res://art/ui/icons/basic_shovel.png",
	"res://art/ui/icons/land_token.png",
	"res://art/ui/icons/build_tool.png",
	"res://art/ui/icons/delete.png",
	"res://art/ui/icons/rotate.png",
	"res://art/ui/icons/paint.png",
	"res://art/generated/hearthvale/ui/dialog_panel.png",
	"res://art/generated/hearthvale/ui/inventory_panel.png",
	"res://art/generated/hearthvale/ui/system_menu_panel.png",
	"res://art/generated/hearthvale/ui/build_menu_panel.png",
	"res://art/generated/hearthvale/ui/check.png",
	"res://art/generated/hearthvale/ui/cursor.png",
	"res://art/generated/hearthvale/characters/player.png",
	"res://art/generated/hearthvale/characters/remote_player.png",
	"res://art/generated/hearthvale/characters/maribel_tock.png",
	"res://art/generated/hearthvale/characters/bram_nettle.png",
	"res://art/generated/hearthvale/characters/rowan.png",
	"res://art/generated/hearthvale/characters/land_clerk.png",
	"res://art/generated/hearthvale/creatures/moss_rabbit.png",
	"res://art/generated/hearthvale/creatures/lantern_moth.png",
	"res://art/generated/hearthvale/creatures/stump_turtle.png",
]

var _validation_placeable_ids: Array[String] = []
var _validation_active_placeable_id: String = ""

func _validation_get_placeable_ids() -> Array:
	return _validation_placeable_ids

func _validation_get_placeable_status(_placeable_id: String) -> Dictionary:
	return {"ok": true, "reason": ""}

func _validation_select_placeable(placeable_id: String) -> void:
	_validation_active_placeable_id = placeable_id

func _validation_get_active_placeable_id() -> String:
	return _validation_active_placeable_id

func _validation_get_inventory_count(_item_id: String) -> int:
	return 1

func _validation_get_identity() -> Dictionary:
	return {
		"display_name": "Validator",
		"username": "validator",
		"profile_id": "validation-profile",
		"mode": "Offline",
		"plot_status": "Your plot",
	}

func _validation_claim_plot(_plot_id: String) -> void:
	pass

func _folder_has_any_file(folder_path: String, file_names: Array[String]) -> bool:
	for file_name in file_names:
		if FileAccess.file_exists("%s/%s" % [folder_path, file_name]):
			return true
	return false

## Blocked/unavailable slots deliberately stay flat so muted labels remain readable.
func _is_limezu_flat_with_fill(box: StyleBox, expected_fill: Color) -> bool:
	if box == null or box is StyleBoxTexture or not (box is StyleBoxFlat):
		return false
	return (box as StyleBoxFlat).bg_color.is_equal_approx(expected_fill)

func _is_limezu_texture_box(box: StyleBox) -> bool:
	if box == null or not (box is StyleBoxTexture):
		return false
	var textured := box as StyleBoxTexture
	return textured.texture != null

func _audit_count(entry: Dictionary, tier: String) -> int:
	return int((entry.get("counts", {}) as Dictionary).get(tier, 0))

func _audit_paths_contain(entry: Dictionary, needle: String) -> bool:
	for path_variant in (entry.get("paths", []) as Array):
		if String(path_variant).contains(needle):
			return true
	return false

func _audit_limezu_family_count(counts: Dictionary) -> int:
	var total := 0
	for tier in ["limezu_reviewed", "limezu_raw", "limezu_derivative", "limezu_inspired", "limezu_generated_local"]:
		total += int(counts.get(tier, 0))
	return total

func _external_metadata_error(folder_path: String) -> String:
	var license_names: Array[String] = ["LICENSE", "LICENSE.txt", "LICENSE.md", "COPYING", "COPYING.txt"]
	var source_names: Array[String] = ["README.md", "README.txt", "SOURCE.txt", "CREDITS.txt", "ATTRIBUTION.txt", "NOTICE", "asset.json", "source.json"]
	if not _folder_has_any_file(folder_path, license_names):
		return "External asset folder missing LICENSE/COPYING metadata: %s" % folder_path
	if not _folder_has_any_file(folder_path, source_names):
		return "External asset folder missing README/SOURCE/CREDITS metadata: %s" % folder_path
	return ""

func _validate_external_asset_tree(root_path: String) -> String:
	var root: DirAccess = DirAccess.open(root_path)
	if root == null:
		return "External asset root could not be opened: %s" % root_path
	root.list_dir_begin()
	var source_name: String = root.get_next()
	while not source_name.is_empty():
		if root.current_is_dir() and not source_name.begins_with("."):
			var source_path := "%s/%s" % [root_path, source_name]
			var source_dir: DirAccess = DirAccess.open(source_path)
			if source_dir == null:
				return "External asset source folder could not be opened: %s" % source_path
			source_dir.list_dir_begin()
			var asset_name: String = source_dir.get_next()
			var found_asset_folder := false
			while not asset_name.is_empty():
				if source_dir.current_is_dir() and not asset_name.begins_with("."):
					found_asset_folder = true
					var metadata_error: String = _external_metadata_error("%s/%s" % [source_path, asset_name])
					if not metadata_error.is_empty():
						source_dir.list_dir_end()
						root.list_dir_end()
						return metadata_error
				asset_name = source_dir.get_next()
			source_dir.list_dir_end()
			if not found_asset_folder:
				var source_metadata_error: String = _external_metadata_error(source_path)
				if not source_metadata_error.is_empty():
					root.list_dir_end()
					return source_metadata_error
		source_name = root.get_next()
	root.list_dir_end()
	return ""

func _initialize() -> void:
	for resource_path in RESOURCE_PATHS:
		var resource: Resource = load(resource_path)
		if resource == null:
			push_error("Failed to load resource: %s" % resource_path)
			quit(1)
			return

		if resource is PackedScene:
			var packed_scene: PackedScene = resource as PackedScene
			var instance: Node = packed_scene.instantiate()
			if instance == null:
				push_error("Failed to instantiate scene: %s" % resource_path)
				quit(1)
				return
			instance.free()

	# Visual/UI foundation pass: required direction docs must exist and mention
	# the concrete style rules this branch is standardizing around.
	for doc_path in VISUAL_DOC_CHECKS.keys():
		if not FileAccess.file_exists(String(doc_path)):
			push_error("Visual identity doc missing: %s" % doc_path)
			quit(1)
			return
		var doc_text: String = FileAccess.get_file_as_string(String(doc_path))
		if doc_text.is_empty():
			push_error("Visual identity doc is empty: %s" % doc_path)
			quit(1)
			return
		var doc_text_lower: String = doc_text.to_lower()
		var doc_snippets: Array = VISUAL_DOC_CHECKS[doc_path] as Array
		for required_snippet in doc_snippets:
			if not doc_text_lower.contains(String(required_snippet).to_lower()):
				push_error("Visual identity doc '%s' is missing '%s'" % [doc_path, required_snippet])
				quit(1)
				return

	# Graphics asset foundation: folder contract, generated placeholders,
	# registry lookups, safe fallbacks, and renderer wiring.
	for dir_path in REQUIRED_ART_DIRS:
		if DirAccess.open(dir_path) == null:
			push_error("Required art folder missing: %s" % dir_path)
			quit(1)
			return
	if not FileAccess.file_exists("res://tools/art/generate_placeholder_art.py"):
		push_error("Generated placeholder script is missing")
		quit(1)
		return
	if not FileAccess.file_exists("res://art/generated/README.md"):
		push_error("Generated placeholder README is missing")
		quit(1)
		return
	for png_path in REQUIRED_GENERATED_PNGS:
		if not FileAccess.file_exists(png_path):
			push_error("Required generated art PNG missing: %s" % png_path)
			quit(1)
			return
	var external_error: String = _validate_external_asset_tree("res://art/external")
	if not external_error.is_empty():
		push_error(external_error)
		quit(1)
		return
	for projection_mode in [WorldProjection.MODE_ISO_64X32, WorldProjection.MODE_SPROUT_TOPDOWN, WorldProjection.MODE_TOPDOWN_16, WorldProjection.MODE_TOPDOWN_32]:
		if not WorldProjection.supported_modes().has(projection_mode):
			push_error("WorldProjection missing supported mode: %s" % projection_mode)
			quit(1)
			return
	if WorldProjection.DEFAULT_MODE != WorldProjection.MODE_SPROUT_TOPDOWN:
		push_error("WorldProjection default must be the live Sprout/top-down mode")
		quit(1)
		return
	if not WorldProjection.is_primary_mode(WorldProjection.MODE_SPROUT_TOPDOWN) or not WorldProjection.is_legacy_mode(WorldProjection.MODE_ISO_64X32):
		push_error("WorldProjection primary/legacy flags regressed")
		quit(1)
		return
	var iso_projection_tile := Vector2i(4, 7)
	if WorldProjection.world_to_tile(WorldProjection.tile_to_world(iso_projection_tile, WorldProjection.MODE_ISO_64X32), WorldProjection.MODE_ISO_64X32) != iso_projection_tile:
		push_error("WorldProjection iso_64x32 round-trip failed")
		quit(1)
		return
	var topdown_projection_tile := Vector2i(5, 6)
	if WorldProjection.tile_size(WorldProjection.MODE_SPROUT_TOPDOWN) != Vector2i(32, 32) or WorldProjection.sprite_canvas_size(WorldProjection.MODE_SPROUT_TOPDOWN) != Vector2i(32, 32):
		push_error("WorldProjection sprout_topdown must use the reviewed 32x32 live tile size")
		quit(1)
		return
	if WorldProjection.tile_to_world(topdown_projection_tile, WorldProjection.MODE_SPROUT_TOPDOWN) != Vector2(160, 192):
		push_error("WorldProjection sprout_topdown tile_to_world did not use 32x32 top-down spacing")
		quit(1)
		return
	if WorldProjection.world_to_tile(Vector2(160, 192), WorldProjection.MODE_SPROUT_TOPDOWN) != topdown_projection_tile:
		push_error("WorldProjection sprout_topdown world_to_tile failed")
		quit(1)
		return
	if not WorldProjection.is_sprout_compatible(WorldProjection.MODE_SPROUT_TOPDOWN) or WorldProjection.is_sprout_compatible(WorldProjection.MODE_ISO_64X32):
		push_error("WorldProjection sprout compatibility flags regressed")
		quit(1)
		return
	if LiveVisualPolicy.PRIMARY_PROJECTION != WorldProjection.MODE_SPROUT_TOPDOWN or LiveVisualPolicy.TILE_SIZE != Vector2i(32, 32):
		push_error("LiveVisualPolicy no longer targets Sprout/top-down 32x32 scale")
		quit(1)
		return
	if LiveVisualPolicy.should_draw_broad_procedural_scenery():
		push_error("Normal play must not draw broad procedural scenery/debug slabs")
		quit(1)
		return
	var sprout_tile_poly: PackedVector2Array = WorldProjection.tile_polygon(WorldProjection.MODE_SPROUT_TOPDOWN)
	if sprout_tile_poly.size() != 4 or sprout_tile_poly[0] != Vector2(-16, -16) or sprout_tile_poly[2] != Vector2(16, 16):
		push_error("WorldProjection sprout_topdown tile polygon must be a centered 32x32 square")
		quit(1)
		return
	var iso_tile_poly: PackedVector2Array = WorldProjection.tile_polygon(WorldProjection.MODE_ISO_64X32)
	if iso_tile_poly.size() != 4 or iso_tile_poly[0].x != 0:
		push_error("WorldProjection iso_64x32 polygon must keep the legacy diamond")
		quit(1)
		return
	if TerrainArtRegistry.texture_path("__invalid_terrain__") != TerrainArtRegistry.FALLBACK_PATH:
		push_error("TerrainArtRegistry invalid id did not return fallback path")
		quit(1)
		return
	if TerrainArtRegistry.texture("__invalid_terrain__") == null:
		push_error("TerrainArtRegistry fallback texture failed to load")
		quit(1)
		return
	for terrain_id_variant in TerrainArtRegistry.required_ids():
		var terrain_id: String = String(terrain_id_variant)
		var terrain_visual: Dictionary = TerrainArtRegistry.visual_for(terrain_id, Vector2i(3, 4))
		if bool(terrain_visual.get("fallback", true)):
			push_error("Required terrain id resolved to fallback instead of art: %s" % terrain_id)
			quit(1)
			return
		if terrain_visual.get("texture", null) == null:
			push_error("Required terrain id resolved to null texture: %s" % terrain_id)
			quit(1)
			return
		if not FileAccess.file_exists(String(terrain_visual.get("path", ""))):
			push_error("Required terrain id resolved to missing path: %s" % terrain_id)
			quit(1)
			return
	var transition_visual: Dictionary = TerrainArtRegistry.transition_visual("meadow", "water")
	if String(transition_visual.get("id", "")) != "grass_to_water" or transition_visual.get("texture", null) == null:
		push_error("TerrainArtRegistry transition helper did not return a safe grass_to_water visual")
		quit(1)
		return
	var sprout_terrain_visual: Dictionary = TerrainArtRegistry.visual_for("meadow", Vector2i.ZERO, WorldProjection.MODE_SPROUT_TOPDOWN)
	var sprout_projection: Dictionary = sprout_terrain_visual.get("projection", {}) as Dictionary
	if not bool(sprout_projection.get("sprout_compatible", false)) or sprout_projection.get("sprite_canvas_size", Vector2i.ZERO) != Vector2i(32, 32):
		push_error("TerrainArtRegistry did not carry Sprout/top-down projection hints safely")
		quit(1)
		return
	# In Sprout/top-down mode a NON-licensed terrain id resolves to an original
	# Hearthvale top-down tile (art/generated/hearthvale/terrain/...) that DOES
	# render as a sprite — the legacy 64x48 iso diamonds are never used here.
	# (farmer_training is never licensed nor tinted, so it stays generated.)
	var topdown_generated_visual: Dictionary = TerrainArtRegistry.visual_for("farmer_training", Vector2i.ZERO, WorldProjection.MODE_SPROUT_TOPDOWN)
	var topdown_generated_path: String = String(topdown_generated_visual.get("path", ""))
	if TerrainArtRegistry.source_of(topdown_generated_path) != "generated" or not topdown_generated_path.begins_with(TerrainArtRegistry.HEARTHVALE_TOPDOWN_ROOT):
		push_error("Non-licensed terrain should resolve to an original Hearthvale top-down tile in Sprout mode")
		quit(1)
		return
	if not bool(topdown_generated_visual.get("render_sprite", false)):
		push_error("Hearthvale top-down generated tile must render as a sprite in Sprout/top-down mode")
		quit(1)
		return
	var legacy_iso_visual: Dictionary = TerrainArtRegistry.visual_for("farmer_training", Vector2i.ZERO, WorldProjection.MODE_ISO_64X32)
	if not String(legacy_iso_visual.get("path", "")).begins_with(TerrainArtRegistry.LEGACY_TILE_ROOT) or not bool(legacy_iso_visual.get("render_sprite", false)):
		push_error("Legacy iso terrain art regressed in iso_64x32 mode")
		quit(1)
		return
	if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("meadow", WorldProjection.MODE_ISO_64X32)) == "licensed":
		push_error("Sprout licensed terrain must not activate in legacy iso_64x32 mode")
		quit(1)
		return
	if ObjectArtRegistry.texture_path("__invalid_object__") != ObjectArtRegistry.FALLBACK_PATH:
		push_error("ObjectArtRegistry invalid id did not return fallback path")
		quit(1)
		return
	if ObjectArtRegistry.texture("__invalid_object__") == null:
		push_error("ObjectArtRegistry fallback texture failed to load")
		quit(1)
		return
	for object_id_variant in ObjectArtRegistry.required_ids():
		var object_id: String = String(object_id_variant)
		var object_visual: Dictionary = ObjectArtRegistry.visual_for(object_id)
		if bool(object_visual.get("fallback", true)):
			push_error("Required object/icon id resolved to fallback instead of art: %s" % object_id)
			quit(1)
			return
		if object_visual.get("texture", null) == null:
			push_error("Required object/icon id resolved to null texture: %s" % object_id)
			quit(1)
			return
		if not FileAccess.file_exists(String(object_visual.get("path", ""))):
			push_error("Required object/icon id resolved to missing path: %s" % object_id)
			quit(1)
			return
	var registry_sprite := ObjectArtRegistry.make_sprite(ContentIds.PLACEABLE_WOOD_WALL)
	if registry_sprite == null or registry_sprite.texture == null:
		push_error("ObjectArtRegistry.make_sprite failed for wood wall")
		if registry_sprite != null:
			registry_sprite.free()
		quit(1)
		return
	registry_sprite.free()
	if CharacterArtRegistry.texture_path("__invalid_actor__") != CharacterArtRegistry.FALLBACK_PATH:
		push_error("CharacterArtRegistry invalid id did not return fallback path")
		quit(1)
		return
	if CharacterArtRegistry.texture("__invalid_actor__") == null:
		push_error("CharacterArtRegistry fallback texture failed to load")
		quit(1)
		return
	for actor_id_variant in CharacterArtRegistry.required_character_ids() + CharacterArtRegistry.required_creature_ids():
		var actor_id: String = String(actor_id_variant)
		var actor_visual: Dictionary = CharacterArtRegistry.visual_for(actor_id)
		if bool(actor_visual.get("fallback", true)):
			push_error("Required actor id resolved to fallback instead of art: %s" % actor_id)
			quit(1)
			return
		if actor_visual.get("texture", null) == null:
			push_error("Required actor id resolved to null texture: %s" % actor_id)
			quit(1)
			return
		if CharacterArtRegistry.source_of(String(actor_visual.get("path", ""))) != "generated":
			push_error("Required actor id should resolve to generated Hearthvale actor art: %s" % actor_id)
			quit(1)
			return
	var actor_sprite := CharacterArtRegistry.make_sprite(CharacterArtRegistry.PLAYER)
	if actor_sprite == null or actor_sprite.texture == null or not String(actor_sprite.name).begins_with("CharacterArt"):
		push_error("CharacterArtRegistry.make_sprite failed for player")
		if actor_sprite != null:
			actor_sprite.free()
		quit(1)
		return
	# Sprout/generated actors are scaled DOWN (<=0.7) for the 32x32 terrain; LimeZu live
	# actors use the upscaled LimeZu farmer (LIMEZU_DISPLAY_SCALE). Allow the right range.
	var max_actor_scale: float = (LiveVisualPolicy.LIMEZU_DISPLAY_SCALE + 0.6) if LiveVisualPolicy.live_limezu_slice() else 0.7
	if actor_sprite.scale.x > max_actor_scale or actor_sprite.scale.y > max_actor_scale:
		push_error("Live actor sprite scale %.2f is out of the expected range (max %.2f)" % [actor_sprite.scale.x, max_actor_scale])
		actor_sprite.free()
		quit(1)
		return
	actor_sprite.free()
	# External-preference resolver: an unactivated real id must resolve to the
	# generated placeholder (not missing); an unknown id resolves to missing. This
	# proves the external -> generated -> missing order is wired without fighting
	# the local Sprout licensed layer when it is installed.
	if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("farmer_training")) != "generated":
		push_error("Terrain external-preference resolver did not classify forest as generated")
		quit(1)
		return
	if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("__nope__")) != "missing":
		push_error("Terrain external-preference resolver did not classify an unknown id as missing")
		quit(1)
		return
	if ObjectArtRegistry.source_of(ObjectArtRegistry.texture_path(ContentIds.PLACEABLE_WOOD_WALL)) != "generated":
		push_error("Object external-preference resolver did not classify wood wall as generated")
		quit(1)
		return
	if not FileAccess.file_exists("res://art/sprout_ui_manifest.template.json"):
		push_error("Tracked Sprout UI manifest template is missing")
		quit(1)
		return
	var sprout_ui_template: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://art/sprout_ui_manifest.template.json"))
	if typeof(sprout_ui_template) != TYPE_DICTIONARY or typeof((sprout_ui_template as Dictionary).get("active", null)) != TYPE_DICTIONARY:
		push_error("Sprout UI manifest template must parse with an active map")
		quit(1)
		return
	if ((sprout_ui_template as Dictionary).get("active", {}) as Dictionary).size() != 0:
		push_error("Sprout UI manifest template must not activate local licensed assets")
		quit(1)
		return
	UIArtRegistry.reload()
	if UIArtRegistry.texture_path("__invalid_ui__") != UIArtRegistry.FALLBACK_PATH:
		push_error("UIArtRegistry invalid id did not return missing fallback")
		quit(1)
		return
	if UIArtRegistry.source_of(UIArtRegistry.texture_path("close")) == "missing":
		push_error("UIArtRegistry did not fall back to generated close/delete icon")
		quit(1)
		return
	for ui_id_variant in UIArtRegistry.required_ids():
		var required_ui_id: String = String(ui_id_variant)
		var required_ui_path: String = UIArtRegistry.texture_path(required_ui_id)
		if UIArtRegistry.source_of(required_ui_path) == "missing":
			push_error("UIArtRegistry required id resolved to missing art: %s" % required_ui_id)
			quit(1)
			return
	if UIArtRegistry.active_source() != "licensed_ui" and UIArtRegistry.active_source() != "cozy_code":
		push_error("UIArtRegistry active_source returned an unknown value")
		quit(1)
		return
	var ui_style_probe := PanelContainer.new()
	CozyUITheme.apply_panel(ui_style_probe)
	if not ui_style_probe.has_meta("ui_art_source"):
		push_error("CozyUITheme did not tag panels with the active UI source")
		ui_style_probe.free()
		quit(1)
		return
	ui_style_probe.free()
	# Manifest-driven activation: the activation manifest must exist + parse, and
	# with no activated entries the resolver must return generated art (proving an
	# imported pack can't blind-replace art just by sitting in the active folder).
	if not FileAccess.file_exists("res://art/active_art_manifest.json"):
		push_error("art/active_art_manifest.json is missing")
		quit(1)
		return
	var activation_file: FileAccess = FileAccess.open("res://art/active_art_manifest.json", FileAccess.READ)
	var activation_parsed: Variant = JSON.parse_string(activation_file.get_as_text())
	if typeof(activation_parsed) != TYPE_DICTIONARY or typeof((activation_parsed as Dictionary).get("active", null)) != TYPE_DICTIONARY:
		push_error("active_art_manifest.json must be an object with an 'active' map")
		quit(1)
		return
	ArtActivation.reload()
	if ArtActivation.active_count() != (activation_parsed as Dictionary)["active"].size():
		push_error("ArtActivation did not load the manifest's active entries")
		quit(1)
		return
	# An id that is NOT in the manifest must get no override (so it stays generated).
	if not ArtActivation.override_for("res://art/tiles/biomes/meadow.png", false).is_empty() and not (activation_parsed as Dictionary)["active"].has("tiles/biomes/meadow.png"):
		push_error("ArtActivation returned an override for an un-activated id")
		quit(1)
		return
	# The downloaded-but-unwired Kenney sheet must NOT be active anywhere.
	if (activation_parsed as Dictionary)["active"].size() > 0:
		for active_key in (activation_parsed as Dictionary)["active"].keys():
			var active_value: String = String((activation_parsed as Dictionary)["active"][active_key])
			if not active_value.is_empty() and not FileAccess.file_exists("res://art/" + active_value.trim_prefix("res://art/")):
				push_error("active_art_manifest entry points at a missing derivative: %s" % active_value)
				quit(1)
				return
	# --- Licensed assets (Sprout Lands, local-only) -----------------------------
	# TRACKING rules below hold regardless of whether the pack is installed (the
	# premium assets must never be committed). Sprout is optional/reference-only:
	# missing or corrupt local Sprout assets must not block boot because generated
	# fallback visuals keep the homestead playable.
	var gitignore_text: String = FileAccess.get_file_as_string("res://.gitignore")
	if not gitignore_text.contains("licensed_assets/"):
		push_error(".gitignore must ignore licensed_assets/ (premium assets must never be committed)")
		quit(1)
		return
	# The TRACKED template manifest must exist, parse, and contain NO real mappings.
	if not FileAccess.file_exists("res://art/sprout_active_manifest.template.json"):
		push_error("Tracked template art/sprout_active_manifest.template.json is missing")
		quit(1)
		return
	var sprout_template: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://art/sprout_active_manifest.template.json"))
	if typeof(sprout_template) != TYPE_DICTIONARY:
		push_error("sprout_active_manifest.template.json does not parse")
		quit(1)
		return
	var template_active: Variant = (sprout_template as Dictionary).get("active_in_template", {})
	if typeof(template_active) == TYPE_DICTIONARY and (template_active as Dictionary).size() != 0:
		push_error("Template manifest must not contain real Sprout mappings")
		quit(1)
		return
	# Loading activation must never crash with the pack absent.
	ArtActivation.reload()
	if ArtActivation.licensed_count() < 0:
		push_error("ArtActivation.licensed_count regressed")
		quit(1)
		return
	# If the LOCAL Sprout manifest is present, inspect it best-effort only. Missing
	# or corrupt local files should report as optional readiness issues, not fail
	# project validation or block fallback boot.
	if FileAccess.file_exists(ArtActivation.LICENSED_MANIFEST_PATH):
		if not FileAccess.file_exists("res://licensed_assets/sprout_lands/CREDIT_AND_LICENSE.txt"):
			push_warning("Optional Sprout pack metadata is missing: CREDIT_AND_LICENSE.txt")
		var sprout_local: Variant = JSON.parse_string(FileAccess.get_file_as_string(ArtActivation.LICENSED_MANIFEST_PATH))
		if typeof(sprout_local) == TYPE_DICTIONARY and typeof((sprout_local as Dictionary).get("active", null)) == TYPE_DICTIONARY:
			for sprout_key in (sprout_local as Dictionary)["active"].keys():
				var sprout_value: String = String((sprout_local as Dictionary)["active"][sprout_key])
				var sprout_full: String = sprout_value if sprout_value.begins_with("res://") else ArtActivation.LICENSED_NORMALIZED_ROOT + sprout_value
				if not FileAccess.file_exists(sprout_full):
					push_warning("Optional Sprout manifest maps a missing local file: %s" % sprout_full)
			# A representative object id must now resolve to the licensed file.
			if (sprout_local as Dictionary)["active"].has("objects/decor/sign.png"):
				if ObjectArtRegistry.source_of(ObjectArtRegistry.texture_path(ContentIds.PLACEABLE_SIGNPOST, true)) != "licensed":
					push_warning("Optional Sprout id did not resolve as a licensed override")
			if (sprout_local as Dictionary)["active"].has("tiles/biomes/meadow.png"):
				if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("meadow", WorldProjection.MODE_SPROUT_TOPDOWN, true)) != "licensed":
					push_warning("Optional Sprout terrain did not resolve as a licensed override in top-down mode")
				if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("meadow", WorldProjection.MODE_ISO_64X32)) == "licensed":
					push_error("Active Sprout terrain leaked into legacy iso mode")
					quit(1)
					return
			for reviewed_sprout_terrain in ["tiles/biomes/meadow.png", "tiles/water/water.png", "tiles/water/creek.png"]:
				if not (sprout_local as Dictionary)["active"].has(reviewed_sprout_terrain):
					push_warning("Optional Sprout manifest is missing reviewed top-down terrain id: %s" % reviewed_sprout_terrain)
	if FileAccess.file_exists(UIArtRegistry.LOCAL_UI_MANIFEST_PATH):
		var ui_local: Variant = JSON.parse_string(FileAccess.get_file_as_string(UIArtRegistry.LOCAL_UI_MANIFEST_PATH))
		if typeof(ui_local) != TYPE_DICTIONARY:
			push_warning("Optional Sprout UI manifest does not parse")
		else:
			for active_ui_id in ((ui_local as Dictionary).get("active", {}) as Dictionary).keys():
				var active_ui_path: String = String(((ui_local as Dictionary).get("active", {}) as Dictionary)[active_ui_id])
				var resolved_ui_path := active_ui_path if active_ui_path.begins_with("res://") else UIArtRegistry.LOCAL_UI_ROOT + active_ui_path
				if not FileAccess.file_exists(resolved_ui_path):
					push_warning("Optional Sprout UI manifest maps a missing file: %s" % resolved_ui_path)
			if typeof((ui_local as Dictionary).get("candidates", null)) == TYPE_DICTIONARY and UIArtRegistry.candidate_count() == 0:
				push_warning("Optional Sprout UI candidates exist but UIArtRegistry did not load them")
	if FileAccess.file_exists("res://licensed_assets/sprout_lands/manifests/animations_inventory.json"):
		var animation_inventory: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://licensed_assets/sprout_lands/manifests/animations_inventory.json"))
		if typeof(animation_inventory) != TYPE_DICTIONARY or typeof((animation_inventory as Dictionary).get("categories", null)) != TYPE_DICTIONARY:
			push_warning("Optional Sprout animation inventory does not parse")
	if FileAccess.file_exists("res://licensed_assets/sprout_lands/original/Sprout Sorry pack.zip"):
		if not FileAccess.file_exists("res://licensed_assets/sprout_lands/manifests/audio_inventory.json"):
			push_warning("Optional Sprout Sorry pack is present but audio_inventory.json was not cataloged")
		else:
			var audio_inventory: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://licensed_assets/sprout_lands/manifests/audio_inventory.json"))
			if typeof(audio_inventory) != TYPE_DICTIONARY or typeof((audio_inventory as Dictionary).get("files", null)) != TYPE_ARRAY or int((audio_inventory as Dictionary).get("count", 0)) <= 0:
				push_warning("Optional Sprout Sorry audio inventory does not parse")
		if not FileAccess.file_exists("res://licensed_assets/sprout_lands/contact_sheets/sorry/sorry_overview.png"):
			push_warning("Optional Sprout Sorry pack is present but Sorry contact sheets were not cataloged")
	if not FileAccess.file_exists("res://docs/examples/sprout_animation_manifest.example.json"):
		push_error("Tracked Sprout animation manifest example is missing")
		quit(1)
		return
	if not FileAccess.file_exists("res://docs/examples/sprout_audio_inventory.example.json"):
		push_error("Tracked Sprout audio inventory example is missing")
		quit(1)
		return
	var git_tracked_output: Array = []
	var git_tracked_code: int = OS.execute("git", ["ls-files", "licensed_assets"], git_tracked_output, true)
	if git_tracked_code == 0 and not "\n".join(git_tracked_output).strip_edges().is_empty():
		push_error("licensed_assets contains tracked files; Sprout assets must stay gitignored")
		quit(1)
		return
	var tracked_files_output: Array = []
	var tracked_files_code: int = OS.execute("git", ["ls-files"], tracked_files_output, true)
	if tracked_files_code == 0:
		var tracked_lines: PackedStringArray = "\n".join(tracked_files_output).split("\n", false)
		for tracked_path_variant in tracked_lines:
			var tracked_path: String = String(tracked_path_variant).replace("\\", "/")
			var lower_tracked_path: String = tracked_path.to_lower()
			if lower_tracked_path.begins_with("licensed_assets/"):
				push_error("Tracked file lives under licensed_assets/: %s" % tracked_path)
				quit(1)
				return
			if lower_tracked_path.contains("sprout") and (
				lower_tracked_path.ends_with(".png") or lower_tracked_path.ends_with(".zip")
				or lower_tracked_path.ends_with(".aseprite") or lower_tracked_path.ends_with(".gif")
				or lower_tracked_path.ends_with(".wav") or lower_tracked_path.ends_with(".ogg")
				or lower_tracked_path.ends_with(".mp3")
			):
				push_error("Tracked Sprout media/raw asset is forbidden: %s" % tracked_path)
				quit(1)
				return
	var tracked_activation_manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://art/active_art_manifest.json"))
	if typeof(tracked_activation_manifest) == TYPE_DICTIONARY:
		for active_key in ((tracked_activation_manifest as Dictionary).get("active", {}) as Dictionary).keys():
			var active_path_for_check: String = String(((tracked_activation_manifest as Dictionary).get("active", {}) as Dictionary)[active_key])
			if active_path_for_check.begins_with("res://licensed_assets/") or active_path_for_check.begins_with("licensed_assets/"):
				push_error("Tracked active_art_manifest points at licensed_assets/: %s" % active_path_for_check)
				quit(1)
				return
	# Original Hearthvale generated UI gap-fill must resolve (generated or licensed).
	if UIArtRegistry.source_of(UIArtRegistry.texture_path("panel")) == "missing":
		push_error("UIArtRegistry has no generated/licensed panel art to resolve")
		quit(1)
		return
	# No generated terrain path may live under (or point into) licensed_assets/.
	for hv_id in ["meadow", "farmland", "dirt_path", "plot_boundary", "stone_path"]:
		var hv_path: String = TerrainArtRegistry.texture_path(hv_id, WorldProjection.MODE_SPROUT_TOPDOWN)
		if TerrainArtRegistry.source_of(hv_path) == "generated" and hv_path.begins_with("res://licensed_assets/"):
			push_error("A generated terrain path points into licensed_assets/: %s" % hv_path)
			quit(1)
			return
	# When the local Sprout pack IS installed and fully ready, the modified tints +
	# object overrides + UI should report their dedicated source tiers. If the local
	# pack is partial/corrupt, warn only; generated fallbacks must still validate.
	var optional_sprout_requirement: Dictionary = SproutAssetRequirement.check()
	if FileAccess.file_exists(ArtActivation.LICENSED_MANIFEST_PATH) and bool(optional_sprout_requirement["ok"]):
		ArtActivation.reload()
		if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("forest", WorldProjection.MODE_SPROUT_TOPDOWN, true)) != "licensed_modified":
			push_error("Active Sprout modified terrain tint did not resolve as licensed_modified")
			quit(1)
			return
		if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("forest", WorldProjection.MODE_ISO_64X32)) == "licensed_modified":
			push_error("Licensed_modified terrain leaked into legacy iso mode")
			quit(1)
			return
		if ObjectArtRegistry.source_of(ObjectArtRegistry.texture_path(ContentIds.PLACEABLE_WORKBENCH, true)) != "licensed":
			push_error("Active Sprout object override (workbench) did not resolve as licensed")
			quit(1)
			return
	UIArtRegistry.reload()
	if FileAccess.file_exists(UIArtRegistry.LOCAL_UI_MANIFEST_PATH) and UIArtRegistry.active_count() > 0 and bool(optional_sprout_requirement["ok"]):
		if not UIArtRegistry.has_licensed("panel", true) or UIArtRegistry.source_of(UIArtRegistry.texture_path("panel", true)) != "licensed_ui":
			push_error("Activated Sprout UI panel did not resolve as licensed_ui")
			quit(1)
			return
		if UIArtRegistry.texture_stylebox("panel", 10, true) == null:
			push_error("CozyUITheme could not build a Sprout UI nine-patch for an active panel")
			quit(1)
			return
	# Generated fallback must still resolve regardless (no licensed override for it).
	if TerrainArtRegistry.source_of(TerrainArtRegistry.texture_path("farmer_training")) != "generated":
		push_error("Generated fallback regressed for an un-activated terrain id")
		quit(1)
		return

	# --- Optional Sprout / fallback boot policy ---------------------------------
	# Sprout must not be a hard runtime dependency. Missing/corrupt local Sprout
	# should report readiness false and continue through generated/procedural fallback.
	if LiveVisualPolicy.SPROUT_REQUIRED_FOR_LIVE or SproutAssetRequirement.REQUIRED:
		push_error("Sprout must be optional; live boot cannot require Sprout assets")
		quit(1)
		return
	# The optional readiness check must run and return a well-formed result.
	var sprout_requirement: Dictionary = SproutAssetRequirement.check()
	if typeof(sprout_requirement.get("missing", null)) != TYPE_ARRAY or typeof(sprout_requirement.get("ok", null)) != TYPE_BOOL:
		push_error("SproutAssetRequirement.check() did not return a well-formed result")
		quit(1)
		return
	if not bool(sprout_requirement["ok"]) and not String(sprout_requirement["summary"]).contains("optional"):
		push_error("Missing Sprout readiness must be reported as optional, not blocking")
		quit(1)
		return
	var region_manager_src: String = FileAccess.get_file_as_string("res://systems/world_region_manager.gd")
	var starting_func_index: int = region_manager_src.find("func _load_starting_region")
	var missing_screen_func_index: int = region_manager_src.find("func _show_missing_assets_screen")
	if starting_func_index < 0 or missing_screen_func_index <= starting_func_index:
		push_error("WorldRegionManager starting-region/fallback structure changed unexpectedly")
		quit(1)
		return
	var starting_region_src: String = region_manager_src.substr(starting_func_index, missing_screen_func_index - starting_func_index)
	if starting_region_src.contains("_show_missing_assets_screen"):
		push_error("WorldRegionManager still blocks boot behind a missing-assets screen")
		quit(1)
		return
	if starting_region_src.contains("[sprout-required]") or starting_region_src.contains("[limezu-required]"):
		push_error("WorldRegionManager still logs preferred art packs as required")
		quit(1)
		return
	if not starting_region_src.contains("[visual-fallback]"):
		push_error("WorldRegionManager must warn non-blockingly when preferred art is missing")
		quit(1)
		return
	if not starting_region_src.contains("_load_region(OVERWORLD_REGION_ID, \"default\")"):
		push_error("WorldRegionManager must always fall through to loading the overworld")
		quit(1)
		return
	var missing_assets_screen_src: String = FileAccess.get_file_as_string("res://ui/missing_assets_screen.gd")
	if missing_assets_screen_src.contains("Sprout assets required") or missing_assets_screen_src.contains("will not load"):
		push_error("MissingAssetsScreen still contains blocking Sprout-required language")
		quit(1)
		return

	# --- Live visual source enforcement (no old graphics in sprout_topdown) -----
	if load("res://systems/visual_source_report.gd") == null:
		push_error("VisualSourceReport helper failed to load")
		quit(1)
		return
	if not VisualSourceReport.is_clean(WorldProjection.MODE_SPROUT_TOPDOWN):
		var bad: Dictionary = VisualSourceReport.registry_summary(WorldProjection.MODE_SPROUT_TOPDOWN)
		push_error("Live sprout_topdown resolves LEGACY old art: terrain=%s objects=%s" % [bad["terrain_legacy_in_live"], bad["object_legacy_in_live"]])
		quit(1)
		return
	# Non-licensed objects must resolve to original Hearthvale top-down art, never
	# the old art/objects/ 96px placeholders.
	var crate_live_path: String = ObjectArtRegistry.texture_path(ContentIds.PLACEABLE_CRATE)
	if ObjectArtRegistry.source_of(crate_live_path) == "generated" and not crate_live_path.begins_with(ObjectArtRegistry.HEARTHVALE_OBJECT_ROOT):
		push_error("Generated object fallback still points at old art/objects/: %s" % crate_live_path)
		quit(1)
		return
	# Required original Hearthvale top-down fallback assets must exist (committable).
	for hearthvale_asset in ["res://art/generated/hearthvale/terrain/meadow.png", "res://art/generated/hearthvale/terrain/dirt_path.png", "res://art/generated/hearthvale/objects/nature/tree.png", "res://art/generated/hearthvale/objects/building/crate.png"]:
		if not FileAccess.file_exists(hearthvale_asset):
			push_error("Required generated Hearthvale fallback asset missing: %s" % hearthvale_asset)
			quit(1)
			return
	for hearthvale_actor_asset in ["res://art/generated/hearthvale/characters/player.png", "res://art/generated/hearthvale/characters/maribel_tock.png", "res://art/generated/hearthvale/characters/bram_nettle.png", "res://art/generated/hearthvale/creatures/moss_rabbit.png"]:
		if not FileAccess.file_exists(hearthvale_actor_asset):
			push_error("Required generated Hearthvale actor asset missing: %s" % hearthvale_actor_asset)
			quit(1)
			return
	for live_terrain_id_variant in TerrainArtRegistry.required_ids():
		var live_terrain_id: String = String(live_terrain_id_variant)
		var live_topdown_path: String = TerrainArtRegistry.texture_path(live_terrain_id, WorldProjection.MODE_SPROUT_TOPDOWN)
		if TerrainArtRegistry.source_of(live_topdown_path) == "generated" and not live_topdown_path.begins_with(TerrainArtRegistry.HEARTHVALE_TOPDOWN_ROOT):
			push_error("Live generated terrain id '%s' is not using art/generated/hearthvale/: %s" % [live_terrain_id, live_topdown_path])
			quit(1)
			return
	# Live map scripts must route decoration/terrain through the registry + skip the
	# covering procedural fills (no hardcoded old texture paths drawn over sprites).
	var hmap_src: String = FileAccess.get_file_as_string("res://world/homestead_map.gd")
	if not hmap_src.contains("_decor_sprite") or not hmap_src.contains("_use_object_sprites"):
		push_error("HomesteadMap does not route world decoration through the object registry")
		quit(1)
		return
	var omap_src: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	if not omap_src.contains("_bg_layer"):
		push_error("OverworldMap does not push background scenery below the terrain tiles")
		quit(1)
		return
	if hmap_src.contains("res://art/tiles/") or hmap_src.contains("res://art/objects/") or omap_src.contains("res://art/tiles/") or omap_src.contains("res://art/objects/"):
		push_error("Live map scripts must not hardcode legacy art/tiles or art/objects paths")
		quit(1)
		return
	if not omap_src.contains("LiveVisualPolicy.terrain_for_plot_ground") or not omap_src.contains("LiveVisualPolicy.should_draw_broad_procedural_scenery"):
		push_error("OverworldMap is not using the top-down live visual policy")
		quit(1)
		return
	var compact_hud_scene := load("res://ui/prototype_hud.tscn") as PackedScene
	var compact_hud_probe: Node = compact_hud_scene.instantiate()
	var compact_hud_panel: Control = compact_hud_probe.get_node_or_null("Panel") as Control
	var compact_hud_identity: CanvasItem = compact_hud_probe.get_node_or_null("Panel/Rows/IdentityLabel") as CanvasItem
	if compact_hud_panel == null or not LiveVisualPolicy.normal_hud_is_compact(compact_hud_panel.custom_minimum_size):
		push_error("Normal HUD is not compact enough for the top-down live presentation")
		compact_hud_probe.free()
		quit(1)
		return
	if compact_hud_identity == null or compact_hud_identity.visible:
		push_error("Normal HUD still shows identity/debug-style details by default")
		compact_hud_probe.free()
		quit(1)
		return
	var compact_hud_source: String = FileAccess.get_file_as_string("res://ui/prototype_hud.gd")
	var compact_hud_scene_source: String = FileAccess.get_file_as_string("res://ui/prototype_hud.tscn")
	for compact_hint in ["Esc Menu", "I Inv", "B Build", "E Edit", "M Map", "H Help", "F11 Window"]:
		if not compact_hud_source.contains(compact_hint) or not compact_hud_scene_source.contains(compact_hint):
			push_error("Normal HUD controls line is missing compact LimeZu hint '%s'" % compact_hint)
			compact_hud_probe.free()
			quit(1)
			return
	if compact_hud_source.contains("F11 Full") or compact_hud_scene_source.contains("Fullscreen F11"):
		push_error("Normal HUD controls line still uses the long fullscreen copy that wraps/clips")
		compact_hud_probe.free()
		quit(1)
		return
	for legacy_icon_path in [
		"Panel/Rows/DayRow/DayIcon",
		"Panel/Rows/ComfortRow/ComfortIcon",
		"Panel/Rows/InvRow/InvIcon",
		"Panel/Rows/InvRow/CarrotIcon",
		"Panel/Rows/InvRow/TurnipIcon",
		"Panel/Rows/InvRow/BerryIcon",
	]:
		var legacy_icon: CanvasItem = compact_hud_probe.get_node_or_null(String(legacy_icon_path)) as CanvasItem
		if legacy_icon != null and legacy_icon.visible:
			push_error("Normal HUD still shows old generated SVG prototype icon: %s" % String(legacy_icon_path))
			compact_hud_probe.free()
			quit(1)
			return
	compact_hud_probe.free()
	# HUD readability: the HUD/minimap/prompt card must keep a solid, dark, mostly
	# opaque backing so its cream text stays readable over the bright world. (The
	# regression was the HUD swapping to the pale Sprout parchment panel.)
	# In SPROUT mode the HUD keeps a solid dark StyleBoxFlat (cream text readability).
	# In LimeZu live mode the HUD must use the Modern UI texture (checked below).
	if not LiveVisualPolicy.live_limezu_slice():
		var hud_style_probe: PanelContainer = PanelContainer.new()
		CozyUITheme.apply_hud_panel(hud_style_probe)
		var hud_box: StyleBox = hud_style_probe.get_theme_stylebox("panel")
		if not (hud_box is StyleBoxFlat):
			push_error("HUD panel backing is not a solid StyleBoxFlat (readability regressed)")
			hud_style_probe.free()
			quit(1)
			return
		var hud_bg: Color = (hud_box as StyleBoxFlat).bg_color
		var hud_luma: float = 0.299 * hud_bg.r + 0.587 * hud_bg.g + 0.114 * hud_bg.b
		if hud_bg.a < 0.85 or hud_luma > 0.45:
			push_error("HUD panel backing is too pale/transparent for readable text (a=%.2f luma=%.2f)" % [hud_bg.a, hud_luma])
			hud_style_probe.free()
			quit(1)
			return
		hud_style_probe.free()
	var chat_scene: PackedScene = load("res://ui/chat_panel.tscn") as PackedScene
	if chat_scene == null:
		push_error("Chat panel scene failed to load")
		quit(1)
		return
	var chat_probe: CanvasLayer = chat_scene.instantiate() as CanvasLayer
	get_root().add_child(chat_probe)
	await process_frame
	var chat_panel_node: Control = chat_probe.get_node_or_null("Panel") as Control
	if chat_panel_node == null:
		push_error("Chat panel is missing its Panel node")
		chat_probe.queue_free()
		quit(1)
		return
	if chat_panel_node.visible:
		push_error("Empty chat panel should be hidden in the live opening screenshot")
		chat_probe.queue_free()
		quit(1)
		return
	chat_probe.call("add_system_line", "Validator toast")
	if not chat_panel_node.visible:
		push_error("Chat panel did not reappear when a system line was added")
		chat_probe.queue_free()
		quit(1)
		return
	var chat_source: String = FileAccess.get_file_as_string("res://ui/chat_panel.gd")
	for chat_snippet in ["CozyUITheme.apply_hud_panel", "_refresh_panel_visibility", "_panel.visible = _input.visible or _log_box.get_child_count() > 0"]:
		if not chat_source.contains(chat_snippet):
			push_error("Chat panel is missing compact LimeZu/HUD polish snippet '%s'" % chat_snippet)
			chat_probe.queue_free()
			quit(1)
			return
	chat_probe.queue_free()
	await process_frame
	# Signs/objects must render as a SINGLE sprite, never a tiled/region texture (the
	# "repeating sign graphics" guard).
	var sign_sprite_probe: Sprite2D = ObjectArtRegistry.make_sprite(ContentIds.PLACEABLE_SIGNPOST)
	if sign_sprite_probe == null or sign_sprite_probe.texture == null:
		push_error("Signpost object sprite failed to build")
		if sign_sprite_probe != null:
			sign_sprite_probe.free()
		quit(1)
		return
	if sign_sprite_probe.region_enabled or sign_sprite_probe.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED:
		push_error("Signpost sprite is set to region/repeat (would tile the sign graphic)")
		sign_sprite_probe.free()
		quit(1)
		return
	sign_sprite_probe.free()
	# Plot signs must not float a permanent title label (declutter): the builder keeps
	# the name as metadata + the interaction prompt, not an always-on Label.
	var plot_sign_src: String = FileAccess.get_file_as_string("res://world/overworld_controller.gd")
	if plot_sign_src.contains("plate.text = title"):
		push_error("Plot sign still floats a permanent title label (clutter regressed)")
		quit(1)
		return

	# --- Curated demo slice (opening view is composed, not the broad overworld) ---
	if not LiveVisualPolicy.CURATED_SLICE:
		push_error("Curated demo slice must be enabled for the live opening view")
		quit(1)
		return
	if LiveVisualPolicy.CURATED_SLICE_ZOOM < LiveVisualPolicy.OVERWORLD_WIDE_ZOOM:
		push_error("Curated slice opening zoom must frame tighter than the wide overworld view")
		quit(1)
		return
	var curated_map_probe: OverworldMap = OverworldMap.new()
	if not curated_map_probe.has_method("_build_curated_slice"):
		push_error("OverworldMap is missing the curated slice builder")
		curated_map_probe.free()
		quit(1)
		return
	if curated_map_probe.get_camera_zoom() != Vector2(LiveVisualPolicy.CURATED_SLICE_ZOOM, LiveVisualPolicy.CURATED_SLICE_ZOOM):
		push_error("Overworld opening camera is not using the curated slice zoom")
		curated_map_probe.free()
		quit(1)
		return
	curated_map_probe.free()
	var overworld_map_src: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	if not overworld_map_src.contains("LiveVisualPolicy.CURATED_SLICE") or not overworld_map_src.contains("_build_curated_slice"):
		push_error("OverworldMap does not gate the broad overworld layers behind the curated slice")
		quit(1)
		return

	# --- Inventory window (closed by default, compact, Sprout-styled, readable) ----
	var inventory_scene := load("res://ui/inventory_panel.tscn") as PackedScene
	var inventory_probe: CanvasLayer = inventory_scene.instantiate() as CanvasLayer
	get_root().add_child(inventory_probe)
	await process_frame
	if inventory_probe.visible:
		push_error("Inventory panel is open by default (must start closed)")
		inventory_probe.queue_free()
		quit(1)
		return
	var inventory_panel_node: Control = inventory_probe.get_node_or_null("Panel") as Control
	if inventory_panel_node == null:
		push_error("Inventory panel root is missing")
		inventory_probe.queue_free()
		quit(1)
		return
	# Window must stay within a reasonable fraction of the viewport (no parchment wall).
	var inventory_w: float = inventory_panel_node.offset_right - inventory_panel_node.offset_left
	var inventory_h: float = inventory_panel_node.offset_bottom - inventory_panel_node.offset_top
	if inventory_w <= 0.0 or inventory_w > 480.0 or inventory_h <= 0.0 or inventory_h > 600.0:
		push_error("Inventory window is too large (%.0fx%.0f); keep it a compact fraction of the viewport" % [inventory_w, inventory_h])
		inventory_probe.queue_free()
		quit(1)
		return
	# Esc/close-button behavior + LimeZu/Sprout styling, not hardcoded panel art.
	var inventory_src: String = FileAccess.get_file_as_string("res://ui/inventory_panel.gd")
	for inventory_snippet in ["cancel_action", "close_panel", "CozyUITheme.apply_inventory_panel", "slot_texture_style", "apply_close_button", "ObjectArtRegistry.icon_texture_for_item"]:
		if not inventory_src.contains(inventory_snippet):
			push_error("Inventory panel is missing required behavior/styling: %s" % inventory_snippet)
			inventory_probe.queue_free()
			quit(1)
			return
	for inventory_readability_snippet in [
		"grid.add_theme_constant_override(\"h_separation\", 5)",
		"grid.columns = 4",
		"LimeZuUITheme.slot_texture_style(false)",
		"apply_slot_icon_layout",
		"Hover an item for details.",
		"_detail_label",
	]:
		if not inventory_src.contains(inventory_readability_snippet):
			push_error("Inventory panel is missing LimeZu readable-slot layout guard: %s" % inventory_readability_snippet)
			inventory_probe.queue_free()
			quit(1)
			return
	var inventory_scene_src: String = FileAccess.get_file_as_string("res://ui/inventory_panel.tscn")
	if not inventory_scene_src.contains("offset_left = -348.0"):
		push_error("Inventory panel width is not using the asset-sized 1280px layout")
		inventory_probe.queue_free()
		quit(1)
		return
	if inventory_src.contains("StyleBoxTexture.new(") or inventory_src.contains("preload(\"res://art/"):
		push_error("Inventory panel hardcodes texture/panel art instead of routing through CozyUITheme/UIArtRegistry")
		inventory_probe.queue_free()
		quit(1)
		return
	inventory_probe.queue_free()
	await process_frame

	# --- LimeZu is now the LIVE visual provider; Sprout stays secondary/comparison ---
	if ArtProviderRegistry.LIVE_PROVIDER != ArtProviderRegistry.PROVIDER_LIMEZU:
		push_error("Live art provider should be LimeZu after the pivot")
		quit(1)
		return
	# Sprout must remain integrated as a secondary/comparison provider (not deleted).
	if not ArtProviderRegistry.is_known(ArtProviderRegistry.PROVIDER_SPROUT) or load("res://systems/visual/sprout_asset_requirement.gd") == null:
		push_error("Sprout provider/integration was removed — it must stay as a secondary provider")
		quit(1)
		return
	if not ArtProviderRegistry.is_known(ArtProviderRegistry.PROVIDER_LIMEZU):
		push_error("ArtProviderRegistry does not list the LimeZu provider")
		quit(1)
		return
	# The live overworld map must have the LimeZu curated-slice builder.
	var overworld_map_src_live: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	if not overworld_map_src_live.contains("_build_limezu_slice"):
		push_error("OverworldMap is missing the LimeZu curated slice builder")
		quit(1)
		return
	# When LimeZu is installed and usable, the live slice must actually resolve LimeZu art.
	var limezu_readiness: Dictionary = LimeZuArtRegistry.readiness()
	var limezu_provider_status: Dictionary = ArtProviderRegistry.status()
	var limezu_world_inputs_present: bool = LimeZuArtRegistry.pack_present("modern_farm") \
		or LimeZuArtRegistry.pack_present("modern_exteriors") \
		or GeneratorAssetResolver.available()
	if LimeZuArtRegistry.is_usable_for_live() and not LiveVisualPolicy.live_limezu_slice():
		push_error("LimeZu is usable for live mode but live_limezu_slice() is false")
		quit(1)
		return
	if limezu_world_inputs_present and not LimeZuArtRegistry.is_usable_for_live():
		push_error("Local LimeZu world inputs are present but readiness is not usable: %s" % str(limezu_readiness))
		quit(1)
		return
	if limezu_world_inputs_present and String(limezu_provider_status.get("selected_live_provider", "")) != ArtProviderRegistry.PROVIDER_LIMEZU:
		push_error("Local LimeZu world inputs are present but selected provider is %s" % String(limezu_provider_status.get("selected_live_provider", "")))
		quit(1)
		return
	if typeof(limezu_readiness.get("tier", null)) != TYPE_STRING \
			or typeof(limezu_readiness.get("resolved_live_ids", null)) != TYPE_ARRAY \
			or typeof(limezu_readiness.get("direct_missing_ids", null)) != TYPE_ARRAY:
		push_error("LimeZuArtRegistry.readiness() did not return the expected structured status")
		quit(1)
		return
	# --- LimeZu generator tooling (style analyzer + derivative + inspired) ----------
	# These run regardless of whether the live LimeZu opening art is installed.
	for gen_tool in [
		"res://tools/art/limezu_style_analyzer.py",
		"res://tools/art/limezu_derivative_generator.py",
		"res://tools/art/limezu_inspired_generator.py",
		"res://tools/art/limezu_generator_catalog.py",
		"res://systems/art/generator_asset_resolver.gd",
	]:
		if not FileAccess.file_exists(gen_tool):
			push_error("Missing LimeZu generator tool/helper: %s" % gen_tool)
			quit(1)
			return
	# The resolver must be SAFE whether or not the local manifests/PNGs exist: an
	# unknown id always returns "" so a clean checkout never depends on dev outputs.
	GeneratorAssetResolver.reload()
	if GeneratorAssetResolver.resolve("__definitely_not_a_real_generator_id__") != "":
		push_error("GeneratorAssetResolver must return \"\" for an unknown id")
		quit(1)
		return
	if typeof(GeneratorAssetResolver.available()) != TYPE_BOOL:
		push_error("GeneratorAssetResolver.available() must return a bool")
		quit(1)
		return
	# If a derivative manifest is present, it must parse and its entries must resolve
	# to existing local PNGs (priority: derivative before inspired).
	if FileAccess.file_exists(GeneratorAssetResolver.DERIVATIVE_MANIFEST):
		var deriv_parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GeneratorAssetResolver.DERIVATIVE_MANIFEST))
		if typeof(deriv_parsed) != TYPE_DICTIONARY or typeof((deriv_parsed as Dictionary).get("entries", null)) != TYPE_DICTIONARY:
			push_error("Derivative manifest present but does not parse with an entries map")
			quit(1)
			return
		var deriv_entries: Dictionary = (deriv_parsed as Dictionary)["entries"]
		if not deriv_entries.is_empty():
			var first_deriv_id: String = String(deriv_entries.keys()[0])
			if GeneratorAssetResolver.resolve(first_deriv_id).is_empty():
				push_error("Derivative manifest entry did not resolve to a present PNG: %s" % first_deriv_id)
				quit(1)
				return
	if GeneratorAssetResolver.available():
		for live_alias_id in ["terrain.dirt_path", "object.crate", "ui.panel"]:
			if GeneratorAssetResolver.resolve(live_alias_id).is_empty():
				push_error("GeneratorAssetResolver must bridge live logical id '%s' to a local output when manifests are present" % live_alias_id)
				quit(1)
				return
	# LimeZu registry must still fail safe (loadable path) for an unmapped logical id,
	# and the resolver fallback must not break that.
	if not FileAccess.file_exists(LimeZuArtRegistry.texture_path("__no_such_logical_id__")):
		push_error("LimeZuArtRegistry must fail safe to a loadable path even with the generator fallback")
		quit(1)
		return
	if limezu_world_inputs_present:
		for live_core_id in ["terrain.grass", "terrain.dirt_path", "object.tree", "object.fence_horizontal", "object.barn", "character.farmer_idle"]:
			if not LimeZuArtRegistry.has_asset(live_core_id):
				push_error("Local LimeZu inputs are present but live core id does not resolve: %s" % live_core_id)
				quit(1)
				return
	# Generator outputs + manifests live under the gitignored licensed_assets/ tree.
	# --- Strict LimeZu live allowlist (deterministic registry check) ---------------
	# Every id the live opening spawns must resolve to an allowed LimeZu-family tier,
	# the HUD status icons must be semantic (never a blank/slot frame), and the distinct
	# world props must NOT collapse onto one shared texture. That last guard is what the
	# scene audit missed: the giant fence-post scatter classified as a valid
	# 'limezu_derivative' tier, so only the bad-generic-mapping check catches it.
	if LiveVisualPolicy.live_limezu_slice():
		var live_world_ids: Array[String] = [
			"terrain.grass", "terrain.dirt_path", "terrain.tilled_soil",
			"object.barn", "object.tree", "object.tree_small",
			"object.fence_horizontal", "object.fence_vertical", "object.fence_post",
			"object.flower", "object.flower2", "object.flower3", "object.crate", "object.sign",
			"crop.carrot", "crop.carrot_stage1",
			"character.farmer_idle", "animal.chicken", "animal.cow",
		]
		for live_id in live_world_ids:
			var live_path: String = LimeZuArtRegistry.texture_path(live_id)
			var live_tier: String = VisualSourceReport.classify_texture(live_path)
			if not LiveVisualPolicy.is_allowed_live_tier(live_tier):
				push_error("Live id '%s' resolves to disallowed source tier '%s' (%s)" % [live_id, live_tier, live_path])
				quit(1)
				return
		# Bad-generic-mapping guard: distinct props must not share one texture (the
		# fence-post regression had many object ids -> one derivative cell).
		var distinct_obj_ids: Array[String] = [
			"object.fence_horizontal", "object.fence_vertical", "object.fence_post",
			"object.crate", "object.tree", "object.barn",
			"object.flower", "object.flower2", "object.flower3", "object.tree_small",
		]
		var path_to_ids: Dictionary = {}
		for obj_id in distinct_obj_ids:
			var op: String = LimeZuArtRegistry.texture_path(obj_id)
			var bucket: Array = path_to_ids.get(op, [])
			bucket.append(obj_id)
			path_to_ids[op] = bucket
		for shared_path in path_to_ids:
			if (path_to_ids[shared_path] as Array).size() >= 3:
				push_error("Generic-mapping regression: %d unrelated object ids share one texture %s -> %s" % [(path_to_ids[shared_path] as Array).size(), str(shared_path), str(path_to_ids[shared_path])])
				quit(1)
				return
		# HUD status icons must be semantic LimeZu-family icons, never a blank/slot frame.
		for hud_icon_id in ["icon.day", "icon.comfort"]:
			var hud_path: String = LimeZuArtRegistry.texture_path(hud_icon_id)
			var hud_tier: String = VisualSourceReport.classify_texture(hud_path)
			if not LiveVisualPolicy.is_allowed_live_tier(hud_tier):
				push_error("HUD status icon '%s' resolves to disallowed tier '%s' (%s)" % [hud_icon_id, hud_tier, hud_path])
				quit(1)
				return
			var hud_low: String = hud_path.to_lower()
			if hud_path.is_empty() or hud_low.contains("slot") or hud_low.contains("missing"):
				push_error("HUD status icon '%s' resolves to a blank/slot texture: %s" % [hud_icon_id, hud_path])
				quit(1)
				return
		# --- Object contract coverage (Task 2): every interactive contract has a prompt and a
		# real action route (no blank/silent F prompts), and the previously pass-through crate
		# is now a solid, interactable storage prop with a collider to build. ---
		for contract_id in AssetWorldMetadata.interactable_ids():
			if AssetWorldMetadata.interaction_prompt(contract_id).is_empty():
				push_error("Interactive object '%s' has interaction_enabled but no prompt (blank F prompt)" % contract_id)
				quit(1)
				return
			if AssetWorldMetadata.has_toast_interaction(contract_id) and AssetWorldMetadata.interaction_response(contract_id).is_empty():
				push_error("Toast-interaction object '%s' shows a prompt but has no response text (silent F)" % contract_id)
				quit(1)
				return
		if not (AssetWorldMetadata.is_blocking("object.crate") \
				and AssetWorldMetadata.interaction_enabled("object.crate") \
				and not AssetWorldMetadata.interaction_response("object.crate").is_empty()):
			push_error("object.crate must be a solid, interactable contract (blocks + F + response), not pass-through decor")
			quit(1)
			return
		if not AssetWorldMetadata.has_asset_collision_shapes("object.crate"):
			push_error("object.crate is blocking but has no collision_shapes to build a collider from")
			quit(1)
			return

		# --- Actor identity (character-identity pass): named actors must be visually distinct.
		# Each required profile exists + resolves to a LimeZu-family character sheet; player and
		# Rowan never share a signature; the named actors don't all collapse to one signature; and
		# the player customization default profile is present. ---
		for required_actor in CharacterProfileRegistry.required_profile_ids():
			if not CharacterProfileRegistry.has(required_actor):
				push_error("Required actor profile missing: %s" % required_actor)
				quit(1)
				return
			var actor_sheet: String = CharacterProfileRegistry.sheet_id(required_actor)
			var actor_path: String = LimeZuArtRegistry.texture_path(actor_sheet)
			var actor_tier: String = VisualSourceReport.classify_texture(actor_path)
			if actor_path.is_empty() or actor_tier == "missing" or actor_tier == "blank":
				push_error("Actor '%s' visual is missing/blank (%s)" % [required_actor, actor_path])
				quit(1)
				return
			if actor_tier == "sprout" or not LiveVisualPolicy.is_allowed_live_tier(actor_tier):
				push_error("Actor '%s' visual tier '%s' is not LimeZu-family (%s)" % [required_actor, actor_tier, actor_path])
				quit(1)
				return
		if CharacterProfileRegistry.signature("player") == CharacterProfileRegistry.signature("rowan"):
			push_error("Player and Farmer Rowan share an identical actor signature (cloning regressed)")
			quit(1)
			return
		var actor_sig_set := {}
		for req_actor in CharacterProfileRegistry.required_profile_ids():
			actor_sig_set[CharacterProfileRegistry.signature(req_actor)] = true
		if actor_sig_set.size() < CharacterProfileRegistry.required_profile_ids().size():
			push_error("Named actors are not all unique — duplicate signatures among %s" % str(CharacterProfileRegistry.required_profile_ids()))
			quit(1)
			return
		if CharacterAppearance.normalized({}).is_empty() or not CharacterAppearance.default_appearance().has("outfit_color"):
			push_error("Player customization default profile is missing/incomplete")
			quit(1)
			return

		# --- Animation / facing / held-tool socket (animation pass) ---------------------
		for anim_sheet in ["character.farmer_idle", "character.farmer2_idle", "character.body2_idle"]:
			if not CharacterAnimationRegistry.has_sheet(anim_sheet):
				push_error("Character sheet '%s' has no animation/facing data" % anim_sheet)
				quit(1)
				return
			for facing in ["down", "up", "side"]:
				if CharacterAnimationRegistry.walk_frames(anim_sheet, facing).is_empty():
					push_error("Character sheet '%s' has no movement frame for facing '%s'" % [anim_sheet, facing])
					quit(1)
					return
			var rev_dirs: Array = CharacterAnimationRegistry.reviewed_directions(anim_sheet)
			if not (rev_dirs.has("down") and rev_dirs.has("up")):
				push_error("Character sheet '%s' must have reviewed down+up facing frames" % anim_sheet)
				quit(1)
				return
		for socket_facing in ["down", "up", "side"]:
			if not CharacterAnimationRegistry.has_hand_socket(socket_facing):
				push_error("Held-tool hand socket missing for facing '%s'" % socket_facing)
				quit(1)
				return

		# --- Terrain completion: the direct ids resolve to allowed LimeZu-family tiers, and grass
		# is a distinct tile (not the old mislabeled path-tile collapse). ---
		for terrain_id in ["terrain.grass", "terrain.dirt_path", "terrain.tilled_soil"]:
			var terr_tier: String = VisualSourceReport.classify_texture(LimeZuArtRegistry.texture_path(terrain_id))
			if not LiveVisualPolicy.is_allowed_live_tier(terr_tier):
				push_error("Terrain '%s' does not resolve to an allowed LimeZu-family tier (%s)" % [terrain_id, terr_tier])
				quit(1)
				return
		if LimeZuArtRegistry.texture_path("terrain.grass") == LimeZuArtRegistry.texture_path("terrain.dirt_path"):
			push_error("terrain.grass resolves to the same tile as terrain.dirt_path (grass not distinct)")
			quit(1)
			return

		# --- Animal/sign/fence/tree/building must block (no walk-through props) ----------
		for solid_world in ["animal.cow", "object.sign", "object.fence_horizontal", "object.tree", "object.barn", "object.crate"]:
			if not AssetWorldMetadata.has_asset_collision_shapes(solid_world):
				push_error("World object '%s' must have collision shapes (player can walk through it)" % solid_world)
				quit(1)
				return

	var gen_gitignore: String = FileAccess.get_file_as_string("res://.gitignore")
	if not gen_gitignore.contains("licensed_assets/"):
		push_error(".gitignore must ignore licensed_assets/ so generator outputs/manifests stay local")
		quit(1)
		return

	# --- Hard no-mixed-assets guard: boot the live opening + audit its sprite sources ---
	if LiveVisualPolicy.live_limezu_slice():
		var ow_scene := load("res://scenes/world/overworld.tscn") as PackedScene
		var ow: Node = ow_scene.instantiate()
		get_root().add_child(ow)
		await process_frame
		await process_frame
		var ow_map: Node = ow.get_node_or_null("Map")
		var opening: Dictionary = VisualSourceReport.live_opening_sources(ow_map)
		print("[visual-source] live opening sources=", opening)
		# Contracted props: the curated crate must spawn a real collider AND an interactable
		# instance — it used to be silent pass-through decor (the reported "walk-through object").
		var prop_instances: Array = ow_map.get_limezu_interactable_props() if ow_map.has_method("get_limezu_interactable_props") else []
		if prop_instances.is_empty():
			push_error("LimeZu opening exposes no interactable contract props (crate interaction regressed)")
			ow.queue_free(); quit(1); return
		if ow_map.find_child("LimeZuPropCollision*", true, false) == null:
			push_error("LimeZu opening has no contracted-prop collider (a physical prop like the crate is walk-through)")
			ow.queue_free(); quit(1); return
		print("[object-contract] interactable props=%d, prop collider present" % prop_instances.size())
		for forbidden_opening_tier in ["sprout", "missing"]:
			if int(opening.get(forbidden_opening_tier, 0)) > 0:
				push_error("LimeZu opening still instantiates %d '%s' sprite(s)" % [int(opening[forbidden_opening_tier]), forbidden_opening_tier])
				ow.queue_free(); quit(1); return
		if int(opening.get("legacy_generated", 0)) > 0:
			push_warning("Broad LimeZu map still has %d off-camera legacy/generated sprite(s); camera-filtered category audit below is authoritative for opening visuals" % int(opening["legacy_generated"]))
		var opening_limezu_count: int = _audit_limezu_family_count(opening)
		var opening_procedural_count: int = int(opening.get("procedural", 0))
		if opening_limezu_count < 1 or opening_limezu_count < opening_procedural_count:
			push_error("LimeZu opening is not LimeZu-dominant (limezu_family=%d procedural=%d)" % [opening_limezu_count, opening_procedural_count])
			ow.queue_free(); quit(1); return
		var category_audit: Dictionary = VisualSourceReport.live_opening_category_audit(ow)
		var categories: Dictionary = category_audit.get("categories", {}) as Dictionary
		var category_totals: Dictionary = category_audit.get("totals", {}) as Dictionary
		print("[visual-source] live opening category totals=", category_totals)
		print("[visual-source] live opening category audit=", categories)
		for required_visible_category in [
			"grass/terrain", "dirt/path tiles", "trees", "bushes/flowers",
			"house/building", "well/props", "farm plots/crops",
			"player avatar", "Farmer Rowan", "quickbar/icons", "UI panels",
		]:
			if not categories.has(required_visible_category):
				push_error("LimeZu opening source audit is missing visible category '%s'" % required_visible_category)
				ow.queue_free(); quit(1); return
		if int(category_totals.get("sprout", 0)) > 0:
			push_error("LimeZu opening category audit still found Sprout visuals: %s" % str(category_totals))
			ow.queue_free(); quit(1); return
		var player_audit: Dictionary = categories.get("player avatar", {}) as Dictionary
		var rowan_audit: Dictionary = categories.get("Farmer Rowan", {}) as Dictionary
		# Player + Rowan render a raw LimeZu CHARACTER sheet (Farmer_1/Farmer_2/Body_2), and they
		# must NOT render the identical sheet — that identical-Farmer_1-for-everyone state was the
		# actor-cloning bug. (Palette-only differences are caught by the deterministic signature
		# check below; player/Rowan are differentiated by base sheet so this stays robust.)
		if _audit_count(player_audit, "limezu_raw") < 1 \
				or not _audit_paths_contain(player_audit, "Characters_16x16/"):
			push_error("Player avatar is not rendering from a raw LimeZu character sheet: %s" % str(player_audit))
			ow.queue_free(); quit(1); return
		if _audit_count(rowan_audit, "limezu_raw") < 1 \
				or not _audit_paths_contain(rowan_audit, "Characters_16x16/"):
			push_error("Farmer Rowan is not rendering from a raw LimeZu character sheet: %s" % str(rowan_audit))
			ow.queue_free(); quit(1); return
		var player_actor_paths: Array = player_audit.get("paths", []) as Array
		if not player_actor_paths.is_empty() and player_actor_paths == (rowan_audit.get("paths", []) as Array):
			push_error("Player and Farmer Rowan render the IDENTICAL character sheet (actor cloning): %s" % str(player_actor_paths))
			ow.queue_free(); quit(1); return
		for clean_category in ["grass/terrain", "dirt/path tiles", "trees", "bushes/flowers", "house/building", "well/props", "player avatar", "Farmer Rowan"]:
			var clean_entry: Dictionary = categories.get(clean_category, {}) as Dictionary
			var clean_counts: Dictionary = clean_entry.get("counts", {}) as Dictionary
			if int(clean_counts.get("legacy_generated", 0)) > 0 or int(clean_counts.get("missing", 0)) > 0:
				push_error("LimeZu opening category '%s' still uses old/missing art: %s" % [clean_category, str(clean_entry)])
				ow.queue_free(); quit(1); return
			if _audit_limezu_family_count(clean_counts) < 1:
				push_error("LimeZu opening category '%s' has no LimeZu-family visual source: %s" % [clean_category, str(clean_entry)])
				ow.queue_free(); quit(1); return
		var playable_area: Dictionary = VisualSourceReport.live_area_sources(ow_map, OverworldMap.LIMEZU_PLAYABLE_AREA_BOUNDS)
		print("[visual-source] live playable area sources=", playable_area)
		for forbidden_area_tier in ["sprout", "legacy_generated", "missing"]:
			if int(playable_area.get(forbidden_area_tier, 0)) > 0:
				push_error("LimeZu playable area still has %d '%s' sprite(s)" % [int(playable_area[forbidden_area_tier]), forbidden_area_tier])
				ow.queue_free(); quit(1); return
		var area_limezu_count: int = _audit_limezu_family_count(playable_area)
		var area_generated_count: int = int(playable_area.get("legacy_generated", 0))
		var area_procedural_count: int = int(playable_area.get("procedural", 0))
		# Procedural budget covers ONLY the documented farm-plot/crop deferral (FarmPlot soil +
		# crop Polygon2Ds + the small sign board). Its exact count varies with each plot's
		# crop/watered state, so the budget is generous + stable; the category audit above is
		# the precise guard that procedural stays confined to "farm plots/crops". A real
		# regression (ground/props falling back to procedural) would be in the hundreds.
		if area_limezu_count < 900 or area_generated_count > 40 or area_procedural_count > 28:
			push_error("LimeZu playable area is not clean enough (limezu_family=%d legacy_generated=%d procedural=%d, farm-deferral budget=28)" % [area_limezu_count, area_generated_count, area_procedural_count])
			ow.queue_free(); quit(1); return
		for collider_snippet in ["_add_limezu_asset_collider", "AssetWorldMetadata.collision_shapes", "Blocked by barn (placement proxy)"]:
			if not overworld_map_src_live.contains(collider_snippet):
				push_error("OverworldMap is missing LimeZu asset-collision/placement guard '%s'" % collider_snippet)
				ow.queue_free(); quit(1); return
		if overworld_map_src_live.contains("_add_limezu_rect_collider") or overworld_map_src_live.contains("LIMEZU_BARN_COLLIDER_RECT"):
			push_error("OverworldMap still contains the retired LimeZu barn rectangle collider path")
			ow.queue_free(); quit(1); return
		var sw_spawn_tile: Vector2i = ow_map.call("get_spawn_tile")
		var sw_blocked: Array = ow_map.call("get_static_blocked_tiles")
		var sw_spawn_blocked: bool = sw_spawn_tile in sw_blocked
		var sw_farm_ok: bool = OverworldMap.LIMEZU_PLAYABLE_AREA_BOUNDS.encloses(OverworldMap.LIMEZU_TILLED_SOIL_RECT)
		var sw_farm_center := Vector2i(
			OverworldMap.LIMEZU_TILLED_SOIL_RECT.position.x + int(OverworldMap.LIMEZU_TILLED_SOIL_RECT.size.x / 2),
			OverworldMap.LIMEZU_TILLED_SOIL_RECT.position.y + int(OverworldMap.LIMEZU_TILLED_SOIL_RECT.size.y / 2)
		)
		if sw_spawn_blocked:
			push_error("Player spawn tile %s is inside blocking LimeZu collision" % str(sw_spawn_tile))
			ow.queue_free(); quit(1); return
		if not sw_farm_ok:
			push_error("Farm test patch (tilled soil) is not inside the playable area near spawn")
			ow.queue_free(); quit(1); return
		if Vector2(sw_farm_center.x - sw_spawn_tile.x, sw_farm_center.y - sw_spawn_tile.y).length() > 8.0:
			push_error("Farm test patch is too far from spawn for a 30-second usability check")
			ow.queue_free(); quit(1); return
		for fy in range(OverworldMap.LIMEZU_TILLED_SOIL_RECT.position.y, OverworldMap.LIMEZU_TILLED_SOIL_RECT.end.y):
			for fx in range(OverworldMap.LIMEZU_TILLED_SOIL_RECT.position.x, OverworldMap.LIMEZU_TILLED_SOIL_RECT.end.x):
				var farm_tile := Vector2i(fx, fy)
				if farm_tile in sw_blocked:
					push_error("Farm test patch tile %s is blocked by static collision" % str(farm_tile))
					ow.queue_free(); quit(1); return
		var limezu_barn_body: StaticBody2D = ow_map.find_child("LimeZuBarnCollision", true, false) as StaticBody2D
		if limezu_barn_body == null or limezu_barn_body.find_children("*", "CollisionPolygon2D", true, false).size() < 2:
			push_error("Live LimeZu map did not instantiate asset-shaped barn collision polygons")
			ow.queue_free(); quit(1); return
		# Tree trunk colliders (StaticBody2D "Tree_*") must exist for the homestead trees.
		if ow_map.find_children("Tree_*", "StaticBody2D", true, false).is_empty():
			push_error("Live LimeZu map did not instantiate the tree trunk colliders")
			ow.queue_free(); quit(1); return
		var fence_probe: StaticBody2D = ow_map.find_child("Fence_*", true, false) as StaticBody2D
		if fence_probe == null or fence_probe.find_children("*", "CollisionShape2D", true, false).is_empty():
			push_error("Live LimeZu map did not instantiate thin fence collision shapes")
			ow.queue_free(); quit(1); return
		ow.queue_free()
		await process_frame
		# UI source-tier: live LimeZu UI must use reviewed Modern UI assets, not the
		# old code-drawn flat fallback.
		var ui_panel_probe := PanelContainer.new()
		CozyUITheme.apply_panel(ui_panel_probe)
		if not _is_limezu_texture_box(ui_panel_probe.get_theme_stylebox("panel")):
			push_error("Live LimeZu UI panel is not using the reviewed Modern UI panel texture")
			ui_panel_probe.free(); quit(1); return
		ui_panel_probe.free()
		var ui_inventory_panel_probe := PanelContainer.new()
		CozyUITheme.apply_inventory_panel(ui_inventory_panel_probe)
		if not _is_limezu_texture_box(ui_inventory_panel_probe.get_theme_stylebox("panel")):
			push_error("Live LimeZu inventory panel is not using the reviewed Modern UI inventory texture")
			ui_inventory_panel_probe.free(); quit(1); return
		ui_inventory_panel_probe.free()
		var ui_slot_probe := PanelContainer.new()
		CozyUITheme.apply_slot(ui_slot_probe)
		if not _is_limezu_texture_box(ui_slot_probe.get_theme_stylebox("panel")):
			push_error("Live LimeZu UI slot is not using the reviewed Modern UI texture frame")
			ui_slot_probe.free(); quit(1); return
		ui_slot_probe.free()
		# HUD card must also be Modern UI in live mode.
		var ui_hud_probe := PanelContainer.new()
		CozyUITheme.apply_hud_panel(ui_hud_probe)
		if not _is_limezu_texture_box(ui_hud_probe.get_theme_stylebox("panel")):
			push_error("Live LimeZu HUD panel is not using the reviewed Modern UI panel texture")
			ui_hud_probe.free(); quit(1); return
		ui_hud_probe.free()
	# Provider must resolve safely whether or not LimeZu is installed.
	LimeZuArtRegistry.reload()
	if LimeZuArtRegistry.texture_path("__nope__") != LimeZuArtRegistry.FALLBACK_PATH:
		push_error("LimeZuArtRegistry unmapped id did not fall back to the missing placeholder")
		quit(1)
		return
	if LimeZuArtRegistry.resolve_source_tier("__nope__") != "missing":
		push_error("LimeZuArtRegistry unmapped id did not report the 'missing' tier")
		quit(1)
		return
	if LimeZuArtRegistry.pack_ids().size() != 7:
		push_error("LimeZuArtRegistry should expose the 7 evaluated pack ids")
		quit(1)
		return
	# When LimeZu is not active, there must be a clear missing reason (no silent blank).
	if not LimeZuArtRegistry.is_available() and LimeZuArtRegistry.missing_reason().is_empty():
		push_error("LimeZu spike has no assets active but reports no missing reason")
		quit(1)
		return
	# The spike scene must instantiate and build via _ready WITHOUT crashing, even with
	# no LimeZu assets (it shows markers / a banner instead).
	var spike_scene := load("res://scenes/visual_spikes/limezu_homestead_slice.tscn") as PackedScene
	if spike_scene == null:
		push_error("LimeZu visual spike scene failed to load")
		quit(1)
		return
	var spike_probe: Node = spike_scene.instantiate()
	get_root().add_child(spike_probe)
	await process_frame
	if spike_probe.get_child_count() == 0:
		push_error("LimeZu visual spike did not build any content")
		spike_probe.queue_free()
		quit(1)
		return
	spike_probe.queue_free()
	await process_frame
	# No LimeZu media (zips / raw PNGs / GIFs / aseprite / audio) or local manifests may
	# be tracked — only commit-safe code/docs/templates.
	var limezu_tracked_output: Array = []
	var limezu_tracked_code: int = OS.execute("git", ["ls-files", "licensed_assets/limezu"], limezu_tracked_output, true)
	if limezu_tracked_code == 0 and not "\n".join(limezu_tracked_output).strip_edges().is_empty():
		push_error("licensed_assets/limezu contains tracked files; LimeZu assets must stay gitignored")
		quit(1)
		return
	# The spike must not paint a marker grid by default (markers are dev-only).
	var limezu_spike_src: String = FileAccess.get_file_as_string("res://scenes/visual_spikes/limezu_homestead_slice.gd")
	if not limezu_spike_src.contains("const DEBUG_MARKERS := false"):
		push_error("LimeZu spike must default DEBUG_MARKERS to false (no missing-marker grid in default view)")
		quit(1)
		return
	if load("res://tools/visual_spike_capture.gd") == null:
		push_error("visual_spike_capture.gd failed to load")
		quit(1)
		return
	# Real-art mapping is enforced only when the LimeZu packs/local outputs are usable
	# locally (a clean checkout without LimeZu must still pass - the spike shows its banner).
	LimeZuArtRegistry.reload()
	if LimeZuArtRegistry.is_usable_for_live():
		for limezu_required_id in ["terrain.grass", "terrain.dirt_path", "terrain.tilled_soil", "object.tree", "object.fence_horizontal", "object.barn"]:
			if not LimeZuArtRegistry.has_asset(limezu_required_id):
				push_error("LimeZu spike core id did not resolve to real art: %s" % limezu_required_id)
				quit(1)
				return
		var dirt_path_tex: Texture2D = LimeZuArtRegistry.resolve_texture("terrain.dirt_path")
		if dirt_path_tex == null:
			push_error("LimeZu dirt path texture failed to load")
			quit(1)
			return
		var dirt_path_img: Image = dirt_path_tex.get_image()
		if dirt_path_img == null or dirt_path_img.is_empty():
			push_error("LimeZu dirt path texture has no readable pixels")
			quit(1)
			return
		var dirt_path_transparent_pixels: int = 0
		for py in range(dirt_path_img.get_height()):
			for px in range(dirt_path_img.get_width()):
				if dirt_path_img.get_pixel(px, py).a < 0.95:
					dirt_path_transparent_pixels += 1
		if dirt_path_transparent_pixels == 0:
			push_error("LimeZu dirt path is still a fully opaque slab; use an irregular/transparent reviewed patch")
			quit(1)
			return
		for limezu_layer_snippet in [
			"func _configure_visual_layers",
			"ground_layer.z_index = LIMEZU_GROUND_LAYER_Z",
			"ground_layer.y_sort_enabled = false",
			"ground_layer.set_meta(\"visual_role\", \"terrain_ground\")",
			"gameplay_layer.y_sort_enabled = true",
			"gameplay_layer.set_meta(\"visual_role\", \"props_actors_y_sorted\")",
			"LIMEZU_GROUND_LAYER_Z := -100",
			"LIMEZU_GROUND_GRASS_Z := -30",
			"LIMEZU_GROUND_PATH_Z := -24",
			"LIMEZU_GROUND_SOIL_Z := -22",
		]:
			if not overworld_map_src_live.contains(limezu_layer_snippet):
				push_error("OverworldMap is missing LimeZu ground-layer contract: %s" % limezu_layer_snippet)
				quit(1)
				return
		for limezu_footprint_snippet in [
			"const LIMEZU_PLAYABLE_AREA_BOUNDS",
			"const LIMEZU_APPROACH_PATH_TILES",
			"const LIMEZU_CURATED_PATH_TILES",
			"const LIMEZU_TILLED_SOIL_RECT",
			"const LIMEZU_BARN_VISUAL_FOOTPRINT",
			"const LIMEZU_CRATE_VISUAL_FOOTPRINT",
			"const LIMEZU_SIGN_VISUAL_FOOTPRINTS",
			"const LIMEZU_EDGE_TREE_TILES",
			"const LIMEZU_EDGE_SMALL_TREE_TILES",
			"const LIMEZU_EDGE_FLOWER_TILES",
			"const LIMEZU_EDGE_FENCE_TILES",
			"const LIMEZU_EDGE_CRATE_TILES",
			"const LIMEZU_PROP_VISUAL_FOOTPRINTS",
			"func _limezu_is_ground_blocked",
			"func _limezu_should_draw_path",
			"func _limezu_should_draw_soil",
			"if _limezu_should_draw_path(tile):",
			"FarmPlot owns those live sprites",
		]:
			if not overworld_map_src_live.contains(limezu_footprint_snippet):
				push_error("OverworldMap is missing LimeZu footprint exclusion contract: %s" % limezu_footprint_snippet)
				quit(1)
				return
		for forbidden_path_snippet in ["Vector2i(7, 12)", "Vector2i(8, 12)", "Vector2i(9, 12)", "Vector2i(9, 13)"]:
			if overworld_map_src_live.contains(forbidden_path_snippet):
				push_error("LimeZu curated path still includes an old sign/barn-overlap cell: %s" % forbidden_path_snippet)
				quit(1)
				return
		for limezu_ground_call in [
			"_limezu_ground(\"terrain.grass\", Vector2i(tx, ty), LIMEZU_GROUND_GRASS_Z)",
			"_limezu_ground(\"terrain.dirt_path\", tile, LIMEZU_GROUND_PATH_Z)",
			"FarmPlot owns those live sprites",
		]:
			if not overworld_map_src_live.contains(limezu_ground_call):
				push_error("LimeZu ground call does not use the low-z terrain tier: %s" % limezu_ground_call)
				quit(1)
				return
		if overworld_map_src_live.contains("var crops: Array[String]") or overworld_map_src_live.contains("_limezu_object(crops"):
			push_error("LimeZu map slice still paints static boot crops instead of FarmPlot state visuals")
			quit(1)
			return
		if not overworld_map_src_live.contains("ground_layer.add_child(s)") or not overworld_map_src_live.contains("gameplay_layer.add_child(holder)"):
			push_error("LimeZu terrain/objects no longer use the expected ground/gameplay parents")
			quit(1)
			return
		if OverworldMap.LIMEZU_PLAYABLE_AREA_BOUNDS.size.x > 48 or OverworldMap.LIMEZU_PLAYABLE_AREA_BOUNDS.size.y > 36:
			push_error("LimeZu playable area expanded too far; this pass must stay small")
			quit(1)
			return
		var visual_source_report_src: String = FileAccess.get_file_as_string("res://systems/visual_source_report.gd")
		for area_audit_snippet in ["func live_area_sources", "_node_in_tile_bounds", "_is_visible_canvas_item", "_sprite_source_path"]:
			if not visual_source_report_src.contains(area_audit_snippet):
				push_error("VisualSourceReport is missing playable-area source audit helper: %s" % area_audit_snippet)
				quit(1)
				return
		var capture_src: String = FileAccess.get_file_as_string("res://tools/live_visual_capture.gd")
		for area_capture_snippet in [
			"live_limezu_opening_after_area_expansion.png",
			"live_limezu_walk_east_after_area_expansion.png",
			"live_limezu_walk_south_after_area_expansion.png",
			"live_limezu_inventory_after_area_expansion.png",
			"live_limezu_opening_after_playability_ui_alignment.png",
			"live_limezu_inventory_after_playability_ui_alignment.png",
			"live_limezu_build_menu_after_playability_ui_alignment.png",
			"live_limezu_farm_prompt_after_playability_ui_alignment.png",
			"_capture_player_offset",
			"_open_build_menu_panel",
			"_farm_prompt_position",
		]:
			if not capture_src.contains(area_capture_snippet):
				push_error("Live visual capture is missing area-expansion screenshot support: %s" % area_capture_snippet)
				quit(1)
				return
		if overworld_map_src_live.contains("_limezu_object(\"object.sign\""):
			push_error("Default LimeZu opening still places optional sign clutter in the map slice")
			quit(1)
			return
		if not (LimeZuArtRegistry.has_asset("crop.carrot") or LimeZuArtRegistry.has_asset("crop.cauliflower")):
			push_error("No LimeZu crop resolves for the spike")
			quit(1)
			return
		if not (LimeZuArtRegistry.has_asset("animal.chicken") or LimeZuArtRegistry.has_asset("animal.cow")):
			push_error("No LimeZu animal resolves for the spike")
			quit(1)
			return
		if load("res://systems/building_placement_system.gd") == null or load("res://ui/build_edit_toolbar.tscn") == null or load("res://buildings/placeable_crate.gd") == null:
			push_error("Placement/edit/delete scripts or toolbar failed to load")
			quit(1)
			return
		if not LimeZuArtRegistry.has_asset("character.farmer_idle"):
			push_error("No LimeZu character/farmer resolves for the spike")
			quit(1)
			return
		var limezu_live_resolved_total: int = LimeZuArtRegistry.list_resolved_live_ids().size()
		if limezu_live_resolved_total < 8:
			push_error("LimeZu live provider resolves only %d core live ids; expected at least 8" % limezu_live_resolved_total)
			quit(1)
			return
		# Cow must be a full frame (the 32x32 slice cropped its head). Require a
		# texture that is not obviously cropped tiny, with real opaque content.
		var cow_tex: Texture2D = LimeZuArtRegistry.resolve_texture("animal.cow")
		if cow_tex == null:
			push_error("LimeZu animal.cow texture failed to load")
			quit(1)
			return
		if cow_tex.get_width() < 24 or cow_tex.get_height() < 24:
			push_error("LimeZu cow texture looks cropped too small (%dx%d) — head likely cut" % [cow_tex.get_width(), cow_tex.get_height()])
			quit(1)
			return
		for limezu_ui_id in [
			"ui.panel", "ui.inventory_panel", "ui.slot", "ui.slot_selected",
			"ui.button", "ui.button_hover", "ui.close", "ui.close_hover", "ui.tab",
		]:
			if not LimeZuArtRegistry.has_asset(limezu_ui_id):
				push_error("Modern UI live id did not resolve to real art: %s" % limezu_ui_id)
				quit(1)
				return
		for limezu_ui_key in ["panel", "inventory_panel", "slot", "slot_selected", "button", "button_hover", "close", "close_hover", "tab"]:
			if not CozyUITheme.LIMEZU_UI_MAP.has(limezu_ui_key):
				push_error("CozyUITheme is missing LimeZu UI map key '%s'" % limezu_ui_key)
				quit(1)
				return
		if CozyUITheme.active_ui_source() != "limezu_modern_ui":
			push_error("CozyUITheme does not tag live LimeZu UI as limezu_modern_ui")
			quit(1)
			return
		var limezu_button_probe := Button.new()
		CozyUITheme.apply_button(limezu_button_probe)
		if not _is_limezu_texture_box(limezu_button_probe.get_theme_stylebox("normal")):
			push_error("CozyUITheme.apply_button did not use the reviewed Modern UI button texture")
			limezu_button_probe.free()
			quit(1)
			return
		CozyUITheme.apply_close_button(limezu_button_probe)
		if not _is_limezu_texture_box(limezu_button_probe.get_theme_stylebox("normal")):
			push_error("CozyUITheme.apply_close_button did not use the reviewed Modern UI close texture")
			limezu_button_probe.free()
			quit(1)
			return
		limezu_button_probe.free()
		var limezu_slot_box: StyleBox = CozyUITheme.slot_box(true, false)
		if not _is_limezu_texture_box(limezu_slot_box):
			push_error("CozyUITheme.slot_box did not use the reviewed Modern UI slot texture")
			quit(1)
			return
		var limezu_blocked_slot_box: StyleBox = CozyUITheme.slot_box(false, true)
		if not _is_limezu_flat_with_fill(limezu_blocked_slot_box, LimeZuUITheme.SLOT_BLOCKED_FILL):
			push_error("CozyUITheme.slot_box did not use the readable dark LimeZu blocked slot frame")
			quit(1)
			return
		var quick_tools_source: String = FileAccess.get_file_as_string("res://ui/quick_tools_bar.gd")
		if not quick_tools_source.contains("LimeZuUITheme.slot_texture_style"):
			push_error("Hotbar slots must use the asset-backed LimeZuUITheme.slot_texture_style")
			quit(1)
			return
		if not quick_tools_source.contains("const SLOT_COUNT := 9") or not quick_tools_source.contains("hotbar_rail_style"):
			push_error("Hotbar is missing the 9-slot count or the cohesive rail backing (hotbar_rail_style)")
			quit(1)
			return
		var quick_tools_scene: PackedScene = load("res://ui/quick_tools_bar.tscn") as PackedScene
		if quick_tools_scene == null:
			push_error("Quick tools/hotbar scene failed explicit load")
			quit(1)
			return
		var quick_tools: CanvasLayer = quick_tools_scene.instantiate() as CanvasLayer
		get_root().add_child(quick_tools)
		await process_frame
		quick_tools.call("setup", Callable(self, "_validation_get_inventory_count"), LocalSaveSystem.default_quickbar_slots(), 0)
		await process_frame
		var hotbar_strip: HBoxContainer = quick_tools.get_node_or_null("Wrap/Rail/Strip") as HBoxContainer
		var hotbar_wrap: Control = quick_tools.get_node_or_null("Wrap") as Control
		if hotbar_strip == null or hotbar_strip.find_children("*", "Panel", false, false).size() < 8 or hotbar_wrap == null or hotbar_wrap.anchor_top < 0.99:
			push_error("Hotbar did not build a bottom-centered quickslot row in a framed rail")
			quick_tools.queue_free()
			quit(1)
			return
		for hotbar_contract_snippet in [
			"signal selected_tool_changed",
			"signal quickbar_assignments_changed",
			"func selected_hotbar_index",
			"func selected_item_id",
			"func held_visual_id",
			"func set_quickbar_assignments",
			"func quickbar_assignments",
			"func begin_quickbar_assignment",
			"func assign_quickbar_slot",
			"func clear_quickbar_slot",
			"func unequip",
			"KEY_0",
			"KEY_1",
			"DEFAULT_ASSIGNMENTS",
			"HELD_TOOL_VISUAL_IDS",
		]:
			if not quick_tools_source.contains(hotbar_contract_snippet):
				push_error("Hotbar selected-tool visual contract is missing '%s'" % hotbar_contract_snippet)
				quick_tools.queue_free()
				quit(1)
				return
		if quick_tools_source.contains("const TOOL_ORDER"):
			push_error("Quickbar still exposes the old forced TOOL_ORDER model instead of saved assignments")
			quick_tools.queue_free()
			quit(1)
			return
		if String(quick_tools.call("selected_item_id")) != ItemIds.TOOL_WORN_AXE:
			push_error("Hotbar selected_item_id did not expose the owned first starter tool")
			quick_tools.queue_free()
			quit(1)
			return
		quick_tools.call("select_hotbar_index", 3)
		if String(quick_tools.call("selected_item_id")) != ItemIds.TOOL_WATERING_CAN \
				or String(quick_tools.call("held_visual_id")).is_empty():
			push_error("Hotbar selection did not expose the watering-can held visual contract")
			quick_tools.queue_free()
			quit(1)
			return
		var validation_slots: Array[String] = LocalSaveSystem.default_quickbar_slots()
		validation_slots[1] = ""
		quick_tools.call("set_quickbar_assignments", validation_slots, 1, false)
		if String(quick_tools.call("selected_item_id")) != "" or String(quick_tools.call("held_visual_id")) != "":
			push_error("Quickbar empty selected slot must resolve to empty hands / no held visual")
			quick_tools.queue_free()
			quit(1)
			return
		quick_tools.call("assign_quickbar_slot", 1, ResourceIds.MATERIAL_WOOD)
		if String(quick_tools.call("selected_item_id")) != ResourceIds.MATERIAL_WOOD:
			push_error("Quickbar assignment did not store/select an inventory item id")
			quick_tools.queue_free()
			quit(1)
			return
		quick_tools.call("clear_quickbar_slot", 1)
		if String((quick_tools.call("quickbar_assignments") as Array)[1]) != "" or String(quick_tools.call("selected_item_id")) != "":
			push_error("Quickbar clear slot did not leave an empty, unequipped slot")
			quick_tools.queue_free()
			quit(1)
			return
		quick_tools.call("assign_quickbar_slot", 2, ItemIds.TOOL_WORN_HOE)
		quick_tools.call("unequip")
		if int(quick_tools.call("selected_hotbar_index")) != -1 or String(quick_tools.call("selected_item_id")) != "":
			push_error("Quickbar unequip did not set hands empty")
			quick_tools.queue_free()
			quit(1)
			return
		if not bool(quick_tools.call("begin_quickbar_assignment", ContentIds.ITEM_CARROT)):
			push_error("Quickbar did not accept an inventory item assignment request")
			quick_tools.queue_free()
			quit(1)
			return
		if not bool(quick_tools.call("begin_quickbar_assignment", ContentIds.ITEM_PLACEHOLDER_SEED_PACKET)):
			push_error("Quickbar did not accept the seed packet item assignment request")
			quick_tools.queue_free()
			quit(1)
			return
		var normalized_quickbar: Array[String] = LocalSaveSystem.normalize_quickbar_slots([ItemIds.TOOL_WORN_AXE, "", "__bad_id__"])
		if normalized_quickbar.size() != LocalSaveSystem.QUICKBAR_SLOT_COUNT or normalized_quickbar[0] != ItemIds.TOOL_WORN_AXE or normalized_quickbar[2] != "":
			push_error("LocalSaveSystem quickbar normalization did not preserve valid ids and reject invalid/tiny data")
			quick_tools.queue_free()
			quit(1)
			return
		if ObjectArtRegistry.icon_texture_for_item(ItemIds.TOOL_WORN_PICKAXE) == null \
				or ObjectArtRegistry.icon_texture_for_item(ItemIds.TOOL_WORN_HOE) == null \
				or ObjectArtRegistry.icon_texture_for_item(ItemIds.TOOL_SIMPLE_HAMMER) == null:
			push_error("Core tools need clean-checkout icon fallback textures")
			quick_tools.queue_free()
			quit(1)
			return
		if ObjectArtRegistry.icon_texture_for_item("__missing__") != null:
			push_error("Unknown item icon lookup should fail safe to null, not a missing-texture box")
			quick_tools.queue_free()
			quit(1)
			return
		quick_tools.queue_free()
		await process_frame
		var overworld_controller_src_live: String = FileAccess.get_file_as_string("res://world/overworld_controller.gd")
		if not overworld_controller_src_live.contains("admin_clear_local_test_placements"):
			push_error("OverworldController is missing the admin local test-placement reset hook")
			quit(1)
			return
		for limezu_sign_snippet in ["func _add_limezu_sign_sprite", "LimeZuArtRegistry.has_asset(\"object.sign\")", "sign_visual_hidden_limezu"]:
			if not overworld_controller_src_live.contains(limezu_sign_snippet):
				push_error("OverworldController is missing LimeZu sign fallback guard: %s" % limezu_sign_snippet)
				quit(1)
				return
		var plot_boundary_index: int = overworld_controller_src_live.find("func _build_plot_boundary")
		var plot_boundary_limezu_guard_index: int = overworld_controller_src_live.find("LiveVisualPolicy.live_limezu_slice()", plot_boundary_index)
		var plot_boundary_line_index: int = overworld_controller_src_live.find("Line2D.new()", plot_boundary_index)
		if plot_boundary_index == -1 or plot_boundary_limezu_guard_index == -1 or plot_boundary_line_index == -1 or plot_boundary_limezu_guard_index > plot_boundary_line_index:
			push_error("Plot boundary line/post visuals must be guarded out of LimeZu live mode")
			quit(1)
			return
		var make_sign_index: int = overworld_controller_src_live.find("func _make_sign")
		var make_sign_limezu_index: int = overworld_controller_src_live.find("_add_limezu_sign_sprite", make_sign_index)
		var make_sign_sprout_index: int = overworld_controller_src_live.find("ContentIds.PLACEABLE_SIGNPOST", make_sign_index)
		if make_sign_index == -1 or make_sign_limezu_index == -1 or make_sign_sprout_index == -1 or make_sign_limezu_index > make_sign_sprout_index:
			push_error("_make_sign must try/hide LimeZu sign visuals before Sprout/procedural fallback in live mode")
			quit(1)
			return
		var plot_sign_index: int = overworld_controller_src_live.find("func _make_plot_sign")
		var plot_sign_limezu_index: int = overworld_controller_src_live.find("_add_limezu_sign_sprite", plot_sign_index)
		var plot_sign_sprout_index: int = overworld_controller_src_live.find("ContentIds.PLACEABLE_SIGNPOST", plot_sign_index)
		if plot_sign_index == -1 or plot_sign_limezu_index == -1 or plot_sign_sprout_index == -1 or plot_sign_limezu_index > plot_sign_sprout_index:
			push_error("_make_plot_sign must try/hide LimeZu sign visuals before Sprout/procedural fallback in live mode")
			quit(1)
			return
		var cottage_sign_index: int = overworld_controller_src_live.find("func _setup_cottage_sign")
		var cottage_limezu_guard_index: int = overworld_controller_src_live.find("LiveVisualPolicy.live_limezu_slice()", cottage_sign_index)
		var cottage_polygon_index: int = overworld_controller_src_live.find("Polygon2D", cottage_sign_index)
		if cottage_sign_index == -1 or cottage_limezu_guard_index == -1 or cottage_polygon_index == -1 or cottage_limezu_guard_index > cottage_polygon_index:
			push_error("Cottage sign still draws old procedural polygons before the LimeZu hide guard")
			quit(1)
			return
		var farm_plot_scene: PackedScene = load("res://scenes/farming/farm_plot.tscn") as PackedScene
		if farm_plot_scene == null:
			push_error("Farm plot scene failed to load for LimeZu visual-clash validation")
			quit(1)
			return
		var farm_plot_probe: Node = farm_plot_scene.instantiate()
		get_root().add_child(farm_plot_probe)
		await process_frame
		farm_plot_probe.call("set_plot_state", {"stage": "crop_stage_3", "is_nearby": true, "crop_id": "carrot", "watered": false})
		for old_soil_node_name in ["SoilRim", "SoilBase", "FurrowTop", "FurrowMid", "FurrowBottom", "SoilHighlight", "MoistureOverlay", "SproutSmall", "SproutLarge", "GrownLeaves", "CropAccent"]:
			var old_soil_node: CanvasItem = farm_plot_probe.get_node_or_null(old_soil_node_name) as CanvasItem
			if old_soil_node != null and old_soil_node.visible:
				push_error("Old farm-plot polygon visual is visible in LimeZu mode: %s" % old_soil_node_name)
				farm_plot_probe.queue_free()
				quit(1)
				return
		var live_soil: CanvasItem = farm_plot_probe.get_node_or_null("LiveLimeZuSoil") as CanvasItem
		var live_crop: CanvasItem = farm_plot_probe.get_node_or_null("LiveLimeZuCrop") as CanvasItem
		if live_soil == null or live_crop == null or not live_soil.visible or not live_crop.visible:
			push_error("Farm plot live LimeZu soil/crop sprites did not render for a mature crop state")
			farm_plot_probe.queue_free()
			quit(1)
			return
		farm_plot_probe.queue_free()
		await process_frame
		var homestead_live_source: String = FileAccess.get_file_as_string("res://world/homestead_controller.gd")
		for farm_alignment_snippet in [
			"_align_limezu_farm_interaction_nodes",
			"FARM_PLOT_CARROT_ID: Vector2i(6, 13)",
			"FARM_PLOT_TURNIP_ID: Vector2i(7, 13)",
			"FARM_PLOT_BERRY_ID: Vector2i(8, 13)",
		]:
			if not homestead_live_source.contains(farm_alignment_snippet):
				push_error("HomesteadController is missing LimeZu farm interaction alignment: %s" % farm_alignment_snippet)
				quit(1)
				return
		for farm_contract_snippet in [
			"var _selected_farming_item_id",
			"func set_selected_farming_item",
			"ContentIds.ITEM_PLACEHOLDER_SEED_PACKET",
			"func admin_grow_crops",
			"farming_system.till_plot",
			"farming_system.plant_seed",
			"farming_system.water_plot",
			"farming_system.harvest_plot",
			"Select Worn Hoe",
			"Select a Seed Packet",
			"Select Watering Can",
		]:
			if not homestead_live_source.contains(farm_contract_snippet):
				push_error("HomesteadController is missing Stardew-style farming contract: %s" % farm_contract_snippet)
				quit(1)
				return
		if not overworld_controller_src_live.contains("set_selected_farming_item(selected_item_id)"):
			push_error("OverworldController does not pass selected quickbar item into farming actions")
			quit(1)
			return
		var farming_contract_probe := FarmingSystem.new()
		farming_contract_probe.ensure_plot_with_crop("validation_plot", ContentIds.CROP_CARROT)
		if farming_contract_probe.plant_seed("validation_plot", ContentIds.CROP_CARROT):
			push_error("FarmingSystem allowed seed planting before hoe/till")
			quit(1)
			return
		if not farming_contract_probe.till_plot("validation_plot"):
			push_error("FarmingSystem hoe/till action failed on an empty plot")
			quit(1)
			return
		if String(farming_contract_probe.get_plot_state("validation_plot").get("stage", "")) != FarmingSystem.STAGE_TILLED_SOIL:
			push_error("FarmingSystem till action did not set tilled_soil")
			quit(1)
			return
		if not farming_contract_probe.plant_seed("validation_plot", ContentIds.CROP_CARROT):
			push_error("FarmingSystem seed planting failed on tilled soil")
			quit(1)
			return
		if not farming_contract_probe.water_plot("validation_plot"):
			push_error("FarmingSystem watering failed on planted crop")
			quit(1)
			return
		if not farming_contract_probe.grow_plot("validation_plot"):
			push_error("FarmingSystem watered crop did not advance to stage 2")
			quit(1)
			return
		if not farming_contract_probe.water_plot("validation_plot") or not farming_contract_probe.grow_plot("validation_plot"):
			push_error("FarmingSystem crop did not advance to mature after second water/grow")
			quit(1)
			return
		if String(farming_contract_probe.get_plot_state("validation_plot").get("stage", "")) != FarmingSystem.STAGE_CROP_STAGE_3:
			push_error("FarmingSystem mature stage is not crop_stage_3")
			quit(1)
			return
		var harvest_probe: Dictionary = farming_contract_probe.harvest_plot("validation_plot")
		if String(harvest_probe.get("crop_id", "")) != ContentIds.CROP_CARROT \
				or String(farming_contract_probe.get_plot_state("validation_plot").get("stage", "")) != FarmingSystem.STAGE_TILLED_SOIL:
			push_error("FarmingSystem harvest did not return crop and reset to empty tilled soil")
			quit(1)
			return
		var spawn_guard_index: int = homestead_live_source.find("LiveVisualPolicy.live_limezu_slice()")
		var homestead_rabbit_index: int = homestead_live_source.find("homestead_rabbit_0")
		if spawn_guard_index == -1 or homestead_rabbit_index == -1 or spawn_guard_index > homestead_rabbit_index:
			push_error("Generated homestead creatures are not guarded out of the LimeZu opening view")
			quit(1)
			return
		var rest_marker_index: int = homestead_live_source.find("func _setup_rest_marker")
		var rest_visual_guard_index: int = homestead_live_source.find("not LiveVisualPolicy.live_limezu_slice()", rest_marker_index)
		var rest_mat_index: int = homestead_live_source.find("var mat: Polygon2D", rest_marker_index)
		if rest_marker_index == -1 or rest_visual_guard_index == -1 or rest_mat_index == -1 or rest_visual_guard_index > rest_mat_index:
			push_error("Old rest-marker diamond visual is not guarded out of the LimeZu opening view")
			quit(1)
			return
	# Generator workflow doc must exist when generator installers are present locally.
	var farm_gen := FileAccess.file_exists("res://licensed_assets/limezu/modern_farm/original/Farmer Generator Setup.exe")
	var char_gen := FileAccess.file_exists("res://licensed_assets/limezu/modern_interiors/original/Character Generator 2.0 Setup.exe")
	if (farm_gen or char_gen) and not FileAccess.file_exists("res://docs/limezu_generator_workflow.md"):
		push_error("LimeZu generators are present but docs/limezu_generator_workflow.md is missing")
		quit(1)
		return

	var avatar_visual_source: String = FileAccess.get_file_as_string("res://avatar/avatar_visual.gd")
	var remote_player_source: String = FileAccess.get_file_as_string("res://systems/network/remote_player.gd")
	var simple_villager_source: String = FileAccess.get_file_as_string("res://villagers/simple_villager.gd")
	var moss_rabbit_source: String = FileAccess.get_file_as_string("res://creatures/moss_rabbit.gd")
	var lantern_moth_source: String = FileAccess.get_file_as_string("res://creatures/lantern_moth.gd")
	var stump_turtle_source: String = FileAccess.get_file_as_string("res://creatures/stump_turtle.gd")
	for actor_source_pair in [
		["AvatarVisual", avatar_visual_source],
		["RemotePlayer", remote_player_source],
		["SimpleVillager", simple_villager_source],
		["MossRabbit", moss_rabbit_source],
		["LanternMoth", lantern_moth_source],
		["StumpTurtle", stump_turtle_source],
	]:
		if not String(actor_source_pair[1]).contains("CharacterArtRegistry.apply_sprite"):
			push_error("%s is not routed through CharacterArtRegistry actor sprites" % String(actor_source_pair[0]))
			quit(1)
			return
	var player_avatar_source: String = FileAccess.get_file_as_string("res://scenes/avatar/player_avatar.tscn")
	var avatar_controller_source: String = FileAccess.get_file_as_string("res://avatar/avatar_controller.gd")
	var character_registry_source: String = FileAccess.get_file_as_string("res://systems/art/character_art_registry.gd")
	var object_registry_source_live: String = FileAccess.get_file_as_string("res://systems/art/object_art_registry.gd")
	var overworld_map_source_live_layers: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	var overworld_controller_source_live_layers: String = FileAccess.get_file_as_string("res://world/overworld_controller.gd")
	if not player_avatar_source.contains("y_sort_enabled = true"):
		push_error("Player avatar root must participate in y-sort by its feet/base")
		quit(1)
		return
	if not character_registry_source.contains("sprite.z_index = 0 if LiveVisualPolicy.live_limezu_slice() else 2") \
			or not character_registry_source.contains("sprite.z_index = 0"):
		push_error("CharacterArtRegistry must not force LimeZu actors above y-sorted world objects")
		quit(1)
		return
	if not object_registry_source_live.contains("if LiveVisualPolicy.live_limezu_slice():") \
			or not object_registry_source_live.contains("return 0"):
		push_error("ObjectArtRegistry foreground sprites must use the LimeZu y-sort band, not a raised z stack")
		quit(1)
		return
	for ysort_snippet in [
		"ground_layer.y_sort_enabled = false",
		"gameplay_layer.y_sort_enabled = true",
		"_collision_debug.z_index = 4000",
		"_collision_debug_legend.layer = 90",
		"Cyan: y-sort base",
		"_draw_limezu_npc_collision_debug",
	]:
		if not overworld_map_source_live_layers.contains(ysort_snippet):
			push_error("OverworldMap depth/debug contract is missing '%s'" % ysort_snippet)
			quit(1)
			return
	for npc_spawn_snippet in ["gameplay_layer.add_child(rowan)", "gameplay_layer.add_child(clerk)"]:
		if not overworld_controller_source_live_layers.contains(npc_spawn_snippet):
			push_error("NPCs must be direct gameplay-layer children for y-sort: %s" % npc_spawn_snippet)
			quit(1)
			return
	for avatar_controller_snippet in [
		"var facing_direction",
		"var movement_vector",
		"func set_selected_hotbar_tool",
		"func _animation_state_for",
	]:
		if not avatar_controller_source.contains(avatar_controller_snippet):
			push_error("AvatarController is missing visual-state contract '%s'" % avatar_controller_snippet)
			quit(1)
			return
	for avatar_visual_snippet in [
		"STATE_IDLE_DOWN",
		"STATE_WALK_SIDE",
		"func set_animation_state",
		"func set_held_tool_contract",
		"HeldToolAttachment",
		"held_visual_id_for_item",
	]:
		if not avatar_visual_source.contains(avatar_visual_snippet):
			push_error("AvatarVisual is missing animation/held-tool snippet '%s'" % avatar_visual_snippet)
			quit(1)
			return
	if FileAccess.get_file_as_string("res://scenes/avatar/player_avatar.tscn").contains("Polygon2D"):
		push_error("Player avatar scene still contains a procedural Polygon2D body/shadow")
		quit(1)
		return
	var player_avatar_scene: PackedScene = load("res://scenes/avatar/player_avatar.tscn") as PackedScene
	if player_avatar_scene == null:
		push_error("Player avatar scene failed explicit load")
		quit(1)
		return
	var player_avatar: CharacterBody2D = player_avatar_scene.instantiate() as CharacterBody2D
	if player_avatar == null:
		push_error("Player avatar is not a CharacterBody2D")
		quit(1)
		return
	var player_collision: CollisionShape2D = player_avatar.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if player_collision == null or player_collision.disabled or player_collision.shape == null:
		push_error("Player avatar is missing an enabled CollisionShape2D")
		player_avatar.queue_free()
		quit(1)
		return
	if player_avatar.collision_layer <= 0 or player_avatar.collision_mask <= 0:
		push_error("Player avatar collision layer/mask are not sane")
		player_avatar.queue_free()
		quit(1)
		return
	player_avatar.queue_free()
	var avatar_visual_probe := AvatarVisual.new()
	get_root().add_child(avatar_visual_probe)
	await process_frame
	avatar_visual_probe.call("set_facing_direction", AvatarVisual.FACING_SIDE, 1.0)
	avatar_visual_probe.call("set_animation_state", AvatarVisual.STATE_WALK_SIDE, Vector2.RIGHT)
	if String(avatar_visual_probe.call("get_animation_state")) != AvatarVisual.STATE_WALK_SIDE:
		push_error("AvatarVisual walk animation state did not apply")
		avatar_visual_probe.queue_free()
		quit(1)
		return
	avatar_visual_probe.call("set_held_tool_contract", 0, ItemIds.TOOL_WORN_AXE, "")
	await process_frame
	var held_attachment: Node = avatar_visual_probe.find_child("HeldToolAttachment", true, false)
	var held_sprite: Sprite2D = avatar_visual_probe.find_child("HeldToolSprite", true, false) as Sprite2D
	if held_attachment == null or held_sprite == null or not held_sprite.visible or held_sprite.texture == null:
		push_error("AvatarVisual held-tool attachment did not show a selected tool")
		avatar_visual_probe.queue_free()
		quit(1)
		return
	avatar_visual_probe.call("clear_held_tool")
	await process_frame
	if held_sprite.visible:
		push_error("AvatarVisual held-tool sprite did not hide for empty selection")
		avatar_visual_probe.queue_free()
		quit(1)
		return
	avatar_visual_probe.queue_free()
	await process_frame
	if AssetWorldMetadata.collision_type("npc") != AssetWorldMetadata.COLLISION_CIRCLE \
			or not AssetWorldMetadata.interaction_enabled("npc") \
			or AssetWorldMetadata.trunk_radius("npc") <= 0.0 \
			or AssetWorldMetadata.trunk_radius("npc") > 12.0:
		push_error("NPC metadata must use compact body collision while preserving interaction")
		quit(1)
		return
	var villager_probe := SimpleVillager.new()
	get_root().add_child(villager_probe)
	await process_frame
	var npc_body: StaticBody2D = villager_probe.get_node_or_null("NpcBody") as StaticBody2D
	var npc_shapes: Array = npc_body.find_children("*", "CollisionShape2D", true, false) if npc_body != null else []
	var npc_shape_node: CollisionShape2D = npc_shapes[0] as CollisionShape2D if not npc_shapes.is_empty() else null
	var npc_circle: CircleShape2D = npc_shape_node.shape as CircleShape2D if npc_shape_node != null else null
	if npc_body == null or npc_shape_node == null or npc_shape_node.disabled or npc_circle == null \
			or npc_circle.radius <= 0.0 or npc_circle.radius > 12.0:
		push_error("SimpleVillager did not build a compact enabled NPC body collision circle")
		villager_probe.queue_free()
		quit(1)
		return
	villager_probe.queue_free()
	await process_frame
	var live_actor_summary: Dictionary = VisualSourceReport.registry_summary(WorldProjection.MODE_SPROUT_TOPDOWN)
	if (live_actor_summary["actors"] as Dictionary).has("missing"):
		push_error("Live actor registry has missing generated actor art: %s" % [live_actor_summary["actors"]])
		quit(1)
		return
	var map_probe := HomesteadMap.new()
	if not map_probe.has_method("terrain_visual_for"):
		push_error("Map renderer is missing terrain_visual_for helper")
		map_probe.free()
		quit(1)
		return
	if not map_probe.has_method("visual_projection_mode") or not WorldProjection.is_sprout_compatible(String(map_probe.call("visual_projection_mode"))):
		push_error("Map renderer is not using the Sprout/top-down visual projection")
		map_probe.free()
		quit(1)
		return
	var map_projection_tile := Vector2i(9, 11)
	var map_world_position: Vector2 = map_probe.call("grid_to_world", map_projection_tile) as Vector2
	if map_world_position != WorldProjection.tile_to_world(map_projection_tile, WorldProjection.MODE_SPROUT_TOPDOWN):
		push_error("Map renderer grid_to_world does not use WorldProjection sprout_topdown")
		map_probe.free()
		quit(1)
		return
	if (map_probe.call("world_to_grid", map_world_position) as Vector2i) != map_projection_tile:
		push_error("Map renderer world_to_grid did not round-trip through Sprout/top-down projection")
		map_probe.free()
		quit(1)
		return
	var map_visual: Dictionary = map_probe.call("terrain_visual_for", "meadow", Vector2i(0, 0)) as Dictionary
	map_probe.free()
	if map_visual.is_empty() or bool(map_visual.get("fallback", true)) or map_visual.get("texture", null) == null:
		push_error("Map renderer terrain_visual_for did not resolve meadow art")
		quit(1)
		return
	# --- Player-facing polish (movement / delete safety / preview alignment) -----
	# Movement matches the visual projection: pressing "up" is a straight vertical
	# vector in the live top-down mode (no leftover isometric skew).
	var motion_probe := AvatarController.new()
	var topdown_up: Vector2 = motion_probe.get_desired_motion(Vector2(0, -1))
	if not is_zero_approx(topdown_up.x) or topdown_up.y >= 0.0:
		push_error("AvatarController top-down movement is not straight (leftover iso skew?)")
		motion_probe.free()
		quit(1)
		return
	# Legacy iso projection must still skew, so the diagonal grid look is intact.
	motion_probe._projection_mode = WorldProjection.MODE_ISO_64X32
	var iso_up: Vector2 = motion_probe.get_desired_motion(Vector2(0, -1))
	motion_probe.free()
	if is_zero_approx(iso_up.x):
		push_error("AvatarController legacy iso movement lost its isometric skew")
		quit(1)
		return
	if LiveVisualPolicy.INTERACTION_RADIUS < 70.0 or LiveVisualPolicy.INTERACTION_RADIUS > 96.0:
		push_error("LiveVisualPolicy.INTERACTION_RADIUS is outside the LimeZu-scale target range")
		quit(1)
		return
	var interactable_src: String = FileAccess.get_file_as_string("res://systems/interactable_system.gd")
	for interaction_snippet in ["func interaction_radius", "_interaction_point", "LiveVisualPolicy.INTERACTION_RADIUS"]:
		if not interactable_src.contains(interaction_snippet):
			push_error("InteractableSystem is missing LimeZu-scale targeting snippet '%s'" % interaction_snippet)
			quit(1)
			return
	# Build/edit delete safety: the two-step confirmation must be present.
	var placement_src: String = FileAccess.get_file_as_string("res://systems/building_placement_system.gd")
	if not placement_src.contains("DELETE_CONFIRM_WINDOW_MS") or not placement_src.contains("_disarm_delete"):
		push_error("Build/edit delete confirmation safety is missing")
		quit(1)
		return
	var movement_build_src: String = FileAccess.get_file_as_string("res://world/homestead_controller.gd")
	var decorating_mode_index: int = movement_build_src.find("func _on_decorating_mode_changed")
	var decorating_mode_block: String = movement_build_src.substr(decorating_mode_index, 420) if decorating_mode_index >= 0 else ""
	if decorating_mode_block.contains("set_movement_enabled(not is_active)"):
		push_error("Build/edit mode still disables player movement")
		quit(1)
		return
	if not decorating_mode_block.contains("set_movement_enabled(true)"):
		push_error("Build/edit mode does not explicitly keep player movement active")
		quit(1)
		return
	# Worldbuilder previews load and align to whole cells in top-down mode.
	if load("res://systems/parcel_preview.gd") == null or load("res://systems/world_builder_overlay.gd") == null:
		push_error("Parcel preview / world-builder overlay scripts failed to load")
		quit(1)
		return
	var parcel_src: String = FileAccess.get_file_as_string("res://systems/parcel_preview.gd")
	var overlay_src: String = FileAccess.get_file_as_string("res://systems/world_builder_overlay.gd")
	if not parcel_src.contains("_half_tile") or not overlay_src.contains("_expand"):
		push_error("Worldbuilder previews are not aligned to the visual projection")
		quit(1)
		return
	if load("res://avatar/avatar_controller.gd") == null:
		push_error("AvatarController script failed to load")
		quit(1)
		return
	var graphics_homestead_map_source: String = FileAccess.get_file_as_string("res://world/homestead_map.gd")
	var graphics_overworld_map_source: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	if not graphics_homestead_map_source.contains("TerrainArtRegistry.make_tile_sprite"):
		push_error("HomesteadMap does not use TerrainArtRegistry for tile sprites")
		quit(1)
		return
	if not graphics_homestead_map_source.contains("WorldProjection.tile_to_world") or not graphics_homestead_map_source.contains("WorldProjection.tile_polygon"):
		push_error("HomesteadMap is not routed through WorldProjection for live tile placement/polygons")
		quit(1)
		return
	if not graphics_overworld_map_source.contains("_add_terrain_sprite"):
		push_error("OverworldMap does not route plot/terrain override sprites through the map helper")
		quit(1)
		return
	if not graphics_overworld_map_source.contains("_add_road_tile") or not graphics_overworld_map_source.contains("road_sample_tiles"):
		push_error("OverworldMap is missing Sprout/top-down road tile rendering")
		quit(1)
		return
	var graphics_decor_visual_source: String = FileAccess.get_file_as_string("res://buildings/decor_visuals.gd")
	var graphics_crate_visual_source: String = FileAccess.get_file_as_string("res://buildings/placeable_crate.gd")
	var graphics_placeable_decor_source: String = FileAccess.get_file_as_string("res://buildings/placeable_decor.gd")
	if not graphics_decor_visual_source.contains("ObjectArtRegistry.has_art_id") or not graphics_crate_visual_source.contains("ObjectArtRegistry.apply_sprite"):
		push_error("Placeable visuals are not wired to ObjectArtRegistry")
		quit(1)
		return
	for visual_identity_snippet in [
		"func _art_object_id()",
		"return decor_id if not decor_id.is_empty()",
		"_apply_registry_art()",
		"debug_visual_fallback",
	]:
		if not graphics_placeable_decor_source.contains(visual_identity_snippet) and not graphics_crate_visual_source.contains(visual_identity_snippet):
			push_error("Placeable selected-asset visual identity is missing '%s'" % visual_identity_snippet)
			quit(1)
			return
	var registry_visual_required_ids := [
		ContentIds.PLACEABLE_FENCE_SEGMENT,
		ContentIds.PLACEABLE_SIGNPOST,
		ContentIds.PLACEABLE_CRATE,
		ContentIds.PLACEABLE_DIRT_PATH,
		ContentIds.PLACEABLE_FLOOR_DECK,
		ContentIds.PLACEABLE_BARN_SHELL,
		ContentIds.PLACEABLE_WOOD_WALL,
	]
	for required_visual_placeable_id in registry_visual_required_ids + [
		ContentIds.PLACEABLE_FLOWER_BED,
		ContentIds.PLACEABLE_DECOR_SHRUB,
	]:
		if not ContentRegistry.placeables().has(required_visual_placeable_id):
			push_error("Priority build item is missing from ContentRegistry: %s" % required_visual_placeable_id)
			quit(1)
			return
		if registry_visual_required_ids.has(required_visual_placeable_id):
			if not ObjectArtRegistry.has_art_id(required_visual_placeable_id):
				push_error("Priority build item has no ObjectArtRegistry visual id: %s" % required_visual_placeable_id)
				quit(1)
				return
			if ObjectArtRegistry.texture_path(required_visual_placeable_id) == ObjectArtRegistry.FALLBACK_PATH:
				push_error("Priority build item resolves to the generic missing-art fallback: %s" % required_visual_placeable_id)
				quit(1)
				return
		var visual_entry: Dictionary = ContentRegistry.placeables().get(required_visual_placeable_id, {}) as Dictionary
		var visual_scene := load(String(visual_entry.get("scene_path", ""))) as PackedScene
		if visual_scene == null:
			push_error("Priority build item scene failed to load: %s" % required_visual_placeable_id)
			quit(1)
			return
		var visual_node := visual_scene.instantiate()
		get_root().add_child(visual_node)
		await process_frame
		var has_registry_sprite: bool = visual_node.get_node_or_null("RegistryArtSprite") != null
		var has_custom_visual: bool = has_registry_sprite
		if not has_custom_visual:
			for visual_child in visual_node.get_children():
				if visual_child is Polygon2D and not String((visual_child as Node).name).begins_with("Selection"):
					has_custom_visual = true
					break
		if registry_visual_required_ids.has(required_visual_placeable_id) and not has_registry_sprite:
			push_error("Priority build item did not instantiate a selected-id RegistryArtSprite: %s" % required_visual_placeable_id)
			visual_node.queue_free()
			quit(1)
			return
		if not has_custom_visual:
			push_error("Priority build item did not instantiate any selected visual: %s" % required_visual_placeable_id)
			visual_node.queue_free()
			quit(1)
			return
		if String(visual_node.get_meta("debug_visual_asset_id", "")) != required_visual_placeable_id:
			push_error("Priority build item debug visual id did not match selected content id: %s" % required_visual_placeable_id)
			visual_node.queue_free()
			quit(1)
			return
		if bool(visual_node.get_meta("debug_visual_fallback", true)):
			push_error("Priority build item is using the generic visual fallback: %s" % required_visual_placeable_id)
			visual_node.queue_free()
			quit(1)
			return
		visual_node.queue_free()
		await process_frame
	if not graphics_decor_visual_source.contains("WorldProjection.tile_polygon") or not graphics_crate_visual_source.contains("WorldProjection.tile_polygon"):
		push_error("Placeable terrain/edit overlays are not using WorldProjection polygons")
		quit(1)
		return
	if CozyUITheme.panel_style() == null or CozyUITheme.slot_style(true) == null or CozyUITheme.hud_panel_style() == null:
		push_error("CozyUITheme style factories returned null")
		quit(1)
		return
	var style_probe_button := Button.new()
	CozyUITheme.apply_button(style_probe_button)
	if style_probe_button.get_theme_stylebox("normal") == null or style_probe_button.get_theme_stylebox("hover") == null:
		push_error("CozyUITheme.apply_button did not attach button styles")
		style_probe_button.free()
		quit(1)
		return
	style_probe_button.free()
	var style_probe_input := LineEdit.new()
	CozyUITheme.apply_text_input(style_probe_input)
	if style_probe_input.get_theme_stylebox("normal") == null or style_probe_input.get_theme_stylebox("focus") == null:
		push_error("CozyUITheme.apply_text_input did not attach text input styles")
		style_probe_input.free()
		quit(1)
		return
	style_probe_input.free()
	var style_probe_option := OptionButton.new()
	CozyUITheme.apply_option_button(style_probe_option)
	if style_probe_option.get_theme_stylebox("normal") == null:
		push_error("CozyUITheme.apply_option_button did not attach option button styles")
		style_probe_option.free()
		quit(1)
		return
	style_probe_option.free()
	var ui_rewrite_contracts := {
		"res://ui/crafting_panel.gd": ["CozyUITheme.apply_panel", "CozyUITheme.apply_close_button", "CozyUITheme.apply_button"],
		"res://ui/progression_panel.gd": ["CozyUITheme.apply_panel", "CozyUITheme.apply_close_button"],
		"res://ui/network_connect_panel.gd": ["CozyUITheme.apply_panel", "CozyUITheme.apply_text_input"],
		"res://ui/dev_character_creator_panel.gd": ["CozyUITheme.apply_panel", "CozyUITheme.apply_close_button"],
		"res://ui/interior_view.gd": ["CozyUITheme.apply_panel", "CozyUITheme.apply_close_button"],
		"res://ui/chat_panel.gd": ["CozyUITheme.apply_hud_panel", "CozyUITheme.apply_text_input"],
		"res://ui/world_space_hint.gd": ["CozyUITheme.apply_slot", "CozyUITheme.slot_box"],
	}
	for ui_contract_path in ui_rewrite_contracts.keys():
		var ui_contract_source: String = FileAccess.get_file_as_string(String(ui_contract_path))
		for ui_contract_snippet in ui_rewrite_contracts[ui_contract_path]:
			if not ui_contract_source.contains(String(ui_contract_snippet)):
				push_error("UI rewrite contract missing '%s' in %s" % [String(ui_contract_snippet), String(ui_contract_path)])
				quit(1)
				return

	# Build-menu / interiors pass: the menu must build its runtime controls when
	# mounted in-tree, the close affordances must work, every menu item source id
	# must resolve to registered content, and prefab interior metadata must fail
	# closed when missing/invalid.
	var object_registry: ObjectRegistry = ObjectRegistry.new()
	get_root().add_child(object_registry)
	var build_menu_scene: PackedScene = load("res://ui/build_menu_panel.tscn") as PackedScene
	if build_menu_scene == null:
		push_error("Build menu scene failed explicit load")
		quit(1)
		return
	var build_menu: CanvasLayer = build_menu_scene.instantiate() as CanvasLayer
	if build_menu == null:
		push_error("Build menu scene failed explicit instantiate")
		quit(1)
		return
	get_root().add_child(build_menu)
	await process_frame
	_validation_placeable_ids.clear()
	_validation_placeable_ids.append_array(object_registry.get_placeable_ids())
	if _validation_placeable_ids.is_empty():
		push_error("ObjectRegistry returned no placeables for the build menu")
		quit(1)
		return
	_validation_active_placeable_id = String(_validation_placeable_ids[0])
	build_menu.call(
		"setup",
		Callable(self, "_validation_get_placeable_ids"),
		Callable(self, "_validation_get_placeable_status"),
		Callable(self, "_validation_select_placeable"),
		Callable(self, "_validation_get_active_placeable_id")
	)
	build_menu.call("open_panel")
	await process_frame
	var categories_node: HFlowContainer = build_menu.get_node_or_null("Panel/Rows/Categories") as HFlowContainer
	if categories_node == null:
		push_error("Build menu is missing Panel/Rows/Categories")
		quit(1)
		return
	var category_ids: Array[String] = []
	for child in categories_node.get_children():
		if child is Button:
			var category_button: Button = child as Button
			category_ids.append(String(category_button.get_meta("category_id", category_button.tooltip_text)))
			if String(category_button.text).length() > 8:
				push_error("Build menu category tab '%s' is too long for the Modern UI button asset" % String(category_button.text))
				quit(1)
				return
	if category_ids.size() != BuildCategories.ORDER.size():
		push_error("Build menu built %d categories, expected %d" % [category_ids.size(), BuildCategories.ORDER.size()])
		quit(1)
		return
	for category_index in range(BuildCategories.ORDER.size()):
		if category_ids[category_index] != BuildCategories.ORDER[category_index]:
			push_error("Build menu category metadata mismatch at index %d: got '%s', expected '%s'" % [
				category_index, category_ids[category_index], BuildCategories.ORDER[category_index],
			])
			quit(1)
			return
	var close_button: Button = null
	for button_variant in build_menu.find_children("*", "Button", true, false):
		var candidate: Button = button_variant as Button
		if candidate != null and String(candidate.text).begins_with("Close"):
			close_button = candidate
			break
	if close_button == null:
		push_error("Build menu has no Close button")
		quit(1)
		return
	close_button.emit_signal("pressed")
	if build_menu.visible:
		push_error("Build menu close button did not hide the panel")
		quit(1)
		return
	build_menu.call("open_panel")
	var escape_event: InputEventKey = InputEventKey.new()
	escape_event.pressed = true
	escape_event.keycode = KEY_ESCAPE
	build_menu.call("_input", escape_event)
	if build_menu.visible:
		push_error("Build menu Esc close path did not hide the panel")
		quit(1)
		return
	build_menu.call("open_panel")
	await process_frame
	var menu_registry: Dictionary = ContentRegistry.placeables()
	var item_list: VBoxContainer = build_menu.get_node_or_null("Panel/Rows/Scroll/Items") as VBoxContainer
	if item_list == null:
		push_error("Build menu is missing Panel/Rows/Scroll/Items")
		quit(1)
		return
	var selected_info: Label = build_menu.get_node_or_null("Panel/Rows/SelectedInfo") as Label
	if selected_info == null:
		push_error("Build menu is missing selected item info label")
		quit(1)
		return
	if not selected_info.text.contains("Selected:") or not selected_info.text.contains("Cost:"):
		push_error("Build menu selected item info does not expose selection/cost details")
		quit(1)
		return
	for placeable_id_variant in _validation_placeable_ids:
		var placeable_id: String = String(placeable_id_variant)
		if not menu_registry.has(placeable_id):
			push_error("Build menu references unknown content id '%s'" % placeable_id)
			quit(1)
			return
	for menu_category in BuildCategories.ORDER:
		build_menu.set("_active_category", menu_category)
		build_menu.call("refresh")
		await process_frame
		var expected_ids: Array = BuildCategories.ids_in(menu_category, _validation_placeable_ids)
		for expected_id_variant in expected_ids:
			if not menu_registry.has(String(expected_id_variant)):
				push_error("Build menu category '%s' includes unknown content id '%s'" % [menu_category, expected_id_variant])
				quit(1)
				return
		var rendered_rows: int = 0
		for child in item_list.get_children():
			if child is HBoxContainer or (child is PanelContainer and String((child as Node).name).begins_with("BuildItemCard_")):
				rendered_rows += 1
		if rendered_rows != expected_ids.size():
			push_error("Build menu category '%s' rendered %d rows, expected %d" % [
				menu_category, rendered_rows, expected_ids.size(),
			])
			quit(1)
			return
	var new_modular_piece_ids: Array[String] = [
		ContentIds.PLACEABLE_WOOD_WINDOW_WALL,
		ContentIds.PLACEABLE_ROOF_CAP,
		ContentIds.PLACEABLE_FENCE_CORNER,
		ContentIds.PLACEABLE_FENCE_GATE,
		ContentIds.PLACEABLE_STEPS,
	]
	for modular_id in new_modular_piece_ids:
		if not ContentIds.DECOR_PLACEABLE_IDS.has(modular_id):
			push_error("New modular piece '%s' missing from ContentIds.DECOR_PLACEABLE_IDS" % modular_id)
			quit(1)
			return
		if not menu_registry.has(modular_id):
			push_error("New modular piece '%s' missing from ContentRegistry.placeables()" % modular_id)
			quit(1)
			return
		if not BuildCosts.costs().has(modular_id):
			push_error("New modular piece '%s' missing from BuildCosts" % modular_id)
			quit(1)
			return
		if not _validation_placeable_ids.has(modular_id):
			push_error("New modular piece '%s' missing from ObjectRegistry/build menu" % modular_id)
			quit(1)
			return
		var modular_scene_path: String = String((menu_registry[modular_id] as Dictionary).get("scene_path", ""))
		var modular_scene: PackedScene = load(modular_scene_path) as PackedScene
		if modular_scene == null:
			push_error("New modular piece '%s' scene failed to load: %s" % [modular_id, modular_scene_path])
			quit(1)
			return
	var prefab_metadata: Dictionary = PrefabInteriors.all_metadata()
	if PrefabInteriors.parse_metadata_dict({
		"has_interior": true,
		"template": "bogus",
		"interior_scene_id": "",
		"title": "",
	}).size() != 0:
		push_error("PrefabInteriors.parse_metadata_dict accepted invalid metadata")
		quit(1)
		return
	if not PrefabInteriors.metadata(ContentIds.PLACEABLE_GREENHOUSE_SHELL).is_empty():
		push_error("Structure without implemented interior metadata returned non-empty PrefabInteriors metadata")
		quit(1)
		return
	if PrefabInteriors.has_interior(ContentIds.PLACEABLE_GREENHOUSE_SHELL):
		push_error("Structure without implemented interior metadata reported has_interior")
		quit(1)
		return
	if not PrefabInteriors.template_of(ContentIds.PLACEABLE_GREENHOUSE_SHELL).is_empty() \
			or not PrefabInteriors.title_of(ContentIds.PLACEABLE_GREENHOUSE_SHELL).is_empty():
		push_error("PrefabInteriors missing-metadata fallback did not fail closed")
		quit(1)
		return
	if prefab_metadata.is_empty():
		push_error("No prefab structures have valid interior metadata")
		quit(1)
		return
	for prefab_id_variant in prefab_metadata.keys():
		var prefab_id: String = String(prefab_id_variant)
		var parsed: Dictionary = prefab_metadata[prefab_id] as Dictionary
		for required_field in ["has_interior", "template", "interior_scene_id", "title"]:
			if not parsed.has(required_field):
				push_error("PrefabInteriors metadata for '%s' missing field '%s'" % [prefab_id, required_field])
				quit(1)
				return
		if not menu_registry.has(prefab_id):
			push_error("PrefabInteriors metadata references unknown placeable '%s'" % prefab_id)
			quit(1)
			return
	var interior_view_scene: PackedScene = load("res://ui/interior_view.tscn") as PackedScene
	if interior_view_scene == null:
		push_error("Interior view scene failed explicit load")
		quit(1)
		return
	var interior_view: CanvasLayer = interior_view_scene.instantiate() as CanvasLayer
	if interior_view == null:
		push_error("Interior view scene failed explicit instantiate")
		quit(1)
		return
	get_root().add_child(interior_view)
	await process_frame
	interior_view.call("open_interior", PrefabInteriors.TEMPLATE_COTTAGE, "Cozy Cottage")
	if not interior_view.visible:
		push_error("Interior view open_interior() did not show the overlay")
		quit(1)
		return
	var interior_cancel: InputEventAction = InputEventAction.new()
	interior_cancel.action = "cancel_action"
	interior_cancel.pressed = true
	interior_view.call("_input", interior_cancel)
	if interior_view.visible:
		push_error("Interior view cancel action did not close the overlay")
		quit(1)
		return
	interior_view.queue_free()
	await process_frame
	for modular_id in new_modular_piece_ids:
		if PrefabInteriors.has_interior(modular_id) or not PrefabInteriors.metadata(modular_id).is_empty():
			push_error("Modular/custom piece '%s' should not require an interior" % modular_id)
			quit(1)
			return
	var build_toolbar_scene: PackedScene = load("res://ui/build_edit_toolbar.tscn") as PackedScene
	if build_toolbar_scene == null:
		push_error("Build edit toolbar scene failed to load")
		quit(1)
		return
	var build_toolbar: CanvasLayer = build_toolbar_scene.instantiate() as CanvasLayer
	if build_toolbar == null:
		push_error("Build edit toolbar scene failed to instantiate")
		quit(1)
		return
	get_root().add_child(build_toolbar)
	await process_frame
	for required_method in ["set_active", "set_mode_text", "set_selection_text", "set_feedback_text", "set_button_states"]:
		if not build_toolbar.has_method(required_method):
			push_error("Build edit toolbar is missing method '%s'" % required_method)
			quit(1)
			return
	for required_node_path in [
		"Panel/Margin/Rows/ModeLabel",
		"Panel/Margin/Rows/SelectionLabel",
		"Panel/Margin/Rows/FeedbackLabel",
		"Panel/Margin/Rows/ControlsLabel",
		"Panel/Margin/Rows/ButtonsTop/SelectButton",
		"Panel/Margin/Rows/ButtonsTop/MoveButton",
		"Panel/Margin/Rows/ButtonsTop/RotateButton",
		"Panel/Margin/Rows/ButtonsBottom/DeleteButton",
		"Panel/Margin/Rows/ButtonsBottom/CancelButton",
	]:
		if build_toolbar.get_node_or_null(required_node_path) == null:
			push_error("Build edit toolbar is missing '%s'" % required_node_path)
			quit(1)
			return
	build_toolbar.call("set_active", true)
	build_toolbar.call("set_mode_text", "Edit Mode")
	build_toolbar.call("set_selection_text", "Selected: Cozy Cottage")
	build_toolbar.call("set_feedback_text", "Ready", false)
	build_toolbar.call("set_button_states", true, true, true, true, true)
	if not build_toolbar.visible:
		push_error("Build edit toolbar set_active(true) did not show the toolbar")
		quit(1)
		return
	build_toolbar.queue_free()
	await process_frame
	var building_placement_source: String = FileAccess.get_file_as_string("res://systems/building_placement_system.gd")
	for required_snippet in [
		"EDIT_TOOLBAR_SCENE := preload(\"res://ui/build_edit_toolbar.tscn\")",
		"event.is_action_pressed(\"confirm_action\")",
		"event.is_action_pressed(\"edit_move\")",
		"event.is_action_pressed(\"edit_rotate\")",
		"event.is_action_pressed(\"edit_delete\")",
		"_attempt_rotate_selected_object()",
	]:
		if not building_placement_source.contains(required_snippet):
			push_error("BuildingPlacementSystem is missing edit-toolbar/input snippet '%s'" % required_snippet)
			quit(1)
			return
	if building_placement_source.contains("if _selected_record_id == _hovered_record_id:\n\t\t_remove_selected_object()"):
		push_error("Edit click flow still deletes an already-selected object on a second click")
		quit(1)
		return
	if not building_placement_source.contains("func clear_local_test_placements") or not building_placement_source.contains("save_system.set_region_placed_objects(_region_id, _placed_objects)"):
		push_error("BuildingPlacementSystem is missing the safe local test-placement cleanup helper")
		quit(1)
		return
	build_menu.queue_free()
	object_registry.queue_free()
	await process_frame

	# System/pause menu: scene instantiates and exposes open/close + a quit
	# handler so the player always has an in-game way to control the window/quit.
	var system_menu_scene: PackedScene = load("res://ui/system_menu.tscn") as PackedScene
	if system_menu_scene == null:
		push_error("System menu scene failed to load")
		quit(1)
		return
	var system_menu: CanvasLayer = system_menu_scene.instantiate() as CanvasLayer
	if system_menu == null:
		push_error("System menu scene failed to instantiate")
		quit(1)
		return
	get_root().add_child(system_menu)
	await process_frame
	for required_method in ["open", "close", "is_open", "_on_quit", "_on_fullscreen"]:
		if not system_menu.has_method(required_method):
			push_error("System menu is missing method '%s'" % required_method)
			system_menu.queue_free()
			quit(1)
			return
	var fullscreen_button: Button = system_menu.get_node_or_null("Dim/Panel/Rows/FullscreenButton") as Button
	var resume_button: Button = system_menu.get_node_or_null("Dim/Panel/Rows/ResumeButton") as Button
	var settings_button: Button = system_menu.get_node_or_null("Dim/Panel/Rows/SettingsButton") as Button
	var settings_box: VBoxContainer = system_menu.get_node_or_null("Dim/Panel/Rows/SettingsBox") as VBoxContainer
	var vsync_button: Button = system_menu.get_node_or_null("Dim/Panel/Rows/SettingsBox/VsyncButton") as Button
	var quit_button: Button = system_menu.get_node_or_null("Dim/Panel/Rows/QuitButton") as Button
	var close_menu_button: Button = system_menu.get_node_or_null("Dim/Panel/Rows/CloseButton") as Button
	if resume_button == null:
		push_error("System menu is missing ResumeButton")
		quit(1)
		return
	if fullscreen_button == null:
		push_error("System menu is missing FullscreenButton")
		quit(1)
		return
	if quit_button == null:
		push_error("System menu is missing QuitButton")
		quit(1)
		return
	if close_menu_button == null:
		push_error("System menu is missing CloseButton")
		quit(1)
		return
	if settings_button == null or settings_box == null or vsync_button == null:
		push_error("System menu is missing the Settings / Display path")
		quit(1)
		return
	system_menu.call("open")
	if not bool(system_menu.call("is_open")):
		push_error("System menu open() did not show the menu")
		quit(1)
		return
	settings_button.emit_signal("pressed")
	await process_frame
	if not settings_box.visible:
		push_error("System menu Settings / Display button did not reveal the settings box")
		quit(1)
		return
	resume_button.emit_signal("pressed")
	await process_frame
	if bool(system_menu.call("is_open")):
		push_error("System menu Resume button did not hide the menu")
		quit(1)
		return
	system_menu.call("open")
	close_menu_button.emit_signal("pressed")
	await process_frame
	if bool(system_menu.call("is_open")):
		push_error("System menu Close button did not hide the menu")
		quit(1)
		return
	system_menu.call("open")
	var system_escape_event: InputEventKey = InputEventKey.new()
	system_escape_event.pressed = true
	system_escape_event.keycode = KEY_ESCAPE
	system_menu.call("_input", system_escape_event)
	if bool(system_menu.call("is_open")):
		push_error("System menu Esc close path did not hide the menu")
		quit(1)
		return
	system_menu.call("open")
	var system_cancel_event: InputEventAction = InputEventAction.new()
	system_cancel_event.action = "cancel_action"
	system_cancel_event.pressed = true
	system_menu.call("_input", system_cancel_event)
	if bool(system_menu.call("is_open")):
		push_error("System menu cancel action did not hide the menu")
		quit(1)
		return
	system_menu.queue_free()
	await process_frame

	# Cozy UI foundation: inventory and land panels should instantiate, show
	# visible close paths, and render their core readable content.
	var inventory_panel_scene: PackedScene = load("res://ui/inventory_panel.tscn") as PackedScene
	if inventory_panel_scene == null:
		push_error("Inventory panel scene failed explicit load")
		quit(1)
		return
	var inventory_panel: CanvasLayer = inventory_panel_scene.instantiate() as CanvasLayer
	if inventory_panel == null:
		push_error("Inventory panel failed explicit instantiate")
		quit(1)
		return
	get_root().add_child(inventory_panel)
	await process_frame
	inventory_panel.call("setup", Callable(self, "_validation_get_inventory_count"), Callable(self, "_validation_get_identity"))
	inventory_panel.call("open_panel")
	await process_frame
	var inventory_close_button: Button = null
	for button_variant in inventory_panel.find_children("*", "Button", true, false):
		var inventory_button: Button = button_variant as Button
		if inventory_button != null and String(inventory_button.text).begins_with("Close"):
			inventory_close_button = inventory_button
			break
	if inventory_close_button == null:
		push_error("Inventory panel is missing a visible Close button")
		quit(1)
		return
	if inventory_panel.find_children("InventorySlot_*", "Panel", true, false).is_empty():
		push_error("Inventory panel did not render cozy item slots")
		quit(1)
		return
	inventory_close_button.emit_signal("pressed")
	await process_frame
	if inventory_panel.visible:
		push_error("Inventory panel Close button did not hide the panel")
		quit(1)
		return
	inventory_panel.queue_free()
	await process_frame

	var land_panel_scene: PackedScene = load("res://ui/land_panel.tscn") as PackedScene
	if land_panel_scene == null:
		push_error("Land panel scene failed explicit load")
		quit(1)
		return
	var land_panel: CanvasLayer = land_panel_scene.instantiate() as CanvasLayer
	if land_panel == null:
		push_error("Land panel failed explicit instantiate")
		quit(1)
		return
	get_root().add_child(land_panel)
	await process_frame
	land_panel.call("setup", Callable(self, "_validation_claim_plot"))
	land_panel.call("open_for_plot", {
		"plot_id": "validator_plot",
		"display_name": "Validator Meadow",
		"size_text": "30x30 tiles",
		"status_text": "Unclaimed",
		"owner": "Unclaimed",
		"members": 0,
		"cost": 1,
		"tokens": 1,
		"permission_text": "You can claim this plot.",
		"can_claim": true,
	})
	await process_frame
	var land_close_button: Button = null
	for button_variant in land_panel.find_children("*", "Button", true, false):
		var land_button: Button = button_variant as Button
		if land_button != null and land_button.text == "Close":
			land_close_button = land_button
			break
	if land_close_button == null:
		push_error("Land panel is missing a visible Close button")
		quit(1)
		return
	land_close_button.emit_signal("pressed")
	await process_frame
	if land_panel.visible:
		push_error("Land panel Close button did not hide the panel")
		quit(1)
		return
	land_panel.queue_free()
	await process_frame

	var hud_scene: PackedScene = load("res://ui/prototype_hud.tscn") as PackedScene
	if hud_scene == null:
		push_error("Prototype HUD scene failed explicit load")
		quit(1)
		return
	var prototype_hud: CanvasLayer = hud_scene.instantiate() as CanvasLayer
	if prototype_hud == null:
		push_error("Prototype HUD scene failed explicit instantiate")
		quit(1)
		return
	get_root().add_child(prototype_hud)
	await process_frame
	for required_method in ["set_identity_line", "set_area_line", "set_mode_text", "set_materials_text"]:
		if not prototype_hud.has_method(required_method):
			push_error("Prototype HUD is missing method '%s'" % required_method)
			quit(1)
			return
	var controls_label: Label = prototype_hud.get_node_or_null("Panel/Rows/ControlsLabel") as Label
	if controls_label == null:
		push_error("Prototype HUD is missing ControlsLabel")
		quit(1)
		return
	for required_hint in ["Esc Menu", "I Inv", "B Build", "E Edit", "M Map", "H Help", "F11"]:
		if not controls_label.text.contains(required_hint):
			push_error("Prototype HUD controls line is missing '%s'" % required_hint)
			quit(1)
			return
	# Top-left HUD must be a clean, compact, composed status card.
	if controls_label.visible:
		push_error("Prototype HUD controls line must be hidden by default (controls live in Help/System)")
		quit(1)
		return
	var hud_title: Label = prototype_hud.get_node_or_null("Panel/Rows/TitleLabel") as Label
	if hud_title == null or not hud_title.text.contains("Hearthvale"):
		push_error("Prototype HUD is missing its 'Hearthvale' title header")
		quit(1)
		return
	var hud_rows: Node = prototype_hud.get_node_or_null("Panel/Rows")
	var hud_visible_labels: int = 0
	if hud_rows != null:
		for row_child in hud_rows.get_children():
			if row_child is Label and (row_child as Label).visible:
				hud_visible_labels += 1
	if hud_visible_labels > 8:
		push_error("Prototype HUD has too many visible text rows (%d) — keep it a compact status card" % hud_visible_labels)
		quit(1)
		return
	var prototype_hud_source: String = FileAccess.get_file_as_string("res://ui/prototype_hud.gd")
	if not prototype_hud_source.contains("CozyUITheme.apply_hud_panel"):
		push_error("Prototype HUD no longer applies the shared cozy HUD style")
		quit(1)
		return
	if not prototype_hud_source.contains("_compose_card") or not prototype_hud_source.contains("_insert_hud_divider_after"):
		push_error("Prototype HUD is no longer composed into a tiered status card (title/divider/sections)")
		quit(1)
		return
	prototype_hud.queue_free()
	await process_frame

	# Admin/world-builder panel: terrain paint controls must exist for the first
	# pass terrain authoring workflow.
	var admin_panel_scene: PackedScene = load("res://ui/admin_panel.tscn") as PackedScene
	if admin_panel_scene == null:
		push_error("Admin panel scene failed to load")
		quit(1)
		return
	var admin_panel: CanvasLayer = admin_panel_scene.instantiate() as CanvasLayer
	if admin_panel == null:
		push_error("Admin panel scene failed to instantiate")
		quit(1)
		return
	get_root().add_child(admin_panel)
	await process_frame
	for required_method in ["setup", "toggle_panel", "close_panel"]:
		if not admin_panel.has_method(required_method):
			push_error("Admin panel is missing method '%s'" % required_method)
			quit(1)
			return
	var terrain_picker: OptionButton = null
	var terrain_buttons_found: Dictionary = {"Brush": false, "Fill": false, "Reset": false}
	var clear_placements_button_found: bool = false
	var admin_close_button: Button = null
	for child_variant in admin_panel.find_children("*", "OptionButton", true, false):
		var option_button: OptionButton = child_variant as OptionButton
		if option_button != null and option_button.item_count >= 11:
			terrain_picker = option_button
	for button_variant in admin_panel.find_children("*", "Button", true, false):
		var button: Button = button_variant as Button
		if button != null and terrain_buttons_found.has(button.text):
			terrain_buttons_found[button.text] = true
		if button != null and button.text == "Clear Local Test Placements":
			clear_placements_button_found = true
		if button != null and button.text == "Close":
			admin_close_button = button
	if terrain_picker == null:
		push_error("Admin panel is missing the terrain paint picker")
		quit(1)
		return
	var required_terrain_labels: Array[String] = [
		"Meadow", "Forest", "Orchard", "Creekside", "Hilltop", "Grove",
		"Town", "Farmland", "Dirt Path", "Stone Path", "Water",
	]
	for terrain_label in required_terrain_labels:
		var found_label: bool = false
		for index in range(terrain_picker.item_count):
			if terrain_picker.get_item_text(index) == terrain_label:
				found_label = true
				break
		if not found_label:
			push_error("Admin terrain picker is missing '%s'" % terrain_label)
			quit(1)
			return
	for button_text in terrain_buttons_found.keys():
		if not bool(terrain_buttons_found[button_text]):
			push_error("Admin terrain paint control '%s' is missing" % button_text)
			quit(1)
			return
	if not clear_placements_button_found:
		push_error("Admin panel is missing the Clear Local Test Placements button")
		quit(1)
		return
	if admin_close_button == null:
		push_error("Admin panel is missing a visible Close button")
		quit(1)
		return
	admin_panel.queue_free()
	await process_frame

	# Parcel/world-builder helpers: scripts parse, expose their expected APIs,
	# and the parcel preview still round-trips an inclusive two-corner rect.
	var parcel_preview_script: Script = load("res://systems/parcel_preview.gd") as Script
	var parcel_preview: Node2D = null
	if parcel_preview_script != null:
		parcel_preview = parcel_preview_script.new() as Node2D
	if parcel_preview == null:
		push_error("ParcelPreview script failed to load/instantiate")
		quit(1)
		return
	for required_method in ["setup", "set_corners", "pending_rect", "clear"]:
		if not parcel_preview.has_method(required_method):
			push_error("ParcelPreview is missing method '%s'" % required_method)
			quit(1)
			return
	parcel_preview.call("set_corners", Vector2i(2, 3), Vector2i(5, 7), "grove")
	if parcel_preview.call("pending_rect") != Rect2i(2, 3, 4, 5):
		push_error("ParcelPreview pending_rect no longer matches the staked corners")
		quit(1)
		return
	parcel_preview.call("clear")
	parcel_preview.free()
	var world_builder_overlay_script: Script = load("res://systems/world_builder_overlay.gd") as Script
	var world_builder_overlay: Node2D = null
	if world_builder_overlay_script != null:
		world_builder_overlay = world_builder_overlay_script.new() as Node2D
	if world_builder_overlay == null:
		push_error("WorldBuilderOverlay script failed to load/instantiate")
		quit(1)
		return
	for required_method in ["setup", "toggle", "refresh"]:
		if not world_builder_overlay.has_method(required_method):
			push_error("WorldBuilderOverlay is missing method '%s'" % required_method)
			quit(1)
			return
	world_builder_overlay.free()

	# Lightweight save-helper sanity: defaults must be returned with no save file.
	var save_system: LocalSaveSystem = LocalSaveSystem.new()
	if save_system.get_current_mood().is_empty():
		push_error("Save helper get_current_mood returned empty default")
		quit(1)
		return
	if save_system.get_day_count() < 1:
		push_error("Save helper get_day_count returned invalid default")
		quit(1)
		return
	# Overworld/instance helpers must return dictionaries (defensive defaults).
	var _ow: Dictionary = save_system.get_overworld_flags()
	var _inst: Dictionary = save_system.get_instance_state("none")
	save_system.free()

	# Shared iso grid helper must match the original formula and round-trip cleanly.
	if IsoMapHelpers.grid_to_world(Vector2i(1, 0), 64, 32) != Vector2(32, 16):
		push_error("IsoMapHelpers.grid_to_world regression")
		quit(1)
		return
	for tile in [Vector2i(0, 0), Vector2i(7, 11), Vector2i(15, 10), Vector2i(21, 17)]:
		var round_trip: Vector2i = IsoMapHelpers.world_to_grid(IsoMapHelpers.grid_to_world(tile, 64, 32), 64, 32)
		if round_trip != tile:
			push_error("IsoMapHelpers grid round-trip mismatch for %s -> %s" % [tile, round_trip])
			quit(1)
			return

	# Content ids must equal the exact strings already used in saves and dict keys.
	# A mismatch here would silently break save compatibility.
	var id_pairs: Array = [
		[ContentIds.ITEM_CARROT, "carrot"],
		[ContentIds.ITEM_TURNIP, "turnip"],
		[ContentIds.ITEM_BERRY, "berry"],
		[ContentIds.ITEM_PLACEHOLDER_SEED_PACKET, "placeholder_seed_packet"],
		[ContentIds.PLACEABLE_MAILBOX, "mailbox"],
		[ContentIds.AREA_HOMESTEAD, "homestead"],
		[ContentIds.AREA_VILLAGE_SQUARE, "village_square"],
		[ContentIds.AREA_FOREST_EDGE, "forest_edge"],
		[ContentIds.TASK_WATER_GARDEN, "mock_water_garden"],
		[ContentIds.TASK_HARVEST_CARROT, "mock_harvest_carrot"],
		[TaskIntegrationSystem.WATER_GARDEN_TASK_ID, "mock_water_garden"],
		[TaskIntegrationSystem.HARVEST_CARROT_TASK_ID, "mock_harvest_carrot"],
		# Adopted controller constants must still resolve to their original strings.
		[HomesteadController.REGION_ID, "homestead"],
		[HomesteadController.CARROT_ITEM_ID, "carrot"],
		[HomesteadController.TURNIP_ITEM_ID, "turnip"],
		[HomesteadController.BERRY_ITEM_ID, "berry"],
		[HomesteadController.FARM_PLOT_CARROT_ID, "farm_plot_carrot"],
		[HomesteadController.FARM_PLOT_TURNIP_ID, "farm_plot_turnip"],
		[HomesteadController.FARM_PLOT_BERRY_ID, "farm_plot_berry"],
		[HomesteadController.LEGACY_FARM_PLOT_ID, "farm_plot_main"],
		[OverworldController.VILLAGE_REGION_ID, "village_square"],
		[OverworldController.FOREST_REGION_ID, "forest_edge"],
		[OverworldController.MARIBEL_INTRO_FLAG, "maribel_intro_seen"],
		[OverworldController.BRAM_INTRO_FLAG, "bram_intro_seen"],
		[OverworldController.NOTICE_SEEN_FLAG, "notice_board_seen"],
		[OverworldController.SHRINE_SEEN_FLAG, "adventure_marker_seen"],
		# Interaction type ids (now centralized through ContentIds.INTERACTION_*).
		[ContentIds.INTERACTION_MAILBOX, "mailbox"],
		[ContentIds.INTERACTION_FARM_PLOT, "farm_plot"],
		[ContentIds.INTERACTION_AMBIENT_CREATURE, "ambient_creature"],
		[ContentIds.INTERACTION_VILLAGER, "villager"],
		[ContentIds.INTERACTION_NOTICE_BOARD, "notice_board"],
		[ContentIds.INTERACTION_SHRINE_MARKER, "shrine_marker"],
		[ContentIds.INTERACTION_REST, "rest"],
		[ContentIds.INTERACTION_REGION_TRANSITION, "region_transition"],
		[ContentIds.INTERACTION_TASK_BOARD, "task_board"],
		[ContentIds.INTERACTION_GENERIC, "generic"],
		# Action ids (what the player can do; values from get_available_actions).
		[ContentIds.ACTION_CHECK_MAIL, "check_mail"],
		[ContentIds.ACTION_TEND_PLOT, "tend_plot"],
		[ContentIds.ACTION_READ_NOTICE, "read_notice"],
		[ContentIds.ACTION_TRAVEL, "travel"],
		[ContentIds.ACTION_REVIEW_TASKS, "review_tasks"],
		[ContentIds.ACTION_OBSERVE, "observe"],
		[ContentIds.ACTION_TALK, "talk"],
		[ContentIds.ACTION_REST, "rest"],
		[ContentIds.ACTION_INSPECT, "inspect"],
	]
	for pair in id_pairs:
		if String(pair[0]) != String(pair[1]):
			push_error("Content id mismatch: got '%s', expected '%s'" % [pair[0], pair[1]])
			quit(1)
			return
	if not ContentRegistry.items().has(ContentIds.ITEM_PLACEHOLDER_SEED_PACKET):
		push_error("Seed packet item id is missing from ContentRegistry.items(), so quickbar assignment cannot plant seeds")
		quit(1)
		return

	# No critical id may be empty.
	for critical_id in [
		ContentIds.ITEM_CARROT, ContentIds.PLACEABLE_MAILBOX,
		ContentIds.AREA_HOMESTEAD, ContentIds.AREA_VILLAGE_SQUARE, ContentIds.AREA_FOREST_EDGE,
		ContentIds.INTERACTION_MAILBOX, ContentIds.INTERACTION_FARM_PLOT, ContentIds.INTERACTION_VILLAGER,
		ContentIds.INTERACTION_AMBIENT_CREATURE, ContentIds.INTERACTION_NOTICE_BOARD,
		ContentIds.INTERACTION_SHRINE_MARKER, ContentIds.INTERACTION_REST, ContentIds.INTERACTION_GENERIC,
		ContentIds.ACTION_CHECK_MAIL, ContentIds.ACTION_TEND_PLOT, ContentIds.ACTION_OBSERVE,
		ContentIds.ACTION_TALK, ContentIds.ACTION_REST, ContentIds.ACTION_INSPECT,
	]:
		if String(critical_id).is_empty():
			push_error("Critical content id is empty")
			quit(1)
			return

	# ContentRegistry must return the expected display names (display-only metadata).
	var name_pairs: Array = [
		[String((ContentRegistry.items().get(ContentIds.ITEM_CARROT, {}) as Dictionary).get("display_name", "")), "Carrot"],
		[String((ContentRegistry.placeables().get(ContentIds.PLACEABLE_MAILBOX, {}) as Dictionary).get("display_name", "")), "Cozy Mailbox"],
		[ContentRegistry.area_display_name(ContentIds.AREA_HOMESTEAD), "Homestead"],
		[ContentRegistry.area_display_name(ContentIds.AREA_VILLAGE_SQUARE), "Village Square"],
		[ContentRegistry.area_display_name(ContentIds.AREA_FOREST_EDGE), "Forest Edge"],
	]
	for pair in name_pairs:
		if String(pair[0]) != String(pair[1]):
			push_error("ContentRegistry display-name mismatch: got '%s', expected '%s'" % [pair[0], pair[1]])
			quit(1)
			return

	# Phase-1 inheritance chain: HomesteadController -> OutdoorAreaController, and
	# OverworldController -> HomesteadController -> OutdoorAreaController.
	var homestead_controller: HomesteadController = HomesteadController.new()
	var homestead_chain_ok: bool = homestead_controller is OutdoorAreaController
	# Generic observe/message-panel lifecycle must live on the shared base.
	var panel_api_ok: bool = (
		homestead_controller.has_method("_open_observe_panel")
		and homestead_controller.has_method("_close_observe_panel")
		and homestead_controller.has_method("is_observe_panel_open")
	)
	# Generic interactable-registration plumbing must live on the shared base too.
	var registration_api_ok: bool = (
		homestead_controller.has_method("register_world_interactable")
		and homestead_controller.has_method("unregister_world_interactable")
		and homestead_controller.has_method("get_world_interactable_data")
		and homestead_controller.has_method("_dispatch_world_interactable")
	)
	# Phase-4 setup orchestration hooks must be present (added in Chunk 10 step 1).
	var setup_hooks_ok: bool = (
		homestead_controller.has_method("_setup_area_content")
		and homestead_controller.has_method("_after_area_setup")
	)
	homestead_controller.free()
	if not homestead_chain_ok:
		push_error("HomesteadController no longer extends OutdoorAreaController")
		quit(1)
		return
	if not panel_api_ok:
		push_error("Observe panel lifecycle missing from the outdoor controller chain")
		quit(1)
		return
	if not registration_api_ok:
		push_error("World interactable registration plumbing missing from the outdoor controller chain")
		quit(1)
		return
	if not setup_hooks_ok:
		push_error("Setup orchestration hooks (_setup_area_content/_after_area_setup) missing from the outdoor controller chain")
		quit(1)
		return

	var overworld_controller: OverworldController = OverworldController.new()
	var overworld_chain_ok: bool = (overworld_controller is HomesteadController) and (overworld_controller is OutdoorAreaController)
	overworld_controller.free()
	if not overworld_chain_ok:
		push_error("OverworldController inheritance chain regressed")
		quit(1)
		return

	# Character appearance foundation: defaults must be complete and stable,
	# unknown ids must normalize to defaults, and the save helper must always
	# return a valid (already-normalized) appearance dict.
	var default_appearance: Dictionary = CharacterAppearance.default_appearance()
	if CharacterAppearance.normalized({}) != default_appearance:
		push_error("Empty appearance did not normalize to the default appearance")
		quit(1)
		return
	if CharacterAppearance.normalized(default_appearance) != default_appearance:
		push_error("Default appearance contains an id missing from the registry")
		quit(1)
		return
	var junk_appearance: Dictionary = CharacterAppearance.normalized({
		"hair_style": "not_a_style",
		"outfit_color": "not_a_color",
		"accessory": "tiny_hat",
	})
	if String(junk_appearance.get("hair_style", "")) != String(default_appearance["hair_style"]):
		push_error("Unknown hair_style id did not fall back to the default")
		quit(1)
		return
	if String(junk_appearance.get("accessory", "")) != "tiny_hat":
		push_error("Valid accessory id was not preserved through normalization")
		quit(1)
		return

	# The dev character creator toggle must stay a real InputMap action (bound
	# to F9 logical + physical) â€” an exact-keycode check broke on Fn-layer
	# keyboards once already.
	if not InputMap.has_action("toggle_character_creator"):
		push_error("InputMap action 'toggle_character_creator' is missing from project.godot")
		quit(1)
		return

	var appearance_save_system: LocalSaveSystem = LocalSaveSystem.new()
	var saved_appearance: Dictionary = appearance_save_system.get_player_appearance()
	if CharacterAppearance.normalized(saved_appearance) != saved_appearance:
		push_error("get_player_appearance returned a non-normalized appearance")
		quit(1)
		return
	appearance_save_system.free()

	# --- Persistent-world pass: materials, costs, placeables -------------------
	var material_inventory: MaterialInventory = MaterialInventory.from_dictionary({"wood": 3, "bogus": 5})
	material_inventory.add(ResourceIds.MATERIAL_STONE, 2)
	if material_inventory.get_count("wood") != 3 or material_inventory.get_count("bogus") != 0:
		push_error("MaterialInventory failed to filter/load material counts")
		quit(1)
		return
	if material_inventory.spend({"wood": 5}):
		push_error("MaterialInventory allowed overspending")
		quit(1)
		return
	if not material_inventory.spend({"wood": 2, "stone": 1}) or material_inventory.get_count("wood") != 1:
		push_error("MaterialInventory spend math is wrong")
		quit(1)
		return

	var all_placeables: Dictionary = ContentRegistry.placeables()
	var cost_table: Dictionary = BuildCosts.costs()
	for placeable_id in all_placeables.keys():
		var entry: Dictionary = all_placeables[placeable_id] as Dictionary
		for required_field in ["id", "display_name", "scene_path", "footprint", "category"]:
			if not entry.has(required_field):
				push_error("Placeable '%s' registry entry missing field '%s'" % [placeable_id, required_field])
				quit(1)
				return
		if not cost_table.has(placeable_id):
			push_error("Placeable '%s' has no BuildCosts entry" % placeable_id)
			quit(1)
			return
		for material_id in (cost_table[placeable_id] as Dictionary).keys():
			if not ResourceIds.is_storable(String(material_id)):
				push_error("Placeable '%s' cost uses unknown material/component '%s'" % [placeable_id, material_id])
				quit(1)
				return
		var placeable_scene: PackedScene = load(String(entry["scene_path"])) as PackedScene
		if placeable_scene == null:
			push_error("Placeable '%s' scene failed to load" % placeable_id)
			quit(1)
			return
		var placeable_instance: Node = placeable_scene.instantiate()
		if not (placeable_instance is PlaceableCrate):
			push_error("Placeable '%s' root does not extend PlaceableCrate" % placeable_id)
			placeable_instance.free()
			quit(1)
			return
		placeable_instance.free()
	for decor_id in ContentIds.DECOR_PLACEABLE_IDS:
		if not all_placeables.has(decor_id):
			push_error("Decor id '%s' missing from ContentRegistry.placeables()" % decor_id)
			quit(1)
			return

	# --- Persistent-world pass: profiles ---------------------------------------
	var default_profile: Dictionary = LocalProfile.create_default()
	var renormalized_profile: Dictionary = LocalProfile.normalized(default_profile)
	if String(renormalized_profile.get("profile_id", "")).is_empty():
		push_error("Default profile lost its profile_id through normalization")
		quit(1)
		return
	if CharacterAppearance.normalized(renormalized_profile["appearance"] as Dictionary) != renormalized_profile["appearance"]:
		push_error("Default profile appearance is not normalized")
		quit(1)
		return

	# New customization ids must all survive normalization (registry + builder).
	var expanded_appearance: Dictionary = CharacterAppearance.normalized({
		"hair_style": "leafy_pigtails", "hair_color": "berry_red", "skin_tone": "umber",
		"outfit_style": "mushroom_sweater", "outfit_color": "pond_blue", "accessory": "acorn_cap",
	})
	if String(expanded_appearance["hair_style"]) != "leafy_pigtails" or String(expanded_appearance["accessory"]) != "acorn_cap":
		push_error("Expanded customization ids did not survive normalization")
		quit(1)
		return

	# --- Persistent-world pass: server + network --------------------------------
	var default_world: Dictionary = ServerSaveSystem.create_default_world("validation_world")
	for world_field in ["world_id", "created_at", "updated_at", "placed_objects", "world_flags", "known_profiles"]:
		if not default_world.has(world_field):
			push_error("Server world default missing field '%s'" % world_field)
			quit(1)
			return
	var world_state: ServerWorldState = ServerWorldState.from_world(default_world)
	var committed: Dictionary = world_state.add_placed_object("crate", 4, 4, "profile_test", "Tester")
	if committed.is_empty() or not NetworkMessages.is_valid_placed_object(committed):
		push_error("ServerWorldState failed to commit a valid placed object")
		quit(1)
		return
	if not world_state.add_placed_object("crate", 4, 4, "profile_test", "Tester").is_empty():
		push_error("ServerWorldState allowed double placement on one tile")
		quit(1)
		return
	var roundtrip_world: Dictionary = ServerSaveSystem.normalize_world(default_world)
	if (roundtrip_world["placed_objects"] as Array).size() != 1:
		push_error("Server world normalize dropped a valid placed object")
		quit(1)
		return

	var identity: Dictionary = PlayerIdentity.normalized({"display_name": "  ", "appearance": {"hair_style": "junk"}})
	if String(identity["display_name"]).is_empty():
		push_error("PlayerIdentity allowed an empty display name")
		quit(1)
		return

	if NetworkMode.OFFLINE != "offline":
		push_error("NetworkMode.OFFLINE changed; offline-default contract broken")
		quit(1)
		return

	if not InputMap.has_action("toggle_network_panel"):
		push_error("InputMap action 'toggle_network_panel' is missing from project.godot")
		quit(1)
		return

	# Usability/input pass: the fullscreen/menu/minimap actions must exist, plus
	# the controller-ready interact/confirm/cancel/edit actions added for this
	# playtest repair pass.
	for required_action in [
		"toggle_fullscreen", "toggle_inventory", "toggle_help", "toggle_minimap",
		"toggle_admin_panel", "toggle_system_menu", "interact_primary",
		"confirm_action", "cancel_action", "edit_move", "edit_rotate", "edit_delete",
	]:
		if not InputMap.has_action(required_action):
			push_error("InputMap action '%s' is missing from project.godot" % required_action)
			quit(1)
			return
	var fullscreen_has_f11: bool = false
	for event_variant in InputMap.action_get_events("toggle_fullscreen"):
		var fullscreen_event: InputEventKey = event_variant as InputEventKey
		if fullscreen_event != null and (
			fullscreen_event.keycode == KEY_F11 or fullscreen_event.physical_keycode == KEY_F11
		):
			fullscreen_has_f11 = true
			break
	if not fullscreen_has_f11:
		push_error("InputMap action 'toggle_fullscreen' is missing an F11 binding")
		quit(1)
		return
	var controller_move_actions: Array[String] = ["move_up", "move_down", "move_left", "move_right"]
	for move_action in controller_move_actions:
		var has_joypad_motion: bool = false
		for event_variant in InputMap.action_get_events(move_action):
			if event_variant is InputEventJoypadMotion:
				has_joypad_motion = true
				break
		if not has_joypad_motion:
			push_error("Movement action '%s' is missing a joypad axis binding" % move_action)
			quit(1)
			return
	var controller_button_actions: Array[String] = [
		"interact_primary", "confirm_action", "cancel_action",
		"edit_move", "edit_rotate", "edit_delete", "toggle_system_menu",
	]
	for button_action in controller_button_actions:
		var has_joypad_button: bool = false
		for event_variant in InputMap.action_get_events(button_action):
			if event_variant is InputEventJoypadButton:
				has_joypad_button = true
				break
		if not has_joypad_button:
			push_error("Action '%s' is missing a controller button binding" % button_action)
			quit(1)
			return
	var display_settings_source: String = FileAccess.get_file_as_string("res://ui/display_settings.gd")
	for required_snippet in [
		"WINDOW_FLAG_BORDERLESS",
		"WINDOW_MODE_WINDOWED",
		"WINDOW_MODE_FULLSCREEN",
		"config.get_value(\"display\", \"fullscreen\", false)",
		"MAX_WINDOWED_SIZE := Vector2i(1280, 720)",
		"MIN_WINDOWED_SIZE := Vector2i(960, 540)",
		"WINDOWED_SCREEN_MARGIN := Vector2i(120, 140)",
		# Windowed mode must clear borderless AND size/center the window so the OS
		# title bar/borders are visible (the 1080p screen-sized regression).
		"DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)",
		"_fit_windowed_to_screen",
		"screen_get_usable_rect",
		"window_set_size",
		"window_set_position",
	]:
		if not display_settings_source.contains(required_snippet):
			push_error("DisplaySettings is missing the bordered-window/fullscreen helper path '%s'" % required_snippet)
			quit(1)
			return
	var project_settings_source: String = FileAccess.get_file_as_string("res://project.godot")
	if not project_settings_source.contains("window/size/viewport_width=1280") or not project_settings_source.contains("window/size/viewport_height=720"):
		push_error("project.godot default window must be 1280x720 so UI/layout match the LimeZu asset scale")
		quit(1)
		return
	if project_settings_source.contains("window/size/viewport_width=1600") or project_settings_source.contains("window/size/viewport_height=900"):
		push_error("project.godot still contains the oversized 1600x900 prototype window size")
		quit(1)
		return
	if project_settings_source.contains("window/size/viewport_width=1920") or project_settings_source.contains("window/size/viewport_height=1080"):
		push_error("project.godot still contains the old screen-filling 1920x1080 default window size")
		quit(1)
		return
	# The live overworld must NOT draw the big alpha-0.62 region-tint color discs
	# in normal play (they read as ugly debug blocks); biome differentiation lives
	# in the terrain tiles + the admin/world-builder overlay.
	var display_overworld_map_source: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	if display_overworld_map_source.contains("add_disc(_bg_layer(), Vector2(60, 300)"):
		push_error("OverworldMap still draws the large region-tint color discs in normal play")
		quit(1)
		return
	if not display_overworld_map_source.contains("BACKDROP_GRASS"):
		push_error("OverworldMap backdrop is not using the calm grass tone")
		quit(1)
		return
	if not display_overworld_map_source.contains("pass") or not display_overworld_map_source.contains("_build_region_tints"):
		push_error("OverworldMap no longer makes normal-play region tints an explicit no-op")
		quit(1)
		return
	var homestead_controller_source: String = FileAccess.get_file_as_string("res://world/homestead_controller.gd")
	for required_snippet in [
		"SYSTEM_MENU_SCENE := preload(\"res://ui/system_menu.tscn\")",
		"_system_menu = SYSTEM_MENU_SCENE.instantiate()",
		"_system_menu.connect(\"close_requested\", _on_system_menu_closed)",
		"event.is_action_pressed(\"toggle_system_menu\")",
		"Interior coming later.",
	]:
		if not homestead_controller_source.contains(required_snippet):
			push_error("HomesteadController is missing system-menu wiring snippet '%s'" % required_snippet)
			quit(1)
			return
	var interactable_source: String = FileAccess.get_file_as_string("res://systems/interactable_system.gd")
	if not interactable_source.contains("event.is_action_pressed(\"interact_primary\")"):
		push_error("InteractableSystem no longer uses the interact_primary action")
		quit(1)
		return

	# --- Server run/external-access pass ----------------------------------------
	for required_file in [
		"res://tools/run_server_local.ps1",
		"res://tools/run_server_public.ps1",
		"res://tools/run_client_local.ps1",
		"res://tools/run_client_editor.ps1",
		"res://tools/open_firewall_server_port.ps1",
		"res://tools/remove_firewall_server_port.ps1",
		"res://server/server_config.example.json",
		"res://docs/external_server_access.md",
		"res://docs/run_local_server.md",
		"res://docs/run_local_playtest.md",
		"res://docs/playtest_readiness.md",
		"res://docs/visual_identity.md",
		"res://docs/ui_style_guide.md",
		"res://docs/world_art_direction.md",
		"res://docs/building_art_direction.md",
		"res://docs/interiors_plan.md",
	]:
		if not FileAccess.file_exists(required_file):
			push_error("Required playtest file missing: %s" % required_file)
			quit(1)
			return

	# Server config resolution: defaults < config file values < CLI args.
	var config_defaults: Dictionary = ServerConfig.defaults()
	for config_key in ["bind_address", "port", "world", "max_players", "save_on_change", "log_connections"]:
		if not config_defaults.has(config_key):
			push_error("ServerConfig.defaults() missing key '%s'" % config_key)
			quit(1)
			return
	var resolved_config: Dictionary = ServerConfig.resolve(["--port=9001", "--bind=0.0.0.0", "--max-players=4"])
	if int(resolved_config["port"]) != 9001 or String(resolved_config["bind_address"]) != "*" or int(resolved_config["max_players"]) != 4:
		push_error("ServerConfig.resolve() did not apply CLI overrides correctly")
		quit(1)
		return
	if not ServerConfig.resolve(["--port=999999"]).get("port", 0) == ServerConfig.DEFAULT_PORT:
		push_error("ServerConfig accepted an out-of-range port")
		quit(1)
		return
	var example_config: Dictionary = ServerConfig.load_config_file("res://server/server_config.example.json")
	var merged_example: Dictionary = ServerConfig.merge(config_defaults, example_config)
	if int(merged_example["max_players"]) != 8 or String(merged_example["bind_address"]) != "*":
		push_error("server_config.example.json did not merge as expected")
		quit(1)
		return
	if ServerConfig.normalize_bind("not_an_ip") != "" or ServerConfig.normalize_bind("192.168.1.10") != "192.168.1.10":
		push_error("ServerConfig.normalize_bind() validation regressed")
		quit(1)
		return
	if ServerConfig.is_externally_reachable("127.0.0.1") or not ServerConfig.is_externally_reachable("*"):
		push_error("ServerConfig.is_externally_reachable() logic regressed")
		quit(1)
		return

	# --- Gathering + chat pass ----------------------------------------------------
	var seen_node_ids: Dictionary = {}
	var yield_definitions: Dictionary = ResourceNode.definitions()
	for spawn_variant in ResourceSpawnRegistry.definitions():
		var spawn: Dictionary = spawn_variant as Dictionary
		var spawn_node_id: String = String(spawn.get("node_id", ""))
		if spawn_node_id.is_empty() or seen_node_ids.has(spawn_node_id):
			push_error("ResourceSpawnRegistry has a missing/duplicate node_id: '%s'" % spawn_node_id)
			quit(1)
			return
		seen_node_ids[spawn_node_id] = true
		var spawn_type: String = String(spawn.get("type", ""))
		if not yield_definitions.has(spawn_type):
			push_error("ResourceSpawnRegistry node '%s' has unknown type '%s'" % [spawn_node_id, spawn_type])
			quit(1)
			return
		var yield_material: String = String((yield_definitions[spawn_type] as Dictionary).get("material_id", ""))
		if not ResourceIds.is_material(yield_material):
			push_error("Resource type '%s' yields unknown material '%s'" % [spawn_type, yield_material])
			quit(1)
			return
		if not ["homestead", "village", "forest"].has(String(spawn.get("anchor", ""))):
			push_error("ResourceSpawnRegistry node '%s' has unknown anchor" % spawn_node_id)
			quit(1)
			return
	if seen_node_ids.size() < 8:
		push_error("Expected at least 8 gatherable nodes, found %d" % seen_node_ids.size())
		quit(1)
		return
	if ResourceSpawnRegistry.has_node_id("not_a_real_node"):
		push_error("ResourceSpawnRegistry.has_node_id() matched a bogus id")
		quit(1)
		return

	if ChatMessage.sanitize("   ") != "" or ChatMessage.is_sendable("  \n "):
		push_error("ChatMessage failed to reject empty/whitespace messages")
		quit(1)
		return
	var long_message: String = "a".repeat(ChatMessage.MAX_LENGTH + 50)
	if ChatMessage.sanitize(long_message).length() != ChatMessage.MAX_LENGTH:
		push_error("ChatMessage failed to cap message length")
		quit(1)
		return
	if ChatMessage.sanitize("hi\nthere\t friend") != "hi there friend":
		push_error("ChatMessage failed to collapse whitespace/newlines")
		quit(1)
		return

	# --- Crafting pass --------------------------------------------------------------
	var recipe_table: Dictionary = CraftingRegistry.recipes()
	if recipe_table.is_empty():
		push_error("CraftingRegistry has no recipes")
		quit(1)
		return
	for recipe_key in recipe_table.keys():
		var recipe: Dictionary = recipe_table[recipe_key] as Dictionary
		if String(recipe.get("recipe_id", "")) != String(recipe_key):
			push_error("Recipe key '%s' does not match its recipe_id" % recipe_key)
			quit(1)
			return
		var problem: String = CraftingRecipe.validate(recipe)
		if not problem.is_empty():
			push_error("Recipe '%s' invalid: %s" % [recipe_key, problem])
			quit(1)
			return

	# Build costs may use raw materials, components, or crop items â€” nothing else.
	for cost_placeable_id in BuildCosts.costs().keys():
		if not ContentRegistry.placeables().has(String(cost_placeable_id)):
			push_error("BuildCosts references unknown placeable '%s'" % cost_placeable_id)
			quit(1)
			return
		for cost_item_id in (BuildCosts.costs()[cost_placeable_id] as Dictionary).keys():
			if not CraftingRecipe.is_valid_craft_item(String(cost_item_id)):
				push_error("Build cost for '%s' uses unknown id '%s'" % [cost_placeable_id, cost_item_id])
				quit(1)
				return

	# Starter loop sanity: planks must be hand-craftable at level 1 from the
	# multiplayer starter pack, and the offline check/spend math must work.
	var starter_pouch: MaterialInventory = MaterialInventory.starter_pack()
	var plank_check: Dictionary = CraftingSystem.check("craft_plank", starter_pouch.get_count, 1, [])
	if not bool(plank_check["ok"]):
		push_error("Starter materials cannot hand-craft planks: %s" % plank_check["reason"])
		quit(1)
		return
	var plank_result: Dictionary = CraftingSystem.craft_with_pouch("craft_plank", starter_pouch, 1, [])
	if not bool(plank_result["ok"]) or starter_pouch.get_count(ResourceIds.COMPONENT_PLANK) != 2:
		push_error("Pouch plank craft did not grant 2 planks")
		quit(1)
		return
	var blocked_check: Dictionary = CraftingSystem.check("craft_stone_block", starter_pouch.get_count, 1, [])
	if bool(blocked_check["ok"]):
		push_error("Level-2 station recipe was craftable at level 1 with no station")
		quit(1)
		return
	var station_check: Dictionary = CraftingSystem.check(
		"craft_stone_block", starter_pouch.get_count, 2, [ContentIds.PLACEABLE_WORKBENCH]
	)
	if not bool(station_check["ok"]):
		push_error("Workbench recipe denied despite level + station: %s" % station_check["reason"])
		quit(1)
		return

	# Progression model sanity: curve monotonic, levels derive correctly.
	if PlayerProgression.level_for_xp(0) != 1 or PlayerProgression.level_for_xp(25) != 2 or PlayerProgression.level_for_xp(99999) != PlayerProgression.MAX_LEVEL:
		push_error("PlayerProgression level thresholds regressed")
		quit(1)
		return
	for threshold_index in range(1, PlayerProgression.LEVEL_THRESHOLDS.size()):
		if PlayerProgression.LEVEL_THRESHOLDS[threshold_index] <= PlayerProgression.LEVEL_THRESHOLDS[threshold_index - 1]:
			push_error("PlayerProgression XP curve is not strictly increasing")
			quit(1)
			return

	# Skills: unique ids, all defined, normalization (incl. legacy flat shape),
	# grants, level derivation, and unlock checks.
	var seen_skill_ids: Dictionary = {}
	for skill_id in ProgressionRegistry.SKILL_IDS:
		if seen_skill_ids.has(skill_id) or not ProgressionRegistry.skills().has(skill_id):
			push_error("Skill id '%s' duplicated or missing a definition" % skill_id)
			quit(1)
			return
		seen_skill_ids[skill_id] = true
	var default_prog: Dictionary = SkillProgression.default_progression()
	if SkillProgression.normalized({}) != default_prog:
		push_error("Empty progression did not normalize to default")
		quit(1)
		return
	var legacy_prog: Dictionary = SkillProgression.normalized({"xp": 30})
	if int(legacy_prog["total_xp"]) != 30 or SkillProgression.player_level(legacy_prog) != 2:
		push_error("Legacy flat-xp progression shape did not migrate")
		quit(1)
		return
	var grant_check: Dictionary = SkillProgression.grant({}, ProgressionRegistry.SKILL_GATHERING, 25, 25)
	if not bool(grant_check["skill_levelled"]) or not bool(grant_check["player_levelled"]):
		push_error("SkillProgression.grant did not report level-ups at threshold")
		quit(1)
		return
	if SkillProgression.skill_level(grant_check["progression"] as Dictionary, ProgressionRegistry.SKILL_GATHERING) != 2:
		push_error("Skill level did not derive correctly after grant")
		quit(1)
		return
	if ProgressionRegistry.skill_for_material(ResourceIds.MATERIAL_STONE) != ProgressionRegistry.SKILL_MINING \
			or ProgressionRegistry.skill_for_material(ResourceIds.MATERIAL_WOOD) != ProgressionRegistry.SKILL_GATHERING:
		push_error("skill_for_material mapping regressed")
		quit(1)
		return

	# Unlock checks: locked then unlocked, and lock tables reference real ids.
	var arch_lock: Dictionary = ProgressionRegistry.placeable_locks()[ContentIds.PLACEABLE_GARDEN_ARCH] as Dictionary
	if ProgressionRegistry.lock_reason(arch_lock, 1, {"building": 1}).is_empty():
		push_error("Garden arch lock did not deny at Building 1")
		quit(1)
		return
	if not ProgressionRegistry.lock_reason(arch_lock, 1, {"building": 2}).is_empty():
		push_error("Garden arch lock denied despite Building 2")
		quit(1)
		return
	for locked_placeable_id in ProgressionRegistry.placeable_locks().keys():
		if not ContentRegistry.placeables().has(String(locked_placeable_id)):
			push_error("Placeable lock references unknown placeable '%s'" % locked_placeable_id)
			quit(1)
			return
		var placeable_lock: Dictionary = ProgressionRegistry.placeable_locks()[locked_placeable_id] as Dictionary
		var lock_skill: String = String(placeable_lock.get("required_skill", ""))
		if not lock_skill.is_empty() and not ProgressionRegistry.SKILL_IDS.has(lock_skill):
			push_error("Placeable lock for '%s' references unknown skill" % locked_placeable_id)
			quit(1)
			return
	var skill_locked_recipe: Dictionary = CraftingSystem.check(
		"craft_cloth_roll",
		func(_id: String) -> int: return 99,
		PlayerProgression.MAX_LEVEL,
		[ContentIds.PLACEABLE_GARDEN_TABLE],
		{"crafting": 1}
	)
	if bool(skill_locked_recipe["ok"]):
		push_error("Cloth roll craftable despite Crafting 1 (skill lock missing)")
		quit(1)
		return

	# Station placeables exist end-to-end and components are storable.
	for station_id_variant in CraftingRegistry.station_ids():
		if not ContentRegistry.placeables().has(String(station_id_variant)):
			push_error("Recipe station '%s' is not a registered placeable" % station_id_variant)
			quit(1)
			return
	for component_id in ResourceIds.ALL_COMPONENTS:
		if not ResourceIds.is_storable(component_id):
			push_error("Component '%s' is not storable" % component_id)
			quit(1)
			return

	# --- Worldbuilding pass: items, tools, soft-lock, land, identity -----------
	# Item taxonomy: unique ids across every category, wearables map to real
	# appearance accessories.
	var all_item_ids: Dictionary = {}
	for taxonomy_id in ResourceIds.ALL_MATERIALS + ResourceIds.ALL_COMPONENTS + ItemIds.ALL_TOOLS + ItemIds.ALL_WEAPONS + ItemIds.ALL_WEARABLES + ItemIds.ALL_QUEST_ITEMS:
		if all_item_ids.has(taxonomy_id):
			push_error("Duplicate item id across taxonomy: '%s'" % taxonomy_id)
			quit(1)
			return
		all_item_ids[taxonomy_id] = true
	for wearable_id in ItemIds.ALL_WEARABLES:
		var accessory: String = ItemIds.wearable_accessory(wearable_id)
		if not CharacterAppearanceRegistry.accessories().has(accessory):
			push_error("Wearable '%s' maps to unknown accessory '%s'" % [wearable_id, accessory])
			quit(1)
			return

	# Starter soft-lock prevention: every material has a HAND source in the
	# spawn registry, every starter tool recipe is hand-craftable (no station,
	# level 1, no tool-tier inputs), and tool-tier nodes reference real tools.
	var hand_materials: Dictionary = {}
	for spawn_def_variant in ResourceSpawnRegistry.definitions():
		var spawn_def: Dictionary = spawn_def_variant as Dictionary
		var node_yield: Dictionary = ResourceNode.definitions()[String(spawn_def["type"])] as Dictionary
		var node_tool: String = String(node_yield.get("required_tool", ""))
		if node_tool.is_empty():
			hand_materials[String(node_yield["material_id"])] = true
		elif not ItemIds.is_tool_item(node_tool):
			push_error("Resource type '%s' requires unknown tool '%s'" % [spawn_def["type"], node_tool])
			quit(1)
			return
	for base_material in ResourceIds.ALL_MATERIALS:
		if not hand_materials.has(base_material):
			push_error("SOFT-LOCK: material '%s' has no hand-gatherable source" % base_material)
			quit(1)
			return
	for tool_id in ItemIds.ALL_TOOLS:
		var tool_recipe: Dictionary = CraftingRegistry.get_recipe("craft_%s" % tool_id)
		if tool_recipe.is_empty():
			push_error("SOFT-LOCK: starter tool '%s' has no recipe" % tool_id)
			quit(1)
			return
		if not String(tool_recipe.get("required_station", "")).is_empty() or int(tool_recipe.get("required_level", 1)) > 1:
			push_error("SOFT-LOCK: starter tool recipe '%s' is gated behind a station/level" % tool_id)
			quit(1)
			return
		for tool_input in (tool_recipe["inputs"] as Dictionary).keys():
			if not ResourceIds.is_material(String(tool_input)):
				push_error("SOFT-LOCK: starter tool '%s' needs non-raw input '%s'" % [tool_id, tool_input])
				quit(1)
				return
	if not ItemIds.starter_loadout().has(ItemIds.TOOL_SIMPLE_HAMMER):
		push_error("Starter loadout is missing the hammer")
		quit(1)
		return
	# A tree must require the axe (chopping is tool-gated).
	if String((ResourceNode.definitions()[ResourceNode.TYPE_TREE] as Dictionary)["required_tool"]) != ItemIds.TOOL_WORN_AXE:
		push_error("Tree chopping does not require the axe")
		quit(1)
		return

	# Required build tools resolve, terrain takes the shovel.
	for tool_check_id in ContentRegistry.placeables().keys():
		var build_tool: String = ContentRegistry.placeable_required_tool(String(tool_check_id))
		if not ItemIds.is_tool_item(build_tool):
			push_error("Placeable '%s' requires unknown tool '%s'" % [tool_check_id, build_tool])
			quit(1)
			return
	if ContentRegistry.placeable_required_tool(ContentIds.PLACEABLE_DIRT_PATH) != ItemIds.TOOL_BASIC_SHOVEL:
		push_error("Terrain overlays do not require the shovel")
		quit(1)
		return

	# Land: plot ids unique with valid rects/biomes, >= 4 claimable, and the
	# claim/build permission state machine behaves across the expanded lots.
	var plot_ids_seen: Dictionary = {}
	for plot_def_variant in LandRegistry.definitions().values():
		var plot_def: Dictionary = plot_def_variant as Dictionary
		var def_plot_id: String = String(plot_def.get("plot_id", ""))
		if def_plot_id.is_empty() or plot_ids_seen.has(def_plot_id):
			push_error("Land plot id missing/duplicate: '%s'" % def_plot_id)
			quit(1)
			return
		plot_ids_seen[def_plot_id] = true
		var def_rect_variant: Variant = plot_def.get("rect", null)
		if not (def_rect_variant is Rect2i):
			push_error("Land plot '%s' is missing a Rect2i bounds" % def_plot_id)
			quit(1)
			return
		var def_rect: Rect2i = def_rect_variant as Rect2i
		if def_rect.size.x <= 0 or def_rect.size.y <= 0:
			push_error("Land plot '%s' has invalid bounds %s" % [def_plot_id, def_rect])
			quit(1)
			return
		var def_biome: String = String(plot_def.get("biome", ""))
		if not BiomeRegistry.has_biome(def_biome):
			push_error("Land plot '%s' has unknown biome '%s'" % [def_plot_id, def_biome])
			quit(1)
			return
	if LandRegistry.claimable_plot_ids().size() < 4:
		push_error("Fewer than 4 claimable homestead plots defined")
		quit(1)
		return
	var implemented_large_plot_target: int = 24
	# At least 4 default plots must hit the implemented large-lot target.
	var large_plot_ids: Array[String] = []
	for claim_id in LandRegistry.claimable_plot_ids():
		var claim_rect: Rect2i = LandRegistry.get_plot(String(claim_id)).get("rect", Rect2i()) as Rect2i
		if claim_rect.size.x >= implemented_large_plot_target and claim_rect.size.y >= implemented_large_plot_target:
			large_plot_ids.append(String(claim_id))
	if large_plot_ids.size() < 4:
		push_error("Fewer than 4 plots meet the %dx%d large-lot target (found %d)" % [
			implemented_large_plot_target, implemented_large_plot_target, large_plot_ids.size(),
		])
		quit(1)
		return
	var overworld_map: OverworldMap = OverworldMap.new()
	for large_plot_id in large_plot_ids:
		var large_rect: Rect2i = LandRegistry.get_plot(large_plot_id).get("rect", Rect2i()) as Rect2i
		var center_tile: Vector2i = Vector2i(
			large_rect.position.x + large_rect.size.x / 2,
			large_rect.position.y + large_rect.size.y / 2
		)
		if not large_rect.has_point(center_tile):
			push_error("Computed center tile is not inside plot '%s'" % large_plot_id)
			quit(1)
			return
		if String(LandRegistry.plot_at_tile(center_tile).get("plot_id", "")) != large_plot_id:
			push_error("Large plot center resolved to the wrong plot for '%s'" % large_plot_id)
			quit(1)
			return
		# The center AND near-corner interior tiles must be buildable so owners can
		# place throughout the expanded lots without hugging exact edge artifacts.
		var check_tiles: Array = [
			center_tile,
			large_rect.position + Vector2i(1, 1),
			Vector2i(large_rect.end.x - 2, large_rect.position.y + 1),
			Vector2i(large_rect.position.x + 1, large_rect.end.y - 2),
			large_rect.end - Vector2i(2, 2),
		]
		for build_tile_variant in check_tiles:
			var build_tile: Vector2i = build_tile_variant as Vector2i
			if not overworld_map.is_tile_in_bounds(build_tile):
				push_error("Plot '%s' tile (%d,%d) is outside the buildable bounds" % [large_plot_id, build_tile.x, build_tile.y])
				quit(1)
				return
			var build_result: Dictionary = overworld_map.get_place_footprint_result(build_tile, Vector2i.ONE, [])
			if not bool(build_result.get("valid", false)):
				push_error("Plot '%s' tile (%d,%d) is not buildable: %s" % [large_plot_id, build_tile.x, build_tile.y, build_result.get("reason", "")])
				quit(1)
				return
	var town_world: Vector2 = OverworldMap.VILLAGE_OFFSET + Vector2(96, 320)
	var town_area: Dictionary = WorldAreaRegistry.area_at(town_world)
	if String(town_area.get("id", "")) != "town" or not bool(town_area.get("protected", false)):
		push_error("WorldAreaRegistry no longer classifies the village square as protected town land")
		quit(1)
		return
	var town_tile: Vector2i = overworld_map.world_to_grid(town_world)
	if bool(overworld_map.get_place_footprint_result(town_tile, Vector2i.ONE, []).get("valid", false)):
		push_error("Town/protected area allowed normal building")
		quit(1)
		return
	overworld_map.free()
	var test_plots: Dictionary = {}
	# Use an interior tile (plot center), not the sign tile (which now sits in
	# FRONT of the plot), so build-permission tests check the real bounds.
	var test_plot_id: String = large_plot_ids[0]
	var test_rect: Rect2i = LandRegistry.get_plot(test_plot_id).get("rect", Rect2i()) as Rect2i
	var test_tile: Vector2i = Vector2i(test_rect.position.x + test_rect.size.x / 2, test_rect.position.y + test_rect.size.y / 2)
	if not test_rect.has_point(test_tile):
		push_error("Computed test tile is not inside %s" % test_plot_id)
		quit(1)
		return
	if bool(LandClaimSystem.can_build_at(test_tile, "profile_a", test_plots)["allowed"]):
		push_error("Unclaimed plot allowed building without a claim")
		quit(1)
		return
	var claim_no_token: Dictionary = LandClaimSystem.attempt_claim(
		test_plot_id, "profile_a", "julie", test_plots,
		func(_id: String, _n: int) -> bool: return false,
		func(_id: String, _n: int) -> void: pass
	)
	if bool(claim_no_token["ok"]):
		push_error("Plot claim succeeded without a land token")
		quit(1)
		return
	var claim_ok: Dictionary = LandClaimSystem.attempt_claim(
		test_plot_id, "profile_a", "julie", test_plots,
		func(_id: String, _n: int) -> bool: return true,
		func(_id: String, _n: int) -> void: pass
	)
	if not bool(claim_ok["ok"]):
		push_error("Valid plot claim failed: %s" % claim_ok["reason"])
		quit(1)
		return
	test_plots[test_plot_id] = claim_ok["state"]
	if not bool(LandClaimSystem.can_build_at(test_tile, "profile_a", test_plots)["allowed"]):
		push_error("Plot owner denied building on own plot")
		quit(1)
		return
	# Owner can build at every corner of the claimed plot (full-bounds permission).
	var expected_corner_order: Array[Vector2i] = [
		test_rect.position,
		Vector2i(test_rect.end.x - 1, test_rect.position.y),
		test_rect.end - Vector2i.ONE,
		Vector2i(test_rect.position.x, test_rect.end.y - 1),
	]
	if LandRegistry.corner_tiles(test_plot_id) != expected_corner_order:
		push_error("Plot corner_tiles must return a non-crossing clockwise rectangle")
		quit(1)
		return
	for corner_tile_variant in LandRegistry.corner_tiles(test_plot_id):
		if not bool(LandClaimSystem.can_build_at(corner_tile_variant as Vector2i, "profile_a", test_plots)["allowed"]):
			push_error("Plot owner denied building at a corner of their plot")
			quit(1)
			return
	if bool(LandClaimSystem.can_build_at(test_tile, "profile_b", test_plots)["allowed"]):
		push_error("Non-owner allowed building on someone's plot")
		quit(1)
		return
	if not bool(LandClaimSystem.can_build_at(test_tile, "profile_b", test_plots, true)["allowed"]):
		push_error("Admin bypass denied")
		quit(1)
		return
	# Shared-plot invites: only the owner may invite, and the invited member can
	# then build; a non-owner invite is rejected.
	if bool(LandClaimSystem.attempt_invite(test_plot_id, "profile_b", "profile_c", "carol", test_plots)["ok"]):
		push_error("Non-owner was allowed to invite to a plot")
		quit(1)
		return
	var invite_result: Dictionary = LandClaimSystem.attempt_invite(test_plot_id, "profile_a", "profile_b", "bob", test_plots)
	if not bool(invite_result["ok"]):
		push_error("Owner invite failed: %s" % invite_result["reason"])
		quit(1)
		return
	test_plots[test_plot_id] = invite_result["state"]
	if not bool(LandClaimSystem.can_build_at(test_tile, "profile_b", test_plots)["allowed"]):
		push_error("Invited member denied building on shared plot")
		quit(1)
		return
	if not bool(LandClaimSystem.can_build_at(Vector2i(7, 16), "profile_b", test_plots)["allowed"]):
		push_error("Public commons denied building")
		quit(1)
		return
	if bool(LandClaimSystem.attempt_claim("rowan_training_plot", "profile_a", "julie", test_plots, func(_i: String, _n: int) -> bool: return true, func(_i: String, _n: int) -> void: pass)["ok"]):
		push_error("NPC training land was claimable")
		quit(1)
		return

	# Identity: username sanitizer + admin roles.
	if PlayerIdentity.sanitize_username("  JuLie!! 99 ") != "julie99":
		push_error("Username sanitizer regressed: '%s'" % PlayerIdentity.sanitize_username("  JuLie!! 99 "))
		quit(1)
		return
	if PlayerIdentity.is_valid_username("ab") or not PlayerIdentity.is_valid_username("julie_99"):
		push_error("Username validity rules regressed")
		quit(1)
		return
	if String(LocalProfile.normalized({"display_name": "Old Save"}).get("username", "")).is_empty():
		push_error("Old profile without username did not get a default")
		quit(1)
		return
	if not AdminPermissions.can_world_build(AdminPermissions.offline_role()) or AdminPermissions.can_world_build(AdminPermissions.ROLE_PLAYER):
		push_error("Admin role permissions regressed")
		quit(1)
		return

	# Land repair pass: plot rects must not overlap each other (claimable or
	# fixed), and the quick-tools strip ids must all be real tools.
	var all_plot_ids: Array = LandRegistry.definitions().keys()
	for i in range(all_plot_ids.size()):
		for j in range(i + 1, all_plot_ids.size()):
			var rect_a: Rect2i = LandRegistry.get_plot(String(all_plot_ids[i])).get("rect", Rect2i()) as Rect2i
			var rect_b: Rect2i = LandRegistry.get_plot(String(all_plot_ids[j])).get("rect", Rect2i()) as Rect2i
			if rect_a.intersects(rect_b):
				push_error("Plots '%s' and '%s' overlap" % [all_plot_ids[i], all_plot_ids[j]])
				quit(1)
				return
	for quick_tool_id in [ItemIds.TOOL_WORN_AXE, ItemIds.TOOL_WORN_PICKAXE, ItemIds.TOOL_WORN_HOE, ItemIds.TOOL_WATERING_CAN, ItemIds.TOOL_SIMPLE_HAMMER, ItemIds.TOOL_BASIC_SHOVEL]:
		if not ItemIds.is_tool_item(quick_tool_id):
			push_error("Quick-tools strip references non-tool id '%s'" % quick_tool_id)
			quit(1)
			return

	# Usability pass: nameplate helper builds labels; inventory categories all
	# reference ids that resolve to a display name (no crash on lookup).
	var nameplate_host: Node2D = Node2D.new()
	var nameplate_holder: Node2D = Nameplate.attach(nameplate_host, "Tester", "Player")
	if nameplate_holder == null or nameplate_holder.get_child_count() < 1:
		push_error("Nameplate.attach did not build a label")
		nameplate_host.free()
		quit(1)
		return
	var nameplate_label: Label = nameplate_holder.get_child(0) as Label
	if nameplate_label == null or nameplate_label.get_theme_stylebox("normal") == null:
		push_error("Nameplate label is missing its readable backing")
		nameplate_host.free()
		quit(1)
		return
	nameplate_host.free()

	var inventory_ids: Array = ResourceIds.ALL_MATERIALS + ResourceIds.ALL_COMPONENTS + ItemIds.ALL_TOOLS \
		+ ItemIds.ALL_QUEST_ITEMS + ItemIds.ALL_WEAPONS + ItemIds.ALL_WEARABLES \
		+ [ContentIds.ITEM_CARROT, ContentIds.ITEM_TURNIP, ContentIds.ITEM_BERRY]
	for inv_id in inventory_ids:
		if ItemIds.display_name(String(inv_id)).is_empty():
			push_error("Inventory item id '%s' has no display name" % inv_id)
			quit(1)
			return
	if not ItemIds.ALL_QUEST_ITEMS.has(ItemIds.QUEST_LAND_TOKEN):
		push_error("Land token missing from quest items (inventory tokens category)")
		quit(1)
		return

	# --- World-builder runtime plot overlay -------------------------------------
	# Editor-authored plots must merge into every plot query and round-trip through
	# the save data, and clearing must restore the static catalog exactly (so the
	# in-game world-builder can add/remove lots without corrupting the built-ins).
	var static_claimable_count: int = LandRegistry.claimable_plot_ids().size()
	LandRegistry.add_runtime_plot("wb_test_plot", "WB Test Lot", Rect2i(80, 80, 12, 12), "grove")
	if not LandRegistry.is_runtime_plot("wb_test_plot"):
		push_error("Runtime plot was not recorded as a runtime plot")
		quit(1)
		return
	if not LandRegistry.has_plot("wb_test_plot") or not LandRegistry.definitions().has("wb_test_plot"):
		push_error("Runtime plot did not merge into LandRegistry.definitions()")
		quit(1)
		return
	if not LandRegistry.claimable_plot_ids().has("wb_test_plot"):
		push_error("Runtime plot is not claimable")
		quit(1)
		return
	if String(LandRegistry.plot_at_tile(Vector2i(85, 85)).get("plot_id", "")) != "wb_test_plot":
		push_error("plot_at_tile did not resolve a runtime plot")
		quit(1)
		return
	LandRegistry.add_runtime_plot("wb_tiny_plot", "Too Small", Rect2i(96, 96, 4, 4), "grove")
	if LandRegistry.is_runtime_plot("wb_tiny_plot"):
		push_error("Runtime plot helper accepted a tiny plot")
		quit(1)
		return
	LandRegistry.add_runtime_plot("wb_invalid_biome", "Fallback Biome", Rect2i(96, 96, 12, 12), "bogus_biome")
	if not LandRegistry.is_runtime_plot("wb_invalid_biome"):
		push_error("Runtime plot helper rejected a valid plot with fallback biome normalization")
		quit(1)
		return
	if String(LandRegistry.get_plot("wb_invalid_biome").get("biome", "")) != "meadow":
		push_error("Runtime plot helper did not normalize an invalid biome to meadow")
		quit(1)
		return
	var wb_save_data: Dictionary = LandRegistry.runtime_plots_save_data()
	if not wb_save_data.has("wb_test_plot") or (wb_save_data["wb_test_plot"]["rect"] as Array) != [80, 80, 12, 12]:
		push_error("Runtime plot save data did not serialize rect as [x,y,w,h]")
		quit(1)
		return
	if String((wb_save_data["wb_invalid_biome"] as Dictionary).get("biome", "")) != "meadow":
		push_error("Runtime plot save data did not persist normalized biome ids")
		quit(1)
		return
	LandRegistry.load_runtime_plots(wb_save_data)
	if not LandRegistry.is_runtime_plot("wb_test_plot"):
		push_error("Runtime plot did not survive a save round-trip")
		quit(1)
		return
	# Corrupt/tiny records must be skipped, and invalid biomes must fail safe.
	LandRegistry.load_runtime_plots({
		"bad_rec": {"rect": [1, 2]},
		"tiny_rec": {"display_name": "Tiny", "rect": [1, 2, 4, 4], "biome": "grove"},
		"bad_biome": {"display_name": "Bad Biome", "rect": [120, 120, 12, 12], "biome": "bogus"},
		"wb_test_plot": wb_save_data["wb_test_plot"],
	})
	if LandRegistry.is_runtime_plot("bad_rec"):
		push_error("Runtime plot loader accepted a malformed rect")
		quit(1)
		return
	if LandRegistry.is_runtime_plot("tiny_rec"):
		push_error("Runtime plot loader accepted a tiny rect")
		quit(1)
		return
	if not LandRegistry.is_runtime_plot("bad_biome") or String(LandRegistry.get_plot("bad_biome").get("biome", "")) != "meadow":
		push_error("Runtime plot loader did not normalize an invalid biome safely")
		quit(1)
		return
	# Clearing the overlay must restore the static catalog with no leakage.
	LandRegistry.load_runtime_plots({})
	if LandRegistry.is_runtime_plot("wb_test_plot") or LandRegistry.claimable_plot_ids().size() != static_claimable_count:
		push_error("Clearing the runtime overlay did not restore the static plot catalog")
		quit(1)
		return

	# --- Biome registry: ids unique, all resolve, future ids reserved -----------
	for required_biome in ["meadow", "forest", "orchard", "creekside", "hilltop", "grove", "town", "farmland"]:
		if not BiomeRegistry.has_biome(required_biome):
			push_error("Required biome id '%s' is missing from BiomeRegistry" % required_biome)
			quit(1)
			return
	if BiomeRegistry.display_name("not_a_real_biome").is_empty():
		push_error("BiomeRegistry.display_name() did not fail safely for an invalid biome id")
		quit(1)
		return
	var invalid_ground: Color = BiomeRegistry.ground_color("not_a_real_biome")
	var invalid_minimap: Color = BiomeRegistry.minimap_tint("not_a_real_biome")
	if invalid_ground.a <= 0.0 or invalid_minimap.a <= 0.0:
		push_error("BiomeRegistry fallback colors are invalid for an unknown biome id")
		quit(1)
		return
	var seen_biome_ids: Dictionary = {}
	for active_biome in BiomeRegistry.ACTIVE:
		if seen_biome_ids.has(active_biome) or not BiomeRegistry.has_biome(String(active_biome)):
			push_error("Biome id '%s' duplicated or missing from the registry table" % active_biome)
			quit(1)
			return
		seen_biome_ids[active_biome] = true
		if BiomeRegistry.display_name(String(active_biome)).is_empty():
			push_error("Biome '%s' has no display name" % active_biome)
			quit(1)
			return
		var ground_tint: Color = BiomeRegistry.ground_color(String(active_biome))
		var minimap_tint: Color = BiomeRegistry.minimap_tint(String(active_biome))
		if ground_tint.a <= 0.0 or minimap_tint.a <= 0.0:
			push_error("Biome '%s' has an invalid ground/minimap color" % active_biome)
			quit(1)
			return
	for wild_biome in BiomeRegistry.WILD:
		if not BiomeRegistry.ACTIVE.has(String(wild_biome)):
			push_error("Wilderness biome '%s' is not an active biome" % wild_biome)
			quit(1)
			return
	for future_biome in BiomeRegistry.FUTURE:
		if not BiomeRegistry.has_biome(String(future_biome)):
			push_error("Reserved future biome '%s' has no registry entry" % future_biome)
			quit(1)
			return
	for required_terrain_style in ["meadow", "forest", "dirt_path", "stone_path", "tilled_soil", "water", "road", "plot_boundary"]:
		if not BiomeRegistry.terrain_ids().has(required_terrain_style):
			push_error("BiomeRegistry.terrain_ids() is missing '%s'" % required_terrain_style)
			quit(1)
			return
		var terrain_color: Color = BiomeRegistry.terrain_color(required_terrain_style)
		var terrain_detail: Color = BiomeRegistry.terrain_detail_color(required_terrain_style)
		if terrain_color.a <= 0.0 or terrain_detail.a <= 0.0:
			push_error("Terrain style '%s' returned an invisible color" % required_terrain_style)
			quit(1)
			return
	if BiomeRegistry.path_color("dirt_path").a <= 0.0 or BiomeRegistry.water_color().a <= 0.0:
		push_error("BiomeRegistry path/water helpers returned invisible colors")
		quit(1)
		return

	# --- Large-world: plots big enough + roads never cross a plot ----------------
	# At least 4 default claimable plots must hit the new homestead target (24x24).
	var big_plot_count: int = 0
	for big_plot_id in LandRegistry.claimable_plot_ids():
		var big_rect: Rect2i = LandRegistry.get_plot(String(big_plot_id)).get("rect", Rect2i()) as Rect2i
		if big_rect.size.x >= 24 and big_rect.size.y >= 24:
			big_plot_count += 1
	if big_plot_count < 4:
		push_error("Fewer than 4 plots meet the 24x24 homestead target (found %d)" % big_plot_count)
		quit(1)
		return
	# Every tile a road passes through must be outside every plot rect (roads run
	# in the gutters between lots, never across them).
	var road_map: OverworldMap = OverworldMap.new()
	for road_tile_variant in OverworldMap.road_sample_tiles():
		var road_tile: Vector2i = road_tile_variant as Vector2i
		for plot_rect_variant in LandRegistry.all_plot_rects():
			if (plot_rect_variant as Rect2i).has_point(road_tile):
				push_error("A road tile (%d,%d) falls inside a plot" % [road_tile.x, road_tile.y])
				road_map.free()
				quit(1)
				return
	# The world bounds must enclose every plot's corners (walls/camera derive from
	# this), proving the world expanded to fit the large lots.
	var world_limits: Rect2 = Rect2(road_map.get_camera_limits())
	for limit_plot_id in LandRegistry.claimable_plot_ids():
		for corner_variant in LandRegistry.corner_tiles(String(limit_plot_id)):
			if not world_limits.has_point(road_map.grid_to_world(corner_variant as Vector2i)):
				push_error("Plot '%s' corner is outside the framed world bounds" % limit_plot_id)
				road_map.free()
				quit(1)
				return
	var minimap_scene: PackedScene = load("res://ui/minimap_panel.tscn") as PackedScene
	if minimap_scene == null:
		push_error("Minimap scene failed explicit load")
		road_map.free()
		quit(1)
		return
	var minimap: CanvasLayer = minimap_scene.instantiate() as CanvasLayer
	if minimap == null:
		push_error("Minimap scene failed explicit instantiate")
		road_map.free()
		quit(1)
		return
	get_root().add_child(minimap)
	await process_frame
	var minimap_panel: Control = minimap.get_node_or_null("Panel") as Control
	var minimap_rect: Control = minimap.get_node_or_null("Panel/Margin/MapRect") as Control
	if minimap_rect == null or minimap_rect.size.x <= 0.0 or minimap_rect.size.y <= 0.0:
		push_error("Minimap is missing a valid MapRect")
		road_map.free()
		quit(1)
		return
	if minimap_panel == null or not minimap_panel.clip_contents or not minimap_rect.clip_contents:
		push_error("Minimap panel/map rect no longer clips custom drawing to its frame")
		road_map.free()
		quit(1)
		return
	var plot_centers: Dictionary = {}
	for plot_id in LandRegistry.claimable_plot_ids():
		var plot: Dictionary = LandRegistry.get_plot(String(plot_id))
		var rect: Rect2i = plot.get("rect", Rect2i()) as Rect2i
		plot_centers[plot_id] = {
			"center": road_map.grid_to_world(Vector2i(
			rect.position.x + rect.size.x / 2,
			rect.position.y + rect.size.y / 2
			)),
			"biome": String(plot.get("biome", "meadow")),
		}
	minimap.call("setup", [], plot_centers, Rect2(road_map.get_camera_limits()))
	var minimap_plots: Dictionary = minimap.get("_plots") as Dictionary
	for plot_id in LandRegistry.claimable_plot_ids():
		if not minimap_plots.has(plot_id) or String((minimap_plots[plot_id] as Dictionary).get("biome", "")).is_empty():
			push_error("Minimap did not preserve biome metadata for plot '%s'" % plot_id)
			minimap.queue_free()
			road_map.free()
			quit(1)
			return
	minimap.call("set_player_position", Vector2(42, 84))
	if minimap.get("_player_pos") != Vector2(42, 84):
		push_error("Minimap set_player_position() did not update the tracked player marker position")
		minimap.queue_free()
		road_map.free()
		quit(1)
		return
	if not road_map.has_method("limezu_minimap_features") or not road_map.has_method("limezu_minimap_bounds"):
		push_error("OverworldMap is missing live LimeZu minimap feature/bounds helpers")
		minimap.queue_free()
		road_map.free()
		quit(1)
		return
	var live_bounds: Rect2 = road_map.call("limezu_minimap_bounds") as Rect2
	var legacy_bounds: Rect2 = Rect2(road_map.get_camera_limits())
	if live_bounds.size.x <= 1.0 or live_bounds.size.y <= 1.0 or live_bounds.size.x >= legacy_bounds.size.x:
		push_error("Live LimeZu minimap bounds do not frame the playable slice sanely")
		minimap.queue_free()
		road_map.free()
		quit(1)
		return
	var live_features: Array = road_map.call("limezu_minimap_features") as Array
	var live_feature_kinds: Dictionary = {}
	for feature_variant in live_features:
		var feature: Dictionary = feature_variant as Dictionary
		live_feature_kinds[String(feature.get("kind", ""))] = true
		if not feature.has("asset_id") or not AssetWorldMetadata.has(String(feature["asset_id"])):
			push_error("Live minimap feature has no valid AssetWorldMetadata id")
			minimap.queue_free()
			road_map.free()
			quit(1)
			return
	for required_live_kind in [
		AssetWorldMetadata.MINIMAP_BUILDING_FOOTPRINT,
		AssetWorldMetadata.MINIMAP_FARM_PATCH,
		AssetWorldMetadata.MINIMAP_PATH_SHAPE,
		AssetWorldMetadata.MINIMAP_FENCE_LINE,
		AssetWorldMetadata.MINIMAP_TREE_DOT,
	]:
		if not live_feature_kinds.has(required_live_kind):
			push_error("Live LimeZu minimap is missing feature kind '%s'" % required_live_kind)
			minimap.queue_free()
			road_map.free()
			quit(1)
			return
	minimap.call("set_truth_mode", true)
	minimap.call("setup", live_features, {}, live_bounds)
	if not bool(minimap.get("_truth_mode")) or (minimap.get("_plots") as Dictionary).size() != 0:
		push_error("Live LimeZu minimap truth mode must suppress default LandRegistry plot squares")
		minimap.queue_free()
		road_map.free()
		quit(1)
		return
	minimap.call("set_truth_mode", false)
	minimap.call("setup", [], plot_centers, Rect2(road_map.get_camera_limits()))
	minimap.call("set_plot_states", {})
	minimap.call("set_admin_debug", true)
	for center_variant in plot_centers.values():
		var center_record: Dictionary = center_variant as Dictionary
		var minimap_point: Vector2 = minimap.call("_world_to_map", center_record["center"] as Vector2)
		if minimap_point.x < -0.01 or minimap_point.y < -0.01 \
				or minimap_point.x > minimap_rect.size.x + 0.01 or minimap_point.y > minimap_rect.size.y + 0.01:
			push_error("Minimap bounds do not include an expanded plot center at %s" % minimap_point)
			minimap.queue_free()
			road_map.free()
			quit(1)
			return
	minimap.call("toggle_panel")
	minimap.queue_free()
	await process_frame
	road_map.free()
	var overworld_controller_source: String = FileAccess.get_file_as_string("res://world/overworld_controller.gd")
	if overworld_controller_source.find("_minimap.call(\"set_player_position\", get_player_position())") == -1:
		push_error("OverworldController no longer updates the minimap player marker")
		quit(1)
		return
	if overworld_controller_source.find("_minimap.call(\"set_player_position\", get_player_position())") > overworld_controller_source.find("_hud_tick += delta"):
		push_error("OverworldController still updates the minimap only inside the throttled HUD block")
		quit(1)
		return
	var minimap_source: String = FileAccess.get_file_as_string("res://ui/minimap_panel.gd")
	for required_snippet in ["CozyUITheme.apply_hud_panel", "BiomeRegistry.minimap_tint", "\"biome\""]:
		if not minimap_source.contains(required_snippet):
			push_error("Minimap visual foundation is missing snippet '%s'" % required_snippet)
			quit(1)
			return

	# First-pass terrain paint: the map must accept override ids, draw them, and
	# clear them safely; the controller keeps the admin paint/fill/reset API.
	var overworld_scene: PackedScene = load("res://scenes/world/overworld.tscn") as PackedScene
	if overworld_scene == null:
		push_error("Overworld scene failed explicit load for terrain-paint validation")
		quit(1)
		return
	var overworld_runtime: Node = overworld_scene.instantiate()
	if overworld_runtime == null:
		push_error("Overworld scene failed explicit instantiate for terrain-paint validation")
		quit(1)
		return
	get_root().add_child(overworld_runtime)
	await process_frame
	var terrain_map: Node = overworld_runtime.get_node_or_null("Map")
	if terrain_map == null or not terrain_map.has_method("terrain_paint_ids") or not terrain_map.has_method("set_terrain_overrides"):
		push_error("Overworld map is missing the terrain paint API")
		quit(1)
		return
	for required_terrain_id in ["meadow", "forest", "orchard", "creekside", "hilltop", "grove", "town", "farmland", "dirt_path", "stone_path", "water"]:
		if not (terrain_map.call("terrain_paint_ids") as Array).has(required_terrain_id):
			push_error("Terrain paint palette is missing '%s'" % required_terrain_id)
			quit(1)
			return
		if not OverworldMap.supports_terrain_paint_id(required_terrain_id):
			push_error("Overworld map does not support terrain paint id '%s'" % required_terrain_id)
			quit(1)
			return
	var terrain_paint_overworld_map_source: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	for required_snippet in ["BiomeRegistry.path_color", "BiomeRegistry.water_color", "BiomeRegistry.terrain_color", "BiomeRegistry.terrain_detail_color"]:
		if not terrain_paint_overworld_map_source.contains(required_snippet):
			push_error("OverworldMap is not using shared visual palette helper '%s'" % required_snippet)
			quit(1)
			return
	terrain_map.call("set_terrain_overrides", {
		"10,10": "water",
		"11,10": "dirt_path",
		"bad_key": "forest",
		"12,10": "not_real",
	})
	if int(terrain_map.call("terrain_override_count")) != 2:
		push_error("Terrain paint override application did not filter invalid keys/ids safely")
		quit(1)
		return
	terrain_map.call("clear_terrain_overrides")
	if int(terrain_map.call("terrain_override_count")) != 0:
		push_error("Terrain paint clear_terrain_overrides() did not remove painted tiles")
		quit(1)
		return
	for required_snippet in [
		"admin_paint_terrain_brush",
		"admin_paint_terrain_fill",
		"admin_reset_terrain_here",
		"terrain_overrides",
	]:
		if not overworld_controller_source.contains(required_snippet):
			push_error("OverworldController is missing terrain-paint wiring '%s'" % required_snippet)
			quit(1)
			return
	overworld_runtime.queue_free()
	await process_frame

	# --- Chunk / world generation scaffolding -----------------------------------
	if WorldChunk.chunk_id(Vector2i(-2, 3)) != "chunk_-2_3":
		push_error("WorldChunk.chunk_id is not stable/negative-safe")
		quit(1)
		return
	if WorldChunk.coord_of_tile(Vector2i(-1, 33)) != Vector2i(-1, 1):
		push_error("WorldChunk.coord_of_tile floored division regressed")
		quit(1)
		return
	if WorldGeneration.biome_for_chunk(99, Vector2i(4, 4)) != WorldGeneration.biome_for_chunk(99, Vector2i(4, 4)):
		push_error("WorldGeneration.biome_for_chunk is not deterministic")
		quit(1)
		return
	if not BiomeRegistry.WILD.has(WorldGeneration.biome_for_chunk(99, Vector2i(4, 4))):
		push_error("Generated chunk biome is not a wilderness biome")
		quit(1)
		return
	var chunk_registry: WorldChunkRegistry = WorldChunkRegistry.new(2024)
	var generated_chunk: Dictionary = chunk_registry.get_or_generate(Vector2i(5, -2))
	if String(generated_chunk["chunk_id"]) != "chunk_5_-2" or chunk_registry.loaded_count() != 1:
		push_error("WorldChunkRegistry.get_or_generate did not cache a chunk")
		quit(1)
		return
	chunk_registry.get_or_generate(Vector2i(5, -2))
	if chunk_registry.loaded_count() != 1:
		push_error("WorldChunkRegistry regenerated an already-cached chunk")
		quit(1)
		return
	var chunk_round_trip: WorldChunkRegistry = WorldChunkRegistry.new()
	chunk_round_trip.load_save_data(chunk_registry.to_save_data())
	if chunk_round_trip.world_seed() != 2024 or not chunk_round_trip.has_chunk(Vector2i(5, -2)):
		push_error("WorldChunkRegistry save round-trip lost data")
		quit(1)
		return

	# --- Fixed authored areas + day/night ---------------------------------------
	var training_area: Dictionary = WorldAreaRegistry.area_at(Vector2.ZERO)
	if String(training_area.get("id", "")) != "farmer_training" or not bool(training_area.get("protected", false)):
		push_error("WorldAreaRegistry no longer reports the landing/training area correctly")
		quit(1)
		return
	if String(WorldAreaRegistry.area_at(OverworldMap.VILLAGE_OFFSET + Vector2(96, 320)).get("id", "")) != "town":
		push_error("WorldAreaRegistry no longer resolves the town area")
		quit(1)
		return
	if not WorldAreaRegistry.area_at(Vector2(4800, 1800)).is_empty():
		push_error("WorldAreaRegistry should return empty outside fixed areas (wilderness)")
		quit(1)
		return
	if ContentRegistry.area_display_name(ContentIds.AREA_WILDERNESS).is_empty():
		push_error("Wilderness area label is empty")
		quit(1)
		return
	for fixed_area in WorldAreaRegistry.areas():
		if not BiomeRegistry.has_biome(String((fixed_area as Dictionary).get("biome", ""))):
			push_error("Fixed area '%s' has an unknown biome" % (fixed_area as Dictionary).get("id", "?"))
			quit(1)
			return
	# Day/night tint must never crash and must respect the readability floor.
	var day_night: DayNightCycle = DayNightCycle.new()
	for sample_t in [0.0, 0.25, 0.5, 0.75, 1.0]:
		day_night.set_time01(sample_t)
		if day_night.phase_label().is_empty() or not day_night.clock_label().contains(":"):
			push_error("Day/night labels are invalid at t=%.2f" % sample_t)
			quit(1)
			return
		var tint: Color = DayNightCycle.tint_for(sample_t)
		if tint.r < DayNightCycle.MIN_CHANNEL - 0.001 or tint.g < DayNightCycle.MIN_CHANNEL - 0.001 or tint.b < DayNightCycle.MIN_CHANNEL - 0.001:
			push_error("Day/night tint at t=%.2f drops below the readability floor" % sample_t)
			quit(1)
			return
	day_night.free()

# --- Stardew-style LimeZu UI reconstruction asserts --------------------------------
	var sw_res_w: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var sw_res_h: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	if sw_res_w != 1280 or sw_res_h != 720:
		push_error("Default resolution must be 1280x720 (got %dx%d)" % [sw_res_w, sw_res_h])
		quit(1)
		return
	var sw_theme_src: String = FileAccess.get_file_as_string("res://ui/limezu_ui_theme.gd")
	for sw_theme_method in ["hotbar_slot_style", "hotbar_slot_selected_style", "inventory_slot_style", "dialogue_panel_style", "tooltip_panel_style", "text_input_style", "button_disabled_style", "tab_selected_style", "close_texture_style", "warning_text_color", "is_textured"]:
		if not sw_theme_src.contains("func %s(" % sw_theme_method):
			push_error("LimeZuUITheme is missing explicit style method: %s" % sw_theme_method)
			quit(1)
			return
	if LiveVisualPolicy.live_limezu_slice() and not LimeZuUITheme.is_textured():
		push_error("LimeZuUITheme.is_textured() is false in live LimeZu mode (UI art not resolving)")
		quit(1)
		return
	var sw_nameplate_src: String = FileAccess.get_file_as_string("res://ui/nameplate.gd")
	if not sw_nameplate_src.contains("font_shadow_color") or sw_nameplate_src.contains("bg_color = Color(0.12"):
		push_error("Nameplate must use the clean readable style (soft shadow, no heavy dark backing box)")
		quit(1)
		return
	var sw_player_scene: PackedScene = load("res://scenes/avatar/player_avatar.tscn") as PackedScene
	if sw_player_scene == null:
		push_error("Player avatar scene (collision body) failed to load")
		quit(1)
		return
	var sw_player: Node = sw_player_scene.instantiate()
	var sw_player_shape: CollisionShape2D = sw_player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if sw_player_shape == null or sw_player_shape.shape == null:
		push_error("Player avatar is missing an enabled CollisionShape2D")
		sw_player.free(); quit(1); return
	sw_player.free()
	# Interaction reach must be calibrated for the 2x LimeZu scale (was 54px; too fussy).
	if LiveVisualPolicy.live_limezu_slice() and LiveVisualPolicy.INTERACTION_RADIUS < 70.0:
		push_error("INTERACTION_RADIUS (%.0f) is too small for the LimeZu visual scale" % LiveVisualPolicy.INTERACTION_RADIUS)
		quit(1)
		return
	# Generator pipeline: commit-safe schema template exists, and the registry resolves
	# safely (no outputs/manifest -> null, never a crash) so dialogue/nameplate fall back.
	if not FileAccess.file_exists("res://tools/art/templates/limezu_generator_manifest_template.json"):
		push_error("Generator manifest schema template is missing (commit-safe pipeline)")
		quit(1)
		return
	var sw_gen_src: String = FileAccess.get_file_as_string("res://systems/art/generator_character_registry.gd")
	if not sw_gen_src.contains("res://licensed_assets/limezu/generator_manifests/"):
		push_error("GeneratorCharacterRegistry must read its manifest from the gitignored licensed_assets path")
		quit(1)
		return
	GeneratorCharacterRegistry.reload()
	if GeneratorCharacterRegistry.portrait_texture("__nonexistent__") != null:
		push_error("GeneratorCharacterRegistry must return null for an unknown portrait (fallback path)")
		quit(1)
		return
	# Generated-output absence must not crash boot: the scan is fail-safe (>= 0).
	if GeneratorCharacterRegistry.generated_local_count() < 0:
		push_error("GeneratorCharacterRegistry.generated_local_count() must fail safe (>= 0)")
		quit(1)
		return
	# Slot icon-centering helpers exist and are shared by inventory + hotbar.
	var sw_theme_src2: String = FileAccess.get_file_as_string("res://ui/limezu_ui_theme.gd")
	for sw_slot_helper in ["func slot_inner_rect(", "func apply_slot_icon_layout(", "func apply_slot_count_layout("]:
		if not sw_theme_src2.contains(sw_slot_helper):
			push_error("LimeZuUITheme is missing slot icon-layout helper: %s" % sw_slot_helper)
			quit(1)
			return
		if not FileAccess.get_file_as_string("res://ui/inventory_panel.gd").contains("apply_slot_icon_layout"):
			push_error("Inventory slots must use the shared apply_slot_icon_layout centering helper")
			quit(1)
			return
	var inventory_panel_source_for_quickbar: String = FileAccess.get_file_as_string("res://ui/inventory_panel.gd")
	for inventory_quickbar_snippet in [
		"signal quickbar_assign_requested",
		"Click an item to assign it to the quickbar",
		"quickbar_assign_requested.emit",
	]:
		if not inventory_panel_source_for_quickbar.contains(inventory_quickbar_snippet):
			push_error("Inventory panel quickbar assignment MVP is missing '%s'" % inventory_quickbar_snippet)
			quit(1)
			return
	if not FileAccess.get_file_as_string("res://ui/quick_tools_bar.gd").contains("apply_slot_icon_layout"):
		push_error("Hotbar slots must use the same apply_slot_icon_layout centering helper")
		quit(1)
		return
	# Scaffold left-side admin panel was composed (header + section dividers), not a button wall.
	if not FileAccess.get_file_as_string("res://ui/admin_panel.gd").contains("func _add_divider("):
		push_error("Admin/world-builder panel must use composed sections (dividers), not a raw button wall")
		quit(1)
		return
	for safe_panel_path in [
		"res://ui/build_menu_panel.gd",
		"res://ui/inventory_panel.gd",
		"res://ui/admin_panel.gd",
		"res://ui/land_panel.gd",
	]:
		var safe_panel_source: String = FileAccess.get_file_as_string(safe_panel_path)
		if not safe_panel_source.contains("SAFE_DOCK_RECT") or not safe_panel_source.contains("_apply_safe_dock"):
			push_error("Popup panel is missing the safe docking contract: %s" % safe_panel_path)
			quit(1)
			return
	# Original Hearthvale asset-generator pipeline: committed style profile + plan doc exist.
	if not FileAccess.file_exists("res://tools/art/templates/hearthvale_generator_style_profile.json"):
		push_error("Hearthvale generator style profile template is missing (commit-safe)")
		quit(1)
		return
	var hearthvale_icon_generator_source: String = FileAccess.get_file_as_string("res://tools/art/hearthvale_icon_generator.py")
	for icon_recipe in [
		"axe",
		"pickaxe",
		"hoe",
		"shovel",
		"watering_can",
		"empty_hands",
		"generic_seed",
		"carrot_seed_packet",
		"turnip_seed_packet",
		"berry_seed_packet",
		"tilled_soil",
		"crop_stage_1",
		"crop_stage_2",
		"crop_stage_3",
		"wearable_leaf_clip",
		"furniture_prop",
		"generic_tool",
	]:
		if not hearthvale_icon_generator_source.contains("\"%s\"" % icon_recipe):
			push_error("Hearthvale icon generator is missing core tool/quickbar recipe '%s'" % icon_recipe)
			quit(1)
			return
	var object_icon_source: String = FileAccess.get_file_as_string("res://systems/art/object_art_registry.gd")
	for icon_contract_snippet in [
		"HEARTHVALE_GENERATED_ICON_PATHS",
		"func icon_texture_for_item",
		"func icon_source_for_item",
		"item_icon_pickaxe_16px.png",
		"item_icon_generic_tool_16px.png",
		"item_icon_turnip_16px.png",
		"item_icon_wearable_leaf_clip_16px.png",
	]:
		if not object_icon_source.contains(icon_contract_snippet):
			push_error("ObjectArtRegistry icon fallback contract is missing '%s'" % icon_contract_snippet)
			quit(1)
			return
	if not FileAccess.file_exists("res://docs/hearthvale_asset_generator_plan.md"):
		push_error("Hearthvale asset generator plan doc is missing")
		quit(1)
		return
	# Collision debug overlay toggle is wired (map + admin controller) for in-play diagnosis.
	if not FileAccess.get_file_as_string("res://world/overworld_map.gd").contains("func set_collision_debug("):
		push_error("OverworldMap is missing the collision debug overlay (set_collision_debug)")
		quit(1)
		return
	if not FileAccess.get_file_as_string("res://world/overworld_controller.gd").contains("func admin_toggle_collision_debug("):
		push_error("OverworldController is missing admin_toggle_collision_debug hook")
		quit(1)
		return
	# Minimap script loads and has a world->map coordinate mapping.
	var sw_minimap_src: String = FileAccess.get_file_as_string("res://ui/minimap_panel.gd")
	if not sw_minimap_src.contains("func _world_to_map(") or load("res://ui/minimap_panel.tscn") == null:
		push_error("Minimap is missing its world->map coordinate mapping or failed to load")
		quit(1)
		return
	# Tree colliders block only the trunk base (compact circle), not the full canopy.
	if not FileAccess.get_file_as_string("res://world/homestead_map.gd").contains("Block only the TRUNK BASE"):
		push_error("LimeZu tree collider must be the compact trunk-base footprint, not the canopy")
		quit(1)
		return
	# Player collider must be the compact feet shape (not the old tall capsule).
	if FileAccess.get_file_as_string("res://scenes/avatar/player_avatar.tscn").contains("CapsuleShape2D"):
		push_error("Player collider should be a compact feet shape, not the tall CapsuleShape2D")
		quit(1)
		return
	# --- Asset-world metadata registry: the authoritative collision/interaction/minimap contract ---
	if load("res://systems/world/asset_world_metadata.gd") == null:
		push_error("AssetWorldMetadata registry failed to load")
		quit(1)
		return
	for sw_meta_id in ["object.barn", "object.tree", "object.fence_horizontal"]:
		if not AssetWorldMetadata.has(sw_meta_id):
			push_error("AssetWorldMetadata is missing required asset: %s" % sw_meta_id)
			quit(1)
			return
	if not (AssetWorldMetadata.is_blocking("object.barn") and AssetWorldMetadata.is_blocking("object.tree") and AssetWorldMetadata.is_blocking("object.fence_horizontal")):
		push_error("Barn/tree/fence must be declared blocking in AssetWorldMetadata")
		quit(1)
		return
	for sw_open_id in ["object.flower", "terrain.grass", "terrain.dirt_path", "terrain.tilled_soil", "crop.carrot"]:
		if AssetWorldMetadata.is_blocking(sw_open_id):
			push_error("%s must be non-blocking in AssetWorldMetadata" % sw_open_id)
			quit(1)
			return
	if AssetWorldMetadata.minimap_visible_ids().is_empty():
		push_error("AssetWorldMetadata has no minimap-visible features")
		quit(1)
		return
	var expected_minimap_contract := {
		"object.barn": [AssetWorldMetadata.MINIMAP_BUILDING_FOOTPRINT, "rect"],
		"terrain.tilled_soil": [AssetWorldMetadata.MINIMAP_FARM_PATCH, "rect"],
		"terrain.dirt_path": [AssetWorldMetadata.MINIMAP_PATH_SHAPE, "tiles"],
		"object.fence_horizontal": [AssetWorldMetadata.MINIMAP_FENCE_LINE, "tiles"],
		"object.tree": [AssetWorldMetadata.MINIMAP_TREE_DOT, "dot"],
		"object.sign": [AssetWorldMetadata.MINIMAP_SIGN_DOT, "dot"],
		"placed_object": [AssetWorldMetadata.MINIMAP_PLACED_OBJECT_DOT, "dot"],
		"npc": [AssetWorldMetadata.MINIMAP_NPC_DOT, "dot"],
	}
	for contract_id in expected_minimap_contract.keys():
		if not AssetWorldMetadata.minimap_visible(String(contract_id)):
			push_error("%s must be minimap-visible for the live schematic" % contract_id)
			quit(1)
			return
		var contract: Array = expected_minimap_contract[contract_id] as Array
		if AssetWorldMetadata.minimap_kind(String(contract_id)) != String(contract[0]) \
				or AssetWorldMetadata.minimap_shape(String(contract_id)) != String(contract[1]):
			push_error("%s has the wrong minimap kind/shape metadata" % contract_id)
			quit(1)
			return
		if AssetWorldMetadata.minimap_priority(String(contract_id)) <= 0:
			push_error("%s needs a positive minimap draw priority" % contract_id)
			quit(1)
			return
	if AssetWorldMetadata.minimap_footprint("object.barn").size.x <= 0 \
			or AssetWorldMetadata.minimap_footprint("terrain.tilled_soil").size.x <= 0:
		push_error("Building/farm minimap footprints must be declared in AssetWorldMetadata")
		quit(1)
		return
	if not (AssetWorldMetadata.interaction_enabled("object.sign") and AssetWorldMetadata.interaction_enabled("npc")):
		push_error("AssetWorldMetadata must declare sign/NPC interaction")
		quit(1)
		return
	# Asset collision must now distinguish final sprite-shaped collision from tile/grid
	# fallback proxies. Tile rectangles are allowed for terrain and placement proxies, but
	# the live barn/tree/fence runtime colliders must be authored from metadata shapes.
	for collision_type_name in [
		AssetWorldMetadata.COLLISION_CIRCLE,
		AssetWorldMetadata.COLLISION_RECT,
		AssetWorldMetadata.COLLISION_MULTI_RECT,
		AssetWorldMetadata.COLLISION_POLYGON,
		AssetWorldMetadata.COLLISION_MULTI_POLYGON,
		AssetWorldMetadata.COLLISION_LINE,
		AssetWorldMetadata.COLLISION_TILE_RECT_FALLBACK,
		AssetWorldMetadata.COLLISION_ALPHA_MASK_SOURCE,
		AssetWorldMetadata.COLLISION_GENERATED_POLYGON_FROM_ALPHA,
	]:
		if String(collision_type_name).is_empty():
			push_error("AssetWorldMetadata exposes an empty collision type constant")
			quit(1)
			return
	if AssetWorldMetadata.collision_type("object.barn") != AssetWorldMetadata.COLLISION_MULTI_POLYGON:
		push_error("Barn must use multi-polygon asset collision, not a tile rectangle as final collision")
		quit(1)
		return
	if AssetWorldMetadata.collision_shapes("object.barn").size() < 2:
		push_error("Barn must declare multiple asset-shaped collision polygons")
		quit(1)
		return
	if AssetWorldMetadata.collision_tile_proxy("object.barn").size.x <= 0 \
			or AssetWorldMetadata.collision_rect("object.barn").size.x > 0:
		push_error("Barn needs a placement proxy, while final collision_rect remains empty")
		quit(1)
		return
	if not AssetWorldMetadata.collision_precision("object.barn").contains("asset") \
			or AssetWorldMetadata.collision_source("object.barn").is_empty():
		push_error("Barn collision metadata must record asset-derived precision/source notes")
		quit(1)
		return
	if AssetWorldMetadata.collision_type("object.tree") != AssetWorldMetadata.COLLISION_CIRCLE \
			or AssetWorldMetadata.collision_anchor("object.tree") != "sprite_bottom_center" \
			or AssetWorldMetadata.trunk_radius("object.tree") <= 0.0 \
			or AssetWorldMetadata.trunk_offset("object.tree").y > 0.0:
		push_error("Tree collision must be a compact trunk/base circle anchored at the sprite base")
		quit(1)
		return
	var fence_shapes: Array = AssetWorldMetadata.collision_shapes("object.fence_horizontal")
	if AssetWorldMetadata.collision_type("object.fence_horizontal") != AssetWorldMetadata.COLLISION_LINE \
			or fence_shapes.is_empty() \
			or String((fence_shapes[0] as Dictionary).get("type", "")) != AssetWorldMetadata.COLLISION_LINE \
			or float((fence_shapes[0] as Dictionary).get("thickness", 999.0)) > 12.0:
		push_error("Fence collision must be a thin line/segment, not fat tile cells")
		quit(1)
		return
	# Collision build + minimap truth mode are registry-driven (not hand-patched).
	var overworld_map_source: String = FileAccess.get_file_as_string("res://world/overworld_map.gd")
	var homestead_map_source: String = FileAccess.get_file_as_string("res://world/homestead_map.gd")
	for collision_source_snippet in [
		"_add_limezu_asset_collider",
		"_draw_limezu_asset_collision_debug",
		"_draw_limezu_tile_fallback_debug",
		"AssetWorldMetadata.collision_shapes",
		"Blocked by barn (placement proxy)",
	]:
		if not overworld_map_source.contains(collision_source_snippet):
			push_error("OverworldMap asset-collision path is missing '%s'" % collision_source_snippet)
			quit(1)
			return
	if overworld_map_source.contains("_add_limezu_rect_collider") \
			or overworld_map_source.contains("LIMEZU_BARN_COLLIDER_RECT"):
		push_error("OverworldMap still contains the retired LimeZu tile-rectangle collider path")
		quit(1)
		return
	# HomesteadMap delegates shape instancing to the shared PlacedObjectCollision builder so
	# curated + placed objects build collision identically (one source of truth).
	if not homestead_map_source.contains("PlacedObjectCollision.build_shapes_into"):
		push_error("HomesteadMap must build collision via the shared PlacedObjectCollision builder")
		quit(1)
		return
	var placed_collision_source: String = FileAccess.get_file_as_string("res://systems/world/placed_object_collision.gd")
	for placed_shape_snippet in [
		"func build_shapes_into(",
		"func apply_to_placed(",
		"CollisionPolygon2D",
		"CircleShape2D",
		"RectangleShape2D",
		"AssetWorldMetadata.collision_shapes",
	]:
		if not placed_collision_source.contains(placed_shape_snippet):
			push_error("PlacedObjectCollision builder is missing '%s'" % placed_shape_snippet)
			quit(1)
			return
	# Placed objects use the asset-metadata builder + tag debug footprints for the overlay.
	var sw_placement_source: String = FileAccess.get_file_as_string("res://systems/building_placement_system.gd")
	for placement_snippet in [
		"PlacedObjectCollision.apply_to_placed",
		"AssetWorldMetadata.asset_id_for_placeable",
		"debug_footprint_tiles",
		"_preview_object = placeable_data.scene.instantiate()",
		"placed_object: PlaceableCrate = placeable_data.scene.instantiate()",
		"gameplay_layer.add_child(placed_object)",
		"placed_object.visible = false",
		"placed_node.queue_free()",
		"_placed_nodes.erase",
	]:
		if not sw_placement_source.contains(placement_snippet):
			push_error("BuildingPlacementSystem placed-object collision path is missing '%s'" % placement_snippet)
			quit(1)
			return
	if sw_placement_source.contains("_preview_object = PLACEABLE_CRATE_SCENE.instantiate()") \
			or sw_placement_source.contains("placed_object: PlaceableCrate = PLACEABLE_CRATE_SCENE.instantiate()"):
		push_error("Build placement still instantiates the crate scene instead of the selected scene")
		quit(1)
		return
	# At least fence/sign/crate/building placeables map to explicit asset metadata.
	for placeable_id in ["fence_segment", "signpost", "crate", "barn_shell"]:
		if AssetWorldMetadata.asset_id_for_placeable(placeable_id).is_empty():
			push_error("Buildable '%s' has no AssetWorldMetadata mapping (or documented fallback)" % placeable_id)
			quit(1)
			return
	if not FileAccess.file_exists("res://tools/art/limezu_collision_mask_builder.py"):
		push_error("Local LimeZu collision mask builder tool is missing")
		quit(1)
		return
	var collision_tool_source: String = FileAccess.get_file_as_string("res://tools/art/limezu_collision_mask_builder.py")
	for collision_tool_snippet in [
		"alpha_bounds",
		"collision_masks",
		"collision_review",
		"candidate_polygon",
		"lower-body-only",
		"anchor-mode",
	]:
		if not collision_tool_source.contains(collision_tool_snippet):
			push_error("Collision mask builder is missing '%s'" % collision_tool_snippet)
			quit(1)
			return
	var live_capture_source: String = FileAccess.get_file_as_string("res://tools/live_visual_capture.gd")
	for live_capture_snippet in [
		"live_limezu_barn_pixel_collision_overlay.png",
		"live_limezu_tree_pixel_collision_overlay.png",
		"live_limezu_fence_pixel_collision_overlay.png",
		"live_limezu_minimap_after_pixel_collision.png",
		"live_limezu_farm_prompt_after_pixel_collision.png",
		"live_limezu_player_in_front_of_tree.png",
		"live_limezu_player_behind_tree.png",
		"live_limezu_npc_body_collision.png",
		"live_limezu_player_walk_animation.png",
		"live_limezu_held_tool_visual.png",
		"live_limezu_placed_object_ysort_overlay.png",
		"live_limezu_quickbar_assigned.png",
		"live_limezu_quickbar_empty_unequipped.png",
		"live_limezu_held_tool_after_quickbar.png",
		"live_limezu_inventory_quickbar_assign.png",
		"live_limezu_generated_tool_icons_review.png",
		"live_limezu_build_selected_asset.png",
		"live_limezu_build_ghost_asset.png",
		"live_limezu_placed_asset_visual.png",
		"live_limezu_edit_selected_asset.png",
		"live_limezu_admin_safe_panel_position.png",
		"live_limezu_visible_farm_patch.png",
		"live_limezu_farm_prompt_visible_patch.png",
		"live_limezu_farm_before_hoe.png",
		"live_limezu_farm_after_hoe_tilled.png",
		"live_limezu_farm_planted_stage1.png",
		"live_limezu_farm_crop_stage_update.png",
		"live_limezu_farm_harvest_ready.png",
		"live_limezu_build_catalog_real_assets.png",
		"live_limezu_generated_common_items_review.png",
	]:
		if not live_capture_source.contains(live_capture_snippet):
			push_error("Live visual capture is missing pixel-collision output '%s'" % live_capture_snippet)
			quit(1)
			return
	if not live_capture_source.contains("OverworldMap.LIMEZU_TILLED_SOIL_RECT"):
		push_error("Live visual capture farm prompt must follow the current visible farm patch rect")
		quit(1)
		return
	var minimap_live_source: String = FileAccess.get_file_as_string("res://ui/minimap_panel.gd")
	if not minimap_live_source.contains("_truth_mode"):
		push_error("Minimap is missing truth mode (phantom bands/plots not suppressed in the live slice)")
		quit(1)
		return
	if not minimap_live_source.contains("not _truth_mode") or not minimap_live_source.contains("_plots.keys() if show_schematic else []"):
		push_error("Default truth-mode minimap must suppress phantom schematic bands and LandRegistry plot squares")
		quit(1)
		return
	for draw_kind in [
		"building_footprint",
		"farm_patch",
		"path_shape",
		"fence_line",
		"tree_dot",
		"npc_dot",
		"sign_dot",
	]:
		if not minimap_live_source.contains(draw_kind):
			push_error("Minimap renderer is missing drawing support for '%s'" % draw_kind)
			quit(1)
			return
	var controller_live_source: String = FileAccess.get_file_as_string("res://world/overworld_controller.gd")
	if not controller_live_source.contains("set_truth_mode"):
		push_error("OverworldController must put the live LimeZu minimap into truth mode")
		quit(1)
		return
	if not controller_live_source.contains("limezu_minimap_bounds") or not controller_live_source.contains("_limezu_actor_minimap_feature") or not controller_live_source.contains("_limezu_sign_minimap_feature"):
		push_error("OverworldController must source live minimap bounds/features and append NPC/sign markers")
		quit(1)
		return
	var placement_source: String = FileAccess.get_file_as_string("res://systems/building_placement_system.gd")
	if not placement_source.contains("func minimap_features()") or not placement_source.contains("placed_node.visible") or not controller_live_source.contains("minimap_features"):
		push_error("Visible player-placed objects must have a safe minimap feature path")
		quit(1)
		return
	for overlay_snippet in [
		"CollisionDebugLegend",
		"Red: asset collision",
		"Red hatch: tile fallback",
		"Blue: spawn",
		"Green: farm patch",
		"Yellow: interaction",
		"Purple: minimap feature",
		"_draw_limezu_asset_collision_debug",
		"_draw_limezu_tile_fallback_debug",
		"_limezu_visual_tile_rect(Vector2i(gx, gy))",
		"AssetWorldMetadata.minimap_footprint(\"object.barn\")",
	]:
		if not overworld_map_source.contains(overlay_snippet):
			push_error("Collision/minimap overlay source is missing snippet '%s'" % overlay_snippet)
			quit(1)
			return
	print("Project smoke test passed.")
	quit(0)
