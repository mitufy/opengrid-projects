# Annotation Renderer Usage

This guide covers the common workflows. Use `README.md` for the shortest setup
path and `REFERENCE.md` when you need every config field.

All examples run from the repository root and use the installed console script:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe
```

If the package is not installed yet, run:

```powershell
.\build\.venv-tools\Scripts\python.exe -m pip install -e .
```

## Render A Model

Render the default image for a SCAD model:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder
```

The model name maps to the full-name default config:

```text
openconnect_general_holder -> annotation_renderer\configs\openconnect_general_holder.yaml
```

`render` also accepts a YAML or JSON config path directly:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render build\scene_annotations\my_hook.yaml
```

Validate the resolved config without rendering:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder
```

Write the final still image to a stable path:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --output-file build\scene_annotations\my_holder.png
```

Generated files go under `build\scene_annotations\`. Use `--output-mode debug`
when you need logs, temporary STLs, projection JSON, or intermediate overlay
images.

## Override Values

Use `--set path=value` for one-off changes:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --set scene.objects[0].model.defines.compartment_column_count=3 `
  --set render.camera_view_preset=technical_iso
```

Annotation mappings use their stable group names, so tuning does not depend on
list order:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --set annotations.chains.compartment_width_dimension.label_offset_px=36 `
  --set annotations.chains.compartment_width_dimension.label_along_offset_px=24
```

Render-stage caching is on by default, so annotation-only offset changes should
reuse the expensive OpenSCAD and Blender stages. Use `--no-cache` for a cold
run, or `--cache-dir path\to\cache` to use a different cache folder.

## Explore Defaults

List renderable defaults:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe models
```

Describe one model:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe describe openconnect_general_holder
```

List the annotation groups already configured for a model:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe annotations openconnect_general_holder
```

Print the fully resolved config:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --resolved
```

## Discover Annotation IDs

Discovery reads SCAD source directly:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_general_holder.scad
```

Pass a `.scad` file, not a config name. This works:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_sturdy_hook.scad
```

This does not:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_sturdy_hook
```

Discovery lists parameters by config use:

* `dimension parameters`: use as a chain's `id` or in `ids`
* `radius parameters`: use as a radius callout's `id` or in `ids`
* `arc parameters`: use as an arc callout's `id` or in `ids`
* `context value parameters`: use in labels, offsets, and expressions

Write discovery output to a file:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_sturdy_hook.scad `
  --out build\scene_annotations\sturdy_hook_annotations.yaml
```

`--out` supports `.txt`, `.yaml`, `.yml`, and `.json`.

## Create A Custom Config

Start from a compact generated config:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe new-config openconnect_general_holder `
  --out build\scene_annotations\my_general_holder.yaml
```

Edit the generated YAML, then render it:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render `
  build\scene_annotations\my_general_holder.yaml
```

A typical custom config only changes model defines, camera settings, and
annotation offsets:

```yaml
extends: ../../annotation_renderer/configs/openconnect_general_holder.yaml
job_name: my_general_holder

scene:
  objects:
  - id: model
    model:
      scad_file: openconnect_general_holder.scad
      defines:
        compartment_shape: Rectangular
        compartment_column_count: 2

render:
  camera_view_preset: technical_iso

annotations:
  chains:
    compartment_width_dimension:
      id: compartment_width
      label_offset_px: 34
```

Prefer YAML for hand-edited configs. JSON is still accepted for external tools.

## Galleries

Render every default model into a contact sheet:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe gallery `
  annotation_renderer\configs\model_defaults.yaml `
  --gallery-config annotation_renderer\configs\gallery_defaults.yaml
```

Render the scene-control gallery:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe gallery `
  annotation_renderer\configs\render_settings_gallery.yaml
```

Use `variants` in custom configs when several images share the same base model:

```yaml
variants:
- name: technical_iso
  set:
    render.camera_view_preset: technical_iso
- name: left_view
  set:
    render.camera_view: left
```

## Animations

Animations use named render presets from `configs/animation_presets.yaml`.
Animation outputs are unannotated.

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --animation-preset openconnect_insert_animation_render
```

Drawer install plus slide:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_drawer_shell_container `
  --animation-preset drawer_install_then_slide_animation_render
```

## Troubleshooting

Check local dependencies:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor
```

Run a minimal render check:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor --smoke-render
```

If OpenSCAD or Blender is not found, pass explicit paths:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --openscad C:\path\to\openscad.exe `
  --blender C:\path\to\blender.exe
```

If the model is invisible or tiny, check `scene.transform.scale`. Most OpenSCAD
exports are millimeters and should use `[0.001, 0.001, 0.001]` for Blender
meters.

If labels point to empty space after a cutaway, the cutaway probably removed the
annotated geometry. Suppress those annotations or create a dedicated
cross-section config.

If camera changes make labels hard to read, remove `camera_roll_deg` first, then
reduce `camera_orbit_deg` or increase `camera_distance_scale`.

If a config path works from one folder but not another, make paths relative to
the config file or the repository root. The resolver checks both.
