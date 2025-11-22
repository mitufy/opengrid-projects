include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

vertical_grids = 1;
horizontal_grids = 1;

generate_openconnect_screw = true;
generate_slot = true;
openconnect_slot_direction_flip = false;
openconnect_slot_lock_distribution = "Staggered"; //["Staggered","All", "None"]
snap_version = "Standard"; //["Standard","Lite Strong", "Lite Basic"]

view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_overlapped = false;

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN openConnect slot parameters
tile_size = 28;

openconnect_head_bottom_height = 0.4;
openconnect_head_bottom_chamfer = 0;
openconnect_head_top_height = 0.6;
openconnect_head_middle_height = 1.6;
openconnect_head_large_rect_width = 17; //0.1
openconnect_head_large_rect_height = 11.2; //0.1

openconnect_head_nub_to_top_distance = 7.2;
openconnect_lock_nub_depth = 0.4;
openconnect_lock_nub_tip_height = 0.8;
openconnect_lock_nub_inner_fillet = 0.2;
openconnect_lock_nub_outer_fillet = 0.8;

openconnect_head_large_rect_chamfer = 4;
openconnect_head_small_rect_width = openconnect_head_large_rect_width - openconnect_head_middle_height * 2;
openconnect_head_small_rect_height = openconnect_head_large_rect_height - openconnect_head_middle_height;
openconnect_head_small_rect_chamfer = openconnect_head_large_rect_chamfer - openconnect_head_middle_height + ang_adj_to_opp(45 / 2, openconnect_head_middle_height);

openconnect_slot_move_distance = 11; //0.1
openconnect_slot_onramp_clearance = 0.8;
openconnect_slot_bridge_offset = 0.4;
openconnect_slot_side_clearance = 0.18;
openconnect_slot_depth_clearance = 0.12;

