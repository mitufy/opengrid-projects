/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
compartment_shape = "Rectangular"; //[Rectangular,Circular,Elliptic]
//The width of each compartment. Use slightly larger values for more wiggle room.
compartment_width = 38;
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
//"Tile Multiple" makes the sides of the holder align with openGrid tiles, but uses more space.
holder_width_mode = "Minimum"; //["Minimum", "Tile Multiple"]
//Setting this value to 0 generates a bottomless holder.
holder_bottom_thickness = 2; //0.1
//The thickness of the outer wall of the holder.
holder_outer_wall_thickness = 2;
//Tilt the container forward for easier access of content. Set to 0 for a standard vertical holder.
holder_tilt_angle = 0; //[0:5:45]
//Increase this value if you want the object to be held farther away from the wall.
holder_back_offset = 0;

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
front_opening_rounding = 3; //0.1

/* [openConnect Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces.
slot_entryramp_flip = false;
//Determine the horizontal position of the slot, when holder width is not a multiple of 28mm.
slot_horizontal_alignment = "Center"; //["Left", "Center", "Right"]
//Determine the vertical position of the slot, when holder height is not a multiple of 28mm.
slot_vertical_alignment = "Top"; //["Top", "Center", "Bottom"]
//Wall-mounted holders use direction "Up", while underdesk holders usually use "Left" or "Right".
slot_slide_direction = "Up"; //[Left,Right,Up,Down]
//Manually offset the horizontal position of the slots. Use this if you want more precise control than offered by slot_horizontal_alignment.
slot_horizontal_offset = 0; //0.1
//Manually offset the vertical position of the slots. Use this if you want more precise control than offered by slot_vertical_alignment.
slot_vertical_offset = 0; //0.1

/* [Advanced Settings] */
//Affects the thickness of the divider walls between columns.
holder_vertical_divider_thickness = 2; //0.1
//Affects the thickness of the divider walls between rows.
holder_horizontal_divider_thickness = 2; //0.1
//Increase clearances if the slots feel too tight.
slot_side_clearance = 0.1;
slot_depth_clearance = 0.1;
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8;
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6;

/* [Hidden] */
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;

include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>

slot_edge_feature_widen = "Both";
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
  compartment_shape == "Rectangular" ? rect([compartment_width, final_compartment_depth], rounding=final_compartment_rounding)
  : compartment_shape == "Circular" ? circle(d=compartment_width) : ellipse(d=[compartment_width, final_compartment_depth]);
compartment_width_scale = final_compartment_taper_width / compartment_width;
compartment_depth_scale = final_compartment_taper_depth / final_compartment_depth;

slot_face_height = ang_hyp_to_adj(final_holder_tilt_angle, final_holder_height);
minimum_slot_side_buffer = 4;
final_slot_h_grids = holder_width_mode == "Tile Multiple" ? max(1, floor(holder_width / OG_TILE_SIZE)) : max(1, floor((holder_width + minimum_slot_side_buffer) / OG_TILE_SIZE));
final_slot_v_grids = max(1, round(slot_face_height / OG_TILE_SIZE));
slot_flat_region = fwd((slot_face_height - round(slot_face_height / OG_TILE_SIZE) * OG_TILE_SIZE) / 2, rect([holder_width, slot_face_height]));

