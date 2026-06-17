#!/usr/bin/env python3
"""Extract, catalog, and stage LimeZu (Modern Farm/UI/Exteriors/Interiors/Office,
Fungus Cave, RPG-Arsenal) packs for the Hearthvale LimeZu visual spike.

LOCAL ONLY. This script is COMMIT-SAFE (code only). It reads the gitignored vault
under licensed_assets/limezu/ and writes derivatives, contact sheets, manifests, and
normalized candidates ONLY back under that same gitignored vault. It NEVER writes
licensed media into art/, scenes/, or any tracked path, and NEVER commits anything.

Per-pack layout (each is gitignored):
    licensed_assets/limezu/<pack>/original/        purchased zips + .exe generators
    licensed_assets/limezu/<pack>/extracted/       unzipped pack (NOT imported by Godot)
    licensed_assets/limezu/<pack>/normalized/       reviewed single-asset derivatives
    licensed_assets/limezu/<pack>/modified/         locally edited derivatives
    licensed_assets/limezu/<pack>/contact_sheets/   review images (NOT imported)
    licensed_assets/limezu/<pack>/manifests/        inventory/candidate JSON (NOT imported)
    licensed_assets/limezu/limezu_active_manifest.json   provider activation (logical id -> file)

A `.gdignore` is written into original/, extracted/, contact_sheets/, and manifests/
so Godot does NOT try to import the thousands of raw licensed PNGs. normalized/ and
modified/ stay importable so the spike can load reviewed derivatives via res://.

Usage:
    python tools/art/limezu_integrate.py --root licensed_assets/limezu --extract
    python tools/art/limezu_integrate.py --root licensed_assets/limezu --inventory
    python tools/art/limezu_integrate.py --root licensed_assets/limezu --contact-sheets
    python tools/art/limezu_integrate.py --root licensed_assets/limezu --normalize-candidates
    python tools/art/limezu_integrate.py --root licensed_assets/limezu --all
    (optional: --pack modern_farm  --force)
"""

from __future__ import annotations

import argparse
import datetime
import json
import zipfile
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    Image = None  # contact sheets / normalize need Pillow; extract/inventory do not

ROOT = Path(__file__).resolve().parents[2]

PACK_SUBDIRS = ("original", "extracted", "normalized", "modified", "contact_sheets", "manifests")
# Dirs Godot must skip importing (raw licensed media / review files). normalized +
# modified stay importable so the spike can load reviewed derivatives.
GDIGNORE_SUBDIRS = ("original", "extracted", "contact_sheets", "manifests")

IMAGE_EXTS = {".png", ".gif", ".jpg", ".jpeg", ".bmp"}
AUDIO_EXTS = {".wav", ".ogg", ".mp3"}
DATA_EXTS = {".json", ".txt", ".md", ".csv"}
SOURCE_EXTS = {".aseprite", ".ase", ".psd"}

# First matching group (checked top-down) wins the category for a relative path.
CATEGORY_KEYWORDS = [
    ("ui", ("/ui", "interface", "userinterface", "dialog", "dialogue", "menu", "hud",
            "inventory", "questbox", "quest box", "panel", "button", "slot", "cursor", "frame")),
    ("icons", ("icon", "/emote", "emoji", "/items/", "item_", "reward")),
    ("autotiles", ("autotile", "auto_tile", "auto tile")),
    ("crops", ("crop", "harvest", "/seeds", "seed", "/plant", "farming")),
    ("animals", ("animal", "chicken", "/cow", "/dog", "/cat", "horse", "sheep", "/pig", "duck", "livestock")),
    ("characters", ("character", "charakter", "/player", "battler", "/npc", "humanoid")),
    ("weapons", ("weapon", "arsenal", "/sword", "/axe", "/shield", "/bow", "potion", "spell")),
    ("interiors", ("interior", "furniture", "/room", "kitchen", "/bed", "/bath", "/sofa", "/table", "/chair")),
    ("office", ("office", "/desk", "computer", "printer", "cubicle", "workstation")),
    ("cave", ("cave", "fungus", "mushroom", "dungeon", "cavern")),
    ("buildings", ("building", "/house", "exterior", "/roof", "/wall", "/door", "/fence",
                   "/shed", "/barn", "/cottage", "rooftop")),
    ("terrain", ("tileset", "/tile", "ground", "grass", "/floor", "terrain", "/path",
                 "water", "soil", "dirt", "/road")),
    ("objects", ("object", "/prop", "/decor", "/chest", "/sign", "mailbox", "workbench",
                 "/well", "barrel", "crate", "lamp", "bench")),
    ("animation", ("animation", "/anim", "_anim", "frames", "spritesheet", "sprite_sheet")),
]

