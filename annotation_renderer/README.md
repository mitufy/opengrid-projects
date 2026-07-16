# Annotation Renderer Utility

Generate annotated technical images from OpenSCAD models with OpenSCAD, Blender, and Pillow. The public interface is the `opengrid-annotate` command; checked-in YAML files define reusable model views.

## Setup

From the repository root:

```powershell
py -3 -m venv build\.venv-tools
.\build\.venv-tools\Scripts\python.exe -m pip install --upgrade pip
.\build\.venv-tools\Scripts\python.exe -m pip install -e .
```

Install OpenSCAD Nightly and Blender 5.1 or newer. If either tool is outside `PATH`, pass `--openscad` or `--blender`.

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor --smoke-render
```

## Commands

Every render-oriented command accepts a built-in model name or a YAML/JSON config path directly.

```powershell
# Render the configured default view
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder

# Render one named view
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder --variant side

# Render a configured contact sheet
.\build\.venv-tools\Scripts\opengrid-annotate.exe gallery openconnect_general_holder

# Validate all variants or one collection without rendering
.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder
.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder --collection product_views

# Inspect the available models and annotations
.\build\.venv-tools\Scripts\opengrid-annotate.exe models
.\build\.venv-tools\Scripts\opengrid-annotate.exe describe openconnect_general_holder
.\build\.venv-tools\Scripts\opengrid-annotate.exe annotations openconnect_general_holder

# Discover annotation IDs directly from SCAD
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_general_holder.scad
```

Use `render TARGET --resolved` or `gallery TARGET --resolved` to inspect the fully resolved configuration without rendering. Use `schema` to print the JSON Schema.

## Variations

A model owns its views and parameter variations in one canonical file, such as:

```text
openconnect_general_holder.scad
annotation_renderer/configs/openconnect_general_holder.yaml
```

Stable mapping keys make annotation declarations and variant overrides line up:

```yaml
annotations:
  chains:
    compartment_width_dimension:
      id: compartment_width
      line_offset_px: -20
      label_offset_px: -50

variants:
- name: side
  object_overrides:
    model_a:
      model:
        defines:
          compartment_depth: 20
  annotation_overrides:
    compartment_width_dimension:
      label_offset_px: 42
- name: dimensions_hidden
  annotation_overrides:
    compartment_width_dimension:
      enabled: false
```

For `chains`, `radius_callouts`, and `arc_callouts`, a singular `id` expands to `ids: [id]`; when `id` is omitted, the mapping key is used. Image labels also default their `id` to the mapping key.

Collections define ordered subsets for galleries and validation:

```yaml
variant_collections:
  product_views: [default, empty, side, top, taper]

gallery:
  variant_collection: product_views
```

Run a one-off override without changing YAML:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --set scene.objects.model_a.model.defines.compartment_column_count=3
```

Create a separate config only when a variation should not live in the canonical model file:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe new-config openconnect_general_holder `
  --out build\scene_annotations\my_general_holder.yaml

.\build\.venv-tools\Scripts\opengrid-annotate.exe render build\scene_annotations\my_general_holder.yaml
```

## Output

Final images are written under `build/scene_annotations/<model-name>/`. Render-stage caching is enabled by default.

- `--output-mode minimal` keeps final images only.
- `--output-mode standard` also keeps metadata.
- `--output-mode debug` keeps intermediate STLs, logs, projections, and overlay images.
- `--export-blend` saves the prepared Blender scene.
- `--no-cache` forces a cold run.

## Documentation

- [USAGE.md](USAGE.md): practical rendering, gallery, animation, and troubleshooting workflows.
- [REFERENCE.md](REFERENCE.md): complete configuration and SCAD metadata reference.
- [annotation-render-config.schema.json](schemas/annotation-render-config.schema.json): machine-readable config schema.
