/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Recommended to use with openGrid - Self-Expanding Snap. https://www.printables.com/model/1294247-opengrid-self-expanding-snap
The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol.
threads_type = "Blunt"; //["Blunt", "Basic"]
hook_shape_type = "Centered"; //["Straight", "Centered", "Loop"]
corner_type = "Circular"; //["Circular", "Rectangular"]

/* [Hook Settings] */
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

/* [Advanced Settings] */
//Counterclockwisely offset which direction the gadget faces when it's completely screwed in. 270 means it would face 3 o'clock direction.
threads_offset_angle = 0; //[0:15:345]
//Size of fillet at the part hook stem connects to threads.
hook_stem_fillet = 4; //0.4
//Chamfer is automatically clamped to ensure a sufficiently large print surface.
body_max_chamfer = 0.8; //0.2
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]

/* [Experimental Settings] */
//Enable this to draw a custom hook shape with custom_shape_commands. For those who want wacky hooks.
use_custom_shape = false;
//Only supports basic commands, not vectors. For more info, check out BOSL2 wiki for turtle().
custom_shape_commands = "setdir,90,arcright,5,45,move,15,arcleft,5,135,move,30";

/* [Hidden] */
$fa = 1;
$fs = 0.4;

include <lib/opengrid_base.scad>
use <lib/opengrid_threads_lib.scad>

_add_blunt_text = threads_type == "Blunt";
_add_thickness_text = thickness_text_mode == "All" || (thickness_text_mode == "Uncommon" && snap_thickness != OG_LITE_BASIC_THICKNESS && snap_thickness != OG_STANDARD_THICKNESS);

_snaptext_texts = [_add_blunt_text ? OG_SNAP_BLUNT_TEXT : "", _add_thickness_text ? str(floor(snap_thickness)) : ""];

text_depth = 0.4;
_text_cfg = text_cfg(
  texts=_snaptext_texts,
  pos_offsets=(_add_blunt_text && _add_thickness_text) ? OG_GADGET_TEXT_POSITIONS : [[0, 0], [0, 0]]
);

_threads_cfg = threads_cfg(
  threads_type=threads_type,
  threads_offset_angle=threads_offset_angle
);
_threads_diameter = struct_val(_threads_cfg, "threads_diameter");
_threads_pitch = struct_val(_threads_cfg, "threads_pitch");

_threads_connect_diameter = _threads_diameter - OG_THREADS_CONNECT_OFFSET;
_threads_side_offset = _threads_diameter / 2 - OG_SNAP_THREADS_SIDE_OFFSET;

square_corner_radius = 1;
min_ang_radius = 1;
final_tip_size = max(EPS, hook_main_size);
final_stem_length = max(EPS, hook_stem_length);
final_thickness_scale = !use_custom_shape && hook_shape_type == "Loop" ? 1 : body_thickness_scale;
final_side_chamfer = max(0, min(body_thickness / 2 * final_thickness_scale - OG_MIN_WALL_WIDTH, body_width / 2 - OG_MIN_WALL_WIDTH, body_max_chamfer));

circular_straight_hook_path = ["setdir", 90, "arcleft", final_tip_size / 2, hook_tip_angle];
circular_center_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "arcleft", final_tip_size / 2, hook_tip_angle + 90];
circular_loop_hook_path = ["setdir", 0, "arcleft", final_tip_size / 2, 359.9];

rect_offset_angle = opp_adj_to_ang((body_thickness - body_thickness * final_thickness_scale) / 2, final_tip_size);
rect_corner_arc_length = PI / 2 * square_corner_radius;
rect_tip_corner_length = max(EPS, (hook_main_size - square_corner_radius * 2) * (hook_tip_angle - 135) / 90);
rect_straight_middle_ratio = (hook_main_size - square_corner_radius) / (hook_tip_angle > 135 ? (rect_corner_arc_length + rect_tip_corner_length + hook_main_size * 1.5 + rect_corner_arc_length - square_corner_radius) : (hook_main_size * 1.5 + rect_corner_arc_length - square_corner_radius));
rect_center_middle_ratio = (hook_main_size - square_corner_radius) / (hook_tip_angle > 135 ? (rect_corner_arc_length + rect_tip_corner_length + hook_main_size * 2.5 - square_corner_radius * 4 + rect_corner_arc_length * 2) : (hook_main_size * 2.5 - square_corner_radius * 4 + rect_corner_arc_length * 2));

rect_straight_hook_path = ["setdir", 90, "move", hook_main_size / 2, "arcleft", min_ang_radius, 90 + rect_offset_angle * rect_straight_middle_ratio, "move", hook_main_size - square_corner_radius];
rect_center_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "move", hook_main_size / 2 - square_corner_radius, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90 + rect_offset_angle * rect_center_middle_ratio, "move", hook_main_size - square_corner_radius];
rect_hook_tip_path = ["arcleft", square_corner_radius, 90, "move", rect_tip_corner_length];
rect_loop_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "move", hook_main_size / 2 - square_corner_radius - min_ang_radius, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2];

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

tip_rounding_radius = max(0, min(body_thickness * final_thickness_scale, body_width - final_side_chamfer * 2) / 2 - EPS);

default_sweep_profile = rect([body_thickness, body_width], chamfer=final_side_chamfer);
final_sweep_profile = default_sweep_profile;
offset_sweep_profile = scale([final_thickness_scale, 1, 1], final_sweep_profile);
prism_fillet = max(0, min(final_stem_length, hook_stem_fillet));

up(_threads_side_offset) xrot(90)
    diff() {
      zrot(90)
        snap_threads(threads_height=snap_thickness, threads_cfg=_threads_cfg, text_cfg=_text_cfg);
      fwd(_threads_side_offset - body_width / 2)
        down(final_stem_length - EPS) xrot(-90)
            path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1])
              attach("end", "top")
                offset_sweep(offset_sweep_profile, height=tip_rounding_radius + EPS, bottom=os_circle(r=tip_rounding_radius));
      diff("rm2") {
        fwd(_threads_side_offset - body_width / 2)
          zrot(180) xrot(180)
              join_prism(final_sweep_profile, base="plane", length=final_stem_length, base_fillet=prism_fillet, overlap=0) {
                up(EPS) tag_diff(tag="rm2", remove="rm1")
                    cuboid([100, 100, prism_fillet], anchor=TOP) {
                      tag("rm1") cuboid([body_thickness, body_width, final_stem_length + EPS * 2], chamfer=final_side_chamfer, edges="Z", anchor=TOP);
                      tag("rm1") back(_threads_side_offset - body_width / 2 + 0.1)
                          cyl(l=final_stem_length + EPS * 2, d=_threads_connect_diameter, anchor=TOP);
                    }
              }
        tag_diff(tag="rm2", remove="rm1") cyl(l=final_stem_length, d=_threads_connect_diameter * 2, anchor=TOP)
            attach(CENTER, CENTER, inside=true)
              tag("rm1") cyl(l=final_stem_length + EPS * 2, d=_threads_connect_diameter);
      }
      tag("remove") fwd(_threads_side_offset - EPS) cuboid([500, 500, 500], anchor=BACK);
    }
