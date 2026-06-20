"""Validation for annotation render configs."""

from __future__ import annotations

from typing import Mapping, Sequence

from annotation_renderer.config_defaults import (
    ANIMATION_CLIP_CONFIG_KEYS,
    ANIMATION_CONFIG_KEYS,
    AXES,
    CONSTANT_REF_KEY,
    INTERPOLATION_NAMES,
    LOCATION_OFFSET_KEYFRAME_KEYS,
    MESH_SHADING_VALUES,
    OBJECT_ANIMATION_CONFIG_KEYS,
    OPACITY_KEYFRAME_KEYS,
    OUTPUT_FORMATS,
    RENDER_CAMERA_LOOK_AT_VALUES,
    RENDER_CAMERA_VIEW_VALUES,
    RENDER_CAMERA_VIEW_PRESET_VALUES,
    RENDER_CONFIG_KEYS,
    RENDER_ENGINE_VALUES,
    RENDER_LIGHTING_PRESET_VALUES,
    RENDER_OUTPUT_MODE_VALUES,
    RENDER_PRESETS,
    RENDER_QUALITY_VALUES,
    SCENE_OBJECT_CONFIG_KEYS,
    SCENE_OBJECT_DEFAULT_KEYS,
    SCENE_CONFIG_KEYS,
    STYLE_BOOLEAN_FIELDS,
    STYLE_INTEGER_FIELDS,
    STYLE_NUMBER_FIELDS,
    STYLE_OVERRIDE_KEYS,
    STYLE_PRESETS,
    STYLE_STRING_FIELDS,
    VISIBILITY_KEYFRAME_KEYS,
)
from annotation_renderer.config_resolution import deep_merge, resolve_preset_mapping
from annotation_renderer.config_schema import ConfigError


def resolve_scene(scene_config: object) -> dict[str, object]:
    if scene_config is None:
        scene_config = {}
    if not isinstance(scene_config, Mapping):
        raise ConfigError("scene must be an object")
    if "preset" in scene_config:
        raise ConfigError("scene.preset is not supported; set scene.blend_file explicitly")
    resolved = dict(scene_config)
    validate_allowed_keys(resolved, allowed=SCENE_CONFIG_KEYS, name="scene")
    if "blend_file" not in resolved or not isinstance(resolved["blend_file"], str) or not str(resolved["blend_file"]).strip():
        raise ConfigError("scene.blend_file is required")
    objects = resolved.get("objects")
    if objects is None:
        if "object_defaults" in resolved:
            raise ConfigError("scene.object_defaults requires scene.objects")
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


def validate_stl_file_config(stl_file: object, *, name: str) -> None:
    if not isinstance(stl_file, str) or not stl_file.strip():
        raise ConfigError(f"{name} must be a non-empty string")


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


def validate_line_copies_config(value: object, *, name: str) -> None:
    if value is None:
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    allowed_keys = {"count", "spacing_mm"}
    for key in value:
        if key not in allowed_keys:
            raise ConfigError(f"{name}.{key} is not supported")
    count = value.get("count")
    if not isinstance(count, int) or isinstance(count, bool):
        raise ConfigError(f"{name}.count must be an integer")
    if count < 1:
        raise ConfigError(f"{name}.count must be at least 1")
    if "spacing_mm" not in value:
        raise ConfigError(f"{name}.spacing_mm is required")
    validate_vector_shape(value["spacing_mm"], name=f"{name}.spacing_mm")


def validate_grid_copy_counts(value: object, *, name: str) -> None:
    if isinstance(value, Mapping):
        missing = [axis for axis in AXES if axis not in value]
        if missing:
            raise ConfigError(f"{name} mapping must contain x, y, and z")
        items = [value[axis] for axis in AXES]
    else:
        if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) != 3:
            raise ConfigError(f"{name} must be a three-item list or x/y/z object")
        items = list(value)
    for index, item in enumerate(items):
        if not isinstance(item, int) or isinstance(item, bool):
            raise ConfigError(f"{name}[{index}] must be an integer")
        if item < 1:
            raise ConfigError(f"{name}[{index}] must be at least 1")


