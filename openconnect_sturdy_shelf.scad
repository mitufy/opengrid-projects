/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Main Settings] */
slot_lock_distribution = "All"; //["Staggered","All", "None"]
slot_direction_flip = false;

shelf_mounting_slot_position = "Bottom"; //["Bottom","Top", "Both"]

horizontal_grids = 3;
//As depth is not restrained by grid, this is just a convenient way to increment value by 28mm. You can override it by enabling "use_custom_depth" below.
depth_grids = 3;

shelf_back_thickness = 3.6;
shelf_bottom_thickness = 2.1;

vertical_grids = 1;
top_shelf_corner_rounding = 16;

/* [Shelf Edge Settings] */
add_left_edge = true;
add_right_edge = true;
add_front_edge = true;
shelf_side_edge_chamfer_thickness = 2;
shelf_side_edge_wall_thickness = 0.8;
//Side edge angle is capped at 45 to avoid sharp overhang.
shelf_side_edge_angle = 45; //[15:15:45]

shelf_front_edge_chamfer_thickness = 2;
shelf_front_edge_wall_thickness = 0.8;
shelf_front_edge_angle = 45; //[15:15:90]

truss_thickness = 2.1;
truss_rounding = 3; //0.2
truss_depth_ratio = 0.7; //[0.0:0.05:1]

/* [Advanced Settings] */
use_custom_depth = false;
custom_depth = 80;

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

tile_size = 28;

shelf_depth = use_custom_depth ? custom_depth : tile_size * depth_grids;
shelf_width = tile_size * horizontal_grids;
bottom_shelf_back_height = tile_size;
top_shelf_back_height = tile_size * vertical_grids;

top_sweep_start_offset = 1;
top_sweep_right_offset = 0.05;
final_top_shelf_corner_rounding = min(top_shelf_back_height, shelf_depth, top_shelf_corner_rounding) - top_sweep_start_offset;
top_sweep_rect_height = min(shelf_back_thickness, shelf_bottom_thickness) - top_sweep_right_offset;

top_sweep_path = ["setdir", -90, "move", top_sweep_start_offset, "arcleft", final_top_shelf_corner_rounding, 90, "move", top_sweep_start_offset];
top_base_rect_2d = rect([top_sweep_rect_height, shelf_width], anchor=TOP + LEFT);
top_right_edge_2d = right(top_sweep_rect_height, zrot(-90, trapezoid(h=shelf_side_edge_chamfer_thickness, w1=shelf_side_edge_wall_thickness + shelf_side_edge_chamfer_thickness, ang=[90, shelf_side_edge_angle], anchor=LEFT + BOTTOM)));
top_left_edge_2d = right(top_sweep_rect_height, fwd(shelf_width, zrot(-90, trapezoid(h=shelf_side_edge_chamfer_thickness, w1=shelf_side_edge_wall_thickness + shelf_side_edge_chamfer_thickness, ang=[shelf_side_edge_angle, 90], anchor=RIGHT + BOTTOM))));
top_sweep_profile =
  !add_left_edge && !add_right_edge ? top_base_rect_2d
  : add_left_edge && add_right_edge ? union(top_base_rect_2d, top_left_edge_2d, top_right_edge_2d)
  : !add_left_edge ? union(top_base_rect_2d, top_right_edge_2d) : union(top_base_rect_2d, top_left_edge_2d);

truss_depth = truss_depth_ratio <= 0 ? 0 : (shelf_depth - shelf_back_thickness) * truss_depth_ratio;
truss_height = truss_depth_ratio <= 0 ? 0 : tile_size - shelf_bottom_thickness;
truss_angle = truss_depth_ratio <= 0 ? 0 : adj_opp_to_ang(truss_depth, truss_height);
truss_inner_depth = truss_depth_ratio <= 0 ? 0 : truss_depth - ang_opp_to_hyp(truss_angle, truss_thickness);
truss_inner_height = truss_depth_ratio <= 0 ? 0 : truss_height - ang_adj_to_hyp(truss_angle, truss_thickness);

