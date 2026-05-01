/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
//Default height is vertical_grids × 28mm, which aligns with openGrid tiles. You can override it by enabling "use_custom_height" below.
hook_vertical_grids = 1;
//Controls the hook reach after the stem. hook_length + hook_thickness adds up to the total outer length of the hook.
hook_length = 30;
//Recommended minimum width is 20mm. For smaller hooks, try "openGrid framefit hook generator".
hook_width = 28;
hook_thickness = 7;
hook_shape_type = "Circular"; //[Circular,Rectangular,Flat]
//Total radius for circular hooks is capped by hook_length and hook_height (hook_vertical_grids x 28).
circular_corner_radius = 15;
circular_tip_radius = 15;
circular_tip_angle = 165; //[90:15:210]
//0.8 means the thickness at the tip is 80% of the thickness at the start.
circular_thickness_scale = 0.8; //[0.5:0.1:1]
//Extra tip length for rectangular hooks.
rectangular_tip_extra_length = 6;

/* [Truss Settings] */
//Add a truss for more strength.
truss_vertical_grids = 0;
truss_thickness = 5;
truss_rounding = 2;
truss_max_angle = 60; //[30:5:90]

/* [Slot Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces. When printing on the side, place the locking mechanism side closer to the print bed.
slot_entryramp_flip = false;
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/* [Advanced Settings] */
use_custom_height = false;
custom_hook_height = 70;
hook_side_rounding = 2.4; //0.2
hook_tip_rounding = 5; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>
//Double Lock is intended for small models that only use one or two slots.
slot_lock_side = "Left"; //[Left:Standard, Both:Double]
slot_edge_feature_widen = "Side"; //[Both, Top, Side, None]

_slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance
);
vertical_grids = use_custom_height ? max(1, floor(custom_hook_height / OG_TILE_SIZE)) + truss_vertical_grids : hook_vertical_grids + truss_vertical_grids;
horizontal_grids = max(1, floor(hook_width / OG_TILE_SIZE));
hook_stem_height = use_custom_height ? custom_hook_height : hook_vertical_grids * OG_TILE_SIZE;

final_corner_radius = hook_shape_type == "Circular" ? min(circular_corner_radius, hook_stem_height - hook_thickness / 2 - hook_side_rounding, hook_length) : hook_thickness;
final_tip_radius = hook_shape_type == "Circular" ? min(circular_tip_radius, hook_length - final_corner_radius) : hook_thickness;
stem_first_height = max(EPS, hook_stem_height - final_corner_radius);
available_truss_depth = hook_shape_type == "Circular" ? max(EPS, hook_length - final_tip_radius - hook_thickness / 2) : max(EPS, hook_length - final_tip_radius + hook_thickness);

final_circular_thickness_scale = hook_shape_type == "Circular" ? circular_thickness_scale : 1;
final_side_chamfer = max(0, min(hook_thickness / 2 * final_circular_thickness_scale - 0.84, hook_width / 2 - 0.84, hook_side_rounding));
has_side_chamfer = final_side_chamfer > EPS;
function hook_scale_at(ratio) = 1 - (1 - final_circular_thickness_scale) * ratio;
function hook_thickness_at(ratio) = hook_thickness * hook_scale_at(ratio);
function hook_one_side_offset_at(ratio) = (hook_thickness - hook_thickness_at(ratio)) / 2;

hook_path_base = ["setdir", -90, "arcleft", final_corner_radius];
hook_path_flat = ["setdir", -90, "arcleft", final_corner_radius, "move", max(EPS, hook_length - final_corner_radius)];
hook_path_pre_tip = ["setdir", -90, "arcleft", final_corner_radius, "move", max(EPS, hook_length - final_corner_radius - final_tip_radius)];
hook_path_circ = ["setdir", -90, "arcleft", final_corner_radius, "move", max(EPS, hook_length - final_corner_radius - final_tip_radius), "arcleft", final_tip_radius, max(1, circular_tip_angle - 90)];
hook_path_rect = ["setdir", -90, "arcleft", final_corner_radius, "move", max(EPS, hook_length - final_corner_radius - final_tip_radius), "arcleft", final_tip_radius, 90, "move", rectangular_tip_extra_length];
hook_path =
  hook_shape_type == "Flat" ? hook_path_flat
  : hook_shape_type == "Rectangular" ? hook_path_rect
  : hook_shape_type == "Circular" ? hook_path_circ : [];

