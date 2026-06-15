"""Annotation config normalization and collection helpers."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Mapping, Sequence

from annotation_renderer.config_defaults import DEFAULT_LINE_COLORS
from annotation_renderer.config_resolution import (
    add_vectors,
    aliases_from_config,
    annotation_label,
    annotation_parameter_type,
    label_overrides_from_config,
    mapping_vector,
    resolve_style,
    type_line_color,
    vector2,
    vector3,
)
from annotation_renderer.config_schema import ConfigError
from annotation_renderer.scad_annotations import (
    annotation_to_arc_callout,
    annotation_to_dimension_segment,
    annotation_to_radius_callout,
    find_scad_annotation,
)


@dataclass(frozen=True)
class DimensionSegment:
    id: str
    label: str
    value: str
    start_mm: tuple[float, float, float]
    end_mm: tuple[float, float, float]
    color: str
    parameter_type: str = "mm"
    source_start_mm: tuple[float, float, float] | None = None
    source_end_mm: tuple[float, float, float] | None = None


@dataclass(frozen=True)
class RadiusCallout:
    id: str
    label: str
    value: str
    center_mm: tuple[float, float, float]
    edge_mm: tuple[float, float, float]
    color: str
    parameter_type: str


@dataclass(frozen=True)
class ArcCallout:
    id: str
    label: str
    value: str
    points_mm: tuple[tuple[float, float, float], ...]
    color: str
    parameter_type: str


@dataclass(frozen=True)
class AngleRadiusCallout:
    id: str
    angle_label: str
    angle_value: str
    radius_label: str
    radius_value: str
    center_mm: tuple[float, float, float]
    edge_mm: tuple[float, float, float]
    points_mm: tuple[tuple[float, float, float], ...]
    arc_color: str
    radius_color: str
    angle_type: str
    radius_type: str


@dataclass(frozen=True)
class ImageLabel:
    id: str
    label: str
    value_text: str | None
    position: str
    offset_px: tuple[float, float]
    angle_deg: float
    color: str | None
    value_color: str | None
    font_size_px: int | None


def annotation_group_is_optional(config: Mapping[str, object]) -> bool:
    return bool(config.get("optional", False))


@dataclass(frozen=True)
class AnnotationGroupContext:
    offset: tuple[float, float, float]
    colors: Mapping[str, object]
    show_values: bool
    label_overrides: Mapping[str, object]
    optional: bool


def annotation_ids_from_group(group_config: Mapping[str, object], *, message: str) -> Sequence[object]:
    ids = group_config.get("ids")
    if not isinstance(ids, Sequence) or isinstance(ids, (str, bytes)) or not ids:
        raise ConfigError(message)
    return ids


def annotation_group_context(
    *,
    group_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None,
    aliases: Mapping[str, object] | None,
) -> AnnotationGroupContext:
    colors = style_config.get("colors", {})
    if not isinstance(colors, Mapping):
        colors = {}
    return AnnotationGroupContext(
        offset=vector3(
            group_config.get("display_offset_mm"),
            default=(0.0, 0.0, 0.0),
            name="display_offset_mm",
            context=expression_context,
        ),
        colors=colors,
        show_values=bool(style_config.get("show_values", False)),
        label_overrides=label_overrides_from_config(group_config, aliases),
        optional=annotation_group_is_optional(group_config),
    )


def collect_dimension_chain(
    *,
    annotations: Sequence[Mapping[str, object]],
    chain_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None = None,
    aliases: Mapping[str, object] | None = None,
) -> list[DimensionSegment]:
    ids = annotation_ids_from_group(
        chain_config,
        message="dimension chain requires a non-empty ids list",
    )
    context = annotation_group_context(
        group_config=chain_config,
        style_config=style_config,
        expression_context=expression_context,
        aliases=aliases,
    )
    aligned = len(ids) > 1

    segments: list[DimensionSegment] = []
    for index, annotation_id in enumerate(ids):
        annotation_key = str(annotation_id)
        annotation = find_scad_annotation(annotations, annotation_key)
        segment = annotation_to_dimension_segment(annotation)
        if annotation is None or segment is None:
            if context.optional:
                continue
            raise ConfigError(f"No emitted dimension annotation named {annotation_id!r}")
        parameter_type = annotation_parameter_type(annotation_key, kind="dimension")
        fallback_color = str(context.colors.get(annotation_key, DEFAULT_LINE_COLORS.get(annotation_key, "#2f7f8f")))
        color = (
            type_line_color(style_config, parameter_type, index=index, fallback=fallback_color)
            if aligned
            else str(context.colors.get(annotation_key) or type_line_color(style_config, parameter_type, fallback=fallback_color))
        )
        source_start_mm = mapping_vector(segment["start_mm"])
        source_end_mm = mapping_vector(segment["end_mm"])
        segments.append(
            DimensionSegment(
                id=annotation_key,
                label=annotation_label(annotation, override=context.label_overrides.get(annotation_key), show_value=context.show_values),
                value=str(annotation.get("value", "")),
                start_mm=add_vectors(source_start_mm, context.offset),
                end_mm=add_vectors(source_end_mm, context.offset),
                color=color,
                parameter_type=parameter_type,
                source_start_mm=source_start_mm,
                source_end_mm=source_end_mm,
            )
        )
    return segments


def collect_radius_callouts(
    *,
    annotations: Sequence[Mapping[str, object]],
    callout_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None = None,
    aliases: Mapping[str, object] | None = None,
) -> list[RadiusCallout]:
    ids = annotation_ids_from_group(
        callout_config,
        message="radius callout requires a non-empty ids list",
    )
    context = annotation_group_context(
        group_config=callout_config,
        style_config=style_config,
        expression_context=expression_context,
        aliases=aliases,
    )

    callouts: list[RadiusCallout] = []
    for annotation_id in ids:
        annotation = find_scad_annotation(annotations, str(annotation_id))
        callout = annotation_to_radius_callout(annotation)
        if annotation is None or callout is None:
            if context.optional:
                continue
            raise ConfigError(f"No emitted radius annotation named {annotation_id!r}")
        annotation_key = str(annotation_id)
        parameter_type = annotation_parameter_type(annotation_key, kind="radius")
        fallback_color = DEFAULT_LINE_COLORS.get(annotation_key, "#8b6f2f")
        color = str(context.colors.get(annotation_key) or type_line_color(style_config, parameter_type, fallback=fallback_color))
        callouts.append(
            RadiusCallout(
                id=annotation_key,
                label=annotation_label(annotation, override=context.label_overrides.get(annotation_key), show_value=context.show_values),
                value=str(annotation.get("value", "")),
                center_mm=add_vectors(mapping_vector(callout["center_mm"]), context.offset),
                edge_mm=add_vectors(mapping_vector(callout["edge_mm"]), context.offset),
                color=color,
                parameter_type=parameter_type,
            )
        )
    return callouts


def collect_arc_callouts(
    *,
    annotations: Sequence[Mapping[str, object]],
    callout_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None = None,
    aliases: Mapping[str, object] | None = None,
) -> list[ArcCallout]:
    ids = annotation_ids_from_group(
        callout_config,
        message="arc callout requires a non-empty ids list",
    )
    context = annotation_group_context(
        group_config=callout_config,
        style_config=style_config,
        expression_context=expression_context,
        aliases=aliases,
    )

    callouts: list[ArcCallout] = []
    for annotation_id in ids:
        annotation = find_scad_annotation(annotations, str(annotation_id))
        callout = annotation_to_arc_callout(annotation)
        if annotation is None or callout is None:
            if context.optional:
                continue
            raise ConfigError(f"No emitted arc annotation named {annotation_id!r}")
        annotation_key = str(annotation_id)
        parameter_type = annotation_parameter_type(annotation_key, kind="arc")
        fallback_color = DEFAULT_LINE_COLORS.get(annotation_key, "#8b6f2f")
        color = str(context.colors.get(annotation_key) or type_line_color(style_config, parameter_type, fallback=fallback_color))
        points = tuple(add_vectors(mapping_vector(point), context.offset) for point in callout["points_mm"])
        callouts.append(
            ArcCallout(
                id=annotation_key,
                label=annotation_label(annotation, override=context.label_overrides.get(annotation_key), show_value=context.show_values),
                value=str(annotation.get("value", "")),
                points_mm=points,
                color=color,
                parameter_type=parameter_type,
            )
        )
    return callouts


def collect_angle_radius_callouts(
    *,
    annotations: Sequence[Mapping[str, object]],
    callout_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None = None,
    aliases: Mapping[str, object] | None = None,
) -> list[AngleRadiusCallout]:
    arc_id = str(callout_config.get("arc_id", "")).strip()
    radius_id = str(callout_config.get("radius_id", "")).strip()
    angle_id = str(callout_config.get("angle_id") or arc_id).strip()
    if not arc_id or not radius_id:
        raise ConfigError("angle radius callout requires arc_id and radius_id")

    context = annotation_group_context(
        group_config=callout_config,
        style_config=style_config,
        expression_context=expression_context,
        aliases=aliases,
    )

    radius_annotation = find_scad_annotation(annotations, radius_id)
    radius_callout = annotation_to_radius_callout(radius_annotation)
    if radius_annotation is None or radius_callout is None:
        if context.optional:
            return []
        raise ConfigError(f"No emitted radius annotation named {radius_id!r}")
    arc_annotation = find_scad_annotation(annotations, arc_id)
    arc_callout = annotation_to_arc_callout(arc_annotation)
    if arc_annotation is None or arc_callout is None:
        if context.optional:
            return []
        raise ConfigError(f"No emitted arc annotation named {arc_id!r}")

    angle_value = ""
    if expression_context is not None and angle_id in expression_context:
        angle_value = format_context_value(expression_context[angle_id])
    elif "value" in arc_annotation:
        angle_value = str(arc_annotation.get("value", ""))

    angle_base_label = str(context.label_overrides.get(angle_id) or context.label_overrides.get(arc_id) or angle_id)
    angle_label = f"{angle_base_label} = {angle_value}" if context.show_values and angle_value else angle_base_label
    radius_label = annotation_label(
        radius_annotation,
        override=context.label_overrides.get(radius_id),
        show_value=context.show_values,
    )
    callout_id = str(callout_config.get("id") or f"{angle_id}_{radius_id}").strip()
    angle_type = annotation_parameter_type(angle_id, kind="arc")
    radius_type = annotation_parameter_type(radius_id, kind="radius")
    arc_fallback = str(context.colors.get(angle_id) or context.colors.get(arc_id) or DEFAULT_LINE_COLORS.get(angle_id) or DEFAULT_LINE_COLORS.get(arc_id) or "#8b6f2f")
    radius_fallback = str(context.colors.get(radius_id) or DEFAULT_LINE_COLORS.get(radius_id) or arc_fallback)
    arc_color = type_line_color(style_config, angle_type, fallback=arc_fallback)
    radius_color = type_line_color(style_config, radius_type, fallback=radius_fallback)

    return [
        AngleRadiusCallout(
            id=callout_id,
            angle_label=angle_label,
            angle_value=angle_value,
            radius_label=radius_label,
            radius_value=str(radius_annotation.get("value", "")),
            center_mm=add_vectors(mapping_vector(radius_callout["center_mm"]), context.offset),
            edge_mm=add_vectors(mapping_vector(radius_callout["edge_mm"]), context.offset),
            points_mm=tuple(add_vectors(mapping_vector(point), context.offset) for point in arc_callout["points_mm"]),
            arc_color=arc_color,
            radius_color=radius_color,
            angle_type=angle_type,
            radius_type=radius_type,
        )
    ]


def format_context_value(value: object) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, float):
        return f"{value:g}"
    return str(value)


def model_define_value(
    config: Mapping[str, object],
    label_id: str,
    *,
    expression_context: Mapping[str, float] | None = None,
) -> str:
    model = config.get("model", {})
    defines = model.get("defines", {}) if isinstance(model, Mapping) else {}
    if isinstance(defines, Mapping) and label_id in defines:
        value = defines[label_id]
        if isinstance(value, str):
            return value.strip('"')
        if isinstance(value, bool):
            return "true" if value else "false"
        return str(value)
    if expression_context is not None and label_id in expression_context:
        return format_context_value(expression_context[label_id])
    return ""


def collect_image_labels(
    *,
    config: Mapping[str, object],
    labels_config: Sequence[Mapping[str, object]],
    annotation_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None = None,
) -> list[ImageLabel]:
    aliases = aliases_from_config(annotation_config)
    show_values_default = bool(style_config.get("show_values", False))
    labels: list[ImageLabel] = []
    for index, label_config in enumerate(labels_config):
        label_id = str(label_config.get("id") or f"image_label_{index}")
        explicit_text = label_config.get("text")
        if isinstance(explicit_text, str) and explicit_text.strip():
            label_text = explicit_text
            value_text = None
        else:
            label_text = str(label_config.get("label") or aliases.get(label_id) or label_id)
            value = str(
                label_config.get("value")
                or model_define_value(config, label_id, expression_context=expression_context)
            ).strip()
            show_value = bool(label_config.get("show_value", show_values_default))
            value_text = value if show_value and value else None
            if show_value and value:
                label_text = f"{label_text} = {value}"
        font_size = label_config.get("font_size_px")
        labels.append(
            ImageLabel(
                id=label_id,
                label=label_text,
                value_text=value_text,
                position=str(label_config.get("position", "bottom")),
                offset_px=vector2(
                    label_config.get("offset_px"),
                    default=(0.0, 0.0),
                    name=f"image_labels[{index}].offset_px",
                    context=expression_context,
                ),
                angle_deg=float(label_config.get("angle_deg", 0.0)),
                color=str(label_config["color"]) if "color" in label_config and label_config["color"] is not None else None,
                value_color=str(label_config["value_color"])
                if "value_color" in label_config and label_config["value_color"] is not None
                else None,
                font_size_px=int(font_size) if font_size is not None else None,
            )
        )
    return labels


def projection_points_for_segments(segments: Sequence[DimensionSegment]) -> dict[str, list[float]]:
    points: dict[str, list[float]] = {}
    for segment in segments:
        points[f"{segment.id}.start"] = list(segment.start_mm)
        points[f"{segment.id}.end"] = list(segment.end_mm)
        points[f"{segment.id}.source_start"] = list(segment.source_start_mm or segment.start_mm)
        points[f"{segment.id}.source_end"] = list(segment.source_end_mm or segment.end_mm)
    return points


def projection_points_for_radius_callouts(callouts: Sequence[RadiusCallout]) -> dict[str, list[float]]:
    points: dict[str, list[float]] = {}
    for callout in callouts:
        points[f"{callout.id}.center"] = list(callout.center_mm)
        points[f"{callout.id}.edge"] = list(callout.edge_mm)
    return points


def projection_points_for_arc_callouts(callouts: Sequence[ArcCallout]) -> dict[str, list[float]]:
    points: dict[str, list[float]] = {}
    for callout in callouts:
        for index, point in enumerate(callout.points_mm):
            points[f"{callout.id}.points.{index}"] = list(point)
    return points


def projection_points_for_angle_radius_callouts(callouts: Sequence[AngleRadiusCallout]) -> dict[str, list[float]]:
    points: dict[str, list[float]] = {}
    for callout in callouts:
        points[f"{callout.id}.center"] = list(callout.center_mm)
        points[f"{callout.id}.edge"] = list(callout.edge_mm)
        for index, point in enumerate(callout.points_mm):
            points[f"{callout.id}.points.{index}"] = list(point)
    return points

