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
from annotation_renderer.config import ConfigError, DimensionSegment, resolve_render, validate_config_shape
from annotation_renderer.overlay import DimensionChainOverlaySpec, draw_dimension_chains_overlay
from annotation_renderer.scad_annotations import parse_scad_annotation_line
from annotation_renderer.scene_cli import (
    command_failure_message,
    discover_scad_source_annotations,
    discovery_summary_json,
    format_annotation_discovery,
    format_doctor_check,
    apply_animation_preset,
    load_config,
    load_gallery_config,
    main,
    output_mode_for,
    parse_args_from,
    scad_output_folder_name,
    selected_variants,
    variant_config,
    write_annotation_discovery_output,
)


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
        holder_config_file = load_config(Path("annotation_renderer/configs/general_holder_default.yaml"), [])
        holder_config = apply_animation_preset(holder_config_file, "openconnect_insert_animation_render")
        self.assertEqual(holder_config["model"]["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(holder_config["scene"]["transform"]["rotation_deg"], [0, 0, 0])
        self.assertEqual(holder_config["render"]["camera_look_at"], "object_center")
        self.assertEqual(holder_config["render"]["animation"]["object_animations"][0]["object"], "model")
        self.assertEqual(holder_config["annotations"], {})

        shelf_config_file = load_config(Path("annotation_renderer/configs/sturdy_shelf_default.yaml"), [])
        shelf_config = apply_animation_preset(shelf_config_file, "openconnect_insert_animation_render")
        self.assertEqual(shelf_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])

        drawer_config_file = load_config(Path("annotation_renderer/configs/drawer_shell_container_default.yaml"), [])
        drawer_config = apply_animation_preset(drawer_config_file, "drawer_install_then_slide_animation_render")
        animation = drawer_config["render"]["animation"]
        self.assertEqual(animation["clips"][0]["object_animations"][0]["object"], "drawer_shell")
        self.assertEqual(animation["clips"][1]["object_animations"][0]["opacity_keyframes"][1], {"frame": 8, "value": 1})

    def test_animation_preset_shortcut_rejects_non_animation_constants(self) -> None:
        holder_config_file = load_config(Path("annotation_renderer/configs/general_holder_default.yaml"), [])

        with self.assertRaisesRegex(ConfigError, "must include render.animation"):
            apply_animation_preset(holder_config_file, "general_holder_model")

    def test_model_defaults_import_per_model_variant_configs(self) -> None:
        config = load_config(Path("annotation_renderer/configs/model_defaults.yaml"), [])
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
        self.assertEqual(holder_config["render"]["camera_location_offset_mm"], [0, 0, 100])
        self.assertEqual(holder_config["render"]["camera_look_at"], "object_center")
        self.assertEqual(holder_config["annotations"]["chains"][0]["ids"], ["compartment_width"])

        hook_variant = selected_variants(config, "sturdy_hook_default")[0]
        hook_config = variant_config(config, hook_variant)
        self.assertEqual(hook_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])

        shelf_variant = selected_variants(config, "sturdy_shelf_default")[0]
        shelf_config = variant_config(config, shelf_variant)
        self.assertEqual(shelf_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])

    def test_per_model_default_config_is_directly_renderable(self) -> None:
        config = load_config(Path("annotation_renderer/configs/general_holder_default.yaml"), [])

        self.assertEqual(config["model"]["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(config["job_name"], "general_holder_scene_default")
        self.assertEqual(config["annotations"]["chains"][0]["ids"], ["compartment_width"])

    def test_checked_in_defaults_are_yaml_only(self) -> None:
        config_dir = Path("annotation_renderer/configs")

        self.assertTrue((config_dir / "model_defaults.yaml").exists())
        self.assertFalse((config_dir / "model_defaults.json").exists())
        self.assertFalse(any(config_dir.glob("*.json")))

    def test_list_models_uses_default_model_config(self) -> None:
        output = self.run_cli("--list-models")

        self.assertIn("general_holder_default", output)
        self.assertIn("annotation_renderer/configs/general_holder_default.yaml", output)
        self.assertIn("model: openconnect_general_holder.scad", output)

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
            main(["--discover-annotations", "drawer_shell_container_default"])

    def test_general_holder_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("--discover-annotations", "openconnect_general_holder.scad")

        self.assertIn("    - compartment_width (axis=x", output)
        self.assertIn("    - compartment_depth (axis=y", output)
        self.assertIn("    - body_height (axis=z", output)
        self.assertNotIn("    - holder_width", output)
        self.assertNotIn("    - holder_depth", output)
        self.assertNotIn("    - holder_height", output)
        self.assertNotIn("body_width\n", output)
        self.assertNotIn("final_body_depth", output)
        self.assertNotIn("final_body_height", output)

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
        description = self.run_cli("--describe", "general_holder_default")
        direct_description = self.run_cli(
            "--config",
            "annotation_renderer/configs/general_holder_default.yaml",
            "--describe",
            "general_holder_default",
        )
        annotations = self.run_cli("--list-annotations", "general_holder_default")

        self.assertIn("compartment_shape: \"Rectangular\"", description)
        self.assertIn("Source: annotation_renderer/configs/general_holder_default.yaml", direct_description)
        self.assertIn("camera_location_offset_mm: [0,0,100]", description)
        self.assertIn("camera_look_at: \"object_center\"", description)
        self.assertIn("dimension: compartment_width", annotations)
        self.assertIn("line_offset_px=0", annotations)
        self.assertIn("label_offset_px=28", annotations)

    def test_new_config_writes_valid_editable_template(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.json"
            output = self.run_cli("--new-config", "general_holder_default", "--out", str(output_path))
            template = json.loads(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("general_holder_default.yaml"))
        self.assertIn("scene", template)
        self.assertEqual(template["model"]["defines"]["compartment_shape"], "Rectangular")
        self.assertEqual(template["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(config["model"]["scad_file"], "openconnect_general_holder.scad")

    def test_yaml_config_extends_yaml_default(self) -> None:
        default_config = Path("annotation_renderer/configs/general_holder_default.yaml").resolve().as_posix()
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
        default_config = Path("annotation_renderer/configs/general_holder_default.yaml").resolve().as_posix()
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
        self.assertTrue(template["extends"].endswith("general_holder_default.yaml"))
        self.assertIn("scene", template)
        self.assertEqual(template["model"]["defines"]["compartment_shape"], "Rectangular")
        self.assertEqual(template["annotations"]["chains"][0]["ids"], ["compartment_width"])
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

    def test_render_output_mode_is_validated_and_cli_overrides_config(self) -> None:
        render = resolve_render({"preset": "cycles_standard_scene", "output_mode": "debug"})
        args = parse_args_from(["--output-mode", "minimal"])

        self.assertEqual(render["output_mode"], "debug")
        self.assertEqual(output_mode_for({}, argparse.Namespace(output_mode=None)), "standard")
        self.assertEqual(output_mode_for(render, argparse.Namespace(output_mode=None)), "debug")
        self.assertEqual(output_mode_for(render, args), "minimal")
        with self.assertRaisesRegex(ConfigError, "render.output_mode must be one of debug, minimal, standard"):
            resolve_render({"preset": "cycles_standard_scene", "output_mode": "everything"})

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
            "model": {"scad_file": "demo.scad"},
            "scene": {"blend_file": "demo.blend", "target_object": "model"},
            "annotations": {},
        }

        invalid_style = dict(base_config)
        invalid_style["annotations"] = {"style": {"label_font_size_px": "large"}}
        with self.assertRaisesRegex(ConfigError, "annotations.style.label_font_size_px must be an integer"):
            validate_config_shape(invalid_style)

        invalid_group = dict(base_config)
        invalid_group["annotations"] = {"chains": [{"ids": ["span"], "label_font_size_px": 0}]}
        with self.assertRaisesRegex(ConfigError, "annotations.chains\\[0\\].label_font_size_px must be at least 1"):
            validate_config_shape(invalid_group)

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
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            render_path = temp_path / "render.png"
            output_path = temp_path / "annotated.png"
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

        self.assertEqual(metadata[0]["text"]["first"]["color"], "#111111")
        self.assertEqual(metadata[1]["text"]["second"]["color"], "#222222")

    def test_schema_places_animation_under_render_config(self) -> None:
        schema_path = Path("annotation_renderer") / "schemas" / "annotation-render-config.schema.json"
        schema = json.loads(schema_path.read_text(encoding="utf-8"))

        render_properties = schema["$defs"]["renderConfig"]["anyOf"][1]["properties"]
        variant_properties = schema["properties"]["variants"]["items"]["properties"]
        scene_default_properties = schema["$defs"]["sceneObjectDefaults"]["anyOf"][0]["properties"]
        scene_object_properties = schema["$defs"]["sceneObject"]["anyOf"][0]["properties"]
        self.assertIn("animation", render_properties)
        self.assertIn("extends_variant", variant_properties)
        self.assertEqual(render_properties["camera_look_at"]["enum"], ["none", "object_center"])
        self.assertEqual(render_properties["output_mode"]["enum"], ["minimal", "standard", "debug"])
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
        self.assertNotIn('"configs/*.json"', pyproject)


if __name__ == "__main__":
    unittest.main()
