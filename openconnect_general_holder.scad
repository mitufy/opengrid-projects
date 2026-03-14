/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>

/* [Item Size] */
item_horizontal_count = 2;
item_vertical_count = 1;
//Dimensions of the item to be held. You can use slightly larger values for more wiggle room.
item_width = 40;
item_depth = 25;
//By increasing corner_rounding, you can generate circular and elliptic shapes.
item_corner_rounding = 10;
//Make holder narrower as it goes down. 
item_width_taper_angle = 0; //[0:5:45]
item_depth_taper_angle = 0; //[0:5:45]

/* [Holder Main] */
//Minimum holder height is affected by tilt angle. A vertical holder cannot be shorter than 18mm, a 45-degree tilted holder cannot be shorter than 26mm.
holder_height = 28;
holder_bottom_thickness = 2;
holder_outer_wall_thickness = 2.4; //0.1
holder_width_divider_wall_thickness = 1.6; //0.1
holder_depth_divider_wall_thickness = 1.6; //0.1
holder_back_offset = 0;
//Tilt the container forward for easier access of content. Set to 0 for a standard vertical holder.
holder_tilt_angle = 0; //[0:5:45]

/* [Holder Misc] */
//Cutting a hole in the front.
holder_front_cutoff_width = 12;
holder_front_cutoff_height = 20;
holder_front_cutoff_rounding = 3;

/* [openConnect Slot Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
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
holder_width = max(OG_TILE_SIZE, item_width * item_horizontal_count + holder_width_divider_wall_thickness * max(0, item_horizontal_count - 1) + holder_outer_wall_thickness * 2);
holder_depth = item_depth * item_vertical_count + holder_depth_divider_wall_thickness * max(0, item_vertical_count - 1) + holder_outer_wall_thickness + slot_wall_thickness;
holder_added_depth = holder_depth + holder_back_offset;
final_holder_height = max(ang_adj_to_hyp(holder_tilt_angle, slot_wall_min_height), holder_height);

final_item_rounding = min(item_corner_rounding, item_width / 2, item_depth / 2);
holder_shape = rect([holder_width, holder_added_depth], rounding=[final_item_rounding, final_item_rounding, 0, 0]);

item_height = final_holder_height - max(0, holder_bottom_thickness);
final_front_cutoff_height = min(holder_front_cutoff_height, item_height);
front_cutoff_outer_fillet = max(0, min(holder_front_cutoff_rounding, (item_width - holder_front_cutoff_width) / 2));
front_cutoff_inner_fillet = max(0, min(holder_front_cutoff_rounding, holder_front_cutoff_width / 2));

// item_tilt_depth = item_depth - ang_adj_to_opp(holder_tilt_angle, item_height);
final_depth_taper = min(item_depth_taper_angle, adj_opp_to_ang(item_height, item_depth / 2 - 0.5));
final_width_taper = min(item_width_taper_angle, adj_opp_to_ang(item_height, item_width / 2 - 0.5));
item_taper_depth = item_depth - ang_adj_to_opp(final_depth_taper, item_height) * 2;
item_taper_width = item_width - ang_adj_to_opp(final_width_taper, item_height) * 2;
item_shape = rect([item_width, item_depth], rounding=final_item_rounding);
item_width_scale = item_taper_width / item_width;
item_depth_scale = item_taper_depth / item_depth;

final_slot_h_grids = max(1, floor(holder_width / OG_TILE_SIZE));
final_slot_v_grids = max(1, floor(ang_hyp_to_adj(holder_tilt_angle, final_holder_height) / OG_TILE_SIZE));

// xrot(-holder_tilt_angle)
// hide_this()
prismoid(size1=[holder_width, holder_added_depth], h=final_holder_height, xang=[90, 90], yang=[90 + holder_tilt_angle, 90], rounding=[5, 5, 0, 0]) diff() {
    //back holder part, a triangle holder_tilt_angle
    if (holder_tilt_angle > 0)
      attach(FRONT, TOP, align=BOTTOM, inside=true)
        #tag("") prismoid(size1=[holder_width, 0], h=ang_hyp_to_opp(holder_tilt_angle, final_holder_height), xang=[90, 90], yang=[180 - holder_tilt_angle, 90]) {
            #attach(TOP, TOP, align=BACK, inside=true)
              tag("remove") openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS);
          }
    else
      #attach(FRONT, TOP, align=TOP, inside=true)
        tag("remove") openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS);
    //main holder part
    // attach(BOTTOM, TOP, inside=true)
    *diff() {
      tag("") linear_sweep(region=holder_shape, height=final_holder_height, scale=[1, 1], shift=[0, 0]) {
          // fwd(holder_outer_wall_thickness - slot_wall_thickness - holder_back_offset / 2)
        }
      // grid_copies(spacing=[item_width + holder_width_divider_wall_thickness, item_depth + holder_depth_divider_wall_thickness], n=[item_horizontal_count, item_vertical_count])
      // fwd(holder_outer_wall_thickness - slot_wall_thickness - holder_back_offset / 2)
      // up((final_holder_height - item_height) / 2) up(10)
      // tag("remove") 
      back(20) #linear_sweep(region=item_shape, height=item_height, scale=[item_width_scale, item_depth_scale], shift=[0, 0]);
    }
    front_cutoff_depth = item_width - final_item_rounding * 2 - holder_front_cutoff_width > 0 ? holder_outer_wall_thickness : holder_outer_wall_thickness + final_item_rounding;
    if (holder_front_cutoff_width > 0 && holder_front_cutoff_height > 0)
      *tag_diff(tag="remove", remove="rm1")
        line_copies(spacing=item_width + holder_width_divider_wall_thickness, n=item_horizontal_count)
          attach(TOP, TOP, align=BACK, inset=-EPS, inside=true)
            tag("") prismoid(size2=[holder_front_cutoff_width, front_cutoff_depth], h=final_front_cutoff_height, xang=[90, 90], yang=[90 - final_depth_taper, 90]) {
                if (front_cutoff_outer_fillet > 0)
                  fwd(ang_adj_to_opp(final_depth_taper, front_cutoff_outer_fillet) / 2)
                    tag("") edge_mask(holder_bottom_thickness > 0 || final_front_cutoff_height < item_height ? [TOP + LEFT, TOP + RIGHT] : [TOP + LEFT, TOP + RIGHT, BOTTOM + LEFT, BOTTOM + RIGHT])
                        rounding_edge_mask(r=front_cutoff_outer_fillet, spin=90, l=$edge_length + ang_adj_to_opp(final_depth_taper, front_cutoff_outer_fillet));
                if (front_cutoff_inner_fillet > 0 && (holder_bottom_thickness > 0 || final_front_cutoff_height < item_height))
                  tag("rm1") edge_mask([BOTTOM + LEFT, BOTTOM + RIGHT])
                      rounding_edge_mask(r=front_cutoff_inner_fillet);
              }
  }
