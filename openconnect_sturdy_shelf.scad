/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
connector_cutout_delete_tool() is written by BlackJackDuck. https://github.com/AndyLevesque/QuackWorks
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [Main Settings] */
horizontal_grids = 3;
//Depth is not technically restrained by grid. You can override this with "use_custom_depth" below.
depth_grids = 3;
//"Standard" for maximum strength, "Slim" for lightweight applications.
shelf_type = "Standard"; //["Standard", "Slim"]
shelf_back_thickness = 4.4;
//When connector holes are enabled, bottom thickness would be at least 3.7mm.
shelf_bottom_thickness = 3.7;
//corner_fillet needs to be larger than thickness to have effect.
shelf_corner_fillet = 8;

/* [Truss Settings] */
truss_thickness = 3;
//0.7 means truss would reach 70% of shelf depth.
truss_beam_reach = 0.7; //[0.0:0.05:1]
//Space between each vertical truss strut. Set to 0 to disable.
truss_strut_interval = 28;

/* [Texture Settings] */
//Texture improves the appearance of the shelf by hiding layer lines and other artifacts caused by 3d printing.
add_texture = true;
shelf_texture_depth = 0.3;
//A small texture size makes model generation take longer.
shelf_texture_size = 20;

/* [Shelf Edge Settings] */
add_left_edge = true;
//Connector holes allow you to print shelf parts separately and later combine them together.
add_left_connector_holes = false;
add_right_edge = true;
//Connectors used are the same as openGrid boards. 
add_right_connector_holes = false;
shelf_side_edge_depth = 2;

add_front_edge = true;
shelf_front_edge_depth = 2;

