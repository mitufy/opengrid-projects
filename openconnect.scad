/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

/* [Plate Settings] */
plate_size_unit = "mm"; //[grid:Grid Count, mm:Millimeter]
//Depending on the plate_size_unit selected, you can input number either in grids or in millimeters.
plate_horizontal_size = 84;
plate_vertical_size = 56;
//You can set this to 0 if your model already has a wall and you don't want to thicken it. Does not affect Negative slots.
plate_extra_thickness = 0.5;
//Slot alignment applies when the plate size is entered in millimeters and is not divisible by the tile_size (28mm).
plate_slot_alignment = "Center"; //["Center", "Top", "Bottom", "Left", "Right"]
plate_corner_rounding = "None"; //["None", "Chamfer", "Fillet"]
plate_corner_rounding_size = 1;

/* [Slot Settings] */
//"Standard" to add to models. "Negative" to subtract from models. "Vase Mode" to add to specific models designed for vase mode.
slot_type = "slot"; //[slot:Standard,negslot:Negative, vase:Vase Mode]
//For vase mode slots. This value should match the slicer's linewidth setting when printing in vase mode.
vase_slot_linewidth = 0.6;
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Slot entry direction can matter in tight spaces. When printing on the side, place the locking mechanism side closer to the print bed.
slot_direction_flip = false;
//Increase this value if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
//Ensures minimum width for bridges. "Both" is default for compatibility, though only one (or none) may be needed depending on orientation.
slot_bridge_widen = "Both"; //[Both, Top, Side, None]
//Minimum width for bridges when slot_bridge_widen is enabled. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_bridge_min_width = 0.8; //0.01
//Slot bottom acts as a wall when printed on its side. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_bottom_min_thickness = 0.8; //0.01

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//Double Lock can be very difficult to install. They are intended for small models that only use one or two slots. 
ocslot_lock_position = "Left"; //[Left:Standard, Both:Double]
generate_screw = "None"; //["None", "openConnect", "openConnect (Folded)"]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol at the bottom.
threads_type = "Blunt"; //["Blunt", "Basic"]
snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]

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
ocslot_bridge_min_width = slot_bridge_min_width;
ocslot_bridge_widen = slot_bridge_widen;
ocslot_bottom_min_thickness = slot_bottom_min_thickness;
ocslot_side_clearance = slot_side_clearance;
ocslot_depth_clearance = 0.12;

