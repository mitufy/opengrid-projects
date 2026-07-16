"""Render metadata serialization and lightweight quality checks."""

from __future__ import annotations

from pathlib import Path
from typing import Mapping, Sequence

from annotation_renderer.openscad import project_relative_or_absolute


def overlay_bbox_from_metadata(value: object) -> tuple[float, float, float, float] | None:
    if not isinstance(value, Mapping):
        return None
    bbox = value.get("bbox_px")
    if not isinstance(bbox, Mapping):
        return None
    try:
        return (
            float(bbox["left"]),
            float(bbox["top"]),
            float(bbox["right"]),
            float(bbox["bottom"]),
        )
    except (KeyError, TypeError, ValueError):
        return None


def iter_overlay_label_bboxes(value: object, *, path: str = "overlay") -> list[tuple[str, tuple[float, float, float, float]]]:
    bboxes: list[tuple[str, tuple[float, float, float, float]]] = []
    bbox = overlay_bbox_from_metadata(value)
    if bbox is not None:
        bboxes.append((path, bbox))
    if isinstance(value, Mapping):
        for key, item in value.items():
            if key in {"bbox_px", "title_area", "title_areas"}:
                continue
            bboxes.extend(iter_overlay_label_bboxes(item, path=f"{path}.{key}"))
    elif isinstance(value, Sequence) and not isinstance(value, (str, bytes)):
        for index, item in enumerate(value):
            bboxes.extend(iter_overlay_label_bboxes(item, path=f"{path}[{index}]"))
    return bboxes


def bbox_overlap_area(left: tuple[float, float, float, float], right: tuple[float, float, float, float]) -> float:
    width = max(0.0, min(left[2], right[2]) - max(left[0], right[0]))
    height = max(0.0, min(left[3], right[3]) - max(left[1], right[1]))
    return width * height


def overlay_quality_warnings(overlays: Mapping[str, object], *, max_warnings: int = 10) -> list[str]:
    labels = iter_overlay_label_bboxes(overlays)
    warnings: list[str] = []
    for left_index, (left_name, left_bbox) in enumerate(labels):
        for right_name, right_bbox in labels[left_index + 1 :]:
            area = bbox_overlap_area(left_bbox, right_bbox)
            if area <= 25.0:
                continue
            warnings.append(f"label overlap: {left_name} and {right_name} overlap by {area:.0f}px^2")
            if len(warnings) >= max_warnings:
                return warnings
    return warnings


def annotation_bounds_quality_warnings(object_records: Sequence[Mapping[str, object]], *, max_warnings: int = 10) -> list[str]:
    warnings: list[str] = []
    for record in object_records:
        audit = record.get("annotation_bounds_audit")
        if not isinstance(audit, Mapping):
            continue
        audit_warnings = audit.get("warnings")
        if not isinstance(audit_warnings, Sequence) or isinstance(audit_warnings, (str, bytes)):
            continue
        for warning in audit_warnings:
            warnings.append(f"object {record['id']}: {warning}")
            if len(warnings) >= max_warnings:
                return warnings
    return warnings


