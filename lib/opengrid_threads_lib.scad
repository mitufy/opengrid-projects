/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/threading.scad>
include <opengrid_base.scad>

function threads_cfg(
  threads_type = "Blunt",
  threads_diameter = OG_SNAP_THREADS_DIAMETER,
  threads_clearance = OG_SNAP_THREADS_CLEARANCE,
  threads_pitch = OG_SNAP_THREADS_PITCH,
  threads_top_bevel = 0.5,
  threads_bottom_bevel_standard = 2,
  threads_bottom_bevel_lite = 1.2,
  threads_offset_angle = 0,
  threads_blunt_cutoff = true
) =
  struct_set(
    [], [
      "threads_type",
      threads_type,
      "threads_diameter",
      threads_diameter,
      "threads_clearance",
      threads_clearance,
      "threads_pitch",
      threads_pitch,
      "threads_top_bevel",
      threads_top_bevel,
      "threads_bottom_bevel_standard",
      threads_bottom_bevel_standard,
      "threads_bottom_bevel_lite",
      threads_bottom_bevel_lite,
      "threads_offset_angle",
      threads_offset_angle,
      "threads_blunt_cutoff",
      threads_blunt_cutoff,
    ]
  );

function snap_expand_cfg(
  expand_distance_standard = 0.6,
  expand_distance_lite = 0.4,
  expand_entry_height_standard = 0.4,
  expand_entry_height_lite = 0.4,
  expand_entry_height_blunt = 1,
  expand_end_height_standard = 2,
  expand_end_height_lite = 1.2,
  expand_split_angle = 45
) =
  struct_set(
    [], [
      "expand_distance_standard",
      expand_distance_standard,
      "expand_distance_lite",
      expand_distance_lite,
      "expand_entry_height_standard",
      expand_entry_height_standard,
      "expand_entry_height_lite",
      expand_entry_height_lite,
      "expand_entry_height_blunt",
      expand_entry_height_blunt,
      "expand_end_height_standard",
      expand_end_height_standard,
      "expand_end_height_lite",
      expand_end_height_lite,
      "expand_split_angle",
      expand_split_angle,
    ]
  );

module blunt_threads(threads_height = OG_STANDARD_THICKNESS, top_bevel = 0, bottom_bevel = 0, blunt_ang = 10, threads_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);
  _diameter = struct_val(_threads_cfg, "threads_diameter") + struct_val(_threads_cfg, "threads_clearance");
  _pitch = struct_val(_threads_cfg, "threads_pitch");
  _top_cutoff = struct_val(_threads_cfg, "threads_blunt_cutoff");

  thread_lead_in_offset = 1.5;
  min_turns = 0.5;
  offset_height = min(threads_height - thread_lead_in_offset - bottom_bevel, 0);
  turns = max(0, (threads_height - thread_lead_in_offset - bottom_bevel) / _pitch) + min_turns;

  attachable(anchor, spin, orient, d=_diameter, h=threads_height) {
    tag_scope() down(threads_height / 2) diff() {
          cyl(d=_diameter - 2 + EPS, h=threads_height, anchor=BOTTOM, $fn=256);
          diff("helix_cutoff") {
            zrot(0.25 * 120) up(0.25)
                zrot(-(min_turns * _pitch) * 120) up(-(min_turns * _pitch))
                    zrot(offset_height * 120) up(offset_height)
                        thread_helix(
                          d=_diameter, turns=turns, pitch=_pitch, profile=OG_SNAP_THREADS_PROFILE,
                          anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256
                        );
            tag("helix_cutoff") up(threads_height + (_diameter + 2) / 2) cube(_diameter + 2, center=true);
          }
          if (_top_cutoff || top_bevel > 0)
            tag("remove") down((_diameter + 2) / 2) cube(_diameter + 2, center=true);
          if (top_bevel > 0)
            force_tag("remove") rotate_extrude() left(_diameter / 2 - top_bevel / 2 + EPS) right_triangle([top_bevel + EPS, top_bevel + EPS], anchor=BOTTOM);
          if (bottom_bevel > 0)
            force_tag("remove") up(threads_height) rotate_extrude() right(_diameter / 2 - bottom_bevel + EPS) right_triangle([bottom_bevel + EPS, bottom_bevel + EPS], anchor=BOTTOM, spin=180);
        }
    children();
  }
}

