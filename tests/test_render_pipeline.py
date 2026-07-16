from __future__ import annotations

import argparse
import json
import tempfile
from pathlib import Path
from PIL import Image
import yaml
from annotation_renderer.annotation_config import DimensionSegment
from annotation_renderer.config.schema import ConfigError
from annotation_renderer.config.validation import resolve_render, validate_config_shape
from annotation_renderer.config.defaults import (
    ANNOTATION_COLOR_BLUE,
    ANNOTATION_LABEL_FONT_SIZE_PX,
    BUILTIN_CONFIG_CONSTANTS,
    CAMERA_VIEW_PRESETS,
    DEFAULT_IMPORTED_MODEL_MATERIAL_COLOR,
    DEFAULT_RENDER_MESH_SHADING,
    DEFAULT_STYLE_PRESET_NAME,
    GALLERY_SETTING_DEFAULTS,
    MESH_SHADING_VALUES,
    RENDER_CAMERA_VIEW_PRESET_VALUES,
    RENDER_LIGHTING_PRESETS,
    RENDER_OUTPUT_MODES,
)
from annotation_renderer.config.resolution import (
    aliases_from_config,
    build_expression_context,
    resolve_style,
)
from annotation_renderer.config.loader import load_config
from annotation_renderer.diagnostics import MINIMUM_BLENDER_VERSION
from annotation_renderer.gallery import gallery_settings
from annotation_renderer.overlay import DimensionChainOverlaySpec, draw_dimension_chains_overlay
from annotation_renderer.cli import parse_args_from
from annotation_renderer.cache import blender_stage_cache_key, openscad_stage_cache_key
from annotation_renderer.pipeline import (
    cache_enabled_for,
    cache_root_for,
    build_blender_config,
    output_mode_for,
    export_blend_for,
    scad_output_folder_name,
    scene_object_specs,
    style_for_group,
)
from tests.renderer_test_case import RendererTestCase


