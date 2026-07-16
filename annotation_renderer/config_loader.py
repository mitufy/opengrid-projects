"""Config file loading, inheritance, variants, and serialization."""

from __future__ import annotations

import json
import re
from copy import deepcopy
from pathlib import Path
from typing import Mapping, Sequence

try:
    import yaml
except ImportError:  # pragma: no cover - exercised only in incomplete local environments
    yaml = None

from annotation_renderer.config_resolution import (
    apply_annotation_overrides,
    apply_object_overrides,
    deep_merge,
    resolve_config_constants,
    resolve_constant_references,
)
from annotation_renderer.config_schema import ConfigError
from annotation_renderer.config_validation import validate_config_shape
from annotation_renderer.openscad import project_relative_or_absolute, sanitize_name


PROJECT_ROOT = Path(__file__).resolve().parent.parent
JSON_CONFIG_SUFFIXES = {"", ".json"}
YAML_CONFIG_SUFFIXES = {".yaml", ".yml"}
INHERITED_VARIANTS_KEY = "_inherited_variants"


def parse_override_value(value: str) -> object:
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value


def parse_override_path(path: str) -> list[str | int]:
    tokens: list[str | int] = []
    for part in path.split("."):
        part = part.strip()
        if not part:
            continue
        index = 0
        match = re.match(r"[A-Za-z0-9_$-]+", part)
        if match:
            tokens.append(match.group(0))
            index = match.end()
        while index < len(part):
            bracket = re.match(r"\[(\d+)\]", part[index:])
            if bracket is None:
                raise ConfigError(f"Invalid --set path segment {part!r}")
            tokens.append(int(bracket.group(1)))
            index += bracket.end()
    if not tokens:
        raise ConfigError("Override path is empty")
    return tokens


def named_list_item_index(items: Sequence[object], selector: str, *, operation: str) -> int:
    matches = [
        index
        for index, item in enumerate(items)
        if isinstance(item, Mapping)
        and selector in {str(item.get("id") or ""), str(item.get("name") or "")}
    ]
    if not matches:
        raise ConfigError(f"{operation} cannot find named array item {selector!r}")
    if len(matches) > 1:
        raise ConfigError(f"{operation} array item selector {selector!r} is ambiguous")
    return matches[0]


def list_item_index(items: Sequence[object], token: str | int, *, operation: str) -> int:
    if isinstance(token, int):
        if token < 0 or token >= len(items):
            raise ConfigError(f"{operation} array index [{token}] is out of range")
        return token
    return named_list_item_index(items, token, operation=operation)


def set_dotted_value(config: dict[str, object], path: str, assigned_value: object) -> None:
    tokens = parse_override_path(path)
    current: object = config
    for index, token in enumerate(tokens[:-1]):
        next_token = tokens[index + 1]
        if isinstance(current, list):
            current = current[list_item_index(current, token, operation="--set")]
            continue
        if isinstance(token, int):
            raise ConfigError(f"--set cannot index into non-array path at [{token}]")
        if not isinstance(current, dict):
            raise ConfigError(f"--set cannot descend into non-object path {token!r}")
        value = current.get(token)
        if value is None:
            value = [] if isinstance(next_token, int) else {}
            current[token] = value
        current = value
    final_token = tokens[-1]
    if isinstance(current, list):
        current[list_item_index(current, final_token, operation="--set")] = assigned_value
        return
    if isinstance(final_token, int):
        raise ConfigError(f"--set cannot index into non-array path at [{final_token}]")
    if not isinstance(current, dict):
        raise ConfigError(f"--set cannot assign into non-object path {final_token!r}")
    current[final_token] = assigned_value


