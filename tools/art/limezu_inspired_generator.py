#!/usr/bin/env python3
"""LimeZu-INSPIRED original generator — makes NEW Hearthvale-original pixel assets
that feel LimeZu-compatible, guided by the local style profile (palette, outline,
shadow, tile size, contrast). It does NOT copy or slice source sprites — every
pixel is drawn procedurally here, so outputs are original (still kept local until
art/license review).

ABSOLUTE LOCAL ASSET SAFETY: reads only the local style profile JSON; writes only
under licensed_assets/limezu/generator_outputs/inspired/ and the inspired manifest.
Gitignored; do not commit. --force backs up the output folder before overwriting.

Usage:
  python tools/art/limezu_inspired_generator.py --dry-run
  python tools/art/limezu_inspired_generator.py --preview [--seed 7]
  python tools/art/limezu_inspired_generator.py --all [--seed 7] [--force]
"""

from __future__ import annotations

import argparse
import datetime
import json
import random
import shutil
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROFILE = ROOT / "licensed_assets/limezu/generator_manifests/limezu_style_profile.json"
DEFAULT_OUTPUT_ROOT = ROOT / "licensed_assets/limezu/generator_outputs/inspired"
DEFAULT_MANIFEST = ROOT / "licensed_assets/limezu/generator_manifests/limezu_inspired_manifest.json"
TILE = 16
SCALE = 2
# Last-resort fallback palette ONLY when no style profile exists (keeps --dry-run usable).
FALLBACK = {"palette": ["#7faf68", "#5d8c4c", "#8a5e36", "#c88854", "#e6ae55", "#3a9fb1", "#eae3f2", "#3c3c54"],
            "accent_colors": ["#9bc246", "#64b63b", "#e6ae55", "#3a9fb1"],
            "outline_colors": ["#191b1d"], "shadow_colors": ["#2a2630"]}

# id -> (kind, subfolder, hint). hint guides color role / shape family.
SPECS: dict[str, tuple[str, str, str]] = {}


def _add(ids, kind, sub, hint):
    for i in ids:
        SPECS[i] = (kind, sub, hint)


def _build_specs() -> None:
    _add([f"{c}_stage_{s}" for c in ("moonbean", "honeyroot", "starberry", "fluffwheat") for s in (1, 2, 3)], "crop", "crops", "crop")
    _add(["cozy_seed_bin", "ribbon_fence", "heart_sign", "mushroom_lantern", "berry_crate", "flower_wagon",
          "tiny_greenhouse_marker", "garden_charm_stake", "picnic_table", "cozy_workbench", "moonwell_bucket",
          "family_notice_sign"], "prop", "props", "wood")
    _add(["soft_path_tile", "mossy_path_tile", "flower_border_tile"], "terrain", "terrain", "terrain")
    _add(["hearth_panel_soft", "hearth_panel_dark", "questless_notice_card", "family_board_card"], "panel", "ui", "fabric")
    _add(["cozy_button", "cozy_button_hover"], "button", "ui", "fabric")
    _add(["cozy_slot", "cozy_slot_selected"], "slot", "ui", "fabric")
    _add(["tiny_close_button", "crop_status_badge"], "badge", "ui", "fabric")
    _add(["moonbean_seed_packet", "honeyroot_seed_packet", "starberry_seed_packet", "fluffwheat_seed_packet"], "seed_packet", "icons", "crop")
    _add(["comfort_token_icon", "garden_charm_icon", "creature_treat_icon"], "icon", "icons", "accent")
    _add(["village_note_icon", "cozy_task_badge", "family_calendar_icon"], "icon", "icons", "fabric")
    _add(["soft_wood_icon", "rose_clay_icon"], "icon", "icons", "wood")
    _add(["smooth_stone_icon", "meadow_fiber_icon"], "icon", "icons", "terrain")
    _add(["cottage_farmer_outfit_icon", "village_helper_outfit_icon", "soft_apron_icon", "cozy_boots_icon"], "outfit", "wearables", "fabric")
    _add(["flower_hairpin_icon", "star_clip_icon", "round_glasses_icon"], "icon", "wearables", "accent")
    _add(["hearthvale_villager_preview", "hearthvale_farmer_preview"], "outfit", "characters", "fabric")


