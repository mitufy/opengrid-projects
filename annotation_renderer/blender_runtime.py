from __future__ import annotations

import json
import os
from math import degrees, radians
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Euler, Matrix, Vector


def load_runtime_config() -> dict:
    script_path = Path(__file__)
    configured = os.environ.get("OPENGRID_BLENDER_CONFIG")
    candidates = []
    if configured:
        configured_path = Path(configured)
        candidates.append(configured_path if configured_path.is_absolute() else script_path.with_name(configured))
    candidates.extend([
        script_path.with_name("cfg.json"),
        script_path.with_name("blender_scene_config.json"),
    ])
    for candidate in candidates:
        if candidate.exists():
            return json.loads(candidate.read_text(encoding="utf-8"))
    raise FileNotFoundError(f"No Blender scene config found next to {script_path}")


config = load_runtime_config()


def render_default(key: str):
    defaults = config.get("render_defaults", {})
    if isinstance(defaults, dict) and key in defaults:
        return defaults[key]
    raise KeyError(f"Blender config missing render setting {key!r} and render_defaults.{key}")


def render_setting(config_key: str, default_key: str | None = None):
    if config_key in config:
        return config[config_key]
    return render_default(default_key or config_key)


CAMERA_VIEW_DIRECTIONS = {
    "front": Vector((0.0, -1.0, 0.0)),
    "back": Vector((0.0, 1.0, 0.0)),
    "left": Vector((-1.0, 0.0, 0.0)),
    "right": Vector((1.0, 0.0, 0.0)),
    "top": Vector((0.0, 0.0, 1.0)),
    "bottom": Vector((0.0, 0.0, -1.0)),
}


def try_set(target, name, value):
    if target is not None and hasattr(target, name):
        try:
            setattr(target, name, value)
        except Exception:
            pass


def import_stl(path):
    bpy.ops.object.select_all(action="DESELECT")
    try:
        bpy.ops.wm.stl_import(filepath=path)
    except Exception:
        bpy.ops.import_mesh.stl(filepath=path)
    imported = [obj for obj in bpy.context.selected_objects if obj.type == "MESH"]
    if not imported:
        raise RuntimeError(f"No mesh imported from {path}")
    return imported[0]


def configured_matrix(transform):
    if not transform:
        return None
    location = Vector(transform.get("location", (0.0, 0.0, 0.0)))
    rotation_deg = transform.get("rotation_deg", (0.0, 0.0, 0.0))
    rotation = Euler(tuple(radians(float(value)) for value in rotation_deg), "XYZ")
    scale = transform.get("scale", (1.0, 1.0, 1.0))
    scale_matrix = Matrix.Diagonal((float(scale[0]), float(scale[1]), float(scale[2]), 1.0))
    return Matrix.Translation(location) @ rotation.to_matrix().to_4x4() @ scale_matrix


def material_list(source):
    if source is None:
        return []
    return [slot.material for slot in source.material_slots if slot.material is not None]


def parse_material_color(value, alpha=1.0):
    if value is None:
        return None
    if isinstance(value, str):
        color = value.strip()
        if color.startswith("#"):
            color = color[1:]
        if len(color) == 3:
            color = "".join(channel * 2 for channel in color)
        if len(color) == 6:
            return tuple(int(color[index:index + 2], 16) / 255.0 for index in (0, 2, 4)) + (float(alpha),)
        if len(color) == 8:
            return tuple(int(color[index:index + 2], 16) / 255.0 for index in (0, 2, 4, 6))
        raise RuntimeError(f"Unsupported material color {value!r}; use #RGB, #RRGGBB, or #RRGGBBAA")
    if isinstance(value, (list, tuple)) and len(value) in {3, 4}:
        channels = [float(channel) for channel in value]
        if len(channels) == 3:
            channels.append(float(alpha))
        return tuple(channels)
    raise RuntimeError(f"Unsupported material color {value!r}")


def scene_control_settings(value, *, default_enabled=False):
    if value is None:
        return {"enabled": default_enabled}
    if isinstance(value, bool):
        return {"enabled": value}
    if isinstance(value, str):
        return {"enabled": True, "preset": value}
    if isinstance(value, dict):
        settings = dict(value)
        settings.setdefault("enabled", True)
        return settings
    raise RuntimeError(f"Unsupported scene control config {value!r}")


def configured_material(name, material_config, source_materials):
    if material_config is None:
        return None
    if isinstance(material_config, str):
        material_config = {"color": material_config}
    source_material = source_materials[0] if source_materials else None
    material = source_material.copy() if source_material is not None else bpy.data.materials.new(f"{name}_material")
    material.name = f"{name}_configured_material"
    alpha = float(material_config.get("alpha", 1.0))
    color = parse_material_color(material_config.get("color"), alpha=alpha)
    material.diffuse_color = color or material.diffuse_color
    material.use_nodes = True
    principled = next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if principled is not None:
        if color is not None and "Base Color" in principled.inputs:
            principled.inputs["Base Color"].default_value = color
        if "Alpha" in principled.inputs:
            principled.inputs["Alpha"].default_value = material.diffuse_color[3]
        if "Roughness" in principled.inputs and "roughness" in material_config:
            principled.inputs["Roughness"].default_value = float(material_config["roughness"])
        if "Metallic" in principled.inputs and "metallic" in material_config:
            principled.inputs["Metallic"].default_value = float(material_config["metallic"])
    if material.diffuse_color[3] < 1.0:
        try:
            material.blend_method = "BLEND"
            material.use_screen_refraction = True
        except Exception:
            pass
    return material


def replacement_matrix(object_config, original_matrix):
    if object_config.get("inherit_target_transform", True):
        if original_matrix is None:
            raise RuntimeError(
                f"Object {object_config['id']!r} inherits a target transform, but target object "
                f"{object_config.get('target_object')!r} was not found"
            )
        return original_matrix
    matrix = configured_matrix(object_config.get("object_transform"))
    if matrix is None:
        raise RuntimeError(f"Object {object_config['id']!r} requires object_transform when inherit_target_transform is false")
    return matrix


