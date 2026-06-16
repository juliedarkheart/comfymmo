#!/usr/bin/env python3
"""Generate Hearthvale placeholder art — cozy, readable, isometric-friendly.

This is a *generated placeholder* pipeline, not final art. It now renders with
Pillow at 4x supersampling and downsamples with LANCZOS, so the placeholders are
soft, anti-aliased, and warm (storybook toybox) instead of hard-edged polygons.
Output paths, canvas sizes, and pivots are unchanged, so the Godot art
registries and map/placeable rendering keep working with no code changes.

Run:  python tools/art/generate_placeholder_art.py
Needs Pillow (`pip install Pillow`). If Pillow is missing the script explains how
to install it and exits without touching existing art.

Replace later with verified CC0/public-domain art or a ComfyUI batch; see
docs/graphics_pipeline.md and docs/asset_credits.md.
"""

from __future__ import annotations

import random
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:  # pragma: no cover - environment guard
    raise SystemExit(
        "Pillow is required: pip install Pillow\n"
        "(The generator now uses Pillow for anti-aliased cozy placeholders.)"
    )

ROOT = Path(__file__).resolve().parents[2]
SS = 4  # supersampling factor: render big, shrink smooth

TILE = (64, 48)
OBJECT = (96, 96)
ICON = (64, 64)


def hx(color: str, a: int = 255):
    c = color.lstrip("#")
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), a)


def shade(color, factor: float):
    """Lighten (factor>1) or darken (factor<1) an rgba tuple."""
    r, g, b, a = color
    return (
        max(0, min(255, int(r * factor))),
        max(0, min(255, int(g * factor))),
        max(0, min(255, int(b * factor))),
        a,
    )