truss_touch_path =
  hook_shape_type == "Flat" ? hook_path_flat
  : hook_shape_type == "Rectangular" ? hook_path_pre_tip
  : final_tip_radius <= 0 || circular_tip_angle <= 90 ? hook_path
  : hook_path_pre_tip;

tip_length = max(0, min(hook_thickness_at(1), hook_width - final_side_chamfer * 2) / 2 - EPS);
tip_rounding_radius = max(0, min(hook_tip_rounding, tip_length - EPS));
path_first_ratio = path_length(turtle(hook_path_base)) / path_length(turtle(hook_path));
truss_touch_ratio = min(1, max(0, path_length(turtle(truss_touch_path)) / path_length(turtle(hook_path))));
hook_path_taper_compensation = hook_one_side_offset_at(path_first_ratio);
truss_height_offset = hook_one_side_offset_at(truss_touch_ratio) - hook_path_taper_compensation;

final_sweep_profile =
  has_side_chamfer ? difference(
      rect([hook_thickness, hook_width]),
      right(hook_thickness / 2, fwd(hook_width / 2, yflip(zrot(-180, mask2d_teardrop(r=final_side_chamfer, $fn=64))))),
      right(hook_thickness / 2, back(hook_width / 2, zrot(-180, mask2d_teardrop(r=final_side_chamfer, $fn=64))))
    )
  : rect([hook_thickness, hook_width]);
offset_sweep_profile = scale([hook_scale_at(1), 1, 1], final_sweep_profile);

hook_length_annotation_y = -hook_stem_height;
hook_length_annotation_z = hook_width;
function _path_last(path) = path[len(path) - 1];
function _hook_path_point_to_model_top(point) = [
  hook_thickness / 2 + point[0],
  point[1] - stem_first_height + hook_thickness_at(path_first_ratio) / 2,
  hook_width
];
function _sq(value) = value * value;
function _circumcenter_xy(a, b, c) =
  let(
    d = 2 * (a[0] * (b[1] - c[1]) + b[0] * (c[1] - a[1]) + c[0] * (a[1] - b[1])),
    a2 = _sq(a[0]) + _sq(a[1]),
    b2 = _sq(b[0]) + _sq(b[1]),
    c2 = _sq(c[0]) + _sq(c[1])
  )
  abs(d) <= EPS ? [(a[0] + c[0]) / 2, (a[1] + c[1]) / 2, a[2]] : [
    (a2 * (b[1] - c[1]) + b2 * (c[1] - a[1]) + c2 * (a[1] - b[1])) / d,
    (a2 * (c[0] - b[0]) + b2 * (a[0] - c[0]) + c2 * (b[0] - a[0])) / d,
    a[2]
  ];
function _fmt_annotation_vec(point) = str(point[0], ",", point[1], ",", point[2]);
function _fmt_annotation_vec_list(points, index=0) =
  index >= len(points) ? "" :
  str(index == 0 ? "" : ";", _fmt_annotation_vec(points[index]), _fmt_annotation_vec_list(points, index + 1));
hook_tip_radius_arc_angle = max(1, circular_tip_angle - 90);
hook_tip_radius_arc_segments = 16;
function _hook_tip_radius_path_at(angle) = [
  "setdir", -90,
  "arcleft", final_corner_radius,
  "move", max(EPS, hook_length - final_corner_radius - final_tip_radius),
  "arcleft", final_tip_radius, angle
];
hook_tip_radius_arc_points = [
  for (i = [0:hook_tip_radius_arc_segments])
    _hook_path_point_to_model_top(_path_last(turtle(_hook_tip_radius_path_at(hook_tip_radius_arc_angle * i / hook_tip_radius_arc_segments))))
];
hook_tip_radius_start_anchor = _hook_path_point_to_model_top(_path_last(turtle(hook_path_pre_tip)));
hook_tip_radius_mid_anchor = _hook_path_point_to_model_top(_path_last(turtle(_hook_tip_radius_path_at(hook_tip_radius_arc_angle / 2))));
hook_tip_radius_end_anchor = _hook_path_point_to_model_top(_path_last(turtle(hook_path_circ)));
hook_tip_radius_center_anchor = _circumcenter_xy(hook_tip_radius_start_anchor, hook_tip_radius_mid_anchor, hook_tip_radius_end_anchor);
hook_corner_radius_arc_segments = 12;
function _hook_corner_radius_path_at(angle) = [
  "setdir", -90,
  "arcleft", final_corner_radius, angle
];
hook_corner_radius_arc_points = [
  for (i = [0:hook_corner_radius_arc_segments])
    _hook_path_point_to_model_top(_path_last(turtle(_hook_corner_radius_path_at(90 * i / hook_corner_radius_arc_segments))))
];
hook_corner_radius_start_anchor = _hook_path_point_to_model_top(_path_last(turtle(["setdir", -90])));
hook_corner_radius_mid_anchor = _hook_path_point_to_model_top(_path_last(turtle(_hook_corner_radius_path_at(45))));
hook_corner_radius_end_anchor = _hook_path_point_to_model_top(_path_last(turtle(hook_path_base)));
hook_corner_radius_center_anchor = _circumcenter_xy(hook_corner_radius_start_anchor, hook_corner_radius_mid_anchor, hook_corner_radius_end_anchor);
rectangular_tip_start_anchor = _hook_path_point_to_model_top(_path_last(turtle([
  "setdir", -90,
  "arcleft", final_corner_radius,
  "move", max(EPS, hook_length - final_corner_radius - final_tip_radius),
  "arcleft", final_tip_radius, 90
])));
rectangular_tip_end_anchor = _hook_path_point_to_model_top(_path_last(turtle(hook_path_rect)));

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

