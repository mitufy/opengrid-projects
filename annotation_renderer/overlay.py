"""Pillow overlay drawing for projected annotation dimensions."""

from __future__ import annotations

from dataclasses import dataclass
from math import atan2, degrees
from pathlib import Path
from typing import Mapping, Sequence

from PIL import Image, ImageColor, ImageDraw, ImageFont

from annotation_renderer.config import (
    DEFAULT_LINE_ALPHA,
    AngleRadiusCallout,
    ArcCallout,
    DimensionSegment,
    ImageLabel,
    RadiusCallout,
)


LABEL_TEXT_COLOR = "#18212b"
LABEL_OUTLINE_COLOR = "#f8fafc"
LABEL_OUTLINE_WIDTH = 2


def clamp_alpha(value: int) -> int:
    return max(0, min(255, int(value)))


def load_font(size: int):
    candidates = [
        Path(r"C:\Windows\Fonts\bahnschrift.ttf"),
        Path(r"C:\Windows\Fonts\segoeuisb.ttf"),
        Path(r"C:\Windows\Fonts\arialbd.ttf"),
        Path(r"C:\Windows\Fonts\segoeuib.ttf"),
        Path(r"C:\Windows\Fonts\calibrib.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


def rotated_label_image(
    *,
    text: str,
    angle_deg: float,
    text_color: str,
    font_size_px: int,
    outline_color: str,
    outline_width_px: int,
) -> Image.Image:
    font = load_font(font_size_px)
    scratch = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    scratch_draw = ImageDraw.Draw(scratch)
    bbox = scratch_draw.textbbox((0, 0), text, font=font, stroke_width=outline_width_px)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    padding = max(2, round(font_size_px * 0.2))
    label = Image.new("RGBA", (width + padding * 2, height + padding * 2), (0, 0, 0, 0))
    label_draw = ImageDraw.Draw(label)
    label_draw.text(
        (padding, padding - bbox[1]),
        text,
        fill=ImageColor.getrgb(text_color),
        font=font,
        stroke_width=outline_width_px,
        stroke_fill=ImageColor.getrgb(outline_color),
    )
    return label.rotate(-angle_deg, resample=Image.Resampling.BICUBIC, expand=True)


def label_bbox(center: tuple[float, float], size: tuple[int, int]) -> tuple[float, float, float, float]:
    return (
        center[0] - size[0] / 2.0,
        center[1] - size[1] / 2.0,
        center[0] + size[0] / 2.0,
        center[1] + size[1] / 2.0,
    )


def expanded_bbox(bbox: tuple[float, float, float, float], padding: float) -> tuple[float, float, float, float]:
    return (bbox[0] - padding, bbox[1] - padding, bbox[2] + padding, bbox[3] + padding)


def segment_bbox(
    point_a: Sequence[float],
    point_b: Sequence[float],
    *,
    padding: float = 0.0,
) -> tuple[float, float, float, float]:
    return (
        min(float(point_a[0]), float(point_b[0])) - padding,
        min(float(point_a[1]), float(point_b[1])) - padding,
        max(float(point_a[0]), float(point_b[0])) + padding,
        max(float(point_a[1]), float(point_b[1])) + padding,
    )


def polyline_bboxes(
    points: Sequence[Sequence[float]],
    *,
    padding: float = 0.0,
) -> list[tuple[float, float, float, float]]:
    return [
        segment_bbox(start, end, padding=padding)
        for start, end in zip(points, points[1:])
    ]


def overlap_area(left: tuple[float, float, float, float], right: tuple[float, float, float, float]) -> float:
    overlap_width = max(0.0, min(left[2], right[2]) - max(left[0], right[0]))
    overlap_height = max(0.0, min(left[3], right[3]) - max(left[1], right[1]))
    return overlap_width * overlap_height


def clamp_label_center(
    center: tuple[float, float],
    size: tuple[int, int],
    image_size: tuple[int, int],
    *,
    margin_px: float = 8.0,
) -> tuple[float, float]:
    half_width = size[0] / 2.0
    half_height = size[1] / 2.0
    min_x = margin_px + half_width
    max_x = image_size[0] - margin_px - half_width
    min_y = margin_px + half_height
    max_y = image_size[1] - margin_px - half_height
    if min_x > max_x:
        x = image_size[0] / 2.0
    else:
        x = min(max(center[0], min_x), max_x)
    if min_y > max_y:
        y = image_size[1] / 2.0
    else:
        y = min(max(center[1], min_y), max_y)
    return (x, y)


def place_label(
    *,
    preferred_center: tuple[float, float],
    label_size: tuple[int, int],
    image_size: tuple[int, int],
    occupied: list[tuple[float, float, float, float]],
    shift_axes: Sequence[tuple[float, float]],
    margin_px: float = 8.0,
) -> tuple[tuple[float, float], tuple[float, float, float, float]]:
    offsets = (0.0, 14.0, -14.0, 28.0, -28.0, 46.0, -46.0, 70.0, -70.0, 96.0, -96.0, 128.0, -128.0)
    raw_candidates = [preferred_center]
    units: list[tuple[float, float]] = []
    for axis in shift_axes:
        axis_length = (axis[0] ** 2 + axis[1] ** 2) ** 0.5
        if axis_length <= 1e-6:
            continue
        unit = (axis[0] / axis_length, axis[1] / axis_length)
        units.append(unit)
        raw_candidates.extend(
            (
                preferred_center[0] + unit[0] * offset,
                preferred_center[1] + unit[1] * offset,
            )
            for offset in offsets[1:]
        )
    if len(units) >= 2:
        combo_offsets = (28.0, -28.0, 46.0, -46.0, 70.0, -70.0, 96.0, -96.0)
        first, second = units[0], units[1]
        raw_candidates.extend(
            (
                preferred_center[0] + first[0] * first_offset + second[0] * second_offset,
                preferred_center[1] + first[1] * first_offset + second[1] * second_offset,
            )
            for first_offset in combo_offsets
            for second_offset in combo_offsets
        )

    best_center = preferred_center
    best_bbox = label_bbox(preferred_center, label_size)
    best_score = float("inf")
    for candidate in raw_candidates:
        center = clamp_label_center(candidate, label_size, image_size, margin_px=margin_px)
        bbox = label_bbox(center, label_size)
        padded_bbox = expanded_bbox(bbox, 3.0)
        overlap = sum(overlap_area(padded_bbox, other) for other in occupied)
        displacement = ((center[0] - preferred_center[0]) ** 2 + (center[1] - preferred_center[1]) ** 2) ** 0.5
        clamp_displacement = ((center[0] - candidate[0]) ** 2 + (center[1] - candidate[1]) ** 2) ** 0.5
        score = overlap * 20.0 + displacement + clamp_displacement * 3.0
        if score < best_score:
            best_score = score
            best_center = center
            best_bbox = bbox
            if overlap <= 0.0 and clamp_displacement <= 0.0:
                break

    occupied.append(expanded_bbox(best_bbox, 3.0))
    return best_center, best_bbox


@dataclass(frozen=True)
class DimensionChainOverlaySpec:
    segments: Sequence[DimensionSegment]
    line_offset_px: float
    label_offset_px: float
    style_config: Mapping[str, object]


def draw_rotated_label(
    image: Image.Image,
    *,
    text: str,
    center: tuple[float, float],
    angle_deg: float,
    text_color: str,
    font_size_px: int,
    outline_color: str,
    outline_width_px: int,
) -> None:
    rotated = rotated_label_image(
        text=text,
        angle_deg=angle_deg,
        text_color=text_color,
        font_size_px=font_size_px,
        outline_color=outline_color,
        outline_width_px=outline_width_px,
    )
    image.alpha_composite(rotated, (int(center[0] - rotated.width / 2), int(center[1] - rotated.height / 2)))


def draw_dimension_chain_overlay(
    *,
    render_path: Path,
    output_path: Path,
    projection: Mapping[str, object],
    segments: Sequence[DimensionSegment],
    line_offset_px: float,
    label_offset_px: float,
    style_config: Mapping[str, object],
) -> dict[str, object]:
    overlays = draw_dimension_chains_overlay(
        render_path=render_path,
        output_path=output_path,
        projection=projection,
        chains=[
            DimensionChainOverlaySpec(
                segments=segments,
                line_offset_px=line_offset_px,
                label_offset_px=label_offset_px,
                style_config=style_config,
            )
        ],
    )
    return overlays[0]


def draw_dimension_chains_overlay(
    *,
    render_path: Path,
    output_path: Path,
    projection: Mapping[str, object],
    chains: Sequence[DimensionChainOverlaySpec],
) -> list[dict[str, object]]:
    if not chains:
        raise ValueError("At least one dimension chain is required")
    image = Image.open(render_path).convert("RGBA")
    projected = projection["projection"]

    scale = 4
    overlay = Image.new("RGBA", (image.width * scale, image.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    def scaled_point(point: Sequence[float]) -> tuple[int, int]:
        return (round(float(point[0]) * scale), round(float(point[1]) * scale))

    def scaled_width(width: float) -> int:
        return max(1, round(width * scale))

    def draw_segment(point_a: Sequence[float], point_b: Sequence[float], *, width: float, fill: tuple[int, int, int, int]) -> None:
        draw.line((scaled_point(point_a), scaled_point(point_b)), fill=fill, width=scaled_width(width))

    def draw_dashed_segment(
        point_a: Sequence[float],
        point_b: Sequence[float],
        *,
        width: float,
        fill: tuple[int, int, int, int],
        dash_px: float,
        gap_px: float,
    ) -> None:
        vector = (float(point_b[0]) - float(point_a[0]), float(point_b[1]) - float(point_a[1]))
        length = (vector[0] ** 2 + vector[1] ** 2) ** 0.5
        if length <= 1e-6:
            return
        direction = (vector[0] / length, vector[1] / length)
        cursor = 0.0
        dash = max(1.0, float(dash_px))
        gap = max(0.0, float(gap_px))
        while cursor < length:
            dash_end = min(cursor + dash, length)
            start = (float(point_a[0]) + direction[0] * cursor, float(point_a[1]) + direction[1] * cursor)
            end = (float(point_a[0]) + direction[0] * dash_end, float(point_a[1]) + direction[1] * dash_end)
            draw_segment(start, end, width=width, fill=fill)
            cursor = dash_end + gap

    prepared_chains: list[dict[str, object]] = []
    for spec in chains:
        segments = spec.segments
        if not segments:
            raise ValueError("At least one dimension segment is required")

        points: list[tuple[float, float]] = []
        points.append(tuple(float(value) for value in projected[f"{segments[0].id}.start"]["px"]))
        for segment in segments:
            points.append(tuple(float(value) for value in projected[f"{segment.id}.end"]["px"]))

        full_vector = (points[-1][0] - points[0][0], points[-1][1] - points[0][1])
        full_length = (full_vector[0] ** 2 + full_vector[1] ** 2) ** 0.5
        if full_length <= 1e-6:
            raise ValueError("Projected dimension chain collapsed to a zero-length segment")
        direction = (full_vector[0] / full_length, full_vector[1] / full_length)
        normal = (-direction[1], direction[0])
        offset = (normal[0] * spec.line_offset_px, normal[1] * spec.line_offset_px)
        baseline_points = [(point[0] + offset[0], point[1] + offset[1]) for point in points]

        style_config = spec.style_config
        line_alpha = clamp_alpha(int(style_config.get("line_alpha", DEFAULT_LINE_ALPHA)))
        tick_length_px = float(style_config.get("tick_length_px", 18.0))
        angle = degrees(atan2(direction[1], direction[0]))
        if angle > 90.0 or angle < -90.0:
            angle += 180.0

        prepared_chains.append(
            {
                "segments": segments,
                "points": points,
                "baseline_points": baseline_points,
                "normal": normal,
                "line_alpha": line_alpha,
                "line_width_px": float(style_config.get("line_width_px", 3.0)),
                "extension_width_px": float(style_config.get("extension_width_px", 1.7)),
                "extension_visible": bool(style_config.get("extension_visible", True)),
                "extension_dash_px": float(style_config.get("extension_dash_px", 6.0)),
                "extension_gap_px": float(style_config.get("extension_gap_px", 4.0)),
                "tick": (normal[0] * tick_length_px, normal[1] * tick_length_px),
                "label_font_size_px": int(style_config.get("label_font_size_px", 28)),
                "label_color": str(style_config.get("label_color", LABEL_TEXT_COLOR)),
                "label_outline_color": str(style_config.get("label_outline_color", LABEL_OUTLINE_COLOR)),
                "label_outline_width_px": int(style_config.get("label_outline_width_px", LABEL_OUTLINE_WIDTH)),
                "label_offset_px": spec.label_offset_px,
                "angle": angle,
            }
        )

    for chain in prepared_chains:
        if not chain["extension_visible"]:
            continue
        for point, baseline_point in zip(chain["points"], chain["baseline_points"]):
            draw_dashed_segment(
                point,
                baseline_point,
                width=5.0,
                fill=(255, 255, 255, clamp_alpha(min(190, max(130, int(chain["line_alpha"]) + 26)))),
                dash_px=float(chain["extension_dash_px"]),
                gap_px=float(chain["extension_gap_px"]),
            )

    for chain in prepared_chains:
        if not chain["extension_visible"]:
            continue
        segments = chain["segments"]
        for index, (point, baseline_point) in enumerate(zip(chain["points"], chain["baseline_points"])):
            segment = segments[min(index, len(segments) - 1)]
            extension = (*ImageColor.getrgb(segment.color)[:3], clamp_alpha(max(95, int(chain["line_alpha"]) - 42)))
            draw_dashed_segment(
                point,
                baseline_point,
                width=float(chain["extension_width_px"]),
                fill=extension,
                dash_px=float(chain["extension_dash_px"]),
                gap_px=float(chain["extension_gap_px"]),
            )

    for chain in prepared_chains:
        halo = (255, 255, 255, clamp_alpha(min(190, max(130, int(chain["line_alpha"]) + 26))))
        baseline_points = chain["baseline_points"]
        tick = chain["tick"]
        for start, end in zip(baseline_points, baseline_points[1:]):
            draw_segment(start, end, width=6.5, fill=halo)
        for point in baseline_points:
            draw_segment((point[0] - tick[0], point[1] - tick[1]), (point[0] + tick[0], point[1] + tick[1]), width=6.5, fill=halo)

    for chain in prepared_chains:
        segments = chain["segments"]
        baseline_points = chain["baseline_points"]
        tick = chain["tick"]
        line_alpha = int(chain["line_alpha"])
        for index, segment in enumerate(segments):
            color = (*ImageColor.getrgb(segment.color)[:3], line_alpha)
            draw_segment(baseline_points[index], baseline_points[index + 1], width=float(chain["line_width_px"]), fill=color)
        for index, point in enumerate(baseline_points):
            segment = segments[min(index, len(segments) - 1)]
            color = (*ImageColor.getrgb(segment.color)[:3], clamp_alpha(min(210, line_alpha + 22)))
            draw_segment((point[0] - tick[0], point[1] - tick[1]), (point[0] + tick[0], point[1] + tick[1]), width=float(chain["line_width_px"]), fill=color)

    overlay = overlay.resize(image.size, resample=Image.Resampling.LANCZOS)
    image.alpha_composite(overlay)

    chain_metadata = []
    occupied_labels: list[tuple[float, float, float, float]] = []
    for chain in prepared_chains:
        normal = chain["normal"]
        direction = (
            (chain["baseline_points"][-1][0] - chain["baseline_points"][0][0]),
            (chain["baseline_points"][-1][1] - chain["baseline_points"][0][1]),
        )
        text_offset = (normal[0] * float(chain["label_offset_px"]), normal[1] * float(chain["label_offset_px"]))
        baseline_points = chain["baseline_points"]
        text_metadata = {}
        for index, segment in enumerate(chain["segments"]):
            midpoint = (
                (baseline_points[index][0] + baseline_points[index + 1][0]) / 2.0,
                (baseline_points[index][1] + baseline_points[index + 1][1]) / 2.0,
            )
            preferred_center = (midpoint[0] + text_offset[0], midpoint[1] + text_offset[1])
            label_image = rotated_label_image(
                text=segment.label,
                angle_deg=float(chain["angle"]),
                text_color=str(chain["label_color"]),
                font_size_px=int(chain["label_font_size_px"]),
                outline_color=str(chain["label_outline_color"]),
                outline_width_px=int(chain["label_outline_width_px"]),
            )
            center, bbox = place_label(
                preferred_center=preferred_center,
                label_size=label_image.size,
                image_size=image.size,
                occupied=occupied_labels,
                shift_axes=[normal, direction],
            )
            draw_rotated_label(
                image,
                text=segment.label,
                center=center,
                angle_deg=float(chain["angle"]),
                text_color=str(chain["label_color"]),
                font_size_px=int(chain["label_font_size_px"]),
                outline_color=str(chain["label_outline_color"]),
                outline_width_px=int(chain["label_outline_width_px"]),
            )
            text_metadata[segment.id] = {
                "center_px": {"x": round(center[0], 2), "y": round(center[1], 2)},
                "angle_deg": round(float(chain["angle"]), 2),
                "bbox_px": {
                    "left": round(bbox[0], 2),
                    "top": round(bbox[1], 2),
                    "right": round(bbox[2], 2),
                    "bottom": round(bbox[3], 2),
                },
            }

        chain_metadata.append(
            {
                "baseline_points_px": [
                    {"x": round(point[0], 2), "y": round(point[1], 2)}
                    for point in baseline_points
                ],
                "extension_visible": bool(chain["extension_visible"]),
                "text": text_metadata,
            }
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path)
    return chain_metadata


def draw_radius_callout_overlay(
    *,
    render_path: Path,
    output_path: Path,
    projection: Mapping[str, object],
    callouts: Sequence[RadiusCallout],
    label_offset_px: float,
    style_config: Mapping[str, object],
) -> dict[str, object]:
    if not callouts:
        raise ValueError("At least one radius callout is required")
    image = Image.open(render_path).convert("RGBA")
    projected = projection["projection"]

    scale = 4
    overlay = Image.new("RGBA", (image.width * scale, image.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    def scaled_point(point: Sequence[float]) -> tuple[int, int]:
        return (round(float(point[0]) * scale), round(float(point[1]) * scale))

    def scaled_width(width: float) -> int:
        return max(1, round(width * scale))

    def draw_segment(point_a: Sequence[float], point_b: Sequence[float], *, width: float, fill: tuple[int, int, int, int]) -> None:
        draw.line((scaled_point(point_a), scaled_point(point_b)), fill=fill, width=scaled_width(width))

    def draw_dashed_segment(
        point_a: Sequence[float],
        point_b: Sequence[float],
        *,
        width: float,
        fill: tuple[int, int, int, int],
        dash_px: float,
        gap_px: float,
    ) -> None:
        vector = (float(point_b[0]) - float(point_a[0]), float(point_b[1]) - float(point_a[1]))
        length = (vector[0] ** 2 + vector[1] ** 2) ** 0.5
        if length <= 1e-6:
            return
        direction = (vector[0] / length, vector[1] / length)
        dash = max(dash_px, 1.0)
        gap = max(gap_px, 0.0)
        position = 0.0
        while position < length:
            next_position = min(position + dash, length)
            start = (float(point_a[0]) + direction[0] * position, float(point_a[1]) + direction[1] * position)
            end = (float(point_a[0]) + direction[0] * next_position, float(point_a[1]) + direction[1] * next_position)
            draw_segment(start, end, width=width, fill=fill)
            position += dash + gap

    line_alpha = clamp_alpha(int(style_config.get("line_alpha", DEFAULT_LINE_ALPHA)))
    line_width_px = float(style_config.get("line_width_px", 3.0))
    tick_length_px = float(style_config.get("tick_length_px", 18.0))
    label_font_size_px = int(style_config.get("label_font_size_px", 28))
    label_color = str(style_config.get("label_color", LABEL_TEXT_COLOR))
    label_outline_color = str(style_config.get("label_outline_color", LABEL_OUTLINE_COLOR))
    label_outline_width_px = int(style_config.get("label_outline_width_px", LABEL_OUTLINE_WIDTH))

    halo = (255, 255, 255, clamp_alpha(min(190, max(130, line_alpha + 26))))
    text_metadata = {}
    callout_metadata = {}
    occupied_labels: list[tuple[float, float, float, float]] = []

    for callout in callouts:
        center = tuple(float(value) for value in projected[f"{callout.id}.center"]["px"])
        edge = tuple(float(value) for value in projected[f"{callout.id}.edge"]["px"])
        vector = (edge[0] - center[0], edge[1] - center[1])
        length = (vector[0] ** 2 + vector[1] ** 2) ** 0.5
        if length <= 1e-6:
            raise ValueError(f"Projected radius callout {callout.id!r} collapsed to a zero-length segment")
        direction = (vector[0] / length, vector[1] / length)
        normal = (-direction[1], direction[0])
        arc_gap = min(max(10.0, line_width_px * 4.0), length * 0.35)
        leader_end = (
            edge[0] - direction[0] * arc_gap,
            edge[1] - direction[1] * arc_gap,
        )

        dash_px = max(line_width_px * 5.0, 14.0)
        gap_px = max(line_width_px * 3.2, 9.0)
        draw_dashed_segment(center, leader_end, width=line_width_px + 3.5, fill=halo, dash_px=dash_px, gap_px=gap_px)

        color = (*ImageColor.getrgb(callout.color)[:3], line_alpha)
        draw_dashed_segment(center, leader_end, width=line_width_px, fill=color, dash_px=dash_px, gap_px=gap_px)
        center_radius = max(2, round(line_width_px * 1.15 * scale))
        scaled_center = scaled_point(center)
        draw.ellipse(
            (
                scaled_center[0] - center_radius,
                scaled_center[1] - center_radius,
                scaled_center[0] + center_radius,
                scaled_center[1] + center_radius,
            ),
            fill=color,
        )

        angle = degrees(atan2(direction[1], direction[0]))
        if angle > 90.0 or angle < -90.0:
            angle += 180.0
        label_anchor = (
            center[0] + vector[0] * 0.58,
            center[1] + vector[1] * 0.58,
        )
        preferred_label_center = (
            label_anchor[0] + normal[0] * label_offset_px,
            label_anchor[1] + normal[1] * label_offset_px,
        )
        label_image = rotated_label_image(
            text=callout.label,
            angle_deg=angle,
            text_color=label_color,
            font_size_px=label_font_size_px,
            outline_color=label_outline_color,
            outline_width_px=label_outline_width_px,
        )
        label_center, label_bbox_px = place_label(
            preferred_center=preferred_label_center,
            label_size=label_image.size,
            image_size=image.size,
            occupied=occupied_labels,
            shift_axes=[normal, direction],
        )
        overlay = overlay.resize(image.size, resample=Image.Resampling.LANCZOS)
        image.alpha_composite(overlay)
        overlay = Image.new("RGBA", (image.width * scale, image.height * scale), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)

        draw_rotated_label(
            image,
            text=callout.label,
            center=label_center,
            angle_deg=angle,
            text_color=label_color,
            font_size_px=label_font_size_px,
            outline_color=label_outline_color,
            outline_width_px=label_outline_width_px,
        )
        text_metadata[callout.id] = {
            "center_px": {"x": round(label_center[0], 2), "y": round(label_center[1], 2)},
            "angle_deg": round(angle, 2),
            "bbox_px": {
                "left": round(label_bbox_px[0], 2),
                "top": round(label_bbox_px[1], 2),
                "right": round(label_bbox_px[2], 2),
                "bottom": round(label_bbox_px[3], 2),
            },
        }
        callout_metadata[callout.id] = {
            "center_px": {"x": round(center[0], 2), "y": round(center[1], 2)},
            "edge_px": {"x": round(edge[0], 2), "y": round(edge[1], 2)},
            "leader_end_px": {"x": round(leader_end[0], 2), "y": round(leader_end[1], 2)},
        }

    if overlay.getbbox() is not None:
        overlay = overlay.resize(image.size, resample=Image.Resampling.LANCZOS)
        image.alpha_composite(overlay)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path)
    return {
        "radius_callouts": callout_metadata,
        "text": text_metadata,
    }


def draw_arc_callout_overlay(
    *,
    render_path: Path,
    output_path: Path,
    projection: Mapping[str, object],
    callouts: Sequence[ArcCallout],
    label_offset_px: float,
    show_label: bool,
    style_config: Mapping[str, object],
) -> dict[str, object]:
    if not callouts:
        raise ValueError("At least one arc callout is required")
    image = Image.open(render_path).convert("RGBA")
    projected = projection["projection"]

    scale = 4
    overlay = Image.new("RGBA", (image.width * scale, image.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    def scaled_point(point: Sequence[float]) -> tuple[int, int]:
        return (round(float(point[0]) * scale), round(float(point[1]) * scale))

    def scaled_width(width: float) -> int:
        return max(1, round(width * scale))

    def draw_polyline(points: Sequence[Sequence[float]], *, width: float, fill: tuple[int, int, int, int]) -> None:
        if len(points) < 2:
            return
        draw.line([scaled_point(point) for point in points], fill=fill, width=scaled_width(width), joint="curve")

    def draw_segment(point_a: Sequence[float], point_b: Sequence[float], *, width: float, fill: tuple[int, int, int, int]) -> None:
        draw.line((scaled_point(point_a), scaled_point(point_b)), fill=fill, width=scaled_width(width))

    line_alpha = clamp_alpha(int(style_config.get("line_alpha", DEFAULT_LINE_ALPHA)))
    line_width_px = float(style_config.get("line_width_px", 3.0))
    tick_length_px = float(style_config.get("tick_length_px", 18.0))
    label_font_size_px = int(style_config.get("label_font_size_px", 28))
    label_color = str(style_config.get("label_color", LABEL_TEXT_COLOR))
    label_outline_color = str(style_config.get("label_outline_color", LABEL_OUTLINE_COLOR))
    label_outline_width_px = int(style_config.get("label_outline_width_px", LABEL_OUTLINE_WIDTH))

    halo = (255, 255, 255, clamp_alpha(min(190, max(130, line_alpha + 26))))
    text_metadata = {}
    callout_metadata = {}
    occupied_labels: list[tuple[float, float, float, float]] = []

    for callout in callouts:
        points = [
            tuple(float(value) for value in projected[f"{callout.id}.points.{index}"]["px"])
            for index in range(len(callout.points_mm))
        ]
        if len(points) < 2:
            raise ValueError(f"Projected arc callout {callout.id!r} needs at least two points")
        color = (*ImageColor.getrgb(callout.color)[:3], line_alpha)
        draw_polyline(points, width=line_width_px + 3.5, fill=halo)
        draw_polyline(points, width=line_width_px, fill=color)

        for endpoint, neighbor in ((points[0], points[1]), (points[-1], points[-2])):
            tangent = (endpoint[0] - neighbor[0], endpoint[1] - neighbor[1])
            length = (tangent[0] ** 2 + tangent[1] ** 2) ** 0.5
            if length <= 1e-6:
                continue
            normal = (-tangent[1] / length, tangent[0] / length)
            tick = (normal[0] * tick_length_px * 0.35, normal[1] * tick_length_px * 0.35)
            draw_segment(
                (endpoint[0] - tick[0], endpoint[1] - tick[1]),
                (endpoint[0] + tick[0], endpoint[1] + tick[1]),
                width=line_width_px + 3.5,
                fill=halo,
            )
            draw_segment(
                (endpoint[0] - tick[0], endpoint[1] - tick[1]),
                (endpoint[0] + tick[0], endpoint[1] + tick[1]),
                width=line_width_px,
                fill=(*ImageColor.getrgb(callout.color)[:3], clamp_alpha(min(210, line_alpha + 22))),
            )

        mid_index = len(points) // 2
        before = points[max(0, mid_index - 1)]
        after = points[min(len(points) - 1, mid_index + 1)]
        tangent = (after[0] - before[0], after[1] - before[1])
        length = (tangent[0] ** 2 + tangent[1] ** 2) ** 0.5
        if length <= 1e-6:
            raise ValueError(f"Projected arc callout {callout.id!r} has no usable midpoint tangent")
        direction = (tangent[0] / length, tangent[1] / length)
        normal = (-direction[1], direction[0])
        midpoint = points[mid_index]
        preferred_label_center = (
            midpoint[0] + normal[0] * label_offset_px,
            midpoint[1] + normal[1] * label_offset_px,
        )
        angle = degrees(atan2(direction[1], direction[0]))
        if angle > 90.0 or angle < -90.0:
            angle += 180.0
        if show_label:
            label_image = rotated_label_image(
                text=callout.label,
                angle_deg=angle,
                text_color=label_color,
                font_size_px=label_font_size_px,
                outline_color=label_outline_color,
                outline_width_px=label_outline_width_px,
            )
            label_center, label_bbox_px = place_label(
                preferred_center=preferred_label_center,
                label_size=label_image.size,
                image_size=image.size,
                occupied=occupied_labels,
                shift_axes=[normal, direction],
            )
            text_metadata[callout.id] = {
                "center_px": {"x": round(label_center[0], 2), "y": round(label_center[1], 2)},
                "angle_deg": round(angle, 2),
                "bbox_px": {
                    "left": round(label_bbox_px[0], 2),
                    "top": round(label_bbox_px[1], 2),
                    "right": round(label_bbox_px[2], 2),
                    "bottom": round(label_bbox_px[3], 2),
                },
            }
        callout_metadata[callout.id] = {
            "points_px": [{"x": round(point[0], 2), "y": round(point[1], 2)} for point in points],
        }

    overlay = overlay.resize(image.size, resample=Image.Resampling.LANCZOS)
    image.alpha_composite(overlay)
    for callout in (callouts if show_label else ()):
        text = text_metadata[callout.id]
        draw_rotated_label(
            image,
            text=callout.label,
            center=(float(text["center_px"]["x"]), float(text["center_px"]["y"])),
            angle_deg=float(text["angle_deg"]),
            text_color=label_color,
            font_size_px=label_font_size_px,
            outline_color=label_outline_color,
            outline_width_px=label_outline_width_px,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path)
    return {
        "arc_callouts": callout_metadata,
        "text": text_metadata,
    }


def draw_angle_radius_callout_overlay(
    *,
    render_path: Path,
    output_path: Path,
    projection: Mapping[str, object],
    callouts: Sequence[AngleRadiusCallout],
    angle_label_offset_px: float,
    radius_label_offset_px: float,
    show_angle_label: bool,
    show_radius_label: bool,
    style_config: Mapping[str, object],
) -> dict[str, object]:
    if not callouts:
        raise ValueError("At least one angle/radius callout is required")
    image = Image.open(render_path).convert("RGBA")
    projected = projection["projection"]

    scale = 4
    overlay = Image.new("RGBA", (image.width * scale, image.height * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    def scaled_point(point: Sequence[float]) -> tuple[int, int]:
        return (round(float(point[0]) * scale), round(float(point[1]) * scale))

    def scaled_width(width: float) -> int:
        return max(1, round(width * scale))

    def draw_segment(point_a: Sequence[float], point_b: Sequence[float], *, width: float, fill: tuple[int, int, int, int]) -> None:
        draw.line((scaled_point(point_a), scaled_point(point_b)), fill=fill, width=scaled_width(width))

    def draw_polyline(points: Sequence[Sequence[float]], *, width: float, fill: tuple[int, int, int, int]) -> None:
        if len(points) < 2:
            return
        draw.line([scaled_point(point) for point in points], fill=fill, width=scaled_width(width), joint="curve")

    def draw_dashed_segment(
        point_a: Sequence[float],
        point_b: Sequence[float],
        *,
        width: float,
        fill: tuple[int, int, int, int],
        dash_px: float,
        gap_px: float,
    ) -> None:
        vector = (float(point_b[0]) - float(point_a[0]), float(point_b[1]) - float(point_a[1]))
        length = (vector[0] ** 2 + vector[1] ** 2) ** 0.5
        if length <= 1e-6:
            return
        direction = (vector[0] / length, vector[1] / length)
        dash = max(1.0, float(dash_px))
        gap = max(0.0, float(gap_px))
        cursor = 0.0
        while cursor < length:
            dash_end = min(cursor + dash, length)
            start = (float(point_a[0]) + direction[0] * cursor, float(point_a[1]) + direction[1] * cursor)
            end = (float(point_a[0]) + direction[0] * dash_end, float(point_a[1]) + direction[1] * dash_end)
            draw_segment(start, end, width=width, fill=fill)
            cursor = dash_end + gap

    line_alpha = clamp_alpha(int(style_config.get("line_alpha", DEFAULT_LINE_ALPHA)))
    line_width_px = float(style_config.get("line_width_px", 3.0))
    radial_width_px = float(style_config.get("radial_line_width_px", line_width_px))
    radial_dash_px = float(style_config.get("radial_dash_px", max(line_width_px * 5.0, 14.0)))
    radial_gap_px = float(style_config.get("radial_gap_px", max(line_width_px * 3.2, 9.0)))
    label_font_size_px = int(style_config.get("label_font_size_px", 28))
    label_color = str(style_config.get("label_color", LABEL_TEXT_COLOR))
    label_outline_color = str(style_config.get("label_outline_color", LABEL_OUTLINE_COLOR))
    label_outline_width_px = int(style_config.get("label_outline_width_px", LABEL_OUTLINE_WIDTH))
    angle_fill_alpha = clamp_alpha(int(style_config.get("angle_fill_alpha", 30)))
    angle_fill_color = str(style_config.get("angle_fill_color", "#d9ead3"))
    label_avoidance_padding_px = float(style_config.get("label_avoidance_padding_px", max(8.0, line_width_px * 3.0)))

    text_metadata = {}
    callout_metadata = {}
    occupied_labels: list[tuple[float, float, float, float]] = []

    for callout in callouts:
        center = tuple(float(value) for value in projected[f"{callout.id}.center"]["px"])
        radius_edge = tuple(float(value) for value in projected[f"{callout.id}.edge"]["px"])
        points = [
            tuple(float(value) for value in projected[f"{callout.id}.points.{index}"]["px"])
            for index in range(len(callout.points_mm))
        ]
        if len(points) < 2:
            raise ValueError(f"Projected angle/radius callout {callout.id!r} needs at least two arc points")

        start = points[0]
        end = points[-1]
        arc_color = (*ImageColor.getrgb(callout.arc_color)[:3], line_alpha)
        radial_color = (*ImageColor.getrgb(callout.radius_color)[:3], clamp_alpha(max(110, line_alpha - 24)))
        halo = (255, 255, 255, clamp_alpha(min(180, max(120, line_alpha + 18))))
        arc_occupied = polyline_bboxes(points, padding=label_avoidance_padding_px)
        radius_vector = (radius_edge[0] - center[0], radius_edge[1] - center[1])
        radius_length = (radius_vector[0] ** 2 + radius_vector[1] ** 2) ** 0.5
        if radius_length <= 1e-6:
            raise ValueError(f"Projected angle/radius callout {callout.id!r} collapsed to a zero-length radius")
        radius_direction = (radius_vector[0] / radius_length, radius_vector[1] / radius_length)
        arc_gap = min(max(10.0, line_width_px * 4.0), radius_length * 0.35)
        radius_leader_end = (
            radius_edge[0] - radius_direction[0] * arc_gap,
            radius_edge[1] - radius_direction[1] * arc_gap,
        )
        visible_radius_vector = (radius_leader_end[0] - center[0], radius_leader_end[1] - center[1])
        visible_radius_length = (visible_radius_vector[0] ** 2 + visible_radius_vector[1] ** 2) ** 0.5
        if visible_radius_length <= 1e-6:
            visible_radius_vector = radius_vector
            visible_radius_length = radius_length

        if angle_fill_alpha > 0:
            draw.polygon(
                [scaled_point(center), *(scaled_point(point) for point in points)],
                fill=(*ImageColor.getrgb(angle_fill_color)[:3], angle_fill_alpha),
            )

        draw_dashed_segment(
            center,
            radius_leader_end,
            width=line_width_px + 3.5,
            fill=halo,
            dash_px=radial_dash_px,
            gap_px=radial_gap_px,
        )
        draw_dashed_segment(
            center,
            radius_leader_end,
            width=radial_width_px,
            fill=radial_color,
            dash_px=radial_dash_px,
            gap_px=radial_gap_px,
        )

        draw_polyline(points, width=line_width_px + 3.2, fill=halo)
        draw_polyline(points, width=line_width_px, fill=arc_color)

        dot_radius = max(2, round((line_width_px * 1.05) * scale))
        for dot_point, dot_color in ((center, radial_color), (start, arc_color), (end, arc_color)):
            scaled = scaled_point(dot_point)
            draw.ellipse(
                (
                    scaled[0] - dot_radius,
                    scaled[1] - dot_radius,
                    scaled[0] + dot_radius,
                    scaled[1] + dot_radius,
                ),
                fill=dot_color,
            )

        mid_index = len(points) // 2
        midpoint = points[mid_index]
        before = points[max(0, mid_index - 1)]
        after = points[min(len(points) - 1, mid_index + 1)]
        arc_tangent = (after[0] - before[0], after[1] - before[1])
        arc_length = (arc_tangent[0] ** 2 + arc_tangent[1] ** 2) ** 0.5
        if arc_length <= 1e-6:
            raise ValueError(f"Projected angle/radius callout {callout.id!r} has no usable arc tangent")
        arc_direction = (arc_tangent[0] / arc_length, arc_tangent[1] / arc_length)
        center_to_mid = (midpoint[0] - center[0], midpoint[1] - center[1])
        center_to_mid_length = (center_to_mid[0] ** 2 + center_to_mid[1] ** 2) ** 0.5
        arc_normal = (
            center_to_mid[0] / center_to_mid_length,
            center_to_mid[1] / center_to_mid_length,
        ) if center_to_mid_length > 1e-6 else (-arc_direction[1], arc_direction[0])

        angle_text_angle = degrees(atan2(arc_direction[1], arc_direction[0]))
        if angle_text_angle > 90.0 or angle_text_angle < -90.0:
            angle_text_angle += 180.0
        if show_angle_label:
            angle_label_image = rotated_label_image(
                text=callout.angle_label,
                angle_deg=angle_text_angle,
                text_color=label_color,
                font_size_px=label_font_size_px,
                outline_color=label_outline_color,
                outline_width_px=label_outline_width_px,
            )
            preferred_angle_center = (
                midpoint[0] + arc_normal[0] * angle_label_offset_px,
                midpoint[1] + arc_normal[1] * angle_label_offset_px,
            )
            angle_center, angle_bbox = place_label(
                preferred_center=preferred_angle_center,
                label_size=angle_label_image.size,
                image_size=image.size,
                occupied=occupied_labels,
                shift_axes=[arc_normal, arc_direction],
            )
            text_metadata[f"{callout.id}.angle"] = {
                "center_px": {"x": round(angle_center[0], 2), "y": round(angle_center[1], 2)},
                "angle_deg": round(angle_text_angle, 2),
                "bbox_px": {
                    "left": round(angle_bbox[0], 2),
                    "top": round(angle_bbox[1], 2),
                    "right": round(angle_bbox[2], 2),
                    "bottom": round(angle_bbox[3], 2),
                },
            }
        else:
            angle_center = None

        radius_vector = visible_radius_vector
        radius_length = visible_radius_length
        radius_direction = (radius_vector[0] / radius_length, radius_vector[1] / radius_length)
        radius_normal = (-radius_direction[1], radius_direction[0])
        radius_text_angle = degrees(atan2(radius_direction[1], radius_direction[0]))
        if radius_text_angle > 90.0 or radius_text_angle < -90.0:
            radius_text_angle += 180.0
        if show_radius_label:
            radius_label_image = rotated_label_image(
                text=callout.radius_label,
                angle_deg=radius_text_angle,
                text_color=label_color,
                font_size_px=label_font_size_px,
                outline_color=label_outline_color,
                outline_width_px=label_outline_width_px,
            )
            radius_anchor = (
                center[0] + radius_vector[0] * 0.58,
                center[1] + radius_vector[1] * 0.58,
            )
            preferred_radius_center = (
                radius_anchor[0] + radius_normal[0] * radius_label_offset_px,
                radius_anchor[1] + radius_normal[1] * radius_label_offset_px,
            )
            radius_occupied = [*occupied_labels, *arc_occupied]
            radius_center, radius_bbox = place_label(
                preferred_center=preferred_radius_center,
                label_size=radius_label_image.size,
                image_size=image.size,
                occupied=radius_occupied,
                shift_axes=[radius_normal, radius_direction],
            )
            occupied_labels.append(expanded_bbox(radius_bbox, 3.0))
            text_metadata[f"{callout.id}.radius"] = {
                "center_px": {"x": round(radius_center[0], 2), "y": round(radius_center[1], 2)},
                "angle_deg": round(radius_text_angle, 2),
                "bbox_px": {
                    "left": round(radius_bbox[0], 2),
                    "top": round(radius_bbox[1], 2),
                    "right": round(radius_bbox[2], 2),
                    "bottom": round(radius_bbox[3], 2),
                },
            }
        else:
            radius_center = None

        callout_metadata[callout.id] = {
            "center_px": {"x": round(center[0], 2), "y": round(center[1], 2)},
            "radius_edge_px": {"x": round(radius_edge[0], 2), "y": round(radius_edge[1], 2)},
            "radius_leader_end_px": {"x": round(radius_leader_end[0], 2), "y": round(radius_leader_end[1], 2)},
            "points_px": [{"x": round(point[0], 2), "y": round(point[1], 2)} for point in points],
        }

    overlay = overlay.resize(image.size, resample=Image.Resampling.LANCZOS)
    image.alpha_composite(overlay)

    for callout in callouts:
        angle_text = text_metadata.get(f"{callout.id}.angle")
        if angle_text is not None:
            draw_rotated_label(
                image,
                text=callout.angle_label,
                center=(float(angle_text["center_px"]["x"]), float(angle_text["center_px"]["y"])),
                angle_deg=float(angle_text["angle_deg"]),
                text_color=label_color,
                font_size_px=label_font_size_px,
                outline_color=label_outline_color,
                outline_width_px=label_outline_width_px,
            )
        radius_text = text_metadata.get(f"{callout.id}.radius")
        if radius_text is not None:
            draw_rotated_label(
                image,
                text=callout.radius_label,
                center=(float(radius_text["center_px"]["x"]), float(radius_text["center_px"]["y"])),
                angle_deg=float(radius_text["angle_deg"]),
                text_color=label_color,
                font_size_px=label_font_size_px,
                outline_color=label_outline_color,
                outline_width_px=label_outline_width_px,
            )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path)
    return {
        "angle_radius_callouts": callout_metadata,
        "text": text_metadata,
    }


def image_label_center(image: Image.Image, *, position: str, offset_px: Sequence[float], margin_px: float) -> tuple[float, float]:
    positions = {
        "top": (image.width / 2.0, margin_px),
        "bottom": (image.width / 2.0, image.height - margin_px),
        "left": (margin_px, image.height / 2.0),
        "right": (image.width - margin_px, image.height / 2.0),
        "center": (image.width / 2.0, image.height / 2.0),
        "top_left": (margin_px, margin_px),
        "top_right": (image.width - margin_px, margin_px),
        "bottom_left": (margin_px, image.height - margin_px),
        "bottom_right": (image.width - margin_px, image.height - margin_px),
    }
    base = positions.get(position, positions["bottom"])
    return (base[0] + float(offset_px[0]), base[1] + float(offset_px[1]))


def draw_image_label_overlay(
    *,
    render_path: Path,
    output_path: Path,
    labels: Sequence[ImageLabel],
    style_config: Mapping[str, object],
) -> dict[str, object]:
    if not labels:
        raise ValueError("At least one image label is required")
    image = Image.open(render_path).convert("RGBA")
    label_color = str(style_config.get("label_color", LABEL_TEXT_COLOR))
    label_outline_color = str(style_config.get("label_outline_color", LABEL_OUTLINE_COLOR))
    label_outline_width_px = int(style_config.get("label_outline_width_px", LABEL_OUTLINE_WIDTH))
    label_font_size_px = int(style_config.get("label_font_size_px", 28))
    margin_px = float(style_config.get("image_label_margin_px", 42))

    metadata = {}
    occupied_labels: list[tuple[float, float, float, float]] = []
    for label in labels:
        preferred_center = image_label_center(image, position=label.position, offset_px=label.offset_px, margin_px=margin_px)
        font_size = label.font_size_px or label_font_size_px
        label_image = rotated_label_image(
            text=label.label,
            angle_deg=label.angle_deg,
            text_color=label.color or label_color,
            font_size_px=font_size,
            outline_color=label_outline_color,
            outline_width_px=label_outline_width_px,
        )
        if label.position.startswith("top"):
            shift_axes = [(0.0, 1.0), (1.0, 0.0)]
        elif label.position.startswith("bottom"):
            shift_axes = [(0.0, -1.0), (1.0, 0.0)]
        elif label.position == "left":
            shift_axes = [(1.0, 0.0), (0.0, 1.0)]
        elif label.position == "right":
            shift_axes = [(-1.0, 0.0), (0.0, 1.0)]
        else:
            shift_axes = [(0.0, 1.0), (1.0, 0.0)]
        center, bbox = place_label(
            preferred_center=preferred_center,
            label_size=label_image.size,
            image_size=image.size,
            occupied=occupied_labels,
            shift_axes=shift_axes,
        )
        draw_rotated_label(
            image,
            text=label.label,
            center=center,
            angle_deg=label.angle_deg,
            text_color=label.color or label_color,
            font_size_px=font_size,
            outline_color=label_outline_color,
            outline_width_px=label_outline_width_px,
        )
        metadata[label.id] = {
            "center_px": {"x": round(center[0], 2), "y": round(center[1], 2)},
            "angle_deg": round(label.angle_deg, 2),
            "position": label.position,
            "label": label.label,
            "bbox_px": {
                "left": round(bbox[0], 2),
                "top": round(bbox[1], 2),
                "right": round(bbox[2], 2),
                "bottom": round(bbox[3], 2),
            },
        }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output_path)
    return {"image_labels": metadata}
