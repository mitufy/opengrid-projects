"""Config constant, preset, expression, and path resolution helpers."""

from __future__ import annotations

import ast
import json
from copy import deepcopy
from pathlib import Path
from typing import Mapping, Sequence

from annotation_renderer.config_defaults import (
    ANNOTATION_COLLECTION_KEYS,
    AXES,
    BUILTIN_CONFIG_CONSTANTS,
    CONSTANT_REF_KEY,
    DEFAULT_STYLE_PRESET_NAME,
    DEFAULT_LINE_COLORS,
    DEFAULT_TYPE_STYLES,
    STYLE_PRESETS,
)
from annotation_renderer.config_schema import ConfigError


def deep_merge(base: Mapping[str, object], override: Mapping[str, object]) -> dict[str, object]:
    merged: dict[str, object] = dict(base)
    for key, value in override.items():
        current = merged.get(key)
        if isinstance(current, Mapping) and isinstance(value, Mapping):
            merged[key] = deep_merge(current, value)
        else:
            merged[key] = value
    return merged


def annotation_group_identity(collection: str, group: Mapping[str, object]) -> str | None:
    explicit_name = group.get("name")
    if isinstance(explicit_name, str) and explicit_name.strip():
        return explicit_name.strip()
    if collection in {"chains", "radius_callouts", "arc_callouts"}:
        ids = group.get("ids")
        if isinstance(ids, Sequence) and not isinstance(ids, (str, bytes)) and ids:
            return "+".join(str(item) for item in ids)
    if collection == "angle_radius_callouts":
        for key in ("id", "angle_id", "arc_id"):
            value = group.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    if collection == "image_labels":
        for key in ("id", "text"):
            value = group.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    return None


def apply_annotation_overrides(
    annotations: Mapping[str, object],
    overrides: Mapping[str, object],
    *,
    name: str = "annotation_overrides",
) -> dict[str, object]:
    resolved = deepcopy(dict(annotations))
    groups_by_name: dict[str, tuple[str, int]] = {}
    for collection in ANNOTATION_COLLECTION_KEYS:
        raw_groups = resolved.get(collection, [])
        if not isinstance(raw_groups, Sequence) or isinstance(raw_groups, (str, bytes)):
            raise ConfigError(f"annotations.{collection} must be an array")
        for index, group in enumerate(raw_groups):
            if not isinstance(group, Mapping):
                raise ConfigError(f"annotations.{collection}[{index}] must be an object")
            group_name = annotation_group_identity(collection, group)
            if group_name is None:
                continue
            if group_name in groups_by_name:
                previous_collection, previous_index = groups_by_name[group_name]
                raise ConfigError(
                    f"Annotation group name {group_name!r} is ambiguous between "
                    f"annotations.{previous_collection}[{previous_index}] and annotations.{collection}[{index}]"
                )
            groups_by_name[group_name] = (collection, index)

    for raw_group_name, raw_override in overrides.items():
        group_name = str(raw_group_name).strip()
        if not group_name:
            raise ConfigError(f"{name} keys must be non-empty strings")
        if not isinstance(raw_override, Mapping):
            raise ConfigError(f"{name}.{group_name} must be an object")
        if "name" in raw_override:
            raise ConfigError(f"{name}.{group_name}.name cannot change an annotation group's identity")
        target = groups_by_name.get(group_name)
        if target is None:
            available = ", ".join(sorted(groups_by_name)) or "none"
            raise ConfigError(f"{name} references unknown annotation group {group_name!r}. Available groups: {available}")
        collection, index = target
        raw_groups = resolved[collection]
        if not isinstance(raw_groups, list):
            raw_groups = list(raw_groups)
            resolved[collection] = raw_groups
        raw_groups[index] = deep_merge(raw_groups[index], raw_override)
    return resolved


