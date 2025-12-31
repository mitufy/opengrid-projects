/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Main Settings] */
//"Both" is the strongest and most stable, but "Bottom" or "Top" can still hold decent weight as the model is printed on its side.
shelf_mounting_slot_type = "Both"; //["Both", "Bottom","Top"]

horizontal_grids = 3;
//As depth is not restrained by grid, this is just a convenient way to increment value by 28mm. You can override it by enabling "use_custom_depth" below.
depth_grids = 3;

//Not recommended to set back_thickness lower than 3.2.
shelf_back_thickness = 3.6;
shelf_bottom_thickness = 2.1;

add_texture = true;

//0.7 means truss would cover 70% of shelf depth.
truss_depth_ratio = 0.7; //[0.0:0.05:1]
truss_thickness = 2.1;
truss_rounding = 3; //0.2

/* [Shelf Edge Settings] */
add_left_edge = true;
add_right_edge = true;
shelf_side_edge_height = 2;
shelf_side_edge_thickness = 0.8;

add_front_edge = true;
shelf_front_edge_height = 2;
shelf_front_edge_thickness = 0.8;

rough_texture_depth = 0.2;
rough_texture_size = 10;

/* [Advanced Settings] */
//'Staggered' means every other slot. Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Staggered"; //["Staggered","All", "None"]
//Slot entry direction can matter when installing in very tight space. Note when printing, the side with locking mechanism should be closer to print bed.
slot_direction_flip = false;
use_custom_depth = false;
custom_depth = 80;

/* [Hidden] */
top_vertical_grids = 1;
bottom_vertical_grids = 1;
//Side edge angle is capped at 45 to avoid sharp overhang.
shelf_side_edge_angle = 45; //[15:15:45]
shelf_front_edge_angle = 45; //[15:15:90]
//Inner_corner_rounding needs to be at least 4 to have effect.
shelf_inner_corner_rounding = 0;

$fa = 1;
$fs = 0.4;
eps = 0.005;

tile_size = 28;

shelf_depth = use_custom_depth ? custom_depth : tile_size * depth_grids;
shelf_width = tile_size * horizontal_grids;
bottom_shelf_back_height = tile_size * bottom_vertical_grids;
top_shelf_back_height = tile_size * top_vertical_grids;

top_sweep_startend_offset = 2;
top_sweep_rect_height = min(shelf_back_thickness, shelf_bottom_thickness);
final_shelf_inner_corner_rounding = shelf_inner_corner_rounding < 4 ? 0 : min(top_shelf_back_height, shelf_depth, shelf_inner_corner_rounding);
top_sweep_path = ["setdir", -90, "move", top_sweep_startend_offset, "arcleft", final_shelf_inner_corner_rounding, 90, "move", top_sweep_startend_offset];
top_base_rect_2d = rect([top_sweep_rect_height, shelf_width], anchor=TOP + LEFT);
top_right_edge_2d = right(top_sweep_rect_height, zrot(-90, trapezoid(h=shelf_side_edge_height, w1=shelf_side_edge_thickness + shelf_side_edge_height, ang=[90, shelf_side_edge_angle], anchor=LEFT + BOTTOM)));
top_left_edge_2d = right(top_sweep_rect_height, fwd(shelf_width, zrot(-90, trapezoid(h=shelf_side_edge_height, w1=shelf_side_edge_thickness + shelf_side_edge_height, ang=[shelf_side_edge_angle, 90], anchor=RIGHT + BOTTOM))));
top_sweep_profile =
  !add_left_edge && !add_right_edge ? top_base_rect_2d
  : add_left_edge && add_right_edge ? union(top_base_rect_2d, top_left_edge_2d, top_right_edge_2d)
  : !add_left_edge ? union(top_base_rect_2d, top_right_edge_2d) : union(top_base_rect_2d, top_left_edge_2d);

truss_depth = truss_depth_ratio <= 0 ? 0 : (shelf_depth - shelf_back_thickness) * truss_depth_ratio;
truss_height = truss_depth_ratio <= 0 ? 0 : bottom_shelf_back_height - shelf_bottom_thickness;
truss_angle = truss_depth_ratio <= 0 ? 0 : adj_opp_to_ang(truss_depth, truss_height);
truss_inner_depth = truss_depth_ratio <= 0 ? 0 : truss_depth - ang_opp_to_hyp(truss_angle, truss_thickness);
truss_inner_height = truss_depth_ratio <= 0 ? 0 : truss_height - ang_adj_to_hyp(truss_angle, truss_thickness);