module emit_sturdy_hook_annotations() {
  emit_context_values(
    "sturdy_hook_context",
    [
      "OG_TILE_SIZE",
      "horizontal_grids",
      "vertical_grids",
      "hook_vertical_grids",
      "truss_vertical_grids",
      "truss_thickness",
      "truss_rounding",
      "truss_max_angle",
      "hook_length",
      "hook_thickness",
      "hook_width",
      "hook_shape_type",
      "circular_corner_radius",
      "circular_tip_radius",
      "circular_tip_angle",
      "circular_thickness_scale",
      "rectangular_tip_extra_length",
      "final_corner_radius",
      "final_tip_radius",
      "final_circular_thickness_scale"
    ],
    [
      OG_TILE_SIZE,
      horizontal_grids,
      vertical_grids,
      hook_vertical_grids,
      truss_vertical_grids,
      truss_thickness,
      truss_rounding,
      truss_max_angle,
      hook_length,
      hook_thickness,
      hook_width,
      hook_shape_type,
      circular_corner_radius,
      circular_tip_radius,
      circular_tip_angle,
      circular_thickness_scale,
      rectangular_tip_extra_length,
      final_corner_radius,
      final_tip_radius,
      final_circular_thickness_scale
    ]
  );
  emit_dimension_annotation(
    id="hook_vertical_grids",
    label=str("hook_vertical_grids x ", OG_TILE_SIZE, "mm"),
    axis="y",
    value=hook_stem_height,
    start=[0, 0, hook_length_annotation_z],
    end=[0, -hook_stem_height, hook_length_annotation_z],
    basis="stem_height_from_hook_vertical_grids"
  );
  emit_dimension_annotation(
    id="hook_thickness",
    label="hook_thickness",
    axis="x",
    value=hook_thickness,
    start=[0, hook_length_annotation_y, hook_length_annotation_z],
    end=[hook_thickness, hook_length_annotation_y, hook_length_annotation_z],
    basis="stem_thickness_same_plane_as_hook_length"
  );
  emit_dimension_annotation(
    id="hook_length",
    label="hook_length",
    axis="x",
    value=hook_length,
    start=[hook_thickness, hook_length_annotation_y, hook_length_annotation_z],
    end=[hook_thickness + hook_length, hook_length_annotation_y, hook_length_annotation_z],
    basis="outer_reach_after_stem"
  );
  emit_dimension_annotation(
    id="hook_width",
    label="hook_width",
    axis="z",
    value=hook_width,
    start=[0, -final_side_chamfer * (2 - sqrt(2)), 0],
    end=[0, -final_side_chamfer * (2 - sqrt(2)), hook_width],
    basis="extrusion_width_back_rounded_corner_full_width"
  );
  if (truss_vertical_grids > 0) {
    emit_dimension_annotation(
      id="truss_vertical_grids",
      label=str("truss_vertical_grids x ", OG_TILE_SIZE, "mm"),
      axis="y",
      value=truss_vertical_grids * OG_TILE_SIZE,
      start=[0, -hook_stem_height, hook_length_annotation_z],
      end=[0, -(hook_stem_height + truss_vertical_grids * OG_TILE_SIZE), hook_length_annotation_z],
      basis="truss_height_from_truss_vertical_grids"
    );
    emit_dimension_annotation(
      id="truss_thickness",
      label="truss_thickness",
      axis="x",
      value=truss_thickness,
      start=[hook_thickness, -hook_stem_height, hook_length_annotation_z],
      end=[hook_thickness + truss_thickness, -hook_stem_height, hook_length_annotation_z],
      basis="nominal_truss_member_thickness"
    );
  }
  if (hook_shape_type == "Rectangular" && rectangular_tip_extra_length > EPS) {
    emit_dimension_annotation(
      id="rectangular_tip_extra_length",
      label="rectangular_tip_extra_length",
      axis="y",
      value=rectangular_tip_extra_length,
      start=rectangular_tip_start_anchor,
      end=rectangular_tip_end_anchor,
      basis="extra_straight_tip_from_turtle_path"
    );
  }
  if (hook_shape_type == "Circular" && final_corner_radius > EPS) {
    emit_radius_annotation(
      id="circular_corner_radius",
      label="circular_corner_radius",
      value=final_corner_radius,
      center=hook_corner_radius_center_anchor,
      edge=hook_corner_radius_mid_anchor,
      basis="corner_radius_center_to_midpoint_from_turtle_path"
    );
    emit_arc_annotation(
      id="circular_corner_radius_extent",
      label="circular_corner_radius_extent",
      value=final_corner_radius,
      points=hook_corner_radius_arc_points,
      basis="corner_radius_arc_from_turtle_path"
    );
    emit_feature_annotation(
      id="circular_corner_radius_start",
      label="circular_corner_radius_start",
      value=final_corner_radius,
      anchor=hook_corner_radius_start_anchor,
      basis="start_of_corner_radius_arc_from_turtle_path"
    );
    emit_feature_annotation(
      id="circular_corner_radius_end",
      label="circular_corner_radius_end",
      value=final_corner_radius,
      anchor=hook_corner_radius_end_anchor,
      basis="end_of_corner_radius_arc_from_turtle_path"
    );
  }
  if (hook_shape_type == "Circular" && final_tip_radius > EPS) {
    emit_radius_annotation(
      id="circular_tip_radius",
      label="circular_tip_radius",
      value=final_tip_radius,
      center=hook_tip_radius_center_anchor,
      edge=hook_tip_radius_mid_anchor,
      basis="tip_radius_center_to_midpoint_from_turtle_path"
    );
    emit_arc_annotation(
      id="circular_tip_radius_extent",
      label="circular_tip_radius_extent",
      value=final_tip_radius,
      points=hook_tip_radius_arc_points,
      basis="tip_radius_arc_from_turtle_path"
    );
    emit_feature_annotation(
      id="circular_tip_radius_start",
      label="circular_tip_radius_start",
      value=final_tip_radius,
      anchor=hook_tip_radius_start_anchor,
      basis="start_of_tip_radius_arc_from_turtle_path"
    );
    emit_feature_annotation(
      id="circular_tip_radius_end",
      label="circular_tip_radius_end",
      value=final_tip_radius,
      anchor=hook_tip_radius_end_anchor,
      basis="end_of_tip_radius_arc_from_turtle_path"
    );
  }
}

