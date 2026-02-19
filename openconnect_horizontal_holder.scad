/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's Underware_Item_Holder_Clamshell_Style: https://makerworld.com/en/models/783010-underware-2-0-infinite-cable-management
openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>

/* [Item Settings] */
//Dimensions of the item to be held. You can set values slightly higher for more wriggle room.
item_width = 190;
item_height = 60;
item_depth = 30;
//By increasing corner_rounding, it's possible to generate holders that are nearly circular.
item_corner_rounding = 5;

/* [Holder Settings] */
//Generate one part at a time makes it possible to customize each side differently. "Both" requires splitting and orientation adjustment in the slicer.
generate_holder_part = "Both"; //[Both, Left, Right]
//Maximum number of slot columns on each holder half.
holder_slot_column_limit = 2;
//"Top" for item facing down, "Front" for item facing its side. When using a large corner_rounding, "Front" may leave too little space for slots.
holder_slot_position = "Top"; //[Top, Front]
holder_thickness = 2.4;
//Edges surrounding the item. At least one of the edge sizes must be greater than 0 to prevent the item from falling out.
holder_width_edge = 8;
//Alternatively, you can set edge sizes to very large values, thus disable front cutoff completely.
holder_height_edge = 6;

/* [Cutoff Settings] */
//Cutting a hole in the side, useful for items such as power strips.
holder_side_cutoff = "Right"; //[None, Left, Right, Both]
//Using the four offset values below, the size and the position of the cutoff can be freely adjusted.
side_cutoff_front_offset = 15;
side_cutoff_back_offset = 15;
side_cutoff_top_offset = 0;
side_cutoff_bottom_offset = 0;

/* [openConnect Slot Settings] */
//Offsets the slot position. Increasing this helps if a large corner_rounding is cutting into the slot area.
slot_position_offset = 0;
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Slide and entry ramp direction can matter in tight spaces.
slot_slide_direction = "Left"; //[Left,Right]
slot_entryramp_flip = false;
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//A slot is generated for every tile by default.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Double Lock can be very difficult to install. They are intended for small models that only use one or two slots. 
slot_lock_side = "Left"; //[Left:Standard, Both:Double]
//Ensures minimum feature width for 3d printing. "Both" is default for compatibility, though only one (or none) may be needed depending on orientation.
slot_edge_feature_widen = "Top"; //[Both, Top, Side, None]

//BEGIN utility functions

// Returns true if a slot should be placed at grid position [hgrid, vgrid].
function is_slot_position(hgrid, vgrid, max_hgrid, max_vgrid, distri, except_pos = []) =
  let (
    is_exception = in_list([hgrid, vgrid], except_pos),
    is_stagger = hgrid % 2 == vgrid % 2,
    is_top_row = vgrid == 0,
    is_bottom_row = vgrid == max_vgrid - 1,
    is_left_column = hgrid == 0,
    is_right_column = hgrid == max_hgrid - 1,
    is_edge_row = is_top_row || is_bottom_row,
    is_edge_column = is_left_column || is_right_column,
    is_corner = is_edge_row && is_edge_column,
    is_top_corner = is_corner && is_top_row,
    is_bottom_corner = is_corner && is_bottom_row,
    matches_pattern = distri == "All" || (distri == "Staggered" && is_stagger) || (distri == "Corners" && is_corner) || (distri == "Top Corners" && is_top_corner) || (distri == "Bottom Corners" && is_bottom_corner) || (distri == "Edge Rows" && is_edge_row) || (distri == "Edge Columns" && is_edge_column)
  ) !is_exception && matches_pattern;

// Returns true if the slot footprint at center_point lies fully within limit_region.
function is_slot_in_region(center_point, slide_direction, limit_region) =
  let (
    slot_min_wall = 2,
    slot_rotate = slide_direction == "Left" ? 90
    : slide_direction == "Right" ? -90
    : slide_direction == "Down" ? 180 : 0,
    slot_rect = zrot(slot_rotate, fwd(ocslot_middle_to_bottom, rect([ocslot_large_rect_width + slot_min_wall * 2, ocslot_large_rect_width / 2 + ocslot_middle_to_bottom + slot_min_wall], chamfer=[ocslot_large_rect_chamfer + slot_min_wall - ang_adj_to_opp(45 / 2, slot_min_wall), ocslot_large_rect_chamfer + slot_min_wall - ang_adj_to_opp(45 / 2, slot_min_wall), 0, 0], anchor=FRONT))),
    result = [for (i = slot_rect) point_in_region(center_point + i, limit_region) == 1]
  ) !in_list(list=result, val=false);

