# Annotation Renderer Utility

This folder contains the reusable OpenSCAD-to-Blender annotation renderer used for MakerWorld-style technical images.

It exports a configured OpenSCAD model with semantic annotation metadata enabled, replaces a named object in a Blender scene, projects SCAD-authored annotation anchors through the real Blender camera, and writes annotated PNGs or unannotated animation GIFs.

## Folder Layout

```text
annotation_renderer/
  README.md
  __main__.py
  config.py
  scene_cli.py
  blender_scene.py
  openscad.py
  overlay.py
  scad_annotations.py
  assets/
    scenes/
      opengrid_wall_scene.blend
  configs/
    animation_examples.json
    gallery_defaults.json
    model_defaults.json
    parameter_details.json
  schemas/
    annotation-render-config.schema.json
    annotation-render-gallery.schema.json
```

## Requirements

Create the shared tooling environment from the repository root:

```powershell
py -3 -m venv build\.venv-tools
build\.venv-tools\Scripts\python -m pip install --upgrade pip
```

The renderer also needs OpenSCAD Nightly and Blender. You can pass explicit executable paths with `--openscad` and `--blender`.

For a local editable install with the console entry point:

```powershell
build\.venv-tools\Scripts\python -m pip install -e .
opengrid-annotate --config annotation_renderer\configs\model_defaults.json --validate-only
```

Install the optional mesh tooling dependencies when running the full test suite or mesh comparison/review scripts:

```powershell
build\.venv-tools\Scripts\python -m pip install -e ".[mesh]"
```

## Render Examples

Validate a config without rendering:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --validate-only
```

Render the first configured variant. In the tracked defaults this is `sturdy_hook_default` with `hook_length=45`:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json
```

Render the hook example explicitly:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --variant sturdy_hook_default
```

Render the shelf example:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --variant sturdy_shelf_default
```

Render the drawer shell example:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --variant drawer_shell_default
```

Render the drawer shell and drawer container as separate OpenSCAD exports imported into one Blender scene:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --variant drawer_shell_container_default
```

Override config values from the command line without editing JSON:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --set model.defines.hook_length=50
```

Render every named variant in a config and build a contact sheet:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --gallery `
  --gallery-config annotation_renderer\configs\gallery_defaults.json
```

Render only one named variant:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --variant sturdy_shelf_default
```

Print the JSON Schema for editor integration:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer --print-schema
```

Print the fully resolved config without invoking OpenSCAD or Blender:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\model_defaults.json `
  --variant drawer_shell_container_default `
  --print-resolved-config
```

`python -m annotation_renderer` and the optional `opengrid-annotate` console script are the supported entry points.

Single outputs are written under `build/scene_annotations/<job-name>__<timestamp>/`. Gallery outputs are written under `build/scene_annotations/<job-name>__gallery__<timestamp>/`, with each variant in its own subfolder plus `gallery.png`. Generated artifacts stay under `build/` and are ignored by git.

## Animation Workflow

Animations are defined in the selected variant under `render.animation`. The renderer still exports the configured OpenSCAD objects and replaces them in the Blender scene, then applies object keyframes before rendering a PNG frame sequence and encoding `animation.gif`. Animation output is unannotated; the same run can still write `render.png` and `annotated.png` for the final still.

The tracked animation examples live in `configs/animation_examples.json`, which extends `model_defaults.json`. Keep stable still-image defaults in `model_defaults.json`; put demo animations and animation-only presets in the extending config.

Use this loop when adding an animation:

1. Add or copy a variant in `configs/animation_examples.json`.
2. Set `scene.objects` to the generated objects that should exist in the scene.
3. Add `render.animation.enabled: true`, `frame_start: 0`, `fps`, and `output_format: "gif"`.
4. Use `clips` when multiple object animations should run in sequence.
5. Validate with `--validate-only`, then render the named variant.

Example render command:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\animation_examples.json `
  --variant drawer_install_then_container_slide_animation
```

Animation examples use constants as presets, so variants can stay small:

```json
{
  "name": "general_holder_insert_animation",
  "model": {"$constant": "general_holder_model"},
  "render": {"$constant": "openconnect_insert_animation_render"},
  "annotations": {}
}
```

The current animation presets are:

* `openconnect_install_keyframes_mm`: authored openconnect installation motion.
* `openconnect_install_track`: object track using those keyframes.
* `drawer_slide_y_50mm_track`: drawer container slide from `Y:-50mm` to final position.
* `fade_in_8f_track`: show at the clip boundary and fade alpha from `0` to `1` over 8 frames.
* `openconnect_insert_animation_render`, `drawer_slide_animation_render`, and `drawer_install_then_slide_animation_render`: full render presets for common GIF jobs.

