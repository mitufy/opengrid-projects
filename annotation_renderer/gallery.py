"""Variant validation and gallery rendering."""

from __future__ import annotations

import argparse
import json
from copy import deepcopy
from datetime import datetime
from pathlib import Path
from typing import Mapping, Sequence

from PIL import Image, ImageDraw

from annotation_renderer.config.defaults import (
    DEFAULT_RENDER_HEIGHT,
    DEFAULT_RENDER_WIDTH,
    GALLERY_SETTING_DEFAULTS,
)
from annotation_renderer.config.loader import (
    base_job_name,
    selected_variant_collection,
    selected_variants,
    variant_config,
)
from annotation_renderer.config.resolution import resolve_style
from annotation_renderer.config.schema import ConfigError
from annotation_renderer.openscad import project_relative_or_absolute, sanitize_name
from annotation_renderer.overlay import load_font
from annotation_renderer.pipeline import output_root_for, render_config, resolved_config_snapshot


def compact_gallery_config(raw_gallery: object, *, name: str) -> dict[str, object]:
    if raw_gallery is None:
        return {}
    if not isinstance(raw_gallery, Mapping):
        raise ConfigError(f"{name} must be an object")
    return {
        str(key): value
        for key, value in raw_gallery.items()
        if key != "$schema"
    }


def merged_gallery_config(
    config: Mapping[str, object],
    *,
    gallery_config: Mapping[str, object] | None = None,
) -> dict[str, object]:
    merged = compact_gallery_config(gallery_config or {}, name="gallery config")
    merged.update(compact_gallery_config(config.get("gallery", {}), name="gallery"))
    return merged


def gallery_settings(
    config: Mapping[str, object],
    *,
    gallery_config: Mapping[str, object] | None = None,
    variant_count: int | None = None,
) -> dict[str, int]:
    merged_gallery = merged_gallery_config(config, gallery_config=gallery_config)
    settings = {
        key: int(merged_gallery.get(key, default))
        for key, default in GALLERY_SETTING_DEFAULTS.items()
    }
    for key in ("target_width_px", "target_height_px"):
        if key in merged_gallery:
            settings[key] = int(merged_gallery[key])
    for key in ("columns", "thumbnail_width", "title_font_size_px"):
        if settings[key] < 1:
            raise ConfigError(f"gallery.{key} must be at least 1")
    for key in ("margin_px", "gutter_px", "title_height_px"):
        if settings[key] < 0:
            raise ConfigError(f"gallery.{key} must be at least 0")
    target_keys = {"target_width_px", "target_height_px"}
    present_target_keys = target_keys & settings.keys()
    if present_target_keys:
        if present_target_keys != target_keys:
            raise ConfigError("gallery.target_width_px and gallery.target_height_px must be set together")
        for key in target_keys:
            if settings[key] < 1:
                raise ConfigError(f"gallery.{key} must be at least 1")
        if variant_count is None:
            raise ConfigError("gallery target sizing requires a variant count")
        apply_gallery_target_size(settings, variant_count=variant_count)
    return settings


def configured_gallery_variant_collection(
    config: Mapping[str, object],
    *,
    gallery_config: Mapping[str, object] | None = None,
) -> str | None:
    merged_gallery = merged_gallery_config(config, gallery_config=gallery_config)
    collection_name = merged_gallery.get("variant_collection")
    if collection_name is None:
        return None
    if not isinstance(collection_name, str) or not collection_name.strip():
        raise ConfigError("gallery.variant_collection must be a non-empty string")
    return collection_name.strip()


def apply_gallery_target_size(settings: dict[str, int], *, variant_count: int) -> None:
    if variant_count < 1:
        raise ConfigError("Gallery requires at least one render result")
    columns = settings["columns"]
    rows = (variant_count + columns - 1) // columns
    margin = settings["margin_px"]
    gutter = settings["gutter_px"]
    title_height = settings["title_height_px"]
    target_width = settings["target_width_px"]
    target_height = settings["target_height_px"]

    available_width = target_width - margin * 2 - (columns - 1) * gutter
    if available_width < columns:
        raise ConfigError(
            "gallery.target_width_px is too small for gallery.columns, gallery.margin_px, and gallery.gutter_px"
        )
    thumbnail_width = available_width // columns

    available_height = target_height - margin * 2 - (rows - 1) * gutter - rows * title_height
    if available_height < rows:
        raise ConfigError(
            "gallery.target_height_px is too small for gallery rows, gallery.margin_px, gallery.gutter_px, and gallery.title_height_px"
        )
    thumbnail_height = available_height // rows

    settings["thumbnail_width"] = thumbnail_width
    settings["thumbnail_height"] = thumbnail_height
    settings["render_width"] = thumbnail_width
    settings["render_height"] = thumbnail_height


