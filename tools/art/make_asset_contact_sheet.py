#!/usr/bin/env python3
"""Make contact sheets for asset review (human-only artifacts under art/review/).

Two modes:

  folder  — tile a folder of PNGs into a labeled grid (uses filenames as labels).
  sheet   — overlay a numbered grid on a spritesheet so you can pick cells by
            index. Fully transparent cells can be skipped from labeling.

Nothing here is wired into the game. Review, then normalize chosen sprites into
art/generated/from_external/active/<mirror> and activate via
art/active_art_manifest.json. See docs/asset_review_workflow.md.

Examples:
  python tools/art/make_asset_contact_sheet.py folder \
      --dir art/tiles/biomes --out art/review/generated_terrain_contactsheet.png \
      --cols 5 --thumb 72 --title "Generated terrain tiles"

  python tools/art/make_asset_contact_sheet.py sheet \
      --sheet "art/external/kenney/rpg-pack/RPGpack_sheet.png" --cell 16 16 \
      --out art/review/kenney_rpg_pack_contactsheet.png --scale 3 --skip-empty
"""

from __future__ import annotations

import argparse
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]
PARCHMENT = (243, 224, 176, 255)
INK = (74, 52, 32, 255)
GRID = (134, 81, 31, 255)
HONEY = (224, 166, 75, 255)


def _resolve(p: str) -> Path:
    path = Path(p)
    return path if path.is_absolute() else ROOT / path


def _font(size: int = 12):
    try:
        return ImageFont.truetype("DejaVuSans.ttf", size)
    except Exception:
        return ImageFont.load_default()


def folder_sheet(folder: Path, out: Path, cols: int, thumb: int, title: str, recursive: bool = False) -> None:
    globber = folder.rglob if recursive else folder.glob
    pngs = sorted([p for p in globber("*.png")])
    if not pngs:
        raise SystemExit(f"No PNGs in {folder}")
    pad, label_h, header = 10, 16, 30
    cell = thumb + pad * 2 + label_h
    rows = (len(pngs) + cols - 1) // cols
    W = cols * cell + pad
    H = header + rows * cell + pad
    img = Image.new("RGBA", (W, H), PARCHMENT)
    d = ImageDraw.Draw(img)
    d.text((pad, 8), title, fill=INK, font=_font(15))
    for i, png in enumerate(pngs):
        r, c = divmod(i, cols)
        x = pad + c * cell
        y = header + r * cell
        d.rounded_rectangle([x, y, x + cell - pad, y + cell - pad], radius=6,
                            fill=(246, 234, 208, 255), outline=GRID, width=2)
        sprite = Image.open(png).convert("RGBA")
        sprite.thumbnail((thumb, thumb), Image.LANCZOS)
        ox = x + (cell - pad - sprite.width) // 2
        oy = y + pad + (thumb - sprite.height) // 2
        img.alpha_composite(sprite, (ox, oy))
        name = png.stem
        if len(name) > 14:
            name = name[:13] + "…"
        d.text((x + 6, y + cell - pad - label_h + 1), name, fill=INK, font=_font(11))
    out.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGBA").save(out)
    print(f"Folder contact sheet: {len(pngs)} sprites -> {out}")


def sheet_overlay(sheet_path: Path, out: Path, cw: int, ch: int, scale: int, skip_empty: bool) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    cols = sheet.width // cw
    rows = sheet.height // ch
    big = sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST)
    margin = 26
    canvas = Image.new("RGBA", (big.width + margin, big.height + margin), PARCHMENT)
    canvas.alpha_composite(big, (margin, margin))
    d = ImageDraw.Draw(canvas)
    title = f"{sheet_path.name}  grid {cols}x{ch and rows}  cell {cw}x{ch}  (indices = row*cols+col)"
    d.text((4, 6), title, fill=INK, font=_font(12))
    f = _font(max(9, scale * 3))
    for row in range(rows):
        for col in range(cols):
            x0 = margin + col * cw * scale
            y0 = margin + row * ch * scale
            d.rectangle([x0, y0, x0 + cw * scale, y0 + ch * scale], outline=GRID, width=1)
            if skip_empty:
                cell = sheet.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
                if cell.getchannel("A").getbbox() is None:
                    continue
            index = row * cols + col
            d.text((x0 + 2, y0 + 1), str(index), fill=(20, 16, 12, 255), font=f)
            d.text((x0 + 1, y0), str(index), fill=HONEY, font=f)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    print(f"Sheet contact sheet: grid {cols}x{rows} -> {out}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Make asset-review contact sheets.")
    sub = ap.add_subparsers(dest="mode", required=True)

    fp = sub.add_parser("folder")
    fp.add_argument("--dir", required=True)
    fp.add_argument("--out", required=True)
    fp.add_argument("--cols", type=int, default=6)
    fp.add_argument("--thumb", type=int, default=72)
    fp.add_argument("--title", default="Asset contact sheet")
    fp.add_argument("--recursive", action="store_true")

    sp = sub.add_parser("sheet")
    sp.add_argument("--sheet", required=True)
    sp.add_argument("--out", required=True)
    sp.add_argument("--cell", nargs=2, type=int, metavar=("W", "H"), required=True)
    sp.add_argument("--scale", type=int, default=3)
    sp.add_argument("--skip-empty", action="store_true")

    args = ap.parse_args()
    if args.mode == "folder":
        folder_sheet(_resolve(args.dir), _resolve(args.out), args.cols, args.thumb, args.title, args.recursive)
    else:
        sheet_overlay(_resolve(args.sheet), _resolve(args.out), args.cell[0], args.cell[1],
                      args.scale, args.skip_empty)


if __name__ == "__main__":
    main()
