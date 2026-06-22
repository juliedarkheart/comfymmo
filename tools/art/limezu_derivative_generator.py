#!/usr/bin/env python3
"""LimeZu DERIVATIVE generator — makes LOCAL development assets that use licensed
LimeZu source pixels directly (crop, scale, recolor, outline, combine, icon-ify).

ABSOLUTE LOCAL ASSET SAFETY:
  * reads ONLY from licensed_assets/limezu/<pack>/extracted/
  * writes ONLY under licensed_assets/limezu/generator_outputs/derivatives/
  * NEVER deletes/moves/edits/overwrites any source asset
  * --force only overwrites files under the derivatives output root, and FIRST
    makes a timestamped backup of that output folder
All outputs + manifest are local + gitignored. Do NOT commit them.

Usage:
  python tools/art/limezu_derivative_generator.py --dry-run
  python tools/art/limezu_derivative_generator.py --preview
  python tools/art/limezu_derivative_generator.py --all [--force]
"""

from __future__ import annotations

import argparse
import datetime
import json
import shutil
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE_ROOT = ROOT / "licensed_assets/limezu"
DEFAULT_OUTPUT_ROOT = ROOT / "licensed_assets/limezu/generator_outputs/derivatives"
DEFAULT_MANIFEST = ROOT / "licensed_assets/limezu/generator_manifests/limezu_derivative_manifest.json"
SCALE = 2  # LimeZu is 16px, drawn x2 to fill the 32px grid

# id -> recipe. sheet = (pack, [keywords]); cell = source cell px; idx = which
# non-empty cell; op = transform; sub = output subfolder.
RECIPES: dict[str, dict] = {}


def _crop_recipes() -> None:
    crops = [
        ("carrot", 0), ("turnip", 3), ("berry", 6), ("generic_crop", 9),
    ]
    for name, base in crops:
        for stage in (1, 2, 3):
            RECIPES["%s_stage_%d" % (name, stage)] = {
                "sub": "crops", "pack": "modern_farm", "keywords": ["4_crops", "crops"],
                "cell": 16, "idx": base + (stage - 1), "op": "stage", "stage": stage,
            }
    RECIPES["watered_overlay"] = {"sub": "crops", "pack": "modern_farm", "keywords": ["1_terrains", "terrain"], "cell": 16, "idx": 4, "op": "tint", "tint": (90, 150, 210, 120)}
    RECIPES["tilled_soil_variant"] = {"sub": "crops", "pack": "modern_farm", "keywords": ["1_terrains", "terrain"], "cell": 16, "idx": 6, "op": "recolor", "mul": (0.7, 0.55, 0.42)}
    RECIPES["dry_soil_variant"] = {"sub": "crops", "pack": "modern_farm", "keywords": ["1_terrains", "terrain"], "cell": 16, "idx": 6, "op": "recolor", "mul": (1.08, 0.95, 0.78)}


def _prop_recipes() -> None:
    props = ["crate_variant", "storage_chest_variant", "workbench_variant", "sign_variant",
             "fence_variant", "gate_variant", "mailbox_variant", "flower_patch_variant",
             "shrub_variant", "simple_table_variant", "simple_chair_variant", "garden_marker_variant"]
    for i, name in enumerate(props):
        RECIPES[name] = {"sub": "props", "pack": "modern_farm", "keywords": ["3_props", "props", "fences"],
                         "cell": 16, "idx": 4 + i * 3, "op": "outline"}
    terrain = ["path_tile_variant", "dirt_path_variant", "stone_path_variant"]
    for i, name in enumerate(terrain):
        RECIPES[name] = {"sub": "terrain", "pack": "modern_exteriors", "keywords": ["path", "terrain", "tileset"],
                         "cell": 16, "idx": 2 + i * 2, "op": "crop"}


def _ui_recipes() -> None:
    ui = [("panel_variant_dark", "recolor", (0.55, 0.55, 0.65)), ("panel_variant_light", "recolor", (1.15, 1.12, 1.0)),
          ("button_variant", "crop", None), ("button_hover_variant", "recolor", (1.12, 1.1, 0.92)),
          ("slot_variant", "crop", None), ("slot_selected_variant", "recolor", (1.1, 1.05, 0.7)),
          ("close_button_variant", "crop", None), ("tab_variant", "crop", None), ("item_badge_variant", "crop", None)]
    for i, (name, op, mul) in enumerate(ui):
        RECIPES[name] = {"sub": "ui", "pack": "modern_ui", "keywords": ["style_1", "modern_ui", "ui"],
                         "cell": 16, "idx": 1 + i * 2, "op": op, "mul": mul}


