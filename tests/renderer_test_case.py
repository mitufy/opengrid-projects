"""Shared helpers for annotation renderer tests."""

from __future__ import annotations

import io
import json
import unittest
from contextlib import redirect_stdout

from annotation_renderer.cli import main


class RendererTestCase(unittest.TestCase):
    def run_cli(self, *args: str) -> str:
        stream = io.StringIO()
        with redirect_stdout(stream):
            self.assertEqual(main(args), 0)
        return stream.getvalue()

    def gallery_variant_lines(self, model: str, *, collection: str | None = None) -> list[str]:
        args = ["gallery", model, "--resolved"]
        if collection is not None:
            args.extend(["--collection", collection])
        return [item["name"] for item in json.loads(self.run_cli(*args))["variants"]]

    def assert_parameter_gallery(self, config: dict[str, object], model: str, expected_count: int) -> None:
        self.assertEqual(
            config["gallery"],
            {
                "variant_collection": "parameter_gallery",
                "columns": 2,
                "target_width_px": 1920,
                "target_height_px": 1440,
                "margin_px": 0,
                "gutter_px": 4,
                "title_height_px": 60,
                "title_font_size_px": 60,
            },
        )
        default_variants = self.gallery_variant_lines(model)
        explicit_variants = self.gallery_variant_lines(model, collection="parameter_gallery")
        self.assertEqual(default_variants, explicit_variants)
        self.assertEqual(len(default_variants), expected_count)

    def first_model_config(self, config: dict[str, object]) -> dict[str, object]:
        return config["scene"]["objects"][0]["model"]
