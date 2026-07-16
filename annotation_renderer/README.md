# Annotation Renderer Utility

Generate annotated technical PNGs from OpenSCAD models. The normal interface is
`opengrid-annotate`; config files are there when you need to customize the
defaults.

Model `.scad` files are the source of truth. The default render config for a
model uses the full model name, for example:

```text
openconnect_general_holder.scad
annotation_renderer/configs/openconnect_general_holder_default.yaml
```

## Setup

From the repository root:

```powershell
py -3 -m venv build\.venv-tools
.\build\.venv-tools\Scripts\python.exe -m pip install --upgrade pip
.\build\.venv-tools\Scripts\python.exe -m pip install -e .
```

Install OpenSCAD Nightly and Blender 5.1 or newer. If they are not on `PATH`, pass their
locations with `--openscad` and `--blender`.

Check the local toolchain:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor
```

Run one small end-to-end render check:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor --smoke-render
```

## Quick Start

Render the default annotated image for a model:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder
```

That command resolves the model name to:

```text
annotation_renderer/configs/openconnect_general_holder_default.yaml
```

Render with one temporary override:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --set scene.objects.model_a.model.defines.compartment_column_count=3
```

Render a permanent named image variation without creating another config file:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder --variant side
```

Model configs can keep all image variations in one top-level `variants` list. Give annotation groups stable `name` values, then change their layout or visibility with `annotation_overrides`:

```yaml
annotations:
  chains:
  - name: compartment_width_dimension
    ids: [compartment_width]
    label_offset_px: 28

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

`object_overrides` targets scene objects by stable `id`; use `enabled: false` to exclude an object. A variant can also list dotted paths under `unset` when an inherited value must be removed instead of replaced.

Group useful subsets under `variant_collections`, then render or validate only that ordered subset:

```yaml
variant_collections:
  product_views: [default, empty, side, top, taper]

gallery:
  variant_collection: product_views
```

```powershell
# Validate every variant without invoking Blender or OpenSCAD
.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder

# Render one named subset as a contact sheet
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder `
  --gallery --variant-collection product_views
```

When `gallery.variant_collection` is configured, plain `--gallery` renders that collection; an explicit `--variant` or `--variant-collection` takes precedence. Otherwise plain `--gallery` renders every named variant. The general-holder, gridfinity-shelf, sturdy-shelf, sturdy-hook, vasemode-container, and framefit-hook configs are reference examples: their view and parameter variants live in one canonical file per model, while the former per-view and parameter-gallery paths remain compatibility entry points.

List the built-in renderable models:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe list-models
```

Describe one model default:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe describe openconnect_general_holder
```

See the annotation groups currently configured for a model:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe list-annotations openconnect_general_holder
```

Discover annotation IDs from the SCAD source:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe discover openconnect_general_holder.scad
```

Discovery only accepts `.scad` files. It does not accept config names such as
`openconnect_general_holder_default`.

Create a separate editable config only when the result should not live as a named model variant:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe new-config openconnect_general_holder `
  --out build\scene_annotations\my_general_holder.yaml
```

Then render it directly:

```powershell
.\build\.venv-tools\Scripts\opengrid-annotate.exe `
  --config build\scene_annotations\my_general_holder.yaml
```

## Output

Final images are written under `build/scene_annotations/<model-name>/`.
Generated files under `build/` are ignored by git.

Render-stage caching is enabled by default. OpenSCAD exports and Blender
render/projection outputs are reused when their inputs have not changed. Use
`--no-cache` for a cold run.

Use `--output-mode debug` when you need Blender logs, temporary STLs, projection
JSON, or intermediate overlay images. The default `standard` mode keeps the
final image and metadata.

Use `--export-blend` or `render.export_blend: true` when you want the prepared
Blender scene that was rendered. The `.blend` sidecar is written next to the
final still image.

## More Detail

* [`USAGE.md`](USAGE.md): practical workflows for rendering, customizing,
  galleries, animations, and troubleshooting.
* [`REFERENCE.md`](REFERENCE.md): full config, scene, annotation, animation, and
  SCAD metadata reference.
* [`schemas/annotation-render-config.schema.json`](schemas/annotation-render-config.schema.json):
  machine-readable render config schema.
* [`schemas/annotation-render-gallery.schema.json`](schemas/annotation-render-gallery.schema.json):
  contact-sheet config schema.
