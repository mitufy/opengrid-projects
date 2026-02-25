/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <opengrid_variable.scad>
use <util_lib.scad>

/* [Hidden] */
module blunt_threads(diameter = OG_SNAP_THREADS_DIAMETER, threads_height = OG_STANDARD_THICKNESS, top_bevel = 0, bottom_bevel = 0, top_cutoff = false, blunt_ang = 10, anchor = BOTTOM, spin = 0, orient = UP) {
  // lead-in offset from bottom: threads start 1.5mm above the base before bevel
  thread_lead_in_offset = 1.5;
  min_turns = 0.5;
  offset_height = min(threads_height - thread_lead_in_offset - bottom_bevel, 0);
  turns = max(0, (threads_height - thread_lead_in_offset - bottom_bevel) / OG_SNAP_THREADS_PITCH) + min_turns;
  attachable(anchor, spin, orient, d=diameter, h=threads_height) {
    tag_scope() down(threads_height / 2) difference() {
          union() {
            cyl(d=diameter - 2 + EPS, h=threads_height, anchor=BOTTOM, $fn=256);
            difference() {
              zrot(0.25 * 120) up(0.25)
                  zrot(-(min_turns * OG_SNAP_THREADS_PITCH) * 120) up(-(min_turns * OG_SNAP_THREADS_PITCH))
                      zrot(offset_height * 120) up(offset_height)
                          thread_helix(d=diameter, turns=turns, pitch=OG_SNAP_THREADS_PITCH, profile=OG_SNAP_THREADS_PROFILE, anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256);
              up(threads_height + (diameter + 2) / 2) cube(diameter + 2, center=true);
            }
          }
          if (top_cutoff || top_bevel > 0)
            down((diameter + 2) / 2) cube(diameter + 2, center=true);
          if (top_bevel > 0)
            rotate_extrude() left(diameter / 2 - top_bevel / 2 + EPS) right_triangle([top_bevel + EPS, top_bevel + EPS], anchor=BOTTOM);
          if (bottom_bevel > 0)
            up(threads_height) rotate_extrude() right(diameter / 2 - bottom_bevel + EPS) right_triangle([bottom_bevel + EPS, bottom_bevel + EPS], anchor=BOTTOM, spin=180);
        }
    children();
  }
}
module threads_text(snap_thickness = OG_STANDARD_THICKNESS, threads_type = "Blunt", threadstext_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _text_depth = struct_val(threadstext_cfg, "text_depth", 0.4);
  _thickness_text_mode = struct_val(threadstext_cfg, "thickness_text_mode", "Uncommon");
  _add_blunt_text = struct_val(threadstext_cfg, "add_blunt_text", true);
  _text_pos_offset = struct_val(threadstext_cfg, "text_pos_offset", [0, 0]);
  _add_thickness_text = _thickness_text_mode == "All" || (_thickness_text_mode == "Uncommon" && snap_thickness != OG_LITE_BASIC_THICKNESS && snap_thickness != OG_STANDARD_THICKNESS);
  attachable(anchor, spin, orient, d=OG_SNAP_THREADS_DIAMETER, h=_text_depth) {
    tag_scope() down(_text_depth / 2) {
        if (_add_blunt_text && threads_type == "Blunt")
          right(_add_thickness_text ? 2.4 : 0) right(_text_pos_offset[0]) back(_text_pos_offset[1])
                force_tag("remove") linear_extrude(height=_text_depth + EPS) fill()
                      text(OG_SNAP_THREADS_BLUNT_TEXT, size=4, anchor=str("center", CENTER), font=OG_SNAP_THREADS_BLUNT_TEXT_FONT);
        if (_add_thickness_text)
          left(_add_blunt_text && threads_type == "Blunt" ? 2.4 : 0) right(_text_pos_offset[0]) back(_text_pos_offset[1])
                force_tag("remove") linear_extrude(height=_text_depth + EPS)
                    text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font=OG_SNAP_TEXT_FONT);
      }
    children();
  }
}
module snap_threads(threads_type = "Blunt", snap_thickness = OG_STANDARD_THICKNESS, threads_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _threads_offset_angle = struct_val(threads_cfg, "threads_offset_angle", OG_SNAP_THREADS_COMPATIBILITY_ANGLE);
  _threads_blunt_cutoff = struct_val(threads_cfg, "threads_blunt_cutoff", true);
  _snap_threads_top_bevel = struct_val(threads_cfg, "snap_threads_top_bevel", 0.5);
  _snap_threads_bottom_bevel_standard = struct_val(threads_cfg, "snap_threads_bottom_bevel_standard", 2);
  _snap_threads_bottom_bevel_lite = struct_val(threads_cfg, "snap_threads_bottom_bevel_lite", 1.2);
  _snap_threads_bottom_bevel =
    snap_thickness >= OG_STANDARD_THICKNESS ? _snap_threads_bottom_bevel_standard
    : snap_thickness >= OG_LITE_THICKNESS ? _snap_threads_bottom_bevel_lite
    : 0;

  attachable(anchor, spin, orient, d=OG_SNAP_THREADS_DIAMETER, h=snap_thickness) {
    tag_scope() diff()
        down(snap_thickness / 2) zrot(_threads_offset_angle) {
            if (threads_type == "Blunt")
              blunt_threads(diameter=OG_SNAP_THREADS_DIAMETER, threads_height=snap_thickness, top_cutoff=_threads_blunt_cutoff);
            else
              generic_threaded_rod(d=OG_SNAP_THREADS_DIAMETER, l=snap_thickness, pitch=OG_SNAP_THREADS_PITCH, profile=OG_SNAP_THREADS_PROFILE, bevel1=_snap_threads_top_bevel, bevel2=_snap_threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
          }

    children();
  }
}
module expanding_threads(threads_type = "Blunt", threads_height = OG_STANDARD_THICKNESS, diameter = OG_SNAP_THREADS_DIAMETER, expand_distance = 1, entry_height = 0.4, end_height = 1, fold_angle = 45, anchor = BOTTOM, spin = 0, orient = UP) {
  expand_distance_step = 0.05;
  transition_height = threads_height - entry_height - end_height;
  expand_segment_count = ceil(expand_distance / expand_distance_step);
  expand_height_step = transition_height / expand_segment_count;

  // cfg structs used to pass text/cutoff overrides into snap_threads calls
  _no_text_cfg = struct_set([], ["text_depth", 0]);
  _no_cutoff_cfg = struct_set([], ["threads_blunt_cutoff", false]);

  render() {
    attachable(anchor, spin, orient, d=diameter, h=threads_height) {
      tag_scope() down(threads_height / 2) {
          if (entry_height > 0)
            snap_threads(threads_type=threads_type, snap_thickness=entry_height + EPS, threads_cfg=_no_cutoff_cfg);
          for (a = [0:expand_segment_count - 1]) {
            aseg_position = entry_height + expand_height_step * a;
            aseg_expansion_distance = expand_distance_step * (a + 1);
            zrot(-fold_angle)
              partition(spread=-aseg_expansion_distance - EPS, cutpath="flat", $slop=aseg_expansion_distance / 2)
                zrot(fold_angle) up(aseg_position) zrot(aseg_position * 120)
                      snap_threads(threads_type=threads_type, snap_thickness=expand_height_step + EPS, threads_cfg=_no_cutoff_cfg);
          }
          if (end_height > 0) {
            zrot(-fold_angle)
              partition(spread=-expand_segment_count * expand_distance_step - EPS, cutpath="flat", $slop=expand_segment_count * expand_distance_step / 2)
                zrot(fold_angle) up(entry_height + transition_height) zrot((entry_height + transition_height) * 120)
                      snap_threads(threads_type=threads_type, snap_thickness=max(end_height, 0) + EPS, threads_cfg=_no_cutoff_cfg);
          }
        }
      children();
    }
  }
}
