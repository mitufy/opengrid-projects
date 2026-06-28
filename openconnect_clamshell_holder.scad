/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's Underware_Item_Holder_Clamshell_Style: https://makerworld.com/en/models/783010-underware-2-0-infinite-cable-management
openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Item Settings] */
//Dimensions of the item to be held. You can set values slightly higher for more wriggle room.
item_width = 170;
item_height = 60;
item_depth = 30;
//By increasing corner_rounding, it's possible to generate holders that are nearly circular.
item_corner_rounding = 5;

/* [Holder Settings] */
//Generate one part at a time makes it possible to customize each side differently. "Both" requires splitting and orientation adjustment in the slicer.
generate_holder_part = "Both"; //[Both, Left, Right]
//Maximum number of slot columns on each holder half. Set to 1 for a minimal length holder.
holder_slot_column_limit = 1;
//"Top" for item facing down, "Front" for item facing its side. When using a large corner_rounding, "Front" may leave too little space for slots.
holder_slot_position = "Top"; //[Top, Front]
holder_thickness = 2.4;
//Margins around the front opening. At least one margin should be greater than 0 to prevent the item from falling out.
front_opening_side_margin = 8;
//Alternatively, you can set margins to very large values, thus disable the front opening completely.
front_opening_end_margin = 6;

/* [Side Opening] */
//Cutting a hole in the side, useful for items such as power strips.
holder_side_opening = "Right"; //[None, Left, Right, Both]
//Using the four margin values below, the size and the position of the side opening can be freely adjusted.
side_opening_front_margin = 15;
//Margins are from the edge of the opening to the wall. All 0 means the wall would be completely removed.
side_opening_back_margin = 15;
side_opening_top_margin = 0;
side_opening_bottom_margin = 0;

/* [openConnect Settings] */
//Usually, "Left" and "Right" are used when mounting underdesk, "Up" and "Down" are used when mounting on a wall.
slot_slide_direction = "Left"; //[Left,Right,Up,Down]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter when installing in tight spaces.
slot_entryramp_flip = false;
//Only applies when holder_slot_position is "Front". Adjusting the offset may help if a large corner_rounding is cutting into the slot area.
front_slot_position_offset = 0;

/* [Advanced Settings] */
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/* [Hidden] */
include <lib/opengrid_base.scad>
include <lib/annotation_metadata.scad>
use <lib/openconnect_lib.scad>
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;
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
effective_front_opening_side_margin = is_undef(holder_width_edge) ? front_opening_side_margin : holder_width_edge;
effective_front_opening_end_margin = is_undef(holder_height_edge) ? front_opening_end_margin : holder_height_edge;
final_front_opening_side_margin = max(0, min(item_width / 2, effective_front_opening_side_margin));
final_front_opening_end_margin = max(0, min(item_height / 2, effective_front_opening_end_margin));
effective_holder_side_opening = is_undef(holder_side_cutoff) ? holder_side_opening : holder_side_cutoff;
effective_side_opening_front_margin = is_undef(side_cutoff_front_offset) ? side_opening_front_margin : side_cutoff_front_offset;
effective_side_opening_back_margin = is_undef(side_cutoff_back_offset) ? side_opening_back_margin : side_cutoff_back_offset;
effective_side_opening_top_margin = is_undef(side_cutoff_top_offset) ? side_opening_top_margin : side_cutoff_top_offset;
effective_side_opening_bottom_margin = is_undef(side_cutoff_bottom_offset) ? side_opening_bottom_margin : side_cutoff_bottom_offset;
//The calculation of horizontal slots for Front version is just an approximation.
final_slot_h_grids =
  holder_slot_position == "Top" ? max(1, floor(holder_width / OG_TILE_SIZE))
  : max(1, floor(max(holder_width, holder_width - final_corner_rounding * 2 + 10) / OG_TILE_SIZE));
final_slot_v_grids =
  holder_slot_position == "Top" ? max(1, floor(holder_height / OG_TILE_SIZE))
  : max(1, floor(holder_depth / OG_TILE_SIZE));
final_front_slot_position_offset =
  holder_slot_position == "Front" && slot_slide_direction == "Right" ? -front_slot_position_offset
  : holder_slot_position == "Front" && slot_slide_direction == "Left" ? front_slot_position_offset : 0;
//cut off the bridge part of the upper most slot
middle_cutoff_size_base = max(0.8, slot_edge_wall_min_width) * 2 + EPS;
holder_middle_cutoff_tiles = max(0, final_slot_h_grids - max(1, holder_slot_column_limit) * 2);
middle_cutoff_size = middle_cutoff_size_base + holder_middle_cutoff_tiles * OG_TILE_SIZE;
middle_cutoff_offset = final_slot_h_grids % 2 != holder_middle_cutoff_tiles % 2 ? OG_TILE_SIZE / 2 : 0;
//END holder geometry calculations

