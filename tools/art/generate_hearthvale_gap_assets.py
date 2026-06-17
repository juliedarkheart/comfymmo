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
    """Soft two-tone grain fill — no hard border, so tiles tessellate cleanly."""
    img = Image.new("RGBA", (TILE, TILE), base + (255,))
    px = img.load()
    for y in range(TILE):
        for x in range(TILE):
            n = _noise(x, y, seed)
            if n > 1.0 - grain * 0.34:
                px[x, y] = _mix(base, light, 0.55) + (255,)
            elif n < grain * 0.30:
                px[x, y] = _mix(base, dark, 0.5) + (255,)
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


def meadow():
    img = _base_tile((126, 176, 105), (150, 196, 121), (104, 156, 90), 1)
    _specks(img, (96, 146, 84), 1, 26)
    return img


def forest():
    img = _base_tile((78, 122, 70), (104, 150, 92), (58, 96, 54), 2)
    _specks(img, (52, 88, 50), 2, 30)
    return img


def orchard():
    img = _base_tile((150, 188, 96), (176, 206, 120), (124, 162, 80), 3)
    _specks(img, (224, 138, 75), 3, 8)   # fallen fruit
    _specks(img, (130, 168, 86), 13, 18)
    return img


def creekside():
    img = _base_tile((116, 170, 108), (142, 192, 126), (96, 148, 92), 4)
    _specks(img, (88, 140, 88), 4, 20)
    _specks(img, (180, 200, 150), 14, 6)  # reeds glint
    return img


def riverbank():
    img = _base_tile((214, 194, 140), (232, 214, 166), (190, 168, 116), 5, grain=0.6)
    _specks(img, (170, 150, 104), 5, 24)  # pebbles
    return img


def hilltop():
    img = _base_tile((140, 168, 122), (164, 190, 146), (118, 146, 102), 6)
    _specks(img, (158, 156, 142), 6, 12)  # exposed rock
    return img


def grove():
    img = _base_tile((66, 112, 64), (90, 138, 84), (50, 92, 50), 7)
    _specks(img, (44, 82, 46), 7, 28)
    return img


def town():
    img = _base_tile((196, 170, 122), (216, 192, 148), (170, 144, 100), 8, grain=0.4)
    # faint cobble seams
    d = ImageDraw.Draw(img)
    for gx in range(0, TILE, 8):
        d.line([(gx, 0), (gx, TILE)], fill=(168, 142, 100, 70))
    for gy in range(0, TILE, 8):
        d.line([(0, gy), (TILE, gy)], fill=(168, 142, 100, 70))
    return img


def farmland():
    img = _base_tile((156, 110, 70), (180, 134, 92), (130, 88, 54), 9, grain=0.6)
    _specks(img, (120, 80, 48), 9, 26)
    return img


def farmer_training():
    img = _base_tile((136, 182, 108), (160, 202, 130), (114, 158, 92), 10)
    d = ImageDraw.Draw(img)
    for i in range(0, TILE, 6):  # dashed training marker
        d.line([(i, TILE - 2), (i + 3, TILE - 2)], fill=(240, 224, 150, 150))
    return img


def dirt_path():
    img = _base_tile((184, 142, 92), (206, 166, 116), (156, 118, 74), 11, grain=0.6)
    _specks(img, (148, 110, 70), 11, 22)
    _specks(img, (210, 178, 130), 21, 10)
    return img


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
    img = _base_tile((140, 96, 62), (164, 120, 84), (116, 78, 48), 13, grain=0.5)
    d = ImageDraw.Draw(img)
    for ry in range(2, TILE, 6):  # furrow rows
        d.line([(0, ry), (TILE, ry)], fill=(106, 70, 42, 200))
        d.line([(0, ry + 1), (TILE, ry + 1)], fill=(176, 132, 92, 140))
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


def main() -> None:
    TERRAIN_OUT.mkdir(parents=True, exist_ok=True)
    UI_OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in TERRAIN.items():
        fn().save(TERRAIN_OUT / f"{name}.png")
    for name, fn in UI.items():
        fn().save(UI_OUT / f"{name}.png")
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


if __name__ == "__main__":
    main()
