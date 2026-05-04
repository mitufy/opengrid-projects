"""Config parsing and annotation segment preparation."""

from __future__ import annotations

import ast
import json
from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Sequence

from annotation_renderer.scad_annotations import (
    annotation_to_arc_callout,
    annotation_to_dimension_segment,
    annotation_to_radius_callout,
    find_scad_annotation,
)


AXES = ("x", "y", "z")
DEFAULT_OUTPUT_DIR = "build/scene_annotations"
DEFAULT_LINE_ALPHA = 255
DEFAULT_LINE_COLORS = {
    "hook_length": "#2f7f8f",
    "hook_thickness": "#6f7f2f",
    "hook_vertical_grids": "#7f4f8f",
    "shelf_depth": "#2f7f8f",
    "shelf_width": "#6f7f2f",
    "shelf_back_thickness": "#8b6f2f",
    "shelf_bottom_thickness": "#7f4f8f",
    "horizontal_grids": "#2f7f8f",
    "vertical_grids": "#7f4f8f",
    "depth_grids": "#6f7f2f",
    "circular_corner_radius": "#8b6f2f",
    "circular_corner_radius_extent": "#8b6f2f",
    "circular_tip_radius": "#8b6f2f",
    "circular_tip_radius_extent": "#8b6f2f",
    "circular_tip_angle": "#8b6f2f",
    "hook_width": "#2f7f8f",
    "rectangular_tip_extra_length": "#8b6f2f",
    "truss_beam_reach": "#2f7f8f",
    "truss_strut_interval": "#7f4f8f",
    "truss_thickness": "#6f7f2f",
    "truss_vertical_grids": "#7f4f8f",
    "shelf_corner_fillet": "#8b6f2f",
    "shelf_front_edge_depth": "#6f7f2f",
    "shelf_side_edge_depth": "#2f7f8f",
    "shell_thickness": "#6f7f2f",
    "container_width_clearance": "#8b6f2f",
    "container_height_clearance": "#7f4f8f",
    "container_depth_clearance": "#2f7f8f",
}
DEFAULT_TYPE_STYLES: dict[str, dict[str, object]] = {
    "grids": {
        "line_colors": ["#000000"],
        "font": "sans",
    },
    "mm": {
        "line_colors": ["#2563eb"],
        "font": "sans",
    },
    "radius": {
        "line_colors": ["#dc2626"],
        "font": "sans",
    },
    "angle": {
        "line_colors": ["#dc2626"],
        "font": "sans",
    },
}
CONSTANT_REF_KEY = "$constant"
SCENE_OBJECT_CONFIG_KEYS = {
    "id",
    "target_object",
    "model",
    "replace_target_object",
    "inherit_target_transform",
    "transform",
    "material_source_object",
    "material",
    "mesh_shading",
}
SCENE_OBJECT_DEFAULT_KEYS = SCENE_OBJECT_CONFIG_KEYS - {"id"}
STYLE_PRESETS: dict[str, dict[str, object]] = {
    "makerworld_technical_light": {
        "line_alpha": 255,
        "line_width_px": 3,
        "extension_width_px": 1.7,
        "extension_visible": True,
        "extension_dash_px": 6,
        "extension_gap_px": 4,
        "tick_length_px": 18,
        "label_font_size_px": 28,
        "label_color": "#18212b",
        "label_outline_color": "#f8fafc",
        "label_outline_width_px": 2,
        "show_values": False,
        "colors": {},
        "type_styles": DEFAULT_TYPE_STYLES,
    }
}
RENDER_PRESETS: dict[str, dict[str, object]] = {
    "cycles_standard_scene": {
        "engine": "cycles",
        "quality": "standard",
        "width": 1200,
        "height": 900,
        "fit_camera": True,
        "fit_margin": 0.08,
        "mesh_shading": "flat",
    },
    "cycles_draft_scene": {
        "engine": "cycles",
        "quality": "draft",
        "width": 1200,
        "height": 900,
        "fit_camera": True,
        "fit_margin": 0.08,
        "mesh_shading": "flat",
    },
}


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


