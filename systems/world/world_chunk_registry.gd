extends RefCounted
class_name WorldChunkRegistry

## In-memory cache of generated/loaded chunks keyed by chunk id. The streaming
## layer (future) asks `get_or_generate` as the player nears new coordinates; the
## server persists `to_save_data()` and rehydrates with `load_save_data()`. Kept
## deliberately small and pure so it loads headless and is easy to validate.

var _world_seed: int = WorldGeneration.DEFAULT_WORLD_SEED
var _chunks: Dictionary = {}   # chunk_id -> chunk record

func _init(world_seed: int = WorldGeneration.DEFAULT_WORLD_SEED) -> void:
	_world_seed = world_seed

func world_seed() -> int:
	return _world_seed

func has_chunk(coord: Vector2i) -> bool:
	return _chunks.has(WorldChunk.chunk_id(coord))

## Return the cached chunk for a coordinate, generating + caching it if absent.
func get_or_generate(coord: Vector2i) -> Dictionary:
	var id: String = WorldChunk.chunk_id(coord)
	if not _chunks.has(id):
		_chunks[id] = WorldGeneration.generate_chunk(_world_seed, coord)
	return _chunks[id]

## Register an authored (non-generated) chunk, e.g. a fixed town/area chunk.
func set_chunk(record: Dictionary) -> void:
	var normalized: Dictionary = WorldChunk.normalized(record)
	_chunks[String(normalized["chunk_id"])] = normalized

func chunk_for_tile(tile: Vector2i) -> Dictionary:
	return get_or_generate(WorldChunk.coord_of_tile(tile))

func loaded_count() -> int:
	return _chunks.size()

## Serialize the loaded/authored chunks for server persistence.
func to_save_data() -> Dictionary:
	return {"world_seed": _world_seed, "chunks": _chunks.duplicate(true)}

## Rehydrate from saved data, skipping malformed records.
func load_save_data(data: Dictionary) -> void:
	_world_seed = int(data.get("world_seed", _world_seed))
	_chunks.clear()
	var chunks_raw: Variant = data.get("chunks", {})
	if typeof(chunks_raw) != TYPE_DICTIONARY:
		return
	for chunk_id in (chunks_raw as Dictionary).keys():
		var record_raw: Variant = (chunks_raw as Dictionary)[chunk_id]
		if typeof(record_raw) == TYPE_DICTIONARY:
			_chunks[String(chunk_id)] = WorldChunk.normalized(record_raw as Dictionary)