cuboid([shelf_depth, shelf_bottom_thickness, shelf_width], anchor=FRONT + LEFT + BOTTOM) {
  if (add_right_edge)
    tag("") edge_profile([TOP + BACK], excess=0)
        back(shelf_side_edge_wall_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_chamfer_thickness)))
          yflip()
            mask2d_rabbet(size=[shelf_side_edge_wall_thickness, shelf_side_edge_chamfer_thickness], mask_angle=shelf_side_edge_angle, spin=90);
  if (add_left_edge)
    tag("") edge_profile([BOTTOM + BACK], excess=0)
        back(shelf_side_edge_wall_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_chamfer_thickness)))
          yflip()
            mask2d_rabbet(size=[shelf_side_edge_wall_thickness, shelf_side_edge_chamfer_thickness], mask_angle=shelf_side_edge_angle, spin=90);
  if (add_front_edge)
    tag("") edge_profile([BACK + RIGHT], excess=0)
        right(shelf_front_edge_wall_thickness + (shelf_front_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_front_edge_angle, shelf_front_edge_chamfer_thickness)))
          mask2d_rabbet(size=[shelf_front_edge_wall_thickness, shelf_front_edge_chamfer_thickness], mask_angle=shelf_front_edge_angle, spin=180);

  if (shelf_mounting_slot_position != "Top") {
    //bottom shelf back
    back(shelf_bottom_thickness)
      diff()
        attach(FRONT, BACK, align=LEFT)
          cuboid([shelf_back_thickness, tile_size, shelf_width]) {
            attach(LEFT, TOP, inside=true, spin=90)
              tag("remove") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=1, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
          }
    if (truss_inner_depth <= 0 || truss_inner_height <= 0)
      right(shelf_back_thickness) edge_mask(LEFT + FRONT)
          tag("") rounding_edge_mask(r=min(truss_thickness * 3, tile_size - shelf_bottom_thickness), spin=-90);
    //buttom shelf truss
    if (truss_depth_ratio > 0) {
      if (truss_inner_depth > 0 && truss_inner_height > 0) {
        truss_profile = difference(
          right_triangle([truss_depth, truss_height]),
          round_corners(joint=min(truss_rounding, truss_inner_depth / 2 - eps, truss_inner_height / 2 - eps), path=right_triangle([truss_inner_depth, truss_inner_height]), $fn=128)
        );
        right(shelf_back_thickness) xflip()
            attach(FRONT, FRONT, align=RIGHT)
              linear_sweep(truss_profile, shelf_width) {
                if (truss_depth_ratio < 1)
                  edge_mask([RIGHT + FRONT])
                    tag("") rounding_edge_mask(r=min(20, (shelf_depth - shelf_back_thickness) * (1 - truss_depth_ratio)), h=shelf_width, ang=180 - truss_angle, spin=truss_angle, $fn=128);
              }
      }
    }
  }
  if (shelf_mounting_slot_position != "Bottom") {
    //top shelf corner filler
    tag_diff(tag="", remove="remove") {
      attach(BACK, FRONT, align=LEFT, inset=shelf_back_thickness)
        cuboid([final_top_shelf_corner_rounding, final_top_shelf_corner_rounding, shelf_width])
          back(final_top_shelf_corner_rounding / 2 - shelf_bottom_thickness / 2) right(final_top_shelf_corner_rounding / 2 - shelf_back_thickness / 2)
              tag("remove") cyl(r=final_top_shelf_corner_rounding, h=shelf_width + eps*2);
    }
    //top shelf back
    fwd(shelf_mounting_slot_position == "Both" ? 0 : shelf_bottom_thickness)
      diff() attach(BACK, FRONT, align=LEFT)
          cuboid([shelf_back_thickness, top_shelf_back_height, shelf_width]) {
            if (add_right_edge)
              edge_profile([TOP + RIGHT], excess=0)
                back(shelf_side_edge_wall_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_chamfer_thickness)))
                  yflip()
                    tag("") mask2d_rabbet(size=[shelf_side_edge_wall_thickness, shelf_side_edge_chamfer_thickness], mask_angle=shelf_side_edge_angle, spin=90);
            if (add_left_edge)
              edge_profile([BOTTOM + RIGHT], excess=0)
                back(shelf_side_edge_wall_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_chamfer_thickness)))
                  yflip()
                    tag("") mask2d_rabbet(size=[shelf_side_edge_wall_thickness, shelf_side_edge_chamfer_thickness], mask_angle=shelf_side_edge_angle, spin=90);
            right(top_sweep_right_offset) fwd(shelf_mounting_slot_position == "Both" ? shelf_bottom_thickness : 0) fwd(top_shelf_back_height - final_top_shelf_corner_rounding - top_sweep_start_offset)
                  attach(BACK + LEFT, BACK + LEFT, inside=true)
                    tag("") path_sweep(top_sweep_profile, path=path_merge_collinear(turtle(top_sweep_path)), scale=[1, 1]);
            attach(LEFT, TOP, inside=true, spin=90)
              tag("remove") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
          }
  }
}

