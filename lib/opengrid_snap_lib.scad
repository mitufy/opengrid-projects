/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <opengrid_base.scad>
use <opengrid_threads_lib.scad>

function snap_body_cfg(
  snap_width = OG_SNAP_WIDTH,
  snap_height = OG_SNAP_WIDTH,
  snap_thickness = OG_STANDARD_THICKNESS,
  snap_body_shape = "Directional"
) =
  struct_set(
    [], [
      "snap_width",
      snap_width,
      "snap_height",
      snap_height,
      "snap_thickness",
      snap_thickness,
      "snap_body_shape",
      snap_body_shape,
    ]
  );

function snap_corner_cfg(
  directional_corner_fillet_radius = 1.5,
  snap_corner_edge_height = 1.5,
  snap_body_top_corner_extrude = 1.1,
  snap_body_bottom_corner_extrude = 0.6
) =
  struct_set(
    [], [
      "directional_corner_fillet_radius",
      directional_corner_fillet_radius,
      "snap_corner_edge_height",
      snap_corner_edge_height,
      "snap_body_top_corner_extrude",
      snap_body_top_corner_extrude,
      "snap_body_bottom_corner_extrude",
      snap_body_bottom_corner_extrude,
    ]
  );

function snap_cut_cfg(
  cut_width_inset = 6.2,
  bottom_cut_thickness = 0.6,
  bottom_cut_offset_to_top = 0.6,
  bottom_cut_offset_to_edge = 0.7,
  side_cut_thickness = 0.4,
  side_cut_depth = 0.8,
  side_cut_offset_to_top = 0.8,
  directional_slant_height_standard = 3.4,
  directional_slant_height_lite = 1.2,
  directional_slant_depth_standard = 0.8,
  directional_slant_depth_lite = 0.2,
  disable_all_side_cut = false,
  disable_all_bottom_cut = false,
  disable_front_side_cut = false,
  disable_directional_slant = false
) =
  struct_set(
    [], [
      "cut_width_inset",
      cut_width_inset,
      "bottom_cut_thickness",
      bottom_cut_thickness,
      "bottom_cut_offset_to_top",
      bottom_cut_offset_to_top,
      "bottom_cut_offset_to_edge",
      bottom_cut_offset_to_edge,
      "side_cut_thickness",
      side_cut_thickness,
      "side_cut_depth",
      side_cut_depth,
      "side_cut_offset_to_top",
      side_cut_offset_to_top,
      "directional_slant_height_standard",
      directional_slant_height_standard,
      "directional_slant_height_lite",
      directional_slant_height_lite,
      "directional_slant_depth_standard",
      directional_slant_depth_standard,
      "directional_slant_depth_lite",
      directional_slant_depth_lite,
      "disable_all_side_cut",
      disable_all_side_cut,
      "disable_all_bottom_cut",
      disable_all_bottom_cut,
      "disable_front_side_cut",
      disable_front_side_cut,
      "disable_directional_slant",
      disable_directional_slant,
    ]
  );

function snap_nub_cfg(
  basic_nub_width_inset = 7,
  basic_nub_depth = 0.4,
  basic_nub_width_tip_taper = 4,
  basic_nub_top_angle = 35,
  basic_nub_bottom_angle = 35,
  basic_nub_fillet_radius = 15,
  basic_nub_height_standard = 2,
  basic_nub_height_lite = 1.8,
  directional_nub_width_inset = 5,
  directional_nub_depth = 0.8,
  directional_nub_width_tip_taper = 1.6,
  directional_nub_top_angle = 35,
  directional_nub_height_standard = 4,
  directional_nub_height_lite = 2.4,
  directional_nub_bottom_angle_standard = 35,
  directional_nub_bottom_angle_lite = 45,
  directional_nub_fillet_radius = 2.8,
  antidirect_nub_height_standard = 2,
  antidirect_nub_height_lite = 1.4,
  nub_offset_to_top = 1.4
) =
  struct_set(
    [], [
      "basic_nub_width_inset",
      basic_nub_width_inset,
      "basic_nub_depth",
      basic_nub_depth,
      "basic_nub_width_tip_taper",
      basic_nub_width_tip_taper,
      "basic_nub_top_angle",
      basic_nub_top_angle,
      "basic_nub_bottom_angle",
      basic_nub_bottom_angle,
      "basic_nub_fillet_radius",
      basic_nub_fillet_radius,
      "basic_nub_height_standard",
      basic_nub_height_standard,
      "basic_nub_height_lite",
      basic_nub_height_lite,
      "directional_nub_width_inset",
      directional_nub_width_inset,
      "directional_nub_depth",
      directional_nub_depth,
      "directional_nub_width_tip_taper",
      directional_nub_width_tip_taper,
      "directional_nub_top_angle",
      directional_nub_top_angle,
      "directional_nub_height_standard",
      directional_nub_height_standard,
      "directional_nub_height_lite",
      directional_nub_height_lite,
      "directional_nub_bottom_angle_standard",
      directional_nub_bottom_angle_standard,
      "directional_nub_bottom_angle_lite",
      directional_nub_bottom_angle_lite,
      "directional_nub_fillet_radius",
      directional_nub_fillet_radius,
      "antidirect_nub_height_standard",
      antidirect_nub_height_standard,
      "antidirect_nub_height_lite",
      antidirect_nub_height_lite,
      "nub_offset_to_top",
      nub_offset_to_top,
    ]
  );