Animation clips use local frame numbers for their object tracks. The clip `start_frame` shifts those local frames onto the global timeline. This is the compact drawer shell install plus drawer container slide variant:

```json
{
  "name": "drawer_install_then_container_slide_animation",
  "scene": {
    "object_defaults": {"$constant": "drawer_object_defaults"},
    "objects": [
      {"$constant": "drawer_shell_object"},
      {"$constant": "drawer_container_object"}
    ]
  },
  "render": {"$constant": "drawer_install_then_slide_animation_render"},
  "annotations": {}
}
```

Supported object animation fields:

* `location_offset_keyframes_mm`: explicit authored motion keyframes in millimeters. Use this for reusable motions like openconnect installation.
* `from_location_offset_mm` and `to_location_offset_mm`: simple two-keyframe object motion.
* `visible_from_frame`: keep an object hidden until a local or global frame, depending on whether it is inside a clip.
* `visibility_keyframes`: explicit show/hide keyframes.
* `opacity_keyframes`: fade an object's material alpha between `0` and `1`.
* `interpolation` and `opacity_interpolation`: one of `linear`, `constant`, `ease`, `ease_in`, `ease_out`, `ease_in_out`, or `bezier`.

`end_pause_frames` defaults to `12`, so GIFs hold briefly after the last keyframe. Set it in `render.animation` when a different pause length is needed. If `frame_end` is omitted, the renderer derives it from the latest location, visibility, or opacity keyframe, then adds the pause.

Gallery layout is intentionally separate from model defaults:

```json
{
  "$schema": "../schemas/annotation-render-gallery.schema.json",
  "columns": 2,
  "thumbnail_width": 520
}
```

Pass it with `--gallery-config`. A model config can still include top-level `gallery` values, and those override the separate gallery config. This keeps reusable model parameter variants separate from one-off contact-sheet layout choices.

## Config Structure

Configs contain the model parameters, Blender scene binding, render settings, and annotation layout in one file.

The tracked default config is variant-first: hook, shelf, and drawer jobs are all peers under `variants`, while the top level only holds shared scene, render, and constants. Running without `--variant` renders the first variant; `--gallery` renders all variants.

The tracked default config keeps the Blender scene binding explicit:

* `scene.blend_file: "../assets/scenes/opengrid_wall_scene.blend"` for the packaged Blender scene
* `scene.target_object` or `scene.objects[*].target_object` for the object to replace
* `scene.camera: "Camera"` for the render camera
* `render.preset: "cycles_standard_scene"` for Cycles standard quality, camera fitting, and flat STL shading
* `annotations.style.preset: "makerworld_technical_light"` for muted translucent dimension lines and outlined labels

Scene transforms can come from JSON instead of the Blender placeholder object. Set `inherit_target_transform` to `false` and provide `transform`. `location_mm` uses millimeters and is converted to Blender meters internally, while `rotation_deg` and `scale` map directly to the imported STL object transform:

```json
"constants": {
  "drawer_shell_rotation_x_deg": 90,
  "blender_scene_scale": 0.001
},
"scene": {
  "blend_file": "../assets/scenes/opengrid_wall_scene.blend",
  "target_object": "drawer",
  "camera": "Camera",
  "replace_target_object": true,
  "inherit_target_transform": false,
  "transform": {
    "location_mm": [
      "odd(horizontal_grids) * OG_TILE_SIZE / 2",
      0,
      "-OG_TILE_SIZE + odd(vertical_grids) * OG_TILE_SIZE / 2"
    ],
    "rotation_deg": ["drawer_shell_rotation_x_deg", 0, 0],
    "scale": ["blender_scene_scale", "blender_scene_scale", "blender_scene_scale"]
  }
}
```

The expression helper `odd(value)` returns `1` for odd numeric values and `0` for even values, which is useful for half-tile placement corrections.

Expression names can come from top-level numeric `constants`, numeric `model.defines`, and SCAD-emitted numeric context metadata. Prefer SCAD context for values calculated by the model, such as `OG_TILE_SIZE`, `shell_thickness`, `shell_ocslot_part_thickness`, `shelf_back_thickness`, and final derived thicknesses. That keeps JSON transforms and annotation offsets tied to the same OpenSCAD run that generated the STL.

Because SCAD context only exists after export, `--print-resolved-config` may show `transform: null` with the raw `transform_config` for scene objects whose expressions depend on emitted context. A real render resolves those expressions after parsing each object's OpenSCAD log.

