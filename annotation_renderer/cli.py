"""Command-line interface for OpenGrid annotation rendering."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Sequence

from annotation_renderer.config.loader import (
    load_config,
    load_gallery_config,
    selected_variants,
    variant_config,
)
from annotation_renderer.config.schema import CONFIG_SCHEMA_PATH, ConfigError
from annotation_renderer.catalog import CONFIG_SUFFIXES, default_config_for_model, is_directly_renderable_config
from annotation_renderer.commands import (
    print_annotation_groups,
    print_model_description,
    print_model_list,
    resolved_named_config,
    run_annotation_discovery,
    write_new_config_template,
)
from annotation_renderer.diagnostics import run_doctor
from annotation_renderer.gallery import run_all_variant_validation, run_gallery
from annotation_renderer.openscad import project_relative_or_absolute
from annotation_renderer.pipeline import (
    apply_animation_preset,
    render_config,
    resolved_config_snapshot,
)
from annotation_renderer.paths import DEFAULT_MODEL_CONFIG_PATH, PROJECT_ROOT


def add_override_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--set",
        action="append",
        default=[],
        dest="overrides",
        metavar="PATH=VALUE",
        help="Override a dotted config path for this invocation.",
    )


def add_tool_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--openscad", default="openscad", help="OpenSCAD executable.")
    parser.add_argument("--blender", default="blender", help="Blender executable.")


def add_output_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--output-dir", help="Override the output directory root.")
    parser.add_argument("--cache-dir", help="Override the render-stage cache directory.")
    parser.add_argument("--no-cache", action="store_true", help="Disable render-stage cache reuse.")
    parser.add_argument(
        "--output-mode",
        choices=("minimal", "standard", "debug"),
        help="Choose which intermediate artifacts to retain.",
    )
    parser.add_argument("--export-blend", action="store_true", help="Save the prepared Blender scene.")


def add_variant_option(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--variant", help="Select one named variant.")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.set_defaults(
        animation_preset=None,
        blender="blender",
        cache_dir=None,
        command=None,
        export_blend=False,
        force=False,
        gallery=False,
        gallery_config=None,
        no_cache=False,
        openscad="openscad",
        output_dir=None,
        output_file=None,
        output_mode=None,
        overrides=[],
        print_resolved_config=False,
        smoke_render=False,
        validate_only=False,
        variant=None,
        variant_collection=None,
    )
    commands = parser.add_subparsers(dest="command", required=True, metavar="COMMAND")

    render = commands.add_parser("render", help="Render one model or config.")
    render.add_argument("target", help="Built-in model name or config path.")
    add_variant_option(render)
    render.add_argument("--animation-preset", help="Apply one named animation preset.")
    render.add_argument("--output-file", help="Write the final still image to an exact path.")
    render.add_argument(
        "--resolved",
        action="store_true",
        dest="print_resolved_config",
        help="Print the fully resolved render configuration without rendering.",
    )
    add_output_options(render)
    add_tool_options(render)
    add_override_options(render)

    gallery = commands.add_parser("gallery", help="Render a variant contact sheet.")
    gallery.add_argument("target", help="Built-in model name or config path.")
    add_variant_option(gallery)
    gallery.add_argument("--collection", dest="variant_collection", help="Select a named variant collection.")
    gallery.add_argument("--gallery-config", help="Optional contact-sheet settings config.")
    gallery.add_argument(
        "--resolved",
        action="store_true",
        dest="print_resolved_config",
        help="Print all resolved gallery variants without rendering.",
    )
    add_output_options(gallery)
    add_tool_options(gallery)
    add_override_options(gallery)

    validate = commands.add_parser("validate", help="Validate every selected variant without rendering.")
    validate.add_argument("target", help="Built-in model name or config path.")
    add_variant_option(validate)
    validate.add_argument("--collection", dest="variant_collection", help="Select a named variant collection.")
    add_override_options(validate)

    models = commands.add_parser("models", help="List built-in models or models from one config.")
    models.add_argument("target", nargs="?", help="Optional built-in model name or config path.")
    add_override_options(models)

    describe = commands.add_parser("describe", help="Describe one model or variant.")
    describe.add_argument("target", help="Built-in model name or config path.")
    add_variant_option(describe)
    add_override_options(describe)

    annotations = commands.add_parser("annotations", help="List configured annotation groups.")
    annotations.add_argument("target", help="Built-in model name or config path.")
    add_variant_option(annotations)
    add_override_options(annotations)

    discover = commands.add_parser("discover", help="Discover annotation metadata in a SCAD source file.")
    discover.add_argument("target", help="SCAD source path.")
    discover.add_argument("--out", help="Optional YAML, JSON, or text output path.")

    new_config = commands.add_parser("new-config", help="Create an editable config from a model or variant.")
    new_config.add_argument("target", help="Built-in model name or config path.")
    add_variant_option(new_config)
    new_config.add_argument("--out", required=True, help="Output YAML or JSON path.")
    new_config.add_argument("--force", action="store_true", help="Overwrite an existing output file.")
    add_override_options(new_config)

    doctor = commands.add_parser("doctor", help="Check local rendering dependencies and paths.")
    doctor.add_argument("--smoke-render", action="store_true", help="Run one minimal render after checks pass.")
    doctor.add_argument("--output-dir", help="Override the output directory used by the smoke render.")
    add_tool_options(doctor)
    add_override_options(doctor)

    commands.add_parser("schema", help="Print the render config JSON Schema.")
    return parser


def parse_args_from(argv: Sequence[str]) -> argparse.Namespace:
    return build_arg_parser().parse_args(list(argv))


def target_config_path(target: str | None) -> Path:
    if target is None:
        return DEFAULT_MODEL_CONFIG_PATH.resolve()
    raw_path = Path(target).expanduser()
    if raw_path.suffix.lower() in CONFIG_SUFFIXES or raw_path.is_absolute() or raw_path.parent != Path("."):
        path = raw_path if raw_path.is_absolute() else PROJECT_ROOT / raw_path
        path = path.resolve()
        if not path.exists():
            raise ConfigError(f"Config not found: {project_relative_or_absolute(path)}")
        return path
    return default_config_for_model(target)


def loaded_target(args: argparse.Namespace) -> tuple[Path, dict[str, object]]:
    config_path = target_config_path(getattr(args, "target", None))
    return config_path, load_config(config_path, args.overrides)


def selected_render_config(config: dict[str, object], variant_name: str | None) -> dict[str, object]:
    if variant_name:
        return variant_config(config, selected_variants(config, variant_name)[0])
    default_variant = config.get("default_variant")
    if default_variant:
        return variant_config(config, selected_variants(config, str(default_variant))[0])
    if is_directly_renderable_config(config):
        return config
    variants = selected_variants(config, None)
    if not variants:
        raise ConfigError("Config has no directly renderable model and no variants")
    return variant_config(config, variants[0])


def run_inspection(args: argparse.Namespace) -> int:
    config_path, config = loaded_target(args)
    if args.command == "models":
        print_model_list(config=config, config_path=config_path)
        return 0

    target_path = Path(str(args.target))
    target_is_config = target_path.suffix.lower() in CONFIG_SUFFIXES
    target_name = args.variant or (None if target_is_config else str(args.target))
    name, resolved, source_config, _variant = resolved_named_config(
        config,
        config_path=config_path,
        name=target_name,
    )
    if args.command == "describe":
        print_model_description(name=name, config=resolved, source_config=source_config)
        return 0
    if args.command == "annotations":
        print(f"Annotations for {name}:")
        print_annotation_groups(resolved)
        return 0
    if args.command == "new-config":
        output_path = Path(args.out).expanduser()
        if not output_path.is_absolute():
            output_path = (PROJECT_ROOT / output_path).resolve()
        write_new_config_template(
            name=name,
            config=resolved,
            source_config=source_config,
            output_path=output_path,
            force=bool(args.force),
        )
        print(f"Wrote: {project_relative_or_absolute(output_path)}")
        print(f"Extends: {project_relative_or_absolute(source_config)}")
        return 0
    raise ConfigError(f"Unsupported inspection command: {args.command}")


def run(args: argparse.Namespace) -> int:
    if args.command == "doctor":
        return run_doctor(args)
    if args.command == "schema":
        print(CONFIG_SCHEMA_PATH.read_text(encoding="utf-8"), end="")
        return 0
    if args.command == "discover":
        args.config = None
        args.discover_annotations = args.target
        return run_annotation_discovery(args=args)
    if args.command in {"models", "describe", "annotations", "new-config"}:
        return run_inspection(args)

    config_path, config = loaded_target(args)
    config_dir = config_path.parent
    if args.command == "validate":
        return run_all_variant_validation(config=config, config_path=config_path, config_dir=config_dir, args=args)
    if args.command == "gallery":
        args.gallery = True
        gallery_config, gallery_config_path = load_gallery_config(args.gallery_config, config_dir=config_dir)
        return run_gallery(
            config=config,
            config_path=config_path,
            config_dir=config_dir,
            args=args,
            gallery_config=gallery_config,
            gallery_config_path=gallery_config_path,
        )
    if args.command == "render":
        config = selected_render_config(config, args.variant)
        if args.animation_preset:
            config = apply_animation_preset(config, str(args.animation_preset))
        if args.print_resolved_config:
            snapshot = resolved_config_snapshot(config=config, config_path=config_path, config_dir=config_dir, args=args)
            print(json.dumps(snapshot, indent=2))
            return 0
        render_config(config=config, config_path=config_path, config_dir=config_dir, args=args)
        return 0
    raise ConfigError(f"Unsupported command: {args.command}")


def main(argv: Sequence[str] | None = None) -> int:
    args = build_arg_parser().parse_args() if argv is None else parse_args_from(argv)
    try:
        return run(args)
    except ConfigError as exc:
        raise SystemExit(str(exc)) from exc