def replace_or_import_object(object_config):
    object_id = object_config["id"]
    target_name = object_config.get("target_object") or object_id
    original = bpy.data.objects.get(target_name)
    original_matrix = original.matrix_world.copy() if original is not None else None
    original_collections = list(original.users_collection) if original is not None else []
    materials = material_list(original)
    material_source_name = object_config.get("material_source_object")
    if not materials and material_source_name:
        materials = material_list(bpy.data.objects.get(material_source_name))

    if object_config.get("replace_target_object", True) and original is not None:
        bpy.data.objects.remove(original, do_unlink=True)
    elif original is not None:
        target_name = f"{target_name}_generated"

    replacement = import_stl(object_config["stl_path"])
    replacement.name = target_name
    replacement.data.name = f"{target_name}_generated_mesh"
    replacement.matrix_world = replacement_matrix(object_config, original_matrix)

    for collection in original_collections:
        if replacement.name not in {obj.name for obj in collection.objects}:
            try:
                collection.objects.link(replacement)
            except RuntimeError:
                pass
    for collection in list(replacement.users_collection):
        if original_collections and collection not in original_collections:
            try:
                collection.objects.unlink(replacement)
            except RuntimeError:
                pass

    custom_material = configured_material(target_name, object_config.get("material"), materials)
    if custom_material is not None:
        replacement.data.materials.clear()
        replacement.data.materials.append(custom_material)
    elif materials:
        replacement.data.materials.clear()
        for material in materials:
            replacement.data.materials.append(material)
    else:
        default_material = configured_material(target_name, object_config.get("default_material_color"), [])
        if default_material is not None:
            replacement.data.materials.append(default_material)
    return replacement


def configure_shading(obj, shading):
    if shading == "flat":
        for polygon in obj.data.polygons:
            polygon.use_smooth = False
        return
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    except Exception:
        pass
    obj.select_set(False)
    if shading in {"weighted_normals", "auto_smooth"}:
        try:
            modifier = obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")
            modifier.keep_sharp = True
        except Exception:
            pass


def world_bbox(obj):
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    mins = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maxs = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return mins, maxs, points


def bbox_from_points(points):
    mins = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maxs = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return mins, maxs, points


def combined_world_points(objects):
    all_points = []
    for obj in objects:
        all_points.extend(world_bbox(obj)[2])
    return all_points


def combined_world_bbox(objects):
    return bbox_from_points(combined_world_points(objects))


def animation_fit_points(objects, objects_by_id, animation_config):
    points = combined_world_points(objects)
    if not animation_config or not animation_config.get("enabled"):
        return points
    for item in animation_config.get("object_animations", []):
        if item.get("property", "location") != "location":
            continue
        obj = objects_by_id.get(item.get("object"))
        if obj is None:
            continue
        base_corners = world_bbox(obj)[2]
        keyframes = item.get("location_offset_keyframes") or [
            {"location_offset": item.get("from_location_offset", (0.0, 0.0, 0.0))},
            {"location_offset": item.get("to_location_offset", (0.0, 0.0, 0.0))},
        ]
        for keyframe in keyframes:
            offset = Vector(keyframe.get("location_offset", (0.0, 0.0, 0.0)))
            points.extend(corner + offset for corner in base_corners)
    return points


def fit_camera_to_objects(scene, camera, objects, fit_points=None):
    if not render_setting("fit_camera"):
        return None
    margin = float(render_setting("fit_margin"))
    mins, maxs, corners = bbox_from_points(fit_points) if fit_points is not None else combined_world_bbox(objects)
    target = (mins + maxs) / 2
    if camera.data.type == "ORTHO":
        inv_camera = camera.matrix_world.inverted()
        camera_points = [inv_camera @ corner for corner in corners]
        min_x = min(point.x for point in camera_points)
        max_x = max(point.x for point in camera_points)
        min_y = min(point.y for point in camera_points)
        max_y = max(point.y for point in camera_points)
        aspect = max(float(scene.render.resolution_x) / max(float(scene.render.resolution_y), 1.0), 1e-6)
        camera.data.ortho_scale = max(max_y - min_y, (max_x - min_x) / aspect) * (1.0 + margin * 2.0)
        return {"target": [float(v) for v in target], "ortho_scale": float(camera.data.ortho_scale)}

    forward = -(camera.matrix_world.to_quaternion() @ Vector((0.0, 0.0, 1.0))).normalized()
    distance = max((target - camera.location).dot(forward), 0.02)
    camera.location = target - forward * distance
    bpy.context.view_layer.update()
    for _ in range(100):
        projections = [world_to_camera_view(scene, camera, corner) for corner in corners]
        min_x = min(float(p.x) for p in projections)
        max_x = max(float(p.x) for p in projections)
        min_y = min(float(p.y) for p in projections)
        max_y = max(float(p.y) for p in projections)
        if min_x >= margin and max_x <= 1.0 - margin and min_y >= margin and max_y <= 1.0 - margin:
            break
        distance *= 1.06
        camera.location = target - forward * distance
        bpy.context.view_layer.update()
    return {"target": [float(v) for v in target], "distance": float(distance)}


def apply_camera_location_offset(camera):
    offset = config.get("camera_location_offset", (0.0, 0.0, 0.0))
    if not offset:
        return None
    offset_vector = Vector((float(offset[0]), float(offset[1]), float(offset[2])))
    if offset_vector.length <= 1e-9:
        return None
    camera.location += offset_vector
    bpy.context.view_layer.update()
    return [float(value) for value in offset_vector]


def apply_camera_rotation(camera):
    rotation_deg = config.get("camera_rotation")
    if rotation_deg is None:
        return None
    camera.rotation_euler = Euler(tuple(radians(float(value)) for value in rotation_deg), "XYZ")
    bpy.context.view_layer.update()
    return [float(value) for value in rotation_deg]