Constants can also hold reusable JSON snippets. Use `{"$constant": "name"}` anywhere in the active config to replace that value with the matching constant. When `$constant` appears in an object with other keys, the constant is used as a base object and the other keys override it:

```json
"constants": {
  "blender_scene_scale": 0.001,
  "blender_scene_scale_vector": [
    "blender_scene_scale",
    "blender_scene_scale",
    "blender_scene_scale"
  ],
  "placeholder_transform": {
    "location_mm": [0, 0, 0],
    "rotation_deg": [90, 0, -90],
    "scale": {"$constant": "blender_scene_scale_vector"}
  },
  "small_dimension_chain": {
    "label_font_size_px": 20,
    "tick_length_px": 12
  }
},
"scene": {
  "transform": {"$constant": "placeholder_transform"}
},
"annotations": {
  "chains": [
    {"$constant": "small_dimension_chain", "ids": ["shelf_back_thickness"]}
  ]
}
```

Constant references are resolved after the selected variant and `--set` overrides are applied. Numeric constants still feed expression strings; object, array, string, and boolean constants are only used as reusable config values.

For scenes that need more than one generated object, use `scene.objects`. Put repeated object settings in `scene.object_defaults`; each object is merged over those defaults. This is useful when several objects come from the same SCAD file and mostly share OpenSCAD defines. When `scene.objects` is present, the top-level `model` section is optional:

```json
"constants": {
  "drawer_shell_rotation_x_deg": 90,
  "drawer_container_rotation_x_deg": 0,
  "placeholder_transform": {
    "location_mm": [0, 0, 0],
    "rotation_deg": [90, 0, -90],
    "scale": [0.001, 0.001, 0.001]
  },
  "drawer_common_model": {
    "scad_file": "openconnect_drawer.scad",
    "defines": {
      "generate_drawer_stopper_clips": false,
      "view_drawer_overlapped": false,
      "horizontal_grids": 5,
      "vertical_grids": 2,
      "depth_grids": 5,
      "shell_slot_position": "Back"
    }
  },
  "drawer_object_defaults": {
    "model": {"$constant": "drawer_common_model"},
    "inherit_target_transform": false
  },
  "drawer_shell_object": {
    "id": "drawer_shell",
    "target_object": "drawer",
    "model": {
      "defines": {
        "generate_drawer_shell": true,
        "generate_drawer_container": false
      }
    },
    "transform": {
      "location_mm": [
        "odd(horizontal_grids) * OG_TILE_SIZE / 2",
        0,
        "-OG_TILE_SIZE + odd(vertical_grids) * OG_TILE_SIZE / 2"
      ],
      "rotation_deg": ["drawer_shell_rotation_x_deg", 0, 0]
    }
  },
  "drawer_container_object": {
    "id": "drawer_container",
    "target_object": "drawer_container",
    "material_source_object": "drawer",
    "material": {"color": "#ffffff", "roughness": 0.5},
    "model": {
      "defines": {
        "generate_drawer_shell": false,
        "generate_drawer_container": true
      }
    },
    "transform": {
      "location_mm": [
        "odd(horizontal_grids) * OG_TILE_SIZE / 2",
        "-(shell_ocslot_part_thickness + container_depth_clearance)",
        "-(vertical_grids * OG_TILE_SIZE - shell_thickness - container_height_clearance / 2)"
      ],
      "rotation_deg": ["drawer_container_rotation_x_deg", 0, 0]
    }
  }
},
"scene": {
  "blend_file": "../assets/scenes/opengrid_wall_scene.blend",
  "camera": "Camera",
  "transform": {"$constant": "placeholder_transform"},
  "object_defaults": {
    "$constant": "drawer_object_defaults"
  },
  "objects": [
    {
      "$constant": "drawer_shell_object"
    },
    {
      "$constant": "drawer_container_object"
    }
  ]
}
```

Object defaults and object entries are deep-merged. Nested `model.defines` maps are merged, so object-specific flags can override shared flags without repeating the SCAD file or grid parameters. Object `transform` entries are also merged over the scene transform; in the example above, each object supplies only `location_mm` and `rotation_deg`, while the shared `scale` comes from the scene transform.

If `target_object` exists in the Blender file, the renderer replaces it and copies its material. If it does not exist, the STL is imported as a new object with the configured transform. Use `material_source_object` to copy material from another object in the scene or from a generated object imported earlier in the same render.

Set object-level `material` to override the copied material color. The short form is a hex color string, and the object form also supports `alpha`, `roughness`, and `metallic` values from `0` to `1`:

```json
"material": {
  "color": "#f4f1ea",
  "roughness": 0.55
}
```