class Sprite:
    """A supersampled RGBA canvas with cozy drawing helpers."""

    def __init__(self, size):
        self.w, self.h = size
        self.img = Image.new("RGBA", (self.w * SS, self.h * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def _s(self, v):
        return v * SS

    def poly(self, pts, color, outline=None, ow=0):
        sp = [(x * SS, y * SS) for x, y in pts]
        self.d.polygon(sp, fill=color, outline=outline, width=int(ow * SS))

    def ellipse(self, cx, cy, rx, ry, color, outline=None, ow=0):
        box = [(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS]
        self.d.ellipse(box, fill=color, outline=outline, width=int(ow * SS))

    def line(self, a, b, width, color):
        self.d.line([(a[0] * SS, a[1] * SS), (b[0] * SS, b[1] * SS)],
                    fill=color, width=max(1, int(width * SS)))

    def soft_shadow(self, cx, cy, rx, ry, alpha=70):
        """A blurred contact shadow for grounding objects."""
        layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        ld.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS],
                   fill=(30, 24, 18, alpha))
        layer = layer.filter(ImageFilter.GaussianBlur(2.2 * SS))
        self.img.alpha_composite(layer)

    def diamond_pts(self, cx, cy, hw, hh):
        return [(cx, cy - hh), (cx + hw, cy), (cx, cy + hh), (cx - hw, cy)]

    def finish(self, rel_path: str):
        out = self.img.resize((self.w, self.h), Image.LANCZOS)
        path = ROOT / rel_path
        path.parent.mkdir(parents=True, exist_ok=True)
        out.save(path)


# --- Terrain tiles -----------------------------------------------------------

def iso_tile(base_hex, *, kind="grass", detail_hex=None, outline_hex="46361f", seed=0):
    """A cozy isometric ground tile (64x48) with a soft 3D lip + biome texture."""
    s = Sprite(TILE)
    cx, cy, hw, hh = 32, 25, 29, 13
    base = hx(base_hex)
    detail = hx(detail_hex) if detail_hex else shade(base, 1.16)
    rng = random.Random(seed)

    # Contact shadow under the tile lip.
    s.soft_shadow(cx, cy + 5, hw - 1, hh - 1, alpha=46)
    # Side lip (darker) for a little height.
    s.poly([(cx - hw, cy), (cx, cy + hh), (cx + hw, cy), (cx, cy + hh + 5), (cx - hw, cy + 0)],
           shade(base, 0.72))
    s.poly(s.diamond_pts(cx, cy + 4, hw, hh), shade(base, 0.78))
    # Top face with a vertical light gradient (north-lit).
    top = Image.new("RGBA", (TILE[0] * SS, TILE[1] * SS), (0, 0, 0, 0))
    td = ImageDraw.Draw(top)
    steps = 14
    for i in range(steps):
        f = 1.12 - (i / steps) * 0.26
        yy0 = (cy - hh) + (2 * hh) * (i / steps)
        yy1 = (cy - hh) + (2 * hh) * ((i + 1) / steps)
        # clip a horizontal band to the diamond by drawing band-coloured diamonds is hard;
        # approximate with thin polygons spanning the diamond width at that row.
        wfac = 1 - abs((yy0 - cy) / hh)
        hwid = max(1, hw * wfac)
        td.rectangle([(cx - hwid) * SS, yy0 * SS, (cx + hwid) * SS, yy1 * SS], fill=shade(base, f))
    # mask to diamond
    mask = Image.new("L", top.size, 0)
    ImageDraw.Draw(mask).polygon([(x * SS, y * SS) for x, y in s.diamond_pts(cx, cy, hw, hh)], fill=255)
    s.img.paste(top, (0, 0), Image.composite(top.split()[3], Image.new("L", top.size, 0), mask))

    _tile_texture(s, kind, base, detail, cx, cy, hw, hh, rng)

    # Top bevel highlight + soft outline.
    s.line((cx - hw, cy), (cx, cy - hh), 1.2, shade(base, 1.3))
    s.line((cx, cy - hh), (cx + hw, cy), 1.2, shade(base, 1.22))
    s.d.line([(p[0] * SS, p[1] * SS) for p in s.diamond_pts(cx, cy, hw, hh)] +
             [(s.diamond_pts(cx, cy, hw, hh)[0][0] * SS, s.diamond_pts(cx, cy, hw, hh)[0][1] * SS)],
             fill=hx(outline_hex, 90), width=int(1 * SS))
    return s


def _scatter(s, rng, cx, cy, hw, hh, n, draw):
    for _ in range(n):
        u = rng.uniform(-1, 1)
        v = rng.uniform(-1, 1)
        if abs(u) + abs(v) > 0.92:
            continue
        px = cx + u * hw
        py = cy + v * hh
        draw(px, py)


def _tile_texture(s, kind, base, detail, cx, cy, hw, hh, rng):
    if kind == "grass":
        _scatter(s, rng, cx, cy, hw, hh, 26,
                 lambda px, py: s.line((px, py), (px - 0.6, py - 2.4), 0.7, shade(detail, 1.05)))
        _scatter(s, rng, cx, cy, hw, hh, 16,
                 lambda px, py: s.line((px, py), (px + 0.6, py - 2.0), 0.7, shade(base, 0.84)))
    elif kind == "leafy":
        _scatter(s, rng, cx, cy, hw, hh, 22,
                 lambda px, py: s.ellipse(px, py, 2.0, 1.3, shade(detail, 1.0)))
        _scatter(s, rng, cx, cy, hw, hh, 14,
                 lambda px, py: s.ellipse(px, py, 1.6, 1.0, shade(base, 0.8)))
    elif kind == "blossom":
        _scatter(s, rng, cx, cy, hw, hh, 20,
                 lambda px, py: s.line((px, py), (px, py - 2.2), 0.7, shade(base, 0.86)))
        _scatter(s, rng, cx, cy, hw, hh, 8,
                 lambda px, py: s.ellipse(px, py, 1.5, 1.5, hx("f4c4d6")))
    elif kind == "rocky":
        _scatter(s, rng, cx, cy, hw, hh, 10,
                 lambda px, py: s.ellipse(px, py, 2.4, 1.4, hx("c2beb4")))
        _scatter(s, rng, cx, cy, hw, hh, 16,
                 lambda px, py: s.line((px, py), (px - 0.5, py - 2.0), 0.7, shade(detail, 1.0)))
    elif kind == "soil":
        for i in range(-3, 4):
            yy = cy + i * 3.0
            wfac = 1 - abs((yy - cy) / hh)
            s.line((cx - hw * wfac + 2, yy), (cx + hw * wfac - 2, yy), 1.1, shade(base, 0.8))
            s.line((cx - hw * wfac + 2, yy - 0.8), (cx + hw * wfac - 2, yy - 0.8), 0.6, shade(detail, 1.05))
    elif kind == "dirt":
        _scatter(s, rng, cx, cy, hw, hh, 16,
                 lambda px, py: s.ellipse(px, py, 1.6, 1.0, shade(base, 0.82)))
        _scatter(s, rng, cx, cy, hw, hh, 8,
                 lambda px, py: s.ellipse(px, py, 1.2, 0.8, hx("8a6a42")))
    elif kind == "cobble":
        for ix in range(-2, 3):
            for iy in range(-2, 3):
                px = cx + ix * 11 + (6 if iy % 2 else 0)
                py = cy + iy * 6
                if abs((px - cx) / hw) + abs((py - cy) / hh) < 0.8:
                    s.ellipse(px, py, 4.2, 2.4, shade(base, 1.04), outline=hx("7a6a45", 120), ow=0.6)
    elif kind == "water":
        s.ellipse(cx, cy, hw - 4, hh - 2, shade(base, 1.08))
        for yy in (cy - 4, cy + 1, cy + 5):
            s.line((cx - 12, yy), (cx + 12, yy), 1.0, hx("e8f8ff", 150))
        s.ellipse(cx - 7, cy - 3, 4, 1.6, hx("ffffff", 120))
    elif kind == "boundary":
        s.line((cx - hw + 4, cy), (cx + hw - 4, cy), 3.0, hx("e6c76d", 220))
        s.line((cx - hw + 4, cy), (cx + hw - 4, cy), 1.0, hx("fff0a8", 230))
    elif kind == "corner":
        s.ellipse(cx, cy + 1, 4, 2.2, hx("2b2119", 70))
        s.poly([(cx - 2.5, cy), (cx + 2.5, cy), (cx + 2.5, cy - 18), (cx - 2.5, cy - 18)], hx("9a663a"))
        s.ellipse(cx, cy - 19, 4, 2, hx("f0cf78"))


TERRAIN = {
    "meadow": ("art/tiles/biomes/meadow.png", "8bbb6c", "b6da8f", "grass"),
    "forest": ("art/tiles/biomes/forest.png", "557d49", "7aa861", "leafy"),
    "orchard": ("art/tiles/biomes/orchard.png", "84b061", "cbe0a0", "blossom"),
    "creekside": ("art/tiles/biomes/creekside.png", "7fb389", "a9d6b4", "grass"),
    "riverbank": ("art/tiles/biomes/riverbank.png", "82b585", "b3dcb0", "grass"),
    "hilltop": ("art/tiles/biomes/hilltop.png", "97c07c", "c3d8a4", "rocky"),
    "grove": ("art/tiles/biomes/grove.png", "5d8c52", "82af6f", "leafy"),
    "town": ("art/tiles/biomes/town.png", "b3a878", "d2c597", "cobble"),
    "farmland": ("art/tiles/biomes/farmland.png", "a6864f", "c2a06a", "soil"),
    "farmer_training": ("art/tiles/biomes/farmer_training.png", "9c894f", "baa164", "soil"),
    "dirt_path": ("art/tiles/paths/dirt_path.png", "c6a677", "ddc39a", "dirt"),
    "stone_path": ("art/tiles/paths/stone_path.png", "c2c3c8", "e0e0e6", "cobble"),
    "tilled_soil": ("art/tiles/paths/tilled_soil.png", "8c6740", "a8824f", "soil"),
    "plot_boundary": ("art/tiles/paths/plot_boundary.png", "8bbb6c", "e6c76d", "boundary"),
    "plot_corner": ("art/tiles/paths/plot_corner.png", "8bbb6c", "e6c76d", "corner"),
    "water": ("art/tiles/water/water.png", "5ba6cf", "bfe9ff", "water"),
    "creek": ("art/tiles/water/creek.png", "63add2", "c6ecff", "water"),
    "water_edge": ("art/tiles/water/water_edge.png", "7fb389", "5ba6cf", "water"),
}

TRANSITIONS = {
    "grass_to_path": ("8bbb6c", "c6a677"),
    "grass_to_water": ("8bbb6c", "5ba6cf"),
    "grass_to_farmland": ("8bbb6c", "a6864f"),
    "biome_soft_edge": ("8bbb6c", "7aa861"),
    "path_edge": ("c6a677", "8bbb6c"),
    "water_edge": ("5ba6cf", "8bbb6c"),
}


# --- Objects -----------------------------------------------------------------

def obj_canvas():
    return Sprite(OBJECT)


def round_blob(s, cx, cy, rx, ry, color, light=1.18, dark=0.8):
    s.ellipse(cx, cy, rx, ry, shade(color, dark))
    s.ellipse(cx, cy - ry * 0.12, rx * 0.94, ry * 0.9, color)
    s.ellipse(cx - rx * 0.28, cy - ry * 0.34, rx * 0.5, ry * 0.45, shade(color, light))


def make_object(rel_path: str, kind: str):
    s = obj_canvas()
    s.soft_shadow(48, 80, 26, 8, alpha=80)
    wood, wdark, wlight = hx("b07a47"), hx("6f4528"), hx("d9b27e")
    leaf, leaf2, leaf3 = hx("6aa05a"), hx("8cc275"), hx("4f7a44")
    stone, stlight = hx("a7a39a"), hx("c8c4bb")
    cream, roof, water = hx("f2dfb8"), hx("c87d6c"), hx("5ba6cf")

    if kind in ("tree", "fruit_tree"):
        s.poly([(44, 80), (52, 80), (54, 46), (42, 46)], wood)
        s.line((48, 78), (48, 50), 1.5, wdark)
        round_blob(s, 37, 40, 18, 15, leaf2)
        round_blob(s, 60, 41, 17, 14, leaf)
        round_blob(s, 48, 28, 24, 20, leaf2)
        s.ellipse(40, 22, 9, 7, hx("a6d488"))
        if kind == "fruit_tree":
            for x, y in [(35, 44), (58, 38), (50, 52), (44, 33)]:
                s.ellipse(x, y, 3, 3, hx("e87fa0"))
                s.ellipse(x - 0.8, y - 0.8, 1.1, 1.1, hx("ffd0de"))
    elif kind == "rock":
        s.poly([(24, 78), (32, 56), (50, 49), (72, 58), (76, 74), (56, 84), (34, 84)], shade(stone, 0.82))
        s.poly([(30, 70), (40, 56), (52, 53), (66, 62), (66, 74), (44, 78)], stone)
        s.ellipse(45, 60, 10, 5, stlight)
        s.ellipse(62, 70, 7, 3.4, hx("7da964", 180))
    elif kind == "bush":
        round_blob(s, 40, 64, 16, 12, leaf)
        round_blob(s, 58, 62, 15, 12, leaf3)
        round_blob(s, 49, 56, 17, 13, leaf2)
        for x, y in [(38, 58), (60, 56)]:
            s.ellipse(x, y, 2, 2, hx("f4d36b"))
    elif kind == "flower_patch":
        round_blob(s, 48, 70, 25, 10, hx("6f9c5f"))
        for x, y, c in [(34, 64, "e8a0b4"), (47, 60, "f4d36b"), (60, 65, "cdb4dd"), (52, 70, "f0945a"), (40, 70, "9fc4e8")]:
            for ang in range(0, 360, 72):
                import math
                s.ellipse(x + math.cos(math.radians(ang)) * 2.4, y + math.sin(math.radians(ang)) * 2.4, 1.7, 1.7, hx(c))
            s.ellipse(x, y, 1.6, 1.6, hx("fff2c4"))
    elif kind in ("fence", "gate"):
        for x in (28, 48, 68):
            s.poly([(x - 3, 76), (x + 3, 76), (x + 3, 44), (x - 3, 44)], wood)
            s.ellipse(x, 43, 4.5, 2.6, wlight)
            s.line((x - 2, 47), (x - 2, 74), 1, wdark)
        s.line((22, 53), (74, 53), 5, wood)
        s.line((22, 53), (74, 51.5), 1.4, wlight)
        s.line((22, 66), (74, 66), 5, wood)
        if kind == "gate":
            s.line((36, 54), (60, 65), 3.5, shade(wood, 1.1))
            s.line((60, 54), (36, 65), 3.5, shade(wood, 1.1))
    elif kind == "sign":
        s.poly([(44, 80), (52, 80), (52, 38), (44, 38)], wood)
        s.poly([(22, 34), (74, 34), (74, 58), (22, 58)], cream, outline=wdark, ow=1.5)
        s.line((30, 42), (66, 42), 2, hx("9a7b53"))
        s.line((30, 48), (60, 48), 2, hx("9a7b53"))
    elif kind == "mailbox":
        s.poly([(42, 80), (48, 80), (48, 52), (42, 52)], wood)
        s.poly([(34, 42), (62, 42), (70, 50), (62, 66), (40, 66), (34, 58)], hx("8fbce4"), outline=hx("4f7da8"), ow=1.5)
        s.ellipse(48, 54, 11, 9, hx("a9d2f0"))
        s.poly([(70, 40), (82, 45), (70, 50)], hx("d85f4f"))
        s.line((50, 52), (62, 52), 2.5, cream)
    elif kind in ("foundation", "floor"):
        col = stone if kind == "foundation" else hx("cb9f63")
        det = stlight if kind == "foundation" else hx("e0bf8a")
        s.poly([(48, 38), (84, 58), (48, 78), (12, 58)], shade(col, 0.7))
        s.poly([(48, 42), (80, 58), (48, 74), (16, 58)], col)
        s.poly([(48, 46), (66, 58), (48, 70), (30, 58)], det)
        if kind == "floor":
            for off in (-12, 0, 12):
                s.line((48 + off, 46), (48 + off + 16, 58), 0.8, shade(col, 0.78))
    elif kind in ("wall", "stone_wall", "door_wall", "window_wall"):
        fill = stone if kind == "stone_wall" else wood
        s.poly([(24, 78), (72, 78), (72, 34), (24, 34)], shade(fill, 0.88))
        s.poly([(24, 78), (68, 78), (68, 34), (24, 34)], fill)
        s.poly([(24, 34), (72, 34), (66, 26), (30, 26)], shade(fill, 1.15))
        if kind == "door_wall":
            s.poly([(40, 78), (56, 78), (56, 50), (48, 43), (40, 50)], wdark)
            s.ellipse(53, 64, 1.6, 1.6, hx("f4d36b"))
        elif kind == "window_wall":
            s.poly([(36, 44), (60, 44), (60, 60), (36, 60)], hx("bfe0f0"), outline=wdark, ow=1.5)
            s.line((48, 44), (48, 60), 1.5, wdark)
            s.line((36, 52), (60, 52), 1.5, wdark)
        elif kind == "stone_wall":
            for x, y in [(34, 46), (54, 40), (46, 60), (60, 64)]:
                s.ellipse(x, y, 7, 3.4, stlight, outline=shade(stone, 0.8), ow=0.6)
    elif kind == "roof":
        s.poly([(12, 56), (48, 22), (84, 56), (74, 64), (22, 64)], roof)
        s.poly([(24, 52), (48, 30), (72, 52), (66, 56), (30, 56)], shade(roof, 1.12))
        s.line((48, 24), (48, 62), 1, shade(roof, 0.8))
    elif kind == "post":
        s.poly([(43, 80), (53, 80), (53, 26), (43, 26)], wood)
        s.line((45, 30), (45, 76), 1.2, wdark)
        s.ellipse(48, 25, 9, 4, wlight)
    elif kind == "workbench":
        s.poly([(22, 56), (74, 56), (78, 66), (18, 66)], wood)
        s.poly([(22, 53), (74, 53), (74, 56), (18, 56)], wlight)
        s.poly([(26, 66), (32, 66), (32, 80), (26, 80)], wdark)
        s.poly([(64, 66), (70, 66), (70, 80), (64, 80)], wdark)
        s.ellipse(40, 49, 6, 4, stone)
        s.poly([(56, 46), (66, 50), (62, 54), (52, 50)], hx("d6b25a"))
    elif kind in ("storage_chest", "crate"):
        s.poly([(24, 56), (36, 44), (60, 44), (74, 56), (70, 76), (28, 76)], wood)
        s.poly([(30, 46), (48, 34), (66, 46), (60, 52), (36, 52)], shade(wood, 1.12))
        s.line((36, 52), (36, 74), 3, wdark)
        s.line((60, 52), (60, 74), 3, wdark)
        s.ellipse(48, 60, 3, 3, hx("f4d36b"))
    elif kind in ("prefab_cottage", "prefab_shed"):
        wall = cream if kind == "prefab_cottage" else hx("c79a63")
        roof_color = roof if kind == "prefab_cottage" else hx("8a5a36")
        s.poly([(20, 74), (76, 74), (76, 40), (20, 40)], wall, outline=shade(wall, 0.75), ow=1.5)
        s.poly([(8, 44), (48, 14), (88, 44), (78, 52), (18, 52)], roof_color)
        s.poly([(20, 42), (48, 22), (76, 42), (70, 46), (26, 46)], shade(roof_color, 1.12))
        s.poly([(40, 74), (56, 74), (56, 54), (48, 47), (40, 54)], wdark)
        if kind == "prefab_cottage":
            for x in (30, 66):
                s.poly([(x - 6, 50), (x + 6, 50), (x + 6, 62), (x - 6, 62)], hx("bfe0f0"), outline=wdark, ow=1)
                s.line((x, 50), (x, 62), 1, wdark)
            s.poly([(60, 14), (66, 14), (66, 26), (60, 26)], hx("9a6a4a"))
    elif kind == "water_edge":
        s.ellipse(48, 70, 30, 9, water)
        s.line((24, 68), (72, 68), 1.4, hx("e8f8ff", 170))
        round_blob(s, 36, 62, 11, 6, leaf)
    elif kind == "crop_carrot":
        s.ellipse(48, 74, 18, 7, hx("7da964"))
        for x in (40, 48, 56):
            s.poly([(x - 3, 70), (x + 3, 70), (x, 84)], hx("f0945a"))
            s.line((x, 84), (x, 78), 0.8, hx("c96a3a"))
            s.ellipse(x - 2, 66, 3, 5, leaf2)
            s.ellipse(x + 2, 66, 3, 5, leaf)
    elif kind == "well":
        s.ellipse(48, 72, 25, 11, shade(stone, 0.85))
        s.ellipse(48, 70, 18, 8, water)
        s.ellipse(48, 69, 12, 5, shade(water, 1.12))
        s.poly([(30, 67), (34, 67), (34, 34), (30, 34)], wood)
        s.poly([(62, 67), (66, 67), (66, 34), (62, 34)], wood)
        s.poly([(24, 36), (48, 20), (72, 36), (66, 42), (30, 42)], roof)
    elif kind == "stairs":
        for i in range(4):
            y = 76 - i * 8
            c = shade(wood, 1.08) if i % 2 else wood
            s.poly([(26 + i * 4, y), (70 - i * 4, y), (66 - i * 4, y - 7), (30 + i * 4, y - 7)], c)
            s.line((30 + i * 4, y - 7), (66 - i * 4, y - 7), 0.8, wlight)
    else:
        round_blob(s, 48, 56, 18, 18, hx("c98a4a"))
    s.finish(rel_path)


# --- Icons -------------------------------------------------------------------

def make_icon(rel_path: str, kind: str):
    s = Sprite(ICON)
    # Parchment rounded backing so icons read on any panel.
    s.d.rounded_rectangle([6 * SS, 6 * SS, 58 * SS, 58 * SS], radius=12 * SS,
                          fill=hx("f6ead0"), outline=hx("c8893f"), width=int(2 * SS))
    s.ellipse(32, 30, 22, 20, hx("ffe9a8", 90))
    wood, wdark, stone, leaf = hx("b07a47"), hx("6f4528"), hx("a7a39a"), hx("6aa05a")

    if kind == "wood":
        for x, y in [(24, 36), (34, 30), (38, 41)]:
            s.ellipse(x, y, 12, 5, wood)
            s.ellipse(x, y, 5, 2.2, hx("e0bf8a"))
            s.ellipse(x, y, 2, 1, hx("8a5a36"))
    elif kind == "stone":
        s.poly([(18, 44), (25, 26), (41, 21), (50, 38), (40, 49), (24, 50)], stone)
        s.ellipse(31, 30, 8, 4, hx("c8c4bb"))
    elif kind == "fiber":
        for x in (24, 30, 36, 42):
            s.line((x, 46), (x - 6, 20), 3, leaf)
        s.ellipse(32, 47, 9, 3, hx("5f8c56"))
    elif kind == "clay":
        s.ellipse(32, 40, 18, 11, hx("a8714d"))
        s.ellipse(28, 34, 10, 5, hx("c4946a"))
    elif kind == "carrot":
        s.poly([(27, 24), (41, 24), (34, 52)], hx("f0945a"))
        s.line((34, 50), (34, 30), 1, hx("c96a3a"))
        s.ellipse(29, 21, 7, 6, leaf)
        s.ellipse(39, 20, 7, 6, hx("8cc275"))
    elif kind in ("axe", "pickaxe", "hoe", "hammer", "shovel"):
        s.line((22, 48), (43, 18), 4.5, wood)
        if kind == "axe":
            s.poly([(38, 15), (53, 22), (43, 34), (34, 25)], stone)
        elif kind == "pickaxe":
            s.line((21, 23), (53, 17), 4.5, stone)
            s.ellipse(37, 20, 3, 3, hx("c8c4bb"))
        elif kind == "hoe":
            s.line((38, 20), (53, 22), 4.5, stone)
            s.poly([(50, 22), (54, 23), (52, 34), (47, 32)], stone)
        elif kind == "hammer":
            s.poly([(34, 15), (55, 21), (53, 31), (32, 25)], stone)
        else:
            s.poly([(39, 16), (53, 24), (44, 39), (30, 31)], stone)
    elif kind == "watering_can":
        s.ellipse(30, 38, 14, 12, hx("7db5cf"))
        s.ellipse(26, 33, 6, 7, hx("bcd8e8", 150))
        s.poly([(40, 30), (54, 24), (56, 28), (42, 36)], hx("7db5cf"))
        s.line((30, 24), (40, 24), 4, hx("5f97b3"))
    elif kind == "land_token":
        s.ellipse(32, 32, 17, 17, hx("e0a64b"), outline=hx("a9742a"), ow=1.5)
        s.ellipse(32, 32, 10, 10, hx("ffe9a8"))
        s.poly([(32, 25), (35, 31), (32, 30), (29, 31)], hx("d8902f"))
        s.line((26, 32), (38, 32), 1.5, hx("a9742a"))
    elif kind == "build_tool":
        s.line((22, 46), (44, 24), 5, wood)
        s.poly([(30, 18), (50, 18), (50, 27), (30, 27)], stone)
        s.ellipse(33, 22, 1.5, 1.5, hx("6f6b62"))
        s.ellipse(46, 22, 1.5, 1.5, hx("6f6b62"))
    elif kind == "delete":
        s.line((23, 23), (41, 41), 5, hx("c25448"))
        s.line((41, 23), (23, 41), 5, hx("c25448"))
    elif kind == "rotate":
        s.d.arc([16 * SS, 16 * SS, 48 * SS, 48 * SS], start=20, end=300, fill=hx("5f9150"), width=int(4 * SS))
        s.poly([(45, 16), (52, 20), (44, 26)], hx("5f9150"))
    elif kind == "paint":
        s.poly([(22, 44), (30, 26), (40, 30), (32, 48)], hx("8bbb6c"))
        s.ellipse(40, 26, 6, 6, hx("c6a677"))
        s.line((44, 24), (52, 18), 3, wood)
    else:
        s.ellipse(32, 32, 12, 12, hx("c25448"))
    s.finish(rel_path)


def write_text(rel_path: str, text: str):
    p = ROOT / rel_path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")


def make_missing():
    s = Sprite((64, 64))
    s.d.rounded_rectangle([6 * SS, 6 * SS, 58 * SS, 58 * SS], radius=10 * SS,
                          fill=hx("c25448", 220), outline=hx("fff0a8"), width=int(3 * SS))
    s.line((16, 16), (48, 48), 4, hx("fff0a8"))
    s.line((48, 16), (16, 48), 4, hx("fff0a8"))
    s.finish("art/placeholders/missing.png")


def main():
    make_missing()
    for _name, (path, base, detail, kind) in TERRAIN.items():
        iso_tile(base, kind=kind, detail_hex=detail, seed=hash(_name) & 0xFFFF).finish(path)
    for name, (a, b) in TRANSITIONS.items():
        # A soft split tile: biome A diamond with biome B wedge — a cozy edge hint.
        s = iso_tile(a, kind="grass", seed=hash(name) & 0xFFFF)
        s.poly([(32, 25), (61, 25), (32, 38), (3, 25)], hx(b, 150))
        s.finish(f"art/tiles/terrain/{name}.png")

    objects = {
        "art/objects/nature/tree.png": "tree",
        "art/objects/nature/fruit_tree.png": "fruit_tree",
        "art/objects/nature/rock.png": "rock",
        "art/objects/nature/bush.png": "bush",
        "art/objects/nature/flower_patch.png": "flower_patch",
        "art/objects/nature/water_edge.png": "water_edge",
        "art/objects/nature/crop_carrot.png": "crop_carrot",
        "art/objects/decor/fence.png": "fence",
        "art/objects/decor/gate.png": "gate",
        "art/objects/decor/sign.png": "sign",
        "art/objects/decor/mailbox.png": "mailbox",
        "art/objects/building/foundation.png": "foundation",
        "art/objects/building/floor.png": "floor",
        "art/objects/building/wall.png": "wall",
        "art/objects/building/stone_wall.png": "stone_wall",
        "art/objects/building/door_wall.png": "door_wall",
        "art/objects/building/window_wall.png": "window_wall",
        "art/objects/building/roof.png": "roof",
        "art/objects/building/post.png": "post",
        "art/objects/building/workbench.png": "workbench",
        "art/objects/building/storage_chest.png": "storage_chest",
        "art/objects/building/crate.png": "crate",
        "art/objects/building/prefab_cottage.png": "prefab_cottage",
        "art/objects/building/prefab_shed.png": "prefab_shed",
        "art/objects/building/well.png": "well",
        "art/objects/building/stairs.png": "stairs",
    }
    for path, kind in objects.items():
        make_object(path, kind)

    icons = {
        "wood": "wood", "stone": "stone", "fiber": "fiber", "clay": "clay",
        "carrot": "carrot", "worn_axe": "axe", "worn_pickaxe": "pickaxe",
        "worn_hoe": "hoe", "watering_can": "watering_can",
        "simple_hammer": "hammer", "basic_shovel": "shovel",
        "land_token": "land_token", "build_tool": "build_tool",
        "delete": "delete", "rotate": "rotate", "paint": "paint",
    }
    for name, kind in icons.items():
        make_icon(f"art/ui/icons/{name}.png", kind)

    write_text("art/generated/README.md",
               "# Generated placeholder art\n\n"
               "Created by `tools/art/generate_placeholder_art.py` (Pillow, 4x supersampled).\n"
               "Project-local CC0-style placeholders — safe to replace with verified CC0/public-domain\n"
               "art or ComfyUI output. See docs/graphics_pipeline.md and docs/asset_credits.md.\n")
    write_text("art/generated/from_external/README.md",
               "# Normalized derivatives of external assets\n\n"
               "Empty: no external assets have been imported yet. When a verified CC0/public-domain\n"
               "asset is imported under `art/external/<source>/<asset>/`, place resized/cropped/padded\n"
               "derivatives here under `from_external/<source>/<asset>/` and record them in\n"
               "`manifest.json` (source file -> derived file, size, edits). See docs/graphics_pipeline.md.\n")
    print("Generated Hearthvale placeholder art (Pillow, supersampled).")


if __name__ == "__main__":
    main()
