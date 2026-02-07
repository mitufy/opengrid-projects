/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/walls.scad>

generate_drawer_shell = true;
generate_drawer_container = true;
generate_drawer_stopper_clips = false;

/*[Drawer Size]*/
vertical_grids = 2;
horizontal_grids = 5;
depth_grids = 5;

/*[Shell Main Settings]*/
//"Back" for wall-mounted drawers. "Top" for underdesk drawers. Other options are niche and not commonly used. 
shell_slot_position = "Back"; //["Back", "Top", "Bottom", "Left", "Right"]
shell_top_wall_type = "Solid"; //["Solid","Honeycomb"]
shell_bottom_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
shell_side_wall_type = "Solid"; //["Solid","Honeycomb"]
//Note that changing shell dimensions would also change container size.
shell_thickness = 2.4;
shell_outer_chamfer = 2; //0.2

/*[Container Main Settings]*/
container_front_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
container_back_wall_type = "Solid"; //["Solid","Honeycomb"]
//Honeycomb patterns on the side of shell and container do not align. To avoid the inconsistent see-through look, use honeycomb on only one of the two parts.
container_side_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
container_solidwall_thickness = 1.6;
container_honeycombwall_thickness = 2;
//How much lower the back and side walls are compared to the front. "stopper_clips_length" needs to be larger than this value to work.
container_front_back_height_diff = 3;
container_inner_fillet = 2;

/*[Shell Divider]*/
//Divide the drawer shell into several compartments. "Height" stacks drawers vertically. "Width" places them side-by-side.
add_shell_divider = "None"; //["None","Width","Height","Both"]
shell_divider_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
//Compartment sizes by openGrid tiles, separated by commas.
shell_height_compartment_list = "2,3";
//Compartment sizes also correspond to the size of each container, which needs to be generated separately.
shell_width_compartment_list = "3,3";

/*[Container Divider]*/
//Divide the drawer container into several compartments.
add_container_divider = "None"; //["None","Width","Depth","Both"]
container_divider_wall_thickness = 1.2;
//Difference between the height of divider walls and side walls. Increase this value to make the dividers shorter.
container_divider_wall_height_diff = 0;
//Container compartment's unit size is its inner space divided by grid_count.
container_width_grid_count = 3;
//Compartment sizes separated by commas.
container_width_compartment_list = "1,1,1";
//Example 1: width_grid_count="3", width_compartment_list="1,1,1" - container divided into three compartments, each 1\3rd of the total width.
container_depth_grid_count = 5;
//Example 2: depth_grid_count="5", depth_compartment_list="2,3" - container divided into 2 compartments, the first is 2\5ths of the depth, the second 3\5ths.
container_depth_compartment_list = "2,3";

/*[Label and Handle]*/
add_label_holder = true;
//Default label size is recommended for honeycomb front wall. Solid front wall can have larger labels.
label_width = 48;
label_height = 10;
label_depth = 1;
handle_thickness = 2.4;
//How much the handle protrudes from the front of the drawer container.
handle_depth = 10;

/*[Stopper and Magnet Settings]*/
//Simple drawer stoppers, preventing the container from sliding all the way out.
add_stopper_holes = true;
stopper_clips_length = 6;

//Back magnets hold the container securely when it's pushed in.
add_back_magnet_holes = true;
shell_back_magnet_thickness = 2;
container_back_magnet_thickness = 1;
back_magnet_diameter = 6;

//Side magnets act as stoppers by holding the container when it's pulled out.
add_side_magnet_holes = true;
//If wall thickness is not enough for magnets, small "bulges" will be added. 
shell_side_magnet_thickness = 1;
container_side_magnet_thickness = 1;
side_magnet_diameter = 6;

/* [Slot Settings] */
//A slot is generated for every tile by default. Fewer slots mean more surface area, which improves bed adhesion.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Slot entry direction can matter in tight spaces.
slot_direction_flip = false;
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.12; //0.01
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/*[Misc. Settings]*/
container_height_clearance = 0.4; //0.05
container_width_clearance = 0.3; //0.05
container_depth_clearance = 0.4; //0.05
//The thickness of the strut of honeycomb pattern.
honeycomb_strut_hyp = 5;
//Change this value to adjust how much container would pull out before attaching to side magnets. 
side_magnet_shell_edge_distance = 2.6;
side_magnet_container_edge_distance = 2.6;
shell_to_slot_wall_thickness = 0.8;

/*[Hidden]*/
shell_inner_chamfer = max(0, calc_inner_chamfer(shell_outer_chamfer, shell_thickness));
container_outer_chamfer = shell_inner_chamfer;
container_divider_wall_fillet = container_inner_fillet;
container_inner_bottom_fillet = container_inner_fillet;
container_inner_side_fillet = container_inner_fillet;
container_bottom_wall_type = "Solid"; //["Solid","Honeycomb"]
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
container_back_magnet_hole_position = "Bottom Corners"; //["All","Corners","Bottom Corners"]
view_drawer_overlapped = false;
//Slot bottom acts as a wall when printed on its side. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_bottom_min_thickness = 0.8; //0.01

magnet_hole_side_clearance = 0.2;
magnet_hole_depth_clearance = 0.15;

$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN utility functions
function is_grid_distribute(hgrid, vgrid, max_hgrid, max_vgrid, distri, except_pos = []) =
  let (
    is_stagger = hgrid % 2 == vgrid % 2,
    is_corner = (hgrid == 0 || hgrid == max_hgrid - 1) && (vgrid == 0 || vgrid == max_vgrid - 1),
    is_top_row = vgrid == 0,
    is_bottom_row = vgrid == max_vgrid - 1,
    is_edge_row = is_top_row || is_bottom_row,
    is_left_column = hgrid == 0,
    is_right_column = hgrid == max_hgrid - 1,
    is_edge_column = is_left_column || is_right_column,
    is_top_corner = is_corner && is_top_row,
    is_bottom_corner = is_corner && is_bottom_row,
  ) in_list([hgrid, vgrid], except_pos) ? false : (distri == "All") || (distri == "Staggered" && is_stagger) || (distri == "Corners" && is_corner) || (distri == "Top Corners" && is_top_corner) || (distri == "Bottom Corners" && is_top_corner) || (distri == "Edge Rows" && is_edge_row) || (distri == "Edge Columns" && is_edge_column);
