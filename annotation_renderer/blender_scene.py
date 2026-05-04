"""Blender-side scene replacement and projection script generation."""

from __future__ import annotations

from pathlib import Path


RUNTIME_SCRIPT = Path(__file__).with_name("blender_runtime.py")


def write_blender_scene_script(path: Path) -> None:
    path.write_text(RUNTIME_SCRIPT.read_text(encoding="utf-8"), encoding="utf-8")
