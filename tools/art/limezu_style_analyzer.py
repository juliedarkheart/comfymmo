#!/usr/bin/env python3
"""LimeZu style analyzer — builds a LOCAL style profile from the installed LimeZu
extracted packs, so the inspired generator can make Hearthvale-original art that
feels LimeZu-compatible (palette, outline, shadow, scale, contrast, clusters).

ABSOLUTE LOCAL ASSET SAFETY: reads only from licensed_assets/limezu/*/extracted/.
Writes ONLY additively to generator_manifests/ (the profile) and, with --preview,
a palette swatch under generator_outputs/style_review/. Never deletes/moves/edits
any source asset. Output is local + gitignored; do not commit.

Usage:
  python tools/art/limezu_style_analyzer.py --dry-run
  python tools/art/limezu_style_analyzer.py --preview
"""

from __future__ import annotations

import argparse
import colorsys
import datetime
import json
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    raise SystemExit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE_ROOT = ROOT / "licensed_assets/limezu"
DEFAULT_PROFILE = ROOT / "licensed_assets/limezu/generator_manifests/limezu_style_profile.json"
PREVIEW_DIR = ROOT / "licensed_assets/limezu/generator_outputs/style_review"

PACKS = ["modern_farm", "modern_exteriors", "modern_ui", "modern_interiors", "modern_office", "rpg_arsenal"]
MAX_FILES_PER_PACK = 22
ANALYZE_MAX_DIM = 96

# Category -> filename keywords used to cluster colors by material/role.
CATEGORY_KEYWORDS = {
    "crop_plant": ["crop", "plant", "growth", "fruit", "vegetable"],
    "terrain": ["terrain", "tileset", "ground", "autotile", "grass", "soil"],
    "wood": ["fence", "wood", "props_and_buildings", "table", "chair", "crate"],
    "stone": ["stone", "rock", "wall", "path", "pavement"],
    "metal": ["tool", "metal", "fence_metal", "arsenal", "weapon"],
    "fabric": ["ui", "interface", "banner", "carpet", "cloth", "curtain"],
}


def _is_combined_sheet(path: Path) -> bool:
    n = path.name.lower()
    return n[:1].isdigit() and "_16x16" in n


def _sample_files(pack_dir: Path) -> list[Path]:
    """Prefer the numbered combined sheets + a spread of single files, capped."""
    if not pack_dir.is_dir():
        return []
    combined: list[Path] = []
    others: list[Path] = []
    count = 0
    for path in sorted(pack_dir.rglob("*.png")):
        count += 1
        if count > 6000:  # bound enumeration on the huge packs
            break
        if _is_combined_sheet(path):
            combined.append(path)
        elif len(others) < 400:
            others.append(path)
    picks = combined[:8]
    step = max(1, len(others) // max(1, MAX_FILES_PER_PACK - len(picks)))
    picks += others[::step][: MAX_FILES_PER_PACK - len(picks)]
    return picks


def _opaque_pixels(img: Image.Image) -> list[tuple[int, int, int]]:
    img = img.convert("RGBA")
    if max(img.size) > ANALYZE_MAX_DIM:
        scale = ANALYZE_MAX_DIM / max(img.size)
        img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.NEAREST)
    out = []
    for r, g, b, a in img.getdata():
        if a >= 200:
            out.append((r, g, b))
    return out


def _hsv(rgb):
    return colorsys.rgb_to_hsv(rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0)


def _hexc(rgb) -> str:
    return "#%02x%02x%02x" % (rgb[0], rgb[1], rgb[2])


