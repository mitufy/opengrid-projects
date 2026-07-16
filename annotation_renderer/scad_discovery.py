"""Static SCAD source annotation discovery helpers."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Mapping, Sequence

try:
    import yaml
except ImportError:  # pragma: no cover - exercised only in incomplete local environments
    yaml = None

from annotation_renderer.config.schema import ConfigError
from annotation_renderer.openscad import project_relative_or_absolute
from annotation_renderer.paths import PROJECT_ROOT


JSON_DISCOVERY_SUFFIXES = {".json"}
YAML_DISCOVERY_SUFFIXES = {".yaml", ".yml"}
TEXT_DISCOVERY_SUFFIXES = {".txt", ".text"}
OBJECT_SELECTOR_DEFINES = {"generate_drawer_shell", "generate_drawer_container"}
HIDDEN_SECTION_RE = re.compile(r"/\*\s*\[Hidden\]\s*\*/")
TOP_LEVEL_ASSIGNMENT_RE = re.compile(r"^\s*([A-Za-z_$][A-Za-z0-9_$]*)\s*=")
PARAMETER_SECTIONS = (
    ("dimension", "dimension parameters", "add to annotations.chains[].ids"),
    (
        "radius",
        "radius parameters",
        "add to annotations.radius_callouts[].ids or annotations.angle_radius_callouts[].radius_id",
    ),
    (
        "arc",
        "arc parameters",
        "add to annotations.arc_callouts[].ids or annotations.angle_radius_callouts[].arc_id",
    ),
    (
        "context",
        "context value parameters",
        "add to annotations.image_labels[].id; numeric values also work in offsets and angle_radius_callouts[].angle_id",
    ),
)


def discovery_output_format(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in TEXT_DISCOVERY_SUFFIXES:
        return "text"
    if suffix in JSON_DISCOVERY_SUFFIXES:
        return "json"
    if suffix in YAML_DISCOVERY_SUFFIXES:
        return "yaml"
    raise ConfigError(f"Unsupported discovery output format for {path}. Use .txt, .json, .yaml, or .yml.")


def resolve_discovery_scad_path(value: str, *, project_root: Path = PROJECT_ROOT) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = (project_root / path).resolve()
    if path.suffix.lower() != ".scad":
        raise ConfigError("--discover-annotations expects a .scad file path, not a render config model name")
    if not path.exists():
        raise ConfigError(f"SCAD file not found: {path}")
    return path


def strip_scad_comments(source: str) -> str:
    chars = list(source)
    index = 0
    in_string = False
    while index < len(chars):
        char = chars[index]
        next_char = chars[index + 1] if index + 1 < len(chars) else ""
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
            index += 1
            continue
        if char == "/" and next_char == "/":
            chars[index] = " "
            chars[index + 1] = " "
            index += 2
            while index < len(chars) and chars[index] != "\n":
                chars[index] = " "
                index += 1
            continue
        if char == "/" and next_char == "*":
            chars[index] = " "
            chars[index + 1] = " "
            index += 2
            while index + 1 < len(chars) and not (chars[index] == "*" and chars[index + 1] == "/"):
                if chars[index] != "\n":
                    chars[index] = " "
                index += 1
            if index + 1 < len(chars):
                chars[index] = " "
                chars[index + 1] = " "
                index += 2
            continue
        index += 1
    return "".join(chars)


def matching_delimiter_index(source: str, open_index: int, *, open_char: str, close_char: str) -> int | None:
    depth = 0
    index = open_index
    in_string = False
    while index < len(source):
        char = source[index]
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
        elif char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth == 0:
                return index
        index += 1
    return None


def matching_open_delimiter_index(source: str, close_index: int, *, open_char: str, close_char: str) -> int | None:
    depth = 0
    index = close_index
    in_string = False
    while index >= 0:
        char = source[index]
        if in_string:
            if char == '"':
                backslashes = 0
                probe = index - 1
                while probe >= 0 and source[probe] == "\\":
                    backslashes += 1
                    probe -= 1
                if backslashes % 2 == 0:
                    in_string = False
            index -= 1
            continue
        if char == '"':
            in_string = True
        elif char == close_char:
            depth += 1
        elif char == open_char:
            depth -= 1
            if depth == 0:
                return index
        index -= 1
    return None


def condition_before_block(source: str, brace_index: int) -> str | None:
    index = brace_index - 1
    while index >= 0 and source[index].isspace():
        index -= 1
    if index < 0 or source[index] != ")":
        return None
    open_index = matching_open_delimiter_index(source, index, open_char="(", close_char=")")
    if open_index is None:
        return None
    prefix_end = open_index - 1
    while prefix_end >= 0 and source[prefix_end].isspace():
        prefix_end -= 1
    prefix_start = prefix_end
    while prefix_start >= 0 and (source[prefix_start].isalnum() or source[prefix_start] == "_"):
        prefix_start -= 1
    keyword = source[prefix_start + 1 : prefix_end + 1]
    if keyword != "if":
        return None
    return " ".join(source[open_index + 1 : index].split())


def scad_conditional_block_ranges(source: str) -> list[tuple[int, int, str]]:
    ranges: list[tuple[int, int, str]] = []
    stack: list[tuple[int, str | None]] = []
    index = 0
    in_string = False
    while index < len(source):
        char = source[index]
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            stack.append((index, condition_before_block(source, index)))
        elif char == "}" and stack:
            start, condition = stack.pop()
            if condition:
                ranges.append((start, index, condition))
        index += 1
    return ranges


def split_top_level(value: str, separator: str = ",") -> list[str]:
    parts: list[str] = []
    start = 0
    depths = {"(": 0, "[": 0, "{": 0}
    matching = {")": "(", "]": "[", "}": "{"}
    in_string = False
    index = 0
    while index < len(value):
        char = value[index]
        if in_string:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
        elif char in depths:
            depths[char] += 1
        elif char in matching:
            depths[matching[char]] = max(0, depths[matching[char]] - 1)
        elif char == separator and all(depth == 0 for depth in depths.values()):
            parts.append(value[start:index].strip())
            start = index + 1
        index += 1
    tail = value[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def split_top_level_assignment(value: str) -> tuple[str, str] | None:
    parts = split_top_level(value, separator="=")
    if len(parts) != 2:
        return None
    return parts[0].strip(), parts[1].strip()


def scad_string_literal(value: str) -> str | None:
    stripped = value.strip()
    if not stripped.startswith('"') or not stripped.endswith('"'):
        return None
    try:
        parsed = json.loads(stripped)
    except json.JSONDecodeError:
        return stripped[1:-1]
    return parsed if isinstance(parsed, str) else None


def scad_string_literals(value: str) -> list[str]:
    literals: list[str] = []
    for match in re.finditer(r'"(?:\\.|[^"\\])*"', value):
        literal = scad_string_literal(match.group(0))
        if literal is not None:
            literals.append(literal)
    return literals


def scad_customizer_parameter_names(source: str) -> frozenset[str] | None:
    hidden_match = HIDDEN_SECTION_RE.search(source)
    if hidden_match is None:
        return None
    visible_source = strip_scad_comments(source[: hidden_match.start()])
    names: set[str] = set()
    for line in visible_source.splitlines():
        match = TOP_LEVEL_ASSIGNMENT_RE.match(line)
        if match is None:
            continue
        name = match.group(1)
        if not name.startswith("$"):
            names.add(name)
    return frozenset(names)


def scad_call_named_arguments(call_body: str) -> dict[str, str]:
    arguments: dict[str, str] = {}
    for part in split_top_level(call_body):
        assignment = split_top_level_assignment(part)
        if assignment is None:
            continue
        key, value = assignment
        if key:
            arguments[key] = value
    return arguments


def scad_boolean_define_allows_condition(condition: str, defines: Mapping[str, object]) -> bool:
    for name, value in defines.items():
        if str(name) not in OBJECT_SELECTOR_DEFINES:
            continue
        if not isinstance(value, bool):
            continue
        for match in re.finditer(rf"(?<![A-Za-z0-9_!])(!?)\b{re.escape(str(name))}\b(?![A-Za-z0-9_])", condition):
            negated = bool(match.group(1))
            allowed = not value if negated else value
            if not allowed:
                return False
    return True


def discover_scad_source_annotations(scad_file: Path, *, defines: Mapping[str, object]) -> tuple[dict[str, object], ...]:
    raw_source = scad_file.read_text(encoding="utf-8")
    customizer_parameters = scad_customizer_parameter_names(raw_source)
    source = strip_scad_comments(raw_source)
    conditional_ranges = scad_conditional_block_ranges(source)
    annotations: list[dict[str, object]] = []
    call_pattern = re.compile(
        r"\b(emit_context_values|emit_[A-Za-z0-9_]*dimension_annotation|emit_[A-Za-z0-9_]*radius_annotation|emit_[A-Za-z0-9_]*arc_annotation|emit_[A-Za-z0-9_]*feature_annotation)\s*\("
    )
    for match in call_pattern.finditer(source):
        prefix = source[max(0, match.start() - 16) : match.start()]
        if re.search(r"\bmodule\s+$", prefix):
            continue
        open_index = source.find("(", match.start())
        close_index = matching_delimiter_index(source, open_index, open_char="(", close_char=")")
        if close_index is None:
            continue
        conditions = [
            condition
            for start, end, condition in conditional_ranges
            if start < match.start() < end
        ]
        if any(not scad_boolean_define_allows_condition(condition, defines) for condition in conditions):
            continue
        call_name = match.group(1)
        call_body = source[open_index + 1 : close_index]
        if call_name == "emit_context_values":
            positional = split_top_level(call_body)
            source_id = scad_string_literal(positional[0]) if positional else None
            names = scad_string_literals(positional[1]) if len(positional) > 1 else []
            for name in names:
                annotation: dict[str, object] = {"id": name, "kind": "context", "source": source_id or "context"}
                if customizer_parameters is not None and name not in customizer_parameters:
                    annotation["internal"] = True
                if conditions:
                    annotation["conditions"] = conditions
                annotations.append(annotation)
            continue
        arguments = scad_call_named_arguments(call_body)
        annotation_id = scad_string_literal(arguments.get("id", ""))
        if not annotation_id:
            continue
        if call_name.endswith("dimension_annotation"):
            annotation_kind = "dimension"
        elif call_name.endswith("radius_annotation"):
            annotation_kind = "radius"
        elif call_name.endswith("arc_annotation"):
            annotation_kind = "arc"
        else:
            annotation_kind = "feature"
        annotation: dict[str, object] = {
            "id": annotation_id,
            "kind": annotation_kind,
        }
        if customizer_parameters is not None and annotation_id not in customizer_parameters:
            annotation["internal"] = True
        if conditions:
            annotation["conditions"] = conditions
        axis = scad_string_literal(arguments.get("axis", ""))
        label = scad_string_literal(arguments.get("label", ""))
        basis = scad_string_literal(arguments.get("basis", ""))
        if axis:
            annotation["axis"] = axis
        if label and label != annotation_id:
            annotation["label"] = label
        if basis:
            annotation["basis"] = basis
        annotations.append(annotation)
    return tuple(annotations)


def discovered_annotation_summary(annotation: Mapping[str, object]) -> str:
    annotation_id = str(annotation.get("id", "unknown"))
    parts = [annotation_id]
    axis = annotation.get("axis")
    label = annotation.get("label")
    basis = annotation.get("basis")
    conditions = annotation.get("conditions")
    details = []
    if isinstance(axis, str) and axis:
        details.append(f"axis={axis}")
    if isinstance(label, str) and label and label != annotation_id:
        details.append(f"label={label}")
    if isinstance(basis, str) and basis:
        details.append(f"basis={basis}")
    if isinstance(conditions, Sequence) and not isinstance(conditions, (str, bytes)) and conditions:
        details.append("when=" + " && ".join(str(condition) for condition in conditions))
    if details:
        parts.append(f" ({', '.join(details)})")
    return "".join(parts)


def context_parameter_entries(annotations: Sequence[Mapping[str, object]]) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    seen: set[str] = set()
    for annotation in annotations:
        if annotation.get("kind") != "context":
            continue
        if annotation.get("internal"):
            continue
        source_id = str(annotation.get("id") or "")
        values = annotation.get("values")
        added_value = False
        if isinstance(values, str):
            for part in values.split(";"):
                if "=" not in part:
                    continue
                raw_name, _raw_value = part.split("=", 1)
                name = raw_name.strip()
                if not name:
                    continue
                added_value = True
                if name in seen:
                    continue
                seen.add(name)
                entry: dict[str, object] = {
                    "id": name,
                    "kind": "context",
                }
                entries.append(entry)
        if added_value or not source_id or source_id in seen:
            continue
        seen.add(source_id)
        entry = {
            "id": source_id,
            "kind": "context",
        }
        source = annotation.get("source")
        conditions = annotation.get("conditions")
        if isinstance(source, str) and source.strip():
            entry["source"] = source
        if isinstance(conditions, Sequence) and not isinstance(conditions, (str, bytes)) and conditions:
            entry["conditions"] = list(conditions)
        entries.append(entry)
    return entries


def compact_parameter_entry(annotation: Mapping[str, object]) -> dict[str, object]:
    entry: dict[str, object] = {
        "id": str(annotation.get("id") or "unknown"),
        "kind": str(annotation.get("kind", "feature")),
    }
    for key in ("axis", "label", "basis", "source", "conditions"):
        value = annotation.get(key)
        if value is not None and (not isinstance(value, str) or value.strip()):
            entry[key] = value
    return entry


def discovered_parameter_groups(annotations: Sequence[Mapping[str, object]]) -> dict[str, list[Mapping[str, object]]]:
    grouped: dict[str, list[Mapping[str, object]]] = {}
    supported_kinds = {kind for kind, _label, _hint in PARAMETER_SECTIONS}
    for annotation in annotations:
        if annotation.get("internal"):
            continue
        kind = str(annotation.get("kind", "feature"))
        if kind == "context":
            continue
        if kind not in supported_kinds:
            continue
        grouped.setdefault(kind, []).append(compact_parameter_entry(annotation))
    context_entries = context_parameter_entries(annotations)
    if context_entries:
        grouped["context"] = context_entries
    return grouped


def format_annotation_discovery(name: str, object_discoveries: Sequence[Mapping[str, object]]) -> str:
    preferred_kinds = tuple(kind for kind, _label, _hint in PARAMETER_SECTIONS)
    lines = [f"Available annotation parameters for {name}:"]
    for discovery in object_discoveries:
        object_id = str(discovery.get("id") or "model")
        annotations = discovery.get("annotations", ())
        if not isinstance(annotations, Sequence) or isinstance(annotations, (str, bytes)):
            annotations = ()
        log_path = discovery.get("log_path")
        source_path = discovery.get("source_path")
        lines.append(f"- object: {object_id}")
        if isinstance(source_path, Path):
            lines.append(f"  source: {project_relative_or_absolute(source_path)}")
        if isinstance(log_path, Path) and log_path.exists():
            lines.append(f"  log: {project_relative_or_absolute(log_path)}")
        if not annotations:
            lines.append("  no annotation parameters emitted")
            continue

        grouped = discovered_parameter_groups(
            [annotation for annotation in annotations if isinstance(annotation, Mapping)]
        )

        ordered_kinds = [
            *[kind for kind in preferred_kinds if kind in grouped],
            *sorted(kind for kind in grouped if kind not in preferred_kinds),
        ]
        if not ordered_kinds:
            lines.append("  no annotation parameters emitted")
            continue
        for kind in ordered_kinds:
            section = next(
                ((label, hint) for section_kind, label, hint in PARAMETER_SECTIONS if section_kind == kind),
                (f"{kind} parameters", "custom annotation metadata"),
            )
            lines.append(f"  {section[0]} ({section[1]}):")
            for annotation in grouped[kind]:
                lines.append(f"    - {discovered_annotation_summary(annotation)}")
    return "\n".join(lines)


def discovery_summary_json(
    *,
    name: str,
    object_discoveries: Sequence[Mapping[str, object]],
) -> dict[str, object]:
    objects = []
    for discovery in object_discoveries:
        annotations = discovery.get("annotations", ())
        if not isinstance(annotations, Sequence) or isinstance(annotations, (str, bytes)):
            annotations = ()
        parsed_annotations = [annotation for annotation in annotations if isinstance(annotation, Mapping)]
        object_summary: dict[str, object] = {
            "id": str(discovery.get("id") or "model"),
            "annotation_count": len(parsed_annotations),
            "parameters": {
                kind: list(items)
                for kind, items in discovered_parameter_groups(parsed_annotations).items()
            },
        }
        source_path = discovery.get("source_path")
        if isinstance(source_path, Path):
            object_summary["source"] = project_relative_or_absolute(source_path)
        objects.append(object_summary)
    return {
        "name": name,
        "objects": objects,
    }


def write_annotation_discovery_output(
    *,
    output_path: Path,
    text_output: str,
    name: str,
    discoveries: Sequence[Mapping[str, object]],
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_format = discovery_output_format(output_path)
    if output_format == "text":
        output_path.write_text(text_output + "\n", encoding="utf-8")
        return
    summary = discovery_summary_json(name=name, object_discoveries=discoveries)
    if output_format == "json":
        output_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        return
    if yaml is None:
        raise ConfigError("YAML discovery output requires PyYAML. Install with `pip install PyYAML`.")
    output_path.write_text(
        yaml.safe_dump(
            summary,
            sort_keys=False,
            allow_unicode=False,
            default_flow_style=False,
        ),
        encoding="utf-8",
    )
