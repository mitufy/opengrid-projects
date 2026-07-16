from __future__ import annotations

import json
import tempfile
from pathlib import Path
from PIL import Image
import yaml
from annotation_renderer.config.schema import ConfigError
from annotation_renderer.config.loader import load_config, load_gallery_config
from annotation_renderer.gallery import (
    apply_gallery_target_render_size,
    build_gallery_contact_sheet,
    configured_gallery_variant_collection,
    gallery_settings,
)
from annotation_renderer.scad_annotations import parse_scad_annotation_line
from annotation_renderer.cli import main
from annotation_renderer.scad_discovery import (
    discover_scad_source_annotations,
    discovery_summary_json,
    format_annotation_discovery,
    write_annotation_discovery_output,
)
from tests.renderer_test_case import RendererTestCase


class DiscoveryAndGalleryTests(RendererTestCase):
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

            output = self.run_cli("discover", str(scad_path))

        self.assertIn("Available annotation parameters for demo:", output)
        self.assertIn("source:", output)
        self.assertIn("    - span (axis=x, basis=span_basis)", output)
        self.assertIn("    - OG_TILE_SIZE", output)
        self.assertNotIn("debug_anchor", output)
        self.assertNotIn("feature anchors", output)

    def test_discover_annotations_rejects_config_model_names(self) -> None:
        with self.assertRaisesRegex(SystemExit, "expects a \\.scad file path"):
            main(["discover", "openconnect_drawer_shell_container"])

    def test_drawer_discovery_exposes_container_compartment_lists(self) -> None:
        output = self.run_cli("discover", "openconnect_drawer.scad")

        self.assertIn("    - container_width_grid_count", output)
        self.assertIn("    - container_width_compartment_list", output)
        self.assertIn("    - container_depth_grid_count", output)
        self.assertIn("    - container_depth_compartment_list", output)

    def test_general_holder_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("discover", "openconnect_general_holder.scad")

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

    def test_clamshell_holder_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("discover", "openconnect_clamshell_holder.scad")

        self.assertIn("    - item_width (axis=x", output)
        self.assertIn("    - item_height (axis=z", output)
        self.assertIn("    - item_depth (axis=y", output)
        self.assertIn("    - front_opening_left_right_margin (axis=x", output)
        self.assertIn("    - front_opening_top_bottom_margin (axis=z", output)
        self.assertIn("    - side_cutout_top_margin (axis=z", output)
        self.assertIn("    - side_cutout_bottom_margin (axis=z", output)
        self.assertIn("    - side_cutout_back_margin (axis=y", output)
        self.assertIn("    - side_cutout_front_margin (axis=y", output)
        self.assertIn("basis=side_cutout_top_margin_to_visible_cutout_edge", output)
        self.assertIn("basis=side_cutout_back_margin_to_visible_cutout_edge", output)
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
        output = self.run_cli("discover", "openconnect_vasemode_container.scad")

        self.assertIn("    - horizontal_grids (axis=x", output)
        self.assertIn("    - vertical_grids (axis=z", output)
        self.assertIn("    - depth_grids (axis=y", output)
        self.assertIn("    - vase_linewidth (axis=x", output)
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

    def test_parametric_snap_discovery_exposes_openconnect_head_anchors(self) -> None:
        output = self.run_cli("discover", "opengrid_parametric_snap.scad")

        self.assertIn("    - ochead_bottom_height (axis=z", output)
        self.assertIn("    - ochead_large_rect_width (axis=x", output)
        self.assertIn("    - ochead_nub_to_top_distance (axis=y", output)
        self.assertIn("    - ochead_nub_fillet", output)
        self.assertNotIn("    - OCSLOT_MOVE_DISTANCE", output)

        annotations = discover_scad_source_annotations(Path("opengrid_parametric_snap.scad"), defines={})
        slot_move = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "OCSLOT_MOVE_DISTANCE" and annotation["kind"] == "dimension"
        )
        slot_clearance = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "OCSLOT_ONRAMP_CLEARANCE" and annotation["kind"] == "dimension"
        )
        total_height = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "OCHEAD_TOTAL_HEIGHT" and annotation["kind"] == "dimension"
        )

        self.assertEqual(slot_move["kind"], "dimension")
        self.assertEqual(slot_move["basis"], "openconnect_slot_slide_distance_default_reference")
        self.assertTrue(slot_move["internal"])
        self.assertEqual(slot_clearance["axis"], "x")
        self.assertTrue(slot_clearance["internal"])
        self.assertEqual(total_height["axis"], "z")
        self.assertTrue(total_height["internal"])

    def test_openconnect_plate_discovery_exposes_slot_anchors(self) -> None:
        output = self.run_cli("discover", "openconnect_plate.scad")

        self.assertIn("    - slot_side_clearance (axis=x", output)
        self.assertIn("    - slot_depth_clearance (axis=z", output)
        self.assertNotIn("    - slot_large_rect_width", output)

        annotations = discover_scad_source_annotations(Path("openconnect_plate.scad"), defines={})
        slot_width = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "slot_large_rect_width" and annotation["kind"] == "dimension"
        )
        slot_depth = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "slot_total_height" and annotation["kind"] == "dimension"
        )
        slot_move = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "OCSLOT_MOVE_DISTANCE" and annotation["kind"] == "dimension"
        )

        self.assertEqual(slot_width["axis"], "x")
        self.assertTrue(slot_width["internal"])
        self.assertEqual(slot_depth["basis"], "openconnect_plate_slot_total_cut_depth")
        self.assertTrue(slot_depth["internal"])
        self.assertEqual(slot_move["basis"], "openconnect_plate_slot_slide_distance_default_reference")
        self.assertTrue(slot_move["internal"])

    def test_sturdy_shelf_discovery_uses_grid_parameter_ids(self) -> None:
        output = self.run_cli("discover", "openconnect_sturdy_shelf.scad")

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

    def test_gridfinity_shelf_discovery_uses_customizer_parameter_ids(self) -> None:
        output = self.run_cli("discover", "openconnect_gridfinity_shelf.scad")

        self.assertIn("    - gridfinity_width_grids (axis=x", output)
        self.assertIn("    - gridfinity_depth_grids (axis=y", output)
        self.assertIn("    - shelf_back_offset (axis=y", output)
        self.assertIn("    - shelf_side_rim (axis=x", output)
        self.assertIn("    - shelf_front_rim (axis=y", output)
        self.assertIn("    - shelf_rim_lip_height (axis=z", output)
        self.assertIn("    - magnet_position", output)
        self.assertIn("    - gridfinity_socket_clearance", output)
        self.assertNotIn("    - shelf_width (axis=", output)
        self.assertNotIn("    - final_shelf_bottom_tilt_height", output)

        annotations = discover_scad_source_annotations(Path("openconnect_gridfinity_shelf.scad"), defines={})
        width_grids = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "gridfinity_width_grids" and annotation["kind"] == "dimension"
        )
        self.assertEqual(width_grids["basis"], "gridfinity_cell_width_span_from_grid_count")
        back_offset = next(
            annotation
            for annotation in annotations
            if annotation["id"] == "shelf_back_offset" and annotation["kind"] == "dimension"
        )
        self.assertEqual(back_offset["basis"], "back_space_between_gridfinity_cells_and_wall_from_shelf_back_offset")
        bottom_tilt = next(annotation for annotation in annotations if annotation["id"] == "final_shelf_bottom_tilt_height")
        self.assertTrue(bottom_tilt["internal"])

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
        description = self.run_cli("describe", "openconnect_general_holder")
        direct_description = self.run_cli(
            "describe",
            "annotation_renderer/configs/openconnect_general_holder.yaml",
        )
        annotations = self.run_cli("annotations", "openconnect_general_holder")

        self.assertIn("compartment_shape: \"Circular\"", description)
        self.assertIn("Source: annotation_renderer/configs/openconnect_general_holder.yaml", direct_description)
        self.assertIn("dimension: compartment_width", annotations)
        self.assertIn("angle_radius: holder_tilt_angle_callout", annotations)
        self.assertNotIn("image_label: holder_tilt_angle", annotations)
        self.assertIn("line_offset_px=-20", annotations)
        self.assertIn("label_offset_px=-50", annotations)

    def test_sturdy_hook_side_exposes_hook_corner_fillet_callout(self) -> None:
        annotations = self.run_cli(
            "annotations",
            "annotation_renderer/configs/openconnect_sturdy_hook.yaml",
            "--variant",
            "side",
        )

        self.assertIn("angle_radius: hook_corner_fillet_detail", annotations)
        self.assertIn("radius_label_offset_px=50", annotations)

    def test_new_config_preserves_sturdy_hook_corner_fillet_define(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "sturdy_hook_custom.yaml"
            self.run_cli("new-config", "openconnect_sturdy_hook", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))

        defines = template["scene"]["objects"][0]["model"]["defines"]
        self.assertEqual(defines["hook_corner_fillet"], 28)
        self.assertEqual(
            sorted(defines),
            ["circular_tip_radius", "hook_corner_fillet", "hook_length", "hook_vertical_grids"],
        )

    def test_new_config_writes_valid_editable_template(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.json"
            output = self.run_cli("new-config", "openconnect_general_holder", "--out", str(output_path))
            template = json.loads(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("openconnect_general_holder.yaml"))
        self.assertIn("scene", template)
        self.assertEqual(template["scene"]["objects"][0]["model"]["defines"]["compartment_shape"], "Circular")
        self.assertEqual(
            template["annotations"]["chains"]["compartment_width_dimension"]["id"],
            "compartment_width",
        )
        self.assertEqual(
            template["annotations"]["angle_radius_callouts"]["holder_tilt_angle_callout"]["angle_id"],
            "holder_tilt_angle",
        )
        self.assertNotIn("image_labels", template["annotations"])
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")

    def test_new_config_shortcut_accepts_model_stem(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "holder_custom.yaml"
            output = self.run_cli("new-config", "openconnect_general_holder", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("openconnect_general_holder.yaml"))
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")

    def test_yaml_config_extends_yaml_default(self) -> None:
        default_config = Path("annotation_renderer/configs/openconnect_general_holder.yaml").resolve().as_posix()
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
        default_config = Path("annotation_renderer/configs/openconnect_general_holder.yaml").resolve().as_posix()
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
            output = self.run_cli("new-config", "openconnect_general_holder", "--out", str(output_path))
            template = yaml.safe_load(output_path.read_text(encoding="utf-8"))
            config = load_config(output_path, [])

        self.assertIn("Wrote:", output)
        self.assertTrue(template["extends"].endswith("openconnect_general_holder.yaml"))
        self.assertIn("scene", template)
        self.assertEqual(template["scene"]["objects"][0]["model"]["defines"]["compartment_shape"], "Circular")
        self.assertEqual(
            template["annotations"]["chains"]["compartment_width_dimension"]["id"],
            "compartment_width",
        )
        self.assertEqual(
            template["annotations"]["angle_radius_callouts"]["holder_tilt_angle_callout"]["angle_id"],
            "holder_tilt_angle",
        )
        self.assertNotIn("image_labels", template["annotations"])
        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")

    def test_gallery_config_can_be_yaml(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            gallery_path = Path(temp_dir) / "gallery.yaml"
            gallery_path.write_text(
                "columns: 3\n"
                "thumbnail_width: 480\n"
                "variant_collection: external_views\n"
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
                "variant_collection": "external_views",
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
        self.assertEqual(
            configured_gallery_variant_collection({}, gallery_config=gallery_config),
            "external_views",
        )
        self.assertEqual(
            configured_gallery_variant_collection(
                {"gallery": {"variant_collection": "model_views"}},
                gallery_config=gallery_config,
            ),
            "model_views",
        )

    def test_gallery_target_size_derives_thumbnail_and_render_size(self) -> None:
        settings = gallery_settings(
            {
                "gallery": {
                    "columns": 2,
                    "target_width_px": 1920,
                    "target_height_px": 1440,
                    "margin_px": 0,
                    "gutter_px": 4,
                    "title_height_px": 45,
                }
            },
            variant_count=4,
        )

        self.assertEqual(settings["thumbnail_width"], 958)
        self.assertEqual(settings["thumbnail_height"], 673)
        self.assertEqual(settings["render_width"], 958)
        self.assertEqual(settings["render_height"], 673)
        resolved = apply_gallery_target_render_size(
            {
                "render": {"width": 1920, "height": 1440},
                "annotations": {
                    "style": {"label_font_size_px": 60, "line_width_px": 5.0},
                    "chains": [{"label_offset_px": -30, "display_offset_mm": [1, 2, 3]}],
                    "image_labels": [{"offset_px": [10, -10]}],
                },
            },
            settings,
        )
        self.assertEqual(resolved["render"]["width"], 897)
        self.assertEqual(resolved["render"]["height"], 673)
        self.assertEqual(resolved["annotations"]["style"]["label_font_size_px"], 28)
        self.assertAlmostEqual(resolved["annotations"]["style"]["line_width_px"], 2.34, places=2)
        self.assertEqual(resolved["annotations"]["chains"][0]["label_offset_px"], -14)
        self.assertEqual(resolved["annotations"]["chains"][0]["display_offset_mm"], [1, 2, 3])
        self.assertEqual(resolved["annotations"]["image_labels"][0]["offset_px"], [5, -5])

    def test_gallery_target_size_rounds_cells_down_for_non_divisible_layout(self) -> None:
        settings = gallery_settings(
            {
                "gallery": {
                    "columns": 2,
                    "target_width_px": 1919,
                    "target_height_px": 1440,
                }
            },
            variant_count=4,
        )

        self.assertEqual(settings["thumbnail_width"], 941)
        self.assertEqual(settings["thumbnail_height"], 680)

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

    def test_gallery_contact_sheet_can_use_fixed_thumbnail_height(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            image_a = temp_path / "a.png"
            image_b = temp_path / "b.png"
            output_path = temp_path / "gallery.png"
            Image.new("RGB", (40, 30), (255, 0, 0)).save(image_a)
            Image.new("RGB", (40, 30), (0, 0, 255)).save(image_b)

            build_gallery_contact_sheet(
                results=[
                    {"variant_name": "a", "annotated": image_a},
                    {"variant_name": "b", "annotated": image_b},
                ],
                output_path=output_path,
                columns=2,
                thumbnail_width=40,
                thumbnail_height=30,
                margin_px=3,
                gutter_px=5,
                title_height_px=7,
                title_font_size_px=6,
                target_width_px=93,
                target_height_px=45,
            )
            with Image.open(output_path) as gallery:
                self.assertEqual(gallery.size, (93, 45))
