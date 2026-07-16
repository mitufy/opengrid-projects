# Annotation Renderer Reference

This is the detailed reference for the reusable OpenSCAD-to-Blender annotation
renderer used for MakerWorld-style technical images. Start with `README.md` for
setup and the shortest command path, then use this file when you need the full
config and SCAD metadata contract.

It exports a configured OpenSCAD model with semantic annotation metadata enabled, replaces a named object in a Blender scene, projects SCAD-authored annotation anchors through the real Blender camera, and writes annotated PNGs or unannotated animation GIFs.

## Documentation Map

* `README.md`: short setup and quick-start commands.
* `USAGE.md`: practical render, customization, gallery, animation, and troubleshooting workflows.
* `REFERENCE.md`: full config, scene, annotation, animation, and SCAD metadata reference.
* `schemas/annotation-render-config.schema.json`: machine-readable config schema for validation and editor integration.
* `schemas/annotation-render-gallery.schema.json`: gallery contact-sheet settings schema.

## Folder Layout

```text
annotation_renderer/
  README.md
  USAGE.md
  REFERENCE.md
  __main__.py
  scene_cli.py              # CLI orchestration
  blender_runtime.py        # script executed inside Blender
  config*.py                # schema, defaults, loading, validation, resolution
  annotation_config.py      # annotation config collection helpers
  openscad.py               # OpenSCAD command helpers
  overlay.py                # Pillow annotation overlay drawing
  scad_annotations.py       # OpenSCAD echo metadata parser
  scad_discovery.py         # source-level annotation discovery
  assets/
    *.stl
    scenes/
      opengrid_wall_scene.blend
  configs/
    *_default.yaml          # directly renderable model defaults
    *_copies.yaml           # STL copy/grid scene examples
    animation_presets.yaml
    base_scene.yaml
    gallery_defaults.yaml
    model_defaults.yaml     # imports renderable defaults as variants
    parameter_details.yaml
    render_settings_gallery.yaml
  schemas/
    annotation-render-config.schema.json
    annotation-render-gallery.schema.json
```

## Requirements

Use Python 3.10 or newer. The setup example uses the Windows Python launcher as `py -3` to create a virtual environment with an installed Python 3 runtime. After installing dependencies, run renderer commands through the virtual environment's `python.exe` or `opengrid-annotate.exe`.

Create the shared tooling environment from the repository root:

```powershell
py -3 -m venv build\.venv-tools
.\build\.venv-tools\Scripts\python.exe -m pip install --upgrade pip
```

The renderer also needs OpenSCAD Nightly and Blender 5.1 or newer. The bundled scenes use Blender 5.1's compressed file format. You can pass explicit executable paths with `--openscad` and `--blender`.

For a local editable install with the console entry point:

```powershell
.\build\.venv-tools\Scripts\python.exe -m pip install -e .
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder --validate-only
```

Check the local environment before rendering:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor
```

Run one minimal end-to-end render as part of the check:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor --smoke-render
```

Install the optional mesh tooling dependencies and test runner when running the full test suite or mesh comparison/review scripts:

```powershell
.\build\.venv-tools\Scripts\python.exe -m pip install -e ".[mesh,test]"
```

## Command Overview

`opengrid-annotate` is the primary entry point. `python -m annotation_renderer`
accepts the same arguments when the package is not installed as a console
script. See `USAGE.md` for the common workflow.

Essential commands:

```powershell
# Render the default config for one SCAD model
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder

# Validate the default config without rendering
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder --validate-only

# Validate every variant in a model config
.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder

# Render a named config from annotation_renderer\configs without --config
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_sturdy_hook_angle

# Render one config path directly
.\build\.venv-tools\Scripts\opengrid-annotate.exe `
  --config annotation_renderer\configs\openconnect_general_holder_default.yaml

# Render one imported model variant
.\build\.venv-tools\Scripts\opengrid-annotate.exe `
  --config annotation_renderer\configs\model_defaults.yaml `
  --variant openconnect_sturdy_hook_default

# Render a contact sheet for all variants
.\build\.venv-tools\Scripts\opengrid-annotate.exe `
  --config annotation_renderer\configs\model_defaults.yaml `
  --gallery `
  --gallery-config annotation_renderer\configs\gallery_defaults.yaml

# Render the scene-control demonstration gallery
.\build\.venv-tools\Scripts\opengrid-annotate.exe `
  --config annotation_renderer\configs\render_settings_gallery.yaml `
  --gallery
```

Use `--set path=value` for one-off overrides, `--print-resolved-config` to inspect merged config, `--print-schema` for editor integration, and `doctor` to check local dependencies. Array items can be selected by stable `id` or `name`, such as `scene.objects.model.model.defines.hook_length=50`, or by numeric index for compatibility, such as `annotations.chains[0].label_offset_px=36`. Use `--output-file path\image.png` when a workflow needs a stable final still-image path.

OpenSCAD exports and Blender render/projection outputs are cached by default under `build/scene_annotations/.cache`, keyed by the transitive OpenSCAD dependency contents, executable contents, resolved render inputs, and generated STL content. This makes iterative annotation offset changes reuse the expensive stages without serving stale geometry after shared-library edits. Use `--no-cache` for a cold run, `--cache-dir path\to\cache` to override the cache directory, or set `render.cache` / `render.cache_dir` in config. Blender stage caching is disabled for animation renders.

