#!/usr/bin/env python3
"""Catalog/report LimeZu generator outputs into LOCAL, gitignored manifests (commit-safe tool).

There are FOUR local asset paths, none of which require a vendor installer:
  1. vendor GUI exports (OPTIONAL) — the Farmer/Character Generator .exe are GUI
     installers under `licensed_assets/limezu/*/original/*Setup.exe`; they cannot be
     run headlessly and are NOT required. If used, drop exports into
     `generator_outputs/{player,npcs,portraits,characters}/`.
  2. LimeZu DERIVATIVE generator (`tools/art/limezu_derivative_generator.py`) — creates
     local dev assets from installed LimeZu packs (slice/recolor/outline/icon).
  3. LimeZu-INSPIRED generator (`tools/art/limezu_inspired_generator.py`) — creates NEW
     Hearthvale-original art guided by `limezu_style_analyzer.py`'s style profile.
  4. SIMPLE original fallback (`hearthvale_icon_generator.py` / gap assets) — gap filler
     only, used when no style/source asset is available.

This tool scans all of them and (for GUI exports) writes
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
        log(f"original Hearthvale simple-generated assets present: {gen_counts}")

    # --- report ALL generator paths (GUI is just one optional path) ---------------
    def _manifest_entry_count(name: str) -> int:
        p = man_dir / name
        if not p.exists():
            return 0
        try:
            return len(json.loads(p.read_text(encoding="utf-8")).get("entries", {}))
        except Exception:
            return 0

    def _png_count(rel: str) -> int:
        d = out_root / rel
        return len(list(d.rglob("*.png"))) if d.is_dir() else 0

    deriv_entries = _manifest_entry_count("limezu_derivative_manifest.json")
    inspired_entries = _manifest_entry_count("limezu_inspired_manifest.json")
    log("generator paths (all local + gitignored):")
    log(f"  - vendor GUI exports (OPTIONAL): {len(characters)} char entr(y/ies) "
        "via the Farmer/Character Generator .exe — not required and not automated.")
    log(f"  - LimeZu DERIVATIVE generator: {deriv_entries} manifest entr(y/ies), "
        f"{_png_count('derivatives')} PNG(s) — local dev assets sliced/recolored from installed LimeZu packs "
        "(tools/art/limezu_derivative_generator.py).")
    log(f"  - LimeZu-INSPIRED Hearthvale generator: {inspired_entries} manifest entr(y/ies), "
        f"{_png_count('inspired')} PNG(s) — NEW Hearthvale-original art from LimeZu style analysis "
        "(tools/art/limezu_inspired_generator.py).")
    log(f"  - SIMPLE original fallback: {sum(gen_counts.values())} PNG(s) under hearthvale_generated/ "
        "(tools/art/hearthvale_icon_generator.py / generate_hearthvale_gap_assets.py) — gap filler only.")

    log(f"cataloged {len(characters)} GUI character entr(y/ies) -> {man_path.relative_to(ROOT)}")
    if not characters:
        log("No vendor GUI character exports found — that path is OPTIONAL. To use it: run the "
            "Farmer/Character Generator .exe (with your approval), export sheets/portraits into "
            "generator_outputs/{player,npcs,portraits,characters}/, and re-run this tool.")
    if deriv_entries == 0 and inspired_entries == 0:
        log("No derivative/inspired outputs yet. Generate local dev assets without any GUI installer:")
        log("  python tools/art/limezu_style_analyzer.py --preview")
        log("  python tools/art/limezu_derivative_generator.py --all   # licensed-pixel derivatives")
        log("  python tools/art/limezu_inspired_generator.py --all      # Hearthvale-original, style-guided")
    if not HAVE_PIL:
        log("(PIL not installed: skipped the optional review contact sheet — manifest still written.)")


if __name__ == "__main__":
    main()
