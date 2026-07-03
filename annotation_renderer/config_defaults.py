"""Default values and schema-derived config constants."""

from __future__ import annotations

from annotation_renderer.config_schema import (
    schema_allowed_keys,
    schema_definition_enum,
    schema_definition_enum_values,
    schema_property_enum,
    schema_property_enum_values,
)


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
    "hook_corner_fillet": "#8b6f2f",
    "hook_corner_fillet_extent": "#8b6f2f",
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
        "line_colors": ["#0000FF"],
        "font": "sans",
    },
    "mm": {
        "line_colors": ["#000000"],
        "font": "sans",
    },
    "radius": {
        "line_colors": ["#FF0000"],
        "font": "sans",
    },
    "angle": {
        "line_colors": ["#FF0000"],
        "font": "sans",
    },
}
CONSTANT_REF_KEY = "$constant"
DEFAULT_STYLE_PRESET_NAME = "makerworld_technical_light"
DEFAULT_RENDER_PRESET_NAME = "cycles_standard_scene"
DRAFT_RENDER_PRESET_NAME = "cycles_draft_scene"
DEFAULT_RENDER_ENGINE = "cycles"
DEFAULT_RENDER_WIDTH = 1920
DEFAULT_RENDER_HEIGHT = 1440
DEFAULT_RENDER_FIT_CAMERA = True
DEFAULT_RENDER_FIT_MARGIN = 0
DEFAULT_RENDER_MESH_SHADING = "flat"
DEFAULT_OUTPUT_MODE = "standard"
GALLERY_SETTING_DEFAULTS = {
    "columns": 2,
    "thumbnail_width": 520,
    "margin_px": 12,
    "gutter_px": 12,
    "title_height_px": 22,
    "title_font_size_px": 22,
}
CAMERA_VIEW_PRESETS = {
    "front_left": {"camera_view": "front", "camera_orbit_deg": [-35, 8], "camera_distance_scale": 1.08},
    "front_right": {"camera_view": "front", "camera_orbit_deg": [35, 8], "camera_distance_scale": 1.08},
    "back_left": {"camera_view": "back", "camera_orbit_deg": [35, 8], "camera_distance_scale": 1.08},
    "back_right": {"camera_view": "back", "camera_orbit_deg": [-35, 8], "camera_distance_scale": 1.08},
    "top_front": {"camera_view": "front", "camera_orbit_deg": [0, 72], "camera_distance_scale": 1.12},
    "top_back": {"camera_view": "back", "camera_orbit_deg": [0, 72], "camera_distance_scale": 1.12},
    "technical_iso": {"camera_view": "front", "camera_orbit_deg": [35, 24], "camera_distance_scale": 1.15},
    "left_side_zoomed": {"camera_view": "left", "camera_distance_scale": 0.88},
    "right_side_zoomed": {"camera_view": "right", "camera_distance_scale": 0.88},
}
STYLE_PRESETS: dict[str, dict[str, object]] = {
    DEFAULT_STYLE_PRESET_NAME: {
        "line_alpha": 255,
        "line_width_px": 4,
        "line_outline_color": "#ffffff",
        "line_outline_alpha": 190,
        "angle_radius_outline_alpha": 180,
        "line_outline_width_px": 6.5,
        "extension_outline_width_px": 5.0,
        "radial_line_outline_width_px": 7.5,
        "arc_line_outline_width_px": 7.5,
        "angle_radius_arc_outline_width_px": 7.2,
        "extension_width_px": 1.7,
        "extension_visible": True,
        "extension_dash_px": 6,
        "extension_gap_px": 4,
        "tick_length_px": 18,
        "radial_dash_px": 20,
        "radial_gap_px": 12.8,
        "label_font_size_px": 28,
        "label_color": "#18212b",
        "label_color_by_segment": True,
        "label_outline_color": "#f8fafc",
        "label_outline_width_px": 4,
        "angle_fill_color": "#d9ead3",
        "angle_fill_alpha": 30,
        "label_avoidance_padding_px": 3,
        "show_values": False,
        "auto_adjust_labels": False,
        "image_label_margin_px": 42,
        "image_label_title_area": True,
        "image_label_title_positions": ["bottom"],
        "image_label_title_padding_x_px": 34,
        "image_label_title_padding_y_px": 12,
        "image_label_title_radius_px": 18,
        "image_label_title_fill_color": "#ffffff",
        "image_label_title_fill_alpha": 224,
        "image_label_title_outline_color": "#000000",
        "image_label_title_outline_alpha": 255,
        "image_label_title_outline_width_px": 4,
        "image_label_title_min_width_px": 620,
        "image_label_title_top_margin_px": 18,
        "image_label_title_bottom_margin_px": 18,
        "type_styles": DEFAULT_TYPE_STYLES,
    }
}
RENDER_PRESETS: dict[str, dict[str, object]] = {
    DEFAULT_RENDER_PRESET_NAME: {
        "engine": DEFAULT_RENDER_ENGINE,
        "quality": "standard",
        "width": DEFAULT_RENDER_WIDTH,
        "height": DEFAULT_RENDER_HEIGHT,
        "fit_camera": DEFAULT_RENDER_FIT_CAMERA,
        "fit_margin": DEFAULT_RENDER_FIT_MARGIN,
        "mesh_shading": DEFAULT_RENDER_MESH_SHADING,
    },
    DRAFT_RENDER_PRESET_NAME: {
        "engine": DEFAULT_RENDER_ENGINE,
        "quality": "draft",
        "width": DEFAULT_RENDER_WIDTH,
        "height": DEFAULT_RENDER_HEIGHT,
        "fit_camera": DEFAULT_RENDER_FIT_CAMERA,
        "fit_margin": DEFAULT_RENDER_FIT_MARGIN,
        "mesh_shading": DEFAULT_RENDER_MESH_SHADING,
    },
}
STYLE_INTEGER_FIELDS: dict[str, tuple[int | None, int | None]] = {
    "line_alpha": (0, 255),
    "line_outline_alpha": (0, 255),
    "angle_radius_outline_alpha": (0, 255),
    "label_font_size_px": (1, None),
    "font_size_px": (1, None),
    "label_outline_width_px": (0, None),
    "angle_fill_alpha": (0, 255),
    "image_label_title_fill_alpha": (0, 255),
    "image_label_title_outline_alpha": (0, 255),
}
STYLE_NUMBER_FIELDS: dict[str, tuple[float | None, float | None]] = {
    "line_width_px": (None, None),
    "line_outline_width_px": (0.0, None),
    "extension_width_px": (None, None),
    "extension_outline_width_px": (0.0, None),
    "extension_dash_px": (None, None),
    "extension_gap_px": (None, None),
    "tick_length_px": (None, None),
    "radial_line_width_px": (None, None),
    "radial_line_outline_width_px": (0.0, None),
    "radial_dash_px": (None, None),
    "radial_gap_px": (None, None),
    "arc_line_outline_width_px": (0.0, None),
    "angle_radius_arc_outline_width_px": (0.0, None),
    "label_avoidance_padding_px": (0.0, None),
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
    "line_outline_color",
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
MESH_SHADING_OPTIONS = schema_definition_enum_values("meshShading")
MESH_SHADING_VALUES = set(MESH_SHADING_OPTIONS)
RENDER_CAMERA_VIEW_PRESETS = schema_definition_enum_values("cameraViewPreset")
RENDER_CAMERA_VIEW_PRESET_VALUES = set(RENDER_CAMERA_VIEW_PRESETS)
if set(CAMERA_VIEW_PRESETS) != RENDER_CAMERA_VIEW_PRESET_VALUES:
    raise RuntimeError("CAMERA_VIEW_PRESETS must match schema $defs.cameraViewPreset")
RENDER_LIGHTING_PRESETS = schema_definition_enum_values("lightingPreset")
RENDER_LIGHTING_PRESET_VALUES = set(RENDER_LIGHTING_PRESETS)


RENDER_ENGINE_VALUES = schema_property_enum("renderConfig", "engine")
RENDER_QUALITY_VALUES = schema_property_enum("renderConfig", "quality")
RENDER_CAMERA_LOOK_AT_VALUES = schema_property_enum("renderConfig", "camera_look_at")
RENDER_CAMERA_VIEW_VALUES = schema_property_enum("renderConfig", "camera_view")
RENDER_OUTPUT_MODES = schema_property_enum_values("renderConfig", "output_mode")
RENDER_OUTPUT_MODE_VALUES = set(RENDER_OUTPUT_MODES)
if DEFAULT_OUTPUT_MODE not in RENDER_OUTPUT_MODE_VALUES:
    raise RuntimeError("DEFAULT_OUTPUT_MODE must be listed in schema render.output_mode")

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