def apply_camera_rotation_offset(camera):
    rotation_offset_deg = config.get("camera_rotation_offset", (0.0, 0.0, 0.0))
    if not rotation_offset_deg:
        return None
    offset_values = [float(value) for value in rotation_offset_deg]
    if all(abs(value) <= 1e-9 for value in offset_values):
        return None
    before = [degrees(float(value)) for value in camera.rotation_euler]
    camera.rotation_euler = Euler(
        tuple(float(camera.rotation_euler[index]) + radians(offset_values[index]) for index in range(3)),
        camera.rotation_euler.order,
    )
    bpy.context.view_layer.update()
    return {
        "offset_deg": offset_values,
        "before_deg": before,
        "after_deg": [degrees(float(value)) for value in camera.rotation_euler],
        "applied": True,
    }


def apply_camera_lens(camera):
    lens = config.get("camera_lens")
    if lens is None:
        return None
    lens = float(lens)
    if lens <= 0.0:
        raise RuntimeError("camera_lens must be greater than 0")
    old_lens = float(getattr(camera.data, "lens", lens))
    if hasattr(camera.data, "lens"):
        camera.data.lens = lens
    bpy.context.view_layer.update()
    return {
        "lens_mm": lens,
        "old_lens_mm": old_lens,
        "applied": hasattr(camera.data, "lens"),
    }


def camera_object_center(objects, fit_points=None):
    mins, maxs, _corners = bbox_from_points(fit_points) if fit_points is not None else combined_world_bbox(objects)
    return (mins + maxs) / 2


def vector_metadata(vector):
    return [float(value) for value in vector]


def aim_camera_at(camera, target, mode):
    direction = target - camera.location
    if direction.length <= 1e-9:
        return {
            "mode": mode,
            "target": vector_metadata(target),
            "applied": False,
        }
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    return {
        "mode": mode,
        "target": vector_metadata(target),
        "applied": True,
    }


def apply_camera_look_at(camera, objects, fit_points=None):
    mode = config.get("camera_look_at", "none")
    if not mode or mode == "none":
        return None
    if mode != "object_center":
        raise RuntimeError(f"Unsupported camera_look_at mode {mode!r}")
    target = camera_object_center(objects, fit_points=fit_points)
    return aim_camera_at(camera, target, mode)


def apply_camera_target_offset(camera, objects, fit_points=None):
    offset = config.get("camera_target_offset", (0.0, 0.0, 0.0))
    if not offset:
        return None
    offset_vector = Vector((float(offset[0]), float(offset[1]), float(offset[2])))
    if offset_vector.length <= 1e-9:
        return None
    center = camera_object_center(objects, fit_points=fit_points)
    target = center + offset_vector
    look_at = aim_camera_at(camera, target, "camera_target_offset")
    return {
        "offset": vector_metadata(offset_vector),
        "center": vector_metadata(center),
        "target": vector_metadata(target),
        "look_at": look_at,
        "applied": bool(look_at.get("applied")),
    }


def apply_camera_roll(camera):
    roll_deg = float(config.get("camera_roll", 0.0))
    if abs(roll_deg) <= 1e-9:
        return None
    camera.rotation_euler.rotate_axis("Z", radians(roll_deg))
    bpy.context.view_layer.update()
    return {
        "roll_deg": roll_deg,
        "applied": True,
    }


def apply_camera_orbit(camera, objects, fit_points=None):
    orbit_deg = config.get("camera_orbit", (0.0, 0.0))
    if not orbit_deg:
        return None
    yaw_deg = float(orbit_deg[0])
    pitch_deg = float(orbit_deg[1])
    if abs(yaw_deg) <= 1e-9 and abs(pitch_deg) <= 1e-9:
        return None
    target = camera_object_center(objects, fit_points=fit_points)
    vector = camera.location - target
    if vector.length <= 1e-9:
        return {
            "orbit_deg": [yaw_deg, pitch_deg],
            "target": vector_metadata(target),
            "applied": False,
        }

    if abs(yaw_deg) > 1e-9:
        vector = Matrix.Rotation(radians(yaw_deg), 4, Vector((0.0, 0.0, 1.0))) @ vector
    if abs(pitch_deg) > 1e-9:
        pitch_axis = vector.cross(Vector((0.0, 0.0, 1.0)))
        if pitch_axis.length <= 1e-9:
            pitch_axis = camera.matrix_world.to_quaternion() @ Vector((1.0, 0.0, 0.0))
        pitch_axis.normalize()
        vector = Matrix.Rotation(radians(pitch_deg), 4, pitch_axis) @ vector

    camera.location = target + vector
    look_at = aim_camera_at(camera, target, "camera_orbit")
    bpy.context.view_layer.update()
    return {
        "orbit_deg": [yaw_deg, pitch_deg],
        "target": vector_metadata(target),
        "location": vector_metadata(camera.location),
        "look_at": look_at,
        "applied": True,
    }


def apply_camera_distance_scale(camera, objects, fit_points=None):
    scale = float(config.get("camera_distance_scale", 1.0))
    if abs(scale - 1.0) <= 1e-9:
        return None
    if scale <= 0.0:
        raise RuntimeError("camera_distance_scale must be greater than 0")
    target = camera_object_center(objects, fit_points=fit_points)
    if camera.data.type == "ORTHO":
        old_scale = float(camera.data.ortho_scale)
        camera.data.ortho_scale = old_scale * scale
        bpy.context.view_layer.update()
        return {
            "scale": scale,
            "target": vector_metadata(target),
            "ortho_scale_before": old_scale,
            "ortho_scale_after": float(camera.data.ortho_scale),
            "applied": True,
        }

    vector = camera.location - target
    if vector.length <= 1e-9:
        return {
            "scale": scale,
            "target": vector_metadata(target),
            "applied": False,
        }
    old_distance = float(vector.length)
    camera.location = target + vector * scale
    look_at = aim_camera_at(camera, target, "camera_distance_scale")
    bpy.context.view_layer.update()
    return {
        "scale": scale,
        "target": vector_metadata(target),
        "distance_before": old_distance,
        "distance_after": float((camera.location - target).length),
        "location": vector_metadata(camera.location),
        "look_at": look_at,
        "applied": True,
    }


