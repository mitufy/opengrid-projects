"""Reusable OpenSCAD-to-Blender annotation rendering utilities."""

from annotation_renderer.config_schema import ConfigError
from annotation_renderer.scene_cli import default_config_for_model, render_config

__all__ = [
    "ConfigError",
    "default_config_for_model",
    "render_config",
]