ocslot_bottom_height = ochead_bottom_height + ang_adj_to_opp(45 / 2, ocslot_side_clearance) + ocslot_depth_clearance;
ocslot_top_height = ochead_top_height - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_total_height = ocslot_top_height + ochead_middle_height + ocslot_bottom_height;
ocslot_nub_to_top_distance = ochead_nub_to_top_distance + ocslot_side_clearance;
ocslot_top_bridge_offset = ocslot_bridge_widen == "Both" || ocslot_bridge_widen == "Top" ? max(0, ocslot_bridge_min_width - ocslot_top_height) : 0;
ocslot_side_bridge_offset = ocslot_bridge_widen == "Both" || ocslot_bridge_widen == "Side" ? max(0, ocslot_bridge_min_width - ocslot_top_height) : 0;

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
module openconnect_slot(add_nubs = "Left", slot_direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_width, ocslot_total_height]) {
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
    ocslot_bridge_offset_profile = right(ocslot_side_bridge_offset / 2, back(ocslot_small_rect_width / 2 + ochead_back_pos_offset + ocslot_top_bridge_offset, rect([ocslot_small_rect_width + ocslot_side_bridge_offset, ocslot_small_rect_height + ocslot_move_distance + ocslot_onramp_clearance + ocslot_top_bridge_offset], chamfer=[ocslot_small_rect_chamfer + ocslot_top_bridge_offset + ocslot_side_bridge_offset, ocslot_small_rect_chamfer + ocslot_top_bridge_offset, 0, 0], anchor=BACK)));
    difference() {
      union() {
        openconnect_head(head_type="slot", add_nubs=add_nubs, excess_thickness=excess_thickness);
        back(ochead_back_pos_offset) xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance + ochead_back_pos_offset) xflip_copy() polygon(ocslot_side_excess_profile);
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
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width + ocvase_wall_thickness * 2, ocslot_large_rect_width + ocvase_wall_thickness * 2, ocslot_total_height]) {
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
module openconnect_slot_grid(grid_type = "slot", horizontal_grids = 1, vertical_grids = 1, tile_size = 28, slot_lock_distribution = "None", ocslot_lock_position = "Left", slot_direction_flip = false, excess_thickness = 0, overhang_angle = 45, anchor = BOTTOM, spin = 0, orient = UP) {
  grid_height = ocslot_total_height;
  attachable(anchor, spin, orient, size=[horizontal_grids * tile_size, vertical_grids * tile_size, grid_height]) {
    tag_scope() hide_this() cuboid([horizontal_grids * tile_size, vertical_grids * tile_size, grid_height]) {
          back(opengrid_snap_to_edge_offset) {
            if (slot_lock_distribution == "All" || slot_lock_distribution == "Staggered" || slot_lock_distribution == "None")
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger=slot_lock_distribution == "Staggered")
                attach(BOTTOM, BOTTOM, inside=true) {
                  if (grid_type == "slot")
                    openconnect_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? ocslot_lock_position : "", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                  else
                    openconnect_vase_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? ocslot_lock_position : "", overhang_angle=overhang_angle);
                }
            if (slot_lock_distribution == "Staggered")
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger="alt")
                attach(BOTTOM, BOTTOM, inside=true) {
                  if (grid_type == "slot")
                    openconnect_slot(add_nubs=ocslot_lock_position, slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                  else
                    openconnect_vase_slot(add_nubs=ocslot_lock_position, overhang_angle=overhang_angle);
                }
            if (slot_lock_distribution == "Corners" || slot_lock_distribution == "Top Corners") {
              if (slot_lock_distribution == "Corners")
                grid_copies([tile_size * max(1, horizontal_grids - 1), tile_size * max(1, vertical_grids - 1)], [min(horizontal_grids, 2), min(vertical_grids, 2)])
                  attach(BOTTOM, BOTTOM, inside=true) {
                    if (grid_type == "slot")
                      openconnect_slot(add_nubs=ocslot_lock_position, slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                    else
                      openconnect_vase_slot(add_nubs=ocslot_lock_position, overhang_angle=overhang_angle);
                  }
              else {
                back(tile_size * (vertical_grids - 1) / 2)
                  line_copies(spacing=tile_size * max(1, horizontal_grids - 1), n=min(2, horizontal_grids))
                    attach(BOTTOM, BOTTOM, inside=true) {
                      if (grid_type == "slot")
                        openconnect_slot(add_nubs=ocslot_lock_position, slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                      else
                        openconnect_vase_slot(add_nubs=ocslot_lock_position, overhang_angle=overhang_angle);
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
                              openconnect_slot(add_nubs="", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                            else
                              openconnect_vase_slot(add_nubs="", overhang_angle=overhang_angle);
                          }
                    }
                    else
                      line_copies(spacing=tile_size, n=horizontal_grids)
                        attach(BOTTOM, BOTTOM, inside=true) {
                          if (grid_type == "slot")
                            openconnect_slot(add_nubs="", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                          else
                            openconnect_vase_slot(add_nubs="", overhang_angle=overhang_angle);
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

//BEGIN openConnect connectors
text_depth = 0.4;
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
fold_gap_width = 0.4;
fold_gap_height = 0.2;
connector_coin_slot_height = 2.6;
connector_coin_slot_width = 13;
connector_coin_slot_thickness = 2.4;
connector_coin_slot_radius = connector_coin_slot_height / 2 + connector_coin_slot_width ^ 2 / (8 * connector_coin_slot_height);
connector_flat_slot_height = 4.4;
connector_flat_slot_width = 6.5;
connector_flat_slot_height_offset = 0.7;
connector_flat_slot_start_thickness = 1.8;
connector_flat_slot_end_thickness = 1.2;

// /* [Threads Settings] */
threads_diameter = 16;
threads_clearance = 0.5;
threads_compatiblity_angle = 53.5;
threads_rotate_angle = 45;
threads_top_bevel = 0.5; //0.1
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1
threads_negative_diameter = threads_diameter + threads_clearance;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

threads_height = snap_thickness;
threads_bottom_bevel =
  snap_thickness == 6.8 ? threads_bottom_bevel_standard
  : snap_thickness == 4 ? threads_bottom_bevel_lite
  : 0;

add_threads_blunt_text = true;
threads_blunt_text = "🔓";
threads_blunt_text_font = "Noto Emoji"; // font
threads_pitch = 3;

final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

module openconnect_screw(threads_height = threads_height, folded = false) {
  fold_for_printing(body_thickness=snap_thickness + ochead_total_height, fold_position=ochead_middle_to_bottom + eps, fold_sliceoff=fold_gap_width / 2, condition=folded) {
    up(threads_height + ochead_total_height) xrot(180) zrot(180)
          difference() {
            union() {
              up(ochead_total_height - eps)
                zrot(threads_compatiblity_angle) {
                  if (threads_type == "Blunt")
                    blunt_threaded_rod(diameter=threads_diameter, rod_height=threads_height, top_bevel=0, top_cutoff=true);
                  else
                    generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
                }
              intersection() {
                //cut off the part of connector head that may cause overhang
                if (!folded)
                  up(ochead_total_height - eps) right(0.32) back(0.45) cyl(d2=threads_diameter - 0.4, d1=threads_diameter - 0.4 + ochead_total_height * 2, h=ochead_total_height, anchor=TOP);
                openconnect_head(head_type="head", add_nubs="Both");
              }
            }
            up(ochead_total_height) back(folded ? 2 : 0) {
                if (add_threads_blunt_text && threads_type == "Blunt")
                  up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_text, size=4, anchor=str("center", CENTER), font=threads_blunt_text_font);
                if (final_add_thickness_text)
                  up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_text && threads_type == "Blunt" ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
              }
            up(connector_coin_slot_height) zrot(90) xrot(90)
                  cyl(r=connector_coin_slot_radius, h=connector_coin_slot_thickness, $fn=128, anchor=BACK) {
                    //flat head slot
                    fwd(connector_flat_slot_height_offset)
                      attach(BACK, BOTTOM)
                        prismoid(size1=[connector_flat_slot_width, connector_flat_slot_start_thickness], size2=[undef, connector_flat_slot_end_thickness], h=connector_flat_slot_height - connector_coin_slot_height + connector_flat_slot_height_offset, xang=[90, 90]);
                    //cut off remaining coin slot part
                    left(connector_coin_slot_width / 2) attach(BACK, BACK, inside=true)
                        cuboid([connector_coin_slot_width, connector_coin_slot_radius, connector_coin_slot_thickness]);
                  }
          }
  }
}

module blunt_threaded_rod(diameter = threads_diameter, rod_height = snap_thickness, top_bevel = 0, bottom_bevel = 0, top_cutoff = false, blunt_ang = 10, anchor = CENTER, spin = 0, orient = UP) {
  min_turns = 0.5;
  offset_height = min(rod_height - 1.5 - bottom_bevel, 0);
  turns = max(0, (rod_height - 1.5 - bottom_bevel) / 3) + min_turns;
  attachable(anchor, spin, orient, d=diameter, h=rod_height) {
    tag_scope() difference() {
        union() {
          cyl(d=diameter - 2 + eps, h=rod_height, anchor=BOTTOM, $fn=256);
          difference() {
            zrot(0.25 * 120) up(0.25)
                zrot(-(min_turns * 3) * 120) up(-(min_turns * 3))
                    zrot(offset_height * 120) up(offset_height)
                        thread_helix(d=diameter, turns=turns, pitch=threads_pitch, profile=threads_profile, anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256);
            up(rod_height + (diameter + 2) / 2) cube(diameter + 2, center=true);
          }
        }
        if (top_cutoff || top_bevel > 0)
          down((diameter + 2) / 2) cube(diameter + 2, center=true);
        if (top_bevel > 0)
          rotate_extrude() left(diameter / 2 - top_bevel / 2 + eps) right_triangle([top_bevel + eps, top_bevel + eps], anchor=BOTTOM);
        if (bottom_bevel > 0)
          up(rod_height) rotate_extrude() right(diameter / 2 - bottom_bevel + eps) right_triangle([bottom_bevel + eps, bottom_bevel + eps], anchor=BOTTOM, spin=180);
      }
    children();
  }
}

module fold_for_printing(body_thickness, fold_position = 0, fold_gap_width = fold_gap_width, fold_gap_height = fold_gap_height, fold_sliceoff = 0, rmobj_size = 100, condition = true) {
  if (condition) {
    back(fold_position) yrot(180) {
        xrot(-90, cp=[0, -fold_position, 0])
          difference() {
            children();
            fwd(fold_position) cuboid([rmobj_size, rmobj_size, rmobj_size], anchor=BACK);
          }
        fwd(fold_gap_width - eps) up(fold_sliceoff)
            xrot(90, cp=[0, -(fold_position), 0])
              difference() {
                children();
                fwd(fold_position + fold_sliceoff)
                  cuboid([rmobj_size, rmobj_size, rmobj_size], anchor=FRONT);
              }

        fwd(fold_gap_width) xrot(-90, cp=[0, -fold_position, 0])
            linear_extrude(fold_gap_width + eps * 2) difference() {
                projection(cut=true)
                  down(0.01)
                    children();
                fwd(fold_position - fold_gap_height) rect([rmobj_size, rmobj_size], anchor=FRONT);
                fwd(fold_position) rect([rmobj_size, rmobj_size], anchor=BACK);
              }
      }
  }
  else
    children();
}
//END openConnect connectors

view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_overlapped = false;

half_of_anchor =
  view_cross_section == "Right" ? RIGHT
  : view_cross_section == "Back" ? BACK
  : view_cross_section == "Diagonal" ? RIGHT + BACK
  : 0;
if (half_of_anchor != 0)
  half_of(half_of_anchor) main_generate();
else
  main_generate();
module main_generate() {
  if (generate_screw == "openConnect" || generate_screw == "openConnect (Folded)")
    left(10) up(view_overlapped ? snap_thickness + ochead_total_height : 0) yrot(view_overlapped ? 180 : 0)
          openconnect_screw(folded=generate_screw == "openConnect (Folded)");
  if (slot_type != "None") {
    final_plate_width = max(1, plate_size_unit == "mm" ? plate_horizontal_size : plate_horizontal_size * tile_size);
    final_plate_h_grids = max(1, plate_size_unit == "mm" ? floor(plate_horizontal_size / tile_size) : plate_horizontal_size);
    final_plate_height = max(1, plate_size_unit == "mm" ? plate_vertical_size : plate_vertical_size * tile_size);
    final_plate_v_grids = max(1, plate_size_unit == "mm" ? floor(plate_vertical_size / tile_size) : plate_vertical_size);
    final_plate_thickness = slot_type == "negslot" ? eps : max(eps, slot_type == "vase" ? plate_extra_thickness : ocslot_total_height + plate_extra_thickness);
    final_plate_alignment =
      plate_slot_alignment == "Center" ? CENTER
      : plate_slot_alignment == "Top" ? BACK
      : plate_slot_alignment == "Bottom" ? FRONT
      : plate_slot_alignment == "Left" ? LEFT : RIGHT;
    down(final_plate_thickness == eps ? eps : 0) diff() hide("hidden")
          tag(final_plate_thickness == eps ? "hidden" : "") cuboid([final_plate_width, final_plate_height, final_plate_thickness], anchor=BOTTOM + FRONT + LEFT) {
              if (plate_corner_rounding != "None" && plate_corner_rounding_size > 0)
                edge_mask("Z") {
                  if (plate_corner_rounding == "Chamfer")
                    chamfer_edge_mask(chamfer=plate_corner_rounding_size);
                  if (plate_corner_rounding == "Fillet")
                    rounding_edge_mask(r=plate_corner_rounding_size);
                }
              if (slot_type == "slot")
                attach(TOP, TOP, align=final_plate_alignment, inside=true)
                  tag("remove") openconnect_slot_grid(grid_type=slot_type, horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, tile_size=tile_size, slot_lock_distribution=slot_lock_distribution, ocslot_lock_position=ocslot_lock_position, slot_direction_flip=slot_direction_flip, excess_thickness=0);
              else if (slot_type == "negslot")
                attach(TOP, BOTTOM, align=final_plate_alignment)
                  tag("") openconnect_slot_grid(grid_type="slot", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, tile_size=tile_size, slot_lock_distribution=slot_lock_distribution, ocslot_lock_position=ocslot_lock_position, slot_direction_flip=slot_direction_flip, excess_thickness=0);
              else if (slot_type == "vase")
                attach(TOP, BOTTOM, align=final_plate_alignment)
                  tag("") openconnect_slot_grid(grid_type=slot_type, horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, tile_size=tile_size, slot_lock_distribution=slot_lock_distribution, ocslot_lock_position=ocslot_lock_position, slot_direction_flip=slot_direction_flip, excess_thickness=0);
            }
  }
}