openconnect_head_bottom_profile = back(openconnect_head_large_rect_width / 2, rect([openconnect_head_large_rect_width, openconnect_head_large_rect_height], chamfer=[openconnect_head_large_rect_chamfer, openconnect_head_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_top_profile = back(openconnect_head_small_rect_width / 2, rect([openconnect_head_small_rect_width, openconnect_head_small_rect_height], chamfer=[openconnect_head_small_rect_chamfer, openconnect_head_small_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_total_height = openconnect_head_top_height + openconnect_head_middle_height + openconnect_head_bottom_height;
openconnect_head_middle_to_bottom = openconnect_head_large_rect_height - openconnect_head_large_rect_width / 2;

openconnect_slot_top_profile = offset(openconnect_head_top_profile, delta=openconnect_slot_side_clearance);
openconnect_slot_bottom_profile = offset(openconnect_head_bottom_profile, delta=openconnect_slot_side_clearance);
openconnect_slot_bottom_height = openconnect_head_bottom_height + ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance) + openconnect_slot_depth_clearance;
openconnect_slot_middle_height = openconnect_head_middle_height;
openconnect_slot_top_height = openconnect_head_top_height - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_total_height = openconnect_slot_top_height + openconnect_slot_middle_height + openconnect_slot_bottom_height;
openconnect_slot_nub_to_top_distance = openconnect_head_nub_to_top_distance + openconnect_slot_side_clearance;

openconnect_slot_small_rect_width = openconnect_head_small_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_height = openconnect_head_small_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_chamfer = openconnect_head_small_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_large_rect_width = openconnect_head_large_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_height = openconnect_head_large_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_chamfer = openconnect_head_large_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_middle_to_bottom = openconnect_slot_large_rect_height - openconnect_slot_large_rect_width / 2;
openconnect_slot_to_grid_top_offset = (tile_size - 24.8) / 2;

openconnect_head_side_profile = [
  [0, 0],
  [openconnect_head_large_rect_width / 2 - openconnect_head_bottom_chamfer, 0],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_chamfer],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_head_middle_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_head_middle_height + openconnect_head_top_height],
  [0, openconnect_head_bottom_height + openconnect_head_middle_height + openconnect_head_top_height],
];

//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(is_negative = false, add_nubss = 2, excess_thickness = 0) {
  bottom_profile = is_negative ? openconnect_slot_bottom_profile : openconnect_head_bottom_profile;
  top_profile = is_negative ? openconnect_slot_top_profile : openconnect_head_top_profile;

  bottom_height = is_negative ? openconnect_slot_bottom_height : openconnect_head_bottom_height;
  middle_height = is_negative ? openconnect_slot_middle_height : openconnect_head_middle_height;
  top_height = is_negative ? openconnect_slot_top_height : openconnect_head_top_height;
  large_rect_width = is_negative ? openconnect_slot_large_rect_width : openconnect_head_large_rect_width;
  large_rect_height = is_negative ? openconnect_slot_large_rect_height : openconnect_head_large_rect_height;
  nub_to_top_distance = is_negative ? openconnect_slot_nub_to_top_distance : openconnect_head_nub_to_top_distance;

  difference() {
    union() {
      linear_extrude(h=bottom_height) polygon(bottom_profile);
      up(bottom_height - eps) hull() {
          up(middle_height) linear_extrude(h=eps) polygon(top_profile);
          linear_extrude(h=eps) polygon(bottom_profile);
        }
      up(bottom_height + middle_height - eps)
        linear_extrude(h=top_height + excess_thickness + eps) polygon(top_profile);
    }
    back(large_rect_width / 2 - nub_to_top_distance)
      rot_copies([90, 0, 0], n=add_nubss)
        left(large_rect_width / 2 - openconnect_lock_nub_depth / 2 + eps) zrot(-90)
            linear_extrude(4) trapezoid(h=openconnect_lock_nub_depth, w2=openconnect_lock_nub_tip_height, ang=[45, 45], rounding=[openconnect_lock_nub_inner_fillet, openconnect_lock_nub_inner_fillet, -openconnect_lock_nub_outer_fillet, -openconnect_lock_nub_outer_fillet], $fn=64);
  }
}
module openconnect_slot(add_nubss = 1, direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[openconnect_slot_large_rect_width, openconnect_slot_large_rect_height, openconnect_slot_total_height]) {
    up(openconnect_slot_total_height / 2) yrot(180) union() {
          if (direction_flip)
            xflip() openconnect_slot_body(excess_thickness);
          else
            openconnect_slot_body(excess_thickness);
        }
    children();
  }
  module openconnect_slot_body(excess_thickness = 0) {
    openconnect_slot_side_profile = [
      [0, 0],
      [openconnect_slot_large_rect_width / 2, 0],
      [openconnect_slot_large_rect_width / 2, openconnect_slot_bottom_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_slot_middle_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_slot_middle_height + openconnect_slot_top_height + excess_thickness],
      [0, openconnect_slot_bottom_height + openconnect_slot_middle_height + openconnect_slot_top_height + excess_thickness],
    ];
    openconnect_slot_bridge_offset_profile = back(openconnect_slot_small_rect_width / 2, rect([openconnect_slot_small_rect_width / 2 + openconnect_slot_bridge_offset, openconnect_slot_small_rect_height + openconnect_slot_move_distance + openconnect_slot_onramp_clearance], chamfer=[openconnect_slot_small_rect_chamfer + openconnect_slot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(is_negative=true, add_nubss=add_nubss ? 1 : 0, excess_thickness=excess_thickness);
      xrot(90) linear_extrude(openconnect_slot_middle_to_bottom + openconnect_slot_move_distance + openconnect_slot_onramp_clearance) xflip_copy() polygon(openconnect_slot_side_profile);
      up(openconnect_slot_bottom_height) linear_extrude(openconnect_slot_top_height + openconnect_slot_middle_height) polygon(openconnect_slot_bridge_offset_profile);
      fwd(openconnect_slot_move_distance) {
        linear_extrude(openconnect_slot_bottom_height) onramp_2d();
        up(openconnect_slot_bottom_height)
          linear_extrude(openconnect_slot_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(openconnect_slot_middle_height) up(openconnect_slot_bottom_height + openconnect_slot_middle_height)
            linear_extrude(openconnect_slot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(openconnect_slot_small_rect_chamfer) cuboid([openconnect_slot_small_rect_width, openconnect_slot_small_rect_height, openconnect_slot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=openconnect_slot_onramp_clearance)
        left(openconnect_slot_onramp_clearance + openconnect_slot_middle_height) back(openconnect_slot_large_rect_width / 2) {
            rect([openconnect_slot_large_rect_width, openconnect_slot_large_rect_height], chamfer=[openconnect_slot_large_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=openconnect_slot_large_rect_width - openconnect_slot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
module openconnect_slot_grid(h_grid = 1, v_grid = 1, grid_size = 28, lock_distribution = "None", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[h_grid * grid_size, v_grid * grid_size, openconnect_slot_total_height]) {
    tag_scope() hide_this() cuboid([h_grid * grid_size, v_grid * grid_size, openconnect_slot_total_height]) {
          back(openconnect_slot_to_grid_top_offset) {
            grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
              attach(TOP, BOTTOM, inside=true)
                openconnect_slot(add_nubss=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? 1 : 0, direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubss=1, direction_flip=direction_flip, excess_thickness=excess_thickness);
          }
        }
    children();
  }
}
//END openConnect slot modules

//BEGIN openConnect connectors
text_depth = 0.4;
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
split_distance = 0.4;
split_layer_height = 0.2;
coin_slot_height = 3;
coin_slot_width = 14;
coin_slot_thickness = 2.4;
coin_slot_radius = coin_slot_height / 2 + coin_slot_width ^ 2 / (8 * coin_slot_height);

snap_thickness =
  snap_version == "Standard" ? 6.8
  : snap_version == "Lite Strong" ? 4
  : snap_version == "Lite Basic" ? 3.4
  : 0;

openconnect_slot_to_front_thickness = 1.68; //0.42

// /* [Threads Options] */
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
  snap_version == "Standard" ? threads_bottom_bevel_standard
  : snap_version == "Lite" ? threads_bottom_bevel_lite
  : 0;

add_threads_bluntend = true;
add_threads_bluntend_text = true;
threads_bluntend_text = "🔓";
threads_bluntend_text_font = "Noto Emoji"; // font

final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

module openconnect_screw(threads_height = threads_height, split = true) {
  up(split ? openconnect_head_middle_to_bottom : threads_height + openconnect_head_total_height) xrot(split ? 90 : 180) {
      difference() {
        union() {
          up(openconnect_head_total_height - eps)
            difference() {
              zrot(threads_compatiblity_angle) {
                if (add_threads_bluntend)
                  blunt_threaded_rod(diameter=threads_diameter, rod_height=threads_height, top_bevel=0, top_cutoff=true);
                else
                  generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
              }
              back(split ? 1 : 0) {
                if (add_threads_bluntend_text && add_threads_bluntend)
                  up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_bluntend_text, size=4, anchor=str("center", CENTER), font=threads_bluntend_text_font);
                if (final_add_thickness_text)
                  up(snap_thickness - text_depth + eps / 2) left(add_threads_bluntend_text && add_threads_bluntend ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
              }
            }
          openconnect_head(is_negative=false, add_nubss=2);
        }
        up(coin_slot_height) zrot(0) xrot(90) cyl(r=coin_slot_radius, h=coin_slot_thickness, $fn=128, anchor=BACK);
        if (split)
          fwd(openconnect_head_middle_to_bottom) cuboid([50, 50, 50], anchor=BACK);
      }
      if (split) {
        up(split_distance - eps) xrot(180, cp=[0, -openconnect_head_middle_to_bottom, snap_thickness + openconnect_head_total_height]) {
            up(openconnect_head_total_height)
              difference() {
                zrot(threads_compatiblity_angle) {
                  if (add_threads_bluntend)
                    blunt_threaded_rod(diameter=threads_diameter, rod_height=threads_height, top_bevel=0, top_cutoff=true);
                  else
                    generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
                }
                fwd(openconnect_head_middle_to_bottom) cuboid([50, 50, 50], anchor=FRONT);
              }
            up(snap_thickness + openconnect_head_total_height - eps * 2)
              intersection() {
                zcyl(d=threads_diameter - 2 - threads_bottom_bevel, h=split_distance + eps * 4, anchor=BOTTOM);
                fwd(openconnect_head_middle_to_bottom) cuboid([20, split_layer_height, split_distance + eps * 4], anchor=BOTTOM + BACK);
              }
          }
      }
    }
}
//END openConnect connector

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
  if (generate_openconnect_screw)
    fwd(0) back(view_overlapped ? 0 : 28 * vertical_grids + 10) up(openconnect_slot_depth_clearance) openconnect_screw(split=false);
  if (generate_slot) {
    diff() cuboid([tile_size * horizontal_grids, tile_size * vertical_grids, openconnect_slot_total_height + openconnect_slot_to_front_thickness], anchor=BOTTOM) {
        attach(TOP, TOP, inside=true)
          tag("remove") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=openconnect_slot_lock_distribution, direction_flip=openconnect_slot_direction_flip, excess_thickness=0);
      }
  }
}