def apply_object_overrides(
    scene: Mapping[str, object],
    overrides: Mapping[str, object],
    *,
    name: str = "object_overrides",
) -> dict[str, object]:
    resolved = deepcopy(dict(scene))
    raw_objects = resolved.get("objects")
    if not isinstance(raw_objects, Sequence) or isinstance(raw_objects, (str, bytes)):
        raise ConfigError(f"{name} requires scene.objects")
    objects = list(raw_objects)
    objects_by_id: dict[str, int] = {}
    for index, scene_object in enumerate(objects):
        if not isinstance(scene_object, Mapping):
            raise ConfigError(f"scene.objects[{index}] must be an object")
        object_id = scene_object.get("id")
        if not isinstance(object_id, str) or not object_id.strip():
            raise ConfigError(f"scene.objects[{index}].id is required for {name}")
        if object_id in objects_by_id:
            raise ConfigError(f"scene object id {object_id!r} is duplicated")
        objects_by_id[object_id] = index

    removed_indices: set[int] = set()
    for raw_object_id, raw_override in overrides.items():
        object_id = str(raw_object_id).strip()
        if not object_id:
            raise ConfigError(f"{name} keys must be non-empty object IDs")
        if not isinstance(raw_override, Mapping):
            raise ConfigError(f"{name}.{object_id} must be an object")
        if "id" in raw_override:
            raise ConfigError(f"{name}.{object_id}.id cannot change a scene object's identity")
        if object_id not in objects_by_id:
            available = ", ".join(objects_by_id) or "none"
            raise ConfigError(f"{name} references unknown scene object {object_id!r}. Available objects: {available}")
        enabled = raw_override.get("enabled", True)
        if not isinstance(enabled, bool):
            raise ConfigError(f"{name}.{object_id}.enabled must be a boolean")
        index = objects_by_id[object_id]
        if not enabled:
            removed_indices.add(index)
            continue
        patch = {str(key): deepcopy(value) for key, value in raw_override.items() if key != "enabled"}
        objects[index] = deep_merge(objects[index], patch)

    resolved["objects"] = [scene_object for index, scene_object in enumerate(objects) if index not in removed_indices]
    return resolved


def resolve_constant_references(
    value: object,
    *,
    constants: Mapping[str, object],
    path: str = "config",
    stack: tuple[str, ...] = (),
) -> object:
    if isinstance(value, Mapping):
        if CONSTANT_REF_KEY in value:
            constant_name = value[CONSTANT_REF_KEY]
            if not isinstance(constant_name, str) or not constant_name.strip():
                raise ConfigError(f"{path}.{CONSTANT_REF_KEY} must be a non-empty string")
            if constant_name not in constants:
                raise ConfigError(f"{path} references unknown constant {constant_name!r}")
            if constant_name in stack:
                cycle = " -> ".join((*stack, constant_name))
                raise ConfigError(f"{path} contains cyclic constant reference: {cycle}")
            resolved_constant = resolve_constant_references(
                deepcopy(constants[constant_name]),
                constants=constants,
                path=f"constants.{constant_name}",
                stack=(*stack, constant_name),
            )
            if set(value.keys()) == {CONSTANT_REF_KEY}:
                return resolved_constant
            if not isinstance(resolved_constant, Mapping):
                raise ConfigError(f"{path} can only merge {CONSTANT_REF_KEY!r} when it references an object")
            overrides = {
                str(key): resolve_constant_references(value_item, constants=constants, path=f"{path}.{key}", stack=stack)
                for key, value_item in value.items()
                if key != CONSTANT_REF_KEY
            }
            return deep_merge(resolved_constant, overrides)
        return {
            str(key): resolve_constant_references(value_item, constants=constants, path=f"{path}.{key}", stack=stack)
            for key, value_item in value.items()
        }
    if isinstance(value, list):
        return [
            resolve_constant_references(item, constants=constants, path=f"{path}[{index}]", stack=stack)
            for index, item in enumerate(value)
        ]
    return deepcopy(value)


