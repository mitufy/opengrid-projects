"""Parse annotation anchor metadata emitted by OpenSCAD models."""

from __future__ import annotations

from pathlib import Path
from typing import Mapping, Sequence


ANNOTATION_PREFIX = "OPENGRID_ANNOTATION_V1|"
ANNOTATION_METADATA_DEFINE = "emit_annotation_metadata=true"
AXES = ("x", "y", "z")


def with_annotation_metadata_define(defines: Sequence[str]) -> tuple[str, ...]:
    filtered = [define for define in defines if define.split("=", 1)[0].strip() != "emit_annotation_metadata"]
    return (*filtered, ANNOTATION_METADATA_DEFINE)


def _parse_vector(value: str) -> dict[str, float] | None:
    parts = [part.strip() for part in value.split(",")]
    if len(parts) != 3:
        return None
    try:
        values = [float(part) for part in parts]
    except ValueError:
        return None
    return {axis: values[index] for index, axis in enumerate(AXES)}


def _parse_vector_list(value: str) -> list[dict[str, float]] | None:
    vectors: list[dict[str, float]] = []
    for part in value.split(";"):
        vector = _parse_vector(part)
        if vector is None:
            return None
        vectors.append(vector)
    return vectors if vectors else None


def parse_scad_annotation_line(line: str) -> dict[str, object] | None:
    prefix_index = line.find(ANNOTATION_PREFIX)
    if prefix_index < 0:
        return None

    payload = line[prefix_index + len(ANNOTATION_PREFIX) :].strip()
    if payload.endswith('"') or payload.endswith("'"):
        payload = payload[:-1]

    fields: dict[str, str] = {}
    for part in payload.split("|"):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        key = key.strip()
        if key:
            fields[key] = value.strip()

    annotation_id = fields.get("id")
    if not annotation_id:
        return None

    parsed: dict[str, object] = {
        "schema": "OPENGRID_ANNOTATION_V1",
        "id": annotation_id,
        "kind": fields.get("kind", "feature"),
    }
    for key in ("label", "axis", "value", "values", "basis"):
        if key in fields:
            parsed[key] = fields[key]
    for key in ("start", "end", "anchor", "center", "edge"):
        if key in fields:
            vector = _parse_vector(fields[key])
            if vector is not None:
                parsed[f"{key}_mm"] = vector
    if "points" in fields:
        vectors = _parse_vector_list(fields["points"])
        if vectors is not None:
            parsed["points_mm"] = vectors
    return parsed


def read_scad_annotations(log_path: Path) -> tuple[dict[str, object], ...]:
    try:
        lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return ()
    return tuple(
        annotation
        for line in lines
        if (annotation := parse_scad_annotation_line(line)) is not None
    )


def numeric_context_from_scad_annotations(annotations: Sequence[Mapping[str, object]]) -> dict[str, float]:
    context: dict[str, float] = {}
    for annotation in annotations:
        if annotation.get("kind") != "context":
            continue
        values = annotation.get("values")
        if isinstance(values, str):
            for part in values.split(";"):
                if "=" not in part:
                    continue
                raw_name, raw_value = part.split("=", 1)
                name = raw_name.strip()
                if not name:
                    continue
                try:
                    context[name] = float(raw_value.strip())
                except ValueError:
                    continue
        name = annotation.get("id")
        value = annotation.get("value")
        if not isinstance(name, str) or not name.strip():
            continue
        try:
            context[name] = float(str(value).strip())
        except (TypeError, ValueError):
            continue
    return context


def find_scad_annotation(
    annotations: Sequence[Mapping[str, object]],
    annotation_id: str,
) -> Mapping[str, object] | None:
    for annotation in annotations:
        if annotation.get("id") == annotation_id and annotation.get("kind") != "context":
            return annotation
    return None


def annotation_to_dimension_segment(annotation: Mapping[str, object] | None) -> dict[str, object] | None:
    if annotation is None or annotation.get("kind") != "dimension":
        return None
    start = annotation.get("start_mm")
    end = annotation.get("end_mm")
    axis = annotation.get("axis")
    if not isinstance(start, Mapping) or not isinstance(end, Mapping) or axis not in AXES:
        return None
    try:
        start_mm = {axis_name: float(start[axis_name]) for axis_name in AXES}
        end_mm = {axis_name: float(end[axis_name]) for axis_name in AXES}
    except (KeyError, TypeError, ValueError):
        return None
    return {
        "axis": axis,
        "start_mm": start_mm,
        "end_mm": end_mm,
        "source": "scad_metadata",
        "basis": annotation.get("basis"),
    }


def annotation_to_radius_callout(annotation: Mapping[str, object] | None) -> dict[str, object] | None:
    if annotation is None or annotation.get("kind") != "radius":
        return None
    center = annotation.get("center_mm")
    edge = annotation.get("edge_mm")
    if not isinstance(center, Mapping) or not isinstance(edge, Mapping):
        return None
    try:
        center_mm = {axis_name: float(center[axis_name]) for axis_name in AXES}
        edge_mm = {axis_name: float(edge[axis_name]) for axis_name in AXES}
    except (KeyError, TypeError, ValueError):
        return None
    return {
        "center_mm": center_mm,
        "edge_mm": edge_mm,
        "source": "scad_metadata",
        "basis": annotation.get("basis"),
    }


def annotation_to_arc_callout(annotation: Mapping[str, object] | None) -> dict[str, object] | None:
    if annotation is None or annotation.get("kind") != "arc":
        return None
    points = annotation.get("points_mm")
    if not isinstance(points, Sequence) or isinstance(points, (str, bytes)) or len(points) < 2:
        return None
    parsed_points: list[dict[str, float]] = []
    try:
        for point in points:
            if not isinstance(point, Mapping):
                return None
            parsed_points.append({axis_name: float(point[axis_name]) for axis_name in AXES})
    except (KeyError, TypeError, ValueError):
        return None
    return {
        "points_mm": parsed_points,
        "source": "scad_metadata",
        "basis": annotation.get("basis"),
    }
