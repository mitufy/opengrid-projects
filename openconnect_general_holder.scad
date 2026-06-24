/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
compartment_shape = "Rectangular"; //[Rectangular,Circular,Elliptic]
//The width of each compartment. Use slightly larger values for more wiggle room.
compartment_width = 40;
//The depth of each compartment. Doesn't apply to Circular-shaped compartments, as their depth follows the width.
compartment_depth = 25;
//The height of each compartment. The minimum value for compartment_height+holder_bottom_thickness is around 18.
compartment_height = 26;
//By setting column and row count, you can generate a holder that can hold (column x row) objects.
compartment_column_count = 2;
compartment_row_count = 1;
//This value only applies to Rectangular-shaped compartments.
compartment_corner_rounding = 3;

/* [Holder Body] */
//Setting this value to 0 generates a bottomless holder.
holder_bottom_thickness = 2; //0.1
//The thickness of the outer wall of the holder.
holder_outer_wall_thickness = 2.4;
//Tilt the container forward for easier access of content. Set to 0 for a standard vertical holder.
holder_tilt_angle = 0; //[0:5:45]
//Increase this value if you want the object to be held farther away from the wall.
holder_back_offset = 0;
//"Tile Multiple" uses more space, but makes the sides of the holder align with openGrid tiles.
holder_width_mode = "Default"; //["Default", "Tile Multiple"]

/* [Taper Settings] */
//Enable taper to create a compartment shape that narrows as it goes down.
enable_bottom_taper = false;
//Bottom size of each compartment. Values are clamped so they never exceed the top opening.
compartment_bottom_width = 20;
//This value is ignored for circular compartments, as their bottom depth follows bottom width.
compartment_bottom_depth = 10;

/* [Front Opening] */
//Cuts an opening into the front wall.
front_opening_width = 12;
//Set this value equal to compartment_height to cut the front opening down to the bottom.
front_opening_height = 20;
front_opening_rounding = 3;

/* [openConnect Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces.
slot_entryramp_flip = false;

/* [Advanced Settings] */
//Affects the thickness of the divider walls between columns.
holder_vertical_divider_thickness = 2.4; //0.4
//Affects the thickness of the divider walls between rows.
holder_horizontal_divider_thickness = 2.4; //0.4
//A larger value makes a circular compartment smoother, but also takes longer to generate. $fn in openscad.
compartment_max_facets = 128;
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
minimum_holder_width = max(OG_TILE_SIZE, compartment_width * compartment_column_count + holder_vertical_divider_thickness * max(0, compartment_column_count - 1) + holder_outer_wall_thickness * 2);
holder_width = holder_width_mode == "Tile Multiple" ? ceil(minimum_holder_width / OG_TILE_SIZE) * OG_TILE_SIZE : minimum_holder_width;
holder_depth = final_compartment_depth * compartment_row_count + holder_horizontal_divider_thickness * max(0, compartment_row_count - 1) + holder_outer_wall_thickness + slot_wall_thickness;
final_holder_depth = holder_depth + holder_back_offset;
requested_holder_height = max(EPS, compartment_height) + max(0, holder_bottom_thickness);
provisional_holder_height = max(ang_adj_to_hyp(holder_tilt_angle, slot_wall_min_height), requested_holder_height);
//Keep the back wall at least 1mm deep at the base, even if that means reducing the requested tilt.
final_holder_tilt_angle = min(adj_opp_to_ang(provisional_holder_height, final_holder_depth - 1), holder_tilt_angle);
final_holder_height = max(ang_adj_to_hyp(final_holder_tilt_angle, slot_wall_min_height), requested_holder_height);

final_compartment_rounding = min(compartment_corner_rounding, compartment_width / 2, final_compartment_depth / 2);
final_holder_rounding = compartment_shape == "Rectangular" ? max(EPS, min(holder_width / 2, final_holder_depth / 2, final_compartment_rounding + holder_outer_wall_thickness)) : min(holder_width / 2, final_holder_depth / 2, final_compartment_depth / 2 + holder_outer_wall_thickness, compartment_width / 2 + holder_outer_wall_thickness);
holder_shape = rect([holder_width, final_holder_depth], rounding=[final_compartment_rounding, final_compartment_rounding, 0, 0]);

final_compartment_height = max(EPS, final_holder_height - max(0, holder_bottom_thickness));
final_front_opening_height = min(front_opening_height, final_compartment_height);
front_opening_outer_fillet = max(0, min(front_opening_rounding, (compartment_width - front_opening_width) / 2));
front_opening_inner_fillet = max(0, min(front_opening_rounding, front_opening_width / 2));

