include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_version = "Lite Strong"; //[Full:Full - 6.8mm, Lite Strong:Lite Strong - 4mm, Lite Basic:Lite Basic - 3.4mm]
holder_type = "Circular"; //["Circular", "Square"]
//This changes which direction the hook faces when it is completely screwed in to a snap.
threads_rotate_angle = 0;

/* [Hook Options] */
body_width = 14;
body_thickness = 2.6; //0.2
//The scaling of body thickness. 0.6 means thickness at the end would be 60% of the beginning.
body_thickness_scale = 0.5; //[0.1:0.1:1]

holder_entry_width = 10; //1
clamp_inner_size = 25; //1

/* [Square Options] */
clamp_square_depth = 20; //1
clamp_square_corner_rounding = 1; //0.2
clamp_square_corner_angle = 90; //[10:10:170]

/* [Tip Options] */
clamp_has_tip = true;
clamp_tip_diameter = 3; //1
clamp_tip_angle = 160; //10


/* [Advanced Options] */
//This value is automatically clamped to ensure a sufficiently large print surface.
body_side_chamfer = 0.8; //0.2


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

clamp_side_chamfer = max(0, min(body_thickness / 2 * body_thickness_scale - 0.84, body_width / 2 - 0.84, body_side_chamfer));
clamp_circular_angle = 180 - opp_hyp_to_ang(min(holder_entry_width / 2 + body_thickness / 2 + (clamp_has_tip ? clamp_tip_diameter / 2 : 0), clamp_inner_size / 2), clamp_inner_size / 2);

clamp_path_tip = [
  "arcleftto",
  clamp_tip_diameter / 2 + body_thickness / 2,
  340,
];
clamp_path_circular = [
  "arcright",
  clamp_inner_size / 2 + body_thickness / 2,
  clamp_circular_angle,
];
square_inner_corner_rounding = max(0, min(clamp_square_corner_rounding, clamp_inner_size / 2, clamp_square_depth / 2));
square_outer_corner_rounding = max(0, min(clamp_square_corner_rounding, clamp_inner_size / 2 - holder_entry_width / 2 - (clamp_has_tip ? clamp_tip_diameter / 2 : 0)));
square_side_length = max(0, ang_adj_to_hyp(clamp_square_corner_angle - 90, clamp_square_depth) + body_thickness - square_inner_corner_rounding - square_outer_corner_rounding);
clamp_path_square = [
  "move",
  max(0, clamp_inner_size / 2 + body_thickness / 2 - square_inner_corner_rounding),
  "arcrightto",
  square_inner_corner_rounding,
  clamp_square_corner_angle - 180,
  "move",
  square_side_length,
  "arcrightto",
  square_outer_corner_rounding,
  180,
  "move",
  max(0, clamp_inner_size / 2 + body_thickness / 2 - holder_entry_width / 2 - square_outer_corner_rounding - (clamp_has_tip ? clamp_tip_diameter / 2 : 0)),
];
clamp_path_main =
  holder_type == "Circular" ? clamp_path_circular
  : clamp_path_square;

holder_path_length_ratio = clamp_has_tip ? path_length(turtle(clamp_path_main)) / (path_length(turtle(clamp_path_main)) + path_length(turtle(clamp_path_tip))) : 1;
holder_path_end_scale = 1 - (1 - body_thickness_scale) * holder_path_length_ratio;

clamp_path =
  clamp_has_tip ? concat(clamp_path_main, clamp_path_tip)
  : clamp_path_main;
clamp_profile = rect([body_thickness, body_width], chamfer=[0, clamp_side_chamfer, clamp_side_chamfer, clamp_side_chamfer]);

first_target_ratio = (1 - (1 - body_thickness_scale) * holder_path_length_ratio);
prism_base_radius = clamp_inner_size / 2 + body_thickness / 2 * first_target_ratio;
prism_width = prism_base_radius / 2;
prism_down_offset = body_thickness / 2 * min(1, 1 - (1 - first_target_ratio) * 0.9);
prism_fillet = max(0, min(prism_width, snap_thickness, 2));

diff() {
  zrot(threads_compatiblity_angle + threads_rotate_angle)
    generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=3, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
  fwd(threads_offset - body_width / 2) {
    down(body_thickness / 2) up(body_thickness * (1 - body_thickness_scale) / 10)
        xflip_copy()
          xrot(90)
            path_sweep(clamp_profile, path=path_merge_collinear(turtle(clamp_path)), scale=[body_thickness_scale, 1], caps=[true, os_circle(r=min(body_thickness, body_width) * body_thickness_scale, clip_angle=45)]);
  }
  if (holder_type == "Circular")
    diff("inner_remove") {
      difference() {
        //lower the position of the connecting prism, taking thickness scale into account. calculation is inaccurate but seems to be good enough?
        down(clamp_inner_size / 2 + body_thickness / 2 * min(1, 1 - (1 - first_target_ratio) * 0.9))
            join_prism(circle(d=threads_connect_diameter), base="cyl", base_r=prism_base_radius, length=snap_thickness, base_fillet=prism_fillet, overlap=0, base_T=zrot(90), uniform=false);
        difference() {
          cyl(r=10, l=snap_thickness + eps, anchor=BOTTOM);
          cyl(r=7, l=snap_thickness - threads_bottom_bevel, anchor=BOTTOM);
        }
      }
      tag("inner_remove") back(body_width - threads_offset - clamp_side_chamfer) cuboid([50, 50, 50], anchor=FRONT);
    }
  tag("remove") fwd(threads_offset) cuboid([500, 500, 500], anchor=BACK);
}
