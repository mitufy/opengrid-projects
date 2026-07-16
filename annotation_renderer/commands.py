"""Model inspection, SCAD discovery, and config-template commands."""

from __future__ import annotations

import argparse
import json
import os
from copy import deepcopy
from pathlib import Path
from typing import Mapping, Sequence

from annotation_renderer.config.defaults import ANNOTATION_COLLECTION_KEYS
from annotation_renderer.config.loader import dump_config_data, selected_variants, variant_config, variant_items_from_config
from annotation_renderer.config.resolution import annotation_group_identity, deep_merge, resolve_config_path
from annotation_renderer.config.schema import CONFIG_SCHEMA_PATH, ConfigError
from annotation_renderer.config.validation import merge_scene_object_config, resolve_render, resolve_scene
from annotation_renderer.catalog import is_directly_renderable_config, model_name_from_shortcut, model_record_source
from annotation_renderer.openscad import project_relative_or_absolute, sanitize_name
from annotation_renderer.paths import PROJECT_ROOT
from annotation_renderer.scad_discovery import (
    discover_scad_source_annotations,
    format_annotation_discovery,
    resolve_discovery_scad_path,
    write_annotation_discovery_output,
)


def compact_json(value: object) -> str:
    return json.dumps(value, ensure_ascii=True, separators=(",", ":"))


def source_config_for_variant(config_path: Path, variant: Mapping[str, object] | None) -> Path:
    if variant is None:
        return config_path
    raw_source = variant.get("_source_config")
    if isinstance(raw_source, str) and raw_source.strip():
        return Path(raw_source).expanduser().resolve()
    return config_path


def resolved_named_config(
    config: Mapping[str, object],
    *,
    config_path: Path,
    name: str | None,
) -> tuple[str, dict[str, object], Path, Mapping[str, object] | None]:
    if name:
        normalized_name = model_name_from_shortcut(name)
        variants = variant_items_from_config(config)
        matching = [
            variant
            for variant in variants
            if str(variant["name"]) == name or model_name_from_shortcut(str(variant["name"])) == normalized_name
        ]
        if matching:
            variant = matching[0]
            return str(variant["name"]), variant_config(config, variant), source_config_for_variant(config_path, variant), variant
        direct_names = {
            config_path.stem,
            str(config.get("job_name", "")).strip(),
        }
        direct_name_matches = {direct_name for direct_name in direct_names if direct_name}
        normalized_direct_name_matches = {model_name_from_shortcut(direct_name) for direct_name in direct_name_matches}
        if is_directly_renderable_config(config) and (
            name in direct_name_matches or normalized_name in normalized_direct_name_matches
        ):
            return name, deepcopy(dict(config)), config_path, None
        available = ", ".join(str(variant["name"]) for variant in variants if "name" in variant)
        if is_directly_renderable_config(config):
            available = ", ".join(item for item in (*direct_names, available) if item)
        raise ConfigError(f"Unknown model {name!r}. Available models: {available or 'none'}")
    if is_directly_renderable_config(config):
        return config_path.stem, deepcopy(dict(config)), config_path, None
    variants = selected_variants(config, None)
    if not variants:
        raise ConfigError("Config has no directly renderable model and no variants")
    variant = variants[0]
    variant_name = str(variant["name"]).strip()
    return variant_name, variant_config(config, variant), source_config_for_variant(config_path, variant), variant


def model_records_from_config(config: Mapping[str, object]) -> list[dict[str, object]]:
    scene = resolve_scene(config.get("scene", {}))
    records: list[dict[str, object]] = []
    scene_objects = scene.get("objects")
    if scene_objects is not None:
        object_defaults = scene.get("object_defaults")
        for raw_object in scene_objects:
            if not isinstance(raw_object, Mapping):
                continue
            scene_object = merge_scene_object_config(object_defaults, raw_object)
            model = scene_object.get("model")
            if not isinstance(model, Mapping):
                stl_file = scene_object.get("stl_file")
                if isinstance(stl_file, str) and stl_file.strip():
                    records.append(
                        {
                            "id": str(scene_object.get("id", "model")),
                            "target_object": scene_object.get("target_object"),
                            "stl_file": stl_file,
                            "defines": {},
                        }
                    )
                continue
            records.append(
                {
                    "id": str(scene_object.get("id", "model")),
                    "target_object": scene_object.get("target_object"),
                    "scad_file": model.get("scad_file"),
                    "defines": model.get("defines", {}),
                }
            )
        return records
    return records


