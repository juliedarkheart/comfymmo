#!/usr/bin/env python3
"""Build local collision-mask review data from LimeZu alpha masks.

This tool is intentionally commit-safe: it reads licensed PNGs from the local,
gitignored `licensed_assets/limezu/` tree and writes only local review/candidate
outputs back under that ignored tree. It never embeds image pixels in committed
code. The candidate JSON contains simplified point/rect data for human review.
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image


DEFAULT_ASSETS = {
    "object.barn": {
        "path": "modern_farm/normalized/spike/object_barn.png",
        "anchor": "bottom",
        "lower_body_ratio": 0.58,
        "kind": "polygon",
    },
    "object.tree": {
        "path": "modern_farm/normalized/spike/object_tree.png",
        "anchor": "bottom",
        "lower_body_ratio": 0.28,
        "kind": "circle_or_polygon",
    },
    "object.tree_small": {
        "path": "modern_farm/normalized/spike/object_tree_small.png",
        "anchor": "bottom",
        "lower_body_ratio": 0.32,
        "kind": "circle_or_polygon",
    },
    "object.fence_horizontal": {
        "path": "modern_farm/normalized/spike/object_fence_horizontal.png",
        "anchor": "bottom",
        "lower_body_ratio": 1.0,
        "kind": "line_or_rect",
    },
    "object.crate": {
        "path": "modern_farm/normalized/spike/object_crate.png",
        "anchor": "bottom",
        "lower_body_ratio": 0.85,
        "kind": "rect_or_polygon",
    },
    "object.sign": {
        "path": "modern_farm/normalized/spike/object_sign.png",
        "anchor": "bottom",
        "lower_body_ratio": 0.75,
        "kind": "rect_or_polygon",
    },
}


@dataclass(frozen=True)
class Bounds:
    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self) -> int:
        return self.right - self.left

    @property
    def height(self) -> int:
        return self.bottom - self.top

    def as_list(self) -> list[int]:
        return [self.left, self.top, self.right, self.bottom]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default="licensed_assets/limezu", help="Local gitignored LimeZu root")
    parser.add_argument("--alpha-threshold", type=int, default=8, help="Alpha value considered solid")
    parser.add_argument("--simplify-tolerance", type=float, default=2.5, help="RDP simplification tolerance in source pixels")
    parser.add_argument("--sample-step", type=int, default=2, help="Opaque envelope row sample step")
    parser.add_argument("--scale", type=float, default=2.0, help="Rendered scale for world-space candidate points")
    parser.add_argument(
        "--lower-body-only",
        action="store_true",
        default=True,
        help="Use configured lower-body ratios for tall sprites (default for the Hearthvale profile)",
    )
    parser.add_argument(
        "--full-body",
        action="store_false",
        dest="lower_body_only",
        help="Use the full opaque sprite bounds instead of lower-body collision candidates",
    )
    parser.add_argument(
        "--anchor-mode",
        choices=["bottom", "center", "tile_origin"],
        default="",
        help="Override per-asset anchor mode for candidate points",
    )
    parser.add_argument("--review", action="store_true", help="Write review report and candidate JSON")
    return parser.parse_args()


def alpha_bounds(img: Image.Image, threshold: int) -> Bounds | None:
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    raw = alpha.load()
    width, height = alpha.size
    min_x, min_y = width, height
    max_x, max_y = -1, -1
    for y in range(height):
        for x in range(width):
            if raw[x, y] >= threshold:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x < min_x or max_y < min_y:
        return None
    return Bounds(min_x, min_y, max_x + 1, max_y + 1)


def row_span(alpha, y: int, left: int, right: int, threshold: int) -> tuple[int, int] | None:
    xs = [x for x in range(left, right) if alpha[x, y] >= threshold]
    if not xs:
        return None
    return min(xs), max(xs) + 1


def point_line_distance(point: Sequence[float], start: Sequence[float], end: Sequence[float]) -> float:
    px, py = point
    sx, sy = start
    ex, ey = end
    dx, dy = ex - sx, ey - sy
    if dx == 0 and dy == 0:
        return math.hypot(px - sx, py - sy)
    t = max(0.0, min(1.0, ((px - sx) * dx + (py - sy) * dy) / (dx * dx + dy * dy)))
    cx, cy = sx + t * dx, sy + t * dy
    return math.hypot(px - cx, py - cy)


def rdp(points: list[list[float]], tolerance: float) -> list[list[float]]:
    if len(points) <= 2:
        return points
    start, end = points[0], points[-1]
    max_dist = -1.0
    index = 0
    for i in range(1, len(points) - 1):
        dist = point_line_distance(points[i], start, end)
        if dist > max_dist:
            max_dist = dist
            index = i
    if max_dist > tolerance:
        return rdp(points[: index + 1], tolerance)[:-1] + rdp(points[index:], tolerance)
    return [start, end]


def to_anchor_point(x: float, y: float, width: int, height: int, scale: float, anchor: str) -> list[float]:
    if anchor == "center":
        origin_x, origin_y = width * 0.5, height * 0.5
    elif anchor == "tile_origin":
        origin_x, origin_y = 0.0, 0.0
    else:
        origin_x, origin_y = width * 0.5, float(height)
    return [round((x - origin_x) * scale, 3), round((y - origin_y) * scale, 3)]


def envelope_polygon(
    img: Image.Image,
    bounds: Bounds,
    threshold: int,
    lower_body_ratio: float,
    step: int,
    tolerance: float,
    scale: float,
    anchor: str,
) -> list[list[float]]:
    alpha = img.convert("RGBA").getchannel("A").load()
    width, height = img.size
    crop_top = int(bounds.bottom - bounds.height * lower_body_ratio)
    crop_top = max(bounds.top, min(crop_top, bounds.bottom - 1))
    left_edge: list[list[float]] = []
    right_edge: list[list[float]] = []
    for y in range(crop_top, bounds.bottom, max(step, 1)):
        span = row_span(alpha, y, bounds.left, bounds.right, threshold)
        if span is None:
            continue
        left, right = span
        left_edge.append(to_anchor_point(left, y, width, height, scale, anchor))
        right_edge.append(to_anchor_point(right, y, width, height, scale, anchor))
    if not left_edge or not right_edge:
        return []
    points = left_edge + list(reversed(right_edge))
    simplified = rdp(points + [points[0]], tolerance * scale)
    if simplified and simplified[-1] == simplified[0]:
        simplified.pop()
    return simplified


def bbox_candidate(bounds: Bounds, img_size: tuple[int, int], scale: float, anchor: str) -> dict:
    width, height = img_size
    x1, y1 = to_anchor_point(bounds.left, bounds.top, width, height, scale, anchor)
    x2, y2 = to_anchor_point(bounds.right, bounds.bottom, width, height, scale, anchor)
    return {
        "offset": [round((x1 + x2) * 0.5, 3), round((y1 + y2) * 0.5, 3)],
        "size": [round(abs(x2 - x1), 3), round(abs(y2 - y1), 3)],
    }


def load_manifest_paths(root: Path) -> dict[str, str]:
    manifest_path = root / "limezu_active_manifest.json"
    if not manifest_path.exists():
        return {}
    parsed = json.loads(manifest_path.read_text(encoding="utf-8"))
    active = parsed.get("active", {})
    return {str(k): str(v) for k, v in active.items()} if isinstance(active, dict) else {}


def analyze_asset(root: Path, logical_id: str, config: dict, manifest: dict[str, str], args: argparse.Namespace) -> dict:
    rel = manifest.get(logical_id, config["path"])
    path = root / rel
    anchor = args.anchor_mode or str(config.get("anchor", "bottom"))
    configured_lower_body_ratio = float(config.get("lower_body_ratio", 1.0))
    lower_body_ratio = configured_lower_body_ratio if args.lower_body_only else 1.0
    record = {
        "id": logical_id,
        "source": str(path),
        "exists": path.exists(),
        "kind": config.get("kind", "polygon"),
        "anchor": anchor,
        "lower_body_ratio": lower_body_ratio,
        "lower_body_only": bool(args.lower_body_only),
        "warnings": [],
    }
    if not path.exists():
        record["warnings"].append("source missing")
        return record
    with Image.open(path) as img:
        bounds = alpha_bounds(img, args.alpha_threshold)
        record["source_size"] = list(img.size)
        if bounds is None:
            record["warnings"].append("no opaque pixels at threshold")
            return record
        record["opaque_bounds"] = bounds.as_list()
        polygon = envelope_polygon(
            img,
            bounds,
            args.alpha_threshold,
            lower_body_ratio,
            args.sample_step,
            args.simplify_tolerance,
            args.scale,
            anchor,
        )
        record["candidate_polygon"] = polygon
        record["candidate_point_count"] = len(polygon)
        record["candidate_rect"] = bbox_candidate(bounds, img.size, args.scale, anchor)
        if len(polygon) < 3:
            record["warnings"].append("polygon candidate has fewer than 3 points")
        if len(polygon) > 24:
            record["warnings"].append("polygon candidate still high-detail; increase simplify tolerance")
    return record


def write_review(root: Path, records: Iterable[dict]) -> None:
    masks_dir = root / "collision_masks"
    review_dir = root / "collision_review"
    masks_dir.mkdir(parents=True, exist_ok=True)
    review_dir.mkdir(parents=True, exist_ok=True)
    for directory in [masks_dir, review_dir]:
        (directory / ".gdignore").write_text("Local LimeZu collision review output. Do not import.\n", encoding="utf-8")
    records_list = list(records)
    (masks_dir / "collision_candidates.json").write_text(
        json.dumps({"assets": records_list}, indent=2),
        encoding="utf-8",
    )
    lines = ["# LimeZu Collision Mask Review", ""]
    for record in records_list:
        lines.append(f"## {record['id']}")
        lines.append(f"- source: `{record['source']}`")
        lines.append(f"- exists: {record['exists']}")
        if "source_size" in record:
            lines.append(f"- source_size: {record['source_size']}")
        if "opaque_bounds" in record:
            lines.append(f"- opaque_bounds: {record['opaque_bounds']}")
        lines.append(f"- kind: {record['kind']}")
        lines.append(f"- anchor: {record['anchor']}")
        lines.append(f"- lower_body_only: {record['lower_body_only']}")
        lines.append(f"- lower_body_ratio: {record['lower_body_ratio']}")
        lines.append(f"- simplified_points: {record.get('candidate_point_count', 0)}")
        warnings = record.get("warnings", [])
        lines.append(f"- warnings: {', '.join(warnings) if warnings else 'none'}")
        lines.append("")
    (review_dir / "collision_review.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    manifest = load_manifest_paths(root)
    records = [
        analyze_asset(root, logical_id, config, manifest, args)
        for logical_id, config in DEFAULT_ASSETS.items()
    ]
    if args.review:
        write_review(root, records)
    failures = [r for r in records if not r.get("exists")]
    print(f"[limezu-collision] analyzed {len(records)} asset(s); missing={len(failures)}")
    for record in records:
        print(
            f"[limezu-collision] {record['id']}: points={record.get('candidate_point_count', 0)} "
            f"bounds={record.get('opaque_bounds', 'n/a')} warnings={record.get('warnings', [])}"
        )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
