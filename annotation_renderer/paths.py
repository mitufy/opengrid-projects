"""Canonical package and repository paths."""

from pathlib import Path


PACKAGE_ROOT = Path(__file__).resolve().parent
PROJECT_ROOT = PACKAGE_ROOT.parent
CONFIG_DIR = PACKAGE_ROOT / "configs"
SCHEMA_DIR = PACKAGE_ROOT / "schemas"
ASSET_DIR = PACKAGE_ROOT / "assets"
DEFAULT_MODEL_CONFIG_PATH = CONFIG_DIR / "model_defaults.yaml"
ANIMATION_PRESET_CONFIG_PATH = CONFIG_DIR / "animation_presets.yaml"