For multi-object scenes, set `annotations.object` to choose which generated object supplies the OpenSCAD annotation metadata and receives projected model-space anchors:

```json
"annotations": {
  "object": "drawer_shell",
  "chains": [
    {"ids": ["horizontal_grids"]}
  ]
}
```

`display_offset_mm` accepts numbers or simple expressions. The shelf width example keeps the current offset readable:

```json
"display_offset_mm": [
  "shelf_back_thickness",
  "OG_TILE_SIZE + shelf_back_thickness",
  0
]
```

Here `OG_TILE_SIZE` and `shelf_back_thickness` are intended to come from SCAD context metadata, so the offset follows the actual shelf model settings.

By default, annotation text uses only the emitted label and does not append the current parameter value. That keeps labels stable for documentation, for example `hook_length` or `horizontal_grids x 28mm`. Set `annotations.style.show_values` to `true` only when a render should include text like `hook_length = 45`.

Use `annotations.aliases` to shorten parameter names once for every annotation group. Per-group `labels` still work and override aliases when both are present:

```json
"aliases": {
  "circular_tip_radius": "tip_radius"
}
```

Dimension `chains` draw straight measured spans from emitted `kind=dimension` metadata. The helper lines between the measured feature and the dimension line are dashed by default and inherit the measured segment color. Hide them for a specific chain with `"extension_visible": false`, or tune their pattern with `extension_dash_px` and `extension_gap_px`.

Labels are auto-placed after projection. The renderer preserves the label angle, clamps labels inside the image, and nudges labels along the annotation direction/normal to reduce overlap with other labels drawn in the same overlay step.

`radius_callouts` draw dashed radial leaders from emitted `kind=radius` metadata:

```json
"radius_callouts": [
  {
    "ids": ["circular_corner_radius"],
    "display_offset_mm": [0, 0, 0],
    "labels": {
      "circular_corner_radius": "hook_radius"
    },
    "label_offset_px": 54
  }
]
```

Use the optional `labels` mapping on a chain, radius callout, arc callout, or angle/radius callout to keep the SCAD metadata ID stable while shortening the text for a documentation image.

For radius parameters, prefer `radius_callouts` so the label is attached to a center-to-edge radius leader. Set `label_offset_px` to `0` to align the text directly with the radius line; non-zero values move the label perpendicular to that leader. Use `arc_callouts` when the curve extent itself is the annotated feature or when you want to highlight the affected arc alongside a radius leader. `arc_callouts` draw a projected curve from emitted `kind=arc` metadata:

```json
"arc_callouts": [
  {
    "ids": ["circular_tip_radius_extent"],
    "labels": {
      "circular_tip_radius_extent": "tip radius extent"
    },
    "show_label": false,
    "label_offset_px": 42
  }
]
```

`angle_radius_callouts` pair one emitted `kind=arc` annotation with one emitted `kind=radius` annotation. This is useful for circular tip parameters where the same projected shape should show the affected arc angle and the arc radius without drawing the rest of the circle:

```json
"angle_radius_callouts": [
  {
    "id": "circular_tip_angle_radius",
    "arc_id": "circular_tip_radius_extent",
    "radius_id": "circular_tip_radius",
    "angle_id": "circular_tip_angle",
    "labels": {
      "circular_tip_angle": "tip_angle",
      "circular_tip_radius": "tip_radius"
    },
    "angle_label_offset_px": 34,
    "radius_label_offset_px": 32
  }
]
```

The renderer draws only the sampled arc plus one dashed radius leader from the radius center toward the emitted radius edge. The dashed radius uses the same default dash, gap, halo, and line width behavior as `radius_callouts`. `angle_id` can point at a numeric SCAD context value, so `annotations.style.show_values` can append the actual angle when a value-bearing render is needed.

`image_labels` draw screen-space labels without a model anchor. Use them for parameters that describe a variant or mode rather than a specific geometric span:

```json
"image_labels": [
  {
    "id": "hook_shape_type",
    "position": "bottom",
    "offset_px": [0, -24],
    "show_value": true
  }
]
```

When `show_value` is true, image labels first use an explicit `value`, then `model.defines`, then numeric SCAD context metadata from the annotated object. That lets labels such as `shell_thickness`, `handle_depth`, or `shelf_texture_depth` show the actual value used by OpenSCAD without repeating it in JSON.

Annotation groups can override label and line sizing when a parameter span is physically small:

```json
{
  "ids": ["shelf_back_thickness"],
  "label_font_size_px": 20,
  "tick_length_px": 12,
  "line_width_px": 2.2,
  "extension_visible": false
}
```