def resolve_config_constants(config: Mapping[str, object], *, include_variants: bool = False) -> dict[str, object]:
    raw_constants = config.get("constants", {})
    if raw_constants is None:
        raw_constants = {}
    if not isinstance(raw_constants, Mapping):
        raise ConfigError("constants must be an object")
    constants = {**deepcopy(BUILTIN_CONFIG_CONSTANTS), **deepcopy(dict(raw_constants))}

    resolved: dict[str, object] = {}
    for key, value in config.items():
        if key == "constants":
            resolved[key] = deepcopy(constants)
        elif key == "variants" and not include_variants:
            resolved[key] = deepcopy(value)
        else:
            resolved[str(key)] = resolve_constant_references(value, constants=constants, path=str(key))
    return resolved


def resolve_style(style_config: object) -> dict[str, object]:
    if style_config is None:
        return dict(STYLE_PRESETS[DEFAULT_STYLE_PRESET_NAME])
    if isinstance(style_config, str):
        if style_config not in STYLE_PRESETS:
            raise ConfigError(f"Unknown annotation style preset {style_config!r}")
        return dict(STYLE_PRESETS[style_config])
    if not isinstance(style_config, Mapping):
        raise ConfigError("annotations.style must be an object or preset name")
    preset_name = str(style_config.get("preset", DEFAULT_STYLE_PRESET_NAME))
    if preset_name not in STYLE_PRESETS:
        raise ConfigError(f"Unknown annotation style preset {preset_name!r}")
    overrides = normalize_style_aliases(style_config)
    overrides.pop("preset", None)
    return deep_merge(STYLE_PRESETS[preset_name], overrides)


def normalize_style_aliases(style_config: Mapping[str, object]) -> dict[str, object]:
    normalized = dict(style_config)
    if "font_size_px" in normalized and "label_font_size_px" not in normalized:
        normalized["label_font_size_px"] = normalized["font_size_px"]
    return normalized


def annotation_parameter_type(annotation_id: str, *, kind: str = "dimension") -> str:
    name = annotation_id.lower()
    if "grid" in name or "vgrid" in name:
        return "grids"
    if "angle" in name:
        return "angle"
    if kind == "radius" or any(token in name for token in ("radius", "fillet", "rounding")):
        return "radius"
    return "mm"


def type_line_color(
    style_config: Mapping[str, object],
    parameter_type: str,
    *,
    index: int = 0,
    fallback: str = "#2f7f8f",
) -> str:
    type_styles = style_config.get("type_styles", {})
    type_style = type_styles.get(parameter_type, {}) if isinstance(type_styles, Mapping) else {}
    if isinstance(type_style, Mapping):
        line_colors = type_style.get("line_colors")
        if isinstance(line_colors, Sequence) and not isinstance(line_colors, (str, bytes)) and line_colors:
            return str(line_colors[index % len(line_colors)])
        line_color = type_style.get("line_color")
        if isinstance(line_color, str) and line_color:
            return line_color
    return fallback


def resolve_preset_mapping(
    value: object,
    *,
    presets: Mapping[str, Mapping[str, object]],
    name: str,
    default_preset: str | None = None,
) -> dict[str, object]:
    if value is None:
        value = {}
    if isinstance(value, str):
        preset_name = value
        overrides: Mapping[str, object] = {}
    elif isinstance(value, Mapping):
        preset_name = str(value.get("preset", default_preset or ""))
        overrides = value
    else:
        raise ConfigError(f"{name} must be an object or preset name")
    if not preset_name:
        return dict(overrides)
    if preset_name not in presets:
        raise ConfigError(f"Unknown {name} preset {preset_name!r}")
    resolved_overrides = dict(overrides)
    resolved_overrides.pop("preset", None)
    return deep_merge(presets[preset_name], resolved_overrides)


def scene_inherits_target_transform(scene_config: Mapping[str, object]) -> bool:
    return bool(scene_config.get("inherit_target_transform", "transform" not in scene_config))