class ConfigError(ValueError):
    """Raised when an annotation render config is invalid."""


def deep_merge(base: Mapping[str, object], override: Mapping[str, object]) -> dict[str, object]:
    merged: dict[str, object] = dict(base)
    for key, value in override.items():
        if key == "preset":
            continue
        current = merged.get(key)
        if isinstance(current, Mapping) and isinstance(value, Mapping):
            merged[key] = deep_merge(current, value)
        else:
            merged[key] = value
    return merged


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
    constants = config.get("constants", {})
    if constants is None:
        constants = {}
    if not isinstance(constants, Mapping):
        raise ConfigError("constants must be an object")

    resolved: dict[str, object] = {}
    for key, value in config.items():
        if key == "constants":
            resolved[key] = deepcopy(value)
        elif key == "variants" and not include_variants:
            resolved[key] = deepcopy(value)
        else:
            resolved[str(key)] = resolve_constant_references(value, constants=constants, path=str(key))
    return resolved


def resolve_style(style_config: object) -> dict[str, object]:
    if style_config is None:
        return dict(STYLE_PRESETS["makerworld_technical_light"])
    if isinstance(style_config, str):
        if style_config not in STYLE_PRESETS:
            raise ConfigError(f"Unknown annotation style preset {style_config!r}")
        return dict(STYLE_PRESETS[style_config])
    if not isinstance(style_config, Mapping):
        raise ConfigError("annotations.style must be an object or preset name")
    preset_name = str(style_config.get("preset", "makerworld_technical_light"))
    if preset_name not in STYLE_PRESETS:
        raise ConfigError(f"Unknown annotation style preset {preset_name!r}")
    return deep_merge(STYLE_PRESETS[preset_name], style_config)


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
    return deep_merge(presets[preset_name], overrides)


def resolve_scene(scene_config: object) -> dict[str, object]:
    if scene_config is None:
        scene_config = {}
    if not isinstance(scene_config, Mapping):
        raise ConfigError("scene must be an object")
    if "preset" in scene_config:
        raise ConfigError("scene.preset is not supported; set scene.blend_file explicitly")
    resolved = dict(scene_config)
    if "blend_file" not in resolved or not isinstance(resolved["blend_file"], str) or not str(resolved["blend_file"]).strip():
        raise ConfigError("scene.blend_file is required")
    objects = resolved.get("objects")
    if objects is None:
        if "object_defaults" in resolved:
            raise ConfigError("scene.object_defaults requires scene.objects")
        if "target_object" not in resolved or not isinstance(resolved["target_object"], str) or not str(resolved["target_object"]).strip():
            raise ConfigError("scene.target_object is required")
    else:
        validate_scene_object_defaults(resolved.get("object_defaults"))
        validate_scene_objects(objects, object_defaults=resolved.get("object_defaults"))
    if "replace_target_object" in resolved and not isinstance(resolved["replace_target_object"], bool):
        raise ConfigError("scene.replace_target_object must be a boolean")
    if "inherit_target_transform" in resolved and not isinstance(resolved["inherit_target_transform"], bool):
        raise ConfigError("scene.inherit_target_transform must be a boolean")
    validate_scene_transform(resolved.get("transform"))
    if resolved.get("inherit_target_transform") is False and "transform" not in resolved:
        raise ConfigError("scene.transform is required when scene.inherit_target_transform is false")
    return resolved


def validate_model_config(model: object, *, name: str = "model") -> None:
    if not isinstance(model, Mapping):
        raise ConfigError(f"{name} must be an object")
    if not isinstance(model.get("scad_file"), str) or not str(model.get("scad_file")).strip():
        raise ConfigError(f"{name}.scad_file is required")
    defines = model.get("defines", {})
    if not isinstance(defines, Mapping) and (
        not isinstance(defines, Sequence) or isinstance(defines, (str, bytes))
    ):
        raise ConfigError(f"{name}.defines must be an object or list")


