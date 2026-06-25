extends RefCounted
class_name CharacterAnimationRegistry

## Directional FRAME + hand-SOCKET data for LimeZu character sheets (animation/facing pass).
##
## The LimeZu Modern character base sheets (Farmer_1/Farmer_2/Body_2, 6144x832, 16x32 frames)
## share one template. Only the frames we have REVIEWED are wired for runtime: the DOWN (front)
## and UP (back) idle frames, plus a light 2-frame DOWN walk. SIDE reuses the DOWN frame with a
## horizontal flip. The rest of the mega-atlas (full per-direction walk cycles, run, actions) is
## CATALOGED by tools/audit_limezu_animations.gd for a future reviewed pass — see the manifest at
## licensed_assets/limezu/generator_manifests/limezu_animation_manifest.json. Pure data; the
## avatar reads region rects + sockets from here so a wrong-frame guess never ships silently.

const FRAME := Vector2i(16, 32)   # one character frame in the 16x16-pack sheets

# Reviewed frame CELLS (col,row) in the 16x32 grid. rect = (col*16, row*32, 16, 32).
# Verified by eye from the farmer sheet: band 1 col 1 = front/DOWN, band 1 col 4 = back/UP.
const FARMER_FAMILY := {
	"idle": {
		"down": Vector2i(1, 1),
		"up": Vector2i(4, 1),
		"side": Vector2i(1, 1),   # front frame, mirrored by the avatar for left/right
	},
	"walk": {
		"down": [Vector2i(1, 1), Vector2i(1, 3)],   # 2-frame front step (band 1 + band 3)
		"up": [Vector2i(4, 1)],                       # single back frame (+ body bob) until reviewed
		"side": [Vector2i(1, 1)],                     # front frame mirrored (+ bob) until reviewed
	},
	"reviewed_directions": ["down", "up"],   # side is mirrored-front; left/right profiles deferred
}

# Sheets that follow the farmer template (all three LimeZu base character sheets).
const SHEET_FAMILY := {
	"character.farmer_idle": FARMER_FAMILY,
	"character.farmer2_idle": FARMER_FAMILY,
	"character.body2_idle": FARMER_FAMILY,
}

# Per-facing held-tool hand SOCKET (relative to the feet origin of the AvatarVisual), with a
# rotation and whether the tool draws BEHIND the body (for the up/back facing). Data-based +
# approximate; tuned for the 16x32 farmer rendered at the LimeZu x2 scale.
const HAND_SOCKET := {
	"down": {"pos": Vector2(6, -13), "rot": 0.18, "behind": false},
	"side": {"pos": Vector2(9, -12), "rot": 0.42, "behind": false},
	"up": {"pos": Vector2(-6, -15), "rot": -0.22, "behind": true},
}

# --- LimeZu Modern Interiors "Character_Generator" LAYER layout (the player's layered avatar) ---
# Verified by eye from a composited Julie contact sheet:
#   idle front/DOWN = col3,row0, up/back = col1,row0, side/right = col0,row0.
#   walk side/left = cols12-17,row1, walk DOWN/front = cols18-23,row1, walk UP/back = cols8-11,row1.
# Side walk and side idle have opposite base facings. AvatarVisual flips right-walk and left-idle;
# the parent stays scale.x=1 so a stale side transform can never leak into down/up.
const GENERATOR_FRAMES := {
	"idle": {"down": Vector2i(3, 0), "up": Vector2i(1, 0), "side": Vector2i(0, 0)},
	"walk": {
		"down": [Vector2i(18, 1), Vector2i(19, 1), Vector2i(20, 1), Vector2i(21, 1), Vector2i(22, 1), Vector2i(23, 1)],
		"up": [Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1)],
		"side": [Vector2i(12, 1), Vector2i(13, 1), Vector2i(14, 1), Vector2i(15, 1), Vector2i(16, 1), Vector2i(17, 1)],
	},
	"reviewed_directions": ["down", "up", "side"],
}