def validate_grid_copies_config(value: object, *, name: str) -> None:
    if value is None:
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    allowed_keys = {"counts", "spacing_mm"}
    for key in value:
        if key not in allowed_keys:
            raise ConfigError(f"{name}.{key} is not supported")
    if "counts" not in value:
        raise ConfigError(f"{name}.counts is required")
    validate_grid_copy_counts(value["counts"], name=f"{name}.counts")
    if "spacing_mm" not in value:
        raise ConfigError(f"{name}.spacing_mm is required")
    validate_vector_shape(value["spacing_mm"], name=f"{name}.spacing_mm")


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
    if "stl_file" in defaults:
        validate_stl_file_config(defaults["stl_file"], name="scene.object_defaults.stl_file")
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
        if merged_obj.get("model") is not None:
            validate_model_config(merged_obj.get("model"), name=f"{name}.model")
        if "stl_file" in merged_obj:
            validate_stl_file_config(merged_obj["stl_file"], name=f"{name}.stl_file")
        source_count = int(merged_obj.get("model") is not None) + int(merged_obj.get("stl_file") is not None)
        if source_count != 1:
            raise ConfigError(f"{name} must define exactly one of model or stl_file")
        if "replace_target_object" in merged_obj and not isinstance(merged_obj["replace_target_object"], bool):
            raise ConfigError(f"{name}.replace_target_object must be a boolean")
        if "inherit_target_transform" in merged_obj and not isinstance(merged_obj["inherit_target_transform"], bool):
            raise ConfigError(f"{name}.inherit_target_transform must be a boolean")
        if "mesh_shading" in merged_obj and merged_obj["mesh_shading"] not in MESH_SHADING_VALUES:
            raise ConfigError(f"{name}.mesh_shading is not supported")
        validate_material_config(merged_obj.get("material"), name=f"{name}.material")
        validate_partial_scene_transform(merged_obj.get("transform"), name=f"{name}.transform")
        validate_line_copies_config(merged_obj.get("line_copies"), name=f"{name}.line_copies")
        validate_grid_copies_config(merged_obj.get("grid_copies"), name=f"{name}.grid_copies")
        if merged_obj.get("line_copies") is not None and merged_obj.get("grid_copies") is not None:
            raise ConfigError(f"{name} must not define both line_copies and grid_copies")


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


def validate_material_overrides_config(value: object, *, name: str = "render.material_overrides") -> None:
    if value is None:
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    for object_id, material in value.items():
        if not isinstance(object_id, str) or not object_id.strip():
            raise ConfigError(f"{name} keys must be non-empty strings")
        validate_material_config(material, name=f"{name}.{object_id}")


def validate_number_expression(value: object, *, name: str) -> None:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return
    if isinstance(value, str) and value.strip():
        return
    raise ConfigError(f"{name} must be numeric or an expression string")


def validate_number_expression_field(value: Mapping[str, object], key: str, *, name: str) -> None:
    if key in value:
        validate_number_expression(value[key], name=f"{name}.{key}")


def validate_lighting_config(value: object, *, name: str = "render.lighting") -> None:
    if value is None:
        return
    if isinstance(value, str):
        if value not in RENDER_LIGHTING_PRESET_VALUES:
            choices = ", ".join(sorted(RENDER_LIGHTING_PRESET_VALUES))
            raise ConfigError(f"{name} must be one of {choices}")
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be a preset name or object")
    allowed_keys = {"preset", "strength", "ambient_strength", "color"}
    validate_allowed_keys(value, allowed=allowed_keys, name=name)
    validate_enum_field(value, "preset", name=name, allowed=RENDER_LIGHTING_PRESET_VALUES)
    validate_number_field(value, "strength", name=name, minimum=0.0)
    validate_number_field(value, "ambient_strength", name=name, minimum=0.0)
    if "color" in value and (not isinstance(value["color"], str) or not str(value["color"]).strip()):
        raise ConfigError(f"{name}.color must be a non-empty string")


def validate_outline_config(value: object, *, name: str = "render.outline") -> None:
    if value is None or isinstance(value, bool):
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be a boolean or object")
    allowed_keys = {"enabled", "line_color", "line_width_px"}
    validate_allowed_keys(value, allowed=allowed_keys, name=name)
    if "enabled" in value and not isinstance(value["enabled"], bool):
        raise ConfigError(f"{name}.enabled must be a boolean")
    if "line_color" in value and (not isinstance(value["line_color"], str) or not str(value["line_color"]).strip()):
        raise ConfigError(f"{name}.line_color must be a non-empty string")
    validate_number_field(value, "line_width_px", name=name, minimum=0.0)


