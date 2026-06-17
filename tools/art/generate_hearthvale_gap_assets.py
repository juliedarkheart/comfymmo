#!/usr/bin/env python3
"""Generate ORIGINAL Hearthvale top-down gap-fill art.

These are project-local, original, cozy top-down pixel tiles + simple UI shapes
for the Sprout-compatible (sprout_topdown) visual mode. They are the GENERATED
fallback layer: when no licensed Sprout asset is activated for a terrain/UI id,
the registries resolve to these instead of the old 64x48 isometric diamonds, so
a clean checkout (no Sprout pack) still reads as a coherent top-down farming
world.

IMPORTANT — these are committable. They are drawn procedurally here and are NOT
copied, traced, or derived from Sprout Lands (or any other) media. Do not feed
licensed Sprout files into this script. Output lives under art/generated/hearthvale/
(tracked); licensed Sprout derivatives live under the gitignored licensed_assets/.

Run:  python tools/art/generate_hearthvale_gap_assets.py   (needs Pillow)
"""

from __future__ import annotations

import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art/generated/hearthvale"
TERRAIN_OUT = OUT / "terrain"
UI_OUT = OUT / "ui"
TILE = 32  # top-down tile edge (matches WorldProjection.MODE_SPROUT_TOPDOWN)

# Deterministic value noise so tiles are reproducible run to run.
def _noise(x: int, y: int, seed: int) -> float:
    n = (x * 374761393 + y * 668265263 + seed * 982451653) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def _mix(a, b, t: float):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def _base_tile(base, light, dark, seed: int, grain: float = 0.5) -> Image.Image:
    """Gentle two-tone grain fill — subtle, low-contrast, so tiles tessellate into
    calm cozy ground instead of busy noise. No hard border."""
    img = Image.new("RGBA", (TILE, TILE), base + (255,))
    px = img.load()
    for y in range(TILE):
        for x in range(TILE):
            n = _noise(x, y, seed)
            # Fewer textured pixels and a much softer blend than before.
            if n > 1.0 - grain * 0.16:
                px[x, y] = _mix(base, light, 0.3) + (255,)
            elif n < grain * 0.14:
                px[x, y] = _mix(base, dark, 0.28) + (255,)
    return img


def _specks(img: Image.Image, color, seed: int, count: int, alpha: int = 255) -> None:
    px = img.load()
    placed = 0
    i = 0
    while placed < count and i < 400:
        i += 1
        x = int(_noise(i, 11, seed) * TILE)
        y = int(_noise(7, i, seed) * TILE)
        if 0 <= x < TILE and 0 <= y < TILE:
            px[x, y] = color + (alpha,)
            placed += 1


# Calm, close-toned cozy palette. The grass family (meadow/farmer_training/
# creekside/orchard/grove/forest/hilltop) sits in a narrow green band so adjacent
# plot patches read as one coherent meadow with gentle variation, not clashing
# colored rectangles. Functional tiles (soil/path/water) stay distinct but soft.
def _grass(base, seed, light=None, dark=None):
    light = light or _mix(base, (255, 255, 255), 0.14)
    dark = dark or _mix(base, (40, 70, 40), 0.18)
    return _base_tile(base, light, dark, seed, grain=0.4)


def meadow():
    return _grass((132, 178, 110), 1)


def forest():
    img = _grass((104, 152, 96), 2)
    _specks(img, (88, 134, 84), 2, 8, alpha=120)
    return img


def orchard():
    img = _grass((140, 180, 108), 3)
    _specks(img, (214, 150, 92), 3, 4, alpha=150)  # a few fallen fruit, not a field
    return img


def creekside():
    return _grass((124, 176, 120), 4)


def riverbank():
    return _base_tile((206, 192, 150), _mix((206, 192, 150), (255, 255, 255), 0.12),
                      _mix((206, 192, 150), (150, 130, 96), 0.3), 5, grain=0.4)


def hilltop():
    return _grass((146, 174, 132), 6)