# Logical ids the spike + provider care about; normalize/candidates search for these
# by keyword so a human can review which source file fits each.
LOGICAL_ID_KEYWORDS = {
    "terrain.grass": ("grass", "ground"),
    "terrain.dirt_path": ("path", "dirt"),
    "terrain.tilled_soil": ("soil", "farmland", "tilled", "plow"),
    "terrain.water": ("water",),
    "object.house": ("house", "cottage", "home"),
    "object.barn": ("barn",),
    "object.fence": ("fence",),
    "object.tree": ("tree",),
    "object.crop_carrot": ("carrot",),
    "object.crop_wheat": ("wheat",),
    "object.chest": ("chest",),
    "object.mailbox": ("mailbox",),
    "object.workbench": ("workbench", "table"),
    "animal.chicken": ("chicken", "chick"),
    "animal.cow": ("cow",),
    "animal.dog": ("dog",),
    "character.player_idle": ("player", "idle", "character"),
    "ui.panel": ("panel", "dialog", "box"),
    "ui.button": ("button",),
    "ui.slot": ("slot", "inventory"),
    "ui.dialogue_box": ("dialog", "dialogue", "speech"),
    "ui.quest_box": ("quest",),
    "ui.close": ("close", "/x", "cross"),
    "icon.seed": ("seed",),
    "icon.carrot": ("carrot",),
    "icon.wood": ("wood", "log"),
    "icon.stone": ("stone", "rock"),
    "icon.tool_hoe": ("hoe",),
    "icon.tool_axe": ("axe",),
    "cave.floor": ("floor", "ground"),
    "cave.wall": ("wall",),
    "cave.fungus_creature": ("fungus", "mushroom", "creature", "monster"),
}

# Bounded contact-sheet settings so huge packs (Modern Exteriors ~233MB) stay safe.
CONTACT_THUMB = 56
CONTACT_MAX_CELLS = 64
CONTACT_COLS = 8
CONTACT_MAX_PIXELS = 12_000_000   # skip thumbnailing sheets bigger than this
CONTACT_MAX_BYTES = 16 * 1024 * 1024
SAMPLE_CAP = 60                    # capped sample paths stored per category in inventory


def log(msg: str) -> None:
    print(f"[limezu] {msg}")


