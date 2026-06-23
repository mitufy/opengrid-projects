from pathlib import Path

from annotation_renderer.openscad import build_openscad_command


def test_build_openscad_command_enables_required_features(monkeypatch, tmp_path):
    monkeypatch.setattr("annotation_renderer.openscad.require_openscad_executable", lambda executable: executable)

    command = build_openscad_command(
        executable="openscad",
        scad_file=Path("model.scad"),
        output_path=tmp_path / "model.stl",
        defines=('generate_screw="None"',),
    )

    assert command[:5] == ["openscad", "--enable", "textmetrics", "--enable", "lazy-union"]
    assert "--backend=Manifold" in command