holder_min_x = 0;
holder_max_x = holder_width;
holder_min_y = -final_holder_depth;
holder_max_y = 0;
holder_min_z = 0;
holder_max_z = final_holder_height;
compartment_layout_depth = final_compartment_depth * compartment_row_count + holder_horizontal_divider_thickness * max(0, compartment_row_count - 1);
compartment_layout_width = compartment_width * compartment_column_count + holder_vertical_divider_thickness * max(0, compartment_column_count - 1);
compartment_annotation_min_x = (holder_width - compartment_layout_width) / 2;
compartment_annotation_max_x = compartment_annotation_min_x + compartment_width;
compartment_annotation_front_y = holder_min_y + holder_outer_wall_thickness;
compartment_annotation_back_y = compartment_annotation_front_y + final_compartment_depth;
compartment_annotation_center_x = (compartment_annotation_min_x + compartment_annotation_max_x) / 2;
compartment_annotation_center_y = (compartment_annotation_front_y + compartment_annotation_back_y) / 2;
compartment_annotation_z = holder_max_z;
compartment_height_annotation_min_z = holder_min_z + max(0, holder_bottom_thickness);
compartment_height_annotation_max_z = compartment_height_annotation_min_z + final_compartment_height;
holder_bottom_thickness_annotation_min_z = holder_min_z;
holder_bottom_thickness_annotation_max_z = compartment_height_annotation_min_z;
holder_back_offset_annotation_start_y = compartment_annotation_back_y;
holder_back_offset_annotation_end_y = holder_max_y - slot_wall_thickness;
holder_outer_wall_thickness_annotation_x = compartment_annotation_min_x;
holder_outer_wall_thickness_annotation_start_y = holder_min_y;
holder_outer_wall_thickness_annotation_end_y = compartment_annotation_front_y;
front_opening_annotation_center_x = compartment_annotation_min_x + compartment_width / 2;
front_opening_annotation_min_x = front_opening_annotation_center_x - front_opening_width / 2;
front_opening_annotation_max_x = front_opening_annotation_center_x + front_opening_width / 2;
front_opening_annotation_y = holder_min_y;
front_opening_annotation_min_z = holder_max_z - final_front_opening_height;
front_opening_annotation_max_z = holder_max_z;
compartment_corner_center = [
  compartment_annotation_max_x - final_compartment_rounding,
  compartment_annotation_back_y - final_compartment_rounding,
  compartment_annotation_z
];
compartment_corner_edge = [
  compartment_annotation_max_x,
  compartment_annotation_back_y - final_compartment_rounding,
  compartment_annotation_z
];
compartment_corner_arc_mid = [
  compartment_annotation_max_x - final_compartment_rounding + final_compartment_rounding * cos(45),
  compartment_annotation_back_y - final_compartment_rounding + final_compartment_rounding * sin(45),
  compartment_annotation_z
];
compartment_corner_arc_end = [
  compartment_annotation_max_x - final_compartment_rounding,
  compartment_annotation_back_y,
  compartment_annotation_z
];
holder_tilt_angle_anchor = [holder_max_x, holder_max_y, holder_min_z];
holder_tilt_angle_arc_radius = final_holder_height;
holder_tilt_angle_arc_start = [
  holder_max_x,
  holder_max_y,
  holder_min_z + holder_tilt_angle_arc_radius
];
holder_tilt_angle_arc_mid = [
  holder_max_x,
  holder_max_y - holder_tilt_angle_arc_radius * sin(final_holder_tilt_angle / 2),
  holder_min_z + holder_tilt_angle_arc_radius * cos(final_holder_tilt_angle / 2)
];
holder_tilt_angle_arc_end = [
  holder_max_x,
  holder_max_y - holder_tilt_angle_arc_radius * sin(final_holder_tilt_angle),
  holder_min_z + holder_tilt_angle_arc_radius * cos(final_holder_tilt_angle)
];

module emit_dimension_annotation(id, label, axis, value, start, end, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=dimension",
      "|label=", label,
      "|axis=", axis,
      "|value=", value,
      "|start=", start[0], ",", start[1], ",", start[2],
      "|end=", end[0], ",", end[1], ",", end[2],
      "|basis=", basis
    ));
}

function _fmt_annotation_vec(v) = str(v[0], ",", v[1], ",", v[2]);
function _fmt_annotation_vec_list(points, index=0) =
  index >= len(points) ? "" :
  str(index == 0 ? "" : ";", _fmt_annotation_vec(points[index]), _fmt_annotation_vec_list(points, index + 1));

function _fmt_context_values(names, values, index=0) =
  index >= len(names) ? "" :
  str(index == 0 ? "" : ";", names[index], "=", values[index], _fmt_context_values(names, values, index + 1));

module emit_context_values(id, names, values) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=context",
      "|values=", _fmt_context_values(names, values)
    ));
}

module emit_feature_annotation(id, label, value, anchor, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=feature",
      "|label=", label,
      "|value=", value,
      "|anchor=", anchor[0], ",", anchor[1], ",", anchor[2],
      "|basis=", basis
    ));
}

