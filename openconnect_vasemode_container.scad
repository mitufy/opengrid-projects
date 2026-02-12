/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>

/* [Main Settings] */
//Recommended: 150-200% of nozzle size (e.g. 0.6–0.8mm for a 0.4mm nozzle). Higher values may work, feel free to experiment.
vase_slot_linewidth = 0.6;
//Multiple containers of same texture can be installed side by side as the pattern is designed to be complementary.
vase_surface_texture = "checkers"; //["":None, "cubes":Cubes, "diamonds":Diagonal Ribs,"wave_ribs":Wave Ribs,"checkers":Checkers]

horizontal_grids = 2;
vertical_grids = 3;
//Depth is not technically restrained by grid. You can override this with "use_custom_depth" below.
depth_grids = 2;

//Tilt the container forward for easier access of content. Set to 0 for a standard vertical container.
vase_tilt_angle = 15; //[0:5:45]
//Serves similar purpose as tilt_angle by insetting the front face of the container.
vase_front_inset_angle = 0; //[0:5:45]

/* [Label Settings] */
//"Split" option allows two narrow containers placed side-by-side to share a single, long label.
label_holder_type = "None"; //["None", "Standard", "Split-Left", "Split-Right"]
label_width = 48;
label_height = 10;
label_depth = 1;

/* [Advanced Settings] */
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
use_custom_depth = false;
custom_depth = 60;
surface_texture_size = 7;
surface_texture_depth = 1; //0.2

