"""Default values and schema-derived config constants."""

from __future__ import annotations

from annotation_renderer.config_schema import schema_allowed_keys, schema_definition_enum, schema_property_enum


AXES = ("x", "y", "z")
DEFAULT_OUTPUT_DIR = "build/scene_annotations"
DEFAULT_LINE_ALPHA = 255
DEFAULT_LINE_COLORS = {
    "hook_length": "#2f7f8f",
    "hook_thickness": "#6f7f2f",
    "hook_vertical_grids": "#7f4f8f",
    "shelf_depth": "#2f7f8f",
    "shelf_width": "#6f7f2f",
    "shelf_back_thickness": "#8b6f2f",
    "shelf_bottom_thickness": "#7f4f8f",
    "compartment_height": "#000000",
    "horizontal_grids": "#2f7f8f",
    "vertical_grids": "#7f4f8f",
    "depth_grids": "#6f7f2f",
    "circular_corner_radius": "#8b6f2f",
    "circular_corner_radius_extent": "#8b6f2f",
    "circular_tip_radius": "#8b6f2f",
    "circular_tip_radius_extent": "#8b6f2f",
    "circular_tip_angle": "#8b6f2f",
    "hook_width": "#2f7f8f",
    "rectangular_tip_extra_length": "#8b6f2f",
    "truss_beam_reach": "#2f7f8f",
    "truss_strut_interval": "#7f4f8f",
    "truss_thickness": "#6f7f2f",
    "truss_vertical_grids": "#7f4f8f",
    "shelf_corner_fillet": "#8b6f2f",
    "shelf_front_edge_depth": "#6f7f2f",
    "shelf_side_edge_depth": "#2f7f8f",
    "shell_thickness": "#6f7f2f",
    "container_width_clearance": "#8b6f2f",
    "container_height_clearance": "#7f4f8f",
    "container_depth_clearance": "#2f7f8f",
}
DEFAULT_TYPE_STYLES: dict[str, dict[str, object]] = {
    "grids": {
        "line_colors": ["#2563eb"],
        "font": "sans",
    },
    "mm": {
        "line_colors": ["#000000"],
        "font": "sans",
    },
    "radius": {
        "line_colors": ["#dc2626"],
        "font": "sans",
    },
    "angle": {
        "line_colors": ["#dc2626"],
        "font": "sans",
    },
}
CONSTANT_REF_KEY = "$constant"
STYLE_PRESETS: dict[str, dict[str, object]] = {
    "makerworld_technical_light": {
        "line_alpha": 255,
        "line_width_px": 3,
        "extension_width_px": 1.7,
        "extension_visible": True,
        "extension_dash_px": 6,
        "extension_gap_px": 4,
        "tick_length_px": 18,
        "label_font_size_px": 28,
        "label_color": "#18212b",
        "label_outline_color": "#f8fafc",
        "label_outline_width_px": 2,
        "show_values": False,
        "auto_adjust_labels": False,
        "colors": {},
        "type_styles": DEFAULT_TYPE_STYLES,
    }
}
RENDER_PRESETS: dict[str, dict[str, object]] = {
    "cycles_standard_scene": {
        "engine": "cycles",
        "quality": "standard",
        "width": 1200,
        "height": 900,
        "fit_camera": True,
        "fit_margin": 0.08,
        "mesh_shading": "flat",
    },
    "cycles_draft_scene": {
        "engine": "cycles",
        "quality": "draft",
        "width": 1200,
        "height": 900,
        "fit_camera": True,
        "fit_margin": 0.08,
        "mesh_shading": "flat",
    },
}
STYLE_INTEGER_FIELDS: dict[str, tuple[int | None, int | None]] = {
    "line_alpha": (0, 255),
    "label_font_size_px": (1, None),
    "font_size_px": (1, None),
    "label_outline_width_px": (0, None),
    "angle_fill_alpha": (0, 255),
    "image_label_title_fill_alpha": (0, 255),
    "image_label_title_outline_alpha": (0, 255),
}
STYLE_NUMBER_FIELDS: dict[str, tuple[float | None, float | None]] = {
    "line_width_px": (None, None),
    "extension_width_px": (None, None),
    "extension_dash_px": (None, None),
    "extension_gap_px": (None, None),
    "tick_length_px": (None, None),
    "radial_line_width_px": (None, None),
    "radial_dash_px": (None, None),
    "radial_gap_px": (None, None),
    "image_label_margin_px": (0.0, None),
    "image_label_title_padding_x_px": (0.0, None),
    "image_label_title_padding_y_px": (0.0, None),
    "image_label_title_radius_px": (0.0, None),
    "image_label_title_outline_width_px": (0.0, None),
    "image_label_title_min_width_px": (0.0, None),
    "image_label_title_top_margin_px": (0.0, None),
    "image_label_title_bottom_margin_px": (0.0, None),
}
STYLE_BOOLEAN_FIELDS = {
    "extension_visible",
    "label_color_by_segment",
    "image_label_title_area",
    "show_values",
    "auto_adjust_labels",
    "show_label",
    "show_angle_label",
    "show_radius_label",
}
STYLE_STRING_FIELDS = {
    "label_color",
    "label_outline_color",
    "angle_fill_color",
    "image_label_title_fill_color",
    "image_label_title_outline_color",
}
STYLE_STRING_LIST_FIELDS: dict[str, set[str]] = {
    "image_label_title_positions": {"top", "bottom"},
}
STYLE_OVERRIDE_KEYS = (
    set(STYLE_INTEGER_FIELDS)
    | set(STYLE_NUMBER_FIELDS)
    | STYLE_BOOLEAN_FIELDS
    | STYLE_STRING_FIELDS
    | set(STYLE_STRING_LIST_FIELDS)
)
INTERPOLATION_NAMES = schema_property_enum("animationConfig", "interpolation")
OUTPUT_FORMATS = schema_property_enum("animationConfig", "output_format")
MESH_SHADING_VALUES = schema_definition_enum("meshShading")
RENDER_CAMERA_VIEW_PRESET_VALUES = schema_definition_enum("cameraViewPreset")
RENDER_LIGHTING_PRESET_VALUES = schema_definition_enum("lightingPreset")


