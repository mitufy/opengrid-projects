"""Built-in model config discovery and shortcut resolution."""

from __future__ import annotations

from pathlib import Path
from typing import Mapping

from annotation_renderer.config.schema import ConfigError
from annotation_renderer.config.validation import resolve_scene
from annotation_renderer.openscad import sanitize_name
from annotation_renderer.paths import CONFIG_DIR


CONFIG_SUFFIXES = (".yaml", ".yml", ".json")
NON_RENDER_CONFIGS = {"animation_presets", "base_scene", "drawer_base", "gallery_defaults"}


def model_name_from_shortcut(raw_name: str) -> str:
    name = Path(raw_name).stem if raw_name.lower().endswith(".scad") else raw_name
    name = sanitize_name(name.strip())
    if not name:
        raise ConfigError("render requires a SCAD model name, for example `render openconnect_general_holder`")
    return name


def config_name_from_shortcut(raw_name: str) -> str:
    stripped = raw_name.strip()
    name = Path(stripped).stem if stripped.lower().endswith(CONFIG_SUFFIXES) else stripped
    name = sanitize_name(name)
    if not name:
        raise ConfigError("render requires a config or SCAD model name, for example `render openconnect_general_holder`")
    return name


def named_config_path(shortcut: str) -> Path | None:
    for suffix in CONFIG_SUFFIXES:
        config_path = CONFIG_DIR / f"{shortcut}{suffix}"
        if config_path.exists():
            return config_path.resolve()
    return None


def available_render_shortcuts() -> list[str]:
    paths = [path for suffix in CONFIG_SUFFIXES for path in CONFIG_DIR.glob(f"*{suffix}")]
    return sorted({path.stem for path in paths if path.stem not in NON_RENDER_CONFIGS})


def default_config_for_model(model_name: str) -> Path:
    if not model_name.strip().lower().endswith(".scad"):
        config_path = named_config_path(config_name_from_shortcut(model_name))
        if config_path is not None:
            return config_path
    shortcut = model_name_from_shortcut(model_name)
    config_path = CONFIG_DIR / f"{shortcut}.yaml"
    if config_path.exists():
        return config_path.resolve()
    available = ", ".join(available_render_shortcuts()) or "none"
    raise ConfigError(
        f"Unknown render shortcut {model_name!r}. Expected annotation_renderer/configs/{shortcut}.yaml. "
        f"Available shortcuts: {available}"
    )


def is_directly_renderable_config(config: Mapping[str, object]) -> bool:
    return resolve_scene(config.get("scene", {})).get("objects") is not None


def model_record_source(record: Mapping[str, object]) -> str:
    for key in ("scad_file", "stl_file", "stl_path"):
        if record.get(key):
            return str(record[key])
    return "unknown"
