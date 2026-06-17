#!/usr/bin/env python3
"""Normalize selected Sprout Lands (premium, Cup Nooble) sprites for Hearthvale.

LOCAL ONLY. Reads the gitignored extracted pack, writes normalized derivatives +
the local activation manifest under licensed_assets/sprout_lands/ (also
gitignored). Originals are never modified. Nothing here is committed — see
docs/licensed_asset_policy.md. Sprout art is top-down 16px; objects + icons fit
Hearthvale's primary Sprout/top-down view, so those are wired with reviewed
single-tile terrain mappings.

The curated cell boxes below were read off the contact sheets in
licensed_assets/sprout_lands/contact_sheets/ (indices visible there). Re-run after
editing the maps:  python tools/art/sprout_integrate.py
"""

from __future__ import annotations

import json
import zipfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]
SPROUT = ROOT / "licensed_assets/sprout_lands"
PACK = SPROUT / "original/extracted/Sprout Lands - Sprites - premium pack"
UI_ZIP = SPROUT / "original/Sprout Lands - UI Pack - Premium pack.zip"
UI_EXTRACTED = SPROUT / "original/extracted_ui"
UI_ROOT = UI_EXTRACTED / "Sprout Lands - UI Pack - Premium pack"
NORMALIZED = SPROUT / "normalized"
MANIFEST = SPROUT / "sprout_active_manifest.json"
UI_MANIFEST = SPROUT / "sprout_ui_manifest.json"
UI_CONTACT = SPROUT / "contact_sheets/ui"
ANIM_CONTACT = SPROUT / "contact_sheets/animations"
ANIM_INVENTORY = SPROUT / "manifests/animations_inventory.json"
SORRY_ZIP = SPROUT / "original/Sprout Sorry pack.zip"
SORRY_EXTRACTED = SPROUT / "original/extracted_sorry"
SORRY_ROOT = SORRY_EXTRACTED / "Sprout Sorry pack"
SORRY_CONTACT = SPROUT / "contact_sheets/sorry"
AUDIO_INVENTORY = SPROUT / "manifests/audio_inventory.json"

# art-id (relative to res://art/)  ->  (source file in PACK, crop box or None)
OBJECTS = {
    "objects/nature/tree.png":            ("Objects/Trees, stumps and bushes.png", (144, 48, 192, 96)),
    "objects/nature/fruit_tree.png":      ("Objects/Tree animations/tree_appel_sprites.png", (0, 0, 48, 48)),
    "objects/nature/bush.png":            ("Objects/Trees, stumps and bushes.png", (1, 49, 16, 64)),
    "objects/nature/rock.png":            ("Objects/Mushrooms, Flowers, Stones.png", (96, 32, 128, 48)),
    "objects/nature/flower_patch.png":    ("Objects/Mushrooms, Flowers, Stones.png", (64, 48, 112, 64)),
    "objects/building/well.png":          ("Objects/Water well.png", None),
    "objects/decor/sign.png":             ("Objects/signs.png", (0, 0, 16, 18)),
    "objects/decor/fence.png":            ("Tilesets/Building parts/Fences.png", (0, 48, 48, 64)),
    "objects/building/storage_chest.png": ("Tilesets/Building parts/Chest.png", (16, 16, 32, 32)),
}
ICONS = {
    "ui/icons/watering_can.png":  ("Objects/Items/tools and meterials.png", (0, 0, 16, 16)),
    "ui/icons/worn_axe.png":      ("Objects/Items/tools and meterials.png", (16, 0, 32, 16)),
    "ui/icons/simple_hammer.png": ("Objects/Items/tools and meterials.png", (32, 0, 48, 16)),
    "ui/icons/fiber.png":         ("Objects/Items/tools and meterials.png", (48, 0, 64, 16)),
    "ui/icons/wood.png":          ("Objects/Items/tools and meterials.png", (0, 32, 16, 48)),
    "ui/icons/stone.png":         ("Objects/Items/tools and meterials.png", (32, 32, 48, 48)),
}
# Terrain activation is intentionally limited to reviewed single-tile top-down
# mappings. Multi-cell sheets stay catalog-only until manually reviewed.
TERRAIN = {
    "tiles/biomes/meadow.png":      ("Tilesets/ground tiles/New tiles/simpel versions/Grass tiles v2 simple cutout/Grass_tiles_v2_Mid.png", None),
    "tiles/water/water.png":        ("Tilesets/ground tiles/water frames/Water_1.png", None),
    "tiles/water/creek.png":        ("Tilesets/ground tiles/water frames/Water_2.png", None),
}

