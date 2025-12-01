/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem

2025-09-04 Update: Added uninstall notch. Default threads offset angle is now set to 0 for consistency with David's original snaps.
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
//It seems as of now (2025-08) makerworld's customizer needs rounding.scad to be included manually, despite the fact it should be included in std.scad according to BOSL2 wiki.
include <BOSL2/rounding.scad>

snap_version = "Standard"; //[Standard:Standard - 6.8mm, Lite Strong:Lite Strong - 4mm, Lite Basic:Lite Basic - 3.4mm]
snap_base_shape = "Directional"; //["Directional","Symmetric"]
snap_locking_mechanism = "Original"; //["Self-Expanding","Original"]
generate_multiconnect_screw = true;
generate_snap = true;
add_threads_blunt_end = false;

/* [Snap Body Options] */
snap_body_width = 24.8;

snap_corner_edge_height = 1.5;
snap_body_top_corner_extrude = 1.1;
snap_body_bottom_corner_extrude = 0.6;

directional_slant_depth_standard = 0.8;
directional_slant_depth_lite = 0.2;
directional_corner_fillet_radius = 1.5;
directional_arrow_depth = 0.2;

/* [Snap Nub Options] */
basic_nub_width = 10.8;
basic_nub_height_standard = 2; //0.1
basic_nub_height_lite = 1.8;
basic_nub_depth = 0.4;
basic_nub_top_width = 6.8;
basic_nub_top_angle = 35;
basic_nub_bottom_angle = 35;

directional_nub_width = 14; //0.1
directional_nub_height_standard = 4; //0.1
directional_nub_height_lite = 2.4;
directional_nub_depth = 0.8;
directional_nub_top_width = 10; //0.1
directional_nub_top_angle = 35;
directional_nub_bottom_angle_standard = 35;
directional_nub_bottom_angle_lite = 45;

antidirect_nub_height_standard = 2; //0.1
antidirect_nub_height_lite = 1.4; //0.1

nub_offset_to_top = 1.4; //0.1
nub_fillet_radius = 15;

/* [Snap Cut Options] */
back_cut_length = 12.4;
back_cut_thickness = 0.6;
back_cut_offset_to_top = 0.6;
back_cut_offset_to_edge = 0.7;

side_cut_thickness = 0.4; //0.1
side_cut_depth = 0.8; //0.1
side_cut_offset_to_top = 0.8; //0.1

/* [Thread Options] */
//openGrid snap threads are designed to have 16mm diameter and 0.5mm clearance, 16.5mm is the offical diameter for negative parts.
threads_diameter = 16; //0.1
threads_clearance = 0.5;
threads_pitch = 3;
threads_top_bevel = 0.5;
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1
threads_offset_angle = 0; //[0:15:345]
//Threads position offsets doesn't affect self-expanding snaps.
threads_x_position_offset = 0; //0.1
threads_y_position_offset = 0; //0.1

/* [Expanding Snap Options] */
//The default value is suitable for Bambu PLA Basic, Bambu PETG HF, and Sunlu PLA+ 2.0. You may need to adjust it depending on the filament you use.
expand_distance_standard = 1.0; //0.05
//Lite snaps have thinner springs, thus a larger expand distance than Standard snaps.
expand_distance_lite = 1.2; //0.05
//a small notch making uninstalling easier.
add_uninstall_notch = true;
uninstall_notch_width = 4; //0.2
uninstall_notch_surface_height_standard = 1.2;
uninstall_notch_surface_height_lite = 0.8;
uninstall_notch_gap_height_standard = 0.8;
uninstall_notch_gap_height_lite = 0.6;

/* [Expanding Snap Advanced Options] */
//The part before the threads start expanding. Increase this value if you find it difficult to get the screw started.
expand_entry_height_standard = 0.4;
expand_entry_height_lite = 0.4;
expand_entry_height_blunt_end = 1;
expand_split_angle = 45;
//Default spring thickness parameters are set to products of 0.42, a common line width for 0.4mm nozzles.
spring_thickness = 1.26;
spring_to_center_thickness = 0.84;
spring_gap = 0.42;
spring_face_chamfer = 0.2;
//The part at the bottom that completely expands to target width. It's not recommended to set this lower than threads_bottom_bevel.
expand_endpart_height_standard = 2; //0.1
expand_endpart_height_lite = 1.2; //0.1
//this value dictates how much the width of each layer of threads differs from the last. Setting it lower makes the threads smoother and takes longer to generate. For 3d printing, 0.05 should be more than sufficient.
expansion_distance_step = 0.05;