emit_sturdy_hook_annotations();

//BEGIN generation
diff(remove="rm0")
  diff(remove="rm1", keep="kp1 rm0") {
    cuboid([hook_thickness, hook_stem_height, hook_width], anchor=BACK + BOTTOM + LEFT, rounding=final_side_chamfer, edges=[BACK + RIGHT], $fn=64) {
      attach(LEFT, TOP, align=BACK, inside=true, spin=90)
        tag("rm0") openconnect_slot_grid(slot_cfg=_slot_cfg, horizontal_grids=horizontal_grids, vertical_grids=vertical_grids, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=EPS);
      if (has_side_chamfer) {
        tag("rm1") edge_profile([TOP + RIGHT, BOTTOM + RIGHT, BACK + TOP, BACK + BOTTOM], excess=0)
            mask2d_teardrop(r=final_side_chamfer, $fn=64);
        tag("rm1") corner_profile([BACK + TOP + RIGHT, BACK + BOTTOM + RIGHT], r=final_side_chamfer)
            mask2d_teardrop(r=final_side_chamfer, $fn=64);
      }
      tag_diff(remove="rm2", tag="kp1") {
        attach(FRONT, FRONT, align=LEFT, inside=true, shiftout=0)
          tag("") cuboid([final_corner_radius + hook_thickness / 2, final_corner_radius + hook_thickness / 2, hook_width], chamfer=final_side_chamfer, edges=[LEFT + TOP, LEFT + BOTTOM])
              back(final_corner_radius / 2) right(final_corner_radius / 2)
                  tag("rm2") zcyl(r=final_corner_radius, h=hook_width + EPS * 2);
      }
      if (hook_shape_type == "Rectangular")
        tag_diff(remove="rm2", tag="kp1") {
          right(hook_length - final_tip_radius)
            attach(FRONT, FRONT, align=LEFT, inside=true, shiftout=0)
              tag("") cuboid([hook_thickness + final_corner_radius, hook_thickness + final_corner_radius - tip_length, hook_width])
                  back(final_tip_radius / 2) left(final_tip_radius / 2)
                      tag("rm2") zcyl(r=hook_thickness, h=hook_width + EPS * 2);
        }
      if (truss_vertical_grids > 0) {
        truss_height = truss_vertical_grids * OG_TILE_SIZE;
        truss_angle = min(truss_max_angle, adj_opp_to_ang(truss_height + truss_height_offset, available_truss_depth + truss_height_offset));
        truss_depth = min(available_truss_depth, ang_adj_to_opp(truss_angle, truss_height + truss_height_offset) - truss_height_offset);
        attach(FRONT, BACK)
          cuboid([hook_thickness, truss_height, hook_width]) {
            back(truss_height_offset) down(hook_width / 2) position(RIGHT + BACK)
                  sturdy_truss_sweep(
                    truss_height=truss_height,
                    truss_depth=truss_depth,
                    truss_thickness=truss_thickness,
                    truss_width=hook_width,
                    truss_rounding=truss_rounding,
                    truss_angle=truss_angle,
                    truss_height_offset=truss_height_offset
                  );
          }
          }
      }
    tag_diff(remove="rm2", tag="kp1")
      up(hook_width / 2) fwd(stem_first_height - hook_thickness_at(path_first_ratio) / 2) right(hook_thickness / 2) {
            path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[hook_scale_at(1), 1]) {
              if (hook_shape_type == "Flat")
                attach("end", LEFT)
                  cuboid([tip_length, hook_thickness, hook_width], rounding=final_side_chamfer / 2, edges=BACK + RIGHT, $fn=64) {
                    if (has_side_chamfer)
                      tag("rm2") edge_profile([BACK + TOP, BACK + BOTTOM])
                          mask2d_teardrop(r=final_side_chamfer, $fn=64);
                  }
              else
                attach("end", "top")
                  offset_sweep(offset_sweep_profile, height=tip_length, bottom=os_circle(r=tip_rounding_radius), spin=180, $fn=128);
            }
          }
  }