def apply_gallery_target_render_size(config: Mapping[str, object], settings: Mapping[str, int]) -> dict[str, object]:
    if "render_width" not in settings or "render_height" not in settings:
        return dict(config)
    resolved = deepcopy(dict(config))
    render = resolved.get("render", {})
    if render is None:
        render = {}
    if not isinstance(render, Mapping):
        raise ConfigError("render must be an object")
    updated_render = dict(render)
    original_width = int(updated_render.get("width", DEFAULT_RENDER_WIDTH))
    original_height = int(updated_render.get("height", DEFAULT_RENDER_HEIGHT))
    cell_width = int(settings["render_width"])
    cell_height = int(settings["render_height"])
    pixel_scale = min(cell_width / original_width, cell_height / original_height)
    render_width = max(1, round(original_width * pixel_scale))
    render_height = max(1, round(original_height * pixel_scale))
    updated_render["width"] = render_width
    updated_render["height"] = render_height
    resolved["render"] = updated_render
    annotations = resolved.get("annotations")
    if isinstance(annotations, Mapping):
        resolved_annotations = deepcopy(dict(annotations))
        resolved_annotations["style"] = resolve_style(resolved_annotations.get("style", {}))
        resolved["annotations"] = scale_annotation_pixels(resolved_annotations, scale=pixel_scale)
    return resolved


def scale_annotation_pixels(value: object, *, scale: float, pixel_field: bool = False) -> object:
    if pixel_field and isinstance(value, (int, float)) and not isinstance(value, bool):
        scaled = float(value) * scale
        if isinstance(value, int):
            if value > 0:
                return max(1, round(scaled))
            if value < 0:
                return min(-1, round(scaled))
            return 0
        return scaled
    if isinstance(value, Mapping):
        return {
            str(key): scale_annotation_pixels(item, scale=scale, pixel_field=str(key).endswith("_px"))
            for key, item in value.items()
        }
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes)):
        return [scale_annotation_pixels(item, scale=scale, pixel_field=pixel_field) for item in value]
    return deepcopy(value)


def build_gallery_contact_sheet(
    *,
    results: Sequence[Mapping[str, object]],
    output_path: Path,
    columns: int,
    thumbnail_width: int,
    thumbnail_height: int | None = None,
    margin_px: int,
    gutter_px: int,
    title_height_px: int,
    title_font_size_px: int,
    target_width_px: int | None = None,
    target_height_px: int | None = None,
) -> None:
    if not results:
        raise ConfigError("Gallery requires at least one render result")
    cells: list[tuple[str, Image.Image]] = []
    for result in results:
        image = Image.open(Path(result["annotated"])).convert("RGB")
        max_thumbnail_height = thumbnail_height if thumbnail_height is not None else thumbnail_width * 2
        image.thumbnail((thumbnail_width, max_thumbnail_height), resample=Image.Resampling.LANCZOS)
        cells.append((str(result["variant_name"]), image.copy()))

    title_height = title_height_px
    margin = margin_px
    gutter = gutter_px
    cell_width = thumbnail_width
    image_height = thumbnail_height if thumbnail_height is not None else max(image.height for _, image in cells)
    cell_height = image_height + title_height
    rows = (len(cells) + columns - 1) // columns
    content_width = margin * 2 + columns * cell_width + (columns - 1) * gutter
    content_height = margin * 2 + rows * cell_height + (rows - 1) * gutter
    sheet_width = target_width_px or content_width
    sheet_height = target_height_px or content_height
    if sheet_width < content_width or sheet_height < content_height:
        raise ConfigError("Gallery target size is smaller than its resolved cell layout")
    sheet = Image.new("RGB", (sheet_width, sheet_height), (248, 250, 252))
    draw = ImageDraw.Draw(sheet)
    font = load_font(title_font_size_px)

    for index, (name, image) in enumerate(cells):
        row = index // columns
        column = index % columns
        cell_x = margin + column * (cell_width + gutter)
        cell_y = margin + row * (cell_height + gutter)
        draw.text((cell_x, cell_y), name, fill=(24, 33, 43), font=font)
        image_x = cell_x + (cell_width - image.width) // 2
        sheet.paste(image, (image_x, cell_y + title_height))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)


def variants_for_requested_subset(
    config: Mapping[str, object],
    *,
    variant_name: str | None,
    collection_name: str | None,
) -> list[Mapping[str, object]]:
    if variant_name and collection_name:
        raise ConfigError("Do not combine --variant with --collection")
    if collection_name:
        return selected_variant_collection(config, collection_name)
    return selected_variants(config, variant_name)