// Conditionally flips children along the given axis. If copy=true, keep the original.
module conditional_flip(axis = "X", coordinate = 0, copy = false, condition) {
  if (condition) {
    if (axis == "X")
      xflip(x=coordinate) children();
    else if (axis == "Y")
      yflip(y=coordinate) children();
    else if (axis == "Z")
      zflip(z=coordinate) children();
    if (copy)
      children();
  }
  else
    children();
}

// Conditionally cuts children to the given half-space along v.
module conditional_half(v = LEFT, x = 0, obj_size = 300, condition) {
  if (condition) {
    if (v == LEFT)
      left_half(x=x, s=obj_size) children();
    else if (v == RIGHT)
      right_half(x=x, s=obj_size) children();
    else if (v == FRONT)
      front_half(x=x, s=obj_size) children();
    else if (v == BACK)
      back_half(x=x, s=obj_size) children();
    else if (v == TOP)
      top_half(x=x, s=obj_size) children();
    else if (v == BOTTOM)
      bottom_half(x=x, s=obj_size) children();
  }
  else
    children();
}
//END utility functions

//BEGIN openConnect slot parameters
tile_size = 28;
opengrid_snap_to_edge_offset = 0; // There was 1.6mm here. It's gone now.

ochead_bottom_height = 0.6;
ochead_top_height = 0.6;
ochead_middle_height = 1.4;
ochead_large_rect_width = 17; //0.1
ochead_large_rect_height = 10.6; //0.1

ochead_nub_to_top_distance = 7.2;
ochead_nub_depth = 0.6;
ochead_nub_tip_height = 1.2;
ochead_nub_inner_fillet = 0.6;
ochead_nub_outer_fillet = 0.8;

ochead_large_rect_chamfer = 4;
ochead_back_pos_offset = 0.4;
ochead_small_rect_width = ochead_large_rect_width - ochead_middle_height * 2;
ochead_small_rect_height = ochead_large_rect_height - ochead_middle_height;
ochead_small_rect_chamfer = ochead_large_rect_chamfer - ochead_middle_height + ang_adj_to_opp(45 / 2, ochead_middle_height);

ochead_bottom_profile = back(ochead_large_rect_width / 2 + ochead_back_pos_offset, rect([ochead_large_rect_width, ochead_large_rect_height], chamfer=[ochead_large_rect_chamfer, ochead_large_rect_chamfer, 0, 0], anchor=BACK));
ochead_top_profile = back(ochead_small_rect_width / 2 + ochead_back_pos_offset, rect([ochead_small_rect_width, ochead_small_rect_height], chamfer=[ochead_small_rect_chamfer, ochead_small_rect_chamfer, 0, 0], anchor=BACK));
ochead_total_height = ochead_top_height + ochead_middle_height + ochead_bottom_height;
ochead_middle_to_bottom = ochead_large_rect_height - ochead_large_rect_width / 2 - ochead_back_pos_offset;

//standard slot
ocslot_move_distance = 10.6; //0.1
ocslot_onramp_clearance = 0.8;
ocslot_edge_feature_widen = slot_edge_feature_widen;
ocslot_edge_bridge_min_width = slot_edge_bridge_min_width;
ocslot_edge_wall_min_width = slot_edge_wall_min_width;
ocslot_bottom_min_thickness = ocslot_edge_wall_min_width;
ocslot_side_clearance = slot_side_clearance;
ocslot_depth_clearance = slot_depth_clearance;

ocslot_bottom_height = ochead_bottom_height + ang_adj_to_opp(45 / 2, ocslot_side_clearance) + ocslot_depth_clearance;
ocslot_top_height = ochead_top_height - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_total_height = ocslot_top_height + ochead_middle_height + ocslot_bottom_height;
ocslot_nub_to_top_distance = ochead_nub_to_top_distance + ocslot_side_clearance;
ocslot_top_bridge_offset = ocslot_edge_feature_widen == "Both" || ocslot_edge_feature_widen == "Top" ? max(0, ocslot_edge_bridge_min_width - ocslot_top_height) : 0;
ocslot_side_bridge_offset = ocslot_edge_feature_widen == "Both" || ocslot_edge_feature_widen == "Side" ? max(0, ocslot_edge_bridge_min_width - ocslot_top_height) : 0;
ocslot_side_cliff_offset = ocslot_edge_feature_widen == "Both" || ocslot_edge_feature_widen == "Side" ? max(0, ocslot_edge_wall_min_width - ocslot_top_height) : 0;