// compartment_tilt_depth = final_compartment_depth - ang_adj_to_opp(final_holder_tilt_angle, final_compartment_height);
final_compartment_taper_width = enable_bottom_taper ? min(compartment_width, max(1, compartment_bottom_width)) : compartment_width;
final_compartment_taper_depth =
  !enable_bottom_taper ? final_compartment_depth
  : compartment_shape == "Circular" ? final_compartment_taper_width
  : min(final_compartment_depth, max(1, compartment_bottom_depth));
final_depth_taper = adj_opp_to_ang(final_compartment_height, (final_compartment_depth - final_compartment_taper_depth) / 2);
final_width_taper = adj_opp_to_ang(final_compartment_height, (compartment_width - final_compartment_taper_width) / 2);
compartment_sweep_profile =
  compartment_shape == "Rectangular" ? rect([compartment_width, final_compartment_depth], rounding=final_compartment_rounding, $fn=compartment_max_facets)
  : compartment_shape == "Circular" ? circle(d=compartment_width, $fn=compartment_max_facets) : ellipse(d=[compartment_width, final_compartment_depth], $fn=compartment_max_facets);
compartment_width_scale = final_compartment_taper_width / compartment_width;
compartment_depth_scale = final_compartment_taper_depth / final_compartment_depth;

slot_face_height = ang_hyp_to_adj(final_holder_tilt_angle, final_holder_height);
final_slot_h_grids = max(1, floor(holder_width / OG_TILE_SIZE));
final_slot_v_grids = max(1, round(slot_face_height / OG_TILE_SIZE));
slot_flat_region = fwd((slot_face_height - round(slot_face_height / OG_TILE_SIZE) * OG_TILE_SIZE) / 2, rect([holder_width, slot_face_height]));

// xrot(-final_holder_tilt_angle)
right(holder_width / 2) zrot(180)
    diff() {
      back((final_compartment_depth * compartment_row_count) / 2 + (holder_horizontal_divider_thickness * max(0, compartment_row_count - 1)) / 2 + slot_wall_thickness + holder_back_offset)
        grid_copies(spacing=[compartment_width + holder_vertical_divider_thickness, final_compartment_depth + holder_horizontal_divider_thickness], n=[compartment_column_count, compartment_row_count])
          up(holder_bottom_thickness) xrot(180)
              tag("remove") linear_sweep(region=compartment_sweep_profile, height=final_compartment_height, scale=[compartment_width_scale, compartment_depth_scale], shift=[0, 0], anchor="original_top");
      prismoid(size1=[holder_width, final_holder_depth], h=final_holder_height, xang=[90, 90], yang=[90 + final_holder_tilt_angle, 90], rounding=[final_holder_rounding, final_holder_rounding, 0, 0], anchor=FRONT + BOTTOM) {
        attach(FRONT, TOP, align=TOP, inside=true) {
          tag("remove") openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[slot_flat_region]);
        }
        front_opening_depth = holder_outer_wall_thickness + final_compartment_depth / 2 - ang_adj_to_opp(final_depth_taper, final_compartment_height);
        if (front_opening_width > 0 && front_opening_height > 0)
          tag_diff(tag="remove", remove="rm1")
            line_copies(spacing=compartment_width + holder_vertical_divider_thickness, n=compartment_column_count)
              attach(TOP, TOP, align=BACK, inset=-EPS, inside=true)
                tag("") prismoid(size2=[front_opening_width, front_opening_depth], h=final_front_opening_height, xang=[90, 90], yang=[90 - final_depth_taper, 90]) {
                    if (front_opening_outer_fillet > 0)
                      fwd(ang_adj_to_opp(final_depth_taper, front_opening_outer_fillet) / 2)
                        tag("") edge_mask(holder_bottom_thickness > 0 || final_front_opening_height < final_compartment_height ? [TOP + LEFT, TOP + RIGHT] : [TOP + LEFT, TOP + RIGHT, BOTTOM + LEFT, BOTTOM + RIGHT])
                            rounding_edge_mask(r=front_opening_outer_fillet, spin=90, l=$edge_length + ang_adj_to_opp(final_depth_taper, front_opening_outer_fillet));
                    if (front_opening_inner_fillet > 0 && (holder_bottom_thickness > 0 || final_front_opening_height < final_compartment_height))
                      tag("rm1") edge_mask([BOTTOM + LEFT, BOTTOM + RIGHT])
                          rounding_edge_mask(r=front_opening_inner_fillet);
                  }
      }
    }
