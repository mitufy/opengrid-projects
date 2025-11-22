/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Hook Options] */
openconnect_slot_lock_distribution = "Staggered"; //["Staggered","All", "None"]
openconnect_slot_direction_flip = false;
vertical_grids = 1;
//Recommened minimum width is 20mm. For smaller hooks, try "openGrid framefit hook generator".
hook_width = 28;
hook_thickness = 7;
//corner_radius and stem_height add to total height of the hook.
hook_corner_radius = 16;
//The length of the flat bottom part of the hook.
hook_flat_length = 0;
//tip_radius, corner radius and flat_length add to total length of the hook.
hook_tip_radius = 16;
//Scaling of hook thickness. 0.6 means thickness at the end of the hook would be 60% of the beginning.
hook_thickness_scale = 0.8; //[0.5:0.1:1]
//Angle of the tip of the hook. Set this value to 90 and increase flat_length to generate a shelf.
hook_tip_angle = 165; //[90:15:210]

hook_side_rounding = 2.4; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN openConnect slot parameters
tile_size = 28;

openconnect_head_bottom_height = 0.4;
openconnect_head_bottom_chamfer = 0;
openconnect_head_top_height = 0.6;
openconnect_head_middle_height = 1.6;
openconnect_head_large_rect_width = 17; //0.1
openconnect_head_large_rect_height = 11.2; //0.1

openconnect_head_nub_to_top_distance = 7.2;
openconnect_lock_nub_depth = 0.4;
openconnect_lock_nub_tip_height = 0.8;
openconnect_lock_nub_inner_fillet = 0.2;
openconnect_lock_nub_outer_fillet = 0.8;

openconnect_head_large_rect_chamfer = 4;
openconnect_head_small_rect_width = openconnect_head_large_rect_width - openconnect_head_middle_height * 2;
openconnect_head_small_rect_height = openconnect_head_large_rect_height - openconnect_head_middle_height;
openconnect_head_small_rect_chamfer = openconnect_head_large_rect_chamfer - openconnect_head_middle_height + ang_adj_to_opp(45 / 2, openconnect_head_middle_height);

openconnect_slot_move_distance = 11; //0.1
openconnect_slot_onramp_clearance = 0.8;
openconnect_slot_bridge_offset = 0.4;
openconnect_slot_side_clearance = 0.18;
openconnect_slot_depth_clearance = 0.12;

