/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_version = "Standard"; //[Standard:Standard - 6.8mm, Lite Strong:Lite Strong - 4mm, Lite Basic:Lite Basic - 3.4mm]
add_threads_bluntend = true;
hook_shape_type = "Centered"; //["Straight", "Centered", "Loop"]
corner_type = "Circular"; //["Circular", "Rectangular"]

/* [Hook Options] */
//Width of hook body. The value for complete symmetry is 13.2.
body_width = 8; //0.4
//Thickness of hook body.
body_thickness = 6; //0.4
//Size of the main hook shape.
hook_main_size = 20; //0.4
hook_stem_length = 8; //0.4
//Scaling of body thickness. 0.6 means thickness at the end of the hook would be 60% of the beginning.
body_thickness_scale = 0.6; //[0.1:0.1:1]
//Angle affects Centered and Straight hooks.
hook_tip_angle = 165; //[15:15:255]

/* [Advanced Options] */
//Counterclockwisely offset which direction the gadget faces when it's completely screwed in. 270 means it would face 3 o’clock direction.
threads_offset_angle = 0; //[0:15:345]
//Size of fillet at the part hook stem connects to threads.
hook_stem_fillet = 4; //0.4
//Chamfer is automatically clamped to ensure a sufficiently large print surface.
body_max_chamfer = 0.8; //0.2
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]

/* [Experimental Options] */
//Enable this to draw a custom hook shape with custom_shape_commands. For those who want wacky hooks.
use_custom_shape = false;
//Only supports basic commands, not vectors. For more info, check out BOSL2 wiki for turtle().
custom_shape_commands = "setdir,90,arcright,5,45,move,15,arcleft,5,135,move,30";

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

add_threads_bluntend_text = true;
threads_bluntend_text = "🔓";
threads_bluntend_text_font = "Noto Emoji"; // font

threads_side_slice_off = 1.4; //0.1

threads_compatiblity_angle = 53.5;
threads_diameter = 16;
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1

snap_thickness =
  snap_version == "Standard" ? 6.8
  : snap_version == "Lite Strong" ? 4
  : 3.4;

//thread parameters
threads_bottom_bevel =
  snap_version == "Standard" ? threads_bottom_bevel_standard
  : threads_bottom_bevel_lite;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

threads_connect_diameter = threads_diameter - 1.8;
threads_offset = threads_diameter / 2 - threads_side_slice_off;
threads_bluntend_notch_total_height = threads_bottom_bevel + 0.8;
threads_bluntend_distance = max(0, snap_thickness - threads_bluntend_notch_total_height);

//text parameters
text_depth = 0.4;
final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

square_corner_radius = 1;
min_ang_radius = 0.4;
final_tip_size = max(eps, hook_main_size);
final_stem_length = max(eps, hook_stem_length);
final_thickness_scale = !use_custom_shape && hook_shape_type == "Loop" ? 1 : body_thickness_scale;
final_side_chamfer = max(0, min(body_thickness / 2 * final_thickness_scale - 0.84, body_width / 2 - 0.84, body_max_chamfer));

circular_straight_hook_path = ["setdir", 90, "arcleft", final_tip_size / 2, hook_tip_angle];
circular_center_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "arcleft", final_tip_size / 2, hook_tip_angle + 90];
circular_loop_hook_path = ["setdir", 0, "arcright", final_tip_size / 2, 359.9];

//a rough calculation of the offset angle. the goal is to make bottom of the rectagular hook flat when thickness scale is less than 1.
rect_offset_angle = opp_adj_to_ang((body_thickness - body_thickness * final_thickness_scale) / 2, final_tip_size);
rect_corner_arc_length = PI / 2 * square_corner_radius;
rect_tip_corner_length = max(eps, (hook_main_size - square_corner_radius * 2) * (hook_tip_angle - 135) / 90);
rect_straight_middle_ratio = (hook_main_size - square_corner_radius) / (hook_tip_angle > 135 ? (rect_corner_arc_length + rect_tip_corner_length + hook_main_size * 1.5 + rect_corner_arc_length - square_corner_radius) : (hook_main_size * 1.5 + rect_corner_arc_length - square_corner_radius));
rect_center_middle_ratio = (hook_main_size - square_corner_radius) / (hook_tip_angle > 135 ? (rect_corner_arc_length + rect_tip_corner_length + hook_main_size * 2.5 - square_corner_radius * 4 + rect_corner_arc_length * 2) : (hook_main_size * 2.5 - square_corner_radius * 4 + rect_corner_arc_length * 2));

rect_straight_hook_path = ["setdir", 90, "move", hook_main_size / 2, "arcleft", min_ang_radius, 90 + rect_offset_angle * rect_straight_middle_ratio, "move", hook_main_size - square_corner_radius];
rect_center_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "move", hook_main_size / 2 - square_corner_radius, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90 + rect_offset_angle * rect_center_middle_ratio, "move", hook_main_size - square_corner_radius];
rect_hook_tip_path = ["arcleft", square_corner_radius, 90, "move", rect_tip_corner_length];

rect_loop_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "move", hook_main_size / 2 - square_corner_radius, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size / 2];