def object_local_view_direction(obj, mode):
    local_direction = CAMERA_VIEW_DIRECTIONS[mode]
    world_direction = obj.matrix_world.to_quaternion() @ local_direction
    if world_direction.length <= 1e-9:
        world_direction = local_direction.copy()
    return world_direction.normalized()


def apply_camera_view(camera, objects, fit_points=None):
    mode = config.get("camera_view", "none")
    if not mode or mode == "none":
        return None
    if mode not in CAMERA_VIEW_DIRECTIONS:
        raise RuntimeError(f"Unsupported camera_view mode {mode!r}")
    if not objects:
        return None

    mins, maxs, _corners = bbox_from_points(fit_points) if fit_points is not None else combined_world_bbox(objects)
    target = (mins + maxs) / 2
    source_object = objects[0]
    direction = object_local_view_direction(source_object, mode)
    distance = max((maxs - mins).length * 2.0, 0.02)
    camera.location = target + direction * distance
    look_at = aim_camera_at(camera, target, mode)
    bpy.context.view_layer.update()
    return {
        "mode": mode,
        "object": source_object.name,
        "target": vector_metadata(target),
        "direction": vector_metadata(direction),
        "distance": float(distance),
        "look_at": look_at,
    }


def configure_render(scene):
    engine = render_setting("render_engine", "engine")
    if engine == "cycles":
        try:
            scene.render.engine = "CYCLES"
        except Exception:
            pass
    else:
        try:
            scene.render.engine = "BLENDER_EEVEE_NEXT"
        except Exception:
            try:
                scene.render.engine = "BLENDER_EEVEE"
            except Exception:
                scene.render.engine = "CYCLES"
    scene.render.resolution_x = int(render_setting("width"))
    scene.render.resolution_y = int(render_setting("height"))
    scene.render.resolution_percentage = 100
    quality = render_setting("quality")
    sample_count = 32 if quality == "draft" else 192 if quality == "high" else 96
    try_set(getattr(scene, "cycles", None), "samples", sample_count)
    try_set(getattr(scene, "cycles", None), "use_denoising", True)
    try_set(getattr(scene, "eevee", None), "taa_render_samples", sample_count)
    scene.render.filepath = config["render_path"]
    scene.render.image_settings.file_format = "PNG"


def set_world_light(scene, color, strength):
    if scene.world is None:
        scene.world = bpy.data.worlds.new("annotation_world")
    scene.world.color = color[:3]
    try:
        scene.world.use_nodes = True
        background = next((node for node in scene.world.node_tree.nodes if node.type == "BACKGROUND"), None)
        if background is not None:
            background.inputs["Color"].default_value = color
            background.inputs["Strength"].default_value = float(strength)
    except Exception:
        pass


def remove_scene_lights():
    removed = []
    for obj in list(bpy.data.objects):
        if obj.type == "LIGHT":
            removed.append(obj.name)
            bpy.data.objects.remove(obj, do_unlink=True)
    return removed


def aim_object_at(obj, target):
    direction = target - obj.location
    if direction.length <= 1e-9:
        return False
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    return True


def add_area_light(name, *, location, target, energy, size, color):
    data = bpy.data.lights.new(name, type="AREA")
    data.energy = float(energy)
    data.size = float(size)
    data.color = color[:3]
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    aim_object_at(obj, target)
    return obj


SCENE_LIGHT_POWER_KEYS = {
    "toplight_power": "TopLight",
    "frontlight_power": "FrontLight",
}


def set_scene_light_power(light_name, energy):
    light_energy = float(energy)
    light_objects = []
    data_blocks = []

    obj = bpy.data.objects.get(light_name)
    if obj is not None and obj.type == "LIGHT" and getattr(obj, "data", None) is not None:
        light_objects.append(obj.name)
        data_blocks.append(obj.data)

    data = bpy.data.lights.get(light_name)
    if data is not None and data not in data_blocks:
        data_blocks.append(data)

    if not data_blocks:
        return None

    for data in data_blocks:
        data.energy = light_energy
    return {
        "energy": light_energy,
        "objects": light_objects,
        "data": [data.name for data in data_blocks],
    }


def apply_scene_light_power_overrides(settings):
    applied = {}
    missing = []
    for key, light_name in SCENE_LIGHT_POWER_KEYS.items():
        if key not in settings:
            continue
        result = set_scene_light_power(light_name, settings[key])
        if result is None:
            missing.append(light_name)
        else:
            applied[light_name] = result

    summary = {}
    if applied:
        summary["light_powers"] = applied
    if missing:
        summary["missing_lights"] = missing
    return summary


def camera_basis(camera):
    rotation = camera.matrix_world.to_quaternion()
    view = (camera.location - (camera.location + rotation @ Vector((0.0, 0.0, -1.0)))).normalized()
    right = (rotation @ Vector((1.0, 0.0, 0.0))).normalized()
    up = (rotation @ Vector((0.0, 1.0, 0.0))).normalized()
    return view, right, up


