/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
//Circular uses compartment_width as the diameter. Elliptic uses both width and depth.
compartment_shape = "Rectangular"; //[Rectangular,Circular,Elliptic]
//Inner opening size at the top of each pocket. Use slightly larger values for more wiggle room.
compartment_width = 40;
//This value is ignored for circular compartments, as their depth would always follow the width.
compartment_depth = 25;
compartment_column_count = 2;
compartment_row_count = 1;


/* [Holder Body] */
//"Tile Multiple" occupy more space, but makes the sides of the holder align with openGrid tiles.
body_width_mode = "Default"; //["Default", "Tile Multiple"]
//Minimum height is affected by tilt angle. A vertical holder cannot be shorter than 18mm, a 45-degree tilted holder cannot be shorter than 26mm.
body_height = 28;
body_bottom_thickness = 2;
body_vertical_wall_thickness = 2.4;
body_horizontal_wall_thickness = 2.4;
body_rear_extra_depth = 0;
//Tilt the container forward for easier access of content. Set to 0 for a standard vertical holder.
body_tilt_angle = 0; //[0:5:45]


/* [Taper Settings] */
enable_bottom_taper = false;
//Bottom size of each compartment. Values are clamped so they never exceed the top opening.
compartment_bottom_width = 20;
//Ignored for circular compartments, where bottom depth follows bottom width.
compartment_bottom_depth = 10;

/* [Front Opening] */
//Cuts a finger opening into the front wall.
front_opening_width = 12;
front_opening_height = 20;
front_opening_rounding = 3;

/* [openConnect Slots] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
slot_entryramp_flip = false;

/* [Advanced Settings] */
rect_compartment_corner_rounding = 3;
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1;
slot_depth_clearance = 0.1;
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8;
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6;

/* [Hidden] */
$fa = 1;
$fs = 0.4;

include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>

slot_edge_feature_widen = "Top";
//Slide and entry ramp direction can matter in tight spaces.
slot_slide_direction = "Up";
//A slot is generated for every tile by default.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Double Lock can be very difficult to install. They are intended for small models that only use one or two slots.
slot_lock_side = "Left"; //[Left:Standard, Both:Double]

_slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance
);

slot_wall_min_height = 18;
slot_wall_thickness = 1.2 + struct_val(_slot_cfg, "total_height");

final_compartment_depth = compartment_shape == "Circular" ? compartment_width : compartment_depth;
minimum_body_width = max(OG_TILE_SIZE, compartment_width * compartment_column_count + body_vertical_wall_thickness * max(0, compartment_column_count - 1) + body_vertical_wall_thickness * 2);
body_width = body_width_mode == "Tile Multiple" ? ceil(minimum_body_width / OG_TILE_SIZE) * OG_TILE_SIZE : minimum_body_width;
body_depth = final_compartment_depth * compartment_row_count + body_horizontal_wall_thickness * max(0, compartment_row_count - 1) + body_horizontal_wall_thickness + slot_wall_thickness;
final_body_depth = body_depth + body_rear_extra_depth;
provisional_body_height = max(ang_adj_to_hyp(body_tilt_angle, slot_wall_min_height), body_height);
//Keep the back wall at least 1mm deep at the base, even if that means reducing the requested tilt.
final_body_tilt_angle = min(adj_opp_to_ang(provisional_body_height, final_body_depth - 1), body_tilt_angle);
final_body_height = max(ang_adj_to_hyp(final_body_tilt_angle, slot_wall_min_height), body_height);

final_compartment_rounding = min(rect_compartment_corner_rounding, compartment_width / 2, final_compartment_depth / 2);
body_shape = rect([body_width, final_body_depth], rounding=[final_compartment_rounding, final_compartment_rounding, 0, 0]);

compartment_height = final_body_height - max(0, body_bottom_thickness);
final_front_opening_height = min(front_opening_height, compartment_height);
front_opening_outer_fillet = max(0, min(front_opening_rounding, (compartment_width - front_opening_width) / 2));
front_opening_inner_fillet = max(0, min(front_opening_rounding, front_opening_width / 2));

