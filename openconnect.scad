/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

generate_slot = true;
vertical_grids = 1;
horizontal_grids = 1;

generate_screw = "openConnect"; //["None", "openConnect", "openConnect (Folded)"]
//Blunt end helps prevent cross-threading and overtightening. Models with blunt ends have a decorative 'lock' symbol at the bottom.
threads_end_type = "Blunt"; //["Blunt", "Basic"]

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Staggered"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Slot entry direction can matter when installing in very tight space. Note when printing, the side with locking mechanism should be closer to print bed.
slot_direction_flip = false;
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_overlapped = false;

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN openConnect slot parameters
tile_size = 28;

ochead_bottom_height = 0.6;
ochead_top_height = 0.6;
ochead_middle_height = 1.4;
ochead_large_rect_width = 17; //0.1
ochead_large_rect_height = 11.2; //0.1

ochead_nub_to_top_distance = 7.2;
ochead_nub_depth = 0.6;
ochead_nub_tip_height = 1.2;
ochead_nub_inner_fillet = 0.6;
ochead_nub_outer_fillet = 0.8;

ochead_large_rect_chamfer = 4;
ochead_small_rect_width = ochead_large_rect_width - ochead_middle_height * 2;
ochead_small_rect_height = ochead_large_rect_height - ochead_middle_height;
ochead_small_rect_chamfer = ochead_large_rect_chamfer - ochead_middle_height + ang_adj_to_opp(45 / 2, ochead_middle_height);

ocslot_move_distance = 11; //0.1
ocslot_onramp_clearance = 0.8;
ocslot_bridge_offset = 0.4;
ocslot_side_clearance = 0.15;
ocslot_depth_clearance = 0.12;

ochead_bottom_profile = back(ochead_large_rect_width / 2, rect([ochead_large_rect_width, ochead_large_rect_height], chamfer=[ochead_large_rect_chamfer, ochead_large_rect_chamfer, 0, 0], anchor=BACK));
ochead_top_profile = back(ochead_small_rect_width / 2, rect([ochead_small_rect_width, ochead_small_rect_height], chamfer=[ochead_small_rect_chamfer, ochead_small_rect_chamfer, 0, 0], anchor=BACK));
ochead_total_height = ochead_top_height + ochead_middle_height + ochead_bottom_height;
ochead_middle_to_bottom = ochead_large_rect_height - ochead_large_rect_width / 2;

ocslot_bottom_height = ochead_bottom_height + ang_adj_to_opp(45 / 2, ocslot_side_clearance) + ocslot_depth_clearance;
ocslot_top_height = ochead_top_height - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_total_height = ocslot_top_height + ochead_middle_height + ocslot_bottom_height;
ocslot_nub_to_top_distance = ochead_nub_to_top_distance + ocslot_side_clearance * 1.5;

ocslot_small_rect_width = ochead_small_rect_width + ocslot_side_clearance * 2;
ocslot_small_rect_height = ochead_small_rect_height + ocslot_side_clearance * 2;
ocslot_small_rect_chamfer = ochead_small_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_large_rect_width = ochead_large_rect_width + ocslot_side_clearance * 2;
ocslot_large_rect_height = ochead_large_rect_height + ocslot_side_clearance * 2;
ocslot_large_rect_chamfer = ochead_large_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_middle_to_bottom = ocslot_large_rect_height - ocslot_large_rect_width / 2;
ocslot_to_grid_top_offset = (tile_size - 24.8) / 2;
ocslot_top_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width, ocslot_small_rect_height], chamfer=[ocslot_small_rect_chamfer, ocslot_small_rect_chamfer, 0, 0], anchor=BACK));
ocslot_bottom_profile = back(ocslot_large_rect_width / 2, rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));