//BEGIN openConnect slot parameters
openconnect_head_bottom_height = 0.4;
openconnect_head_bottom_chamfer = 0;
openconnect_head_top_height = 0.6;
openconnect_middle_height = 1.6;
openconnect_head_large_rect_width = 17; //0.1
openconnect_head_large_rect_height = 11.2; //0.1

openconnect_head_nub_to_top_distance = 7.2;
openconnect_lock_nub_depth = 0.4;
openconnect_lock_nub_tip_height = 1;
openconnect_lock_nub_inner_fillet = 0.2;
openconnect_lock_nub_outer_fillet = 0.8;

openconnect_head_large_rect_chamfer = 4;
openconnect_head_small_rect_width = openconnect_head_large_rect_width - openconnect_middle_height * 2;
openconnect_head_small_rect_height = openconnect_head_large_rect_height - openconnect_middle_height;
openconnect_head_small_rect_chamfer = openconnect_head_large_rect_chamfer - openconnect_middle_height + ang_adj_to_opp(45 / 2, openconnect_middle_height);

openconnect_slot_move_distance = 11; //0.1
openconnect_slot_onramp_clearance = 0.8;
openconnect_slot_bridge_offset = 0.4;
openconnect_slot_side_clearance = 0.18;
openconnect_slot_depth_clearance = 0.12;

