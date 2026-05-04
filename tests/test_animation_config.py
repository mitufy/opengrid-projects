from __future__ import annotations

import unittest
from pathlib import Path

from annotation_renderer.animation import resolve_animation_config
from annotation_renderer.config import ConfigError
from annotation_renderer.scene_cli import load_config, selected_variants, variant_config


class AnimationConfigTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
