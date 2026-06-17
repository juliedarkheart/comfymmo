#!/usr/bin/env python3
"""Slice/copy a CURATED set of real LimeZu assets for the visual spike.

LOCAL ONLY + COMMIT-SAFE (code only). Reads the gitignored extracted LimeZu packs and
writes a small reviewed set of normalized PNGs to
`licensed_assets/limezu/<pack>/normalized/spike/`, then updates the local
`licensed_assets/limezu/limezu_active_manifest.json` so LimeZuArtRegistry resolves the
spike's logical ids to real art. It does NOT normalize the whole library — only enough
for one good Modern Farm / Modern UI homestead screenshot.

Asset selection was reviewed from the extracted folder/file names + dimensions:
- Single-file complete assets are copied as-is (trees, crops, fences, soil, signs,
  crates, barn, flower tufts, icons).
- Animal/character sheets are sliced to their first frame (configured cell size) and
  trimmed to the alpha bbox.
- Plain fill tiles (grass/water) are picked from `1_Terrains_16x16.png` by scanning
  for the most uniform, fully-opaque cell nearest a target colour. The live dirt path
  uses a reviewed transparent Modern Exteriors dirt patch instead of a full opaque
  cell, so it does not read as a flat rectangular slab.
- Modern UI: `--analyze-ui` prints alpha-gap element boxes from a Style sheet and
  writes a gridded review sheet, so UI cells can be chosen deliberately (panel/slot
  slicing stays a documented manual step rather than a blind guess).

Usage:
    python tools/art/limezu_slice_spike_assets.py --root licensed_assets/limezu --all
    python tools/art/limezu_slice_spike_assets.py --root licensed_assets/limezu --analyze-ui
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

# Pack extracted roots (relative to the vault root).
FARM = "modern_farm/extracted/Modern_Farm_v1.2"
UI = "modern_ui/extracted/modernuserinterface-win"
EXTERIORS = "modern_exteriors/extracted/modernexteriors-win/Modern_Exteriors_16x16"
SINGLES = f"{FARM}/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16"
FARM_PROPS = f"{FARM}/16x16/Single_Files_16x16/Props_and_Buildings_16x16"
ICONS = f"{FARM}/Icons/Icons_16x16/Icons_16x16_Singles"
ANIMALS = f"{FARM}/16x16/Animals_16x16"
CHARS = f"{FARM}/16x16/Characters_16x16"
UI_STYLE_SHEET = f"{UI}/16x16/Modern_UI_Style_1.png"
EXTERIOR_TERRAIN_SINGLES = f"{EXTERIORS}/ME_Theme_Sorter_16x16/1_Terrains_and_Fences_Singles_16x16"

# --- Curated spike asset table ----------------------------------------------
# op "copy": copy a complete single-file asset as-is.
# op "slice": crop the first frame (x,y,w,h) from a sheet, then trim to alpha bbox.
# op "terrain": pick the most uniform opaque cell near target_rgb from a tilesheet.
# Each entry: (logical_id, pack, op, source_rel, extra)
SPIKE_ASSETS = [
    # Terrain. Grass/water are clean fills; dirt path is a reviewed transparent patch
    # so the opening does not draw a flat rectangular road.
    ("terrain.grass", "modern_farm", "terrain", f"{FARM}/16x16/1_Terrains_16x16.png", (16, "grass")),
    ("terrain.dirt_path", "modern_exteriors", "copy", f"{EXTERIOR_TERRAIN_SINGLES}/ME_Singles_Terrains_and_Fences_16x16_Props_Dirt_18.png", None),
    ("terrain.water", "modern_farm", "terrain", f"{FARM}/16x16/1_Terrains_16x16.png", (16, "water")),
    ("terrain.tilled_soil", "modern_farm", "copy", f"{SINGLES}/Soil_Wet_1_16x16.png", None),
    # Buildings / objects
    ("object.barn", "modern_farm", "copy", f"{SINGLES}/Barn_Small_16x16.png", None),
    ("object.tree", "modern_farm", "copy", f"{SINGLES}/Fruit_Tree_Apple_Ripe_16x16.png", None),
    ("object.tree_small", "modern_farm", "copy", f"{SINGLES}/Fruit_Tree_Small_Apple_16x16.png", None),
    ("object.fence_horizontal", "modern_farm", "copy", f"{SINGLES}/Wooden_Fence_Type_1_Brown_1_16x16.png", None),
    ("object.fence_vertical", "modern_farm", "copy", f"{SINGLES}/Wooden_Fence_Type_1_Brown_3_16x16.png", None),
    ("object.fence_post", "modern_farm", "copy", f"{SINGLES}/Wooden_Fence_Type_1_Brown_5_16x16.png", None),
    ("object.flower", "modern_farm", "copy", f"{SINGLES}/Grass_Tufts_Flowers_16x16_1.png", None),
    ("object.flower2", "modern_farm", "copy", f"{SINGLES}/Grass_Tufts_Flowers_16x16_5.png", None),
    ("object.flower3", "modern_farm", "copy", f"{SINGLES}/Grass_Tufts_Flowers_16x16_9.png", None),
    ("object.crate", "modern_farm", "copy", f"{SINGLES}/Crate_Brown_Apples_16x16.png", None),
    ("object.sign", "modern_farm", "copy", f"{FARM_PROPS}/Sign_1_16x16.png", None),
    # Crops (field)
    ("crop.carrot", "modern_farm", "copy", f"{SINGLES}/Crop_Carrot_Ripe_1_16x16.png", None),
    ("crop.carrot_stage1", "modern_farm", "copy", f"{SINGLES}/Crop_Carrot_Stage_1_16x16.png", None),
    ("crop.cauliflower", "modern_farm", "copy", f"{SINGLES}/Crop_Cauliflower_Ripe_16x16.png", None),
    ("crop.watermelon", "modern_farm", "copy", f"{SINGLES}/Crop_Watermelon_Ripe_16x16.png", None),
    # Icons (single 16x16)
    ("icon.carrot", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Crops_ Carrot.png", None),
    ("icon.seed", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Seed_Bags_Carrot.png", None),
    ("icon.wood", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Resources_Trunk_1.png", None),
    ("icon.tool_axe", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Tools_Axe.png", None),
    ("icon.tool_watering_can", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Tools_Watering_Can.png", None),
    ("icon.tool_shovel", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Tools_Shovel.png", None),
    ("icon.egg", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Food_Egg.png", None),
    ("icon.cheese", "modern_farm", "copy", f"{ICONS}/Icons_16x16_Food_Cheese.png", None),
    # Animals / character (slice first frame, then trim)
    ("animal.chicken", "modern_farm", "slice", f"{ANIMALS}/Chickens_and_Roosters/Chicken_Brown_16x16.png", (0, 0, 16, 16)),
    # Cow frames are 48x48 (4 rows of 48px; 32x32 cut the head off). Frame 0 is a
    # side-facing cow; trim only removes transparent margin, never the head.
    ("animal.cow", "modern_farm", "slice", f"{ANIMALS}/Cows/Cow_16x16.png", (0, 0, 48, 48)),
    ("character.farmer_idle", "modern_farm", "slice_first", f"{CHARS}/Farmer_1_16x16.png", (16, 32)),
    # Modern UI 9-patch frames (raw crop, NEVER alpha-trimmed — trimming breaks the
    # nine-patch border). Rects were chosen by reviewing Modern_UI_Style_1.png cells
    # (see licensed_assets/limezu/modern_ui/contact_sheets/_ui_candidates.png).
    ("ui.panel", "modern_ui", "rawcrop", UI_STYLE_SHEET, (1, 8, 47, 31)),
    ("ui.inventory_panel", "modern_ui", "rawcrop", UI_STYLE_SHEET, (1, 8, 47, 31)),
    ("ui.slot", "modern_ui", "rawcrop", UI_STYLE_SHEET, (1, 300, 47, 24)),
    ("ui.slot_selected", "modern_ui", "rawcrop", UI_STYLE_SHEET, (51, 129, 58, 29)),
    # Reviewed from contact_sheets/_ui_candidates.png:
    # 32/33 are neutral small button strips; 31 is a red close/danger strip;
    # 34 is a compact tab frame. These stay local/gitignored like all LimeZu art.
    ("ui.button", "modern_ui", "rawcrop", UI_STYLE_SHEET, (238, 466, 29, 11)),
    ("ui.button_hover", "modern_ui", "rawcrop", UI_STYLE_SHEET, (238, 482, 29, 11)),
    ("ui.close", "modern_ui", "rawcrop", UI_STYLE_SHEET, (238, 450, 29, 11)),
    ("ui.close_hover", "modern_ui", "rawcrop", UI_STYLE_SHEET, (238, 482, 29, 11)),
    ("ui.tab", "modern_ui", "rawcrop", UI_STYLE_SHEET, (268, 386, 34, 13)),
]


def log(msg: str) -> None:
    print(f"[limezu-slice] {msg}")


def _spike_dir(vault: Path, pack: str) -> Path:
    d = vault / pack / "normalized" / "spike"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _safe_name(logical_id: str) -> str:
    return logical_id.replace(".", "_") + ".png"


def _trim(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    return img.crop(bbox) if bbox else img


def do_copy(src: Path, dst: Path) -> bool:
    if not src.is_file():
        return False
    img = Image.open(src).convert("RGBA")
    img.save(dst)
    return True


def do_slice(src: Path, dst: Path, box) -> bool:
    if not src.is_file():
        return False
    img = Image.open(src).convert("RGBA")
    x, y, w, h = box
    if x + w > img.width or y + h > img.height:
        return False
    frame = _trim(img.crop((x, y, x + w, y + h)))
    if frame.width == 0 or frame.height == 0:
        return False
    frame.save(dst)
    return True


def do_rawcrop(src: Path, dst: Path, box) -> bool:
    """Crop an exact rect WITHOUT trimming — for UI nine-patch frames where trimming
    would destroy the border/patch margins."""
    if not src.is_file():
        return False
    img = Image.open(src).convert("RGBA")
    x, y, w, h = box
    if x + w > img.width or y + h > img.height:
        return False
    img.crop((x, y, x + w, y + h)).save(dst)
    return True


def do_slice_first(src: Path, dst: Path, cell) -> bool:
    """Find the first row-major cell (cw x ch) whose opacity looks like a single
    character/object frame (not blank, not a fully-packed block), then trim + save.
    Used for big animation atlases where frame (0,0) may be empty/padding."""
    if not src.is_file():
        return False
    img = Image.open(src).convert("RGBA")
    cw, ch = cell
    apx = img.getchannel("A").load()
    for gy in range(0, img.height - ch + 1, ch):
        for gx in range(0, img.width - cw + 1, cw):
            opaque = 0
            for y in range(gy, gy + ch):
                for x in range(gx, gx + cw):
                    if apx[x, y] > 20:
                        opaque += 1
            frac = opaque / float(cw * ch)
            if 0.15 <= frac <= 0.92:
                frame = _trim(img.crop((gx, gy, gx + cw, gy + ch)))
                if frame.width > 0 and frame.height > 0:
                    frame.save(dst)
                    return True
    return False


def _hue_ok(category: str, mr: float, mg: float, mb: float) -> bool:
    if category == "grass":
        return mg > mr + 10 and mg > mb + 10 and mg > 70
    if category == "dirt":
        return mr > mb + 18 and mr >= mg - 6 and mg > mb and mr > 90
    if category == "water":
        return mb > mr + 12 and mb > 90
    return True


def do_terrain(src: Path, dst: Path, cell: int, category: str) -> bool:
    """Pick the most uniform (lowest colour-variance) fully-opaque cell whose mean
    colour matches the category hue — a clean fill tile, never an edge/corner tile."""
    if not src.is_file():
        return False
    img = Image.open(src).convert("RGBA")
    px = img.load()
    best = None
    best_var = 1e18
    for gy in range(0, img.height - cell + 1, cell):
        for gx in range(0, img.width - cell + 1, cell):
            rs = gs = bs = 0
            vals = []
            opaque = True
            for y in range(gy, gy + cell):
                if not opaque:
                    break
                for x in range(gx, gx + cell):
                    r, g, b, a = px[x, y]
                    if a < 255:
                        opaque = False
                        break
                    rs += r
                    gs += g
                    bs += b
                    vals.append((r, g, b))
            if not opaque:
                continue
            n = cell * cell
            mr, mg, mb = rs / n, gs / n, bs / n
            if not _hue_ok(category, mr, mg, mb):
                continue
            var = sum((r - mr) ** 2 + (g - mg) ** 2 + (b - mb) ** 2 for r, g, b in vals) / n
            if var < best_var:
                best_var = var
                best = (gx, gy)
    if best is None:
        return False
    img.crop((best[0], best[1], best[0] + cell, best[1] + cell)).save(dst)
    return True


def analyze_ui(vault: Path) -> None:
    """Print alpha-gap element boxes from the Modern UI style sheet + write a gridded
    review sheet, so UI cells can be chosen deliberately later (no blind slicing)."""
    src = vault / UI_STYLE_SHEET
    if not src.is_file():
        log(f"UI style sheet not found: {src}")
        return
    img = Image.open(src).convert("RGBA")
    alpha = img.getchannel("A")
    w, h = img.size
    apx = alpha.load()
    col_has = [any(apx[x, y] > 16 for y in range(h)) for x in range(w)]
    row_has = [any(apx[x, y] > 16 for x in range(w)) for y in range(h)]

    def runs(flags):
        out = []
        start = None
        for i, f in enumerate(flags):
            if f and start is None:
                start = i
            elif not f and start is not None:
                out.append((start, i))
                start = None
        if start is not None:
            out.append((start, len(flags)))
        return out

    col_runs = runs(col_has)
    row_runs = runs(row_has)
    log(f"UI style sheet {w}x{h}: {len(col_runs)} column bands x {len(row_runs)} row bands")
    boxes = []
    for (ry0, ry1) in row_runs[:24]:
        for (cx0, cx1) in col_runs[:24]:
            boxes.append((cx0, ry0, cx1 - cx0, ry1 - ry0))
    boxes_sorted = sorted(boxes, key=lambda b: -(b[2] * b[3]))
    log("largest element boxes (x,y,w,h):")
    for b in boxes_sorted[:12]:
        print("   ", b)
    # gridded review sheet (local, gitignored)
    out_dir = vault / "modern_ui" / "contact_sheets"
    out_dir.mkdir(parents=True, exist_ok=True)
    grid = img.convert("RGBA").copy()
    from PIL import ImageDraw
    d = ImageDraw.Draw(grid)
    for x in range(0, w, 16):
        d.line([(x, 0), (x, h)], fill=(255, 0, 128, 90))
    for y in range(0, h, 16):
        d.line([(0, y), (w, y)], fill=(255, 0, 128, 90))
    grid.save(out_dir / "style1_16grid.png")
    log(f"wrote review grid: {out_dir / 'style1_16grid.png'}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Slice curated LimeZu spike assets (local only).")
    parser.add_argument("--root", default="licensed_assets/limezu")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--analyze-ui", action="store_true")
    args = parser.parse_args()

    vault = Path(args.root)
    if not vault.is_absolute():
        vault = ROOT / vault
    if not vault.is_dir():
        log(f"vault not found: {vault} (nothing to do)")
        return

    if args.analyze_ui:
        analyze_ui(vault)
        if not args.all:
            return

    mapped: dict[str, str] = {}
    failed: list[str] = []
    for logical_id, pack, op, src_rel, extra in SPIKE_ASSETS:
        src = vault / src_rel
        dst = _spike_dir(vault, pack) / _safe_name(logical_id)
        ok = False
        if op == "copy":
            ok = do_copy(src, dst)
        elif op == "slice":
            ok = do_slice(src, dst, extra)
        elif op == "slice_first":
            ok = do_slice_first(src, dst, extra)
        elif op == "rawcrop":
            ok = do_rawcrop(src, dst, extra)
        elif op == "terrain":
            ok = do_terrain(src, dst, extra[0], extra[1])
        if ok:
            mapped[logical_id] = f"{pack}/normalized/spike/{_safe_name(logical_id)}"
        else:
            failed.append(logical_id)
            log(f"  ! could not produce {logical_id} from {src_rel}")

    # Merge into the local active manifest (keep any pre-existing keys).
    manifest_path = vault / "limezu_active_manifest.json"
    manifest = {"provider": "limezu", "active": {}}
    if manifest_path.exists():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            manifest = {"provider": "limezu", "active": {}}
    active = manifest.get("active", {})
    if not isinstance(active, dict):
        active = {}
    active.update(mapped)
    manifest["active"] = active
    manifest["provider"] = "limezu"
    manifest["_comment"] = ("LOCAL gitignored LimeZu activation manifest. Spike mappings written by "
                            "tools/art/limezu_slice_spike_assets.py from reviewed Modern Farm single "
                            "files + sliced sheets. Never commit this file or the assets it points at.")
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    log(f"mapped {len(mapped)} spike ids; {len(failed)} failed; manifest has {len(active)} active ids")
    if failed:
        log(f"failed ids: {failed}")
    print(json.dumps({"mapped": sorted(mapped.keys()), "failed": failed}, indent=2))


if __name__ == "__main__":
    main()