/* [Text Options] */
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
//Useful when experimenting with expansion distance.
add_snap_expansion_distance_text = false;
text_depth = 0.4;

/* [Misc. Connector Options] */
coin_slot_height = 3;
coin_slot_width = 14;
coin_slot_thickness = 2.4;
split_distance = 0.4;
split_layer_height = 0.2;
//The following formula is derived from intersecting chord theorem. Don't ask.
coin_slot_radius = coin_slot_height / 2 + coin_slot_width ^ 2 / (8 * coin_slot_height);

/* [View Options] */
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
//Use with cross-section view to see how threads of snap and connector fit together.
view_snap_and_connector_overlapped = false;
view_snap_rotated = 0;
//By default, the connector needs to rotate 45 degrees to fit the expanding snap.
view_connector_rotated = 0;

/* [Experimental Options] */
override_snap_thickness = false;
//Custom thickness only applies when override_snap_thickness is checked.
custom_snap_thickness = 3.4;
//Making multiconnect connector attach to the backside, opening up a new option for mounting the board. Idea suggested by @ljhms.
reverse_threads_entryside = false;

/* [Disable Part Options] */
disable_snap_threads = false;
disable_snap_corners = false;
disable_snap_cuts = false;
disable_snap_nubs = false;
disable_snap_directional_slants = false;
disable_snap_expanding_springs = false;

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

generate_openconnect_screw = false;
openconnect_screw_split = false;
add_threads_blunt_end_text = true;
threads_blunt_end_text = "🔓";
threads_blunt_end_text_font = "Noto Emoji"; // font

//The official Snap threads are designed in shapr3d and have a different starting point than those made in openscad. Rotating by 53.5 degrees makes them conform.
threads_compatiblity_angle = 53.5;

snap_thickness =
  override_snap_thickness ? custom_snap_thickness
  : snap_version == "Standard" ? 6.8
  : snap_version == "Lite Strong" ? 4
  : 3.4;
snap_body_corner_outer_diagonal = 2.7 + 1 / sqrt(2);
snap_body_corner_chamfer = snap_body_corner_outer_diagonal * sqrt(2);
snap_body_corner_inner_diagonal = snap_body_width * sqrt(2) / 2 - snap_body_corner_outer_diagonal;

//threads parameters
threads_negative_diameter = threads_diameter + threads_clearance;
threads_bottom_bevel =
  add_threads_blunt_end ? 0
  : snap_version == "Standard" ? threads_bottom_bevel_standard
  : threads_bottom_bevel_lite;

//nub paramters
basic_nub_height =
  snap_version == "Standard" ? basic_nub_height_standard
  : basic_nub_height_lite;
directional_nub_height =
  snap_version == "Standard" ? directional_nub_height_standard
  : directional_nub_height_lite;
antidirect_nub_height =
  snap_version == "Standard" ? antidirect_nub_height_standard
  : antidirect_nub_height_lite;
directional_nub_bottom_angle =
  snap_version == "Standard" ? directional_nub_bottom_angle_standard
  : directional_nub_bottom_angle_lite;

//slant parameters
directional_slant_height = max(snap_thickness - nub_offset_to_top - antidirect_nub_height, eps);
directional_slant_depth =
  snap_version == "Standard" ? directional_slant_depth_standard
  : directional_slant_depth_lite;
directional_corner_slant_depth = directional_slant_depth / sqrt(2);

//text parameters
final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

//expand parameters
expanding_distance_offset = 0;
expand_distance =
  snap_version == "Standard" ? expand_distance_standard - expanding_distance_offset
  : expand_distance_lite - expanding_distance_offset;