def validate_ground_plane_config(value: object, *, name: str = "render.ground_plane") -> None:
    if value is None or isinstance(value, bool):
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be a boolean or object")
    allowed_keys = {"enabled", "offset_mm", "size_scale", "color", "alpha", "roughness", "shadow_only"}
    validate_allowed_keys(value, allowed=allowed_keys, name=name)
    if "enabled" in value and not isinstance(value["enabled"], bool):
        raise ConfigError(f"{name}.enabled must be a boolean")
    validate_number_expression_field(value, "offset_mm", name=name)
    validate_number_field(value, "size_scale", name=name, minimum=0.000001)
    for key in ("alpha", "roughness"):
        validate_number_field(value, key, name=name, minimum=0.0, maximum=1.0)
    if "color" in value and (not isinstance(value["color"], str) or not str(value["color"]).strip()):
        raise ConfigError(f"{name}.color must be a non-empty string")
    if "shadow_only" in value and not isinstance(value["shadow_only"], bool):
        raise ConfigError(f"{name}.shadow_only must be a boolean")


def validate_cutaway_config(value: object, *, name: str = "render.cutaway") -> None:
    if value is None or isinstance(value, bool):
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be a boolean or object")
    allowed_keys = {"enabled", "objects", "axis", "keep", "position_mm", "position_fraction", "offset_mm", "section_plane"}
    validate_allowed_keys(value, allowed=allowed_keys, name=name)
    if "enabled" in value and not isinstance(value["enabled"], bool):
        raise ConfigError(f"{name}.enabled must be a boolean")
    validate_enum_field(value, "axis", name=name, allowed={"x", "y", "z"})
    validate_enum_field(value, "keep", name=name, allowed={"positive", "negative"})
    for key in ("position_mm", "position_fraction", "offset_mm"):
        validate_number_expression_field(value, key, name=name)
    if "position_mm" in value and "position_fraction" in value:
        raise ConfigError(f"{name} must not define both position_mm and position_fraction")
    if "position_fraction" in value and is_number(value["position_fraction"]):
        fraction = float(value["position_fraction"])
        if fraction < 0.0 or fraction > 1.0:
            raise ConfigError(f"{name}.position_fraction must be between 0 and 1")
    if "objects" in value:
        objects = value["objects"]
        if not isinstance(objects, Sequence) or isinstance(objects, (str, bytes)):
            raise ConfigError(f"{name}.objects must be an array")
        if not all(isinstance(item, str) and item.strip() for item in objects):
            raise ConfigError(f"{name}.objects must contain non-empty strings")
    validate_cutaway_section_plane_config(value.get("section_plane"), name=f"{name}.section_plane")


def validate_cutaway_section_plane_config(value: object, *, name: str) -> None:
    if value is None or isinstance(value, bool):
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be a boolean or object")
    allowed_keys = {"enabled", "color", "alpha", "padding_mm", "offset_mm"}
    validate_allowed_keys(value, allowed=allowed_keys, name=name)
    if "enabled" in value and not isinstance(value["enabled"], bool):
        raise ConfigError(f"{name}.enabled must be a boolean")
    if "color" in value and (not isinstance(value["color"], str) or not str(value["color"]).strip()):
        raise ConfigError(f"{name}.color must be a non-empty string")
    validate_number_field(value, "alpha", name=name, minimum=0.0, maximum=1.0)
    for key in ("padding_mm", "offset_mm"):
        validate_number_expression_field(value, key, name=name)


def validate_xray_config(value: object, *, name: str = "render.xray") -> None:
    if value is None or isinstance(value, bool):
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be a boolean or object")
    allowed_keys = {"enabled", "objects", "alpha", "color"}
    validate_allowed_keys(value, allowed=allowed_keys, name=name)
    if "enabled" in value and not isinstance(value["enabled"], bool):
        raise ConfigError(f"{name}.enabled must be a boolean")
    validate_number_field(value, "alpha", name=name, minimum=0.0, maximum=1.0)
    if "color" in value and (not isinstance(value["color"], str) or not str(value["color"]).strip()):
        raise ConfigError(f"{name}.color must be a non-empty string")
    if "objects" in value:
        objects = value["objects"]
        if not isinstance(objects, Sequence) or isinstance(objects, (str, bytes)):
            raise ConfigError(f"{name}.objects must be an array")
        if not all(isinstance(item, str) and item.strip() for item in objects):
            raise ConfigError(f"{name}.objects must contain non-empty strings")


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


