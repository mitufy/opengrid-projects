/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <util_lib.scad>

/* [Hidden] */
//openGrid snap threads are designed to have 16mm diameter and 0.5mm clearance, 16.5mm is the offical diameter for negative parts.
snap_threads_diameter = 16;
snap_threads_clearance = 0.5;
snap_threads_compatibility_angle = 53.5;
snap_threads_rotate_angle = 45;
snap_threads_top_bevel = 0.5; //0.1
snap_threads_bottom_bevel_standard = 2; //0.1
snap_threads_bottom_bevel_lite = 1.2; //0.1
snap_threads_negative_diameter = snap_threads_diameter + snap_threads_clearance;

snap_threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

snap_threads_blunt_text = "🔓";
snap_threads_blunt_text_font = "Noto Emoji"; // font
snap_threads_pitch = 3;

module blunt_threaded_rod(diameter = snap_threads_diameter, rod_height = 6.8, top_bevel = 0, bottom_bevel = 0, top_cutoff = false, blunt_ang = 10, anchor = BOTTOM, spin = 0, orient = UP) {
  min_turns = 0.5;
  offset_height = min(rod_height - 1.5 - bottom_bevel, 0);
  turns = max(0, (rod_height - 1.5 - bottom_bevel) / 3) + min_turns;
  attachable(anchor, spin, orient, d=diameter, h=rod_height) {
    tag_scope() down(rod_height / 2) difference() {
          union() {
            cyl(d=diameter - 2 + eps, h=rod_height, anchor=BOTTOM, $fn=256);
            difference() {
              zrot(0.25 * 120) up(0.25)
                  zrot(-(min_turns * 3) * 120) up(-(min_turns * 3))
                      zrot(offset_height * 120) up(offset_height)
                          thread_helix(d=diameter, turns=turns, pitch=snap_threads_pitch, profile=snap_threads_profile, anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256);
              up(rod_height + (diameter + 2) / 2) cube(diameter + 2, center=true);
            }
          }
          if (top_cutoff || top_bevel > 0)
            down((diameter + 2) / 2) cube(diameter + 2, center=true);
          if (top_bevel > 0)
            rotate_extrude() left(diameter / 2 - top_bevel / 2 + eps) right_triangle([top_bevel + eps, top_bevel + eps], anchor=BOTTOM);
          if (bottom_bevel > 0)
            up(rod_height) rotate_extrude() right(diameter / 2 - bottom_bevel + eps) right_triangle([bottom_bevel + eps, bottom_bevel + eps], anchor=BOTTOM, spin=180);
        }
    children();
  }
}
module snap_threads(threads_type = "Blunt", snap_thickness = 6.8, text_depth = 0.4, text_pos_offset = [0], thickness_text_mode = "Uncommon", threads_offset_angle = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  snap_threads_bottom_bevel = snap_thickness >= 6.8 ? snap_threads_bottom_bevel_standard : snap_thickness >= 4 ? snap_threads_bottom_bevel_lite : 0;
  add_thickness_text = thickness_text_mode == "All" || (thickness_text_mode == "Uncommon" && snap_thickness == 4);
  attachable(anchor, spin, orient, d=snap_threads_diameter, h=snap_thickness) {
    tag_scope() zrot(threads_offset_angle) down(snap_thickness / 2) diff() {
            zrot(snap_threads_compatibility_angle) {
              if (threads_type == "Blunt")
                blunt_threaded_rod(diameter=snap_threads_diameter, rod_height=snap_thickness, top_cutoff=true);
              else
                generic_threaded_rod(d=snap_threads_diameter, l=snap_thickness, pitch=snap_threads_pitch, profile=snap_threads_profile, bevel1=0.5, bevel2=snap_threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
            }
            right(text_pos_offset[0])back(text_pos_offset[1]) {
              if (threads_type == "Blunt")
                up(snap_thickness - text_depth + eps / 2) right(add_thickness_text ? 2.4 : 0)
                    force_tag("remove") linear_extrude(height=text_depth + eps) fill() text(snap_threads_blunt_text, size=4, anchor=str("center", CENTER), font=snap_threads_blunt_text_font);
              if (add_thickness_text)
                up(snap_thickness - text_depth + eps / 2) left(threads_type == "Blunt" ? 2.4 : 0)
                    force_tag("remove") linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
            }
          }
    children();
  }
}