def resolve_scene_transform(
    scene_config: Mapping[str, object],
    *,
    expression_context: Mapping[str, float],
) -> dict[str, object] | None:
    transform = scene_config.get("transform")
    if transform is None:
        return None
    if not isinstance(transform, Mapping):
        raise ConfigError("scene.transform must be an object")
    location_mm = vector3(transform.get("location_mm"), name="scene.transform.location_mm", context=expression_context)
    rotation_deg = vector3(transform.get("rotation_deg"), name="scene.transform.rotation_deg", context=expression_context)
    scale = vector3(transform.get("scale"), name="scene.transform.scale", context=expression_context)
    return {
        "location_mm": list(location_mm),
        "location": [value / 1000.0 for value in location_mm],
        "rotation_deg": list(rotation_deg),
        "scale": list(scale),
    }


def format_scad_define(name: str, value: object) -> str:
    if isinstance(value, bool):
        formatted = "true" if value else "false"
    elif isinstance(value, (int, float)):
        formatted = f"{value:g}" if isinstance(value, float) else str(value)
    elif isinstance(value, str):
        stripped = value.strip()
        if (stripped.startswith('"') and stripped.endswith('"')) or stripped in {"true", "false"}:
            formatted = stripped
        else:
            formatted = json.dumps(value)
    else:
        formatted = json.dumps(value)
    return f"{name}={formatted}"


def build_scad_defines(model_config: Mapping[str, object]) -> tuple[str, ...]:
    raw_defines = model_config.get("defines", {})
    if isinstance(raw_defines, Mapping):
        return tuple(format_scad_define(str(name), value) for name, value in raw_defines.items())
    if isinstance(raw_defines, Sequence) and not isinstance(raw_defines, (str, bytes)):
        return tuple(str(value) for value in raw_defines)
    raise ConfigError("model.defines must be an object or list")


def build_expression_context(config: Mapping[str, object]) -> dict[str, float]:
    context: dict[str, float] = {}
    constants = config.get("constants", {})
    if isinstance(constants, Mapping):
        for name, value in constants.items():
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                context[str(name)] = float(value)
    return context


def build_expression_context_for_model(config: Mapping[str, object], model_config: Mapping[str, object]) -> dict[str, float]:
    context = build_expression_context(config)
    defines = model_config.get("defines", {})
    if isinstance(defines, Mapping):
        for name, value in defines.items():
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                context[str(name)] = float(value)
    return context


def eval_numeric_expression(value: object, *, context: Mapping[str, float], name: str) -> float:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    if not isinstance(value, str):
        raise ConfigError(f"{name} must be a number or expression string")
    expression = value.strip()
    if not expression:
        raise ConfigError(f"{name} expression must not be empty")

    def eval_node(node: ast.AST) -> float:
        if isinstance(node, ast.Expression):
            return eval_node(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)) and not isinstance(node.value, bool):
            return float(node.value)
        if isinstance(node, ast.Name):
            if node.id not in context:
                raise ConfigError(f"{name} references unknown constant {node.id!r}")
            return float(context[node.id])
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
            value = eval_node(node.operand)
            return value if isinstance(node.op, ast.UAdd) else -value
        if isinstance(node, ast.BinOp) and isinstance(node.op, (ast.Add, ast.Sub, ast.Mult, ast.Div)):
            left = eval_node(node.left)
            right = eval_node(node.right)
            if isinstance(node.op, ast.Add):
                return left + right
            if isinstance(node.op, ast.Sub):
                return left - right
            if isinstance(node.op, ast.Mult):
                return left * right
            if right == 0:
                raise ConfigError(f"{name} divides by zero")
            return left / right
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
            if node.keywords or len(node.args) != 1:
                raise ConfigError(f"{name} contains unsupported function call syntax")
            value = eval_node(node.args[0])
            rounded = int(round(value))
            if node.func.id == "odd":
                return 1.0 if rounded % 2 else 0.0
            if node.func.id == "even":
                return 0.0 if rounded % 2 else 1.0
            raise ConfigError(f"{name} references unsupported function {node.func.id!r}")
        raise ConfigError(f"{name} contains unsupported expression syntax")

    try:
        parsed = ast.parse(expression, mode="eval")
    except SyntaxError as exc:
        raise ConfigError(f"{name} is not a valid expression: {expression!r}") from exc
    return eval_node(parsed)


