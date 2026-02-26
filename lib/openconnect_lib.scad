/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/
include <BOSL2/std.scad>
include <opengrid_base.scad>
use <opengrid_threads_lib.scad>

function ochead_cfg(
  bottom_height = OCHEAD_BOTTOM_HEIGHT,
  top_height = OCHEAD_TOP_HEIGHT,
  middle_height = OCHEAD_MIDDLE_HEIGHT,
  large_rect_width = OCHEAD_LARGE_RECT_WIDTH,
  large_rect_height = OCHEAD_LARGE_RECT_HEIGHT,
  large_rect_chamfer = OCHEAD_LARGE_RECT_CHAMFER,
  nub_to_top_distance = OCHEAD_NUB_TO_TOP_DISTANCE,
  nub_depth = OCHEAD_NUB_DEPTH,
  nub_tip_height = OCHEAD_NUB_TIP_HEIGHT,
  nub_fillet = OCHEAD_NUB_FILLET,
  back_pos_offset = OCHEAD_BACK_POS_OFFSET
) =
  let (
    small_rect_width = large_rect_width - middle_height * 2,
    small_rect_height = large_rect_height - middle_height,
    small_rect_chamfer = large_rect_chamfer - middle_height + ang_adj_to_opp(45 / 2, middle_height),
    total_height = top_height + middle_height + bottom_height,
    middle_to_bottom = large_rect_height - large_rect_width / 2 - back_pos_offset,
    bottom_profile = back(large_rect_width / 2 + back_pos_offset, rect([large_rect_width, large_rect_height], chamfer=[large_rect_chamfer, large_rect_chamfer, 0, 0], anchor=BACK)),
    top_profile = back(small_rect_width / 2 + back_pos_offset, rect([small_rect_width, small_rect_height], chamfer=[small_rect_chamfer, small_rect_chamfer, 0, 0], anchor=BACK))
  ) struct_set(
    [], [
      "bottom_height",
      bottom_height,
      "top_height",
      top_height,
      "middle_height",
      middle_height,
      "large_rect_width",
      large_rect_width,
      "large_rect_height",
      large_rect_height,
      "large_rect_chamfer",
      large_rect_chamfer,
      "nub_to_top_distance",
      nub_to_top_distance,
      "nub_depth",
      nub_depth,
      "nub_tip_height",
      nub_tip_height,
      "nub_fillet",
      nub_fillet,
      "back_pos_offset",
      back_pos_offset,
      "small_rect_width",
      small_rect_width,
      "small_rect_height",
      small_rect_height,
      "small_rect_chamfer",
      small_rect_chamfer,
      "total_height",
      total_height,
      "middle_to_bottom",
      middle_to_bottom,
      "bottom_profile",
      bottom_profile,
      "top_profile",
      top_profile,
    ]
  );

