"""CLI entry point for rendering configured annotations in a Blender scene."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
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
from annotation_renderer.config import (
    DEFAULT_OUTPUT_DIR,
    ConfigError,
    aliases_from_config,
    build_expression_context,
    build_expression_context_for_model,
    build_scad_defines,
    collect_angle_radius_callouts,
    collect_arc_callouts,
    collect_dimension_chain,
    collect_image_labels,
    collect_radius_callouts,
    deep_merge,
    merge_scene_object_config,
    projection_points_for_angle_radius_callouts,
    projection_points_for_arc_callouts,
    projection_points_for_radius_callouts,
    projection_points_for_segments,
    resolve_config_constants,
    resolve_config_path,
    resolve_constant_references,
    resolve_render,
    resolve_scene,
    resolve_scene_transform,
    resolve_style,
    scene_inherits_target_transform,
    validate_config_shape,
    vector3,
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
    with_annotation_metadata_define,
)


UTILITY_ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = UTILITY_ROOT.parent
CONFIG_SCHEMA_PATH = UTILITY_ROOT / "schemas" / "annotation-render-config.schema.json"
DEFAULT_MODEL_CONFIG_PATH = UTILITY_ROOT / "configs" / "model_defaults.yaml"
DISCOVERY_ACTIONS = ("list_models", "describe", "list_annotations", "new_config")
JSON_CONFIG_SUFFIXES = {"", ".json"}
YAML_CONFIG_SUFFIXES = {".yaml", ".yml"}
OUTPUT_MODES = ("minimal", "standard", "debug")
INHERITED_VARIANTS_KEY = "_inherited_variants"
DISCOVERY_TEXT_SUFFIXES = {".txt", ".text"}
DISCOVERY_PARAMETER_SECTIONS = (
    ("dimension", "dimension parameters", "add to annotations.chains[].ids"),
    (
        "radius",
        "radius parameters",
        "add to annotations.radius_callouts[].ids or annotations.angle_radius_callouts[].radius_id",
    ),
    (
        "arc",
        "arc parameters",
        "add to annotations.arc_callouts[].ids or annotations.angle_radius_callouts[].arc_id",
    ),
    (
        "context",
        "context value parameters",
        "add to annotations.image_labels[].id; numeric values also work in offsets and angle_radius_callouts[].angle_id",
    ),
)
DISCOVERY_OBJECT_SELECTOR_DEFINES = {"generate_drawer_shell", "generate_drawer_container"}
GROUP_STYLE_KEYS = {
    "line_alpha",
    "line_width_px",
    "extension_width_px",
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
    "radial_dash_px",
    "radial_gap_px",
    "angle_fill_color",
    "angle_fill_alpha",
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
    return 0 if all(ok for ok, _label, _detail in checks) else 1


def parse_override_value(value: str) -> object:
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value


def set_dotted_value(config: dict[str, object], path: str, assigned_value: object) -> None:
    keys = [key.strip() for key in path.split(".") if key.strip()]
    if not keys:
        raise ConfigError("Override path is empty")
    current: dict[str, object] = config
    for key in keys[:-1]:
        value = current.get(key)
        if value is None:
            value = {}
            current[key] = value
        if not isinstance(value, dict):
            raise ConfigError(f"--set cannot descend into non-object path {key!r}")
        current = value
    current[keys[-1]] = assigned_value


def apply_override(config: dict[str, object], override: str) -> None:
    if "=" not in override:
        raise ConfigError(f"--set override must be path=value, got {override!r}")
    path, raw_value = override.split("=", 1)
    set_dotted_value(config, path, parse_override_value(raw_value))


class NoAliasSafeDumper(yaml.SafeDumper if yaml is not None else object):
    def ignore_aliases(self, data: object) -> bool:
        return True


class ConfigSafeLoader(yaml.SafeLoader if yaml is not None else object):
    pass


def represent_compact_sequence(dumper: object, data: Sequence[object]) -> object:
    flow_style = len(data) <= 4 and all(
        not isinstance(item, Mapping)
        and (not isinstance(item, Sequence) or isinstance(item, (str, bytes)))
        for item in data
    )
    return dumper.represent_sequence("tag:yaml.org,2002:seq", data, flow_style=flow_style)


if yaml is not None:
    ConfigSafeLoader.yaml_implicit_resolvers = {
        key: list(resolvers)
        for key, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
    }
    for key, resolvers in list(ConfigSafeLoader.yaml_implicit_resolvers.items()):
        ConfigSafeLoader.yaml_implicit_resolvers[key] = [
            (tag, regexp)
            for tag, regexp in resolvers
            if tag != "tag:yaml.org,2002:bool"
        ]
    ConfigSafeLoader.add_implicit_resolver(
        "tag:yaml.org,2002:bool",
        re.compile(r"^(?:true|false|True|False|TRUE|FALSE)$"),
        list("tTfF"),
    )
    NoAliasSafeDumper.add_representer(list, represent_compact_sequence)
    NoAliasSafeDumper.add_representer(tuple, represent_compact_sequence)


def config_format(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in JSON_CONFIG_SUFFIXES:
        return "json"
    if suffix in YAML_CONFIG_SUFFIXES:
        return "yaml"
    raise ConfigError(f"Unsupported config format for {path}. Use .json, .yaml, or .yml.")


def load_mapping_file(path: Path, *, description: str) -> dict[str, object]:
    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise ConfigError(f"{description} not found: {path}") from exc

    file_format = config_format(path)
    try:
        if file_format == "json":
            data = json.loads(text)
        else:
            if yaml is None:
                raise ConfigError("YAML config support requires PyYAML. Install with `pip install PyYAML`.")
            data = yaml.load(text, Loader=ConfigSafeLoader)
    except ConfigError:
        raise
    except Exception as exc:
        raise ConfigError(f"Could not parse {description.lower()} {path}: {exc}") from exc

    if data is None:
        data = {}
    if not isinstance(data, Mapping):
        raise ConfigError(f"{description} must be an object")
    return dict(data)


def dump_config_data(data: Mapping[str, object], *, path: Path) -> str:
    file_format = config_format(path)
    if file_format == "json":
        return json.dumps(data, indent=2) + "\n"
    if yaml is None:
        raise ConfigError("YAML config support requires PyYAML. Install with `pip install PyYAML`.")
    return yaml.dump(
        dict(data),
        Dumper=NoAliasSafeDumper,
        sort_keys=False,
        allow_unicode=False,
        default_flow_style=False,
    )


def discovery_output_format(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in DISCOVERY_TEXT_SUFFIXES:
        return "text"
    if suffix in JSON_CONFIG_SUFFIXES and suffix:
        return "json"
    if suffix in YAML_CONFIG_SUFFIXES:
        return "yaml"
    raise ConfigError(f"Unsupported discovery output format for {path}. Use .txt, .json, .yaml, or .yml.")


def resolve_discovery_scad_path(value: str) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = (PROJECT_ROOT / path).resolve()
    if path.suffix.lower() != ".scad":
        raise ConfigError("--discover-annotations expects a .scad file path, not a render config model name")
    if not path.exists():
        raise ConfigError(f"SCAD file not found: {path}")
    return path


def variant_from_config_file(config: Mapping[str, object], *, path: Path) -> dict[str, object]:
    variant_name = config.get("variant_name") or path.stem
    if not isinstance(variant_name, str) or not variant_name.strip():
        raise ConfigError(f"variant_name must be a non-empty string in {project_relative_or_absolute(path)}")
    variant: dict[str, object] = {"name": variant_name.strip(), "_source_config": str(path)}
    for key in ("job_name", "output_dir", "constants", "model", "scene", "render", "annotations"):
        if key in config:
            variant[key] = deepcopy(config[key])
    return variant


def expand_variant_configs(config: dict[str, object], *, config_dir: Path, seen: tuple[Path, ...]) -> dict[str, object]:
    variant_paths = config.pop("variant_configs", None)
    if variant_paths is None:
        return config
    if not isinstance(variant_paths, Sequence) or isinstance(variant_paths, (str, bytes)):
        raise ConfigError("variant_configs must be an array of config paths")

    constants = config.get("constants", {})
    if constants is None:
        constants = {}
    if not isinstance(constants, Mapping):
        raise ConfigError("constants must be an object when variant_configs is used")
    merged_constants: Mapping[str, object] = constants

    variants = config.get("variants", [])
    if variants is None:
        variants = []
    if not isinstance(variants, Sequence) or isinstance(variants, (str, bytes)):
        raise ConfigError("variants must be an array when variant_configs is used")
    merged_variants: list[object] = [deepcopy(item) for item in variants]

    for index, raw_path in enumerate(variant_paths):
        if not isinstance(raw_path, str) or not raw_path.strip():
            raise ConfigError(f"variant_configs[{index}] must be a non-empty string")
        variant_path = resolve_optional_config_path(raw_path, config_dir=config_dir)
        included_config = load_raw_config(variant_path, seen)
        included_constants = included_config.get("constants", {})
        if included_constants is not None:
            if not isinstance(included_constants, Mapping):
                raise ConfigError(f"constants must be an object in {project_relative_or_absolute(variant_path)}")
            merged_constants = deep_merge(merged_constants, included_constants)
        merged_variants.append(variant_from_config_file(included_config, path=variant_path))

    config["constants"] = deepcopy(dict(merged_constants))
    config["variants"] = merged_variants
    return config


def load_raw_config(path: Path, seen: tuple[Path, ...] = ()) -> dict[str, object]:
    if path in seen:
        chain = " -> ".join(project_relative_or_absolute(item) for item in (*seen, path))
        raise ConfigError(f"Config extends cycle detected: {chain}")
    config = load_mapping_file(path, description="Config")
    extends_value = config.pop("extends", None)
    if extends_value is None:
        return expand_variant_configs(config, config_dir=path.parent, seen=(*seen, path))
    if not isinstance(extends_value, str) or not extends_value.strip():
        raise ConfigError("extends must be a non-empty string")
    base_path = resolve_optional_config_path(extends_value, config_dir=path.parent)
    base_config = load_raw_config(base_path, (*seen, path))
    merged_config = deep_merge(base_config, config)
    if "variants" in config:
        inherited_variants = [
            *deepcopy(base_config.get(INHERITED_VARIANTS_KEY, [])),
            *deepcopy(base_config.get("variants", [])),
        ]
        if inherited_variants:
            merged_config[INHERITED_VARIANTS_KEY] = inherited_variants
    return expand_variant_configs(merged_config, config_dir=path.parent, seen=(*seen, path))


def load_config(path: Path, overrides: Sequence[str]) -> dict[str, object]:
    config = deepcopy(load_raw_config(path))
    for override in overrides:
        apply_override(config, override)
    config = resolve_config_constants(config, include_variants=False)
    validate_config_shape(config)
    return config


def require_mapping(value: object, *, name: str) -> Mapping[str, object]:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    return value


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
    for key in GROUP_STYLE_KEYS:
        if key in group_config:
            merged[key] = group_config[key]
    return merged


def base_job_name(config: Mapping[str, object]) -> str:
    if config.get("job_name"):
        return str(config["job_name"])
    model = config.get("model", {})
    if isinstance(model, Mapping) and model.get("scad_file"):
        return Path(str(model["scad_file"])).stem
    scene = config.get("scene", {})
    objects = scene.get("objects", []) if isinstance(scene, Mapping) else []
    if isinstance(objects, Sequence) and not isinstance(objects, (str, bytes)) and objects:
        first_object = objects[0]
        if isinstance(first_object, Mapping):
            object_id = first_object.get("id")
            if isinstance(object_id, str) and object_id.strip():
                return object_id
            object_model = first_object.get("model")
            if isinstance(object_model, Mapping) and object_model.get("scad_file"):
                return Path(str(object_model["scad_file"])).stem
    return "annotation_render"


def variant_items_from_config(config: Mapping[str, object]) -> list[Mapping[str, object]]:
    raw_variants = config.get("variants", [])
    if raw_variants is None:
        return []
    if not isinstance(raw_variants, Sequence) or isinstance(raw_variants, (str, bytes)):
        raise ConfigError("variants must be an array")
    variants: list[Mapping[str, object]] = []
    for index, variant in enumerate(raw_variants):
        if not isinstance(variant, Mapping):
            raise ConfigError(f"variants[{index}] must be an object")
        name = variant.get("name")
        if not isinstance(name, str) or not name.strip():
            raise ConfigError(f"variants[{index}].name is required")
        variants.append(variant)
    return variants


def variant_config(
    config: Mapping[str, object],
    variant: Mapping[str, object],
    *,
    stack: tuple[str, ...] = (),
) -> dict[str, object]:
    variant_name = str(variant["name"]).strip()
    if variant_name in stack:
        chain = " -> ".join((*stack, variant_name))
        raise ConfigError(f"Variant inheritance cycle detected: {chain}")
    base_variant_name = variant.get("extends_variant")
    if base_variant_name is not None:
        if not isinstance(base_variant_name, str) or not base_variant_name.strip():
            raise ConfigError(f"variants[{variant_name}].extends_variant must be a non-empty string")
        inherited_variants = config.get(INHERITED_VARIANTS_KEY, [])
        if inherited_variants is None:
            inherited_variants = []
        if not isinstance(inherited_variants, Sequence) or isinstance(inherited_variants, (str, bytes)):
            raise ConfigError(f"{INHERITED_VARIANTS_KEY} must be an array")
        matches = [
            item
            for item in [*variant_items_from_config(config), *inherited_variants]
            if isinstance(item, Mapping) and str(item["name"]).strip() == base_variant_name
        ]
        if not matches:
            raise ConfigError(f"variants[{variant_name}].extends_variant references unknown variant {base_variant_name!r}")
        resolved = variant_config(config, matches[0], stack=(*stack, variant_name))
    else:
        resolved = deepcopy(dict(config))
        resolved.pop("variants", None)
        resolved.pop(INHERITED_VARIANTS_KEY, None)
    if "job_name" not in variant:
        resolved["job_name"] = f"{base_job_name(config)}__{variant_name}"

    replace_sections = {"model", "annotations"}
    for key in ("job_name", "output_dir", "constants", "model", "scene", "render", "annotations"):
        if key not in variant:
            continue
        current = resolved.get(key)
        if key == "constants":
            override = variant[key]
            if isinstance(current, Mapping) and isinstance(override, Mapping):
                resolved[key] = deep_merge(current, override)
            else:
                resolved[key] = deepcopy(override)
            continue
        override = resolve_constant_references(
            variant[key],
            constants=require_mapping(resolved.get("constants", {}), name="constants"),
            path=f"variants[{variant_name}].{key}",
        )
        if key not in replace_sections and isinstance(current, Mapping) and isinstance(override, Mapping):
            resolved[key] = deep_merge(current, override)
        else:
            resolved[key] = deepcopy(override)

    set_values = variant.get("set", {})
    if set_values is not None:
        if not isinstance(set_values, Mapping):
            raise ConfigError(f"variants[{variant_name}].set must be an object")
        for path, value in set_values.items():
            set_dotted_value(resolved, str(path), deepcopy(value))

    resolved = resolve_config_constants(resolved, include_variants=False)
    validate_config_shape(resolved)
    return resolved


def selected_variants(config: Mapping[str, object], selected_name: str | None) -> list[Mapping[str, object]]:
    variants = variant_items_from_config(config)
    if selected_name is None:
        return variants
    matching = [variant for variant in variants if str(variant["name"]) == selected_name]
    if not matching:
        available = ", ".join(str(variant["name"]) for variant in variants) or "none"
        raise ConfigError(f"Unknown variant {selected_name!r}. Available variants: {available}")
    return matching


def discovery_requested(args: argparse.Namespace) -> bool:
    return any(bool(getattr(args, name, None)) for name in DISCOVERY_ACTIONS)


def config_path_from_args(args: argparse.Namespace, *, allow_default: bool = False) -> Path:
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
    if scene.get("objects") is not None:
        return True
    return config.get("model") is not None


def output_root_for(config: Mapping[str, object], args: argparse.Namespace) -> Path:
    output_root = Path(args.output_dir or config.get("output_dir") or DEFAULT_OUTPUT_DIR)
    if not output_root.is_absolute():
        output_root = PROJECT_ROOT / output_root
    return output_root


def output_mode_for(render_config: Mapping[str, object], args: argparse.Namespace) -> str:
    raw_mode = getattr(args, "output_mode", None) or render_config.get("output_mode") or "standard"
    mode = str(raw_mode)
    if mode not in OUTPUT_MODES:
        raise ConfigError(f"render.output_mode must be one of {', '.join(OUTPUT_MODES)}")
    return mode


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


def scad_output_folder_name(object_specs: Sequence[Mapping[str, object]]) -> str:
    stems: list[str] = []
    for object_spec in object_specs:
        stem = Path(str(object_spec["scad_file"])).stem
        if stem not in stems:
            stems.append(stem)
    if not stems:
        return "unknown_model"
    return sanitize_name(stems[0] if len(stems) == 1 else "__".join(stems))


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


def resolve_optional_config_path(path_value: str, *, config_dir: Path) -> Path:
    path = Path(path_value).expanduser()
    if path.is_absolute():
        return path.resolve()
    config_relative = (config_dir / path).resolve()
    if config_relative.exists():
        return config_relative
    return (PROJECT_ROOT / path).resolve()


def load_gallery_config(path_value: str | None, *, config_dir: Path) -> tuple[dict[str, object], Path | None]:
    if not path_value:
        return {}, None
    path = resolve_optional_config_path(path_value, config_dir=config_dir)
    return load_mapping_file(path, description="Gallery config"), path


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
        variants = variant_items_from_config(config)
        matching = [variant for variant in variants if str(variant["name"]) == name]
        if matching:
            variant = matching[0]
            return name, variant_config(config, variant), source_config_for_variant(config_path, variant), variant
        direct_names = {
            config_path.stem,
            str(config.get("variant_name", "")).strip(),
            str(config.get("job_name", "")).strip(),
        }
        if is_directly_renderable_config(config) and name in direct_names:
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

    model = config.get("model")
    if isinstance(model, Mapping):
        records.append(
            {
                "id": "model",
                "target_object": scene.get("target_object"),
                "scad_file": model.get("scad_file"),
                "defines": model.get("defines", {}),
            }
        )
    return records


def model_summary(records: Sequence[Mapping[str, object]]) -> str:
    if not records:
        return "no model"
    parts = []
    for record in records:
        object_id = str(record.get("id") or "model")
        scad_file = str(record.get("scad_file") or "unknown")
        parts.append(f"{object_id}: {scad_file}")
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
            ("line_offset_px", group.get("line_offset_px", 0)),
            ("label_offset_px", group.get("label_offset_px", 0)),
        ]
    elif kind == "image_label":
        items = [("offset_px", group.get("offset_px", [0, 0]))]
    else:
        items = [("display_offset_mm", group.get("display_offset_mm", [0, 0, 0]))]
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


def strip_scad_comments(source: str) -> str:
    chars = list(source)
    index = 0
    in_string = False
    while index < len(chars):
        char = chars[index]
        next_char = chars[index + 1] if index + 1 < len(chars) else ""
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
            index += 1
            continue
        if char == "/" and next_char == "/":
            chars[index] = " "
            chars[index + 1] = " "
            index += 2
            while index < len(chars) and chars[index] != "\n":
                chars[index] = " "
                index += 1
            continue
        if char == "/" and next_char == "*":
            chars[index] = " "
            chars[index + 1] = " "
            index += 2
            while index + 1 < len(chars) and not (chars[index] == "*" and chars[index + 1] == "/"):
                if chars[index] != "\n":
                    chars[index] = " "
                index += 1
            if index + 1 < len(chars):
                chars[index] = " "
                chars[index + 1] = " "
                index += 2
            continue
        index += 1
    return "".join(chars)


def matching_delimiter_index(source: str, open_index: int, *, open_char: str, close_char: str) -> int | None:
    depth = 0
    index = open_index
    in_string = False
    while index < len(source):
        char = source[index]
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
        elif char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth == 0:
                return index
        index += 1
    return None


def matching_open_delimiter_index(source: str, close_index: int, *, open_char: str, close_char: str) -> int | None:
    depth = 0
    index = close_index
    in_string = False
    while index >= 0:
        char = source[index]
        if in_string:
            if char == '"':
                backslashes = 0
                probe = index - 1
                while probe >= 0 and source[probe] == "\\":
                    backslashes += 1
                    probe -= 1
                if backslashes % 2 == 0:
                    in_string = False
            index -= 1
            continue
        if char == '"':
            in_string = True
        elif char == close_char:
            depth += 1
        elif char == open_char:
            depth -= 1
            if depth == 0:
                return index
        index -= 1
    return None


def condition_before_block(source: str, brace_index: int) -> str | None:
    index = brace_index - 1
    while index >= 0 and source[index].isspace():
        index -= 1
    if index < 0 or source[index] != ")":
        return None
    open_index = matching_open_delimiter_index(source, index, open_char="(", close_char=")")
    if open_index is None:
        return None
    prefix_end = open_index - 1
    while prefix_end >= 0 and source[prefix_end].isspace():
        prefix_end -= 1
    prefix_start = prefix_end
    while prefix_start >= 0 and (source[prefix_start].isalnum() or source[prefix_start] == "_"):
        prefix_start -= 1
    keyword = source[prefix_start + 1 : prefix_end + 1]
    if keyword != "if":
        return None
    return " ".join(source[open_index + 1 : index].split())


def scad_conditional_block_ranges(source: str) -> list[tuple[int, int, str]]:
    ranges: list[tuple[int, int, str]] = []
    stack: list[tuple[int, str | None]] = []
    index = 0
    in_string = False
    while index < len(source):
        char = source[index]
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            stack.append((index, condition_before_block(source, index)))
        elif char == "}" and stack:
            start, condition = stack.pop()
            if condition:
                ranges.append((start, index, condition))
        index += 1
    return ranges


def split_top_level(value: str, separator: str = ",") -> list[str]:
    parts: list[str] = []
    start = 0
    depths = {"(": 0, "[": 0, "{": 0}
    matching = {")": "(", "]": "[", "}": "{"}
    in_string = False
    index = 0
    while index < len(value):
        char = value[index]
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
        elif char in depths:
            depths[char] += 1
        elif char in matching:
            depths[matching[char]] = max(0, depths[matching[char]] - 1)
        elif char == separator and all(depth == 0 for depth in depths.values()):
            parts.append(value[start:index].strip())
            start = index + 1
        index += 1
    tail = value[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def split_top_level_assignment(value: str) -> tuple[str, str] | None:
    parts = split_top_level(value, separator="=")
    if len(parts) != 2:
        return None
    return parts[0].strip(), parts[1].strip()


def scad_string_literal(value: str) -> str | None:
    stripped = value.strip()
    if not stripped.startswith('"') or not stripped.endswith('"'):
        return None
    try:
        parsed = json.loads(stripped)
    except json.JSONDecodeError:
        return stripped[1:-1]
    return parsed if isinstance(parsed, str) else None


def scad_string_literals(value: str) -> list[str]:
    literals: list[str] = []
    for match in re.finditer(r'"(?:\\.|[^"\\])*"', value):
        literal = scad_string_literal(match.group(0))
        if literal is not None:
            literals.append(literal)
    return literals


def scad_call_named_arguments(call_body: str) -> dict[str, str]:
    arguments: dict[str, str] = {}
    for part in split_top_level(call_body):
        assignment = split_top_level_assignment(part)
        if assignment is None:
            continue
        key, value = assignment
        if key:
            arguments[key] = value
    return arguments


def scad_boolean_define_allows_condition(condition: str, defines: Mapping[str, object]) -> bool:
    for name, value in defines.items():
        if str(name) not in DISCOVERY_OBJECT_SELECTOR_DEFINES:
            continue
        if not isinstance(value, bool):
            continue
        for match in re.finditer(rf"(?<![A-Za-z0-9_!])(!?)\b{re.escape(str(name))}\b(?![A-Za-z0-9_])", condition):
            negated = bool(match.group(1))
            allowed = not value if negated else value
            if not allowed:
                return False
    return True


def discover_scad_source_annotations(scad_file: Path, *, defines: Mapping[str, object]) -> tuple[dict[str, object], ...]:
    source = strip_scad_comments(scad_file.read_text(encoding="utf-8"))
    conditional_ranges = scad_conditional_block_ranges(source)
    annotations: list[dict[str, object]] = []
    call_kinds = {
        "emit_dimension_annotation": "dimension",
        "emit_radius_annotation": "radius",
        "emit_arc_annotation": "arc",
        "emit_feature_annotation": "feature",
    }
    call_pattern = re.compile(r"\b(emit_context_values|emit_dimension_annotation|emit_radius_annotation|emit_arc_annotation|emit_feature_annotation)\s*\(")
    for match in call_pattern.finditer(source):
        prefix = source[max(0, match.start() - 16) : match.start()]
        if re.search(r"\bmodule\s+$", prefix):
            continue
        open_index = source.find("(", match.start())
        close_index = matching_delimiter_index(source, open_index, open_char="(", close_char=")")
        if close_index is None:
            continue
        conditions = [
            condition
            for start, end, condition in conditional_ranges
            if start < match.start() < end
        ]
        if any(not scad_boolean_define_allows_condition(condition, defines) for condition in conditions):
            continue
        call_name = match.group(1)
        call_body = source[open_index + 1 : close_index]
        if call_name == "emit_context_values":
            positional = split_top_level(call_body)
            source_id = scad_string_literal(positional[0]) if positional else None
            names = scad_string_literals(positional[1]) if len(positional) > 1 else []
            for name in names:
                annotation: dict[str, object] = {"id": name, "kind": "context", "source": source_id or "context"}
                if conditions:
                    annotation["conditions"] = conditions
                annotations.append(annotation)
            continue
        arguments = scad_call_named_arguments(call_body)
        annotation_id = scad_string_literal(arguments.get("id", ""))
        if not annotation_id:
            continue
        annotation: dict[str, object] = {
            "id": annotation_id,
            "kind": call_kinds[call_name],
        }
        if conditions:
            annotation["conditions"] = conditions
        axis = scad_string_literal(arguments.get("axis", ""))
        label = scad_string_literal(arguments.get("label", ""))
        basis = scad_string_literal(arguments.get("basis", ""))
        if axis:
            annotation["axis"] = axis
        if label and label != annotation_id:
            annotation["label"] = label
        if basis:
            annotation["basis"] = basis
        annotations.append(annotation)
    return tuple(annotations)


def discovered_annotation_summary(annotation: Mapping[str, object]) -> str:
    annotation_id = str(annotation.get("id", "unknown"))
    parts = [annotation_id]
    axis = annotation.get("axis")
    label = annotation.get("label")
    basis = annotation.get("basis")
    conditions = annotation.get("conditions")
    details = []
    if isinstance(axis, str) and axis:
        details.append(f"axis={axis}")
    if isinstance(label, str) and label and label != annotation_id:
        details.append(f"label={label}")
    if isinstance(basis, str) and basis:
        details.append(f"basis={basis}")
    if isinstance(conditions, Sequence) and not isinstance(conditions, (str, bytes)) and conditions:
        details.append("when=" + " && ".join(str(condition) for condition in conditions))
    if details:
        parts.append(f" ({', '.join(details)})")
    return "".join(parts)


def context_parameter_entries(annotations: Sequence[Mapping[str, object]]) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    seen: set[str] = set()
    for annotation in annotations:
        if annotation.get("kind") != "context":
            continue
        source_id = str(annotation.get("id") or "")
        values = annotation.get("values")
        added_value = False
        if isinstance(values, str):
            for part in values.split(";"):
                if "=" not in part:
                    continue
                raw_name, raw_value = part.split("=", 1)
                name = raw_name.strip()
                if not name:
                    continue
                added_value = True
                if name in seen:
                    continue
                seen.add(name)
                entry: dict[str, object] = {
                    "id": name,
                    "kind": "context",
                }
                entries.append(entry)
        if added_value or not source_id or source_id in seen:
            continue
        seen.add(source_id)
        entry = {
            "id": source_id,
            "kind": "context",
        }
        source = annotation.get("source")
        conditions = annotation.get("conditions")
        if isinstance(source, str) and source.strip():
            entry["source"] = source
        if isinstance(conditions, Sequence) and not isinstance(conditions, (str, bytes)) and conditions:
            entry["conditions"] = list(conditions)
        entries.append(entry)
    return entries


def compact_parameter_entry(annotation: Mapping[str, object]) -> dict[str, object]:
    entry: dict[str, object] = {
        "id": str(annotation.get("id") or "unknown"),
        "kind": str(annotation.get("kind", "feature")),
    }
    for key in ("axis", "label", "basis", "source", "conditions"):
        value = annotation.get(key)
        if value is not None and (not isinstance(value, str) or value.strip()):
            entry[key] = value
    return entry


def discovered_parameter_groups(annotations: Sequence[Mapping[str, object]]) -> dict[str, list[Mapping[str, object]]]:
    grouped: dict[str, list[Mapping[str, object]]] = {}
    supported_kinds = {kind for kind, _label, _hint in DISCOVERY_PARAMETER_SECTIONS}
    for annotation in annotations:
        kind = str(annotation.get("kind", "feature"))
        if kind == "context":
            continue
        if kind not in supported_kinds:
            continue
        grouped.setdefault(kind, []).append(compact_parameter_entry(annotation))
    context_entries = context_parameter_entries(annotations)
    if context_entries:
        grouped["context"] = context_entries
    return grouped


def format_annotation_discovery(name: str, object_discoveries: Sequence[Mapping[str, object]]) -> str:
    preferred_kinds = tuple(kind for kind, _label, _hint in DISCOVERY_PARAMETER_SECTIONS)
    lines = [f"Available annotation parameters for {name}:"]
    for discovery in object_discoveries:
        object_id = str(discovery.get("id") or "model")
        annotations = discovery.get("annotations", ())
        if not isinstance(annotations, Sequence) or isinstance(annotations, (str, bytes)):
            annotations = ()
        log_path = discovery.get("log_path")
        source_path = discovery.get("source_path")
        lines.append(f"- object: {object_id}")
        if isinstance(source_path, Path):
            lines.append(f"  source: {project_relative_or_absolute(source_path)}")
        if isinstance(log_path, Path) and log_path.exists():
            lines.append(f"  log: {project_relative_or_absolute(log_path)}")
        if not annotations:
            lines.append("  no annotation parameters emitted")
            continue

        grouped = discovered_parameter_groups(
            [annotation for annotation in annotations if isinstance(annotation, Mapping)]
        )

        ordered_kinds = [
            *[kind for kind in preferred_kinds if kind in grouped],
            *sorted(kind for kind in grouped if kind not in preferred_kinds),
        ]
        if not ordered_kinds:
            lines.append("  no annotation parameters emitted")
            continue
        for kind in ordered_kinds:
            section = next(
                ((label, hint) for section_kind, label, hint in DISCOVERY_PARAMETER_SECTIONS if section_kind == kind),
                (f"{kind} parameters", "custom annotation metadata"),
            )
            lines.append(f"  {section[0]} ({section[1]}):")
            for annotation in grouped[kind]:
                lines.append(f"    - {discovered_annotation_summary(annotation)}")
    return "\n".join(lines)


def discovery_summary_json(
    *,
    name: str,
    object_discoveries: Sequence[Mapping[str, object]],
) -> dict[str, object]:
    objects = []
    for discovery in object_discoveries:
        annotations = discovery.get("annotations", ())
        if not isinstance(annotations, Sequence) or isinstance(annotations, (str, bytes)):
            annotations = ()
        parsed_annotations = [annotation for annotation in annotations if isinstance(annotation, Mapping)]
        object_summary: dict[str, object] = {
            "id": str(discovery.get("id") or "model"),
            "annotation_count": len(parsed_annotations),
            "parameters": {
                kind: list(items)
                for kind, items in discovered_parameter_groups(parsed_annotations).items()
            },
        }
        source_path = discovery.get("source_path")
        if isinstance(source_path, Path):
            object_summary["source"] = project_relative_or_absolute(source_path)
        objects.append(object_summary)
    return {
        "name": name,
        "objects": objects,
    }


def write_annotation_discovery_output(
    *,
    output_path: Path,
    text_output: str,
    name: str,
    discoveries: Sequence[Mapping[str, object]],
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_format = discovery_output_format(output_path)
    if output_format == "text":
        output_path.write_text(text_output + "\n", encoding="utf-8")
        return
    summary = discovery_summary_json(name=name, object_discoveries=discoveries)
    if output_format == "json":
        output_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        return
    if yaml is None:
        raise ConfigError("YAML discovery output requires PyYAML. Install with `pip install PyYAML`.")
    output_path.write_text(
        yaml.dump(
            summary,
            Dumper=NoAliasSafeDumper,
            sort_keys=False,
            allow_unicode=False,
            default_flow_style=False,
        ),
        encoding="utf-8",
    )


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
        print(f"- {record.get('id')}: {record.get('scad_file')} -> {record.get('target_object')}")
        defines = record.get("defines", {})
        if isinstance(defines, Mapping) and defines:
            for define_name, value in defines.items():
                print(f"  {define_name}: {compact_json(value)}")
        elif isinstance(defines, Sequence) and not isinstance(defines, (str, bytes)) and defines:
            for define in defines:
                print(f"  {define}")
    print("Render:")
    for key in ("engine", "quality", "width", "height", "fit_camera", "fit_margin", "camera_location_offset_mm", "camera_look_at", "output_mode"):
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
                "line_offset_px",
                "label_offset_px",
                "angle_label_offset_px",
                "radius_label_offset_px",
                "angle_label_tangent_offset_px",
                "radius_label_tangent_offset_px",
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
    model = config.get("model")
    if isinstance(model, Mapping):
        defines = model.get("defines", {})
        if isinstance(defines, Mapping) and defines:
            return {"model": {"defines": deepcopy(dict(defines))}}
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
    relative = os.path.relpath(source_config, start=output_path.parent)
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
        "$schema": Path(os.path.relpath(CONFIG_SCHEMA_PATH, start=output_path.parent)).as_posix(),
        "extends": config_reference(source_config=source_config, output_path=output_path),
        "job_name": f"{sanitize_name(name)}_custom",
    }
    scene = resolve_scene(config.get("scene", {}))
    blend_file = scene.get("blend_file")
    if isinstance(blend_file, str) and blend_file.strip():
        scene_path = resolve_config_path(blend_file, config_dir=source_config.parent, project_root=PROJECT_ROOT)
        template["scene"] = {
            "blend_file": Path(os.path.relpath(scene_path, start=output_path.parent)).as_posix()
        }
    template.update(editable_model_template(config))
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
    parser.add_argument("--config", help="Path to scene annotation render JSON or YAML config.")
    parser.add_argument("--gallery-config", help="Path to contact-sheet settings JSON or YAML config used with --gallery.")
    parser.add_argument("--output-dir", help="Override output directory root.")
    parser.add_argument("--openscad", default="openscad", help="OpenSCAD executable.")
    parser.add_argument("--blender", default="blender", help="Blender executable.")
    parser.add_argument("--doctor", action="store_true", help="Check local renderer dependencies and paths.")
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
        help="Override a config value with dotted path syntax, for example model.defines.hook_length=50.",
    )
    return parser


def parse_args() -> argparse.Namespace:
    parser = build_arg_parser()
    return parser.parse_args()


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args() if argv is None else parse_args_from(argv)
    try:
        return run(args)
    except ConfigError as exc:
        raise SystemExit(str(exc)) from exc


def parse_args_from(argv: Sequence[str]) -> argparse.Namespace:
    parser = build_arg_parser()
    return parser.parse_args(list(argv))


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
                    "scad_file": project_relative_or_absolute(Path(object_spec["scad_file"])),
                    "scad_file_exists": Path(object_spec["scad_file"]).exists(),
                    "defines": list(build_scad_defines(require_mapping(object_spec["model_config"], name="model"))),
                    "expression_context": object_spec["expression_context"],
                    "inherit_target_transform": bool(object_spec["inherit_target_transform"]),
                    "transform": object_spec["transform"],
                    "transform_config": object_spec["object_scene_config"].get("transform"),
                    "replace_target_object": bool(object_spec["replace_target_object"]),
                    "material_source_object": object_spec.get("material_source_object"),
                    "material": object_spec.get("material"),
                    "mesh_shading": object_spec.get("mesh_shading") or render_settings.get("mesh_shading", "flat"),
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
        model_config = require_mapping(config.get("model", {}), name="model")
        object_context = build_expression_context_for_model(config, model_config)
        inherit_target_transform = scene_inherits_target_transform(scene_config)
        scene_transform = (
            resolve_scene_transform_for_object(
                scene_config,
                expression_context=object_context,
                name="scene",
                allow_deferred=allow_deferred_transforms,
            )
            if resolve_transforms
            else None
        )
        if not inherit_target_transform and scene_config.get("transform") is None:
            raise ConfigError("scene.transform is required when scene.inherit_target_transform is false")
        return [
            {
                "id": "model",
                "target_object": str(scene_config["target_object"]),
                "model_config": model_config,
                "scad_file": resolve_config_path(
                    str(model_config["scad_file"]),
                    config_dir=config_dir,
                    project_root=PROJECT_ROOT,
                ),
                "expression_context": object_context,
                "object_scene_config": dict(scene_config),
                "inherit_target_transform": inherit_target_transform,
                "transform": scene_transform,
                "replace_target_object": bool(scene_config.get("replace_target_object", True)),
                "material_source_object": None,
                "mesh_shading": None,
            }
        ]

    if not isinstance(raw_objects, Sequence) or isinstance(raw_objects, (str, bytes)):
        raise ConfigError("scene.objects must be an array")
    object_defaults = scene_config.get("object_defaults")
    specs: list[dict[str, object]] = []
    seen_ids: set[str] = set()
    for index, raw_object in enumerate(raw_objects):
        if not isinstance(raw_object, Mapping):
            raise ConfigError(f"scene.objects[{index}] must be an object")
        object_config = merge_scene_object_config(object_defaults, raw_object)
        object_id = str(object_config["id"]).strip()
        if object_id in seen_ids:
            raise ConfigError(f"scene.objects[{index}].id duplicates {object_id!r}")
        seen_ids.add(object_id)

        model_config = require_mapping(object_config.get("model"), name=f"scene.objects[{index}].model")
        object_context = build_expression_context_for_model(config, model_config)
        object_scene_config = dict(scene_config)
        object_scene_config.pop("objects", None)
        object_scene_config.pop("object_defaults", None)
        for key in ("inherit_target_transform", "replace_target_object", "transform"):
            if key in object_config:
                if key == "transform" and isinstance(object_scene_config.get("transform"), Mapping) and isinstance(object_config[key], Mapping):
                    object_scene_config[key] = deep_merge(object_scene_config["transform"], object_config[key])
                else:
                    object_scene_config[key] = object_config[key]
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
                "model_config": model_config,
                "scad_file": resolve_config_path(
                    str(model_config["scad_file"]),
                    config_dir=config_dir,
                    project_root=PROJECT_ROOT,
                ),
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


def render_config(
    *,
    config: Mapping[str, object],
    config_path: Path,
    config_dir: Path,
    args: argparse.Namespace,
    run_dir: Path | None = None,
) -> dict[str, object]:
    scene_config = resolve_scene(config.get("scene", {}))
    render_config = resolve_render(config.get("render", {}))
    annotation_config = require_mapping(config.get("annotations", {}), name="annotations")
    style_config = resolve_style(annotation_config.get("style"))
    expression_context = build_expression_context(config)
    aliases = aliases_from_config(annotation_config)

    blend_file = resolve_config_path(str(scene_config["blend_file"]), config_dir=config_dir, project_root=PROJECT_ROOT)
    object_specs = scene_object_specs(
        config=config,
        scene_config=scene_config,
        config_dir=config_dir,
        expression_context=expression_context,
        resolve_transforms=False,
    )
    for object_spec in object_specs:
        scad_file = Path(object_spec["scad_file"])
        if not scad_file.exists():
            raise ConfigError(f"SCAD file not found for object {object_spec['id']}: {scad_file}")
    if not blend_file.exists():
        raise ConfigError(f"Blender scene not found: {blend_file}")
    if args.validate_only:
        print(f"Config OK: {project_relative_or_absolute(config_path)}")
        print(f"Scene:     {blend_file}")
        for object_spec in object_specs:
            print(f"Object:    {object_spec['id']} -> {project_relative_or_absolute(Path(object_spec['scad_file']))}")
        return {
            "job_name": base_job_name(config),
            "validated": True,
            "config": config,
            "objects": object_specs,
            "blend_file": blend_file,
        }

    blender = require_blender_executable(args.blender)
    job_name = sanitize_name(str(config.get("job_name") or base_job_name(config)))
    output_mode = output_mode_for(render_config, args)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    run_name = f"{job_name}__{timestamp}"
    output_parent = run_dir if run_dir is not None else output_root_for(config, args)
    output_dir = output_parent / scad_output_folder_name(object_specs)
    debug_dir = output_dir / "debug" / run_name
    output_dir.mkdir(parents=True, exist_ok=True)
    debug_dir.mkdir(parents=True, exist_ok=True)
    run_dir = debug_dir

    object_records: list[dict[str, object]] = []
    openscad_commands: dict[str, list[str]] = {}
    for object_spec in object_specs:
        object_id = str(object_spec["id"])
        safe_object_id = sanitize_name(object_id)
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
        openscad_result = run_command_logged(openscad_command, cwd=PROJECT_ROOT, log_path=openscad_log)
        if openscad_result.returncode != 0:
            raise SystemExit(
                command_failure_message(
                    f"OpenSCAD export failed for object {object_id}",
                    log_path=openscad_log,
                )
            )
        openscad_commands[object_id] = openscad_command
        scad_annotations = read_scad_annotations(openscad_log)
        scad_context = numeric_context_from_scad_annotations(scad_annotations)
        object_context = dict(object_spec["expression_context"])
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

        object_record = dict(object_spec)
        object_record.update(
            {
                "stl_path": stl_path,
                "openscad_log": openscad_log,
                "defines": defines,
                "scad_annotations": scad_annotations,
                "scad_context": scad_context,
                "expression_context": object_context,
                "transform": object_transform,
            }
        )
        object_records.append(object_record)

    animation_config = resolve_animation_config(render_config.get("animation"), object_records=object_records)

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
    active_chains = [group for _, group in chain_pairs]
    active_radius_groups = [group for _, group in radius_pairs]
    active_arc_groups = [group for _, group in arc_pairs]
    active_angle_radius_groups = [group for _, group in angle_radius_pairs]
    image_labels = collect_image_labels(
        config=config,
        labels_config=image_label_items,
        annotation_config=annotation_config,
        style_config=style_config,
        expression_context=annotation_expression_context,
    )

    projection_points: dict[str, dict[str, object]] = {}
    for chain_segments in active_chains:
        projection_points.update(projection_points_for_object(projection_points_for_segments(chain_segments), object_id=annotation_object_id))
    for radius_callouts in active_radius_groups:
        projection_points.update(projection_points_for_object(projection_points_for_radius_callouts(radius_callouts), object_id=annotation_object_id))
    for arc_callouts in active_arc_groups:
        projection_points.update(projection_points_for_object(projection_points_for_arc_callouts(arc_callouts), object_id=annotation_object_id))
    for angle_radius_callouts in active_angle_radius_groups:
        projection_points.update(
            projection_points_for_object(
                projection_points_for_angle_radius_callouts(angle_radius_callouts),
                object_id=annotation_object_id,
            )
        )

    render_path = run_dir / "render.png"
    annotated_path = output_dir / f"{run_name}.png"
    animation_frame_dir = run_dir / "animation_frames" if animation_config else None
    animation_path = (
        output_dir / f"{run_name}.gif"
        if animation_config and str(animation_config.get("output_format")) == "gif"
        else None
    )
    projection_path = run_dir / "projection.json"
    blender_config_path = run_dir / "blender_scene_config.json"
    blender_script_path = run_dir / "blender_scene_render.py"
    blender_log = run_dir / "blender.log"

    blender_config = {
        "objects": [
            {
                "id": str(record["id"]),
                "stl_path": str(record["stl_path"]),
                "target_object": str(record["target_object"]),
                "replace_target_object": bool(record["replace_target_object"]),
                "inherit_target_transform": bool(record["inherit_target_transform"]),
                "object_transform": record["transform"],
                "material_source_object": record.get("material_source_object"),
                "material": record.get("material"),
                "mesh_shading": str(record.get("mesh_shading") or render_config.get("mesh_shading", "flat")),
            }
            for record in object_records
        ],
        "camera_name": scene_config.get("camera"),
        "render_path": str(render_path),
        "projection_path": str(projection_path),
        "projection_points": projection_points,
        "width": int(render_config.get("width", 1200)),
        "height": int(render_config.get("height", 900)),
        "render_engine": str(render_config.get("engine", "cycles")),
        "quality": str(render_config.get("quality", "standard")),
        "fit_camera": bool(render_config.get("fit_camera", False)),
        "fit_margin": float(render_config.get("fit_margin", 0.08)),
        "camera_location_offset": [
            value / 1000.0
            for value in vector3(
                render_config.get("camera_location_offset_mm"),
                default=(0.0, 0.0, 0.0),
                name="render.camera_location_offset_mm",
                context=expression_context,
            )
        ],
        "camera_look_at": str(render_config.get("camera_look_at", "none")),
        "mesh_shading": str(render_config.get("mesh_shading", "flat")),
    }
    if animation_config:
        assert animation_frame_dir is not None
        animation_frame_dir.mkdir(parents=True, exist_ok=True)
        blender_config["animation"] = animation_config
        blender_config["animation_frame_path"] = str(animation_frame_dir / "frame_")
    blender_config_path.write_text(json.dumps(blender_config, indent=2) + "\n", encoding="utf-8")
    write_blender_scene_script(blender_script_path)

    blender_command = [blender, "--background", str(blend_file), "--python", str(blender_script_path)]
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
    animation_frames: list[Path] = []
    if animation_config and animation_frame_dir is not None:
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

    projection = json.loads(projection_path.read_text(encoding="utf-8"))
    current_input = render_path
    chain_overlays = []
    radius_overlays = []
    arc_overlays = []
    angle_radius_overlays = []
    image_label_overlay = None
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
        output_path = annotated_path if overlay_index == total_overlay_steps else run_dir / f"annotated_step_{overlay_index}.png"
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
                )
                for chain_config, chain_segments in chain_pairs
            ],
        )
        current_input = output_path
    for arc_config, arc_callouts in arc_pairs:
        overlay_index += 1
        output_path = annotated_path if overlay_index == total_overlay_steps else run_dir / f"annotated_step_{overlay_index}.png"
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
    for radius_config, radius_callouts in radius_pairs:
        overlay_index += 1
        output_path = annotated_path if overlay_index == total_overlay_steps else run_dir / f"annotated_step_{overlay_index}.png"
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
    for callout_config, angle_radius_callouts in angle_radius_pairs:
        overlay_index += 1
        output_path = annotated_path if overlay_index == total_overlay_steps else run_dir / f"annotated_step_{overlay_index}.png"
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
        output_path = annotated_path if overlay_index == total_overlay_steps else run_dir / f"annotated_step_{overlay_index}.png"
        image_label_overlay = draw_image_label_overlay(
            render_path=current_input,
            output_path=output_path,
            labels=image_labels,
            style_config=style_config,
        )
        current_input = output_path

    if total_overlay_steps == 0:
        shutil.copyfile(render_path, annotated_path)

    metadata = {
        "job_name": job_name,
        "output_mode": output_mode,
        "config": project_relative_or_absolute(config_path),
        "constants": expression_context,
        "scene": {
            "blend_file": str(blend_file),
            "camera": scene_config.get("camera"),
            "objects": [
                {
                    "id": str(record["id"]),
                    "target_object": str(record["target_object"]),
                    "scad_file": project_relative_or_absolute(Path(record["scad_file"])),
                    "defines": list(record["defines"]),
                    "expression_context": record["expression_context"],
                    "scad_context": record["scad_context"],
                    "inherit_target_transform": bool(record["inherit_target_transform"]),
                    "transform": record["transform"],
                    "transform_config": record["object_scene_config"].get("transform"),
                    "replace_target_object": bool(record["replace_target_object"]),
                    "material_source_object": record.get("material_source_object"),
                    "material": record.get("material"),
                }
                for record in object_records
            ],
        },
        "render": blender_config,
        "style": style_config,
        "annotation_object": annotation_object_id,
        "scad_annotations": scad_annotations,
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
            for chain_segments in active_chains
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
            for radius_callouts in active_radius_groups
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
            for arc_callouts in active_arc_groups
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
            for angle_radius_callouts in active_angle_radius_groups
        ],
        "image_labels": [
            {
                "id": label.id,
                "label": label.label,
                "position": label.position,
                "offset_px": list(label.offset_px),
                "angle_deg": label.angle_deg,
            }
            for label in image_labels
        ],
        "projection": projection,
        "overlay": {
            "chains": chain_overlays,
            "radius_callouts": radius_overlays,
            "arc_callouts": arc_overlays,
            "angle_radius_callouts": angle_radius_overlays,
            "image_labels": image_label_overlay,
        },
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
            } if output_mode == "debug" else {},
            "blender_log": project_relative_or_absolute(blender_log) if output_mode == "debug" else None,
            "render": project_relative_or_absolute(render_path) if output_mode == "debug" else None,
            "annotated": project_relative_or_absolute(annotated_path),
            "metadata": project_relative_or_absolute(output_dir / f"{run_name}.metadata.json") if output_mode != "minimal" else None,
            "animation": project_relative_or_absolute(animation_path) if animation_path is not None else None,
            "animation_frames": project_relative_or_absolute(animation_frame_dir) if animation_frame_dir is not None and output_mode == "debug" else None,
            "projection": project_relative_or_absolute(projection_path) if output_mode == "debug" else None,
        },
        "commands": {
            "openscad": openscad_commands,
            "blender": blender_command,
        },
    }
    metadata_path = output_dir / f"{run_name}.metadata.json"
    if output_mode != "minimal":
        metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    remove_debug_artifacts(output_mode=output_mode, debug_dir=run_dir, output_dir=output_dir)

    print(f"Output folder: {project_relative_or_absolute(output_dir)}")
    print(f"Annotated:    {project_relative_or_absolute(annotated_path)}")
    if animation_path is not None:
        print(f"Animation:    {project_relative_or_absolute(animation_path)}")
    elif animation_frame_dir is not None and output_mode == "debug":
        print(f"Frames:       {project_relative_or_absolute(animation_frame_dir)}")
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
        "output_mode": output_mode,
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
) -> dict[str, int]:
    merged_gallery = compact_gallery_config(gallery_config or {}, name="gallery config")
    raw_gallery = config.get("gallery", {})
    merged_gallery.update(compact_gallery_config(raw_gallery, name="gallery"))
    columns = int(merged_gallery.get("columns", 2))
    thumbnail_width = int(merged_gallery.get("thumbnail_width", 520))
    if columns < 1:
        raise ConfigError("gallery.columns must be at least 1")
    if thumbnail_width < 1:
        raise ConfigError("gallery.thumbnail_width must be at least 1")
    return {"columns": columns, "thumbnail_width": thumbnail_width}


def build_gallery_contact_sheet(
    *,
    results: Sequence[Mapping[str, object]],
    output_path: Path,
    columns: int,
    thumbnail_width: int,
) -> None:
    if not results:
        raise ConfigError("Gallery requires at least one render result")
    cells: list[tuple[str, Image.Image]] = []
    for result in results:
        image = Image.open(Path(result["annotated"])).convert("RGB")
        image.thumbnail((thumbnail_width, thumbnail_width * 2), resample=Image.Resampling.LANCZOS)
        cells.append((str(result["variant_name"]), image.copy()))

    title_height = 42
    margin = 24
    gutter = 20
    cell_width = thumbnail_width
    cell_height = max(image.height for _, image in cells) + title_height
    rows = (len(cells) + columns - 1) // columns
    sheet_width = margin * 2 + columns * cell_width + (columns - 1) * gutter
    sheet_height = margin * 2 + rows * cell_height + (rows - 1) * gutter
    sheet = Image.new("RGB", (sheet_width, sheet_height), (248, 250, 252))
    draw = ImageDraw.Draw(sheet)
    font = load_font(22)

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
    if args.print_resolved_config:
        print(
            json.dumps(
                {
                    "gallery": gallery_settings(config, gallery_config=gallery_config),
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

    settings = gallery_settings(config, gallery_config=gallery_config)
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
    if args.print_schema:
        print(CONFIG_SCHEMA_PATH.read_text(encoding="utf-8"), end="")
        return 0
    if args.discover_annotations:
        return run_annotation_discovery(args=args)
    config_path = config_path_from_args(args, allow_default=discovery_requested(args))
    config = load_config(config_path, args.overrides)
    config_dir = config_path.parent

    if discovery_requested(args):
        return run_discovery(config=config, config_path=config_path, args=args)

    gallery_config, gallery_config_path = load_gallery_config(args.gallery_config, config_dir=config_dir)

    if args.gallery:
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