Use `--export-blend` or `render.export_blend: true` to save the prepared Blender scene used for the still render. The `.blend` sidecar is written next to the final PNG or exact `--output-file` path. When a Blender render is served from cache, the cache must also contain the prepared `.blend`; otherwise the Blender stage runs once to create it.

Final render images are grouped by SCAD source under `build/scene_annotations/<scad-file-stem>/`, for example `build/scene_annotations/openconnect_general_holder/general_holder_scene_default__20260513-215208.png`. Gallery runs create a timestamped gallery folder and write `gallery.png` plus `gallery_metadata.json`.

Use `--output-mode` or `render.output_mode` to control retained sidecars:

* `minimal`: keep only final image outputs, such as `.png` or `.gif`
* `standard`: keep final image outputs plus a matching `.metadata.json` sidecar
* `debug`: keep final image outputs, metadata, and all working artifacts under `<scad-file-stem>/debug/<job-name>__<timestamp>/`

`standard` is the default. Generated artifacts stay under `build/` and are ignored by git.

When generated label bounding boxes overlap, or emitted annotation anchors are
well outside the exported STL bounds, the renderer prints a warning and stores
the warning in metadata when metadata is enabled.

## Discovery And Templates

Discovery commands default to `configs/model_defaults.yaml`, so they can be used without passing `--config`.

List the renderable default models:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe list-models
```

Describe one model preset:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe describe openconnect_general_holder
```

List annotation groups and their current offsets:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe list-annotations openconnect_general_holder
```

List the parameters that can be added to annotation config:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_sturdy_hook.scad
```

The discovery output reads the SCAD source directly. Pass a `.scad` file path, not a render config name such as `openconnect_sturdy_hook_default` or `openconnect_drawer_shell_container_default`. It lists Customizer-facing annotation parameters without running OpenSCAD, so it does not include exact values that depend on customizable model parameters. Internal helper metadata used to draw composed arcs and radius leaders is hidden from discovery. The list is grouped by config use:

* `dimension parameters` can be added to `annotations.chains[].ids`
* `radius parameters` can be added to `annotations.radius_callouts[].ids` or `annotations.angle_radius_callouts[].radius_id`
* `arc parameters` can be added to `annotations.arc_callouts[].ids` or `annotations.angle_radius_callouts[].arc_id`
* `context value parameters` can be added to `annotations.image_labels[].id`; numeric values can also be used in offsets and `annotations.angle_radius_callouts[].angle_id`

By default, discovery only prints the plain text list. Add `--out` when you want a file:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_sturdy_hook.scad `
  --out build\scene_annotations\sturdy_hook_annotations.yaml
```

`--out` supports `.txt` for the same plain text list, `.yaml` or `.yml` for editable structured output, and `.json` for machine-readable output. Discovery does not generate temporary STL or OpenSCAD log files.

Generate a compact editable config that extends a default model:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe new-config openconnect_general_holder `
  --out build\scene_annotations\my_holder.yaml
```

The generated config includes editable object-scoped model defines and annotation offset groups, plus a `scene.blend_file` path rewritten relative to the output file so it validates from any folder. Use a `.yaml` or `.yml` output path to write YAML, or `.json` to write JSON.

## YAML And JSON

The renderer accepts `.yaml`, `.yml`, and `.json` files anywhere a config path is used, including `--config`, `--gallery-config`, `extends`, and `variant_configs`. The checked-in defaults are YAML now, and new custom configs should also prefer YAML because it is easier to read and edit by hand. JSON remains supported for external configs, but the old checked-in JSON config paths are gone:

```yaml
extends: ../../annotation_renderer/configs/openconnect_general_holder_default.yaml
job_name: general_holder_custom

scene:
  objects:
    - id: model
      model:
        scad_file: openconnect_general_holder.scad
        defines:
          compartment_shape: Rectangular
          compartment_column_count: 2
          compartment_row_count: 1

annotations:
  chains:
    - ids: [compartment_width]
      display_offset_mm: [0, 0, 0]
      line_offset_px: 20
      label_offset_px: 28
```

Keep using the existing `extends` and `$constant` composition features instead of YAML anchors or merge keys. That keeps configs portable between YAML and JSON.

Checked-in model configs use the built-in `default_annotation_style` constant for shared annotation line, font, color-type, and image-title defaults. Those values live in `config_defaults.py` under the `makerworld_technical_light` style preset, so `configs/base_scene.yaml` does not duplicate them. Use `style.type_styles` for broad parameter categories such as `mm`, `grids`, `radius`, and `angle`. Put color overrides on the chain or callout that uses them with `color`; use `colors` only when one group needs per-ID exceptions. Keep model-specific offsets local, and override only the style keys that differ:

```yaml
constants:
  my_annotations:
    style:
      $constant: default_annotation_style
      tick_length_px: 15
```

Grid-count annotations should use their actual parameter IDs in `chains`, then add the display affix through aliases. The built-in `default_grid_label_aliases` constant covers `horizontal_grids`, `vertical_grids`, and `depth_grids`:

```yaml
annotations:
  aliases:
    $constant: default_grid_label_aliases
  chains:
    - ids: [horizontal_grids]
```

## Animation Workflow

