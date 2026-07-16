from __future__ import annotations

import json
import tempfile
from pathlib import Path
from PIL import Image
import yaml
from annotation_renderer.annotation_config import ImageLabel
from annotation_renderer.config.resolution import aliases_from_config
from annotation_renderer.config.loader import (
    load_config,
    selected_variant_collection,
    selected_variants,
    variant_config,
)
from annotation_renderer.catalog import default_config_for_model
from annotation_renderer.diagnostics import command_failure_message, format_doctor_check
from annotation_renderer.metadata import (
    annotation_bounds_quality_warnings,
    overlay_quality_warnings,
)
from annotation_renderer.overlay import draw_image_label_overlay
from annotation_renderer.scad_annotations import parse_scad_annotation_line
from annotation_renderer.cli import parse_args_from
from annotation_renderer.pipeline import (
    angle_radius_items_from_config,
    audit_scad_annotation_bounds,
    chain_items_from_config,
    image_label_items_from_config,
    output_file_from_args,
)
from tests.renderer_test_case import RendererTestCase


class ConfigAndCliTests(RendererTestCase):
    def test_model_defaults_import_per_model_variant_configs(self) -> None:
        config = load_config(Path("annotation_renderer/configs/model_defaults.yaml"), [])
        names = [variant["name"] for variant in selected_variants(config, None)]

        self.assertEqual(
            names,
            [
                "openconnect_sturdy_hook",
                "openconnect_sturdy_shelf",
                "openconnect_gridfinity_shelf",
                "openconnect_general_holder",
                "openconnect_vasemode_container",
                "openconnect_clamshell_holder",
                "openconnect_drawer_shell",
                "openconnect_drawer_shell_container",
                "openconnect_standard_snap_grid_copies",
                "opengrid_expanding_standard_snap_grid_copies",
                "opengrid_framefit_hook",
                "opengrid_snap_gadget_hook",
                "opengrid_snap_gadget_clip",
                "opengrid_snap_gadget_plier_holder",
            ],
        )

        holder_variant = selected_variants(config, "openconnect_general_holder")[0]
        holder_config = variant_config(config, holder_variant)
        self.assertEqual(self.first_model_config(holder_config)["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual([obj["id"] for obj in holder_config["scene"]["objects"]], ["model_b", "model_a"])
        self.assertEqual(holder_config["scene"]["objects"][0]["transform"]["rotation_deg"], ["holder_tilt_angle", 0, 0])
        self.assertEqual(holder_config["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(holder_config["annotations"]["angle_radius_callouts"][0]["angle_id"], "holder_tilt_angle")
        self.assertEqual(image_label_items_from_config(holder_config["annotations"]), [])

        vase_variant = selected_variants(config, "openconnect_vasemode_container")[0]
        vase_config = variant_config(config, vase_variant)
        self.assertEqual(self.first_model_config(vase_config)["scad_file"], "openconnect_vasemode_container.scad")
        self.assertEqual(vase_config["scene"]["transform"]["rotation_deg"], ["vase_tilt_angle", 0, 0])
        self.assertEqual(self.first_model_config(vase_config)["defines"]["label_holder_type"], "Standard")
        self.assertEqual(vase_config["annotations"]["chains"][0]["ids"], ["horizontal_grids"])
        self.assertEqual(angle_radius_items_from_config(vase_config["annotations"]), [])
        self.assertEqual(
            [label["id"] for label in vase_config["annotations"]["image_labels"]],
            ["vase_surface_texture"],
        )

        hook_variant = selected_variants(config, "openconnect_sturdy_hook")[0]
        hook_config = variant_config(config, hook_variant)
        self.assertEqual(hook_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])
        self.assertNotIn("angle_radius_callouts", hook_config["annotations"])

        shelf_variant = selected_variants(config, "openconnect_sturdy_shelf")[0]
        shelf_config = variant_config(config, shelf_variant)
        self.assertEqual(shelf_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])
        self.assertEqual(shelf_config["annotations"]["chains"][0]["ids"], ["depth_grids"])
        self.assertEqual(shelf_config["annotations"]["chains"][1]["ids"], ["horizontal_grids"])
        self.assertEqual(
            aliases_from_config(shelf_config["annotations"], context=shelf_config["constants"])["horizontal_grids"],
            "horizontal_grids x 28mm",
        )

        gridfinity_shelf_variant = selected_variants(config, "openconnect_gridfinity_shelf")[0]
        gridfinity_shelf_config = variant_config(config, gridfinity_shelf_variant)
        self.assertEqual(self.first_model_config(gridfinity_shelf_config)["scad_file"], "openconnect_gridfinity_shelf.scad")
        self.assertEqual(gridfinity_shelf_config["annotations"]["chains"][0]["ids"], ["gridfinity_width_grids"])
        self.assertEqual(
            gridfinity_shelf_config["annotations"]["aliases"]["gridfinity_width_grids"],
            "gridfinity_width_grids x 42mm",
        )

        clamshell_holder_variant = selected_variants(config, "openconnect_clamshell_holder")[0]
        clamshell_holder_config = variant_config(config, clamshell_holder_variant)
        self.assertEqual(self.first_model_config(clamshell_holder_config)["scad_file"], "openconnect_clamshell_holder.scad")
        clamshell_holder_objects = clamshell_holder_config["scene"]["objects"]
        self.assertEqual(len(clamshell_holder_objects), 1)
        self.assertEqual(clamshell_holder_objects[0]["model"]["scad_file"], "openconnect_clamshell_holder.scad")
        self.assertEqual(clamshell_holder_objects[0]["transform"]["rotation_deg"], [0, 0, 0])
        self.assertEqual(
            clamshell_holder_objects[0]["transform"]["location_mm"],
            [0, "-(item_depth+holder_thickness+3.72) / 2", "-(item_height+holder_thickness*2) / 2"],
        )
        self.assertNotIn("camera_rotation_deg", clamshell_holder_config["render"])
        self.assertEqual(clamshell_holder_config["annotations"]["chains"][0]["ids"], ["item_width"])
        self.assertEqual(image_label_items_from_config(clamshell_holder_config["annotations"]), [])

    def test_per_model_default_config_is_directly_renderable(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_general_holder.yaml"), [])

        self.assertEqual(self.first_model_config(config)["scad_file"], "openconnect_general_holder.scad")
        self.assertEqual(config["job_name"], "openconnect_general_holder")
        self.assertEqual(config["annotations"]["chains"][0]["ids"], ["compartment_width"])
        self.assertEqual(config["annotations"]["angle_radius_callouts"][0]["angle_id"], "holder_tilt_angle")
        self.assertEqual(image_label_items_from_config(config["annotations"]), [])

    def test_general_holder_variants_share_one_named_annotation_catalog(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_general_holder.yaml"), [])

        expected = {
            "default": (
                {"compartment_width_dimension", "compartment_height_dimension"},
                {"holder_tilt_angle_callout"},
                set(),
            ),
            "empty": (set(), set(), set()),
            "side": (
                {"holder_bottom_thickness_dimension"},
                {"holder_tilt_angle_callout"},
                set(),
            ),
            "top": (
                {
                    "compartment_width_dimension",
                    "compartment_depth_dimension",
                    "holder_back_offset_dimension",
                    "holder_outer_wall_thickness_dimension",
                },
                {"compartment_corner_rounding_callout"},
                set(),
            ),
            "taper": (
                {
                    "compartment_width_dimension",
                    "compartment_depth_dimension",
                    "compartment_bottom_width_dimension",
                    "compartment_bottom_depth_dimension",
                },
                set(),
                {"holder_bottom_thickness_label", "enable_bottom_taper_label"},
            ),
        }

        for variant_name, (chain_names, callout_names, label_names) in expected.items():
            variant = selected_variants(config, variant_name)[0]
            resolved = variant_config(config, variant)
            annotations = resolved["annotations"]
            self.assertEqual({item["name"] for item in chain_items_from_config(annotations)}, chain_names)
            self.assertEqual({item["name"] for item in angle_radius_items_from_config(annotations)}, callout_names)
            self.assertEqual({item["name"] for item in image_label_items_from_config(annotations)}, label_names)

    def test_gridfinity_shelf_variants_share_one_canonical_config(self) -> None:
        config_path = Path("annotation_renderer/configs/openconnect_gridfinity_shelf.yaml")
        config = load_config(config_path, [])

        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "top"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            ["Magnet_None", "Magnet_All", "Rim2_LipHeight3", "WidthGrid4_DepthGrid3"],
        )

        expected_chains = {
            "default": {"gridfinity_width_dimension", "gridfinity_depth_dimension"},
            "empty": set(),
            "top": {
                "shelf_back_offset_dimension",
                "shelf_side_rim_dimension",
                "shelf_front_rim_dimension",
            },
        }
        for variant_name, chain_names in expected_chains.items():
            resolved = variant_config(config, selected_variants(config, variant_name)[0])
            self.assertEqual(
                {item["name"] for item in chain_items_from_config(resolved["annotations"])},
                chain_names,
            )

        empty = variant_config(config, selected_variants(config, "empty")[0])
        self.assertNotIn("magnet_position", self.first_model_config(empty)["defines"])
        self.assertEqual(empty["render"]["camera_view_preset"], "technical_iso")
        self.assertNotIn("camera_location_offset_mm", empty["render"])

        top = variant_config(config, selected_variants(config, "top")[0])
        self.assertEqual(self.first_model_config(top)["defines"]["shelf_back_offset"], 8)
        self.assertEqual(top["render"]["camera_view_preset"], "top_front")

        wide = variant_config(config, selected_variants(config, "WidthGrid4_DepthGrid3")[0])
        self.assertEqual(self.first_model_config(wide)["defines"]["gridfinity_width_grids"], 4)
        self.assertEqual(wide["scene"]["objects"][0]["transform"]["location_mm"], ["-(3 * og_tile_size)", 0, "-og_tile_size"])

        self.assert_parameter_gallery(config, "openconnect_gridfinity_shelf", 4)

    def test_sturdy_shelf_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_sturdy_shelf.yaml"), [])

        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "side"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            ["Slim_NoTexture", "Slim_NoTexture_NoEdges", "Standard_NoTexture", "Split_Left_NoTexture"],
        )

        empty = variant_config(config, selected_variants(config, "empty")[0])
        self.assertEqual(self.first_model_config(empty).get("defines", {}), {})
        self.assertEqual(empty["render"]["lighting"], {"toplight_power": 1.5, "frontlight_power": 1.5})
        self.assertEqual(chain_items_from_config(empty["annotations"]), [])

        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(side["annotations"])},
            {"shelf_back_thickness_dimension", "shelf_bottom_thickness_dimension"},
        )
        self.assertEqual(
            {item["name"] for item in angle_radius_items_from_config(side["annotations"])},
            {"shelf_corner_fillet_callout"},
        )
        self.assertEqual(side["render"]["camera_view"], "bottom")

        self.assert_parameter_gallery(config, "openconnect_sturdy_shelf", 4)

    def test_sturdy_hook_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_sturdy_hook.yaml"), [])

        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "side"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            ["SliceOff_Target14", "Rectangular", "Flat", "TrussGrid1"],
        )

        default = variant_config(config, selected_variants(config, "default")[0])
        empty = variant_config(config, selected_variants(config, "empty")[0])
        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual([item["id"] for item in default["scene"]["objects"]], ["large_hook", "model"])
        self.assertEqual([item["id"] for item in empty["scene"]["objects"]], ["large_hook"])
        self.assertEqual(empty["annotations"], {})
        self.assertEqual(
            {item["name"] for item in angle_radius_items_from_config(side["annotations"])},
            {"circular_tip_angle_radius", "hook_corner_fillet_detail", "truss_angle_detail"},
        )
        self.assertEqual(side["render"]["camera_view"], "bottom")

        rectangular = variant_config(config, selected_variants(config, "Rectangular")[0])
        rectangular_defines = self.first_model_config(rectangular)["defines"]
        self.assertEqual(rectangular_defines["hook_shape_type"], "Rectangular")
        self.assertEqual(rectangular_defines["hook_corner_fillet"], 0)

        self.assert_parameter_gallery(config, "openconnect_sturdy_hook", 4)

    def test_vasemode_container_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_vasemode_container.yaml"), [])

        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "side"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            ["Checkers_Texture", "Cubes_Texture", "Wave_Ribs_Texture", "No_Texture"],
        )

        empty = variant_config(config, selected_variants(config, "empty")[0])
        self.assertNotIn("vase_surface_texture", self.first_model_config(empty)["defines"])
        self.assertNotIn("camera_location_offset_mm", empty["render"])
        self.assertEqual(chain_items_from_config(empty["annotations"]), [])
        self.assertEqual(image_label_items_from_config(empty["annotations"]), [])

        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(side["annotations"])},
            {"depth_grids_dimension"},
        )
        self.assertEqual(
            {item["name"] for item in angle_radius_items_from_config(side["annotations"])},
            {"vase_tilt_angle_callout"},
        )
        side_label = image_label_items_from_config(side["annotations"])[0]
        self.assertEqual(side_label["position"], "bottom")
        self.assertEqual(side_label["offset_px"], [0, -24])

        no_texture = variant_config(config, selected_variants(config, "No_Texture")[0])
        self.assertEqual(self.first_model_config(no_texture)["defines"]["vase_surface_texture"], "")

        self.assert_parameter_gallery(config, "openconnect_vasemode_container", 4)

    def test_framefit_hook_views_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/opengrid_framefit_hook.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "side"],
        )

        default = variant_config(config, selected_variants(config, "default")[0])
        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            [item["id"] for item in default["scene"]["objects"]],
            ["model", "large_hook", "truss_hook"],
        )
        self.assertEqual([item["id"] for item in side["scene"]["objects"]], ["model"])
        self.assertEqual(self.first_model_config(side)["defines"]["hook_corner_fillet"], 10)
        self.assertEqual(side["render"]["camera_view"], "left")
        self.assertEqual(
            {item["name"] for item in angle_radius_items_from_config(side["annotations"])},
            {"hook_corner_fillet_detail"},
        )

        resolved = json.loads(
            self.run_cli(
                "render",
                "annotation_renderer/configs/opengrid_framefit_hook.yaml",
                "--variant",
                "side",
                "--resolved",
            )
        )
        self.assertEqual([item["id"] for item in resolved["scene"]["objects"]], ["model"])
        self.assertEqual(resolved["render"]["camera_view"], "left")

    def test_snap_gadget_hook_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/opengrid_snap_gadget_hook.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "side"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            ["Centered_main20", "Straight_main40_width13.2_thick10", "Loop_main20", "Centered_Rectangular_main20"],
        )

        default = variant_config(config, selected_variants(config, "default")[0])
        empty = variant_config(config, selected_variants(config, "empty")[0])
        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            [item["id"] for item in default["scene"]["objects"]],
            ["model_a", "snap_a", "model_b", "snap_b"],
        )
        self.assertEqual([item["id"] for item in empty["scene"]["objects"]], ["model", "snap_a"])
        self.assertEqual(chain_items_from_config(empty["annotations"]), [])
        self.assertEqual(
            {item["name"] for item in angle_radius_items_from_config(side["annotations"])},
            {"hook_tip_angle_detail"},
        )
        self.assertEqual(side["render"]["camera_view"], "top")

        straight = variant_config(config, selected_variants(config, "Straight_main40_width13.2_thick10")[0])
        straight_defines = self.first_model_config(straight)["defines"]
        self.assertEqual(straight_defines["hook_main_size"], 40)
        self.assertEqual(straight_defines["hook_width"], 13.2)

        self.assert_parameter_gallery(config, "opengrid_snap_gadget_hook", 4)

    def test_snap_gadget_clip_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/opengrid_snap_gadget_clip.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "side"],
        )
        self.assertEqual(len(selected_variant_collection(config, "parameter_gallery")), 4)

        default = variant_config(config, selected_variants(config, "default")[0])
        empty = variant_config(config, selected_variants(config, "empty")[0])
        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            [item["id"] for item in default["scene"]["objects"]],
            ["clip_a", "snap_a", "clip_b", "snap_b"],
        )
        self.assertEqual([item["id"] for item in empty["scene"]["objects"]], ["model", "snap_a"])
        self.assertEqual([item["id"] for item in side["scene"]["objects"]], ["circ_clip", "snapa"])
        self.assertEqual(
            {item["name"] for item in angle_radius_items_from_config(side["annotations"])},
            {"clip_surround_angle_detail"},
        )

        vertical = variant_config(config, selected_variants(config, "Circular_Vertical_Tilt45")[0])
        self.assertEqual(vertical["scene"]["objects"][0]["transform"]["rotation_deg"], [0, -90, 0])

        self.assert_parameter_gallery(config, "opengrid_snap_gadget_clip", 4)

    def test_snap_gadget_plier_holder_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/opengrid_snap_gadget_plier_holder.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "side"],
        )
        self.assertEqual(len(selected_variant_collection(config, "parameter_gallery")), 4)

        default = variant_config(config, selected_variants(config, "default")[0])
        empty = variant_config(config, selected_variants(config, "empty")[0])
        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            [item["id"] for item in default["scene"]["objects"]],
            ["model_a", "snap_a", "model_b", "snap_b"],
        )
        self.assertEqual([item["id"] for item in empty["scene"]["objects"]], ["model_a", "snap_a"])
        self.assertEqual(self.first_model_config(empty).get("defines", {}), {})
        self.assertNotIn("camera_view", empty["render"])
        self.assertEqual(side["render"]["camera_view"], "right")
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(side["annotations"])},
            {
                "stem_height_dimension",
                "stem_depth_dimension",
                "transition_depth_ratio_dimension",
                "stopper_depth_dimension",
            },
        )

        wide = variant_config(config, selected_variants(config, "Width_Scale_1.4")[0])
        self.assertEqual(self.first_model_config(wide)["defines"]["stopper_width_scale"], 1.4)
        self.assertEqual(wide["render"]["camera_view_preset"], "top_front")

        self.assert_parameter_gallery(config, "opengrid_snap_gadget_plier_holder", 4)

    def test_clamshell_holder_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_clamshell_holder.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "alt", "empty", "front", "side"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            [
                "Width164_Height60_SlotColumn1",
                "Width164_Height60_SlotColumn2",
                "Width164_SlotPosition_Top",
                "Width120_Height100_Rounding20",
            ],
        )

        default = variant_config(config, selected_variants(config, "default")[0])
        alt = variant_config(config, selected_variants(config, "alt")[0])
        empty = variant_config(config, selected_variants(config, "empty")[0])
        front = variant_config(config, selected_variants(config, "front")[0])
        side = variant_config(config, selected_variants(config, "side")[0])
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(default["annotations"])},
            {"item_width_dimension", "item_height_dimension", "item_depth_dimension"},
        )
        self.assertEqual(chain_items_from_config(alt["annotations"]), [])
        self.assertEqual(image_label_items_from_config(alt["annotations"])[0]["id"], "holder_slot_position")
        self.assertEqual(self.first_model_config(empty).get("defines", {}), {})
        self.assertEqual(chain_items_from_config(empty["annotations"]), [])
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(front["annotations"])},
            {
                "item_width_dimension",
                "item_height_dimension",
                "front_opening_left_right_margin_dimension",
                "front_opening_top_bottom_margin_dimension",
            },
        )
        self.assertEqual(front["render"]["camera_view"], "front")
        self.assertEqual(angle_radius_items_from_config(front["annotations"])[0]["name"], "item_corner_rounding_fillet")
        self.assertEqual(side["render"]["camera_view"], "right")
        self.assertEqual(self.first_model_config(side)["defines"]["side_cutout_bottom_margin"], 20)
        self.assertNotIn("aliases", side["annotations"])
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(side["annotations"])},
            {
                "front_opening_top_bottom_margin_dimension",
                "side_cutout_top_margin_dimension",
                "side_cutout_bottom_margin_dimension",
                "side_cutout_back_margin_dimension",
                "side_cutout_front_margin_dimension",
            },
        )

        top_slot = variant_config(config, selected_variants(config, "Width164_SlotPosition_Top")[0])
        self.assertEqual(self.first_model_config(top_slot)["defines"]["holder_slot_position"], "Top")
        self.assertEqual(top_slot["scene"]["objects"][0]["transform"]["rotation_deg"], [-90, 0, 0])

        self.assert_parameter_gallery(config, "openconnect_clamshell_holder", 4)

    def test_drawer_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_drawer_shell_container.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["default", "empty", "top", "shell"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            [
                "Solid_Wall_NoLabel",
                "Solid_Wall_hGrid3_vGrid4",
                "DivHeight_22_hGrid6_vGrid4",
                "DivWidth_42_hGrid6_vGrid4",
            ],
        )

        default = variant_config(config, selected_variants(config, "default")[0])
        empty = variant_config(config, selected_variants(config, "empty")[0])
        top = variant_config(config, selected_variants(config, "top")[0])
        shell = variant_config(config, selected_variants(config, "shell")[0])
        self.assertEqual([item["id"] for item in default["scene"]["objects"]], ["drawer_shell", "drawer_container"])
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(default["annotations"])},
            {
                "container_horizontal_grids_dimension",
                "container_vertical_grids_dimension",
                "container_depth_grids_dimension",
            },
        )
        self.assertEqual(chain_items_from_config(empty["annotations"]), [])
        self.assertEqual([item["id"] for item in top["scene"]["objects"]], ["drawer_shell", "drawer_container"])
        self.assertEqual(top["scene"]["objects"][0]["model"]["defines"]["shell_slot_position"], "Top")
        self.assertNotIn("roughness", top["scene"]["objects"][1]["material"])
        self.assertNotIn("camera_rotation_offset_deg", top["render"])
        self.assertEqual(image_label_items_from_config(top["annotations"])[0]["id"], "shell_slot_position")
        self.assertEqual([item["id"] for item in shell["scene"]["objects"]], ["drawer_shell"])
        self.assertEqual(shell["annotations"]["object"], "drawer_shell")
        self.assertEqual(
            {item["name"] for item in chain_items_from_config(shell["annotations"])},
            {
                "shell_horizontal_grids_dimension",
                "shell_vertical_grids_dimension",
                "shell_depth_grids_dimension",
            },
        )
        self.assertNotIn("lighting", shell["render"])

        solid = variant_config(config, selected_variants(config, "Solid_Wall_NoLabel")[0])
        self.assertEqual(solid["scene"]["objects"][0]["model"]["defines"]["shell_side_wall_type"], "Solid")
        self.assertFalse(solid["scene"]["objects"][1]["model"]["defines"]["add_label_holder"])
        divided = variant_config(config, selected_variants(config, "DivHeight_22_hGrid6_vGrid4")[0])
        self.assertEqual([item["id"] for item in divided["scene"]["objects"]], ["drawer_shell"])
        self.assertEqual(divided["scene"]["objects"][0]["model"]["defines"]["add_shell_divider"], "Height")

        self.assert_parameter_gallery(config, "openconnect_drawer_shell_container", 4)

        model_defaults = load_config(Path("annotation_renderer/configs/model_defaults.yaml"), [])
        imported_shell = variant_config(
            model_defaults,
            selected_variants(model_defaults, "openconnect_drawer_shell")[0],
        )
        self.assertEqual([item["id"] for item in imported_shell["scene"]["objects"]], ["drawer_shell"])

    def test_drawer_floor_variants_share_one_canonical_config(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_drawer_floor.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "product_views")],
            ["gallery_base", "floor_width", "floor_depth", "floor_both"],
        )
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            ["Divider_Width", "Divider_Depth", "Divider_Both"],
        )

        gallery_base = variant_config(config, selected_variants(config, "gallery_base")[0])
        floor_width = variant_config(config, selected_variants(config, "floor_width")[0])
        floor_depth = variant_config(config, selected_variants(config, "floor_depth")[0])
        floor_both = variant_config(config, selected_variants(config, "floor_both")[0])
        self.assertEqual(
            [item["id"] for item in image_label_items_from_config(gallery_base["annotations"])],
            [
                "container_width_grid_count",
                "container_width_compartment_list",
                "container_depth_grid_count",
                "container_depth_compartment_list",
            ],
        )
        self.assertEqual(
            [item["id"] for item in image_label_items_from_config(floor_width["annotations"])],
            ["container_width_grid_count", "container_width_compartment_list"],
        )
        self.assertTrue(all(item["position"] == "bottom" for item in image_label_items_from_config(floor_width["annotations"])))
        self.assertNotIn("container_width_grid_count", self.first_model_config(floor_depth)["defines"])
        self.assertEqual(
            [item["id"] for item in image_label_items_from_config(floor_depth["annotations"])],
            ["container_depth_grid_count", "container_depth_compartment_list", "add_container_divider"],
        )
        self.assertEqual(self.first_model_config(floor_both)["defines"]["add_container_divider"], "Both")
        self.assertEqual(
            [item["offset_px"] for item in image_label_items_from_config(floor_both["annotations"])],
            [[0, 0], [0, 80], [0, 115], [0, 165], [0, 0]],
        )

        divider_depth = variant_config(config, selected_variants(config, "Divider_Depth")[0])
        self.assertEqual(self.first_model_config(divider_depth)["defines"]["container_depth_grid_count"], 4)

        self.assert_parameter_gallery(config, "openconnect_drawer_floor", 3)

    def test_plate_and_snap_utilities_share_canonical_configs(self) -> None:
        plate = load_config(Path("annotation_renderer/configs/openconnect_plate.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(plate, "product_views")],
            ["floor", "slot_annotated"],
        )
        annotated_plate = variant_config(plate, selected_variants(plate, "slot_annotated")[0])
        self.assertEqual([item["id"] for item in annotated_plate["scene"]["objects"]], ["plate"])
        self.assertTrue(annotated_plate["scene"]["blend_file"].endswith("opengrid_wall_scene.blend"))
        self.assertEqual(len(chain_items_from_config(annotated_plate["annotations"])), 9)

        parametric_snap = load_config(Path("annotation_renderer/configs/opengrid_parametric_snap.yaml"), [])
        self.assertEqual(parametric_snap["job_name"], "opengrid_parametric_snap")
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(parametric_snap, "product_views")],
            ["wall", "floor", "openconnect_annotated"],
        )
        snap_floor = variant_config(parametric_snap, selected_variants(parametric_snap, "floor")[0])
        self.assertEqual([item["id"] for item in snap_floor["scene"]["objects"]], ["screw", "snap", "snap_double"])
        self.assertNotIn("camera_view", snap_floor["render"])
        annotated_snap = variant_config(parametric_snap, selected_variants(parametric_snap, "openconnect_annotated")[0])
        self.assertEqual(annotated_snap["annotations"]["object"], "snap")
        self.assertEqual(len(chain_items_from_config(annotated_snap["annotations"])), 10)
        self.assertEqual(annotated_snap["annotations"]["radius_callouts"][0]["name"], "ochead_nub_fillet_callout")

        expanding_snap = load_config(Path("annotation_renderer/configs/opengrid_expanding_snap.yaml"), [])
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(expanding_snap, "product_views")],
            ["wall", "floor"],
        )
        expanding_floor = variant_config(expanding_snap, selected_variants(expanding_snap, "floor")[0])
        self.assertEqual([item["id"] for item in expanding_floor["scene"]["objects"]], ["screw"])
        self.assertEqual(self.first_model_config(expanding_floor)["scad_file"], "opengrid_expanding_snap.scad")

    def test_each_scad_source_has_one_config_definition(self) -> None:
        source_locations: dict[str, list[str]] = {}

        def collect_sources(value: object, *, path: Path) -> None:
            if isinstance(value, dict):
                source = value.get("scad_file")
                if isinstance(source, str):
                    source_locations.setdefault(source, []).append(path.name)
                for child in value.values():
                    collect_sources(child, path=path)
            elif isinstance(value, list):
                for child in value:
                    collect_sources(child, path=path)

        for config_path in Path("annotation_renderer/configs").glob("*.yaml"):
            collect_sources(yaml.safe_load(config_path.read_text(encoding="utf-8")), path=config_path)

        duplicates = {source: locations for source, locations in source_locations.items() if len(locations) > 1}
        self.assertEqual(duplicates, {})

    def test_config_tree_has_no_selector_only_compatibility_files(self) -> None:
        selector_configs: list[str] = []
        for config_path in Path("annotation_renderer/configs").glob("*.yaml"):
            raw_config = yaml.safe_load(config_path.read_text(encoding="utf-8"))
            if not isinstance(raw_config, dict):
                continue
            variants = raw_config.get("variants")
            if (
                isinstance(raw_config.get("extends"), str)
                and isinstance(variants, list)
                and len(variants) == 1
                and isinstance(variants[0], dict)
                and "extends_variant" in variants[0]
                and not any(key in raw_config for key in ("scene", "render", "annotations", "gallery"))
            ):
                selector_configs.append(config_path.name)

        self.assertEqual(selector_configs, [])
        self.assertEqual(
            sorted(path.name for path in Path("annotation_renderer/configs").glob("*gallery.yaml")),
            ["render_settings_gallery.yaml"],
        )

    def test_canonical_config_uses_its_default_gallery_collection(self) -> None:
        config = load_config(Path("annotation_renderer/configs/openconnect_general_holder.yaml"), [])
        self.assertEqual(config["default_variant"], "default")
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "parameter_gallery")],
            [
                "Width45_Mode_Minimum",
                "Width45_Mode_Tile_Multiple",
                "Circular_Tapered_Bottomless",
                "Circular_Grid_3x2",
            ],
        )
        self.assert_parameter_gallery(config, "openconnect_general_holder", 4)

    def test_replacing_variants_drops_an_inherited_gallery_collection(self) -> None:
        config = load_config(Path("annotation_renderer/configs/render_settings_gallery.yaml"), [])

        self.assertNotIn("variant_collection", config["gallery"])
        self.assertEqual(len(selected_variants(config, None)), 6)

    def test_validate_command_checks_all_variants_or_one_collection(self) -> None:
        all_output = self.run_cli("validate", "openconnect_general_holder")
        collection_output = self.run_cli(
            "validate",
            "openconnect_general_holder",
            "--collection",
            "annotated_views",
        )

        self.assertEqual(all_output.count("Config OK:"), 9)
        self.assertIn("Validated:  9 variants", all_output)
        self.assertEqual(collection_output.count("Config OK:"), 4)
        self.assertIn("Validated:  4 variants", collection_output)

    def test_checked_in_defaults_are_yaml_only(self) -> None:
        config_dir = Path("annotation_renderer/configs")

        self.assertTrue((config_dir / "model_defaults.yaml").exists())
        self.assertFalse((config_dir / "model_defaults.json").exists())
        self.assertFalse(any(config_dir.glob("*.json")))

    def test_list_models_uses_default_model_config(self) -> None:
        output = self.run_cli("models")

        self.assertIn("openconnect_general_holder", output)
        self.assertIn("annotation_renderer/configs/openconnect_general_holder.yaml", output)
        self.assertIn("model_b: openconnect_general_holder.scad", output)
        self.assertIn("model_a: openconnect_general_holder.scad", output)
        self.assertIn("openconnect_clamshell_holder", output)
        self.assertIn("model: openconnect_clamshell_holder.scad", output)
        self.assertIn("openconnect_vasemode_container", output)
        self.assertIn("model: openconnect_vasemode_container.scad", output)
        self.assertIn("openconnect_standard_snap_grid_copies", output)
        self.assertIn("openconnect_standard_snap: ../assets/openconnect_standard_snap.stl", output)
        self.assertIn("opengrid_expanding_standard_snap_grid_copies", output)
        self.assertIn("opengrid_expanding_standard_snap: ../assets/opengrid_expanding_standard_snap.stl", output)

    def test_canonical_commands_use_model_names(self) -> None:
        list_output = self.run_cli("models")
        description = self.run_cli("describe", "openconnect_general_holder")
        vase_description = self.run_cli("describe", "openconnect_vasemode_container")
        annotations = self.run_cli("annotations", "openconnect_general_holder")
        vase_annotations = self.run_cli("annotations", "openconnect_vasemode_container")
        discovery = self.run_cli("discover", "openconnect_general_holder.scad")
        doctor_args = parse_args_from(["doctor", "--smoke-render"])

        self.assertIn("openconnect_general_holder", list_output)
        self.assertIn("Source: annotation_renderer/configs/openconnect_general_holder.yaml", description)
        self.assertIn("Source: annotation_renderer/configs/openconnect_vasemode_container.yaml", vase_description)
        self.assertIn("dimension: compartment_width", annotations)
        self.assertIn("dimension: horizontal_grids", vase_annotations)
        self.assertIn("Available annotation parameters for openconnect_general_holder:", discovery)
        self.assertEqual(doctor_args.command, "doctor")
        self.assertTrue(doctor_args.smoke_render)

    def test_render_shortcut_uses_scad_model_default_config(self) -> None:
        output = self.run_cli("validate", "openconnect_general_holder", "--variant", "default")

        self.assertIn("Config OK: annotation_renderer/configs/openconnect_general_holder.yaml", output)
        self.assertIn("Object:    model_b -> openconnect_general_holder.scad", output)
        self.assertIn("Object:    model_a -> openconnect_general_holder.scad", output)
        self.assertEqual(
            default_config_for_model("openconnect_general_holder"),
            Path("annotation_renderer/configs/openconnect_general_holder.yaml").resolve(),
        )
        self.assertEqual(
            default_config_for_model("openconnect_vasemode_container"),
            Path("annotation_renderer/configs/openconnect_vasemode_container.yaml").resolve(),
        )

    def test_render_shortcut_accepts_named_config_files(self) -> None:
        output = self.run_cli("validate", "openconnect_standard_snap_grid_copies")

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
            Path("annotation_renderer/configs/openconnect_general_holder.yaml"),
            ["annotations.chains.compartment_width_dimension.label_offset_px=36"],
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
                value_color="#0000FF",
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
                value_color="#0000FF",
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

    def test_image_label_title_area_can_be_enabled_per_top_label(self) -> None:
        labels = [
            ImageLabel(
                id="top_label",
                label="top_label",
                value_text=None,
                position="top",
                offset_px=(0.0, 0.0),
                angle_deg=0.0,
                color=None,
                value_color=None,
                font_size_px=24,
                title_area=True,
                title_edge_margin_px=14,
            )
        ]
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            render_path = tmp_path / "render.png"
            output_path = tmp_path / "annotated.png"
            Image.new("RGB", (420, 260), "#ffffff").save(render_path)

            metadata = draw_image_label_overlay(
                render_path=render_path,
                output_path=output_path,
                labels=labels,
                style_config={
                    "image_label_title_positions": ["bottom"],
                    "image_label_margin_px": 20,
                    "image_label_title_padding_x_px": 12,
                    "image_label_title_padding_y_px": 8,
                    "image_label_title_min_width_px": 160,
                },
            )

        self.assertIn("top", metadata["title_areas"])
        self.assertGreaterEqual(metadata["title_areas"]["top"]["bbox_px"]["top"], 14)

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
