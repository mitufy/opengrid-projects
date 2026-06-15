"""Compatibility facade for config helpers.

The implementation is split across focused modules:
- config_schema: shared schema metadata and ConfigError
- config_defaults: constants and schema-derived key sets
- config_resolution: constants, presets, expressions, and path resolution
- config_validation: shape and semantic validation
- annotation_config: annotation dataclasses and collection helpers
"""

from annotation_renderer.annotation_config import *
from annotation_renderer.config_defaults import *
from annotation_renderer.config_resolution import *
from annotation_renderer.config_schema import *
from annotation_renderer.config_validation import *