def _icon_recipes() -> None:
    icons = ["carrot_seed_packet", "turnip_seed_packet", "berry_seed_packet",
             "carrot_crop_icon", "turnip_crop_icon", "berry_crop_icon",
             "wood_icon", "stone_icon", "clay_icon", "fiber_icon",
             "hoe_icon", "axe_icon", "shovel_icon", "pickaxe_icon", "watering_can_icon",
             "crate_icon", "fence_icon", "sign_icon", "mailbox_icon", "workbench_icon"]
    for i, name in enumerate(icons):
        kw = ["7_pickup", "pickup", "items"] if "icon" in name and "seed" not in name else ["7_pickup", "pickup", "items", "tools"]
        RECIPES[name] = {"sub": "icons", "pack": "modern_farm", "keywords": kw, "cell": 16, "idx": 1 + i, "op": "icon"}


def _wearable_recipes() -> None:
    wear = ["farmer_outfit_icon", "shopkeeper_outfit_icon", "basic_hair_icon", "hat_icon",
            "accessory_icon", "player_palette_variant_preview", "villager_palette_variant_preview"]
    for i, name in enumerate(wear):
        RECIPES[name] = {"sub": "wearables", "pack": "modern_farm", "keywords": ["characters", "character"],
                         "cell": 16, "idx": 2 + i * 4, "op": "icon"}


def _build_recipes() -> None:
    _crop_recipes(); _prop_recipes(); _ui_recipes(); _icon_recipes(); _wearable_recipes()


PREVIEW_IDS = ["carrot_stage_1", "carrot_stage_2", "carrot_stage_3", "tilled_soil_variant",
               "crate_variant", "fence_variant", "panel_variant_dark", "button_variant",
               "carrot_seed_packet", "hoe_icon"]


# --- source helpers ---------------------------------------------------------
def find_sheet(source_root: Path, pack: str, keywords: list[str]) -> Path | None:
    pack_dir = source_root / pack / "extracted"
    if not pack_dir.is_dir():
        return None
    cap = 0
    candidates: list[Path] = []
    for path in sorted(pack_dir.rglob("*.png")):
        cap += 1
        if cap > 8000:
            break
        low = path.name.lower()
        if any(k in low for k in keywords):
            candidates.append(path)
    if not candidates:
        # fall back to the first reasonably large 16x16 sheet
        for path in sorted(pack_dir.rglob("*16x16*.png")):
            candidates.append(path)
            break
    candidates.sort(key=lambda p: (0 if p.name[:1].isdigit() else 1, len(p.name)))
    return candidates[0] if candidates else None