def grove():
    return _grass((116, 162, 104), 7)


def town():
    img = _base_tile((192, 176, 140), _mix((192, 176, 140), (255, 255, 255), 0.1),
                     _mix((192, 176, 140), (150, 130, 100), 0.25), 8, grain=0.3)
    d = ImageDraw.Draw(img)
    for gx in range(0, TILE, 8):
        d.line([(gx, 0), (gx, TILE)], fill=(170, 150, 116, 50))
    for gy in range(0, TILE, 8):
        d.line([(0, gy), (TILE, gy)], fill=(170, 150, 116, 50))
    return img


def farmland():
    return _base_tile((168, 130, 96), _mix((168, 130, 96), (255, 240, 210), 0.12),
                      _mix((168, 130, 96), (110, 80, 56), 0.28), 9, grain=0.4)


def farmer_training():
    return _grass((138, 180, 116), 10)


def dirt_path():
    return _base_tile((188, 156, 112), _mix((188, 156, 112), (255, 240, 210), 0.12),
                      _mix((188, 156, 112), (140, 108, 74), 0.28), 11, grain=0.4)


def stone_path():
    img = Image.new("RGBA", (TILE, TILE), (158, 152, 142, 255))
    d = ImageDraw.Draw(img)
    # rounded cobbles in a soft grid
    for cy in range(4):
        for cx in range(4):
            ox = cx * 8 + (3 if cy % 2 else 0)
            oy = cy * 8
            shade = 150 + int(_noise(cx, cy, 12) * 26)
            d.rounded_rectangle([ox + 1, oy + 1, ox + 6, oy + 6], radius=2,
                                fill=(shade, shade - 4, shade - 12, 255),
                                outline=(120, 116, 108, 255))
    return img


def tilled_soil():
    img = _base_tile((158, 118, 84), (176, 138, 102), (130, 94, 64), 13, grain=0.4)
    d = ImageDraw.Draw(img)
    for ry in range(3, TILE, 7):  # soft furrow rows
        d.line([(0, ry), (TILE, ry)], fill=(128, 92, 60, 120))
        d.line([(0, ry + 1), (TILE, ry + 1)], fill=(186, 150, 112, 80))
    return img


def _water(base, light, seed):
    img = _base_tile(base, light, _mix(base, (20, 40, 70), 0.4), seed, grain=0.35)
    d = ImageDraw.Draw(img)
    for ry in range(4, TILE, 9):  # gentle ripples
        d.line([(2, ry), (TILE - 4, ry)], fill=light + (150,))
        d.line([(5, ry + 2), (TILE - 7, ry + 2)], fill=light + (90,))
    return img


def water():
    return _water((86, 166, 212), (150, 206, 234), 15)


def creek():
    return _water((118, 194, 224), (176, 222, 244), 16)


def plot_boundary():
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    soft = (233, 207, 125, 210)  # gentle honey, not a debug line
    for i in range(0, TILE, 6):  # dashed inset edge
        d.line([(i, 1), (i + 3, 1)], fill=soft)
        d.line([(i, TILE - 2), (i + 3, TILE - 2)], fill=soft)
        d.line([(1, i), (1, i + 3)], fill=soft)
        d.line([(TILE - 2, i), (TILE - 2, i + 3)], fill=soft)
    return img


def plot_corner():
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # small rounded corner post: wood stake + honey cap
    d.rounded_rectangle([12, 10, 19, 26], radius=2, fill=(150, 104, 62, 255),
                        outline=(110, 74, 44, 255))
    d.ellipse([10, 6, 21, 14], fill=(233, 207, 125, 255), outline=(190, 158, 86, 255))
    return img


TERRAIN = {
    "meadow": meadow, "forest": forest, "orchard": orchard, "creekside": creekside,
    "riverbank": riverbank, "hilltop": hilltop, "grove": grove, "town": town,
    "farmland": farmland, "farmer_training": farmer_training,
    "dirt_path": dirt_path, "stone_path": stone_path, "tilled_soil": tilled_soil,
    "water": water, "creek": creek,
    "plot_boundary": plot_boundary, "plot_corner": plot_corner,
}


