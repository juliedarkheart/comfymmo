#!/usr/bin/env python3
"""Stage an external asset pack for review (no wiring, no overwrite of originals).

Given an already-downloaded pack folder under art/external/<source>/<asset>/,
this:
  - checks the folder has a LICENSE + a source/attribution file (the same gate
    tools/validate_project.gd enforces);
  - builds a review contact sheet under art/review/;
  - (optionally, for an unlabeled spritesheet) slices it into numbered cells
    under art/generated/from_external/<source>/<asset>/cells/.

It deliberately does NOT normalize-into-active or edit art_active_manifest.json —
activation stays a manual, post-review step. See docs/asset_review_workflow.md.

Example:
  python tools/art/import_asset_pack.py \
      --pack art/external/kenney/rpg-pack --sheet RPGpack_sheet.png --cell 16 16
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LICENSE_NAMES = ["LICENSE", "LICENSE.txt", "LICENSE.md", "COPYING", "COPYING.txt"]
SOURCE_NAMES = ["README.md", "README.txt", "SOURCE.txt", "CREDITS.txt",
                "ATTRIBUTION.txt", "NOTICE", "asset.json", "source.json"]


def _resolve(p: str) -> Path:
    path = Path(p)
    return path if path.is_absolute() else ROOT / path


def check_metadata(pack: Path) -> None:
    has_license = any((pack / n).exists() for n in LICENSE_NAMES)
    has_source = any((pack / n).exists() for n in SOURCE_NAMES)
    if not has_license:
        raise SystemExit(f"FAIL: {pack} has no license file ({', '.join(LICENSE_NAMES)})")
    if not has_source:
        raise SystemExit(f"FAIL: {pack} has no source/attribution file ({', '.join(SOURCE_NAMES)})")
    print(f"OK: license + source metadata present in {pack.relative_to(ROOT)}")


def run(args_list: list[str]) -> None:
    print("  $", " ".join(args_list))
    subprocess.run([sys.executable, *args_list], check=True)


def main() -> None:
    ap = argparse.ArgumentParser(description="Stage an external pack for review.")
    ap.add_argument("--pack", required=True, help="art/external/<source>/<asset> folder")
    ap.add_argument("--sheet", help="spritesheet filename inside the pack (optional)")
    ap.add_argument("--cell", nargs=2, type=int, metavar=("W", "H"))
    ap.add_argument("--slice", action="store_true", help="also slice the sheet into numbered cells")
    args = ap.parse_args()

    pack = _resolve(args.pack)
    if not pack.is_dir():
        raise SystemExit(f"Pack folder not found: {pack}")
    check_metadata(pack)

    source = pack.parent.name
    asset = pack.name
    tools = ROOT / "tools" / "art"

    if args.sheet and args.cell:
        sheet_path = pack / args.sheet
        review_out = ROOT / "art" / "review" / f"{source}_{asset}_contactsheet.png"
        run([str(tools / "make_asset_contact_sheet.py"), "sheet",
             "--sheet", str(sheet_path), "--out", str(review_out),
             "--cell", str(args.cell[0]), str(args.cell[1]), "--skip-empty"])
        if args.slice:
            cells_out = ROOT / "art" / "generated" / "from_external" / source / asset / "cells"
            run([str(tools / "slice_spritesheet.py"),
                 "--sheet", str(sheet_path), "--cell", str(args.cell[0]), str(args.cell[1]),
                 "--out", str(cells_out), "--skip-empty"])
    print("\nStaged for review. Nothing wired. Next: inspect art/review/ + "
          "tools/art/asset_preview.tscn, then normalize chosen cells into "
          "art/generated/from_external/active/<mirror> and list them in "
          "art/active_art_manifest.json.")


if __name__ == "__main__":
    main()
