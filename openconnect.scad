include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

vertical_grids = 1;
horizontal_grids = 1;

generate_connector = true;
generate_slot = true;
flip_slot_direction = false;
slot_side_empty = false;
slot_bottom_empty = false;

slot_lock_distribution = "Staggered"; //["Staggered","All", "None"]
snap_version = "Standard"; //["Standard","Lite Strong", "Lite Basic"]

view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_overlapped = false;

head_bottom_height = 0.6;
head_bottom_chamfer = 0;
head_top_height = 0.4;
head_middle_height = 1.6;
head_large_rect_width = 17; //0.1
head_large_rect_height = 11; //0.1

head_nub_to_top_distance = 7.3;
nub_depth = 0.6;
nub_tip_height = 1; //0.1
nub_inner_fillet = 0.2;
nub_outer_fillet = 0.8;

head_large_rect_chamfer = 4; //0.1
head_small_rect_width = head_large_rect_width - head_middle_height * 2;
head_small_rect_height = head_large_rect_height - head_middle_height;
head_small_rect_chamfer = head_large_rect_chamfer - head_middle_height + ang_adj_to_opp(45 / 2, head_middle_height);

split_distance = 0.4;
split_layer_height = 0.2;

/*[Slot Parameters]*/
slot_ramp_clearance = 1.6;
slot_move_distance = 10.4; //0.1
slot_side_clearance = 0.2;
slot_depth_clearance = 0.12;
slot_to_front_thickness = 1.68; //0.42

/*[Text Options]*/
text_depth = 0.4;
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

tile_size = 28;

// /* [Thread Options] */
threads_diameter = 16;
threads_clearance = 0.5;
threads_compatiblity_angle = 53.5;
threads_rotate_angle = 45;
threads_top_bevel = 0.5; //0.1
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1
threads_negative_diameter = threads_diameter + threads_clearance;

snap_thickness =
  snap_version == "Standard" ? 6.8
  : snap_version == "Lite Strong" ? 4
  : snap_version == "Lite Basic" ? 3.4
  : 0;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

//threads parameters
threads_height = snap_thickness;
threads_bottom_bevel =
  snap_version == "Standard" ? threads_bottom_bevel_standard
  : snap_version == "Lite" ? threads_bottom_bevel_lite
  : 0;

// /* [Threads Locking Options] */
add_threads_locking = true;
threads_locking_path_degree = 30;
threads_locking_starting_degree_standard = 155;
threads_locking_starting_degree_lite = 150;
threads_locking_starting_degree =
  snap_version == "Standard" ? threads_locking_starting_degree_standard
  : threads_locking_starting_degree_lite;

add_threads_locking_text = true;
threads_locking_text = "🔓";
threads_locking_text_font = "Noto Emoji"; // font
threads_locking_notch_total_height = threads_bottom_bevel + 1.2;
threads_locking_distance = max(0, snap_thickness - threads_locking_notch_total_height);

final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

coin_slot_height = 3;
coin_slot_width = 13.3;
coin_slot_thickness = 2.4;
coin_slot_radius = coin_slot_height / 2 + coin_slot_width ^ 2 / (8 * coin_slot_height);

head_bottom_profile = back(head_large_rect_width / 2, rect([head_large_rect_width, head_large_rect_height], chamfer=[head_large_rect_chamfer, head_large_rect_chamfer, 0, 0], anchor=BACK));
head_top_profile = back(head_small_rect_width / 2, rect([head_small_rect_width, head_small_rect_height], chamfer=[head_small_rect_chamfer, head_small_rect_chamfer, 0, 0], anchor=BACK));
head_total_height = head_top_height + head_middle_height + head_bottom_height;

slot_top_profile = offset(head_top_profile, delta=slot_side_clearance);
slot_bottom_profile = offset(head_bottom_profile, delta=slot_side_clearance);