module snap_threads(threads_height = OG_STANDARD_THICKNESS, threads_cfg = [], text_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);
  _text_cfg = struct_merge(text_cfg(), text_cfg);
  _threads_type = struct_val(_threads_cfg, "threads_type");
  _threads_offset_angle = struct_val(_threads_cfg, "threads_offset_angle");
  _threads_blunt_cutoff = struct_val(_threads_cfg, "threads_blunt_cutoff");
  _snap_threads_top_bevel = struct_val(_threads_cfg, "threads_top_bevel");
  _snap_threads_bottom_bevel_standard = struct_val(_threads_cfg, "threads_bottom_bevel_standard");
  _snap_threads_bottom_bevel_lite = struct_val(_threads_cfg, "threads_bottom_bevel_lite");
  _threads_diameter = struct_val(_threads_cfg, "threads_diameter");
  _threads_clearance = struct_val(_threads_cfg, "threads_clearance");
  _threads_pitch = struct_val(_threads_cfg, "threads_pitch");
  _snap_threads_bottom_bevel =
    threads_height >= OG_STANDARD_THICKNESS ? _snap_threads_bottom_bevel_standard
    : threads_height >= OG_LITE_BASIC_THICKNESS ? _snap_threads_bottom_bevel_lite
    : 0;

  attachable(anchor, spin, orient, d=_threads_diameter + _threads_clearance, h=threads_height) {
    tag_scope() diff() {
        down(threads_height / 2) zrot(_threads_offset_angle + OG_SNAP_THREADS_COMPATIBILITY_ANGLE) {
            if (_threads_type == "Blunt")
              blunt_threads(threads_height=threads_height, threads_cfg=_threads_cfg);
            else
              generic_threaded_rod(d=_threads_diameter + _threads_clearance, l=threads_height, pitch=_threads_pitch, profile=OG_SNAP_THREADS_PROFILE, bevel1=_snap_threads_top_bevel, bevel2=_snap_threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
          }
        if (struct_val(_text_cfg, "text_depth") > 0)
          up(threads_height / 2 - EPS)
            tag("remove") snap_text(text_cfg=_text_cfg, anchor=TOP);
      }

    children();
  }
}
module expanding_threads(threads_height = OG_STANDARD_THICKNESS, threads_cfg = [], text_cfg = [], expand_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _expand_cfg = struct_merge(snap_expand_cfg(), expand_cfg);
  _is_standard = threads_height >= OG_STANDARD_THICKNESS;

  _threads_cfg = struct_merge(threads_cfg(), threads_cfg);
  _threads_type = struct_val(_threads_cfg, "threads_type");

  _expand_distance = _is_standard ? struct_val(_expand_cfg, "expand_distance_standard") : struct_val(_expand_cfg, "expand_distance_lite");
  _entry_height = _threads_type == "Blunt" ? struct_val(_expand_cfg, "expand_entry_height_blunt") : (_is_standard ? struct_val(_expand_cfg, "expand_entry_height_standard") : struct_val(_expand_cfg, "expand_entry_height_lite"));
  _end_height = _is_standard ? struct_val(_expand_cfg, "expand_end_height_standard") : struct_val(_expand_cfg, "expand_end_height_lite");
  _expand_split_angle = struct_val(_expand_cfg, "expand_split_angle");

  expand_distance_step = 0.05;
  transition_height = threads_height - _entry_height - _end_height;
  expand_segment_count = ceil(_expand_distance / expand_distance_step);
  expand_height_step = transition_height / expand_segment_count;

  _no_text_cfg = ["text_depth", 0];
  _no_cutoff_cfg = ["threads_blunt_cutoff", false];
  _no_top_bevel_cfg = ["threads_top_bevel", 0];
  _no_bottom_bevel_cfg = ["threads_bottom_bevel_standard", 0, "threads_bottom_bevel_lite", 0];

  _diameter = struct_val(_threads_cfg, "threads_diameter");

  render() {
    attachable(anchor, spin, orient, d=_diameter, h=threads_height) {
      tag_scope() down(threads_height / 2) {
          if (_entry_height > 0)
            snap_threads(threads_height=_entry_height + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg, _no_bottom_bevel_cfg)));
          for (a = [0:expand_segment_count - 1]) {
            aseg_position = _entry_height + expand_height_step * a;
            aseg_expansion_distance = expand_distance_step * (a + 1);
            zrot(-_expand_split_angle)
              partition(spread=-aseg_expansion_distance - EPS, cutpath="flat", $slop=aseg_expansion_distance / 2)
                zrot(_expand_split_angle) up(aseg_position) zrot(aseg_position * 120)
                      snap_threads(threads_height=expand_height_step + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg, _no_bottom_bevel_cfg)));
          }
          if (_end_height > 0) {
            zrot(-_expand_split_angle)
              partition(spread=-expand_segment_count * expand_distance_step - EPS, cutpath="flat", $slop=expand_segment_count * expand_distance_step / 2)
                zrot(_expand_split_angle) up(_entry_height + transition_height) zrot((_entry_height + transition_height) * 120)
                      snap_threads(threads_height=max(_end_height, 0) + EPS, text_cfg=_no_text_cfg, threads_cfg=struct_merge(_threads_cfg, concat(_no_cutoff_cfg, _no_top_bevel_cfg)));
          }
        }
      children();
    }
  }
}