holder_min_x = -holder_width / 2;
holder_max_x = holder_width / 2;
holder_min_y = -holder_height / 2;
holder_max_y = holder_height / 2;
holder_min_z = 0;
holder_max_z = holder_depth;
bottom_annotation_z = holder_min_z;
item_center_y = (holder_front_thickness - holder_thickness) / 2;
item_center_z = holder_thickness + item_depth / 2;
item_min_x = -item_width / 2;
item_max_x = item_width / 2;
item_min_y = item_center_y - item_height / 2;
item_max_y = item_center_y + item_height / 2;
item_min_z = holder_thickness;
item_max_z = holder_thickness + item_depth;
item_corner_rounding_center = [item_max_x - final_corner_rounding, item_max_y - final_corner_rounding, bottom_annotation_z];
item_corner_rounding_arc_segments = 12;
function item_corner_rounding_arc_point(angle) = [
  item_corner_rounding_center[0] + cos(angle) * final_corner_rounding,
  item_corner_rounding_center[1] + sin(angle) * final_corner_rounding,
  bottom_annotation_z
];
item_corner_rounding_arc_points = [
  for (i = [0:item_corner_rounding_arc_segments])
    item_corner_rounding_arc_point(0 + 90 * i / item_corner_rounding_arc_segments)
];
item_corner_rounding_radius_edge = item_corner_rounding_arc_point(45);
side_opening_height = item_height - final_front_opening_end_margin * 2 - effective_side_opening_front_margin - effective_side_opening_back_margin;
side_opening_depth = item_depth + holder_thickness - effective_side_opening_top_margin - effective_side_opening_bottom_margin;
side_opening_width =
  effective_side_opening_back_margin < 0 || effective_side_opening_front_margin < 0 ? holder_width / 2
  : (holder_width - (item_width - final_front_opening_side_margin * 2)) / 2 + max(0, final_corner_rounding - effective_side_opening_back_margin, final_corner_rounding - effective_side_opening_front_margin);
side_opening_side_face_x = effective_holder_side_opening == "Left" ? holder_min_x : holder_max_x;
side_opening_wall_front_y = holder_min_y + holder_front_thickness + final_front_opening_end_margin;
side_opening_front_y = side_opening_wall_front_y + effective_side_opening_front_margin;
side_opening_back_y = side_opening_front_y + side_opening_height;
side_opening_wall_back_y = side_opening_back_y + effective_side_opening_back_margin;
side_opening_wall_top_z = holder_depth - holder_top_thickness;
side_opening_top_z = side_opening_wall_top_z - effective_side_opening_top_margin;
side_opening_bottom_z = side_opening_top_z - side_opening_depth;
side_opening_wall_bottom_z = side_opening_bottom_z - effective_side_opening_bottom_margin;
side_opening_mid_y = (side_opening_front_y + side_opening_back_y) / 2;
side_opening_mid_z = (side_opening_bottom_z + side_opening_top_z) / 2;

