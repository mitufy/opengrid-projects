from __future__ import annotations

import argparse
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from PIL import Image
import yaml

from annotation_renderer.animation import resolve_animation_config
from annotation_renderer.annotation_config import (
    ImageLabel,
    collect_angle_radius_callouts,
    collect_dimension_chain,
    collect_image_labels,
)
from annotation_renderer.config import ConfigError, DimensionSegment, resolve_render, validate_config_shape
from annotation_renderer.config_resolution import build_expression_context, resolve_style
from annotation_renderer.overlay import DimensionChainOverlaySpec, draw_dimension_chains_overlay, draw_image_label_overlay
from annotation_renderer.scad_annotations import parse_scad_annotation_line, value_context_from_scad_annotations
from annotation_renderer.scene_cli import (
    annotation_bounds_quality_warnings,
    audit_scad_annotation_bounds,
    blender_stage_cache_key,
    cache_enabled_for,
    cache_root_for,
    command_failure_message,
    build_blender_config,
    build_gallery_contact_sheet,
    discover_scad_source_annotations,
    discovery_summary_json,
    default_config_for_model,
    format_annotation_discovery,
    format_doctor_check,
    gallery_settings,
    apply_animation_preset,
    load_config,
    load_gallery_config,
    label_value_context_for_record,
    main,
    output_file_from_args,
    output_mode_for,
    export_blend_for,
    overlay_quality_warnings,
    parse_args_from,
    scad_output_folder_name,
    selected_variants,
    scene_object_specs,
    style_for_group,
    variant_config,
    write_annotation_discovery_output,
)