expand_entry_height =
  add_threads_blunt_end ? expand_entry_height_blunt_end
  : snap_version == "Standard" ? expand_entry_height_standard
  : expand_entry_height_lite;
expand_endpart_height =
  add_threads_blunt_end ? 0
  : snap_version == "Standard" ? expand_endpart_height_standard
  : expand_endpart_height_lite;

expand_transpart_height = max(snap_thickness - expand_entry_height - expand_endpart_height, 0);
expand_segment_count = ceil(expand_distance / expansion_distance_step);
expand_height_step = expand_transpart_height / expand_segment_count;

threads_blunt_end_notch_offset_standard = 1.6;
threads_blunt_end_notch_offset_lite = 0.8;
threads_blunt_end_notch_total_height =
  snap_version == "Standard" ? threads_bottom_bevel + threads_blunt_end_notch_offset_standard
  : threads_bottom_bevel + threads_blunt_end_notch_offset_lite;
threads_blunt_end_distance = max(0, snap_thickness - threads_blunt_end_notch_total_height);

uninstall_notch_surface_height =
  snap_version == "Standard" ? uninstall_notch_surface_height_standard
  : uninstall_notch_surface_height_lite;
uninstall_notch_gap_height =
  snap_version == "Standard" ? uninstall_notch_gap_height_standard
  : uninstall_notch_gap_height_lite;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

corner_anchors = [FRONT + LEFT, FRONT + RIGHT, BACK + LEFT, BACK + RIGHT];
side_anchors = [FRONT, LEFT, RIGHT, BACK];

module snap_shape(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[snap_body_width, snap_body_width, snap_thickness]) {
    cuboid([snap_body_width, snap_body_width, snap_thickness], chamfer=snap_body_corner_chamfer, edges="Z");
    children();
  }
}

