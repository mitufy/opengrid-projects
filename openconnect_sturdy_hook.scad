/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Main Options] */
//Default hook height is vertical_grids x 28mm, which aligns with openGrid tiles. You can override it by enabling "use_custom_height" below.
vertical_grids = 1;
//Recommened minimum width is 20mm. For smaller hooks, try "openGrid framefit hook generator".
hook_width = 28;
//The total outer length of the hook can be calculated by adding hook_thickness, corner_radius, flat_length and tip_radius together.
hook_thickness = 7;
//Corner_radius cannot be larger than hook_height (vertical_grids x 28). For example, a hook with 40 corner_radius needs at least 2 vertical_grids.
hook_corner_radius = 16;
//The length of the flat bottom part of the hook.
hook_flat_length = 0;
//The radius of the tip of the hook.
hook_tip_radius = 16;
//0.8 means thickness at the end of the hook would be 80% of the beginning. 
hook_thickness_scale = 0.8; //[0.5:0.1:1]
//Angle of the tip of the hook. Set this value to 90 and increase flat_length to generate a flat hook.
hook_tip_angle = 165; //[90:15:210]

/* [Advanced Options] */
//'Staggered' means every other slot. Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Staggered"; //["Staggered","All", "None"]
//Slot entry direction can matter when installing in very tight space. Note when printing, the side with locking mechanism should be closer to print bed.
slot_direction_flip = false;
use_custom_height = false;
custom_hook_height = 70;
//As custom height is not multiples of 28 (otherwise there is no reason to use custom height), slots' position alignment needs to be chosen.
custom_height_slot_alignment = "Center"; //[Center,Top, Bottom]
hook_side_rounding = 2.4; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN openConnect slot parameters
tile_size = 28;

ochead_bottom_height = 0.8;
ochead_bottom_chamfer = 0;
ochead_top_height = 0.6;
ochead_middle_height = 1.4;
ochead_large_rect_width = 17; //0.1
ochead_large_rect_height = 11.2; //0.1

ochead_nub_to_top_distance = 7.2;
ochead_nub_depth = 0.6;
ochead_nub_tip_height = 1.2;
ochead_nub_inner_fillet = 0.2;
ochead_nub_outer_fillet = 0.8;

ochead_large_rect_chamfer = 4;
ochead_small_rect_width = ochead_large_rect_width - ochead_middle_height * 2;
ochead_small_rect_height = ochead_large_rect_height - ochead_middle_height;
ochead_small_rect_chamfer = ochead_large_rect_chamfer - ochead_middle_height + ang_adj_to_opp(45 / 2, ochead_middle_height);

ocslot_move_distance = 11; //0.1
ocslot_onramp_clearance = 0.8;
ocslot_bridge_offset = 0.4;
ocslot_side_clearance = 0.15;
ocslot_depth_clearance = 0.12;

ochead_bottom_profile = back(ochead_large_rect_width / 2, rect([ochead_large_rect_width, ochead_large_rect_height], chamfer=[ochead_large_rect_chamfer, ochead_large_rect_chamfer, 0, 0], anchor=BACK));
ochead_top_profile = back(ochead_small_rect_width / 2, rect([ochead_small_rect_width, ochead_small_rect_height], chamfer=[ochead_small_rect_chamfer, ochead_small_rect_chamfer, 0, 0], anchor=BACK));
ochead_total_height = ochead_top_height + ochead_middle_height + ochead_bottom_height;
ochead_middle_to_bottom = ochead_large_rect_height - ochead_large_rect_width / 2;

ocslot_bottom_height = ochead_bottom_height + ang_adj_to_opp(45 / 2, ocslot_side_clearance) + ocslot_depth_clearance;
ocslot_top_height = ochead_top_height - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_total_height = ocslot_top_height + ochead_middle_height + ocslot_bottom_height;
ocslot_nub_to_top_distance = ochead_nub_to_top_distance + ocslot_side_clearance;

ocslot_small_rect_width = ochead_small_rect_width + ocslot_side_clearance * 2;
ocslot_small_rect_height = ochead_small_rect_height + ocslot_side_clearance * 2;
ocslot_small_rect_chamfer = ochead_small_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_large_rect_width = ochead_large_rect_width + ocslot_side_clearance * 2;
ocslot_large_rect_height = ochead_large_rect_height + ocslot_side_clearance * 2;
ocslot_large_rect_chamfer = ochead_large_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_middle_to_bottom = ocslot_large_rect_height - ocslot_large_rect_width / 2;
ocslot_to_grid_top_offset = (tile_size - 24.8) / 2;
ocslot_top_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width, ocslot_small_rect_height], chamfer=[ocslot_small_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));
ocslot_bottom_profile = back(ocslot_large_rect_width / 2, rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));