ochead_side_profile = [
  [0, 0],
  [ochead_large_rect_width / 2, 0],
  [ochead_large_rect_width / 2, ochead_bottom_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height + ochead_top_height],
  [0, ochead_bottom_height + ochead_middle_height + ochead_top_height],
];
//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = "both", nub_flattop = true, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : ochead_nub_to_top_distance;
  nub_angle = nub_taperin ? adj_opp_to_ang(ochead_middle_height, ochead_middle_height - ochead_nub_depth) : 0;
  total_height = bottom_height + top_height + ochead_middle_height;

  attachable(anchor, spin, orient, size=[large_rect_width, large_rect_width, total_height]) {
    tag_scope() down(total_height / 2) difference() {
          union() {
            linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
            up(bottom_height - eps) hull() {
                up(ochead_middle_height) linear_extrude(h=eps) polygon(offset(top_profile, delta=size_offset));
                linear_extrude(h=eps) polygon(offset(bottom_profile, delta=size_offset));
              }
            if (top_height + excess_thickness > 0)
              up(bottom_height + ochead_middle_height - eps)
                linear_extrude(h=top_height + excess_thickness + eps) polygon(offset(top_profile, delta=size_offset));
          }
          back(large_rect_width / 2 - nub_to_top_distance) {
            if (add_nubs == "left" || add_nubs == "both")
              left(large_rect_width / 2 + size_offset - ochead_nub_depth + eps) zrot(-90) {
                  linear_extrude(bottom_height) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                  up(bottom_height) linear_extrude(1 / cos(nub_angle) * ochead_middle_height, v=[0, tan(nub_angle), 1]) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                }
            if (add_nubs == "right" || add_nubs == "both")
              right(large_rect_width / 2 + size_offset - ochead_nub_depth + eps) zrot(90) {
                  linear_extrude(bottom_height) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                  up(bottom_height) linear_extrude(1 / cos(nub_angle) * ochead_middle_height, v=[0, tan(nub_angle), 1]) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
                }
          }
        }
    children();
  }
}
module openconnect_slot(add_nubs = "left", direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_width, ocslot_total_height]) {
    tag_scope() up(ocslot_total_height / 2) yrot(180) union() {
            if (direction_flip)
              xflip() ocslot_body(excess_thickness);
            else
              ocslot_body(excess_thickness);
          }
    children();
  }
  module ocslot_body(excess_thickness = 0) {
    ocslot_side_profile = [
      [0, 0],
      [ocslot_large_rect_width / 2, 0],
      [ocslot_large_rect_width / 2, ocslot_bottom_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness],
      [0, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness],
    ];
    ocslot_bridge_offset_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width / 2 + ocslot_bridge_offset, ocslot_small_rect_height + ocslot_move_distance + ocslot_onramp_clearance], chamfer=[ocslot_small_rect_chamfer + ocslot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(head_type="slot", add_nubs=add_nubs, excess_thickness=excess_thickness);
      xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_profile);
      up(ocslot_bottom_height) linear_extrude(ocslot_top_height + ochead_middle_height) polygon(ocslot_bridge_offset_profile);
      fwd(ocslot_move_distance) {
        linear_extrude(ocslot_bottom_height) onramp_2d();
        up(ocslot_bottom_height)
          linear_extrude(ochead_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(ochead_middle_height) up(ocslot_bottom_height + ochead_middle_height)
            linear_extrude(ocslot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(ocslot_small_rect_chamfer) cuboid([ocslot_small_rect_width, ocslot_small_rect_height, ocslot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=ocslot_onramp_clearance)
        left(ocslot_onramp_clearance + ochead_middle_height) back(ocslot_large_rect_width / 2) {
            rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
module openconnect_slot_grid(h_grid = 1, v_grid = 1, grid_size = 28, lock_distribution = "None", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[h_grid * grid_size, v_grid * grid_size, ocslot_total_height]) {
    tag_scope() hide_this() cuboid([h_grid * grid_size, v_grid * grid_size, ocslot_total_height]) {
          back(ocslot_to_grid_top_offset) {
            if (lock_distribution == "All" || lock_distribution == "Staggered" || lock_distribution == "None")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? "left" : "", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Corners" || lock_distribution == "Top Corners") {
              if (lock_distribution == "Corners")
                grid_copies([grid_size * max(1, h_grid - 1), grid_size * max(1, v_grid - 1)], [min(h_grid, 2), min(v_grid, 2)])
                  attach(TOP, BOTTOM, inside=true)
                    openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
              else {
                back(grid_size * (v_grid - 1) / 2)
                  line_copies(spacing=grid_size * max(1, h_grid - 1), n=min(2, h_grid))
                    attach(TOP, BOTTOM, inside=true)
                      openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
              }
              omit_edge_rows =
                lock_distribution == "Corners" ? [0, v_grid - 1]
                : lock_distribution == "Top Corners" ? [0] : [];
              for (i = [0:1:v_grid - 1]) {
                back(grid_size * (v_grid - 1) / 2) fwd(grid_size * i) {
                    if (in_list(i, omit_edge_rows)) {
                      if (h_grid > 2)
                        line_copies(spacing=grid_size, n=h_grid - 2)
                          attach(TOP, BOTTOM, inside=true)
                            openconnect_slot(add_nubs="", direction_flip=direction_flip, excess_thickness=excess_thickness);
                    }
                    else
                      line_copies(spacing=grid_size, n=h_grid)
                        attach(TOP, BOTTOM, inside=true)
                          openconnect_slot(add_nubs="", direction_flip=direction_flip, excess_thickness=excess_thickness);
                  }
              }
            }
          }
        }
    children();
  }
}
//END openConnect slot modules

//BEGIN openConnect connectors
text_depth = 0.4;
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
fold_gap_width = 0.4;
fold_gap_height = 0.2;
connector_coin_slot_height = 2.6;
connector_coin_slot_width = 13;
connector_coin_slot_thickness = 2.4;
connector_coin_slot_radius = connector_coin_slot_height / 2 + connector_coin_slot_width ^ 2 / (8 * connector_coin_slot_height);

// /* [Threads Settings] */
threads_diameter = 16;
threads_clearance = 0.5;
threads_compatiblity_angle = 53.5;
threads_rotate_angle = 45;
threads_top_bevel = 0.5; //0.1
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1
threads_negative_diameter = threads_diameter + threads_clearance;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

threads_height = snap_thickness;
threads_bottom_bevel =
  snap_thickness == 6.8 ? threads_bottom_bevel_standard
  : snap_thickness == 4 ? threads_bottom_bevel_lite
  : 0;

add_threads_blunt_end_text = true;
threads_blunt_end_text = "🔓";
threads_blunt_end_text_font = "Noto Emoji"; // font
threads_pitch = 3;

final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

module openconnect_screw(threads_height = threads_height, folded = false) {
  fold_for_printing(body_thickness=snap_thickness + ochead_total_height, fold_position=ochead_middle_to_bottom + eps, fold_sliceoff=fold_gap_width / 2, condition=folded) {
    up(threads_height + ochead_total_height) xrot(180) zrot(180)
          difference() {
            union() {
              up(ochead_total_height - eps)
                zrot(threads_compatiblity_angle) {
                  if (threads_end_type == "Blunt")
                    blunt_threaded_rod(diameter=threads_diameter, rod_height=threads_height, top_bevel=0, top_cutoff=true);
                  else
                    generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
                }
              intersection() {
                //cut off part of connector head that may cause overhang
                if (!folded)
                  up(ochead_total_height - eps) right(0.32) back(0.45) cyl(d2=threads_diameter - 0.4, d1=threads_diameter - 0.4 + ochead_total_height * 2, h=ochead_total_height, anchor=TOP);
                openconnect_head(head_type="head", add_nubs="both");
              }
            }
            up(ochead_total_height) back(folded ? 1 : 0) {
                if (add_threads_blunt_end_text && threads_end_type == "Blunt")
                  up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
                if (final_add_thickness_text)
                  up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_end_text && threads_end_type == "Blunt" ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
              }
            up(connector_coin_slot_height) zrot(0) xrot(90) cyl(r=connector_coin_slot_radius, h=connector_coin_slot_thickness, $fn=128, anchor=BACK);
          }
  }
}

module blunt_threaded_rod(diameter = threads_diameter, rod_height = snap_thickness, top_bevel = 0, bottom_bevel = 0, top_cutoff = false, blunt_ang = 10, anchor = CENTER, spin = 0, orient = UP) {
  min_turns = 0.5;
  offset_height = min(rod_height - 1.5 - bottom_bevel, 0);
  turns = max(0, (rod_height - 1.5 - bottom_bevel) / 3) + min_turns;
  attachable(anchor, spin, orient, d=diameter, h=rod_height) {
    tag_scope() difference() {
        union() {
          cyl(d=diameter - 2 + eps, h=rod_height, anchor=BOTTOM, $fn=256);
          difference() {
            zrot(0.25 * 120) up(0.25)
                zrot(-(min_turns * 3) * 120) up(-(min_turns * 3))
                    zrot(offset_height * 120) up(offset_height)
                        thread_helix(d=diameter, turns=turns, pitch=threads_pitch, profile=threads_profile, anchor=BOTTOM, internal=false, lead_in_ang2=blunt_ang, $fn=256);
            up(rod_height + (diameter + 2) / 2) cube(diameter + 2, center=true);
          }
        }
        if (top_cutoff || top_bevel > 0)
          down((diameter + 2) / 2) cube(diameter + 2, center=true);
        if (top_bevel > 0)
          rotate_extrude() left(diameter / 2 - top_bevel / 2 + eps) right_triangle([top_bevel + eps, top_bevel + eps], anchor=BOTTOM);
        if (bottom_bevel > 0)
          up(rod_height) rotate_extrude() right(diameter / 2 - bottom_bevel + eps) right_triangle([bottom_bevel + eps, bottom_bevel + eps], anchor=BOTTOM, spin=180);
      }
    children();
  }
}

module fold_for_printing(body_thickness, fold_position = 0, fold_gap_width = fold_gap_width, fold_gap_height = fold_gap_height, fold_sliceoff = 0, rmobj_size = 100, condition = true) {
  if (condition) {
    back(fold_position) yrot(180) {
        xrot(-90, cp=[0, -fold_position, 0])
          difference() {
            children();
            fwd(fold_position) cuboid([rmobj_size, rmobj_size, rmobj_size], anchor=BACK);
          }
        fwd(fold_gap_width - eps) up(fold_sliceoff)
            xrot(90, cp=[0, -(fold_position), 0])
              difference() {
                children();
                fwd(fold_position + fold_sliceoff)
                  cuboid([rmobj_size, rmobj_size, rmobj_size], anchor=FRONT);
              }

        fwd(fold_gap_width) xrot(-90, cp=[0, -fold_position, 0])
            linear_extrude(fold_gap_width + eps * 2) difference() {
                projection(cut=true)
                  down(0.01)
                    children();
                fwd(fold_position - fold_gap_height) rect([rmobj_size, rmobj_size], anchor=FRONT);
                fwd(fold_position) rect([rmobj_size, rmobj_size], anchor=BACK);
              }
      }
  }
  else
    children();
}
//END openConnect connectors

half_of_anchor =
  view_cross_section == "Right" ? RIGHT
  : view_cross_section == "Back" ? BACK
  : view_cross_section == "Diagonal" ? RIGHT + BACK
  : 0;
if (half_of_anchor != 0)
  half_of(half_of_anchor) main_generate();
else
  main_generate();
module main_generate() {
  if (generate_screw == "openConnect" || generate_screw == "openConnect (Folded)")
    fwd(0) back(view_overlapped || !generate_slot ? 0 : 28 * vertical_grids + 10) up(view_overlapped ? snap_thickness + ochead_total_height : 0) yrot(view_overlapped ? 180 : 0)
            openconnect_screw(folded=generate_screw == "openConnect (Folded)");
  if (generate_slot) {
    down(0.84) fwd(15.6)
        diff() cuboid([tile_size * horizontal_grids, tile_size * vertical_grids, ocslot_total_height + 0.84], anchor=BOTTOM + FRONT) {
            attach(TOP, TOP, inside=true)
              tag("remove") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
          }
  }
}