def configure_lighting(scene, camera, objects):
    value = config.get("lighting")
    if value is None:
        return None
    settings = scene_control_settings(value)
    if not settings.get("enabled", True):
        return {"enabled": False}
    has_scene_light_overrides = any(key in settings for key in SCENE_LIGHT_POWER_KEYS)
    preset = str(settings.get("preset") or ("scene" if has_scene_light_overrides else "technical"))
    if preset == "scene":
        summary = apply_scene_light_power_overrides(settings)
        return {
            "preset": "scene",
            "applied": bool(summary.get("light_powers")),
            **summary,
        }

    color = parse_material_color(settings.get("color", "#ffffff"), alpha=1.0)
    strength_scale = float(settings.get("strength", 1.0))
    ambient_strength = float(settings.get("ambient_strength", 0.25 if preset != "flat" else 0.9))
    set_world_light(scene, color, ambient_strength)
    removed = remove_scene_lights()

    mins, maxs, _corners = combined_world_bbox(objects)
    target = (mins + maxs) / 2
    diag = max(float((maxs - mins).length), 0.25)
    view, right, up = camera_basis(camera)
    light_specs = []

    if preset == "flat":
        light_specs = []
    elif preset == "front_lit":
        light_specs = [
            ("front_key", target + view * diag * 1.4 + up * diag * 0.25, 520.0, diag * 1.5),
        ]
    elif preset == "softbox":
        light_specs = [
            ("softbox", target + view * diag * 1.2 + up * diag * 0.9 + right * diag * 0.15, 650.0, diag * 2.3),
        ]
    elif preset == "dramatic":
        light_specs = [
            ("dramatic_key", target + view * diag * 1.1 + right * diag * 0.85 + up * diag * 0.85, 850.0, diag * 0.85),
            ("dramatic_rim", target - view * diag * 0.9 - right * diag * 0.55 + up * diag * 0.45, 180.0, diag * 0.75),
        ]
    else:
        light_specs = [
            ("technical_key", target + view * diag * 1.25 + right * diag * 0.55 + up * diag * 0.85, 520.0, diag * 1.2),
            ("technical_fill", target + view * diag * 1.05 - right * diag * 0.85 + up * diag * 0.35, 160.0, diag * 1.8),
            ("technical_rim", target - view * diag * 0.9 + up * diag * 0.7, 95.0, diag * 1.4),
        ]

    added = [
        add_area_light(
            f"annotation_{name}",
            location=location,
            target=target,
            energy=energy * strength_scale,
            size=size,
            color=color,
        ).name
        for name, location, energy, size in light_specs
    ]
    bpy.context.view_layer.update()
    return {
        "preset": preset,
        "removed": removed,
        "added": added,
        "ambient_strength": ambient_strength,
        "strength": strength_scale,
        "applied": True,
    }


def configure_outline(scene):
    value = config.get("outline")
    if value is None:
        return None
    settings = scene_control_settings(value)
    if not settings.get("enabled", True):
        try_set(scene.render, "use_freestyle", False)
        return {"enabled": False}

    line_color = parse_material_color(settings.get("line_color", "#111827"), alpha=1.0)
    line_width = float(settings.get("line_width_px", 1.5))
    try_set(scene.render, "use_freestyle", True)
    view_layer = bpy.context.view_layer
    try_set(view_layer, "use_freestyle", True)
    try:
        freestyle_settings = view_layer.freestyle_settings
        if len(freestyle_settings.linesets) == 0:
            bpy.ops.scene.freestyle_lineset_add()
        line_set = freestyle_settings.linesets[0]
        line_style = line_set.linestyle
        line_style.color = line_color[:3]
        line_style.thickness = line_width
    except Exception:
        pass
    return {
        "enabled": True,
        "line_color": list(line_color),
        "line_width_px": line_width,
        "applied": True,
    }


def configure_ground_plane(objects):
    value = config.get("ground_plane")
    if value is None:
        return None
    settings = scene_control_settings(value)
    if not settings.get("enabled", True):
        return {"enabled": False}

    mins, maxs, _corners = combined_world_bbox(objects)
    center = (mins + maxs) / 2
    dims = maxs - mins
    size = max(float(dims.x), float(dims.y), 0.08) * float(settings.get("size_scale", 2.5))
    offset = float(settings.get("offset_mm", 0.0)) / 1000.0
    z = float(mins.z) + offset
    bpy.ops.mesh.primitive_plane_add(size=size, location=(float(center.x), float(center.y), z))
    plane = bpy.context.object
    plane.name = "annotation_ground_plane"
    material = configured_material(
        plane.name,
        {
            "color": settings.get("color", "#f8fafc"),
            "alpha": float(settings.get("alpha", 1.0)),
            "roughness": float(settings.get("roughness", 0.7)),
        },
        [],
    )
    plane.data.materials.append(material)
    if settings.get("shadow_only", False):
        try_set(plane, "is_shadow_catcher", True)
    bpy.context.view_layer.update()
    return {
        "enabled": True,
        "name": plane.name,
        "location": vector_metadata(plane.location),
        "size": size,
        "shadow_only": bool(settings.get("shadow_only", False)),
    }


def selected_render_objects(objects_by_id, settings, *, name):
    object_ids = settings.get("objects")
    if object_ids is None:
        return list(objects_by_id.items())
    selected = []
    for object_id in object_ids:
        if object_id not in objects_by_id:
            raise RuntimeError(f"{name} references unknown object {object_id!r}")
        selected.append((object_id, objects_by_id[object_id]))
    return selected


def cutaway_position(settings, *, bounds_min, bounds_max, center_values, axis_index):
    if "position_mm" in settings:
        return float(settings["position_mm"]) / 1000.0, "position_mm"
    offset = float(settings.get("offset_mm", 0.0)) / 1000.0
    if "position_fraction" in settings:
        fraction = float(settings["position_fraction"])
        if fraction < 0.0 or fraction > 1.0:
            raise RuntimeError("cutaway.position_fraction must be between 0 and 1")
        return bounds_min[axis_index] + (bounds_max[axis_index] - bounds_min[axis_index]) * fraction + offset, "position_fraction"
    return center_values[axis_index] + offset, "center_offset"