slot_bottom_height = head_bottom_height + ang_adj_to_opp(45 / 2, slot_side_clearance);
slot_middle_height = head_middle_height;
slot_top_height = head_top_height - ang_adj_to_opp(45 / 2, slot_side_clearance) + slot_depth_clearance;
slot_total_height = slot_top_height + slot_middle_height + slot_bottom_height;
slot_nub_to_top_distance = head_nub_to_top_distance + slot_side_clearance;

slot_small_rect_width = head_small_rect_width + slot_side_clearance * 2;
slot_small_rect_height = head_small_rect_height + slot_side_clearance * 2;
slot_small_rect_chamfer = head_small_rect_chamfer + slot_side_clearance - ang_adj_to_opp(45 / 2, slot_side_clearance);
slot_large_rect_width = head_large_rect_width + slot_side_clearance * 2;
slot_large_rect_height = head_large_rect_height + slot_side_clearance * 2;
slot_large_rect_chamfer = head_large_rect_chamfer + slot_side_clearance - ang_adj_to_opp(45 / 2, slot_side_clearance);
slot_to_grid_top_offset = (tile_size - 24.8) / 2;

head_side_profile = [
  [0, 0],
  [head_large_rect_width / 2 - head_bottom_chamfer, 0],
  [head_large_rect_width / 2, head_bottom_chamfer],
  [head_large_rect_width / 2, head_bottom_height],
  [head_small_rect_width / 2, head_bottom_height + head_middle_height],
  [head_small_rect_width / 2, head_bottom_height + head_middle_height + head_top_height],
  [0, head_bottom_height + head_middle_height + head_top_height],
];

slot_side_profile = [
  [0, 0],
  [slot_large_rect_width / 2, 0],
  [slot_large_rect_width / 2, slot_bottom_height],
  [slot_small_rect_width / 2, slot_bottom_height + slot_middle_height],
  [slot_small_rect_width / 2, slot_bottom_height + slot_middle_height + slot_top_height],
  [0, slot_bottom_height + slot_middle_height + slot_top_height],
];

module openconnect_head(is_negative = false, add_nub = 2, excess_thickness = 0) {
  bottom_profile = is_negative ? slot_bottom_profile : head_bottom_profile;
  top_profile = is_negative ? slot_top_profile : head_top_profile;

  bottom_height = is_negative ? slot_bottom_height : head_bottom_height;
  middle_height = is_negative ? slot_middle_height : head_middle_height;
  top_height = is_negative ? slot_top_height : head_top_height;
  large_rect_width = is_negative ? slot_large_rect_width : head_large_rect_width;
  large_rect_height = is_negative ? slot_large_rect_height : head_large_rect_height;
  nub_to_top_distance = is_negative ? slot_nub_to_top_distance : head_nub_to_top_distance;

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
      rot_copies([90, 0, 0], n=add_nub)
        left(large_rect_width / 2 - nub_depth / 2 + eps) zrot(-90)
            linear_extrude(4) trapezoid(h=nub_depth, w2=nub_tip_height, ang=[45, 45], rounding=[nub_inner_fillet, nub_inner_fillet, -nub_outer_fillet, -nub_outer_fillet], $fn=64);
  }
}