# --- simple cozy UI fallback shapes (original, code-drawn) -------------------
PARCHMENT = (243, 224, 176)
PARCHMENT_DEEP = (231, 203, 141)
BORDER = (134, 81, 31)
BORDER_LIGHT = (200, 137, 63)
HONEY = (224, 166, 75)
SLOT = (246, 234, 208)
SLOT_SEL = (255, 233, 168)


def _panel(size, fill, border, radius=8, bw=4):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([1, 1, size - 2, size - 2], radius=radius,
                        fill=fill + (255,), outline=border + (255,), width=bw)
    return img


def ui_panel():
    return _panel(48, PARCHMENT, BORDER, radius=10, bw=4)


def ui_button():
    img = _panel(32, SLOT, BORDER_LIGHT, radius=7, bw=3)
    return img


def ui_button_hover():
    return _panel(32, SLOT_SEL, HONEY, radius=7, bw=3)


def ui_slot():
    return _panel(28, SLOT, BORDER_LIGHT, radius=5, bw=2)


def ui_slot_selected():
    return _panel(28, SLOT_SEL, HONEY, radius=5, bw=3)


UI = {
    "panel": ui_panel, "button": ui_button, "button_hover": ui_button_hover,
    "slot": ui_slot, "slot_selected": ui_slot_selected,
}


# --- original cozy top-down OBJECT sprites -----------------------------------
# 96x96 canvas, content bottom-anchored near y=86 to match ObjectArtRegistry's
# anchor (the contact point sits on the tile). Original art, NOT from Sprout.
OBJ = 96
BASE_Y = 86
T_TRUNK = (140, 98, 60); T_TRUNK_D = (110, 74, 44)
LEAF = (104, 156, 84); LEAF_D = (72, 120, 62); LEAF_HI = (142, 188, 118)
PINEC = (70, 122, 70); PINE_HI = (118, 162, 106)
ROCKC = (162, 158, 150); ROCK_HI = (198, 194, 186); ROCK_D = (120, 116, 108)
WOODC = (196, 154, 100); WOOD_D = (150, 104, 62); WOOD_HI = (226, 192, 142)
STONEC = (170, 164, 154); STONE_D = (122, 118, 110); STONE_HI = (202, 198, 188)
ROOFC = (201, 122, 106); ROOF_HI = (216, 143, 126)
WALLC = (242, 223, 184); WALL_D = (214, 193, 154)
WATERC = (110, 182, 214); WATER_HI = (170, 212, 236)
SH = (20, 16, 12, 70)


def _obj():
    return Image.new("RGBA", (OBJ, OBJ), (0, 0, 0, 0))


def _shadow(d, cx=OBJ // 2, by=BASE_Y, rw=22, rh=8):
    d.ellipse([cx - rw, by - rh, cx + rw, by + rh], fill=SH)


def o_tree():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=24)
    d.rectangle([44, 56, 52, BASE_Y], fill=T_TRUNK, outline=T_TRUNK_D)
    for c, box in [(LEAF_D, (18, 18, 78, 66)), (LEAF, (22, 14, 74, 60)), (LEAF_HI, (30, 16, 58, 42))]:
        d.ellipse(box, fill=c)
    return img


def o_fruit_tree():
    img = o_tree(); d = ImageDraw.Draw(img)
    for x, y in [(34, 36), (54, 30), (44, 50), (60, 44)]:
        d.ellipse([x, y, x + 7, y + 7], fill=(226, 96, 78), outline=(176, 60, 48))
    return img