def vector3(
    value: object,
    *,
    default: Sequence[float] | None = None,
    name: str = "vector",
    context: Mapping[str, float] | None = None,
) -> tuple[float, float, float]:
    if value is None and default is not None:
        value = default
    if isinstance(value, Mapping):
        try:
            return tuple(
                eval_numeric_expression(value[axis], context=context or {}, name=f"{name}.{axis}")
                for axis in AXES
            )
        except KeyError as exc:
            raise ConfigError(f"{name} mapping must contain x, y, and z") from exc
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 3:
        raise ConfigError(f"{name} must be a three-number list or x/y/z object")
    return tuple(
        eval_numeric_expression(item, context=context or {}, name=f"{name}[{index}]")
        for index, item in enumerate(value)
    )


def vector2(
    value: object,
    *,
    default: Sequence[float] | None = None,
    name: str = "vector",
    context: Mapping[str, float] | None = None,
) -> tuple[float, float]:
    if value is None and default is not None:
        value = default
    if isinstance(value, Mapping):
        try:
            return tuple(
                eval_numeric_expression(value[axis], context=context or {}, name=f"{name}.{axis}")
                for axis in ("x", "y")
            )
        except KeyError as exc:
            raise ConfigError(f"{name} mapping must contain x and y") from exc
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 2:
        raise ConfigError(f"{name} must be a two-number list or x/y object")
    return tuple(
        eval_numeric_expression(item, context=context or {}, name=f"{name}[{index}]")
        for index, item in enumerate(value)
    )


def add_vectors(left: Sequence[float], right: Sequence[float]) -> tuple[float, float, float]:
    return tuple(float(left[index]) + float(right[index]) for index in range(3))


def mapping_vector(values: Mapping[str, object]) -> tuple[float, float, float]:
    return tuple(float(values[axis]) for axis in AXES)


def annotation_label(annotation: Mapping[str, object], *, override: str | None = None, show_value: bool = False) -> str:
    if override:
        return override
    label = str(annotation.get("label") or annotation.get("id") or "dimension")
    value = str(annotation.get("value", "")).strip()
    return f"{label} = {value}" if show_value and value else label


def aliases_from_config(
    config: Mapping[str, object],
    *,
    context: Mapping[str, object] | None = None,
) -> Mapping[str, object]:
    aliases = config.get("aliases", {})
    if isinstance(aliases, Mapping):
        if context is None:
            return aliases
        formatted: dict[str, object] = {}
        for key, value in aliases.items():
            if not isinstance(value, str) or "{" not in value:
                formatted[str(key)] = value
                continue
            try:
                formatted[str(key)] = value.format_map(context)
            except (KeyError, ValueError):
                formatted[str(key)] = value
        return formatted
    return {}


def label_overrides_from_config(config: Mapping[str, object], aliases: Mapping[str, object] | None = None) -> Mapping[str, object]:
    merged: dict[str, object] = dict(aliases or {})
    labels = config.get("labels", {})
    if isinstance(labels, Mapping):
        merged.update(labels)
    return merged


def resolve_config_path(value: str | Path, *, config_dir: Path, project_root: Path) -> Path:
    path = Path(value).expanduser()
    if path.is_absolute():
        return path.resolve()
    config_relative = (config_dir / path).resolve()
    if config_relative.exists():
        return config_relative
    return (project_root / path).resolve()