function snap_notch_cfg(
  notch_width = 5,
  notch_surface_inset = 1,
  notch_gap_inset = 1.8,
  notch_surface_height_standard = 1.2,
  notch_surface_height_lite = 0.8,
  notch_gap_height_standard = 1,
  notch_gap_height_lite = 0.6
) =
  struct_set(
    [], [
      "notch_width",
      notch_width,
      "notch_surface_inset",
      notch_surface_inset,
      "notch_gap_inset",
      notch_gap_inset,
      "notch_surface_height_standard",
      notch_surface_height_standard,
      "notch_surface_height_lite",
      notch_surface_height_lite,
      "notch_gap_height_standard",
      notch_gap_height_standard,
      "notch_gap_height_lite",
      notch_gap_height_lite,
    ]
  );

function snap_spring_cfg(
  spring_thickness = 1.26,
  spring_to_center_thickness = 0.84,
  spring_gap = 0.42,
  spring_face_chamfer = 0.2
) =
  struct_set(
    [], [
      "spring_thickness",
      spring_thickness,
      "spring_to_center_thickness",
      spring_to_center_thickness,
      "spring_gap",
      spring_gap,
      "spring_face_chamfer",
      spring_face_chamfer,
    ]
  );

module snap_corner(snapbody_cfg = [], snapcorner_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _corner_cfg = struct_merge(snap_corner_cfg(), snapcorner_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _directional_corner_fillet_radius = struct_val(_corner_cfg, "directional_corner_fillet_radius");
  _snap_corner_edge_height = struct_val(_corner_cfg, "snap_corner_edge_height");
  _snap_body_top_corner_extrude = struct_val(_corner_cfg, "snap_body_top_corner_extrude");
  _snap_body_bottom_corner_extrude = struct_val(_corner_cfg, "snap_body_bottom_corner_extrude");
  up(_snap_thickness / 2 - _snap_corner_edge_height / 2) {
    for (i = [FRONT + LEFT, FRONT + RIGHT, BACK + LEFT, BACK + RIGHT])
      attach(i, BOTTOM, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL - EPS)
        prismoid(size1=[OG_SNAP_CORNER_CHAMFER * sqrt(2), _snap_corner_edge_height], xang=45, yang=[45, 90], h=_snap_body_top_corner_extrude);
  }
  //bottom corners for directional full snaps
  if (_snap_body_shape == "Directional" && _snap_thickness >= OG_STANDARD_THICKNESS) {
    down(_snap_thickness / 2 - _snap_corner_edge_height / 2)
      diff("corner_fillet")
        attach([BACK + LEFT, BACK + RIGHT], BOTTOM, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL - EPS)
          prismoid(size1=[OG_SNAP_CORNER_CHAMFER * sqrt(2), _snap_corner_edge_height], xang=45, yang=[90, 45], h=_snap_body_bottom_corner_extrude)
            tag("corner_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=OG_STANDARD_THICKNESS, r=_directional_corner_fillet_radius, $fn=64);
  }
}
module snap_cut(snapbody_cfg = [], snapcut_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _cut_cfg = struct_merge(snap_cut_cfg(), snapcut_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _snap_width = struct_val(_body_cfg, "snap_width");
  _snap_height = struct_val(_body_cfg, "snap_height");

  _cut_width_inset = struct_val(_cut_cfg, "cut_width_inset");
  _bottom_cut_thickness = struct_val(_cut_cfg, "bottom_cut_thickness");
  _bottom_cut_offset_to_top = struct_val(_cut_cfg, "bottom_cut_offset_to_top");
  _bottom_cut_offset_to_edge = struct_val(_cut_cfg, "bottom_cut_offset_to_edge");
  _side_cut_thickness = struct_val(_cut_cfg, "side_cut_thickness");
  _side_cut_depth = struct_val(_cut_cfg, "side_cut_depth");
  _side_cut_offset_to_top = struct_val(_cut_cfg, "side_cut_offset_to_top");
  _directional_slant_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_height_standard") : struct_val(_cut_cfg, "directional_slant_height_lite");
  _directional_slant_depth = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_depth_standard") : struct_val(_cut_cfg, "directional_slant_depth_lite");
  _directional_corner_slant_depth = _directional_slant_depth / sqrt(2);

  _disable_all_side_cut = struct_val(_cut_cfg, "disable_all_side_cut");
  _disable_all_bottom_cut = struct_val(_cut_cfg, "disable_all_bottom_cut");
  _disable_front_side_cut = struct_val(_cut_cfg, "disable_front_side_cut");
  _disable_directional_slant = struct_val(_cut_cfg, "disable_directional_slant");

  for (i = [FRONT, LEFT, RIGHT, BACK]) {
    bottom_cut_length = ((i == LEFT || i == RIGHT) ? _snap_height : _snap_width) - _cut_width_inset * 2;
    bottom_cut_rounding = _snap_body_shape == "Directional" && i == FRONT ? 0 : _bottom_cut_thickness / 2;
    if (!_disable_all_bottom_cut && !(_snap_body_shape == "Directional" && i == BACK)) {
      down(_bottom_cut_offset_to_top)
        attach(i, FRONT, inside=true, shiftout=-_bottom_cut_offset_to_edge)
          cuboid([bottom_cut_length, _bottom_cut_thickness, _snap_thickness], rounding=bottom_cut_rounding, edges="Z", $fn=64);
    }
    if (!_disable_all_side_cut)
      if (i != FRONT || !_disable_front_side_cut)
        down(_side_cut_offset_to_top)
          attach(i, FRONT, align=TOP, inside=true)
            cuboid([bottom_cut_length, _side_cut_depth, _side_cut_thickness]);
  }
  if (_snap_body_shape == "Directional" && !_disable_all_bottom_cut)
    down(_snap_thickness / 2 - _directional_slant_height / 2) {
      bottom_cut_length = _snap_width - _cut_width_inset * 2;
      tag_diff("remove", "inner_remove") {
        attach(FRONT, BACK, inside=true, shiftout=-_bottom_cut_offset_to_edge - _bottom_cut_thickness)
          tag("") prismoid(size1=[bottom_cut_length, _directional_slant_depth], size2=[bottom_cut_length, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
        attach(FRONT, BACK, inside=true, shiftout=-_bottom_cut_offset_to_edge)
          tag("inner_remove") prismoid(size1=[bottom_cut_length, _directional_slant_depth], size2=[bottom_cut_length, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
      }
      tag_diff("keep", "inner_remove") {
        attach(FRONT, BACK, inside=true, shiftout=-_bottom_cut_offset_to_edge)
          tag("") prismoid(size1=[bottom_cut_length, _directional_slant_depth], size2=[bottom_cut_length, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
        attach(FRONT, BACK, inside=true)
          tag("inner_remove") prismoid(size1=[_snap_width, _directional_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
      }
    }
  if (_snap_body_shape == "Directional" && !_disable_directional_slant) {
    down(_snap_thickness / 2 - _directional_slant_height / 2) {
      attach(FRONT + LEFT, BACK, inside=true, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL)
        prismoid(size1=[_snap_width, _directional_corner_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_corner_slant_depth / 2], h=_directional_slant_height);
      attach(FRONT + RIGHT, BACK, inside=true, shiftout=-OG_SNAP_CORNER_OUTER_DIAGONAL)
        prismoid(size1=[_snap_width, _directional_corner_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_corner_slant_depth / 2], h=_directional_slant_height);
      attach(FRONT, BACK, inside=true)
        prismoid(size1=[_snap_width, _directional_slant_depth], size2=[_snap_width, 0], shift=[0, _directional_slant_depth / 2], h=_directional_slant_height);
    }
  }
}
module snap_nub(snapbody_cfg = [], snapnub_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _nub_cfg = struct_merge(snap_nub_cfg(), snapnub_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _snap_width = struct_val(_body_cfg, "snap_width");
  _snap_height = struct_val(_body_cfg, "snap_height");
  _basic_nub_width_inset = struct_val(_nub_cfg, "basic_nub_width_inset");
  _basic_nub_depth = struct_val(_nub_cfg, "basic_nub_depth");
  _basic_nub_width_tip_taper = struct_val(_nub_cfg, "basic_nub_width_tip_taper");
  _basic_nub_top_angle = struct_val(_nub_cfg, "basic_nub_top_angle");
  _basic_nub_bottom_angle = struct_val(_nub_cfg, "basic_nub_bottom_angle");
  _basic_nub_fillet_radius = struct_val(_nub_cfg, "basic_nub_fillet_radius");
  _directional_nub_width_inset = struct_val(_nub_cfg, "directional_nub_width_inset");
  _directional_nub_depth = struct_val(_nub_cfg, "directional_nub_depth");
  _directional_nub_width_tip_taper = struct_val(_nub_cfg, "directional_nub_width_tip_taper");
  _directional_nub_top_angle = struct_val(_nub_cfg, "directional_nub_top_angle");
  _directional_nub_fillet_radius = struct_val(_nub_cfg, "directional_nub_fillet_radius");
  _nub_offset_to_top = struct_val(_nub_cfg, "nub_offset_to_top");

  _basic_nub_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "basic_nub_height_standard") : struct_val(_nub_cfg, "basic_nub_height_lite");
  _directional_nub_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "directional_nub_height_standard") : struct_val(_nub_cfg, "directional_nub_height_lite");
  _antidirect_nub_height = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "antidirect_nub_height_standard") : struct_val(_nub_cfg, "antidirect_nub_height_lite");
  _directional_nub_bottom_angle = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_nub_cfg, "directional_nub_bottom_angle_standard") : struct_val(_nub_cfg, "directional_nub_bottom_angle_lite");

  basic_nub_yang = [_basic_nub_top_angle, _basic_nub_bottom_angle];
  directional_nub_yang = [_directional_nub_top_angle, _directional_nub_bottom_angle];

  diff("nub_remove") {
    for (i = [FRONT, LEFT, RIGHT, BACK]) {
      basic_nub_width = ((i == LEFT || i == RIGHT) ? _snap_height : _snap_width) - _basic_nub_width_inset * 2;
      directional_nub_width = ((i == LEFT || i == RIGHT) ? _snap_height : _snap_width) - _directional_nub_width_inset * 2;
      basic_nub_size1 = [basic_nub_width, _basic_nub_height];
      basic_nub_size2 = [basic_nub_width - _basic_nub_width_tip_taper, undef];
      directional_nub_size1 = [directional_nub_width, _directional_nub_height];
      directional_nub_size2 = [directional_nub_width - _directional_nub_width_tip_taper, undef];
      antidirect_nub_size1 = [basic_nub_width, _antidirect_nub_height];
      final_nub_size1 =
        (_snap_body_shape == "Directional" && i == BACK) ? directional_nub_size1
        : (_snap_body_shape == "Directional" && i == FRONT) ? antidirect_nub_size1
        : basic_nub_size1;
      final_nub_size2 =
        (_snap_body_shape == "Directional" && i == BACK) ? directional_nub_size2
        : basic_nub_size2;
      l_nub_yang = (_snap_body_shape == "Directional" && i == BACK) ? directional_nub_yang : basic_nub_yang;
      l_nub_depth = (_snap_body_shape == "Directional" && i == BACK) ? _directional_nub_depth : _basic_nub_depth;
      nub_fillet_radius = (_snap_body_shape == "Directional" && i == BACK) ? _directional_nub_fillet_radius : _basic_nub_fillet_radius;
      attach(i, BOTTOM, align=TOP, inset=_nub_offset_to_top, shiftout=-EPS)
        prismoid(size1=final_nub_size1, size2=final_nub_size2, yang=l_nub_yang, h=l_nub_depth)
          tag("nub_remove") edge_mask([TOP + LEFT, TOP + RIGHT])
              rounding_edge_mask(l=8, r=nub_fillet_radius, $fn=64);
    }
    attach(BOTTOM, TOP)
      tag("nub_remove") cuboid([_snap_width * 2, _snap_height * 2, _snap_thickness * 2]);
  }
}
module snap_uninstall_notch(snapbody_cfg = [], snapnotch_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _notch_cfg = struct_merge(snap_notch_cfg(), snapnotch_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _notch_width = struct_val(_notch_cfg, "notch_width");
  _notch_surface_inset = struct_val(_notch_cfg, "notch_surface_inset");
  _notch_gap_inset = struct_val(_notch_cfg, "notch_gap_inset");
  _notch_surface_height_standard = struct_val(_notch_cfg, "notch_surface_height_standard");
  _notch_surface_height_lite = struct_val(_notch_cfg, "notch_surface_height_lite");
  _notch_gap_height_standard = struct_val(_notch_cfg, "notch_gap_height_standard");
  _notch_gap_height_lite = struct_val(_notch_cfg, "notch_gap_height_lite");
  _notch_surface_height =
    _snap_thickness >= OG_STANDARD_THICKNESS ? _notch_surface_height_standard
    : _notch_surface_height_lite;
  _notch_gap_height =
    _snap_thickness >= OG_STANDARD_THICKNESS ? _notch_gap_height_standard
    : _notch_gap_height_lite;
  if (_notch_width > 0 && _notch_surface_inset > 0 && _notch_surface_height > 0)
    cuboid([_notch_width, _notch_surface_inset, _notch_surface_height], anchor=anchor, spin=spin, orient=orient)
      attach(BOTTOM, TOP, align=FRONT)
        cuboid([_notch_width, _notch_gap_inset, _notch_gap_height])
          //cut off remaining snap extrusion
          attach(FRONT, BACK, align=TOP)
            cuboid([_notch_width, _notch_gap_inset, _notch_gap_height]);
}
module expanding_spring(snapbody_cfg = [], spring_cfg = [], snapcorner_cfg = [], snapcut_cfg = []) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _spring_cfg = struct_merge(snap_spring_cfg(), spring_cfg);
  _corner_cfg = struct_merge(snap_corner_cfg(), snapcorner_cfg);
  _cut_cfg = struct_merge(snap_cut_cfg(), snapcut_cfg);

  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  _disable_directional_slant = struct_val(_cut_cfg, "disable_directional_slant");
  bottom_type_back = _snap_body_shape == "Directional" && _snap_thickness >= OG_STANDARD_THICKNESS ? "Corners" : "None";
  bottom_type_front = _snap_body_shape == "Directional" && !_disable_directional_slant ? "Slant" : "None";

  for (i = [0:1]) {
    bottom_type = i == 0 ? bottom_type_back : bottom_type_front;
    zrot(i * 180) {
      // spring-specific params
      _spring_thickness = struct_val(_spring_cfg, "spring_thickness");
      _spring_to_center_thickness = struct_val(_spring_cfg, "spring_to_center_thickness");
      _spring_gap = struct_val(_spring_cfg, "spring_gap");
      _spring_face_chamfer = struct_val(_spring_cfg, "spring_face_chamfer");
      // corner geometry
      _snap_corner_edge_height = struct_val(_corner_cfg, "snap_corner_edge_height");
      _snap_body_top_corner_extrude = struct_val(_corner_cfg, "snap_body_top_corner_extrude");
      _snap_body_bottom_corner_extrude = struct_val(_corner_cfg, "snap_body_bottom_corner_extrude");
      // slant geometry
      _directional_slant_depth =
        _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_depth_standard")
        : struct_val(_cut_cfg, "directional_slant_depth_lite");
      _directional_slant_height =
        _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_cut_cfg, "directional_slant_height_standard")
        : struct_val(_cut_cfg, "directional_slant_height_lite");
      // constants from opengrid_variable.scad (no global var needed)
      _threads_negative_diameter = OG_SNAP_THREADS_DIAMETER + OG_SNAP_THREADS_CLEARANCE;
      _snap_body_corner_inner_diagonal = OG_SNAP_CORNER_INNER_DIAGONAL;

      // gap_length: minimum reach to clear the thread hole center from the spring wall
      gap_length = _threads_negative_diameter / 2 + _spring_to_center_thickness;
      gap_top_profile = [[-_spring_gap / 2, 0], [-_spring_gap / 2, gap_length], [_spring_gap / 2, gap_length], [_spring_gap / 2, 0]];
      gap_top_profile_rounded = round_corners(gap_top_profile, method="circle", radius=[0, _spring_gap / 2, _spring_gap / 2, 0], $fn=64);
      middle_gap_side_profile_none = [
        [0, 0],
        [0, _snap_thickness],
        [gap_length, _snap_thickness],
        [gap_length, _snap_corner_edge_height],
        [gap_length + _snap_body_top_corner_extrude, _snap_corner_edge_height - _snap_body_top_corner_extrude],
        [gap_length + _snap_body_top_corner_extrude, 0],
      ];
      middle_gap_side_profile_slant = [
        [0, 0],
        [0, _snap_thickness],
        [gap_length - _directional_slant_depth, _snap_thickness],
        [gap_length, _snap_thickness - _directional_slant_height],
        [gap_length, _snap_corner_edge_height],
        [gap_length + _snap_body_top_corner_extrude, _snap_corner_edge_height - _snap_body_top_corner_extrude],
        [gap_length + _snap_body_top_corner_extrude, 0],
      ];
      middle_gap_side_profile_corner = [
        [0, 0],
        [0, _snap_thickness],
        [gap_length + _snap_body_bottom_corner_extrude, _snap_thickness],
        [gap_length + _snap_body_bottom_corner_extrude, _snap_thickness - (_snap_corner_edge_height - _snap_body_bottom_corner_extrude)],
        [gap_length, _snap_thickness - _snap_corner_edge_height],
        [gap_length, _snap_corner_edge_height],
        [gap_length + _snap_body_top_corner_extrude, _snap_corner_edge_height - _snap_body_top_corner_extrude],
        [gap_length + _snap_body_top_corner_extrude, 0],
      ];
      middle_gap_side_profile =
        bottom_type == "None" ? middle_gap_side_profile_none
        : bottom_type == "Slant" ? middle_gap_side_profile_slant
        : middle_gap_side_profile_corner;
      middle_gap_bottom_to_side =
        bottom_type == "None" ? 0
        : bottom_type == "Slant" ? -_directional_slant_depth
        : _snap_body_bottom_corner_extrude;

      //middle gap main body
      back(_snap_body_corner_inner_diagonal - gap_length - _spring_thickness) zrot(90) xrot(90)
            offset_sweep(middle_gap_side_profile, height=_spring_gap + EPS, bottom=os_smooth(joint=_spring_gap / 2), top=os_smooth(joint=_spring_gap / 2), anchor="zcenter");
      //middle gap bottom chamfer
      up(_snap_thickness + EPS / 2)
        yrot(180) back(_snap_body_corner_inner_diagonal - gap_length - _spring_thickness + middle_gap_bottom_to_side)
            offset_sweep(gap_top_profile_rounded, height=_spring_face_chamfer + EPS, bottom=os_chamfer(width=-_spring_face_chamfer));
      //middle gap top chamfer
      down(EPS / 2)
        back(_snap_body_corner_inner_diagonal - gap_length - _spring_thickness + _snap_body_top_corner_extrude)
          offset_sweep(gap_top_profile_rounded, height=_spring_face_chamfer + EPS, bottom=os_chamfer(width=-_spring_face_chamfer));
      down(EPS / 2)
        yflip_copy() right(_spring_thickness + _spring_gap) back(gap_length + _threads_negative_diameter / 2 + _spring_to_center_thickness) zrot(180)
                offset_sweep(gap_top_profile_rounded, height=_snap_thickness + EPS, bottom=os_chamfer(width=-_spring_face_chamfer), top=os_chamfer(width=-_spring_face_chamfer));
    }
  }
}

module base_snap(snapbody_cfg = [], disable_features = [], snapcorner_cfg = [], snapnub_cfg = [], snapnotch_cfg = [], snapcut_cfg = [], text_cfg = [], anchor = BOTTOM, spin = 0, orient = UP) {
  _body_cfg = struct_merge(snap_body_cfg(), snapbody_cfg);
  _snap_width = struct_val(_body_cfg, "snap_width");
  _snap_height = struct_val(_body_cfg, "snap_height");
  _snap_thickness = struct_val(_body_cfg, "snap_thickness");
  _snap_body_shape = struct_val(_body_cfg, "snap_body_shape");
  attachable(anchor, spin, orient, size=[_snap_width, _snap_height, _snap_thickness]) {
    tag_scope() diff()
        cuboid([_snap_width, _snap_height, _snap_thickness], chamfer=OG_SNAP_CORNER_CHAMFER, edges="Z") {
          if (!in_list(list=disable_features, val="snap_corner"))
            snap_corner(snapbody_cfg=snapbody_cfg, snapcorner_cfg=snapcorner_cfg);
          if (!in_list(list=disable_features, val="snap_nub"))
            snap_nub(snapbody_cfg=snapbody_cfg, snapnub_cfg=snapnub_cfg);
          if (!in_list(list=disable_features, val="snap_cut"))
            snap_cut(snapbody_cfg=snapbody_cfg, snapcut_cfg=struct_set(snapcut_cfg, ["disable_front_side_cut", !in_list(list=disable_features, val="snap_uninstall_notch")]));
          if (!in_list(list=disable_features, val="snap_uninstall_notch"))
            attach(TOP, TOP, align=FRONT, shiftout=EPS, inside=true)
              snap_uninstall_notch(snapbody_cfg=snapbody_cfg, snapnotch_cfg=snapnotch_cfg);
          if (!in_list(list=disable_features, val="snap_text"))
            attach(BOTTOM, TOP, inside=true)
              snap_text(text_cfg=text_cfg, snapbody_cfg=snapbody_cfg);
        }
    children();
  }
}

module expanding_snap(
  snapbody_cfg = [],
  snapcorner_cfg = [],
  snapnub_cfg = [],
  snapcut_cfg = [],
  snapnotch_cfg = [],
  text_cfg = [],
  spring_cfg = [],
  expand_cfg = [],
  threads_cfg = [],
  add_expand_distance_text = false,
  center_position_offset = [0, 0]
) {
  _snap_thickness = struct_val(snapbody_cfg, "snap_thickness", OG_STANDARD_THICKNESS);
  _snap_width = struct_val(snapbody_cfg, "snap_width", OG_SNAP_WIDTH);
  expand_cut_cfg = struct_set(snapcut_cfg, ["disable_all_side_cut", true, "disable_all_bottom_cut", true]);
  _expand_cfg = struct_merge(snap_expand_cfg(), expand_cfg);
  _expand_distance = _snap_thickness >= OG_STANDARD_THICKNESS ? struct_val(_expand_cfg, "expand_distance_standard") : struct_val(_expand_cfg, "expand_distance_lite");
  _expand_split_angle = struct_val(_expand_cfg, "expand_split_angle");
  _texts = struct_val(text_cfg, "texts", []);
  _sizes = struct_val(text_cfg, "sizes", []);
  _fonts = struct_val(text_cfg, "fonts", []);
  _pos_offsets = struct_val(text_cfg, "pos_offsets", []);

  expand_text_cfg =
    add_expand_distance_text ? struct_set(
        text_cfg, [
          "texts",
          concat(_texts, [str(_expand_distance)]),
          "sizes",
          concat(_sizes, [3.2]),
          "fonts",
          concat(_fonts, [OG_SNAP_TEXT_FONT]),
          "pos_offsets",
          concat(_pos_offsets, [[0, -(_snap_width / 2 - 3.2)]]),
        ]
      )
    : text_cfg;
  tag_scope() diff() {
      up(_snap_thickness) yrot(180)
          base_snap(
            snapbody_cfg=snapbody_cfg, snapcorner_cfg=snapcorner_cfg, snapnub_cfg=snapnub_cfg,
            snapcut_cfg=expand_cut_cfg, snapnotch_cfg=snapnotch_cfg, text_cfg=expand_text_cfg
          );
      left(center_position_offset[0]) back(center_position_offset[1]) {
        down(EPS / 2) tag("remove") expanding_threads(
              threads_height=_snap_thickness,
              expand_cfg=expand_cfg, threads_cfg=threads_cfg
            );
        zrot(_expand_split_angle)
          tag("remove") expanding_spring(
              snapbody_cfg, spring_cfg, snapcorner_cfg, snapcut_cfg
            );
      }
    }
}