def o_pine():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=20)
    d.rectangle([45, 70, 51, BASE_Y], fill=T_TRUNK, outline=T_TRUNK_D)
    for cy, w in [(70, 30), (52, 24), (34, 17)]:
        d.polygon([(48 - w, cy), (48 + w, cy), (48, cy - 24)], fill=PINEC)
        d.polygon([(48 - w + 6, cy - 4), (48 + 4, cy - 4), (48, cy - 20)], fill=PINE_HI)
    return img


def o_bush():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=20)
    d.ellipse([26, 52, 70, BASE_Y], fill=LEAF_D)
    d.ellipse([30, 50, 66, 80], fill=LEAF)
    d.ellipse([36, 50, 54, 66], fill=LEAF_HI)
    for x, y in [(40, 62), (56, 58), (48, 70)]:
        d.ellipse([x, y, x + 4, y + 4], fill=(216, 120, 150))
    return img


def o_rock():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=22)
    d.ellipse([28, 56, 70, BASE_Y], fill=ROCK_D)
    d.ellipse([30, 52, 68, 80], fill=ROCKC)
    d.ellipse([38, 56, 56, 68], fill=ROCK_HI)
    return img


def o_flower_patch():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=22, rh=6)
    d.ellipse([26, 74, 70, BASE_Y + 2], fill=LEAF_D)
    palette = [(228, 124, 132), (240, 210, 120), (190, 150, 220), (236, 168, 196)]
    for i, (x, y) in enumerate([(34, 66), (46, 70), (58, 64), (40, 74), (54, 76)]):
        c = palette[i % len(palette)]
        d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=c)
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(250, 240, 200))
    return img


def o_mushroom():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=14)
    d.rectangle([44, 66, 52, BASE_Y], fill=(244, 230, 200), outline=(210, 190, 150))
    d.pieslice([30, 50, 66, 84], 180, 360, fill=(206, 96, 76), outline=(168, 64, 50))
    for x, y in [(40, 62), (52, 58), (58, 64)]:
        d.ellipse([x, y, x + 5, y + 5], fill=(244, 232, 206))
    return img


def o_grass_tuft():
    img = _obj(); d = ImageDraw.Draw(img)
    for x in (40, 46, 52, 58):
        d.polygon([(x, BASE_Y), (x + 3, BASE_Y), (x + 1, BASE_Y - 18)], fill=LEAF)
    d.polygon([(48, BASE_Y), (51, BASE_Y), (49, BASE_Y - 22)], fill=LEAF_HI)
    return img


def o_stump():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=16)
    d.rectangle([38, 68, 58, BASE_Y], fill=T_TRUNK_D)
    d.ellipse([36, 60, 60, 74], fill=T_TRUNK)
    d.ellipse([42, 63, 54, 71], fill=WOOD_HI)
    return img


def o_water_edge():
    img = _obj(); d = ImageDraw.Draw(img)
    d.ellipse([20, 60, 76, 88], fill=WATERC)
    d.ellipse([30, 64, 66, 78], fill=WATER_HI)
    return img


def o_crop_carrot():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=14)
    d.polygon([(48, 78), (40, BASE_Y), (56, BASE_Y)], fill=(228, 138, 64), outline=(190, 104, 48))
    for x in (42, 48, 54):
        d.polygon([(x, 78), (x + 2, 78), (x, 60)], fill=LEAF)
    return img


def _post(d, x):
    d.rectangle([x - 3, 50, x + 3, BASE_Y], fill=WOODC, outline=WOOD_D)


def o_mailbox():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=14)
    d.rectangle([45, 56, 51, BASE_Y], fill=WOOD_D)
    d.rounded_rectangle([34, 40, 62, 60], radius=5, fill=(120, 150, 200), outline=(80, 110, 160))
    d.rectangle([60, 42, 66, 50], fill=(214, 90, 80))
    return img


def o_sign():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=14)
    d.rectangle([45, 54, 51, BASE_Y], fill=WOOD_D)
    d.rounded_rectangle([30, 40, 66, 60], radius=4, fill=WOODC, outline=WOOD_D)
    for y in (46, 52):
        d.line([34, y, 62, y], fill=WOOD_D, width=2)
    return img