Animations are defined by applying a render animation preset with `--animation-preset`. The renderer still exports the configured OpenSCAD objects and replaces them in the Blender scene, then applies object keyframes before rendering a PNG frame sequence and encoding a GIF. The shortcut clears annotation groups for the run, so animation outputs are unannotated.

Reusable animation presets live in `configs/animation_presets.yaml`. The CLI loads that file as the central animation registry, then merges any same-named constants from the selected model config. Animation settings therefore remain reusable without requiring every model config to inherit through the preset file.

Use this loop when adding an animation:

1. Add a reusable render preset under `constants` in `configs/animation_presets.yaml`.
2. Use `object_animations` for one-object motion or `clips` when multiple object animations should run in sequence.
3. Validate the target model config with `--animation-preset <preset> --validate-only`.
4. Render the target model config with that preset.

Example render command:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_drawer_shell_container `
  --animation-preset drawer_install_then_slide_animation_render
```

Sturdy shelf insert animation:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_sturdy_shelf `
  --animation-preset openconnect_insert_animation_render
```

The current animation presets are:

* `openconnect_install_keyframes_mm`: authored openconnect installation motion.
* `openconnect_install_track`: object track using those keyframes.
* `drawer_slide_y_50mm_track`: drawer container slide from `Y:-50mm` to final position.
* `fade_in_8f_track`: show at the clip boundary and fade alpha from `0` to `1` over 8 frames.
* `openconnect_insert_animation_render`, `drawer_slide_animation_render`, and `drawer_install_then_slide_animation_render`: full render presets for common GIF jobs.

Animation clips use local frame numbers for their object tracks. The clip `start_frame` shifts those local frames onto the global timeline. This is the compact drawer shell install plus drawer container slide preset:

```yaml
drawer_install_then_slide_animation_render:
  engine: eevee
  quality: draft
  fit_margin: 0.14
  animation:
    enabled: true
    duration_frames: 48
    clips:
    - name: shell_openconnect_install
      start_frame: 0
      object_animations:
      - $constant: openconnect_install_track
        object: drawer_shell
    - name: container_slide
      start_frame: 48
      interpolation: ease_out
      object_animations:
      - $constant: fade_in_8f_track
        object: drawer_container
        from_location_offset_mm: [0, -50, 0]
        to_location_offset_mm: [0, 0, 0]
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

```yaml
$schema: ../schemas/annotation-render-gallery.schema.json
variant_collection: product_views
columns: 2
thumbnail_width: 520
margin_px: 12
gutter_px: 12
title_height_px: 22
title_font_size_px: 22
```

Pass it with `--gallery-config`. `variant_collection` selects the default ordered subset for a gallery. A model config can still include top-level `gallery` values, and those override the separate gallery config. Explicit `--variant` or `--variant-collection` arguments override the configured collection. This keeps reusable model variants in the model config while allowing one-off contact-sheet selection and layout choices to stay external.

For an exact contact-sheet size without post-scaling or padding, set `target_width_px` and `target_height_px` instead of hand-calculating `thumbnail_width` and per-render `render.width` / `render.height`:

```yaml
gallery:
  columns: 2
  target_width_px: 1920
  target_height_px: 1440
  margin_px: 0
  gutter_px: 4
  title_height_px: 60
  title_font_size_px: 60
```

The gallery runner derives `thumbnail_width`, `thumbnail_height`, and each variant's render size from the target dimensions, row count, margins, gutters, and title height. The target size must divide evenly after subtracting those spacing values.

## Config Structure

Configs contain the model parameters, Blender scene binding, render settings, and annotation layout in one file.

The tracked defaults are split by model. `base_scene.yaml` holds shared scene, render, and annotation constants. Each model default extends it and is directly renderable. `model_defaults.yaml` imports the per-model files with `variant_configs`, so running it without `--variant` renders the first imported variant and `--gallery` renders all imported variants.

The tracked default config keeps the Blender scene and render binding explicit:

* `scene.blend_file: "../assets/scenes/opengrid_wall_scene.blend"` for the packaged Blender scene
* `scene.objects[*].id` for stable generated object names used by annotations and render controls
* `scene.camera: "Camera"` for the render camera
* `render.preset: "cycles_standard_scene"` for Cycles standard quality, camera fitting, and flat STL shading
* `annotations.style.preset: "makerworld_technical_light"` for muted translucent dimension lines and outlined labels

New render scene controls are opt-in. Existing configs keep their default render behavior unless they explicitly set fields such as `camera_view_preset`, `lighting`, `outline`, `ground_plane`, `cutaway`, `xray`, or `material_overrides`.

Scene transforms usually come from config. Set `inherit_target_transform` to `false` and provide `transform`. `location_mm` uses millimeters and is converted to Blender meters internally, while `rotation_deg` and `scale` map directly to the imported STL object transform:

```yaml
constants:
  drawer_shell_rotation_x_deg: 90
  blender_scene_scale: 0.001
scene:
  blend_file: ../assets/scenes/opengrid_wall_scene.blend
  objects:
  - id: drawer_shell
    model:
      scad_file: openconnect_drawer.scad
  camera: Camera
  replace_target_object: true
  inherit_target_transform: false
  transform:
    location_mm:
      - odd(horizontal_grids) * OG_TILE_SIZE / 2
      - 0
      - -OG_TILE_SIZE + odd(vertical_grids) * OG_TILE_SIZE / 2
    rotation_deg: [drawer_shell_rotation_x_deg, 0, 0]
    scale: [blender_scene_scale, blender_scene_scale, blender_scene_scale]