def model_summary(records: Sequence[Mapping[str, object]]) -> str:
    if not records:
        return "no model"
    parts = []
    for record in records:
        object_id = str(record.get("id") or "model")
        parts.append(f"{object_id}: {model_record_source(record)}")
    return "; ".join(parts)


def iter_annotation_groups(annotations: Mapping[str, object]) -> list[tuple[str, Mapping[str, object]]]:
    groups: list[tuple[str, Mapping[str, object]]] = []
    for key, kind in (
        ("chains", "dimension"),
        ("radius_callouts", "radius"),
        ("arc_callouts", "arc"),
        ("angle_radius_callouts", "angle_radius"),
        ("image_labels", "image_label"),
    ):
        raw_groups = annotations.get(key, [])
        if not isinstance(raw_groups, Sequence) or isinstance(raw_groups, (str, bytes)):
            continue
        for group in raw_groups:
            if isinstance(group, Mapping) and group.get("enabled", True) is not False:
                groups.append((kind, group))
    return groups


def annotation_group_name(kind: str, group: Mapping[str, object]) -> str:
    collection = {
        "dimension": "chains",
        "radius": "radius_callouts",
        "arc": "arc_callouts",
        "angle_radius": "angle_radius_callouts",
        "image_label": "image_labels",
    }.get(kind)
    identity = annotation_group_identity(collection, group) if collection is not None else None
    return identity or kind


def annotation_offset_summary(kind: str, group: Mapping[str, object]) -> str:
    if kind == "dimension":
        items: list[tuple[str, object]] = [
            ("display_offset_mm", group.get("display_offset_mm", [0, 0, 0])),
            ("display_rotation_deg", group.get("display_rotation_deg", [0, 0, 0])),
            ("line_offset_px", group.get("line_offset_px", 0)),
            ("label_offset_px", group.get("label_offset_px", 0)),
            ("label_along_offset_px", group.get("label_along_offset_px", 0)),
        ]
    elif kind == "image_label":
        items = [("offset_px", group.get("offset_px", [0, 0]))]
    else:
        items = [
            ("display_offset_mm", group.get("display_offset_mm", [0, 0, 0])),
            ("display_rotation_deg", group.get("display_rotation_deg", [0, 0, 0])),
        ]
        for key in (
            "label_offset_px",
            "angle_label_offset_px",
            "radius_label_offset_px",
            "angle_label_tangent_offset_px",
            "radius_label_tangent_offset_px",
        ):
            if key in group:
                items.append((key, group[key]))
    if group.get("optional"):
        items.append(("optional", True))
    return ", ".join(f"{key}={compact_json(value)}" for key, value in items)


def print_annotation_groups(config: Mapping[str, object]) -> None:
    annotations = config.get("annotations", {})
    if not isinstance(annotations, Mapping):
        print("No annotation config.")
        return
    groups = iter_annotation_groups(annotations)
    if not groups:
        print("No annotation groups.")
        return
    for kind, group in groups:
        print(f"- {kind}: {annotation_group_name(kind, group)}")
        print(f"  {annotation_offset_summary(kind, group)}")


def run_annotation_discovery(
    *,
    args: argparse.Namespace,
) -> int:
    if args.config:
        raise ConfigError("discover reads a SCAD file directly; do not pass a render config")
    scad_file = resolve_discovery_scad_path(str(args.discover_annotations))
    name = scad_file.stem
    discoveries: list[dict[str, object]] = [
        {
            "id": name,
            "source_path": scad_file,
            "annotations": discover_scad_source_annotations(scad_file, defines={}),
        }
    ]

    text_output = format_annotation_discovery(name, discoveries)
    print(text_output)
    if args.out:
        output_path = Path(args.out).expanduser()
        if not output_path.is_absolute():
            output_path = (PROJECT_ROOT / output_path).resolve()
        write_annotation_discovery_output(
            output_path=output_path,
            text_output=text_output,
            name=name,
            discoveries=discoveries,
        )
        print(f"Wrote: {project_relative_or_absolute(output_path)}")
    return 0


