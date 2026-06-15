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
item_corner_rounding = 5; //0.1

/* [Holder Settings] */
//Generate one part at a time makes it possible to customize each side differently. "Both" requires splitting and orientation adjustment in the slicer.
generate_holder_part = "Both"; //[Both, Left, Right]
//Maximum number of slot columns on each holder half. Set to 1 for a minimal length holder.
holder_slot_column_limit = 1;
//If item_depth is too small or corner_rounding is too large, "Top" may leave too little space for slots.
holder_slot_position = "Back"; //[Back, Top]
holder_thickness = 2.4;
//Margins around the front opening. At least one margin should be greater than 0 to prevent the item from falling out.
front_opening_left_right_margin = 8; //0.1
//Alternatively, you can set margins to very large values, thus disable the front opening completely.
front_opening_top_bottom_margin = 6; //0.1

/* [Side Opening] */
//Cutting a hole in the side, useful for items such as power strips.
holder_side_cutout = "Right"; //[None, Left, Right, Both]
//Using the four margin values below, the size and the position of the side opening can be freely adjusted.
side_cutout_top_margin = 20; //0.1
//Cutout's top/bottom margins starts at the end of front_opening_top_bottom_margin, so it's necessary to substract its value when the calculation is based on item_height.
side_cutout_bottom_margin = 10; //0.1
//By default, the cutout would not remove the edges of the front opening. You can set cutout margins to negative values to change this.
side_cutout_back_margin = 0; //0.1
side_cutout_front_margin = 0; //0.1
side_cutout_rounding = 2; //0.1

/* [openConnect Settings] */
//Usually, "Left" and "Right" are used when mounting underdesk, "Up" and "Down" are used when mounting on a wall.
slot_slide_direction = "Left"; //[Left,Right,Up,Down]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter when installing in tight spaces.
slot_entryramp_flip = false;
//Manually offset the horizontal position of the slots.
slot_horizontal_offset = 0; //0.1
//Manually offset the vertical position of the slots.
slot_vertical_offset = 0; //0.1

/* [Advanced Settings] */
//Increase clearances if the slots feel too tight.
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
holder_top_thickness = holder_slot_position == "Back" ? slot_wall_thickness : holder_thickness;
holder_front_thickness = holder_slot_position == "Top" ? slot_wall_thickness : holder_thickness;
holder_width = item_width + holder_thickness * 2;
holder_height = item_height + holder_thickness + holder_front_thickness;
holder_depth = item_depth + holder_thickness + holder_top_thickness;

final_corner_rounding = max(0, min(item_width / 2, item_height / 2, item_corner_rounding));
effective_front_opening_left_right_margin = front_opening_left_right_margin;
effective_front_opening_top_bottom_margin = front_opening_top_bottom_margin;
final_front_opening_left_right_margin = max(0, min(item_width / 2, effective_front_opening_left_right_margin));
final_front_opening_top_bottom_margin = max(0, min(item_height / 2, effective_front_opening_top_bottom_margin));
effective_holder_side_cutout = holder_side_cutout;
effective_side_cutout_top_margin = side_cutout_top_margin;
effective_side_cutout_bottom_margin = side_cutout_bottom_margin;
effective_side_cutout_back_margin = side_cutout_back_margin;
effective_side_cutout_front_margin = side_cutout_front_margin;
//The calculation of horizontal slots for Front version is just an approximation.
final_slot_h_grids =
  holder_slot_position == "Back" ? max(1, floor(holder_width / OG_TILE_SIZE))
  : max(1, floor(max(holder_width, holder_width - final_corner_rounding * 2 + 10) / OG_TILE_SIZE));
