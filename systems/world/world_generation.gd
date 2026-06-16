extends RefCounted
class_name WorldGeneration

## Deterministic chunk generation. Given a world seed and a chunk coordinate it
## produces a stable seed and a biome — same inputs always yield the same chunk,
## so offline and server agree without storing every chunk. Fixed authored areas
## (town, landing, the starter neighborhood) are NOT generated here; they come
## from WorldAreaRegistry and take precedence. Everything else is "wilderness"
## the generator fills as players explore. See docs/world_generation.md.

const DEFAULT_WORLD_SEED: int = 1337

## A stable per-chunk seed mixed from the world seed + coordinate (negative-safe).
static func chunk_seed(world_seed: int, coord: Vector2i) -> int:
	var hashed: int = hash("%d:%d:%d" % [world_seed, coord.x, coord.y])
	return absi(hashed)

## Pick a wilderness biome deterministically, with a little coarse clustering so
## neighbors tend to share a biome (avoids a noisy checkerboard).
static func biome_for_chunk(world_seed: int, coord: Vector2i) -> String:
	# Coarse cells of 3x3 chunks share a roll, giving small biome regions.
	var cell: Vector2i = Vector2i(floori(coord.x / 3.0), floori(coord.y / 3.0))
	var roll: int = chunk_seed(world_seed, cell) % BiomeRegistry.WILD.size()
	return String(BiomeRegistry.WILD[roll])

## Generate a wilderness chunk record for a coordinate.
static func generate_chunk(world_seed: int, coord: Vector2i) -> Dictionary:
	var biome: String = biome_for_chunk(world_seed, coord)
	return WorldChunk.make(coord, biome, chunk_seed(world_seed, coord), {
		"buildable": false,
		"claimable": true,   # wilderness can be claimed into a parcel by players
		"protected": false,
		"public": true,
		"wilderness": true,
	})
