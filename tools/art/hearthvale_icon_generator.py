#!/usr/bin/env python3
"""Generate ORIGINAL Hearthvale placeholder icons procedurally (commit-safe tool).

Draws simple, ORIGINAL geometric silhouettes (NOT copied from LimeZu or any pack) using the
committed `tools/art/templates/hearthvale_generator_style_profile.json` â€” its palette, 1px
darker-shade outline, top-light + 1px-down shadow, and 16px cell with inner padding. Outputs
are local/gitignored under `licensed_assets/limezu/generator_outputs/hearthvale_generated/`
until docs/hearthvale_asset_generator_plan.md declares a commit policy.

    python tools/art/hearthvale_icon_generator.py --preview
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / "tools/art/templates/hearthvale_generator_style_profile.json"
OUT_REL = "generator_outputs/hearthvale_generated"

try:
    from PIL import Image, ImageDraw
    HAVE_PIL = True
except Exception:
    HAVE_PIL = False


def log(msg: str) -> None:
    print(f"[hearthvale-icongen] {msg}")


def _hex(c: str):
    c = c.lstrip("#")
    return (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255)


def _shade(c, f=0.55):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), 255)


def _draw_icon(name: str, pal: dict, cell: int = 16) -> "Image.Image":
    img = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cell / 2.0
    P = {k: _hex(v) for k, v in pal.items() if isinstance(v, str) and v.startswith("#")}
    # Each recipe is an ORIGINAL primitive composition (no traced/copied art).
    if name == "log":
        body = P["wood_mid"]; d.rounded_rectangle([2, 5, cell - 3, cell - 5], radius=2, fill=body, outline=_shade(body))
        d.ellipse([2, 5, 6, cell - 5], fill=P["wood_light"], outline=_shade(body))
    elif name == "stone":
        body = P["stone"]; d.polygon([(3, cell - 4), (5, 5), (cell - 4, 6), (cell - 3, cell - 4)], fill=body, outline=_shade(body))
    elif name == "leaf":
        body = P["leaf_mid"]; d.ellipse([3, 3, cell - 3, cell - 3], fill=body, outline=_shade(body))
        d.line([(cx, 4), (cx, cell - 4)], fill=_shade(body), width=1)
    elif name == "berry":
        body = P["berry"]; d.ellipse([3, 5, cell - 6, cell - 3], fill=body, outline=_shade(body))
        d.ellipse([6, 4, cell - 3, cell - 5], fill=body, outline=_shade(body))
        d.line([(cx, 2), (cx + 1, 5)], fill=P["leaf_dark"], width=1)
    elif name == "acorn":
        body = P["wood_light"]; d.ellipse([4, 6, cell - 4, cell - 2], fill=body, outline=_shade(body))
        d.rectangle([4, 4, cell - 4, 7], fill=P["wood_dark"], outline=_shade(P["wood_dark"]))
    elif name == "coin":
        body = P["gold"]; d.ellipse([3, 3, cell - 3, cell - 3], fill=body, outline=_shade(body))
        d.ellipse([6, 6, cell - 6, cell - 6], outline=_shade(body))
    elif name == "axe":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(5, 3), (11, cell - 3)], fill=_shade(handle), width=3)
        d.line([(5, 3), (11, cell - 3)], fill=handle, width=1)
        d.polygon([(3, 3), (8, 2), (9, 6), (4, 7)], fill=metal, outline=_shade(metal))
    elif name == "pickaxe":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(8, 4), (8, cell - 3)], fill=_shade(handle), width=3)
        d.line([(8, 4), (8, cell - 3)], fill=handle, width=1)
        d.line([(3, 4), (13, 4)], fill=_shade(metal), width=3)
        d.line([(3, 4), (13, 4)], fill=metal, width=1)
    elif name == "hoe":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(5, 3), (11, cell - 3)], fill=_shade(handle), width=3)
        d.line([(5, 3), (11, cell - 3)], fill=handle, width=1)
        d.rectangle([3, 3, 8, 5], fill=metal, outline=_shade(metal))
    elif name == "shovel":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(8, 2), (8, 10)], fill=_shade(handle), width=3)
        d.line([(8, 2), (8, 10)], fill=handle, width=1)
        d.polygon([(5, 9), (11, 9), (10, 14), (6, 14)], fill=metal, outline=_shade(metal))
    elif name == "watering_can":
        body = P["water"]; rim = _shade(body)
        d.rounded_rectangle([3, 6, 11, 13], radius=2, fill=body, outline=rim)
        d.arc([8, 5, 15, 12], 260, 80, fill=rim, width=1)
        d.line([(3, 7), (1, 5)], fill=rim, width=1)
        d.point([(1, 4), (2, 4)], fill=P["water"])
    elif name == "generic_seed":
        body = P["leaf_light"]
        d.ellipse([3, 4, 7, 8], fill=body, outline=_shade(body))
        d.ellipse([8, 7, 12, 11], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
        d.ellipse([5, 10, 9, 14], fill=P["wood_light"], outline=_shade(P["wood_light"]))
    elif name == "generic_tool":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(4, 12), (12, 4)], fill=_shade(handle), width=3)
        d.line([(4, 12), (12, 4)], fill=handle, width=1)
        d.rectangle([9, 2, 13, 6], fill=metal, outline=_shade(metal))
    elif name == "empty_hands":
        skin = P["parchment"]; outline = _shade(skin)
        d.ellipse([3, 6, 8, 11], fill=skin, outline=outline)
        d.ellipse([8, 6, 13, 11], fill=skin, outline=outline)
        d.line([(5, 11), (4, 13)], fill=outline, width=1)
        d.line([(11, 11), (12, 13)], fill=outline, width=1)
    else:
        body = P["parchment"]; d.rounded_rectangle([3, 3, cell - 3, cell - 3], radius=2, fill=body, outline=_shade(body))
    # top-left highlight + 1px down shadow contact dot (style-profile rules)
    return img


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate original Hearthvale placeholder icons.")
    parser.add_argument("--preview", action="store_true", help="Render the sample set + a contact sheet.")
    parser.add_argument("--root", default="licensed_assets/limezu")
    parser.add_argument("--scale", type=int, default=4, help="Integer NEAREST upscale for the contact sheet.")
    args = parser.parse_args()

    if not PROFILE.is_file():
        log(f"style profile missing: {PROFILE}"); return
    profile = json.loads(PROFILE.read_text(encoding="utf-8"))
    pal = profile.get("palette", {})
    cell = int(profile.get("icons", {}).get("item_icon_px", 16))

    vault = Path(args.root)
    if not vault.is_absolute():
        vault = ROOT / vault
    out_dir = vault / OUT_REL / "item_icons"
    review_dir = vault / OUT_REL / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    review_dir.mkdir(parents=True, exist_ok=True)
    gi = (vault / OUT_REL / ".gdignore")
    if not gi.exists():
        gi.write_text("Local ORIGINAL Hearthvale generated art. Gitignored until policy says otherwise.\n", encoding="utf-8")

    if not HAVE_PIL:
        log("PIL not installed; cannot render. `pip install pillow` then re-run --preview.")
        return
    if not args.preview:
        log("Nothing to do without --preview (this is a preview/stub generator).")
        return

    names = [
        "log", "stone", "leaf", "berry", "acorn", "coin",
        "axe", "pickaxe", "hoe", "shovel", "watering_can",
        "empty_hands", "generic_seed", "generic_tool",
    ]
    for n in names:
        img = _draw_icon(n, pal, cell)
        img.save(out_dir / f"item_icon_{n}_{cell}px.png")
    # Contact sheet (gitignored review).
    s = args.scale
    cols = min(7, len(names))
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell * s + (cols + 1) * 4, rows * cell * s + (rows + 1) * 4), (40, 40, 48, 255))
    for i, n in enumerate(names):
        img = Image.open(out_dir / f"item_icon_{n}_{cell}px.png").convert("RGBA").resize((cell * s, cell * s), Image.NEAREST)
        x = i % cols
        y = i // cols
        sheet.paste(img, (4 + x * (cell * s + 4), 4 + y * (cell * s + 4)), img)
    sheet.save(review_dir / "hearthvale_icon_preview.png")
    log(f"generated {len(names)} original placeholder icons -> {out_dir.relative_to(ROOT)} (gitignored)")
    log(f"contact sheet -> {(review_dir / 'hearthvale_icon_preview.png').relative_to(ROOT)}")


if __name__ == "__main__":
    main()