def validate_partial_model_config(model: object, *, name: str) -> None:
    if model is None:
        return
    if not isinstance(model, Mapping):
        raise ConfigError(f"{name} must be an object")
    if "scad_file" in model and (not isinstance(model["scad_file"], str) or not str(model["scad_file"]).strip()):
        raise ConfigError(f"{name}.scad_file must be a non-empty string")
    defines = model.get("defines", {})
    if not isinstance(defines, Mapping) and (
        not isinstance(defines, Sequence) or isinstance(defines, (str, bytes))
    ):
        raise ConfigError(f"{name}.defines must be an object or list")


def validate_partial_scene_transform(transform: object, *, name: str) -> None:
    if transform is None:
        return
    if not isinstance(transform, Mapping):
        raise ConfigError(f"{name} must be an object")
    allowed_keys = {"location_mm", "rotation_deg", "scale"}
    for key in transform:
        if key not in allowed_keys:
            raise ConfigError(f"{name}.{key} is not supported")
        validate_vector_shape(transform[key], name=f"{name}.{key}")


def validate_scene_object_defaults(defaults: object) -> None:
    if defaults is None:
        return
    if not isinstance(defaults, Mapping):
        raise ConfigError("scene.object_defaults must be an object")
    for key in defaults:
        if key not in SCENE_OBJECT_DEFAULT_KEYS:
            raise ConfigError(f"scene.object_defaults.{key} is not supported")
    if "target_object" in defaults and defaults["target_object"] is not None and (
        not isinstance(defaults["target_object"], str) or not str(defaults["target_object"]).strip()
    ):
        raise ConfigError("scene.object_defaults.target_object must be a non-empty string")
    if "material_source_object" in defaults and defaults["material_source_object"] is not None and (
        not isinstance(defaults["material_source_object"], str) or not str(defaults["material_source_object"]).strip()
    ):
        raise ConfigError("scene.object_defaults.material_source_object must be a non-empty string")
    validate_partial_model_config(defaults.get("model"), name="scene.object_defaults.model")
    if "replace_target_object" in defaults and not isinstance(defaults["replace_target_object"], bool):
        raise ConfigError("scene.object_defaults.replace_target_object must be a boolean")
    if "inherit_target_transform" in defaults and not isinstance(defaults["inherit_target_transform"], bool):
        raise ConfigError("scene.object_defaults.inherit_target_transform must be a boolean")
    if "mesh_shading" in defaults and defaults["mesh_shading"] not in {"flat", "smooth", "weighted_normals", "auto_smooth"}:
        raise ConfigError("scene.object_defaults.mesh_shading is not supported")
    validate_material_config(defaults.get("material"), name="scene.object_defaults.material")
    validate_partial_scene_transform(defaults.get("transform"), name="scene.object_defaults.transform")


def merge_scene_object_config(object_defaults: object, scene_object: Mapping[str, object]) -> dict[str, object]:
    if object_defaults is None:
        return dict(scene_object)
    if not isinstance(object_defaults, Mapping):
        raise ConfigError("scene.object_defaults must be an object")
    return deep_merge(object_defaults, scene_object)


