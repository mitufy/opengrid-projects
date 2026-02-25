/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/
include <BOSL2/std.scad>
include <opengrid_variable.scad>
use <util_lib.scad>
use <opengrid_snap_threads_lib.scad>

function ocslot_cfg(
  edge_feature = "Both",
  edge_bridge_min_w = 0.8,
  edge_wall_min_w = 0.6,
  side_clearance = 0.10,
  depth_clearance = 0.10,
  footprint_wall = 2,
  vase_linewidth = 0.6,
  vase_overhang_angle = 45
) =
  let (
    bottom_height = OCHEAD_BOTTOM_HEIGHT + ang_adj_to_opp(45 / 2, side_clearance) + depth_clearance,
    top_height = OCHEAD_TOP_HEIGHT - ang_adj_to_opp(45 / 2, side_clearance),
    total_height = top_height + OCHEAD_MIDDLE_HEIGHT + bottom_height,
    nub_to_top = OCHEAD_NUB_TO_TOP_DISTANCE + side_clearance,
    small_rect_w = OCHEAD_SMALL_RECT_WIDTH + side_clearance * 2,
    small_rect_h = OCHEAD_SMALL_RECT_HEIGHT + side_clearance * 2,
    small_rect_chamfer = OCHEAD_SMALL_RECT_CHAMFER + side_clearance - ang_adj_to_opp(45 / 2, side_clearance),
    large_rect_w = OCHEAD_LARGE_RECT_WIDTH + side_clearance * 2,
    large_rect_h = OCHEAD_LARGE_RECT_HEIGHT + side_clearance * 2,
    large_rect_chamfer = OCHEAD_LARGE_RECT_CHAMFER + side_clearance - ang_adj_to_opp(45 / 2, side_clearance),
    middle_to_bottom = large_rect_h - large_rect_w / 2 - OCHEAD_BACK_POS_OFFSET,
    top_profile = back(
      small_rect_w / 2 + OCHEAD_BACK_POS_OFFSET,
      rect([small_rect_w, small_rect_h], chamfer=[small_rect_chamfer, small_rect_chamfer, 0, 0], anchor=BACK)
    ),
    bottom_profile = back(
      large_rect_w / 2 + OCHEAD_BACK_POS_OFFSET,
      rect([large_rect_w, large_rect_h], chamfer=[large_rect_chamfer, large_rect_chamfer, 0, 0], anchor=BACK)
    ),
    footprint = fwd(
      middle_to_bottom,
      rect(
        [
          large_rect_w + footprint_wall * 2,
          large_rect_w / 2 + middle_to_bottom + footprint_wall,
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
    bridge_offset_profile = right(side_bridge_offset / 2 - side_cliff_offset / 2, back(small_rect_w / 2 + OCHEAD_BACK_POS_OFFSET + top_bridge_offset, rect([small_rect_w + side_bridge_offset + side_cliff_offset, small_rect_h + OCSLOT_MOVE_DISTANCE + OCSLOT_ONRAMP_CLEARANCE + top_bridge_offset], chamfer=[small_rect_chamfer + top_bridge_offset + side_bridge_offset, small_rect_chamfer + top_bridge_offset + side_cliff_offset, 0, 0], anchor=BACK))),

    vase_wall_thickness = vase_linewidth * 2,
    vase_bottom_height = bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness),
    vase_top_height = top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness),
    vase_sweep_profile_base = [
      [0, 0],
      [0, vase_bottom_height],
      [min(OCHEAD_MIDDLE_HEIGHT, total_height - vase_bottom_height), total_height],
      [OCHEAD_MIDDLE_HEIGHT + vase_wall_thickness, total_height],
      [OCHEAD_MIDDLE_HEIGHT + vase_wall_thickness, bottom_height + OCHEAD_MIDDLE_HEIGHT],
      [vase_wall_thickness, bottom_height],
      [vase_wall_thickness, 0],
    ],
    vase_sweep_profile = total_height - vase_bottom_height > OCHEAD_MIDDLE_HEIGHT ? list_insert(vase_sweep_profile_base, 2, [OCHEAD_MIDDLE_HEIGHT, vase_bottom_height + OCHEAD_MIDDLE_HEIGHT]) : vase_sweep_profile_base
  ) struct_set(
    [], [
      // inputs
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

      // derived heights
      "bottom_height",
      bottom_height,
      "top_height",
      top_height,
      "total_height",
      total_height,
      "nub_to_top",
      nub_to_top,

      // derived profiles/dims
      "small_rect_w",
      small_rect_w,
      "small_rect_h",
      small_rect_h,
      "small_rect_chamfer",
      small_rect_chamfer,

      "large_rect_w",
      large_rect_w,
      "large_rect_h",
      large_rect_h,
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
    ]
  );

module openconnect_head(head_type = "head", slot_cfg = undef, add_nubs = "Both", nub_flattop = false, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = head_type == "head" ? undef : is_undef(slot_cfg) ? ocslot_cfg() : slot_cfg;

  bottom_profile = head_type == "slot" ? struct_val(cfg, "bottom_profile") : OCHEAD_BOTTOM_PROFILE;
  top_profile = head_type == "slot" ? struct_val(cfg, "top_profile") : OCHEAD_TOP_PROFILE;
  bottom_height = head_type == "slot" ? struct_val(cfg, "bottom_height") : OCHEAD_BOTTOM_HEIGHT;
  top_height = head_type == "slot" ? struct_val(cfg, "top_height") : OCHEAD_TOP_HEIGHT;
  large_rect_width = head_type == "slot" ? struct_val(cfg, "large_rect_w") : OCHEAD_LARGE_RECT_WIDTH;
  large_rect_height = head_type == "slot" ? struct_val(cfg, "large_rect_h") : OCHEAD_LARGE_RECT_HEIGHT;
  nub_to_top_distance = head_type == "slot" ? struct_val(cfg, "nub_to_top") : OCHEAD_NUB_TO_TOP_DISTANCE;

  total_height = bottom_height + top_height + OCHEAD_MIDDLE_HEIGHT;

  // Slot heads may inset the right nub when the top bridge widens.
  nub_inset_right = head_type == "slot" ? struct_val(cfg, "side_bridge_offset", 0) : 0;

  nub_angle_left = nub_taperin ? adj_opp_to_ang(OCHEAD_MIDDLE_HEIGHT, OCHEAD_MIDDLE_HEIGHT - OCHEAD_NUB_DEPTH) : 0;
  nub_angle_right =
    nub_taperin && OCHEAD_MIDDLE_HEIGHT - OCHEAD_NUB_DEPTH - nub_inset_right > 0 ? adj_opp_to_ang(OCHEAD_MIDDLE_HEIGHT - nub_inset_right, OCHEAD_MIDDLE_HEIGHT - OCHEAD_NUB_DEPTH - nub_inset_right)
    : 0;

  attachable(anchor, spin, orient, size=[large_rect_width, large_rect_width, total_height]) {
    tag_scope() down(total_height / 2) difference() {
          union() {
            linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
            up(bottom_height - EPS) hull() {
                up(OCHEAD_MIDDLE_HEIGHT) linear_extrude(h=EPS) polygon(offset(top_profile, delta=size_offset));
                linear_extrude(h=EPS) polygon(offset(bottom_profile, delta=size_offset));
              }
            if (top_height + excess_thickness > 0)
              up(bottom_height + OCHEAD_MIDDLE_HEIGHT - EPS)
                linear_extrude(h=top_height + excess_thickness + EPS) polygon(offset(top_profile, delta=size_offset));
          }
          back(large_rect_width / 2 - nub_to_top_distance + OCHEAD_BACK_POS_OFFSET) {
            if (add_nubs == "Left" || add_nubs == "Both")
              left(large_rect_width / 2 + size_offset + EPS)
                openconnect_lock(bottom_height=bottom_height, middle_height=OCHEAD_MIDDLE_HEIGHT, nub_angle=nub_angle_left, nub_flattop=nub_flattop);
            if (add_nubs == "Right" || add_nubs == "Both")
              right(large_rect_width / 2 + size_offset + EPS)
                xflip() openconnect_lock(bottom_height=bottom_height, middle_height=OCHEAD_NUB_DEPTH, nub_angle=0, nub_flattop=nub_flattop);
          }
        }
    children();
  }
}
module openconnect_lock(bottom_height, middle_height, nub_angle = 0, nub_flattop = false) {
  right(OCHEAD_NUB_DEPTH) zrot(-90) {
      linear_extrude(bottom_height)
        trapezoid(h=OCHEAD_NUB_DEPTH, w2=OCHEAD_NUB_TIP_HEIGHT, ang=[nub_flattop ? 90 : 45, 45], rounding=[OCHEAD_NUB_FILLET, nub_flattop ? 0 : OCHEAD_NUB_FILLET, nub_flattop ? 0 : -OCHEAD_NUB_FILLET, -OCHEAD_NUB_FILLET], anchor=BACK, $fn=64);
      up(bottom_height)
        linear_extrude(v=[0, tan(nub_angle) * middle_height, middle_height])
          trapezoid(h=OCHEAD_NUB_DEPTH, w2=OCHEAD_NUB_TIP_HEIGHT, ang=[nub_flattop ? 90 : 45, 45], rounding=[OCHEAD_NUB_FILLET, nub_flattop ? 0 : OCHEAD_NUB_FILLET, nub_flattop ? 0 : -OCHEAD_NUB_FILLET, -OCHEAD_NUB_FILLET], anchor=BACK, $fn=64);
    }
}
module openconnect_slot(slot_type = "slot", slot_cfg = undef, add_nubs = "Left", slot_entryramp_flip = false, excess_thickness = EPS, anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = is_undef(slot_cfg) ? ocslot_cfg() : slot_cfg;

  ocslot_edge_wall_min_width = struct_val(cfg, "edge_wall_min_w");

  ocslot_bottom_height = struct_val(cfg, "bottom_height");
  ocslot_top_height = struct_val(cfg, "top_height");
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_nub_to_top_distance = struct_val(cfg, "nub_to_top");
  ocslot_small_rect_width = struct_val(cfg, "small_rect_w");
  ocslot_small_rect_height = struct_val(cfg, "small_rect_h");
  ocslot_small_rect_chamfer = struct_val(cfg, "small_rect_chamfer");
  ocslot_large_rect_width = struct_val(cfg, "large_rect_w");
  ocslot_large_rect_height = struct_val(cfg, "large_rect_h");
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
    nub_angle = adj_opp_to_ang(OCHEAD_MIDDLE_HEIGHT, OCHEAD_MIDDLE_HEIGHT - OCHEAD_NUB_DEPTH);
    sweep_corner_radius = ocvase_wall_thickness * sqrt(2);
    sweep_corner_offset = ang_adj_to_opp(45 / 2, sweep_corner_radius - ocvase_wall_thickness);
    vase_sweep_path = ["setdir", 90, "move", straight_extra_length + straight_base_length - sweep_corner_offset, "arcleft", sweep_corner_radius, 45, "move", ocslot_large_rect_chamfer * sqrt(2)];
    fwd(ocslot_middle_to_bottom + straight_extra_length)
      diff() {
        xflip_copy() right(ocvase_wall_thickness + ocslot_large_rect_width / 2) path_sweep(ocvase_sweep_profile, path=turtle(vase_sweep_path));
        if (add_nubs == "Left" || add_nubs == "Right" || add_nubs == "Both")
          conditional_flip(axis="X", copy=add_nubs == "Both", condition=add_nubs == "Right" || add_nubs == "Both")
            left(ocvase_wall_thickness + ocslot_large_rect_width / 2) back(ocslot_large_rect_height + straight_extra_length - ocslot_nub_to_top_distance) {
                right(ocvase_wall_thickness)
                  openconnect_lock(bottom_height=ocslot_bottom_height, middle_height=OCHEAD_MIDDLE_HEIGHT, nub_angle=nub_angle);
                left(EPS)
                  tag("remove") openconnect_lock(bottom_height=ocvase_bottom_height, middle_height=OCHEAD_MIDDLE_HEIGHT, nub_angle=nub_angle);
              }
        xrot(90 - ocvase_overhang_angle) tag("remove") cuboid([OG_TILE_SIZE, 60, ocslot_total_height * 2], anchor=BOTTOM + FRONT);
      }
  }
  module ocslot_body(excess_thickness = 0) {
    ocslot_bridge_offset_profile = struct_val(cfg, "bridge_offset_profile");
    ocslot_side_excess_profile = [
      [0, 0],
      [ocslot_large_rect_width / 2, 0],
      [ocslot_large_rect_width / 2, ocslot_bottom_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + OCHEAD_MIDDLE_HEIGHT],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + OCHEAD_MIDDLE_HEIGHT + ocslot_top_height + excess_thickness],
      [0, ocslot_bottom_height + OCHEAD_MIDDLE_HEIGHT + ocslot_top_height + excess_thickness],
    ];
    difference() {
      union() {
        openconnect_head(head_type="slot", slot_cfg=cfg, add_nubs=add_nubs, excess_thickness=excess_thickness);
        back(OCHEAD_BACK_POS_OFFSET) xrot(90) up(ocslot_middle_to_bottom) linear_extrude(OCSLOT_MOVE_DISTANCE + OCSLOT_ONRAMP_CLEARANCE + OCHEAD_BACK_POS_OFFSET) xflip_copy() polygon(ocslot_side_excess_profile);
        up(ocslot_bottom_height) linear_extrude(ocslot_top_height + OCHEAD_MIDDLE_HEIGHT + EPS) polygon(ocslot_bridge_offset_profile);
        fwd(OCSLOT_MOVE_DISTANCE) {
          linear_extrude(ocslot_bottom_height) onramp_2d();
          up(ocslot_bottom_height)
            linear_extrude(OCHEAD_MIDDLE_HEIGHT * sqrt(2), v=[-1, 0, 1]) onramp_2d();
          left(OCHEAD_MIDDLE_HEIGHT) up(ocslot_bottom_height + OCHEAD_MIDDLE_HEIGHT)
              linear_extrude(ocslot_top_height + excess_thickness) onramp_2d();
        }
        if (excess_thickness > 0)
          fwd(ocslot_small_rect_chamfer) cuboid([ocslot_small_rect_width, ocslot_small_rect_height, ocslot_total_height + excess_thickness], anchor=BOTTOM);
      }
      fwd(OG_TILE_SIZE / 2)
        cuboid([OG_TILE_SIZE, ocslot_edge_wall_min_width, ocslot_bottom_height + OCHEAD_MIDDLE_HEIGHT + ocslot_top_height + excess_thickness + EPS], anchor=FRONT + BOTTOM);
    }
  }
  module onramp_2d() {
    offset(delta=OCSLOT_ONRAMP_CLEARANCE)
      left(OCSLOT_ONRAMP_CLEARANCE + OCHEAD_MIDDLE_HEIGHT) back(ocslot_large_rect_width / 2 + OCHEAD_BACK_POS_OFFSET) {
          rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
          trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
        }
  }
}