PREVIEW_IDS = ["moonbean_stage_1", "moonbean_stage_3", "honeyroot_stage_2", "cozy_seed_bin",
               "ribbon_fence", "soft_path_tile", "hearth_panel_soft", "cozy_button",
               "moonbean_seed_packet", "comfort_token_icon"]


def _hex2rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


class Style:
    def __init__(self, profile: dict):
        self.palette = [_hex2rgb(c) for c in profile.get("palette", FALLBACK["palette"])]
        self.accents = [_hex2rgb(c) for c in (profile.get("accent_colors") or FALLBACK["accent_colors"])]
        self.outline = _hex2rgb((profile.get("outline_colors") or FALLBACK["outline_colors"])[0])
        self.shadow = _hex2rgb((profile.get("shadow_colors") or FALLBACK["shadow_colors"])[0])
        self.clusters = {k: [_hex2rgb(c) for c in v] for k, v in profile.get("color_clusters", {}).items()}

    def color(self, role: str, rng: random.Random):
        pool = {
            "crop": self.clusters.get("crop_plant") or self.accents,
            "terrain": self.clusters.get("terrain") or self.palette,
            "wood": self.clusters.get("wood") or self.palette,
            "stone": self.clusters.get("stone") or self.palette,
            "fabric": self.clusters.get("fabric") or self.palette,
            "accent": self.accents or self.palette,
        }.get(role, self.palette)
        return rng.choice(pool) if pool else (140, 150, 120)


def _lighten(c, f=0.35):
    return tuple(min(255, int(v + (255 - v) * f)) for v in c)


def _darken(c, f=0.3):
    return tuple(max(0, int(v * (1 - f))) for v in c)


def _outline_pass(img: Image.Image, color) -> Image.Image:
    w, h = img.size
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src = img.load(); dst = out.load()
    out.alpha_composite(img)
    for y in range(h):
        for x in range(w):
            if src[x, y][3] > 60:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] == 0:
                        dst[nx, ny] = color + (255,)
    return out


