"""Content-addressed cache keys for OpenSCAD and Blender stages."""

from __future__ import annotations

import hashlib
import json
import os
import re
from copy import deepcopy
from pathlib import Path
from typing import Mapping, Sequence

from annotation_renderer.openscad import project_relative_or_absolute
from annotation_renderer.paths import PACKAGE_ROOT, PROJECT_ROOT
from annotation_renderer.scad_annotations import with_annotation_metadata_define


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def stable_json(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)


def cache_key_for(value: object) -> str:
    return hashlib.sha256(stable_json(value).encode("utf-8")).hexdigest()


SCAD_DEPENDENCY_PATTERN = re.compile(r"^\s*(?:include|use)\s*<([^>]+)>", re.MULTILINE)


def openscad_library_roots() -> tuple[Path, ...]:
    candidates: list[Path] = [PROJECT_ROOT, PROJECT_ROOT / "lib"]
    configured = os.environ.get("OPENSCADPATH")
    if configured:
        candidates.extend(Path(item).expanduser() for item in configured.split(os.pathsep) if item.strip())
    candidates.extend(
        [
            Path.home() / "Documents" / "OpenSCAD" / "libraries",
            Path.home() / ".local" / "share" / "OpenSCAD" / "libraries",
            Path("/usr/share/openscad/libraries"),
            Path("/usr/local/share/openscad/libraries"),
        ]
    )
    if os.name == "nt":
        candidates.extend(
            [
                Path(r"C:\Program Files\OpenSCAD (Nightly)\libraries"),
                Path(r"C:\Program Files\OpenSCAD\libraries"),
            ]
        )
    roots: list[Path] = []
    seen: set[Path] = set()
    for candidate in candidates:
        resolved = candidate.resolve()
        if resolved in seen or not resolved.exists():
            continue
        seen.add(resolved)
        roots.append(resolved)
    return tuple(roots)


def resolve_scad_dependency(reference: str, *, source: Path, library_roots: Sequence[Path]) -> Path | None:
    reference_path = Path(reference)
    candidates = [source.parent / reference_path, *(root / reference_path for root in library_roots)]
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    return None


def scad_dependency_manifest(
    scad_file: Path,
    *,
    library_roots: Sequence[Path] | None = None,
) -> dict[str, object]:
    roots = tuple(library_roots) if library_roots is not None else openscad_library_roots()
    pending = [scad_file.resolve()]
    visited: set[Path] = set()
    files: list[dict[str, str]] = []
    unresolved: list[dict[str, str]] = []
    while pending:
        source = pending.pop()
        if source in visited:
            continue
        visited.add(source)
        files.append({"path": project_relative_or_absolute(source), "sha256": file_sha256(source)})
        text_value = source.read_text(encoding="utf-8", errors="replace")
        for reference in SCAD_DEPENDENCY_PATTERN.findall(text_value):
            dependency = resolve_scad_dependency(reference.strip(), source=source, library_roots=roots)
            if dependency is None:
                unresolved.append({"source": project_relative_or_absolute(source), "reference": reference.strip()})
            elif dependency not in visited:
                pending.append(dependency)
    return {
        "files": sorted(files, key=lambda item: item["path"]),
        "unresolved": sorted(unresolved, key=lambda item: (item["source"], item["reference"])),
    }


def openscad_stage_cache_key(
    *,
    scad_file: Path,
    defines: Sequence[str],
    executable: str,
    dependency_roots: Sequence[Path] | None = None,
) -> str:
    executable_path = Path(executable)
    return cache_key_for(
        {
            "stage": "openscad_export_v2",
            "scad_file": project_relative_or_absolute(scad_file),
            "dependencies": scad_dependency_manifest(scad_file, library_roots=dependency_roots),
            "defines": list(with_annotation_metadata_define(defines)),
            "executable": executable,
            "executable_sha256": file_sha256(executable_path) if executable_path.is_file() else None,
            "backend": "Manifold",
            "enable_textmetrics": True,
            "enable_lazy_union": True,
        }
    )


def normalized_blender_cache_config(blender_config: Mapping[str, object]) -> dict[str, object]:
    normalized = deepcopy(dict(blender_config))
    normalized["render_path"] = "<render>"
    normalized["projection_path"] = "<projection>"
    normalized.pop("export_blend_path", None)
    normalized.pop("animation_frame_path", None)
    objects = normalized.get("objects")
    if isinstance(objects, list):
        normalized_objects = []
        for item in objects:
            if not isinstance(item, Mapping):
                normalized_objects.append(item)
                continue
            normalized_item = deepcopy(dict(item))
            stl_path = Path(str(normalized_item.get("stl_path", "")))
            if stl_path.exists():
                normalized_item["stl_path"] = {
                    "name": stl_path.name,
                    "sha256": file_sha256(stl_path),
                }
            normalized_objects.append(normalized_item)
        normalized["objects"] = normalized_objects
    return normalized


def blender_stage_cache_key(
    *,
    blender: str,
    blend_file: Path,
    blender_config: Mapping[str, object],
) -> str:
    return cache_key_for(
        {
            "stage": "blender_render_projection_v1",
            "blender": blender,
            "blend_file": project_relative_or_absolute(blend_file),
            "blend_file_sha256": file_sha256(blend_file),
            "runtime_sha256": file_sha256(PACKAGE_ROOT / "blender_runtime.py"),
            "config": normalized_blender_cache_config(blender_config),
        }
    )
