#!/usr/bin/env python3
"""Catalog LimeZu generator outputs into a LOCAL, gitignored manifest (commit-safe tool).

The LimeZu Farmer Generator and Character Generator 2.0 are GUI installers
(`licensed_assets/limezu/*/original/*Setup.exe`) — they cannot be run headlessly, so this
tool does NOT generate art. It scans whatever the user has exported into
`licensed_assets/limezu/generator_outputs/{player,npcs,portraits,characters}/` and writes
`licensed_assets/limezu/generator_manifests/limezu_generator_manifest.json` so
`GeneratorCharacterRegistry` can resolve sprites/portraits by character id.

Everything it reads/writes lives under gitignored `licensed_assets/limezu/`; only this
script + the template/docs are committed. If no outputs exist yet it writes an empty
manifest skeleton and prints the exact manual steps. See docs/limezu_generator_workflow.md.

    python tools/art/limezu_generator_catalog.py --root licensed_assets/limezu
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT_SUBDIRS = ["player", "npcs", "portraits", "characters"]
PORTRAIT_DIRS = {"portraits"}

try:
    from PIL import Image
    HAVE_PIL = True
except Exception:
    HAVE_PIL = False


def log(msg: str) -> None:
    print(f"[limezu-gen-catalog] {msg}")


def _guess_cell(w: int, h: int) -> int:
    for cell in (48, 32, 16):
        if w % cell == 0 and h % cell == 0:
            return cell
    return 16


def _image_size(path: Path):
    if not HAVE_PIL:
        return None
    try:
        with Image.open(path) as im:
            return im.size
    except Exception:
        return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Catalog LimeZu generator outputs (local only).")
    parser.add_argument("--root", default="licensed_assets/limezu")
    args = parser.parse_args()

    vault = Path(args.root)
    if not vault.is_absolute():
        vault = ROOT / vault
    out_root = vault / "generator_outputs"
    man_dir = vault / "generator_manifests"
    man_dir.mkdir(parents=True, exist_ok=True)
    for sub in OUTPUT_SUBDIRS + ["review"]:
        (out_root / sub).mkdir(parents=True, exist_ok=True)
    # Keep the dirs gitignored even when otherwise empty.
    for d in (out_root, man_dir):
        gi = d / ".gdignore"
        if not gi.exists():
            gi.write_text("Local licensed LimeZu generator data. Do not import or commit.\n", encoding="utf-8")

    characters: dict = {}
    portrait_files: list[Path] = []
    sheet_files: list[Path] = []
    for sub in OUTPUT_SUBDIRS:
        d = out_root / sub
        if not d.is_dir():
            continue
        for png in sorted(d.glob("*.png")):
            rel = png.relative_to(vault).as_posix()
            cid = f"{sub}_{png.stem}".lower().replace(" ", "_")
            size = _image_size(png)
            if sub in PORTRAIT_DIRS:
                portrait_files.append(png)
                w, h = (size or (48, 48))
                characters.setdefault(cid, {})
                characters[cid].update({
                    "display_name": png.stem.replace("_", " ").title(),
                    "kind": "npc",
                    "portrait_sheet": rel,
                    "portrait_rect": [0, 0, min(w, 48), min(h, 48)],
                    "notes": "Portrait auto-cataloged; adjust portrait_rect to taste.",
                })
            else:
                sheet_files.append(png)
                cell = _guess_cell(*size) if size else 16
                characters.setdefault(cid, {})
                characters[cid].update({
                    "display_name": png.stem.replace("_", " ").title(),
                    "kind": "player" if sub == "player" else "npc",
                    "sprite_sheet": rel,
                    "sheet_cell": [cell, cell],
                    "sheet_scale": 2,
                    "idle_frame_rect": [0, 0, cell, cell],
                    "notes": "Auto-cataloged; set walk_frame_rects per the source layout.",
                })

    manifest = {
        "_schema": "hearthvale.limezu_generator_manifest.v1",
        "_comment": "LOCAL gitignored manifest written by tools/art/limezu_generator_catalog.py. Never commit.",
        "provider": "limezu_generators",
        "characters": characters,
    }
    man_path = man_dir / "limezu_generator_manifest.json"
    man_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # Optional contact sheet of portraits/sheets for review (local, gitignored).
    if HAVE_PIL and (portrait_files or sheet_files):
        thumbs = (portrait_files + sheet_files)[:24]
        cols = 6
        cell = 96
        rows = (len(thumbs) + cols - 1) // cols
        sheet = Image.new("RGBA", (cols * cell, max(rows, 1) * cell), (40, 40, 48, 255))
        for i, p in enumerate(thumbs):
            try:
                im = Image.open(p).convert("RGBA")
                im.thumbnail((cell - 8, cell - 8), Image.NEAREST)
                sheet.paste(im, ((i % cols) * cell + 4, (i // cols) * cell + 4), im)
            except Exception:
                pass
        sheet.save(out_root / "review" / "_generator_catalog.png")
        log(f"wrote review contact sheet ({len(thumbs)} thumbs)")

    # Also report ORIGINAL Hearthvale generated assets (procedural, local/gitignored).
    gen_root = out_root / "hearthvale_generated"
    gen_counts: dict = {}
    if gen_root.is_dir():
        for sub in sorted(p for p in gen_root.iterdir() if p.is_dir() and p.name != "review"):
            n = len(list(sub.glob("*.png")))
            if n:
                gen_counts[sub.name] = n
    if gen_counts:
        log(f"original Hearthvale generated assets present: {gen_counts}")

    log(f"cataloged {len(characters)} character entr(y/ies) -> {man_path.relative_to(ROOT)}")
    if not characters:
        log("No generator outputs found. MANUAL STEPS (GUI generators cannot be automated):")
        log("  1. Run the installers (with your approval): " +
            "licensed_assets/limezu/modern_farm/original/'Farmer Generator Setup.exe' and " +
            "licensed_assets/limezu/modern_interiors/original/'Character Generator 2.0 Setup.exe'.")
        log("  2. In each generator, design characters and EXPORT the sprite sheet(s) / portrait(s).")
        log("  3. Drop exported PNGs into licensed_assets/limezu/generator_outputs/"
            "{player,npcs,portraits,characters}/.")
        log("  4. Re-run this tool to (re)build the local manifest; GeneratorCharacterRegistry picks it up.")
    if not HAVE_PIL:
        log("(PIL not installed: skipped the optional review contact sheet — manifest still written.)")


if __name__ == "__main__":
    main()
