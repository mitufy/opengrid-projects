from __future__ import annotations

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

import yaml

from annotation_renderer.animation import resolve_animation_config
from annotation_renderer.config import ConfigError, validate_config_shape
from annotation_renderer.scene_cli import load_config, load_gallery_config, main, selected_variants, variant_config


class AnimationConfigTests(unittest.TestCase):
    def run_cli(self, *args: str) -> str:
        stream = io.StringIO()
        with redirect_stdout(stream):
            self.assertEqual(main(args), 0)
        return stream.getvalue()

    def test_clips_shift_local_keyframes_and_expand_visibility_and_opacity(self) -> None:
        animation = resolve_animation_config(
            {
                "enabled": True,
                "frame_start": 0,
                "duration_frames": 48,
                "fps": 24,
                "output_format": "gif",
                "gif_width_px": 900,
                "interpolation": "bezier",
                "clips": [
                    {
                        "name": "shell_openconnect_install",
                        "start_frame": 0,
                        "object_animations": [
                            {
                                "object": "drawer_shell",
                                "location_offset_keyframes_mm": [
                                    {"frame": 0, "value": [0, -20, 10]},
                                    {"frame": 48, "value": [0, 0, 0]},
                                ],
                            }
                        ],
                    },
                    {
                        "name": "container_slide",
                        "start_frame": 48,
                        "interpolation": "ease_out",
                        "object_animations": [
                            {
                                "object": "drawer_container",
                                "visible_from_frame": 0,
                                "opacity_interpolation": "linear",
                                "opacity_keyframes": [
                                    {"frame": 0, "value": 0},
                                    {"frame": 8, "value": 1},
                                ],
                                "from_location_offset_mm": [0, -50, 0],
                                "to_location_offset_mm": [0, 0, 0],
                            }
                        ],
                    },
                ],
            },
            object_records=[
                {"id": "drawer_shell", "expression_context": {}},
                {"id": "drawer_container", "expression_context": {}},
            ],
        )

        assert animation is not None
        self.assertEqual(animation["frame_start"], 0)
        self.assertEqual(animation["keyframe_frame_end"], 96)
        self.assertEqual(animation["frame_end"], 108)
        self.assertEqual(animation["end_pause_frames"], 12)
        self.assertEqual(animation["fps"], 24)
        self.assertEqual(animation["output_format"], "gif")
        self.assertEqual(animation["gif_width_px"], 900)

        shell, container = animation["object_animations"]
        self.assertEqual(shell["object"], "drawer_shell")
        self.assertEqual(shell["clip"], "shell_openconnect_install")
        self.assertEqual(shell["interpolation"], "bezier")
        self.assertEqual([keyframe["frame"] for keyframe in shell["location_offset_keyframes"]], [0, 48])
        self.assertEqual(shell["location_offset_keyframes"][0]["location_offset"], [0.0, -0.02, 0.01])

        self.assertEqual(container["object"], "drawer_container")
        self.assertEqual(container["clip"], "container_slide")
        self.assertEqual(container["start_frame"], 48)
        self.assertEqual(container["end_frame"], 96)
        self.assertEqual(container["interpolation"], "ease_out")
        self.assertEqual(container["opacity_interpolation"], "linear")
        self.assertEqual([keyframe["frame"] for keyframe in container["location_offset_keyframes"]], [48, 96])
        self.assertEqual(container["location_offset_keyframes"][0]["location_offset"], [0.0, -0.05, 0.0])
        self.assertEqual(
            container["visibility_keyframes"],
            [
                {"frame": 0, "visible": False},
                {"frame": 47, "visible": False},
                {"frame": 48, "visible": True},
            ],
        )
        self.assertEqual(
            container["opacity_keyframes"],
            [
                {"frame": 48, "opacity": 0.0},
                {"frame": 56, "opacity": 1.0},
            ],
        )

    def test_latest_opacity_keyframe_extends_derived_frame_end(self) -> None:
        animation = resolve_animation_config(
            {
                "enabled": True,
                "frame_start": 0,
                "duration_frames": 4,
                "end_pause_frames": 2,
                "object_animations": [
                    {
                        "object": "model",
                        "start_frame": 0,
                        "end_frame": 4,
                        "opacity_keyframes": [
                            {"frame": 0, "value": 0},
                            {"frame": 10, "value": 1},
                        ],
                    }
                ],
            },
            object_records=[{"id": "model", "expression_context": {}}],
        )

        assert animation is not None
        self.assertEqual(animation["keyframe_frame_end"], 10)
        self.assertEqual(animation["frame_end"], 12)
        self.assertEqual(animation["object_animations"][0]["opacity_keyframes"][-1], {"frame": 10, "opacity": 1.0})

    def test_opacity_keyframe_value_must_be_between_zero_and_one(self) -> None:
        with self.assertRaisesRegex(ConfigError, "opacity_keyframes\\[1\\].value must be between 0 and 1"):
            resolve_animation_config(
                {
                    "enabled": True,
                    "object_animations": [
                        {
                            "object": "model",
                            "opacity_keyframes": [
                                {"frame": 0, "value": 0},
                                {"frame": 1, "value": 1.25},
                            ],
                        }
                    ],
                },
                object_records=[{"id": "model", "expression_context": {}}],
            )

    def test_animation_examples_extend_model_defaults(self) -> None:
        config = load_config(Path("annotation_renderer/configs/animation_examples.json"), [])
        names = [variant["name"] for variant in selected_variants(config, None)]

        self.assertEqual(
            names,
            [
                "sturdy_shelf_insert_animation",
                "general_holder_insert_animation",
                "drawer_shell_container_slide_animation",
                "drawer_install_then_container_slide_animation",
            ],
        )

        drawer_variant = selected_variants(config, "drawer_install_then_container_slide_animation")[0]
        drawer_config = variant_config(config, drawer_variant)
        animation = drawer_config["render"]["animation"]
        self.assertEqual(animation["clips"][0]["object_animations"][0]["object"], "drawer_shell")
        self.assertEqual(animation["clips"][1]["object_animations"][0]["opacity_keyframes"][1], {"frame": 8, "value": 1})

        holder_variant = selected_variants(config, "general_holder_insert_animation")[0]
        holder_config = variant_config(config, holder_variant)
        self.assertEqual(holder_config["model"]["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(holder_config["render"]["animation"]["object_animations"][0]["object"], "model")

    def test_model_defaults_import_per_model_variant_configs(self) -> None:
        config = load_config(Path("annotation_renderer/configs/model_defaults.json"), [])
        names = [variant["name"] for variant in selected_variants(config, None)]

        self.assertEqual(
            names,
            [
                "sturdy_hook_default",
                "sturdy_shelf_default",
                "general_holder_default",
                "drawer_shell_default",
                "drawer_shell_container_default",
            ],
        )

        holder_variant = selected_variants(config, "general_holder_default")[0]
        holder_config = variant_config(config, holder_variant)
        self.assertEqual(holder_config["model"]["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(holder_config["scene"]["transform"]["rotation_deg"], [0, 0, 0])
        self.assertEqual(holder_config["render"]["camera_location_offset_mm"], [0, 0, 10])
        self.assertEqual(holder_config["annotations"]["chains"][0]["ids"], ["holder_width"])

    def test_per_model_default_config_is_directly_renderable(self) -> None:
        config = load_config(Path("annotation_renderer/configs/general_holder_default.json"), [])

        self.assertEqual(config["model"]["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(config["job_name"], "general_holder_scene_default")
        self.assertEqual(config["annotations"]["chains"][0]["ids"], ["holder_width"])

    def test_list_models_uses_default_model_config(self) -> None:
        output = self.run_cli("--list-models")

        self.assertIn("general_holder_default", output)
        self.assertIn("annotation_renderer/configs/general_holder_default.json", output)
        self.assertIn("model: openconnect_general_holder.scad", output)

    def test_describe_and_list_annotations_report_editable_settings(self) -> None:
        description = self.run_cli("--describe", "general_holder_default")
        direct_description = self.run_cli(
            "--config",
            "annotation_renderer/configs/general_holder_default.json",
            "--describe",
            "general_holder_default",
        )
        annotations = self.run_cli("--list-annotations", "general_holder_default")

        self.assertIn("compartment_shape: \"Rectangular\"", description)
        self.assertIn("Source: annotation_renderer/configs/general_holder_default.json", direct_description)
        self.assertIn("camera_location_offset_mm: [0,0,10]", description)
        self.assertIn("dimension: holder_width", annotations)
        self.assertIn("line_offset_px=20", annotations)
        self.assertIn("label_offset_px=28", annotations)

    def test_new_config_writes_valid_editable_template(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.json"
            output = self.run_cli("--new-config", "general_holder_default", "--out", str(output_path))
            template = json.loads(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("general_holder_default.json"))
        self.assertIn("scene", template)
        self.assertEqual(template["model"]["defines"]["compartment_shape"], "Rectangular")
        self.assertEqual(template["annotations"]["chains"][0]["ids"], ["holder_width"])
        self.assertEqual(config["model"]["scad_file"], "openconnect_general_holder.scad")

    def test_yaml_config_extends_json_default(self) -> None:
        default_config = Path("annotation_renderer/configs/general_holder_default.json").resolve().as_posix()
        scene_file = Path("annotation_renderer/assets/scenes/opengrid_wall_scene.blend").resolve().as_posix()
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.yaml"
            output_path.write_text(
                "\n".join(
                    [
                        f"extends: {json.dumps(default_config)}",
                        "job_name: holder_yaml_custom",
                        "scene:",
                        f"  blend_file: {json.dumps(scene_file)}",
                        "model:",
                        "  defines:",
                        "    compartment_column_count: 3",
                        "    custom_label: on",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            config = load_config(output_path, [])

        self.assertEqual(config["job_name"], "holder_yaml_custom")
        self.assertEqual(config["model"]["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(config["model"]["defines"]["compartment_column_count"], 3)
        self.assertEqual(config["model"]["defines"]["custom_label"], "on")

    def test_json_config_can_extend_yaml_config(self) -> None:
        default_config = Path("annotation_renderer/configs/general_holder_default.json").resolve().as_posix()
        scene_file = Path("annotation_renderer/assets/scenes/opengrid_wall_scene.blend").resolve().as_posix()
        with tempfile.TemporaryDirectory() as temp_dir:
            base_yaml_path = Path(temp_dir) / "holder_base.yaml"
            json_path = Path(temp_dir) / "holder_custom.json"
            base_yaml_path.write_text(
                "\n".join(
                    [
                        f"extends: {json.dumps(default_config)}",
                        "job_name: holder_yaml_base",
                        "scene:",
                        f"  blend_file: {json.dumps(scene_file)}",
                        "model:",
                        "  defines:",
                        "    compartment_column_count: 2",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            json_path.write_text(
                json.dumps(
                    {
                        "extends": base_yaml_path.as_posix(),
                        "job_name": "holder_json_extends_yaml",
                        "model": {"defines": {"compartment_row_count": 2}},
                    }
                ),
                encoding="utf-8",
            )
            config = load_config(json_path, [])

        self.assertEqual(config["job_name"], "holder_json_extends_yaml")
        self.assertEqual(config["model"]["defines"]["compartment_column_count"], 2)
        self.assertEqual(config["model"]["defines"]["compartment_row_count"], 2)

    def test_new_config_writes_yaml_template_from_yaml_extension(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.yaml"
            output = self.run_cli("--new-config", "general_holder_default", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("general_holder_default.json"))
        self.assertIn("scene", template)
        self.assertEqual(template["model"]["defines"]["compartment_shape"], "Rectangular")
        self.assertEqual(template["annotations"]["chains"][0]["ids"], ["holder_width"])
        self.assertEqual(config["model"]["scad_file"], "openconnect_general_holder.scad")

    def test_gallery_config_can_be_yaml(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            gallery_path = Path(temp_dir) / "gallery.yaml"
            gallery_path.write_text("columns: 3\nthumbnail_width: 480\n", encoding="utf-8")
            gallery_config, resolved_path = load_gallery_config(str(gallery_path), config_dir=Path.cwd())

        self.assertEqual(resolved_path, gallery_path.resolve())
        self.assertEqual(gallery_config, {"columns": 3, "thumbnail_width": 480})

    def test_render_animation_is_validated_during_config_shape_validation(self) -> None:
        config = {
            "model": {"scad_file": "demo.scad"},
            "scene": {"blend_file": "demo.blend", "target_object": "model"},
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
                "model": {"scad_file": "demo.scad"},
                "scene": {"blend_file": "demo.blend", "target_object": "model"},
                "render": {
                    "animation": {
                        "object_animations": [{"object": "model", "start_frame": 0, "end_frame": 2}],
                    }
                },
                "annotations": {},
            }
        )

    def test_schema_places_animation_under_render_config(self) -> None:
        schema_path = Path("annotation_renderer") / "schemas" / "annotation-render-config.schema.json"
        schema = json.loads(schema_path.read_text(encoding="utf-8"))

        render_properties = schema["$defs"]["renderConfig"]["anyOf"][1]["properties"]
        scene_default_properties = schema["$defs"]["sceneObjectDefaults"]["anyOf"][0]["properties"]
        scene_object_properties = schema["$defs"]["sceneObject"]["anyOf"][0]["properties"]
        self.assertIn("animation", render_properties)
        self.assertIn("variant_name", schema["properties"])
        self.assertIn("variant_configs", schema["properties"])
        self.assertNotIn("animation", scene_default_properties)
        self.assertNotIn("animation", scene_object_properties)

    def test_pyproject_declares_test_extra(self) -> None:
        pyproject = Path("pyproject.toml").read_text(encoding="utf-8")

        self.assertIn("test = [", pyproject)
        self.assertIn('"pytest>=9"', pyproject)
        self.assertIn('"PyYAML>=6.0"', pyproject)
        self.assertIn('"configs/*.yaml"', pyproject)
        self.assertIn('"configs/*.yml"', pyproject)


if __name__ == "__main__":
    unittest.main()