def run_all_variant_validation(
    *,
    config: Mapping[str, object],
    config_path: Path,
    config_dir: Path,
    args: argparse.Namespace,
) -> int:
    if args.gallery:
        raise ConfigError("validate does not use --gallery; it validates every variant by default")
    if args.animation_preset:
        raise ConfigError("validate does not support --animation-preset")
    if args.print_resolved_config:
        raise ConfigError("validate does not support --resolved")
    variants = variants_for_requested_subset(
        config,
        variant_name=args.variant,
        collection_name=args.variant_collection,
    )
    validation_args = argparse.Namespace(**vars(args))
    validation_args.validate_only = True
    validation_args.gallery = False

    if not variants:
        render_config(config=config, config_path=config_path, config_dir=config_dir, args=validation_args)
        print("Validated:  1 directly renderable config")
        return 0

    for variant in variants:
        name = str(variant["name"]).strip()
        print(f"Variant:   {name}")
        resolved = variant_config(config, variant)
        render_config(config=resolved, config_path=config_path, config_dir=config_dir, args=validation_args)
    print(f"Validated:  {len(variants)} variant{'s' if len(variants) != 1 else ''}")
    return 0


def run_gallery(
    *,
    config: Mapping[str, object],
    config_path: Path,
    config_dir: Path,
    args: argparse.Namespace,
    gallery_config: Mapping[str, object] | None = None,
    gallery_config_path: Path | None = None,
) -> int:
    configured_collection = configured_gallery_variant_collection(config, gallery_config=gallery_config)
    collection_name = args.variant_collection or (configured_collection if not args.variant else None)
    variants = variants_for_requested_subset(
        config,
        variant_name=args.variant,
        collection_name=collection_name,
    )
    if not variants:
        raise ConfigError("No variants are configured. Add a top-level variants array or render the config normally.")

    resolved_variants = [(str(variant["name"]).strip(), variant_config(config, variant)) for variant in variants]
    settings = gallery_settings(config, gallery_config=gallery_config, variant_count=len(resolved_variants))
    resolved_variants = [
        (name, apply_gallery_target_render_size(resolved_config, settings))
        for name, resolved_config in resolved_variants
    ]
    if args.print_resolved_config:
        print(
            json.dumps(
                {
                    "gallery": settings,
                    "gallery_config": project_relative_or_absolute(gallery_config_path) if gallery_config_path else None,
                    "variant_collection": collection_name,
                    "variants": [
                        {
                            "name": name,
                            "resolved": resolved_config_snapshot(
                                config=resolved_config,
                                config_path=config_path,
                                config_dir=config_dir,
                                args=args,
                            ),
                        }
                        for name, resolved_config in resolved_variants
                    ],
                },
                indent=2,
            )
        )
        return 0
    if args.validate_only:
        for name, resolved_config in resolved_variants:
            print(f"Variant:   {name}")
            render_config(config=resolved_config, config_path=config_path, config_dir=config_dir, args=args)
        return 0

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    gallery_root = output_root_for(config, args) / f"{sanitize_name(base_job_name(config))}__gallery__{timestamp}"
    gallery_root.mkdir(parents=True, exist_ok=True)

    results: list[dict[str, object]] = []
    for name, resolved_config in resolved_variants:
        result = render_config(
            config=resolved_config,
            config_path=config_path,
            config_dir=config_dir,
            args=args,
            run_dir=gallery_root,
        )
        result["variant_name"] = name
        results.append(result)

    contact_sheet = gallery_root / "gallery.png"
    build_gallery_contact_sheet(
        results=results,
        output_path=contact_sheet,
        columns=settings["columns"],
        thumbnail_width=settings["thumbnail_width"],
        thumbnail_height=settings.get("thumbnail_height"),
        margin_px=settings["margin_px"],
        gutter_px=settings["gutter_px"],
        title_height_px=settings["title_height_px"],
        title_font_size_px=settings["title_font_size_px"],
        target_width_px=settings.get("target_width_px"),
        target_height_px=settings.get("target_height_px"),
    )
    metadata = {
        "config": project_relative_or_absolute(config_path),
        "gallery_config": project_relative_or_absolute(gallery_config_path) if gallery_config_path else None,
        "variant_collection": collection_name,
        "gallery": settings,
        "contact_sheet": project_relative_or_absolute(contact_sheet),
        "variants": [
            {
                "name": result["variant_name"],
                "run_dir": project_relative_or_absolute(Path(result["run_dir"])),
                "annotated": project_relative_or_absolute(Path(result["annotated"])),
                "metadata": project_relative_or_absolute(Path(result["metadata"])) if result.get("metadata") else None,
            }
            for result in results
        ],
    }
    metadata_path = gallery_root / "gallery_metadata.json"
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(f"Gallery:      {project_relative_or_absolute(contact_sheet)}")
    print(f"Metadata:     {project_relative_or_absolute(metadata_path)}")
    return 0