ocslot_small_rect_width = ochead_small_rect_width + ocslot_side_clearance * 2;
ocslot_small_rect_height = ochead_small_rect_height + ocslot_side_clearance * 2;
ocslot_small_rect_chamfer = ochead_small_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_large_rect_width = ochead_large_rect_width + ocslot_side_clearance * 2;
ocslot_large_rect_height = ochead_large_rect_height + ocslot_side_clearance * 2;
ocslot_large_rect_chamfer = ochead_large_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_middle_to_bottom = ocslot_large_rect_height - ocslot_large_rect_width / 2 - ochead_back_pos_offset;
ocslot_top_profile = back(ocslot_small_rect_width / 2 + ochead_back_pos_offset, rect([ocslot_small_rect_width, ocslot_small_rect_height], chamfer=[ocslot_small_rect_chamfer, ocslot_small_rect_chamfer, 0, 0], anchor=BACK));
ocslot_bottom_profile = back(ocslot_large_rect_width / 2 + ochead_back_pos_offset, rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));

//vase slot
ocvase_linewidth = 0.6;
ocvase_wall_thickness = ocvase_linewidth * 2;
ocvase_bottom_height = ocslot_bottom_height + ang_adj_to_opp(45 / 2, ocvase_wall_thickness);
ocvase_top_height = ocslot_top_height - ang_adj_to_opp(45 / 2, ocvase_wall_thickness);
ocvase_sweep_profile_a = [
  [0, 0],
  [0, ocvase_bottom_height],
  [ochead_middle_height, ocvase_bottom_height + ochead_middle_height],
  [ochead_middle_height, ocslot_total_height],
  [ochead_middle_height + ocvase_wall_thickness, ocslot_total_height],
  [ochead_middle_height + ocvase_wall_thickness, ocslot_bottom_height + ochead_middle_height],
  [ocvase_wall_thickness, ocslot_bottom_height],
  [ocvase_wall_thickness, 0],
];
ocvase_sweep_profile_b = [
  [0, 0],
  [0, ocvase_bottom_height],
  [ocslot_total_height - ocvase_bottom_height, ocslot_total_height],
  [ochead_middle_height + ocvase_wall_thickness, ocslot_total_height],
  [ochead_middle_height + ocvase_wall_thickness, ocslot_bottom_height + ochead_middle_height],
  [ocvase_wall_thickness, ocslot_bottom_height],
  [ocvase_wall_thickness, 0],
];
ocvase_sweep_profile = ocslot_total_height - ocvase_bottom_height > ochead_middle_height ? ocvase_sweep_profile_a : ocvase_sweep_profile_b;
//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = "Both", nub_flattop = false, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : ochead_nub_to_top_distance;
  total_height = bottom_height + top_height + ochead_middle_height;
  nub_inset_right = head_type == "slot" ? ocslot_side_bridge_offset : 0;
  nub_angle_left = nub_taperin ? adj_opp_to_ang(ochead_middle_height, ochead_middle_height - ochead_nub_depth) : 0;
  nub_angle_right = nub_taperin && ochead_middle_height - ochead_nub_depth - nub_inset_right > 0 ? adj_opp_to_ang(ochead_middle_height - nub_inset_right, ochead_middle_height - ochead_nub_depth - nub_inset_right) : 0;
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
          back(large_rect_width / 2 - nub_to_top_distance + ochead_back_pos_offset) {
            if (add_nubs == "Left" || add_nubs == "Both")
              left(large_rect_width / 2 + size_offset + eps)
                openconnect_lock(bottom_height=bottom_height, middle_height=ochead_middle_height, nub_angle=nub_angle_left, nub_flattop=nub_flattop);
            if (add_nubs == "Right" || add_nubs == "Both")
              right(large_rect_width / 2 + size_offset + eps)
                xflip() openconnect_lock(bottom_height=bottom_height, middle_height=ochead_nub_depth, nub_angle=0, nub_flattop=nub_flattop);
          }
        }
    children();
  }
}
module openconnect_lock(bottom_height, middle_height, nub_angle = 0, nub_flattop = false) {
  right(ochead_nub_depth) zrot(-90) {
      linear_extrude(bottom_height)
        trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
      up(bottom_height)
        linear_extrude(v=[0, tan(nub_angle) * middle_height, middle_height])
          trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
    }
}
module openconnect_slot(add_nubs = "Left", slot_entryramp_flip = false, excess_thickness = eps, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[tile_size, tile_size, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) {
        if (slot_entryramp_flip)
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
    ocslot_bridge_offset_profile = right(ocslot_side_bridge_offset / 2 - ocslot_side_cliff_offset / 2, back(ocslot_small_rect_width / 2 + ochead_back_pos_offset + ocslot_top_bridge_offset, rect([ocslot_small_rect_width + ocslot_side_bridge_offset + ocslot_side_cliff_offset, ocslot_small_rect_height + ocslot_move_distance + ocslot_onramp_clearance + ocslot_top_bridge_offset], chamfer=[ocslot_small_rect_chamfer + ocslot_top_bridge_offset + ocslot_side_bridge_offset, ocslot_small_rect_chamfer + ocslot_top_bridge_offset + ocslot_side_cliff_offset, 0, 0], anchor=BACK)));
    difference() {
      union() {
        openconnect_head(head_type="slot", add_nubs=add_nubs, excess_thickness=excess_thickness);
        back(ochead_back_pos_offset) xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance + ochead_back_pos_offset) xflip_copy() polygon(ocslot_side_excess_profile);
        up(ocslot_bottom_height) linear_extrude(ocslot_top_height + ochead_middle_height + eps) polygon(ocslot_bridge_offset_profile);
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
      fwd(tile_size / 2)
        cuboid([tile_size, ocslot_bottom_min_thickness, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness + eps], anchor=FRONT + BOTTOM);
    }
  }
  module onramp_2d() {
    offset(delta=ocslot_onramp_clearance)
      left(ocslot_onramp_clearance + ochead_middle_height) back(ocslot_large_rect_width / 2 + ochead_back_pos_offset) {
          rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
          trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
        }
  }
}
module openconnect_vase_slot(add_nubs = "", overhang_angle = 45, anchor = BOTTOM, spin = 0, orient = UP) {
  straight_base_length = ocslot_large_rect_height - ocslot_large_rect_chamfer;
  straight_extra_length = tan(overhang_angle) * ocslot_total_height;
  nub_angle = adj_opp_to_ang(ochead_middle_height, ochead_middle_height - ochead_nub_depth);
  sweep_corner_radius = ocvase_wall_thickness * sqrt(2);
  sweep_corner_offset = ang_adj_to_opp(22.5, sweep_corner_radius - ocvase_wall_thickness);
  vase_sweep_path = ["setdir", 90, "move", straight_extra_length + straight_base_length - sweep_corner_offset, "arcleft", sweep_corner_radius, 45, "move", ocslot_large_rect_chamfer * sqrt(2)];
  attachable(anchor, spin, orient, size=[tile_size, tile_size, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) fwd(ocslot_middle_to_bottom + straight_extra_length)
          diff() {
            xflip_copy() right(ocvase_wall_thickness + ocslot_large_rect_width / 2) path_sweep(ocvase_sweep_profile, path=turtle(vase_sweep_path));
            if (add_nubs == "Left" || add_nubs == "Both")
              left(ocvase_wall_thickness + ocslot_large_rect_width / 2) {
                back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) right(ocvase_wall_thickness)
                    openconnect_lock(bottom_height=ocslot_bottom_height, middle_height=ochead_middle_height, nub_angle=nub_angle);
                back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) left(eps)
                    tag("remove") openconnect_lock(bottom_height=ocvase_bottom_height, middle_height=ochead_middle_height, nub_angle=nub_angle);
              }
            if (add_nubs == "Right" || add_nubs == "Both")
              right(ocvase_wall_thickness + ocslot_large_rect_width / 2) {
                back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) left(ocvase_wall_thickness)
                    xflip() openconnect_lock(bottom_height=ocslot_bottom_height, middle_height=ochead_middle_height, nub_angle=nub_angle);
                back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) right(eps)
                    xflip() tag("remove") openconnect_lock(bottom_height=ocvase_bottom_height, middle_height=ochead_middle_height, nub_angle=nub_angle);
              }
            xrot(90 - overhang_angle) tag("remove") cuboid([tile_size, 60, ocslot_total_height * 2], anchor=BOTTOM + FRONT);
          }
    children();
  }
}