def _write_gdignore(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    (path / ".gdignore").write_text(
        "Local licensed LimeZu review/original assets. Do not import into Godot.\n",
        encoding="utf-8",
    )


def discover_packs(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return sorted(p for p in root.iterdir() if p.is_dir() and not p.name.startswith("."))


def ensure_pack_dirs(pack: Path) -> None:
    for sub in PACK_SUBDIRS:
        (pack / sub).mkdir(parents=True, exist_ok=True)
    for sub in GDIGNORE_SUBDIRS:
        _write_gdignore(pack / sub)


def category_for(rel_path: str) -> str:
    low = rel_path.replace("\\", "/").lower()
    for name, keys in CATEGORY_KEYWORDS:
        if any(k in low for k in keys):
            return name
    return "other"


def _safe_extract(zf: zipfile.ZipFile, dest: Path) -> int:
    count = 0
    dest_resolved = dest.resolve()
    for member in zf.infolist():
        if member.is_dir():
            continue
        target = (dest / member.filename).resolve()
        if not str(target).startswith(str(dest_resolved)):
            log(f"  ! skipping unsafe path in zip: {member.filename}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(member) as src, open(target, "wb") as out:
            out.write(src.read())
        count += 1
    return count


def extract_pack(pack: Path, force: bool) -> dict:
    original = pack / "original"
    extracted = pack / "extracted"
    state_path = pack / "manifests" / "extract_state.json"
    state = {}
    if state_path.exists():
        try:
            state = json.loads(state_path.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            state = {}
    zips = sorted(original.glob("*.zip")) if original.is_dir() else []
    result = {"zips": [z.name for z in zips], "extracted": [], "skipped": [], "failed": []}
    if not zips:
        log(f"{pack.name}: no .zip in original/ (nothing to extract)")
        return result
    for z in zips:
        stat = z.stat()
        sig = f"{stat.st_size}:{int(stat.st_mtime)}"
        dest = extracted / z.stem
        if not force and state.get(z.name) == sig and dest.is_dir():
            result["skipped"].append(z.name)
            log(f"{pack.name}: up-to-date, skipping {z.name} (use --force to re-extract)")
            continue
        try:
            with zipfile.ZipFile(z) as zf:
                n = _safe_extract(zf, dest)
            state[z.name] = sig
            result["extracted"].append({"zip": z.name, "files": n})
            log(f"{pack.name}: extracted {z.name} -> {n} files")
        except (zipfile.BadZipFile, OSError) as exc:
            result["failed"].append({"zip": z.name, "error": str(exc)})
            log(f"{pack.name}: FAILED to extract {z.name}: {exc}")
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")
    return result


def inventory_pack(pack: Path) -> dict:
    extracted = pack / "extracted"
    by_ext: dict[str, int] = {}
    by_category: dict[str, int] = {}
    samples: dict[str, list[str]] = {}
    image_paths: dict[str, list[str]] = {}
    total = 0
    if extracted.is_dir():
        for f in extracted.rglob("*"):
            if not f.is_file() or f.name == ".gdignore":
                continue
            total += 1
            ext = f.suffix.lower()
            by_ext[ext] = by_ext.get(ext, 0) + 1
            rel = f.relative_to(extracted).as_posix()
            cat = category_for(rel)
            by_category[cat] = by_category.get(cat, 0) + 1
            if len(samples.setdefault(cat, [])) < SAMPLE_CAP:
                samples[cat].append(rel)
            if ext in IMAGE_EXTS:
                image_paths.setdefault(cat, [])
                if len(image_paths[cat]) < CONTACT_MAX_CELLS:
                    image_paths[cat].append(rel)
    inv = {
        "pack": pack.name,
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "total_files": total,
        "by_ext": dict(sorted(by_ext.items(), key=lambda kv: -kv[1])),
        "by_category": dict(sorted(by_category.items(), key=lambda kv: -kv[1])),
        "samples": samples,
        "_image_paths_for_contact": image_paths,
    }
    out = pack / "manifests" / "inventory.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(inv, indent=2), encoding="utf-8")
    log(f"{pack.name}: inventory -> {total} files, categories={list(inv['by_category'])}")
    return inv


def _load_inventory(pack: Path) -> dict:
    p = pack / "manifests" / "inventory.json"
    if p.exists():
        try:
            return json.loads(p.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            return {}
    return {}


def contact_sheets_pack(pack: Path) -> list[str]:
    if Image is None:
        log(f"{pack.name}: Pillow not available, skipping contact sheets")
        return []
    inv = _load_inventory(pack) or inventory_pack(pack)
    extracted = pack / "extracted"
    out_dir = pack / "contact_sheets"
    out_dir.mkdir(parents=True, exist_ok=True)
    _write_gdignore(out_dir)
    written = []
    for cat, rels in (inv.get("_image_paths_for_contact") or {}).items():
        thumbs = []
        for rel in rels[:CONTACT_MAX_CELLS]:
            src = extracted / rel
            try:
                if not src.is_file() or src.stat().st_size > CONTACT_MAX_BYTES:
                    continue
                img = Image.open(src)
                if (img.width * img.height) > CONTACT_MAX_PIXELS:
                    continue
                img = img.convert("RGBA")
                img.thumbnail((CONTACT_THUMB, CONTACT_THUMB), Image.NEAREST)
                thumbs.append(img)
            except (OSError, ValueError):
                continue
        if not thumbs:
            continue
        cols = CONTACT_COLS
        rows = (len(thumbs) + cols - 1) // cols
        cell = CONTACT_THUMB + 4
        sheet = Image.new("RGBA", (cols * cell, rows * cell), (24, 22, 20, 255))
        for i, th in enumerate(thumbs):
            cx = (i % cols) * cell + (cell - th.width) // 2
            cy = (i // cols) * cell + (cell - th.height) // 2
            sheet.alpha_composite(th, (cx, cy))
        path = out_dir / f"{cat}.png"
        sheet.save(path)
        written.append(path.name)
    log(f"{pack.name}: contact sheets -> {written}")
    return written


def normalize_candidates_pack(pack: Path) -> dict:
    """Record candidate source files per logical id (for human review). Does NOT
    auto-copy uncertain art; a reviewer maps confident ones into the active manifest.
    """
    inv = _load_inventory(pack) or inventory_pack(pack)
    extracted = pack / "extracted"
    candidates: dict[str, list[str]] = {}
    all_images: list[str] = []
    for rels in (inv.get("samples") or {}).values():
        all_images.extend(r for r in rels if Path(r).suffix.lower() in IMAGE_EXTS)
    for logical_id, keys in LOGICAL_ID_KEYWORDS.items():
        hits = []
        for rel in all_images:
            low = rel.lower()
            if any(k in low for k in keys):
                hits.append(rel)
            if len(hits) >= 6:
                break
        if hits:
            candidates[logical_id] = hits
    out = pack / "manifests" / "candidates.json"
    out.write_text(json.dumps({
        "pack": pack.name,
        "_comment": "Candidate source files per logical id (keyword match). Review the "
                    "contact sheets, then map confident picks into "
                    "licensed_assets/limezu/limezu_active_manifest.json (rel to "
                    "licensed_assets/limezu/). Nothing here is committed.",
        "candidates": candidates,
    }, indent=2), encoding="utf-8")
    log(f"{pack.name}: candidates -> {len(candidates)} logical ids with matches")
    return candidates


def ensure_active_manifest(root: Path) -> None:
    """Create an EMPTY local activation manifest if absent. A reviewer fills `active`
    with logical-id -> file mappings (rel to licensed_assets/limezu/). Gitignored."""
    path = root / "limezu_active_manifest.json"
    if path.exists():
        return
    path.write_text(json.dumps({
        "_comment": "LOCAL gitignored LimeZu activation manifest. Keys are logical ids "
                    "(see tools/art/templates/limezu_manifest_template.json). Values are "
                    "paths rel to licensed_assets/limezu/ (or full res://). Read by "
                    "systems/art/limezu_art_registry.gd. Never commit this file or the "
                    "assets it points at.",
        "provider": "limezu",
        "active": {},
    }, indent=2), encoding="utf-8")
    log(f"created empty active manifest: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract + catalog LimeZu packs (local only).")
    parser.add_argument("--root", default="licensed_assets/limezu",
                        help="Vault root (rel to repo or absolute).")
    parser.add_argument("--pack", default="", help="Limit to a single pack folder name.")
    parser.add_argument("--extract", action="store_true")
    parser.add_argument("--inventory", action="store_true")
    parser.add_argument("--contact-sheets", action="store_true")
    parser.add_argument("--normalize-candidates", action="store_true")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--force", action="store_true", help="Re-extract even if unchanged.")
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_absolute():
        root = ROOT / root
    if not root.is_dir():
        log(f"vault root not found: {root} (nothing to do — clean checkout is fine)")
        return

    do_extract = args.extract or args.all
    do_inventory = args.inventory or args.all
    do_contact = args.contact_sheets or args.all
    do_normalize = args.normalize_candidates or args.all
    if not any((do_extract, do_inventory, do_contact, do_normalize)):
        log("no action flag given; use --extract/--inventory/--contact-sheets/"
            "--normalize-candidates/--all")
        return

    packs = discover_packs(root)
    if args.pack:
        packs = [p for p in packs if p.name == args.pack]
    if not packs:
        log(f"no pack folders under {root}")
        return
    log(f"packs: {[p.name for p in packs]}")

    ensure_active_manifest(root)
    summary = {}
    for pack in packs:
        ensure_pack_dirs(pack)
        entry = {}
        if do_extract:
            entry["extract"] = extract_pack(pack, args.force)
        if do_inventory:
            inv = inventory_pack(pack)
            entry["inventory"] = {"total": inv["total_files"], "categories": inv["by_category"]}
        if do_contact:
            entry["contact_sheets"] = contact_sheets_pack(pack)
        if do_normalize:
            entry["candidates"] = list(normalize_candidates_pack(pack).keys())
        summary[pack.name] = entry
    log("done. summary:")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