openconnect_head_bottom_profile = back(openconnect_head_large_rect_width / 2, rect([openconnect_head_large_rect_width, openconnect_head_large_rect_height], chamfer=[openconnect_head_large_rect_chamfer, openconnect_head_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_top_profile = back(openconnect_head_small_rect_width / 2, rect([openconnect_head_small_rect_width, openconnect_head_small_rect_height], chamfer=[openconnect_head_small_rect_chamfer, openconnect_head_small_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_total_height = openconnect_head_top_height + openconnect_head_middle_height + openconnect_head_bottom_height;
openconnect_head_middle_to_bottom = openconnect_head_large_rect_height - openconnect_head_large_rect_width / 2;

openconnect_slot_top_profile = offset(openconnect_head_top_profile, delta=openconnect_slot_side_clearance);
openconnect_slot_bottom_profile = offset(openconnect_head_bottom_profile, delta=openconnect_slot_side_clearance);
openconnect_slot_bottom_height = openconnect_head_bottom_height + ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance) + openconnect_slot_depth_clearance;
openconnect_slot_middle_height = openconnect_head_middle_height;
openconnect_slot_top_height = openconnect_head_top_height - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_total_height = openconnect_slot_top_height + openconnect_slot_middle_height + openconnect_slot_bottom_height;
openconnect_slot_nub_to_top_distance = openconnect_head_nub_to_top_distance + openconnect_slot_side_clearance;

openconnect_slot_small_rect_width = openconnect_head_small_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_height = openconnect_head_small_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_chamfer = openconnect_head_small_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_large_rect_width = openconnect_head_large_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_height = openconnect_head_large_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_chamfer = openconnect_head_large_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_middle_to_bottom = openconnect_slot_large_rect_height - openconnect_slot_large_rect_width / 2;
openconnect_slot_to_grid_top_offset = (tile_size - 24.8) / 2;

openconnect_head_side_profile = [
  [0, 0],
  [openconnect_head_large_rect_width / 2 - openconnect_head_bottom_chamfer, 0],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_chamfer],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_head_middle_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_head_middle_height + openconnect_head_top_height],
  [0, openconnect_head_bottom_height + openconnect_head_middle_height + openconnect_head_top_height],
];

//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(is_negative = false, add_nubs = 2, excess_thickness = 0) {
  bottom_profile = is_negative ? openconnect_slot_bottom_profile : openconnect_head_bottom_profile;
  top_profile = is_negative ? openconnect_slot_top_profile : openconnect_head_top_profile;

  bottom_height = is_negative ? openconnect_slot_bottom_height : openconnect_head_bottom_height;
  middle_height = is_negative ? openconnect_slot_middle_height : openconnect_head_middle_height;
  top_height = is_negative ? openconnect_slot_top_height : openconnect_head_top_height;
  large_rect_width = is_negative ? openconnect_slot_large_rect_width : openconnect_head_large_rect_width;
  large_rect_height = is_negative ? openconnect_slot_large_rect_height : openconnect_head_large_rect_height;
  nub_to_top_distance = is_negative ? openconnect_slot_nub_to_top_distance : openconnect_head_nub_to_top_distance;

  difference() {
    union() {
      linear_extrude(h=bottom_height) polygon(bottom_profile);
      up(bottom_height - eps) hull() {
          up(middle_height) linear_extrude(h=eps) polygon(top_profile);
          linear_extrude(h=eps) polygon(bottom_profile);
        }
      up(bottom_height + middle_height - eps)
        linear_extrude(h=top_height + excess_thickness + eps) polygon(top_profile);
    }
    back(large_rect_width / 2 - nub_to_top_distance)
      rot_copies([90, 0, 0], n=add_nubs)
        left(large_rect_width / 2 - openconnect_lock_nub_depth / 2 + eps) zrot(-90)
            linear_extrude(4) trapezoid(h=openconnect_lock_nub_depth, w2=openconnect_lock_nub_tip_height, ang=[45, 45], rounding=[openconnect_lock_nub_inner_fillet, openconnect_lock_nub_inner_fillet, -openconnect_lock_nub_outer_fillet, -openconnect_lock_nub_outer_fillet], $fn=64);
  }
}
module openconnect_slot(add_nubs = 1, direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[openconnect_slot_large_rect_width, openconnect_slot_large_rect_height, openconnect_slot_total_height]) {
    up(openconnect_slot_total_height / 2) yrot(180) union() {
          if (direction_flip)
            xflip() openconnect_slot_body(excess_thickness);
          else
            openconnect_slot_body(excess_thickness);
        }
    children();
  }
  module openconnect_slot_body(excess_thickness = 0) {
    openconnect_slot_side_profile = [
      [0, 0],
      [openconnect_slot_large_rect_width / 2, 0],
      [openconnect_slot_large_rect_width / 2, openconnect_slot_bottom_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_slot_middle_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_slot_middle_height + openconnect_slot_top_height + excess_thickness],
      [0, openconnect_slot_bottom_height + openconnect_slot_middle_height + openconnect_slot_top_height + excess_thickness],
    ];
    openconnect_slot_bridge_offset_profile = back(openconnect_slot_small_rect_width / 2, rect([openconnect_slot_small_rect_width / 2 + openconnect_slot_bridge_offset, openconnect_slot_small_rect_height + openconnect_slot_move_distance + openconnect_slot_onramp_clearance], chamfer=[openconnect_slot_small_rect_chamfer + openconnect_slot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(is_negative=true, add_nubs=add_nubs ? 1 : 0, excess_thickness=excess_thickness);
      xrot(90) linear_extrude(openconnect_slot_middle_to_bottom + openconnect_slot_move_distance + openconnect_slot_onramp_clearance) xflip_copy() polygon(openconnect_slot_side_profile);
      up(openconnect_slot_bottom_height) linear_extrude(openconnect_slot_top_height + openconnect_slot_middle_height) polygon(openconnect_slot_bridge_offset_profile);
      fwd(openconnect_slot_move_distance) {
        linear_extrude(openconnect_slot_bottom_height) onramp_2d();
        up(openconnect_slot_bottom_height)
          linear_extrude(openconnect_slot_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(openconnect_slot_middle_height) up(openconnect_slot_bottom_height + openconnect_slot_middle_height)
            linear_extrude(openconnect_slot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(openconnect_slot_small_rect_chamfer) cuboid([openconnect_slot_small_rect_width, openconnect_slot_small_rect_height, openconnect_slot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=openconnect_slot_onramp_clearance)
        left(openconnect_slot_onramp_clearance + openconnect_slot_middle_height) back(openconnect_slot_large_rect_width / 2) {
            rect([openconnect_slot_large_rect_width, openconnect_slot_large_rect_height], chamfer=[openconnect_slot_large_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=openconnect_slot_large_rect_width - openconnect_slot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
module openconnect_slot_grid(h_grid = 1, v_grid = 1, grid_size = 28, lock_distribution = "None", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[h_grid * grid_size, v_grid * grid_size, openconnect_slot_total_height]) {
    tag_scope() hide_this() cuboid([h_grid * grid_size, v_grid * grid_size, openconnect_slot_total_height]) {
          back(openconnect_slot_to_grid_top_offset) {
            grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
              attach(TOP, BOTTOM, inside=true)
                openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? 1 : 0, direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs=1, direction_flip=direction_flip, excess_thickness=excess_thickness);
          }
        }
    children();
  }
}
//END openConnect slot modules

horizontal_grids = max(1, floor((hook_width) / tile_size));

hook_stem_height = vertical_grids * tile_size;
final_hook_corner_radius = min(hook_corner_radius, hook_stem_height - hook_thickness / 2 - hook_side_rounding);
stem_first_height = max(eps, vertical_grids * tile_size - final_hook_corner_radius);

final_thickness_scale = hook_thickness_scale;
final_side_chamfer = max(0, min(hook_thickness / 2 * final_thickness_scale - 0.84, hook_width / 2 - 0.84, hook_side_rounding));

hook_path = ["setdir", -90, "arcleft", final_hook_corner_radius, "move", max(eps, hook_flat_length), "arcleft", hook_tip_radius, max(1, hook_tip_angle - 90)];
hook_path_first_part = ["setdir", -90, "arcleft", final_hook_corner_radius];

tip_rounding_radius = max(0, min(hook_thickness * final_thickness_scale, hook_width - final_side_chamfer * 2) / 2 - eps);

path_first_ratio = path_length(turtle(hook_path_first_part)) / path_length(turtle(hook_path));

teardrop_sweep_profile = difference(
  rect([hook_thickness, hook_width]),
  right(hook_thickness / 2, fwd(hook_width / 2, yflip(zrot(-180, mask2d_teardrop(r=final_side_chamfer, $fn=64))))),
  right(hook_thickness / 2, back(hook_width / 2, zrot(-180, mask2d_teardrop(r=final_side_chamfer, $fn=64))))
);

default_sweep_profile = rect([hook_thickness, hook_width], chamfer=[final_side_chamfer, 0, 0, final_side_chamfer]);

final_sweep_profile = teardrop_sweep_profile;
offset_sweep_profile = scale([final_thickness_scale, 1, 1], final_sweep_profile);

diff(remove="rm0")
  diff(remove="rm1", keep="kp1 rm0") {
    cuboid([hook_thickness, hook_stem_height, hook_width], anchor=BACK + BOTTOM, rounding=final_side_chamfer, edges=[BACK + RIGHT], $fn=128) {
      tag("rm1") edge_profile([TOP + RIGHT, BOTTOM + RIGHT, BACK + TOP, BACK + BOTTOM])
          mask2d_teardrop(r=final_side_chamfer, $fn=64);
      tag("rm1") corner_profile([BACK + TOP + RIGHT, BACK + BOTTOM + RIGHT], r=final_side_chamfer)
          mask2d_teardrop(r=final_side_chamfer, $fn=128);
      tag_diff(remove="rm2", tag="kp1") {
        attach(FRONT, FRONT, align=LEFT, inside=true)
          tag("") cuboid([final_hook_corner_radius + hook_thickness / 2, final_hook_corner_radius + hook_thickness / 2, hook_width], chamfer=final_side_chamfer, edges=[LEFT + TOP, LEFT + BOTTOM])
              back(final_hook_corner_radius / 2) right(final_hook_corner_radius / 2)
                  tag("rm2") zcyl(r=final_hook_corner_radius, h=hook_width + eps * 2);
      }
      attach(LEFT, TOP, inside=true, spin=90)
        tag("rm0") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=openconnect_slot_lock_distribution, direction_flip=openconnect_slot_direction_flip, excess_thickness=0);
    }
    //path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1], caps=[true, os_circle(r=tip_rounding_radius)]);
    //makerworld doesn't support newest path_sweep caps yet so it has to be done the old way.
    tag("kp1") up(hook_width / 2) fwd(stem_first_height - hook_thickness / 2 * (1 - ( (1 - hook_thickness_scale) * path_first_ratio))) path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1]) {
            attach("end", "top")
              offset_sweep(offset_sweep_profile, height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius), spin=180, $fn=128);
          }
  }
