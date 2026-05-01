# OpenGrid Annotation Image Generator

## Branch purpose

This branch is dedicated to the annotation image generation utility. It turns
OpenSCAD models into repeatable, annotated technical images using OpenSCAD,
Blender, and Pillow.

Most of the utility's implementation and documentation were created with
OpenAI Codex, with human direction, review, and testing. The OpenGrid and
openConnect model files in this branch are primarily real-world inputs and
examples for the renderer; they are not the focus of this README.

## What it does

The `opengrid-annotate` command coordinates the complete image-generation
pipeline:

1. A checked-in YAML config selects a model, parameters, camera, materials, and
   annotation layout.
2. OpenSCAD generates the model mesh and emits geometry-aware annotation
   anchors.
3. Blender prepares the scene and renders the model, including supported
   cutaway and view settings.
4. The renderer draws dimensions, radius and angle callouts, labels, and other
   overlays onto the final image.

Named variants keep multiple views or parameter combinations in one canonical
config. The utility can also validate configs, apply one-off command-line
overrides, generate galleries, and retain debug artifacts when an annotation
needs inspection.

## Quick start

Requirements:

- Python 3.10 or newer
- [OpenSCAD Snapshot](https://openscad.org/downloads.html#snapshots)
- Blender 5.1 or newer
- [BOSL2](https://github.com/BelfrySCAD/BOSL2) for the included OpenSCAD models

From the repository root on Windows:

```powershell
py -3 -m venv build\.venv-tools
.\build\.venv-tools\Scripts\python.exe -m pip install --upgrade pip
.\build\.venv-tools\Scripts\python.exe -m pip install -e .

.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor
.\build\.venv-tools\Scripts\opengrid-annotate.exe doctor --smoke-render
```

Using OpenSCAD's **Manifold** rendering backend is recommended for substantially
faster model generation.

## Common commands

```powershell
# List configured models and render the default variant
.\build\.venv-tools\Scripts\opengrid-annotate.exe models
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder

# Render one named variation
.\build\.venv-tools\Scripts\opengrid-annotate.exe render openconnect_general_holder --variant side

# Validate every variation without rendering
.\build\.venv-tools\Scripts\opengrid-annotate.exe validate openconnect_general_holder

# Inspect available annotations and generate a configured gallery
.\build\.venv-tools\Scripts\opengrid-annotate.exe annotations openconnect_general_holder
.\build\.venv-tools\Scripts\opengrid-annotate.exe gallery openconnect_general_holder
```

Generated images and optional debug artifacts are written under
`build/scene_annotations/<model-name>/`.

## Project guide

- [`annotation_renderer/`](annotation_renderer/) contains the Python package,
  bundled Blender scenes, schemas, and canonical YAML configs.
- [`annotation_renderer/README.md`](annotation_renderer/README.md) is the concise
  usage guide.
- [`annotation_renderer/USAGE.md`](annotation_renderer/USAGE.md) covers practical
  rendering, galleries, animation, and troubleshooting.
- [`annotation_renderer/REFERENCE.md`](annotation_renderer/REFERENCE.md) documents
  the complete configuration and SCAD annotation metadata formats.
- [`tests/`](tests/) contains the renderer and CLI regression suite.

## Model context and licensing

The included OpenGrid/openConnect models provide varied geometry for developing
and exercising the renderer, including parametric dimensions, fillets, slots,
connectors, and cutaway views.

- The openConnect connector libraries and connector/snap generators are
  licensed under **CC-BY 4.0**.
- Most holder, drawer, shelf, hook, label, and gadget model generators are
  licensed under **CC-BY-SA 4.0**.
