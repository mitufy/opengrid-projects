"""Reusable OpenSCAD-to-Blender annotation rendering utilities."""

from annotation_renderer.config.schema import ConfigError
from annotation_renderer.catalog import default_config_for_model
from annotation_renderer.pipeline import render_config

__all__ = [
    "ConfigError",
    "default_config_for_model",
    "render_config",
]