def o_fence():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=24, rh=6)
    for x in (32, 64):
        _post(d, x)
    for y in (58, 70):
        d.rectangle([30, y, 66, y + 5], fill=WOOD_HI, outline=WOOD_D)
    return img


def o_gate():
    img = o_fence(); d = ImageDraw.Draw(img)
    d.line([32, BASE_Y, 64, 56], fill=WOOD_D, width=3)
    d.line([32, 56, 64, BASE_Y], fill=WOOD_D, width=3)
    return img


def o_crate():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=20)
    d.rounded_rectangle([32, 50, 64, BASE_Y], radius=3, fill=WOODC, outline=WOOD_D, width=2)
    d.line([32, 50, 64, BASE_Y], fill=WOOD_D, width=2)
    d.line([64, 50, 32, BASE_Y], fill=WOOD_D, width=2)
    return img


def o_workbench():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=24)
    d.rectangle([30, 70, 36, BASE_Y], fill=WOOD_D)
    d.rectangle([60, 70, 66, BASE_Y], fill=WOOD_D)
    d.rectangle([26, 58, 70, 70], fill=WOODC, outline=WOOD_D, width=2)
    d.rectangle([40, 50, 46, 58], fill=STONE_D)  # a tool on top
    return img


def o_well():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=24)
    d.ellipse([30, 64, 66, BASE_Y + 2], fill=STONE_D)
    d.ellipse([32, 60, 64, 80], fill=STONEC, outline=STONE_D, width=2)
    d.ellipse([40, 64, 56, 74], fill=(70, 110, 150))
    for x in (32, 64):
        d.rectangle([x - 2, 30, x + 2, 64], fill=WOOD_D)
    d.polygon([(26, 34), (70, 34), (48, 16)], fill=ROOFC, outline=(168, 92, 78))
    return img


def _house(scale_w=40, scale_h=34, roof=ROOFC):
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=scale_w - 2)
    left = 48 - scale_w; right = 48 + scale_w
    top = BASE_Y - scale_h
    d.rectangle([left, top, right, BASE_Y], fill=WALLC, outline=WALL_D, width=2)
    d.polygon([(left - 4, top + 2), (right + 4, top + 2), (48, top - scale_h * 0.7)], fill=roof, outline=(168, 92, 78))
    d.rectangle([42, BASE_Y - 18, 54, BASE_Y], fill=WOOD_D)  # door
    d.ellipse([left + 6, top + 8, left + 16, top + 18], fill=(247, 223, 160))  # window
    d.ellipse([right - 16, top + 8, right - 6, top + 18], fill=(247, 223, 160))
    return img


def o_cottage():
    return _house(40, 34, ROOFC)


def o_shed():
    return _house(30, 26, (150, 120, 92))


def _wall(window=False, door=False, stone=False):
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=22, rh=6)
    fill = STONEC if stone else WALLC
    edge = STONE_D if stone else WALL_D
    d.rectangle([26, 44, 70, BASE_Y], fill=fill, outline=edge, width=2)
    if door:
        d.rectangle([40, BASE_Y - 26, 56, BASE_Y], fill=WOOD_D)
    if window:
        d.rectangle([38, 54, 58, 68], fill=(247, 223, 160), outline=edge)
    return img


def o_wall():
    return _wall()


def o_door_wall():
    return _wall(door=True)


def o_window_wall():
    return _wall(window=True)


def o_stone_wall():
    return _wall(stone=True)


def o_floor():
    img = _obj(); d = ImageDraw.Draw(img)
    d.rectangle([26, 58, 70, BASE_Y], fill=WOODC, outline=WOOD_D)
    for x in (37, 48, 59):
        d.line([x, 58, x, BASE_Y], fill=WOOD_D)
    return img