module emit_radius_annotation(id, label, value, center, edge, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=radius",
      "|label=", label,
      "|value=", value,
      "|center=", center[0], ",", center[1], ",", center[2],
      "|edge=", edge[0], ",", edge[1], ",", edge[2],
      "|basis=", basis
    ));
}

module emit_arc_annotation(id, label, value, points, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=arc",
      "|label=", label,
      "|value=", value,
      "|start=", points[0][0], ",", points[0][1], ",", points[0][2],
      "|end=", points[len(points) - 1][0], ",", points[len(points) - 1][1], ",", points[len(points) - 1][2],
      "|points=", _fmt_annotation_vec_list(points),
      "|basis=", basis
    ));
}

module emit_general_holder_annotations() {
  emit_context_values(
    "general_holder_context",
    [
      "OG_TILE_SIZE",
      "compartment_shape",
      "compartment_column_count",
      "compartment_row_count",
      "holder_width",
      "final_holder_depth",
      "final_holder_height",
      "final_holder_tilt_angle",
      "slot_face_height",
      "final_slot_h_grids",
      "final_slot_v_grids",
      "front_opening_width",
      "front_opening_height",
      "final_front_opening_height",
      "front_opening_rounding",
      "compartment_width",
      "final_compartment_depth",
      "final_compartment_height",
      "holder_bottom_thickness",
      "holder_outer_wall_thickness",
      "holder_back_offset",
      "final_compartment_rounding",
      "enable_bottom_taper",
      "final_compartment_taper_width",
      "final_compartment_taper_depth",
      "holder_vertical_divider_thickness",
      "holder_horizontal_divider_thickness"
    ],
    [
      OG_TILE_SIZE,
      compartment_shape,
      compartment_column_count,
      compartment_row_count,
      holder_width,
      final_holder_depth,
      final_holder_height,
      final_holder_tilt_angle,
      slot_face_height,
      final_slot_h_grids,
      final_slot_v_grids,
      front_opening_width,
      front_opening_height,
      final_front_opening_height,
      front_opening_rounding,
      compartment_width,
      final_compartment_depth,
      final_compartment_height,
      max(0, holder_bottom_thickness),
      holder_outer_wall_thickness,
      holder_back_offset,
      final_compartment_rounding,
      enable_bottom_taper,
      final_compartment_taper_width,
      final_compartment_taper_depth,
      holder_vertical_divider_thickness,
      holder_horizontal_divider_thickness
    ]
  );
  emit_dimension_annotation(
    id="holder_width",
    label="holder_width",
    axis="x",
    value=holder_width,
    start=[holder_min_x, holder_min_y, holder_min_z],
    end=[holder_max_x, holder_min_y, holder_min_z],
    basis="overall_holder_width_on_front_bottom_edge"
  );
  emit_dimension_annotation(
    id="holder_depth",
    label="holder_depth",
    axis="y",
    value=final_holder_depth,
    start=[holder_min_x, holder_min_y, holder_max_z],
    end=[holder_min_x, holder_max_y, holder_max_z],
    basis="overall_holder_depth_on_camera_front_side"
  );
  emit_dimension_annotation(
    id="holder_height",
    label="holder_height",
    axis="z",
    value=final_holder_height,
    start=[holder_min_x, holder_max_y, holder_min_z],
    end=[holder_min_x, holder_max_y, holder_max_z],
    basis="overall_holder_height"
  );
  emit_dimension_annotation(
    id="compartment_width",
    label="compartment_width",
    axis="x",
    value=compartment_width,
    start=[compartment_annotation_min_x, compartment_annotation_front_y, compartment_annotation_z],
    end=[compartment_annotation_max_x, compartment_annotation_front_y, compartment_annotation_z],
    basis="first_compartment_opening_width"
  );
  if (compartment_shape != "Circular")
    emit_dimension_annotation(
      id="compartment_depth",
      label="compartment_depth",
      axis="y",
      value=compartment_depth,
      start=[compartment_annotation_min_x, compartment_annotation_front_y, compartment_annotation_z],
      end=[compartment_annotation_min_x, compartment_annotation_back_y, compartment_annotation_z],
      basis="first_compartment_opening_depth"
    );
  if (compartment_shape == "Rectangular" && final_compartment_rounding > 0) {
    emit_radius_annotation(
      id="compartment_corner_rounding",
      label="compartment_corner_rounding",
      value=final_compartment_rounding,
      center=compartment_corner_center,
      edge=compartment_corner_edge,
      basis="first_compartment_back_right_corner_rounding"
    );
    emit_arc_annotation(
      id="compartment_corner_rounding_extent",
      label="compartment_corner_rounding_extent",
      value=final_compartment_rounding,
      points=[compartment_corner_edge, compartment_corner_arc_mid, compartment_corner_arc_end],
      basis="first_compartment_back_right_corner_rounding_extent"
    );
  }
  if (holder_back_offset > 0)
    emit_dimension_annotation(
      id="holder_back_offset",
      label="holder_back_offset",
      axis="y",
      value=holder_back_offset,
      start=[compartment_annotation_min_x, holder_back_offset_annotation_start_y, compartment_annotation_z],
      end=[compartment_annotation_min_x, holder_back_offset_annotation_end_y, compartment_annotation_z],
      basis="extra_depth_added_by_holder_back_offset"
    );
  if (holder_outer_wall_thickness > 0)
    emit_dimension_annotation(
      id="holder_outer_wall_thickness",
      label="holder_outer_wall_thickness",
      axis="y",
      value=holder_outer_wall_thickness,
      start=[holder_outer_wall_thickness_annotation_x, holder_outer_wall_thickness_annotation_start_y, compartment_annotation_z],
      end=[holder_outer_wall_thickness_annotation_x, holder_outer_wall_thickness_annotation_end_y, compartment_annotation_z],
      basis="front_outer_wall_thickness_from_holder_outer_wall_thickness"
    );
  if (enable_bottom_taper) {
    emit_dimension_annotation(
      id="compartment_bottom_width",
      label="compartment_bottom_width",
      axis="x",
      value=final_compartment_taper_width,
      start=[compartment_annotation_center_x - final_compartment_taper_width / 2, compartment_annotation_center_y, holder_bottom_thickness_annotation_max_z],
      end=[compartment_annotation_center_x + final_compartment_taper_width / 2, compartment_annotation_center_y, holder_bottom_thickness_annotation_max_z],
      basis="first_compartment_bottom_taper_width"
    );
    if (compartment_shape != "Circular")
      emit_dimension_annotation(
        id="compartment_bottom_depth",
        label="compartment_bottom_depth",
        axis="y",
        value=final_compartment_taper_depth,
        start=[compartment_annotation_center_x, compartment_annotation_center_y - final_compartment_taper_depth / 2, holder_bottom_thickness_annotation_max_z],
        end=[compartment_annotation_center_x, compartment_annotation_center_y + final_compartment_taper_depth / 2, holder_bottom_thickness_annotation_max_z],
        basis="first_compartment_bottom_taper_depth"
      );
  }
  if (compartment_column_count > 1)
    emit_dimension_annotation(
      id="holder_vertical_divider_thickness",
      label="holder_vertical_divider_thickness",
      axis="x",
      value=holder_vertical_divider_thickness,
      start=[compartment_annotation_max_x, compartment_annotation_front_y, compartment_annotation_z],
      end=[compartment_annotation_max_x + holder_vertical_divider_thickness, compartment_annotation_front_y, compartment_annotation_z],
      basis="divider_between_first_two_compartment_columns"
    );
  if (compartment_row_count > 1)
    emit_dimension_annotation(
      id="holder_horizontal_divider_thickness",
      label="holder_horizontal_divider_thickness",
      axis="y",
      value=holder_horizontal_divider_thickness,
      start=[compartment_annotation_min_x, compartment_annotation_back_y, compartment_annotation_z],
      end=[compartment_annotation_min_x, compartment_annotation_back_y + holder_horizontal_divider_thickness, compartment_annotation_z],
      basis="divider_between_first_two_compartment_rows"
    );
  if (holder_bottom_thickness > 0)
    emit_dimension_annotation(
      id="holder_bottom_thickness",
      label="holder_bottom_thickness",
      axis="z",
      value=max(0, holder_bottom_thickness),
      start=[holder_max_x, holder_min_y, holder_bottom_thickness_annotation_min_z],
      end=[holder_max_x, holder_min_y, holder_bottom_thickness_annotation_max_z],
      basis="bottom_floor_thickness_from_holder_bottom_thickness"
    );
  emit_dimension_annotation(
    id="compartment_height",
    label="compartment_height",
    axis="z",
    value=final_compartment_height,
    start=[holder_max_x, holder_min_y, compartment_height_annotation_min_z],
    end=[holder_max_x, holder_min_y, compartment_height_annotation_max_z],
    basis="usable_compartment_height_from_compartment_height"
  );
  emit_feature_annotation(
    id="holder_tilt_angle",
    label="holder_tilt_angle",
    value=final_holder_tilt_angle,
    anchor=holder_tilt_angle_anchor,
    basis="bottom_rear_side_corner_for_holder_tilt_angle"
  );
  if (final_holder_tilt_angle > 0) {
    emit_radius_annotation(
      id="holder_tilt_angle_radius",
      label="holder_tilt_angle_radius",
      value=holder_tilt_angle_arc_radius,
      center=holder_tilt_angle_anchor,
      edge=holder_tilt_angle_arc_start,
      basis="holder_tilt_angle_arc_radius"
    );
    emit_arc_annotation(
      id="holder_tilt_angle_extent",
      label="holder_tilt_angle_extent",
      value=final_holder_tilt_angle,
      points=[holder_tilt_angle_arc_start, holder_tilt_angle_arc_mid, holder_tilt_angle_arc_end],
      basis="holder_tilt_angle_arc_extent"
    );
  }
  if (front_opening_width > 0 && front_opening_height > 0) {
    emit_dimension_annotation(
      id="front_opening_width",
      label="front_opening_width",
      axis="x",
      value=front_opening_width,
      start=[front_opening_annotation_min_x, front_opening_annotation_y, front_opening_annotation_min_z],
      end=[front_opening_annotation_max_x, front_opening_annotation_y, front_opening_annotation_min_z],
      basis="first_front_opening_width"
    );
    emit_dimension_annotation(
      id="front_opening_height",
      label="front_opening_height",
      axis="z",
      value=final_front_opening_height,
      start=[front_opening_annotation_min_x, front_opening_annotation_y, front_opening_annotation_min_z],
      end=[front_opening_annotation_min_x, front_opening_annotation_y, front_opening_annotation_max_z],
      basis="first_front_opening_effective_height"
    );
  }
}

