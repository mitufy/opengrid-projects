/*
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/

/* [Plate Settings] */
//Size can be inputted in either grids or millimeters. 1 grid = 28mm.
plate_size_unit = "mm"; //[grid:Grid Count, mm:Millimeter]
plate_horizontal_size = 84;
plate_vertical_size = 56;
//Set this to 0 if your model already has a wall and you don't want to thicken it. Does not affect Negative slots.
plate_extra_thickness = 0.5;
plate_corner_rounding = "None"; //["None", "Chamfer", "Fillet"]
plate_corner_rounding_size = 0;

/* [Slot Settings] */
//"Standard" to add to models. "Negative" to subtract from models. "Vase Mode" to add to specific models designed for vase mode.
slot_type = "slot"; //[slot:Standard, negslot:Negative, vase:Vase Mode]
//For vase mode slots. This value should match the slicer's linewidth setting when printing in vase mode.
vase_linewidth = 0.6;
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces. When printing the slots on the side, place the locking mechanism side closer to the print bed.
slot_entryramp_flip = false;
//"All" is the default and means a slot is generated for every openGrid tile.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]

/* [Advanced Settings] */
//Slot alignment applies when the plate size is in millimeters and not divisible by 28.
plate_slot_horizontal_alignment = "Center"; //["Center", "Left", "Right"]
plate_slot_vertical_alignment = "Center"; //["Center", "Top", "Bottom"]
//Manually offset the horizontal position of the slots. Use this if you want more precise control than offered by plate_slot_horizontal_alignment.
plate_slot_horizontal_offset = 0; //0.1
//Manually offset the vertical position of the slots. Use this if you want more precise control than offered by plate_slot_vertical_alignment.
plate_slot_vertical_offset = 0; //0.1
//Increase clearances if the slots feel too tight.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
//Ensures minimum feature width for printing. "Both" is default for compatibility, though only one (or none) may be needed depending on orientation.
slot_edge_feature_widen = "Both"; //[Both, Top, Side, None]
//Minimum width for bridges under slot_edge_feature_widen. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls under slot_edge_feature_widen. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/* [Hidden] */
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;
include <lib/opengrid_base.scad>
include <lib/annotation_metadata.scad>
use <lib/openconnect_lib.scad>

slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance,
  vase_linewidth=vase_linewidth,
  vase_overhang_angle=45
);
slot_total_height = struct_val(slot_cfg, "total_height");

slot_lock_side = "Left";
final_plate_width = max(1, plate_size_unit == "mm" ? plate_horizontal_size : plate_horizontal_size * OG_TILE_SIZE);
final_plate_h_grids = max(1, plate_size_unit == "mm" ? floor(plate_horizontal_size / OG_TILE_SIZE) : plate_horizontal_size);
final_plate_height = max(1, plate_size_unit == "mm" ? plate_vertical_size : plate_vertical_size * OG_TILE_SIZE);
final_plate_v_grids = max(1, plate_size_unit == "mm" ? floor(plate_vertical_size / OG_TILE_SIZE) : plate_vertical_size);
final_plate_thickness = slot_type == "negslot" ? EPS : max(EPS, slot_type == "vase" ? plate_extra_thickness : slot_total_height + plate_extra_thickness);
final_plate_horizontal_alignment =
  plate_slot_horizontal_alignment == "Left" ? LEFT
  : plate_slot_horizontal_alignment == "Right" ? RIGHT : CENTER;
final_plate_vertical_alignment =
  plate_slot_vertical_alignment == "Top" ? BACK
  : plate_slot_vertical_alignment == "Bottom" ? FRONT : CENTER;
final_plate_alignment = final_plate_horizontal_alignment + final_plate_vertical_alignment;

slot_head_cfg = struct_val(slot_cfg, "head_cfg");
slot_middle_height = struct_val(slot_head_cfg, "middle_height");
slot_back_pos_offset = struct_val(slot_head_cfg, "back_pos_offset");
slot_bottom_height = struct_val(slot_cfg, "bottom_height");
slot_top_height = struct_val(slot_cfg, "top_height");
slot_large_rect_width = struct_val(slot_cfg, "large_rect_width");
slot_large_rect_height = struct_val(slot_cfg, "large_rect_height");
slot_large_rect_chamfer = struct_val(slot_cfg, "large_rect_chamfer");
slot_nub_to_top_distance = struct_val(slot_cfg, "nub_to_top_distance");
slot_middle_to_bottom = struct_val(slot_cfg, "middle_to_bottom");
slot_top_bridge_offset = struct_val(slot_cfg, "top_bridge_offset");
slot_side_bridge_offset = struct_val(slot_cfg, "side_bridge_offset");
slot_side_cliff_offset = struct_val(slot_cfg, "side_cliff_offset");
slot_grid_width = final_plate_h_grids * OG_TILE_SIZE;
slot_grid_height = final_plate_v_grids * OG_TILE_SIZE;
slot_grid_center_x =
  final_plate_horizontal_alignment == LEFT ? slot_grid_width / 2
  : final_plate_horizontal_alignment == RIGHT ? final_plate_width - slot_grid_width / 2
  : final_plate_width / 2;