def build_render_metadata(
    *,
    job_name: str,
    output_mode: str,
    config_path: Path,
    expression_context: Mapping[str, float],
    blend_file: Path,
    scene_config: Mapping[str, object],
    object_records: Sequence[Mapping[str, object]],
    blender_config: Mapping[str, object],
    style_config: Mapping[str, object],
    annotation_state: Mapping[str, object],
    projection: Mapping[str, object],
    overlays: Mapping[str, object],
    output_dir: Path,
    run_dir: Path,
    render_path: Path,
    annotated_path: Path,
    metadata_path: Path,
    export_blend_path: Path | None,
    animation_path: Path | None,
    animation_frame_dir: Path | None,
    projection_path: Path,
    blender_log: Path,
    openscad_commands: Mapping[str, Sequence[str]],
    blender_command: Sequence[str],
    cache_info: Mapping[str, object],
) -> dict[str, object]:
    return {
        "job_name": job_name,
        "output_mode": output_mode,
        "config": project_relative_or_absolute(config_path),
        "cache": dict(cache_info),
        "constants": expression_context,
        "scene": {
            "blend_file": str(blend_file),
            "camera": scene_config.get("camera"),
            "objects": [
                {
                    "id": str(record["id"]),
                    "target_object": str(record["target_object"]),
                    "source_type": str(record.get("source_type") or "model"),
                    "scad_file": (
                        project_relative_or_absolute(Path(record["scad_file"]))
                        if record.get("scad_file") is not None
                        else None
                    ),
                    "stl_file": (
                        project_relative_or_absolute(Path(record["stl_file"]))
                        if record.get("stl_file") is not None
                        else None
                    ),
                    "defines": list(record["defines"]),
                    "expression_context": record["expression_context"],
                    "scad_context": record["scad_context"],
                    "inherit_target_transform": bool(record["inherit_target_transform"]),
                    "transform": record["transform"],
                    "transform_config": record["object_scene_config"].get("transform"),
                    "replace_target_object": bool(record["replace_target_object"]),
                    "material_source_object": record.get("material_source_object"),
                    "material": record.get("material"),
                    "stl_bounds_mm": record.get("stl_bounds_mm"),
                    "annotation_bounds_audit": record.get("annotation_bounds_audit"),
                    "cache": record.get("cache"),
                }
                for record in object_records
            ],
        },
        "render": blender_config,
        "style": style_config,
        "annotation_object": annotation_state["annotation_object_id"],
        "scad_annotations": annotation_state["scad_annotations"],
        "warnings": list(overlays.get("warnings", [])) if isinstance(overlays.get("warnings"), Sequence) else [],
        "chains": [
            [
                {
                    "id": segment.id,
                    "label": segment.label,
                    "start_mm": list(segment.start_mm),
                    "end_mm": list(segment.end_mm),
                    "color": segment.color,
                    "parameter_type": segment.parameter_type,
                }
                for segment in chain_segments
            ]
            for chain_segments in annotation_state["active_chains"]
        ],
        "radius_callouts": [
            [
                {
                    "id": callout.id,
                    "label": callout.label,
                    "center_mm": list(callout.center_mm),
                    "edge_mm": list(callout.edge_mm),
                    "color": callout.color,
                }
                for callout in radius_callouts
            ]
            for radius_callouts in annotation_state["active_radius_groups"]
        ],
        "arc_callouts": [
            [
                {
                    "id": callout.id,
                    "label": callout.label,
                    "points_mm": [list(point) for point in callout.points_mm],
                    "color": callout.color,
                }
                for callout in arc_callouts
            ]
            for arc_callouts in annotation_state["active_arc_groups"]
        ],
        "angle_radius_callouts": [
            [
                {
                    "id": callout.id,
                    "angle_label": callout.angle_label,
                    "radius_label": callout.radius_label,
                    "center_mm": list(callout.center_mm),
                    "edge_mm": list(callout.edge_mm),
                    "points_mm": [list(point) for point in callout.points_mm],
                    "arc_color": callout.arc_color,
                    "radius_color": callout.radius_color,
                }
                for callout in angle_radius_callouts
            ]
            for angle_radius_callouts in annotation_state["active_angle_radius_groups"]
        ],
        "image_labels": [
            {
                "id": label.id,
                "label": label.label,
                "position": label.position,
                "offset_px": list(label.offset_px),
                "angle_deg": label.angle_deg,
                "title_area": label.title_area,
            }
            for label in annotation_state["image_labels"]
        ],
        "projection": projection,
        "overlay": dict(overlays),
        "paths": {
            "output_dir": project_relative_or_absolute(output_dir),
            "debug_dir": project_relative_or_absolute(run_dir) if output_mode == "debug" else None,
            "stls": {
                str(record["id"]): project_relative_or_absolute(Path(record["stl_path"]))
                for record in object_records
            } if output_mode == "debug" else {},
            "openscad_logs": {
                str(record["id"]): project_relative_or_absolute(Path(record["openscad_log"]))
                for record in object_records
                if record.get("openscad_log") is not None
            } if output_mode == "debug" else {},
            "blender_log": project_relative_or_absolute(blender_log) if output_mode == "debug" else None,
            "render": project_relative_or_absolute(render_path) if output_mode == "debug" else None,
            "annotated": project_relative_or_absolute(annotated_path),
            "metadata": project_relative_or_absolute(metadata_path) if output_mode != "minimal" else None,
            "blend": project_relative_or_absolute(export_blend_path) if export_blend_path is not None else None,
            "animation": project_relative_or_absolute(animation_path) if animation_path is not None else None,
            "animation_frames": project_relative_or_absolute(animation_frame_dir) if animation_frame_dir is not None and output_mode == "debug" else None,
            "projection": project_relative_or_absolute(projection_path) if output_mode == "debug" else None,
        },
        "commands": {
            "openscad": openscad_commands,
            "blender": list(blender_command),
        },
    }