```

The expression helper `odd(value)` returns `1` for odd numeric values and `0` for even values, which is useful for half-tile placement corrections.

Use `render.camera_location_offset_mm` when the fitted camera needs to move after framing the model. If the camera should still point at the model after that move, set `render.camera_look_at: object_center`:

```yaml
render:
  camera_location_offset_mm: [0, 0, 50]
  camera_look_at: object_center
```

`camera_look_at` defaults to `none`. With `object_center`, the runtime rotates the render camera toward the combined generated-object bounding-box center before fitting and repeats that rotation after any location offset.

Use `render.camera_view` for a named model-relative side view without tuning manual offsets:

```yaml
render:
  camera_view: left
```

Supported values are `front`, `back`, `left`, `right`, `top`, `bottom`, and `none`. Named views use the first generated object's transformed local axes, place the camera on that side of the combined object bounds, aim it at the object center, and then use the normal camera fitting pass.

When `camera_view` is set, it owns the initial object-center aim. `camera_look_at` is only applied when `camera_view` is `none`; after a manual `camera_location_offset_mm`, the named view is re-aimed and fitted again.

Use `render.camera_rotation_deg` when a render needs an explicit base camera Euler rotation before fitting:

```yaml
render:
  camera_rotation_deg: [0, -90, 0]
```

This is applied before `camera_view` and `camera_look_at`, so those higher-level aiming options override it when configured.

Use `render.camera_rotation_offset_deg` for a final additive rotation tweak after camera view, look-at, fitting, location offset, orbit, and target-offset handling:

```yaml
render:
  camera_rotation_offset_deg: [0, 0, 5]
```

This adds XYZ Euler degrees to the camera's current rotation. It is useful for small framing adjustments without replacing the base camera rotation.

Expression names can come from top-level numeric `constants`, numeric `scene.objects[*].model.defines` for the active object, and SCAD-emitted numeric context metadata. Prefer SCAD context for values calculated by the model, such as `OG_TILE_SIZE`, `shell_thickness`, `shell_ocslot_part_thickness`, `shelf_back_thickness`, and final derived thicknesses. That keeps config transforms and annotation offsets tied to the same OpenSCAD run that generated the STL.

Because SCAD context only exists after export, `--print-resolved-config` may show `transform: null` with the raw `transform_config` for scene objects whose expressions depend on emitted context. A real render resolves those expressions after parsing each object's OpenSCAD log.

Constants can also hold reusable config snippets. Use `{"$constant": "name"}` in JSON or `$constant: name` in YAML anywhere in the active config to replace that value with the matching constant. When `$constant` appears in an object with other keys, the constant is used as a base object and the other keys override it:

```yaml
constants:
  blender_scene_scale: 0.001
  blender_scene_scale_vector: [blender_scene_scale, blender_scene_scale, blender_scene_scale]
  placeholder_transform:
    location_mm: [0, 0, 0]
    rotation_deg: [0, 0, 0]
    scale:
      $constant: blender_scene_scale_vector
  small_dimension_chain:
    label_font_size_px: 20
    tick_length_px: 12
scene:
  transform:
    $constant: placeholder_transform
annotations:
  chains:
    - $constant: small_dimension_chain
      ids: [shelf_back_thickness]
```

Constant references are resolved after the selected variant and `--set` overrides are applied. Numeric constants still feed expression strings; object, array, string, and boolean constants are only used as reusable config values.

Variants can inherit another variant with `extends_variant`. This is useful when a secondary still-image variant should keep another variant's model, scene, and render settings while changing only a few fields:

```yaml
variants:
- name: general_holder_large_opening
  extends_variant: openconnect_general_holder_default
  set:
    scene.objects[0].model.defines.front_opening_width: 38
```

Use `scene.objects` for every renderable source. Each object must define exactly one source: `model` for an OpenSCAD-generated STL, or `stl_file` for a prebuilt STL asset. Put repeated object settings in `scene.object_defaults`; each object is merged over those defaults. This is useful when several objects come from the same SCAD file and mostly share OpenSCAD defines:

```yaml
constants:
  drawer_shell_rotation_x_deg: 90
  drawer_container_rotation_x_deg: 0
  placeholder_transform:
    location_mm: [0, 0, 0]
    rotation_deg: [0, 0, 0]
    scale: [0.001, 0.001, 0.001]
  drawer_common_model:
    scad_file: openconnect_drawer.scad
    defines:
      generate_drawer_stopper_clips: false
      view_drawer_overlapped: false
      horizontal_grids: 5
      vertical_grids: 2
      depth_grids: 5
      shell_slot_position: Back
  drawer_object_defaults:
    model:
      $constant: drawer_common_model
    inherit_target_transform: false
  drawer_shell_object:
    id: drawer_shell
    model:
      defines:
        generate_drawer_shell: true
        generate_drawer_container: false
    transform:
      location_mm:
        - odd(horizontal_grids) * OG_TILE_SIZE / 2
        - 0
        - -OG_TILE_SIZE + odd(vertical_grids) * OG_TILE_SIZE / 2
      rotation_deg: [drawer_shell_rotation_x_deg, 0, 0]
  drawer_container_object:
    id: drawer_container
    material:
      color: '#ffffff'
      roughness: 0.5
    model:
      defines:
        generate_drawer_shell: false
        generate_drawer_container: true
    transform:
      location_mm:
        - odd(horizontal_grids) * OG_TILE_SIZE / 2
        - -(shell_ocslot_part_thickness + container_depth_clearance)
        - -(vertical_grids * OG_TILE_SIZE - shell_thickness - container_height_clearance / 2)
      rotation_deg: [drawer_container_rotation_x_deg, 0, 0]