ochead_side_profile = [
  [0, 0],
  [ochead_large_rect_width / 2 - ochead_bottom_chamfer, 0],
  [ochead_large_rect_width / 2, ochead_bottom_chamfer],
  [ochead_large_rect_width / 2, ochead_bottom_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height + ochead_top_height],
  [0, ochead_bottom_height + ochead_middle_height + ochead_top_height],
];
//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = "both", nub_flattop = true, excess_thickness = 0, size_offset = 0) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : ochead_nub_to_top_distance;

  difference() {
    union() {
      linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
      up(bottom_height - eps) hull() {
          up(ochead_middle_height) linear_extrude(h=eps) polygon(offset(top_profile, delta=size_offset));
          linear_extrude(h=eps) polygon(offset(bottom_profile, delta=size_offset));
        }
      if (top_height + excess_thickness > 0)
        up(bottom_height + ochead_middle_height - eps)
          linear_extrude(h=top_height + excess_thickness + eps) polygon(offset(top_profile, delta=size_offset));
    }
    back(large_rect_width / 2 - nub_to_top_distance) {
      if (add_nubs == "left" || add_nubs == "both")
        left(large_rect_width / 2 + size_offset - ochead_nub_depth / 2 + eps) zrot(-90)
            linear_extrude(4) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], $fn=64);
      if (add_nubs == "right" || add_nubs == "both")
        right(large_rect_width / 2 + size_offset - ochead_nub_depth / 2 + eps) zrot(90)
            linear_extrude(4) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], $fn=64);
    }
  }
}
module openconnect_slot(add_nubs = "left", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_height, ocslot_total_height]) {
    up(ocslot_total_height / 2) yrot(180) union() {
          if (direction_flip)
            xflip() ocslot_body(excess_thickness);
          else
            ocslot_body(excess_thickness);
        }
    children();
  }
  module ocslot_body(excess_thickness = 0) {
    ocslot_side_profile = [
      [0, 0],
      [ocslot_large_rect_width / 2, 0],
      [ocslot_large_rect_width / 2, ocslot_bottom_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness],
      [0, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness],
    ];
    ocslot_bridge_offset_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width / 2 + ocslot_bridge_offset, ocslot_small_rect_height + ocslot_move_distance + ocslot_onramp_clearance], chamfer=[ocslot_small_rect_chamfer + ocslot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(head_type="slot", add_nubs=add_nubs, excess_thickness=excess_thickness);
      xrot(90) linear_extrude(ocslot_middle_to_bottom + ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_profile);
      up(ocslot_bottom_height) linear_extrude(ocslot_top_height + ochead_middle_height) polygon(ocslot_bridge_offset_profile);
      fwd(ocslot_move_distance) {
        linear_extrude(ocslot_bottom_height) onramp_2d();
        up(ocslot_bottom_height)
          linear_extrude(ochead_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(ochead_middle_height) up(ocslot_bottom_height + ochead_middle_height)
            linear_extrude(ocslot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(ocslot_small_rect_chamfer) cuboid([ocslot_small_rect_width, ocslot_small_rect_height, ocslot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=ocslot_onramp_clearance)
        left(ocslot_onramp_clearance + ochead_middle_height) back(ocslot_large_rect_width / 2) {
            rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
module openconnect_slot_grid(h_grid = 1, v_grid = 1, grid_size = 28, lock_distribution = "None", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[h_grid * grid_size, v_grid * grid_size, ocslot_total_height]) {
    tag_scope() hide_this() cuboid([h_grid * grid_size, v_grid * grid_size, ocslot_total_height]) {
          back(ocslot_to_grid_top_offset) {
            grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
              attach(TOP, BOTTOM, inside=true)
                openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? "left" : "", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
          }
        }
    children();
  }
}
//END openConnect slot modules

horizontal_grids = max(1, floor((hook_width) / tile_size));

hook_stem_height = use_custom_height ? custom_hook_height : vertical_grids * tile_size;
hook_slot_alignment =
  !use_custom_height || custom_height_slot_alignment == "Center" ? CENTER
  : custom_height_slot_alignment == "Top" ? BACK : FRONT;
final_hook_corner_radius = min(hook_corner_radius, hook_stem_height - hook_thickness / 2 - hook_side_rounding);
stem_first_height = max(eps, hook_stem_height - final_hook_corner_radius);

final_thickness_scale = hook_thickness_scale;
final_side_chamfer = max(0, min(hook_thickness / 2 * final_thickness_scale - 0.84, hook_width / 2 - 0.84, hook_side_rounding));

hook_path =
  hook_tip_radius <= 0 || hook_tip_angle <= 90 ? ["setdir", -90, "arcleft", final_hook_corner_radius, "move", max(eps, hook_flat_length)]
  : ["setdir", -90, "arcleft", final_hook_corner_radius, "move", max(eps, hook_flat_length), "arcleft", hook_tip_radius, max(1, hook_tip_angle - 90)];
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
      attach(LEFT, TOP, align=hook_slot_alignment, inside=true, spin=90)
        tag("rm0") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
    }
    //path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1], caps=[true, os_circle(r=tip_rounding_radius)]);
    //makerworld doesn't support newest path_sweep caps yet so it has to be done the old way.
    tag("kp1") up(hook_width / 2) fwd(stem_first_height - hook_thickness / 2 * (1 - ( (1 - hook_thickness_scale) * path_first_ratio))) path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1]) {
            attach("end", "top")
              offset_sweep(offset_sweep_profile, height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius), spin=180, $fn=128);
          }
  }
