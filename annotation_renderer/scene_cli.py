"""CLI entry point for rendering configured annotations in a Blender scene."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
from copy import deepcopy
from datetime import datetime
from pathlib import Path
from typing import Mapping, Sequence

from PIL import Image, ImageDraw

try:
    import yaml
except ImportError:  # pragma: no cover - exercised only in incomplete local environments
    yaml = None

from annotation_renderer.animation import encode_animation_gif, resolve_animation_config
from annotation_renderer.blender_scene import write_blender_scene_script
from annotation_renderer.config_loader import (
    INHERITED_VARIANTS_KEY,
    base_job_name,
    dump_config_data,
    load_config,
    load_gallery_config,
    require_mapping,
    selected_variants,
    variant_config,
    variant_items_from_config,
)
from annotation_renderer.annotation_config import (
    collect_angle_radius_callouts,
    collect_arc_callouts,
    collect_dimension_chain,
    collect_image_labels,
    collect_radius_callouts,
    projection_points_for_angle_radius_callouts,
    projection_points_for_arc_callouts,
    projection_points_for_radius_callouts,
    projection_points_for_segments,
)
from annotation_renderer.config_defaults import (
    CAMERA_VIEW_PRESETS,
    DEFAULT_OUTPUT_DIR,
    DEFAULT_OUTPUT_MODE,
    DEFAULT_RENDER_MESH_SHADING,
    DEFAULT_RENDER_PRESET_NAME,
    GALLERY_SETTING_DEFAULTS,
    RENDER_OUTPUT_MODES,
    RENDER_PRESETS,
)
from annotation_renderer.config_resolution import (
    aliases_from_config,
    build_expression_context,
    build_expression_context_for_model,
    build_scad_defines,
    deep_merge,
    eval_numeric_expression,
    resolve_config_path,
    resolve_constant_references,
    resolve_scene_transform,
    resolve_style,
    normalize_style_aliases,
    scene_inherits_target_transform,
    vector2,
    vector3,
)
from annotation_renderer.config_schema import CONFIG_SCHEMA_PATH, ConfigError
from annotation_renderer.config_validation import (
    merge_scene_object_config,
    resolve_render,
    resolve_scene,
    validate_config_shape,
)
from annotation_renderer.openscad import (
    build_openscad_command,
    project_relative_or_absolute,
    resolve_openscad_executable,
    run_command_logged,
    sanitize_name,
)
from annotation_renderer.overlay import (
    DimensionChainOverlaySpec,
    draw_angle_radius_callout_overlay,
    draw_arc_callout_overlay,
    draw_dimension_chains_overlay,
    draw_image_label_overlay,
    draw_radius_callout_overlay,
    load_font,
)
from annotation_renderer.scad_annotations import (
    numeric_context_from_scad_annotations,
    read_scad_annotations,
    value_context_from_scad_annotations,
    with_annotation_metadata_define,
)
from annotation_renderer.scad_discovery import (
    discover_scad_source_annotations,
    discovery_summary_json,
    format_annotation_discovery,
    resolve_discovery_scad_path,
    write_annotation_discovery_output,
)


UTILITY_ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = UTILITY_ROOT.parent
DEFAULT_MODEL_CONFIG_PATH = UTILITY_ROOT / "configs" / "model_defaults.yaml"
DISCOVERY_ACTIONS = ("list_models", "describe", "list_annotations", "new_config")
COMMANDS = ("render", "doctor", "discover", "new-config", "list-models", "describe", "list-annotations")
OUTPUT_MODES = RENDER_OUTPUT_MODES
CONFIG_SHORTCUT_SUFFIXES = (".yaml", ".yml", ".json")
GROUP_STYLE_KEYS = {
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
    "label_font_size_px",
    "label_color",
    "label_color_by_segment",
    "label_outline_color",
    "label_outline_width_px",
    "radial_line_width_px",
    "radial_line_outline_width_px",
    "radial_dash_px",
    "radial_gap_px",
    "arc_line_outline_width_px",
    "angle_radius_arc_outline_width_px",
    "angle_fill_color",
    "angle_fill_alpha",
    "label_avoidance_padding_px",
    "type_styles",
}


def default_windows_blender_candidates() -> list[Path]:
    candidates = [
        Path(r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"),
        Path(r"C:\Program Files\Blender Foundation\Blender 4.1\blender.exe"),
        Path(r"C:\Program Files\Blender Foundation\Blender\blender.exe"),
    ]
    foundation = Path(r"C:\Program Files\Blender Foundation")
    if foundation.exists():
        candidates.extend(sorted(foundation.glob("Blender *\\blender.exe"), reverse=True))
    return candidates


def resolve_blender_executable(executable: str = "blender") -> str | None:
    raw_path = Path(executable).expanduser()
    if raw_path.exists():
        return str(raw_path.resolve())

    discovered = shutil.which(executable)
    if discovered:
        return discovered

    env_override = os.environ.get("BLENDER_EXECUTABLE")
    if env_override:
        env_path = Path(env_override).expanduser()
        if env_path.exists():
            return str(env_path.resolve())

    if os.name == "nt":
        for candidate in default_windows_blender_candidates():
            if candidate.exists():
                return str(candidate.resolve())

    return None


def require_blender_executable(executable: str = "blender") -> str:
    resolved = resolve_blender_executable(executable)
    if resolved is None:
        raise SystemExit(
            f"Missing required tool: {executable}. Install Blender, put it on PATH, or set BLENDER_EXECUTABLE."
        )
    return resolved


def log_tail(log_path: Path, *, line_count: int = 40) -> str:
    try:
        lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return ""
    return "\n".join(lines[-line_count:])


def command_failure_message(message: str, *, log_path: Path, line_count: int = 40) -> str:
    tail = log_tail(log_path, line_count=line_count)
    log_reference = project_relative_or_absolute(log_path)
    if not tail:
        return f"{message}. Log: {log_reference}"
    return f"{message}. Last {line_count} log lines:\n{tail}\nLog: {log_reference}"


def format_doctor_check(ok: bool, label: str, detail: str) -> str:
    status = "OK" if ok else "FAIL"
    return f"[{status}] {label}: {detail}"


def doctor_checks(args: argparse.Namespace) -> list[tuple[bool, str, str]]:
    checks: list[tuple[bool, str, str]] = []
    checks.append((True, "Python", sys.executable))

    checks.append((yaml is not None, "PyYAML", "available" if yaml is not None else "missing"))

    openscad = resolve_openscad_executable(args.openscad)
    checks.append(
        (
            openscad is not None,
            "OpenSCAD",
            openscad or f"not found for {args.openscad!r}; set OPENSCAD_EXECUTABLE or pass --openscad",
        )
    )

    blender = resolve_blender_executable(args.blender)
    checks.append(
        (
            blender is not None,
            "Blender",
            blender or f"not found for {args.blender!r}; set BLENDER_EXECUTABLE or pass --blender",
        )
    )

    default_scene = UTILITY_ROOT / "assets" / "scenes" / "opengrid_wall_scene.blend"
    checks.append((default_scene.exists(), "Default Blender scene", project_relative_or_absolute(default_scene)))

    output_root = PROJECT_ROOT / DEFAULT_OUTPUT_DIR
    try:
        output_root.mkdir(parents=True, exist_ok=True)
        checks.append((True, "Output directory", project_relative_or_absolute(output_root)))
    except OSError as exc:
        checks.append((False, "Output directory", f"{project_relative_or_absolute(output_root)} ({exc})"))

    return checks


def run_doctor(args: argparse.Namespace) -> int:
    checks = doctor_checks(args)
    print("Annotation renderer doctor")
    for ok, label, detail in checks:
        print(format_doctor_check(ok, label, detail))
    if not all(ok for ok, _label, _detail in checks):
        return 1
    if getattr(args, "smoke_render", False):
        smoke_config_path = default_config_for_model("openconnect_general_holder")
        print("Smoke render: openconnect_general_holder")
        smoke_args = argparse.Namespace(**vars(args))
        smoke_args.config = str(smoke_config_path)
        smoke_args.command = None
        smoke_args.model_shortcut = None
        smoke_args.gallery = False
        smoke_args.gallery_config = None
        smoke_args.variant = None
        smoke_args.animation_preset = None
        smoke_args.validate_only = False
        smoke_args.print_resolved_config = False
        smoke_args.output_mode = "minimal"
        smoke_args.output_file = None
        config = load_config(smoke_config_path, smoke_args.overrides)
        render_config(
            config=config,
            config_path=smoke_config_path,
            config_dir=smoke_config_path.parent,
            args=smoke_args,
        )
    return 0


def annotation_mapping_items(
    annotation_config: Mapping[str, object],
    key: str,
) -> list[Mapping[str, object]]:
    item_config = annotation_config.get(key, [])
    if not isinstance(item_config, Sequence) or isinstance(item_config, (str, bytes)):
        raise ConfigError(f"annotations.{key} must be an array")
    items: list[Mapping[str, object]] = []
    for index, item in enumerate(item_config):
        if not isinstance(item, Mapping):
            raise ConfigError(f"annotations.{key}[{index}] must be an object")
        items.append(item)
    return items


def chain_items_from_config(annotation_config: Mapping[str, object]) -> list[Mapping[str, object]]:
    return annotation_mapping_items(annotation_config, "chains")


def radius_items_from_config(annotation_config: Mapping[str, object]) -> list[Mapping[str, object]]:
    return annotation_mapping_items(annotation_config, "radius_callouts")


def arc_items_from_config(annotation_config: Mapping[str, object]) -> list[Mapping[str, object]]:
    return annotation_mapping_items(annotation_config, "arc_callouts")


def angle_radius_items_from_config(annotation_config: Mapping[str, object]) -> list[Mapping[str, object]]:
    return annotation_mapping_items(annotation_config, "angle_radius_callouts")


def image_label_items_from_config(annotation_config: Mapping[str, object]) -> list[Mapping[str, object]]:
    return annotation_mapping_items(annotation_config, "image_labels")


def style_for_group(style_config: Mapping[str, object], group_config: Mapping[str, object]) -> dict[str, object]:
    merged = dict(style_config)
    normalized_group_config = normalize_style_aliases(group_config)
    for key in GROUP_STYLE_KEYS:
        if key in normalized_group_config:
            merged[key] = normalized_group_config[key]
    return merged


def discovery_requested(args: argparse.Namespace) -> bool:
    return any(bool(getattr(args, name, None)) for name in DISCOVERY_ACTIONS)


def render_shortcut_requested(args: argparse.Namespace) -> bool:
    return getattr(args, "command", None) == "render"


def set_command_alias_value(args: argparse.Namespace, attr: str, value: object, *, command: str) -> None:
    current = getattr(args, attr, None)
    if current not in (None, False, "") and current != value:
        flag_name = attr.replace("_", "-")
        raise ConfigError(f"Do not combine `{command}` with --{flag_name}")
    setattr(args, attr, value)


def normalize_command_aliases(args: argparse.Namespace) -> argparse.Namespace:
    command = getattr(args, "command", None)
    target = getattr(args, "model_shortcut", None)
    if command is None or command == "render":
        return args

    if command == "doctor":
        if target:
            raise ConfigError("doctor does not take a model name")
        set_command_alias_value(args, "doctor", True, command=command)
        return args

    if command == "list-models":
        if target:
            raise ConfigError("list-models does not take a model name")
        set_command_alias_value(args, "list_models", True, command=command)
        return args

    if command in {"discover", "new-config", "describe", "list-annotations"} and not target:
        examples = {
            "discover": "discover openconnect_general_holder.scad",
            "new-config": "new-config openconnect_general_holder --out build\\scene_annotations\\my_holder.yaml",
            "describe": "describe openconnect_general_holder",
            "list-annotations": "list-annotations openconnect_general_holder",
        }
        raise ConfigError(f"{command} requires a target, for example `{examples[command]}`")

    if command == "discover":
        set_command_alias_value(args, "discover_annotations", target, command=command)
    elif command == "new-config":
        set_command_alias_value(args, "new_config", target, command=command)
    elif command == "describe":
        set_command_alias_value(args, "describe", target, command=command)
    elif command == "list-annotations":
        set_command_alias_value(args, "list_annotations", target, command=command)
    return args


def model_name_from_shortcut(raw_name: str) -> str:
    name = Path(raw_name).stem if raw_name.lower().endswith(".scad") else raw_name
    name = sanitize_name(name.strip())
    if name.endswith("_default"):
        name = name[: -len("_default")]
    if not name:
        raise ConfigError("render requires a SCAD model name, for example `render openconnect_general_holder`")
    return name


def config_name_from_shortcut(raw_name: str) -> str:
    stripped = raw_name.strip()
    name = Path(stripped).stem if stripped.lower().endswith(CONFIG_SHORTCUT_SUFFIXES) else stripped
    name = sanitize_name(name)
    if not name:
        raise ConfigError("render requires a config or SCAD model name, for example `render openconnect_general_holder`")
    return name


def named_config_path(shortcut: str) -> Path | None:
    for suffix in CONFIG_SHORTCUT_SUFFIXES:
        config_path = UTILITY_ROOT / "configs" / f"{shortcut}{suffix}"
        if config_path.exists():
            return config_path.resolve()
    return None


def available_render_shortcuts() -> list[str]:
    shortcuts: list[str] = []
    for path in sorted((UTILITY_ROOT / "configs").glob("*.y*ml")) + sorted((UTILITY_ROOT / "configs").glob("*.json")):
        name = path.stem
        if name in {"animation_presets", "base_scene", "gallery_defaults"}:
            continue
        if name.endswith("_default"):
            name = name[: -len("_default")]
        if name not in shortcuts:
            shortcuts.append(name)
    return shortcuts


def default_config_for_model(model_name: str) -> Path:
    if not model_name.strip().lower().endswith(".scad"):
        config_shortcut = config_name_from_shortcut(model_name)
        config_path = named_config_path(config_shortcut)
        if config_path is not None:
            return config_path
    shortcut = model_name_from_shortcut(model_name)
    config_path = UTILITY_ROOT / "configs" / f"{shortcut}_default.yaml"
    if config_path.exists():
        return config_path.resolve()
    available = ", ".join(available_render_shortcuts()) or "none"
    raise ConfigError(
        f"Unknown render shortcut {model_name!r}. Expected annotation_renderer/configs/{shortcut}.yaml "
        f"or annotation_renderer/configs/{shortcut}_default.yaml. Available shortcuts: {available}"
    )


def config_path_from_args(args: argparse.Namespace, *, allow_default: bool = False) -> Path:
    if render_shortcut_requested(args):
        if args.config:
            raise ConfigError("Do not pass --config with `render MODEL`; the model name selects the default config")
        if not getattr(args, "model_shortcut", None):
            raise ConfigError("render requires a SCAD model name, for example `render openconnect_general_holder`")
        return default_config_for_model(str(args.model_shortcut))
    if args.config:
        path = Path(args.config).expanduser()
        if not path.is_absolute():
            path = (PROJECT_ROOT / path).resolve()
        return path
    if allow_default:
        return DEFAULT_MODEL_CONFIG_PATH.resolve()
    raise ConfigError("--config is required unless --print-schema or a discovery command is used")


def is_directly_renderable_config(config: Mapping[str, object]) -> bool:
    scene = resolve_scene(config.get("scene", {}))
    return scene.get("objects") is not None


def output_root_for(config: Mapping[str, object], args: argparse.Namespace) -> Path:
    output_root = Path(args.output_dir or config.get("output_dir") or DEFAULT_OUTPUT_DIR)
    if not output_root.is_absolute():
        output_root = PROJECT_ROOT / output_root
    return output_root


def output_file_from_args(args: argparse.Namespace) -> Path | None:
    raw_path = getattr(args, "output_file", None)
    if not raw_path:
        return None
    output_file = Path(str(raw_path)).expanduser()
    if not output_file.is_absolute():
        output_file = (PROJECT_ROOT / output_file).resolve()
    if output_file.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        raise ConfigError("--output-file must end with .png, .jpg, or .jpeg for still-image renders")
    return output_file


def output_mode_for(render_config: Mapping[str, object], args: argparse.Namespace) -> str:
    raw_mode = getattr(args, "output_mode", None) or render_config.get("output_mode") or DEFAULT_OUTPUT_MODE
    mode = str(raw_mode)
    if mode not in OUTPUT_MODES:
        raise ConfigError(f"render.output_mode must be one of {', '.join(OUTPUT_MODES)}")
    return mode


def export_blend_for(render_config: Mapping[str, object], args: argparse.Namespace) -> bool:
    raw_value = render_config.get("export_blend", False)
    if not isinstance(raw_value, bool):
        raise ConfigError("render.export_blend must be a boolean")
    return bool(raw_value or getattr(args, "export_blend", False))


def cache_enabled_for(render_config: Mapping[str, object], args: argparse.Namespace) -> bool:
    if getattr(args, "no_cache", False):
        return False
    raw_value = render_config.get("cache", True)
    if not isinstance(raw_value, bool):
        raise ConfigError("render.cache must be a boolean")
    return raw_value


def cache_root_for(config: Mapping[str, object], render_config: Mapping[str, object], args: argparse.Namespace) -> Path | None:
    if not cache_enabled_for(render_config, args):
        return None
    raw_path = getattr(args, "cache_dir", None) or render_config.get("cache_dir")
    cache_root = Path(str(raw_path)).expanduser() if raw_path else output_root_for(config, args) / ".cache"
    if not cache_root.is_absolute():
        cache_root = (PROJECT_ROOT / cache_root).resolve()
    cache_root.mkdir(parents=True, exist_ok=True)
    return cache_root


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def stable_json(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)


def cache_key_for(value: object) -> str:
    return hashlib.sha256(stable_json(value).encode("utf-8")).hexdigest()


def animation_render_preset(config: Mapping[str, object], preset_name: str) -> Mapping[str, object]:
    if not preset_name.strip():
        raise ConfigError("--animation-preset must not be empty")
    preset = resolve_constant_references(
        {"$constant": preset_name},
        constants=require_mapping(config.get("constants", {}), name="constants"),
        path=f"animation preset {preset_name}",
    )
    if not isinstance(preset, Mapping):
        raise ConfigError(f"Animation preset {preset_name!r} must resolve to a render object")
    if "animation" not in preset:
        raise ConfigError(f"Animation preset {preset_name!r} must include render.animation")
    return preset


def apply_animation_preset(config: Mapping[str, object], preset_name: str) -> dict[str, object]:
    resolved = deepcopy(dict(config))
    current_render = resolve_render(resolved.get("render", {}))
    resolved["render"] = deep_merge(current_render, animation_render_preset(resolved, preset_name))
    resolved["annotations"] = {}
    if "job_name" in resolved:
        resolved["job_name"] = f"{sanitize_name(str(resolved['job_name']))}__{sanitize_name(preset_name)}"
    validate_config_shape(resolved)
    return resolved


def work_dir_name(*, job_name: str, timestamp: str) -> str:
    digest = hashlib.sha1(job_name.encode("utf-8")).hexdigest()[:8]
    return f"work__{timestamp}__{digest}"


def scad_output_folder_name(object_specs: Sequence[Mapping[str, object]]) -> str:
    stems: list[str] = []
    for object_spec in object_specs:
        source_path = object_spec.get("scad_file") or object_spec.get("stl_file") or object_spec.get("stl_path")
        stem = Path(str(source_path)).stem if source_path else "unknown_model"
        if stem not in stems:
            stems.append(stem)
    if not stems:
        return "unknown_model"
    return sanitize_name(stems[0] if len(stems) == 1 else "__".join(stems))


def model_record_source(record: Mapping[str, object]) -> str:
    if record.get("scad_file"):
        return str(record["scad_file"])
    if record.get("stl_file"):
        return str(record["stl_file"])
    if record.get("stl_path"):
        return str(record["stl_path"])
    return "unknown"


def vector3_config_items(value: object, *, name: str) -> list[object]:
    if isinstance(value, Mapping):
        try:
            return [value[axis] for axis in ("x", "y", "z")]
        except KeyError as exc:
            raise ConfigError(f"{name} mapping must contain x, y, and z") from exc
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 3:
        raise ConfigError(f"{name} must be a three-item list or x/y/z object")
    return list(value)


def int_vector3_config_items(value: object, *, name: str) -> tuple[int, int, int]:
    if isinstance(value, Mapping):
        try:
            items = [value[axis] for axis in ("x", "y", "z")]
        except KeyError as exc:
            raise ConfigError(f"{name} mapping must contain x, y, and z") from exc
    else:
        if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 3:
            raise ConfigError(f"{name} must be a three-item list or x/y/z object")
        items = list(value)
    counts: list[int] = []
    for index, item in enumerate(items):
        if not isinstance(item, int) or isinstance(item, bool):
            raise ConfigError(f"{name}[{index}] must be an integer")
        if item < 1:
            raise ConfigError(f"{name}[{index}] must be at least 1")
        counts.append(item)
    return (counts[0], counts[1], counts[2])


def expression_token(value: object) -> str:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f"{value:g}"
    return str(value).strip()


def is_zero_expression(value: object) -> bool:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value) == 0.0
    try:
        return float(str(value).strip()) == 0.0
    except ValueError:
        return False


def offset_expression(base_value: object, spacing_value: object, copy_index: int) -> object:
    if copy_index == 0 or is_zero_expression(spacing_value):
        return base_value
    return f"({expression_token(base_value)}) + ({expression_token(spacing_value)}) * {copy_index}"


def add_copy_offset_to_scene_transform(
    scene_config: Mapping[str, object],
    *,
    spacing_mm: object,
    copy_indices: Sequence[int],
    name: str,
    config_name: str,
) -> dict[str, object]:
    if all(index == 0 for index in copy_indices):
        return dict(scene_config)
    transform = scene_config.get("transform")
    if not isinstance(transform, Mapping):
        raise ConfigError(f"{name}.transform is required when {config_name} is used")
    base_location = vector3_config_items(transform.get("location_mm"), name=f"{name}.transform.location_mm")
    spacing = vector3_config_items(spacing_mm, name=f"{name}.{config_name}.spacing_mm")
    updated_transform = dict(transform)
    updated_transform["location_mm"] = [
        offset_expression(base_location[axis], spacing[axis], int(copy_indices[axis]))
        for axis in range(3)
    ]
    updated_scene = dict(scene_config)
    updated_scene["transform"] = updated_transform
    return updated_scene


def expanded_scene_object_configs(
    raw_objects: Sequence[object],
    *,
    object_defaults: object,
) -> list[tuple[int, dict[str, object], Mapping[str, object] | None]]:
    expanded: list[tuple[int, dict[str, object], Mapping[str, object] | None]] = []
    for index, raw_object in enumerate(raw_objects):
        if not isinstance(raw_object, Mapping):
            raise ConfigError(f"scene.objects[{index}] must be an object")
        object_config = merge_scene_object_config(object_defaults, raw_object)
        grid_copies = object_config.get("grid_copies")
        line_copies = object_config.get("line_copies")
        if line_copies is not None and grid_copies is not None:
            raise ConfigError(f"scene.objects[{index}] must not define both line_copies and grid_copies")
        if grid_copies is not None:
            if not isinstance(grid_copies, Mapping):
                raise ConfigError(f"scene.objects[{index}].grid_copies must be an object")
            counts = int_vector3_config_items(grid_copies.get("counts"), name=f"scene.objects[{index}].grid_copies.counts")
            spacing_mm = grid_copies.get("spacing_mm")
            base_id = str(object_config.get("id", "")).strip()
            if not base_id:
                raise ConfigError(f"scene.objects[{index}].id is required")
            base_target = object_config.get("target_object")
            for z_index in range(counts[2]):
                for y_index in range(counts[1]):
                    for x_index in range(counts[0]):
                        copied_object = deepcopy(object_config)
                        copied_object.pop("grid_copies", None)
                        copied_object["id"] = f"{base_id}_{x_index}_{y_index}_{z_index}"
                        if isinstance(base_target, str) and base_target.strip():
                            copied_object["target_object"] = f"{base_target}_{x_index}_{y_index}_{z_index}"
                        expanded.append(
                            (
                                index,
                                copied_object,
                                {
                                    "indices": (x_index, y_index, z_index),
                                    "spacing_mm": spacing_mm,
                                    "base_id": base_id,
                                    "config_name": "grid_copies",
                                },
                            )
                        )
            continue
        if line_copies is None:
            expanded.append((index, object_config, None))
            continue
        if not isinstance(line_copies, Mapping):
            raise ConfigError(f"scene.objects[{index}].line_copies must be an object")
        count = line_copies.get("count")
        if not isinstance(count, int) or isinstance(count, bool) or count < 1:
            raise ConfigError(f"scene.objects[{index}].line_copies.count must be a positive integer")
        spacing_mm = line_copies.get("spacing_mm")
        base_id = str(object_config.get("id", "")).strip()
        if not base_id:
            raise ConfigError(f"scene.objects[{index}].id is required")
        base_target = object_config.get("target_object")
        for copy_index in range(count):
            copied_object = deepcopy(object_config)
            copied_object.pop("line_copies", None)
            copied_object["id"] = f"{base_id}_{copy_index}"
            if isinstance(base_target, str) and base_target.strip():
                copied_object["target_object"] = f"{base_target}_{copy_index}"
            expanded.append(
                (
                    index,
                    copied_object,
                    {
                        "indices": (copy_index, 0, 0),
                        "spacing_mm": spacing_mm,
                        "base_id": base_id,
                        "config_name": "line_copies",
                    },
                )
            )
    return expanded


def remove_debug_artifacts(*, output_mode: str, debug_dir: Path, output_dir: Path) -> None:
    if output_mode == "debug" or not debug_dir.exists():
        return
    debug_root = (output_dir / "debug").resolve()
    resolved_debug_dir = debug_dir.resolve()
    try:
        resolved_debug_dir.relative_to(debug_root)
    except ValueError as exc:
        raise ConfigError(f"Refusing to clean debug artifacts outside {debug_root}") from exc
    shutil.rmtree(resolved_debug_dir)


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
            str(config.get("variant_name", "")).strip(),
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
            if isinstance(group, Mapping):
                groups.append((kind, group))
    return groups


def annotation_group_name(kind: str, group: Mapping[str, object]) -> str:
    if kind in {"dimension", "radius", "arc"}:
        ids = group.get("ids", [])
        if isinstance(ids, Sequence) and not isinstance(ids, (str, bytes)):
            return ",".join(str(item) for item in ids)
    if kind == "angle_radius":
        return str(group.get("id") or group.get("angle_id") or group.get("arc_id") or "angle_radius")
    return str(group.get("id") or group.get("text") or "image_label")


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
        raise ConfigError("--discover-annotations reads a SCAD file directly; do not pass --config")
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

    name = config.get("variant_name") or config_path.stem
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
    for key in ("chains", "radius_callouts", "arc_callouts", "angle_radius_callouts", "image_labels"):
        raw_groups = annotations.get(key)
        if not isinstance(raw_groups, Sequence) or isinstance(raw_groups, (str, bytes)):
            continue
        copied_groups = []
        for group in raw_groups:
            if not isinstance(group, Mapping):
                continue
            copied_group: dict[str, object] = {}
            for group_key in (
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
            if copied_group:
                copied_groups.append(copied_group)
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


def run_discovery(*, config: Mapping[str, object], config_path: Path, args: argparse.Namespace) -> int:
    if args.list_models:
        print_model_list(config=config, config_path=config_path)
        return 0
    if args.describe:
        name, resolved_config, source_config, _variant = resolved_named_config(
            config,
            config_path=config_path,
            name=str(args.describe),
        )
        print_model_description(name=name, config=resolved_config, source_config=source_config)
        return 0
    if args.list_annotations:
        name, resolved_config, _source_config, _variant = resolved_named_config(
            config,
            config_path=config_path,
            name=str(args.list_annotations),
        )
        print(f"Annotations for {name}:")
        print_annotation_groups(resolved_config)
        return 0
    if args.new_config:
        if not args.out:
            raise ConfigError("--new-config requires --out")
        output_path = Path(args.out).expanduser()
        if not output_path.is_absolute():
            output_path = (PROJECT_ROOT / output_path).resolve()
        name, resolved_config, source_config, _variant = resolved_named_config(
            config,
            config_path=config_path,
            name=str(args.new_config),
        )
        write_new_config_template(
            name=name,
            config=resolved_config,
            source_config=source_config,
            output_path=output_path,
            force=bool(args.force),
        )
        print(f"Wrote: {project_relative_or_absolute(output_path)}")
        print(f"Extends: {project_relative_or_absolute(source_config)}")
        return 0
    raise ConfigError("No discovery action was requested")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        nargs="?",
        choices=COMMANDS,
        help="Shortcut command, for example `render MODEL`, `doctor`, `discover FILE.scad`, or `new-config MODEL`.",
    )
    parser.add_argument("model_shortcut", nargs="?", help="Model name or SCAD file used by shortcut commands.")
    parser.add_argument("--config", help="Path to scene annotation render JSON or YAML config.")
    parser.add_argument("--gallery-config", help="Path to contact-sheet settings JSON or YAML config used with --gallery.")
    parser.add_argument("--output-dir", help="Override output directory root.")
    parser.add_argument("--output-file", help="Write the final still image to an exact path instead of a timestamped output path.")
    parser.add_argument("--cache-dir", help="Override the render-stage cache directory. Defaults to <output-dir>\\.cache.")
    parser.add_argument("--no-cache", action="store_true", help="Disable OpenSCAD and Blender render-stage cache reuse for this run.")
    parser.add_argument("--export-blend", action="store_true", help="Save the prepared Blender scene used for rendering next to the final image.")
    parser.add_argument("--openscad", default="openscad", help="OpenSCAD executable.")
    parser.add_argument("--blender", default="blender", help="Blender executable.")
    parser.add_argument("--doctor", action="store_true", help="Check local renderer dependencies and paths.")
    parser.add_argument("--smoke-render", action="store_true", help="With --doctor, run one minimal default render after dependency checks pass.")
    parser.add_argument("--print-schema", action="store_true", help="Print the JSON Schema for render configs and exit.")
    parser.add_argument("--print-resolved-config", action="store_true", help="Print the resolved render config as JSON and exit.")
    parser.add_argument("--validate-only", action="store_true", help="Validate and resolve the config without rendering.")
    parser.add_argument("--gallery", action="store_true", help="Render every configured variant and build a contact sheet.")
    parser.add_argument("--variant", help="Render only one named variant from the config.")
    parser.add_argument("--animation-preset", help="Apply a named render animation preset from config constants to the selected model.")
    parser.add_argument(
        "--output-mode",
        choices=OUTPUT_MODES,
        help="Choose retained artifacts: minimal keeps final images only, standard also keeps metadata, debug keeps all intermediates.",
    )
    discovery = parser.add_mutually_exclusive_group()
    discovery.add_argument("--list-models", action="store_true", help="List renderable models or variants in a config.")
    discovery.add_argument("--describe", metavar="MODEL", help="Describe one model or variant without rendering.")
    discovery.add_argument("--list-annotations", metavar="MODEL", help="List annotation groups and offsets for one model or variant.")
    discovery.add_argument(
        "--discover-annotations",
        metavar="SCAD_FILE",
        help="Read SCAD source and list parameters that can be added to annotation config.",
    )
    discovery.add_argument("--new-config", metavar="MODEL", help="Write an editable JSON or YAML config template for one model or variant.")
    parser.add_argument("--out", help="Output path used with --new-config or --discover-annotations.")
    parser.add_argument("--force", action="store_true", help="Allow --new-config to overwrite an existing output file.")
    parser.add_argument(
        "--set",
        action="append",
        default=[],
        dest="overrides",
        help="Override a config value with dotted path syntax, for example scene.objects[0].model.defines.hook_length=50.",
    )
    return parser


def parse_args() -> argparse.Namespace:
    parser = build_arg_parser()
    return normalize_command_aliases(parser.parse_args())


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args() if argv is None else parse_args_from(argv)
    try:
        return run(args)
    except ConfigError as exc:
        raise SystemExit(str(exc)) from exc


def parse_args_from(argv: Sequence[str]) -> argparse.Namespace:
    parser = build_arg_parser()
    return normalize_command_aliases(parser.parse_args(list(argv)))


def resolved_config_snapshot(
    *,
    config: Mapping[str, object],
    config_path: Path,
    config_dir: Path,
    args: argparse.Namespace,
) -> dict[str, object]:
    scene_config = resolve_scene(config.get("scene", {}))
    render_settings = resolve_render(config.get("render", {}))
    render_snapshot = dict(render_settings)
    render_snapshot["output_mode"] = output_mode_for(render_settings, args)
    render_snapshot["export_blend"] = export_blend_for(render_settings, args)
    annotation_config = require_mapping(config.get("annotations", {}), name="annotations")
    style_config = resolve_style(annotation_config.get("style"))
    expression_context = build_expression_context(config)
    blend_file = resolve_config_path(str(scene_config["blend_file"]), config_dir=config_dir, project_root=PROJECT_ROOT)
    object_specs = scene_object_specs(
        config=config,
        scene_config=scene_config,
        config_dir=config_dir,
        expression_context=expression_context,
        allow_deferred_transforms=True,
    )
    annotation_object_id = str(annotation_config.get("object") or object_specs[0]["id"])

    return {
        "job_name": sanitize_name(str(config.get("job_name") or base_job_name(config))),
        "config": project_relative_or_absolute(config_path),
        "output_root": project_relative_or_absolute(output_root_for(config, args)),
        "constants": expression_context,
        "scene": {
            "blend_file": str(blend_file),
            "blend_file_exists": blend_file.exists(),
            "camera": scene_config.get("camera"),
            "objects": [
                {
                    "id": str(object_spec["id"]),
                    "target_object": str(object_spec["target_object"]),
                    "source_type": str(object_spec.get("source_type") or "model"),
                    "scad_file": (
                        project_relative_or_absolute(Path(object_spec["scad_file"]))
                        if object_spec.get("scad_file") is not None
                        else None
                    ),
                    "scad_file_exists": (
                        Path(object_spec["scad_file"]).exists() if object_spec.get("scad_file") is not None else None
                    ),
                    "stl_file": (
                        project_relative_or_absolute(Path(object_spec["stl_file"]))
                        if object_spec.get("stl_file") is not None
                        else None
                    ),
                    "stl_file_exists": (
                        Path(object_spec["stl_file"]).exists() if object_spec.get("stl_file") is not None else None
                    ),
                    "defines": (
                        list(build_scad_defines(require_mapping(object_spec["model_config"], name="model")))
                        if object_spec.get("model_config") is not None
                        else []
                    ),
                    "expression_context": object_spec["expression_context"],
                    "inherit_target_transform": bool(object_spec["inherit_target_transform"]),
                    "transform": object_spec["transform"],
                    "transform_config": object_spec["object_scene_config"].get("transform"),
                    "replace_target_object": bool(object_spec["replace_target_object"]),
                    "material_source_object": object_spec.get("material_source_object"),
                    "material": object_spec.get("material"),
                    "mesh_shading": object_spec.get("mesh_shading")
                    or render_settings.get("mesh_shading", DEFAULT_RENDER_MESH_SHADING),
                }
                for object_spec in object_specs
            ],
        },
        "render": render_snapshot,
        "style": style_config,
        "annotation_object": annotation_object_id,
        "annotations": {
            "chains": [list(chain.get("ids", [])) for chain in chain_items_from_config(annotation_config)],
            "radius_callouts": [list(callout.get("ids", [])) for callout in radius_items_from_config(annotation_config)],
            "arc_callouts": [list(callout.get("ids", [])) for callout in arc_items_from_config(annotation_config)],
            "angle_radius_callouts": [
                {
                    "arc_id": callout.get("arc_id"),
                    "radius_id": callout.get("radius_id"),
                    "angle_id": callout.get("angle_id"),
                }
                for callout in angle_radius_items_from_config(annotation_config)
            ],
            "image_labels": [label.get("id") or label.get("text") for label in image_label_items_from_config(annotation_config)],
        },
        "config_data": {key: value for key, value in config.items() if key != INHERITED_VARIANTS_KEY},
    }


def scene_object_specs(
    *,
    config: Mapping[str, object],
    scene_config: Mapping[str, object],
    config_dir: Path,
    expression_context: Mapping[str, float],
    resolve_transforms: bool = True,
    allow_deferred_transforms: bool = False,
) -> list[dict[str, object]]:
    raw_objects = scene_config.get("objects")
    if raw_objects is None:
        raise ConfigError("scene.objects is required for renderable configs")

    if not isinstance(raw_objects, Sequence) or isinstance(raw_objects, (str, bytes)):
        raise ConfigError("scene.objects must be an array")
    object_defaults = scene_config.get("object_defaults")
    specs: list[dict[str, object]] = []
    seen_ids: set[str] = set()
    for index, object_config, copy_config in expanded_scene_object_configs(raw_objects, object_defaults=object_defaults):
        object_id = str(object_config["id"]).strip()
        if object_id in seen_ids:
            raise ConfigError(f"scene.objects[{index}].id duplicates expanded object id {object_id!r}")
        seen_ids.add(object_id)

        raw_model_config = object_config.get("model")
        raw_stl_file = object_config.get("stl_file")
        if raw_model_config is not None:
            source_type = "model"
            model_config = require_mapping(raw_model_config, name=f"scene.objects[{index}].model")
            object_context = build_expression_context_for_model(config, model_config)
            scad_file = resolve_config_path(
                str(model_config["scad_file"]),
                config_dir=config_dir,
                project_root=PROJECT_ROOT,
            )
            stl_file = None
        elif isinstance(raw_stl_file, str) and raw_stl_file.strip():
            source_type = "stl"
            model_config = None
            object_context = dict(expression_context)
            scad_file = None
            stl_file = resolve_config_path(raw_stl_file, config_dir=config_dir, project_root=PROJECT_ROOT)
        else:
            raise ConfigError(f"scene.objects[{index}] must define exactly one of model or stl_file")
        object_scene_config = dict(scene_config)
        object_scene_config.pop("objects", None)
        object_scene_config.pop("object_defaults", None)
        for key in ("inherit_target_transform", "replace_target_object", "transform"):
            if key in object_config:
                if key == "transform" and isinstance(object_scene_config.get("transform"), Mapping) and isinstance(object_config[key], Mapping):
                    object_scene_config[key] = deep_merge(object_scene_config["transform"], object_config[key])
                else:
                    object_scene_config[key] = object_config[key]
        if copy_config is not None:
            copy_indices = tuple(int(item) for item in copy_config["indices"])
            object_context["copy_index"] = float(copy_indices[0])
            object_context["copy_index_x"] = float(copy_indices[0])
            object_context["copy_index_y"] = float(copy_indices[1])
            object_context["copy_index_z"] = float(copy_indices[2])
            object_scene_config = add_copy_offset_to_scene_transform(
                object_scene_config,
                spacing_mm=copy_config.get("spacing_mm"),
                copy_indices=copy_indices,
                name=f"scene.objects[{object_id}]",
                config_name=str(copy_config.get("config_name") or "copies"),
            )
        inherit_target_transform = scene_inherits_target_transform(object_scene_config)
        object_transform = (
            resolve_scene_transform_for_object(
                object_scene_config,
                expression_context=object_context,
                name=f"scene.objects[{object_id}]",
                allow_deferred=allow_deferred_transforms,
            )
            if resolve_transforms
            else None
        )
        if not inherit_target_transform and object_scene_config.get("transform") is None:
            raise ConfigError(f"scene.objects[{index}].transform is required when inherit_target_transform is false")

        specs.append(
            {
                "id": object_id,
                "target_object": str(object_config.get("target_object") or object_id),
                "source_type": source_type,
                "model_config": model_config,
                "scad_file": scad_file,
                "stl_file": stl_file,
                "expression_context": object_context,
                "object_scene_config": object_scene_config,
                "inherit_target_transform": inherit_target_transform,
                "transform": object_transform,
                "replace_target_object": bool(object_scene_config.get("replace_target_object", True)),
                "material_source_object": object_config.get("material_source_object"),
                "material": object_config.get("material"),
                "mesh_shading": object_config.get("mesh_shading"),
            }
        )
    return specs


def resolve_scene_transform_for_object(
    scene_config: Mapping[str, object],
    *,
    expression_context: Mapping[str, float],
    name: str,
    allow_deferred: bool = False,
) -> dict[str, object] | None:
    try:
        return resolve_scene_transform(scene_config, expression_context=expression_context)
    except ConfigError as exc:
        if allow_deferred and "references unknown constant" in str(exc):
            return None
        raise ConfigError(f"{name}.transform could not be resolved: {exc}") from exc


def projection_points_for_object(points: Mapping[str, list[float]], *, object_id: str) -> dict[str, dict[str, object]]:
    return {key: {"object": object_id, "coords": coords} for key, coords in points.items()}


def openscad_stage_cache_key(
    *,
    scad_file: Path,
    defines: Sequence[str],
    executable: str,
) -> str:
    return cache_key_for(
        {
            "stage": "openscad_export_v1",
            "scad_file": project_relative_or_absolute(scad_file),
            "scad_sha256": file_sha256(scad_file),
            "defines": list(with_annotation_metadata_define(defines)),
            "executable": executable,
            "backend": "Manifold",
            "enable_textmetrics": True,
            "enable_lazy_union": True,
        }
    )


STL_BOUND_AXES = ("x", "y", "z")
ANNOTATION_BOUNDS_TOLERANCE_MM = 2.0


def read_stl_bounds(stl_path: Path) -> dict[str, dict[str, float]] | None:
    try:
        data = stl_path.read_bytes()
    except FileNotFoundError:
        return None

    vertices: list[tuple[float, float, float]] = []
    if len(data) >= 84:
        triangle_count = struct.unpack_from("<I", data, 80)[0]
        binary_length = 84 + triangle_count * 50
        if binary_length == len(data):
            offset = 84
            for _ in range(triangle_count):
                offset += 12  # normal
                for _ in range(3):
                    vertices.append(struct.unpack_from("<fff", data, offset))
                    offset += 12
                offset += 2  # attribute byte count

    if not vertices:
        text = data.decode("utf-8", errors="ignore")
        for line in text.splitlines():
            parts = line.strip().split()
            if len(parts) != 4 or parts[0].lower() != "vertex":
                continue
            try:
                vertices.append((float(parts[1]), float(parts[2]), float(parts[3])))
            except ValueError:
                continue

    if not vertices:
        return None

    mins = {axis: min(vertex[index] for vertex in vertices) for index, axis in enumerate(STL_BOUND_AXES)}
    maxs = {axis: max(vertex[index] for vertex in vertices) for index, axis in enumerate(STL_BOUND_AXES)}
    return {"min": mins, "max": maxs}


def annotation_vector_tuple(value: object) -> tuple[float, float, float] | None:
    if isinstance(value, Mapping):
        try:
            return (float(value["x"]), float(value["y"]), float(value["z"]))
        except (KeyError, TypeError, ValueError):
            return None
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes)) and len(value) == 3:
        try:
            return (float(value[0]), float(value[1]), float(value[2]))
        except (TypeError, ValueError):
            return None
    return None


def iter_annotation_points(annotation: Mapping[str, object]) -> list[tuple[str, tuple[float, float, float]]]:
    points: list[tuple[str, tuple[float, float, float]]] = []
    for field in ("start_mm", "end_mm", "anchor_mm", "center_mm", "edge_mm"):
        vector = annotation_vector_tuple(annotation.get(field))
        if vector is not None:
            points.append((field, vector))
    point_list = annotation.get("points_mm")
    if isinstance(point_list, Sequence) and not isinstance(point_list, (str, bytes)):
        for index, value in enumerate(point_list):
            vector = annotation_vector_tuple(value)
            if vector is not None:
                points.append((f"points_mm[{index}]", vector))
    return points


def point_outside_bounds_mm(point: tuple[float, float, float], bounds: Mapping[str, Mapping[str, float]]) -> float:
    mins = bounds.get("min", {})
    maxs = bounds.get("max", {})
    outside = 0.0
    for index, axis in enumerate(STL_BOUND_AXES):
        try:
            min_value = float(mins[axis])
            max_value = float(maxs[axis])
        except (KeyError, TypeError, ValueError):
            continue
        coordinate = point[index]
        if coordinate < min_value:
            outside = max(outside, min_value - coordinate)
        elif coordinate > max_value:
            outside = max(outside, coordinate - max_value)
    return outside


def audit_scad_annotation_bounds(
    annotations: Sequence[Mapping[str, object]],
    bounds: Mapping[str, Mapping[str, float]] | None,
    *,
    tolerance_mm: float = ANNOTATION_BOUNDS_TOLERANCE_MM,
    max_outliers: int = 20,
) -> dict[str, object]:
    audit: dict[str, object] = {
        "bounds_mm": bounds,
        "tolerance_mm": tolerance_mm,
        "outliers": [],
        "warnings": [],
    }
    if bounds is None:
        return audit

    outliers: list[dict[str, object]] = []
    for annotation in annotations:
        if annotation.get("kind") == "context":
            continue
        annotation_id = str(annotation.get("id") or "<unknown>")
        annotation_kind = str(annotation.get("kind") or "feature")
        for field, point in iter_annotation_points(annotation):
            outside_mm = point_outside_bounds_mm(point, bounds)
            if outside_mm <= tolerance_mm:
                continue
            outliers.append(
                {
                    "id": annotation_id,
                    "kind": annotation_kind,
                    "field": field,
                    "outside_mm": round(outside_mm, 3),
                    "point_mm": {axis: point[index] for index, axis in enumerate(STL_BOUND_AXES)},
                }
            )

    outliers.sort(key=lambda item: float(item["outside_mm"]), reverse=True)
    audit["outliers"] = outliers[:max_outliers]
    audit["warnings"] = [
        (
            "annotation anchor outside STL bounds: "
            f"{outlier['id']}.{outlier['field']} is {outlier['outside_mm']}mm outside"
        )
        for outlier in outliers[:max_outliers]
    ]
    return audit


def export_object_records(
    *,
    object_specs: Sequence[Mapping[str, object]],
    run_dir: Path,
    args: argparse.Namespace,
    cache_root: Path | None = None,
) -> tuple[list[dict[str, object]], dict[str, list[str]]]:
    object_records: list[dict[str, object]] = []
    openscad_commands: dict[str, list[str]] = {}
    shared_scad_context: dict[str, float] = {}
    for object_spec in object_specs:
        object_id = str(object_spec["id"])
        safe_object_id = sanitize_name(object_id)
        source_type = str(object_spec.get("source_type") or "model")
        base_context = dict(object_spec["expression_context"])
        base_context.update(shared_scad_context)

        if source_type == "stl":
            stl_path = Path(object_spec["stl_file"])
            openscad_log = None
            defines = ()
            scad_annotations = []
            scad_context: dict[str, float] = {}
            scad_value_context: dict[str, str] = {}
            object_context = base_context
            cache_info = {"stage": "source_stl", "enabled": False, "hit": False}
        else:
            stl_path = run_dir / f"{safe_object_id}.stl"
            openscad_log = run_dir / f"openscad_export__{safe_object_id}.log"
            model_config = require_mapping(object_spec["model_config"], name=f"scene.objects[{object_id}].model")
            scad_file = Path(object_spec["scad_file"])
            defines = build_scad_defines(model_config)
            openscad_command = build_openscad_command(
                executable=args.openscad,
                scad_file=scad_file,
                output_path=stl_path,
                defines=with_annotation_metadata_define(defines),
            )
            cache_info = {"stage": "openscad", "enabled": cache_root is not None, "hit": False}
            cached_stl = None
            cached_log = None
            if cache_root is not None:
                key = openscad_stage_cache_key(scad_file=scad_file, defines=defines, executable=str(openscad_command[0]))
                cache_info["key"] = key
                cache_dir = cache_root / "openscad" / key
                cached_stl = cache_dir / "model.stl"
                cached_log = cache_dir / "openscad_export.log"
                if cached_stl.exists() and cached_log.exists():
                    shutil.copy2(cached_stl, stl_path)
                    shutil.copy2(cached_log, openscad_log)
                    cache_info["hit"] = True
            if not cache_info["hit"]:
                openscad_result = run_command_logged(openscad_command, cwd=PROJECT_ROOT, log_path=openscad_log)
                if openscad_result.returncode != 0:
                    raise SystemExit(
                        command_failure_message(
                            f"OpenSCAD export failed for object {object_id}",
                            log_path=openscad_log,
                        )
                    )
                if not stl_path.exists():
                    raise SystemExit(
                        command_failure_message(
                            f"OpenSCAD export did not create STL for object {object_id}",
                            log_path=openscad_log,
                        )
                    )
                if cached_stl is not None and cached_log is not None:
                    cached_stl.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(stl_path, cached_stl)
                    shutil.copy2(openscad_log, cached_log)
            openscad_commands[object_id] = openscad_command
            scad_annotations = read_scad_annotations(openscad_log)
            scad_context = numeric_context_from_scad_annotations(scad_annotations)
            scad_value_context = value_context_from_scad_annotations(scad_annotations)
            object_context = dict(base_context)
            object_context.update(scad_context)
        object_scene_config = require_mapping(
            object_spec["object_scene_config"],
            name=f"scene.objects[{object_id}]",
        )
        object_transform = object_spec["transform"]
        if not object_spec["inherit_target_transform"]:
            object_transform = resolve_scene_transform_for_object(
                object_scene_config,
                expression_context=object_context,
                name=f"scene.objects[{object_id}]",
            )
            if object_transform is None:
                raise ConfigError(f"scene.objects[{object_id}].transform is required when inherit_target_transform is false")

        stl_bounds = read_stl_bounds(stl_path)
        annotation_bounds_audit = audit_scad_annotation_bounds(scad_annotations, stl_bounds)
        object_record = dict(object_spec)
        object_record.update(
            {
                "stl_path": stl_path,
                "openscad_log": openscad_log,
                "defines": defines,
                "scad_annotations": scad_annotations,
                "scad_context": scad_context,
                "scad_value_context": scad_value_context,
                "stl_bounds_mm": stl_bounds,
                "annotation_bounds_audit": annotation_bounds_audit,
                "expression_context": object_context,
                "transform": object_transform,
                "cache": cache_info,
            }
        )
        object_records.append(object_record)
        shared_scad_context.update(scad_context)
    return object_records, openscad_commands


def label_value_context_for_record(record: Mapping[str, object]) -> dict[str, object]:
    context: dict[str, object] = {}
    model_config = record.get("model_config")
    defines = model_config.get("defines", {}) if isinstance(model_config, Mapping) else {}
    if isinstance(defines, Mapping):
        context.update({str(name): value for name, value in defines.items()})
    scad_value_context = record.get("scad_value_context")
    if isinstance(scad_value_context, Mapping):
        context.update({str(name): value for name, value in scad_value_context.items()})
    return context


def collect_annotation_render_state(
    *,
    config: Mapping[str, object],
    annotation_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float],
    object_records: Sequence[Mapping[str, object]],
) -> dict[str, object]:
    aliases = aliases_from_config(annotation_config)
    annotation_object_id = str(annotation_config.get("object") or object_records[0]["id"])
    annotation_record = next((record for record in object_records if str(record["id"]) == annotation_object_id), None)
    if annotation_record is None:
        raise ConfigError(f"annotations.object references unknown scene object {annotation_object_id!r}")

    scad_annotations = annotation_record["scad_annotations"]
    annotation_expression_context = annotation_record.get("expression_context", expression_context)
    chain_items = chain_items_from_config(annotation_config)
    radius_items = radius_items_from_config(annotation_config)
    arc_items = arc_items_from_config(annotation_config)
    angle_radius_items = angle_radius_items_from_config(annotation_config)
    image_label_items = image_label_items_from_config(annotation_config)
    chains = [
        collect_dimension_chain(
            annotations=scad_annotations,
            chain_config=chain,
            style_config=style_config,
            expression_context=annotation_expression_context,
            aliases=aliases,
        )
        for chain in chain_items
    ]
    radius_groups = [
        collect_radius_callouts(
            annotations=scad_annotations,
            callout_config=callout,
            style_config=style_config,
            expression_context=annotation_expression_context,
            aliases=aliases,
        )
        for callout in radius_items
    ]
    arc_groups = [
        collect_arc_callouts(
            annotations=scad_annotations,
            callout_config=callout,
            style_config=style_config,
            expression_context=annotation_expression_context,
            aliases=aliases,
        )
        for callout in arc_items
    ]
    angle_radius_groups = [
        collect_angle_radius_callouts(
            annotations=scad_annotations,
            callout_config=callout,
            style_config=style_config,
            expression_context=annotation_expression_context,
            aliases=aliases,
        )
        for callout in angle_radius_items
    ]
    chain_pairs = [(item, group) for item, group in zip(chain_items, chains, strict=True) if group]
    radius_pairs = [(item, group) for item, group in zip(radius_items, radius_groups, strict=True) if group]
    arc_pairs = [(item, group) for item, group in zip(arc_items, arc_groups, strict=True) if group]
    angle_radius_pairs = [
        (item, group) for item, group in zip(angle_radius_items, angle_radius_groups, strict=True) if group
    ]
    image_labels = collect_image_labels(
        labels_config=image_label_items,
        annotation_config=annotation_config,
        style_config=style_config,
        expression_context=annotation_expression_context,
        value_context=label_value_context_for_record(annotation_record),
    )
    return {
        "annotation_object_id": annotation_object_id,
        "scad_annotations": scad_annotations,
        "chain_pairs": chain_pairs,
        "radius_pairs": radius_pairs,
        "arc_pairs": arc_pairs,
        "angle_radius_pairs": angle_radius_pairs,
        "active_chains": [group for _, group in chain_pairs],
        "active_radius_groups": [group for _, group in radius_pairs],
        "active_arc_groups": [group for _, group in arc_pairs],
        "active_angle_radius_groups": [group for _, group in angle_radius_pairs],
        "image_labels": image_labels,
    }


def build_projection_points_for_annotations(annotation_state: Mapping[str, object]) -> dict[str, dict[str, object]]:
    annotation_object_id = str(annotation_state["annotation_object_id"])
    projection_points: dict[str, dict[str, object]] = {}
    for chain_segments in annotation_state["active_chains"]:
        projection_points.update(projection_points_for_object(projection_points_for_segments(chain_segments), object_id=annotation_object_id))
    for radius_callouts in annotation_state["active_radius_groups"]:
        projection_points.update(projection_points_for_object(projection_points_for_radius_callouts(radius_callouts), object_id=annotation_object_id))
    for arc_callouts in annotation_state["active_arc_groups"]:
        projection_points.update(projection_points_for_object(projection_points_for_arc_callouts(arc_callouts), object_id=annotation_object_id))
    for angle_radius_callouts in annotation_state["active_angle_radius_groups"]:
        projection_points.update(
            projection_points_for_object(
                projection_points_for_angle_radius_callouts(angle_radius_callouts),
                object_id=annotation_object_id,
            )
        )
    return projection_points


def render_setting(
    render_settings: Mapping[str, object],
    preset_settings: Mapping[str, object],
    key: str,
    default: object = None,
) -> object:
    return render_settings[key] if key in render_settings else preset_settings.get(key, default)


def scalar_render_setting(
    value: object,
    *,
    default: float,
    name: str,
    context: Mapping[str, float],
) -> float:
    if value is None:
        value = default
    return eval_numeric_expression(value, context=context, name=name)


def material_for_object(record: Mapping[str, object], render_settings: Mapping[str, object]) -> object:
    material = record.get("material")
    overrides = render_settings.get("material_overrides")
    if not isinstance(overrides, Mapping):
        return material
    override = overrides.get(str(record["id"]))
    if override is None:
        return material
    if isinstance(material, Mapping) and isinstance(override, Mapping):
        return deep_merge(material, override)
    return override


def resolve_scene_edit_config(
    value: object,
    *,
    scalar_keys: Sequence[str] = (),
    scalar_keys_mm: Sequence[str] = (),
    expression_context: Mapping[str, float],
    name: str,
) -> object:
    if value is None or isinstance(value, bool) or isinstance(value, str):
        return value
    if not isinstance(value, Mapping):
        return value
    resolved = dict(value)
    for key in scalar_keys_mm:
        if key in resolved:
            resolved[key] = eval_numeric_expression(
                resolved[key],
                context=expression_context,
                name=f"{name}.{key}",
            )
    for key in scalar_keys:
        if key in resolved:
            resolved[key] = eval_numeric_expression(
                resolved[key],
                context=expression_context,
                name=f"{name}.{key}",
            )
    section_plane = resolved.get("section_plane")
    if isinstance(section_plane, Mapping):
        section_resolved = dict(section_plane)
        for key in ("padding_mm", "offset_mm"):
            if key in section_resolved:
                section_resolved[key] = eval_numeric_expression(
                    section_resolved[key],
                    context=expression_context,
                    name=f"{name}.section_plane.{key}",
                )
        resolved["section_plane"] = section_resolved
    return resolved


def build_blender_config(
    *,
    scene_config: Mapping[str, object],
    render_settings: Mapping[str, object],
    object_records: Sequence[Mapping[str, object]],
    projection_points: Mapping[str, object],
    render_path: Path,
    projection_path: Path,
    animation_config: Mapping[str, object] | None,
    animation_frame_dir: Path | None,
    expression_context: Mapping[str, float],
    export_blend_path: Path | None = None,
) -> dict[str, object]:
    camera_view_preset = str(render_settings.get("camera_view_preset") or "")
    camera_preset_settings = CAMERA_VIEW_PRESETS.get(camera_view_preset, {})
    camera_lens_value = (
        render_settings.get("camera_lens_mm")
        if "camera_lens_mm" in render_settings
        else render_settings.get("camera_focal_length_mm")
    )
    default_render_settings = RENDER_PRESETS[DEFAULT_RENDER_PRESET_NAME]
    blender_config: dict[str, object] = {
        "objects": [
            {
                "id": str(record["id"]),
                "stl_path": str(record["stl_path"]),
                "target_object": str(record["target_object"]),
                "replace_target_object": bool(record["replace_target_object"]),
                "inherit_target_transform": bool(record["inherit_target_transform"]),
                "object_transform": record["transform"],
                "material_source_object": record.get("material_source_object"),
                "material": material_for_object(record, render_settings),
                "default_material_color": render_settings.get(
                    "default_material_color", default_render_settings.get("default_material_color")
                ),
                "mesh_shading": str(
                    record.get("mesh_shading") or render_settings.get("mesh_shading", default_render_settings["mesh_shading"])
                ),
            }
            for record in object_records
        ],
        "camera_name": scene_config.get("camera"),
        "render_path": str(render_path),
        "projection_path": str(projection_path),
        "projection_points": projection_points,
        "render_defaults": dict(default_render_settings),
        "width": int(render_settings.get("width", default_render_settings["width"])),
        "height": int(render_settings.get("height", default_render_settings["height"])),
        "render_engine": str(render_settings.get("engine", default_render_settings["engine"])),
        "quality": str(render_settings.get("quality", default_render_settings["quality"])),
        "fit_camera": bool(render_settings.get("fit_camera", default_render_settings["fit_camera"])),
        "fit_margin": float(render_settings.get("fit_margin", default_render_settings["fit_margin"])),
        "camera_location_offset": [
            value / 1000.0
            for value in vector3(
                render_settings.get("camera_location_offset_mm"),
                default=(0.0, 0.0, 0.0),
                name="render.camera_location_offset_mm",
                context=expression_context,
            )
        ],
        "camera_target_offset": [
            value / 1000.0
            for value in vector3(
                render_setting(render_settings, camera_preset_settings, "camera_target_offset_mm"),
                default=(0.0, 0.0, 0.0),
                name="render.camera_target_offset_mm",
                context=expression_context,
            )
        ],
        "camera_rotation": (
            list(
                vector3(
                    render_setting(render_settings, camera_preset_settings, "camera_rotation_deg"),
                    name="render.camera_rotation_deg",
                    context=expression_context,
                )
            )
            if "camera_rotation_deg" in render_settings or "camera_rotation_deg" in camera_preset_settings
            else None
        ),
        "camera_rotation_offset": list(
            vector3(
                render_setting(render_settings, camera_preset_settings, "camera_rotation_offset_deg"),
                default=(0.0, 0.0, 0.0),
                name="render.camera_rotation_offset_deg",
                context=expression_context,
            )
        ),
        "camera_orbit": list(
            vector2(
                render_setting(render_settings, camera_preset_settings, "camera_orbit_deg"),
                default=(0.0, 0.0),
                name="render.camera_orbit_deg",
                context=expression_context,
            )
        ),
        "camera_distance_scale": scalar_render_setting(
            render_setting(render_settings, camera_preset_settings, "camera_distance_scale"),
            default=1.0,
            name="render.camera_distance_scale",
            context=expression_context,
        ),
        "camera_roll": scalar_render_setting(
            render_setting(render_settings, camera_preset_settings, "camera_roll_deg"),
            default=0.0,
            name="render.camera_roll_deg",
            context=expression_context,
        ),
        "camera_lens": (
            scalar_render_setting(
                camera_lens_value,
                default=50.0,
                name="render.camera_lens_mm",
                context=expression_context,
            )
            if camera_lens_value is not None
            else None
        ),
        "camera_look_at": str(render_settings.get("camera_look_at", "none")),
        "camera_view": str(render_setting(render_settings, camera_preset_settings, "camera_view", "none")),
        "camera_view_preset": camera_view_preset or None,
        "lighting": render_settings.get("lighting"),
        "outline": render_settings.get("outline"),
        "ground_plane": resolve_scene_edit_config(
            render_settings.get("ground_plane"),
            scalar_keys_mm=("offset_mm",),
            expression_context=expression_context,
            name="render.ground_plane",
        ),
        "cutaway": resolve_scene_edit_config(
            render_settings.get("cutaway"),
            scalar_keys_mm=("position_mm", "offset_mm"),
            scalar_keys=("position_fraction",),
            expression_context=expression_context,
            name="render.cutaway",
        ),
        "xray": render_settings.get("xray"),
        "mesh_shading": str(render_settings.get("mesh_shading", default_render_settings["mesh_shading"])),
    }
    if export_blend_path is not None:
        blender_config["export_blend_path"] = str(export_blend_path)
    if animation_config:
        assert animation_frame_dir is not None
        animation_frame_dir.mkdir(parents=True, exist_ok=True)
        blender_config["animation"] = animation_config
        blender_config["animation_frame_path"] = str(animation_frame_dir / "frame_")
    return blender_config


def normalized_blender_cache_config(blender_config: Mapping[str, object]) -> dict[str, object]:
    normalized = deepcopy(dict(blender_config))
    normalized["render_path"] = "<render>"
    normalized["projection_path"] = "<projection>"
    normalized.pop("export_blend_path", None)
    normalized.pop("animation_frame_path", None)
    objects = normalized.get("objects")
    if isinstance(objects, list):
        normalized_objects = []
        for item in objects:
            if not isinstance(item, Mapping):
                normalized_objects.append(item)
                continue
            normalized_item = deepcopy(dict(item))
            stl_path = Path(str(normalized_item.get("stl_path", "")))
            if stl_path.exists():
                normalized_item["stl_path"] = {
                    "name": stl_path.name,
                    "sha256": file_sha256(stl_path),
                }
            normalized_objects.append(normalized_item)
        normalized["objects"] = normalized_objects
    return normalized


def blender_stage_cache_key(
    *,
    blender: str,
    blend_file: Path,
    blender_config: Mapping[str, object],
) -> str:
    return cache_key_for(
        {
            "stage": "blender_render_projection_v1",
            "blender": blender,
            "blend_file": project_relative_or_absolute(blend_file),
            "blend_file_sha256": file_sha256(blend_file),
            "runtime_sha256": file_sha256(UTILITY_ROOT / "blender_runtime.py"),
            "config": normalized_blender_cache_config(blender_config),
        }
    )


def run_blender_scene(
    *,
    blender: str,
    blend_file: Path,
    blender_config: Mapping[str, object],
    blender_config_path: Path,
    blender_script_path: Path,
    blender_log: Path,
    render_path: Path,
    projection_path: Path,
    cache_root: Path | None = None,
) -> tuple[list[str], dict[str, object]]:
    blender_config_path.write_text(json.dumps(blender_config, indent=2) + "\n", encoding="utf-8")
    write_blender_scene_script(blender_script_path)
    blender_command = [blender, "--background", str(blend_file), "--python", str(blender_script_path)]
    raw_export_blend_path = blender_config.get("export_blend_path")
    export_blend_path = Path(str(raw_export_blend_path)) if raw_export_blend_path else None
    cache_info: dict[str, object] = {
        "stage": "blender",
        "enabled": cache_root is not None and "animation" not in blender_config,
        "hit": False,
    }
    if cache_root is not None and "animation" in blender_config:
        cache_info["disabled_reason"] = "animation"
    cached_render = None
    cached_projection = None
    cached_log = None
    cached_blend = None
    if cache_info["enabled"]:
        key = blender_stage_cache_key(
            blender=blender,
            blend_file=blend_file,
            blender_config=blender_config,
        )
        cache_info["key"] = key
        cache_dir = cache_root / "blender" / key
        cached_render = cache_dir / "render.png"
        cached_projection = cache_dir / "projection.json"
        cached_log = cache_dir / "blender.log"
        cached_blend = cache_dir / "scene.blend"
        cache_hit_ready = cached_render.exists() and cached_projection.exists()
        if export_blend_path is not None:
            cache_hit_ready = cache_hit_ready and cached_blend.exists()
        if cache_hit_ready:
            shutil.copy2(cached_render, render_path)
            shutil.copy2(cached_projection, projection_path)
            if export_blend_path is not None:
                export_blend_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(cached_blend, export_blend_path)
            if cached_log.exists():
                shutil.copy2(cached_log, blender_log)
            else:
                blender_log.write_text(f"Blender cache hit: {key}\n", encoding="utf-8")
            cache_info["hit"] = True
            return blender_command, cache_info
    with blender_log.open("w", encoding="utf-8", errors="replace") as log_handle:
        blender_result = subprocess.run(
            blender_command,
            cwd=PROJECT_ROOT,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            check=False,
        )
    if blender_result.returncode != 0 or not render_path.exists() or not projection_path.exists():
        raise SystemExit(command_failure_message("Blender scene render failed", log_path=blender_log))
    if export_blend_path is not None and not export_blend_path.exists():
        raise SystemExit(command_failure_message("Blender scene export failed", log_path=blender_log))
    if cached_render is not None and cached_projection is not None:
        cached_render.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(render_path, cached_render)
        shutil.copy2(projection_path, cached_projection)
        if export_blend_path is not None and cached_blend is not None:
            shutil.copy2(export_blend_path, cached_blend)
        if cached_log is not None:
            shutil.copy2(blender_log, cached_log)
    return blender_command, cache_info


def encode_animation_artifacts(
    *,
    animation_config: Mapping[str, object] | None,
    animation_frame_dir: Path | None,
    animation_path: Path | None,
    blender_log: Path,
) -> list[Path]:
    if not animation_config or animation_frame_dir is None:
        return []
    animation_frames = sorted(animation_frame_dir.glob("*.png"))
    if not animation_frames:
        raise SystemExit(command_failure_message("Blender animation render failed", log_path=blender_log))
    if animation_path is not None:
        encode_animation_gif(
            frame_paths=animation_frames,
            output_path=animation_path,
            fps=int(animation_config.get("fps", 24)),
            width_px=int(animation_config.get("gif_width_px", 0)),
        )
    return animation_frames


def overlay_step_path(*, index: int, total: int, annotated_path: Path, run_dir: Path) -> Path:
    return annotated_path if index == total else run_dir / f"annotated_step_{index}.png"


def apply_annotation_overlays(
    *,
    render_path: Path,
    annotated_path: Path,
    run_dir: Path,
    projection: Mapping[str, object],
    style_config: Mapping[str, object],
    annotation_state: Mapping[str, object],
) -> dict[str, object]:
    current_input = render_path
    chain_overlays = []
    radius_overlays = []
    arc_overlays = []
    angle_radius_overlays = []
    image_label_overlay = None
    active_chains = annotation_state["active_chains"]
    active_radius_groups = annotation_state["active_radius_groups"]
    active_arc_groups = annotation_state["active_arc_groups"]
    active_angle_radius_groups = annotation_state["active_angle_radius_groups"]
    image_labels = annotation_state["image_labels"]
    total_overlay_steps = (
        (1 if active_chains else 0)
        + len(active_radius_groups)
        + len(active_arc_groups)
        + len(active_angle_radius_groups)
        + (1 if image_labels else 0)
    )
    overlay_index = 0
    if active_chains:
        overlay_index += 1
        output_path = overlay_step_path(index=overlay_index, total=total_overlay_steps, annotated_path=annotated_path, run_dir=run_dir)
        chain_overlays = draw_dimension_chains_overlay(
            render_path=current_input,
            output_path=output_path,
            projection=projection,
            chains=[
                DimensionChainOverlaySpec(
                    segments=chain_segments,
                    line_offset_px=float(chain_config.get("line_offset_px", 0.0)),
                    label_offset_px=float(chain_config.get("label_offset_px", 40.0)),
                    style_config=style_for_group(style_config, chain_config),
                    label_along_offset_px=float(chain_config.get("label_along_offset_px", 0.0)),
                )
                for chain_config, chain_segments in annotation_state["chain_pairs"]
            ],
        )
        current_input = output_path
    for arc_config, arc_callouts in annotation_state["arc_pairs"]:
        overlay_index += 1
        output_path = overlay_step_path(index=overlay_index, total=total_overlay_steps, annotated_path=annotated_path, run_dir=run_dir)
        overlay = draw_arc_callout_overlay(
            render_path=current_input,
            output_path=output_path,
            projection=projection,
            callouts=arc_callouts,
            label_offset_px=float(arc_config.get("label_offset_px", 42.0)),
            show_label=bool(arc_config.get("show_label", True)),
            style_config=style_for_group(style_config, arc_config),
        )
        arc_overlays.append(overlay)
        current_input = output_path
    for radius_config, radius_callouts in annotation_state["radius_pairs"]:
        overlay_index += 1
        output_path = overlay_step_path(index=overlay_index, total=total_overlay_steps, annotated_path=annotated_path, run_dir=run_dir)
        overlay = draw_radius_callout_overlay(
            render_path=current_input,
            output_path=output_path,
            projection=projection,
            callouts=radius_callouts,
            label_offset_px=float(radius_config.get("label_offset_px", 55.0)),
            style_config=style_for_group(style_config, radius_config),
        )
        radius_overlays.append(overlay)
        current_input = output_path
    for callout_config, angle_radius_callouts in annotation_state["angle_radius_pairs"]:
        overlay_index += 1
        output_path = overlay_step_path(index=overlay_index, total=total_overlay_steps, annotated_path=annotated_path, run_dir=run_dir)
        overlay = draw_angle_radius_callout_overlay(
            render_path=current_input,
            output_path=output_path,
            projection=projection,
            callouts=angle_radius_callouts,
            angle_label_offset_px=float(callout_config.get("angle_label_offset_px", 36.0)),
            radius_label_offset_px=float(callout_config.get("radius_label_offset_px", 34.0)),
            angle_label_tangent_offset_px=float(callout_config.get("angle_label_tangent_offset_px", 0.0)),
            radius_label_tangent_offset_px=float(callout_config.get("radius_label_tangent_offset_px", 0.0)),
            show_angle_label=bool(callout_config.get("show_angle_label", True)),
            show_radius_label=bool(callout_config.get("show_radius_label", True)),
            style_config=style_for_group(style_config, callout_config),
        )
        angle_radius_overlays.append(overlay)
        current_input = output_path
    if image_labels:
        overlay_index += 1
        output_path = overlay_step_path(index=overlay_index, total=total_overlay_steps, annotated_path=annotated_path, run_dir=run_dir)
        image_label_overlay = draw_image_label_overlay(
            render_path=current_input,
            output_path=output_path,
            labels=image_labels,
            style_config=style_config,
        )
        current_input = output_path

    if total_overlay_steps == 0:
        shutil.copyfile(render_path, annotated_path)
    return {
        "chains": chain_overlays,
        "radius_callouts": radius_overlays,
        "arc_callouts": arc_overlays,
        "angle_radius_callouts": angle_radius_overlays,
        "image_labels": image_label_overlay,
    }


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


def render_config(
    *,
    config: Mapping[str, object],
    config_path: Path,
    config_dir: Path,
    args: argparse.Namespace,
    run_dir: Path | None = None,
) -> dict[str, object]:
    scene_config = resolve_scene(config.get("scene", {}))
    render_settings = resolve_render(config.get("render", {}))
    annotation_config = require_mapping(config.get("annotations", {}), name="annotations")
    style_config = resolve_style(annotation_config.get("style"))
    expression_context = build_expression_context(config)

    blend_file = resolve_config_path(str(scene_config["blend_file"]), config_dir=config_dir, project_root=PROJECT_ROOT)
    object_specs = scene_object_specs(
        config=config,
        scene_config=scene_config,
        config_dir=config_dir,
        expression_context=expression_context,
        resolve_transforms=False,
    )
    for object_spec in object_specs:
        if object_spec.get("scad_file") is not None:
            scad_file = Path(object_spec["scad_file"])
            if not scad_file.exists():
                raise ConfigError(f"SCAD file not found for object {object_spec['id']}: {scad_file}")
        elif object_spec.get("stl_file") is not None:
            stl_file = Path(object_spec["stl_file"])
            if not stl_file.exists():
                raise ConfigError(f"STL file not found for object {object_spec['id']}: {stl_file}")
    if not blend_file.exists():
        raise ConfigError(f"Blender scene not found: {blend_file}")
    if args.validate_only:
        print(f"Config OK: {project_relative_or_absolute(config_path)}")
        print(f"Scene:     {blend_file}")
        for object_spec in object_specs:
            source_path = object_spec.get("scad_file") or object_spec.get("stl_file")
            print(f"Object:    {object_spec['id']} -> {project_relative_or_absolute(Path(source_path))}")
        return {
            "job_name": base_job_name(config),
            "validated": True,
            "config": config,
            "objects": object_specs,
            "blend_file": blend_file,
        }

    exact_output_file = output_file_from_args(args)
    blender = require_blender_executable(args.blender)
    job_name = sanitize_name(str(config.get("job_name") or base_job_name(config)))
    output_mode = output_mode_for(render_settings, args)
    export_blend = export_blend_for(render_settings, args)
    cache_root = cache_root_for(config, render_settings, args)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    run_name = f"{job_name}__{timestamp}"
    output_parent = run_dir if run_dir is not None else output_root_for(config, args)
    output_dir = output_parent / scad_output_folder_name(object_specs)
    debug_dir = output_dir / "debug" / work_dir_name(job_name=job_name, timestamp=timestamp)
    output_dir.mkdir(parents=True, exist_ok=True)
    debug_dir.mkdir(parents=True, exist_ok=True)
    run_dir = debug_dir

    object_records, openscad_commands = export_object_records(
        object_specs=object_specs,
        run_dir=run_dir,
        args=args,
        cache_root=cache_root,
    )
    animation_config = resolve_animation_config(render_settings.get("animation"), object_records=object_records)
    annotation_state = collect_annotation_render_state(
        config=config,
        annotation_config=annotation_config,
        style_config=style_config,
        expression_context=expression_context,
        object_records=object_records,
    )
    projection_points = build_projection_points_for_annotations(annotation_state)

    render_path = run_dir / "render.png"
    annotated_path = exact_output_file or (output_dir / f"{run_name}.png")
    export_blend_path = annotated_path.with_suffix(".blend") if export_blend else None
    animation_frame_dir = run_dir / "animation_frames" if animation_config else None
    animation_path = (
        output_dir / f"{run_name}.gif"
        if animation_config and str(animation_config.get("output_format")) == "gif"
        else None
    )
    projection_path = run_dir / "proj.json"
    blender_config_path = run_dir / "cfg.json"
    blender_script_path = run_dir / "run.py"
    blender_log = run_dir / "blender.log"

    blender_config = build_blender_config(
        scene_config=scene_config,
        render_settings=render_settings,
        object_records=object_records,
        projection_points=projection_points,
        render_path=render_path,
        projection_path=projection_path,
        animation_config=animation_config,
        animation_frame_dir=animation_frame_dir,
        expression_context=expression_context,
        export_blend_path=export_blend_path,
    )
    blender_command, blender_cache_info = run_blender_scene(
        blender=blender,
        blend_file=blend_file,
        blender_config=blender_config,
        blender_config_path=blender_config_path,
        blender_script_path=blender_script_path,
        blender_log=blender_log,
        render_path=render_path,
        projection_path=projection_path,
        cache_root=cache_root,
    )
    encode_animation_artifacts(
        animation_config=animation_config,
        animation_frame_dir=animation_frame_dir,
        animation_path=animation_path,
        blender_log=blender_log,
    )

    projection = json.loads(projection_path.read_text(encoding="utf-8"))
    overlays = apply_annotation_overlays(
        render_path=render_path,
        annotated_path=annotated_path,
        run_dir=run_dir,
        projection=projection,
        style_config=style_config,
        annotation_state=annotation_state,
    )
    warnings = annotation_bounds_quality_warnings(object_records)
    warnings.extend(overlay_quality_warnings(overlays))
    if warnings:
        overlays["warnings"] = warnings

    metadata_path = (
        annotated_path.with_name(f"{annotated_path.stem}.metadata.json")
        if exact_output_file is not None
        else output_dir / f"{run_name}.metadata.json"
    )
    metadata = build_render_metadata(
        job_name=job_name,
        output_mode=output_mode,
        config_path=config_path,
        expression_context=expression_context,
        blend_file=blend_file,
        scene_config=scene_config,
        object_records=object_records,
        blender_config=blender_config,
        style_config=style_config,
        annotation_state=annotation_state,
        projection=projection,
        overlays=overlays,
        output_dir=output_dir,
        run_dir=run_dir,
        render_path=render_path,
        annotated_path=annotated_path,
        metadata_path=metadata_path,
        export_blend_path=export_blend_path,
        animation_path=animation_path,
        animation_frame_dir=animation_frame_dir,
        projection_path=projection_path,
        blender_log=blender_log,
        openscad_commands=openscad_commands,
        blender_command=blender_command,
        cache_info={
            "root": project_relative_or_absolute(cache_root) if cache_root is not None else None,
            "objects": {str(record["id"]): record.get("cache") for record in object_records},
            "blender": blender_cache_info,
        },
    )
    if output_mode != "minimal":
        metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    remove_debug_artifacts(output_mode=output_mode, debug_dir=run_dir, output_dir=output_dir)

    print(f"Output folder: {project_relative_or_absolute(output_dir)}")
    print(f"Annotated:    {project_relative_or_absolute(annotated_path)}")
    if cache_root is not None:
        openscad_cache_records = [
            record
            for record in object_records
            if isinstance(record.get("cache"), Mapping) and record["cache"].get("stage") == "openscad"
        ]
        object_hits = sum(1 for record in openscad_cache_records if record["cache"].get("hit"))
        blender_hit = bool(blender_cache_info.get("hit"))
        print(f"Cache:        OpenSCAD {object_hits}/{len(openscad_cache_records)} hit, Blender {'hit' if blender_hit else 'miss'}")
    for warning in warnings:
        print(f"Warning:      {warning}")
    if animation_path is not None:
        print(f"Animation:    {project_relative_or_absolute(animation_path)}")
    elif animation_frame_dir is not None and output_mode == "debug":
        print(f"Frames:       {project_relative_or_absolute(animation_frame_dir)}")
    if export_blend_path is not None:
        print(f"Blend:        {project_relative_or_absolute(export_blend_path)}")
    if output_mode != "minimal":
        print(f"Metadata:     {project_relative_or_absolute(metadata_path)}")
    if output_mode == "debug":
        print(f"Debug:        {project_relative_or_absolute(run_dir)}")
    result = {
        "job_name": job_name,
        "run_dir": output_dir,
        "debug_dir": run_dir if output_mode == "debug" else None,
        "render": render_path if output_mode == "debug" else None,
        "annotated": annotated_path,
        "metadata": metadata_path if output_mode != "minimal" else None,
        "blend": export_blend_path,
        "output_mode": output_mode,
        "cache": {
            "root": cache_root,
            "objects": {str(record["id"]): record.get("cache") for record in object_records},
            "blender": blender_cache_info,
        },
    }
    if animation_path is not None:
        result["animation"] = animation_path
    elif animation_frame_dir is not None:
        result["animation_frames"] = animation_frame_dir
    return result


def compact_gallery_config(raw_gallery: object, *, name: str) -> dict[str, object]:
    if raw_gallery is None:
        return {}
    if not isinstance(raw_gallery, Mapping):
        raise ConfigError(f"{name} must be an object")
    return {
        str(key): value
        for key, value in raw_gallery.items()
        if key != "$schema"
    }


def gallery_settings(
    config: Mapping[str, object],
    *,
    gallery_config: Mapping[str, object] | None = None,
    variant_count: int | None = None,
) -> dict[str, int]:
    merged_gallery = compact_gallery_config(gallery_config or {}, name="gallery config")
    raw_gallery = config.get("gallery", {})
    merged_gallery.update(compact_gallery_config(raw_gallery, name="gallery"))
    settings = {
        key: int(merged_gallery.get(key, default))
        for key, default in GALLERY_SETTING_DEFAULTS.items()
    }
    for key in ("target_width_px", "target_height_px"):
        if key in merged_gallery:
            settings[key] = int(merged_gallery[key])
    for key in ("columns", "thumbnail_width", "title_font_size_px"):
        if settings[key] < 1:
            raise ConfigError(f"gallery.{key} must be at least 1")
    for key in ("margin_px", "gutter_px", "title_height_px"):
        if settings[key] < 0:
            raise ConfigError(f"gallery.{key} must be at least 0")
    target_keys = {"target_width_px", "target_height_px"}
    present_target_keys = target_keys & settings.keys()
    if present_target_keys:
        if present_target_keys != target_keys:
            raise ConfigError("gallery.target_width_px and gallery.target_height_px must be set together")
        for key in target_keys:
            if settings[key] < 1:
                raise ConfigError(f"gallery.{key} must be at least 1")
        if variant_count is None:
            raise ConfigError("gallery target sizing requires a variant count")
        apply_gallery_target_size(settings, variant_count=variant_count)
    return settings


def apply_gallery_target_size(settings: dict[str, int], *, variant_count: int) -> None:
    if variant_count < 1:
        raise ConfigError("Gallery requires at least one render result")
    columns = settings["columns"]
    rows = (variant_count + columns - 1) // columns
    margin = settings["margin_px"]
    gutter = settings["gutter_px"]
    title_height = settings["title_height_px"]
    target_width = settings["target_width_px"]
    target_height = settings["target_height_px"]

    available_width = target_width - margin * 2 - (columns - 1) * gutter
    if available_width < columns:
        raise ConfigError(
            "gallery.target_width_px is too small for gallery.columns, gallery.margin_px, and gallery.gutter_px"
        )
    if available_width % columns:
        raise ConfigError(
            "gallery.target_width_px must leave a width divisible by gallery.columns after margins and gutters"
        )
    thumbnail_width = available_width // columns

    available_height = target_height - margin * 2 - (rows - 1) * gutter - rows * title_height
    if available_height < rows:
        raise ConfigError(
            "gallery.target_height_px is too small for gallery rows, gallery.margin_px, gallery.gutter_px, and gallery.title_height_px"
        )
    if available_height % rows:
        raise ConfigError(
            "gallery.target_height_px must leave a height divisible by gallery rows after margins, gutters, and titles"
        )
    thumbnail_height = available_height // rows

    settings["thumbnail_width"] = thumbnail_width
    settings["thumbnail_height"] = thumbnail_height
    settings["render_width"] = thumbnail_width
    settings["render_height"] = thumbnail_height


def apply_gallery_target_render_size(config: Mapping[str, object], settings: Mapping[str, int]) -> dict[str, object]:
    if "render_width" not in settings or "render_height" not in settings:
        return dict(config)
    resolved = deepcopy(dict(config))
    render = resolved.get("render", {})
    if render is None:
        render = {}
    if not isinstance(render, Mapping):
        raise ConfigError("render must be an object")
    updated_render = dict(render)
    updated_render["width"] = int(settings["render_width"])
    updated_render["height"] = int(settings["render_height"])
    resolved["render"] = updated_render
    return resolved


def build_gallery_contact_sheet(
    *,
    results: Sequence[Mapping[str, object]],
    output_path: Path,
    columns: int,
    thumbnail_width: int,
    thumbnail_height: int | None = None,
    margin_px: int,
    gutter_px: int,
    title_height_px: int,
    title_font_size_px: int,
) -> None:
    if not results:
        raise ConfigError("Gallery requires at least one render result")
    cells: list[tuple[str, Image.Image]] = []
    for result in results:
        image = Image.open(Path(result["annotated"])).convert("RGB")
        max_thumbnail_height = thumbnail_height if thumbnail_height is not None else thumbnail_width * 2
        image.thumbnail((thumbnail_width, max_thumbnail_height), resample=Image.Resampling.LANCZOS)
        cells.append((str(result["variant_name"]), image.copy()))

    title_height = title_height_px
    margin = margin_px
    gutter = gutter_px
    cell_width = thumbnail_width
    image_height = thumbnail_height if thumbnail_height is not None else max(image.height for _, image in cells)
    cell_height = image_height + title_height
    rows = (len(cells) + columns - 1) // columns
    sheet_width = margin * 2 + columns * cell_width + (columns - 1) * gutter
    sheet_height = margin * 2 + rows * cell_height + (rows - 1) * gutter
    sheet = Image.new("RGB", (sheet_width, sheet_height), (248, 250, 252))
    draw = ImageDraw.Draw(sheet)
    font = load_font(title_font_size_px)

    for index, (name, image) in enumerate(cells):
        row = index // columns
        column = index % columns
        cell_x = margin + column * (cell_width + gutter)
        cell_y = margin + row * (cell_height + gutter)
        draw.text((cell_x, cell_y), name, fill=(24, 33, 43), font=font)
        image_x = cell_x + (cell_width - image.width) // 2
        sheet.paste(image, (image_x, cell_y + title_height))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)


def run_gallery(
    *,
    config: Mapping[str, object],
    config_path: Path,
    config_dir: Path,
    args: argparse.Namespace,
    gallery_config: Mapping[str, object] | None = None,
    gallery_config_path: Path | None = None,
) -> int:
    variants = selected_variants(config, args.variant)
    if not variants:
        raise ConfigError("No variants are configured. Add a top-level variants array or render the config normally.")

    resolved_variants = [(str(variant["name"]).strip(), variant_config(config, variant)) for variant in variants]
    settings = gallery_settings(config, gallery_config=gallery_config, variant_count=len(resolved_variants))
    resolved_variants = [
        (name, apply_gallery_target_render_size(resolved_config, settings))
        for name, resolved_config in resolved_variants
    ]
    if args.print_resolved_config:
        print(
            json.dumps(
                {
                    "gallery": settings,
                    "gallery_config": project_relative_or_absolute(gallery_config_path) if gallery_config_path else None,
                    "variants": [
                        {
                            "name": name,
                            "resolved": resolved_config_snapshot(
                                config=resolved_config,
                                config_path=config_path,
                                config_dir=config_dir,
                                args=args,
                            ),
                        }
                        for name, resolved_config in resolved_variants
                    ],
                },
                indent=2,
            )
        )
        return 0
    if args.validate_only:
        for name, resolved_config in resolved_variants:
            print(f"Variant:   {name}")
            render_config(config=resolved_config, config_path=config_path, config_dir=config_dir, args=args)
        return 0

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    gallery_root = output_root_for(config, args) / f"{sanitize_name(base_job_name(config))}__gallery__{timestamp}"
    gallery_root.mkdir(parents=True, exist_ok=True)

    results: list[dict[str, object]] = []
    for name, resolved_config in resolved_variants:
        result = render_config(
            config=resolved_config,
            config_path=config_path,
            config_dir=config_dir,
            args=args,
            run_dir=gallery_root,
        )
        result["variant_name"] = name
        results.append(result)

    contact_sheet = gallery_root / "gallery.png"
    build_gallery_contact_sheet(
        results=results,
        output_path=contact_sheet,
        columns=settings["columns"],
        thumbnail_width=settings["thumbnail_width"],
        thumbnail_height=settings.get("thumbnail_height"),
        margin_px=settings["margin_px"],
        gutter_px=settings["gutter_px"],
        title_height_px=settings["title_height_px"],
        title_font_size_px=settings["title_font_size_px"],
    )
    metadata = {
        "config": project_relative_or_absolute(config_path),
        "gallery_config": project_relative_or_absolute(gallery_config_path) if gallery_config_path else None,
        "gallery": settings,
        "contact_sheet": project_relative_or_absolute(contact_sheet),
        "variants": [
            {
                "name": result["variant_name"],
                "run_dir": project_relative_or_absolute(Path(result["run_dir"])),
                "annotated": project_relative_or_absolute(Path(result["annotated"])),
                "metadata": project_relative_or_absolute(Path(result["metadata"])) if result.get("metadata") else None,
            }
            for result in results
        ],
    }
    metadata_path = gallery_root / "gallery_metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(f"Gallery:      {project_relative_or_absolute(contact_sheet)}")
    print(f"Metadata:     {project_relative_or_absolute(metadata_path)}")
    return 0


def run(args: argparse.Namespace) -> int:
    if args.doctor:
        return run_doctor(args)
    if getattr(args, "smoke_render", False):
        raise ConfigError("--smoke-render is only supported with --doctor")
    if args.print_schema:
        print(CONFIG_SCHEMA_PATH.read_text(encoding="utf-8"), end="")
        return 0
    if render_shortcut_requested(args) and discovery_requested(args):
        raise ConfigError("Discovery commands do not support `render MODEL`; use the discovery command directly")
    if args.discover_annotations:
        return run_annotation_discovery(args=args)
    config_path = config_path_from_args(args, allow_default=discovery_requested(args))
    config = load_config(config_path, args.overrides)
    config_dir = config_path.parent

    if discovery_requested(args):
        return run_discovery(config=config, config_path=config_path, args=args)

    gallery_config, gallery_config_path = load_gallery_config(args.gallery_config, config_dir=config_dir)

    if args.gallery:
        if getattr(args, "output_file", None):
            raise ConfigError("--output-file is not supported with --gallery; use --output-dir for gallery output")
        if args.animation_preset:
            raise ConfigError("--animation-preset is not supported with --gallery")
        return run_gallery(
            config=config,
            config_path=config_path,
            config_dir=config_dir,
            args=args,
            gallery_config=gallery_config,
            gallery_config_path=gallery_config_path,
        )
    if args.variant:
        variants = selected_variants(config, args.variant)
        if not variants:
            raise ConfigError("No variants are configured")
        config = variant_config(config, variants[0])
    elif not is_directly_renderable_config(config):
        variants = selected_variants(config, None)
        if not variants:
            raise ConfigError("Config has no directly renderable model and no variants")
        config = variant_config(config, variants[0])
    if args.animation_preset:
        config = apply_animation_preset(config, str(args.animation_preset))
    if args.print_resolved_config:
        print(json.dumps(resolved_config_snapshot(config=config, config_path=config_path, config_dir=config_dir, args=args), indent=2))
        return 0

    render_config(config=config, config_path=config_path, config_dir=config_dir, args=args)
    return 0