scene:
  blend_file: ../assets/scenes/opengrid_wall_scene.blend
  camera: Camera
  transform:
    $constant: placeholder_transform
  object_defaults:
    $constant: drawer_object_defaults
  objects:
    - $constant: drawer_shell_object
    - $constant: drawer_container_object
```

Object defaults and object entries are deep-merged. Nested `model.defines` maps are merged, so object-specific flags can override shared flags without repeating the SCAD file or grid parameters. Object `transform` entries are also merged over the scene transform; in the example above, each object supplies only `location_mm` and `rotation_deg`, while the shared `scale` comes from the scene transform.

Prebuilt STL assets use the same object transform, material, and camera-fit path as generated models:

```yaml
scene:
  objects:
    - id: snap
      stl_file: ../assets/openconnect_standard_snap.stl
      inherit_target_transform: false
      transform:
        location_mm: ["-(og_tile_size / 2)", og_standard_thickness, "-(og_tile_size / 2)"]
        rotation_deg: [90, 0, 0]
        scale: [0.001, 0.001, 0.001]
```

Use `line_copies` when several copies of one object should be laid out at a fixed spacing. The renderer expands this into suffixed object IDs such as `snap_0` and `snap_1`:

```yaml
scene:
  objects:
    - id: snap
      stl_file: ../assets/openconnect_standard_snap.stl
      inherit_target_transform: false
      transform:
        location_mm: ["-(og_tile_size / 2)", og_standard_thickness, "-(og_tile_size / 2)"]
        rotation_deg: [90, 0, 0]
        scale: [0.001, 0.001, 0.001]
      line_copies:
        count: 2
        spacing_mm: [og_tile_size, 0, 0]
```

Use `grid_copies` for a 3D copy grid. `counts` are ordered `[x, y, z]`, so this creates two columns and two Z rows:

```yaml
scene:
  objects:
    - id: snap
      stl_file: ../assets/openconnect_standard_snap.stl
      inherit_target_transform: false
      transform:
        location_mm: ["-(og_tile_size / 2)", og_standard_thickness, "-(og_tile_size / 2)"]
        rotation_deg: [90, 0, 0]
        scale: [0.001, 0.001, 0.001]
      grid_copies:
        counts: [2, 1, 2]
        spacing_mm: [og_tile_size, 0, og_tile_size]
```

If `target_object` exists in the Blender file, the renderer replaces it and copies its material. If it does not exist, the STL is imported as a new object with the configured transform. Use `material_source_object` to copy material from another object in the scene or from an object imported earlier in the same render.

Set object-level `material` to override the copied material color. The short form is a hex color string, and the object form also supports `alpha`, `roughness`, and `metallic` values from `0` to `1`:

```yaml
material:
  color: '#f4f1ea'
  roughness: 0.55
```

Imported models that have no explicit material and cannot copy one from a target or `material_source_object` receive `render.default_material_color`. Its built-in value is `#cccccc`; set it at render level to choose another fallback color:

```yaml
render:
  default_material_color: '#d6d3d1'
```

You can also override object materials from `render.material_overrides` when the same scene needs a different visual treatment without changing the scene object definitions:

```yaml
render:
  material_overrides:
    snap_0:
      color: '#94a3b8'
      alpha: 0.35
```

Scene render controls live under `render` and are applied in Blender after the objects are imported. Camera presets provide compact view bundles, while explicit camera fields still override the preset values:

```yaml
render:
  camera_view_preset: technical_iso
  camera_orbit_deg: [30, 12]
  camera_distance_scale: 1.25
  camera_target_offset_mm: [0, compartment_width / 2, 0]
  camera_roll_deg: 4
  camera_lens_mm: 70
```

Additional Blender scene controls:

* `lighting`: `scene`, `technical`, `softbox`, `front_lit`, `dramatic`, or `flat`; object form supports `preset`, `strength`, `ambient_strength`, `color`, `toplight_power`, and `frontlight_power`. `toplight_power` and `frontlight_power` set the Blender scene lights named `TopLight` and `FrontLight`; use them with `preset: scene` when keeping the bundled scene lights.
* `outline`: enables Freestyle outlines; object form supports `enabled`, `line_color`, and `line_width_px`.
* `ground_plane`: adds a floor plane below the model; object form supports `offset_mm`, `size_scale`, `color`, `alpha`, `roughness`, and `shadow_only`.
* `cutaway`: adds a boolean half-space cutter; object form supports `objects`, `axis`, `keep`, `position_mm`, `position_fraction`, `offset_mm`, and `section_plane`. `position_mm` is an absolute scene-axis position. `position_fraction` is usually easier: `0` means the selected bounds minimum, `0.5` means center, and `1` means bounds maximum. Without either, `offset_mm` is relative to the selected objects' bounding-box center.
* `xray`: makes selected objects transparent; object form supports `objects`, `alpha`, and `color`.