module openconnect_slot_grid(slot_cfg = undef, slot_type = "slot", horizontal_grids = 1, vertical_grids = 1, slot_slide_direction = "Up", slot_position = "All", slot_lock_distribution = "None", slot_lock_side = "Left", slot_entryramp_flip = false, excess_thickness = EPS, vase_overhang_angle = 45, except_slot_pos = [], chamfer = 0, rounding = 0, limit_region = [], anchor = BOTTOM, spin = 0, orient = UP) {
  cfg = is_undef(slot_cfg) ? ocslot_cfg() : slot_cfg;
  // Slot dimensions needed for grid sizing/placement
  ocslot_total_height = struct_val(cfg, "total_height");
  ocslot_footprint = struct_val(cfg, "footprint");
  tag_scope() attachable(anchor, spin, orient, size=[horizontal_grids * OG_TILE_SIZE, vertical_grids * OG_TILE_SIZE, ocslot_total_height]) {
      grid_slot_spin = slot_slide_direction == "Left" ? -90 : slot_slide_direction == "Right" ? 90 : slot_slide_direction == "Down" ? 180 : 0;
      grid_slot_flip = slot_slide_direction == "Right" || slot_slide_direction == "Down" ? !slot_entryramp_flip : slot_entryramp_flip;
      down(ocslot_total_height / 2) intersect() {
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
module openconnect_screw(snap_thickness = OG_STANDARD_THICKNESS, threads_type = "Blunt", text_depth = 0.4, thickness_text_mode = "Uncommon", text_pos_offset = [0, 0], folded = false) {
  ocfold_gap_width = 0.4;
  ocfold_gap_height = 0.2;
  ocscrew_overhang_cyl_diameter = 15.6;
  ocscrew_coin_slot_height = 2.6;
  ocscrew_coin_slot_width = 13;
  ocscrew_coin_slot_thickness = 2.4;
  ocscrew_coin_slot_radius = ocscrew_coin_slot_height / 2 + ocscrew_coin_slot_width ^ 2 / (8 * ocscrew_coin_slot_height);
  ocscrew_flat_slot_height = 4.4;
  ocscrew_flat_slot_width = 6.5;
  ocscrew_flat_slot_height_offset = 0.7;
  ocscrew_flat_slot_start_thickness = 1.8;
  ocscrew_flat_slot_end_thickness = 1.2;
  conditional_fold(body_thickness=snap_thickness + OCHEAD_TOTAL_HEIGHT, fold_position=OCHEAD_MIDDLE_TO_BOTTOM + EPS, fold_gap_width=ocfold_gap_width, fold_gap_height=ocfold_gap_height, fold_sliceoff=ocfold_gap_width / 2, condition=folded) {
    up(snap_thickness + OCHEAD_TOTAL_HEIGHT) xrot(180) zrot(180)
          difference() {
            union() {
              up(OCHEAD_TOTAL_HEIGHT - EPS)
              right(_text_pos_offset[0]) back(_text_pos_offset[1]) 
                snap_threads(threads_type=threads_type, snap_thickness=snap_thickness, text_depth=text_depth, thickness_text_mode=thickness_text_mode, text_pos_offset=[text_pos_offset[0], text_pos_offset[1] + (folded ? 2 : 0)]);
              intersection() {
                //cut off the part of connector head that may cause overhang
                if (!folded)
                  up(OCHEAD_TOTAL_HEIGHT - EPS) right(0.32) back(0.45) cyl(d2=ocscrew_overhang_cyl_diameter, d1=ocscrew_overhang_cyl_diameter + OCHEAD_TOTAL_HEIGHT * 2, h=OCHEAD_TOTAL_HEIGHT, anchor=TOP);
                openconnect_head(head_type="head", add_nubs="Both");
              }
            }
            up(ocscrew_coin_slot_height) zrot(90) xrot(90)
                  cyl(r=ocscrew_coin_slot_radius, h=ocscrew_coin_slot_thickness, $fn=128, anchor=BACK) {
                    //flat head slot
                    fwd(ocscrew_flat_slot_height_offset)
                      attach(BACK, BOTTOM)
                        prismoid(size1=[ocscrew_flat_slot_width, ocscrew_flat_slot_start_thickness], size2=[undef, ocscrew_flat_slot_end_thickness], h=ocscrew_flat_slot_height - ocscrew_coin_slot_height + ocscrew_flat_slot_height_offset, xang=[90, 90]);
                    //cut off remaining coin slot part
                    left(ocscrew_coin_slot_width / 2) attach(BACK, BACK, inside=true)
                        cuboid([ocscrew_coin_slot_width, ocscrew_coin_slot_radius, ocscrew_coin_slot_thickness]);
                  }
          }
  }
}