class RenderPipelineTests(RendererTestCase):
    def test_render_animation_is_validated_during_config_shape_validation(self) -> None:
        config = {
            "scene": {
                "blend_file": "demo.blend",
                "objects": [{"id": "model", "model": {"scad_file": "demo.scad"}}],
            },
            "render": {
                "animation": {
                    "fps": "fast",
                    "object_animations": [{"object": "model", "start_frame": 0, "end_frame": 2}],
                }
            },
            "annotations": {},
        }

        with self.assertRaisesRegex(ConfigError, "render.animation.fps must be an integer"):
            validate_config_shape(config)

    def test_render_animation_is_allowed_under_render_config(self) -> None:
        validate_config_shape(
            {
                "scene": {
                    "blend_file": "demo.blend",
                    "objects": [{"id": "model", "model": {"scad_file": "demo.scad"}}],
                },
                "render": {
                    "animation": {
                        "object_animations": [{"object": "model", "start_frame": 0, "end_frame": 2}],
                    }
                },
                "annotations": {},
            }
        )

    def test_scene_objects_can_reference_prebuilt_stl_files(self) -> None:
        config = {
            "constants": {"og_tile_size": 28, "og_standard_thickness": 6.8},
            "scene": {
                "blend_file": "demo.blend",
                "objects": [
                    {"id": "model", "model": {"scad_file": "demo.scad"}},
                    {
                        "id": "snap",
                        "stl_file": "annotation_renderer/assets/openconnect_standard_snap.stl",
                        "inherit_target_transform": False,
                        "transform": {
                            "location_mm": ["-(og_tile_size / 2)", "og_standard_thickness", "-(og_tile_size / 2)"],
                            "rotation_deg": [90, 0, 0],
                            "scale": [0.001, 0.001, 0.001],
                        },
                    },
                ],
            },
            "annotations": {},
        }

        validate_config_shape(config)
        specs = scene_object_specs(
            config=config,
            scene_config=config["scene"],
            config_dir=Path.cwd(),
            expression_context=build_expression_context(config),
        )

        self.assertEqual(specs[1]["source_type"], "stl")
        self.assertEqual(Path(specs[1]["stl_file"]).name, "openconnect_standard_snap.stl")
        self.assertEqual(specs[1]["transform"]["location_mm"], [-14.0, 6.8, -14.0])

    def test_scene_line_copies_expand_stl_object_offsets(self) -> None:
        config_path = Path("annotation_renderer/configs/openconnect_standard_snap_line_copies.yaml")
        config = load_config(config_path, [])
        specs = scene_object_specs(
            config=config,
            scene_config=config["scene"],
            config_dir=config_path.parent,
            expression_context=build_expression_context(config),
        )

        self.assertEqual([spec["id"] for spec in specs], ["openconnect_standard_snap_0", "openconnect_standard_snap_1"])
        self.assertEqual([spec["target_object"] for spec in specs], ["openconnect_standard_snap_0", "openconnect_standard_snap_1"])
        self.assertEqual(specs[0]["transform"]["location_mm"], [-14.0, 6.8, -14.0])
        self.assertEqual(specs[1]["transform"]["location_mm"], [14.0, 6.8, -14.0])

    def test_scene_grid_copies_expand_stl_object_offsets(self) -> None:
        config_path = Path("annotation_renderer/configs/openconnect_standard_snap_grid_copies.yaml")
        config = load_config(config_path, [])
        specs = scene_object_specs(
            config=config,
            scene_config=config["scene"],
            config_dir=config_path.parent,
            expression_context=build_expression_context(config),
        )

        self.assertEqual(
            [spec["id"] for spec in specs],
            [
                "openconnect_standard_snap_0_0_0",
                "openconnect_standard_snap_1_0_0",
                "openconnect_standard_snap_0_0_1",
                "openconnect_standard_snap_1_0_1",
            ],
        )
        self.assertEqual(specs[0]["transform"]["location_mm"], [-14.0, 6.8, -14.0])
        self.assertEqual(specs[1]["transform"]["location_mm"], [14.0, 6.8, -14.0])
        self.assertEqual(specs[2]["transform"]["location_mm"], [-14.0, 6.8, 14.0])
        self.assertEqual(specs[3]["transform"]["location_mm"], [14.0, 6.8, 14.0])

    def test_expanding_snap_grid_copies_use_expanding_stl_transform(self) -> None:
        config_path = Path("annotation_renderer/configs/opengrid_expanding_standard_snap_grid_copies.yaml")
        config = load_config(config_path, [])
        specs = scene_object_specs(
            config=config,
            scene_config=config["scene"],
            config_dir=config_path.parent,
            expression_context=build_expression_context(config),
        )

        self.assertEqual(Path(specs[0]["stl_file"]).name, "opengrid_expanding_standard_snap.stl")
        self.assertEqual(config["render"]["camera_view"], "bottom")
        self.assertEqual(specs[0]["transform"]["location_mm"], [-14.0, 0.0, -14.0])
        self.assertEqual(specs[0]["transform"]["rotation_deg"], [-90.0, 180.0, 0.0])
        self.assertEqual(specs[3]["transform"]["location_mm"], [14.0, 0.0, 14.0])

    def test_render_output_mode_is_validated_and_cli_overrides_config(self) -> None:
        render = resolve_render({"preset": "cycles_standard_scene", "output_mode": "debug"})
        args = parse_args_from(["render", "openconnect_general_holder", "--output-mode", "minimal"])

        self.assertEqual(render["output_mode"], "debug")
        self.assertEqual(output_mode_for({}, argparse.Namespace(output_mode=None)), "standard")
        self.assertEqual(output_mode_for(render, argparse.Namespace(output_mode=None)), "debug")
        self.assertEqual(output_mode_for(render, args), "minimal")
        with self.assertRaisesRegex(ConfigError, "render.output_mode must be one of debug, minimal, standard"):
            resolve_render({"preset": "cycles_standard_scene", "output_mode": "everything"})

    def test_render_export_blend_is_validated_and_cli_overrides_config(self) -> None:
        render = resolve_render({"preset": "cycles_standard_scene", "export_blend": True})
        default_args = parse_args_from(["render", "openconnect_general_holder"])
        cli_args = parse_args_from(["render", "openconnect_general_holder", "--export-blend"])

        self.assertTrue(export_blend_for(render, default_args))
        self.assertTrue(export_blend_for({}, cli_args))
        self.assertFalse(export_blend_for({}, default_args))
        with self.assertRaisesRegex(ConfigError, "render.export_blend must be a boolean"):
            resolve_render({"preset": "cycles_standard_scene", "export_blend": "yes"})

    def test_default_material_color_is_passed_to_imported_models(self) -> None:
        render = resolve_render({"preset": "cycles_standard_scene"})
        self.assertEqual(render["default_material_color"], DEFAULT_IMPORTED_MODEL_MATERIAL_COLOR)
        with self.assertRaisesRegex(ConfigError, "render.default_material_color must be a non-empty color string"):
            resolve_render({"preset": "cycles_standard_scene", "default_material_color": ""})
        with self.assertRaisesRegex(ConfigError, "render.default_material_color must be a non-empty color string"):
            resolve_render({"preset": "cycles_standard_scene", "default_material_color": {"color": "#ffffff"}})
        with self.assertRaisesRegex(ConfigError, "must use #RGB"):
            resolve_render({"preset": "cycles_standard_scene", "default_material_color": "white"})

        blender_config = build_blender_config(
            scene_config={"camera": "Camera"},
            render_settings=render,
            object_records=[
                {
                    "id": "model",
                    "stl_path": "model.stl",
                    "target_object": "model",
                    "replace_target_object": True,
                    "inherit_target_transform": False,
                    "transform": {"location": [0, 0, 0], "rotation_deg": [0, 0, 0], "scale": [1, 1, 1]},
                }
            ],
            projection_points={},
            render_path=Path("render.png"),
            projection_path=Path("projection.json"),
            animation_config=None,
            animation_frame_dir=None,
            expression_context={},
        )

        self.assertIsNone(blender_config["objects"][0]["material"])
        self.assertEqual(
            blender_config["objects"][0]["default_material_color"],
            DEFAULT_IMPORTED_MODEL_MATERIAL_COLOR,
        )

    def test_render_cache_controls_are_resolved_from_cli_and_config(self) -> None:
        default_args = parse_args_from(["render", "openconnect_general_holder"])

        self.assertTrue(cache_enabled_for({}, default_args))
        self.assertFalse(cache_enabled_for({"cache": False}, default_args))
        self.assertFalse(cache_enabled_for({}, parse_args_from(["render", "openconnect_general_holder", "--no-cache"])))
        self.assertIsNone(
            cache_root_for(
                {"output_dir": "build/scene_annotations"},
                {},
                parse_args_from(["render", "openconnect_general_holder", "--no-cache"]),
            )
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            cache_dir = Path(temp_dir) / "cache"
            args = parse_args_from(["render", "openconnect_general_holder", "--cache-dir", str(cache_dir)])
            self.assertEqual(cache_root_for({"output_dir": "build/scene_annotations"}, {}, args), cache_dir.resolve())
            self.assertTrue(cache_dir.exists())

        with self.assertRaisesRegex(ConfigError, "render.cache must be a boolean"):
            cache_enabled_for({"cache": "yes"}, default_args)

    def test_openscad_cache_key_changes_when_included_dependency_changes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            dependency_dir = root / "deps"
            dependency_dir.mkdir()
            source = root / "model.scad"
            dependency = dependency_dir / "shared.scad"
            source.write_text("include <deps/shared.scad>\ncube(size);\n", encoding="utf-8")
            dependency.write_text("size = 10;\n", encoding="utf-8")
            first = openscad_stage_cache_key(
                scad_file=source,
                defines=(),
                executable="openscad",
                dependency_roots=(root,),
            )
            dependency.write_text("size = 20;\n", encoding="utf-8")
            second = openscad_stage_cache_key(
                scad_file=source,
                defines=(),
                executable="openscad",
                dependency_roots=(root,),
            )

        self.assertNotEqual(first, second)

    def test_schema_validation_rejects_unknown_config_fields(self) -> None:
        base = {
            "scene": {"blend_file": "demo.blend"},
            "render": {},
            "annotations": {},
        }
        with self.assertRaisesRegex(ConfigError, "Config schema validation failed.*typo_top_level"):
            validate_config_shape({**base, "typo_top_level": True})
        with self.assertRaisesRegex(ConfigError, "Config schema validation failed.*typo_annotation"):
            validate_config_shape({**base, "annotations": {"typo_annotation": True}})

    def test_grid_aliases_format_from_the_shared_tile_size(self) -> None:
        aliases = aliases_from_config(
            {"aliases": {"horizontal_grids": "horizontal_grids x {og_tile_size:g}mm"}},
            context={"og_tile_size": 42},
        )

        self.assertEqual(aliases["horizontal_grids"], "horizontal_grids x 42mm")

    def test_blender_cache_key_ignores_output_paths_and_tracks_stl_content(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            blend_file = temp_path / "scene.blend"
            stl_file = temp_path / "model.stl"
            blend_file.write_bytes(b"blend-v1")
            stl_file.write_bytes(b"stl-v1")
            blender_config = {
                "render_path": str(temp_path / "run-a" / "render.png"),
                "projection_path": str(temp_path / "run-a" / "projection.json"),
                "width": 640,
                "height": 480,
                "objects": [
                    {
                        "id": "model",
                        "stl_path": str(stl_file),
                        "target_object": "model",
                        "transform": {"location": [0, 0, 0], "rotation_deg": [0, 0, 0], "scale": [1, 1, 1]},
                    }
                ],
            }

            first_key = blender_stage_cache_key(blender="blender", blend_file=blend_file, blender_config=blender_config)
            same_inputs_new_output = dict(blender_config)
            same_inputs_new_output["render_path"] = str(temp_path / "run-b" / "render.png")
            same_inputs_new_output["projection_path"] = str(temp_path / "run-b" / "projection.json")
            same_inputs_new_output["export_blend_path"] = str(temp_path / "run-b" / "scene.blend")
            self.assertEqual(
                first_key,
                blender_stage_cache_key(blender="blender", blend_file=blend_file, blender_config=same_inputs_new_output),
            )

            stl_file.write_bytes(b"stl-v2")
            self.assertNotEqual(
                first_key,
                blender_stage_cache_key(blender="blender", blend_file=blend_file, blender_config=blender_config),
            )

    def test_render_camera_view_is_validated_and_passed_to_blender(self) -> None:
        render = resolve_render(
            {
                "preset": "cycles_standard_scene",
                "camera_view": "left",
                "camera_view_preset": "technical_iso",
                "camera_rotation_deg": [0, -90, 0],
                "camera_rotation_offset_deg": [0, 0, 5],
                "camera_orbit_deg": [30, 12],
                "camera_distance_scale": 1.35,
                "camera_target_offset_mm": [0, "og_tile_size / 2", 0],
                "camera_roll_deg": 7,
                "camera_lens_mm": 70,
                "lighting": {"preset": "technical", "strength": 1.2},
                "outline": {"enabled": True, "line_width_px": 1.25},
                "ground_plane": {"enabled": True, "offset_mm": "-og_tile_size / 4"},
                "cutaway": {
                    "enabled": True,
                    "axis": "z",
                    "keep": "negative",
                    "position_fraction": "0.35",
                    "offset_mm": "og_tile_size / 2",
                    "section_plane": {
                        "enabled": True,
                        "color": "#f97316",
                        "alpha": 0.4,
                        "padding_mm": "og_tile_size / 10",
                        "offset_mm": 0.2,
                    },
                },
                "xray": {"enabled": True, "objects": ["model"], "alpha": 0.3},
                "default_material_color": "#D6D3D1",
                "material_overrides": {"model": {"color": "#FF0000", "alpha": 0.5}},
            }
        )
        self.assertEqual(render["camera_view"], "left")
        self.assertEqual(render["camera_view_preset"], "technical_iso")
        self.assertEqual(render["camera_rotation_deg"], [0, -90, 0])
        self.assertEqual(render["camera_rotation_offset_deg"], [0, 0, 5])
        self.assertEqual(render["camera_orbit_deg"], [30, 12])
        self.assertEqual(render["camera_distance_scale"], 1.35)
        self.assertEqual(render["camera_roll_deg"], 7)
        self.assertEqual(render["camera_lens_mm"], 70)
        self.assertEqual(render["lighting"]["preset"], "technical")
        self.assertEqual(render["default_material_color"], "#D6D3D1")
        self.assertEqual(render["material_overrides"]["model"]["alpha"], 0.5)
        with self.assertRaisesRegex(ConfigError, "render.camera_view must be one of back, bottom, front, left, none, right, top"):
            resolve_render({"preset": "cycles_standard_scene", "camera_view": "diagonal"})
        with self.assertRaisesRegex(ConfigError, "render.camera_distance_scale must be at least"):
            resolve_render({"preset": "cycles_standard_scene", "camera_distance_scale": 0})
        with self.assertRaisesRegex(ConfigError, "render.camera_view_preset must be one of"):
            resolve_render({"preset": "cycles_standard_scene", "camera_view_preset": "corner"})
        with self.assertRaisesRegex(ConfigError, "must not define both camera_focal_length_mm and camera_lens_mm"):
            resolve_render({"preset": "cycles_standard_scene", "camera_focal_length_mm": 55, "camera_lens_mm": 70})
        with self.assertRaisesRegex(ConfigError, "must not define both position_mm and position_fraction"):
            resolve_render(
                {
                    "preset": "cycles_standard_scene",
                    "cutaway": {"position_mm": 10, "position_fraction": 0.5},
                }
            )

        blender_config = build_blender_config(
            scene_config={"camera": "Camera"},
            render_settings=render,
            object_records=[
                {
                    "id": "model",
                    "stl_path": "model.stl",
                    "target_object": "model",
                    "replace_target_object": True,
                    "inherit_target_transform": False,
                    "transform": {"location": [0, 0, 0], "rotation_deg": [0, 0, 0], "scale": [1, 1, 1]},
                    "material": {"roughness": 0.4},
                }
            ],
            projection_points={},
            render_path=Path("render.png"),
            projection_path=Path("projection.json"),
            animation_config=None,
            animation_frame_dir=None,
            expression_context={"og_tile_size": 28},
        )

        self.assertEqual(blender_config["camera_view"], "left")
        self.assertEqual(blender_config["camera_view_preset"], "technical_iso")
        self.assertEqual(blender_config["camera_rotation"], [0.0, -90.0, 0.0])
        self.assertEqual(blender_config["camera_rotation_offset"], [0.0, 0.0, 5.0])
        self.assertEqual(blender_config["camera_orbit"], [30.0, 12.0])
        self.assertEqual(blender_config["camera_distance_scale"], 1.35)
        self.assertEqual(blender_config["camera_target_offset"], [0.0, 0.014, 0.0])
        self.assertEqual(blender_config["camera_roll"], 7.0)
        self.assertEqual(blender_config["camera_lens"], 70.0)
        self.assertEqual(blender_config["lighting"]["preset"], "technical")
        self.assertEqual(blender_config["ground_plane"]["offset_mm"], -7.0)
        self.assertEqual(blender_config["cutaway"]["offset_mm"], 14.0)
        self.assertEqual(blender_config["cutaway"]["position_fraction"], 0.35)
        self.assertEqual(blender_config["cutaway"]["section_plane"]["padding_mm"], 2.8)
        self.assertEqual(blender_config["cutaway"]["section_plane"]["offset_mm"], 0.2)
        self.assertEqual(blender_config["objects"][0]["material"], {"roughness": 0.4, "color": "#FF0000", "alpha": 0.5})

        preset_config = build_blender_config(
            scene_config={"camera": "Camera"},
            render_settings=resolve_render({"preset": "cycles_standard_scene", "camera_view_preset": "technical_iso"}),
            object_records=[
                {
                    "id": "model",
                    "stl_path": "model.stl",
                    "target_object": "model",
                    "replace_target_object": True,
                    "inherit_target_transform": False,
                    "transform": {"location": [0, 0, 0], "rotation_deg": [0, 0, 0], "scale": [1, 1, 1]},
                }
            ],
            projection_points={},
            render_path=Path("render.png"),
            projection_path=Path("projection.json"),
            animation_config=None,
            animation_frame_dir=None,
            expression_context={},
        )
        self.assertEqual(preset_config["camera_view"], "front")
        self.assertEqual(preset_config["camera_orbit"], [35.0, 24.0])
        self.assertEqual(preset_config["camera_distance_scale"], 1.0)

    def test_render_scene_light_power_is_validated_and_passed_to_blender(self) -> None:
        render = resolve_render(
            {
                "preset": "cycles_standard_scene",
                "lighting": {"preset": "scene", "toplight_power": 175.0, "frontlight_power": 80.0},
            }
        )
        self.assertEqual(render["lighting"]["preset"], "scene")
        self.assertEqual(render["lighting"]["toplight_power"], 175.0)
        self.assertEqual(render["lighting"]["frontlight_power"], 80.0)

        with self.assertRaisesRegex(ConfigError, "render.lighting.toplight_power must be numeric"):
            resolve_render({"preset": "cycles_standard_scene", "lighting": {"preset": "scene", "toplight_power": "bright"}})
        with self.assertRaisesRegex(ConfigError, "render.lighting.frontlight_power must be at least 0"):
            resolve_render({"preset": "cycles_standard_scene", "lighting": {"preset": "scene", "frontlight_power": -1}})

        blender_config = build_blender_config(
            scene_config={"camera": "Camera"},
            render_settings=render,
            object_records=[
                {
                    "id": "model",
                    "stl_path": "model.stl",
                    "target_object": "model",
                    "replace_target_object": True,
                    "inherit_target_transform": False,
                    "transform": {"location": [0, 0, 0], "rotation_deg": [0, 0, 0], "scale": [1, 1, 1]},
                }
            ],
            projection_points={},
            render_path=Path("render.png"),
            projection_path=Path("projection.json"),
            animation_config=None,
            animation_frame_dir=None,
            expression_context={},
        )
        self.assertEqual(
            blender_config["lighting"],
            {"preset": "scene", "toplight_power": 175.0, "frontlight_power": 80.0},
        )

    def test_scad_output_folder_name_groups_by_scad_source(self) -> None:
        self.assertEqual(
            scad_output_folder_name(
                [
                    {"scad_file": "openconnect_general_holder.scad"},
                    {"scad_file": "openconnect_general_holder.scad"},
                ]
            ),
            "openconnect_general_holder",
        )
        self.assertEqual(
            scad_output_folder_name(
                [
                    {"scad_file": "openconnect_drawer.scad"},
                    {"scad_file": "openconnect_sturdy_hook.scad"},
                ]
            ),
            "openconnect_drawer_openconnect_sturdy_hook",
        )

    def test_annotation_style_values_are_validated_at_runtime(self) -> None:
        base_config = {
            "scene": {
                "blend_file": "demo.blend",
                "objects": [{"id": "model", "model": {"scad_file": "demo.scad"}}],
            },
            "annotations": {},
        }

        invalid_style = dict(base_config)
        invalid_style["annotations"] = {"style": {"label_font_size_px": "large"}}
        with self.assertRaisesRegex(ConfigError, "annotations.style.label_font_size_px must be an integer"):
            validate_config_shape(invalid_style)

        validate_config_shape(
            {
                **base_config,
                "annotations": {
                    "style": {
                        "image_label_title_positions": ["top", "bottom"],
                        "image_label_title_top_margin_px": 24,
                    }
                },
            }
        )
        invalid_title_position = dict(base_config)
        invalid_title_position["annotations"] = {"style": {"image_label_title_positions": ["center"]}}
        with self.assertRaisesRegex(
            ConfigError,
            "annotations.style.image_label_title_positions must be a non-empty array containing only bottom, top",
        ):
            validate_config_shape(invalid_title_position)

        invalid_group = dict(base_config)
        invalid_group["annotations"] = {"chains": [{"ids": ["span"], "label_font_size_px": 0}]}
        with self.assertRaisesRegex(ConfigError, "annotations.chains\\[0\\].label_font_size_px must be at least 1"):
            validate_config_shape(invalid_group)

        invalid_group_alias = dict(base_config)
        invalid_group_alias["annotations"] = {"chains": [{"ids": ["span"], "font_size_px": 0}]}
        with self.assertRaisesRegex(ConfigError, "annotations.chains\\[0\\].font_size_px must be at least 1"):
            validate_config_shape(invalid_group_alias)

    def test_annotation_font_size_aliases_resolve_to_label_font_size(self) -> None:
        self.assertEqual(resolve_style({"font_size_px": 34})["label_font_size_px"], 34)
        self.assertEqual(
            style_for_group({"label_font_size_px": 20}, {"font_size_px": 35})["label_font_size_px"],
            35,
        )
        self.assertEqual(
            style_for_group({"label_font_size_px": 20}, {"font_size_px": 35, "label_font_size_px": 28})[
                "label_font_size_px"
            ],
            28,
        )

    def test_base_scene_uses_builtin_annotation_style_defaults(self) -> None:
        raw_base = yaml.safe_load(Path("annotation_renderer/configs/base_scene.yaml").read_text(encoding="utf-8"))
        raw_constants = raw_base["constants"]
        self.assertNotIn("default_annotation_style", raw_constants)
        self.assertNotIn("annotation_label_font_size_px", raw_constants)
        self.assertNotIn("annotation_color_blue", raw_constants)

        self.assertEqual(BUILTIN_CONFIG_CONSTANTS["default_annotation_style"], {"preset": DEFAULT_STYLE_PRESET_NAME})
        config = load_config(Path("annotation_renderer/configs/openconnect_clamshell_holder.yaml"), [])
        self.assertEqual(config["constants"]["default_annotation_style"], {"preset": DEFAULT_STYLE_PRESET_NAME})
        style = resolve_style(config["annotations"]["style"])
        self.assertEqual(style["label_font_size_px"], ANNOTATION_LABEL_FONT_SIZE_PX)
        self.assertEqual(style["tick_length_px"], 14)
        self.assertEqual(style["extension_width_px"], 2)
        self.assertEqual(style["type_styles"]["grids"]["line_colors"], [ANNOTATION_COLOR_BLUE])

    def test_dimension_chains_use_each_chain_style_for_label_metadata(self) -> None:
        projection = {
            "projection": {
                "first.start": {"px": [20.0, 40.0]},
                "first.end": {"px": [80.0, 40.0]},
                "second.start": {"px": [20.0, 80.0]},
                "second.end": {"px": [80.0, 80.0]},
            }
        }
        first_segment = DimensionSegment(
            id="first",
            label="first",
            value="60",
            start_mm=(0.0, 0.0, 0.0),
            end_mm=(60.0, 0.0, 0.0),
            color="#2f7f8f",
        )
        second_segment = DimensionSegment(
            id="second",
            label="second",
            value="60",
            start_mm=(0.0, 0.0, 0.0),
            end_mm=(60.0, 0.0, 0.0),
            color="#2f7f8f",
        )
        temp_path = Path("build") / "tmp"
        temp_path.mkdir(parents=True, exist_ok=True)
        render_path = temp_path / "chain_style_render.png"
        output_path = temp_path / "chain_style_annotated.png"
        try:
            Image.new("RGB", (120, 120), "white").save(render_path)

            metadata = draw_dimension_chains_overlay(
                render_path=render_path,
                output_path=output_path,
                projection=projection,
                chains=[
                    DimensionChainOverlaySpec(
                        segments=[first_segment],
                        line_offset_px=0.0,
                        label_offset_px=12.0,
                        style_config={
                            "label_font_size_px": 10,
                            "label_outline_width_px": 0,
                            "type_styles": {"mm": {"text_color": "#111111", "font": "sans"}},
                        },
                    ),
                    DimensionChainOverlaySpec(
                        segments=[second_segment],
                        line_offset_px=0.0,
                        label_offset_px=12.0,
                        style_config={
                            "label_font_size_px": 10,
                            "label_outline_width_px": 0,
                            "type_styles": {"mm": {"text_color": "#222222", "font": "sans"}},
                        },
                    ),
                ],
            )
        finally:
            render_path.unlink(missing_ok=True)
            output_path.unlink(missing_ok=True)

        self.assertEqual(metadata[0]["text"]["first"]["color"], "#111111")
        self.assertEqual(metadata[1]["text"]["second"]["color"], "#222222")

    def test_dimension_chain_label_along_offset_moves_label_with_line_direction(self) -> None:
        projection = {
            "projection": {
                "span.start": {"px": [20.0, 40.0]},
                "span.end": {"px": [80.0, 40.0]},
            }
        }
        segment = DimensionSegment(
            id="span",
            label="span",
            value="60",
            start_mm=(0.0, 0.0, 0.0),
            end_mm=(60.0, 0.0, 0.0),
            color="#2f7f8f",
        )
        temp_path = Path("build") / "tmp"
        temp_path.mkdir(parents=True, exist_ok=True)
        render_path = temp_path / "label_along_render.png"
        output_path = temp_path / "label_along_annotated.png"
        try:
            Image.new("RGB", (120, 120), "white").save(render_path)

            metadata = draw_dimension_chains_overlay(
                render_path=render_path,
                output_path=output_path,
                projection=projection,
                chains=[
                    DimensionChainOverlaySpec(
                        segments=[segment],
                        line_offset_px=0.0,
                        label_offset_px=0.0,
                        style_config={"label_font_size_px": 10, "label_outline_width_px": 0},
                        label_along_offset_px=15.0,
                    ),
                ],
            )
        finally:
            render_path.unlink(missing_ok=True)
            output_path.unlink(missing_ok=True)

        center = metadata[0]["text"]["span"]["center_px"]
        self.assertEqual(center, {"x": 65.0, "y": 40.0})
        self.assertEqual(metadata[0]["label_along_offset_px"], 15.0)

    def test_label_auto_adjustment_is_disabled_by_default(self) -> None:
        projection = {
            "projection": {
                "first.start": {"px": [20.0, 40.0]},
                "first.end": {"px": [80.0, 40.0]},
                "second.start": {"px": [20.0, 40.0]},
                "second.end": {"px": [80.0, 40.0]},
            }
        }
        first_segment = DimensionSegment(
            id="first",
            label="first_label",
            value="60",
            start_mm=(0.0, 0.0, 0.0),
            end_mm=(60.0, 0.0, 0.0),
            color="#2f7f8f",
        )
        second_segment = DimensionSegment(
            id="second",
            label="second_label",
            value="60",
            start_mm=(0.0, 0.0, 0.0),
            end_mm=(60.0, 0.0, 0.0),
            color="#2f7f8f",
        )

        def render_centers(*, auto_adjust_labels: bool) -> tuple[dict[str, object], dict[str, object]]:
            temp_path = Path("build") / "tmp"
            temp_path.mkdir(parents=True, exist_ok=True)
            suffix = "adjusted" if auto_adjust_labels else "default"
            render_path = temp_path / f"auto_adjust_{suffix}_render.png"
            output_path = temp_path / f"auto_adjust_{suffix}_annotated.png"
            try:
                Image.new("RGB", (200, 120), "white").save(render_path)
                style = {
                    "label_font_size_px": 14,
                    "label_outline_width_px": 0,
                    "auto_adjust_labels": auto_adjust_labels,
                }
                metadata = draw_dimension_chains_overlay(
                    render_path=render_path,
                    output_path=output_path,
                    projection=projection,
                    chains=[
                        DimensionChainOverlaySpec(
                            segments=[first_segment],
                            line_offset_px=0.0,
                            label_offset_px=0.0,
                            style_config=style,
                        ),
                        DimensionChainOverlaySpec(
                            segments=[second_segment],
                            line_offset_px=0.0,
                            label_offset_px=0.0,
                            style_config=style,
                        ),
                    ],
                )
            finally:
                render_path.unlink(missing_ok=True)
                output_path.unlink(missing_ok=True)
            return metadata[0]["text"]["first"]["center_px"], metadata[1]["text"]["second"]["center_px"]

        default_first, default_second = render_centers(auto_adjust_labels=False)
        adjusted_first, adjusted_second = render_centers(auto_adjust_labels=True)

        self.assertEqual(default_first, default_second)
        self.assertNotEqual(adjusted_first, adjusted_second)

    def test_schema_places_animation_under_render_config(self) -> None:
        schema_path = Path("annotation_renderer") / "schemas" / "annotation-render-config.schema.json"
        schema = json.loads(schema_path.read_text(encoding="utf-8"))

        render_properties = schema["$defs"]["renderConfig"]["anyOf"][1]["properties"]
        style_properties = schema["$defs"]["annotationStyle"]["anyOf"][1]["properties"]
        annotation_group_properties = schema["$defs"]["annotationGroup"]["anyOf"][0]["properties"]
        angle_radius_properties = schema["$defs"]["angleRadiusCallout"]["anyOf"][0]["properties"]
        image_label_properties = schema["$defs"]["imageLabel"]["anyOf"][0]["properties"]
        variant_properties = schema["properties"]["variants"]["items"]["properties"]
        scene_default_properties = schema["$defs"]["sceneObjectDefaults"]["anyOf"][0]["properties"]
        scene_object_properties = schema["$defs"]["sceneObject"]["anyOf"][0]["properties"]
        self.assertIn("animation", render_properties)
        self.assertIn("extends_variant", variant_properties)
        self.assertEqual(render_properties["camera_look_at"]["enum"], ["none", "object_center"])
        self.assertIn("camera_rotation_deg", render_properties)
        self.assertIn("camera_rotation_offset_deg", render_properties)
        self.assertIn("camera_orbit_deg", render_properties)
        self.assertIn("camera_distance_scale", render_properties)
        self.assertIn("camera_target_offset_mm", render_properties)
        self.assertIn("camera_roll_deg", render_properties)
        self.assertIn("camera_lens_mm", render_properties)
        self.assertIn("camera_focal_length_mm", render_properties)
        self.assertEqual(render_properties["camera_view"]["enum"], ["none", "front", "back", "left", "right", "top", "bottom"])
        self.assertIn("camera_view_preset", render_properties)
        self.assertEqual(schema["$defs"]["lightingPreset"]["enum"], ["scene", "technical", "softbox", "front_lit", "dramatic", "flat"])
        self.assertIn("lighting", render_properties)
        lighting_properties = schema["$defs"]["lightingConfig"]["anyOf"][1]["properties"]
        self.assertEqual(lighting_properties["toplight_power"]["minimum"], 0)
        self.assertEqual(lighting_properties["frontlight_power"]["minimum"], 0)
        self.assertIn("outline", render_properties)
        self.assertIn("ground_plane", render_properties)
        self.assertIn("cutaway", render_properties)
        cutaway_properties = schema["$defs"]["cutawayConfig"]["anyOf"][1]["properties"]
        self.assertIn("position_fraction", cutaway_properties)
        self.assertIn("section_plane", cutaway_properties)
        self.assertIn("xray", render_properties)
        self.assertIn("default_material_color", render_properties)
        self.assertIn("material_overrides", render_properties)
        self.assertEqual(render_properties["output_mode"]["enum"], ["minimal", "standard", "debug"])
        self.assertIn("auto_adjust_labels", style_properties)
        self.assertIn("font_size_px", style_properties)
        self.assertIn("font_size_px", annotation_group_properties)
        self.assertIn("display_rotation_deg", annotation_group_properties)
        self.assertIn("label_along_offset_px", annotation_group_properties)
        self.assertIn("font_size_px", angle_radius_properties)
        self.assertIn("display_rotation_deg", angle_radius_properties)
        self.assertIn("label_font_size_px", image_label_properties)
        self.assertIn("cache", render_properties)
        self.assertIn("cache_dir", render_properties)
        self.assertIn("export_blend", render_properties)
        self.assertNotIn("variant_name", schema["properties"])
        self.assertIn("annotationGroupMap", schema["$defs"])
        self.assertIn("variant_configs", schema["properties"])
        self.assertIn("variant_collections", schema["properties"])
        self.assertIn("variant_collection", schema["properties"]["gallery"]["properties"])
        self.assertIn("object_overrides", variant_properties)
        self.assertIn("unset", variant_properties)
        gallery_schema = json.loads(
            Path("annotation_renderer/schemas/annotation-render-gallery.schema.json").read_text(encoding="utf-8")
        )
        self.assertIn("variant_collection", gallery_schema["properties"])
        self.assertNotIn("animation", scene_default_properties)
        self.assertNotIn("animation", scene_object_properties)
        self.assertNotIn("line_copies", scene_default_properties)
        self.assertIn("line_copies", scene_object_properties)
        self.assertIn("grid_copies", scene_object_properties)

    def test_schema_backed_runtime_defaults_stay_in_sync(self) -> None:
        schema = json.loads(Path("annotation_renderer/schemas/annotation-render-config.schema.json").read_text(encoding="utf-8"))
        render_properties = schema["$defs"]["renderConfig"]["anyOf"][1]["properties"]
        self.assertEqual(tuple(render_properties["output_mode"]["enum"]), RENDER_OUTPUT_MODES)
        self.assertEqual(set(schema["$defs"]["cameraViewPreset"]["enum"]), set(CAMERA_VIEW_PRESETS))
        reference = Path("annotation_renderer/REFERENCE.md").read_text(encoding="utf-8")
        readme = Path("annotation_renderer/README.md").read_text(encoding="utf-8")
        self.assertIn(f"`{DEFAULT_IMPORTED_MODEL_MATERIAL_COLOR}`", reference)
        minimum_blender = ".".join(str(item) for item in MINIMUM_BLENDER_VERSION[:2])
        self.assertIn(f"Blender {minimum_blender}", reference)
        self.assertIn(f"Blender {minimum_blender}", readme)
        self.assertEqual(RENDER_CAMERA_VIEW_PRESET_VALUES, set(CAMERA_VIEW_PRESETS))
        self.assertEqual(tuple(schema["$defs"]["lightingPreset"]["enum"]), RENDER_LIGHTING_PRESETS)
        self.assertIn(DEFAULT_RENDER_MESH_SHADING, MESH_SHADING_VALUES)
        self.assertEqual(
            set(yaml.safe_load(Path("annotation_renderer/configs/gallery_defaults.yaml").read_text(encoding="utf-8")).keys()),
            {"$schema"},
        )
        self.assertEqual(
            gallery_settings({}, gallery_config={}),
            {key: int(value) for key, value in GALLERY_SETTING_DEFAULTS.items()},
        )

    def test_pyproject_declares_test_extra(self) -> None:
        pyproject = Path("pyproject.toml").read_text(encoding="utf-8")

        self.assertIn("test = [", pyproject)
        self.assertIn('"pytest>=9"', pyproject)
        self.assertIn('"PyYAML>=6.0"', pyproject)
        self.assertIn('"assets/*.stl"', pyproject)
        self.assertIn('"configs/*.yaml"', pyproject)
        self.assertIn('"configs/*.yml"', pyproject)
        self.assertNotIn('"configs/*.json"', pyproject)