diff(remove="outer_rm") cuboid([shelf_depth, shelf_bottom_thickness, shelf_width], anchor=FRONT + LEFT + BOTTOM) {
    rough_wall_alignment =
      add_left_edge == add_right_edge ? CENTER
      : add_right_edge ? BOTTOM : TOP;
    rough_wall_width_offset = (add_left_edge ? shelf_side_edge_height + shelf_side_edge_thickness : 0) + (add_right_edge ? shelf_side_edge_height + shelf_side_edge_thickness : 0);
    if (add_texture)
      attach(BACK, BOTTOM, align=rough_wall_alignment)
        textured_tile("rough", w1=shelf_depth, w2=shelf_depth, ysize=shelf_width - rough_wall_width_offset, tex_depth=rough_texture_depth, tex_size=[rough_texture_size, rough_texture_size], style="min_edge");
    if (add_right_edge)
      tag("") edge_profile([TOP + BACK], excess=0)
          back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_height)))
            yflip()
              mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_height], mask_angle=shelf_side_edge_angle, spin=90);
    if (add_left_edge)
      tag("") edge_profile([BOTTOM + BACK], excess=0)
          back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_height)))
            yflip()
              mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_height], mask_angle=shelf_side_edge_angle, spin=90);
    if (add_front_edge)
      tag("") edge_profile([BACK + RIGHT], excess=0)
          right(shelf_front_edge_thickness + (shelf_front_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_front_edge_angle, shelf_front_edge_height)))
            mask2d_rabbet(size=[shelf_front_edge_thickness, shelf_front_edge_height], mask_angle=shelf_front_edge_angle, spin=180);

    if (shelf_mounting_slot_type != "Top") {
      //bottom shelf back
      back(shelf_bottom_thickness)
        diff()
          attach(FRONT, BACK, align=LEFT)
            cuboid([shelf_back_thickness, bottom_shelf_back_height, shelf_width]) {
              if (shelf_mounting_slot_type == "Bottom")
                attach(LEFT, TOP, inside=true, spin=90)
                  tag("remove") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=bottom_vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
            }
      if (truss_inner_depth <= 0 || truss_inner_height <= 0)
        right(shelf_back_thickness) edge_mask(LEFT + FRONT)
            tag("") rounding_edge_mask(r=min(truss_thickness * 3, tile_size - shelf_bottom_thickness), spin=-90);
      //buttom shelf truss
      if (truss_depth_ratio > 0) {
        if (truss_inner_depth > 0 && truss_inner_height > 0) {
          truss_profile = difference(
            right_triangle([truss_depth, truss_height]),
            round_corners(joint=min(truss_rounding, truss_inner_depth / 2 - eps, truss_inner_height / 2 - eps), path=right_triangle([truss_inner_depth, truss_inner_height]))
          );
          right(shelf_back_thickness) xflip()
              attach(FRONT, FRONT, align=RIGHT)
                linear_sweep(truss_profile, shelf_width) {
                  if (truss_depth_ratio < 1)
                    edge_mask([RIGHT + FRONT])
                      tag("") rounding_edge_mask(r=min(20, (shelf_depth - shelf_back_thickness) * (1 - truss_depth_ratio)), h=shelf_width, ang=180 - truss_angle, spin=truss_angle);
                }
        }
      }
    }
    if (shelf_mounting_slot_type != "Bottom") {
      //top shelf corner filler
      if (final_shelf_inner_corner_rounding > eps)
        tag_diff(tag="", remove="remove") {
          attach(BACK, FRONT, align=LEFT, inset=shelf_back_thickness)
            cuboid([final_shelf_inner_corner_rounding, final_shelf_inner_corner_rounding, shelf_width])
              back(final_shelf_inner_corner_rounding / 2 - shelf_bottom_thickness / 2) right(final_shelf_inner_corner_rounding / 2 - shelf_back_thickness / 2)
                  tag("remove") cyl(r=final_shelf_inner_corner_rounding, h=shelf_width + eps * 2);
        }
      //top shelf back
      fwd(shelf_mounting_slot_type == "Both" ? 0 : shelf_bottom_thickness)
        tag_diff(tag="", remove="remove") attach(BACK, FRONT, align=LEFT)
            cuboid([shelf_back_thickness, top_shelf_back_height, shelf_width]) {
              if (add_texture)
                attach(RIGHT, BOTTOM, align=rough_wall_alignment)
                  textured_tile("rough", w1=top_shelf_back_height, w2=top_shelf_back_height, ysize=shelf_width - rough_wall_width_offset, tex_depth=rough_texture_depth, tex_size=[rough_texture_size, rough_texture_size], style="min_edge");
              if (add_right_edge)
                edge_profile([TOP + RIGHT], excess=0)
                  back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_height)))
                    yflip()
                      tag("") mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_height], mask_angle=shelf_side_edge_angle, spin=90);
              if (add_left_edge)
                edge_profile([BOTTOM + RIGHT], excess=0)
                  back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_height)))
                    yflip()
                      tag("") mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_height], mask_angle=shelf_side_edge_angle, spin=90);
              if (final_shelf_inner_corner_rounding > eps)
                right(max(0, shelf_back_thickness - shelf_bottom_thickness)) back(max(0, shelf_bottom_thickness - shelf_back_thickness)) fwd(shelf_mounting_slot_type == "Both" ? shelf_bottom_thickness : 0) fwd(top_shelf_back_height - final_shelf_inner_corner_rounding - top_sweep_startend_offset)
                        attach(BACK + LEFT, BACK + LEFT, inside=true)
                          tag("") path_sweep(top_sweep_profile, path=path_merge_collinear(turtle(top_sweep_path)), scale=[1, 1], $fn=128);
              if (shelf_mounting_slot_type == "Top")
                attach(LEFT, TOP, inside=true, spin=90)
                  tag("remove") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=top_vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
            }
    }
    if (shelf_mounting_slot_type == "Both") {
      back(shelf_bottom_thickness / 2) right(shelf_back_thickness)
          tag("outer_rm") attach(LEFT, RIGHT)
              hide_this() cuboid([shelf_back_thickness, top_shelf_back_height + bottom_shelf_back_height, shelf_width])
                  attach(LEFT, TOP, align=FRONT, inside=true, spin=90)
                    openconnect_slot_grid(h_grid=horizontal_grids, v_grid=shelf_mounting_slot_type == "Both" ? top_vertical_grids + bottom_vertical_grids : top_vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
    }
  }

//BEGIN openConnect slot parameters

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