def nonempty_cells(img: Image.Image, cell: int) -> list[tuple[int, int]]:
    cols, rows = max(1, img.width // cell), max(1, img.height // cell)
    out = []
    for ry in range(rows):
        for cx in range(cols):
            tile = img.crop((cx * cell, ry * cell, cx * cell + cell, ry * cell + cell))
            if tile.getchannel("A").getbbox() is not None:
                out.append((cx, ry))
    return out


def _trim(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    return img.crop(bbox) if bbox else img


def _scale_nn(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def _recolor(img: Image.Image, mul) -> Image.Image:
    out = img.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (min(255, int(r * mul[0])), min(255, int(g * mul[1])), min(255, int(b * mul[2])), a)
    return out


def _tint(img: Image.Image, rgba) -> Image.Image:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    op = overlay.load(); sp = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if sp[x, y][3] > 0:
                op[x, y] = rgba
    return Image.alpha_composite(img, overlay)


def _outline(img: Image.Image, color=(20, 18, 24, 255)) -> Image.Image:
    w, h = img.size
    out = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    out.alpha_composite(img, (1, 1))
    src = img.load(); dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] > 60:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ox, oy = x + 1 + dx, y + 1 + dy
                    if 0 <= ox < w + 2 and 0 <= oy < h + 2 and dst[ox, oy][3] == 0:
                        dst[ox, oy] = color
    return out


def _icon_canvas(sprite: Image.Image, size: int = 32) -> Image.Image:
    sprite = _trim(sprite)
    scale = min(size / max(1, sprite.width), size / max(1, sprite.height), 3.0)
    sprite = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(sprite, ((size - sprite.width) // 2, (size - sprite.height) // 2))
    return canvas


def build_one(source_root: Path, asset_id: str, recipe: dict) -> tuple[Image.Image, dict] | None:
    sheet = find_sheet(source_root, recipe["pack"], recipe["keywords"])
    if sheet is None:
        return None
    try:
        img = Image.open(sheet).convert("RGBA")
    except Exception:
        return None
    cell = recipe.get("cell", 16)
    cells = nonempty_cells(img, cell)
    if not cells:
        return None
    cx, ry = cells[recipe.get("idx", 0) % len(cells)]
    rect = (cx * cell, ry * cell, cx * cell + cell, ry * cell + cell)
    tile = img.crop(rect)
    op = recipe.get("op", "crop")
    if op == "stage":
        tile = _recolor(tile, (1.0, 1.0, 1.0))  # real pixels; stage variety via idx
        result = _scale_nn(tile, SCALE)
    elif op == "tint":
        result = _scale_nn(_tint(tile, recipe["tint"]), SCALE)
    elif op == "recolor":
        result = _scale_nn(_recolor(tile, recipe.get("mul") or (1.0, 1.0, 1.0)), SCALE)
    elif op == "outline":
        result = _scale_nn(_outline(tile), SCALE)
    elif op == "icon":
        result = _icon_canvas(tile, 32)
    else:  # crop
        result = _scale_nn(tile, SCALE)
    meta = {
        "id": asset_id, "category": recipe["sub"], "source_type": "licensed_limezu_derivative",
        "source_pack": recipe["pack"], "source_path": sheet.relative_to(source_root.parent.parent).as_posix(),
        "source_rect": list(rect), "operations": [op] + (["scale_nn:%dx" % SCALE] if op not in ("icon",) else ["icon_fit"]),
        "dimensions": list(result.size), "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "generator": "tools/art/limezu_derivative_generator.py", "commit_policy": "local_gitignored_output",
        "runtime_candidate": recipe["sub"] in ("crops", "props", "terrain", "ui", "icons"),
        "notes": "Local derivative from licensed LimeZu pixels; gitignored; review before any reuse.",
    }
    return result, meta


def _backup_outputs(output_root: Path) -> Path | None:
    if not output_root.exists() or not any(output_root.rglob("*.png")):
        return None
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = output_root.parent / ("_backup_derivatives_%s" % stamp)
    shutil.copytree(output_root, backup)
    return backup


def main() -> None:
    _build_recipes()
    ap = argparse.ArgumentParser(description="Generate LOCAL LimeZu derivative assets (gitignored).")
    ap.add_argument("--preview", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--source-root", default=str(DEFAULT_SOURCE_ROOT))
    ap.add_argument("--output-root", default=str(DEFAULT_OUTPUT_ROOT))
    ap.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    args = ap.parse_args()

    source_root = Path(args.source_root)
    if not (source_root / "modern_farm" / "extracted").is_dir():
        raise SystemExit("[derivative] STOP: modern_farm/extracted missing under %s — not repairing." % source_root)

    ids = PREVIEW_IDS if args.preview and not args.all else list(RECIPES.keys())
    output_root = Path(args.output_root)

    if args.dry_run:
        print("[derivative] dry-run: %d planned output(s) under %s" % (len(ids), output_root))
        for asset_id in ids[:12]:
            print("  - %s/%s.png" % (RECIPES[asset_id]["sub"], asset_id))
        if len(ids) > 12:
            print("  ... +%d more" % (len(ids) - 12))
        return

    if args.force:
        backup = _backup_outputs(output_root)
        if backup:
            print("[derivative] backed up existing outputs -> %s" % backup)

    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / ".gdignore").write_text("Local licensed derivative outputs. Do not import.\n", encoding="utf-8")
    manifest: dict = {"schema": "limezu_derivative_manifest/v1", "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
                      "generator": "tools/art/limezu_derivative_generator.py", "commit_policy": "local_gitignored_output", "entries": {}}
    written = skipped = failed = 0
    for asset_id in ids:
        recipe = RECIPES[asset_id]
        dest = output_root / recipe["sub"] / ("%s.png" % asset_id)
        if dest.exists() and not args.force:
            skipped += 1
            continue
        built = build_one(source_root, asset_id, recipe)
        if built is None:
            failed += 1
            continue
        image, meta = built
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest)
        meta["output_path"] = dest.relative_to(source_root.parent.parent).as_posix()
        manifest["entries"][asset_id] = meta
        written += 1

    Path(args.manifest).parent.mkdir(parents=True, exist_ok=True)
    if Path(args.manifest).exists() and not args.force:
        try:
            prev = json.loads(Path(args.manifest).read_text(encoding="utf-8")).get("entries", {})
            for k, v in prev.items():
                manifest["entries"].setdefault(k, v)
        except Exception:
            pass
    Path(args.manifest).write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print("[derivative] wrote=%d skipped=%d failed=%d -> %s" % (written, skipped, failed, output_root))
    print("[derivative] manifest (%d entries) -> %s" % (len(manifest["entries"]), args.manifest))


if __name__ == "__main__":
    main()