## Variants

Use top-level `variants` when several images share most of the same scene and render settings. The tracked defaults use variants for every model-specific job so hook, shelf, and drawer configs stay structurally equal. Each variant has a `name` and can either set complete sections or use a `set` object whose keys are dotted config paths:

```json
"variants": [
  {
    "name": "deep_drawer_shell",
    "set": {
      "model.defines.depth_grids": 6
    }
  }
]
```

Variant objects can also override full config sections when a dotted path is not enough. `model` and `annotations` are replaced as complete sections so model-specific labels do not leak between variants. `constants`, `scene`, and `render` are merged with the base config so shared Blender scene settings can stay in one place.

`model_defaults.json` keeps the default variants intentionally sparse. Extra parameter groups live in `configs/parameter_details.json`, which extends the defaults and replaces the variant list with secondary detail renders:

```powershell
build\.venv-tools\Scripts\python -m annotation_renderer `
  --config annotation_renderer\configs\parameter_details.json `
  --variant sturdy_hook_circular_details
```

Current parameter-detail variants:

* `sturdy_hook_circular_details`: `hook_width`, `circular_corner_radius`, `circular_tip_radius`, `circular_tip_angle`
* `sturdy_hook_rectangular_details`: `hook_width`, `rectangular_tip_extra_length`, `hook_shape_type`
* `sturdy_hook_truss_details`: `truss_vertical_grids`, `truss_thickness`, `truss_max_angle`
* `sturdy_shelf_truss_details`: `truss_beam_reach`, `truss_thickness`, `truss_strut_interval`, `shelf_corner_fillet`
* `sturdy_shelf_edge_texture_details`: `shelf_side_edge_depth`, `shelf_front_edge_depth`, `shelf_texture_depth`
* `drawer_shell_clearance_details`: `shell_thickness`, container width/height/depth clearances, `container_front_back_height_offset`
* `drawer_container_label_handle_details`: `handle_depth`, `label_width`, `label_height`, stopper settings, and magnet diameters

Use `extends` in a config when a secondary parameter set should reuse `model_defaults.json` constants, scene binding, and render presets without copying them:

```json
{
  "extends": "model_defaults.json",
  "job_name": "my_parameter_details",
  "variants": []
}
```

## SCAD Annotation Contract

To make a model compatible, add:

```scad
emit_annotation_metadata = false;
```

Then emit lines using the `OPENGRID_ANNOTATION_V1` format when that flag is true. Dimension anchors are model-local coordinates:

```text
OPENGRID_ANNOTATION_V1|id=shelf_width|kind=dimension|label=shelf_width|axis=z|value=84|start=0,-28,0|end=0,-28,84|basis=left_to_right_width
```

Radius callouts use `center` and `edge` instead of `start` and `end`:

```text
OPENGRID_ANNOTATION_V1|id=circular_corner_radius|kind=radius|label=circular_corner_radius|value=15|center=18.5,-13,28|edge=7.89,-23.61,28|basis=first_circular_corner_radius
```

Feature markers use a single `anchor`. They are useful for machine-readable landmarks such as the start and end of a curved region, and they do not require visible marker geometry in the exported model:

```text
OPENGRID_ANNOTATION_V1|id=circular_tip_radius_start|kind=feature|label=circular_tip_radius_start|value=15|anchor=33.5,-24.78,28|basis=start_of_tip_radius_arc_from_turtle_path
```

Arc callouts use `points`, a semicolon-separated list of model-local 3D points sampled along the curve. The renderer projects those points and draws the curve on the clean render:

```text
OPENGRID_ANNOTATION_V1|id=circular_tip_radius_extent|kind=arc|label=circular_tip_radius_extent|value=15|points=33.5,-24.78,28;38.1,-24.05,28;...|basis=tip_radius_arc_from_turtle_path
```

Models can also emit numeric context values for renderer expressions. Prefer the bundled form when several values are needed:

```text
OPENGRID_ANNOTATION_V1|id=drawer_context|kind=context|values=OG_TILE_SIZE=28;shell_thickness=2.4;shell_ocslot_part_thickness=3.6
```

Use `kind=context` for any numeric SCAD value that JSON transforms or annotation offsets should reference. These entries are not drawn directly. The older single-value form, `id=shell_thickness|kind=context|value=2.4`, is still supported.

The renderer applies config offsets in model-local coordinates before Blender object transform and camera projection.

## Notes

For OpenSCAD STL imports, `mesh_shading: "flat"` is usually the safer default because blanket smooth shading can show artificial triangular bands on curved generated surfaces.
