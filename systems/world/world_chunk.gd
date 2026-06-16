extends RefCounted
class_name WorldChunk

## Data model for one world chunk — the unit of the large-world architecture. A
## chunk is a square block of tiles with a stable id, a biome, a deterministic
## seed, and zone flags (buildable / claimable / protected / public / wilderness).
## This is the persistence + generation contract; rendering streaming is layered
## on top later (see docs/world_generation.md). Pure data + helpers so it is safe
## to load, serialize, and unit-test with no scene dependencies.

const CHUNK_TILES: int = 32

## Stable, save-safe id from a chunk coordinate (negative-safe).
static func chunk_id(coord: Vector2i) -> String:
	return "chunk_%d_%d" % [coord.x, coord.y]

## Which chunk a tile belongs to (floored division so negatives bucket correctly).
static func coord_of_tile(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(tile.x / float(CHUNK_TILES)), floori(tile.y / float(CHUNK_TILES)))

## Tile rect a chunk covers.
static func tile_rect(coord: Vector2i) -> Rect2i:
	return Rect2i(coord.x * CHUNK_TILES, coord.y * CHUNK_TILES, CHUNK_TILES, CHUNK_TILES)

## Build a chunk record. `flags` overrides the defaults below.
static func make(coord: Vector2i, biome: String, seed_value: int, flags: Dictionary = {}) -> Dictionary:
	var record: Dictionary = {
		"chunk_id": chunk_id(coord),
		"coord": [coord.x, coord.y],
		"biome": biome,
		"seed": seed_value,
		"buildable": false,
		"claimable": false,
		"protected": false,
		"public": true,
		"wilderness": true,
		"landmarks": [],
		"resources": [],
	}
	for key in flags.keys():
		record[key] = flags[key]
	return record

## Defensive normalize for loaded/networked data (fills missing keys, fixes types).
static func normalized(record: Dictionary) -> Dictionary:
	var coord_raw: Variant = record.get("coord", [0, 0])
	var coord: Vector2i = Vector2i.ZERO
	if typeof(coord_raw) == TYPE_ARRAY and (coord_raw as Array).size() == 2:
		coord = Vector2i(int((coord_raw as Array)[0]), int((coord_raw as Array)[1]))
	var biome: String = String(record.get("biome", "meadow"))
	if not BiomeRegistry.has_biome(biome):
		biome = "meadow"
	var base: Dictionary = make(coord, biome, int(record.get("seed", 0)))
	for key in ["buildable", "claimable", "protected", "public", "wilderness"]:
		base[key] = bool(record.get(key, base[key]))
	for key in ["landmarks", "resources"]:
		var list_raw: Variant = record.get(key, [])
		base[key] = (list_raw as Array) if typeof(list_raw) == TYPE_ARRAY else []
	return base
