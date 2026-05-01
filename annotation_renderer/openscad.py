"""OpenSCAD subprocess helpers for annotation renders."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Sequence


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def project_relative_or_absolute(path: Path, *, repo_root: Path = PROJECT_ROOT) -> str:
    resolved_path = path.resolve()
    try:
        return resolved_path.relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(resolved_path)


def sanitize_name(value: str) -> str:
    lowered = value.lower()
    sanitized = re.sub(r"[^a-z0-9._-]+", "_", lowered)
    sanitized = re.sub(r"_+", "_", sanitized).strip("_")
    return sanitized or "value"


def default_windows_openscad_candidates() -> list[Path]:
    local_app_data = Path(os.environ.get("LOCALAPPDATA", ""))
    candidates = [
        Path(r"C:\Program Files\OpenSCAD (Nightly)\openscad.com"),
        Path(r"C:\Program Files\OpenSCAD (Nightly)\openscad.exe"),
        Path(r"C:\Program Files\OpenSCAD\openscad.com"),
        Path(r"C:\Program Files\OpenSCAD\openscad.exe"),
        Path(r"C:\Program Files (x86)\OpenSCAD\openscad.exe"),
    ]
    if local_app_data:
        candidates.append(local_app_data / "Programs" / "OpenSCAD" / "openscad.exe")
    return candidates


def resolve_openscad_executable(executable: str = "openscad") -> str | None:
    raw_path = Path(executable).expanduser()
    if raw_path.exists():
        return str(raw_path.resolve())

    discovered = shutil.which(executable)
    if discovered:
        return discovered

    env_override = os.environ.get("OPENSCAD_EXECUTABLE")
    if env_override:
        env_path = Path(env_override).expanduser()
        if env_path.exists():
            return str(env_path.resolve())

    if os.name == "nt":
        for candidate in default_windows_openscad_candidates():
            if candidate.exists():
                return str(candidate.resolve())

    return None


def require_openscad_executable(executable: str = "openscad") -> str:
    resolved = resolve_openscad_executable(executable)
    if resolved is None:
        raise SystemExit(
            f"Missing required tool: {executable}. Install OpenSCAD, put it on PATH, or set OPENSCAD_EXECUTABLE."
        )
    return resolved


def build_openscad_command(
    *,
    executable: str,
    scad_file: Path,
    output_path: Path,
    defines: Sequence[str] = (),
    backend: str = "Manifold",
    enable_textmetrics: bool = True,
    camera: str | None = None,
    projection: str | None = None,
    imgsize: tuple[int, int] | None = None,
    colorscheme: str | None = None,
) -> list[str]:
    command = [require_openscad_executable(executable)]
    if enable_textmetrics:
        command.extend(["--enable", "textmetrics"])
    command.append(f"--backend={backend}")
    if imgsize is not None:
        command.append(f"--imgsize={imgsize[0]},{imgsize[1]}")
    if projection is not None:
        command.append(f"--projection={projection}")
    if colorscheme is not None:
        command.append(f"--colorscheme={colorscheme}")
    if camera is not None:
        command.append(f"--camera={camera}")
    for define in defines:
        command.extend(["-D", define])
    command.extend(["-o", str(output_path), str(scad_file)])
    return command


def run_command_logged(command: Sequence[str], *, cwd: Path, log_path: Path) -> subprocess.CompletedProcess[object]:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8", errors="replace") as log_handle:
        return subprocess.run(
            [str(item) for item in command],
            cwd=cwd,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            check=False,
        )