def validate_scene_objects(objects: object, *, object_defaults: object = None) -> None:
    if not isinstance(objects, Sequence) or isinstance(objects, (str, bytes)) or not objects:
        raise ConfigError("scene.objects must be a non-empty array")
    for index, obj in enumerate(objects):
        name = f"scene.objects[{index}]"
        if not isinstance(obj, Mapping):
            raise ConfigError(f"{name} must be an object")
        for key in obj:
            if key not in SCENE_OBJECT_CONFIG_KEYS:
                raise ConfigError(f"{name}.{key} is not supported")
        merged_obj = merge_scene_object_config(object_defaults, obj)
        object_id = merged_obj.get("id")
        if not isinstance(object_id, str) or not object_id.strip():
            raise ConfigError(f"{name}.id is required")
        if "target_object" in merged_obj and (
            not isinstance(merged_obj["target_object"], str) or not str(merged_obj["target_object"]).strip()
        ):
            raise ConfigError(f"{name}.target_object must be a non-empty string")
        if "material_source_object" in merged_obj and merged_obj["material_source_object"] is not None and (
            not isinstance(merged_obj["material_source_object"], str) or not str(merged_obj["material_source_object"]).strip()
        ):
            raise ConfigError(f"{name}.material_source_object must be a non-empty string")
        validate_model_config(merged_obj.get("model"), name=f"{name}.model")
        if "replace_target_object" in merged_obj and not isinstance(merged_obj["replace_target_object"], bool):
            raise ConfigError(f"{name}.replace_target_object must be a boolean")
        if "inherit_target_transform" in merged_obj and not isinstance(merged_obj["inherit_target_transform"], bool):
            raise ConfigError(f"{name}.inherit_target_transform must be a boolean")
        if "mesh_shading" in merged_obj and merged_obj["mesh_shading"] not in {"flat", "smooth", "weighted_normals", "auto_smooth"}:
            raise ConfigError(f"{name}.mesh_shading is not supported")
        validate_material_config(merged_obj.get("material"), name=f"{name}.material")
        validate_partial_scene_transform(merged_obj.get("transform"), name=f"{name}.transform")


def validate_material_config(material: object, *, name: str) -> None:
    if material is None:
        return
    if isinstance(material, str):
        if not material.strip():
            raise ConfigError(f"{name} must not be empty")
        return
    if not isinstance(material, Mapping):
        raise ConfigError(f"{name} must be a color string or object")
    allowed_keys = {"color", "alpha", "roughness", "metallic"}
    for key in material:
        if key not in allowed_keys:
            raise ConfigError(f"{name}.{key} is not supported")
    if "color" in material and (not isinstance(material["color"], str) or not str(material["color"]).strip()):
        raise ConfigError(f"{name}.color must be a non-empty string")
    for key in ("alpha", "roughness", "metallic"):
        if key in material:
            value = material[key]
            if not isinstance(value, (int, float)) or isinstance(value, bool):
                raise ConfigError(f"{name}.{key} must be numeric")
            if float(value) < 0.0 or float(value) > 1.0:
                raise ConfigError(f"{name}.{key} must be between 0 and 1")


def validate_scene_transform(transform: object) -> None:
    if transform is None:
        return
    if not isinstance(transform, Mapping):
        raise ConfigError("scene.transform must be an object")
    allowed_keys = {"location_mm", "rotation_deg", "scale"}
    for key in transform:
        if key not in allowed_keys:
            raise ConfigError(f"scene.transform.{key} is not supported")
    for key in ("location_mm", "rotation_deg", "scale"):
        if key not in transform:
            raise ConfigError(f"scene.transform.{key} is required")
        validate_vector_shape(transform[key], name=f"scene.transform.{key}")


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


def resolve_render(render_config: object) -> dict[str, object]:
    return resolve_preset_mapping(
        render_config,
        presets=RENDER_PRESETS,
        name="render",
        default_preset="cycles_standard_scene",
    )


def validate_vector_shape(value: object, *, name: str) -> None:
    if value is None:
        return
    if isinstance(value, Mapping):
        missing = [axis for axis in AXES if axis not in value]
        if missing:
            raise ConfigError(f"{name} mapping must contain x, y, and z")
        return
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 3:
        raise ConfigError(f"{name} must be a three-item list or x/y/z object")


def validate_vector2_shape(value: object, *, name: str) -> None:
    if value is None:
        return
    if isinstance(value, Mapping):
        missing = [axis for axis in ("x", "y") if axis not in value]
        if missing:
            raise ConfigError(f"{name} mapping must contain x and y")
        return
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 2:
        raise ConfigError(f"{name} must be a two-item list or x/y object")