def _quantize(pixels, n=12):
    """Coarse palette: bucket into a small grid and return most common centers."""
    buckets: dict[tuple, list] = {}
    for r, g, b in pixels:
        key = (r // 24, g // 24, b // 24)
        buckets.setdefault(key, [0, 0, 0, 0])
        acc = buckets[key]
        acc[0] += r; acc[1] += g; acc[2] += b; acc[3] += 1
    centers = []
    for acc in buckets.values():
        c = acc[3]
        centers.append(((acc[0] // c, acc[1] // c, acc[2] // c), c))
    centers.sort(key=lambda x: -x[1])
    return centers[:n]


def analyze(source_root: Path) -> dict:
    all_pixels: list[tuple[int, int, int]] = []
    category_pixels: dict[str, list] = {k: [] for k in CATEGORY_KEYWORDS}
    sizes: dict[str, int] = {}
    transparent_frac: list[float] = []
    packs_used: list[str] = []
    sampled_total = 0

    for pack in PACKS:
        pack_dir = source_root / pack / "extracted"
        files = _sample_files(pack_dir)
        if not files:
            continue
        packs_used.append(pack)
        for path in files:
            try:
                img = Image.open(path).convert("RGBA")
            except Exception:
                continue
            sampled_total += 1
            w, h = img.size
            sizes["%dx%d" % (w, h)] = sizes.get("%dx%d" % (w, h), 0) + 1
            data = list(img.getdata())
            if data:
                transparent_frac.append(sum(1 for px in data if px[3] < 20) / len(data))
            px = _opaque_pixels(img)
            all_pixels.extend(px[:4000])
            low = path.as_posix().lower()
            for cat, kws in CATEGORY_KEYWORDS.items():
                if any(k in low for k in kws):
                    category_pixels[cat].extend(px[:1500])

    if not all_pixels:
        return {}

    palette = _quantize(all_pixels, 14)
    palette_hex = [_hexc(c) for c, _ in palette]

    # Accent = lively, saturated colors. The dark global palette under-weights these,
    # so source them from the crop/terrain cluster pixels (greens, water, sand) plus
    # any saturated palette entries.
    accent_pool: list = []
    for cat in ("crop_plant", "terrain"):
        accent_pool.extend(category_pixels.get(cat, []))
    accent_centers = _quantize(accent_pool, 16) if accent_pool else []
    accents = [_hexc(c) for c, _ in accent_centers if _hsv(c)[1] > 0.4 and _hsv(c)[2] > 0.4][:6]
    by_sat = sorted(palette, key=lambda x: -_hsv(x[0])[1])
    for c, _ in by_sat:
        if len(accents) >= 6:
            break
        if _hsv(c)[1] > 0.35 and _hsv(c)[2] > 0.45 and _hexc(c) not in accents:
            accents.append(_hexc(c))
    darks = sorted(palette, key=lambda x: _hsv(x[0])[2])
    outline = [_hexc(c) for c, _ in darks if _hsv(c)[2] < 0.25][:3] or [palette_hex[-1]]
    shadow = [_hexc(c) for c, _ in darks if _hsv(c)[2] < 0.4 and _hsv(c)[1] < 0.4][:3] or outline

    lumas = [0.299 * r + 0.587 * g + 0.114 * b for r, g, b in all_pixels[:20000]]
    mean_luma = sum(lumas) / len(lumas)
    contrast = (sum((l - mean_luma) ** 2 for l in lumas) / len(lumas)) ** 0.5 / 255.0
    sats = [_hsv(p)[1] for p in all_pixels[:20000]]
    mean_sat = sum(sats) / len(sats)

    clusters = {}
    for cat, px in category_pixels.items():
        if px:
            clusters[cat] = [_hexc(c) for c, _ in _quantize(px, 6)]

    common_sizes = sorted(sizes.items(), key=lambda x: -x[1])[:6]

    return {
        "schema": "limezu_style_profile/v1",
        "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "generator": "tools/art/limezu_style_analyzer.py",
        "commit_policy": "local_gitignored_output",
        "source_packs_used": packs_used,
        "sampled_images": sampled_total,
        "palette": palette_hex,
        "accent_colors": accents,
        "outline_colors": outline,
        "shadow_colors": shadow,
        "common_image_sizes": ["%s (x%d)" % (k, v) for k, v in common_sizes],
        "base_tile_size": 16,
        "render_scale": 2,
        "average_contrast": round(contrast, 3),
        "average_saturation": round(mean_sat, 3),
        "average_transparency": round(sum(transparent_frac) / len(transparent_frac), 3) if transparent_frac else 0.0,
        "outline_thickness_px": 1,
        "shadow_style": "soft contact ellipse, low-alpha dark, below sprite",
        "ui_border_px": 4,
        "color_clusters": clusters,
        "notes": [
            "Local style reference for the inspired generator; not authoritative art.",
            "Sampled from licensed LimeZu extracted packs; never copies whole sprites.",
        ],
    }


def _write_preview(profile: dict) -> Path | None:
    palette = profile.get("palette", [])
    if not palette:
        return None
    sw = 24
    cols = len(palette)
    img = Image.new("RGBA", (sw * cols, sw * 3), (0, 0, 0, 0))
    px = img.load()
    rows = [palette, profile.get("accent_colors", []), profile.get("outline_colors", []) + profile.get("shadow_colors", [])]
    for ry, row in enumerate(rows):
        for cx, hexc in enumerate(row):
            rgb = tuple(int(hexc[i:i + 2], 16) for i in (1, 3, 5))
            for y in range(sw):
                for x in range(sw):
                    if 0 <= cx * sw + x < img.width:
                        px[cx * sw + x, ry * sw + y] = rgb + (255,)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    (PREVIEW_DIR / ".gdignore").write_text("Local style review art. Do not import.\n", encoding="utf-8")
    dest = PREVIEW_DIR / "limezu_style_palette.png"
    img.save(dest)
    return dest


def main() -> None:
    ap = argparse.ArgumentParser(description="Analyze installed LimeZu packs into a local style profile.")
    ap.add_argument("--dry-run", action="store_true", help="report the plan, write nothing")
    ap.add_argument("--preview", action="store_true", help="also write a palette swatch for review")
    ap.add_argument("--source-root", default=str(DEFAULT_SOURCE_ROOT))
    ap.add_argument("--output", default=str(DEFAULT_PROFILE))
    args = ap.parse_args()

    source_root = Path(args.source_root)
    present = [p for p in PACKS if (source_root / p / "extracted").is_dir()]
    if not present:
        raise SystemExit("[style-analyzer] STOP: no LimeZu extracted packs under %s — not repairing." % source_root)

    if args.dry_run:
        print("[style-analyzer] dry-run. Packs present: %s" % ", ".join(present))
        print("[style-analyzer] would write profile -> %s" % args.output)
        return

    print("[style-analyzer] analyzing %d pack(s)..." % len(present))
    profile = analyze(source_root)
    if not profile:
        raise SystemExit("[style-analyzer] STOP: no analyzable pixels found in source packs.")

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(profile, indent=2), encoding="utf-8")
    print("[style-analyzer] wrote %s (palette=%d, packs=%s)" % (out, len(profile["palette"]), profile["source_packs_used"]))
    if args.preview:
        dest = _write_preview(profile)
        if dest:
            print("[style-analyzer] palette swatch -> %s" % dest)


if __name__ == "__main__":
    main()