Example:

```yaml
render:
  lighting:
    preset: scene
    toplight_power: 175
    frontlight_power: 80
  outline:
    enabled: true
    line_width_px: 1.4
  ground_plane:
    enabled: true
    offset_mm: -1
    color: '#f8fafc'
  xray:
    objects: [snap_0, snap_1]
    alpha: 0.28
```

Clear cross-section example:

```yaml
render:
  cutaway:
    enabled: true
    axis: x
    keep: negative
    position_fraction: 0.72
    section_plane:
      enabled: true
      color: '#f97316'
      alpha: 0.35
      padding_mm: 1
```

For multi-object scenes, set `annotations.object` to choose which generated object supplies the OpenSCAD annotation metadata and receives projected model-space anchors:

```yaml
annotations:
  object: drawer_shell
  chains:
    - ids: [horizontal_grids]
```

`display_offset_mm` translates emitted annotation anchors in model-local millimeters. `display_rotation_deg` rotates those same anchors in model-local degrees before that offset is applied. Rotation uses `[x, y, z]` order, matching the OpenSCAD annotation helper transform order. Both fields accept numbers or simple expressions. The shelf width example keeps the current offset readable:

```yaml
display_offset_mm:
  - shelf_back_thickness
  - OG_TILE_SIZE + shelf_back_thickness
  - 0
```

Here `OG_TILE_SIZE` and `shelf_back_thickness` are intended to come from SCAD context metadata, so the offset follows the actual shelf model settings.

Use `display_rotation_deg` when an emitted anchor is correct in shape but needs to be presented from another local orientation:

```yaml
chains:
  - ids: [stem_bottom_width]
    display_rotation_deg: [0, 0, 90]
    display_offset_mm: [0, 0, 0]
```

By default, annotation text uses only the emitted label or config alias and does not append the current parameter value. That keeps labels stable for documentation, for example `hook_length` or `horizontal_grids x 28mm`. Set `annotations.style.show_values` to `true` only when a render should include text like `hook_length = 45`.

Use `annotations.aliases` to shorten parameter names once for every annotation group. Per-group `labels` still work and override aliases when both are present:

```yaml
aliases:
  circular_tip_radius: tip_radius
```

Dimension `chains` draw straight measured spans from emitted `kind=dimension` metadata. The helper lines between the measured feature and the dimension line are dashed by default and inherit the measured segment color. Hide them for a specific chain with `extension_visible: false`, or tune their pattern with `extension_dash_px` and `extension_gap_px`.

Labels use their projected anchor and configured offsets by default. For dimension chains, `label_offset_px` moves text perpendicular to the dimension line, and `label_along_offset_px` moves text along the rendered dimension direction from start to end. The renderer still reports final label overlap warnings when labels collide. Set `annotations.style.auto_adjust_labels` to `true` to enable automatic placement; when enabled, the renderer preserves the label angle, clamps labels inside the image, and may further nudge dimension-chain labels along the annotation direction to reduce overlap with other labels drawn in the same overlay step.

```yaml
annotations:
  style:
    auto_adjust_labels: true
  chains:
  - ids: [compartment_depth]
    color: "#000000"
    label_offset_px: -28
    label_along_offset_px: 36
```

`radius_callouts` draw dashed radial leaders from emitted `kind=radius` metadata:

```yaml
radius_callouts:
  - ids: [hook_corner_fillet]
    display_offset_mm: [0, 0, 0]
    labels:
      hook_corner_fillet: corner_fillet
    color: "#dc2626"
    label_offset_px: 54
```

Use the optional `labels` mapping on a chain, radius callout, arc callout, or angle/radius callout to keep the SCAD metadata ID stable while shortening the text for a documentation image. Use `color` on those same groups to override their type style color. If a multi-ID group needs mixed colors, add `colors` entries for the IDs that should differ from the group `color`.

For radius parameters, prefer `radius_callouts` so the label is attached to a center-to-edge radius leader. Set `label_offset_px` to `0` to align the text directly with the radius line; non-zero values move the label perpendicular to that leader. `arc_callouts` are advanced: they draw a projected curve from emitted `kind=arc` helper metadata, which is usually internal and hidden from discovery:

```yaml
arc_callouts:
  - ids: [circular_tip_radius_extent]
    labels:
      circular_tip_radius_extent: tip radius extent
    show_label: false
    label_offset_px: 42
```

`angle_radius_callouts` pair one emitted `kind=arc` helper annotation with one emitted `kind=radius` annotation. This is useful for Customizer parameters where the same projected shape should show an angle and radius without drawing the rest of the circle:

```yaml
angle_radius_callouts:
  - id: circular_tip_angle_radius
    arc_id: circular_tip_radius_extent
    radius_id: circular_tip_radius
    angle_id: circular_tip_angle
    labels:
      circular_tip_angle: tip_angle
      circular_tip_radius: tip_radius
    angle_label_offset_px: 34
    radius_label_offset_px: 32
```