def print_model_list(*, config: Mapping[str, object], config_path: Path) -> None:
    variants = selected_variants(config, None)
    if variants:
        print(f"Config: {project_relative_or_absolute(config_path)}")
        for variant in variants:
            name = str(variant["name"]).strip()
            resolved_config = variant_config(config, variant)
            source_config = source_config_for_variant(config_path, variant)
            records = model_records_from_config(resolved_config)
            print(f"- {name}")
            print(f"  source: {project_relative_or_absolute(source_config)}")
            print(f"  job: {resolved_config.get('job_name', name)}")
            print(f"  models: {model_summary(records)}")
        return

    name = config_path.stem
    print(f"Config: {project_relative_or_absolute(config_path)}")
    print(f"- {name}")
    print(f"  source: {project_relative_or_absolute(config_path)}")
    print(f"  job: {config.get('job_name', name)}")
    print(f"  models: {model_summary(model_records_from_config(config))}")


def print_model_description(*, name: str, config: Mapping[str, object], source_config: Path) -> None:
    scene = resolve_scene(config.get("scene", {}))
    render = resolve_render(config.get("render", {}))
    print(f"Name:   {name}")
    print(f"Source: {project_relative_or_absolute(source_config)}")
    print(f"Job:    {config.get('job_name', name)}")
    print(f"Scene:  {scene.get('blend_file')}")
    print(f"Camera: {scene.get('camera', 'Camera')}")
    print("Models:")
    for record in model_records_from_config(config):
        print(f"- {record.get('id')}: {model_record_source(record)} -> {record.get('target_object')}")
        defines = record.get("defines", {})
        if isinstance(defines, Mapping) and defines:
            for define_name, value in defines.items():
                print(f"  {define_name}: {compact_json(value)}")
        elif isinstance(defines, Sequence) and not isinstance(defines, (str, bytes)) and defines:
            for define in defines:
                print(f"  {define}")
    print("Render:")
    for key in (
        "engine",
        "quality",
        "width",
        "height",
        "fit_camera",
        "fit_margin",
        "camera_view",
        "camera_view_preset",
        "camera_rotation_deg",
        "camera_rotation_offset_deg",
        "camera_orbit_deg",
        "camera_distance_scale",
        "camera_target_offset_mm",
        "camera_location_offset_mm",
        "camera_roll_deg",
        "camera_lens_mm",
        "camera_focal_length_mm",
        "camera_look_at",
        "lighting",
        "outline",
        "ground_plane",
        "cutaway",
        "xray",
        "material_overrides",
        "output_mode",
    ):
        if key in render:
            print(f"- {key}: {compact_json(render[key])}")
    annotations = config.get("annotations", {})
    group_count = len(iter_annotation_groups(annotations)) if isinstance(annotations, Mapping) else 0
    print(f"Annotations: {group_count} groups")