module openconnect_slot_grid(grid_type = "slot", horizontal_grids = 1, vertical_grids = 1, tile_size = 28, slot_slide_direction = "Up", slot_position = "All", slot_lock_distribution = "None", slot_lock_side = "Left", slot_entryramp_flip = false, excess_thickness = eps, overhang_angle = 45, except_slot_pos = [], chamfer = 0, rounding = 0, limit_region = [], anchor = BOTTOM, spin = 0, orient = UP) {
  tag_scope() attachable(anchor, spin, orient, size=[horizontal_grids * tile_size, vertical_grids * tile_size, ocslot_total_height]) {
      grid_slot_spin = slot_slide_direction == "Left" ? -90 : slot_slide_direction == "Right" ? 90 : slot_slide_direction == "Down" ? 180 : 0;
      grid_slot_flip = slot_slide_direction == "Right" || slot_slide_direction == "Down" ? !slot_entryramp_flip : slot_entryramp_flip;
      down(ocslot_total_height / 2) intersect() {
          cuboid([horizontal_grids * tile_size, vertical_grids * tile_size, ocslot_total_height + excess_thickness], edges="Z", chamfer=chamfer, rounding=rounding, anchor=BOTTOM) {
            for (i = [0:horizontal_grids - 1])
              for (j = [0:vertical_grids - 1]) {
                x_offset = -(horizontal_grids - i * 2 - 1) * tile_size / 2;
                y_offset = (vertical_grids - j * 2 - 1) * tile_size / 2;
                if (!is_region(limit_region) || is_slot_in_region(center_point=[x_offset, y_offset], slide_direction=slot_slide_direction, limit_region=limit_region))
                  if (is_slot_position(i, j, horizontal_grids, vertical_grids, slot_position, except_slot_pos)) {
                    right(x_offset) back(y_offset)
                        attach(BOTTOM, BOTTOM, inside=true, spin=grid_slot_spin) {
                          if (grid_type == "slot")
                            tag("intersect") openconnect_slot(add_nubs=is_slot_position(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", slot_entryramp_flip=grid_slot_flip, excess_thickness=excess_thickness);
                          else
                            tag("intersect") openconnect_vase_slot(is_slot_position(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", overhang_angle=overhang_angle);
                        }
                  }
              }
          }
        }
      children();
    }
}
//END openConnect slot modules

//BEGIN holder geometry calculations
assert(item_width > 0 && item_height > 0 && item_depth > 0, "item size must be greater than 0");

slot_wall_thickness = 1.2 + ocslot_total_height;
holder_top_thickness = holder_slot_position == "Top" ? slot_wall_thickness : holder_thickness;
holder_front_thickness = holder_slot_position == "Front" ? slot_wall_thickness : holder_thickness;
holder_width = item_width + holder_thickness * 2;
holder_height = item_height + holder_thickness + holder_front_thickness;
holder_depth = item_depth + holder_thickness + holder_top_thickness;

final_corner_rounding = max(0, min(item_width / 2, item_height / 2, item_corner_rounding));
//The calculation of horizontal slots for Front version is just an approximation.
final_slot_h_grids = holder_slot_position == "Top" ? floor(holder_width / tile_size) : floor(max(holder_width, holder_width - final_corner_rounding * 2 + 10) / tile_size);
final_slot_v_grids = holder_slot_position == "Top" ? floor(holder_height / tile_size) : floor(holder_depth / tile_size);
final_slot_position_offset = holder_slot_position == "Top" ? 0 : slot_slide_direction == "Right" ? -slot_position_offset : slot_position_offset;
//cut off the bridge part of the upper most slot
middle_cutoff_size_base = max(0.8, ocslot_bottom_min_thickness) * 2 + eps;
holder_middle_cutoff_tiles = max(0, final_slot_h_grids - max(1, holder_slot_column_limit) * 2);
middle_cutoff_size = middle_cutoff_size_base + holder_middle_cutoff_tiles * tile_size;
middle_cutoff_offset = final_slot_h_grids % 2 != holder_middle_cutoff_tiles % 2 ? tile_size / 2 : 0;
//END holder geometry calculations

//BEGIN holder generation
up(generate_holder_part == "Both" ? holder_depth / 2 : holder_width / 2) yrot(generate_holder_part == "Left" ? -90 : generate_holder_part == "Right" ? 90 : 0)
    conditional_half(v=generate_holder_part == "Left" ? LEFT : RIGHT, x=middle_cutoff_offset + final_slot_position_offset, condition=generate_holder_part != "Both", obj_size=max(holder_width, holder_height) + 10)
      diff() cuboid([holder_width, holder_height, holder_depth], edges=BOTTOM, rounding=0.8) {
          down(eps) back((holder_front_thickness - holder_thickness) / 2) {
              down((holder_top_thickness - holder_thickness) / 2)
                attach(CENTER, CENTER)
                  tag("remove") cuboid([item_width, item_height, item_depth + eps * 2], edges="Z", rounding=final_corner_rounding);
              if (item_width - holder_width_edge * 2 > 0 && item_height - holder_height_edge * 2 > 0)
                attach(BOTTOM, BOTTOM, inside=true)
                  cuboid([item_width - holder_width_edge * 2, item_height - holder_height_edge * 2, holder_thickness + eps * 2], edges="Z", rounding=min((item_width - holder_width_edge * 2) / 2, (item_height - holder_height_edge * 2) / 2, final_corner_rounding));
              right(middle_cutoff_offset + final_slot_position_offset) {
                attach(CENTER, CENTER, inside=true)
                  cuboid([middle_cutoff_size, holder_height + 10, holder_depth + 10]);
                if (holder_height_edge > 0 && item_height - holder_height_edge * 2 > 0)
                  attach(BOTTOM, BOTTOM, inside=true)
                    cuboid([middle_cutoff_size, item_height - holder_height_edge * 2, holder_thickness + eps * 2])
                      edge_mask("Z")
                        rounding_edge_mask(r=min(max(0, item_width - holder_width_edge * 2 - final_corner_rounding * 2), holder_height_edge, 2), spin=180);
              }
            }
          if (holder_side_cutoff != "None") {
            side_cutoff_height = item_height - holder_height_edge * 2 - side_cutoff_front_offset - side_cutoff_back_offset;
            side_cutoff_depth = item_depth + holder_thickness - side_cutoff_top_offset - side_cutoff_bottom_offset;
            side_cutoff_width =
              side_cutoff_back_offset < 0 || side_cutoff_front_offset < 0 ? holder_width / 2
              : (holder_width - (item_width - holder_width_edge * 2)) / 2 + max(0, final_corner_rounding - side_cutoff_back_offset, final_corner_rounding - side_cutoff_front_offset);
            rounding_edges = side_cutoff_bottom_offset > 0 ? "X" : [FRONT + TOP, BACK + TOP];
            if (side_cutoff_height > 0 && side_cutoff_depth > 0)
              back(holder_front_thickness + side_cutoff_front_offset + holder_height_edge) down(holder_top_thickness + side_cutoff_top_offset) {
                  conditional_flip(axis="x", copy=holder_side_cutoff == "Both", condition=(holder_side_cutoff == "Both" || holder_side_cutoff == "Left"))
                    attach(FRONT + TOP, FRONT + TOP, align=RIGHT, inside=true)
                      cuboid([side_cutoff_width, side_cutoff_height + eps, side_cutoff_depth + eps], edges=rounding_edges, rounding=min(side_cutoff_height / 2, side_cutoff_depth / 2, 2)) {
                        if (side_cutoff_front_offset - final_corner_rounding > eps && side_cutoff_back_offset - final_corner_rounding > eps && holder_width_edge > eps) {
                          if (side_cutoff_front_offset - final_corner_rounding > eps)
                            edge_mask([LEFT + FRONT])
                              rounding_edge_mask(r=min(side_cutoff_front_offset - final_corner_rounding, holder_width_edge, 2), spin=-90);
                          if (side_cutoff_back_offset - final_corner_rounding > eps)
                            edge_mask([LEFT + BACK])
                              rounding_edge_mask(r=min(side_cutoff_back_offset - final_corner_rounding, holder_width_edge, 2), spin=-90);
                        }
                      }
                }
          }
          attach_anchor = holder_slot_position == "Top" ? TOP : FRONT;
          flat_region = holder_slot_position == "Top" ? left(final_slot_position_offset, rect([holder_width, holder_height], rounding=final_corner_rounding)) : left(final_slot_position_offset, rect([holder_width - final_corner_rounding * 2, holder_depth]));
          right(final_slot_position_offset)
            attach(attach_anchor, TOP, inside=true)
              openconnect_slot_grid(grid_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, tile_size=tile_size, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=eps, limit_region=[flat_region]);
          if (final_corner_rounding > 0)
            edge_mask([LEFT + FRONT, LEFT + BACK, RIGHT + FRONT, RIGHT + BACK])
              yflip() teardrop_edge_mask(l=$edge_length, r=final_corner_rounding, spin=-90);
        }
//END holder generation