def unset_dotted_value(config: dict[str, object], path: str) -> None:
    tokens = parse_override_path(path)
    current: object = config
    for token in tokens[:-1]:
        if isinstance(current, list):
            current = current[list_item_index(current, token, operation="unset")]
            continue
        if isinstance(token, int):
            raise ConfigError(f"unset cannot index into non-array path at [{token}]")
        if not isinstance(current, dict) or token not in current:
            raise ConfigError(f"unset path {path!r} does not exist")
        current = current[token]

    final_token = tokens[-1]
    if isinstance(current, list):
        current.pop(list_item_index(current, final_token, operation="unset"))
        return
    if isinstance(final_token, int):
        raise ConfigError(f"unset cannot index into non-array path at [{final_token}]")
    if not isinstance(current, dict) or final_token not in current:
        raise ConfigError(f"unset path {path!r} does not exist")
    del current[final_token]


def apply_override(config: dict[str, object], override: str) -> None:
    if "=" not in override:
        raise ConfigError(f"--set override must be path=value, got {override!r}")
    path, raw_value = override.split("=", 1)
    set_dotted_value(config, path, parse_override_value(raw_value))


class NoAliasSafeDumper(yaml.SafeDumper if yaml is not None else object):
    def ignore_aliases(self, data: object) -> bool:
        return True


class ConfigSafeLoader(yaml.SafeLoader if yaml is not None else object):
    pass


def represent_compact_sequence(dumper: object, data: Sequence[object]) -> object:
    flow_style = len(data) <= 4 and all(
        not isinstance(item, Mapping)
        and (not isinstance(item, Sequence) or isinstance(item, (str, bytes)))
        for item in data
    )
    return dumper.represent_sequence("tag:yaml.org,2002:seq", data, flow_style=flow_style)


if yaml is not None:
    ConfigSafeLoader.yaml_implicit_resolvers = {
        key: list(resolvers)
        for key, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
    }
    for key, resolvers in list(ConfigSafeLoader.yaml_implicit_resolvers.items()):
        ConfigSafeLoader.yaml_implicit_resolvers[key] = [
            (tag, regexp)
            for tag, regexp in resolvers
            if tag != "tag:yaml.org,2002:bool"
        ]
    ConfigSafeLoader.add_implicit_resolver(
        "tag:yaml.org,2002:bool",
        re.compile(r"^(?:true|false|True|False|TRUE|FALSE)$"),
        list("tTfF"),
    )
    NoAliasSafeDumper.add_representer(list, represent_compact_sequence)
    NoAliasSafeDumper.add_representer(tuple, represent_compact_sequence)