function ocslot_cfg(
  edge_feature = "Both",
  edge_bridge_min_w = 0.8,
  edge_wall_min_w = 0.6,
  side_clearance = 0.10,
  depth_clearance = 0.10,
  footprint_wall = 2,
  vase_linewidth = 0.6,
  vase_overhang_angle = 45,
  head_cfg = ochead_cfg()
) =
  let (
    _head_cfg = struct_merge(ochead_cfg(), head_cfg),
    head_middle_height = struct_val(_head_cfg, "middle_height"),
    head_nub_to_top = struct_val(_head_cfg, "nub_to_top_distance"),
    head_large_rect_width = struct_val(_head_cfg, "large_rect_width"),
    head_large_rect_height = struct_val(_head_cfg, "large_rect_height"),
    head_large_rect_chamfer = struct_val(_head_cfg, "large_rect_chamfer"),
    head_small_rect_width = struct_val(_head_cfg, "small_rect_width"),
    head_small_rect_height = struct_val(_head_cfg, "small_rect_height"),
    head_small_rect_chamfer = struct_val(_head_cfg, "small_rect_chamfer"),
    head_back_pos_offset = struct_val(_head_cfg, "back_pos_offset"),
    bottom_height = struct_val(_head_cfg, "bottom_height") + ang_adj_to_opp(45 / 2, side_clearance) + depth_clearance,
    top_height = struct_val(_head_cfg, "top_height") - ang_adj_to_opp(45 / 2, side_clearance),
    total_height = top_height + head_middle_height + bottom_height,
    nub_to_top_distance = head_nub_to_top + side_clearance,
    small_rect_width = head_small_rect_width + side_clearance * 2,
    small_rect_height = head_small_rect_height + side_clearance * 2,
    small_rect_chamfer = head_small_rect_chamfer + side_clearance - ang_adj_to_opp(45 / 2, side_clearance),
    large_rect_width = head_large_rect_width + side_clearance * 2,
    large_rect_height = head_large_rect_height + side_clearance * 2,
    large_rect_chamfer = head_large_rect_chamfer + side_clearance - ang_adj_to_opp(45 / 2, side_clearance),
    middle_to_bottom = large_rect_height - large_rect_width / 2 - head_back_pos_offset,
    top_profile = back(
      small_rect_width / 2 + head_back_pos_offset,
      rect([small_rect_width, small_rect_height], chamfer=[small_rect_chamfer, small_rect_chamfer, 0, 0], anchor=BACK)
    ),
    bottom_profile = back(
      large_rect_width / 2 + head_back_pos_offset,
      rect([large_rect_width, large_rect_height], chamfer=[large_rect_chamfer, large_rect_chamfer, 0, 0], anchor=BACK)
    ),
    footprint = fwd(
      middle_to_bottom,
      rect(
        [
          large_rect_width + footprint_wall * 2,
          large_rect_width / 2 + middle_to_bottom + footprint_wall,
        ],
        chamfer=[
          large_rect_chamfer + footprint_wall - ang_adj_to_opp(45 / 2, footprint_wall),
          large_rect_chamfer + footprint_wall - ang_adj_to_opp(45 / 2, footprint_wall),
          0,
          0,
        ],
        anchor=BACK
      )
    ),
    top_bridge_offset = (edge_feature == "Both" || edge_feature == "Top") ? max(0, edge_bridge_min_w - top_height) : 0,
    side_bridge_offset = (edge_feature == "Both" || edge_feature == "Side") ? max(0, edge_bridge_min_w - top_height) : 0,
    side_cliff_offset = (edge_feature == "Both" || edge_feature == "Side") ? max(0, edge_wall_min_w - top_height) : 0,
    bridge_offset_profile = right(side_bridge_offset / 2 - side_cliff_offset / 2, back(small_rect_width / 2 + head_back_pos_offset + top_bridge_offset, rect([small_rect_width + side_bridge_offset + side_cliff_offset, small_rect_height + OCSLOT_MOVE_DISTANCE + OCSLOT_ONRAMP_CLEARANCE + top_bridge_offset], chamfer=[small_rect_chamfer + top_bridge_offset + side_bridge_offset, small_rect_chamfer + top_bridge_offset + side_cliff_offset, 0, 0], anchor=BACK))),
    vase_wall_thickness = vase_linewidth * 2,
    vase_bottom_height = bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness),
    vase_top_height = top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness),
    vase_sweep_profile_base = [
      [0, 0],
      [0, vase_bottom_height],
      [min(head_middle_height, total_height - vase_bottom_height), total_height],
      [head_middle_height + vase_wall_thickness, total_height],
      [head_middle_height + vase_wall_thickness, bottom_height + head_middle_height],
      [vase_wall_thickness, bottom_height],
      [vase_wall_thickness, 0],
    ],
    vase_sweep_profile = total_height - vase_bottom_height > head_middle_height ? list_insert(vase_sweep_profile_base, 2, [head_middle_height, vase_bottom_height + head_middle_height]) : vase_sweep_profile_base
  ) struct_set(
    [], [
      "edge_feature",
      edge_feature,
      "edge_bridge_min_w",
      edge_bridge_min_w,
      "edge_wall_min_w",
      edge_wall_min_w,
      "side_clearance",
      side_clearance,
      "depth_clearance",
      depth_clearance,
      "footprint_wall",
      footprint_wall,
      "bottom_height",
      bottom_height,
      "top_height",
      top_height,
      "total_height",
      total_height,
      "nub_to_top_distance",
      nub_to_top_distance,
      "small_rect_width",
      small_rect_width,
      "small_rect_height",
      small_rect_height,
      "small_rect_chamfer",
      small_rect_chamfer,
      "large_rect_width",
      large_rect_width,
      "large_rect_height",
      large_rect_height,
      "large_rect_chamfer",
      large_rect_chamfer,
      "middle_to_bottom",
      middle_to_bottom,
      "top_profile",
      top_profile,
      "bottom_profile",
      bottom_profile,
      "footprint",
      footprint,
      "top_bridge_offset",
      top_bridge_offset,
      "side_bridge_offset",
      side_bridge_offset,
      "side_cliff_offset",
      side_cliff_offset,
      "bridge_offset_profile",
      bridge_offset_profile,
      "vase_linewidth",
      vase_linewidth,
      "vase_wall_thickness",
      vase_wall_thickness,
      "vase_bottom_height",
      vase_bottom_height,
      "vase_top_height",
      vase_top_height,
      "vase_sweep_profile",
      vase_sweep_profile,
      "vase_overhang_angle",
      vase_overhang_angle,
      "head_cfg",
      _head_cfg,
    ]
  );