/* [Hidden] */
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
ocslot_edge_feature_widen = "None";
ocslot_edge_bridge_min_width = 0.8;
ocslot_edge_wall_min_width = 0.6;
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
module openconnect_slot_grid(grid_type = "slot", horizontal_grids = 1, vertical_grids = 1, tile_size = 28, slot_slide_direction = "Up", slot_position = "All", slot_lock_distribution = "None", slot_lock_side = "Left", slot_entryramp_flip = false, excess_thickness = eps, overhang_angle = 45, except_slot_pos = [], chamfer = 0, rounding = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  tag_scope() attachable(anchor, spin, orient, size=[horizontal_grids * tile_size, vertical_grids * tile_size, ocslot_total_height]) {
      grid_slot_spin = slot_slide_direction == "Left" ? -90 : slot_slide_direction == "Right" ? 90 : slot_slide_direction == "Down" ? 180 : 0;
      grid_slot_filp = slot_slide_direction == "Right" || slot_slide_direction == "Down" ? !slot_entryramp_flip : slot_entryramp_flip;
      down(ocslot_total_height / 2) intersect() {
          cuboid([horizontal_grids * tile_size, vertical_grids * tile_size, ocslot_total_height + excess_thickness], edges="Z", chamfer=chamfer, rounding=rounding, anchor=BOTTOM) {
            for (i = [0:horizontal_grids - 1])
              for (j = [0:vertical_grids - 1])
                if (is_grid_distribute(i, j, horizontal_grids, vertical_grids, slot_position, except_slot_pos)) {
                  left((horizontal_grids - i * 2 - 1) * tile_size / 2) back((vertical_grids - j * 2 - 1) * tile_size / 2)
                      attach(BOTTOM, BOTTOM, inside=true, spin=grid_slot_spin) {
                        if (grid_type == "slot")
                          tag("intersect") openconnect_slot(add_nubs=is_grid_distribute(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", slot_entryramp_flip=grid_slot_filp, excess_thickness=excess_thickness);
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

vase_width = tile_size * horizontal_grids;
vase_depth = use_custom_depth ? custom_depth : tile_size * depth_grids;
final_vase_tilt_angle = min(adj_opp_to_ang(tile_size * vertical_grids, vase_depth - 1), vase_tilt_angle);
vase_slot_overhang_angle = max(45, 45 + final_vase_tilt_angle - 15);
vase_height = ang_hyp_to_adj(final_vase_tilt_angle, tile_size * vertical_grids);
final_vase_front_inset_angle = min(adj_opp_to_ang(vase_height, max(0, vase_depth - ang_adj_to_opp(final_vase_tilt_angle, vase_height) - 1)), vase_front_inset_angle);
final_surface_texture_size = surface_texture_size * (vase_surface_texture == "checkers" || vase_surface_texture == "cubes" ? 2 : 1);

label_overhang_angle = max(10, 45 - final_vase_front_inset_angle);
label_side_clearance = 0.2;
label_depth_clearance = 0.3;
label_holder_wall_thickness = vase_slot_linewidth * 2;
label_holder_depth = label_depth + label_depth_clearance + label_holder_wall_thickness;
label_holder_side_width = vase_slot_linewidth * 4;
label_move =
  label_holder_type == "Split-Left" ? -vase_width / 2
  : label_holder_type == "Split-Right" ? vase_width / 2 : 0;
up(vase_height / 2) xrot(90 + final_vase_tilt_angle) {
    // right(vase_surface_texture != "" ? surface_texture_depth / 2 : 0)
    xrot(-final_vase_tilt_angle)
      diff(remove="root_rm") diff(remove="remove", keep="keep root_rm")
          prismoid(size1=[vase_width, vase_depth], h=vase_height, xang=[90, 90], yang=[90 - final_vase_front_inset_angle, 90 - final_vase_tilt_angle], chamfer=0, orient=FRONT, anchor=BACK) {
            attach(BACK, BOTTOM, spin=180)
              openconnect_slot_grid(grid_type="vase", horizontal_grids=horizontal_grids, vertical_grids=vertical_grids, tile_size=tile_size, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, overhang_angle=vase_slot_overhang_angle);
            if (vase_surface_texture != "") {
              frontwall_height = ang_adj_to_hyp(final_vase_front_inset_angle, vase_height) + ang_adj_to_opp(final_vase_front_inset_angle, surface_texture_depth);
              quant_texture_size = vase_surface_texture == "cubes" ? sqrt(3) * final_surface_texture_size : final_surface_texture_size;
              final_wall_height = quantup(frontwall_height, quant_texture_size);
              final_wall_width = quantup(vase_width, quant_texture_size);
              final_wall_depth = quantup(vase_depth, quant_texture_size);
              final_texture = vase_surface_texture == "checkers" ? texture(vase_surface_texture, border=0.2) : texture(vase_surface_texture);
              diff(remove="frontwall_rm") {
                attach(FRONT, BOTTOM, align=BOTTOM)
                  textured_tile(final_texture, w1=final_wall_width, w2=final_wall_width, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]) {
                    if (label_holder_type != "None")
                      right(label_move) tag("frontwall_rm")
                          attach(TOP, BOTTOM, align=FRONT, inside=true, shiftout=eps)
                            prismoid(size2=[label_width + label_side_clearance * 2, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=surface_texture_depth);
                  }
                tag("frontwall_rm") attach(BOTTOM, BACK)
                    cuboid([400, 400, 400]);
                tag("frontwall_rm") attach(LEFT, BACK)
                    cuboid([400, 400, 400]);
                tag("frontwall_rm") attach(RIGHT, BACK)
                    cuboid([400, 400, 400]);
              }
              diff(remove="sidewall_rm") {
                attach(LEFT, BOTTOM, align=BOTTOM)
                  textured_tile(final_texture, w1=final_wall_depth, w2=final_wall_depth, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                tag("sidewall_rm") attach(FRONT, BACK)
                    cuboid([400, 400, 400]);
                tag("sidewall_rm") attach(BACK, BACK)
                    cuboid([400, 400, 400]);
              }
              tag("remove") diff(remove="sidewall_rm") {
                  attach(RIGHT, BOTTOM, inside=true, align=BOTTOM)
                    textured_tile(final_texture, w1=final_wall_depth, w2=final_wall_depth, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                  tag("sidewall_rm") attach(FRONT, BACK, shiftout=eps)
                      cuboid([400, 400, 400]);
                  tag("sidewall_rm") attach(BACK, BACK, shiftout=eps)
                      cuboid([400, 400, 400]);
                }
              tag("root_rm")
                left(surface_texture_depth + 1) fwd(surface_texture_depth + 1)
                    edge_profile([LEFT + FRONT], excess=10)
                      mask2d_chamfer(x=surface_texture_depth * 2 + 2);
              tag("root_rm")
                right(surface_texture_depth) fwd(surface_texture_depth + 1)
                    edge_profile([RIGHT + FRONT], excess=10)
                      mask2d_chamfer(x=surface_texture_depth * 3 + 1);
              tag("root_rm") attach(TOP, BACK)
                  cuboid([400, 400, 400]);
            }
            else
              tag("root_rm")
                edge_profile([LEFT + FRONT, RIGHT + FRONT], excess=10)
                  mask2d_chamfer(x=1);
            if (label_holder_type != "None")
              right(label_move)
                tag_diff(tag="keep", remove="rm0") {
                  if (label_holder_type != "Split-Right")
                    right((label_width + label_side_clearance * 2) / 2)
                      attach(FRONT, BOTTOM, align=BOTTOM)
                        tag("") prismoid(size2=[label_holder_side_width, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth) {
                            attach(LEFT + BOTTOM, LEFT + BOTTOM, align=FRONT, inside=true)
                              tag("rm0") prismoid(size2=[label_holder_side_width - vase_slot_linewidth * 2, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth - label_holder_wall_thickness);
                          }
                  if (label_holder_type != "Split-Left")
                    left((label_width + label_side_clearance * 2) / 2)
                      attach(FRONT, BOTTOM, align=BOTTOM)
                        tag("") prismoid(size2=[label_holder_side_width, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth) {
                            attach(RIGHT + BOTTOM, RIGHT + BOTTOM, align=FRONT, inside=true)
                              tag("rm0") prismoid(size2=[label_holder_side_width - vase_slot_linewidth * 2, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth - label_holder_wall_thickness);
                          }
                }
          }
  }
