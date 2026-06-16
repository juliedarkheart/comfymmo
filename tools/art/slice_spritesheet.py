#!/usr/bin/env python3
"""Slice a spritesheet into numbered cells + a manifest, for asset review.

Does NOT touch the original sheet and does NOT wire anything into the game. It
writes individual cell PNGs (transparent cells are skipped by default) and a
`slices.json` mapping cell index -> {row, col, bbox, file}. Pick the cells you
want from the contact sheet, then normalize them into
art/generated/from_external/active/<mirror> and activate via
art/active_art_manifest.json. See docs/asset_review_workflow.md.

Example:
  python tools/art/slice_spritesheet.py \
      --sheet "art/external/kenney/rpg-pack/RPGpack_sheet.png" \
      --cell 16 16 \
      --out "art/generated/from_external/kenney/rpg-pack/cells" \
      --skip-empty
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]


def _resolve(p: str) -> Path:
    path = Path(p)
    return path if path.is_absolute() else ROOT / path


def cell_is_empty(img: Image.Image) -> bool:
    if img.mode != "RGBA":
        return False
    alpha = img.getchannel("A")
    return alpha.getbbox() is None


def slice_sheet(sheet_path: Path, cell_w: int, cell_h: int, out_dir: Path,
                skip_empty: bool, prefix: str) -> dict:
    sheet = Image.open(sheet_path).convert("RGBA")
    cols = sheet.width // cell_w
    rows = sheet.height // cell_h
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "source": str(sheet_path.relative_to(ROOT)).replace("\\", "/"),
        "sheet_size": [sheet.width, sheet.height],
        "cell_size": [cell_w, cell_h],
        "cols": cols,
        "rows": rows,
        "cells": [],
        "note": "Review cells in the contact sheet; normalize chosen ones into "
                "active/<mirror> and activate via art/active_art_manifest.json. "
                "Slicing alone does NOT wire anything.",
    }
    written = 0
    for row in range(rows):
        for col in range(cols):
            index = row * cols + col
            box = (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)
            cell = sheet.crop(box)
            if skip_empty and cell_is_empty(cell):
                continue
            fname = f"{prefix}_{index:04d}_r{row}_c{col}.png"
            cell.save(out_dir / fname)
            manifest["cells"].append({
                "index": index, "row": row, "col": col,
                "bbox": list(box), "file": fname,
            })
            written += 1
    (out_dir / "slices.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Sliced {written} non-empty cells -> {out_dir} (grid {cols}x{rows}, cell {cell_w}x{cell_h})")
    return manifest


def main() -> None:
    ap = argparse.ArgumentParser(description="Slice a spritesheet into numbered cells.")
    ap.add_argument("--sheet", required=True, help="path to the spritesheet PNG")
    ap.add_argument("--cell", nargs=2, type=int, metavar=("W", "H"), required=True)
    ap.add_argument("--out", required=True, help="output directory for cell PNGs")
    ap.add_argument("--skip-empty", action="store_true", help="skip fully transparent cells")
    ap.add_argument("--prefix", default="cell")
    args = ap.parse_args()
    slice_sheet(_resolve(args.sheet), args.cell[0], args.cell[1], _resolve(args.out),
                args.skip_empty, args.prefix)


if __name__ == "__main__":
    main()