module emit_clamshell_holder_annotations() {
  emit_context_values(
    "clamshell_holder_context",
    [
      "OG_TILE_SIZE",
      "og_tile_size",
      "og_standard_thickness",
      "item_width",
      "item_height",
      "item_depth",
      "item_corner_rounding",
      "generate_holder_part",
      "holder_slot_column_limit",
      "holder_slot_position",
      "holder_thickness",
      "front_opening_side_margin",
      "front_opening_end_margin",
      "holder_side_opening",
      "side_opening_front_margin",
      "side_opening_back_margin",
      "side_opening_top_margin",
      "side_opening_bottom_margin",
      "slot_lock_distribution",
      "slot_entryramp_flip",
      "front_slot_position_offset",
      "slot_slide_direction",
      "slot_side_clearance",
      "slot_depth_clearance",
      "slot_edge_bridge_min_width",
      "slot_edge_wall_min_width"
    ],
    [
      OG_TILE_SIZE,
      OG_TILE_SIZE,
      OG_STANDARD_THICKNESS,
      item_width,
      item_height,
      item_depth,
      item_corner_rounding,
      generate_holder_part,
      holder_slot_column_limit,
      holder_slot_position,
      holder_thickness,
      effective_front_opening_side_margin,
      effective_front_opening_end_margin,
      effective_holder_side_opening,
      effective_side_opening_front_margin,
      effective_side_opening_back_margin,
      effective_side_opening_top_margin,
      effective_side_opening_bottom_margin,
      slot_lock_distribution,
      slot_entryramp_flip,
      front_slot_position_offset,
      slot_slide_direction,
      slot_side_clearance,
      slot_depth_clearance,
      slot_edge_bridge_min_width,
      slot_edge_wall_min_width
    ]
  );
  emit_dimension_annotation(
    id="item_width",
    label="item_width",
    axis="x",
    value=item_width,
    start=[item_min_x, item_min_y, bottom_annotation_z],
    end=[item_max_x, item_min_y, bottom_annotation_z],
    basis="bottom_plane_item_width"
  );
  emit_dimension_annotation(
    id="item_height",
    label="item_height",
    axis="y",
    value=item_height,
    start=[item_min_x, item_min_y, bottom_annotation_z],
    end=[item_min_x, item_max_y, bottom_annotation_z],
    basis="bottom_plane_item_height"
  );
  emit_dimension_annotation(
    id="item_depth",
    label="item_depth",
    axis="z",
    value=item_depth,
    start=[item_max_x, item_max_y, bottom_annotation_z],
    end=[item_max_x, item_max_y, bottom_annotation_z + item_depth],
    basis="bottom_plane_item_depth"
  );
  if (final_corner_rounding > 0) {
    emit_radius_annotation(
      id="item_corner_rounding",
      label="item_corner_rounding",
      value=final_corner_rounding,
      center=item_corner_rounding_center,
      edge=item_corner_rounding_radius_edge,
      basis="bottom_front_left_item_corner_rounding_center_to_arc_midpoint"
    );
    emit_arc_annotation(
      id="item_corner_rounding_extent",
      label="item_corner_rounding_extent",
      value=final_corner_rounding,
      points=item_corner_rounding_arc_points,
      basis="bottom_front_left_item_corner_rounding_fillet_arc"
    );
  }
  if (effective_front_opening_side_margin > 0) {
    emit_dimension_annotation(
      id="front_opening_side_margin",
      label="front_opening_side_margin",
      axis="x",
      value=effective_front_opening_side_margin,
      start=[item_min_x, item_max_y, holder_min_z],
      end=[item_min_x + final_front_opening_side_margin, item_max_y, holder_min_z],
      basis="left_front_opening_side_margin"
    );
  }
  if (effective_front_opening_end_margin > 0) {
    emit_dimension_annotation(
      id="front_opening_end_margin",
      label="front_opening_end_margin",
      axis="y",
      value=effective_front_opening_end_margin,
      start=[item_max_x, item_min_y, holder_min_z],
      end=[item_max_x, item_min_y + final_front_opening_end_margin, holder_min_z],
      basis="front_opening_end_margin"
    );
  }
  if (effective_holder_side_opening != "None" && side_opening_height > 0 && side_opening_depth > 0) {
    if (effective_side_opening_front_margin > 0) {
      emit_dimension_annotation(
        id="side_opening_front_margin",
        label="side_opening_front_margin",
        axis="y",
        value=effective_side_opening_front_margin,
        start=[side_opening_side_face_x, side_opening_wall_front_y, side_opening_mid_z],
        end=[side_opening_side_face_x, side_opening_front_y, side_opening_mid_z],
        basis="side_opening_front_margin_to_visible_cutout_edge"
      );
    }
    if (effective_side_opening_back_margin > 0) {
      emit_dimension_annotation(
        id="side_opening_back_margin",
        label="side_opening_back_margin",
        axis="y",
        value=effective_side_opening_back_margin,
        start=[side_opening_side_face_x, side_opening_back_y, side_opening_mid_z],
        end=[side_opening_side_face_x, side_opening_wall_back_y, side_opening_mid_z],
        basis="side_opening_back_margin_to_visible_cutout_edge"
      );
    }
    if (effective_side_opening_top_margin > 0) {
      emit_dimension_annotation(
        id="side_opening_top_margin",
        label="side_opening_top_margin",
        axis="z",
        value=effective_side_opening_top_margin,
        start=[side_opening_side_face_x, side_opening_mid_y, side_opening_top_z],
        end=[side_opening_side_face_x, side_opening_mid_y, side_opening_wall_top_z],
        basis="side_opening_top_margin_to_visible_cutout_edge"
      );
    }
    if (effective_side_opening_bottom_margin > 0) {
      emit_dimension_annotation(
        id="side_opening_bottom_margin",
        label="side_opening_bottom_margin",
        axis="z",
        value=effective_side_opening_bottom_margin,
        start=[side_opening_side_face_x, side_opening_mid_y, side_opening_wall_bottom_z],
        end=[side_opening_side_face_x, side_opening_mid_y, side_opening_bottom_z],
        basis="side_opening_bottom_margin_to_visible_cutout_edge"
      );
    }
  }
}

if (generate_holder_part == "Both")
  emit_clamshell_holder_annotations();

