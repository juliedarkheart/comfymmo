#!/usr/bin/env python3
"""Generate ORIGINAL Hearthvale placeholder icons procedurally (commit-safe tool).

Draws simple, ORIGINAL geometric silhouettes (NOT copied from LimeZu or any pack) using the
committed `tools/art/templates/hearthvale_generator_style_profile.json` — its palette, 1px
darker-shade outline, top-light + 1px-down shadow, and 16px cell with inner padding. Outputs
are local/gitignored under `licensed_assets/limezu/generator_outputs/hearthvale_generated/`
until docs/hearthvale_asset_generator_plan.md declares a commit policy.

    python tools/art/hearthvale_icon_generator.py --preview
    python tools/art/hearthvale_icon_generator.py --all
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

    # === MATERIALS ===
    if name == "wood" or name == "log":
        body = P["wood_mid"]; d.rounded_rectangle([2, 5, cell - 3, cell - 5], radius=2, fill=body, outline=_shade(body))
        d.ellipse([2, 5, 6, cell - 5], fill=P["wood_light"], outline=_shade(body))
    elif name == "stone":
        body = P["stone"]; d.polygon([(3, cell - 4), (5, 5), (cell - 4, 6), (cell - 3, cell - 4)], fill=body, outline=_shade(body))
    elif name == "clay":
        body = P["clay"]
        d.ellipse([3, 7, 10, 13], fill=body, outline=_shade(body))
        d.ellipse([7, 5, 13, 12], fill=body, outline=_shade(body))
        d.point([(5, 8), (9, 7), (11, 10)], fill=P["parchment_deep"])
    elif name == "fiber":
        body = P["leaf_light"]
        d.line([(4, 3), (4, 13)], fill=_shade(body), width=2)
        d.line([(8, 4), (8, 14)], fill=body, width=2)
        d.line([(12, 3), (12, 13)], fill=P["leaf_mid"], width=2)
    elif name == "leaf":
        body = P["leaf_mid"]; d.ellipse([3, 3, cell - 3, cell - 3], fill=body, outline=_shade(body))
        d.line([(cx, 4), (cx, cell - 4)], fill=_shade(body), width=1)

    # === CROPS ===
    elif name == "carrot" or name == "carrot_crop":
        body = P["wood_light"]; top = P["leaf_mid"]
        d.polygon([(6, 7), (10, 7), (9, 14), (7, 14)], fill=body, outline=_shade(body))
        d.polygon([(7, 14), (9, 14), (8, 16)], fill=_shade(body))
        d.ellipse([5, 4, 8, 7], fill=top, outline=_shade(top))
        d.ellipse([8, 3, 12, 7], fill=P["leaf_light"], outline=_shade(top))
    elif name == "turnip" or name == "turnip_crop":
        body = P["parchment"]; top = P["leaf_mid"]
        d.ellipse([4, 6, cell - 4, cell - 2], fill=body, outline=_shade(body))
        d.polygon([(7, 14), (9, 14), (8, 16)], fill=_shade(body))
        d.ellipse([5, 3, 8, 7], fill=top, outline=_shade(top))
        d.ellipse([8, 2, 12, 7], fill=P["leaf_light"], outline=_shade(top))
    elif name == "berry" or name == "berry_crop":
        body = P["berry"]; d.ellipse([3, 5, cell - 6, cell - 3], fill=body, outline=_shade(body))
        d.ellipse([6, 4, cell - 3, cell - 5], fill=body, outline=_shade(body))
        d.line([(cx, 2), (cx + 1, 5)], fill=P["leaf_dark"], width=1)

    # === CROP STAGES ===
    elif name == "tilled_soil" or name == "watered_soil":
        soil = P["soil"] if name == "tilled_soil" else P["water"]
        d.polygon([(8, 3), (14, 8), (8, 13), (2, 8)], fill=soil, outline=_shade(soil))
        for y in [6, 8, 10]:
            d.line([(5, y), (11, y)], fill=P["wood_dark"], width=1)
    elif name in ["carrot_stage_1", "carrot_stage_2", "carrot_stage_3"]:
        soil = P["soil"]
        d.polygon([(8, 11), (13, 14), (8, 16), (3, 14)], fill=soil, outline=_shade(soil))
        if name == "carrot_stage_1":
            d.line([(8, 11), (8, 7)], fill=P["leaf_dark"], width=1)
            d.ellipse([5, 6, 8, 9], fill=P["leaf_light"], outline=_shade(P["leaf_mid"]))
        elif name == "carrot_stage_2":
            d.line([(8, 11), (8, 5)], fill=P["leaf_dark"], width=1)
            d.ellipse([4, 5, 9, 10], fill=P["leaf_light"], outline=_shade(P["leaf_mid"]))
            d.ellipse([7, 4, 13, 10], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
        else:
            d.ellipse([4, 4, 12, 12], fill=P["leaf_mid"], outline=_shade(P["leaf_dark"]))
            d.ellipse([6, 8, 10, 13], fill=P["wood_light"], outline=_shade(P["wood_light"]))
    elif name in ["turnip_stage_1", "turnip_stage_2", "turnip_stage_3"]:
        soil = P["soil"]
        d.polygon([(8, 11), (13, 14), (8, 16), (3, 14)], fill=soil, outline=_shade(soil))
        if name == "turnip_stage_1":
            d.line([(8, 11), (8, 7)], fill=P["leaf_dark"], width=1)
            d.ellipse([6, 6, 10, 9], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
        elif name == "turnip_stage_2":
            d.line([(8, 11), (8, 5)], fill=P["leaf_dark"], width=1)
            d.ellipse([4, 5, 10, 10], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
            d.ellipse([7, 4, 12, 9], fill=P["leaf_light"], outline=_shade(P["leaf_mid"]))
        else:
            d.ellipse([4, 5, 12, 12], fill=P["leaf_mid"], outline=_shade(P["leaf_dark"]))
            d.ellipse([6, 10, 11, 15], fill=P["parchment"], outline=_shade(P["parchment"]))
    elif name in ["berry_stage_1", "berry_stage_2", "berry_stage_3"]:
        soil = P["soil"]
        d.polygon([(8, 11), (13, 14), (8, 16), (3, 14)], fill=soil, outline=_shade(soil))
        if name == "berry_stage_1":
            d.line([(8, 11), (8, 7)], fill=P["leaf_dark"], width=1)
            d.ellipse([5, 6, 11, 10], fill=P["leaf_light"], outline=_shade(P["leaf_mid"]))
        elif name == "berry_stage_2":
            d.line([(8, 11), (8, 4)], fill=P["leaf_dark"], width=1)
            d.ellipse([3, 4, 13, 11], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
            d.ellipse([6, 7, 10, 10], fill=P["berry"], outline=_shade(P["berry"]))
        else:
            d.ellipse([3, 3, 13, 12], fill=P["leaf_mid"], outline=_shade(P["leaf_dark"]))
            d.ellipse([5, 6, 9, 10], fill=P["berry"], outline=_shade(P["berry"]))
            d.ellipse([7, 8, 11, 12], fill=P["berry"], outline=_shade(P["berry"]))
    elif name in ["crop_stage_1", "crop_stage_2", "crop_stage_3"]:
        soil = P["soil"]
        d.polygon([(8, 11), (13, 14), (8, 16), (3, 14)], fill=soil, outline=_shade(soil))
        if name == "crop_stage_1":
            d.line([(8, 11), (8, 7)], fill=P["leaf_dark"], width=1)
            d.ellipse([5, 6, 8, 9], fill=P["leaf_light"], outline=_shade(P["leaf_mid"]))
            d.ellipse([8, 6, 11, 9], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
        elif name == "crop_stage_2":
            d.line([(8, 11), (8, 5)], fill=P["leaf_dark"], width=1)
            d.ellipse([4, 5, 9, 10], fill=P["leaf_light"], outline=_shade(P["leaf_mid"]))
            d.ellipse([7, 4, 13, 10], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
        else:
            d.ellipse([4, 4, 12, 12], fill=P["leaf_mid"], outline=_shade(P["leaf_dark"]))
            d.ellipse([6, 6, 10, 11], fill=P["wood_light"], outline=_shade(P["wood_light"]))

    # === TOOLS ===
    elif name == "hoe":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(5, 3), (11, cell - 3)], fill=_shade(handle), width=3)
        d.line([(5, 3), (11, cell - 3)], fill=handle, width=1)
        d.rectangle([3, 3, 8, 5], fill=metal, outline=_shade(metal))
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
    elif name == "generic_tool":
        handle = P["wood_mid"]; metal = P["stone"]
        d.line([(4, 12), (12, 4)], fill=_shade(handle), width=3)
        d.line([(4, 12), (12, 4)], fill=handle, width=1)
        d.rectangle([9, 2, 13, 6], fill=metal, outline=_shade(metal))

    # === SEEDS ===
    elif name == "generic_seed":
        body = P["leaf_light"]
        d.ellipse([3, 4, 7, 8], fill=body, outline=_shade(body))
        d.ellipse([8, 7, 12, 11], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))
        d.ellipse([5, 10, 9, 14], fill=P["wood_light"], outline=_shade(P["wood_light"]))
    elif name in ["carrot_seed_packet", "turnip_seed_packet", "berry_seed_packet"]:
        accent = P["wood_light"] if name.startswith("carrot") else P["parchment"] if name.startswith("turnip") else P["berry"]
        paper = P["parchment"]
        d.rounded_rectangle([3, 3, 12, 14], radius=1, fill=paper, outline=_shade(paper))
        d.line([(4, 6), (11, 6)], fill=_shade(paper), width=1)
        d.ellipse([6, 9, 10, 13], fill=accent, outline=_shade(accent))
        d.ellipse([4, 4, 6, 6], fill=P["leaf_mid"], outline=_shade(P["leaf_mid"]))

    # === PROPS & BUILDABLES ===
    elif name == "crate":
        wood = P["wood_mid"]
        d.rounded_rectangle([3, 4, 13, 14], radius=1, fill=wood, outline=_shade(wood))
        d.line([(3, 7), (13, 7)], fill=P["wood_dark"], width=1)
        d.line([(3, 11), (13, 11)], fill=P["wood_dark"], width=1)
        d.line([(6, 4), (6, 14)], fill=P["wood_dark"], width=1)
        d.line([(10, 4), (10, 14)], fill=P["wood_dark"], width=1)
    elif name == "sign":
        post = P["wood_dark"]; board = P["wood_mid"]
        d.rectangle([7, 4, 9, 14], fill=post, outline=_shade(post))
        d.rounded_rectangle([3, 6, 13, 11], radius=1, fill=board, outline=_shade(board))
        d.line([(4, 8), (12, 8)], fill=P["wood_light"], width=1)
    elif name == "fence":
        post = P["wood_dark"]; rail = P["wood_mid"]
        d.rectangle([3, 4, 5, 14], fill=post, outline=_shade(post))
        d.rectangle([11, 4, 13, 14], fill=post, outline=_shade(post))
        d.rectangle([3, 7, 13, 9], fill=rail, outline=_shade(rail))
        d.rectangle([3, 11, 13, 13], fill=rail, outline=_shade(rail))
    elif name == "simple_chair":
        wood = P["wood_mid"]
        d.rectangle([4, 6, 12, 10], fill=wood, outline=_shade(wood))
        d.rectangle([5, 10, 6, 14], fill=P["wood_dark"])
        d.rectangle([10, 10, 11, 14], fill=P["wood_dark"])
        d.line([(4, 6), (12, 6)], fill=P["wood_light"], width=1)
        d.rectangle([4, 3, 12, 5], fill=wood, outline=_shade(wood))
    elif name == "simple_table":
        wood = P["wood_mid"]
        d.rectangle([3, 7, 13, 10], fill=wood, outline=_shade(wood))
        d.line([(3, 7), (13, 7)], fill=P["wood_light"], width=1)
        d.rectangle([4, 10, 5, 14], fill=P["wood_dark"])
        d.rectangle([11, 10, 12, 14], fill=P["wood_dark"])
    elif name == "simple_chest":
        body = P["wood_dark"]; metal = P["stone"]
        d.rounded_rectangle([3, 6, 13, 14], radius=1, fill=body, outline=_shade(body))
        d.rectangle([6, 9, 10, 11], fill=metal, outline=_shade(metal))
        d.line([(3, 10), (13, 10)], fill=_shade(body), width=1)
    elif name == "workbench":
        wood = P["wood_mid"]; top = P["wood_light"]
        d.rectangle([2, 6, 14, 9], fill=top, outline=_shade(top))
        d.rectangle([3, 9, 5, 14], fill=wood)
        d.rectangle([11, 9, 13, 14], fill=wood)
        d.line([(2, 6), (14, 6)], fill=_shade(top), width=1)
        d.rectangle([6, 10, 10, 11], fill=P["stone"], outline=_shade(P["stone"]))
    elif name == "seed_bag":
        bag = P["leaf_dark"]; tie = P["wood_mid"]
        d.ellipse([4, 7, 12, 15], fill=bag, outline=_shade(bag))
        d.polygon([(6, 7), (10, 7), (9, 5), (7, 5)], fill=tie, outline=_shade(tie))
        d.ellipse([7, 10, 9, 12], fill=P["leaf_light"], outline=_shade(P["leaf_light"]))
    elif name == "fabric":
        cloth = P["parchment"]
        d.rounded_rectangle([3, 5, 13, 13], radius=1, fill=cloth, outline=_shade(cloth))
        d.line([(3, 7), (13, 7)], fill=_shade(cloth), width=1)
        d.line([(3, 10), (13, 10)], fill=_shade(cloth), width=1)
        d.line([(6, 5), (6, 13)], fill=_shade(cloth), width=1)
        d.line([(10, 5), (10, 13)], fill=_shade(cloth), width=1)
    elif name == "button":
        button = P["wood_light"]
        d.ellipse([5, 5, 11, 11], fill=button, outline=_shade(button))
        d.point([(7, 7), (9, 7), (7, 9), (9, 9)], fill=_shade(button))
    elif name == "dye_bottle":
        glass = P["water"]; liquid = P["berry"]
        d.rounded_rectangle([5, 5, 11, 14], radius=1, fill=glass, outline=_shade(glass))
        d.rounded_rectangle([6, 8, 10, 13], radius=1, fill=liquid, outline=_shade(liquid))
        d.rectangle([6, 4, 10, 6], fill=P["wood_dark"], outline=_shade(P["wood_dark"]))
    elif name == "generic_decor":
        body = P["leaf_mid"]
        d.ellipse([4, 4, 12, 12], fill=body, outline=_shade(body))
        d.ellipse([6, 6, 10, 10], fill=P["leaf_light"], outline=_shade(P["leaf_light"]))
    elif name == "furniture_prop":
        wood = P["wood_mid"]
        d.rectangle([4, 6, 12, 10], fill=wood, outline=_shade(wood))
        d.rectangle([5, 10, 6, 14], fill=P["wood_dark"])
        d.rectangle([10, 10, 11, 14], fill=P["wood_dark"])
        d.line([(4, 6), (12, 6)], fill=P["wood_light"], width=1)
    elif name == "generic_material":
        body = P["stone"]
        d.polygon([(8, 3), (13, 7), (11, 13), (5, 13), (3, 7)], fill=body, outline=_shade(body))
        d.line([(8, 3), (8, 13)], fill=_shade(body), width=1)

    # === WEARABLES ===
    elif name == "shirt_icon":
        cloth = P["parchment"]
        d.polygon([(4, 5), (12, 5), (14, 9), (14, 14), (2, 14), (2, 9)], fill=cloth, outline=_shade(cloth))
        d.line([(8, 5), (8, 14)], fill=_shade(cloth), width=1)
    elif name == "pants_icon":
        cloth = P["leaf_dark"]
        d.rectangle([5, 5, 11, 10], fill=cloth, outline=_shade(cloth))
        d.rectangle([5, 10, 7, 15], fill=cloth, outline=_shade(cloth))
        d.rectangle([9, 10, 11, 15], fill=cloth, outline=_shade(cloth))
    elif name == "dress_icon":
        cloth = P["berry"]
        d.polygon([(4, 4), (12, 4), (14, 8), (13, 15), (3, 15), (2, 8)], fill=cloth, outline=_shade(cloth))
        d.line([(8, 4), (8, 15)], fill=_shade(cloth), width=1)
    elif name == "shoes_icon":
        leather = P["wood_dark"]
        d.ellipse([3, 9, 7, 13], fill=leather, outline=_shade(leather))
        d.ellipse([9, 9, 13, 13], fill=leather, outline=_shade(leather))
    elif name == "hat_icon":
        cloth = P["wood_mid"]
        d.ellipse([3, 10, 13, 14], fill=cloth, outline=_shade(cloth))
        d.rounded_rectangle([5, 4, 11, 11], radius=2, fill=cloth, outline=_shade(cloth))
    elif name == "hair_icon":
        hair = P["wood_light"]
        d.ellipse([4, 3, 12, 13], fill=hair, outline=_shade(hair))
        d.ellipse([6, 5, 10, 11], fill=_shade(hair), outline=_shade(hair))
    elif name == "accessory_icon":
        accent = P["gold"]
        d.ellipse([4, 6, 8, 10], fill=accent, outline=_shade(accent))
        d.ellipse([8, 6, 12, 10], fill=accent, outline=_shade(accent))
        d.line([(6, 10), (6, 12)], fill=_shade(accent), width=1)
        d.line([(10, 10), (10, 12)], fill=_shade(accent), width=1)
    elif name == "wearable_leaf_clip":
        leaf = P["leaf_light"]
        d.ellipse([4, 4, 12, 10], fill=leaf, outline=_shade(leaf))
        d.line([(5, 10), (12, 4)], fill=P["leaf_dark"], width=1)
        d.rectangle([5, 11, 12, 13], fill=P["gold"], outline=_shade(P["gold"]))

    # === MISC ===
    elif name == "empty_hands":
        skin = P["parchment"]; outline = _shade(skin)
        d.ellipse([3, 6, 8, 11], fill=skin, outline=outline)
        d.ellipse([8, 6, 13, 11], fill=skin, outline=outline)
        d.line([(5, 11), (4, 13)], fill=outline, width=1)
        d.line([(11, 11), (12, 13)], fill=outline, width=1)
    elif name == "acorn":
        body = P["wood_light"]; d.ellipse([4, 6, cell - 4, cell - 2], fill=body, outline=_shade(body))
        d.rectangle([4, 4, cell - 4, 7], fill=P["wood_dark"], outline=_shade(P["wood_dark"]))
    elif name == "coin":
        body = P["gold"]; d.ellipse([3, 3, cell - 3, cell - 3], fill=body, outline=_shade(body))
        d.ellipse([6, 6, cell - 6, cell - 6], outline=_shade(body))
    elif name == "generic_crop":
        body = P["leaf_mid"]
        d.ellipse([4, 5, 12, 13], fill=body, outline=_shade(body))
        d.ellipse([6, 7, 10, 11], fill=P["wood_light"], outline=_shade(P["wood_light"]))
    elif name == "generic_furniture":
        wood = P["wood_mid"]
        d.rectangle([4, 6, 12, 10], fill=wood, outline=_shade(wood))
        d.rectangle([5, 10, 6, 14], fill=P["wood_dark"])
        d.rectangle([10, 10, 11, 14], fill=P["wood_dark"])
        d.line([(4, 6), (12, 6)], fill=P["wood_light"], width=1)
    elif name == "generic_wearable":
        cloth = P["parchment"]
        d.rounded_rectangle([4, 4, 12, 13], radius=2, fill=cloth, outline=_shade(cloth))
        d.line([(8, 4), (8, 13)], fill=_shade(cloth), width=1)
    else:
        body = P["parchment"]; d.rounded_rectangle([3, 3, cell - 3, cell - 3], radius=2, fill=body, outline=_shade(body))
    # top-left highlight + 1px down shadow contact dot (style-profile rules)
    return img


def _get_all_names() -> list[str]:
    """Return the complete list of recipe names."""
    return [
        # Materials
        "wood", "log", "stone", "clay", "fiber", "leaf", "generic_material",
        # Crops
        "carrot", "carrot_crop", "turnip", "turnip_crop", "berry", "berry_crop", "generic_crop",
        # Crop stages
        "tilled_soil", "watered_soil",
        "carrot_stage_1", "carrot_stage_2", "carrot_stage_3",
        "turnip_stage_1", "turnip_stage_2", "turnip_stage_3",
        "berry_stage_1", "berry_stage_2", "berry_stage_3",
        "crop_stage_1", "crop_stage_2", "crop_stage_3",
        # Tools
        "hoe", "axe", "pickaxe", "shovel", "watering_can", "generic_tool",
        # Seeds
        "generic_seed", "carrot_seed_packet", "turnip_seed_packet", "berry_seed_packet",
        # Props & Buildables
        "crate", "sign", "fence", "simple_chair", "simple_table", "simple_chest",
        "workbench", "seed_bag", "fabric", "button", "dye_bottle", "generic_decor",
        "furniture_prop",
        # Wearables
        "shirt_icon", "pants_icon", "dress_icon", "shoes_icon", "hat_icon",
        "hair_icon", "accessory_icon", "wearable_leaf_clip", "generic_wearable",
        "generic_furniture",
        # Misc
        "empty_hands", "acorn", "coin",
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate original Hearthvale placeholder icons.")
    parser.add_argument("--preview", action="store_true", help="Render the sample set + a contact sheet.")
    parser.add_argument("--all", action="store_true", help="Render all recipes including crop stages and wearables.")
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
    if not args.preview and not args.all:
        log("Nothing to do without --preview or --all.")
        return

    names = _get_all_names() if args.all else [
        "log", "stone", "leaf", "berry", "acorn", "coin",
        "turnip", "clay",
        "axe", "pickaxe", "hoe", "shovel", "watering_can",
        "empty_hands", "generic_seed", "carrot_seed_packet", "turnip_seed_packet",
        "berry_seed_packet", "tilled_soil", "crop_stage_1", "crop_stage_2",
        "crop_stage_3", "wearable_leaf_clip", "furniture_prop", "generic_tool",
    ]
    for n in names:
        img = _draw_icon(n, pal, cell)
        img.save(out_dir / f"item_icon_{n}_{cell}px.png")
    # Contact sheet (gitignored review).
    s = args.scale
    cols = min(8, len(names))
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell * s + (cols + 1) * 4, rows * cell * s + (rows + 1) * 4), (40, 40, 48, 255))
    for i, n in enumerate(names):
        img = Image.open(out_dir / f"item_icon_{n}_{cell}px.png").convert("RGBA").resize((cell * s, cell * s), Image.NEAREST)
        x = i % cols
        y = i // cols
        sheet.paste(img, (4 + x * (cell * s + 4), 4 + y * (cell * s + 4)), img)
    sheet_name = "hearthvale_icon_preview_all.png" if args.all else "hearthvale_icon_preview.png"
    sheet.save(review_dir / sheet_name)
    log(f"generated {len(names)} original placeholder icons -> {out_dir.relative_to(ROOT)} (gitignored)")
    log(f"contact sheet -> {(review_dir / sheet_name).relative_to(ROOT)}")


if __name__ == "__main__":
    main()
