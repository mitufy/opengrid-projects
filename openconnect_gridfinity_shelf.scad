/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Gridfinity is created by Zack Freedman. https://gridfinity.xyz/
*/

/* [Gridfinity Settings] */
//An even number of width grids is recommended, as 2 Gridfinity cells (42mm x 2) line up with 3 openGrid cells (28mm x 3).
gridfinity_width_grids = 2;
gridfinity_depth_grids = 2;
magnet_position = "None"; //["None", "Corners Only", "All"]
magnet_diameter = 6.4; //0.1
magnet_thickness = 2.4; //0.1

/* [Shelf Rim] */
// Adds extra material to the left and right edges. The shelf width will no longer be an exact 42mm multiple.
shelf_side_rim = 0; //0.1
// Adds extra material to the front edge.
shelf_front_rim = 0; //0.1
// Adds a raised lip to help keep bins on the shelf. Only applies where a rim is enabled.
shelf_rim_lip_height = 0; //0.1

/* [openConnect Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces.
slot_entryramp_flip = false;
//Slot alignment applies when the shelf width is not an exact multiple of 28 mm.
slot_horizontal_alignment = "Center"; //["Center", "Left", "Right"]

/* [Advanced Settings] */
// Increase this if Gridfinity bins fit too tightly.
gridfinity_socket_clearance = 0; //0.01
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
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>

//A slot is generated for every tile by default.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//BEGIN gridfinity constants
GF_PITCH = 42;
GF_BASEPLATE_LOWER_TAPER_HEIGHT = 0.7;
GF_BASEPLATE_RISER_HEIGHT = 1.8;
GF_BASEPLATE_UPPER_TAPER_HEIGHT = 2.15;
GF_BASEPLATE_PROFILE_HEIGHT = GF_BASEPLATE_LOWER_TAPER_HEIGHT + GF_BASEPLATE_RISER_HEIGHT + GF_BASEPLATE_UPPER_TAPER_HEIGHT;
GF_NOMINAL_BIN_CLEARANCE = 0.5;
GF_TOP_CORNER_RADIUS = 4;
GF_MID_INSET = GF_BASEPLATE_LOWER_TAPER_HEIGHT;
GF_BOTTOM_INSET = GF_BASEPLATE_LOWER_TAPER_HEIGHT + GF_BASEPLATE_UPPER_TAPER_HEIGHT;
GF_MID_CORNER_RADIUS = GF_TOP_CORNER_RADIUS - GF_MID_INSET;
GF_BOTTOM_CORNER_RADIUS = GF_TOP_CORNER_RADIUS - GF_BOTTOM_INSET;
GF_ATTACHMENT_BORDER = 8;
GF_ATTACHMENT_EDGE_CLEARANCE = 4;
GF_ATTACHMENT_DIAMETER = max(0, magnet_diameter);
GF_ATTACHMENT_BOSS_DIAMETER = GF_ATTACHMENT_DIAMETER + 4;
GF_MAGNET_POSITION = min(GF_PITCH / 2 - GF_ATTACHMENT_BORDER, GF_PITCH / 2 - GF_ATTACHMENT_EDGE_CLEARANCE - GF_ATTACHMENT_DIAMETER / 2);
GF_SKELETON_PROFILE_MARGIN = 0.5;
GF_SKELETON_RAIL_WIDTH = GF_BOTTOM_INSET + GF_SKELETON_PROFILE_MARGIN;
GF_SKELETON_WINDOW_SIZE = GF_PITCH - GF_SKELETON_RAIL_WIDTH * 2;
GF_ATTACHMENT_BOSS_RAIL_OVERLAP = 2.4;
GF_ATTACHMENT_WINDOW_SIZE = max(1, min(GF_SKELETON_WINDOW_SIZE, (GF_MAGNET_POSITION + GF_ATTACHMENT_BOSS_DIAMETER / 2 - GF_ATTACHMENT_BOSS_RAIL_OVERLAP) * 2));
//END gridfinity constants

//BEGIN openConnect parameters
slot_edge_feature_widen = "Top"; //[Both, Top, Side, None]
slot_slide_direction = "Up"; //[Left,Right,Up,Down]
slot_lock_side = "Left"; //[Left:Standard, Both:Double]

_slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance
);
//END openConnect parameters