emit_general_holder_annotations();

// xrot(-final_holder_tilt_angle)
right(holder_width / 2) zrot(180)
    diff() {
      back((final_compartment_depth * compartment_row_count) / 2 + (holder_horizontal_divider_thickness * max(0, compartment_row_count - 1)) / 2 + slot_wall_thickness + holder_back_offset)
        grid_copies(spacing=[compartment_width + holder_vertical_divider_thickness, final_compartment_depth + holder_horizontal_divider_thickness], n=[compartment_column_count, compartment_row_count])
          up(holder_bottom_thickness) xrot(180)
              tag("remove") linear_sweep(region=compartment_sweep_profile, height=final_compartment_height, scale=[compartment_width_scale, compartment_depth_scale], shift=[0, 0], anchor="original_top");
      prismoid(size1=[holder_width, final_holder_depth], h=final_holder_height, xang=[90, 90], yang=[90 + final_holder_tilt_angle, 90], rounding=[final_holder_rounding, final_holder_rounding, 0, 0], anchor=FRONT + BOTTOM) {
        h_offset = slot_horizontal_alignment == "Left" ? -(final_slot_h_grids * OG_TILE_SIZE - holder_width) / 2 : slot_horizontal_alignment == "Right" ? (final_slot_h_grids * OG_TILE_SIZE - holder_width) / 2 : 0;
        valign = slot_vertical_alignment == "Top" ? TOP : slot_vertical_alignment == "Bottom" ? BOTTOM : CENTER;

        right(slot_horizontal_offset) up(slot_vertical_offset)
            right(h_offset) attach(FRONT, TOP, align=valign, inside=true)
                tag("remove") openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="slot", horizontal_grids=final_slot_h_grids, vertical_grids=final_slot_v_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, slot_slide_direction=slot_slide_direction, excess_thickness=EPS, limit_region=[slot_flat_region]);
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