The renderer draws only the sampled arc plus one dashed radius leader from the radius center toward the emitted radius edge. The dashed radius uses the same default dash, gap, halo, and line width behavior as `radius_callouts`. `angle_id` can point at a numeric SCAD context value, so `annotations.style.show_values` can append the actual angle when a value-bearing render is needed.

`image_labels` draw screen-space labels without a model anchor. Use them for parameters that describe a variant or mode rather than a specific geometric span:

```yaml
image_labels:
  - id: hook_shape_type
    position: bottom
    offset_px: [0, -24]
    show_value: true
    title_area: true
```

When `show_value` is true, image labels first use an explicit `value`, then the annotated object's `scene.objects[*].model.defines`, then SCAD context metadata from that same object. That lets labels such as `shell_thickness`, `handle_depth`, or `shelf_texture_depth` show the actual value used by OpenSCAD without repeating it in config.

Set `title_area: true` on an image label to draw the rounded background box for that label's top or bottom edge. Shared constants such as `top_image_label` and `bottom_image_label` already include this. Box defaults still come from `annotations.style.image_label_title_*`, but individual labels can override them with shorter fields such as `title_padding_x_px`, `title_padding_y_px`, `title_min_width_px`, and `title_edge_margin_px`.

Image labels accept `font_size_px`; `label_font_size_px` is also accepted as an alias.

Annotation groups can override label and line sizing when a parameter span is physically small:

```yaml
ids: [shelf_back_thickness]
label_font_size_px: 20
tick_length_px: 12
line_width_px: 2.2
extension_visible: false
```

For annotation groups, `label_font_size_px` is the canonical label size field. `font_size_px` is accepted as an alias for consistency with image labels.

Line outlines are controlled through `annotations.style` or the same keys on an individual annotation group:

```yaml
annotations:
  style:
    line_width_px: 4
    line_outline_color: "#ffffff"
    line_outline_alpha: 190
    line_outline_width_px: 6.5
    extension_outline_width_px: 5.0
    radial_line_outline_width_px: 7.5
    arc_line_outline_width_px: 7.5
    angle_radius_outline_alpha: 180
    angle_radius_arc_outline_width_px: 7.2
```

Set an outline width or alpha to `0` to disable that halo. `line_outline_width_px` applies to normal dimension lines and ticks, `extension_outline_width_px` applies to dashed extension lines, `radial_line_outline_width_px` applies to radius leaders, `arc_line_outline_width_px` applies to standalone arc callouts, and `angle_radius_arc_outline_width_px` applies to the arc portion of combined angle/radius callouts.

## Variants

Use top-level `variants` when several images share most of the same scene and render settings. Each variant has a unique `name` and can either set complete sections or use a `set` object whose keys are dotted config paths. Prefer a stable object `id` or annotation `name` over a numeric array position:

```yaml
variants:
  - name: deep_drawer_shell
    set:
      scene.objects.drawer_shell.model.defines.depth_grids: 6
```

Variant objects can also override full config sections when a dotted path is not enough. `annotations` is replaced as a complete section so model-specific labels do not leak between variants. `constants`, `scene`, and `render` are merged with the base config so shared Blender scene settings can stay in one place.

For object changes, `object_overrides` provides an explicit map keyed by `scene.objects[*].id`. Nested values are merged into the matching object. Set `enabled: false` to remove an inherited object from that variant:

```yaml
variants:
- name: shell_only
  object_overrides:
    drawer_shell:
      model:
        defines:
          depth_grids: 6
    drawer_container:
      enabled: false
```

Use `unset` when a variant must remove an inherited value entirely. Its entries use the same dotted paths and stable array selectors as `set`:

```yaml
variants:
- name: automatic_camera
  unset:
  - render.camera_view
  - scene.objects.drawer_shell.model.defines.legacy_parameter
```

Variant changes resolve in this order: full section overrides, `set`, `object_overrides`, `annotation_overrides`, then `unset`. Invalid, missing, or ambiguous stable targets are rejected.

For annotation layout changes, prefer stable group names and `annotation_overrides` over numeric paths such as `annotations.chains[0]`. Overrides are applied after the variant's section and `set` changes, nested objects are merged, and `enabled: false` keeps a group in the shared catalog while excluding it from rendering and annotation listings:

```yaml
annotations:
  chains:
  - name: compartment_width_dimension
    ids: [compartment_width]
    line_offset_px: 0
    label_offset_px: 28
  angle_radius_callouts:
  - name: holder_tilt_angle_callout
    id: holder_tilt_angle_callout
    arc_id: holder_tilt_angle_extent
    radius_id: holder_tilt_angle_radius
    angle_id: holder_tilt_angle

variants:
- name: side
  annotation_overrides:
    compartment_width_dimension:
      label_offset_px: 42
    holder_tilt_angle_callout:
      enabled: false
```

Names must be unique across the annotation catalog. For compatibility, an unnamed group can be targeted by its single annotation ID, callout ID, or image-label ID, but explicit names are recommended because they remain stable when IDs are reorganized. Invalid and ambiguous override targets are rejected.

Set `default_variant` when omitting `--variant` should select a named variation even though the base config is directly renderable:

```yaml
default_variant: default
variants:
- name: default
- name: side
  # overrides...
```

Use `variant_collections` to define reusable ordered subsets without splitting one model back into multiple config files:

```yaml
variant_collections:
  product_views: [default, empty, side, top, taper]
  parameter_gallery: [width_45, circular_taper]

gallery:
  variant_collection: product_views
```

Collections are accepted by gallery rendering and all-variant validation:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --gallery --variant-collection product_views

.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder `
  --variant-collection product_views
```

`validate MODEL` resolves every variant by default and checks its final schema, object targets, source files, and Blender scene path without running the rendering applications. It catches errors in variants that a normal default render would never select.

`gallery.variant_collection` makes a collection the default for plain `--gallery`. Command-line selection still wins, and omitting both the configured collection and command-line selection renders all variants.

`openconnect_general_holder_default.yaml` demonstrates the one-file-per-model pattern. Its `default`, `empty`, `side`, `top`, `taper`, and four parameter-gallery variants share a single named annotation catalog. The old per-view files are small compatibility entry points, and `openconnect_general_holder_gallery.yaml` only supplies gallery layout plus its default collection. These wrappers should not receive new image definitions.

`openconnect_gridfinity_shelf_default.yaml` follows the same pattern for its `default`, `empty`, `top`, and four parameter-gallery variants. Its old view files contain only compatibility variant selection, while `openconnect_gridfinity_shelf_gallery.yaml` contains only layout and `gallery.variant_collection`.

`openconnect_sturdy_shelf_default.yaml` likewise owns its `default`, `empty`, `side`, and four parameter-gallery variants. The shared named annotation catalog switches between grid dimensions and the side-view thickness/fillet callouts without duplicating complete annotation sections.

`openconnect_sturdy_hook_default.yaml` owns its two-object default view, single-object empty and side views, and four parameter-gallery variants. The side-specific annotation catalog remains explicit because it intentionally uses different aliases and technical-line styling; scene and model definitions are still shared.

`openconnect_vasemode_container_default.yaml` shares one named annotation catalog across its default, empty, side, and texture-gallery variants. The variants toggle grid dimensions and the tilt callout, and reposition the texture label without duplicating its base style or aliases.

`opengrid_framefit_hook_default.yaml` owns both its three-object default composition and single-object side detail. The old side config is a compatibility selector rather than a second copy of the model, camera, and annotation setup.

Use `variant_configs` when a gallery config should import complete per-model config files as variants:

```yaml
extends: base_scene.yaml
job_name: opengrid_annotation_models
variant_configs:
  - openconnect_sturdy_hook_default.yaml
  - openconnect_sturdy_shelf_default.yaml
  - openconnect_general_holder_default.yaml
```

Imported config paths are resolved relative to the importing config. The imported variant name comes from top-level `variant_name`, or from the filename stem when `variant_name` is omitted. Extra parameter groups live in `configs/parameter_details.yaml`, which extends the defaults and replaces the variant list with secondary detail renders:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe `
  --config annotation_renderer\configs\parameter_details.yaml `
  --variant sturdy_hook_circular_details
```

Current parameter-detail variants:

* `sturdy_hook_circular_details`: `hook_width`, `hook_corner_fillet`, `circular_tip_radius`, `circular_tip_angle`
* `sturdy_hook_rectangular_details`: `hook_width`, `rectangular_tip_extra_length`, `hook_shape_type`
* `sturdy_hook_truss_details`: `truss_vertical_grids`, `truss_thickness`, `truss_max_angle`
* `sturdy_shelf_truss_details`: `truss_beam_reach`, `truss_thickness`, `truss_strut_interval`, `shelf_corner_fillet`
* `sturdy_shelf_edge_texture_details`: `shelf_side_edge_depth`, `shelf_front_edge_depth`, `shelf_texture_depth`
* `drawer_shell_clearance_details`: `shell_thickness`, container width/height/depth clearances, `container_back_side_height_offset`
* `drawer_container_label_handle_details`: `handle_depth`, `label_width`, `label_height`, stopper settings, and magnet diameters

Use `extends` in a config when a secondary parameter set should reuse `model_defaults.yaml` constants, scene binding, and render presets without copying them:

```yaml
extends: model_defaults.yaml
job_name: my_parameter_details
variants: []
```

## SCAD Annotation Contract

To make a model compatible, add:

```scad
emit_annotation_metadata = false;
```

Then emit lines using the `OPENGRID_ANNOTATION_V1` format when that flag is true. Dimension anchors are model-local coordinates:

```text
OPENGRID_ANNOTATION_V1|id=horizontal_grids|kind=dimension|label=horizontal_grids|axis=z|value=84|start=0,-28,0|end=0,-28,84|basis=left_to_right_width_from_horizontal_grids
```

Radius callouts use `center` and `edge` instead of `start` and `end`:

```text
OPENGRID_ANNOTATION_V1|id=hook_corner_fillet|kind=radius|label=hook_corner_fillet|value=15|center=18.5,-13,28|edge=7.89,-23.61,28|basis=first_hook_corner_fillet
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

Use `kind=context` for any numeric SCAD value that config transforms or annotation offsets should reference. These entries are not drawn directly. The older single-value form, `id=shell_thickness|kind=context|value=2.4`, is still supported.

The renderer applies config offsets in model-local coordinates before Blender object transform and camera projection.

## Notes

For OpenSCAD STL imports, `mesh_shading: "flat"` is usually the safer default because blanket smooth shading can show artificial triangular bands on curved generated surfaces.