def add_cutaway_section_plane(settings, *, axis_name, axis_index, keep, position, bounds_min, bounds_max, center_values):
    section_value = settings.get("section_plane")
    if section_value is None:
        return None
    section = scene_control_settings(section_value)
    if not section.get("enabled", True):
        return {"enabled": False}

    padding = float(section.get("padding_mm", 1.0)) / 1000.0
    keep_sign = 1.0 if keep == "positive" else -1.0
    plane_offset = float(section.get("offset_mm", 0.15)) / 1000.0 * keep_sign
    other_axes = [index for index in range(3) if index != axis_index]
    low_a = bounds_min[other_axes[0]] - padding
    high_a = bounds_max[other_axes[0]] + padding
    low_b = bounds_min[other_axes[1]] - padding
    high_b = bounds_max[other_axes[1]] + padding

    vertices = []
    for a_value, b_value in ((low_a, low_b), (high_a, low_b), (high_a, high_b), (low_a, high_b)):
        coords = list(center_values)
        coords[axis_index] = position + plane_offset
        coords[other_axes[0]] = a_value
        coords[other_axes[1]] = b_value
        vertices.append(tuple(coords))

    mesh = bpy.data.meshes.new("annotation_cutaway_section_plane_mesh")
    mesh.from_pydata(vertices, [], [(0, 1, 2, 3)])
    mesh.update()
    plane = bpy.data.objects.new("annotation_cutaway_section_plane", mesh)
    bpy.context.collection.objects.link(plane)
    material = configured_material(
        plane.name,
        {
            "color": section.get("color", "#f97316"),
            "alpha": float(section.get("alpha", 0.32)),
            "roughness": 0.85,
        },
        [],
    )
    try_set(material, "show_transparent_back", True)
    plane.data.materials.append(material)
    bpy.context.view_layer.update()
    return {
        "enabled": True,
        "name": plane.name,
        "axis": axis_name,
        "location": position + plane_offset,
        "padding": padding,
        "offset": plane_offset,
        "color": section.get("color", "#f97316"),
        "alpha": float(section.get("alpha", 0.32)),
    }


def apply_cutaway(objects_by_id):
    value = config.get("cutaway")
    if value is None:
        return None
    settings = scene_control_settings(value)
    if not settings.get("enabled", True):
        return {"enabled": False}

    selected = selected_render_objects(objects_by_id, settings, name="cutaway")
    selected_objects = [obj for _object_id, obj in selected]
    mins, maxs, _corners = combined_world_bbox(selected_objects)
    center = (mins + maxs) / 2
    axis_name = str(settings.get("axis", "x")).lower()
    axis_index = {"x": 0, "y": 1, "z": 2}[axis_name]
    keep = str(settings.get("keep", "positive"))
    bounds_min = [float(mins.x), float(mins.y), float(mins.z)]
    bounds_max = [float(maxs.x), float(maxs.y), float(maxs.z)]
    center_values = [float(center.x), float(center.y), float(center.z)]
    position, position_mode = cutaway_position(
        settings,
        bounds_min=bounds_min,
        bounds_max=bounds_max,
        center_values=center_values,
        axis_index=axis_index,
    )
    diag = max(float((maxs - mins).length), 0.1)
    margin = diag * 2.0
    remove_min = bounds_min[axis_index] - margin
    remove_max = position
    if keep == "negative":
        remove_min = position
        remove_max = bounds_max[axis_index] + margin

    cutter_location = center_values
    cutter_dimensions = [
        max(bounds_max[index] - bounds_min[index] + margin * 2.0, 0.1)
        for index in range(3)
    ]
    cutter_location[axis_index] = (remove_min + remove_max) / 2.0
    cutter_dimensions[axis_index] = max(abs(remove_max - remove_min), 0.001)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=tuple(cutter_location))
    cutter = bpy.context.object
    cutter.name = "annotation_cutaway_cutter"
    cutter.dimensions = tuple(cutter_dimensions)
    bpy.context.view_layer.update()
    cutter.hide_viewport = True
    cutter.hide_render = True

    modified = []
    for object_id, obj in selected:
        modifier = obj.modifiers.new("annotation_cutaway", "BOOLEAN")
        modifier.operation = "DIFFERENCE"
        modifier.object = cutter
        try_set(modifier, "solver", "FAST")
        modified.append(object_id)
    section_plane = add_cutaway_section_plane(
        settings,
        axis_name=axis_name,
        axis_index=axis_index,
        keep=keep,
        position=position,
        bounds_min=bounds_min,
        bounds_max=bounds_max,
        center_values=center_values,
    )
    bpy.context.view_layer.update()
    return {
        "enabled": True,
        "axis": axis_name,
        "keep": keep,
        "position": position,
        "position_mode": position_mode,
        "position_fraction": settings.get("position_fraction"),
        "objects": modified,
        "cutter": cutter.name,
        "section_plane": section_plane,
    }


def keyframe_interpolation_settings(name):
    normalized = str(name or "ease_out").strip().lower().replace("-", "_")
    if normalized == "linear":
        return "LINEAR", None
    if normalized == "constant":
        return "CONSTANT", None
    if normalized in {"ease_in", "in"}:
        return "SINE", "EASE_IN"
    if normalized in {"ease_out", "out"}:
        return "SINE", "EASE_OUT"
    if normalized in {"ease_in_out", "in_out", "ease"}:
        return "SINE", "EASE_IN_OUT"
    return "BEZIER", None


def apply_keyframe_interpolation(action, data_path, interpolation_name):
    if action is None:
        return
    fcurves = getattr(action, "fcurves", None)
    if fcurves is None:
        return
    interpolation, easing = keyframe_interpolation_settings(interpolation_name)
    for fcurve in fcurves:
        if fcurve.data_path != data_path:
            continue
        for keyframe in fcurve.keyframe_points:
            try:
                keyframe.interpolation = interpolation
            except TypeError:
                keyframe.interpolation = "BEZIER"
            if easing is not None:
                try:
                    keyframe.easing = easing
                except TypeError:
                    pass


def apply_visibility_keyframes(obj, keyframes):
    if not keyframes:
        return
    for keyframe in keyframes:
        visible = bool(keyframe.get("visible", True))
        frame = int(keyframe["frame"])
        obj.hide_viewport = not visible
        obj.hide_render = not visible
        obj.keyframe_insert(data_path="hide_viewport", frame=frame)
        obj.keyframe_insert(data_path="hide_render", frame=frame)
    action = obj.animation_data.action if obj.animation_data is not None else None
    apply_keyframe_interpolation(action, "hide_viewport", "constant")
    apply_keyframe_interpolation(action, "hide_render", "constant")


def principled_bsdf(material):
    if material is None:
        return None
    material.use_nodes = True
    return next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)


