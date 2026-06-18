#!/usr/bin/env python3
"""Measure production CONSTRAINTS of the local LimeZu pixel art (commit-safe tool).

This learns *style constraints* — canvas sizes, outline thickness, value/saturation ranges,
icon fill ratio, dominant hue buckets — NOT the art itself. It writes a LOCAL, gitignored
JSON report (derived data from licensed assets stays local) and prints a summary. The
commit-safe, ORIGINAL Hearthvale rules live in
`tools/art/templates/hearthvale_generator_style_profile.json`; use this report to sanity-check
and tune that profile. No pixels are copied into committed files.

    python tools/art/hearthvale_palette_analyzer.py --root licensed_assets/limezu
"""
from __future__ import annotations
import argparse
import colorsys
import glob
import json
import os
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

try:
    from PIL import Image
    HAVE_PIL = True
except Exception:
    HAVE_PIL = False


def log(msg: str) -> None:
    print(f"[hearthvale-analyze] {msg}")


def _sample_icon_paths(vault: Path, limit: int = 200) -> list[Path]:
    pats = [
        "modern_farm/**/Icons_16x16_Singles/*.png",
        "modern_ui/normalized/spike/*.png",
        "modern_farm/**/Single_Files_16x16/**/*.png",
    ]
    found: list[Path] = []
    for pat in pats:
        found.extend(Path(p) for p in glob.glob(str(vault / pat), recursive=True))
        if len(found) >= limit:
            break
    return found[:limit]


def _analyze_image(path: Path) -> dict | None:
    try:
        im = Image.open(path).convert("RGBA")
    except Exception:
        return None
    w, h = im.size
    px = im.load()
    opaque = 0
    dark_edge = 0
    vals: list[float] = []
    sats: list[float] = []
    hue_buckets: Counter = Counter()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 40:
                continue
            opaque += 1
            hh, ll, ss = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            vals.append(ll)
            sats.append(ss)
            hue_buckets[int(hh * 12) % 12] += 1
            if ll < 0.22:
                dark_edge += 1
    if opaque == 0:
        return None
    return {
        "size": (w, h),
        "fill_ratio": opaque / float(w * h),
        "dark_ratio": dark_edge / float(opaque),
        "mean_value": sum(vals) / len(vals),
        "mean_sat": sum(sats) / len(sats),
        "top_hue_bucket": hue_buckets.most_common(1)[0][0] if hue_buckets else -1,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Measure LimeZu pixel-art style constraints (local report).")
    parser.add_argument("--root", default="licensed_assets/limezu")
    args = parser.parse_args()
    vault = Path(args.root)
    if not vault.is_absolute():
        vault = ROOT / vault

    out_dir = vault / "generator_manifests"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "hearthvale_style_analysis.json"

    if not HAVE_PIL:
        report = {"_schema": "hearthvale.style_analysis.v1", "error": "PIL not installed; cannot analyze.",
                  "guidance": "pip install pillow, then re-run. The committed style profile already has sane defaults."}
        out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        log("PIL missing — wrote a stub report. Committed style profile defaults still apply.")
        return

    paths = _sample_icon_paths(vault)
    sizes: Counter = Counter()
    fill_ratios: list[float] = []
    dark_ratios: list[float] = []
    values: list[float] = []
    sats: list[float] = []
    hue_buckets: Counter = Counter()
    analyzed = 0
    for p in paths:
        r = _analyze_image(p)
        if r is None:
            continue
        analyzed += 1
        sizes[f"{r['size'][0]}x{r['size'][1]}"] += 1
        fill_ratios.append(r["fill_ratio"])
        dark_ratios.append(r["dark_ratio"])
        values.append(r["mean_value"])
        sats.append(r["mean_sat"])
        if r["top_hue_bucket"] >= 0:
            hue_buckets[r["top_hue_bucket"]] += 1

    def avg(xs):
        return round(sum(xs) / len(xs), 3) if xs else None

    report = {
        "_schema": "hearthvale.style_analysis.v1",
        "_comment": "LOCAL gitignored measurements derived from licensed LimeZu art. Never commit. "
                    "Use to tune tools/art/templates/hearthvale_generator_style_profile.json (committed, original).",
        "samples_analyzed": analyzed,
        "common_canvas_sizes": sizes.most_common(8),
        "mean_fill_ratio": avg(fill_ratios),
        "mean_dark_outline_ratio": avg(dark_ratios),
        "mean_value": avg(values),
        "mean_saturation": avg(sats),
        "dominant_hue_buckets_0to11": hue_buckets.most_common(6),
        "derived_recommendations": {
            "base_cell_px": int((sizes.most_common(1)[0][0].split("x")[0]) if sizes else 16),
            "outline_thickness_px": 1,
            "value_range": [0.25, 0.9],
            "saturation_range": [0.2, 0.7],
            "note": "Recommendations feed the ORIGINAL Hearthvale profile; no pixels are copied.",
        },
    }
    out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    log(f"analyzed {analyzed} samples -> {out_path.relative_to(ROOT)} (local/gitignored)")
    log(f"common sizes={sizes.most_common(4)} mean_value={avg(values)} mean_sat={avg(sats)} outline_ratio={avg(dark_ratios)}")


if __name__ == "__main__":
    main()
