"""Dependency discovery, diagnostics, and renderer smoke checks."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - exercised only in incomplete local environments
    yaml = None

from annotation_renderer.config.defaults import DEFAULT_OUTPUT_DIR
from annotation_renderer.config.loader import load_config
from annotation_renderer.openscad import project_relative_or_absolute, resolve_openscad_executable
from annotation_renderer.paths import ASSET_DIR, PROJECT_ROOT


MINIMUM_BLENDER_VERSION = (5, 1, 0)
BLENDER_SCENE_PROBE_MARKER = "OPENGRID_SCENE_OPENED"


def default_windows_blender_candidates() -> list[Path]:
    candidates = [
        Path(r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"),
        Path(r"C:\Program Files\Blender Foundation\Blender\blender.exe"),
    ]
    foundation = Path(r"C:\Program Files\Blender Foundation")
    if foundation.exists():
        candidates.extend(sorted(foundation.glob("Blender *\\blender.exe"), reverse=True))
    return candidates


def resolve_blender_executable(executable: str = "blender") -> str | None:
    raw_path = Path(executable).expanduser()
    if raw_path.exists():
        return str(raw_path.resolve())
    discovered = shutil.which(executable)
    if discovered:
        return discovered
    env_override = os.environ.get("BLENDER_EXECUTABLE")
    if env_override:
        env_path = Path(env_override).expanduser()
        if env_path.exists():
            return str(env_path.resolve())
    if os.name == "nt":
        for candidate in default_windows_blender_candidates():
            if candidate.exists():
                return str(candidate.resolve())
    return None


def parse_blender_version(output: str) -> tuple[int, int, int] | None:
    match = re.search(r"\bBlender\s+(\d+)\.(\d+)(?:\.(\d+))?", output)
    if match is None:
        return None
    return tuple(int(value or 0) for value in match.groups())


def blender_version(executable: str) -> tuple[int, int, int] | None:
    try:
        result = subprocess.run(
            [executable, "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
            timeout=15,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return parse_blender_version(result.stdout or "")


def blender_version_text(version: tuple[int, int, int] | None) -> str:
    return ".".join(str(item) for item in version) if version is not None else "unknown"


def blender_can_open_scene(executable: str, scene_path: Path) -> tuple[bool, str]:
    try:
        result = subprocess.run(
            [
                executable,
                "--background",
                "--factory-startup",
                str(scene_path),
                "--python-expr",
                f"print('{BLENDER_SCENE_PROBE_MARKER}')",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return False, str(exc)
    output = result.stdout or ""
    if result.returncode == 0 and BLENDER_SCENE_PROBE_MARKER in output:
        return True, project_relative_or_absolute(scene_path)
    detail = next((line.strip() for line in output.splitlines() if "Error:" in line), "scene open probe failed")
    return False, detail


def require_blender_executable(executable: str = "blender") -> str:
    resolved = resolve_blender_executable(executable)
    if resolved is None:
        raise SystemExit(
            f"Missing required tool: {executable}. Install Blender, put it on PATH, or set BLENDER_EXECUTABLE."
        )
    version = blender_version(resolved)
    if version is None or version < MINIMUM_BLENDER_VERSION:
        raise SystemExit(
            f"Blender {blender_version_text(MINIMUM_BLENDER_VERSION)} or newer is required by the bundled scenes; "
            f"found {blender_version_text(version)} at {resolved}."
        )
    return resolved


def log_tail(log_path: Path, *, line_count: int = 40) -> str:
    try:
        lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return ""
    return "\n".join(lines[-line_count:])


def command_failure_message(message: str, *, log_path: Path, line_count: int = 40) -> str:
    tail = log_tail(log_path, line_count=line_count)
    log_reference = project_relative_or_absolute(log_path)
    if not tail:
        return f"{message}. Log: {log_reference}"
    return f"{message}. Last {line_count} log lines:\n{tail}\nLog: {log_reference}"


def format_doctor_check(ok: bool, label: str, detail: str) -> str:
    return f"[{'OK' if ok else 'FAIL'}] {label}: {detail}"


def doctor_checks(args: argparse.Namespace) -> list[tuple[bool, str, str]]:
    checks: list[tuple[bool, str, str]] = [(True, "Python", sys.executable)]
    checks.append((yaml is not None, "PyYAML", "available" if yaml is not None else "missing"))

    openscad = resolve_openscad_executable(args.openscad)
    checks.append(
        (
            openscad is not None,
            "OpenSCAD",
            openscad or f"not found for {args.openscad!r}; set OPENSCAD_EXECUTABLE or pass --openscad",
        )
    )
    blender = resolve_blender_executable(args.blender)
    checks.append(
        (
            blender is not None,
            "Blender",
            blender or f"not found for {args.blender!r}; set BLENDER_EXECUTABLE or pass --blender",
        )
    )
    runtime_version = blender_version(blender) if blender is not None else None
    version_ok = runtime_version is not None and runtime_version >= MINIMUM_BLENDER_VERSION
    checks.append(
        (
            version_ok,
            "Blender version",
            f"{blender_version_text(runtime_version)} (requires {blender_version_text(MINIMUM_BLENDER_VERSION)}+)",
        )
    )

    default_scene = ASSET_DIR / "scenes" / "opengrid_wall_scene.blend"
    checks.append((default_scene.exists(), "Default Blender scene", project_relative_or_absolute(default_scene)))
    if blender is not None and version_ok and default_scene.exists():
        scene_ok, scene_detail = blender_can_open_scene(blender, default_scene)
        checks.append((scene_ok, "Default Blender scene compatibility", scene_detail))

    output_root = PROJECT_ROOT / DEFAULT_OUTPUT_DIR
    try:
        output_root.mkdir(parents=True, exist_ok=True)
        checks.append((True, "Output directory", project_relative_or_absolute(output_root)))
    except OSError as exc:
        checks.append((False, "Output directory", f"{project_relative_or_absolute(output_root)} ({exc})"))
    return checks


def run_doctor(args: argparse.Namespace) -> int:
    checks = doctor_checks(args)
    print("Annotation renderer doctor")
    for ok, label, detail in checks:
        print(format_doctor_check(ok, label, detail))
    if not all(ok for ok, _label, _detail in checks):
        return 1
    if not args.smoke_render:
        return 0

    from annotation_renderer.catalog import default_config_for_model
    from annotation_renderer.pipeline import render_config

    config_path = default_config_for_model("openconnect_general_holder")
    print("Smoke render: openconnect_general_holder")
    smoke_args = argparse.Namespace(**vars(args))
    smoke_args.animation_preset = None
    smoke_args.cache_dir = None
    smoke_args.export_blend = False
    smoke_args.gallery = False
    smoke_args.gallery_config = None
    smoke_args.no_cache = False
    smoke_args.output_file = None
    smoke_args.output_mode = "minimal"
    smoke_args.print_resolved_config = False
    smoke_args.validate_only = False
    smoke_args.variant = None
    smoke_args.variant_collection = None
    config = load_config(config_path, smoke_args.overrides)
    render_config(config=config, config_path=config_path, config_dir=config_path.parent, args=smoke_args)
    return 0