function connector_slot_cfg(
  coin_slot_height = 2.6,
  coin_slot_width = 13,
  coin_slot_thickness = 2.4,
  flat_slot_height = 4.4,
  flat_slot_width = 6.5,
  flat_slot_height_offset = 0.7,
  flat_slot_start_thickness = 1.8,
  flat_slot_end_thickness = 1.2
) =
  let (
    coin_slot_radius = coin_slot_height / 2 + coin_slot_width ^ 2 / (8 * coin_slot_height)
  ) struct_set(
    [], [
      "coin_slot_height",
      coin_slot_height,
      "coin_slot_width",
      coin_slot_width,
      "coin_slot_thickness",
      coin_slot_thickness,
      "coin_slot_radius",
      coin_slot_radius,
      "flat_slot_height",
      flat_slot_height,
      "flat_slot_width",
      flat_slot_width,
      "flat_slot_height_offset",
      flat_slot_height_offset,
      "flat_slot_start_thickness",
      flat_slot_start_thickness,
      "flat_slot_end_thickness",
      flat_slot_end_thickness,
    ]
  );

module openconnect_head(head_type = "head", head_cfg = [], slot_cfg = [], add_nubs = "Both", nub_flattop = false, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  _head_cfg = struct_merge(ochead_cfg(), head_cfg);
  cfg = head_type == "head" ? _head_cfg : struct_merge(ocslot_cfg(), slot_cfg);

  _nub_depth = struct_val(_head_cfg, "nub_depth");
  _nub_tip_height = struct_val(_head_cfg, "nub_tip_height");
  _nub_fillet = struct_val(_head_cfg, "nub_fillet");
  _middle_height = struct_val(_head_cfg, "middle_height");
  _back_pos_offset = struct_val(_head_cfg, "back_pos_offset");

  bottom_profile = struct_val(cfg, "bottom_profile");
  top_profile = struct_val(cfg, "top_profile");
  bottom_height = struct_val(cfg, "bottom_height");
  top_height = struct_val(cfg, "top_height");
  large_rect_width = struct_val(cfg, "large_rect_width");
  large_rect_height = struct_val(cfg, "large_rect_height");
  nub_to_top_distance = struct_val(cfg, "nub_to_top_distance");

  total_height = bottom_height + top_height + _middle_height;

  // Slot heads may inset the right nub when the top bridge widens.
  nub_inset_right = struct_val(cfg, "side_bridge_offset", default=0);

  nub_angle_left = nub_taperin ? adj_opp_to_ang(_middle_height, _middle_height - _nub_depth) : 0;
  nub_angle_right =
    nub_taperin && _middle_height - _nub_depth - nub_inset_right > 0 ? adj_opp_to_ang(_middle_height - nub_inset_right, _middle_height - _nub_depth - nub_inset_right)
    : 0;

  attachable(anchor, spin, orient, size=[large_rect_width, large_rect_width, total_height]) {
    tag_scope() down(total_height / 2) difference() {
          union() {
            linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
            up(bottom_height - EPS) hull() {
                up(_middle_height) linear_extrude(h=EPS) polygon(offset(top_profile, delta=size_offset));
                linear_extrude(h=EPS) polygon(offset(bottom_profile, delta=size_offset));
              }
            if (top_height + excess_thickness > 0)
              up(bottom_height + _middle_height - EPS)
                linear_extrude(h=top_height + excess_thickness + EPS) polygon(offset(top_profile, delta=size_offset));
          }
          back(large_rect_width / 2 - nub_to_top_distance + _back_pos_offset) {
            if (add_nubs == "Left" || add_nubs == "Both")
              left(large_rect_width / 2 + size_offset + EPS)
                openconnect_lock(bottom_height=bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_height, nub_fillet=_nub_fillet, nub_angle=nub_angle_left, nub_flattop=nub_flattop);
            if (add_nubs == "Right" || add_nubs == "Both")
              right(large_rect_width / 2 + size_offset + EPS)
                xflip() openconnect_lock(bottom_height=bottom_height, middle_height=_nub_depth, nub_depth=_nub_depth, nub_tip_height=_nub_tip_height, nub_fillet=_nub_fillet, nub_angle=0, nub_flattop=nub_flattop);
          }
        }
    children();
  }
}
module openconnect_lock(bottom_height, middle_height, nub_depth = OCHEAD_NUB_DEPTH, nub_tip_height = OCHEAD_NUB_TIP_HEIGHT, nub_fillet = OCHEAD_NUB_FILLET, nub_angle = 0, nub_flattop = false) {
  right(nub_depth) zrot(-90) {
      linear_extrude(bottom_height)
        trapezoid(h=nub_depth, w2=nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[nub_fillet, nub_flattop ? 0 : nub_fillet, nub_flattop ? 0 : -nub_fillet, -nub_fillet], anchor=BACK, $fn=64);
      up(bottom_height)
        linear_extrude(v=[0, tan(nub_angle) * middle_height, middle_height])
          trapezoid(h=nub_depth, w2=nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[nub_fillet, nub_flattop ? 0 : nub_fillet, nub_flattop ? 0 : -nub_fillet, -nub_fillet], anchor=BACK, $fn=64);
    }
}
module openconnect_slot(slot_type = "slot", slot_cfg = [], add_nubs = "Left", slot_entryramp_flip = false, excess_thickness = EPS, anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = struct_merge(ocslot_cfg(), slot_cfg);

  ocslot_edge_wall_min_width = struct_val(cfg, "edge_wall_min_w");

  ocslot_bottom_height = struct_val(cfg, "bottom_height");
  ocslot_top_height = struct_val(cfg, "top_height");
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_nub_to_top_distance = struct_val(cfg, "nub_to_top_distance");
  ocslot_small_rect_width = struct_val(cfg, "small_rect_width");
  ocslot_small_rect_height = struct_val(cfg, "small_rect_height");
  ocslot_small_rect_chamfer = struct_val(cfg, "small_rect_chamfer");
  ocslot_large_rect_width = struct_val(cfg, "large_rect_width");
  ocslot_large_rect_height = struct_val(cfg, "large_rect_height");
  ocslot_large_rect_chamfer = struct_val(cfg, "large_rect_chamfer");
  ocslot_middle_to_bottom = struct_val(cfg, "middle_to_bottom");

  ocslot_top_profile = struct_val(cfg, "top_profile");
  ocslot_bottom_profile = struct_val(cfg, "bottom_profile");
  ocslot_footprint_wall = struct_val(cfg, "footprint_wall");
  ocslot_footprint = struct_val(cfg, "footprint");

  attachable(anchor, spin, orient, size=[OG_TILE_SIZE, OG_TILE_SIZE, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) if (slot_type == "slot")
        conditional_flip(axis="X", condition=slot_entryramp_flip) ocslot_body(excess_thickness);
      else if (slot_type == "vase")
        ocvase_body();
    children();
  }
  module ocvase_body(cfg = cfg) {
    ocvase_wall_thickness = struct_val(cfg, "vase_wall_thickness");
    ocvase_bottom_height = struct_val(cfg, "vase_bottom_height");
    ocvase_top_height = struct_val(cfg, "vase_top_height");
    ocvase_sweep_profile = struct_val(cfg, "vase_sweep_profile");
    ocvase_overhang_angle = struct_val(cfg, "vase_overhang_angle");
    straight_base_length = ocslot_large_rect_height - ocslot_large_rect_chamfer;
    straight_extra_length = tan(ocvase_overhang_angle) * ocslot_total_height;
    _slot_head_cfg = struct_val(cfg, "head_cfg", ochead_cfg());
    _middle_height = struct_val(_slot_head_cfg, "middle_height");
    nub_angle = adj_opp_to_ang(_middle_height, _middle_height - struct_val(_slot_head_cfg, "nub_depth"));
    sweep_corner_radius = ocvase_wall_thickness * sqrt(2);
    sweep_corner_offset = ang_adj_to_opp(45 / 2, sweep_corner_radius - ocvase_wall_thickness);
    vase_sweep_path = ["setdir", 90, "move", straight_extra_length + straight_base_length - sweep_corner_offset, "arcleft", sweep_corner_radius, 45, "move", ocslot_large_rect_chamfer * sqrt(2)];
    fwd(ocslot_middle_to_bottom + straight_extra_length)
      diff() {
        xflip_copy() right(ocvase_wall_thickness + ocslot_large_rect_width / 2) path_sweep(ocvase_sweep_profile, path=turtle(vase_sweep_path));
        if (add_nubs == "Left" || add_nubs == "Right" || add_nubs == "Both")
          conditional_flip(axis="X", copy=add_nubs == "Both", condition=add_nubs == "Right" || add_nubs == "Both")
            left(ocvase_wall_thickness + ocslot_large_rect_width / 2) back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) {
                _nub_depth = struct_val(_slot_head_cfg, "nub_depth");
                _nub_tip_h = struct_val(_slot_head_cfg, "nub_tip_height");
                _nub_fillet = struct_val(_slot_head_cfg, "nub_fillet");
                right(ocvase_wall_thickness)
                  openconnect_lock(bottom_height=ocslot_bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_h, nub_fillet=_nub_fillet, nub_angle=nub_angle);
                left(EPS)
                  tag("remove") openconnect_lock(bottom_height=ocvase_bottom_height, middle_height=_middle_height, nub_depth=_nub_depth, nub_tip_height=_nub_tip_h, nub_fillet=_nub_fillet, nub_angle=nub_angle);
              }
        xrot(90 - ocvase_overhang_angle) tag("remove") cuboid([OG_TILE_SIZE, 60, ocslot_total_height * 2], anchor=BOTTOM + FRONT);
      }
  }
  module ocslot_body(excess_thickness = 0) {
    _slot_head_cfg = struct_val(cfg, "head_cfg", ochead_cfg());
    _middle_height = struct_val(_slot_head_cfg, "middle_height");
    _back_pos_offset = struct_val(_slot_head_cfg, "back_pos_offset");
    _slot_move_distance = struct_val(_slot_head_cfg, "slot_move_distance", OCSLOT_MOVE_DISTANCE);
    _slot_onramp_clearance = struct_val(_slot_head_cfg, "slot_onramp_clearance", OCSLOT_ONRAMP_CLEARANCE);

    ocslot_bridge_offset_profile = struct_val(cfg, "bridge_offset_profile");
    ocslot_side_excess_profile = [
      [0, 0],
      [ocslot_large_rect_width / 2, 0],
      [ocslot_large_rect_width / 2, ocslot_bottom_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + _middle_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + _middle_height + ocslot_top_height + excess_thickness],
      [0, ocslot_bottom_height + _middle_height + ocslot_top_height + excess_thickness],
    ];
    difference() {
      union() {
        openconnect_head(head_type="slot", slot_cfg=cfg, add_nubs=add_nubs, excess_thickness=excess_thickness);
        back(_back_pos_offset) xrot(90) up(ocslot_middle_to_bottom) linear_extrude(_slot_move_distance + _slot_onramp_clearance + _back_pos_offset) xflip_copy() polygon(ocslot_side_excess_profile);
        up(ocslot_bottom_height) linear_extrude(ocslot_top_height + _middle_height + EPS) polygon(ocslot_bridge_offset_profile);
        fwd(_slot_move_distance) {
          linear_extrude(ocslot_bottom_height) onramp_2d();
          up(ocslot_bottom_height)
            linear_extrude(_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
          left(_middle_height) up(ocslot_bottom_height + _middle_height)
              linear_extrude(ocslot_top_height + excess_thickness) onramp_2d();
        }
        if (excess_thickness > 0)
          fwd(ocslot_small_rect_chamfer) cuboid([ocslot_small_rect_width, ocslot_small_rect_height, ocslot_total_height + excess_thickness], anchor=BOTTOM);
      }
      fwd(OG_TILE_SIZE / 2)
        cuboid([OG_TILE_SIZE, ocslot_edge_wall_min_width, ocslot_bottom_height + _middle_height + ocslot_top_height + excess_thickness + EPS], anchor=FRONT + BOTTOM);
    }
  }
  module onramp_2d() {
    _slot_head_cfg = struct_val(cfg, "head_cfg", ochead_cfg());
    _middle_height = struct_val(_slot_head_cfg, "middle_height");
    _back_pos_offset = struct_val(_slot_head_cfg, "back_pos_offset");
    _slot_onramp_clearance = struct_val(_slot_head_cfg, "slot_onramp_clearance", OCSLOT_ONRAMP_CLEARANCE);
    offset(delta=_slot_onramp_clearance)
      left(_slot_onramp_clearance + _middle_height) back(ocslot_large_rect_width / 2 + _back_pos_offset) {
          rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
          trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
        }
  }
}

