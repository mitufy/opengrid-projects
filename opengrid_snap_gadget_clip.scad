/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_version = "Lite Strong"; //[Full:Full - 6.8mm, Lite Strong:Lite Strong - 4mm, Lite Basic:Lite Basic - 3.4mm]
clip_type = "Circular"; //["Circular", "Rectangular","Rect_Half"]
//This changes which direction the hook faces when it is completely screwed in to a snap.
threads_rotate_angle = 0;

/* [Hook Options] */
body_width = 14;
body_thickness = 2.6; //0.2
//The scaling of body thickness. 0.6 means thickness at the end would be 60% of the beginning.
body_thickness_scale = 0.5; //[0.1:0.1:1]

clip_entry_width = 10; //0.2
clip_inner_size = 25; //0.2
clip_circular_angle = 160;

/* [Rectangular Options] */
clip_square_depth = 20; //1
clip_square_corner_rounding = 1; //0.2
clip_square_corner_angle = 90; //[10:10:170]

/* [Tip Options] */
clip_has_tip = true;
clip_tip_diameter_a = 3; //1
clip_tip_diameter = 3; //1
clip_tip_angle = 160; //10

/* [Advanced Options] */
//This value is automatically cliped to ensure a sufficiently large print surface.
body_side_chamfer = 0.8; //0.2
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]

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

//text parameters
text_depth = 0.4;
final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

final_side_chamfer = max(0, min(body_thickness / 2 * body_thickness_scale - 0.84, body_width / 2 - 0.84, body_side_chamfer));
// clip_circular_angle = 180 - opp_hyp_to_ang(min(clip_entry_width / 2 + body_thickness / 2 + (clip_has_tip ? clip_tip_diameter / 2 : 0), clip_inner_size / 2), clip_inner_size / 2);

clip_path_tip = [
  "arcleftto",
  clip_tip_diameter / 2 + body_thickness / 2,
  340,
];
clip_path_circular = [
  "arcright",
  clip_inner_size / 2 + body_thickness / 2,
  clip_circular_angle,
];

rect_icorner_rounding = max(0, min(clip_square_corner_rounding, clip_inner_size / 2, clip_square_depth / 2));
rect_ocorner_rounding = max(0, min(clip_square_corner_rounding, clip_inner_size / 2 - clip_entry_width / 2 - (clip_has_tip ? clip_tip_diameter / 2 : 0)));
square_side_length = max(0, ang_adj_to_hyp(clip_square_corner_angle - 90, clip_square_depth) + body_thickness - rect_icorner_rounding - rect_ocorner_rounding);
square_side_length_a = max(0, ang_adj_to_hyp(clip_square_corner_angle - 90, clip_square_depth) + body_thickness - rect_icorner_rounding - clip_tip_diameter_a / 2);
clip_path_square = ["move", max(0, clip_inner_size / 2 + body_thickness / 2 - rect_icorner_rounding), "arcrightto", rect_icorner_rounding, clip_square_corner_angle - 180, "move", square_side_length, "arcrightto", rect_ocorner_rounding, 180, "move", max(0, clip_inner_size / 2 + body_thickness / 2 - clip_entry_width / 2 - rect_ocorner_rounding - (clip_has_tip ? clip_tip_diameter / 2 : 0))];
clip_path_square_no = ["move", max(0, clip_inner_size / 2 + body_thickness / 2 - rect_icorner_rounding), "arcrightto", rect_icorner_rounding, clip_square_corner_angle - 180, "move", square_side_length_a, "arcright", clip_tip_diameter_a / 2, 40, "arcleft", clip_tip_diameter / 2, 180];

clip_path_main =
  clip_type == "Circular" ? clip_path_circular
  : clip_type == "Rectangular" ? clip_path_square
  : clip_path_square_no;

clip_path_length_ratio = clip_has_tip ? path_length(turtle(clip_path_main)) / (path_length(turtle(clip_path_main)) + path_length(turtle(clip_path_tip))) : 1;
clip_path_end_scale = 1 - (1 - body_thickness_scale) * clip_path_length_ratio;

clip_path =
  clip_has_tip ? concat(clip_path_main, clip_path_tip)
  : clip_path_main;
clip_profile = rect([body_thickness, body_width], chamfer=[0, final_side_chamfer, final_side_chamfer, final_side_chamfer]);
offset_sweep_profile = scale([body_thickness_scale, 1, 1], clip_profile);
tip_rounding_radius = max(0, min(body_thickness * body_thickness_scale - final_side_chamfer * 2, body_width - final_side_chamfer * 2) / 2 - eps);

first_target_ratio = (1 - (1 - body_thickness_scale) * clip_path_length_ratio);
prism_base_radius = clip_inner_size / 2 + body_thickness / 2 * first_target_ratio;
prism_width = prism_base_radius / 2;
prism_down_offset = body_thickness / 2 * min(1, 1 - (1 - first_target_ratio) * 0.9);
prism_fillet = max(0, min(prism_width, snap_thickness, 0.01));

// rotate_sweep(right(10,clip_profile),angle=300);
diff() {
  zrot(threads_compatiblity_angle + threads_rotate_angle)
    generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=3, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
  if (final_add_thickness_text)
    tag("remove") up(snap_thickness - text_depth + eps / 2)
        linear_extrude(height=text_depth + eps) text(str(snap_thickness), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
  fwd(threads_offset - body_width / 2) {
    down(body_thickness / 2) up(body_thickness * (1 - body_thickness_scale) / 10)
        xflip_copy()
          xrot(90)
            // path_sweep(clip_profile, path=path_merge_collinear(turtle(clip_path)), scale=[body_thickness_scale, 1], caps=[true, os_circle(r=min(body_thickness, body_width) * body_thickness_scale, clip_angle=45)]);
            //makerworld doesn't support newest path_sweep caps yet so it has to be done the old way.
            path_sweep(clip_profile, path=path_merge_collinear(turtle(clip_path)), scale=[body_thickness_scale, 1])
              attach("end", "top")
                offset_sweep(offset_sweep_profile, height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius));
  }
  if (clip_type == "Circular") {
    diff("inner_remove") {
      connect_cyl_diameter = min(threads_connect_diameter, clip_inner_size + body_thickness * 2);
      fwd((threads_connect_diameter - connect_cyl_diameter) / 2 + 0.1)
        cyl(d=connect_cyl_diameter, l=clip_inner_size * 2 / 3, anchor=TOP);
      tag("inner_remove") ycyl(r=clip_inner_size / 2 + body_thickness / 2, l=200, anchor=TOP);
      tag("inner_remove") back(body_width - threads_offset - final_side_chamfer) cuboid([50, 50, 50], anchor=FRONT);
    }
  }
  tag("remove") fwd(threads_offset) cuboid([500, 500, 500], anchor=BACK);
}
