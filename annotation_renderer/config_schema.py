"""Shared config schema metadata and errors."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Mapping


class ConfigError(ValueError):
    """Raised when an annotation render config is invalid."""


CONFIG_SCHEMA_PATH = Path(__file__).resolve().parent / "schemas" / "annotation-render-config.schema.json"
CONFIG_SCHEMA = json.loads(CONFIG_SCHEMA_PATH.read_text(encoding="utf-8"))


def schema_definition(definition_name: str) -> Mapping[str, object]:
    return CONFIG_SCHEMA["$defs"][definition_name]


def schema_definition_properties(definition_name: str) -> set[str]:
    definition = schema_definition(definition_name)
    if "properties" in definition:
        return set(definition["properties"])
    for option in definition.get("anyOf", []):
        if isinstance(option, Mapping) and "properties" in option:
            return set(option["properties"])
    raise ConfigError(f"Schema definition {definition_name!r} does not expose object properties")


def schema_allowed_keys(definition_name: str, *, constant_ref_key: str = "$constant") -> set[str]:
    return schema_definition_properties(definition_name) - {constant_ref_key}


def schema_object_property(definition_name: str, property_name: str) -> Mapping[str, object]:
    definition = schema_definition(definition_name)
    candidates: list[Mapping[str, object]] = []
    if isinstance(definition.get("properties"), Mapping):
        candidates.append(definition)
    for option in definition.get("anyOf", []):
        if isinstance(option, Mapping) and isinstance(option.get("properties"), Mapping):
            candidates.append(option)
    for candidate in candidates:
        properties = candidate.get("properties", {})
        if isinstance(properties, Mapping) and property_name in properties:
            property_schema = properties[property_name]
            if isinstance(property_schema, Mapping):
                return property_schema
    raise ConfigError(f"Schema definition {definition_name!r} has no property {property_name!r}")


def schema_property_enum(definition_name: str, property_name: str) -> set[str]:
    property_schema = schema_object_property(definition_name, property_name)
    values = property_schema.get("enum")
    if not isinstance(values, list) or not all(isinstance(item, str) for item in values):
        raise ConfigError(f"Schema property {definition_name}.{property_name} does not expose a string enum")
    return set(values)


def schema_definition_enum(definition_name: str) -> set[str]:
    definition = schema_definition(definition_name)
    values = definition.get("enum")
    if not isinstance(values, list) or not all(isinstance(item, str) for item in values):
        raise ConfigError(f"Schema definition {definition_name!r} does not expose a string enum")
    return set(values)