module openconnect_slot_grid(slot_cfg = [], slot_type = "slot", horizontal_grids = 1, vertical_grids = 1, slot_slide_direction = "Up", slot_position = "All", slot_lock_distribution = "None", slot_lock_side = "Left", slot_entryramp_flip = false, excess_thickness = EPS, vase_overhang_angle = 45, except_slot_pos = [], chamfer = 0, rounding = 0, limit_region = [], anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = struct_merge(ocslot_cfg(), slot_cfg);
  // Slot dimensions needed for grid sizing/placement
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_footprint = struct_val(cfg, "footprint");
  attachable(anchor, spin, orient, size=[horizontal_grids * OG_TILE_SIZE, vertical_grids * OG_TILE_SIZE, ocslot_total_height]) {
    grid_slot_spin = slot_slide_direction == "Left" ? -90 : slot_slide_direction == "Right" ? 90 : slot_slide_direction == "Down" ? 180 : 0;
    grid_slot_flip = slot_slide_direction == "Right" || slot_slide_direction == "Down" ? !slot_entryramp_flip : slot_entryramp_flip;
    tag_scope() down(ocslot_total_height / 2) intersect() {
          cuboid([horizontal_grids * OG_TILE_SIZE, vertical_grids * OG_TILE_SIZE, ocslot_total_height + excess_thickness], edges="Z", chamfer=chamfer, rounding=rounding, anchor=BOTTOM) {
            for (i = [0:horizontal_grids - 1])
              for (j = [0:vertical_grids - 1]) {
                x_offset = -(horizontal_grids - i * 2 - 1) * OG_TILE_SIZE / 2;
                y_offset = (vertical_grids - j * 2 - 1) * OG_TILE_SIZE / 2;
                footprint_rotate = slot_slide_direction == "Left" ? 90 : slot_slide_direction == "Right" ? -90 : slot_slide_direction == "Down" ? 180 : 0;
                if (!is_region(limit_region) || is_pos_shape_in_region(cp=[x_offset, y_offset], footprint=zrot(footprint_rotate, ocslot_footprint), limit_region=limit_region))
                  if (is_grid_pos_described(i, j, horizontal_grids, vertical_grids, slot_position, except_slot_pos))
                    right(x_offset) back(y_offset)
                        attach(BOTTOM, BOTTOM, inside=true, spin=grid_slot_spin)
                          tag("intersect") openconnect_slot(slot_type=slot_type, slot_cfg=slot_cfg, add_nubs=is_grid_pos_described(i, j, horizontal_grids, vertical_grids, slot_lock_distribution) ? slot_lock_side : "", slot_entryramp_flip=grid_slot_flip, excess_thickness=excess_thickness);
              }
          }
        }
    children();
  }
}
//END openConnect slot modules