final_slot_v_grids =
  holder_slot_position == "Back" ? max(1, floor(holder_height / OG_TILE_SIZE))
  : max(1, floor(holder_depth / OG_TILE_SIZE));
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
item_corner_rounding_center = [item_min_x + final_corner_rounding, item_min_y + final_corner_rounding, bottom_annotation_z];
item_corner_rounding_arc_segments = 12;
function item_corner_rounding_arc_point(angle) = [
  item_corner_rounding_center[0] + cos(angle) * final_corner_rounding,
  item_corner_rounding_center[1] + sin(angle) * final_corner_rounding,
  bottom_annotation_z
];
item_corner_rounding_arc_points = [
  for (i = [0:item_corner_rounding_arc_segments])
    item_corner_rounding_arc_point(180 + 90 * i / item_corner_rounding_arc_segments)
];
item_corner_rounding_radius_edge = item_corner_rounding_arc_point(225);
side_cutout_height = item_height - final_front_opening_top_bottom_margin * 2 - effective_side_cutout_top_margin - effective_side_cutout_bottom_margin;
side_cutout_depth = item_depth + holder_thickness - effective_side_cutout_back_margin - effective_side_cutout_front_margin;
side_cutout_width =
  effective_side_cutout_bottom_margin < 0 || effective_side_cutout_top_margin < 0 ? holder_width / 2
  : (holder_width - (item_width - final_front_opening_left_right_margin * 2)) / 2 + max(0, final_corner_rounding - effective_side_cutout_bottom_margin, final_corner_rounding - effective_side_cutout_top_margin);
side_cutout_side_face_x = effective_holder_side_cutout == "Left" ? holder_min_x : holder_max_x;
side_cutout_wall_top_y = holder_min_y + holder_front_thickness + final_front_opening_top_bottom_margin;
side_cutout_top_y = side_cutout_wall_top_y + effective_side_cutout_top_margin;
side_cutout_bottom_y = side_cutout_top_y + side_cutout_height;
side_cutout_wall_bottom_y = side_cutout_bottom_y + effective_side_cutout_bottom_margin;
side_cutout_wall_back_z = holder_depth - holder_top_thickness;
side_cutout_back_z = side_cutout_wall_back_z - effective_side_cutout_back_margin;
side_cutout_front_z = side_cutout_back_z - side_cutout_depth;
side_cutout_wall_front_z = side_cutout_front_z - effective_side_cutout_front_margin;
side_cutout_mid_y = (side_cutout_top_y + side_cutout_bottom_y) / 2;
side_cutout_mid_z = (side_cutout_front_z + side_cutout_back_z) / 2;