RENDER_ENGINE_VALUES = schema_property_enum("renderConfig", "engine")
RENDER_QUALITY_VALUES = schema_property_enum("renderConfig", "quality")
RENDER_CAMERA_LOOK_AT_VALUES = schema_property_enum("renderConfig", "camera_look_at")
RENDER_CAMERA_VIEW_VALUES = schema_property_enum("renderConfig", "camera_view")
RENDER_OUTPUT_MODE_VALUES = schema_property_enum("renderConfig", "output_mode")

SCENE_OBJECT_CONFIG_KEYS = schema_allowed_keys("sceneObject")
SCENE_OBJECT_DEFAULT_KEYS = schema_allowed_keys("sceneObjectDefaults")
SCENE_CONFIG_KEYS = schema_allowed_keys("sceneConfig")
RENDER_CONFIG_KEYS = schema_allowed_keys("renderConfig")
ANIMATION_CONFIG_KEYS = schema_allowed_keys("animationConfig")
ANIMATION_CLIP_CONFIG_KEYS = schema_allowed_keys("animationClipConfig")
OBJECT_ANIMATION_CONFIG_KEYS = schema_allowed_keys("objectAnimationConfig")
VISIBILITY_KEYFRAME_KEYS = schema_allowed_keys("visibilityKeyframe")
OPACITY_KEYFRAME_KEYS = schema_allowed_keys("opacityKeyframe")
LOCATION_OFFSET_KEYFRAME_KEYS = schema_allowed_keys("locationOffsetKeyframe")

