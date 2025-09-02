include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_version = "Lite Strong"; //[Full:Full - 6.8mm, Lite Strong:Lite Strong - 4mm, Lite Basic:Lite Basic - 3.4mm]
hook_type = "Centered"; //["Straight", "Centered", "Loop","Vertical"]
//This changes which direction the hook faces when it is completely screwed in to a snap.
threads_rotate_angle = 0;

/* [Hook Options] */
body_width = 13.2; //0.4
body_thickness = 6; //0.4
//The scaling of body thickness. 0.6 means thickness at the end would be 60% of the beginning.
body_thickness_scale = 0.5; //[0.1:0.1:1]

hook_stem_length = 8; //0.4
hook_stem_fillet = 4; //0.4
hook_tip_radius = 10; //1
//Does not affect "Loop" hooks.
hook_tip_angle = 180; //[5:5:260]

/* [Advanced Options] */
//This value is automatically clamped to ensure a sufficiently large print surface.
body_side_chamfer = 0.8; //0.2
//An experimental feature for those who want wacky hooks. Use this to draw a custom hook shape with custom_shape_commands.
use_custom_shape = false;
//This customizer only supports basic commands, not vectors. For more info, check out BOSL2 wiki for turtle().
custom_shape_commands = "setdir,90,move,3,arcleft,5,45,move,5,arcright,3,45,move,10,arcright,3,move,20";

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

threads_side_slice_off = 1.4; //0.1

threads_compatiblity_angle = 53.5;
threads_diameter = 16;
threads_bottom_bevel_full = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1

snap_thickness =
  snap_version == "Full" ? 6.8
  : snap_version == "Lite Strong" ? 4
  : 3.4;

//thread parameters
threads_bottom_bevel =
  snap_version == "Full" ? threads_bottom_bevel_full
  : threads_bottom_bevel_lite;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

threads_connect_diameter = threads_diameter - 1.8;
threads_offset = threads_diameter / 2 - threads_side_slice_off;

final_tip_radius = max(0.01, hook_tip_radius);
final_stem_length = max(0.01, hook_stem_length);
final_thickness_scale = hook_type == "Loop" ? 1 : body_thickness_scale;
final_side_chamfer = max(0, min(body_thickness / 2 * final_thickness_scale - 0.84, body_width / 2 - 0.84, body_side_chamfer));


straight_hook_path = ["setdir", 90, "arcright", final_tip_radius, hook_tip_angle];
center_hook_path = ["setdir", 0, "arcleft", 0.01, 180, "arcright", final_tip_radius, hook_tip_angle + 90];
loop_hook_path = ["setdir", 0, "arcleft", 0.01, 180, "arcright", final_tip_radius, 359.9];

function to_turtle(x) = is_num(parse_num(x)) ? parse_num(x) : x;
temp_path = str_split(str_strip(str_replace_char(str_replace_char(custom_shape_commands, " ", ""), "\"", ""), ","), ",");
custom_hook_path = [for (i = [0:len(temp_path) - 1]) to_turtle(temp_path[i])];

hook_path =
  use_custom_shape ? custom_hook_path
  : hook_type == "Loop" ? loop_hook_path
  : hook_type == "Centered" ? center_hook_path
  : straight_hook_path;

tip_rounding_cut=min(body_thickness * final_thickness_scale, body_width)*sqrt(2)-min(body_thickness * final_thickness_scale, body_width);
// tip_length_ratio = tip_rounding_cut/(path_length(turtle(hook_path))+final_stem_length);

body_sweep_profile_chamfers = [hook_type == "Vertical" ? 0 : final_side_chamfer, final_side_chamfer, final_side_chamfer, hook_type == "Vertical" ? 0 : final_side_chamfer];
body_sweep_profile = rect([body_thickness, body_width], chamfer=body_sweep_profile_chamfers);
prism_fillet = max(0, min(final_stem_length, hook_stem_fillet));

diff() {
  zrot(threads_compatiblity_angle + threads_rotate_angle + 90)
    generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=3, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
  tag("remove") up(snap_thickness - 0.4) linear_extrude(height=0.4 + eps) text(str(threads_rotate_angle), size=3.2, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
  fwd(threads_offset - body_width / 2) {
    if (hook_type == "Vertical" && !use_custom_shape) {
      down(body_thickness / 2) yrot(90) xrot(-90) {
            //ensure that the starting part connects to threads, not affected by body_thickness_scale
            fwd(3.2) path_sweep(body_sweep_profile, path=path_merge_collinear(turtle(["ymove", 6 + final_stem_length])));
            back(2.8 + final_stem_length) path_sweep(body_sweep_profile, path=path_merge_collinear(turtle(straight_hook_path)), scale=[final_thickness_scale, 1], caps=[true, os_circle(r=min(body_thickness, body_width) * final_thickness_scale, clip_angle=45)]);
          }
    } else {
      down(final_stem_length - eps) xrot(-90)
          path_sweep(body_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1], caps=[true, os_circle(cut=tip_rounding_cut, clip_angle=45)]);
      difference() {
        xrot(180) join_prism(body_sweep_profile, base="plane", length=final_stem_length, base_fillet=prism_fillet, overlap=0);
        up(eps) difference() {
            cuboid([100, 100, prism_fillet], anchor=TOP);
            union(){
              cuboid([body_thickness, body_width,final_stem_length + eps * 2], chamfer=final_side_chamfer,edges="Z", anchor=TOP);
            back(threads_offset - body_width / 2 + 0.1)
              cyl(l=final_stem_length + eps * 2, d=threads_connect_diameter, anchor=TOP);
            }
          }
      }
    }
  }
  tag("remove") fwd(threads_offset) cuboid([500, 500, 500], anchor=BACK);
}
