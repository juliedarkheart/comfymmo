extends RefCounted
class_name PlacedObjectCollision

## Shared runtime collision builder for BOTH curated world objects and player-PLACED objects.
##
## Reads AssetWorldMetadata.collision_shapes(asset_id) and instantiates Godot collision nodes
## (circle / rect / line / polygon; multi-* = several entries) as DIRECT children of a
## CollisionObject2D (they must be direct children to register). Curated objects pass the
## StaticBody already positioned at the sprite bottom-centre (base_offset = 0); placed objects
## pass the footprint bottom-centre delta as base_offset so shapes land under the visible art.
##
## This is the ONE place collision shapes are built, so curated + placed objects use the same
## asset-metadata model. Commit-safe (no licensed deps); a clean checkout works.

## Build the metadata collision shapes for `asset_id` onto `body`, each offset by `base_offset`
## (the body-local position of the asset's anchor). Returns the number of shapes added.
static func build_shapes_into(body: CollisionObject2D, asset_id: String, base_offset: Vector2 = Vector2.ZERO) -> int:
	if body == null:
		return 0
	var shapes: Array = AssetWorldMetadata.collision_shapes(asset_id)
	if shapes.is_empty():
		return 0
	var added: int = 0
	for shape_variant in shapes:
		var shape_data: Dictionary = shape_variant as Dictionary
		match String(shape_data.get("type", AssetWorldMetadata.collision_type(asset_id))):
			AssetWorldMetadata.COLLISION_CIRCLE, AssetWorldMetadata.COLLISION_TRUNK:
				var circle_collision := CollisionShape2D.new()
				var circle_shape := CircleShape2D.new()
				circle_shape.radius = maxf(float(shape_data.get("radius", AssetWorldMetadata.trunk_radius(asset_id))), 1.0)
				circle_collision.position = base_offset + (shape_data.get("offset", AssetWorldMetadata.trunk_offset(asset_id)) as Vector2)
				circle_collision.shape = circle_shape
				body.add_child(circle_collision)
				added += 1
			AssetWorldMetadata.COLLISION_RECT:
				var rect_collision := CollisionShape2D.new()
				var rect_shape := RectangleShape2D.new()
				rect_shape.size = shape_data.get("size", Vector2.ONE) as Vector2
				rect_collision.position = base_offset + (shape_data.get("offset", Vector2.ZERO) as Vector2)
				rect_collision.shape = rect_shape
				body.add_child(rect_collision)
				added += 1
			AssetWorldMetadata.COLLISION_LINE:
				var from_point: Vector2 = shape_data.get("from", Vector2.ZERO) as Vector2
				var to_point: Vector2 = shape_data.get("to", Vector2.ZERO) as Vector2
				var delta: Vector2 = to_point - from_point
				if delta.length() <= 0.1:
					continue
				var line_collision := CollisionShape2D.new()
				var line_shape := RectangleShape2D.new()
				line_shape.size = Vector2(delta.length(), maxf(float(shape_data.get("thickness", 4.0)), 1.0))
				line_collision.position = base_offset + (from_point + to_point) * 0.5
				line_collision.rotation = delta.angle()
				line_collision.shape = line_shape
				body.add_child(line_collision)
				added += 1
			AssetWorldMetadata.COLLISION_POLYGON:
				var polygon_points := PackedVector2Array()
				for point_variant in (shape_data.get("points", []) as Array):
					polygon_points.append(point_variant as Vector2)
				if polygon_points.size() >= 3:
					var polygon_collision := CollisionPolygon2D.new()
					polygon_collision.polygon = polygon_points
					polygon_collision.position = base_offset
					body.add_child(polygon_collision)
					added += 1
	return added

## Apply asset-metadata collision to a player-PLACED object body. The placed body sits at the
## tile origin (grid_to_world(tile)); `footprint`/`tile_size` give the bottom-centre anchor.
## Returns a status the caller acts on:
##   "metadata_blocking" -> shapes added (caller disables the generic proxy)
##   "metadata_none"     -> asset is non-blocking by design (caller disables the proxy)
##   "proxy"             -> no metadata / blocking-but-uncurated -> caller keeps the proxy
static func apply_to_placed(body: CollisionObject2D, asset_id: String, footprint: Vector2i, tile_size: Vector2i) -> String:
	if asset_id.is_empty() or not AssetWorldMetadata.has(asset_id):
		return "proxy"
	if not AssetWorldMetadata.is_blocking(asset_id):
		return "metadata_none"
	# Footprint bottom-centre in body-local space (body origin = tile top-left).
	var base_offset := Vector2(float(footprint.x) * float(tile_size.x) * 0.5, float(footprint.y) * float(tile_size.y))
	if build_shapes_into(body, asset_id, base_offset) > 0:
		return "metadata_blocking"
	return "proxy"