slot_grid_center_y =
  final_plate_vertical_alignment == BACK ? final_plate_height - slot_grid_height / 2
  : final_plate_vertical_alignment == FRONT ? slot_grid_height / 2
  : final_plate_height / 2;
annotation_slot_center = [
  slot_grid_center_x + plate_slot_horizontal_offset - (final_plate_h_grids - 1) * OG_TILE_SIZE / 2,
  slot_grid_center_y + plate_slot_vertical_offset + (final_plate_v_grids - 1) * OG_TILE_SIZE / 2,
  0
];
slot_annotation_top_z = slot_type == "negslot" ? 0 : final_plate_thickness;
slot_annotation_bottom_z = slot_annotation_top_z - slot_total_height;
slot_annotation_middle_z = slot_annotation_bottom_z + slot_bottom_height;
slot_annotation_top_layer_z = slot_annotation_middle_z + slot_middle_height;
slot_annotation_half_width = slot_large_rect_width / 2;
slot_annotation_back_y = slot_annotation_half_width + slot_back_pos_offset;
slot_annotation_front_y = slot_annotation_back_y - slot_large_rect_height;
slot_annotation_nub_y = slot_annotation_back_y - slot_nub_to_top_distance;
slot_annotation_side_x = slot_annotation_half_width;
slot_annotation_side_y = slot_annotation_front_y + max(EPS, slot_large_rect_height / 3);
plate_annotation_edge_offset =
  plate_corner_rounding != "None" && plate_corner_rounding_size > 0
  ? plate_corner_rounding_size : 0;
plate_corner_rounding_center = [
  final_plate_width - plate_corner_rounding_size,
  final_plate_height - plate_corner_rounding_size,
  slot_annotation_top_z
];
plate_corner_rounding_arc_segments = 12;
function plate_corner_rounding_arc_point(angle) = [
  plate_corner_rounding_center[0] + cos(angle) * plate_corner_rounding_size,
  plate_corner_rounding_center[1] + sin(angle) * plate_corner_rounding_size,
  slot_annotation_top_z
];
plate_corner_rounding_arc_points = [
  for (i = [0:plate_corner_rounding_arc_segments])
    plate_corner_rounding_arc_point(90 * i / plate_corner_rounding_arc_segments)
];
plate_corner_rounding_radius_edge = plate_corner_rounding_arc_point(45);

module emit_plate_annotations() {
  emit_dimension_annotation(
    id="plate_horizontal_size",
    label="plate_horizontal_size",
    axis="x",
    value=final_plate_width,
    start=[0, plate_annotation_edge_offset, slot_annotation_top_z],
    end=[final_plate_width, plate_annotation_edge_offset, slot_annotation_top_z],
    basis="plate_front_edge_full_horizontal_span"
  );
  emit_dimension_annotation(
    id="plate_vertical_size",
    label="plate_vertical_size",
    axis="y",
    value=final_plate_height,
    start=[plate_annotation_edge_offset, 0, slot_annotation_top_z],
    end=[plate_annotation_edge_offset, final_plate_height, slot_annotation_top_z],
    basis="plate_left_edge_full_vertical_span"
  );
  if (plate_corner_rounding == "Fillet" && plate_corner_rounding_size > 0) {
    emit_radius_annotation(
      id="plate_corner_rounding_size",
      label="plate_corner_rounding_size",
      value=plate_corner_rounding_size,
      center=plate_corner_rounding_center,
      edge=plate_corner_rounding_radius_edge,
      basis="plate_back_right_corner_fillet_center_to_arc_midpoint"
    );
    emit_arc_annotation(
      id="plate_corner_rounding_size_extent",
      label="plate_corner_rounding_size_extent",
      value=plate_corner_rounding_size,
      points=plate_corner_rounding_arc_points,
      basis="plate_back_right_corner_fillet_arc"
    );
  }
}

function plate_slot_point(point) = [
  annotation_slot_center[0] + point[0],
  annotation_slot_center[1] + point[1],
  point[2]
];

module emit_plate_slot_dimension_annotation(id, label, axis, value, start, end, basis) {
  emit_dimension_annotation(
    id=id,
    label=label,
    axis=axis,
    value=value,
    start=plate_slot_point(start),
    end=plate_slot_point(end),
    basis=basis
  );
}