module conditional_flip(axis = "x", coordinate = 0, copy = false, condition) {
  if (condition) {
    if (axis == "x")
      xflip(x=coordinate) children();
    else if (axis == "y")
      yflip(y=coordinate) children();
    else if (axis == "z")
      zflip(z=coordinate) children();
    if (copy)
      children();
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
ocslot_edge_feature_widen = shell_slot_position == "Back" ? "None" : "Side";
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
vase_slot_linewidth = 0.6;
ocvase_wall_thickness = vase_slot_linewidth * 2;
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
            if (add_nubs == "right" || add_nubs == "Both")
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
module openconnect_slot(add_nubs = "Left", slot_direction_flip = false, excess_thickness = eps, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[tile_size, tile_size, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) {
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
    union() {
      offset(delta=ocslot_onramp_clearance)
        left(ocslot_onramp_clearance + ochead_middle_height) back(ocslot_large_rect_width / 2 + ochead_back_pos_offset) {
            rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
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
            if (add_nubs == "right" || add_nubs == "Both")
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
module openconnect_slot_grid(grid_type = "slot", horizontal_grids = 1, vertical_grids = 1, tile_size = 28, slot_position = "All", slot_lock_distribution = "None", slot_lock_side = "Left", slot_direction_flip = false, excess_thickness = eps, overhang_angle = 45, except_slot_pos = [], chamfer = 0, rounding = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  tag_scope() attachable(anchor, spin, orient, size=[horizontal_grids * tile_size, vertical_grids * tile_size, ocslot_total_height]) {
      down(ocslot_total_height / 2) intersect() {
          cuboid([horizontal_grids * tile_size, vertical_grids * tile_size, ocslot_total_height + excess_thickness], edges="Z", chamfer=chamfer, rounding=rounding, anchor=BOTTOM) {
            for (i = [0:horizontal_grids - 1])
              for (j = [0:vertical_grids - 1])
                if (is_grid_distribute(i, j, horizontal_grids, vertical_grids, slot_position, except_slot_pos)) {
                  right(i * tile_size) fwd(j * tile_size)
                      attach(BOTTOM + LEFT + BACK, BOTTOM + LEFT + BACK, inside=true) {
                        if (grid_type == "slot")
                          tag("intersect") openconnect_slot(add_nubs=is_grid_distribute(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                        else
                          tag("intersect") openconnect_vase_slot(is_grid_distribute(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", overhang_angle=overhang_angle);
                      }
                }
          }
        }
      children();
    }
}
//END openConnect slot modules

shell_ocslot_part_thickness = ocslot_total_height + shell_to_slot_wall_thickness;

//shell parameters
shell_width = horizontal_grids * tile_size + (shell_slot_position == "Left" || shell_slot_position == "Right" ? shell_ocslot_part_thickness - shell_thickness : 0);
shell_height = vertical_grids * tile_size + (shell_slot_position == "Top" || shell_slot_position == "Bottom" ? shell_ocslot_part_thickness - shell_thickness : 0);
shell_depth = depth_grids * tile_size;
shell_inner_width = horizontal_grids * tile_size - shell_thickness * 2;
shell_inner_height = vertical_grids * tile_size - shell_thickness * 2;
shell_inner_depth = depth_grids * tile_size - shell_ocslot_part_thickness;
//hexwall size is calculated so outer strut overlap with shell wall
shell_hexwall_width = shell_width - shell_inner_chamfer * 2;
shell_hexwall_height = shell_height - shell_inner_chamfer * 2;
shell_hexwall_depth = shell_depth + shell_thickness - shell_ocslot_part_thickness;

//shell divider parameter
shell_height_divide_strs = str_split(str_strip(str_replace_char(shell_height_compartment_list, " ", ","), ","), ",");
shell_height_divide_nums = [for (i = [0:len(shell_height_divide_strs) - 1]) parse_num(shell_height_divide_strs[i])];
shell_height_divide_cumnums = add_shell_divider == "Height" || add_shell_divider == "Both" ? [for (i = cumsum(shell_height_divide_nums)) if (i < vertical_grids) i] : [vertical_grids];
shell_height_divide_tmp =
  len(shell_height_divide_cumnums) == 0 ? []
  : slice(shell_height_divide_nums, 0, len(shell_height_divide_cumnums) - 1);
shell_height_divide_list =
  len(shell_height_divide_tmp) == 0 ? []
  : last(shell_height_divide_cumnums) == vertical_grids ? shell_height_divide_tmp
  : concat(shell_height_divide_tmp, [vertical_grids - last(shell_height_divide_cumnums)]);
shell_vertical_compartments = add_shell_divider == "Height" || add_shell_divider == "Both" ? shell_height_divide_list : [vertical_grids];

shell_width_divide_strs = str_split(str_strip(str_replace_char(shell_width_compartment_list, " ", ","), ","), ",");
shell_width_divide_nums = [for (i = [0:len(shell_width_divide_strs) - 1]) parse_num(shell_width_divide_strs[i])];
shell_width_divide_cumnums = add_shell_divider == "Width" || add_shell_divider == "Both" ? [for (i = cumsum(shell_width_divide_nums)) if (i < horizontal_grids) i] : [horizontal_grids];
shell_width_divide_tmp =
  len(shell_width_divide_cumnums) == 0 ? []
  : slice(shell_width_divide_nums, 0, len(shell_width_divide_cumnums) - 1);
shell_width_divide_list =
  len(shell_width_divide_tmp) == 0 ? []
  : last(shell_width_divide_cumnums) == horizontal_grids ? shell_width_divide_tmp
  : concat(shell_width_divide_tmp, [horizontal_grids - last(shell_width_divide_cumnums)]);
shell_horizontal_compartments = add_shell_divider == "Width" || add_shell_divider == "Both" ? shell_width_divide_list : [horizontal_grids];

//container parameters
container_width = shell_inner_width - container_width_clearance * 2;
container_height = shell_inner_height - container_height_clearance * 2;
container_depth = shell_inner_depth - container_depth_clearance;
container_front_wall_thickness = container_front_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_bottom_wall_thickness = container_bottom_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_side_wall_thickness = container_side_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_back_wall_thickness = container_back_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_back_wall_height = container_height - container_front_back_height_diff;
container_side_wall_height = container_back_wall_height - container_outer_chamfer;
container_divider_wall_height = container_side_wall_height - container_divider_wall_height_diff;

//hexwall parameters
honeycomb_unit_space_adj = 14;
honeycomb_unit_space_hyp = ang_adj_to_hyp(30, honeycomb_unit_space_adj);
honeycomb_strut_adj = ang_hyp_to_adj(30, honeycomb_strut_hyp);
hex_ir = (honeycomb_unit_space_hyp - honeycomb_strut_adj) / 2;
hex_or = hex_ir * 2 / sqrt(3);
fronthex_width_struts = floor(container_width / honeycomb_unit_space_adj);
fronthex_width = fronthex_width_struts * honeycomb_unit_space_adj;
fronthex_width_offset = (container_width - fronthex_width) / 2;
//height struts is round to nearest 0.5
fronthex_height_struts = floor(container_height / honeycomb_unit_space_hyp * 2) / 2;
fronthex_height = fronthex_height_struts * honeycomb_unit_space_hyp;
fronthex_height_offset = (container_height - fronthex_height) / 2;
fronthex_bottom_strut_height = honeycomb_unit_space_hyp / 2 + honeycomb_strut_adj / 2 + fronthex_height_offset - honeycomb_strut_adj;
height_adj_to_width_opp = ang_adj_to_opp(30, abs(fronthex_height_offset));
//this is a magic number because I don't want to calculate hexagon anymore
shell_front_hex_offset = 4.4;
shell_hex_frame_thickness = honeycomb_strut_adj;
container_top_frame_thickness = honeycomb_strut_adj;

stopper_width = 4.8;
stopper_height = 2.4;
stopper_rounding = 0.4;
stopper_flank_width = 2;
stopper_flank_depth = 0.8;
//when set to 0, the center of the stopper is 14mm to the edge of the drawer.
stopper_to_edge_offset = 0;

handle_chamfer = 0.4;

//magnet parameters
shell_back_magnet_hole_thickness = shell_back_magnet_thickness + magnet_hole_depth_clearance;
container_back_magnet_hole_thickness = container_back_magnet_thickness + magnet_hole_depth_clearance;
back_magnet_hole_diameter = back_magnet_diameter + magnet_hole_side_clearance * 2;
back_magnet_ocslot_offset = 4.6;
back_magnet_grid_space =
  container_back_magnet_hole_position == "Corners" ? [tile_size * (horizontal_grids - 2), tile_size * (vertical_grids - 1)]
  : container_back_magnet_hole_position == "Bottom Corners" ? [tile_size * (horizontal_grids - 2), tile_size * (vertical_grids - 1)]
  : [tile_size, tile_size];
back_magnet_grid_count =
  container_back_magnet_hole_position == "Corners" ? [min(horizontal_grids - 1, 2), min(vertical_grids, 2)]
  : container_back_magnet_hole_position == "Bottom Corners" ? [min(horizontal_grids - 1, 2), 1]
  : [horizontal_grids - 1, vertical_grids];

shell_side_magnet_hole_thickness = shell_side_magnet_thickness + magnet_hole_depth_clearance;
container_side_magnet_hole_thickness = container_side_magnet_thickness + magnet_hole_depth_clearance;
side_magnet_hole_diameter = side_magnet_diameter + magnet_hole_side_clearance * 2;

function calc_inner_chamfer(outer_chamfer, wall_thickness) = (outer_chamfer / sqrt(2) + wall_thickness - wall_thickness * sqrt(2)) * sqrt(2);

half_of_anchor =
  view_cross_section == "Right" ? RIGHT
  : view_cross_section == "Back" ? BACK
  : view_cross_section == "Diagonal" ? RIGHT + BACK
  : 0;

if (half_of_anchor != 0) {
  if (generate_drawer_shell)
    half_of(half_of_anchor, s=300)
      down(shell_ocslot_part_thickness)
        back(shell_slot_position == "Top" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Bottom" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
          left(shell_slot_position == "Left" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Right" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
            drawer_shell();
  if (generate_drawer_container && !(generate_drawer_shell && add_shell_divider != "None"))
    half_of(half_of_anchor, s=300)
      left(view_drawer_overlapped ? 0 : horizontal_grids * tile_size)
        up(container_depth_clearance)
          drawer_container();
} else {
  if (generate_drawer_shell)
    down(view_drawer_overlapped ? shell_ocslot_part_thickness : 0)
      back(shell_slot_position == "Top" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Bottom" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
        left(shell_slot_position == "Left" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Right" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
          drawer_shell();
  if (generate_drawer_container && !(generate_drawer_shell && add_shell_divider != "None"))
    fwd(view_drawer_overlapped || !generate_drawer_shell ? 0 : vertical_grids * tile_size / 2 + 10)
      up(view_drawer_overlapped ? container_depth_clearance : container_height / 2)
        xrot(view_drawer_overlapped ? 0 : 90)
          drawer_container();
  if (generate_drawer_stopper_clips)
    right(generate_drawer_shell ? horizontal_grids * tile_size / 2 + 10 : 0) xrot(-90) {
        drawer_stopper(hole_excess=shell_thickness);
        right(tile_size)
          drawer_stopper();
      }
}

module drawer_shell() {
  difference() {
    intersection() {
      diff(remove="rm_outer", keep="") diff(keep="keep rm_outer") {
          cuboid([shell_width, shell_height, shell_depth], anchor=BOTTOM) {
            shell_inner_cut_align =
              shell_slot_position == "Bottom" ? BACK
              : shell_slot_position == "Top" ? FRONT
              : shell_slot_position == "Left" ? RIGHT
              : shell_slot_position == "Right" ? LEFT : CENTER;
            left_hc = shell_side_wall_type == "Honeycomb" && shell_slot_position != "Left";
            right_hc = shell_side_wall_type == "Honeycomb" && shell_slot_position != "Right";
            top_hc = shell_top_wall_type == "Honeycomb" && shell_slot_position != "Top";
            bottom_hc = shell_bottom_wall_type == "Honeycomb" && shell_slot_position != "Bottom";
            attach(TOP, TOP, align=shell_inner_cut_align, inset=shell_thickness, inside=true)
              tag("remove") cuboid([shell_inner_width, shell_inner_height, shell_inner_depth], edges="Z", chamfer=shell_inner_chamfer);
            //left wall
            if (left_hc)
              attach(TOP, RIGHT, align=LEFT, inside=true, spin=90)
                tag("keep") hex_panel([shell_hexwall_depth, shell_hexwall_height, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_hex_frame_thickness);
            attach(TOP, TOP, align=LEFT, inside=true)
              tag(left_hc ? "remove" : "keep") cuboid([shell_thickness + (left_hc ? eps : 0), shell_inner_height - shell_inner_chamfer * 2, shell_inner_depth]);
            //right wall
            if (right_hc)
              attach(TOP, RIGHT, align=RIGHT, inside=true, spin=90)
                tag("keep") hex_panel([shell_hexwall_depth, shell_hexwall_height, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_hex_frame_thickness);
            attach(TOP, TOP, align=RIGHT, inside=true)
              tag(right_hc ? "remove" : "keep") cuboid([shell_thickness + (right_hc ? eps : 0), shell_inner_height - shell_inner_chamfer * 2, shell_inner_depth]);
            //top wall
            if (top_hc)
              attach(TOP, RIGHT, align=BACK, inside=true)
                tag("keep") hex_panel([shell_hexwall_depth, shell_hexwall_width, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_hex_frame_thickness);
            if (add_stopper_holes)
              attach(BACK, BACK, align=TOP, inset=shell_thickness, inside=true)
                tag("keep") cuboid([shell_inner_width, shell_thickness, shell_front_hex_offset]);
            attach(TOP, TOP, align=BACK, inside=true)
              tag(top_hc ? "remove" : "keep") cuboid([shell_inner_width - shell_inner_chamfer * 2, shell_thickness + (top_hc ? eps : 0), shell_inner_depth]);
            //bottom wall
            if (bottom_hc)
              attach(TOP, RIGHT, align=FRONT, inside=true)
                tag("keep") hex_panel([shell_hexwall_depth, shell_hexwall_width, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_hex_frame_thickness);
            attach(TOP, TOP, align=FRONT, inside=true)
              tag(bottom_hc ? "remove" : "keep") cuboid([shell_inner_width - shell_inner_chamfer * 2, shell_thickness + (bottom_hc ? eps : 0), shell_inner_depth]);
            //openconnect slot
            slot_parent_anchor =
              shell_slot_position == "Back" ? BOTTOM
              : shell_slot_position == "Top" ? BACK
              : shell_slot_position == "Bottom" ? FRONT
              : shell_slot_position == "Left" ? LEFT
              : RIGHT;
            slot_spin =
              shell_slot_position == "Back" ? 0
              : shell_slot_position == "Left" ? 90
              : (shell_slot_position == "Top" || shell_slot_position == "Bottom") && slot_direction_flip ? 90
              : -90;
            slot_hgrids = shell_slot_position == "Back" ? horizontal_grids : depth_grids;
            slot_vgrids = shell_slot_position == "Top" || shell_slot_position == "Bottom" ? horizontal_grids : vertical_grids;
            except_slot_pos =
              add_stopper_holes && shell_slot_position == "Top" && !slot_direction_flip ? [[0, 0], [0, slot_vgrids - 1]]
              : add_stopper_holes && shell_slot_position == "Top" && slot_direction_flip ? [[slot_hgrids - 1, 0], [slot_hgrids - 1, slot_vgrids - 1]]
              : add_side_magnet_holes && shell_slot_position == "Right" ? [[0, 0], [0, slot_vgrids - 1]]
              : add_side_magnet_holes && shell_slot_position == "Left" ? [[slot_hgrids - 1, 0], [slot_hgrids - 1, slot_vgrids - 1]]
              : [];
            conditional_flip(axis="x", condition=shell_slot_position == "Top" || shell_slot_position == "Bottom")
              attach(slot_parent_anchor, TOP, inside=true, spin=slot_spin)
                tag("rm_outer") openconnect_slot_grid(horizontal_grids=slot_hgrids, vertical_grids=slot_vgrids, tile_size=tile_size, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_direction_flip=slot_direction_flip, excess_thickness=eps, except_slot_pos=except_slot_pos, chamfer=min(4, max(0.8, ocslot_bottom_min_thickness) + ochead_middle_height + 1));
            if (add_side_magnet_holes) {
              if (left_hc)
                attach(LEFT + FRONT, LEFT + FRONT, align=TOP, inside=true)
                  tag("keep") cuboid([shell_thickness, shell_height, 10.8]);
              ycopies(tile_size, vertical_grids)
                right(shell_slot_position == "Left" ? shell_ocslot_part_thickness : shell_thickness) left(shell_side_magnet_hole_thickness - eps * 2) attach(LEFT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                      tag("rm_outer") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
              if (right_hc)
                attach(RIGHT + FRONT, RIGHT + FRONT, align=TOP, inside=true)
                  tag("keep") cuboid([shell_thickness, shell_height, 10.8]);
              ycopies(tile_size, vertical_grids)
                left(shell_slot_position == "Right" ? shell_ocslot_part_thickness : shell_thickness) right(shell_side_magnet_hole_thickness - eps * 2) attach(RIGHT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                      tag("rm_outer") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
            }
            if (add_shell_divider == "Width" || add_shell_divider == "Both")
              drawer_divider(is_shell=true, by_width=true);
            if (add_shell_divider == "Height" || add_shell_divider == "Both")
              drawer_divider(is_shell=true, by_width=false);
            if (add_back_magnet_holes) {
              for (i = [0:len(shell_vertical_compartments) - 1]) {
                for (j = [0:len(shell_horizontal_compartments) - 1]) {
                  back(i == 0 ? 0 : shell_height_divide_cumnums[i - 1] * tile_size)
                    right(j == 0 ? 0 : shell_width_divide_cumnums[j - 1] * tile_size)
                      left((horizontal_grids - 2) / 2 * tile_size)
                        fwd((vertical_grids - 1) / 2 * tile_size - back_magnet_ocslot_offset)
                          line_copies(spacing=tile_size * max(shell_horizontal_compartments[j] - 2, 0), n=min(shell_horizontal_compartments[j] - 1, 2), p1=[0, 0, 0])
                            attach(BOTTOM, BOTTOM, inside=true)
                              tag("rm_outer") cyl(h=shell_back_magnet_hole_thickness, d=back_magnet_hole_diameter, chamfer1=-0.2);
                }
              }
            }
            if (add_stopper_holes)
              for (i = [0:len(shell_horizontal_compartments) - 1])
                left(shell_width / 2 - tile_size / 2) right(i == 0 ? 0 : shell_width_divide_cumnums[i - 1] * tile_size) {
                    for (j = [0:shell_horizontal_compartments[i] == 1 ? 0 : 1])
                      left(shell_horizontal_compartments[i] == 1 ? 0 : j == 0 ? stopper_to_edge_offset : -stopper_to_edge_offset) right(j * (shell_horizontal_compartments[i] - 1) * tile_size) {
                          tag("rm_outer") attach(BACK, TOP, align=TOP, inset=shell_thickness, inside=true)
                              drawer_stopper(hole=true);
                        }
                  }
          }
        }
      shell_chamfer_edge_except =
        shell_slot_position == "Bottom" ? [FRONT + LEFT, FRONT + RIGHT]
        : shell_slot_position == "Top" ? [BACK + LEFT, BACK + RIGHT]
        : shell_slot_position == "Left" ? [BACK + LEFT, FRONT + LEFT]
        : shell_slot_position == "Right" ? [BACK + RIGHT, FRONT + RIGHT]
        : [];
      cuboid([shell_width, shell_height, shell_depth], edges="Z", chamfer=shell_outer_chamfer, except=shell_chamfer_edge_except, anchor=BOTTOM);
    }
  }
}
module drawer_container() {
  intersect(intersect="mask", keep="kp_root") {
    diff(remove="rm_outer", keep="mask kp_root") diff(remove="remove", keep="keep mask rm_outer kp_root")
        cuboid([container_width, container_height, container_depth], anchor=BOTTOM) {
          left_hc = container_side_wall_type == "Honeycomb";
          right_hc = container_side_wall_type == "Honeycomb";
          bottom_hc = container_bottom_wall_type == "Honeycomb";
          front_hc = container_front_wall_type == "Honeycomb";
          back_hc = container_back_wall_type == "Honeycomb";
          attach(BACK, BACK, align=BOTTOM, inset=container_back_wall_thickness, inside=true)
            tag("remove") cuboid([container_width - container_side_wall_thickness * 2, container_height - container_bottom_wall_thickness, container_depth - container_back_wall_thickness - container_front_wall_thickness])
                tag("keep") if (container_inner_bottom_fillet > 0) {
                  edge_mask([FRONT])
                    rounding_edge_mask(r=container_inner_bottom_fillet);
                  edge_mask(["Y"])
                    rounding_edge_mask(r=container_inner_side_fillet);
                  corner_mask([FRONT])
                    rounding_corner_mask(r=container_inner_bottom_fillet);
                }
          //front wall
          if (front_hc)
            attach(FRONT, LEFT, align=TOP, inside=true)
              tag("keep") hex_panel([container_height, container_width, container_front_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness));
          attach(TOP, TOP, align=FRONT, inset=container_bottom_wall_thickness + container_inner_bottom_fillet, inside=true)
            tag(front_hc ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2 - (front_hc ? container_inner_side_fillet * 2 : 0), container_height - container_bottom_wall_thickness - (front_hc ? container_top_frame_thickness + container_inner_bottom_fillet : 0), container_front_wall_thickness + (front_hc ? eps : 0)]);
          //back wall
          if (back_hc)
            attach(FRONT, LEFT, align=BOTTOM, inside=true)
              tag("keep") hex_panel([container_height, container_width, container_back_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness));
          attach(BOTTOM, BOTTOM, align=FRONT, inset=container_bottom_wall_thickness + container_inner_bottom_fillet, inside=true)
            tag(back_hc ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2 - (back_hc ? container_inner_side_fillet * 2 : 0), back_hc ? container_back_wall_height - container_bottom_wall_thickness - container_top_frame_thickness - container_inner_bottom_fillet : container_back_wall_height, container_back_wall_thickness + (back_hc ? eps : 0)]);
          //side walls
          if (left_hc)
            attach(FRONT, LEFT, align=LEFT, inside=true, spin=90)
              tag("keep") hex_panel([container_height, container_depth, container_side_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness));
          if (right_hc)
            attach(FRONT, LEFT, align=RIGHT, inside=true, spin=90)
              tag("keep") hex_panel([container_height, container_depth, container_side_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness));
          down(container_front_wall_thickness) attach(LEFT + TOP, LEFT + TOP, align=FRONT, inset=container_bottom_wall_thickness + container_inner_bottom_fillet, inside=true)
              tag(left_hc ? "remove" : "keep") cuboid([container_side_wall_thickness + (left_hc ? eps : 0), container_side_wall_height - container_bottom_wall_thickness - (left_hc ? container_top_frame_thickness + container_inner_bottom_fillet : 0), container_depth - container_front_wall_thickness - container_back_wall_thickness - (left_hc ? container_inner_side_fillet * 2 : 0)]);
          down(container_front_wall_thickness) attach(RIGHT + TOP, RIGHT + TOP, align=FRONT, inset=container_bottom_wall_thickness + container_inner_bottom_fillet, inside=true)
              tag(right_hc ? "remove" : "keep") cuboid([container_side_wall_thickness + (right_hc ? eps : 0), container_side_wall_height - container_bottom_wall_thickness - (right_hc ? container_top_frame_thickness + container_inner_bottom_fillet : 0), container_depth - container_front_wall_thickness - container_back_wall_thickness - (right_hc ? container_inner_side_fillet * 2 : 0)]);

          
          //bottom wall
          if (bottom_hc)
            attach(TOP, LEFT, align=FRONT, inside=true)
              tag("keep") hex_panel([container_depth, container_width, container_bottom_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_back_wall_thickness, container_front_wall_thickness));
          attach(FRONT, FRONT, align=BOTTOM, inset=container_back_wall_thickness, inside=true)
            tag(bottom_hc ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2 - (bottom_hc ? container_inner_side_fillet * 2 : 0), container_bottom_wall_thickness + (bottom_hc ? eps : 0), container_depth - container_front_wall_thickness - container_back_wall_thickness - (bottom_hc ? container_inner_bottom_fillet * 2 : 0)]);

          
          tag("mask") {
            attach(FRONT, FRONT, align=TOP, inset=-handle_depth, inside=true)
              cuboid([container_width, container_height, container_front_wall_thickness + handle_depth], edges="Z", chamfer=container_outer_chamfer);
            attach(FRONT, FRONT, align=TOP, inset=container_front_wall_thickness, inside=true)
              cuboid([container_width, container_side_wall_height, container_depth - container_front_wall_thickness - container_back_wall_thickness], edges=[FRONT + LEFT, FRONT + RIGHT], chamfer=container_outer_chamfer);
            attach(BOTTOM, BOTTOM, align=FRONT, inside=true)
              cuboid([container_width, container_back_wall_height, container_back_wall_thickness], edges=["Z"], chamfer=container_outer_chamfer);
          }
          container_handle();
          if (add_label_holder)
            container_label_holder();
          if (add_container_divider == "Width" || add_container_divider == "Both")
            drawer_divider(is_shell=false, by_width=true);
          if (add_container_divider == "Depth" || add_container_divider == "Both")
            drawer_divider(is_shell=false, by_width=false);
          if (add_side_magnet_holes)
            xflip_copy() {
              hole_extrude_thickness = container_side_magnet_hole_thickness - container_side_wall_thickness + 0.45 + eps;
              if (container_side_wall_type == "Honeycomb")
                attach(LEFT + FRONT, LEFT + FRONT, align=BOTTOM, inside=true)
                  tag("keep") cuboid([container_side_wall_thickness, container_height - container_front_back_height_diff - container_outer_chamfer, shell_front_hex_offset + honeycomb_unit_space_hyp / 2]);
              ycopies(tile_size, vertical_grids) {
                attach(LEFT, FRONT, align=BOTTOM, inset=side_magnet_container_edge_distance, inside=true, spin=90)
                  tag("rm_outer") teardrop(h=container_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                if (hole_extrude_thickness > eps)
                  right(container_side_wall_thickness) attach(LEFT, FRONT, align=BOTTOM, inset=side_magnet_container_edge_distance, inside=true, spin=90)
                      tag("kp_root") teardrop(h=hole_extrude_thickness, d=side_magnet_hole_diameter + 0.2, cap_h=side_magnet_hole_diameter / 2 + 0.2, chamfer1=-hole_extrude_thickness);
              }
            }
          if (add_back_magnet_holes) {
            hole_extrude_thickness = container_back_magnet_hole_thickness - container_back_wall_thickness + 0.45 + eps;
            if (back_hc)
              line_copies(back_magnet_grid_space[0], back_magnet_grid_count[0])
                attach(BOTTOM + FRONT, BOTTOM + FRONT, inside=true)
                  tag("keep") cuboid([back_magnet_hole_diameter + 4.2, container_height - container_front_back_height_diff, container_back_wall_thickness]);
            fwd((vertical_grids - 1) / 2 * tile_size - back_magnet_ocslot_offset)
              line_copies(back_magnet_grid_space[0], back_magnet_grid_count[0]) {
                attach(BOTTOM, FRONT, inside=true)
                  tag("rm_outer") teardrop(h=container_back_magnet_hole_thickness, d=back_magnet_hole_diameter, cap_h=back_magnet_hole_diameter / 2 + 0.2);
                if (hole_extrude_thickness > eps)
                  up(container_back_wall_thickness) attach(BOTTOM, FRONT, inside=true)
                      tag("kp_root") teardrop(h=hole_extrude_thickness, d=back_magnet_hole_diameter + 0.2, cap_h=back_magnet_hole_diameter / 2 + 0.2, chamfer1=-hole_extrude_thickness);
              }
          }
        }
  }
}

module drawer_divider(is_shell, by_width) {
  divider_wall_thickness = is_shell ? shell_thickness * 2 : container_divider_wall_thickness;
  divider_wall_type = is_shell ? shell_divider_wall_type : "Solid";
  grid_count =
    by_width && !is_shell ? container_width_grid_count
    : !by_width && !is_shell ? container_depth_grid_count
    : by_width && is_shell ? horizontal_grids : vertical_grids;
  compartment_list =
    by_width && !is_shell ? container_width_compartment_list
    : !by_width && !is_shell ? container_depth_compartment_list
    : by_width && is_shell ? shell_width_compartment_list : shell_height_compartment_list;
  divide_strs = str_split(str_strip(str_replace_char(compartment_list, " ", ","), ","), ",");
  divide_nums = [for (i = [0:len(divide_strs) - 1]) parse_num(divide_strs[i])];
  divide_cumnums = [for (i = cumsum(divide_nums)) if (i < grid_count) i];
  inner_size =
    by_width && !is_shell ? container_width - container_side_wall_thickness * 2 - divider_wall_thickness * len(divide_cumnums)
    : !by_width && !is_shell ? container_depth - container_front_wall_thickness - container_back_wall_thickness - divider_wall_thickness * len(divide_cumnums)
    : by_width && is_shell ? shell_inner_width - divider_wall_thickness * len(divide_cumnums) : shell_inner_height - divider_wall_thickness * len(divide_cumnums);
  wall_alignment =
    by_width && !is_shell ? LEFT
    : !by_width && !is_shell ? TOP
    : by_width && is_shell ? LEFT : BACK;

  solidwall_anchor =
    by_width && !is_shell ? FRONT + TOP
    : !by_width && !is_shell ? FRONT
    : by_width && is_shell ? TOP : LEFT;
  solidwall_x =
    by_width ? divider_wall_thickness
    : is_shell ? shell_width : container_width;
  solidwall_y =
    by_width && is_shell ? shell_height
    : !by_width && is_shell ? divider_wall_thickness
    : min((container_height - container_front_back_height_diff - container_outer_chamfer), container_divider_wall_height + container_bottom_wall_thickness);
  solidwall_z =
    by_width && !is_shell ? container_depth
    : !by_width && !is_shell ? divider_wall_thickness
    : shell_depth;

  hexwall_anchor = TOP;
  hexwall_spin = by_width ? 90 : 0;
  hexwall_length = !by_width ? shell_hexwall_width : shell_hexwall_height;
  hexwall_depth = shell_hexwall_depth;

  compartment_size_unit = is_shell ? tile_size : inner_size / grid_count;
  compartment_first_wall_offset =
    by_width && !is_shell ? container_side_wall_thickness
    : !by_width && !is_shell ? container_front_wall_thickness
    : (shell_slot_position == "Bottom" && !by_width) || (shell_slot_position == "Left" && by_width) ? -(divider_wall_thickness - shell_ocslot_part_thickness)
    : -(divider_wall_thickness - shell_thickness);

  container_divider_fillet_edges = by_width ? [FRONT + LEFT, FRONT + RIGHT] : [FRONT + TOP, FRONT + BOTTOM];
  for (i = [0:len(divide_cumnums) - 1]) {
    compartment_inset = divide_cumnums[i] * compartment_size_unit + compartment_first_wall_offset + (is_shell ? 0 : i * divider_wall_thickness);
    if (divide_cumnums[i] > 0 && compartment_inset < inner_size) {
      tag_intersect(tag="keep", intersect="msk0", keep="kp1") {
        attach(solidwall_anchor, solidwall_anchor, align=wall_alignment, inset=compartment_inset, inside=true)
          tag_diff(tag=divider_wall_type == "Honeycomb" ? "" : "kp1", remove="rm1") cuboid([solidwall_x, solidwall_y, solidwall_z]) {
              if (is_shell) {
                if (!by_width && add_stopper_holes) {
                  for (in_i = [0:len(shell_horizontal_compartments) - 1]) {
                    left(shell_width / 2 - tile_size / 2) right(in_i == 0 ? 0 : shell_width_divide_cumnums[in_i - 1] * tile_size) {
                        for (in_j = [0:shell_horizontal_compartments[in_i] == 1 ? 0 : 1]) {
                          left(shell_horizontal_compartments[in_i] == 1 ? 0 : in_j == 0 ? stopper_to_edge_offset : -stopper_to_edge_offset) right(in_j * (shell_horizontal_compartments[in_i] - 1) * tile_size)
                              tag("rm1") attach(BACK, TOP, align=TOP, inset=shell_thickness, inside=true)
                                  drawer_stopper(hole=true, hole_excess=shell_thickness);
                        }
                      }
                  }
                }
                if (by_width && add_side_magnet_holes) {
                  ycopies(tile_size, vertical_grids)
                    attach(LEFT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                      tag("rm1") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                  ycopies(tile_size, vertical_grids)
                    attach(RIGHT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                      tag("rm1") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                }
              } else if (container_divider_wall_fillet > 0)
                back(container_bottom_wall_thickness)
                  tag("") edge_mask(container_divider_fillet_edges)
                      rounding_edge_mask(r=container_divider_wall_fillet, spin=by_width ? 90 : -90);
            }
        if (divider_wall_type == "Honeycomb")
          tag_diff(tag="msk0", remove="rm0")
            attach(TOP, RIGHT, align=wall_alignment, inset=compartment_inset, inside=true, spin=hexwall_spin)
              hex_panel([hexwall_depth, hexwall_length, divider_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness) {
                if (is_shell) {
                  if (!by_width && add_stopper_holes)
                    attach(RIGHT, TOP, inside=true)
                      tag("") cuboid([shell_width, divider_wall_thickness, 10.8]);
                  if (by_width && add_side_magnet_holes)
                    attach(RIGHT, TOP, inside=true)
                      tag("") cuboid([shell_height, divider_wall_thickness, 10.8]);
                }
              }
      }
    }
  }
}

module container_handle() {
  //Calculate honeycomb pattern so I can align the stem of the handle in a way that looks natural. I'm pretty sure some of the calculations are redundant, but I cannot improve the code because I forgot how they work an hour after typing them.
  handle_strut_number = fronthex_width < 100 ? 0 : (fronthex_width_struts - 1) / 2 % 2;
  hexwall_edge_to_strut_offset = hex_or * 2 + honeycomb_strut_hyp / 2 - height_adj_to_width_opp;
  leftcol1_rightcol2 = honeycomb_unit_space_adj * (handle_strut_number - 1) + hexwall_edge_to_strut_offset;
  leftcol2_rightcol1 = honeycomb_unit_space_adj * ( -handle_strut_number + fronthex_width_struts - 2) + hexwall_edge_to_strut_offset;
  left_strut_offset = handle_strut_number % 2 == 0 ? leftcol1_rightcol2 : leftcol2_rightcol1;
  right_strut_offset = handle_strut_number % 2 == 0 ? leftcol2_rightcol1 : leftcol1_rightcol2;

  handle_strut_slant_width = ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer);

  fill_handle_width_inset = handle_strut_number * honeycomb_unit_space_adj;
  turtle_start_offset = 0.2;
  pull_handle_transition_depth = handle_depth - handle_thickness - handle_thickness / 2 - turtle_start_offset;

  left_transition_offset = fronthex_width / 2 - left_strut_offset;
  right_transition_offset = fronthex_width / 2 - right_strut_offset;

  left_transition_target_x = ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer) / 2 - (handle_thickness - honeycomb_strut_hyp);
  right_transition_target_x = fronthex_width - (right_strut_offset + honeycomb_strut_hyp) - (left_strut_offset + left_transition_target_x) - (handle_thickness - honeycomb_strut_hyp);

  left_turtle_offset = fronthex_width / 2 - left_strut_offset - handle_thickness / 2 - left_transition_target_x;
  right_turtle_offset = fronthex_width / 2 - right_strut_offset - handle_thickness / 2 - right_transition_target_x;

  turtle_handle_width =
    handle_strut_number % 2 == 0 ? fronthex_width / 2 - left_strut_offset - left_transition_target_x - handle_thickness - handle_thickness / 2
    : fronthex_width / 2 - right_strut_offset - right_transition_target_x - handle_thickness - handle_thickness / 2;

  handle_sweep_turtle_path_left = ["move", turtle_start_offset, "arcleft", handle_thickness, 90, "move", turtle_handle_width];
  handle_sweep_turtle_path_right = ["move", turtle_start_offset, "arcright", handle_thickness, 90, "move", turtle_handle_width];

  up(pull_handle_transition_depth - eps) fwd(container_height / 2 - fronthex_bottom_strut_height / 2) left(handle_strut_number % 2 == 0 ? left_turtle_offset : -left_turtle_offset)
        attach(TOP, "start-centroid")
          path_sweep(rect([handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_left));
  up(pull_handle_transition_depth - eps) fwd(container_height / 2 - fronthex_bottom_strut_height / 2) left(handle_strut_number % 2 == 0 ? right_turtle_offset : -right_turtle_offset)
        attach(TOP, "start-centroid")
          path_sweep(rect([handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_right));
  //middle truss
  if (turtle_handle_width > 50) {
    up((container_depth) / 2 - eps) fwd(container_height / 2) {
        left(handle_strut_number % 2 == 0 ? left_transition_offset : -left_transition_offset) {
          if ( (fronthex_width_struts - 1) / 2 % 2 == 0)
            right((fronthex_width_struts - handle_strut_number * 2 - 1) / 2 * honeycomb_unit_space_adj)
              handle_transition(trans_offset=(left_transition_target_x + right_transition_target_x) / 2, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness, add_front=handle_thickness - handle_chamfer);
          else
            right((fronthex_width_struts - handle_strut_number * 2 - 1) / 2 * honeycomb_unit_space_adj)
              xflip() handle_transition(trans_offset=(left_transition_target_x + right_transition_target_x) / 2, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness, add_front=handle_thickness - handle_chamfer);
        }
      }
  }
  up((container_depth) / 2 - eps) fwd(container_height / 2)
      left(handle_strut_number % 2 == 0 ? left_transition_offset : -left_transition_offset) {
        if (handle_strut_number % 2 == 0)
          handle_transition(trans_offset=left_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
        else
          xflip() handle_transition(trans_offset=left_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
      }
  up((container_depth) / 2 - eps) fwd(container_height / 2)
      left(handle_strut_number % 2 == 0 ? right_transition_offset : -right_transition_offset) {
        if (handle_strut_number % 2 == 0)
          handle_transition(trans_offset=right_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
        else
          xflip() handle_transition(trans_offset=right_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
      }
  function handle_profile_func(first_ang, second_ang = 30, thickness = honeycomb_strut_hyp) =
    [
      [ang_adj_to_opp(first_ang, handle_chamfer), handle_chamfer],
      [ang_adj_to_opp(first_ang, fronthex_bottom_strut_height - handle_chamfer), fronthex_bottom_strut_height - handle_chamfer],
      [ang_adj_to_opp(first_ang, fronthex_bottom_strut_height - handle_chamfer) + handle_chamfer, fronthex_bottom_strut_height],
      [thickness + ang_adj_to_opp(first_ang, fronthex_bottom_strut_height) - handle_chamfer - ang_adj_to_opp(first_ang, handle_chamfer), fronthex_bottom_strut_height],
      [thickness + ang_adj_to_opp(first_ang, fronthex_bottom_strut_height - handle_chamfer), fronthex_bottom_strut_height - handle_chamfer],
      [thickness + ang_adj_to_opp(first_ang, handle_chamfer) + ang_adj_to_opp(30 - second_ang, fronthex_bottom_strut_height - handle_chamfer * 2), handle_chamfer],
      [thickness + ang_adj_to_opp(first_ang, handle_chamfer) + ang_adj_to_opp(30 - second_ang, fronthex_bottom_strut_height - handle_chamfer * 2) - ang_adj_to_opp(45, handle_chamfer), 0],
      [ang_adj_to_opp(first_ang, handle_chamfer) + handle_chamfer, 0],
    ];
  module handle_transition(steps = 90, trans_offset = "Left", starting_thickness = honeycomb_strut_hyp, target_thickness = honeycomb_strut_hyp, starting_angle = 30, wide_bottom = true, add_front = 0) {
    ang_unit = starting_angle / steps;
    up_unit = pull_handle_transition_depth / steps;
    thickness_unit = (target_thickness - starting_thickness) / steps;
    target_x =
      trans_offset == "Left" ? ang_adj_to_opp(starting_angle, fronthex_bottom_strut_height - handle_chamfer)
      : trans_offset == "Middle" ? ang_adj_to_opp(starting_angle, fronthex_bottom_strut_height - handle_chamfer) / 2 - (target_thickness - starting_thickness)
      : trans_offset == "Right" ? 0
      : trans_offset;
    x_unit = target_x / steps;
    render() {
      if (wide_bottom) {
        down(container_front_wall_thickness - eps) linear_extrude(container_front_wall_thickness) polygon(handle_profile_func(first_ang=starting_angle, second_ang=0, thickness=starting_thickness));
      }
      for (i = [1:1:steps]) {
        handle_profile1 = handle_profile_func(first_ang=starting_angle - ang_unit * (i - 1), second_ang=wide_bottom ? ang_unit * (i - 1) : starting_angle, thickness=starting_thickness + thickness_unit * (i - 1));
        handle_profile2 = handle_profile_func(first_ang=starting_angle - ang_unit * (i), second_ang=wide_bottom ? ang_unit * (i) : starting_angle, thickness=starting_thickness + thickness_unit * (i));
        hull() {
          right(x_unit * (i - 1)) up(up_unit * (i - 1)) linear_extrude(eps) polygon(handle_profile1);
          right(x_unit * i) up(up_unit * i) linear_extrude(eps) polygon(handle_profile2);
        }
      }
      if (add_front > 0) {
        right(x_unit * steps) up(up_unit * steps) linear_extrude(add_front) polygon(handle_profile_func(first_ang=starting_angle - ang_unit * steps, second_ang=wide_bottom ? ang_unit * steps : starting_angle, thickness=starting_thickness + thickness_unit * steps));
      }
    }
  }
}
module container_label_holder() {
  frontplate_width = honeycomb_unit_space_adj * 4;
  frontplate_offset_mode = (fronthex_width_struts - 1) / 2 % 2 == fronthex_height_struts % 1 * 2;
  label_side_clearance = 0.2;
  label_depth_clearance = 0.3;
  label_holder_wall_thickness = 0.8;
  label_holder_width = label_width + label_holder_wall_thickness * 2 + label_side_clearance * 2;
  label_holder_depth = label_depth + label_depth_clearance + label_holder_wall_thickness;
  label_holder_height = label_height + label_holder_depth + label_side_clearance;
  if (container_front_wall_type == "Honeycomb") {
    left(honeycomb_unit_space_adj / 2 - ang_hyp_to_adj(30, honeycomb_strut_adj) / 2) {
      right(frontplate_offset_mode ? hex_or : hex_or / 2)
        attach(TOP, FRONT, align=FRONT, inset=fronthex_height_offset + (fronthex_height_struts - 0.5) * honeycomb_unit_space_hyp, inside=true)
          tag("keep") prismoid(size1=[frontplate_width, container_front_wall_thickness], xang=frontplate_offset_mode ? [120, 60] : [60, 120], yang=[90, 90], h=honeycomb_unit_space_hyp / 2 + fronthex_height_offset);
      right(frontplate_offset_mode ? hex_or / 2 : hex_or)
        attach(TOP, FRONT, align=FRONT, inset=fronthex_height_offset + (fronthex_height_struts - 1) * honeycomb_unit_space_hyp, inside=true)
          tag("keep") prismoid(size1=[frontplate_width, container_front_wall_thickness], xang=frontplate_offset_mode ? [60, 120] : [120, 60], yang=[90, 90], h=honeycomb_unit_space_hyp / 2);
    }
    attach(TOP, TOP, align=BACK, inset=honeycomb_strut_adj / 2, inside=true)
      tag("keep") cuboid([label_holder_width, label_holder_height, container_front_wall_thickness]);
  }
  tag_diff(tag="keep", remove="label_remove") {
    attach(TOP, BOTTOM, align=BACK, inset=honeycomb_strut_adj / 2)
      tag("") prismoid(size1=[label_holder_width, label_holder_height], xang=[90, 90], yang=[45, 90], h=label_holder_depth, rounding=[0, 0, 0.8, 0.8], $fn=64) {
          edge_mask([TOP + LEFT, TOP + RIGHT])
            tag("label_remove") rounding_edge_mask(r=0.4, l=$edge_length + 5);
          back(eps) attach(BACK, BACK, align=BOTTOM, inside=true)
              tag("label_remove") cuboid([label_holder_width - label_holder_wall_thickness * 2, label_height + label_side_clearance, label_holder_depth - label_holder_wall_thickness]);
          attach(BACK, BACK, align=TOP, inside=true, shiftout=eps)
            tag("label_remove") cuboid([label_holder_width - label_holder_wall_thickness * 2 - label_holder_wall_thickness * 4, label_height + label_side_clearance, label_holder_depth - label_holder_wall_thickness]);
        }
  }
}

module drawer_stopper(hole = false, hole_excess = 0, anchor = TOP, orient = UP, spin = 0) {
  stopper_leg_thickness = 1.6;
  stopper_leg_outer_round = stopper_clips_length - stopper_rounding < 0.6 ? 0 : stopper_rounding;
  stopper_leg_inner_round = min(stopper_rounding, stopper_clips_length / 2);
  stopper_leg_nub_length = min(3, stopper_clips_length - stopper_leg_outer_round);
  stopper_leg_nub_width = min(0.6, stopper_leg_nub_length);

  stopper_width_clearance = 0.1;
  stopper_height_clearance = 0.15;
  stopper_clips_length_clearance = 0.1;

  cuboid([stopper_width + stopper_flank_width - (hole ? 0 : stopper_width_clearance * 2), stopper_height - (hole ? 0 : stopper_height_clearance * 2), stopper_flank_depth - (hole ? 0 : stopper_clips_length_clearance)], anchor=anchor, orient=orient, spin=spin) {
    attach(BOTTOM, TOP)
      tag_scope() diff() cuboid([stopper_width - (hole ? 0 : stopper_width_clearance * 2), stopper_height - (hole ? 0 : stopper_height_clearance * 2), shell_thickness - stopper_flank_depth + (hole ? eps * 2 : 0)], rounding=-stopper_rounding, edges=[TOP + LEFT, TOP + RIGHT], $fn=64) {
            if (hole && hole_excess > 0)
              attach(BOTTOM, TOP)
                cuboid([stopper_width + stopper_flank_width, stopper_height, hole_excess]);
            if (!hole && stopper_clips_length > eps)
              attach(BOTTOM, TOP)
                cuboid([stopper_width - stopper_width_clearance * 2, stopper_height - stopper_height_clearance * 2, stopper_clips_length], rounding=stopper_leg_outer_round, edges=[BOTTOM + LEFT, BOTTOM + RIGHT], $fn=64) {
                  attach(BOTTOM, BOTTOM, inside=true)
                    cuboid([stopper_width - stopper_leg_thickness * 2 - stopper_width_clearance * 2, stopper_height - stopper_height_clearance * 2 + eps, stopper_clips_length], rounding=stopper_leg_inner_round, edges=[TOP + LEFT, TOP + RIGHT], $fn=64) {
                      edge_mask([BOTTOM + LEFT, BOTTOM + RIGHT])
                        rounding_edge_mask(r=stopper_leg_inner_round, spin=90);
                    }
                  attach(RIGHT, BOTTOM, align=TOP)
                    prismoid(size1=[stopper_height - stopper_height_clearance * 2, stopper_leg_nub_length], size2=[stopper_height - stopper_height_clearance * 2, 0], shift=[0, stopper_leg_nub_length / 2], h=stopper_leg_nub_width);
                  attach(LEFT, BOTTOM, align=TOP)
                    prismoid(size1=[stopper_height - stopper_height_clearance * 2, stopper_leg_nub_length], size2=[stopper_height - stopper_height_clearance * 2, 0], shift=[0, stopper_leg_nub_length / 2], h=stopper_leg_nub_width);
                }
          }
  }
}