class AnimationConfigTests(unittest.TestCase):
    def run_cli(self, *args: str) -> str:
        stream = io.StringIO()
        with redirect_stdout(stream):
            self.assertEqual(main(args), 0)
        return stream.getvalue()

    def first_model_config(self, config: dict[str, object]) -> dict[str, object]:
        return config["scene"]["objects"][0]["model"]

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

    def test_clip_object_start_and_end_frames_are_local_to_clip(self) -> None:
        animation = resolve_animation_config(
            {
                "enabled": True,
                "frame_start": 0,
                "duration_frames": 48,
                "clips": [
                    {
                        "start_frame": 48,
                        "object_animations": [
                            {
                                "object": "drawer_container",
                                "start_frame": 12,
                                "end_frame": 24,
                                "from_location_offset_mm": [0, -50, 0],
                                "to_location_offset_mm": [0, 0, 0],
                            }
                        ],
                    }
                ],
            },
            object_records=[{"id": "drawer_container", "expression_context": {}}],
        )

        assert animation is not None
        track = animation["object_animations"][0]
        self.assertEqual(track["start_frame"], 60)
        self.assertEqual(track["end_frame"], 72)
        self.assertEqual([keyframe["frame"] for keyframe in track["location_offset_keyframes"]], [60, 72])

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

    def test_animation_presets_file_has_no_model_variants(self) -> None:
        config = load_config(Path("annotation_renderer/configs/animation_presets.yaml"), [])

        self.assertEqual(selected_variants(config, None), [])
        self.assertIn("openconnect_insert_animation_render", config["constants"])
        self.assertIn("drawer_install_then_slide_animation_render", config["constants"])

    def test_animation_preset_shortcut_applies_to_model_defaults(self) -> None:
        holder_config_file = load_config(Path("annotation_renderer/configs/openconnect_general_holder_default.yaml"), [])
        holder_config = apply_animation_preset(holder_config_file, "openconnect_insert_animation_render")
        self.assertEqual(self.first_model_config(holder_config)["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(holder_config["scene"]["transform"]["rotation_deg"], ["holder_tilt_angle", 0, 0])
        self.assertEqual(holder_config["render"]["camera_look_at"], "object_center")
        self.assertEqual(holder_config["render"]["animation"]["object_animations"][0]["object"], "model")
        self.assertEqual(holder_config["annotations"], {})

        shelf_config_file = load_config(Path("annotation_renderer/configs/openconnect_sturdy_shelf_default.yaml"), [])
        shelf_config = apply_animation_preset(shelf_config_file, "openconnect_insert_animation_render")
        self.assertEqual(shelf_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])

        drawer_config_file = load_config(Path("annotation_renderer/configs/openconnect_drawer_shell_container_default.yaml"), [])
        drawer_config = apply_animation_preset(drawer_config_file, "drawer_install_then_slide_animation_render")
        animation = drawer_config["render"]["animation"]
        self.assertEqual(animation["clips"][0]["object_animations"][0]["object"], "drawer_shell")
        self.assertEqual(animation["clips"][1]["object_animations"][0]["opacity_keyframes"][1], {"frame": 8, "value": 1})

    def test_animation_preset_shortcut_rejects_non_animation_constants(self) -> None:
        holder_config_file = load_config(Path("annotation_renderer/configs/openconnect_general_holder_default.yaml"), [])

        with self.assertRaisesRegex(ConfigError, "must include render.animation"):
            apply_animation_preset(holder_config_file, "general_holder_model")

    def test_image_labels_use_selected_object_string_values(self) -> None:
        record = {
            "model_config": {"defines": {"shell_slot_position": "Left"}},
            "scad_value_context": {"shell_slot_position": "Back"},
        }

        labels = collect_image_labels(
            labels_config=[{"id": "shell_slot_position", "show_value": True}],
            annotation_config={},
            style_config={},
            expression_context={},
            value_context=label_value_context_for_record(record),
        )

        self.assertEqual(labels[0].label, "shell_slot_position = Back")
        self.assertEqual(labels[0].value_text, "Back")

    def test_image_labels_accept_label_font_size_alias(self) -> None:
        labels = collect_image_labels(
            labels_config=[{"id": "mode", "label_font_size_px": 33}],
            annotation_config={},
            style_config={},
            expression_context={},
            value_context={},
        )

        self.assertEqual(labels[0].font_size_px, 33)

    def test_explicit_annotation_color_overrides_type_style_for_dimensions(self) -> None:
        annotations = [
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=body_width|kind=dimension|label=body_width|axis=x|value=80|start=0,0,0|end=80,0,0|basis=test"'
            ),
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=body_depth|kind=dimension|label=body_depth|axis=y|value=40|start=0,0,0|end=0,40,0|basis=test"'
            ),
        ]

        chain = collect_dimension_chain(
            annotations=[annotation for annotation in annotations if annotation is not None],
            chain_config={"ids": ["body_width", "body_depth"]},
            style_config=resolve_style(
                {
                    "colors": {"body_width": "#123456"},
                    "type_styles": {"mm": {"line_colors": ["#0000ff"]}},
                }
            ),
        )

        self.assertEqual(chain[0].color, "#123456")
        self.assertEqual(chain[1].color, "#0000ff")

    def test_explicit_annotation_color_overrides_type_style_for_angle_radius_callouts(self) -> None:
        annotations = [
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=tip_radius|kind=radius|label=tip_radius|value=15|center=0,0,0|edge=15,0,0|basis=test"'
            ),
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=tip_radius_extent|kind=arc|label=tip_radius|value=90|points=15,0,0;10,10,0;0,15,0|basis=test"'
            ),
        ]

        callouts = collect_angle_radius_callouts(
            annotations=[annotation for annotation in annotations if annotation is not None],
            callout_config={
                "arc_id": "tip_radius_extent",
                "radius_id": "tip_radius",
                "angle_id": "tip_angle",
            },
            style_config=resolve_style(
                {
                    "colors": {
                        "tip_angle": "#123456",
                        "tip_radius": "#654321",
                    },
                    "type_styles": {
                        "angle": {"line_colors": ["#dc2626"]},
                        "radius": {"line_colors": ["#dc2626"]},
                    },
                }
            ),
        )

        self.assertEqual(callouts[0].arc_color, "#123456")
        self.assertEqual(callouts[0].radius_color, "#654321")

    def test_scad_value_context_keeps_string_values(self) -> None:
        annotation = parse_scad_annotation_line(
            'ECHO: "OPENGRID_ANNOTATION_V1|id=drawer_context|kind=context|values=shell_slot_position=Back;horizontal_grids=5;bad=undef"'
        )

        context = value_context_from_scad_annotations([annotation])

        self.assertEqual(context["shell_slot_position"], "Back")
        self.assertEqual(context["horizontal_grids"], "5")
        self.assertNotIn("bad", context)

    def test_model_defaults_import_per_model_variant_configs(self) -> None:
        config = load_config(Path("annotation_renderer/configs/model_defaults.yaml"), [])
        names = [variant["name"] for variant in selected_variants(config, None)]

        self.assertEqual(
            names,
            [
                "openconnect_sturdy_hook_default",
                "openconnect_sturdy_shelf_default",
                "openconnect_general_holder_default",
                "openconnect_vasemode_container_default",
                "openconnect_horizontal_holder_default",
                "openconnect_drawer_shell_default",
                "openconnect_drawer_shell_container_default",
                "openconnect_standard_snap_grid_copies",
                "opengrid_expanding_standard_snap_grid_copies",
            ],
        )

        holder_variant = selected_variants(config, "openconnect_general_holder_default")[0]
        holder_config = variant_config(config, holder_variant)
        self.assertEqual(self.first_model_config(holder_config)["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(holder_config["scene"]["transform"]["rotation_deg"], ["holder_tilt_angle", 0, 0])
        self.assertEqual(holder_config["render"]["camera_location_offset_mm"], [0, 0, 100])
        self.assertEqual(holder_config["render"]["camera_look_at"], "object_center")
        self.assertEqual(holder_config["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(holder_config["annotations"]["angle_radius_callouts"][0]["angle_id"], "holder_tilt_angle")
        self.assertEqual(
            [label["id"] for label in holder_config["annotations"]["image_labels"]],
            ["compartment_shape"],
        )

        vase_variant = selected_variants(config, "openconnect_vasemode_container_default")[0]
        vase_config = variant_config(config, vase_variant)
        self.assertEqual(self.first_model_config(vase_config)["scad_file"], "openconnect_vasemode_container.scad")
        self.assertEqual(vase_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])
        self.assertEqual(self.first_model_config(vase_config)["defines"]["label_holder_type"], "Standard")
        self.assertEqual(vase_config["annotations"]["chains"][0]["ids"], ["horizontal_grids"])
        self.assertEqual(vase_config["annotations"]["angle_radius_callouts"][0]["angle_id"], "vase_tilt_angle")
        self.assertEqual(
            [label["id"] for label in vase_config["annotations"]["image_labels"]],
            ["vase_surface_texture", "label_holder_type"],
        )

        hook_variant = selected_variants(config, "openconnect_sturdy_hook_default")[0]
        hook_config = variant_config(config, hook_variant)
        self.assertEqual(hook_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])
        self.assertEqual(
            hook_config["annotations"]["angle_radius_callouts"][0]["radius_id"],
            "circular_corner_radius",
        )

        shelf_variant = selected_variants(config, "openconnect_sturdy_shelf_default")[0]
        shelf_config = variant_config(config, shelf_variant)
        self.assertEqual(shelf_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])
        self.assertEqual(shelf_config["annotations"]["chains"][0]["ids"], ["depth_grids"])
        self.assertEqual(shelf_config["annotations"]["chains"][1]["ids"], ["horizontal_grids"])
        self.assertEqual(shelf_config["annotations"]["aliases"]["horizontal_grids"], "horizontal_grids x 28mm")

        horizontal_holder_variant = selected_variants(config, "openconnect_horizontal_holder_default")[0]
        horizontal_holder_config = variant_config(config, horizontal_holder_variant)
        self.assertEqual(self.first_model_config(horizontal_holder_config)["scad_file"], "openconnect_horizontal_holder.scad")
        horizontal_holder_objects = horizontal_holder_config["scene"]["objects"]
        self.assertEqual(horizontal_holder_objects[0]["model"]["scad_file"], "openconnect_horizontal_holder.scad")
        self.assertEqual(horizontal_holder_objects[0]["transform"]["rotation_deg"], [-90, 0, 0])
        self.assertEqual(
            horizontal_holder_objects[0]["transform"]["location_mm"],
            [0, "-(item_height / 2 + og_standard_thickness)", 0],
        )
        self.assertEqual(horizontal_holder_objects[1]["id"], "openconnect_standard_snap")
        self.assertEqual(horizontal_holder_objects[1]["stl_file"], "../assets/openconnect_standard_snap.stl")
        self.assertEqual(horizontal_holder_objects[1]["transform"]["rotation_deg"], [90, 0, 0])
        self.assertEqual(
            horizontal_holder_objects[1]["transform"]["location_mm"],
            ["-(og_tile_size / 2)", "og_standard_thickness", "-(og_tile_size / 2)"],
        )
        self.assertNotIn("camera_rotation_deg", horizontal_holder_config["render"])
        self.assertEqual(horizontal_holder_config["annotations"]["chains"][0]["ids"], ["item_width"])
        side_margin_chain_ids = [
            chain["ids"]
            for chain in horizontal_holder_config["annotations"]["chains"]
            if chain["ids"][0].startswith("side_opening_")
        ]
        self.assertEqual(
            side_margin_chain_ids,
            [
                ["side_opening_front_margin"],
                ["side_opening_back_margin"],
                ["side_opening_top_margin"],
                ["side_opening_bottom_margin"],
            ],
        )
        self.assertEqual(horizontal_holder_config["annotations"]["image_labels"][0]["id"], "holder_slot_position")

    def test_per_model_default_config_is_directly_renderable(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_general_holder_default.yaml"), [])

        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(config["job_name"], "general_holder_scene_default")
        self.assertEqual(config["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(config["annotations"]["angle_radius_callouts"][0]["angle_id"], "holder_tilt_angle")
        self.assertEqual(
            [label["id"] for label in config["annotations"]["image_labels"]],
            ["compartment_shape"],
        )

    def test_checked_in_defaults_are_yaml_only(self) -> None:
        config_dir = Path("annotation_renderer/configs")

        self.assertTrue((config_dir / "model_defaults.yaml").exists())
        self.assertFalse((config_dir / "model_defaults.json").exists())
        self.assertFalse(any(config_dir.glob("*.json")))

    def test_list_models_uses_default_model_config(self) -> None:
        output = self.run_cli("--list-models")

        self.assertIn("openconnect_general_holder_default", output)
        self.assertIn("annotation_renderer/configs/openconnect_general_holder_default.yaml", output)
        self.assertIn("model: openconnect_general_holder.scad", output)
        self.assertIn("openconnect_horizontal_holder_default", output)
        self.assertIn("model: openconnect_horizontal_holder.scad", output)
        self.assertIn("openconnect_vasemode_container_default", output)
        self.assertIn("model: openconnect_vasemode_container.scad", output)
        self.assertIn("openconnect_standard_snap_grid_copies", output)
        self.assertIn("openconnect_standard_snap: ../assets/openconnect_standard_snap.stl", output)
        self.assertIn("opengrid_expanding_standard_snap_grid_copies", output)
        self.assertIn("opengrid_expanding_standard_snap: ../assets/opengrid_expanding_standard_snap.stl", output)

    def test_simple_command_aliases_use_model_names(self) -> None:
        list_output = self.run_cli("list-models")
        description = self.run_cli("describe", "openconnect_general_holder")
        vase_description = self.run_cli("describe", "openconnect_vasemode_container")
        annotations = self.run_cli("list-annotations", "openconnect_general_holder")
        vase_annotations = self.run_cli("list-annotations", "openconnect_vasemode_container")
        discovery = self.run_cli("discover", "openconnect_general_holder.scad")
        doctor_args = parse_args_from(["doctor", "--smoke-render"])

        self.assertIn("openconnect_general_holder_default", list_output)
        self.assertIn("Source: annotation_renderer/configs/openconnect_general_holder_default.yaml", description)
        self.assertIn("Source: annotation_renderer/configs/openconnect_vasemode_container_default.yaml", vase_description)
        self.assertIn("dimension: compartment_width", annotations)
        self.assertIn("dimension: horizontal_grids", vase_annotations)
        self.assertIn("Available annotation parameters for openconnect_general_holder:", discovery)
        self.assertTrue(doctor_args.doctor)
        self.assertTrue(doctor_args.smoke_render)

    def test_render_shortcut_uses_scad_model_default_config(self) -> None:
        output = self.run_cli("render", "openconnect_general_holder", "--validate-only")

        self.assertIn("Config OK: annotation_renderer/configs/openconnect_general_holder_default.yaml", output)
        self.assertIn("Object:    model -> openconnect_general_holder.scad", output)
        self.assertEqual(
            default_config_for_model("openconnect_general_holder"),
            Path("annotation_renderer/configs/openconnect_general_holder_default.yaml").resolve(),
        )
        self.assertEqual(
            default_config_for_model("openconnect_vasemode_container"),
            Path("annotation_renderer/configs/openconnect_vasemode_container_default.yaml").resolve(),
        )

    def test_render_shortcut_accepts_named_config_files(self) -> None:
        output = self.run_cli("render", "openconnect_standard_snap_grid_copies", "--validate-only")

        self.assertIn("Config OK: annotation_renderer/configs/openconnect_standard_snap_grid_copies.yaml", output)
        self.assertIn("Object:    openconnect_standard_snap_0_0_0 -> annotation_renderer/assets/openconnect_standard_snap.stl", output)
        self.assertEqual(
            default_config_for_model("openconnect_standard_snap_grid_copies"),
            Path("annotation_renderer/configs/openconnect_standard_snap_grid_copies.yaml").resolve(),
        )
        self.assertEqual(
            default_config_for_model("openconnect_standard_snap_grid_copies.yaml"),
            Path("annotation_renderer/configs/openconnect_standard_snap_grid_copies.yaml").resolve(),
        )

    def test_set_override_supports_array_indexes(self) -> None:
        config = load_config(
            Path("annotation_renderer/configs/openconnect_general_holder_default.yaml"),
            ["annotations.chains[0].label_offset_px=36"],
        )

        self.assertEqual(config["annotations"]["chains"][0]["label_offset_px"], 36)

    def test_output_file_resolves_to_exact_still_image_path(self) -> None:
        args = parse_args_from(["render", "openconnect_general_holder", "--output-file", "build/final_holder.png"])

        self.assertEqual(output_file_from_args(args), Path("build/final_holder.png").resolve())

    def test_overlay_quality_warnings_report_label_overlaps(self) -> None:
        warnings = overlay_quality_warnings(
            {
                "chains": [
                    {
                        "text": {
                            "first": {"bbox_px": {"left": 0, "top": 0, "right": 30, "bottom": 30}},
                            "second": {"bbox_px": {"left": 10, "top": 10, "right": 40, "bottom": 40}},
                        }
                    }
                ],
                "image_labels": {
                    "title_area": {"bbox_px": {"left": 0, "top": 0, "right": 100, "bottom": 100}},
                },
            }
        )

        self.assertEqual(len(warnings), 1)
        self.assertIn("label overlap", warnings[0])

    def test_image_label_title_area_supports_top_and_bottom_positions(self) -> None:
        labels = [
            ImageLabel(
                id="top_label",
                label="top_label = Top",
                value_text="Top",
                position="top",
                offset_px=(0.0, 0.0),
                angle_deg=0.0,
                color=None,
                value_color="#2563eb",
                font_size_px=24,
            ),
            ImageLabel(
                id="bottom_label",
                label="bottom_label = Bottom",
                value_text="Bottom",
                position="bottom",
                offset_px=(0.0, 0.0),
                angle_deg=0.0,
                color=None,
                value_color="#2563eb",
                font_size_px=24,
            ),
        ]
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            render_path = tmp_path / "render.png"
            output_path = tmp_path / "annotated.png"
            Image.new("RGB", (500, 320), "#ffffff").save(render_path)

            metadata = draw_image_label_overlay(
                render_path=render_path,
                output_path=output_path,
                labels=labels,
                style_config={
                    "image_label_title_area": True,
                    "image_label_title_positions": ["top", "bottom"],
                    "image_label_margin_px": 20,
                    "image_label_title_padding_x_px": 12,
                    "image_label_title_padding_y_px": 8,
                    "image_label_title_radius_px": 6,
                    "image_label_title_outline_width_px": 1,
                    "image_label_title_min_width_px": 160,
                    "image_label_title_top_margin_px": 24,
                    "image_label_title_bottom_margin_px": 30,
                },
            )

        title_areas = metadata["title_areas"]
        top_bbox = title_areas["top"]["bbox_px"]
        bottom_bbox = title_areas["bottom"]["bbox_px"]
        self.assertGreaterEqual(top_bbox["top"], 24)
        self.assertLessEqual(bottom_bbox["bottom"], 320 - 30)
        self.assertEqual(metadata["title_area"], title_areas["bottom"])

    def test_annotation_bounds_audit_reports_far_outside_anchor_points(self) -> None:
        annotation = parse_scad_annotation_line(
            'ECHO: "OPENGRID_ANNOTATION_V1|id=depth_grids|kind=dimension|label=depth_grids|axis=y|value=56|start=10,10,10|end=10,-40,10|basis=test"'
        )
        self.assertIsNotNone(annotation)

        audit = audit_scad_annotation_bounds(
            [annotation],
            {
                "min": {"x": 0.0, "y": 0.0, "z": 0.0},
                "max": {"x": 20.0, "y": 20.0, "z": 20.0},
            },
            tolerance_mm=2.0,
        )

        self.assertEqual(len(audit["outliers"]), 1)
        self.assertEqual(audit["outliers"][0]["id"], "depth_grids")
        self.assertEqual(audit["outliers"][0]["field"], "end_mm")
        self.assertIn("depth_grids.end_mm", audit["warnings"][0])

    def test_annotation_bounds_quality_warnings_prefix_object_id(self) -> None:
        warnings = annotation_bounds_quality_warnings(
            [
                {
                    "id": "model",
                    "annotation_bounds_audit": {
                        "warnings": ["annotation anchor outside STL bounds: depth_grids.end_mm is 40.0mm outside"],
                    },
                }
            ]
        )

        self.assertEqual(warnings, ["object model: annotation anchor outside STL bounds: depth_grids.end_mm is 40.0mm outside"])

    def test_doctor_check_format_is_machine_scannable(self) -> None:
        self.assertEqual(format_doctor_check(True, "OpenSCAD", "C:/OpenSCAD/openscad.exe"), "[OK] OpenSCAD: C:/OpenSCAD/openscad.exe")
        self.assertEqual(format_doctor_check(False, "Blender", "missing"), "[FAIL] Blender: missing")

    def test_command_failure_message_includes_log_tail(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            log_path = Path(temp_dir) / "tool.log"
            log_path.write_text("\n".join(f"line {index}" for index in range(5)), encoding="utf-8")

            message = command_failure_message("Tool failed", log_path=log_path, line_count=2)

        self.assertIn("Tool failed", message)
        self.assertIn("Last 2 log lines", message)
        self.assertNotIn("line 2\n", message)
        self.assertIn("line 3\nline 4", message)

    def test_format_annotation_discovery_lists_available_parameters(self) -> None:
        annotations = [
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=hook_length|kind=dimension|label=hook_length|axis=x|value=45|start=0,0,0|end=45,0,0|basis=test"'
            ),
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=tip_radius|kind=radius|label=tip_radius|value=15|center=0,0,0|edge=15,0,0|basis=test"'
            ),
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=tip_radius_start|kind=feature|label=tip_radius_start|value=15|anchor=0,0,0|basis=debug_anchor"'
            ),
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=demo_context|kind=context|values=OG_TILE_SIZE=28;shell_thickness=2.4"'
            ),
        ]

        output = format_annotation_discovery(
            "demo",
            [
                {
                    "id": "model",
                    "annotations": [annotation for annotation in annotations if annotation is not None],
                    "log_path": Path("build/demo/openscad.log"),
                }
            ],
        )

        self.assertIn("Available annotation parameters for demo:", output)
        self.assertIn("  dimension parameters (add to annotations.chains[].ids):", output)
        self.assertIn("    - hook_length (axis=x, basis=test)", output)
        self.assertIn("  radius parameters (add to annotations.radius_callouts[].ids", output)
        self.assertIn("  context value parameters (add to annotations.image_labels[].id", output)
        self.assertIn("    - OG_TILE_SIZE", output)
        self.assertIn("    - shell_thickness", output)
        self.assertNotIn("value=45", output)
        self.assertNotIn("value=28", output)
        self.assertNotIn("tip_radius_start", output)
        self.assertNotIn("feature anchors", output)
        self.assertNotIn("suggested annotation config", output)

    def test_static_discovery_uses_source_without_evaluated_values(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            scad_path = Path(temp_dir) / "demo.scad"
            scad_path.write_text(
                """
                emit_context_values("demo_context", ["OG_TILE_SIZE", "shell_thickness"], [OG_TILE_SIZE, shell_thickness]);
                if (generate_drawer_shell) {
                  emit_dimension_annotation(
                    id="shell_width",
                    label="shell_width",
                    axis="x",
                    value=shell_width,
                    start=[0, 0, 0],
                    end=[shell_width, 0, 0],
                    basis="shell_width_basis"
                  );
                }
                if (mode == "Fancy") {
                  emit_dimension_annotation(
                    id="fancy_depth",
                    label="fancy_depth",
                    axis="z",
                    value=fancy_depth,
                    start=[0, 0, 0],
                    end=[0, 0, fancy_depth],
                    basis="conditional_fancy_depth"
                  );
                }
                if (add_front_edge) {
                  emit_dimension_annotation(
                    id="front_edge_depth",
                    label="front_edge_depth",
                    axis="x",
                    value=front_edge_depth,
                    start=[0, 0, 0],
                    end=[front_edge_depth, 0, 0],
                    basis="conditional_front_edge_depth"
                  );
                }
                """,
                encoding="utf-8",
            )

            annotations = discover_scad_source_annotations(scad_path, defines={"generate_drawer_shell": False, "add_front_edge": False})

        ids = {str(annotation["id"]) for annotation in annotations}
        self.assertIn("OG_TILE_SIZE", ids)
        self.assertIn("shell_thickness", ids)
        self.assertIn("fancy_depth", ids)
        self.assertIn("front_edge_depth", ids)
        self.assertNotIn("shell_width", ids)
        fancy = next(annotation for annotation in annotations if annotation["id"] == "fancy_depth")
        self.assertEqual(fancy["axis"], "z")
        self.assertEqual(fancy["basis"], "conditional_fancy_depth")
        self.assertEqual(fancy["conditions"], ["mode == \"Fancy\""])
        self.assertNotIn("value", fancy)
        front_edge = next(annotation for annotation in annotations if annotation["id"] == "front_edge_depth")
        self.assertEqual(front_edge["conditions"], ["add_front_edge"])

    def test_discover_annotations_targets_scad_file_without_config(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            scad_path = Path(temp_dir) / "demo.scad"
            scad_path.write_text(
                """
                emit_context_values("demo_context", ["OG_TILE_SIZE"], [OG_TILE_SIZE]);
                emit_feature_annotation(
                  id="debug_anchor",
                  label="debug_anchor",
                  value=span,
                  anchor=[0, 0, 0],
                  basis="debug_only"
                );
                emit_dimension_annotation(
                  id="span",
                  label="span",
                  axis="x",
                  value=span,
                  start=[0, 0, 0],
                  end=[span, 0, 0],
                  basis="span_basis"
                );
                """,
                encoding="utf-8",
            )

            output = self.run_cli("--discover-annotations", str(scad_path))

        self.assertIn("Available annotation parameters for demo:", output)
        self.assertIn("source:", output)
        self.assertIn("    - span (axis=x, basis=span_basis)", output)
        self.assertIn("    - OG_TILE_SIZE", output)
        self.assertNotIn("debug_anchor", output)
        self.assertNotIn("feature anchors", output)

    def test_discover_annotations_rejects_config_model_names(self) -> None:
        with self.assertRaisesRegex(SystemExit, "expects a \\.scad file path"):
            main(["--discover-annotations", "openconnect_drawer_shell_container_default"])

    def test_drawer_discovery_exposes_container_compartment_lists(self) -> None:
        output = self.run_cli("--discover-annotations", "openconnect_drawer.scad")

        self.assertIn("    - container_width_grid_count", output)
        self.assertIn("    - container_width_compartment_list", output)
        self.assertIn("    - container_depth_grid_count", output)
        self.assertIn("    - container_depth_compartment_list", output)

    def test_general_holder_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("--discover-annotations", "openconnect_general_holder.scad")

        self.assertIn("    - compartment_width (axis=x", output)
        self.assertIn("    - compartment_depth (axis=y", output)
        self.assertIn("    - holder_back_offset (axis=y", output)
        self.assertIn("    - compartment_bottom_width (axis=x", output)
        self.assertIn("    - compartment_bottom_depth (axis=y", output)
        self.assertIn("    - holder_vertical_divider_thickness (axis=x", output)
        self.assertIn("    - holder_horizontal_divider_thickness (axis=y", output)
        self.assertIn("    - compartment_height (axis=z", output)
        self.assertIn("    - holder_width_mode", output)
        self.assertNotIn("    - holder_height (axis=z", output)
        self.assertNotIn("    - holder_tilt_angle_radius", output)
        self.assertNotIn("    - holder_tilt_angle_extent", output)
        self.assertNotIn("    - holder_width (axis=", output)
        self.assertNotIn("    - holder_depth (axis=", output)
        self.assertNotIn("    - body_height (axis=", output)
        self.assertNotIn("    - body_width_mode", output)
        self.assertNotIn("final_body_depth", output)
        self.assertNotIn("final_body_height", output)

        annotations = discover_scad_source_annotations(Path("openconnect_general_holder.scad"), defines={})
        tilt_anchor = next(annotation for annotation in annotations if annotation["id"] == "holder_tilt_angle" and annotation["kind"] == "feature")
        self.assertEqual(tilt_anchor["basis"], "bottom_rear_side_corner_for_holder_tilt_angle")
        tilt_radius = next(annotation for annotation in annotations if annotation["id"] == "holder_tilt_angle_radius" and annotation["kind"] == "radius")
        self.assertEqual(tilt_radius["basis"], "bottom_holder_tilt_angle_anchor_to_tilt_wedge_midpoint")
        self.assertTrue(tilt_radius["internal"])
        tilt_arc = next(annotation for annotation in annotations if annotation["id"] == "holder_tilt_angle_extent" and annotation["kind"] == "arc")
        self.assertEqual(tilt_arc["basis"], "tilt_wedge_side_arc_for_holder_tilt_angle")
        self.assertTrue(tilt_arc["internal"])
        compartment_height = next(annotation for annotation in annotations if annotation["id"] == "compartment_height" and annotation["kind"] == "dimension")
        self.assertEqual(compartment_height["basis"], "usable_compartment_height_from_compartment_height")
        back_offset = next(annotation for annotation in annotations if annotation["id"] == "holder_back_offset" and annotation["kind"] == "dimension")
        self.assertEqual(back_offset["basis"], "extra_depth_added_by_holder_back_offset")
        bottom_width = next(annotation for annotation in annotations if annotation["id"] == "compartment_bottom_width" and annotation["kind"] == "dimension")
        self.assertEqual(bottom_width["basis"], "first_compartment_tapered_bottom_width")
        bottom_depth = next(annotation for annotation in annotations if annotation["id"] == "compartment_bottom_depth" and annotation["kind"] == "dimension")
        self.assertEqual(bottom_depth["basis"], "first_compartment_tapered_bottom_depth")
        vertical_divider = next(annotation for annotation in annotations if annotation["id"] == "holder_vertical_divider_thickness" and annotation["kind"] == "dimension")
        self.assertEqual(vertical_divider["basis"], "divider_between_first_two_compartment_columns")
        horizontal_divider = next(annotation for annotation in annotations if annotation["id"] == "holder_horizontal_divider_thickness" and annotation["kind"] == "dimension")
        self.assertEqual(horizontal_divider["basis"], "divider_between_first_two_compartment_rows")

    def test_horizontal_holder_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("--discover-annotations", "openconnect_horizontal_holder.scad")

        self.assertIn("    - item_width (axis=x", output)
        self.assertIn("    - item_height (axis=y", output)
        self.assertIn("    - item_depth (axis=z", output)
        self.assertIn("    - front_opening_width_margin (axis=x", output)
        self.assertIn("    - front_opening_height_margin (axis=y", output)
        self.assertIn("    - side_opening_front_margin (axis=y", output)
        self.assertIn("    - side_opening_back_margin (axis=y", output)
        self.assertIn("    - side_opening_top_margin (axis=z", output)
        self.assertIn("    - side_opening_bottom_margin (axis=z", output)
        self.assertIn("basis=side_opening_front_margin_to_visible_opening_edge", output)
        self.assertIn("basis=side_opening_top_margin_to_visible_opening_edge", output)
        self.assertIn("    - item_corner_rounding", output)
        self.assertIn("    - holder_slot_position", output)
        self.assertIn("    - slot_slide_direction", output)
        self.assertNotIn("    - og_standard_thickness", output)
        self.assertNotIn("    - item_corner_rounding_extent", output)
        self.assertNotIn("    - final_slot_h_grids", output)
        self.assertNotIn("    - final_slot_v_grids", output)
        self.assertNotIn("    - holder_width_edge", output)
        self.assertNotIn("    - holder_height_edge", output)
        self.assertNotIn("    - side_cutoff_front_offset", output)
        self.assertNotIn("    - holder_width (axis=", output)
        self.assertNotIn("    - holder_depth (axis=", output)

    def test_vasemode_container_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("--discover-annotations", "openconnect_vasemode_container.scad")

        self.assertIn("    - horizontal_grids (axis=x", output)
        self.assertIn("    - vertical_grids (axis=z", output)
        self.assertIn("    - depth_grids (axis=y", output)
        self.assertIn("    - ocvase_linewidth (axis=x", output)
        self.assertIn("    - label_width (axis=x", output)
        self.assertIn("when=label_holder_type != \"None\"", output)
        self.assertIn("    - vase_surface_texture", output)
        self.assertIn("    - label_holder_type", output)
        self.assertNotIn("    - vase_tilt_angle_radius", output)
        self.assertNotIn("    - vase_tilt_angle_extent", output)
        self.assertNotIn("    - vase_width (axis=", output)
        self.assertNotIn("    - vase_height (axis=", output)

        annotations = discover_scad_source_annotations(Path("openconnect_vasemode_container.scad"), defines={})
        tilt_radius = next(annotation for annotation in annotations if annotation["id"] == "vase_tilt_angle_radius")
        self.assertEqual(tilt_radius["basis"], "vase_tilt_angle_anchor_to_arc_midpoint")
        self.assertTrue(tilt_radius["internal"])
        label_width = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "label_width" and annotation["kind"] == "dimension"
        )
        self.assertEqual(label_width["conditions"], ['label_holder_type != "None"'])

    def test_sturdy_shelf_discovery_uses_grid_parameter_ids(self) -> None:
        output = self.run_cli("--discover-annotations", "openconnect_sturdy_shelf.scad")

        self.assertIn("    - horizontal_grids (axis=z", output)
        self.assertIn("    - depth_grids (axis=x", output)
        self.assertNotIn("    - shelf_width (axis=", output)
        self.assertNotIn("    - shelf_depth (axis=", output)

        annotations = discover_scad_source_annotations(Path("openconnect_sturdy_shelf.scad"), defines={})
        horizontal_grids = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "horizontal_grids" and annotation["kind"] == "dimension"
        )
        self.assertEqual(horizontal_grids["basis"], "left_to_right_width_from_horizontal_grids")

    def test_discovery_summary_json_is_compact_parameter_data(self) -> None:
        annotation = parse_scad_annotation_line(
            'ECHO: "OPENGRID_ANNOTATION_V1|id=hook_length|kind=dimension|label=hook_length|axis=x|value=45|start=0,0,0|end=45,0,0|basis=test"'
        )

        summary = discovery_summary_json(
            name="demo",
            object_discoveries=[
                {
                    "id": "model",
                    "annotations": [annotation],
                    "log_path": Path("build/demo/openscad.log"),
                    "stl_path": Path("build/demo/model.stl"),
                }
            ],
        )

        self.assertNotIn("paths", summary)
        self.assertNotIn("artifacts_kept", summary)
        self.assertNotIn("log", summary["objects"][0])
        self.assertNotIn("stl", summary["objects"][0])
        self.assertEqual(summary["objects"][0]["annotation_count"], 1)
        self.assertEqual(summary["objects"][0]["parameters"]["dimension"][0]["id"], "hook_length")
        self.assertNotIn("value", summary["objects"][0]["parameters"]["dimension"][0])

    def test_discovery_output_writes_requested_format_only(self) -> None:
        annotation = {"id": "hook_length", "kind": "dimension", "axis": "x", "basis": "outer_reach"}
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            text_path = temp_path / "annotations.txt"
            json_path = temp_path / "annotations.json"
            yaml_path = temp_path / "annotations.yaml"

            write_annotation_discovery_output(
                output_path=text_path,
                text_output="Available annotation parameters for demo:\n- object: model",
                name="demo",
                discoveries=[{"id": "model", "annotations": [annotation]}],
            )
            write_annotation_discovery_output(
                output_path=json_path,
                text_output="unused",
                name="demo",
                discoveries=[{"id": "model", "annotations": [annotation]}],
            )
            write_annotation_discovery_output(
                output_path=yaml_path,
                text_output="unused",
                name="demo",
                discoveries=[{"id": "model", "annotations": [annotation]}],
            )

            self.assertEqual(text_path.read_text(encoding="utf-8"), "Available annotation parameters for demo:\n- object: model\n")
            self.assertEqual(json.loads(json_path.read_text(encoding="utf-8"))["objects"][0]["parameters"]["dimension"][0]["id"], "hook_length")
            self.assertIn("name: demo", yaml_path.read_text(encoding="utf-8"))

    def test_describe_and_list_annotations_report_editable_settings(self) -> None:
        description = self.run_cli("--describe", "openconnect_general_holder_default")
        direct_description = self.run_cli(
            "--config",
            "annotation_renderer/configs/openconnect_general_holder_default.yaml",
            "--describe",
            "openconnect_general_holder_default",
        )
        annotations = self.run_cli("--list-annotations", "openconnect_general_holder_default")

        self.assertIn("compartment_shape: \"Rectangular\"", description)
        self.assertIn("Source: annotation_renderer/configs/openconnect_general_holder_default.yaml", direct_description)
        self.assertIn("camera_location_offset_mm: [0,0,100]", description)
        self.assertIn("camera_look_at: \"object_center\"", description)
        self.assertIn("dimension: compartment_width", annotations)
        self.assertIn("angle_radius: holder_tilt_angle_callout", annotations)
        self.assertNotIn("image_label: holder_tilt_angle", annotations)
        self.assertIn("line_offset_px=0", annotations)
        self.assertIn("label_offset_px=28", annotations)

    def test_sturdy_hook_default_exposes_circular_corner_radius_callout(self) -> None:
        annotations = self.run_cli("--list-annotations", "openconnect_sturdy_hook_default")

        self.assertIn("angle_radius: circular_corner_radius_detail", annotations)
        self.assertIn("radius_label_offset_px=26", annotations)

    def test_new_config_preserves_sturdy_hook_corner_radius_callout(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "sturdy_hook_custom.yaml"
            self.run_cli("new-config", "openconnect_sturdy_hook", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))

        callout = template["annotations"]["angle_radius_callouts"][0]
        self.assertEqual(callout["id"], "circular_corner_radius_detail")
        self.assertEqual(callout["arc_id"], "circular_corner_radius_extent")
        self.assertEqual(callout["radius_id"], "circular_corner_radius")
        self.assertTrue(callout["optional"])
        self.assertFalse(callout["show_angle_label"])
        self.assertEqual(callout["radius_label_offset_px"], 26)
        self.assertEqual(callout["angle_fill_alpha"], 28)

    def test_new_config_writes_valid_editable_template(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.json"
            output = self.run_cli("--new-config", "openconnect_general_holder_default", "--out", str(output_path))
            template = json.loads(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("openconnect_general_holder_default.yaml"))
        self.assertIn("scene", template)
        self.assertEqual(template["scene"]["objects"][0]["model"]["defines"]["compartment_shape"], "Rectangular")
        self.assertEqual(template["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(template["annotations"]["angle_radius_callouts"][0]["angle_id"], "holder_tilt_angle")
        self.assertEqual(
            [label["id"] for label in template["annotations"]["image_labels"]],
            ["compartment_shape"],
        )
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")

    def test_new_config_shortcut_accepts_model_stem(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.yaml"
            output = self.run_cli("new-config", "openconnect_general_holder", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("openconnect_general_holder_default.yaml"))
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")

    def test_yaml_config_extends_yaml_default(self) -> None:
        default_config = Path("annotation_renderer/configs/openconnect_general_holder_default.yaml").resolve().as_posix()
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
                        "  objects:",
                        "  - id: model",
                        "    model:",
                        "      scad_file: openconnect_general_holder.scad",
                        "      defines:",
                        "        compartment_column_count: 3",
                        "        custom_label: on",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            config = load_config(output_path, [])

        self.assertEqual(config["job_name"], "holder_yaml_custom")
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(self.first_model_config(config)["defines"]["compartment_column_count"], 3)
        self.assertEqual(self.first_model_config(config)["defines"]["custom_label"], "on")

    def test_json_config_can_extend_yaml_config(self) -> None:
        default_config = Path("annotation_renderer/configs/openconnect_general_holder_default.yaml").resolve().as_posix()
        scene_file = Path("annotation_renderer/assets/scenes/opengrid_wall_scene.blend").resolve().as_posix()
        with tempfile.TemporaryDirectory() as temp_dir:
            base_yaml_path = Path(temp_dir) / "holder_base.yaml"
            json_path = Path(temp_dir) / "holder_custom.json"
            base_yaml_path.write_text(
                "\n".join(
                    [
                        f"extends: {json.dumps(default_config)}",
                        "job_name: holder_yaml_base",
                        "constants:",
                        "  holder_yaml_model:",
                        "    scad_file: openconnect_general_holder.scad",
                        "    defines:",
                        "      compartment_column_count: 2",
                        "scene:",
                        f"  blend_file: {json.dumps(scene_file)}",
                        "  objects:",
                        "  - id: model",
                        "    model:",
                        "      $constant: holder_yaml_model",
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
                        "constants": {"holder_yaml_model": {"defines": {"compartment_row_count": 2}}},
                    }
                ),
                encoding="utf-8",
            )
            config = load_config(json_path, [])

        self.assertEqual(config["job_name"], "holder_json_extends_yaml")
        self.assertEqual(self.first_model_config(config)["defines"]["compartment_column_count"], 2)
        self.assertEqual(self.first_model_config(config)["defines"]["compartment_row_count"], 2)

    def test_new_config_writes_yaml_template_from_yaml_extension(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.yaml"
            output = self.run_cli("--new-config", "openconnect_general_holder_default", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("openconnect_general_holder_default.yaml"))
        self.assertIn("scene", template)
        self.assertEqual(template["scene"]["objects"][0]["model"]["defines"]["compartment_shape"], "Rectangular")
        self.assertEqual(template["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(template["annotations"]["angle_radius_callouts"][0]["angle_id"], "holder_tilt_angle")
        self.assertEqual(
            [label["id"] for label in template["annotations"]["image_labels"]],
            ["compartment_shape"],
        )
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")

    def test_gallery_config_can_be_yaml(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            gallery_path = Path(temp_dir) / "gallery.yaml"
            gallery_path.write_text(
                "columns: 3\n"
                "thumbnail_width: 480\n"
                "margin_px: 8\n"
                "gutter_px: 10\n"
                "title_height_px: 24\n"
                "title_font_size_px: 18\n",
                encoding="utf-8",
            )
            gallery_config, resolved_path = load_gallery_config(str(gallery_path), config_dir=Path.cwd())

        self.assertEqual(resolved_path, gallery_path.resolve())
        self.assertEqual(
            gallery_config,
            {
                "columns": 3,
                "thumbnail_width": 480,
                "margin_px": 8,
                "gutter_px": 10,
                "title_height_px": 24,
                "title_font_size_px": 18,
            },
        )
        settings = gallery_settings(
            {"gallery": {"thumbnail_width": 360, "gutter_px": 6}},
            gallery_config=gallery_config,
        )
        self.assertEqual(
            settings,
            {
                "columns": 3,
                "thumbnail_width": 360,
                "margin_px": 8,
                "gutter_px": 6,
                "title_height_px": 24,
                "title_font_size_px": 18,
            },
        )

    def test_gallery_contact_sheet_uses_layout_settings(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            image_a = temp_path / "a.png"
            image_b = temp_path / "b.png"
            output_path = temp_path / "gallery.png"
            Image.new("RGB", (20, 10), (255, 0, 0)).save(image_a)
            Image.new("RGB", (20, 10), (0, 0, 255)).save(image_b)

            build_gallery_contact_sheet(
                results=[
                    {"variant_name": "a", "annotated": image_a},
                    {"variant_name": "b", "annotated": image_b},
                ],
                output_path=output_path,
                columns=2,
                thumbnail_width=40,
                margin_px=3,
                gutter_px=5,
                title_height_px=7,
                title_font_size_px=6,
            )
            with Image.open(output_path) as gallery:
                self.assertEqual(gallery.size, (91, 23))

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
        args = parse_args_from(["--output-mode", "minimal"])

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
                "material_overrides": {"model": {"color": "#ff0000", "alpha": 0.5}},
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
        self.assertEqual(blender_config["objects"][0]["material"], {"roughness": 0.4, "color": "#ff0000", "alpha": 0.5})

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
        self.assertEqual(preset_config["camera_distance_scale"], 1.15)

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
        self.assertIn("outline", render_properties)
        self.assertIn("ground_plane", render_properties)
        self.assertIn("cutaway", render_properties)
        cutaway_properties = schema["$defs"]["cutawayConfig"]["anyOf"][1]["properties"]
        self.assertIn("position_fraction", cutaway_properties)
        self.assertIn("section_plane", cutaway_properties)
        self.assertIn("xray", render_properties)
        self.assertIn("material_overrides", render_properties)
        self.assertEqual(render_properties["output_mode"]["enum"], ["minimal", "standard", "debug"])
        self.assertIn("auto_adjust_labels", style_properties)
        self.assertIn("font_size_px", style_properties)
        self.assertIn("font_size_px", annotation_group_properties)
        self.assertIn("label_along_offset_px", annotation_group_properties)
        self.assertIn("font_size_px", angle_radius_properties)
        self.assertIn("label_font_size_px", image_label_properties)
        self.assertIn("cache", render_properties)
        self.assertIn("cache_dir", render_properties)
        self.assertIn("export_blend", render_properties)
        self.assertIn("variant_name", schema["properties"])
        self.assertIn("variant_configs", schema["properties"])
        self.assertNotIn("animation", scene_default_properties)
        self.assertNotIn("animation", scene_object_properties)
        self.assertNotIn("line_copies", scene_default_properties)
        self.assertIn("line_copies", scene_object_properties)
        self.assertIn("grid_copies", scene_object_properties)

    def test_pyproject_declares_test_extra(self) -> None:
        pyproject = Path("pyproject.toml").read_text(encoding="utf-8")

        self.assertIn("test = [", pyproject)
        self.assertIn('"pytest>=9"', pyproject)
        self.assertIn('"PyYAML>=6.0"', pyproject)
        self.assertIn('"assets/*.stl"', pyproject)
        self.assertIn('"configs/*.yaml"', pyproject)
        self.assertIn('"configs/*.yml"', pyproject)
        self.assertNotIn('"configs/*.json"', pyproject)


if __name__ == "__main__":
    unittest.main()
