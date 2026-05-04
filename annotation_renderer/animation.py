"""Animation config normalization and output helpers."""

from __future__ import annotations

from pathlib import Path
from typing import Mapping, Sequence

from PIL import Image

from annotation_renderer.config import ConfigError, vector3


def resolve_animation_config(
    raw_animation: object,
    *,
    object_records: Sequence[Mapping[str, object]],
) -> dict[str, object] | None:
    if raw_animation is None:
        return None
    if not isinstance(raw_animation, Mapping):
        raise ConfigError("render.animation must be an object")
    enabled = raw_animation.get("enabled", True)
    if not isinstance(enabled, bool):
        raise ConfigError("render.animation.enabled must be a boolean")
    if not enabled:
        return None

    default_duration_frames = int(raw_animation.get("duration_frames", 48))
    if default_duration_frames < 1:
        raise ConfigError("render.animation.duration_frames must be at least 1")
    frame_start = int(raw_animation.get("frame_start", 0))
    frame_end_configured = "frame_end" in raw_animation
    declared_frame_end = int(raw_animation.get("frame_end", frame_start + default_duration_frames))
    fps = int(raw_animation.get("fps", 24))
    if frame_start < 0:
        raise ConfigError("render.animation.frame_start must be zero or greater")
    if declared_frame_end <= frame_start:
        raise ConfigError("render.animation.frame_end must be greater than frame_start")
    if fps < 1:
        raise ConfigError("render.animation.fps must be at least 1")
    end_pause_frames = int(raw_animation.get("end_pause_frames", 12))
    if end_pause_frames < 0:
        raise ConfigError("render.animation.end_pause_frames must be zero or greater")
    output_format = str(raw_animation.get("output_format", "gif")).strip().lower()
    if output_format not in {"gif", "png_sequence"}:
        raise ConfigError("render.animation.output_format must be 'gif' or 'png_sequence'")
    gif_width_px = int(raw_animation.get("gif_width_px", 0))
    if gif_width_px < 0:
        raise ConfigError("render.animation.gif_width_px must be zero or positive")

    records_by_id = {str(record["id"]): record for record in object_records}
    object_animations: list[dict[str, object]] = []
    timeline_last_keyframe = frame_start

    def ensure_frame_in_range(frame: int, *, name: str) -> None:
        if frame < frame_start:
            raise ConfigError(f"{name} must be greater than or equal to render.animation.frame_start")
        if frame_end_configured and frame > declared_frame_end:
            raise ConfigError(f"{name} must be less than or equal to render.animation.frame_end")

    def resolve_items(
        raw_items: object,
        *,
        path: str,
        frame_offset: int,
        start_default: int,
        end_default: int,
        interpolation_default: object,
        clip_name: str | None = None,
    ) -> None:
        nonlocal timeline_last_keyframe
        if not isinstance(raw_items, Sequence) or isinstance(raw_items, (str, bytes)) or not raw_items:
            raise ConfigError(f"{path} must be a non-empty array")
        for index, item in enumerate(raw_items):
            item_path = f"{path}[{index}]"
            if not isinstance(item, Mapping):
                raise ConfigError(f"{item_path} must be an object")
            object_id = str(item.get("object") or item.get("id") or "").strip()
            if not object_id:
                raise ConfigError(f"{item_path}.object is required")
            record = records_by_id.get(object_id)
            if record is None:
                raise ConfigError(f"{item_path} references unknown object {object_id!r}")
            property_name = str(item.get("property", "location"))
            if property_name != "location":
                raise ConfigError(f"{item_path}.property only supports 'location'")

            context = record.get("expression_context", {})
            if not isinstance(context, Mapping):
                context = {}
            raw_keyframes = item.get("location_offset_keyframes_mm", item.get("keyframes"))
            location_offset_keyframes: list[dict[str, object]] = []
            if raw_keyframes is not None:
                if not isinstance(raw_keyframes, Sequence) or isinstance(raw_keyframes, (str, bytes)) or not raw_keyframes:
                    raise ConfigError(f"{item_path}.location_offset_keyframes_mm must be a non-empty array")
                for keyframe_index, raw_keyframe in enumerate(raw_keyframes):
                    keyframe_path = f"{item_path}.location_offset_keyframes_mm[{keyframe_index}]"
                    if not isinstance(raw_keyframe, Mapping):
                        raise ConfigError(f"{keyframe_path} must be an object")
                    frame = int(raw_keyframe.get("frame", 0)) + frame_offset
                    ensure_frame_in_range(frame, name=f"{keyframe_path}.frame")
                    offset_mm = vector3(
                        raw_keyframe.get("value", raw_keyframe.get("value_mm", raw_keyframe.get("location_offset_mm"))),
                        name=f"{keyframe_path}.value",
                        context=context,
                    )
                    location_offset_keyframes.append(
                        {
                            "frame": frame,
                            "location_offset_mm": list(offset_mm),
                            "location_offset": [value / 1000.0 for value in offset_mm],
                        }
                    )
                location_offset_keyframes.sort(key=lambda keyframe: int(keyframe["frame"]))
                item_start_frame = int(location_offset_keyframes[0]["frame"])
                item_end_frame = int(location_offset_keyframes[-1]["frame"])
            else:
                item_start_frame = int(item.get("start_frame", start_default))
                item_end_frame = int(item.get("end_frame", end_default))
                ensure_frame_in_range(item_start_frame, name=f"{item_path}.start_frame")
                ensure_frame_in_range(item_end_frame, name=f"{item_path}.end_frame")

            if item_end_frame <= item_start_frame:
                raise ConfigError(f"{item_path} end frame must be greater than start frame")

            visibility_keyframes: list[dict[str, object]] = []
            raw_visibility_keyframes = item.get("visibility_keyframes")
            if raw_visibility_keyframes is not None:
                if (
                    not isinstance(raw_visibility_keyframes, Sequence)
                    or isinstance(raw_visibility_keyframes, (str, bytes))
                    or not raw_visibility_keyframes
                ):
                    raise ConfigError(f"{item_path}.visibility_keyframes must be a non-empty array")
                for keyframe_index, raw_visibility_keyframe in enumerate(raw_visibility_keyframes):
                    visibility_path = f"{item_path}.visibility_keyframes[{keyframe_index}]"
                    if not isinstance(raw_visibility_keyframe, Mapping):
                        raise ConfigError(f"{visibility_path} must be an object")
                    frame = int(raw_visibility_keyframe.get("frame", 0)) + frame_offset
                    ensure_frame_in_range(frame, name=f"{visibility_path}.frame")
                    visible = raw_visibility_keyframe.get("visible")
                    if not isinstance(visible, bool):
                        raise ConfigError(f"{visibility_path}.visible must be a boolean")
                    visibility_keyframes.append({"frame": frame, "visible": visible})

            if "visible_from_frame" in item:
                visible_from_frame = int(item["visible_from_frame"]) + frame_offset
                ensure_frame_in_range(visible_from_frame, name=f"{item_path}.visible_from_frame")
                if visible_from_frame > frame_start:
                    visibility_keyframes.append({"frame": frame_start, "visible": False})
                    hold_frame = visible_from_frame - 1
                    if hold_frame > frame_start:
                        visibility_keyframes.append({"frame": hold_frame, "visible": False})
                visibility_keyframes.append({"frame": visible_from_frame, "visible": True})

            if visibility_keyframes:
                merged_visibility: dict[int, bool] = {}
                for visibility_keyframe in visibility_keyframes:
                    merged_visibility[int(visibility_keyframe["frame"])] = bool(visibility_keyframe["visible"])
                visibility_keyframes = [
                    {"frame": frame, "visible": visible}
                    for frame, visible in sorted(merged_visibility.items())
                ]

            opacity_keyframes: list[dict[str, object]] = []
            raw_opacity_keyframes = item.get("opacity_keyframes")
            if raw_opacity_keyframes is not None:
                if (
                    not isinstance(raw_opacity_keyframes, Sequence)
                    or isinstance(raw_opacity_keyframes, (str, bytes))
                    or not raw_opacity_keyframes
                ):
                    raise ConfigError(f"{item_path}.opacity_keyframes must be a non-empty array")
                for keyframe_index, raw_opacity_keyframe in enumerate(raw_opacity_keyframes):
                    opacity_path = f"{item_path}.opacity_keyframes[{keyframe_index}]"
                    if not isinstance(raw_opacity_keyframe, Mapping):
                        raise ConfigError(f"{opacity_path} must be an object")
                    frame = int(raw_opacity_keyframe.get("frame", 0)) + frame_offset
                    ensure_frame_in_range(frame, name=f"{opacity_path}.frame")
                    raw_opacity = raw_opacity_keyframe.get(
                        "value",
                        raw_opacity_keyframe.get("opacity", raw_opacity_keyframe.get("alpha")),
                    )
                    if raw_opacity is None:
                        raise ConfigError(f"{opacity_path}.value is required")
                    opacity = float(raw_opacity)
                    if opacity < 0.0 or opacity > 1.0:
                        raise ConfigError(f"{opacity_path}.value must be between 0 and 1")
                    opacity_keyframes.append({"frame": frame, "opacity": opacity})

            if opacity_keyframes:
                merged_opacity: dict[int, float] = {}
                for opacity_keyframe in opacity_keyframes:
                    merged_opacity[int(opacity_keyframe["frame"])] = float(opacity_keyframe["opacity"])
                opacity_keyframes = [
                    {"frame": frame, "opacity": opacity}
                    for frame, opacity in sorted(merged_opacity.items())
                ]

            if not location_offset_keyframes:
                from_offset_mm = vector3(
                    item.get("from_location_offset_mm", item.get("from_offset_mm")),
                    default=(0.0, 0.0, 0.0),
                    name=f"{item_path}.from_location_offset_mm",
                    context=context,
                )
                to_offset_mm = vector3(
                    item.get("to_location_offset_mm", item.get("to_offset_mm")),
                    default=(0.0, 0.0, 0.0),
                    name=f"{item_path}.to_location_offset_mm",
                    context=context,
                )
                location_offset_keyframes = [
                    {
                        "frame": item_start_frame,
                        "location_offset_mm": list(from_offset_mm),
                        "location_offset": [value / 1000.0 for value in from_offset_mm],
                    },
                    {
                        "frame": item_end_frame,
                        "location_offset_mm": list(to_offset_mm),
                        "location_offset": [value / 1000.0 for value in to_offset_mm],
                    },
                ]

            visibility_end_frame = max((int(keyframe["frame"]) for keyframe in visibility_keyframes), default=item_end_frame)
            opacity_end_frame = max((int(keyframe["frame"]) for keyframe in opacity_keyframes), default=item_end_frame)
            timeline_last_keyframe = max(timeline_last_keyframe, item_end_frame, visibility_end_frame, opacity_end_frame)
            object_animations.append(
                {
                    "object": object_id,
                    "property": "location",
                    "clip": clip_name,
                    "start_frame": item_start_frame,
                    "end_frame": item_end_frame,
                    "location_offset_keyframes": location_offset_keyframes,
                    "visibility_keyframes": visibility_keyframes,
                    "opacity_keyframes": opacity_keyframes,
                    "opacity_interpolation": str(item.get("opacity_interpolation", item.get("interpolation", interpolation_default))),
                    "interpolation": str(item.get("interpolation", interpolation_default)),
                }
            )

    raw_items = raw_animation.get("object_animations", raw_animation.get("objects"))
    if raw_items is not None:
        resolve_items(
            raw_items,
            path="render.animation.object_animations",
            frame_offset=0,
            start_default=frame_start,
            end_default=declared_frame_end,
            interpolation_default=raw_animation.get("interpolation", "ease_out"),
        )

    raw_clips = raw_animation.get("clips", [])
    if raw_clips is not None:
        if not isinstance(raw_clips, Sequence) or isinstance(raw_clips, (str, bytes)):
            raise ConfigError("render.animation.clips must be an array")
        for clip_index, raw_clip in enumerate(raw_clips):
            clip_path = f"render.animation.clips[{clip_index}]"
            if not isinstance(raw_clip, Mapping):
                raise ConfigError(f"{clip_path} must be an object")
            clip_start_frame = int(raw_clip.get("start_frame", frame_start))
            ensure_frame_in_range(clip_start_frame, name=f"{clip_path}.start_frame")
            clip_duration_frames = int(raw_clip.get("duration_frames", default_duration_frames))
            if clip_duration_frames < 1:
                raise ConfigError(f"{clip_path}.duration_frames must be at least 1")
            clip_end_default = clip_start_frame + clip_duration_frames
            if frame_end_configured and clip_end_default > declared_frame_end:
                raise ConfigError(f"{clip_path} default end frame exceeds render.animation.frame_end")
            clip_items = raw_clip.get("object_animations", raw_clip.get("objects"))
            if clip_items is None:
                raise ConfigError(f"{clip_path}.object_animations is required")
            resolve_items(
                clip_items,
                path=f"{clip_path}.object_animations",
                frame_offset=clip_start_frame,
                start_default=clip_start_frame,
                end_default=clip_end_default,
                interpolation_default=raw_clip.get("interpolation", raw_animation.get("interpolation", "ease_out")),
                clip_name=str(raw_clip.get("name") or f"clip_{clip_index + 1}"),
            )

    if not object_animations:
        raise ConfigError("render.animation requires object_animations or clips")

    keyframe_frame_end = max(declared_frame_end if frame_end_configured else timeline_last_keyframe, timeline_last_keyframe)
    render_frame_end = keyframe_frame_end + end_pause_frames

    return {
        "enabled": True,
        "frame_start": frame_start,
        "frame_end": render_frame_end,
        "keyframe_frame_end": keyframe_frame_end,
        "end_pause_frames": end_pause_frames,
        "fps": fps,
        "output_format": output_format,
        "gif_width_px": gif_width_px,
        "object_animations": object_animations,
    }


def encode_animation_gif(
    *,
    frame_paths: Sequence[Path],
    output_path: Path,
    fps: int,
    width_px: int = 0,
) -> None:
    if not frame_paths:
        raise ConfigError("Cannot encode animation GIF without rendered frames")
    duration_ms = max(1, round(1000 / max(fps, 1)))
    frames: list[Image.Image] = []
    for frame_path in frame_paths:
        frame = Image.open(frame_path).convert("RGB")
        if width_px > 0 and frame.width > width_px:
            height_px = max(1, round(frame.height * (width_px / frame.width)))
            frame = frame.resize((width_px, height_px), resample=Image.Resampling.LANCZOS)
        frames.append(frame)
    first, rest = frames[0], frames[1:]
    first.save(output_path, save_all=True, append_images=rest, duration=duration_ms, loop=0, optimize=True)