static func generator_idle_rect(facing: String) -> Rect2i:
	var cell: Vector2i = (GENERATOR_FRAMES["idle"] as Dictionary).get(_facing_key(facing), Vector2i(0, 0))
	return Rect2i(cell.x * FRAME.x, cell.y * FRAME.y, FRAME.x, FRAME.y)

static func generator_walk_frames(facing: String) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	for cell in (GENERATOR_FRAMES["walk"] as Dictionary).get(_facing_key(facing), []):
		out.append(Rect2i((cell as Vector2i).x * FRAME.x, (cell as Vector2i).y * FRAME.y, FRAME.x, FRAME.y))
	if out.is_empty():
		out.append(generator_idle_rect(facing))
	return out

## Region for the layered (interiors generator) player by animation state + frame index.
static func generator_region_for(state: String, frame_index: int) -> Rect2i:
	var facing := "down"
	if String(state).ends_with("up"):
		facing = "up"
	elif String(state).ends_with("side"):
		facing = "side"
	if String(state).begins_with("walk"):
		var frames := generator_walk_frames(facing)
		return frames[frame_index % frames.size()]
	return generator_idle_rect(facing)

static func generator_reviewed_directions() -> Array:
	return (GENERATOR_FRAMES["reviewed_directions"] as Array).duplicate()

static func has_sheet(sheet_id: String) -> bool:
	return SHEET_FAMILY.has(String(sheet_id))

static func _cell_rect(cell: Vector2i) -> Rect2i:
	return Rect2i(cell.x * FRAME.x, cell.y * FRAME.y, FRAME.x, FRAME.y)

static func _facing_key(facing: String) -> String:
	var f := String(facing)
	return f if (f == "up" or f == "side") else "down"

## The 16x32 region for a sheet's IDLE frame in a facing.
static func idle_rect(sheet_id: String, facing: String) -> Rect2i:
	if not has_sheet(sheet_id):
		return _cell_rect(Vector2i(1, 1))
	var cell: Vector2i = (SHEET_FAMILY[sheet_id]["idle"] as Dictionary).get(_facing_key(facing), Vector2i(1, 1))
	return _cell_rect(cell)

## The ordered WALK frame regions for a facing (1+ frames). Avatar cycles by walk phase.
static func walk_frames(sheet_id: String, facing: String) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	if not has_sheet(sheet_id):
		out.append(_cell_rect(Vector2i(1, 1)))
		return out
	var cells: Array = (SHEET_FAMILY[sheet_id]["walk"] as Dictionary).get(_facing_key(facing), [])
	for cell in cells:
		out.append(_cell_rect(cell as Vector2i))
	if out.is_empty():
		out.append(idle_rect(sheet_id, facing))
	return out

## The region for a given animation state + walk frame index.
static func region_for(sheet_id: String, state: String, frame_index: int) -> Rect2i:
	var facing := "down"
	if String(state).ends_with("up"):
		facing = "up"
	elif String(state).ends_with("side"):
		facing = "side"
	if String(state).begins_with("walk"):
		var frames := walk_frames(sheet_id, facing)
		return frames[frame_index % frames.size()] if not frames.is_empty() else idle_rect(sheet_id, facing)
	return idle_rect(sheet_id, facing)

## True when left/right facing should mirror the down frame (no dedicated side profile yet).
static func side_uses_flip(sheet_id: String) -> bool:
	return has_sheet(sheet_id)

## Reviewed directions wired for runtime (for the audit/validation; "side" is mirrored-front).
static func reviewed_directions(sheet_id: String) -> Array:
	if not has_sheet(sheet_id):
		return []
	return ((SHEET_FAMILY[sheet_id] as Dictionary).get("reviewed_directions", []) as Array).duplicate()

static func hand_socket(facing: String) -> Dictionary:
	return (HAND_SOCKET.get(_facing_key(facing), HAND_SOCKET["down"]) as Dictionary).duplicate(true)

static func has_hand_socket(facing: String) -> bool:
	return HAND_SOCKET.has(_facing_key(facing))
