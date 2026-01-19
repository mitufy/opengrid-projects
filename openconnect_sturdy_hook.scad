/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Main Settings] */
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

/* [Advanced Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//The slot entry direction can matter when installing in very tight spaces. Note the side with the locking mechanism should be closer to the print bed.
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
opengrid_snap_to_edge_offset = (tile_size - 24.8) / 2;

ochead_bottom_height = 0.6;
ochead_top_height = 0.6;
ochead_middle_height = 1.4;
ochead_large_rect_width = 17; //0.1
ochead_large_rect_height = 11.2; //0.1

ochead_nub_to_top_distance = 7.2;
ochead_nub_depth = 0.6;
ochead_nub_tip_height = 1.2;
ochead_nub_inner_fillet = 0.6;
ochead_nub_outer_fillet = 0.8;

ochead_large_rect_chamfer = 4;
ochead_small_rect_width = ochead_large_rect_width - ochead_middle_height * 2;
ochead_small_rect_height = ochead_large_rect_height - ochead_middle_height;
ochead_small_rect_chamfer = ochead_large_rect_chamfer - ochead_middle_height + ang_adj_to_opp(45 / 2, ochead_middle_height);

ochead_bottom_profile = back(ochead_large_rect_width / 2, rect([ochead_large_rect_width, ochead_large_rect_height], chamfer=[ochead_large_rect_chamfer, ochead_large_rect_chamfer, 0, 0], anchor=BACK));
ochead_top_profile = back(ochead_small_rect_width / 2, rect([ochead_small_rect_width, ochead_small_rect_height], chamfer=[ochead_small_rect_chamfer, ochead_small_rect_chamfer, 0, 0], anchor=BACK));
ochead_total_height = ochead_top_height + ochead_middle_height + ochead_bottom_height;
ochead_middle_to_bottom = ochead_large_rect_height - ochead_large_rect_width / 2;

ochead_side_profile = [
  [0, 0],
  [ochead_large_rect_width / 2, 0],
  [ochead_large_rect_width / 2, ochead_bottom_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height + ochead_top_height],
  [0, ochead_bottom_height + ochead_middle_height + ochead_top_height],
];


ocslot_move_distance = 11; //0.1
ocslot_onramp_clearance = 0.8;
ocslot_bridge_offset = 0.4;
ocslot_side_clearance = 0.15;
ocslot_depth_clearance = 0.12;

ocslot_bottom_height = ochead_bottom_height + ang_adj_to_opp(45 / 2, ocslot_side_clearance) + ocslot_depth_clearance;
ocslot_top_height = ochead_top_height - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_total_height = ocslot_top_height + ochead_middle_height + ocslot_bottom_height;
ocslot_nub_to_top_distance = ochead_nub_to_top_distance + ocslot_side_clearance * 1.5;

ocslot_small_rect_width = ochead_small_rect_width + ocslot_side_clearance * 2;
ocslot_small_rect_height = ochead_small_rect_height + ocslot_side_clearance * 2;
ocslot_small_rect_chamfer = ochead_small_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_large_rect_width = ochead_large_rect_width + ocslot_side_clearance * 2;
ocslot_large_rect_height = ochead_large_rect_height + ocslot_side_clearance * 2;
ocslot_large_rect_chamfer = ochead_large_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_middle_to_bottom = ocslot_large_rect_height - ocslot_large_rect_width / 2;
ocslot_top_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width, ocslot_small_rect_height], chamfer=[ocslot_small_rect_chamfer, ocslot_small_rect_chamfer, 0, 0], anchor=BACK));
ocslot_bottom_profile = back(ocslot_large_rect_width / 2, rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));

ocslot_side_profile = [
  [0, 0],
  [ocslot_large_rect_width / 2, 0],
  [ocslot_large_rect_width / 2, ocslot_bottom_height],
  [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height],
  [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height + ocslot_top_height],
  [0, ocslot_bottom_height + ochead_middle_height + ocslot_top_height],
];

vase_linewidth = 0.6;
vase_wall_thickness = vase_linewidth * 2;
vase_tilt_offset_angle = 0;

ocvase_small_rect_width = ocslot_small_rect_width + vase_wall_thickness * 2;
ocvase_small_rect_height = ocslot_small_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + vase_tilt_offset_angle, ocslot_total_height);
ocvase_small_rect_chamfer = ocslot_small_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_large_rect_width = ocslot_large_rect_width + vase_wall_thickness * 2;
ocvase_large_rect_height = ocslot_large_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + vase_tilt_offset_angle, ocslot_total_height);
ocvase_large_rect_chamfer = ocslot_large_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_middle_to_bottom = ocvase_large_rect_height - ocvase_large_rect_width / 2;

ocvase_nub_to_top_distance = ocslot_nub_to_top_distance + vase_wall_thickness * 1.5;
ocvase_bottom_height = ocslot_bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_top_height = ocslot_top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_total_height = ocvase_top_height + ochead_middle_height + ocvase_bottom_height;
ocvase_top_profile = back(ocvase_small_rect_width / 2, rect([ocvase_small_rect_width, ocvase_small_rect_height], chamfer=[ocvase_small_rect_chamfer, ocvase_small_rect_chamfer, 0, 0], anchor=BACK));
ocvase_bottom_profile = back(ocvase_large_rect_width / 2, rect([ocvase_large_rect_width, ocvase_large_rect_height], chamfer=[ocvase_large_rect_chamfer, ocvase_large_rect_chamfer, 0, 0], anchor=BACK));

//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = "both", nub_flattop = true, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : head_type == "vase" ? ocvase_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : head_type == "vase" ? ocvase_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : head_type == "vase" ? ocvase_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : head_type == "vase" ? ocvase_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : head_type == "vase" ? ocvase_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : head_type == "vase" ? ocvase_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : head_type == "vase" ? ocvase_nub_to_top_distance : ochead_nub_to_top_distance;
  nub_angle = nub_taperin ? adj_opp_to_ang(ochead_middle_height, ochead_middle_height - ochead_nub_depth) : 0;
  total_height = bottom_height + top_height + ochead_middle_height;

  attachable(anchor, spin, orient, size=[large_rect_width, large_rect_width, total_height]) {
    tag_scope() down(total_height / 2) difference() {
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
              left(large_rect_width / 2 + size_offset - ochead_nub_depth + eps) zrot(-90) {
                  linear_extrude(bottom_height) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                  up(bottom_height) linear_extrude(1 / cos(nub_angle) * ochead_middle_height, v=[0, tan(nub_angle), 1]) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                }
            if (add_nubs == "right" || add_nubs == "both")
              right(large_rect_width / 2 + size_offset - ochead_nub_depth + eps) zrot(90) {
                  linear_extrude(bottom_height) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                  up(bottom_height) linear_extrude(1 / cos(nub_angle) * ochead_middle_height, v=[0, tan(nub_angle), 1]) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                }
          }
        }
    children();
  }
}
module openconnect_slot(add_nubs = "left", slot_direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_width, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) union() {
          if (slot_direction_flip)
            xflip() ocslot_body(excess_thickness);
          else
            ocslot_body(excess_thickness);
        }
    children();
  }
  module ocslot_body(excess_thickness = 0) {
    ocslot_side_excess_profile = [
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
      xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_excess_profile);
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
module openconnect_vase_slot(add_nubs = "", anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocvase_large_rect_width, ocvase_large_rect_width, ocvase_total_height]) {
    tag_scope()
      diff(remove="remove")
        down(ocvase_total_height / 2) {
          tag("") openconnect_head(head_type="vase", add_nubs=add_nubs, nub_flattop=false);
          tag("remove") openconnect_head(head_type="slot", add_nubs=add_nubs, nub_flattop=false);
          tag("remove") cuboid([ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ocslot_large_rect_height, ocslot_total_height], anchor=FRONT + BOTTOM);
          fwd(ocvase_middle_to_bottom) xrot(-(45 + vase_tilt_offset_angle))
              tag("remove") cuboid([ocvase_large_rect_width + eps, 20, 20], anchor=BACK + BOTTOM);
          xrot(90) up(ocslot_middle_to_bottom)
              force_tag("remove") linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_profile);
          up(ocslot_total_height)
            tag("remove") cuboid([50, 50, 50], anchor=BOTTOM);
        }
    children();
  }
}
module openconnect_slot_grid(grid_type = "slot", horizontal_grids = 1, vertical_grids = 1, tile_size = 28, slot_lock_distribution = "None", slot_direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  grid_height = grid_type == "slot" ? ocslot_total_height : ocvase_total_height;
  attachable(anchor, spin, orient, size=[horizontal_grids * tile_size, vertical_grids * tile_size, grid_height]) {
    tag_scope() hide_this() cuboid([horizontal_grids * tile_size, vertical_grids * tile_size, grid_height]) {
          back(opengrid_snap_to_edge_offset) {
            if (slot_lock_distribution == "All" || slot_lock_distribution == "Staggered" || slot_lock_distribution == "None")
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger=slot_lock_distribution == "Staggered")
                attach(BOTTOM, BOTTOM, inside=true) {
                  if (grid_type == "slot")
                    openconnect_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? "left" : "", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                  else
                    openconnect_vase_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? "left" : "");
                }
            if (slot_lock_distribution == "Staggered")
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger="alt")
                attach(BOTTOM, BOTTOM, inside=true) {
                  if (grid_type == "slot")
                    openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                  else
                    openconnect_vase_slot(add_nubs="left");
                }
            if (slot_lock_distribution == "Corners" || slot_lock_distribution == "Top Corners") {
              if (slot_lock_distribution == "Corners")
                grid_copies([tile_size * max(1, horizontal_grids - 1), tile_size * max(1, vertical_grids - 1)], [min(horizontal_grids, 2), min(vertical_grids, 2)])
                  attach(BOTTOM, BOTTOM, inside=true) {
                    if (grid_type == "slot")
                      openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                    else
                      openconnect_vase_slot(add_nubs="left");
                  }
              else {
                back(tile_size * (vertical_grids - 1) / 2)
                  line_copies(spacing=tile_size * max(1, horizontal_grids - 1), n=min(2, horizontal_grids))
                    attach(BOTTOM, BOTTOM, inside=true) {
                      if (grid_type == "slot")
                        openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                      else
                        openconnect_vase_slot(add_nubs="left");
                    }
              }
              omit_edge_rows =
                slot_lock_distribution == "Corners" ? [0, vertical_grids - 1]
                : slot_lock_distribution == "Top Corners" ? [0] : [];
              for (i = [0:1:vertical_grids - 1]) {
                back(tile_size * (vertical_grids - 1) / 2) fwd(tile_size * i) {
                    if (in_list(i, omit_edge_rows)) {
                      if (horizontal_grids > 2)
                        line_copies(spacing=tile_size, n=horizontal_grids - 2)
                          attach(BOTTOM, BOTTOM, inside=true) {
                            if (grid_type == "slot")
                              openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                            else
                              openconnect_vase_slot(add_nubs="left");
                          }
                    }
                    else
                      line_copies(spacing=tile_size, n=horizontal_grids)
                        attach(BOTTOM, BOTTOM, inside=true) {
                          if (grid_type == "slot")
                            openconnect_slot(add_nubs="", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                          else
                            openconnect_vase_slot(add_nubs="");
                        }
                  }
              }
            }
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
        tag("rm0") openconnect_slot_grid(horizontal_grids=horizontal_grids, vertical_grids=vertical_grids, tile_size=tile_size, slot_lock_distribution=slot_lock_distribution, slot_direction_flip=slot_direction_flip, excess_thickness=0);
    }
    //path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1], caps=[true, os_circle(r=tip_rounding_radius)]);
    //makerworld doesn't support newest path_sweep caps yet so it has to be done the old way.
    tag("kp1") up(hook_width / 2) fwd(stem_first_height - hook_thickness / 2 * (1 - ( (1 - hook_thickness_scale) * path_first_ratio))) {
          path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1])
            attach("end", "top")
              offset_sweep(offset_sweep_profile, height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius), spin=180, $fn=128);
        }
  }