def _shadow(d: ImageDraw.ImageDraw, cx, by, rw, st):
    d.ellipse([cx - rw, by - rw // 2, cx + rw, by + rw // 2], fill=st.shadow + (90,))


def _finish(img: Image.Image, st: Style) -> Image.Image:
    return _outline_pass(img, st.outline).resize(((TILE) * SCALE + 2 * SCALE, (TILE) * SCALE + 2 * SCALE) if False else None or ((img.width) * SCALE, (img.height) * SCALE), Image.NEAREST)


def draw_crop(asset_id: str, st: Style, rng: random.Random) -> Image.Image:
    stage = int(asset_id[-1]) if asset_id[-1].isdigit() else 1
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    _shadow(d, 8, 14, 5, st)
    soil = st.color("wood", rng)
    d.rectangle([3, 12, 12, 14], fill=_darken(soil, 0.15))
    plant = st.color("crop", rng)
    top = 11 - stage * 2
    d.line([(8, 12), (8, top)], fill=_darken(plant, 0.2), width=1)  # stem
    if stage >= 1:
        d.ellipse([5, top, 8, top + 3], fill=plant)
        d.ellipse([8, top, 11, top + 3], fill=_lighten(plant, 0.2))
    if stage >= 2:
        d.ellipse([4, top - 2, 7, top + 1], fill=plant)
        d.ellipse([9, top - 2, 12, top + 1], fill=_lighten(plant, 0.25))
    if stage >= 3:
        fruit = rng.choice(st.accents) if st.accents else plant
        d.ellipse([6, top - 4, 10, top], fill=fruit)
        d.point((7, top - 3), fill=_lighten(fruit, 0.5))
    return _outline_pass(img, st.outline).resize((TILE * SCALE, TILE * SCALE), Image.NEAREST)


def draw_prop(asset_id: str, st: Style, rng: random.Random) -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    _shadow(d, 8, 14, 6, st)
    wood = st.color("wood", rng)
    accent = rng.choice(st.accents) if st.accents else st.color("crop", rng)
    fam = rng.randint(0, 3)
    if "fence" in asset_id or "sign" in asset_id or "stake" in asset_id or "notice" in asset_id:
        d.rectangle([3, 4, 5, 13], fill=wood); d.rectangle([10, 4, 12, 13], fill=wood)
        d.rectangle([2, 6, 13, 8], fill=_lighten(wood, 0.2))
        if "sign" in asset_id or "notice" in asset_id:
            d.rectangle([3, 3, 12, 8], fill=_lighten(wood, 0.3))
            d.line([(5, 5), (10, 5)], fill=_darken(wood, 0.3)); d.line([(5, 7), (9, 7)], fill=_darken(wood, 0.3))
        if "heart" in asset_id:
            d.ellipse([5, 3, 8, 6], fill=accent); d.ellipse([8, 3, 11, 6], fill=accent); d.polygon([(5, 5), (11, 5), (8, 9)], fill=accent)
    elif "bucket" in asset_id or "bin" in asset_id or "crate" in asset_id:
        d.rectangle([3, 6, 13, 14], fill=wood)
        d.rectangle([3, 6, 13, 7], fill=_lighten(wood, 0.3))
        d.line([(3, 6), (13, 14)], fill=_darken(wood, 0.3)); d.line([(13, 6), (3, 14)], fill=_darken(wood, 0.3))
        if "berry" in asset_id or "moonwell" in asset_id:
            d.ellipse([5, 4, 7, 6], fill=accent); d.ellipse([8, 4, 10, 6], fill=accent)
    elif "lantern" in asset_id:
        d.rectangle([7, 8, 9, 14], fill=_darken(wood, 0.2))
        d.ellipse([4, 3, 12, 10], fill=accent); d.ellipse([6, 5, 10, 8], fill=_lighten(accent, 0.4))
    elif "table" in asset_id or "workbench" in asset_id:
        d.rectangle([2, 6, 14, 8], fill=_lighten(wood, 0.2)); d.rectangle([3, 8, 5, 14], fill=wood); d.rectangle([11, 8, 13, 14], fill=wood)
        if "workbench" in asset_id:
            d.rectangle([6, 3, 10, 6], fill=st.color("stone", rng))
    elif "wagon" in asset_id:
        d.rectangle([3, 5, 13, 11], fill=wood); d.ellipse([3, 10, 7, 14], fill=_darken(wood, 0.4)); d.ellipse([9, 10, 13, 14], fill=_darken(wood, 0.4))
        d.ellipse([5, 3, 7, 5], fill=accent); d.ellipse([8, 3, 10, 5], fill=_lighten(accent, 0.3))
    else:  # generic marker
        d.rectangle([7, 5, 9, 14], fill=wood); d.polygon([(9, 4), (14, 6), (9, 8)], fill=accent)
    return _outline_pass(img, st.outline).resize((TILE * SCALE, TILE * SCALE), Image.NEAREST)


def draw_terrain(asset_id: str, st: Style, rng: random.Random) -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    base = st.color("terrain", rng)
    if "path" in asset_id:
        base = st.color("wood", rng) if "soft" in asset_id else st.color("stone", rng)
    px = img.load()
    for y in range(TILE):
        for x in range(TILE):
            n = ((x * 37 + y * 71 + rng.randint(0, 999)) % 7)
            c = _lighten(base, 0.12) if n == 0 else (_darken(base, 0.1) if n == 1 else base)
            px[x, y] = c + (255,)
    d = ImageDraw.Draw(img)
    if "border" in asset_id:
        for fx in (3, 8, 12):
            fc = rng.choice(st.accents) if st.accents else base
            d.ellipse([fx, 11, fx + 2, 13], fill=fc)
    if "mossy" in asset_id:
        moss = st.color("crop", rng)
        for _ in range(5):
            d.point((rng.randint(0, 15), rng.randint(0, 15)), fill=moss)
    return img.resize((TILE * SCALE, TILE * SCALE), Image.NEAREST)


def draw_ui(asset_id: str, kind: str, st: Style, rng: random.Random) -> Image.Image:
    size = 48 if kind == "panel" else 24
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fill = st.color("fabric", rng)
    if "dark" in asset_id:
        fill = _darken(fill, 0.45)
    elif kind == "panel" or "soft" in asset_id or "card" in asset_id:
        fill = _lighten(fill, 0.35)
    border = st.outline
    accent = rng.choice(st.accents) if st.accents else fill
    bw = 4 if kind == "panel" else 2
    d.rounded_rectangle([1, 1, size - 2, size - 2], radius=5, fill=fill + (255,), outline=border + (255,), width=bw)
    if kind == "button" and "hover" in asset_id:
        d.rounded_rectangle([3, 3, size - 4, size - 4], radius=4, outline=accent + (255,), width=1)
    if kind == "slot" and "selected" in asset_id:
        d.rounded_rectangle([2, 2, size - 3, size - 3], radius=4, outline=accent + (255,), width=2)
    if kind == "badge":
        if "close" in asset_id:
            d.line([(7, 7), (size - 8, size - 8)], fill=border + (255,), width=2)
            d.line([(size - 8, 7), (7, size - 8)], fill=border + (255,), width=2)
        else:
            d.ellipse([6, 6, size - 7, size - 7], fill=accent + (255,), outline=border + (255,))
    if "card" in asset_id:
        d.line([(6, 9), (size - 7, 9)], fill=border + (255,)); d.line([(6, 14), (size - 10, 14)], fill=border + (255,))
    return img.resize((size * SCALE, size * SCALE), Image.NEAREST)


def draw_icon(asset_id: str, kind: str, hint: str, st: Style, rng: random.Random) -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    base = st.color(hint if hint in ("crop", "wood", "terrain", "accent") else "accent", rng)
    accent = rng.choice(st.accents) if st.accents else base
    if kind == "seed_packet":
        d.rectangle([3, 2, 12, 14], fill=_lighten(base, 0.4)); d.polygon([(3, 2), (12, 2), (8, 6)], fill=_darken(base, 0.2))
        d.ellipse([6, 8, 10, 12], fill=accent)
    elif kind == "outfit":
        d.polygon([(8, 3), (12, 7), (11, 14), (5, 14), (4, 7)], fill=base)  # tunic
        d.rectangle([7, 3, 9, 5], fill=_lighten(base, 0.3))
        if "apron" in asset_id:
            d.rectangle([6, 7, 10, 13], fill=_lighten(accent, 0.2))
        if "boots" in asset_id:
            d.rectangle([5, 12, 11, 14], fill=_darken(base, 0.4))
    else:
        d.ellipse([3, 3, 13, 13], fill=base, outline=_darken(base, 0.3))
        if "token" in asset_id or "calendar" in asset_id:
            d.rectangle([5, 5, 11, 11], fill=_lighten(base, 0.3))
        if "star" in asset_id or "charm" in asset_id or "clip" in asset_id:
            d.polygon([(8, 3), (10, 8), (13, 8), (10, 10), (11, 14), (8, 11), (5, 14), (6, 10), (3, 8), (6, 8)], fill=accent)
        if "note" in asset_id or "task" in asset_id:
            d.rectangle([5, 4, 11, 13], fill=_lighten(base, 0.4)); d.line([(6, 7), (10, 7)], fill=st.outline); d.line([(6, 10), (9, 10)], fill=st.outline)
        if "fiber" in asset_id:
            d.line([(5, 12), (8, 4)], fill=accent, width=1); d.line([(11, 12), (8, 4)], fill=_lighten(accent, 0.3))
    return _outline_pass(img, st.outline).resize((16 * SCALE + 2 * SCALE, 16 * SCALE + 2 * SCALE) if False else (16 * SCALE, 16 * SCALE), Image.NEAREST)


def build_one(asset_id: str, st: Style, base_seed: int):
    kind, sub, hint = SPECS[asset_id]
    rng = random.Random((base_seed * 1000003) ^ (abs(hash(asset_id)) & 0xFFFFFFFF))
    if kind == "crop":
        img = draw_crop(asset_id, st, rng)
    elif kind == "prop":
        img = draw_prop(asset_id, st, rng)
    elif kind == "terrain":
        img = draw_terrain(asset_id, st, rng)
    elif kind in ("panel", "button", "slot", "badge"):
        img = draw_ui(asset_id, kind, st, rng)
    else:
        img = draw_icon(asset_id, kind, hint, st, rng)
    meta = {
        "id": asset_id, "category": sub, "source_type": "hearthvale_limezu_inspired_original",
        "style_profile_path": "licensed_assets/limezu/generator_manifests/limezu_style_profile.json",
        "operations": ["procedural_%s" % kind, "outline", "scale_nn:%dx" % SCALE], "seed": base_seed,
        "dimensions": list(img.size), "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "generator": "tools/art/limezu_inspired_generator.py", "commit_policy": "local_gitignored_output",
        "runtime_candidate": sub in ("crops", "props", "terrain", "ui", "icons"),
        "notes": "Original Hearthvale art drawn procedurally from the LimeZu style profile; not a source copy.",
    }
    return img, meta


def _backup(output_root: Path):
    if not output_root.exists() or not any(output_root.rglob("*.png")):
        return None
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = output_root.parent / ("_backup_inspired_%s" % stamp)
    shutil.copytree(output_root, backup)
    return backup


def main() -> None:
    _build_specs()
    ap = argparse.ArgumentParser(description="Generate LOCAL Hearthvale LimeZu-inspired original assets (gitignored).")
    ap.add_argument("--preview", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--style-profile", default=str(DEFAULT_PROFILE))
    ap.add_argument("--output-root", default=str(DEFAULT_OUTPUT_ROOT))
    ap.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    args = ap.parse_args()

    profile_path = Path(args.style_profile)
    profile = {}
    if profile_path.exists():
        try:
            profile = json.loads(profile_path.read_text(encoding="utf-8"))
        except Exception:
            profile = {}
    ids = PREVIEW_IDS if args.preview and not args.all else list(SPECS.keys())

    if args.dry_run:
        print("[inspired] dry-run: %d planned output(s); style profile %s" % (
            len(ids), "present" if profile else "MISSING (would use fallback palette)"))
        for asset_id in ids[:12]:
            print("  - %s/%s.png" % (SPECS[asset_id][1], asset_id))
        return

    if args.preview and not profile:
        raise SystemExit("[inspired] STOP: style profile missing — run limezu_style_analyzer.py --preview first.")

    st = Style(profile or FALLBACK)
    output_root = Path(args.output_root)
    if args.force:
        b = _backup(output_root)
        if b:
            print("[inspired] backed up existing outputs -> %s" % b)
    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / ".gdignore").write_text("Local inspired-original outputs. Do not import.\n", encoding="utf-8")

    manifest = {"schema": "limezu_inspired_manifest/v1", "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
                "generator": "tools/art/limezu_inspired_generator.py", "seed": args.seed,
                "commit_policy": "local_gitignored_output", "entries": {}}
    written = skipped = 0
    for asset_id in ids:
        dest = output_root / SPECS[asset_id][1] / ("%s.png" % asset_id)
        if dest.exists() and not args.force:
            skipped += 1
            continue
        img, meta = build_one(asset_id, st, args.seed)
        dest.parent.mkdir(parents=True, exist_ok=True)
        img.save(dest)
        meta["output_path"] = dest.relative_to(ROOT).as_posix()
        manifest["entries"][asset_id] = meta
        written += 1

    if Path(args.manifest).exists() and not args.force:
        try:
            prev = json.loads(Path(args.manifest).read_text(encoding="utf-8")).get("entries", {})
            for k, v in prev.items():
                manifest["entries"].setdefault(k, v)
        except Exception:
            pass
    Path(args.manifest).parent.mkdir(parents=True, exist_ok=True)
    Path(args.manifest).write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print("[inspired] wrote=%d skipped=%d (seed=%d) -> %s" % (written, skipped, args.seed, output_root))
    print("[inspired] manifest (%d entries) -> %s" % (len(manifest["entries"]), args.manifest))


if __name__ == "__main__":
    main()