def resolve_render(render_config: object) -> dict[str, object]:
    render = resolve_preset_mapping(
        render_config,
        presets=RENDER_PRESETS,
        name="render",
        default_preset="cycles_standard_scene",
    )
    validate_render_config(render)
    return render


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


def is_integer(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def is_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def validate_allowed_keys(value: Mapping[str, object], *, allowed: set[str], name: str) -> None:
    for key in value:
        if key not in allowed:
            raise ConfigError(f"{name}.{key} is not supported")


def validate_integer_field(value: Mapping[str, object], key: str, *, name: str, minimum: int | None = None) -> None:
    if key not in value:
        return
    field_value = value[key]
    if not is_integer(field_value):
        raise ConfigError(f"{name}.{key} must be an integer")
    if minimum is not None and int(field_value) < minimum:
        raise ConfigError(f"{name}.{key} must be at least {minimum}")


def validate_number_field(
    value: Mapping[str, object],
    key: str,
    *,
    name: str,
    minimum: float | None = None,
    maximum: float | None = None,
) -> None:
    if key not in value:
        return
    field_value = value[key]
    if not is_number(field_value):
        raise ConfigError(f"{name}.{key} must be numeric")
    if minimum is not None and float(field_value) < minimum:
        raise ConfigError(f"{name}.{key} must be at least {minimum:g}")
    if maximum is not None and float(field_value) > maximum:
        raise ConfigError(f"{name}.{key} must be at most {maximum:g}")


def validate_enum_field(value: Mapping[str, object], key: str, *, name: str, allowed: set[str]) -> None:
    if key not in value:
        return
    field_value = value[key]
    if not isinstance(field_value, str) or field_value not in allowed:
        choices = ", ".join(sorted(allowed))
        raise ConfigError(f"{name}.{key} must be one of {choices}")


def validate_visibility_keyframes(value: object, *, name: str) -> None:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or not value:
        raise ConfigError(f"{name} must be a non-empty array")
    for index, keyframe in enumerate(value):
        keyframe_name = f"{name}[{index}]"
        if not isinstance(keyframe, Mapping):
            raise ConfigError(f"{keyframe_name} must be an object")
        validate_allowed_keys(keyframe, allowed=VISIBILITY_KEYFRAME_KEYS, name=keyframe_name)
        validate_integer_field(keyframe, "frame", name=keyframe_name, minimum=0)
        if "visible" not in keyframe or not isinstance(keyframe["visible"], bool):
            raise ConfigError(f"{keyframe_name}.visible must be a boolean")


def validate_opacity_keyframes(value: object, *, name: str) -> None:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or not value:
        raise ConfigError(f"{name} must be a non-empty array")
    for index, keyframe in enumerate(value):
        keyframe_name = f"{name}[{index}]"
        if not isinstance(keyframe, Mapping):
            raise ConfigError(f"{keyframe_name} must be an object")
        validate_allowed_keys(keyframe, allowed=OPACITY_KEYFRAME_KEYS, name=keyframe_name)
        validate_integer_field(keyframe, "frame", name=keyframe_name, minimum=0)
        if not any(key in keyframe for key in ("value", "opacity", "alpha")):
            raise ConfigError(f"{keyframe_name}.value is required")
        for key in ("value", "opacity", "alpha"):
            validate_number_field(keyframe, key, name=keyframe_name, minimum=0.0, maximum=1.0)


def validate_location_offset_keyframes(value: object, *, name: str) -> None:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or len(value) < 2:
        raise ConfigError(f"{name} must be an array with at least two items")
    for index, keyframe in enumerate(value):
        keyframe_name = f"{name}[{index}]"
        if not isinstance(keyframe, Mapping):
            raise ConfigError(f"{keyframe_name} must be an object")
        validate_allowed_keys(
            keyframe,
            allowed=LOCATION_OFFSET_KEYFRAME_KEYS,
            name=keyframe_name,
        )
        validate_integer_field(keyframe, "frame", name=keyframe_name, minimum=0)
        if not any(key in keyframe for key in ("value", "value_mm", "location_offset_mm")):
            raise ConfigError(f"{keyframe_name}.value is required")
        for key in ("value", "value_mm", "location_offset_mm"):
            if key in keyframe:
                validate_vector_shape(keyframe[key], name=f"{keyframe_name}.{key}")


def validate_object_animation_config(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    validate_allowed_keys(value, allowed=OBJECT_ANIMATION_CONFIG_KEYS, name=name)
    object_id = value.get("object") or value.get("id")
    if not isinstance(object_id, str) or not object_id.strip():
        raise ConfigError(f"{name}.object is required")
    if "property" in value and value["property"] != "location":
        raise ConfigError(f"{name}.property only supports 'location'")
    for key in ("start_frame", "end_frame", "visible_from_frame"):
        validate_integer_field(value, key, name=name, minimum=0)
    if "start_frame" in value and "end_frame" in value and int(value["end_frame"]) <= int(value["start_frame"]):
        raise ConfigError(f"{name}.end_frame must be greater than {name}.start_frame")
    for key in ("from_location_offset_mm", "to_location_offset_mm", "from_offset_mm", "to_offset_mm"):
        if key in value:
            validate_vector_shape(value[key], name=f"{name}.{key}")
    for key in ("interpolation", "opacity_interpolation"):
        validate_enum_field(value, key, name=name, allowed=INTERPOLATION_NAMES)
    if "visibility_keyframes" in value:
        validate_visibility_keyframes(value["visibility_keyframes"], name=f"{name}.visibility_keyframes")
    if "opacity_keyframes" in value:
        validate_opacity_keyframes(value["opacity_keyframes"], name=f"{name}.opacity_keyframes")
    for key in ("location_offset_keyframes_mm", "keyframes"):
        if key in value:
            validate_location_offset_keyframes(value[key], name=f"{name}.{key}")


def validate_object_animation_items(value: object, *, name: str) -> None:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)) or not value:
        raise ConfigError(f"{name} must be a non-empty array")
    for index, item in enumerate(value):
        validate_object_animation_config(item, name=f"{name}[{index}]")