module emit_plate_slot_annotations() {
  emit_context_values(
    "openconnect_plate_slot_context",
    [
      "slot_side_clearance",
      "slot_depth_clearance",
      "slot_edge_bridge_min_width",
      "slot_edge_wall_min_width",
      "slot_bottom_height",
      "slot_middle_height",
      "slot_top_height",
      "slot_total_height",
      "slot_large_rect_width",
      "slot_large_rect_height",
      "slot_large_rect_chamfer",
      "slot_nub_to_top_distance",
      "slot_middle_to_bottom",
      "slot_top_bridge_offset",
      "slot_side_bridge_offset",
      "slot_side_cliff_offset",
      "OCSLOT_MOVE_DISTANCE",
      "OCSLOT_ONRAMP_CLEARANCE"
    ],
    [
      slot_side_clearance,
      slot_depth_clearance,
      slot_edge_bridge_min_width,
      slot_edge_wall_min_width,
      slot_bottom_height,
      slot_middle_height,
      slot_top_height,
      slot_total_height,
      slot_large_rect_width,
      slot_large_rect_height,
      slot_large_rect_chamfer,
      slot_nub_to_top_distance,
      slot_middle_to_bottom,
      slot_top_bridge_offset,
      slot_side_bridge_offset,
      slot_side_cliff_offset,
      OCSLOT_MOVE_DISTANCE,
      OCSLOT_ONRAMP_CLEARANCE
    ]
  );
  emit_plate_slot_dimension_annotation(
    id="slot_total_height",
    label="slot_total_height",
    axis="z",
    value=slot_total_height,
    start=[-slot_annotation_half_width, slot_annotation_front_y, slot_annotation_bottom_z],
    end=[-slot_annotation_half_width, slot_annotation_front_y, slot_annotation_top_z],
    basis="openconnect_plate_slot_total_cut_depth"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_bottom_height",
    label="slot_bottom_height",
    axis="z",
    value=slot_bottom_height,
    start=[slot_annotation_side_x, slot_annotation_side_y, slot_annotation_bottom_z],
    end=[slot_annotation_side_x, slot_annotation_side_y, slot_annotation_middle_z],
    basis="openconnect_plate_slot_bottom_clearance_layer_height"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_middle_height",
    label="slot_middle_height",
    axis="z",
    value=slot_middle_height,
    start=[slot_annotation_side_x, slot_annotation_side_y, slot_annotation_middle_z],
    end=[slot_annotation_side_x, slot_annotation_side_y, slot_annotation_top_layer_z],
    basis="openconnect_plate_slot_tapered_middle_height"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_top_height",
    label="slot_top_height",
    axis="z",
    value=slot_top_height,
    start=[slot_annotation_side_x, slot_annotation_side_y, slot_annotation_top_layer_z],
    end=[slot_annotation_side_x, slot_annotation_side_y, slot_annotation_top_z],
    basis="openconnect_plate_slot_top_clearance_layer_height"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_large_rect_width",
    label="slot_large_rect_width",
    axis="x",
    value=slot_large_rect_width,
    start=[-slot_annotation_half_width, slot_annotation_back_y, slot_annotation_top_z],
    end=[slot_annotation_half_width, slot_annotation_back_y, slot_annotation_top_z],
    basis="openconnect_plate_slot_large_profile_width"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_large_rect_height",
    label="slot_large_rect_height",
    axis="y",
    value=slot_large_rect_height,
    start=[slot_annotation_half_width, slot_annotation_front_y, slot_annotation_top_z],
    end=[slot_annotation_half_width, slot_annotation_back_y, slot_annotation_top_z],
    basis="openconnect_plate_slot_large_profile_depth"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_large_rect_chamfer",
    label="slot_large_rect_chamfer",
    axis="x",
    value=slot_large_rect_chamfer,
    start=[slot_annotation_half_width - slot_large_rect_chamfer, slot_annotation_back_y, slot_annotation_top_z],
    end=[slot_annotation_half_width, slot_annotation_back_y, slot_annotation_top_z],
    basis="openconnect_plate_slot_large_profile_back_corner_chamfer"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_nub_to_top_distance",
    label="slot_nub_to_top_distance",
    axis="y",
    value=slot_nub_to_top_distance,
    start=[slot_annotation_half_width, slot_annotation_nub_y, slot_annotation_middle_z],
    end=[slot_annotation_half_width, slot_annotation_back_y, slot_annotation_middle_z],
    basis="openconnect_plate_slot_back_edge_to_lock_nub_centerline"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_side_clearance",
    label="slot_side_clearance",
    axis="x",
    value=slot_side_clearance,
    start=[OCHEAD_LARGE_RECT_WIDTH / 2, slot_annotation_back_y, slot_annotation_top_z],
    end=[slot_annotation_half_width, slot_annotation_back_y, slot_annotation_top_z],
    basis="openconnect_plate_slot_side_clearance_added_to_head_width"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_depth_clearance",
    label="slot_depth_clearance",
    axis="z",
    value=slot_depth_clearance,
    start=[-slot_annotation_half_width, slot_annotation_side_y, slot_annotation_bottom_z],
    end=[-slot_annotation_half_width, slot_annotation_side_y, slot_annotation_bottom_z + slot_depth_clearance],
    basis="openconnect_plate_slot_depth_clearance_added_to_bottom_layer"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_top_bridge_offset",
    label="slot_top_bridge_offset",
    axis="y",
    value=slot_top_bridge_offset,
    start=[0, slot_annotation_back_y, slot_annotation_top_z],
    end=[0, slot_annotation_back_y + slot_top_bridge_offset, slot_annotation_top_z],
    basis="openconnect_plate_slot_top_bridge_offset_from_min_bridge_width"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_side_bridge_offset",
    label="slot_side_bridge_offset",
    axis="x",
    value=slot_side_bridge_offset,
    start=[slot_annotation_half_width, slot_annotation_back_y + slot_top_bridge_offset, slot_annotation_top_z],
    end=[slot_annotation_half_width + slot_side_bridge_offset, slot_annotation_back_y + slot_top_bridge_offset, slot_annotation_top_z],
    basis="openconnect_plate_slot_side_bridge_offset_from_min_bridge_width"
  );
  emit_plate_slot_dimension_annotation(
    id="slot_side_cliff_offset",
    label="slot_side_cliff_offset",
    axis="x",
    value=slot_side_cliff_offset,
    start=[-slot_annotation_half_width - slot_side_cliff_offset, slot_annotation_back_y + slot_top_bridge_offset, slot_annotation_top_z],
    end=[-slot_annotation_half_width, slot_annotation_back_y + slot_top_bridge_offset, slot_annotation_top_z],
    basis="openconnect_plate_slot_side_cliff_offset_from_min_wall_width"
  );
  emit_plate_slot_dimension_annotation(
    id="OCSLOT_MOVE_DISTANCE",
    label="OCSLOT_MOVE_DISTANCE",
    axis="y",
    value=OCSLOT_MOVE_DISTANCE,
    start=[0, slot_annotation_front_y, slot_annotation_top_layer_z],
    end=[0, slot_annotation_front_y + OCSLOT_MOVE_DISTANCE, slot_annotation_top_layer_z],
    basis="openconnect_plate_slot_slide_distance_default_reference"
  );
  emit_plate_slot_dimension_annotation(
    id="OCSLOT_ONRAMP_CLEARANCE",
    label="OCSLOT_ONRAMP_CLEARANCE",
    axis="x",
    value=OCSLOT_ONRAMP_CLEARANCE,
    start=[slot_annotation_half_width - OCSLOT_ONRAMP_CLEARANCE, slot_annotation_front_y, slot_annotation_top_layer_z],
    end=[slot_annotation_half_width, slot_annotation_front_y, slot_annotation_top_layer_z],
    basis="openconnect_plate_slot_onramp_clearance_default_reference"
  );
}