module snap_corner() {
  down(snap_thickness / 2 - snap_corner_edge_height / 2) {
    for (i = corner_anchors) {
      attach(i, BOTTOM, shiftout=-snap_body_corner_outer_diagonal - eps)
        prismoid(size1=[snap_body_corner_chamfer * sqrt(2), snap_corner_edge_height], xang=45, yang=[90, 45], h=snap_body_top_corner_extrude);
    }
  }
  //bottom corners for directional full snaps
  if (snap_base_shape == "Directional" && snap_version == "Standard") {
    up(snap_thickness / 2 - snap_corner_edge_height / 2) {
      diff("corner_fillet") {
        attach(BACK + LEFT, BOTTOM, shiftout=-snap_body_corner_outer_diagonal - eps)
          prismoid(size1=[snap_body_corner_chamfer * sqrt(2), snap_corner_edge_height], xang=45, yang=[45, 90], h=snap_body_bottom_corner_extrude)
            tag("corner_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=6.8, r=directional_corner_fillet_radius, $fn=64);
        attach(BACK + RIGHT, BOTTOM, shiftout=-snap_body_corner_outer_diagonal - eps)
          prismoid(size1=[snap_body_corner_chamfer * sqrt(2), snap_corner_edge_height], xang=45, yang=[45, 90], h=snap_body_bottom_corner_extrude)
            tag("corner_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=6.8, r=directional_corner_fillet_radius, $fn=64);
      }
    }
  }
}
module snap_cut() {
  for (i = side_anchors) {
    //The way I make directional snap's slanted side means setting rounding here won't work. It's probably better to create the cut by rotating rounded cuboid, but then the position needs to be calculated and I can't trignometry anymore
    back_cut_rounding = snap_base_shape == "Directional" && i == FRONT ? 0 : back_cut_thickness / 2;
    if (snap_base_shape != "Directional" || i != BACK) {
      up(back_cut_offset_to_top)
        attach(i, FRONT, inside=true, shiftout=-back_cut_offset_to_edge)
          cuboid([back_cut_length, back_cut_thickness, snap_thickness], rounding=back_cut_rounding, edges="Z", $fn=64);
      up(side_cut_offset_to_top)
        attach(i, FRONT, align=BOTTOM, inside=true)
          cuboid([back_cut_length, side_cut_depth, side_cut_thickness]);
    }
  }
  if (snap_base_shape == "Directional") {
    //a relatively simple way to do "offset face".
    up(snap_thickness / 2 - directional_slant_height / 2) {
      tag_diff("remove", "inner_remove") {
        //the triangle used for cutting
        attach(FRONT, FRONT, inside=true, shiftout=-back_cut_offset_to_edge - back_cut_thickness)
          tag("") prismoid(size2=[back_cut_length, directional_slant_depth], size1=[back_cut_length, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
        //the triangle used for cutting the triangle used for cutting
        attach(FRONT, FRONT, inside=true, shiftout=-back_cut_offset_to_edge)
          tag("inner_remove") prismoid(size2=[back_cut_length, directional_slant_depth], size1=[back_cut_length, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
      }
      //the keep tag makes resulting shape invulnerable to diff()
      tag_diff("keep", "inner_remove") {
        attach(FRONT, FRONT, inside=true, shiftout=-back_cut_offset_to_edge)
          tag("") prismoid(size2=[back_cut_length, directional_slant_depth], size1=[back_cut_length, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
        attach(FRONT, FRONT, inside=true)
          tag("inner_remove") prismoid(size2=[snap_body_width, directional_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
      }
    }
  }
}
module snap_nub() {
  basic_nub_size1 = [basic_nub_width, basic_nub_height];
  basic_nub_size2 = [basic_nub_top_width, undef];

  directional_nub_size1 = [directional_nub_width, directional_nub_height];
  directional_nub_size2 = [directional_nub_top_width, undef];

  antidirect_nub_size1 = [basic_nub_width, antidirect_nub_height];

  basic_nub_yang = [basic_nub_top_angle, basic_nub_bottom_angle];
  directional_nub_yang = [directional_nub_top_angle, directional_nub_bottom_angle];

  for (i = side_anchors) {
    final_nub_size1 =
      (snap_base_shape == "Directional" && i == BACK) ? directional_nub_size1
      : (snap_base_shape == "Directional" && i == FRONT) ? antidirect_nub_size1
      : basic_nub_size1;
    final_nub_size2 = (snap_base_shape == "Directional" && i == BACK) ? directional_nub_size2 : basic_nub_size2;
    l_nub_yang = (snap_base_shape == "Directional" && i == BACK) ? directional_nub_yang : basic_nub_yang;
    l_nub_depth = (snap_base_shape == "Directional" && i == BACK) ? directional_nub_depth : basic_nub_depth;
    up(nub_offset_to_top) attach(i, BOTTOM, align=BOTTOM, shiftout=-eps)
        diff("nub_fillet") {
          prismoid(size1=final_nub_size1, size2=final_nub_size2, yang=l_nub_yang, h=l_nub_depth)
            tag("nub_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=6.8, r=nub_fillet_radius);
        }
  }
  //cut off excess nub parts
  down(eps / 2) tag("remove") attach(TOP, TOP) cuboid(30);
}

module snap_directional_slant() {
  up(snap_thickness / 2 - directional_slant_height / 2) {
    attach(FRONT + LEFT, FRONT, inside=true, shiftout=-snap_body_corner_outer_diagonal)
      prismoid(size2=[snap_body_width, directional_corner_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_corner_slant_depth / 2], h=directional_slant_height);
    attach(FRONT + RIGHT, FRONT, inside=true, shiftout=-snap_body_corner_outer_diagonal)
      prismoid(size2=[snap_body_width, directional_corner_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_corner_slant_depth / 2], h=directional_slant_height);
    attach(FRONT, FRONT, inside=true)
      prismoid(size2=[snap_body_width, directional_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
  }
}
module expanding_spring(bottom_type = "None") {
  //gap_length needs to be enough to cut to screw hole without reaching the other side. exact number doesn't matter 
  gap_length = 9;
  //only after writing these did I realize I can achieve the same thing with a rect()
  gap_top_profile = [[-spring_gap / 2, 0], [-spring_gap / 2, gap_length], [spring_gap / 2, gap_length], [spring_gap / 2, 0]];
  gap_top_profile_rounded = round_corners(gap_top_profile, method="circle", radius=[0, spring_gap / 2, spring_gap / 2, 0], $fn=64);
  middle_gap_side_profile_none = [
    [0, 0],
    [0, snap_thickness],
    [gap_length, snap_thickness],
    [gap_length, snap_corner_edge_height],
    [gap_length + snap_body_top_corner_extrude, snap_corner_edge_height - snap_body_top_corner_extrude],
    [gap_length + snap_body_top_corner_extrude, 0],
  ];
  middle_gap_side_profile_slant = [
    [0, 0],
    [0, snap_thickness],
    [gap_length - directional_slant_depth, snap_thickness],
    [gap_length, snap_thickness - directional_slant_height],
    [gap_length, snap_corner_edge_height],
    [gap_length + snap_body_top_corner_extrude, snap_corner_edge_height - snap_body_top_corner_extrude],
    [gap_length + snap_body_top_corner_extrude, 0],
  ];
  middle_gap_side_profile_corner = [
    [0, 0],
    [0, snap_thickness],
    [gap_length + snap_body_bottom_corner_extrude, snap_thickness],
    [gap_length + snap_body_bottom_corner_extrude, snap_thickness - (snap_corner_edge_height - snap_body_bottom_corner_extrude)],
    [gap_length, snap_thickness - snap_corner_edge_height],
    [gap_length, snap_corner_edge_height],
    [gap_length + snap_body_top_corner_extrude, snap_corner_edge_height - snap_body_top_corner_extrude],
    [gap_length + snap_body_top_corner_extrude, 0],
  ];
  middle_gap_side_profile =
    bottom_type == "None" ? middle_gap_side_profile_none
    : bottom_type == "Slant" ? middle_gap_side_profile_slant
    : middle_gap_side_profile_corner;
  middle_gap_bottom_to_side =
    bottom_type == "None" ? 0
    : bottom_type == "Slant" ? -directional_slant_depth
    : snap_body_bottom_corner_extrude;

  //middle gap main body
  back(snap_body_corner_inner_diagonal - gap_length - spring_thickness) zrot(90) xrot(90)
        offset_sweep(middle_gap_side_profile, height=spring_gap + eps, bottom=os_smooth(joint=spring_gap / 2), top=os_smooth(joint=spring_gap / 2), anchor="zcenter");
  //middle gap top chamfer
  back(snap_body_corner_inner_diagonal - gap_length - spring_thickness + snap_body_top_corner_extrude)
    offset_sweep(gap_top_profile_rounded, height=spring_face_chamfer + eps, bottom=os_chamfer(width=-spring_face_chamfer));
  //middle gap bottom chamfer
  up(snap_thickness + eps / 2) yrot(180) back(snap_body_corner_inner_diagonal - gap_length - spring_thickness + middle_gap_bottom_to_side)
        offset_sweep(gap_top_profile_rounded, height=spring_face_chamfer + eps, bottom=os_chamfer(width=-spring_face_chamfer));

  right(spring_thickness + spring_gap) back(gap_length + threads_negative_diameter / 2 + spring_to_center_thickness) zrot(180) offset_sweep(gap_top_profile_rounded, height=snap_thickness + eps, bottom=os_chamfer(width=-spring_face_chamfer), top=os_chamfer(width=-spring_face_chamfer));
  left(spring_thickness + spring_gap) back(gap_length + threads_negative_diameter / 2 + spring_to_center_thickness) zrot(180) offset_sweep(gap_top_profile_rounded, height=snap_thickness + eps, bottom=os_chamfer(width=-spring_face_chamfer), top=os_chamfer(width=-spring_face_chamfer));
}

module expanding_snap_shape(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[snap_body_width, snap_body_width, snap_thickness]) {
    down(snap_thickness / 2) difference() {
        snap_shape(anchor=BOTTOM);
        if (!disable_snap_threads) {
          down(eps / 2)
            up(reverse_threads_entryside ? snap_thickness + eps / 2 : 0) yrot(reverse_threads_entryside ? 180 : 0)
                expanding_thread(diameter=threads_negative_diameter, expand_width=expand_distance, entry_height=expand_entry_height, transition_height=expand_transpart_height, end_height=expand_endpart_height, offset_angle=threads_compatiblity_angle + threads_offset_angle, split_angle=expand_split_angle, anchor=BOT);
        }
      }
    children();
  }
}
module expanding_thread(diameter, expand_width, entry_height, transition_height, end_height, offset_angle = 53.5, split_angle = 45, anchor = CENTER, spin = 0, orient = UP) {
  expand_width_step = expansion_distance_step;
  expand_segment_count = ceil(expand_width / expand_width_step);
  expand_height_step = transition_height / expand_segment_count;
  render() {
    attachable(anchor, spin, orient, d=diameter, h=entry_height + transition_height + end_height) {
      tag_scope() diff() {
          down((entry_height + transition_height + end_height) / 2) {
            if (entry_height > 0) {
              zrot(offset_angle) {
                if (add_threads_blunt_end)
                  blunt_threaded_rod(diameter=diameter, rod_height=entry_height + eps, top_bevel=0, bottom_bevel=0);
                else
                  generic_threaded_rod(d=diameter, l=entry_height + eps, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_top_bevel, entry_height), bevel2=0, anchor=BOTTOM, blunt_start=false, internal=false);
              }
            }
            echo(entry_height=entry_height, transition_height=transition_height, end_height=end_height);
            for (a = [0:expand_segment_count - 1]) {
              aseg_position = entry_height + expand_height_step * a;
              aseg_expansion_distance = expand_width_step * (a + 1);
              echo(a=a, aseg_position=aseg_position, aseg_expansion_distance=aseg_expansion_distance);
              zrot(-split_angle)
                partition(spread=-aseg_expansion_distance - eps, cutpath="flat", $slop=aseg_expansion_distance / 2)
                  zrot(split_angle + offset_angle) up(aseg_position) zrot(aseg_position * 120) {
                        if (add_threads_blunt_end)
                          blunt_threaded_rod(diameter=diameter, rod_height=expand_height_step + eps, top_bevel=0, bottom_bevel=0);
                        else
                          generic_threaded_rod(d=diameter, l=expand_height_step + eps, pitch=threads_pitch, profile=threads_profile, bevel1=0, bevel2=0, anchor=BOTTOM, blunt_start=false, internal=false);
                      }
            }
            if (end_height > 0) {
              zrot(-split_angle)
                partition(spread=-expand_segment_count * expand_width_step - eps, cutpath="flat", $slop=expand_segment_count * expand_width_step / 2)
                  zrot(split_angle + offset_angle) up(entry_height + transition_height) zrot((entry_height + transition_height) * 120) {
                        if (add_threads_blunt_end)
                          blunt_threaded_rod(diameter=diameter, rod_height=max(end_height, 0) + eps, top_bevel=0, bottom_bevel=0);
                        else
                          generic_threaded_rod(d=diameter, l=max(end_height, 0) + eps, pitch=threads_pitch, profile=threads_profile, bevel1=0, bevel2=max(0, min(end_height, threads_bottom_bevel)), anchor=BOTTOM, blunt_start=false, internal=false);
                      }
            }
          }
        }
      children();
    }
  }
}

module snap() {
  difference() {
    if (snap_locking_mechanism == "Self-Expanding") {
      diff() {
        expanding_snap_shape(anchor=BOTTOM) {
          if (!disable_snap_corners)
            snap_corner();
          if (!disable_snap_nubs)
            snap_nub();
          if (!disable_snap_directional_slants && snap_base_shape == "Directional")
            snap_directional_slant();
        }
        if (!disable_snap_expanding_springs) {
          tag("remove") down(eps / 2) zrot(expand_split_angle) expanding_spring(snap_base_shape == "Directional" && snap_version == "Standard" ? "Corner" : "None");
          tag("remove") down(eps / 2) zrot(expand_split_angle - 180) expanding_spring(snap_base_shape == "Directional" ? "Slant" : "None");
        }
        if (add_uninstall_notch) {
          tag("remove") down(eps) fwd(snap_body_width / 2)
                cuboid([uninstall_notch_width, 0.84, uninstall_notch_surface_height], anchor=BOTTOM + FRONT)
                  attach(TOP, BOTTOM, align=FRONT)
                    cuboid([uninstall_notch_width, 1.68, uninstall_notch_gap_height])
                      attach(FRONT, BACK, align=TOP)
                        cuboid([uninstall_notch_width, 1.68, uninstall_notch_gap_height]);
        }
      }
    } else if (snap_locking_mechanism == "Original") {
      diff() {
        snap_shape(anchor=BOTTOM) {
          if (!disable_snap_corners)
            snap_corner();
          if (!disable_snap_nubs)
            snap_nub();
          if (!disable_snap_cuts)
            snap_cut();
          if (!disable_snap_directional_slants && snap_base_shape == "Directional")
            snap_directional_slant();
        }
        if (!disable_snap_threads) {
          tag_diff(tag="remove", remove="inner_rm") left(threads_x_position_offset) back(threads_y_position_offset)
                down(eps / 2) up(reverse_threads_entryside ? snap_thickness + eps / 2 : 0) yrot(reverse_threads_entryside ? 180 : 0)
                      zrot(threads_compatiblity_angle + threads_offset_angle) {
                        if (add_threads_blunt_end)
                          blunt_threaded_rod(diameter=threads_negative_diameter, rod_height=snap_thickness + eps);
                        else
                          generic_threaded_rod(d=threads_negative_diameter, l=snap_thickness + eps, pitch=threads_pitch, profile=threads_profile, bevel1=0, bevel2=min(threads_bottom_bevel, snap_thickness), anchor=BOTTOM, blunt_start=false, internal=false);
                      }
        }
      }
    }
    if (add_threads_blunt_end_text && add_threads_blunt_end)
      up(snap_thickness - text_depth) fwd(0) left(expand_split_angle < 0 ? 0.5 : -0.5) zrot(-expand_split_angle) linear_extrude(height=text_depth) back(snap_body_width / 2 - 2) zrot(45) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
    if (final_add_thickness_text)
      up(snap_thickness - text_depth) fwd(1.1) left(expand_split_angle < 0 ? -0.7 : 0.7) zrot(-expand_split_angle) linear_extrude(height=text_depth) fwd(snap_body_width / 2 - 2) zrot(45) text(str(floor(snap_thickness)), size=4, anchor=str("baseline", CENTER), font="Merriweather Sans:style=Bold");
    if (add_snap_expansion_distance_text && snap_locking_mechanism == "Self-Expanding")
      up(snap_thickness - text_depth) linear_extrude(height=text_depth + eps) fwd(snap_body_width / 2 - 1.6) text(str(expand_distance), size=3.2, anchor=str("baseline", CENTER), font="Merriweather Sans:style=Bold");
    //arrow
    if (snap_base_shape == "Directional")
      zrot(-90) up(snap_thickness + eps / 2) left(snap_body_width / 2 - 1.1) zrot(180) regular_prism(3, side=3.3, h=directional_arrow_depth + eps, chamfer1=directional_arrow_depth, anchor=RIGHT + TOP);
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
module multiconnect_connector() {
  //In David's original design the slot is created in shapr3d by a fillet with a mysterious curvature parameter. I have no idea how to replicate that so here's a circle. Difference in geometry is negligible.
  difference() {
    zrot(threads_compatiblity_angle) {
      if (add_threads_blunt_end)
        blunt_threaded_rod(diameter=threads_diameter, rod_height=snap_thickness, top_bevel=threads_top_bevel, top_cutoff=true);
      else
        generic_threaded_rod(d=threads_diameter, l=snap_thickness + eps, pitch=threads_pitch, profile=threads_profile, bevel1=min(snap_thickness, threads_top_bevel), bevel2=max(0, min(snap_thickness - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
      up(eps) cylinder(h=0.5, r=7.5, anchor=TOP)
          attach(BOTTOM, TOP) cylinder(h=2.5, r2=7.5, r1=10)
              attach(BOTTOM, TOP) cylinder(h=1, r=10);
    }
    down(4 - coin_slot_height) xrot(90) cyl(r=coin_slot_radius, h=coin_slot_thickness, $fn=128, anchor=BACK);
    if (final_add_thickness_text)
      up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_end_text && add_threads_blunt_end ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
    if (add_threads_blunt_end_text && add_threads_blunt_end)
      up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
  }
}

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
openconnect_lock_nub_tip_height = 1;
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
module openconnect_head(is_negative = false, add_nubs = 2, excess_thickness = 0) {
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
      rot_copies([90, 0, 0], n=add_nubs)
        left(large_rect_width / 2 - openconnect_lock_nub_depth / 2 + eps) zrot(-90)
            linear_extrude(4) trapezoid(h=openconnect_lock_nub_depth, w2=openconnect_lock_nub_tip_height, ang=[45, 45], rounding=[openconnect_lock_nub_inner_fillet, openconnect_lock_nub_inner_fillet, -openconnect_lock_nub_outer_fillet, -openconnect_lock_nub_outer_fillet], $fn=64);
  }
}
module openconnect_slot(add_nubs = 1, direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
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
      openconnect_head(is_negative=true, add_nubs=add_nubs ? 1 : 0, excess_thickness=excess_thickness);
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
                openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? 1 : 0, direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs=1, direction_flip=direction_flip, excess_thickness=excess_thickness);
          }
        }
    children();
  }
}
//END openConnect slot modules

//BEGIN openConnect connectors
module openconnect_screw(threads_height = threads_height, split = true) {
  up(split ? openconnect_head_middle_to_bottom : threads_height + openconnect_head_total_height) xrot(split ? 90 : 180) {
      difference() {
        union() {
          up(openconnect_head_total_height - eps)
            difference() {
              zrot(threads_compatiblity_angle) {
                if (add_threads_blunt_end)
                  blunt_threaded_rod(diameter=threads_diameter, rod_height=threads_height, top_bevel=0, top_cutoff=true);
                else
                  generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
              }
              back(split ? 1 : 0) {
                if (add_threads_blunt_end_text && add_threads_blunt_end)
                  up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
                if (final_add_thickness_text)
                  up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_end_text && add_threads_blunt_end ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
              }
            }
          openconnect_head(is_negative=false, add_nubs=2);
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
                  if (add_threads_blunt_end)
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

module openconnect_split_snap() {
  diff() {
    snap_shape(anchor=BOTTOM) {
      if (!disable_snap_corners)
        snap_corner();
      if (!disable_snap_nubs)
        snap_nub();
      if (!disable_snap_cuts)
        snap_cut();
      if (!disable_snap_directional_slants && snap_base_shape == "Directional")
        snap_directional_slant();
      if (split)
        tag("remove") fwd(openconnect_head_middle_to_bottom) cuboid([50, 50, 50], anchor=BACK);
    }
  }
  if (split) {
    up(split_distance - eps) xrot(180, cp=[0, -openconnect_head_middle_to_bottom, snap_thickness + openconnect_head_total_height]) {
        up(openconnect_head_total_height)
          difference() {
            zrot(threads_compatiblity_angle)
              generic_threaded_rod(d=threads_diameter, l=threads_height, pitch=threads_pitch, profile=threads_profile, bevel1=min(threads_height, threads_top_bevel), bevel2=max(0, min(threads_height - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
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
module main_generate() {
  if (generate_snap)
    zrot(view_snap_rotated)
      snap();
  if (generate_multiconnect_screw)
    left(!generate_snap || view_snap_and_connector_overlapped ? 0 : 28) up(view_snap_and_connector_overlapped ? 0 : 4) zrot(view_connector_rotated)
          multiconnect_connector();
  if (generate_openconnect_screw)
    back(!generate_snap || view_snap_and_connector_overlapped ? 0 : 28) fwd(view_snap_and_connector_overlapped && openconnect_screw_split ? openconnect_head_middle_to_bottom : 0)
        down(!view_snap_and_connector_overlapped ? 0 : openconnect_screw_split ? openconnect_head_total_height : -snap_thickness)
          zrot(view_connector_rotated) xrot(!view_snap_and_connector_overlapped ? 0 : openconnect_screw_split ? -90 : -180)
              openconnect_screw(threads_height=snap_thickness, split=openconnect_screw_split);
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