def validate_animation_clip_config(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    validate_allowed_keys(value, allowed=ANIMATION_CLIP_CONFIG_KEYS, name=name)
    if "object_animations" not in value and "objects" not in value:
        raise ConfigError(f"{name}.object_animations is required")
    validate_integer_field(value, "start_frame", name=name, minimum=0)
    validate_integer_field(value, "duration_frames", name=name, minimum=1)
    validate_enum_field(value, "interpolation", name=name, allowed=INTERPOLATION_NAMES)
    if "name" in value and not isinstance(value["name"], str):
        raise ConfigError(f"{name}.name must be a string")
    if "object_animations" in value:
        validate_object_animation_items(value["object_animations"], name=f"{name}.object_animations")
    if "objects" in value:
        validate_object_animation_items(value["objects"], name=f"{name}.objects")


def validate_animation_config_shape(value: object, *, name: str = "render.animation") -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    validate_allowed_keys(value, allowed=ANIMATION_CONFIG_KEYS, name=name)
    if "enabled" in value and not isinstance(value["enabled"], bool):
        raise ConfigError(f"{name}.enabled must be a boolean")
    for key, minimum in (
        ("frame_start", 0),
        ("frame_end", 1),
        ("duration_frames", 1),
        ("end_pause_frames", 0),
        ("fps", 1),
        ("gif_width_px", 0),
    ):
        validate_integer_field(value, key, name=name, minimum=minimum)
    frame_start = int(value.get("frame_start", 0))
    if "frame_end" in value and int(value["frame_end"]) <= frame_start:
        raise ConfigError(f"{name}.frame_end must be greater than {name}.frame_start")
    validate_enum_field(value, "output_format", name=name, allowed=OUTPUT_FORMATS)
    validate_enum_field(value, "interpolation", name=name, allowed=INTERPOLATION_NAMES)
    if "object_animations" in value:
        validate_object_animation_items(value["object_animations"], name=f"{name}.object_animations")
    if "objects" in value:
        validate_object_animation_items(value["objects"], name=f"{name}.objects")
    clips = value.get("clips")
    if clips is not None:
        if not isinstance(clips, Sequence) or isinstance(clips, (str, bytes)):
            raise ConfigError(f"{name}.clips must be an array")
        for index, clip in enumerate(clips):
            validate_animation_clip_config(clip, name=f"{name}.clips[{index}]")
    if value.get("enabled", True):
        has_top_level_items = "object_animations" in value or "objects" in value
        has_clips = isinstance(clips, Sequence) and not isinstance(clips, (str, bytes)) and bool(clips)
        if not has_top_level_items and not has_clips:
            raise ConfigError(f"{name} requires object_animations or clips")


def validate_render_config(value: Mapping[str, object]) -> None:
    validate_allowed_keys(value, allowed=RENDER_CONFIG_KEYS, name="render")
    validate_enum_field(value, "engine", name="render", allowed=RENDER_ENGINE_VALUES)
    validate_enum_field(value, "quality", name="render", allowed=RENDER_QUALITY_VALUES)
    validate_enum_field(value, "mesh_shading", name="render", allowed=MESH_SHADING_VALUES)
    validate_enum_field(value, "camera_look_at", name="render", allowed=RENDER_CAMERA_LOOK_AT_VALUES)
    validate_enum_field(value, "camera_view", name="render", allowed=RENDER_CAMERA_VIEW_VALUES)
    validate_enum_field(value, "camera_view_preset", name="render", allowed=RENDER_CAMERA_VIEW_PRESET_VALUES)
    validate_enum_field(value, "output_mode", name="render", allowed=RENDER_OUTPUT_MODE_VALUES)
    if "cache" in value and not isinstance(value["cache"], bool):
        raise ConfigError("render.cache must be a boolean")
    if "cache_dir" in value and (not isinstance(value["cache_dir"], str) or not str(value["cache_dir"]).strip()):
        raise ConfigError("render.cache_dir must be a non-empty string")
    validate_integer_field(value, "width", name="render", minimum=1)
    validate_integer_field(value, "height", name="render", minimum=1)
    validate_number_field(value, "fit_margin", name="render")
    validate_number_field(value, "camera_distance_scale", name="render", minimum=0.000001)
    validate_vector_shape(value.get("camera_location_offset_mm"), name="render.camera_location_offset_mm")
    validate_vector_shape(value.get("camera_target_offset_mm"), name="render.camera_target_offset_mm")
    validate_vector_shape(value.get("camera_rotation_deg"), name="render.camera_rotation_deg")
    validate_vector_shape(value.get("camera_rotation_offset_deg"), name="render.camera_rotation_offset_deg")
    validate_vector2_shape(value.get("camera_orbit_deg"), name="render.camera_orbit_deg")
    validate_number_expression_field(value, "camera_roll_deg", name="render")
    validate_number_expression_field(value, "camera_focal_length_mm", name="render")
    validate_number_expression_field(value, "camera_lens_mm", name="render")
    if "camera_focal_length_mm" in value and "camera_lens_mm" in value:
        raise ConfigError("render must not define both camera_focal_length_mm and camera_lens_mm")
    validate_lighting_config(value.get("lighting"))
    validate_outline_config(value.get("outline"))
    validate_ground_plane_config(value.get("ground_plane"))
    validate_cutaway_config(value.get("cutaway"))
    validate_xray_config(value.get("xray"))
    validate_material_overrides_config(value.get("material_overrides"))
    if "fit_camera" in value and not isinstance(value["fit_camera"], bool):
        raise ConfigError("render.fit_camera must be a boolean")
    if "animation" in value:
        validate_animation_config_shape(value["animation"])


def validate_integer_style_field(
    value: Mapping[str, object],
    key: str,
    *,
    name: str,
    minimum: int | None = None,
    maximum: int | None = None,
) -> None:
    if key not in value:
        return
    field_value = value[key]
    if not is_integer(field_value):
        raise ConfigError(f"{name}.{key} must be an integer")
    if minimum is not None and int(field_value) < minimum:
        raise ConfigError(f"{name}.{key} must be at least {minimum}")
    if maximum is not None and int(field_value) > maximum:
        raise ConfigError(f"{name}.{key} must be at most {maximum}")


def validate_style_override_fields(value: Mapping[str, object], *, name: str) -> None:
    for key, (minimum, maximum) in STYLE_INTEGER_FIELDS.items():
        validate_integer_style_field(value, key, name=name, minimum=minimum, maximum=maximum)
    for key, (minimum, maximum) in STYLE_NUMBER_FIELDS.items():
        validate_number_field(value, key, name=name, minimum=minimum, maximum=maximum)
    for key in STYLE_BOOLEAN_FIELDS:
        if key in value and not isinstance(value[key], bool):
            raise ConfigError(f"{name}.{key} must be a boolean")
    for key in STYLE_STRING_FIELDS:
        if key in value and not isinstance(value[key], str):
            raise ConfigError(f"{name}.{key} must be a string")


def validate_string_mapping(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    if not all(isinstance(key, str) and isinstance(item, str) for key, item in value.items()):
        raise ConfigError(f"{name} must map strings to strings")


def validate_type_styles(value: object, *, name: str) -> None:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    allowed_keys = {"line_color", "line_colors", "text_color", "text_shade", "font"}
    for type_name, type_style in value.items():
        item_name = f"{name}.{type_name}"
        if not isinstance(type_name, str) or not type_name.strip():
            raise ConfigError(f"{name} keys must be non-empty strings")
        if not isinstance(type_style, Mapping):
            raise ConfigError(f"{item_name} must be an object")
        validate_allowed_keys(type_style, allowed=allowed_keys, name=item_name)
        for key in ("line_color", "text_color"):
            if key in type_style and not isinstance(type_style[key], str):
                raise ConfigError(f"{item_name}.{key} must be a string")
        line_colors = type_style.get("line_colors")
        if line_colors is not None:
            if (
                not isinstance(line_colors, Sequence)
                or isinstance(line_colors, (str, bytes))
                or not all(isinstance(color, str) for color in line_colors)
            ):
                raise ConfigError(f"{item_name}.line_colors must be an array of strings")
        validate_number_field(type_style, "text_shade", name=item_name, minimum=0.0, maximum=1.0)
        if "font" in type_style:
            font = type_style["font"]
            if not isinstance(font, str) or font not in {"sans", "mono", "serif", "angle"}:
                raise ConfigError(f"{item_name}.font must be one of angle, mono, sans, serif")


def validate_annotation_style(value: object, *, name: str = "annotations.style") -> None:
    if value is None:
        return
    if isinstance(value, str):
        if value not in STYLE_PRESETS:
            raise ConfigError(f"Unknown annotation style preset {value!r}")
        return
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object or preset name")
    if CONSTANT_REF_KEY in value:
        return
    global_style_keys = STYLE_OVERRIDE_KEYS - {"show_label", "show_angle_label", "show_radius_label"}
    validate_allowed_keys(value, allowed=global_style_keys | {"preset", "colors", "type_styles"}, name=name)
    preset = str(value.get("preset", "makerworld_technical_light"))
    if preset not in STYLE_PRESETS:
        raise ConfigError(f"Unknown annotation style preset {preset!r}")
    validate_style_override_fields(value, name=name)
    if "colors" in value:
        validate_string_mapping(value["colors"], name=f"{name}.colors")
    if "type_styles" in value:
        validate_type_styles(value["type_styles"], name=f"{name}.type_styles")


def validate_config_shape(config: Mapping[str, object]) -> None:
    if "model" in config:
        raise ConfigError("top-level model is not supported; put model config in scene.objects[*].model")
    resolve_scene(config.get("scene", {}))
    raw_variants = config.get("variants", [])
    if isinstance(raw_variants, Sequence) and not isinstance(raw_variants, (str, bytes)):
        for index, variant in enumerate(raw_variants):
            if isinstance(variant, Mapping) and "model" in variant:
                raise ConfigError(
                    f"variants[{index}].model is not supported; put model config in variants[{index}].scene.objects[*].model"
                )
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
    validate_annotation_style(annotations.get("style"))
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
    for key in ("line_offset_px", "label_offset_px"):
        validate_number_field(value, key, name=name)
    validate_style_override_fields(value, name=name)


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
        if key in value and not is_number(value[key]):
            raise ConfigError(f"{name}.{key} must be numeric")
    validate_style_override_fields(value, name=name)


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
        if key in value and not is_number(value[key]):
            raise ConfigError(f"{name}.{key} must be numeric")
    if "show_value" in value and not isinstance(value["show_value"], bool):
        raise ConfigError(f"{name}.show_value must be a boolean")
    for key in ("font_size_px", "label_font_size_px"):
        if key in value and not is_integer(value[key]):
            raise ConfigError(f"{name}.{key} must be an integer")
        if key in value and int(value[key]) < 1:
            raise ConfigError(f"{name}.{key} must be at least 1")