emit_plate_annotations();
emit_plate_slot_annotations();

//BEGIN generation
down(final_plate_thickness == EPS ? EPS : 0) diff()
    hide("hidden") tag(final_plate_thickness == EPS ? "hidden" : "")
        cuboid([final_plate_width, final_plate_height, final_plate_thickness], anchor=BOTTOM + FRONT + LEFT) {
          if (plate_corner_rounding != "None" && plate_corner_rounding_size > 0)
            edge_mask("Z") {
              if (plate_corner_rounding == "Chamfer")
                chamfer_edge_mask(chamfer=plate_corner_rounding_size);
              if (plate_corner_rounding == "Fillet")
                rounding_edge_mask(r=plate_corner_rounding_size);
            }
          if (slot_type == "slot")
            right(plate_slot_horizontal_offset) back(plate_slot_vertical_offset)
                attach(TOP, TOP, align=final_plate_alignment, inside=true)
                  tag("remove") openconnect_slot_grid(slot_cfg=slot_cfg, slot_type="slot", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=EPS);
          else if (slot_type == "negslot")
            right(plate_slot_horizontal_offset) back(plate_slot_vertical_offset)
                attach(TOP, BOTTOM, align=final_plate_alignment)
                  tag("") openconnect_slot_grid(slot_cfg=slot_cfg, slot_type="slot", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=0);
          else if (slot_type == "vase")
            right(plate_slot_horizontal_offset) back(plate_slot_vertical_offset)
                attach(TOP, BOTTOM, align=final_plate_alignment)
                  tag("") openconnect_slot_grid(slot_cfg=slot_cfg, slot_type="vase", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=0);
        }

//END generation