openconnect_head_bottom_profile = back(openconnect_head_large_rect_width / 2, rect([openconnect_head_large_rect_width, openconnect_head_large_rect_height], chamfer=[openconnect_head_large_rect_chamfer, openconnect_head_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_top_profile = back(openconnect_head_small_rect_width / 2, rect([openconnect_head_small_rect_width, openconnect_head_small_rect_height], chamfer=[openconnect_head_small_rect_chamfer, openconnect_head_small_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_total_height = openconnect_head_top_height + openconnect_middle_height + openconnect_head_bottom_height;
openconnect_head_middle_to_bottom = openconnect_head_large_rect_height - openconnect_head_large_rect_width / 2;

openconnect_slot_bottom_height = openconnect_head_bottom_height + ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance) + openconnect_slot_depth_clearance;
openconnect_slot_top_height = openconnect_head_top_height - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_total_height = openconnect_slot_top_height + openconnect_middle_height + openconnect_slot_bottom_height;
openconnect_slot_nub_to_top_distance = openconnect_head_nub_to_top_distance + openconnect_slot_side_clearance;

openconnect_slot_small_rect_width = openconnect_head_small_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_height = openconnect_head_small_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_chamfer = openconnect_head_small_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_large_rect_width = openconnect_head_large_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_height = openconnect_head_large_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_chamfer = openconnect_head_large_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_middle_to_bottom = openconnect_slot_large_rect_height - openconnect_slot_large_rect_width / 2;
openconnect_slot_to_grid_top_offset = (tile_size - 24.8) / 2;
openconnect_slot_top_profile = back(openconnect_slot_small_rect_width / 2, rect([openconnect_slot_small_rect_width, openconnect_slot_small_rect_height], chamfer=[openconnect_slot_small_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_slot_bottom_profile = back(openconnect_slot_large_rect_width / 2, rect([openconnect_slot_large_rect_width, openconnect_slot_large_rect_height], chamfer=[openconnect_slot_large_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=BACK));

openconnect_head_side_profile = [
  [0, 0],
  [openconnect_head_large_rect_width / 2 - openconnect_head_bottom_chamfer, 0],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_chamfer],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_middle_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_middle_height + openconnect_head_top_height],
  [0, openconnect_head_bottom_height + openconnect_middle_height + openconnect_head_top_height],
];
//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = 2, excess_thickness = 0, size_offset = 0) {
  bottom_profile = head_type == "slot" ? openconnect_slot_bottom_profile : head_type == "vase" ? openconnect_vase_bottom_profile : openconnect_head_bottom_profile;
  top_profile = head_type == "slot" ? openconnect_slot_top_profile : head_type == "vase" ? openconnect_vase_top_profile : openconnect_head_top_profile;
  bottom_height = head_type == "slot" ? openconnect_slot_bottom_height : head_type == "vase" ? openconnect_vase_bottom_height : openconnect_head_bottom_height;
  top_height = head_type == "slot" ? openconnect_slot_top_height : head_type == "vase" ? openconnect_vase_top_height : openconnect_head_top_height;
  large_rect_width = head_type == "slot" ? openconnect_slot_large_rect_width : head_type == "vase" ? openconnect_vase_large_rect_width : openconnect_head_large_rect_width;
  large_rect_height = head_type == "slot" ? openconnect_slot_large_rect_height : head_type == "vase" ? openconnect_vase_large_rect_height : openconnect_head_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? openconnect_slot_nub_to_top_distance : head_type == "vase" ? openconnect_vase_nub_to_top_distance : openconnect_head_nub_to_top_distance;

  difference() {
    union() {
      linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
      up(bottom_height - eps) hull() {
          up(openconnect_middle_height) linear_extrude(h=eps) polygon(offset(top_profile, delta=size_offset));
          linear_extrude(h=eps) polygon(offset(bottom_profile, delta=size_offset));
        }
      if (top_height + excess_thickness > 0)
        up(bottom_height + openconnect_middle_height - eps)
          linear_extrude(h=top_height + excess_thickness + eps) polygon(offset(top_profile, delta=size_offset));
    }
    back(large_rect_width / 2 - nub_to_top_distance)
      rot_copies([90, 0, 0], n=add_nubs)
        left(large_rect_width / 2 + size_offset - openconnect_lock_nub_depth / 2 + eps) zrot(-90)
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
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_middle_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_middle_height + openconnect_slot_top_height + excess_thickness],
      [0, openconnect_slot_bottom_height + openconnect_middle_height + openconnect_slot_top_height + excess_thickness],
    ];
    openconnect_slot_bridge_offset_profile = back(openconnect_slot_small_rect_width / 2, rect([openconnect_slot_small_rect_width / 2 + openconnect_slot_bridge_offset, openconnect_slot_small_rect_height + openconnect_slot_move_distance + openconnect_slot_onramp_clearance], chamfer=[openconnect_slot_small_rect_chamfer + openconnect_slot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(head_type="slot", add_nubs=add_nubs ? 1 : 0, excess_thickness=excess_thickness);
      xrot(90) linear_extrude(openconnect_slot_middle_to_bottom + openconnect_slot_move_distance + openconnect_slot_onramp_clearance) xflip_copy() polygon(openconnect_slot_side_profile);
      up(openconnect_slot_bottom_height) linear_extrude(openconnect_slot_top_height + openconnect_middle_height) polygon(openconnect_slot_bridge_offset_profile);
      fwd(openconnect_slot_move_distance) {
        linear_extrude(openconnect_slot_bottom_height) onramp_2d();
        up(openconnect_slot_bottom_height)
          linear_extrude(openconnect_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(openconnect_middle_height) up(openconnect_slot_bottom_height + openconnect_middle_height)
            linear_extrude(openconnect_slot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(openconnect_slot_small_rect_chamfer) cuboid([openconnect_slot_small_rect_width, openconnect_slot_small_rect_height, openconnect_slot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=openconnect_slot_onramp_clearance)
        left(openconnect_slot_onramp_clearance + openconnect_middle_height) back(openconnect_slot_large_rect_width / 2) {
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