/* [Advanced Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//The slot entry direction can matter when installing in very tight spaces. Note the side with the locking mechanism should be closer to the print bed.
slot_direction_flip = false;
use_custom_depth = false;
custom_depth = 80;
truss_rounding = 3; //0.2
shelf_side_edge_thickness = 1;
shelf_front_edge_thickness = 1;

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

//code by BlackJackDuck
module connector_cutout_delete_tool(anchor = CENTER, spin = 0, orient = UP) {
  //Begin connector cutout profile
  connector_cutout_radius = 2.6;
  connector_cutout_dimple_radius = 2.7;
  connector_cutout_separation = 2.5;
  connector_cutout_height = 2.4;
  dimple_radius = 0.75 / 2;

  attachable(anchor, spin, orient, size=[connector_cutout_radius * 2 - 0.1, connector_cutout_radius * 2, connector_cutout_height]) {
    //connector cutout tool
    tag_scope()
      translate([-connector_cutout_radius + 0.05, 0, -connector_cutout_height / 2])
        render()
          half_of(RIGHT, s=connector_cutout_dimple_radius * 4)
            linear_extrude(height=connector_cutout_height)
              union() {
                left(0.1)
                  diff() {
                    $fn = 50;
                    //primary round pieces
                    hull()
                      xcopies(spacing=connector_cutout_radius * 2)
                        circle(r=connector_cutout_radius);
                    //inset clip
                    tag("remove")
                      right(connector_cutout_radius - connector_cutout_separation)
                        ycopies(spacing=(connector_cutout_radius + connector_cutout_separation) * 2)
                          circle(r=connector_cutout_dimple_radius);
                    //dimple (ass) to force seam. Only needed for positive connector piece (not delete tool)
                    //tag("remove")
                    //right(connector_cutout_radius*2 + 0.45 )//move dimple in or out
                    //    yflip_copy(offset=(dimple_radius+connector_cutout_radius)/2)//both sides of the dimpme
                    //        rect([1,dimple_radius+connector_cutout_radius], rounding=[0,-connector_cutout_radius,-dimple_radius,0], $fn=32); //rect with rounding of inner flare and outer smoothing
                  }
                //outward flare fillet for easier insertion
                rect([1, connector_cutout_separation * 2 - (connector_cutout_dimple_radius - connector_cutout_separation)], rounding=[0, -.25, -.25, 0], $fn=32, corner_flip=true, anchor=LEFT);
              }
    children();
  }
}

top_vertical_grids = 1;
bottom_vertical_grids = 1;
//Side edge angle is capped at 45 to avoid sharp overhang.
shelf_side_edge_angle = 45; //[15:15:45]
shelf_front_edge_angle = 45; //[15:15:90]

shelf_depth = use_custom_depth ? custom_depth : tile_size * depth_grids;
shelf_width = tile_size * horizontal_grids;

shelf_linewidth = 0.42;
final_shelf_bottom_thickness = add_left_connector_holes || add_right_connector_holes ? max(shelf_bottom_thickness, 2.4 + shelf_linewidth * 3) : shelf_bottom_thickness;
bottom_shelf_back_height = tile_size * bottom_vertical_grids + final_shelf_bottom_thickness;
top_shelf_back_height = tile_size * top_vertical_grids - final_shelf_bottom_thickness;

top_sweep_startend_offset = 2;
top_sweep_rect_height = min(shelf_back_thickness, final_shelf_bottom_thickness);
final_shelf_corner_fillet = shelf_corner_fillet < 4 ? 0 : min(top_shelf_back_height, shelf_depth, shelf_corner_fillet);
top_sweep_path = ["setdir", -90, "move", top_sweep_startend_offset, "arcleft", final_shelf_corner_fillet, 90, "move", top_sweep_startend_offset];
top_base_rect_2d = rect([top_sweep_rect_height, shelf_width], anchor=TOP + LEFT);
top_left_edge_2d = right(top_sweep_rect_height, zrot(-90, trapezoid(h=shelf_side_edge_depth, w1=shelf_side_edge_thickness + shelf_side_edge_depth, ang=[90, shelf_side_edge_angle], anchor=LEFT + BOTTOM)));
top_right_edge_2d = right(top_sweep_rect_height, fwd(shelf_width, zrot(-90, trapezoid(h=shelf_side_edge_depth, w1=shelf_side_edge_thickness + shelf_side_edge_depth, ang=[shelf_side_edge_angle, 90], anchor=RIGHT + BOTTOM))));
top_sweep_profile =
  !add_left_edge && !add_right_edge ? top_base_rect_2d
  : add_left_edge && add_right_edge ? union(top_base_rect_2d, top_left_edge_2d, top_right_edge_2d)
  : !add_left_edge ? union(top_base_rect_2d, top_right_edge_2d) : union(top_base_rect_2d, top_left_edge_2d);

truss_depth = truss_beam_reach <= 0 ? 0 : (shelf_depth - shelf_back_thickness) * truss_beam_reach;
truss_height = truss_beam_reach <= 0 ? 0 : bottom_shelf_back_height - final_shelf_bottom_thickness;
truss_angle = truss_beam_reach <= 0 ? 0 : adj_opp_to_ang(truss_depth, truss_height);
truss_inner_depth = truss_beam_reach <= 0 ? 0 : truss_depth - ang_opp_to_hyp(truss_angle, truss_thickness);
truss_inner_height = truss_beam_reach <= 0 ? 0 : truss_height - ang_adj_to_hyp(truss_angle, truss_thickness);

diff(remove="outer_rm")
  cuboid([shelf_depth, final_shelf_bottom_thickness, shelf_width], anchor=FRONT + LEFT + BOTTOM) {
    rough_wall_alignment =
      add_left_edge == add_right_edge ? CENTER
      : add_left_edge ? BOTTOM : TOP;
    rough_wall_width_offset = (add_left_edge ? shelf_side_edge_depth + shelf_side_edge_thickness : 0) + (add_right_edge ? shelf_side_edge_depth + shelf_side_edge_thickness : 0);
    if (add_left_connector_holes)
      left(shelf_depth % tile_size / 2)
        attach(TOP, LEFT, inside=true, align=FRONT, inset=shelf_linewidth * 2)
          tag("outer_rm") line_copies(spacing=tile_size, n=floor(shelf_depth / tile_size)) connector_cutout_delete_tool(anchor=LEFT);
    if (add_right_connector_holes)
      left(shelf_depth % tile_size / 2)
        attach(BOTTOM, LEFT, inside=true, align=FRONT, inset=shelf_linewidth * 2)
          tag("outer_rm") line_copies(spacing=tile_size, n=floor(shelf_depth / tile_size)) connector_cutout_delete_tool(anchor=LEFT);
    if (add_texture)
      attach(BACK, BOTTOM, align=rough_wall_alignment)
        textured_tile("rough", w1=shelf_depth, w2=shelf_depth, ysize=shelf_width - rough_wall_width_offset, tex_depth=shelf_texture_depth, tex_size=[shelf_texture_size, shelf_texture_size], style="min_edge");
    if (add_left_edge)
      tag("") edge_profile([TOP + BACK], excess=0)
          back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
            yflip()
              mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
    if (add_right_edge)
      tag("") edge_profile([BOTTOM + BACK], excess=0)
          back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
            yflip()
              mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
    if (add_front_edge)
      tag("") edge_profile([BACK + RIGHT], excess=0)
          right(shelf_front_edge_thickness + (shelf_front_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_front_edge_angle, shelf_front_edge_depth)))
            mask2d_rabbet(size=[shelf_front_edge_thickness, shelf_front_edge_depth], mask_angle=shelf_front_edge_angle, spin=180);

    if (shelf_type != "Slim") {
      if (truss_inner_depth <= 0 || truss_inner_height <= 0 || truss_thickness <= eps)
        right(shelf_back_thickness) edge_mask(LEFT + FRONT)
            tag("") rounding_edge_mask(r=min(truss_thickness * 3, tile_size - final_shelf_bottom_thickness), spin=-90);
      //bottom shelf truss
      else {
        if (truss_inner_depth > 0 && truss_inner_height > 0) {
          truss_profile = difference(
            right_triangle([truss_depth, truss_height]),
            round_corners(joint=min(truss_rounding, truss_inner_depth / 2 - eps, truss_inner_height / 2 - eps), path=right_triangle([truss_inner_depth, truss_inner_height]))
          );
          if (truss_strut_interval > eps) {
            truss_strut_count = floor((truss_inner_depth - floor(truss_inner_depth / truss_strut_interval) * truss_thickness) / truss_strut_interval);
            intersect() {
              for (i = [0:truss_strut_count - 1]) {
                attach(FRONT, BACK, align=LEFT, inset=(i + 1) * truss_strut_interval - i * truss_thickness)
                  tag("") cuboid([truss_thickness, truss_height, shelf_width]);
              }
              right(shelf_back_thickness) xflip()
                  attach(FRONT, FRONT, align=RIGHT)
                    tag("intersect") linear_sweep(right_triangle([truss_depth, truss_height]), shelf_width);
            }
          }
          right(shelf_back_thickness) xflip()
              attach(FRONT, FRONT, align=RIGHT)
                linear_sweep(truss_profile, shelf_width) {
                  if (truss_beam_reach < 1)
                    edge_mask([RIGHT + FRONT])
                      tag("") rounding_edge_mask(r=min(20, (shelf_depth - shelf_back_thickness) * (1 - truss_beam_reach)), h=shelf_width, ang=180 - truss_angle, spin=truss_angle);
                }
        }
      }
    }
    //unused top shelf corner filler
    if (final_shelf_corner_fillet > eps)
      tag_diff(tag="", remove="remove") {
        attach(BACK, FRONT, align=LEFT, inset=shelf_back_thickness)
          cuboid([final_shelf_corner_fillet, final_shelf_corner_fillet, shelf_width])
            back(final_shelf_corner_fillet / 2 - final_shelf_bottom_thickness / 2) right(final_shelf_corner_fillet / 2 - shelf_back_thickness / 2)
                tag("remove") cyl(r=final_shelf_corner_fillet, h=shelf_width + eps * 2);
      }
    //top shelf back
    tag_diff(tag="", remove="remove")
      attach(BACK, FRONT, align=LEFT)
        cuboid([shelf_back_thickness, top_shelf_back_height, shelf_width]) {
          if (add_texture)
            attach(RIGHT, BOTTOM, align=rough_wall_alignment)
              textured_tile("rough", w1=top_shelf_back_height, w2=top_shelf_back_height, ysize=shelf_width - rough_wall_width_offset, tex_depth=shelf_texture_depth, tex_size=[shelf_texture_size, shelf_texture_size], style="min_edge");
          if (add_left_edge)
            edge_profile([TOP + RIGHT], excess=0)
              back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
                yflip()
                  tag("") mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
          if (add_right_edge)
            edge_profile([BOTTOM + RIGHT], excess=0)
              back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
                yflip()
                  tag("") mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
          if (final_shelf_corner_fillet > eps)
            right(max(0, shelf_back_thickness - final_shelf_bottom_thickness)) back(max(0, final_shelf_bottom_thickness - shelf_back_thickness)) fwd(final_shelf_bottom_thickness) fwd(top_shelf_back_height - final_shelf_corner_fillet - top_sweep_startend_offset)
                    attach(BACK + LEFT, BACK + LEFT, inside=true)
                      tag("") path_sweep(top_sweep_profile, path=path_merge_collinear(turtle(top_sweep_path)), scale=[1, 1], $fn=128);
          if (shelf_type == "Slim")
            attach(LEFT, TOP, inside=true, spin=90)
              tag("remove") openconnect_slot_grid(horizontal_grids=horizontal_grids, vertical_grids=top_vertical_grids, tile_size=tile_size, slot_lock_distribution=slot_lock_distribution, slot_direction_flip=slot_direction_flip, excess_thickness=0);
        }
    //bottom back and slots
    fwd(shelf_type == "Slim" ? 0 : tile_size)
      attach(FRONT + LEFT, FRONT + LEFT, inside=true)
        cuboid([shelf_back_thickness, shelf_type == "Slim" ? tile_size : tile_size * 2, shelf_width])
          attach(LEFT, TOP, align=BACK, inside=true, spin=90)
            tag("outer_rm") openconnect_slot_grid(horizontal_grids=horizontal_grids, vertical_grids=shelf_type == "Standard" ? top_vertical_grids + bottom_vertical_grids : top_vertical_grids, tile_size=tile_size, slot_lock_distribution=slot_lock_distribution, slot_direction_flip=slot_direction_flip, excess_thickness=eps);
  }