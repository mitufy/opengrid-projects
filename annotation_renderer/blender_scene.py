"""Blender-side scene replacement and projection script generation."""

from __future__ import annotations

from pathlib import Path


def write_blender_scene_script(path: Path) -> None:
    path.write_text(
        r'''
from __future__ import annotations

import json
from math import radians
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Euler, Matrix, Vector


config = json.loads(Path(__file__).with_name("blender_scene_config.json").read_text(encoding="utf-8"))


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


def combined_world_bbox(objects):
    all_points = []
    for obj in objects:
        all_points.extend(world_bbox(obj)[2])
    mins = Vector((min(p.x for p in all_points), min(p.y for p in all_points), min(p.z for p in all_points)))
    maxs = Vector((max(p.x for p in all_points), max(p.y for p in all_points), max(p.z for p in all_points)))
    return mins, maxs, all_points


def fit_camera_to_objects(scene, camera, objects):
    if not config.get("fit_camera", False):
        return None
    margin = float(config.get("fit_margin", 0.08))
    mins, maxs, corners = combined_world_bbox(objects)
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


def configure_render(scene):
    engine = config.get("render_engine", "cycles")
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
    scene.render.resolution_x = int(config.get("width", 1200))
    scene.render.resolution_y = int(config.get("height", 900))
    scene.render.resolution_percentage = 100
    quality = config.get("quality", "standard")
    sample_count = 32 if quality == "draft" else 192 if quality == "high" else 96
    try_set(getattr(scene, "cycles", None), "samples", sample_count)
    try_set(getattr(scene, "cycles", None), "use_denoising", True)
    try_set(getattr(scene, "eevee", None), "taa_render_samples", sample_count)
    scene.render.filepath = config["render_path"]
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
            "mesh_shading": config.get("mesh_shading", "flat"),
        }
    ]

objects_by_id = {}
rendered_objects = []
for object_config in object_configs:
    obj = replace_or_import_object(object_config)
    configure_shading(obj, object_config.get("mesh_shading", config.get("mesh_shading", "flat")))
    objects_by_id[object_config["id"]] = obj
    rendered_objects.append(obj)
if not rendered_objects:
    raise RuntimeError("No render objects configured")

configure_render(scene)
bpy.context.view_layer.update()
camera_fit = fit_camera_to_objects(scene, camera, rendered_objects)
bpy.ops.render.render(write_still=True)

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
                "fit": camera_fit,
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
'''.lstrip(),
        encoding="utf-8",
    )