UI_CANDIDATES = {
    "panel": [
        "UI Sprites/Dialouge UI/dialog box big.png",
        "UI Sprites/Dialouge UI/Premade dialog box  big.png",
        "UI Sprites/Other UI sprites/Setting menu.png",
    ],
    "button": [
        "UI Sprites/buttons/square/Square Buttons 26x26.png",
        "UI Sprites/buttons/square/Square Buttons 26x19.png",
        "UI Sprites/buttons/round/medium colored round buttons.png",
    ],
    "button_hover": [
        "UI Sprites/buttons/square/Square Buttons 26x26.png",
        "UI Sprites/buttons/round/medium colored round buttons.png",
    ],
    "slot": [
        "emojis/emoji style ui/Inventory_Spritesheet.png",
        "emojis/emoji style ui/Inventory_Blocks_Spritesheet.png",
    ],
    "slot_selected": [
        "emojis/emoji style ui/Inventory_Herat_Spritesheet.png",
        "emojis/emoji style ui/Inventory_Light_Herat_Spritesheet.png",
    ],
    "close": [
        "UI Sprites/Other UI sprites/Xs and check marks/1s/big X.png",
        "UI Sprites/Other UI sprites/Xs and check marks/1s/X.png",
    ],
    "check": [
        "UI Sprites/Other UI sprites/Xs and check marks/1s/big check mark.png",
        "UI Sprites/Other UI sprites/Xs and check marks/1s/check mark.png",
    ],
    "cursor": [
        "UI Sprites/Mouse sprites/Arrow Mouse icon 1.png",
        "UI Sprites/Mouse sprites/Triangle Mouse icon 1.png",
    ],
    "dialog_panel": [
        "UI Sprites/Dialouge UI/dialog box.png",
        "UI Sprites/Dialouge UI/dialog box medium.png",
    ],
    "inventory_panel": [
        "emojis/emoji style ui/inventory_example_with_slots.png",
        "emojis/emoji style ui/inventory_Light_example_with_slots.png",
    ],
    "system_menu_panel": [
        "UI Sprites/Other UI sprites/Setting menu.png",
        "UI Sprites/Dialouge UI/Premade dialog box medium.png",
    ],
    "build_menu_panel": [
        "UI Sprites/Dialouge UI/Premade dialog box  big.png",
        "UI Sprites/Dialouge UI/dialog box big.png",
    ],
}

ANIMATION_KEYWORDS = {
    "water": ["water", "wave", "splash"],
    "crops": ["farming", "plant", "crop"],
    "trees": ["tree", "leaf", "leaves", "fruit"],
    "tools": ["tool", "watering", "wateringcan", "axe", "pickaxe", "hoe"],
    "characters": ["character", "charakter"],
    "doors_chests_mailbox": ["door", "chest", "mailbox", "gate"],
}
AUDIO_EXTENSIONS = {".wav", ".ogg", ".mp3"}


def trim(img: Image.Image) -> Image.Image:
    bbox = img.getchannel("A").getbbox()
    return img.crop(bbox) if bbox else img


def load_crop(src: str, box) -> Image.Image:
    img = Image.open(PACK / src).convert("RGBA")
    if box:
        img = img.crop(box)
    return trim(img)


def fit(sprite: Image.Image, max_w: int, max_h: int) -> Image.Image:
    scale = min(max_w / sprite.width, max_h / sprite.height)
    return sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.LANCZOS)


def place(art_id: str, src: str, box, canvas, fit_box, anchor: str) -> None:
    sprite = fit(load_crop(src, box), *fit_box)
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    x = (canvas[0] - sprite.width) // 2
    if anchor == "bottom":
        y = canvas[1] - sprite.height - 6
    else:
        y = (canvas[1] - sprite.height) // 2
    out.alpha_composite(sprite, (x, max(0, y)))
    dest = NORMALIZED / art_id
    dest.parent.mkdir(parents=True, exist_ok=True)
    out.save(dest)


def _safe_rel(path: Path) -> str:
    return path.relative_to(SPROUT).as_posix()