//BEGIN shelf parameters
final_gridfinity_width_grids = max(1, floor(gridfinity_width_grids));
final_gridfinity_depth_grids = max(1, floor(gridfinity_depth_grids));
final_magnet_position =
  magnet_position == "All" ? "All"
  : magnet_position == "Corners Only" ? "Corners Only"
  : "None";
final_magnet_diameter = max(0, magnet_diameter);
final_magnet_thickness = max(0, magnet_thickness);
magnet_holes_enabled = final_magnet_position != "None" && final_magnet_diameter > 0 && final_magnet_thickness > 0;
final_shelf_base_extra_thickness = magnet_holes_enabled && final_magnet_thickness > 2.4 ? final_magnet_thickness : 2.4;
final_socket_clearance = max(0, gridfinity_socket_clearance);
final_shelf_side_rim = max(0, shelf_side_rim);
final_shelf_front_rim = max(0, shelf_front_rim);

shelf_width = final_gridfinity_width_grids * GF_PITCH + final_shelf_side_rim * 2;
shelf_depth = final_gridfinity_depth_grids * GF_PITCH + final_shelf_front_rim;
shelf_deck_height = final_shelf_base_extra_thickness + GF_BASEPLATE_PROFILE_HEIGHT;
final_shelf_bottom_tilt_height = max(0, OG_TILE_SIZE - shelf_deck_height);

slot_h_grids = max(1, floor(shelf_width / OG_TILE_SIZE));

final_shelf_rim_lip_height = max(0, shelf_rim_lip_height);
has_side_lips = final_shelf_rim_lip_height > 0 && final_shelf_side_rim > 0;
has_front_lip = final_shelf_rim_lip_height > 0 && final_shelf_front_rim > 0;
side_wall = has_side_lips ? final_shelf_side_rim : 0;
front_wall = has_front_lip ? final_shelf_front_rim : 0;
inner_width = shelf_width - side_wall * 2;
inner_depth = shelf_depth - front_wall;
print_bottom_angle = final_shelf_bottom_tilt_height <= 0 ? 0 : atan(final_shelf_bottom_tilt_height / shelf_depth);

//END shelf parameters

//BEGIN generation
difference() {
  xrot(-print_bottom_angle) up(final_shelf_bottom_tilt_height)
      tag_diff(tag="", remove="rm1")
        cuboid([shelf_width, shelf_depth, shelf_deck_height], rounding=GF_TOP_CORNER_RADIUS, edges=[BACK + LEFT, BACK + RIGHT], anchor=FRONT + LEFT + BOTTOM) {
          fwd(final_shelf_front_rim / 2) down(shelf_deck_height / 2 - final_shelf_base_extra_thickness)
              force_tag("rm1") gridfinity_baseplate_cutouts();
          if (has_side_lips || has_front_lip)
            tag_diff(tag="", remove="rm0") {
              attach(TOP, BOTTOM)
                cuboid([shelf_width, shelf_depth, final_shelf_rim_lip_height], rounding=GF_TOP_CORNER_RADIUS, edges=[BACK + LEFT, BACK + RIGHT])
                  fwd(final_shelf_front_rim / 2) attach(TOP, TOP, inside=true)
                      tag("rm0") cuboid([inner_width, inner_depth, final_shelf_rim_lip_height + EPS], rounding=GF_TOP_CORNER_RADIUS, edges=has_side_lips && has_front_lip ? "Z" : has_front_lip ? [BACK + LEFT, BACK + RIGHT] : []);
            }
          if (final_shelf_bottom_tilt_height > 0)
            shelf_tilted_bottom();
        }
  xrot(90 - print_bottom_angle)
    openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=slot_h_grids, vertical_grids=1, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, excess_length=4, anchor=TOP + FRONT + LEFT);
}

//END generation
module shelf_tilted_bottom() {
  ztop = -shelf_deck_height / 2 + EPS;
  zback = ztop - final_shelf_bottom_tilt_height;
  bottom_mask_height = final_shelf_bottom_tilt_height + EPS * 4;