//BEGIN openConnect connectors
module openconnect_screw(threads_height = OG_STANDARD_THICKNESS, text_cfg = [], head_cfg = [], connectorslot_cfg = [], threads_cfg = [], folded = false) {
  _head_cfg = struct_merge(ochead_cfg(), head_cfg);
  _total_height = struct_val(_head_cfg, "total_height", OCHEAD_TOTAL_HEIGHT);
  _middle_to_bot = struct_val(_head_cfg, "middle_to_bottom", OCHEAD_MIDDLE_TO_BOTTOM);

  ocfold_gap_width = 0.4;
  ocfold_gap_height = 0.2;
  ocscrew_overhang_cyl_diameter = 15.6;

  ocscrew_coin_slot_height = struct_val(connectorslot_cfg, "coin_slot_height", 2.6);
  ocscrew_coin_slot_width = struct_val(connectorslot_cfg, "coin_slot_width", 13);
  ocscrew_coin_slot_thickness = struct_val(connectorslot_cfg, "coin_slot_thickness", 2.4);
  ocscrew_coin_slot_radius = struct_val(
    connectorslot_cfg, "coin_slot_radius",
    ocscrew_coin_slot_height / 2 + ocscrew_coin_slot_width ^ 2 / (8 * ocscrew_coin_slot_height)
  );
  ocscrew_flat_slot_height = struct_val(connectorslot_cfg, "flat_slot_height", 4.4);
  ocscrew_flat_slot_width = struct_val(connectorslot_cfg, "flat_slot_width", 6.5);
  ocscrew_flat_slot_height_offset = struct_val(connectorslot_cfg, "flat_slot_height_offset", 0.7);
  ocscrew_flat_slot_start_thickness = struct_val(connectorslot_cfg, "flat_slot_start_thickness", 1.8);
  ocscrew_flat_slot_end_thickness = struct_val(connectorslot_cfg, "flat_slot_end_thickness", 1.2);