def config_format(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in JSON_CONFIG_SUFFIXES:
        return "json"
    if suffix in YAML_CONFIG_SUFFIXES:
        return "yaml"
    raise ConfigError(f"Unsupported config format for {path}. Use .json, .yaml, or .yml.")


def load_mapping_file(path: Path, *, description: str) -> dict[str, object]:
    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise ConfigError(f"{description} not found: {path}") from exc

    file_format = config_format(path)
    try:
        if file_format == "json":
            data = json.loads(text)
        else:
            if yaml is None:
                raise ConfigError("YAML config support requires PyYAML. Install with `pip install PyYAML`.")
            data = yaml.load(text, Loader=ConfigSafeLoader)
    except ConfigError:
        raise
    except Exception as exc:
        raise ConfigError(f"Could not parse {description.lower()} {path}: {exc}") from exc

    if data is None:
        data = {}
    if not isinstance(data, Mapping):
        raise ConfigError(f"{description} must be an object")
    return dict(data)


def dump_config_data(data: Mapping[str, object], *, path: Path) -> str:
    file_format = config_format(path)
    if file_format == "json":
        return json.dumps(data, indent=2) + "\n"
    if yaml is None:
        raise ConfigError("YAML config support requires PyYAML. Install with `pip install PyYAML`.")
    return yaml.dump(
        dict(data),
        Dumper=NoAliasSafeDumper,
        sort_keys=False,
        allow_unicode=False,
        default_flow_style=False,
    )


def variant_from_config_file(
    config: Mapping[str, object],
    *,
    path: Path,
    selected_variant: str | None = None,
    variant_name_override: str | None = None,
) -> dict[str, object]:
    variant_name = variant_name_override or config.get("variant_name") or path.stem
    if not isinstance(variant_name, str) or not variant_name.strip():
        raise ConfigError(f"variant_name must be a non-empty string in {project_relative_or_absolute(path)}")
    selected_config = config
    default_variant = selected_variant or config.get("default_variant")
    if default_variant is not None:
        if not isinstance(default_variant, str) or not default_variant.strip():
            raise ConfigError(f"default_variant must be a non-empty string in {project_relative_or_absolute(path)}")
        resolved_config = resolve_config_constants(config, include_variants=False)
        matches = selected_variants(resolved_config, default_variant.strip())
        if not matches:
            selector_name = "variant" if selected_variant is not None else "default_variant"
            raise ConfigError(
                f"{selector_name} {default_variant!r} does not match a variant in "
                f"{project_relative_or_absolute(path)}"
            )
        selected_config = variant_config(resolved_config, matches[0])
    variant: dict[str, object] = {"name": variant_name.strip(), "_source_config": str(path)}
    for key in ("job_name", "output_dir", "constants", "scene", "render", "annotations"):
        if key in selected_config:
            variant[key] = deepcopy(selected_config[key])
    return variant


def expand_variant_configs(config: dict[str, object], *, config_dir: Path, seen: tuple[Path, ...]) -> dict[str, object]:
    variant_paths = config.pop("variant_configs", None)
    if variant_paths is None:
        return config
    if not isinstance(variant_paths, Sequence) or isinstance(variant_paths, (str, bytes)):
        raise ConfigError("variant_configs must be an array of config paths")

    constants = config.get("constants", {})
    if constants is None:
        constants = {}
    if not isinstance(constants, Mapping):
        raise ConfigError("constants must be an object when variant_configs is used")
    merged_constants: Mapping[str, object] = constants

    variants = config.get("variants", [])
    if variants is None:
        variants = []
    if not isinstance(variants, Sequence) or isinstance(variants, (str, bytes)):
        raise ConfigError("variants must be an array when variant_configs is used")
    merged_variants: list[object] = [deepcopy(item) for item in variants]

    for index, raw_entry in enumerate(variant_paths):
        selected_variant: str | None = None
        variant_name_override: str | None = None
        if isinstance(raw_entry, str):
            raw_path = raw_entry
        elif isinstance(raw_entry, Mapping):
            unknown_keys = set(raw_entry) - {"path", "variant", "name"}
            if unknown_keys:
                unknown = ", ".join(sorted(str(key) for key in unknown_keys))
                raise ConfigError(f"variant_configs[{index}] contains unknown fields: {unknown}")
            raw_path = raw_entry.get("path")
            selected_variant = raw_entry.get("variant")
            variant_name_override = raw_entry.get("name")
            if selected_variant is not None and (not isinstance(selected_variant, str) or not selected_variant.strip()):
                raise ConfigError(f"variant_configs[{index}].variant must be a non-empty string")
            if variant_name_override is not None and (
                not isinstance(variant_name_override, str) or not variant_name_override.strip()
            ):
                raise ConfigError(f"variant_configs[{index}].name must be a non-empty string")
        else:
            raise ConfigError(f"variant_configs[{index}] must be a path string or an object")
        if not isinstance(raw_path, str) or not raw_path.strip():
            raise ConfigError(f"variant_configs[{index}].path must be a non-empty string")
        variant_path = resolve_optional_config_path(raw_path, config_dir=config_dir)
        included_config = load_raw_config(variant_path, seen)
        included_constants = included_config.get("constants", {})
        if included_constants is not None:
            if not isinstance(included_constants, Mapping):
                raise ConfigError(f"constants must be an object in {project_relative_or_absolute(variant_path)}")
            merged_constants = deep_merge(merged_constants, included_constants)
        merged_variants.append(
            variant_from_config_file(
                included_config,
                path=variant_path,
                selected_variant=selected_variant.strip() if selected_variant is not None else None,
                variant_name_override=variant_name_override.strip() if variant_name_override is not None else None,
            )
        )

    config["constants"] = deepcopy(dict(merged_constants))
    config["variants"] = merged_variants
    return config


def load_raw_config(path: Path, seen: tuple[Path, ...] = ()) -> dict[str, object]:
    if path in seen:
        chain = " -> ".join(project_relative_or_absolute(item) for item in (*seen, path))
        raise ConfigError(f"Config extends cycle detected: {chain}")
    config = load_mapping_file(path, description="Config")
    extends_value = config.pop("extends", None)
    if extends_value is None:
        return expand_variant_configs(config, config_dir=path.parent, seen=(*seen, path))
    if not isinstance(extends_value, str) or not extends_value.strip():
        raise ConfigError("extends must be a non-empty string")
    base_path = resolve_optional_config_path(extends_value, config_dir=path.parent)
    base_config = load_raw_config(base_path, (*seen, path))
    merged_config = deep_merge(base_config, config)
    if "variants" in config:
        if "default_variant" not in config:
            merged_config.pop("default_variant", None)
        if "variant_collections" in config:
            merged_config["variant_collections"] = deepcopy(config["variant_collections"])
        else:
            merged_config.pop("variant_collections", None)
        inherited_variants = [
            *deepcopy(base_config.get(INHERITED_VARIANTS_KEY, [])),
            *deepcopy(base_config.get("variants", [])),
        ]
        if inherited_variants:
            merged_config[INHERITED_VARIANTS_KEY] = inherited_variants
    return expand_variant_configs(merged_config, config_dir=path.parent, seen=(*seen, path))


def load_config(path: Path, overrides: Sequence[str]) -> dict[str, object]:
    config = deepcopy(load_raw_config(path))
    constant_overrides = [
        override
        for override in overrides
        if override.split("=", 1)[0].strip() == "constants"
        or override.split("=", 1)[0].strip().startswith("constants.")
    ]
    deferred_overrides = [override for override in overrides if override not in constant_overrides]
    for override in constant_overrides:
        apply_override(config, override)
    config = resolve_config_constants(config, include_variants=False)
    for override in deferred_overrides:
        apply_override(config, override)
    config = resolve_config_constants(config, include_variants=False)
    validate_config_shape(config)
    return config



def require_mapping(value: object, *, name: str) -> Mapping[str, object]:
    if not isinstance(value, Mapping):
        raise ConfigError(f"{name} must be an object")
    return value


def base_job_name(config: Mapping[str, object]) -> str:
    if config.get("job_name"):
        return str(config["job_name"])
    scene = config.get("scene", {})
    objects = scene.get("objects", []) if isinstance(scene, Mapping) else []
    if isinstance(objects, Sequence) and not isinstance(objects, (str, bytes)) and objects:
        first_object = objects[0]
        if isinstance(first_object, Mapping):
            object_id = first_object.get("id")
            if isinstance(object_id, str) and object_id.strip():
                return object_id
            object_model = first_object.get("model")
            if isinstance(object_model, Mapping) and object_model.get("scad_file"):
                return Path(str(object_model["scad_file"])).stem
    return "annotation_render"


def variant_items_from_config(config: Mapping[str, object]) -> list[Mapping[str, object]]:
    raw_variants = config.get("variants", [])
    if raw_variants is None:
        return []
    if not isinstance(raw_variants, Sequence) or isinstance(raw_variants, (str, bytes)):
        raise ConfigError("variants must be an array")
    variants: list[Mapping[str, object]] = []
    for index, variant in enumerate(raw_variants):
        if not isinstance(variant, Mapping):
            raise ConfigError(f"variants[{index}] must be an object")
        name = variant.get("name")
        if not isinstance(name, str) or not name.strip():
            raise ConfigError(f"variants[{index}].name is required")
        variants.append(variant)
    return variants


def variant_config(
    config: Mapping[str, object],
    variant: Mapping[str, object],
    *,
    stack: tuple[str, ...] = (),
) -> dict[str, object]:
    variant_name = str(variant["name"]).strip()
    if variant_name in stack:
        chain = " -> ".join((*stack, variant_name))
        raise ConfigError(f"Variant inheritance cycle detected: {chain}")
    base_variant_name = variant.get("extends_variant")
    if base_variant_name is not None:
        if not isinstance(base_variant_name, str) or not base_variant_name.strip():
            raise ConfigError(f"variants[{variant_name}].extends_variant must be a non-empty string")
        inherited_variants = config.get(INHERITED_VARIANTS_KEY, [])
        if inherited_variants is None:
            inherited_variants = []
        if not isinstance(inherited_variants, Sequence) or isinstance(inherited_variants, (str, bytes)):
            raise ConfigError(f"{INHERITED_VARIANTS_KEY} must be an array")
        matches = [
            item
            for item in [*variant_items_from_config(config), *inherited_variants]
            if isinstance(item, Mapping) and str(item["name"]).strip() == base_variant_name
        ]
        if not matches:
            raise ConfigError(f"variants[{variant_name}].extends_variant references unknown variant {base_variant_name!r}")
        resolved = variant_config(config, matches[0], stack=(*stack, variant_name))
    else:
        resolved = deepcopy(dict(config))
        resolved.pop("variants", None)
        resolved.pop(INHERITED_VARIANTS_KEY, None)
        resolved.pop("default_variant", None)
        resolved.pop("variant_collections", None)
        resolved_gallery = resolved.get("gallery")
        if isinstance(resolved_gallery, Mapping) and "variant_collection" in resolved_gallery:
            resolved["gallery"] = {
                str(key): deepcopy(value)
                for key, value in resolved_gallery.items()
                if key != "variant_collection"
            }
    if "job_name" not in variant:
        resolved["job_name"] = f"{base_job_name(config)}__{variant_name}"

    replace_sections = {"annotations"}
    for key in ("job_name", "output_dir", "constants", "scene", "render", "annotations"):
        if key not in variant:
            continue
        current = resolved.get(key)
        if key == "constants":
            override = variant[key]
            if isinstance(current, Mapping) and isinstance(override, Mapping):
                resolved[key] = deep_merge(current, override)
            else:
                resolved[key] = deepcopy(override)
            continue
        override = resolve_constant_references(
            variant[key],
            constants=require_mapping(resolved.get("constants", {}), name="constants"),
            path=f"variants[{variant_name}].{key}",
        )
        if key not in replace_sections and isinstance(current, Mapping) and isinstance(override, Mapping):
            resolved[key] = deep_merge(current, override)
        else:
            resolved[key] = deepcopy(override)

    set_values = variant.get("set", {})
    if set_values is not None:
        if not isinstance(set_values, Mapping):
            raise ConfigError(f"variants[{variant_name}].set must be an object")
        for path, value in set_values.items():
            set_dotted_value(resolved, str(path), deepcopy(value))

    resolved = resolve_config_constants(resolved, include_variants=False)
    object_overrides = variant.get("object_overrides")
    if object_overrides is not None:
        if not isinstance(object_overrides, Mapping):
            raise ConfigError(f"variants[{variant_name}].object_overrides must be an object")
        if object_overrides:
            resolved_overrides = resolve_constant_references(
                object_overrides,
                constants=require_mapping(resolved.get("constants", {}), name="constants"),
                path=f"variants[{variant_name}].object_overrides",
            )
            if not isinstance(resolved_overrides, Mapping):
                raise ConfigError(f"variants[{variant_name}].object_overrides must resolve to an object")
            scene = require_mapping(resolved.get("scene", {}), name="scene")
            resolved["scene"] = apply_object_overrides(
                scene,
                resolved_overrides,
                name=f"variants[{variant_name}].object_overrides",
            )
    annotation_overrides = variant.get("annotation_overrides")
    if annotation_overrides is not None:
        if not isinstance(annotation_overrides, Mapping):
            raise ConfigError(f"variants[{variant_name}].annotation_overrides must be an object")
        if annotation_overrides:
            resolved_overrides = resolve_constant_references(
                annotation_overrides,
                constants=require_mapping(resolved.get("constants", {}), name="constants"),
                path=f"variants[{variant_name}].annotation_overrides",
            )
            if not isinstance(resolved_overrides, Mapping):
                raise ConfigError(f"variants[{variant_name}].annotation_overrides must resolve to an object")
            annotations = require_mapping(resolved.get("annotations", {}), name="annotations")
            resolved["annotations"] = apply_annotation_overrides(
                annotations,
                resolved_overrides,
                name=f"variants[{variant_name}].annotation_overrides",
            )
    unset_paths = variant.get("unset", [])
    if unset_paths is not None:
        if not isinstance(unset_paths, Sequence) or isinstance(unset_paths, (str, bytes)):
            raise ConfigError(f"variants[{variant_name}].unset must be an array")
        for index, unset_path in enumerate(unset_paths):
            if not isinstance(unset_path, str) or not unset_path.strip():
                raise ConfigError(f"variants[{variant_name}].unset[{index}] must be a non-empty path")
            unset_dotted_value(resolved, unset_path.strip())
    validate_config_shape(resolved)
    return resolved


def selected_variants(config: Mapping[str, object], selected_name: str | None) -> list[Mapping[str, object]]:
    variants = variant_items_from_config(config)
    if selected_name is None:
        return variants
    matching = [variant for variant in variants if str(variant["name"]) == selected_name]
    if not matching:
        available = ", ".join(str(variant["name"]) for variant in variants) or "none"
        raise ConfigError(f"Unknown variant {selected_name!r}. Available variants: {available}")
    return matching


def selected_variant_collection(config: Mapping[str, object], collection_name: str) -> list[Mapping[str, object]]:
    raw_collections = config.get("variant_collections", {})
    if not isinstance(raw_collections, Mapping):
        raise ConfigError("variant_collections must be an object")
    raw_names = raw_collections.get(collection_name)
    if raw_names is None:
        available = ", ".join(str(name) for name in raw_collections) or "none"
        raise ConfigError(f"Unknown variant collection {collection_name!r}. Available collections: {available}")
    if not isinstance(raw_names, Sequence) or isinstance(raw_names, (str, bytes)):
        raise ConfigError(f"variant_collections.{collection_name} must be an array")

    variants_by_name = {str(variant["name"]): variant for variant in variant_items_from_config(config)}
    selected: list[Mapping[str, object]] = []
    for index, raw_name in enumerate(raw_names):
        if not isinstance(raw_name, str) or not raw_name.strip():
            raise ConfigError(f"variant_collections.{collection_name}[{index}] must be a non-empty variant name")
        if raw_name not in variants_by_name:
            available = ", ".join(variants_by_name) or "none"
            raise ConfigError(
                f"variant_collections.{collection_name} references unknown variant {raw_name!r}. "
                f"Available variants: {available}"
            )
        selected.append(variants_by_name[raw_name])
    return selected


def resolve_optional_config_path(path_value: str, *, config_dir: Path) -> Path:
    path = Path(path_value).expanduser()
    if path.is_absolute():
        return path.resolve()
    config_relative = (config_dir / path).resolve()
    if config_relative.exists():
        return config_relative
    return (PROJECT_ROOT / path).resolve()


def load_gallery_config(path_value: str | None, *, config_dir: Path) -> tuple[dict[str, object], Path | None]:
    if not path_value:
        return {}, None
    path = resolve_optional_config_path(path_value, config_dir=config_dir)
    return load_mapping_file(path, description="Gallery config"), path