//BEGIN holder generation
up(generate_holder_part == "Both" ? holder_depth / 2 : holder_width / 2) yrot(generate_holder_part == "Left" ? -90 : generate_holder_part == "Right" ? 90 : 0)
    conditional_half(v=generate_holder_part == "Left" ? LEFT : RIGHT, pos_offset=middle_cutoff_offset + final_front_slot_position_offset, condition=generate_holder_part != "Both", mask_size=max(holder_width, holder_height) + 10)
      diff() cuboid([holder_width, holder_height, holder_depth], edges=BOTTOM, rounding=0.8) {
          down(EPS) back((holder_front_thickness - holder_thickness) / 2) {
              down((holder_top_thickness - holder_thickness) / 2)
                attach(CENTER, CENTER)
                  tag("remove") cuboid([item_width, item_height, item_depth + EPS * 2], edges="Z", rounding=final_corner_rounding);
              if (item_width - final_front_opening_side_margin * 2 > 0 && item_height - final_front_opening_end_margin * 2 > 0)
                attach(BOTTOM, BOTTOM, inside=true)
                  cuboid([item_width - final_front_opening_side_margin * 2, item_height - final_front_opening_end_margin * 2, holder_thickness + EPS * 2], edges="Z", rounding=min((item_width - final_front_opening_side_margin * 2) / 2, (item_height - final_front_opening_end_margin * 2) / 2, final_corner_rounding));
              right(middle_cutoff_offset + final_front_slot_position_offset) {
                attach(CENTER, CENTER, inside=true)
                  cuboid([middle_cutoff_size, holder_height + 10, holder_depth + 10]);
                if (final_front_opening_end_margin > 0 && item_height - final_front_opening_end_margin * 2 > 0)
                  attach(BOTTOM, BOTTOM, inside=true)
                    cuboid([middle_cutoff_size, item_height - final_front_opening_end_margin * 2, holder_thickness + EPS * 2])
                      edge_mask("Z")
                        rounding_edge_mask(r=min(max(0, item_width - final_front_opening_side_margin * 2 - final_corner_rounding * 2), final_front_opening_end_margin, 2), spin=180);
              }
            }
          if (effective_holder_side_opening != "None") {
            rounding_edges = effective_side_opening_bottom_margin > 0 ? "X" : [FRONT + TOP, BACK + TOP];
            if (side_opening_height > 0 && side_opening_depth > 0)
              back(holder_front_thickness + effective_side_opening_front_margin + final_front_opening_end_margin) down(holder_top_thickness + effective_side_opening_top_margin) {
                  conditional_flip(axis="X", copy=effective_holder_side_opening == "Both", condition=(effective_holder_side_opening == "Both" || effective_holder_side_opening == "Left"))
                    attach(FRONT + TOP, FRONT + TOP, align=RIGHT, inside=true)
                      cuboid([side_opening_width, side_opening_height + EPS, side_opening_depth + EPS], edges=rounding_edges, rounding=min(side_opening_height / 2, side_opening_depth / 2, 2)) {
                        if (effective_side_opening_front_margin - final_corner_rounding > EPS && effective_side_opening_back_margin - final_corner_rounding > EPS && final_front_opening_side_margin > EPS) {
                          if (effective_side_opening_front_margin - final_corner_rounding > EPS)
                            edge_mask([LEFT + FRONT])
                              rounding_edge_mask(r=min(effective_side_opening_front_margin - final_corner_rounding, final_front_opening_side_margin, 2), spin=-90);
                          if (effective_side_opening_back_margin - final_corner_rounding > EPS)
                            edge_mask([LEFT + BACK])
                              rounding_edge_mask(r=min(effective_side_opening_back_margin - final_corner_rounding, final_front_opening_side_margin, 2), spin=-90);
                        }
                      }
                }
          }
          attach_anchor = holder_slot_position == "Top" ? TOP : FRONT;
          flat_region = holder_slot_position == "Top" ? left(final_front_slot_position_offset, rect([holder_width, holder_height], rounding=final_corner_rounding)) : left(final_front_slot_position_offset, rect([holder_width - final_corner_rounding * 2, holder_depth]));
          right(final_front_slot_position_offset)
            attach(attach_anchor, TOP, inside=true) {
              openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[flat_region]);
              // openconnect_slot_grid_limit_debug(slot_cfg=_slot_cfg, horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[flat_region]);
            }
          if (final_corner_rounding > 0)
            edge_mask([LEFT + FRONT, LEFT + BACK, RIGHT + FRONT, RIGHT + BACK])
              yflip() teardrop_edge_mask(l=$edge_length, r=final_corner_rounding, spin=-90);
        }
//END holder generation