compartment_fn = 64;
// compartment_tilt_depth = final_compartment_depth - ang_adj_to_opp(final_body_tilt_angle, compartment_height);
final_compartment_taper_width = enable_bottom_taper ? min(compartment_width, max(1, compartment_bottom_width)) : compartment_width;
final_compartment_taper_depth =
  !enable_bottom_taper ? final_compartment_depth
  : compartment_shape == "Circular" ? final_compartment_taper_width
  : min(final_compartment_depth, max(1, compartment_bottom_depth));
final_depth_taper = adj_opp_to_ang(compartment_height, (final_compartment_depth - final_compartment_taper_depth) / 2);
final_width_taper = adj_opp_to_ang(compartment_height, (compartment_width - final_compartment_taper_width) / 2);
compartment_sweep_profile =
  compartment_shape == "Rectangular" ? rect([compartment_width, final_compartment_depth], rounding=final_compartment_rounding, $fn=compartment_fn)
  : compartment_shape == "Circular" ? circle(d=compartment_width, $fn=compartment_fn) : ellipse(d=[compartment_width, final_compartment_depth], $fn=compartment_fn);
compartment_width_scale = final_compartment_taper_width / compartment_width;
compartment_depth_scale = final_compartment_taper_depth / final_compartment_depth;

final_slot_h_grids = max(1, floor(body_width / OG_TILE_SIZE));
final_slot_v_grids = max(1, floor(ang_hyp_to_adj(final_body_tilt_angle, final_body_height) / OG_TILE_SIZE));

// xrot(-final_body_tilt_angle)
diff() {
  back(body_rear_extra_depth / 2) grid_copies(spacing=[compartment_width + body_vertical_wall_thickness, final_compartment_depth + body_horizontal_wall_thickness], n=[compartment_column_count, compartment_row_count])
      up(body_bottom_thickness) xrot(180)
          tag("remove") linear_sweep(region=compartment_sweep_profile, height=compartment_height, scale=[compartment_width_scale, compartment_depth_scale], shift=[0, 0], anchor="original_top");
  prismoid(size1=[body_width, final_body_depth], h=final_body_height, xang=[90, 90], yang=[90 + final_body_tilt_angle, 90], rounding=[5, 5, 0, 0]) {
    attach(FRONT, TOP, align=TOP, inside=true)
      tag("remove") openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS);

    front_opening_depth = body_horizontal_wall_thickness + final_compartment_depth / 2 - ang_adj_to_opp(final_depth_taper, compartment_height);
    if (front_opening_width > 0 && front_opening_height > 0)
      tag_diff(tag="remove", remove="rm1")
        line_copies(spacing=compartment_width + body_vertical_wall_thickness, n=compartment_column_count)
          attach(TOP, TOP, align=BACK, inset=-EPS, inside=true)
            tag("") prismoid(size2=[front_opening_width, front_opening_depth], h=final_front_opening_height, xang=[90, 90], yang=[90 - final_depth_taper, 90]) {
                if (front_opening_outer_fillet > 0)
                  fwd(ang_adj_to_opp(final_depth_taper, front_opening_outer_fillet) / 2)
                    tag("") edge_mask(body_bottom_thickness > 0 || final_front_opening_height < compartment_height ? [TOP + LEFT, TOP + RIGHT] : [TOP + LEFT, TOP + RIGHT, BOTTOM + LEFT, BOTTOM + RIGHT])
                        rounding_edge_mask(r=front_opening_outer_fillet, spin=90, l=$edge_length + ang_adj_to_opp(final_depth_taper, front_opening_outer_fillet));
                if (front_opening_inner_fillet > 0 && (body_bottom_thickness > 0 || final_front_opening_height < compartment_height))
                  tag("rm1") edge_mask([BOTTOM + LEFT, BOTTOM + RIGHT])
                      rounding_edge_mask(r=front_opening_inner_fillet);
              }
  }
}