  intersection() {
    hull() {
      up(ztop)
        cuboid([shelf_width, shelf_depth, EPS], anchor=TOP);
      fwd(shelf_depth / 2) up(zback)
          cuboid([shelf_width, EPS, EPS], anchor=BOTTOM);
      back(shelf_depth / 2) up(ztop)
          cuboid([shelf_width, EPS, EPS], anchor=BOTTOM);
    }
    up(ztop - final_shelf_bottom_tilt_height / 2)
      cuboid([shelf_width, shelf_depth, bottom_mask_height], rounding=GF_TOP_CORNER_RADIUS, edges=[BACK + LEFT, BACK + RIGHT]);
  }
}

module gridfinity_baseplate_cutouts() {
  grid_copies(spacing=[GF_PITCH, GF_PITCH], n=[final_gridfinity_width_grids, final_gridfinity_depth_grids])
    gridfinity_socket_cutout();
  if (final_shelf_base_extra_thickness + final_shelf_bottom_tilt_height > 0)
    baseplate_window_cutouts();
  if (magnet_holes_enabled)
    magnet_position_copies()
      cyl(d=final_magnet_diameter, h=final_magnet_thickness, $fn=128, anchor=TOP);
}

module baseplate_window_cutouts() {
  window_size = magnet_holes_enabled ? GF_ATTACHMENT_WINDOW_SIZE : GF_SKELETON_WINDOW_SIZE;
  down(final_shelf_base_extra_thickness + final_shelf_bottom_tilt_height + EPS)
    linear_extrude(height=final_shelf_base_extra_thickness + final_shelf_bottom_tilt_height + EPS * 2)
      difference() {
        grid_copies(spacing=[GF_PITCH, GF_PITCH], n=[final_gridfinity_width_grids, final_gridfinity_depth_grids])
          rect([window_size, window_size], rounding=GF_BOTTOM_CORNER_RADIUS, $fn=64);
        if (magnet_holes_enabled)
          magnet_position_copies()
            circle(d=GF_ATTACHMENT_BOSS_DIAMETER, $fn=128);
      }
}

module magnet_position_copies() {
  corner_spacing = [
    (final_gridfinity_width_grids - 1) * GF_PITCH + GF_MAGNET_POSITION * 2,
    (final_gridfinity_depth_grids - 1) * GF_PITCH + GF_MAGNET_POSITION * 2,
  ];

  if (final_magnet_position == "All")
    grid_copies(spacing=[GF_PITCH, GF_PITCH], n=[final_gridfinity_width_grids, final_gridfinity_depth_grids])
      grid_copies(spacing=[GF_MAGNET_POSITION * 2, GF_MAGNET_POSITION * 2], n=[2, 2])
        children();
  else if (final_magnet_position == "Corners Only")
    grid_copies(spacing=corner_spacing, n=[2, 2])
      children();
}

module gridfinity_socket_cutout() {
  top_size = min(GF_PITCH + 0.2, GF_PITCH - GF_NOMINAL_BIN_CLEARANCE + final_socket_clearance);
  mid_size = max(1, top_size - GF_MID_INSET * 2);
  bottom_size = max(1, top_size - GF_BOTTOM_INSET * 2);
  top_radius = max(0.1, GF_TOP_CORNER_RADIUS);
  mid_radius = max(0.1, GF_MID_CORNER_RADIUS);
  bottom_radius = max(0.1, GF_BOTTOM_CORNER_RADIUS);

  hull() {
    linear_extrude(height=EPS)
      rect([bottom_size, bottom_size], rounding=bottom_radius, $fn=128);
    up(GF_BASEPLATE_LOWER_TAPER_HEIGHT)
      linear_extrude(height=EPS)
        rect([mid_size, mid_size], rounding=mid_radius, $fn=128);
  }
  up(GF_BASEPLATE_LOWER_TAPER_HEIGHT - EPS)
    linear_extrude(height=GF_BASEPLATE_RISER_HEIGHT + EPS * 2)
      rect([mid_size, mid_size], rounding=mid_radius, $fn=128);
  hull() {
    up(GF_BASEPLATE_LOWER_TAPER_HEIGHT + GF_BASEPLATE_RISER_HEIGHT)
      linear_extrude(height=EPS)
        rect([mid_size, mid_size], rounding=mid_radius, $fn=128);
    up(GF_BASEPLATE_PROFILE_HEIGHT + EPS)
      linear_extrude(height=EPS)
        rect([top_size, top_size], rounding=top_radius, $fn=128);
  }
}