def opacity_materials(obj):
    if len(obj.material_slots) == 0:
        material = bpy.data.materials.new(f"{obj.name}_opacity_material")
        obj.data.materials.append(material)

    materials = []
    for slot_index, slot in enumerate(obj.material_slots):
        material = slot.material
        if material is None:
            material = bpy.data.materials.new(f"{obj.name}_opacity_material_{slot_index}")
            slot.material = material
        elif material.users > 1:
            material = material.copy()
            material.name = f"{obj.name}_{material.name}_opacity"
            slot.material = material

        material.use_nodes = True
        try:
            material.blend_method = "BLEND"
            material.show_transparent_back = True
            material.use_screen_refraction = True
        except Exception:
            pass
        materials.append(material)
    return materials


def set_material_opacity(material, opacity):
    opacity = max(0.0, min(1.0, float(opacity)))
    color = list(material.diffuse_color)
    if len(color) < 4:
        color = color[:3] + [1.0]
    color[3] = opacity
    material.diffuse_color = color

    principled = principled_bsdf(material)
    if principled is not None:
        if "Alpha" in principled.inputs:
            principled.inputs["Alpha"].default_value = opacity
        if "Base Color" in principled.inputs:
            base_color = list(principled.inputs["Base Color"].default_value)
            if len(base_color) >= 4:
                base_color[3] = opacity
                principled.inputs["Base Color"].default_value = base_color


def apply_xray(objects_by_id):
    value = config.get("xray")
    if value is None:
        return None
    settings = scene_control_settings(value)
    if not settings.get("enabled", True):
        return {"enabled": False}

    alpha = float(settings.get("alpha", 0.28))
    color = parse_material_color(settings["color"], alpha=alpha) if "color" in settings else None
    selected = selected_render_objects(objects_by_id, settings, name="xray")
    changed = []
    for object_id, obj in selected:
        materials = opacity_materials(obj)
        for material in materials:
            if color is not None:
                material.diffuse_color = color
                principled = principled_bsdf(material)
                if principled is not None and "Base Color" in principled.inputs:
                    principled.inputs["Base Color"].default_value = color
            set_material_opacity(material, alpha)
            try_set(material, "blend_method", "BLEND")
            try_set(material, "show_transparent_back", True)
            try_set(material, "use_screen_refraction", True)
        changed.append(object_id)
    bpy.context.view_layer.update()
    return {
        "enabled": True,
        "objects": changed,
        "alpha": alpha,
        "color": list(color) if color is not None else None,
    }


def apply_opacity_keyframes(obj, keyframes, interpolation_name):
    if not keyframes:
        return
    materials = opacity_materials(obj)
    for keyframe in keyframes:
        frame = int(keyframe["frame"])
        opacity = float(keyframe["opacity"])
        for material in materials:
            set_material_opacity(material, opacity)
            material.keyframe_insert(data_path="diffuse_color", frame=frame, index=3)
            principled = principled_bsdf(material)
            if principled is not None:
                if "Alpha" in principled.inputs:
                    principled.inputs["Alpha"].keyframe_insert(data_path="default_value", frame=frame)
                if "Base Color" in principled.inputs:
                    principled.inputs["Base Color"].keyframe_insert(data_path="default_value", frame=frame, index=3)

    for material in materials:
        action = material.animation_data.action if material.animation_data is not None else None
        apply_keyframe_interpolation(action, "diffuse_color", interpolation_name)
        node_tree = material.node_tree
        if node_tree and node_tree.animation_data is not None:
            action = node_tree.animation_data.action
            apply_keyframe_interpolation(action, 'nodes["Principled BSDF"].inputs[4].default_value', interpolation_name)


def apply_animation(scene, objects_by_id):
    animation_config = config.get("animation")
    if not animation_config or not animation_config.get("enabled"):
        return False
    scene.frame_start = int(animation_config.get("frame_start", 1))
    scene.frame_end = int(animation_config.get("frame_end", 72))
    scene.render.fps = int(animation_config.get("fps", 24))
    base_locations = {
        object_id: obj.location.copy()
        for object_id, obj in objects_by_id.items()
    }
    for item in animation_config.get("object_animations", []):
        object_id = item["object"]
        obj = objects_by_id.get(object_id)
        if obj is None:
            raise RuntimeError(f"Animation references unknown object {object_id!r}")
        if item.get("property", "location") != "location":
            raise RuntimeError(f"Animation for {object_id!r} only supports location")

        apply_visibility_keyframes(obj, item.get("visibility_keyframes", []))
        apply_opacity_keyframes(obj, item.get("opacity_keyframes", []), item.get("opacity_interpolation", item.get("interpolation", "ease_out")))
        final_location = base_locations[object_id]
        keyframes = item.get("location_offset_keyframes") or [
            {"frame": int(item.get("start_frame", scene.frame_start)), "location_offset": item.get("from_location_offset", (0.0, 0.0, 0.0))},
            {"frame": int(item.get("end_frame", scene.frame_end)), "location_offset": item.get("to_location_offset", (0.0, 0.0, 0.0))},
        ]
        final_keyframe_offset = Vector((0.0, 0.0, 0.0))
        for keyframe in keyframes:
            final_keyframe_offset = Vector(keyframe.get("location_offset", (0.0, 0.0, 0.0)))
            obj.location = final_location + final_keyframe_offset
            obj.keyframe_insert(data_path="location", frame=int(keyframe["frame"]))
        apply_keyframe_interpolation(
            obj.animation_data.action if obj.animation_data is not None else None,
            "location",
            item.get("interpolation", "ease_out"),
        )
        obj.location = final_location + final_keyframe_offset
    scene.frame_set(scene.frame_end)
    bpy.context.view_layer.update()
    return True


def configure_animation_output(scene):
    scene.render.filepath = config["animation_frame_path"]
    scene.render.image_settings.file_format = "PNG"


