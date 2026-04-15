/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's Underware_Item_Holder_Clamshell_Style: https://makerworld.com/en/models/783010-underware-2-0-infinite-cable-management
openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/


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
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>
$fa = 1;
$fs = 0.4;
//A slot is generated for every tile by default.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Double Lock can be very difficult to install. They are intended for small models that only use one or two slots.
slot_lock_side = "Left"; //[Left:Standard, Both:Double]
//Ensures minimum feature width for printing. "Both" is default for compatibility, though only one (or none) may be needed depending on orientation.
slot_edge_feature_widen = "Top"; //[Both, Top, Side, None]

_slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance
);

//BEGIN holder geometry calculations
assert(item_width > 0 && item_height > 0 && item_depth > 0, "item size must be greater than 0");

slot_wall_thickness = 1.2 + struct_val(_slot_cfg, "total_height");
holder_top_thickness = holder_slot_position == "Top" ? slot_wall_thickness : holder_thickness;
holder_front_thickness = holder_slot_position == "Front" ? slot_wall_thickness : holder_thickness;
holder_width = item_width + holder_thickness * 2;
holder_height = item_height + holder_thickness + holder_front_thickness;
holder_depth = item_depth + holder_thickness + holder_top_thickness;

final_corner_rounding = max(0, min(item_width / 2, item_height / 2, item_corner_rounding));
//The calculation of horizontal slots for Front version is just an approximation.
final_slot_h_grids =
  holder_slot_position == "Top" ? max(1, floor(holder_width / OG_TILE_SIZE))
  : max(1, floor(max(holder_width, holder_width - final_corner_rounding * 2 + 10) / OG_TILE_SIZE));
final_slot_v_grids =
  holder_slot_position == "Top" ? max(1, floor(holder_height / OG_TILE_SIZE))
  : max(1, floor(holder_depth / OG_TILE_SIZE));
final_slot_position_offset = holder_slot_position == "Top" ? 0 : slot_slide_direction == "Right" ? -slot_position_offset : slot_position_offset;
//cut off the bridge part of the upper most slot
middle_cutoff_size_base = max(0.8, slot_edge_wall_min_width) * 2 + EPS;
holder_middle_cutoff_tiles = max(0, final_slot_h_grids - max(1, holder_slot_column_limit) * 2);
middle_cutoff_size = middle_cutoff_size_base + holder_middle_cutoff_tiles * OG_TILE_SIZE;
middle_cutoff_offset = final_slot_h_grids % 2 != holder_middle_cutoff_tiles % 2 ? OG_TILE_SIZE / 2 : 0;
//END holder geometry calculations

//BEGIN holder generation
// recolor("Silver")
up(generate_holder_part == "Both" ? holder_depth / 2 : holder_width / 2) yrot(generate_holder_part == "Left" ? -90 : generate_holder_part == "Right" ? 90 : 0)
    conditional_half(v=generate_holder_part == "Left" ? LEFT : RIGHT, pos_offset=middle_cutoff_offset + final_slot_position_offset, condition=generate_holder_part != "Both", mask_size=max(holder_width, holder_height) + 10)
      diff() cuboid([holder_width, holder_height, holder_depth], edges=BOTTOM, rounding=0.8) {
          down(EPS) back((holder_front_thickness - holder_thickness) / 2) {
              down((holder_top_thickness - holder_thickness) / 2)
                attach(CENTER, CENTER)
                  tag("remove") cuboid([item_width, item_height, item_depth + EPS * 2], edges="Z", rounding=final_corner_rounding);
              if (item_width - holder_width_edge * 2 > 0 && item_height - holder_height_edge * 2 > 0)
                attach(BOTTOM, BOTTOM, inside=true)
                  cuboid([item_width - holder_width_edge * 2, item_height - holder_height_edge * 2, holder_thickness + EPS * 2], edges="Z", rounding=min((item_width - holder_width_edge * 2) / 2, (item_height - holder_height_edge * 2) / 2, final_corner_rounding));
              right(middle_cutoff_offset + final_slot_position_offset) {
                attach(CENTER, CENTER, inside=true)
                  cuboid([middle_cutoff_size, holder_height + 10, holder_depth + 10]);
                if (holder_height_edge > 0 && item_height - holder_height_edge * 2 > 0)
                  attach(BOTTOM, BOTTOM, inside=true)
                    cuboid([middle_cutoff_size, item_height - holder_height_edge * 2, holder_thickness + EPS * 2])
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
                  conditional_flip(axis="X", copy=holder_side_cutoff == "Both", condition=(holder_side_cutoff == "Both" || holder_side_cutoff == "Left"))
                    attach(FRONT + TOP, FRONT + TOP, align=RIGHT, inside=true)
                      cuboid([side_cutoff_width, side_cutoff_height + EPS, side_cutoff_depth + EPS], edges=rounding_edges, rounding=min(side_cutoff_height / 2, side_cutoff_depth / 2, 2)) {
                        if (side_cutoff_front_offset - final_corner_rounding > EPS && side_cutoff_back_offset - final_corner_rounding > EPS && holder_width_edge > EPS) {
                          if (side_cutoff_front_offset - final_corner_rounding > EPS)
                            edge_mask([LEFT + FRONT])
                              rounding_edge_mask(r=min(side_cutoff_front_offset - final_corner_rounding, holder_width_edge, 2), spin=-90);
                          if (side_cutoff_back_offset - final_corner_rounding > EPS)
                            edge_mask([LEFT + BACK])
                              rounding_edge_mask(r=min(side_cutoff_back_offset - final_corner_rounding, holder_width_edge, 2), spin=-90);
                        }
                      }
                }
          }
          attach_anchor = holder_slot_position == "Top" ? TOP : FRONT;
          flat_region = holder_slot_position == "Top" ? left(final_slot_position_offset, rect([holder_width, holder_height], rounding=final_corner_rounding)) : left(final_slot_position_offset, rect([holder_width - final_corner_rounding * 2, holder_depth]));
          // recolor("Gainsboro")
          right(final_slot_position_offset)
            attach(attach_anchor, TOP, inside=true)
              openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[flat_region]);
          if (final_corner_rounding > 0)
            edge_mask([LEFT + FRONT, LEFT + BACK, RIGHT + FRONT, RIGHT + BACK])
              yflip() teardrop_edge_mask(l=$edge_length, r=final_corner_rounding, spin=-90);
        }
//END holder generation