def validate_config_shape(config: Mapping[str, object]) -> None:
    scene = resolve_scene(config.get("scene", {}))
    raw_variants = config.get("variants", [])
    has_variants = (
        isinstance(raw_variants, Sequence)
        and not isinstance(raw_variants, (str, bytes))
        and bool(raw_variants)
    )
    if scene.get("objects") is None:
        if config.get("model") is None and has_variants:
            pass
        else:
            validate_model_config(config.get("model"))
    elif config.get("model") is not None:
        validate_model_config(config.get("model"))
    resolve_render(config.get("render", {}))

    annotations = config.get("annotations")
    if not isinstance(annotations, Mapping):
        raise ConfigError("annotations must be an object")
    chains = annotations.get("chains", [])
    radius_callouts = annotations.get("radius_callouts", [])
    arc_callouts = annotations.get("arc_callouts", [])
    angle_radius_callouts = annotations.get("angle_radius_callouts", [])
    image_labels = annotations.get("image_labels", [])
    annotation_object = annotations.get("object")
    if annotation_object is not None and (not isinstance(annotation_object, str) or not annotation_object.strip()):
        raise ConfigError("annotations.object must be a non-empty string")
    aliases = annotations.get("aliases", {})
    if aliases is not None:
        if not isinstance(aliases, Mapping):
            raise ConfigError("annotations.aliases must be an object")
        if not all(isinstance(key, str) and isinstance(label, str) for key, label in aliases.items()):
            raise ConfigError("annotations.aliases must map annotation IDs to strings")
    if not isinstance(chains, Sequence) or isinstance(chains, (str, bytes)):
        raise ConfigError("annotations.chains must be an array")
    for index, chain in enumerate(chains):
        validate_annotation_group(chain, name=f"annotations.chains[{index}]")
    if not isinstance(radius_callouts, Sequence) or isinstance(radius_callouts, (str, bytes)):
        raise ConfigError("annotations.radius_callouts must be an array")
    for index, radius_callout in enumerate(radius_callouts):
        validate_annotation_group(radius_callout, name=f"annotations.radius_callouts[{index}]")
    if not isinstance(arc_callouts, Sequence) or isinstance(arc_callouts, (str, bytes)):
        raise ConfigError("annotations.arc_callouts must be an array")
    for index, arc_callout in enumerate(arc_callouts):
        validate_annotation_group(arc_callout, name=f"annotations.arc_callouts[{index}]")
    if not isinstance(angle_radius_callouts, Sequence) or isinstance(angle_radius_callouts, (str, bytes)):
        raise ConfigError("annotations.angle_radius_callouts must be an array")
    for index, callout in enumerate(angle_radius_callouts):
        validate_angle_radius_group(callout, name=f"annotations.angle_radius_callouts[{index}]")
    if not isinstance(image_labels, Sequence) or isinstance(image_labels, (str, bytes)):
        raise ConfigError("annotations.image_labels must be an array")
    for index, image_label in enumerate(image_labels):
        validate_image_label(image_label, name=f"annotations.image_labels[{index}]")

    constants = config.get("constants", {})
    if constants is not None:
        if not isinstance(constants, Mapping):
            raise ConfigError("constants must be an object")
        for key in constants:
            if not isinstance(key, str) or not key.strip():
                raise ConfigError("constants keys must be non-empty strings")


