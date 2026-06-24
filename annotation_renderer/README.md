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

Install OpenSCAD Nightly and Blender. If they are not on `PATH`, pass their
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
  --set scene.objects[0].model.defines.compartment_column_count=3
```

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

Create a small editable config that extends the default:

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