module openconnect_screw(threads_height = threads_height, split = true) {
  head_middle_to_bottom = head_large_rect_height - head_large_rect_width / 2;
  diff() {
    force_tag("") difference() {
        union() {
          up(head_total_height - eps) difference() {
              zrot(threads_compatiblity_angle)
                generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=3, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
              if (add_threads_locking)
                #zrot(threads_compatiblity_angle)
                  up(threads_locking_distance) zrot(threads_locking_distance * 120)
                      rotate_sweep(right(threads_diameter / 2 - 1, rect([1 + eps, threads_locking_notch_total_height], anchor=LEFT + BOTTOM)), angle=threads_locking_path_degree, start=threads_locking_starting_degree);
              back(1) {
                if (add_threads_locking_text && add_threads_locking)
                  up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_locking_text, size=4, anchor=str("center", CENTER), font=threads_locking_text_font);
                if (final_add_thickness_text)
                  up(snap_thickness - text_depth + eps / 2) left(add_threads_locking_text && add_threads_locking ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
              }
            }
          openconnect_head(is_negative=false, add_nub=2);
        }
        up(coin_slot_height) zrot(0) xrot(90) cyl(r=coin_slot_radius, h=coin_slot_thickness, $fn=128, anchor=BACK);
      }
    if (split)
      tag("remove") fwd(head_middle_to_bottom) cuboid([50, 50, 50], anchor=BACK);
  }
  if (split) {
    up(split_distance) xrot(180, cp=[0, -head_middle_to_bottom, snap_thickness + head_total_height]) {
        up(head_total_height - eps) difference() {
            zrot(threads_compatiblity_angle)
              generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=3, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
            if (add_threads_locking)
              zrot(threads_compatiblity_angle)
                up(threads_locking_distance) zrot(threads_locking_distance * 120)
                    rotate_sweep(right(threads_diameter / 2 - 1, rect([1 + eps, threads_locking_notch_total_height], anchor=LEFT + BOTTOM)), angle=threads_locking_path_degree, start=threads_locking_starting_degree);
            fwd(head_middle_to_bottom) cuboid([50, 50, 50], anchor=FRONT);
          }
        up(snap_thickness + head_total_height) intersection() {
            zcyl(d=threads_diameter - 2 - threads_bottom_bevel, h=split_distance, anchor=BOTTOM);
            fwd(head_middle_to_bottom) cuboid([20, split_layer_height, split_distance], anchor=BOTTOM + BACK);
          }
      }
  }
}

module openconnect_slot(add_nub = 1, flip_slot_direction = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[slot_large_rect_width, slot_large_rect_height, slot_total_height]) {
    up(slot_total_height / 2) yrot(180) union() {
          if (flip_slot_direction)
            xflip() slot_body(excess_thickness);
          else
            slot_body(excess_thickness);
        }
    children();
  }

  module slot_body(excess_thickness = 0) {
    union() {
      openconnect_head(is_negative=true, add_nub=add_nub ? 1 : 0, excess_thickness=excess_thickness);
      xrot(90) linear_extrude(slot_large_rect_height / 2) polygon(slot_side_profile);
      fwd(slot_move_distance) {
        linear_extrude(slot_bottom_height) onramp_2d();
        up(slot_bottom_height)
          linear_extrude(slot_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(slot_middle_height) up(slot_bottom_height + slot_middle_height)
            linear_extrude(slot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(slot_small_rect_chamfer) cuboid([slot_small_rect_width, slot_small_rect_height, slot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=slot_ramp_clearance)
        left(slot_ramp_clearance) back(slot_large_rect_width / 2) {
            rect([slot_large_rect_width, slot_large_rect_height], chamfer=[slot_large_rect_chamfer, slot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=slot_ramp_clearance, w1=slot_large_rect_width - slot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
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
  if (generate_connector)
    fwd(0) back(view_overlapped ? 0 : 28 * vertical_grids) openconnect_screw();
  if (generate_slot) {
    down(slot_to_front_thickness) fwd(slot_to_grid_top_offset) diff() {
          cuboid([tile_size * horizontal_grids, tile_size * vertical_grids, slot_total_height + slot_to_front_thickness], anchor=BOTTOM) {
            back(slot_to_grid_top_offset) {
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger=slot_lock_distribution == "Staggered")
                attach(TOP, BOTTOM, inside=true, shiftout=0.001)
                  openconnect_slot(add_nub=(horizontal_grids == 1 && vertical_grids == 1) || slot_lock_distribution == "All" ? 1 : 0, flip_slot_direction=flip_slot_direction, excess_thickness=0);
              if (slot_lock_distribution == "Staggered")
                grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger="alt")
                  attach(TOP, BOTTOM, inside=true, shiftout=0.001)
                    openconnect_slot(add_nub=1, flip_slot_direction=flip_slot_direction, excess_thickness=0);
            }
          }
        }
  }
}