def editable_annotations_template(config: Mapping[str, object]) -> dict[str, object]:
    annotations = config.get("annotations", {})
    if not isinstance(annotations, Mapping):
        return {}
    editable: dict[str, object] = {}
    for key in ANNOTATION_COLLECTION_KEYS:
        raw_groups = annotations.get(key)
        if not isinstance(raw_groups, Sequence) or isinstance(raw_groups, (str, bytes)):
            continue
        copied_groups: dict[str, object] = {}
        for group in raw_groups:
            if not isinstance(group, Mapping):
                continue
            if group.get("enabled", True) is False:
                continue
            group_name = annotation_group_identity(key, group)
            if group_name is None:
                continue
            copied_group: dict[str, object] = {}
            for group_key in (
                "enabled",
                "id",
                "ids",
                "arc_id",
                "radius_id",
                "angle_id",
                "optional",
                "display_offset_mm",
                "display_rotation_deg",
                "color",
                "colors",
                "line_offset_px",
                "label_offset_px",
                "label_along_offset_px",
                "line_alpha",
                "line_width_px",
                "line_outline_color",
                "line_outline_alpha",
                "angle_radius_outline_alpha",
                "line_outline_width_px",
                "extension_width_px",
                "extension_outline_width_px",
                "extension_visible",
                "extension_dash_px",
                "extension_gap_px",
                "tick_length_px",
                "radial_line_width_px",
                "radial_line_outline_width_px",
                "radial_dash_px",
                "radial_gap_px",
                "arc_line_outline_width_px",
                "angle_radius_arc_outline_width_px",
                "label_font_size_px",
                "label_color",
                "label_color_by_segment",
                "label_outline_color",
                "label_outline_width_px",
                "angle_label_offset_px",
                "radius_label_offset_px",
                "angle_label_tangent_offset_px",
                "radius_label_tangent_offset_px",
                "show_label",
                "show_angle_label",
                "show_radius_label",
                "angle_fill_alpha",
                "label_avoidance_padding_px",
                "offset_px",
                "position",
                "show_value",
                "value",
                "text",
                "value_color",
            ):
                if group_key in group:
                    copied_group[group_key] = deepcopy(group[group_key])
            if key in {"chains", "radius_callouts", "arc_callouts"}:
                ids = copied_group.pop("ids", None)
                if isinstance(ids, Sequence) and not isinstance(ids, (str, bytes)):
                    if len(ids) == 1 and ids[0] != group_name:
                        copied_group["id"] = ids[0]
                    elif list(ids) != [group_name]:
                        copied_group["ids"] = list(ids)
            elif copied_group.get("id") == group_name:
                copied_group.pop("id")
            copied_groups[group_name] = copied_group
        if copied_groups:
            editable[key] = copied_groups
    return editable


def editable_model_template(config: Mapping[str, object]) -> dict[str, object]:
    scene = resolve_scene(config.get("scene", {}))
    raw_objects = scene.get("objects")
    if isinstance(raw_objects, Sequence) and not isinstance(raw_objects, (str, bytes)) and raw_objects:
        editable_scene: dict[str, object] = {"objects": deepcopy(list(raw_objects))}
        object_defaults = scene.get("object_defaults")
        if object_defaults is not None:
            editable_scene["object_defaults"] = deepcopy(object_defaults)
        return {"scene": editable_scene}
    constants = config.get("constants", {})
    if isinstance(constants, Mapping):
        editable_constants: dict[str, object] = {}
        for key in ("drawer_common_defines",):
            value = constants.get(key)
            if isinstance(value, Mapping):
                editable_constants[key] = deepcopy(dict(value))
        if editable_constants:
            return {"constants": editable_constants}
    return {}


def config_reference(*, source_config: Path, output_path: Path) -> str:
    return path_reference(source_config, start=output_path.parent)


def path_reference(path: Path, *, start: Path) -> str:
    try:
        relative = os.path.relpath(path.resolve(), start=start.resolve())
    except ValueError:
        return project_relative_or_absolute(path)
    return Path(relative).as_posix()


def write_new_config_template(
    *,
    name: str,
    config: Mapping[str, object],
    source_config: Path,
    output_path: Path,
    force: bool,
) -> None:
    if output_path.exists() and not force:
        raise ConfigError(f"Output config already exists: {output_path}. Use --force to overwrite it.")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    template: dict[str, object] = {
        "$schema": path_reference(CONFIG_SCHEMA_PATH, start=output_path.parent),
        "extends": config_reference(source_config=source_config, output_path=output_path),
        "job_name": f"{sanitize_name(name)}_custom",
    }
    scene = resolve_scene(config.get("scene", {}))
    blend_file = scene.get("blend_file")
    if isinstance(blend_file, str) and blend_file.strip():
        scene_path = resolve_config_path(blend_file, config_dir=source_config.parent, project_root=PROJECT_ROOT)
        template["scene"] = {
            "blend_file": path_reference(scene_path, start=output_path.parent)
        }
    template = deep_merge(template, editable_model_template(config))
    editable_annotations = editable_annotations_template(config)
    if editable_annotations:
        template["annotations"] = editable_annotations
    output_path.write_text(dump_config_data(template, path=output_path), encoding="utf-8")