scene = bpy.context.scene
camera = bpy.data.objects.get(config.get("camera_name")) if config.get("camera_name") else scene.camera
if camera is None:
    raise RuntimeError("No camera configured or active in Blender scene")
scene.camera = camera

object_configs = config.get("objects")
if not object_configs:
    object_configs = [
        {
            "id": "model",
            "stl_path": config["stl_path"],
            "target_object": config["target_object"],
            "replace_target_object": config.get("replace_target_object", True),
            "inherit_target_transform": config.get("inherit_target_transform", True),
            "object_transform": config.get("object_transform"),
            "mesh_shading": render_setting("mesh_shading"),
        }
    ]

objects_by_id = {}
rendered_objects = []
for object_config in object_configs:
    obj = replace_or_import_object(object_config)
    configure_shading(obj, object_config.get("mesh_shading", render_setting("mesh_shading")))
    objects_by_id[object_config["id"]] = obj
    rendered_objects.append(obj)
if not rendered_objects:
    raise RuntimeError("No render objects configured")

cutaway = apply_cutaway(objects_by_id)
xray = apply_xray(objects_by_id)
configure_render(scene)
bpy.context.view_layer.update()
fit_points = animation_fit_points(rendered_objects, objects_by_id, config.get("animation"))
camera_lens = apply_camera_lens(camera)
camera_rotation = apply_camera_rotation(camera)
camera_view = apply_camera_view(camera, rendered_objects, fit_points=fit_points)
camera_look_at = None if camera_view is not None else apply_camera_look_at(camera, rendered_objects, fit_points=fit_points)
camera_fit = fit_camera_to_objects(scene, camera, rendered_objects, fit_points=fit_points)
camera_location_offset = apply_camera_location_offset(camera)
if camera_location_offset is not None:
    should_refit = False
    if camera_view is not None:
        camera_view["look_at_after_offset"] = aim_camera_at(
            camera,
            camera_object_center(rendered_objects, fit_points=fit_points),
            str(camera_view["mode"]),
        )
        should_refit = True
    elif camera_look_at is not None:
        camera_look_at = apply_camera_look_at(camera, rendered_objects, fit_points=fit_points)
        should_refit = True
    if should_refit and config.get("fit_camera", False):
        camera_fit = fit_camera_to_objects(scene, camera, rendered_objects, fit_points=fit_points)
camera_orbit = apply_camera_orbit(camera, rendered_objects, fit_points=fit_points)
if camera_orbit is not None and camera_orbit.get("applied") and config.get("fit_camera", False):
    camera_fit = fit_camera_to_objects(scene, camera, rendered_objects, fit_points=fit_points)
camera_distance_scale = apply_camera_distance_scale(camera, rendered_objects, fit_points=fit_points)
camera_target_offset = apply_camera_target_offset(camera, rendered_objects, fit_points=fit_points)
camera_rotation_offset = apply_camera_rotation_offset(camera)
camera_roll = apply_camera_roll(camera)
ground_plane = configure_ground_plane(rendered_objects)
lighting = configure_lighting(scene, camera, rendered_objects)
outline = configure_outline(scene)
has_animation = apply_animation(scene, objects_by_id)
scene.render.filepath = config["render_path"]
scene.render.image_settings.file_format = "PNG"
bpy.ops.render.render(write_still=True)
if has_animation:
    configure_animation_output(scene)
    bpy.ops.render.render(animation=True)
    scene.frame_set(scene.frame_end)
    bpy.context.view_layer.update()

default_object_id = object_configs[0]["id"]
projection = {}
for key, point_config in config["projection_points"].items():
    if isinstance(point_config, dict):
        object_id = point_config.get("object", default_object_id)
        coords = point_config["coords"]
    else:
        object_id = default_object_id
        coords = point_config
    if object_id not in objects_by_id:
        raise RuntimeError(f"Projection point {key!r} references unknown object {object_id!r}")
    obj = objects_by_id[object_id]
    local = Vector(coords)
    world = obj.matrix_world @ local
    projected = world_to_camera_view(scene, camera, world)
    projection[key] = {
        "object": object_id,
        "local": [float(value) for value in local],
        "world": [float(value) for value in world],
        "normalized": [float(projected.x), float(projected.y), float(projected.z)],
        "px": [
            float(projected.x) * scene.render.resolution_x,
            (1.0 - float(projected.y)) * scene.render.resolution_y,
        ],
    }

export_blend_path = config.get("export_blend_path")
if export_blend_path:
    Path(export_blend_path).parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(export_blend_path))

Path(config["projection_path"]).write_text(
    json.dumps(
        {
            "file": bpy.data.filepath,
            "target_objects": [obj.name for obj in rendered_objects],
            "camera": {
                "name": camera.name,
                "type": camera.data.type,
                "location": [float(value) for value in camera.location],
                "matrix_world": [[float(value) for value in row] for row in camera.matrix_world],
                "lens": camera_lens,
                "configured_rotation": camera_rotation,
                "view": camera_view,
                "view_preset": config.get("camera_view_preset"),
                "fit": camera_fit,
                "location_offset": camera_location_offset,
                "orbit": camera_orbit,
                "distance_scale": camera_distance_scale,
                "target_offset": camera_target_offset,
                "rotation_offset": camera_rotation_offset,
                "roll": camera_roll,
                "look_at": camera_look_at,
            },
            "scene_controls": {
                "lighting": lighting,
                "outline": outline,
                "ground_plane": ground_plane,
                "cutaway": cutaway,
                "xray": xray,
            },
            "objects": {
                object_id: {
                    "name": obj.name,
                    "matrix_world": [[float(value) for value in row] for row in obj.matrix_world],
                    "dimensions": [float(value) for value in obj.dimensions],
                    "transform_mode": (
                        "inherited_target"
                        if next(item for item in object_configs if item["id"] == object_id).get("inherit_target_transform", True)
                        else "config"
                    ),
                    "configured_transform": next(item for item in object_configs if item["id"] == object_id).get("object_transform"),
                }
                for object_id, obj in objects_by_id.items()
            },
            "projection": projection,
        },
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
