from __future__ import annotations

from pathlib import Path
from annotation_renderer.animation import resolve_animation_config
from annotation_renderer.annotation_config import (
    collect_angle_radius_callouts,
    collect_dimension_chain,
    collect_image_labels,
)
from annotation_renderer.config.schema import ConfigError
from annotation_renderer.config.validation import validate_config_shape
from annotation_renderer.config.resolution import deep_merge, resolve_style
from annotation_renderer.config.loader import (
    load_config,
    selected_variant_collection,
    selected_variants,
    variant_config,
)
from annotation_renderer.diagnostics import parse_blender_version
from annotation_renderer.scad_annotations import (
    parse_scad_annotation_line,
    value_context_from_scad_annotations,
)
from annotation_renderer.pipeline import (
    chain_items_from_config,
    apply_animation_preset,
    label_value_context_for_record,
)
from tests.renderer_test_case import RendererTestCase


class AnimationAndAnnotationTests(RendererTestCase):
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

    def test_deep_merge_preserves_nested_preset_overrides(self) -> None:
        merged = deep_merge(
            {"render": {"preset": "cycles_standard_scene", "lighting": {"preset": "technical", "strength": 1}}},
            {"render": {"preset": "cycles_draft_scene", "lighting": {"preset": "flat"}}},
        )

        self.assertEqual(merged["render"]["preset"], "cycles_draft_scene")
        self.assertEqual(merged["render"]["lighting"], {"preset": "flat", "strength": 1})

    def test_variant_annotation_overrides_use_stable_group_names(self) -> None:
        config = {
            "scene": {"blend_file": "demo.blend"},
            "render": {},
            "annotations": {
                "chains": [
                    {
                        "name": "width_dimension",
                        "ids": ["width"],
                        "label_offset_px": 20,
                        "labels": {"width": "Width"},
                    },
                    {"name": "height_dimension", "ids": ["height"], "label_offset_px": 10},
                ]
            },
            "variants": [
                {
                    "name": "side",
                    "annotation_overrides": {
                        "width_dimension": {"enabled": False},
                        "height_dimension": {"label_offset_px": 42},
                    },
                }
            ],
        }

        resolved = variant_config(config, config["variants"][0])

        self.assertFalse(resolved["annotations"]["chains"][0]["enabled"])
        self.assertEqual(resolved["annotations"]["chains"][0]["labels"], {"width": "Width"})
        self.assertEqual(resolved["annotations"]["chains"][1]["label_offset_px"], 42)
        self.assertEqual(
            [group["name"] for group in chain_items_from_config(resolved["annotations"])],
            ["height_dimension"],
        )

    def test_variant_annotation_overrides_reject_unknown_or_ambiguous_names(self) -> None:
        base = {
            "scene": {"blend_file": "demo.blend"},
            "render": {},
            "annotations": {"chains": [{"name": "width", "ids": ["width"]}]},
        }
        with self.assertRaisesRegex(ConfigError, "unknown annotation group 'missing'"):
            variant_config(
                {**base, "variants": [{"name": "bad", "annotation_overrides": {"missing": {"enabled": False}}}]},
                {"name": "bad", "annotation_overrides": {"missing": {"enabled": False}}},
            )
        with self.assertRaisesRegex(ConfigError, "Annotation group name 'width' is ambiguous"):
            variant_config(
                {
                    **base,
                    "annotations": {
                        "chains": [{"name": "width", "ids": ["width"]}],
                        "image_labels": [{"name": "width", "id": "width"}],
                    },
                    "variants": [{"name": "bad", "annotation_overrides": {"width": {"enabled": False}}}],
                },
                {"name": "bad", "annotation_overrides": {"width": {"enabled": False}}},
            )

    def test_variant_object_overrides_named_paths_and_unset_compose(self) -> None:
        config = {
            "scene": {
                "blend_file": "demo.blend",
                "objects": [
                    {
                        "id": "drawer_shell",
                        "model": {"scad_file": "drawer.scad", "defines": {"old": True, "width": 1}},
                    },
                    {"id": "drawer_container", "model": {"scad_file": "drawer.scad"}},
                ],
            },
            "render": {"camera_view": "top"},
            "annotations": {},
            "variants": [
                {
                    "name": "shell_only",
                    "set": {"scene.objects.drawer_shell.model.defines.width": 3},
                    "object_overrides": {
                        "drawer_shell": {"model": {"defines": {"height": 2}}},
                        "drawer_container": {"enabled": False},
                    },
                    "unset": [
                        "scene.objects.drawer_shell.model.defines.old",
                        "render.camera_view",
                    ],
                }
            ],
        }

        resolved = variant_config(config, config["variants"][0])

        self.assertEqual([item["id"] for item in resolved["scene"]["objects"]], ["drawer_shell"])
        self.assertEqual(resolved["scene"]["objects"][0]["model"]["defines"], {"width": 3, "height": 2})
        self.assertNotIn("camera_view", resolved["render"])

    def test_variant_object_overrides_and_unset_reject_unknown_targets(self) -> None:
        base = {
            "scene": {
                "blend_file": "demo.blend",
                "objects": [{"id": "model", "model": {"scad_file": "demo.scad"}}],
            },
            "render": {},
            "annotations": {},
        }
        with self.assertRaisesRegex(ConfigError, "unknown scene object 'missing'"):
            variant_config(
                {**base, "variants": [{"name": "bad", "object_overrides": {"missing": {"enabled": False}}}]},
                {"name": "bad", "object_overrides": {"missing": {"enabled": False}}},
            )
        with self.assertRaisesRegex(ConfigError, "unset path 'render.missing' does not exist"):
            variant_config(
                {**base, "variants": [{"name": "bad", "unset": ["render.missing"]}]},
                {"name": "bad", "unset": ["render.missing"]},
            )

    def test_variant_collections_preserve_declared_order_and_validate_members(self) -> None:
        config = {
            "scene": {"blend_file": "demo.blend"},
            "render": {},
            "annotations": {},
            "variant_collections": {"views": ["side", "default"]},
            "variants": [{"name": "default"}, {"name": "side"}, {"name": "parameter_demo"}],
        }

        validate_config_shape(config)
        validate_config_shape({**config, "gallery": {"variant_collection": "views"}})
        self.assertEqual(
            [variant["name"] for variant in selected_variant_collection(config, "views")],
            ["side", "default"],
        )
        with self.assertRaisesRegex(ConfigError, "references unknown variant 'missing'"):
            validate_config_shape({**config, "variant_collections": {"views": ["missing"]}})
        with self.assertRaisesRegex(ConfigError, "gallery.variant_collection references unknown collection 'missing'"):
            validate_config_shape({**config, "gallery": {"variant_collection": "missing"}})

    def test_blender_version_parser_enforces_semantic_version_shape(self) -> None:
        self.assertEqual(parse_blender_version("Blender 5.1.0\n"), (5, 1, 0))
        self.assertEqual(parse_blender_version("Blender 6.0\n"), (6, 0, 0))
        self.assertIsNone(parse_blender_version("not blender"))

    def test_animation_preset_shortcut_applies_to_model_defaults(self) -> None:
        shelf_config_file = load_config(Path("annotation_renderer/configs/openconnect_sturdy_shelf.yaml"), [])
        shelf_config = apply_animation_preset(shelf_config_file, "openconnect_insert_animation_render")
        self.assertEqual(shelf_config["scene"]["transform"]["rotation_deg"], [90, 0, -90])
        self.assertEqual(shelf_config["render"]["animation"]["object_animations"][0]["object"], "model")
        self.assertEqual(shelf_config["annotations"], {})

        drawer_config_file = load_config(Path("annotation_renderer/configs/openconnect_drawer_shell_container.yaml"), [])
        drawer_config = apply_animation_preset(drawer_config_file, "drawer_install_then_slide_animation_render")
        animation = drawer_config["render"]["animation"]
        self.assertEqual(animation["clips"][0]["object_animations"][0]["object"], "drawer_shell")
        self.assertEqual(animation["clips"][1]["object_animations"][0]["opacity_keyframes"][1], {"frame": 8, "value": 1})

    def test_animation_preset_shortcut_rejects_non_animation_constants(self) -> None:
        holder_config_file = load_config(Path("annotation_renderer/configs/openconnect_general_holder.yaml"), [])

        with self.assertRaisesRegex(ConfigError, "must include render.animation"):
            apply_animation_preset(holder_config_file, "default_annotation_style")

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

    def test_image_labels_accept_per_label_title_area(self) -> None:
        labels = collect_image_labels(
            labels_config=[
                {
                    "id": "mode",
                    "position": "top",
                    "title_area": True,
                    "title_edge_margin_px": 11,
                    "title_padding_x_px": 7,
                }
            ],
            annotation_config={},
            style_config={},
            expression_context={},
            value_context={},
        )

        self.assertTrue(labels[0].title_area)
        self.assertEqual(labels[0].title_edge_margin_px, 11)
        self.assertEqual(labels[0].title_padding_x_px, 7)

    def test_annotation_group_color_overrides_type_style_for_dimensions(self) -> None:
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
            chain_config={
                "ids": ["body_width", "body_depth"],
                "color": "#123456",
                "colors": {"body_depth": "#654321"},
            },
            style_config=resolve_style(
                {
                    "type_styles": {"mm": {"line_colors": ["#0000ff"]}},
                }
            ),
        )

        self.assertEqual(chain[0].color, "#123456")
        self.assertEqual(chain[1].color, "#654321")

    def test_annotation_group_color_overrides_type_style_for_angle_radius_callouts(self) -> None:
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
                "color": "#123456",
                "colors": {
                    "tip_radius": "#654321",
                },
            },
            style_config=resolve_style(
                {
                    "type_styles": {
                        "angle": {"line_colors": ["#FF0000"]},
                        "radius": {"line_colors": ["#FF0000"]},
                    },
                }
            ),
        )

        self.assertEqual(callouts[0].arc_color, "#123456")
        self.assertEqual(callouts[0].radius_color, "#654321")

    def test_annotation_group_display_rotation_applies_before_offset(self) -> None:
        annotation = parse_scad_annotation_line(
            'ECHO: "OPENGRID_ANNOTATION_V1|id=body_width|kind=dimension|label=body_width|axis=x|value=2|start=1,0,0|end=2,0,0|basis=test"'
        )

        chain = collect_dimension_chain(
            annotations=[annotation],
            chain_config={
                "ids": ["body_width"],
                "display_rotation_deg": [0, 0, 90],
                "display_offset_mm": [10, 0, 0],
            },
            style_config=resolve_style({}),
        )

        self.assertEqual(chain[0].source_start_mm, (1.0, 0.0, 0.0))
        self.assertEqual(chain[0].source_end_mm, (2.0, 0.0, 0.0))
        self.assertAlmostEqual(chain[0].start_mm[0], 10.0)
        self.assertAlmostEqual(chain[0].start_mm[1], 1.0)
        self.assertAlmostEqual(chain[0].end_mm[0], 10.0)
        self.assertAlmostEqual(chain[0].end_mm[1], 2.0)

    def test_angle_radius_display_rotation_applies_to_radius_and_arc_points(self) -> None:
        annotations = [
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=tip_radius|kind=radius|label=tip_radius|value=2|center=1,0,0|edge=2,0,0|basis=test"'
            ),
            parse_scad_annotation_line(
                'ECHO: "OPENGRID_ANNOTATION_V1|id=tip_radius_extent|kind=arc|label=tip_radius|value=90|points=2,0,0;0,2,0|basis=test"'
            ),
        ]

        callouts = collect_angle_radius_callouts(
            annotations=[annotation for annotation in annotations if annotation is not None],
            callout_config={
                "arc_id": "tip_radius_extent",
                "radius_id": "tip_radius",
                "display_rotation_deg": [0, 0, 90],
                "display_offset_mm": [10, 0, 0],
            },
            style_config=resolve_style({}),
        )

        self.assertAlmostEqual(callouts[0].center_mm[0], 10.0)
        self.assertAlmostEqual(callouts[0].center_mm[1], 1.0)
        self.assertAlmostEqual(callouts[0].edge_mm[0], 10.0)
        self.assertAlmostEqual(callouts[0].edge_mm[1], 2.0)
        self.assertAlmostEqual(callouts[0].points_mm[0][0], 10.0)
        self.assertAlmostEqual(callouts[0].points_mm[0][1], 2.0)

    def test_scad_value_context_keeps_string_values(self) -> None:
        annotation = parse_scad_annotation_line(
            'ECHO: "OPENGRID_ANNOTATION_V1|id=drawer_context|kind=context|values=shell_slot_position=Back;horizontal_grids=5;bad=undef"'
        )

        context = value_context_from_scad_annotations([annotation])

        self.assertEqual(context["shell_slot_position"], "Back")
        self.assertEqual(context["horizontal_grids"], "5")
        self.assertNotIn("bad", context)