function to_turtle(x) = is_num(parse_num(x)) ? parse_num(x) : x;
temp_path = str_split(str_strip(str_replace_char(str_replace_char(custom_shape_commands, " ", ""), "\"", ""), ","), ",");
custom_hook_path = [for (i = [0:len(temp_path) - 1]) to_turtle(temp_path[i])];

circular_hook_path =
  hook_shape_type == "Loop" ? circular_loop_hook_path
  : hook_shape_type == "Centered" ? circular_center_hook_path
  : circular_straight_hook_path;

rect_hook_path =
  hook_shape_type == "Centered" && hook_tip_angle > 135 ? concat(rect_center_hook_path, rect_hook_tip_path)
  : hook_shape_type == "Centered" ? rect_center_hook_path
  : hook_shape_type == "Straight" && hook_tip_angle > 135 ? concat(rect_straight_hook_path, rect_hook_tip_path)
  : hook_shape_type == "Straight" ? rect_straight_hook_path
  : rect_loop_hook_path;

hook_path =
  use_custom_shape ? custom_hook_path
  : corner_type == "Circular" ? circular_hook_path
  : rect_hook_path;

tip_rounding_radius = max(0, min(body_thickness * final_thickness_scale, body_width - final_side_chamfer * 2) / 2 - eps);

//unimplemented ring profile
ring_profile = false;
ring_main_width = body_width;
ring_main_thickness = ring_main_width / 2;
ring_sweep_profile = back(2, right(body_width / 2, zrot(90, ring(width=ring_main_width, thickness=ring_main_thickness, ring_width=body_thickness / 2, n=32, full=false))));
ring_hook_path = ["setdir", 90, "arcright", ring_main_thickness, 90, "arcleft", final_tip_size / 2, hook_tip_angle + 90];
profile_zrot = ring_profile ? 180 : 0;
profile_back_offset = ring_profile ? 4 : 0;

default_sweep_profile = rect([body_thickness, body_width], chamfer=final_side_chamfer);

final_sweep_profile = ring_profile ? ring_sweep_profile : default_sweep_profile;
offset_sweep_profile = scale([final_thickness_scale, 1, 1], final_sweep_profile);
prism_fillet = max(0, min(final_stem_length, hook_stem_fillet));

up(threads_offset) xrot(90)
    diff() {
      zrot(90 + threads_offset_angle) {
        zrot(threads_compatiblity_angle) {
          if (add_threads_bluntend)
            blunt_threaded_rod(diameter=threads_diameter, rod_height=snap_thickness, top_cutoff=true);
          else
            generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=threads_pitch, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
        }
        if (add_threads_bluntend_text && add_threads_bluntend)
          up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0)
              tag("remove") linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_bluntend_text, size=4, anchor=str("center", CENTER), font=threads_bluntend_text_font);
        if (final_add_thickness_text)
          up(snap_thickness - text_depth + eps / 2) left(add_threads_bluntend_text && add_threads_bluntend ? 2.4 : 0)
              tag("remove") linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
      }
      fwd(threads_offset - body_width / 2) {
        down(final_stem_length - eps) xrot(-90)
            //path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1], caps=[true, os_circle(r=tip_rounding_radius)]);
            //makerworld doesn't support newest path_sweep caps yet so it has to be done the old way.
            path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1])
              attach("end", "top")
                back(profile_back_offset) offset_sweep(offset_sweep_profile, height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius), spin=profile_zrot);
        difference() {
          zrot(profile_zrot) xrot(180) join_prism(final_sweep_profile, base="plane", length=final_stem_length, base_fillet=prism_fillet, overlap=0);
          up(eps) difference() {
              cuboid([100, 100, prism_fillet], anchor=TOP);
              union() {
                cuboid([body_thickness, body_width, final_stem_length + eps * 2], chamfer=final_side_chamfer, edges="Z", anchor=TOP);
                back(threads_offset - body_width / 2 + 0.1)
                  cyl(l=final_stem_length + eps * 2, d=threads_connect_diameter, anchor=TOP);
              }
            }
        }
      }
      tag("remove") fwd(threads_offset - eps) cuboid([500, 500, 500], anchor=BACK);
    }


module blunt_threaded_rod(diameter = threads_diameter, rod_height = snap_thickness, top_bevel = 0, bottom_bevel = 0, top_cutoff = false, blunt_ang = 10, anchor = CENTER, spin = 0, orient = UP) {
  min_turns = 0.5;
  offset_height = min(rod_height - 1.5 - bottom_bevel, 0);
  turns = max(0, (rod_height - 1.5 - bottom_bevel) / 3) + min_turns;
  attachable(anchor, spin, orient, d=diameter, h=rod_height) {
    tag_scope() difference() {
        union() {
          cyl(d=diameter - 2 + eps, h=rod_height, anchor=BOTTOM, $fn=256);
          difference() {
            zrot(0.25 * 120) up(0.25)
                zrot(-(min_turns * 3) * 120) up(-(min_turns * 3))
                    zrot(offset_height * 120) up(offset_height)
                        thread_helix(d=diameter, turns=turns, pitch=threads_pitch, profile=threads_profile, anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256);
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