def _write_godot_ignore(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    (path / ".gdignore").write_text(
        "Local licensed review/original assets. Do not import into Godot.\n",
        encoding="utf-8",
    )


def _extract_ui_pack() -> bool:
    if UI_ROOT.is_dir():
        return True
    if not UI_ZIP.exists():
        return False
    UI_EXTRACTED.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(UI_ZIP) as zf:
        zf.extractall(UI_EXTRACTED)
    return UI_ROOT.is_dir()


def _extract_sorry_pack() -> bool:
    if SORRY_ROOT.is_dir():
        return True
    if not SORRY_ZIP.exists():
        return False
    SORRY_EXTRACTED.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(SORRY_ZIP) as zf:
        zf.extractall(SORRY_EXTRACTED)
    return SORRY_ROOT.is_dir()


def _find_images(root: Path, limit: int = 80) -> list[Path]:
    if not root.exists():
        return []
    images: list[Path] = []
    for path in sorted(root.rglob("*")):
        if path.suffix.lower() in {".png", ".gif"}:
            images.append(path)
        if len(images) >= limit:
            break
    return images


def _load_preview(path: Path) -> Image.Image | None:
    try:
        img = Image.open(path).convert("RGBA")
        if getattr(img, "is_animated", False):
            img.seek(0)
            img = img.convert("RGBA")
        return img
    except Exception:
        return None


def _contact_sheet(title: str, files: list[Path], dest: Path, thumb=(104, 72), columns=4) -> None:
    if not files:
        return
    rows = (len(files) + columns - 1) // columns
    label_h = 34
    pad = 10
    cell_w = thumb[0] + pad * 2
    cell_h = thumb[1] + label_h + pad * 2
    title_h = 30
    sheet = Image.new("RGBA", (cell_w * columns, title_h + cell_h * rows), (244, 226, 184, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((pad, 8), title, fill=(74, 52, 32, 255))
    for index, path in enumerate(files):
        img = _load_preview(path)
        if img is None:
            continue
        img.thumbnail(thumb, Image.LANCZOS)
        x = (index % columns) * cell_w
        y = title_h + (index // columns) * cell_h
        draw.rectangle((x + 3, y + 3, x + cell_w - 3, y + cell_h - 3), outline=(134, 81, 31, 255), width=2)
        sheet.alpha_composite(img, (x + (cell_w - img.width) // 2, y + pad))
        label = path.name if len(path.name) <= 28 else path.name[:25] + "..."
        draw.text((x + pad, y + pad + thumb[1] + 4), label, fill=(74, 52, 32, 255))
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)


def _write_ui_manifest() -> None:
    if not UI_ROOT.is_dir():
        return
    existing_active: dict[str, str] = {}
    if UI_MANIFEST.exists():
        try:
            existing = json.loads(UI_MANIFEST.read_text(encoding="utf-8"))
            if isinstance(existing.get("active"), dict):
                existing_active = dict(existing["active"])
        except Exception:
            existing_active = {}
    candidates: dict[str, list[str]] = {}
    for ui_id, rels in UI_CANDIDATES.items():
        paths: list[str] = []
        for rel in rels:
            candidate = UI_ROOT / rel
            if candidate.exists():
                paths.append(_safe_rel(candidate))
        candidates[ui_id] = paths
    manifest = {
        "_comment": "LOCAL gitignored Sprout UI manifest. Active is intentionally safe to leave empty; UIArtRegistry falls back to generated/cozy code-drawn UI.",
        "version": 1,
        "pack": "Sprout Lands UI Pack (premium) by Cup Nooble",
        "license": "premium, local-only, non-redistributable; credit Cup Nooble",
        "active": existing_active,
        "candidates": candidates,
    }
    UI_MANIFEST.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def _write_ui_contact_sheets() -> None:
    if not UI_ROOT.is_dir():
        return
    groups = {
        "ui_overview": UI_ROOT / "UI Sprites",
        "ui_buttons": UI_ROOT / "UI Sprites/buttons",
        "ui_dialog_panels": UI_ROOT / "UI Sprites/Dialouge UI",
        "ui_icons_selectors": UI_ROOT / "UI Sprites/Other UI sprites",
        "ui_inventory": UI_ROOT / "emojis/emoji style ui",
    }
    for name, root in groups.items():
        _contact_sheet(name, _find_images(root, 36), UI_CONTACT / f"{name}.png", columns=4)


def _animation_inventory() -> None:
    roots = [PACK]
    if UI_ROOT.is_dir():
        roots.append(UI_ROOT)
    inventory: dict[str, list[str]] = {key: [] for key in ANIMATION_KEYWORDS}
    for root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if path.suffix.lower() not in {".png", ".gif"}:
                continue
            rel_lower = path.as_posix().lower()
            if "dungeon" in rel_lower or "enemy" in rel_lower or "bat" in rel_lower or "slime" in rel_lower:
                continue
            for category, keywords in ANIMATION_KEYWORDS.items():
                if any(keyword in rel_lower for keyword in keywords):
                    inventory[category].append(_safe_rel(path))
                    break
    ANIM_INVENTORY.parent.mkdir(parents=True, exist_ok=True)
    ANIM_INVENTORY.write_text(json.dumps({
        "_comment": "LOCAL gitignored Sprout animation inventory. Catalog only; no runtime wiring.",
        "version": 1,
        "pack": "Sprout Lands local animation scan",
        "categories": inventory,
        "counts": {key: len(value) for key, value in inventory.items()},
        "notes": ["No combat, creature, or dungeon animation work in this pass."],
    }, indent=2), encoding="utf-8")
    for category, rels in inventory.items():
        files = [SPROUT / rel for rel in rels[:32]]
        _contact_sheet(f"animations_{category}", files, ANIM_CONTACT / f"{category}.png", columns=4)


def _catalog_sorry_pack() -> bool:
    if not _extract_sorry_pack():
        return False
    groups = {
        "sorry_overview": SORRY_ROOT,
        "sorry_village": SORRY_ROOT / "Early Access/Village pack",
        "sorry_plants": SORRY_ROOT / "Early Access/Plant update 2",
        "sorry_ocean": SORRY_ROOT / "Early Access/Ocean Pack",
        "sorry_dungeon_catalog_only": SORRY_ROOT / "Early Access/Dungeon Pack",
    }
    for name, root in groups.items():
        _contact_sheet(name, _find_images(root, 36), SORRY_CONTACT / f"{name}.png", columns=4)

    audio_files: list[str] = []
    for path in sorted(SORRY_ROOT.rglob("*")):
        if path.suffix.lower() in AUDIO_EXTENSIONS:
            audio_files.append(_safe_rel(path))
    AUDIO_INVENTORY.parent.mkdir(parents=True, exist_ok=True)
    AUDIO_INVENTORY.write_text(json.dumps({
        "_comment": "LOCAL gitignored Sprout Sorry pack audio inventory. Catalog only; no runtime wiring.",
        "version": 1,
        "pack": "Sprout Sorry pack by Cup Nooble",
        "license": "local-only, non-redistributable; credit Cup Nooble",
        "files": audio_files,
        "count": len(audio_files),
        "notes": ["No combat, dungeon gameplay, enemy, or audio runtime wiring in this pass."],
    }, indent=2), encoding="utf-8")
    return True


def main() -> None:
    if not PACK.is_dir():
        raise SystemExit(f"Sprout pack not extracted at {PACK}")
    # Originals, extracted UI sheets/fonts, and contact sheets are review inputs,
    # not runtime resources. Ignoring them keeps headless imports from processing
    # thousands of local-only licensed files while normalized active art remains
    # loadable from licensed_assets/sprout_lands/normalized/.
    _write_godot_ignore(SPROUT / "original")
    _write_godot_ignore(SPROUT / "contact_sheets")
    _write_godot_ignore(SPROUT / "manifests")
    ui_available = _extract_ui_pack()
    active: dict[str, str] = {}
    for art_id, (src, box) in OBJECTS.items():
        place(art_id, src, box, (96, 96), (90, 84), "bottom")
        active[art_id] = art_id
    for art_id, (src, box) in ICONS.items():
        place(art_id, src, box, (64, 64), (48, 48), "center")
        active[art_id] = art_id
    for art_id, (src, box) in TERRAIN.items():
        place(art_id, src, box, (32, 32), (32, 32), "center")
        active[art_id] = art_id

    manifest = {
        "_comment": "LOCAL gitignored activation manifest for Sprout Lands (Cup Nooble). "
                    "Generated by tools/art/sprout_integrate.py. Keys are art ids (rel to "
                    "res://art/); values are rel to licensed_assets/sprout_lands/normalized/. "
                    "Never commit this file or the normalized assets.",
        "version": 1,
        "pack": "Sprout Lands (premium) by Cup Nooble",
        "license": "premium, local-only, non-redistributable; credit Cup Nooble",
        "active": active,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # Preserve the pack's license/credit at a stable, predictable path.
    readme = PACK / "read_me.txt"
    if readme.exists():
        (SPROUT / "CREDIT_AND_LICENSE.txt").write_text(
            "Source: Sprout Lands (premium) by Cup Nooble — local-only, non-redistributable.\n"
            "Credit: Assets -From : Sprout Lands -By : Cup Nooble\n"
            "Original pack license text follows:\n\n"
            + readme.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
    print(f"Normalized {len(OBJECTS)} objects + {len(ICONS)} icons + {len(TERRAIN)} terrain.")
    print(f"Activated {len(active)} ids -> {MANIFEST.relative_to(ROOT)}")
    if ui_available:
        _write_ui_manifest()
        _write_ui_contact_sheets()
        print(f"Prepared UI manifest + contact sheets under {UI_CONTACT.relative_to(ROOT)}")
    else:
        print("UI pack zip not found; skipped UI extraction/contact sheets.")
    _animation_inventory()
    print(f"Cataloged animations -> {ANIM_INVENTORY.relative_to(ROOT)}")
    if _catalog_sorry_pack():
        print(f"Cataloged Sprout Sorry pack -> {SORRY_CONTACT.relative_to(ROOT)}")
        print(f"Cataloged Sorry audio -> {AUDIO_INVENTORY.relative_to(ROOT)}")
    else:
        print("Sprout Sorry pack zip not found; skipped Sorry catalog.")


if __name__ == "__main__":
    main()