def o_foundation():
    img = _obj(); d = ImageDraw.Draw(img)
    d.rectangle([26, 58, 70, BASE_Y], fill=STONEC, outline=STONE_D)
    for x in (37, 48, 59):
        d.line([x, 58, x, BASE_Y], fill=STONE_D)
    return img


def o_post():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=10)
    d.rectangle([42, 40, 54, BASE_Y], fill=WOODC, outline=WOOD_D, width=2)
    return img


def o_roof():
    img = _obj(); d = ImageDraw.Draw(img)
    d.polygon([(24, BASE_Y), (72, BASE_Y), (48, 50)], fill=ROOFC, outline=(168, 92, 78))
    d.polygon([(34, BASE_Y - 6), (62, BASE_Y - 6), (48, 58)], fill=ROOF_HI)
    return img


def o_stairs():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=22, rh=6)
    for i, y in enumerate(range(58, BASE_Y, 8)):
        d.rectangle([30 + i * 4, y, 66 - i * 4, y + 7], fill=STONEC, outline=STONE_D)
    return img


def o_storage_chest():
    img = _obj(); d = ImageDraw.Draw(img)
    _shadow(d, rw=20)
    d.rounded_rectangle([32, 58, 64, BASE_Y], radius=3, fill=WOODC, outline=WOOD_D, width=2)
    d.rectangle([32, 56, 64, 64], fill=WOOD_HI, outline=WOOD_D)
    d.rectangle([45, 60, 51, 68], fill=(214, 178, 90))  # latch
    return img


OBJECTS = {
    "nature/tree": o_tree, "nature/fruit_tree": o_fruit_tree, "nature/pine": o_pine,
    "nature/bush": o_bush, "nature/rock": o_rock, "nature/flower_patch": o_flower_patch,
    "nature/mushroom": o_mushroom, "nature/grass_tuft": o_grass_tuft, "nature/stump": o_stump,
    "nature/water_edge": o_water_edge, "nature/crop_carrot": o_crop_carrot,
    "decor/mailbox": o_mailbox, "decor/sign": o_sign, "decor/fence": o_fence, "decor/gate": o_gate,
    "building/crate": o_crate, "building/workbench": o_workbench, "building/well": o_well,
    "building/prefab_cottage": o_cottage, "building/prefab_shed": o_shed,
    "building/wall": o_wall, "building/door_wall": o_door_wall,
    "building/window_wall": o_window_wall, "building/stone_wall": o_stone_wall,
    "building/floor": o_floor, "building/foundation": o_foundation,
    "building/post": o_post, "building/roof": o_roof, "building/stairs": o_stairs,
    "building/storage_chest": o_storage_chest,
}


OBJ_OUT = OUT / "objects"


def main() -> None:
    TERRAIN_OUT.mkdir(parents=True, exist_ok=True)
    UI_OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in TERRAIN.items():
        fn().save(TERRAIN_OUT / f"{name}.png")
    for name, fn in UI.items():
        fn().save(UI_OUT / f"{name}.png")
    for rel, fn in OBJECTS.items():
        dest = OBJ_OUT / f"{rel}.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        fn().save(dest)
    # A short README so the tracked folder explains itself.
    (OUT / "README.md").write_text(
        "# Hearthvale generated gap-fill art (original, committable)\n\n"
        "Original procedural top-down tiles + simple UI shapes for the "
        "`sprout_topdown` visual mode, generated by "
        "`tools/art/generate_hearthvale_gap_assets.py`. NOT derived from Sprout "
        "Lands or any third-party media. These are the GENERATED fallback the "
        "registries resolve when no licensed asset is active, so a clean checkout "
        "(no Sprout pack) still reads as a coherent top-down farming world.\n",
        encoding="utf-8")
    print(f"Wrote {len(TERRAIN)} terrain tiles -> {TERRAIN_OUT.relative_to(ROOT)}")
    print(f"Wrote {len(UI)} UI shapes -> {UI_OUT.relative_to(ROOT)}")
    print(f"Wrote {len(OBJECTS)} object sprites -> {OBJ_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