def validate_annotation_group(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    if "optional" in value and not isinstance(value["optional"], bool):
        raise ConfigError(f"{name}.optional must be a boolean")
    ids = value.get("ids")
    if not isinstance(ids, Sequence) or isinstance(ids, (str, bytes)) or not ids:
        raise ConfigError(f"{name}.ids must be a non-empty list")
    if not all(isinstance(item, str) and item.strip() for item in ids):
        raise ConfigError(f"{name}.ids must contain only strings")
    validate_vector_shape(value.get("display_offset_mm"), name=f"{name}.display_offset_mm")
    labels = value.get("labels", {})
    if labels is not None:
        if not isinstance(labels, Mapping):
            raise ConfigError(f"{name}.labels must be an object")
        if not all(isinstance(key, str) and isinstance(label, str) for key, label in labels.items()):
            raise ConfigError(f"{name}.labels must map annotation IDs to strings")


def validate_angle_radius_group(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    if "optional" in value and not isinstance(value["optional"], bool):
        raise ConfigError(f"{name}.optional must be a boolean")
    for key in ("arc_id", "radius_id"):
        if not isinstance(value.get(key), str) or not str(value.get(key)).strip():
            raise ConfigError(f"{name}.{key} must be a non-empty string")
    for key in ("id", "angle_id"):
        if key in value and value[key] is not None and (not isinstance(value[key], str) or not str(value[key]).strip()):
            raise ConfigError(f"{name}.{key} must be a non-empty string")
    validate_vector_shape(value.get("display_offset_mm"), name=f"{name}.display_offset_mm")
    labels = value.get("labels", {})
    if labels is not None:
        if not isinstance(labels, Mapping):
            raise ConfigError(f"{name}.labels must be an object")
        if not all(isinstance(key, str) and isinstance(label, str) for key, label in labels.items()):
            raise ConfigError(f"{name}.labels must map annotation IDs to strings")
    for key in ("show_angle_label", "show_radius_label"):
        if key in value and not isinstance(value[key], bool):
            raise ConfigError(f"{name}.{key} must be a boolean")
    for key in ("angle_label_offset_px", "radius_label_offset_px", "angle_label_tangent_offset_px", "radius_label_tangent_offset_px"):
        if key in value and not isinstance(value[key], (int, float)):
            raise ConfigError(f"{name}.{key} must be numeric")


def validate_image_label(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    label_id = value.get("id")
    text = value.get("text")
    if (not isinstance(label_id, str) or not label_id.strip()) and (not isinstance(text, str) or not text.strip()):
        raise ConfigError(f"{name}.id or {name}.text is required")
    position = value.get("position", "bottom")
    allowed_positions = {"top", "bottom", "left", "right", "center", "top_left", "top_right", "bottom_left", "bottom_right"}
    if not isinstance(position, str) or position not in allowed_positions:
        raise ConfigError(f"{name}.position must be one of {', '.join(sorted(allowed_positions))}")
    validate_vector2_shape(value.get("offset_px"), name=f"{name}.offset_px")
    for key in ("label", "text", "value", "color", "value_color"):
        if key in value and value[key] is not None and not isinstance(value[key], str):
            raise ConfigError(f"{name}.{key} must be a string")
    for key in ("angle_deg",):
        if key in value and not isinstance(value[key], (int, float)):
            raise ConfigError(f"{name}.{key} must be numeric")
    if "show_value" in value and not isinstance(value["show_value"], bool):
        raise ConfigError(f"{name}.show_value must be a boolean")
    if "font_size_px" in value and not isinstance(value["font_size_px"], int):
        raise ConfigError(f"{name}.font_size_px must be an integer")


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
    model = config.get("model", {})
    defines = model.get("defines", {}) if isinstance(model, Mapping) else {}
    if isinstance(defines, Mapping):
        for name, value in defines.items():
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                context.setdefault(str(name), float(value))
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


def aliases_from_config(config: Mapping[str, object]) -> Mapping[str, object]:
    aliases = config.get("aliases", {})
    if isinstance(aliases, Mapping):
        return aliases
    return {}


def label_overrides_from_config(config: Mapping[str, object], aliases: Mapping[str, object] | None = None) -> Mapping[str, object]:
    merged: dict[str, object] = dict(aliases or {})
    labels = config.get("labels", {})
    if isinstance(labels, Mapping):
        merged.update(labels)
    return merged


def annotation_group_is_optional(config: Mapping[str, object]) -> bool:
    return bool(config.get("optional", False))


def collect_dimension_chain(
    *,
    annotations: Sequence[Mapping[str, object]],
    chain_config: Mapping[str, object],
    style_config: Mapping[str, object],
    expression_context: Mapping[str, float] | None = None,
    aliases: Mapping[str, object] | None = None,
) -> list[DimensionSegment]:
    ids = chain_config.get("ids")
    if not isinstance(ids, Sequence) or isinstance(ids, (str, bytes)) or not ids:
        raise ConfigError("dimension chain requires a non-empty ids list")
    offset = vector3(
        chain_config.get("display_offset_mm"),
        default=(0.0, 0.0, 0.0),
        name="display_offset_mm",
        context=expression_context,
    )
    colors = style_config.get("colors", {})
    if not isinstance(colors, Mapping):
        colors = {}
    show_values = bool(style_config.get("show_values", False))
    label_overrides = label_overrides_from_config(chain_config, aliases)
    optional = annotation_group_is_optional(chain_config)
    aligned = len(ids) > 1

    segments: list[DimensionSegment] = []
    for index, annotation_id in enumerate(ids):
        annotation_key = str(annotation_id)
        annotation = find_scad_annotation(annotations, annotation_key)
        segment = annotation_to_dimension_segment(annotation)
        if annotation is None or segment is None:
            if optional:
                continue
            raise ConfigError(f"No emitted dimension annotation named {annotation_id!r}")
        parameter_type = annotation_parameter_type(annotation_key, kind="dimension")
        fallback_color = str(colors.get(annotation_key, DEFAULT_LINE_COLORS.get(annotation_key, "#2f7f8f")))
        color = (
            type_line_color(style_config, parameter_type, index=index, fallback=fallback_color)
            if aligned
            else str(colors.get(annotation_key) or type_line_color(style_config, parameter_type, fallback=fallback_color))
        )
        source_start_mm = mapping_vector(segment["start_mm"])
        source_end_mm = mapping_vector(segment["end_mm"])
        segments.append(
            DimensionSegment(
                id=annotation_key,
                label=annotation_label(annotation, override=label_overrides.get(annotation_key), show_value=show_values),
                value=str(annotation.get("value", "")),
                start_mm=add_vectors(source_start_mm, offset),
                end_mm=add_vectors(source_end_mm, offset),
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
    ids = callout_config.get("ids")
    if not isinstance(ids, Sequence) or isinstance(ids, (str, bytes)) or not ids:
        raise ConfigError("radius callout requires a non-empty ids list")
    offset = vector3(
        callout_config.get("display_offset_mm"),
        default=(0.0, 0.0, 0.0),
        name="display_offset_mm",
        context=expression_context,
    )
    colors = style_config.get("colors", {})
    if not isinstance(colors, Mapping):
        colors = {}
    show_values = bool(style_config.get("show_values", False))
    label_overrides = label_overrides_from_config(callout_config, aliases)
    optional = annotation_group_is_optional(callout_config)

    callouts: list[RadiusCallout] = []
    for annotation_id in ids:
        annotation = find_scad_annotation(annotations, str(annotation_id))
        callout = annotation_to_radius_callout(annotation)
        if annotation is None or callout is None:
            if optional:
                continue
            raise ConfigError(f"No emitted radius annotation named {annotation_id!r}")
        annotation_key = str(annotation_id)
        parameter_type = annotation_parameter_type(annotation_key, kind="radius")
        fallback_color = DEFAULT_LINE_COLORS.get(annotation_key, "#8b6f2f")
        color = str(colors.get(annotation_key) or type_line_color(style_config, parameter_type, fallback=fallback_color))
        callouts.append(
            RadiusCallout(
                id=annotation_key,
                label=annotation_label(annotation, override=label_overrides.get(annotation_key), show_value=show_values),
                value=str(annotation.get("value", "")),
                center_mm=add_vectors(mapping_vector(callout["center_mm"]), offset),
                edge_mm=add_vectors(mapping_vector(callout["edge_mm"]), offset),
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
    ids = callout_config.get("ids")
    if not isinstance(ids, Sequence) or isinstance(ids, (str, bytes)) or not ids:
        raise ConfigError("arc callout requires a non-empty ids list")
    offset = vector3(
        callout_config.get("display_offset_mm"),
        default=(0.0, 0.0, 0.0),
        name="display_offset_mm",
        context=expression_context,
    )
    colors = style_config.get("colors", {})
    if not isinstance(colors, Mapping):
        colors = {}
    show_values = bool(style_config.get("show_values", False))
    label_overrides = label_overrides_from_config(callout_config, aliases)
    optional = annotation_group_is_optional(callout_config)

    callouts: list[ArcCallout] = []
    for annotation_id in ids:
        annotation = find_scad_annotation(annotations, str(annotation_id))
        callout = annotation_to_arc_callout(annotation)
        if annotation is None or callout is None:
            if optional:
                continue
            raise ConfigError(f"No emitted arc annotation named {annotation_id!r}")
        annotation_key = str(annotation_id)
        parameter_type = annotation_parameter_type(annotation_key, kind="arc")
        fallback_color = DEFAULT_LINE_COLORS.get(annotation_key, "#8b6f2f")
        color = str(colors.get(annotation_key) or type_line_color(style_config, parameter_type, fallback=fallback_color))
        points = tuple(add_vectors(mapping_vector(point), offset) for point in callout["points_mm"])
        callouts.append(
            ArcCallout(
                id=annotation_key,
                label=annotation_label(annotation, override=label_overrides.get(annotation_key), show_value=show_values),
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

    offset = vector3(
        callout_config.get("display_offset_mm"),
        default=(0.0, 0.0, 0.0),
        name="display_offset_mm",
        context=expression_context,
    )
    colors = style_config.get("colors", {})
    if not isinstance(colors, Mapping):
        colors = {}
    show_values = bool(style_config.get("show_values", False))
    label_overrides = label_overrides_from_config(callout_config, aliases)
    optional = annotation_group_is_optional(callout_config)

    radius_annotation = find_scad_annotation(annotations, radius_id)
    radius_callout = annotation_to_radius_callout(radius_annotation)
    if radius_annotation is None or radius_callout is None:
        if optional:
            return []
        raise ConfigError(f"No emitted radius annotation named {radius_id!r}")
    arc_annotation = find_scad_annotation(annotations, arc_id)
    arc_callout = annotation_to_arc_callout(arc_annotation)
    if arc_annotation is None or arc_callout is None:
        if optional:
            return []
        raise ConfigError(f"No emitted arc annotation named {arc_id!r}")

    angle_value = ""
    if expression_context is not None and angle_id in expression_context:
        angle_value = format_context_value(expression_context[angle_id])
    elif "value" in arc_annotation:
        angle_value = str(arc_annotation.get("value", ""))

    angle_base_label = str(label_overrides.get(angle_id) or label_overrides.get(arc_id) or angle_id)
    angle_label = f"{angle_base_label} = {angle_value}" if show_values and angle_value else angle_base_label
    radius_label = annotation_label(
        radius_annotation,
        override=label_overrides.get(radius_id),
        show_value=show_values,
    )
    callout_id = str(callout_config.get("id") or f"{angle_id}_{radius_id}").strip()
    angle_type = annotation_parameter_type(angle_id, kind="arc")
    radius_type = annotation_parameter_type(radius_id, kind="radius")
    arc_fallback = str(colors.get(angle_id) or colors.get(arc_id) or DEFAULT_LINE_COLORS.get(angle_id) or DEFAULT_LINE_COLORS.get(arc_id) or "#8b6f2f")
    radius_fallback = str(colors.get(radius_id) or DEFAULT_LINE_COLORS.get(radius_id) or arc_fallback)
    arc_color = type_line_color(style_config, angle_type, fallback=arc_fallback)
    radius_color = type_line_color(style_config, radius_type, fallback=radius_fallback)

    return [
        AngleRadiusCallout(
            id=callout_id,
            angle_label=angle_label,
            angle_value=angle_value,
            radius_label=radius_label,
            radius_value=str(radius_annotation.get("value", "")),
            center_mm=add_vectors(mapping_vector(radius_callout["center_mm"]), offset),
            edge_mm=add_vectors(mapping_vector(radius_callout["edge_mm"]), offset),
            points_mm=tuple(add_vectors(mapping_vector(point), offset) for point in arc_callout["points_mm"]),
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


def resolve_config_path(value: str | Path, *, config_dir: Path, project_root: Path) -> Path:
    path = Path(value).expanduser()
    if path.is_absolute():
        return path.resolve()
    config_relative = (config_dir / path).resolve()
    if config_relative.exists():
        return config_relative
    return (project_root / path).resolve()