module emit_horizontal_holder_annotations() {
  emit_context_values(
    "horizontal_holder_context",
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
      "front_opening_left_right_margin",
      "front_opening_top_bottom_margin",
      "holder_side_cutout",
      "side_cutout_top_margin",
      "side_cutout_bottom_margin",
      "side_cutout_back_margin",
      "side_cutout_front_margin",
      "slot_lock_distribution",
      "slot_entryramp_flip",
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
      effective_front_opening_left_right_margin,
      effective_front_opening_top_bottom_margin,
      effective_holder_side_cutout,
      effective_side_cutout_top_margin,
      effective_side_cutout_bottom_margin,
      effective_side_cutout_back_margin,
      effective_side_cutout_front_margin,
      slot_lock_distribution,
      slot_entryramp_flip,
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
  if (effective_front_opening_left_right_margin > 0) {
    emit_dimension_annotation(
      id="front_opening_left_right_margin",
      label="front_opening_left_right_margin",
      axis="x",
      value=effective_front_opening_left_right_margin,
      start=[item_min_x, item_min_y, holder_min_z],
      end=[item_min_x + final_front_opening_left_right_margin, item_min_y, holder_min_z],
      basis="left_front_opening_left_right_margin"
    );
  }
  if (effective_front_opening_top_bottom_margin > 0) {
    emit_dimension_annotation(
      id="front_opening_top_bottom_margin",
      label="front_opening_top_bottom_margin",
      axis="y",
      value=effective_front_opening_top_bottom_margin,
      start=[item_min_x, item_min_y, holder_min_z],
      end=[item_min_x, item_min_y + final_front_opening_top_bottom_margin, holder_min_z],
      basis="front_opening_top_bottom_margin"
    );
  }
  if (effective_holder_side_cutout != "None" && side_cutout_height > 0 && side_cutout_depth > 0) {
    if (effective_side_cutout_top_margin > 0) {
      emit_dimension_annotation(
        id="side_cutout_top_margin",
        label="side_cutout_top_margin",
        axis="y",
        value=effective_side_cutout_top_margin,
        start=[side_cutout_side_face_x, side_cutout_wall_top_y, side_cutout_mid_z],
        end=[side_cutout_side_face_x, side_cutout_top_y, side_cutout_mid_z],
        basis="side_cutout_top_margin_to_visible_cutout_edge"
      );
    }
    if (effective_side_cutout_bottom_margin > 0) {
      emit_dimension_annotation(
        id="side_cutout_bottom_margin",
        label="side_cutout_bottom_margin",
        axis="y",
        value=effective_side_cutout_bottom_margin,
        start=[side_cutout_side_face_x, side_cutout_bottom_y, side_cutout_mid_z],
        end=[side_cutout_side_face_x, side_cutout_wall_bottom_y, side_cutout_mid_z],
        basis="side_cutout_bottom_margin_to_visible_cutout_edge"
      );
    }
    if (effective_side_cutout_back_margin > 0) {
      emit_dimension_annotation(
        id="side_cutout_back_margin",
        label="side_cutout_back_margin",
        axis="z",
        value=effective_side_cutout_back_margin,
        start=[side_cutout_side_face_x, side_cutout_mid_y, side_cutout_back_z],
        end=[side_cutout_side_face_x, side_cutout_mid_y, side_cutout_wall_back_z],
        basis="side_cutout_back_margin_to_visible_cutout_edge"
      );
    }
    if (effective_side_cutout_front_margin > 0) {
      emit_dimension_annotation(
        id="side_cutout_front_margin",
        label="side_cutout_front_margin",
        axis="z",
        value=effective_side_cutout_front_margin,
        start=[side_cutout_side_face_x, side_cutout_mid_y, side_cutout_wall_front_z],
        end=[side_cutout_side_face_x, side_cutout_mid_y, side_cutout_front_z],
        basis="side_cutout_front_margin_to_visible_cutout_edge"
      );
    }
  }
}

emit_horizontal_holder_annotations();

//BEGIN holder generation
up(generate_holder_part == "Both" ? holder_height / 2 : holder_width / 2)
  yrot(generate_holder_part == "Left" ? -90 : generate_holder_part == "Right" ? 90 : 0)
    xrot(generate_holder_part == "Both" ? -90 : 0)
      conditional_half(v=generate_holder_part == "Left" ? LEFT : RIGHT, pos_offset=middle_cutoff_offset, condition=generate_holder_part != "Both", mask_size=max(holder_width, holder_height) + 10)
        diff() cuboid([holder_width, holder_height, holder_depth], edges=BOTTOM, rounding=0.8) {
            down(EPS) back((holder_front_thickness - holder_thickness) / 2) {
                down((holder_top_thickness - holder_thickness) / 2)
                  attach(CENTER, CENTER)
                    tag("remove") cuboid([item_width, item_height, item_depth + EPS * 2], edges="Z", rounding=final_corner_rounding);
                if (item_width - front_opening_left_right_margin * 2 > 0 && item_height - front_opening_top_bottom_margin * 2 > 0)
                  attach(BOTTOM, BOTTOM, inside=true)
                    cuboid([item_width - front_opening_left_right_margin * 2, item_height - front_opening_top_bottom_margin * 2, holder_thickness + EPS * 2], edges="Z", rounding=min((item_width - front_opening_left_right_margin * 2) / 2, (item_height - front_opening_top_bottom_margin * 2) / 2, final_corner_rounding));
                right(middle_cutoff_offset) {
                  attach(CENTER, CENTER, inside=true)
                    cuboid([middle_cutoff_size, holder_height + 10, holder_depth + 10]);
                  if (front_opening_top_bottom_margin > 0 && item_height - front_opening_top_bottom_margin * 2 > 0)
                    attach(BOTTOM, BOTTOM, inside=true)
                      cuboid([middle_cutoff_size, item_height - front_opening_top_bottom_margin * 2, holder_thickness + EPS * 2])
                        edge_mask("Z")
                          rounding_edge_mask(r=min(max(0, item_width - front_opening_left_right_margin * 2 - final_corner_rounding * 2), front_opening_top_bottom_margin, 2), spin=180);
                }
              }
            if (holder_side_cutout != "None") {
              side_cutout_height = item_height - front_opening_top_bottom_margin * 2 - side_cutout_top_margin - side_cutout_bottom_margin;
              side_cutout_depth = item_depth + holder_thickness - side_cutout_back_margin - side_cutout_front_margin;
              side_cutout_width =
                side_cutout_bottom_margin < 0 || side_cutout_top_margin < 0 ? holder_width / 2
                : (holder_width - (item_width - front_opening_left_right_margin * 2)) / 2 + max(0, final_corner_rounding - side_cutout_bottom_margin, final_corner_rounding - side_cutout_top_margin);
              rounding_edges = side_cutout_front_margin > 0 ? "X" : [FRONT + TOP, BACK + TOP];
              if (side_cutout_height > 0 && side_cutout_depth > 0)
                back(holder_front_thickness + side_cutout_top_margin + front_opening_top_bottom_margin) down(holder_top_thickness + side_cutout_back_margin) {
                    conditional_flip(axis="X", copy=holder_side_cutout == "Both", condition=(holder_side_cutout == "Both" || holder_side_cutout == "Left"))
                      attach(FRONT + TOP, FRONT + TOP, align=RIGHT, inside=true)
                        cuboid([side_cutout_width + EPS, side_cutout_height + EPS * 2, side_cutout_depth + EPS * 2], edges=rounding_edges, rounding=max(0, min(side_cutout_height / 2, side_cutout_depth / 2, side_cutout_rounding))) {
                          if (side_cutout_top_margin - final_corner_rounding > EPS && side_cutout_bottom_margin - final_corner_rounding > EPS && front_opening_left_right_margin > EPS) {
                            if (side_cutout_top_margin - final_corner_rounding > EPS)
                              edge_mask([LEFT + FRONT])
                                rounding_edge_mask(r=min(side_cutout_top_margin - final_corner_rounding, front_opening_left_right_margin, 2), spin=-90);
                            if (side_cutout_bottom_margin - final_corner_rounding > EPS)
                              edge_mask([LEFT + BACK])
                                rounding_edge_mask(r=min(side_cutout_bottom_margin - final_corner_rounding, front_opening_left_right_margin, 2), spin=-90);
                          }
                        }
                  }
            }
            attach_anchor = holder_slot_position == "Back" ? TOP : FRONT;
            flat_region = holder_slot_position == "Back" ? left(slot_horizontal_offset, fwd(slot_vertical_offset, rect([holder_width, holder_height], rounding=final_corner_rounding))) : left(slot_horizontal_offset, fwd(slot_vertical_offset, rect([holder_width - final_corner_rounding * 2, holder_depth])));
            attach(attach_anchor, TOP, inside=true) {
              right(slot_horizontal_offset) back(slot_vertical_offset)
                  openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[flat_region]);
              // openconnect_slot_grid_limit_debug(slot_cfg=_slot_cfg, horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[flat_region]);
            }
            if (final_corner_rounding > 0)
              edge_mask([LEFT + FRONT, LEFT + BACK, RIGHT + FRONT, RIGHT + BACK])
                yflip() teardrop_edge_mask(l=$edge_length, r=final_corner_rounding, spin=-90);
          }
//END holder generation