  _screw_threads_cfg = struct_set(threads_cfg, ["threads_clearance", 0]);
  _shifted_offsets = [for (p = struct_val(text_cfg, "pos_offsets", [])) [p[0], p[1] + (folded ? 2 : 0)]];
  _text_cfg_shifted = struct_set(text_cfg, ["pos_offsets", _shifted_offsets]);

  tag_scope() conditional_fold(
      body_thickness=threads_height + _total_height,
      fold_position=_middle_to_bot + EPS,
      fold_gap_width=ocfold_gap_width, fold_gap_height=ocfold_gap_height,
      fold_sliceoff=ocfold_gap_width / 2, condition=folded
    )
      up(threads_height + _total_height) xrot(180) zrot(180)
            diff() {
              up(_total_height - EPS)
                snap_threads(threads_height=threads_height, threads_cfg=_screw_threads_cfg, text_cfg=_text_cfg_shifted);
              tag_intersect("") {
                tag(folded ? "keep" : "") openconnect_head(head_type="head", add_nubs="Both", head_cfg=_head_cfg);
                if (!folded)
                  tag("intersect") up(_total_height - EPS) right(0.32) back(0.45)
                          cyl(d2=ocscrew_overhang_cyl_diameter, d1=ocscrew_overhang_cyl_diameter + _total_height * 2, h=_total_height, anchor=TOP);
              }
              tag("remove") up(ocscrew_coin_slot_height) zrot(90) xrot(90)
                      cyl(r=ocscrew_coin_slot_radius, h=ocscrew_coin_slot_thickness, $fn=128, anchor=BACK) {
                        fwd(ocscrew_flat_slot_height_offset)
                          attach(BACK, BOTTOM)
                            prismoid(
                              size1=[ocscrew_flat_slot_width, ocscrew_flat_slot_start_thickness],
                              size2=[undef, ocscrew_flat_slot_end_thickness],
                              h=ocscrew_flat_slot_height - ocscrew_coin_slot_height + ocscrew_flat_slot_height_offset,
                              xang=[90, 90]
                            );
                        left(ocscrew_coin_slot_width / 2)
                          attach(BACK, BACK, inside=true)
                            cuboid([ocscrew_coin_slot_width, ocscrew_coin_slot_radius, ocscrew_coin_slot_thickness]);
                      }
            }
}