//END generation
module sturdy_truss_sweep(truss_height, truss_depth, truss_thickness, truss_width, truss_rounding = EPS, truss_angle = 45, truss_height_offset = 0) {
  truss_outer_depth = truss_depth + truss_height_offset;
  truss_outer_height = truss_height + truss_height_offset;
  truss_final_thickness = max(EPS, min(truss_outer_depth / 2 - EPS, truss_thickness));
  truss_inner_depth = max(0, truss_depth - ang_adj_to_hyp(truss_angle, truss_final_thickness));
  truss_inner_height = max(0, truss_height - ang_opp_to_hyp(truss_angle, truss_final_thickness));
  truss_final_rounding = min(truss_rounding, truss_inner_depth / 2 - EPS, truss_inner_height / 2 - EPS);
  trap_large = zrot(-90, trapezoid(w1=truss_outer_height, w2=EPS, h=truss_outer_depth, shift=-(truss_outer_height - EPS) / 2, anchor=FRONT + LEFT));
  trap_small =
    truss_inner_depth <= 0 || truss_inner_height <= 0 ? undef
    : [
      [0, -(truss_inner_height + truss_height_offset)],
      [0, 0],
      [truss_inner_depth + truss_height_offset, 0],
    ];
  truss_cutout =
    is_undef(trap_small) ? undef
    : truss_final_rounding > EPS ? round_corners(joint=truss_final_rounding, path=trap_small)
    : trap_small;
  truss_profile = is_undef(truss_cutout) ? trap_large : difference(trap_large, truss_cutout);
  linear_sweep(region=truss_profile, height=truss_width);
}
