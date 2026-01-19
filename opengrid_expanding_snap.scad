/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
//It seems as of now (2025-08) makerworld's customizer needs rounding.scad to be included manually, despite the fact it should be included in std.scad according to BOSL2 wiki.
include <BOSL2/rounding.scad>

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm]
//Directional for vertical wall-mounted boards. Symmetric for horizontal boards, often used with Underware.
snap_base_shape = "Directional"; //["Directional","Symmetric"]
//Regular version is usually enough. Folded version is stronger but requires thinner layer height, thus taking longer to print.
generate_screw = "openConnect"; //["None", "openConnect", "openConnect (Folded)", "multiConnect"]
//Blunt end helps prevent cross-threading and overtightening. Models with blunt ends have a decorative 'lock' symbol at the bottom.
threads_end_type = "Blunt"; //["Blunt", "Basic"]

/* [Expanding Snap Settings] */
//Default value is tested on Bambu PLA Basic, Bambu PETG HF, and Sunlu PLA+ 2.0. You may need to adjust it depending on the filament you use.
expand_distance_standard = 1.0; //0.05
//Lite snaps have thinner springs, thus a larger expand distance than Standard snaps.
expand_distance_lite = 1.2; //0.05
//A small notch to make uninstalling easier. Set to 0 to disable.
uninstall_notch_width = 5; //0.2

/* [Text Settings] */
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
//Useful when experimenting with expansion distance.
add_snap_expansion_distance_text = false;
text_depth = 0.4;

/* [Advanced Settings] */
//Default spring parameters are set to products of 0.42, a common linewidth for 0.4mm nozzles.
spring_thickness = 1.26;
spring_to_center_thickness = 0.84;
spring_gap = 0.42;
threads_offset_angle = 0; //[0:15:345]

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//Generating self-expanding snaps takes longer than original ones. 
generate_snap = "Self-Expanding Threads"; //["Self-Expanding Threads","Basic Threads","openConnect","multiConnect"]

// /* [Snap Body Settings] */
snap_body_width = 24.8;

//Offset connector head/threads position, in x and y.
snap_center_position_offset = [0,0]; //0.1

snap_corner_edge_height = 1.5;
snap_body_top_corner_extrude = 1.1;
snap_body_bottom_corner_extrude = 0.6;

directional_slant_depth_standard = 0.8;
directional_slant_depth_lite = 0.2;
directional_corner_fillet_radius = 1.5;
directional_arrow_depth = 0.2;

// /* [Snap Nub Settings] */
basic_nub_width = 10.8;
basic_nub_height_standard = 2; //0.1
basic_nub_height_lite = 1.8;
basic_nub_depth = 0.4;
basic_nub_top_width = 6.8;
basic_nub_top_angle = 35;
basic_nub_bottom_angle = 35;
basic_nub_fillet_radius = 15;

directional_nub_width = 14.8; //0.1
directional_nub_height_standard = 4; //0.1
directional_nub_height_lite = 2.4;
directional_nub_depth = 0.8;
directional_nub_top_width = 13.2; //0.1
directional_nub_top_angle = 35;
directional_nub_bottom_angle_standard = 35;
directional_nub_bottom_angle_lite = 45;
directional_nub_fillet_radius = 2.8;

antidirect_nub_height_standard = 2; //0.1
antidirect_nub_height_lite = 1.4; //0.1

nub_offset_to_top = 1.4; //0.1

// /* [Snap Cut Settings] */
back_cut_length = 12.4;
back_cut_thickness = 0.6;
back_cut_offset_to_top = 0.6;
back_cut_offset_to_edge = 0.7;

side_cut_thickness = 0.4; //0.1
side_cut_depth = 0.8; //0.1
side_cut_offset_to_top = 0.8; //0.1

// /* [Thread Settings] */
//openGrid snap threads are designed to have 16mm diameter and 0.5mm clearance, 16.5mm is the offical diameter for negative parts.
threads_diameter = 16; //0.1
threads_clearance = 0.5;
threads_pitch = 3;
threads_top_bevel = 0.5;
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1
// /* [Expanding Snap Advanced Settings] */
uninstall_notch_surface_inset = 1;
uninstall_notch_gap_inset = 1.8;
uninstall_notch_surface_height_standard = 1.2;
uninstall_notch_surface_height_lite = 0.8;
uninstall_notch_gap_height_standard = 1;
uninstall_notch_gap_height_lite = 0.6;
//The part before the threads start expanding. Increase this value if you find it difficult to get the screw started.
expand_entry_height_standard = 0.4;
expand_entry_height_lite = 0.4;
expand_entry_height_blunt_end = 1;
expand_split_angle = 45;
spring_face_chamfer = 0.2;
//The part at the bottom that completely expands to target width. It's not recommended to set this lower than threads_bottom_bevel.
expand_endpart_height_standard = 2; //0.1
expand_endpart_height_lite = 1.2; //0.1
//this value dictates how much the width of each layer of threads differs from the last. Setting it lower makes the threads smoother and takes longer to generate. For 3d printing, 0.05 should be more than sufficient.
expansion_distance_step = 0.05;

// /* [openConnect Settings] */
// ochead_bottom_height = 0.6;
// ochead_top_height = 0.6;
// ochead_middle_height = 1.4;
// ochead_large_rect_width = 17; //0.1
// ochead_large_rect_height = 11.2; //0.1
// ochead_large_rect_chamfer = 4;

// ochead_nub_to_top_distance = 7.2;
// ochead_nub_depth = 0.6;
// ochead_nub_tip_height = 1.2;
// ochead_nub_inner_fillet = 0.6;
// ochead_nub_outer_fillet = 0.8;

// ocslot_move_distance = 11; //0.1
// ocslot_onramp_clearance = 0.8;
// ocslot_bridge_offset = 0.4;
// ocslot_side_clearance = 0.15;
// ocslot_depth_clearance = 0.12;

// /* [multiConnect Settings] */
mchead_large_diameter = 20;
mchead_small_diameter = 15;
mchead_top_height = 0.5;
mchead_middle_height = 2.5;
mchead_bottom_height = 1;
mchead_total_height = mchead_top_height + mchead_middle_height + mchead_bottom_height;
connector_coin_slot_height = 2.6;
connector_coin_slot_width = 13;
connector_coin_slot_thickness = 2.4;
//The following formula is derived from intersecting chord theorem. Don't ask.
connector_coin_slot_radius = connector_coin_slot_height / 2 + connector_coin_slot_width ^ 2 / (8 * connector_coin_slot_height);
// /* [View Settings] */
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
//Use with cross-section view to see how threads of snap and connector fit together.
view_snap_and_connector_overlapped = false;
view_snap_rotated = 0;
view_connector_rotated = 0;

// /* [Experimental Settings] */
override_snap_thickness = false;
//Custom thickness only applies when override_snap_thickness is checked.
custom_snap_thickness = 3.4;
//Making multiconnect connector attach to the backside, opening up a new option for mounting the board. Idea suggested by @ljhms.
reverse_threads_entryside = false;

// /* [Disable Part Settings] */
disable_snap_threads = false;
disable_snap_corners = false;
disable_snap_cuts = false;
disable_snap_nubs = false;
disable_snap_directional_slants = false;
disable_snap_expanding_springs = false;

fold_gap_width = 0.4;
fold_gap_height = 0.2;
add_threads_blunt_end_text = true;
threads_blunt_end_text = "🔓";
threads_blunt_end_text_font = "Noto Emoji"; // font

//The official Snap threads are designed in shapr3d and have a different starting point than those made in openscad. Rotating by 53.5 degrees makes them conform.
threads_compatiblity_angle = 53.5;

snap_body_corner_outer_diagonal = 2.7 + 1 / sqrt(2);
snap_body_corner_chamfer = snap_body_corner_outer_diagonal * sqrt(2);
snap_body_corner_inner_diagonal = snap_body_width * sqrt(2) / 2 - snap_body_corner_outer_diagonal;

//threads parameters
threads_negative_diameter = threads_diameter + threads_clearance;
threads_bottom_bevel =
  threads_end_type == "Blunt" ? 0
  : snap_thickness == 6.8 ? threads_bottom_bevel_standard
  : threads_bottom_bevel_lite;

//nub paramters
basic_nub_height =
  snap_thickness == 6.8 ? basic_nub_height_standard
  : basic_nub_height_lite;
directional_nub_height =
  snap_thickness == 6.8 ? directional_nub_height_standard
  : directional_nub_height_lite;
antidirect_nub_height =
  snap_thickness == 6.8 ? antidirect_nub_height_standard
  : antidirect_nub_height_lite;
directional_nub_bottom_angle =
  snap_thickness == 6.8 ? directional_nub_bottom_angle_standard
  : directional_nub_bottom_angle_lite;

//slant parameters
directional_slant_height = max(snap_thickness - nub_offset_to_top - antidirect_nub_height, eps);
directional_slant_depth =
  snap_thickness == 6.8 ? directional_slant_depth_standard
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
  snap_thickness == 6.8 ? expand_distance_standard - expanding_distance_offset
  : expand_distance_lite - expanding_distance_offset;
expand_entry_height =
  threads_end_type == "Blunt" ? expand_entry_height_blunt_end
  : snap_thickness == 6.8 ? expand_entry_height_standard
  : expand_entry_height_lite;
expand_endpart_height =
  threads_end_type == "Blunt" ? 0
  : snap_thickness == 6.8 ? expand_endpart_height_standard
  : expand_endpart_height_lite;

expand_transpart_height = max(snap_thickness - expand_entry_height - expand_endpart_height, 0);
expand_segment_count = ceil(expand_distance / expansion_distance_step);
expand_height_step = expand_transpart_height / expand_segment_count;

uninstall_notch_surface_height =
  snap_thickness == 6.8 ? uninstall_notch_surface_height_standard
  : uninstall_notch_surface_height_lite;
uninstall_notch_gap_height =
  snap_thickness == 6.8 ? uninstall_notch_gap_height_standard
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
  if (snap_base_shape == "Directional" && snap_thickness == 6.8) {
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
    nub_fillet_radius = (snap_base_shape == "Directional" && i == BACK) ? directional_nub_fillet_radius : basic_nub_fillet_radius;
    up(nub_offset_to_top) attach(i, BOTTOM, align=BOTTOM, shiftout=-eps)
        diff("nub_fillet") {
          prismoid(size1=final_nub_size1, size2=final_nub_size2, yang=l_nub_yang, h=l_nub_depth)
            tag("nub_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=8, r=nub_fillet_radius, $fn=64);
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

module snap_uninstall_notch() {
  attach(BOTTOM, BOTTOM, align=FRONT, shiftout=eps, inside=true)
    cuboid([uninstall_notch_width, uninstall_notch_surface_inset, uninstall_notch_surface_height], anchor=BOTTOM)
      attach(TOP, BOTTOM, align=FRONT)
        cuboid([uninstall_notch_width, uninstall_notch_gap_inset, uninstall_notch_gap_height])
          //cut off remaining snap extrusion
          attach(FRONT, BACK, align=TOP)
            cuboid([uninstall_notch_width, uninstall_notch_gap_inset, uninstall_notch_gap_height]);
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
                expanding_thread(diameter=threads_negative_diameter, expand_width=expand_distance, entry_height=expand_entry_height, transition_height=expand_transpart_height, end_height=expand_endpart_height, offset_angle=threads_compatiblity_angle + threads_offset_angle, fold_angle=expand_split_angle, anchor=BOT);
        }
      }
    children();
  }
}
module expanding_thread(diameter, expand_width, entry_height, transition_height, end_height, offset_angle = 53.5, fold_angle = 45, anchor = CENTER, spin = 0, orient = UP) {
  expand_width_step = expansion_distance_step;
  expand_segment_count = ceil(expand_width / expand_width_step);
  expand_height_step = transition_height / expand_segment_count;
  render() {
    attachable(anchor, spin, orient, d=diameter, h=entry_height + transition_height + end_height) {
      tag_scope() diff() {
          down((entry_height + transition_height + end_height) / 2) {
            if (entry_height > 0) {
              zrot(offset_angle) {
                if (threads_end_type == "Blunt")
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
              zrot(-fold_angle)
                partition(spread=-aseg_expansion_distance - eps, cutpath="flat", $slop=aseg_expansion_distance / 2)
                  zrot(fold_angle + offset_angle) up(aseg_position) zrot(aseg_position * 120) {
                        if (threads_end_type == "Blunt")
                          blunt_threaded_rod(diameter=diameter, rod_height=expand_height_step + eps, top_bevel=0, bottom_bevel=0);
                        else
                          generic_threaded_rod(d=diameter, l=expand_height_step + eps, pitch=threads_pitch, profile=threads_profile, bevel1=0, bevel2=0, anchor=BOTTOM, blunt_start=false, internal=false);
                      }
            }
            if (end_height > 0) {
              zrot(-fold_angle)
                partition(spread=-expand_segment_count * expand_width_step - eps, cutpath="flat", $slop=expand_segment_count * expand_width_step / 2)
                  zrot(fold_angle + offset_angle) up(entry_height + transition_height) zrot((entry_height + transition_height) * 120) {
                        if (threads_end_type == "Blunt")
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
  fold_for_printing(body_thickness=snap_thickness + ochead_total_height, fold_position=ochead_middle_to_bottom + eps, condition=generate_snap == "openConnect (Folded)")
    up(generate_snap == "Self-Expanding Threads" || generate_snap == "Basic Threads" ? 0 : snap_thickness)
      yrot(generate_snap == "Self-Expanding Threads" || generate_snap == "Basic Threads" ? 0 : 180)
        difference() {
          if (generate_snap == "Self-Expanding Threads") {
            diff() {
              expanding_snap_shape(anchor=BOTTOM) {
                if (!disable_snap_corners)
                  snap_corner();
                if (!disable_snap_nubs)
                  snap_nub();
                if (!disable_snap_directional_slants && snap_base_shape == "Directional")
                  tag("remove") snap_directional_slant();
                if (uninstall_notch_width > eps)
                  tag("remove") snap_uninstall_notch();
              }
              if (!disable_snap_expanding_springs) {
                tag("remove") down(eps / 2) zrot(expand_split_angle) expanding_spring(snap_base_shape == "Directional" && snap_thickness == 6.8 ? "Corners" : "None");
                tag("remove") down(eps / 2) zrot(expand_split_angle - 180) expanding_spring(snap_base_shape == "Directional" ? "Slant" : "None");
              }
            }
          } else {
            diff(remove="remove") {
              snap_shape(anchor=BOTTOM) {
                if (!disable_snap_corners)
                  snap_corner();
                if (!disable_snap_nubs)
                  snap_nub();
                if (!disable_snap_cuts)
                  snap_cut();
                if (!disable_snap_directional_slants && snap_base_shape == "Directional")
                  tag("remove") snap_directional_slant();
                if (uninstall_notch_width > eps)
                  tag("remove") snap_uninstall_notch();
              }
              left(snap_center_position_offset[0]) back(snap_center_position_offset[1]) {
                  if (generate_snap == "Basic Threads" && !disable_snap_threads) {
                    tag_diff(tag="remove", remove="rm0")
                      down(eps / 2) up(reverse_threads_entryside ? snap_thickness + eps / 2 : 0) yrot(reverse_threads_entryside ? 180 : 0)
                            zrot(threads_compatiblity_angle + threads_offset_angle) {
                              if (threads_end_type == "Blunt")
                                blunt_threaded_rod(diameter=threads_negative_diameter, rod_height=snap_thickness + eps);
                              else
                                generic_threaded_rod(d=threads_negative_diameter, l=snap_thickness + eps, pitch=threads_pitch, profile=threads_profile, bevel1=0, bevel2=min(threads_bottom_bevel, snap_thickness), anchor=BOTTOM, blunt_start=false, internal=false);
                            }
                  }
                  if (generate_snap == "openConnect" || generate_snap == "openConnect (Folded)")
                    down(ochead_total_height) force_tag("") openconnect_head(add_nubs="both");
                  if (generate_snap == "multiConnect")
                    multiconnect_head("dimple");
                }
            }
          }
          if (add_threads_blunt_end_text && threads_end_type == "Blunt" && generate_snap != "openConnect" && generate_snap != "multiConnect")
            up(snap_thickness - text_depth) fwd(0) left(expand_split_angle < 0 ? 0.5 : -0.5) zrot(-expand_split_angle) linear_extrude(height=text_depth) back(snap_body_width / 2 - 2) zrot(45) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
          if (final_add_thickness_text)
            up(snap_thickness - text_depth) fwd(1.1) left(expand_split_angle < 0 ? -0.7 : 0.7) zrot(-expand_split_angle) linear_extrude(height=text_depth) fwd(snap_body_width / 2 - 2) zrot(45) text(str(floor(snap_thickness)), size=4, anchor=str("baseline", CENTER), font="Merriweather Sans:style=Bold");
          if (add_snap_expansion_distance_text && generate_snap == "Self-Expanding Threads")
            up(snap_thickness - text_depth) linear_extrude(height=text_depth + eps) fwd(snap_body_width / 2 - 1.6) text(str(expand_distance), size=3.2, anchor=str("baseline", CENTER), font="Merriweather Sans:style=Bold");
          //arrow
          if (snap_base_shape == "Directional")
            zrot(-90) up(snap_thickness + eps / 2) left(snap_body_width / 2 - 1.1) zrot(180) regular_prism(3, side=3.3, h=directional_arrow_depth + eps, chamfer1=directional_arrow_depth, anchor=RIGHT + TOP);
        }
}

module multiconnect_screw() {
  //In David's original design the slot is created in shapr3d by a fillet with a mysterious curvature parameter. I have no idea how to replicate that so here's a circle. Difference in geometry is negligible.
  difference() {
    union() {
      zrot(threads_compatiblity_angle) {
        if (threads_end_type == "Blunt")
          blunt_threaded_rod(diameter=threads_diameter, rod_height=snap_thickness, top_bevel=threads_top_bevel, top_cutoff=true);
        else
          generic_threaded_rod(d=threads_diameter, l=snap_thickness + eps, pitch=threads_pitch, profile=threads_profile, bevel1=min(snap_thickness, threads_top_bevel), bevel2=max(0, min(snap_thickness - threads_top_bevel, threads_bottom_bevel)), blunt_start=false, anchor=BOTTOM, internal=false);
      }
      multiconnect_head(top_pattern="coin_slot");
    }
    if (final_add_thickness_text)
      up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_end_text && threads_end_type == "Blunt" ? 2.4 : 0) linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
    if (add_threads_blunt_end_text && threads_end_type == "Blunt")
      up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0) linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
  }
}
module multiconnect_head(top_pattern = "coin_slot") {
  difference() {
    up(eps) cylinder(h=mchead_top_height, r=mchead_small_diameter / 2, anchor=TOP)
        attach(BOTTOM, TOP) cylinder(h=mchead_middle_height, r2=mchead_large_diameter / 2 - mchead_middle_height, r1=mchead_large_diameter / 2)
            attach(BOTTOM, TOP) cylinder(h=mchead_bottom_height, r=mchead_large_diameter / 2);
    //In David's original design the slot is created in shapr3d by a fillet with a mysterious curvature parameter. I have no idea how to replicate that so here's a circle. Difference in geometry is negligible.
    if (top_pattern == "coin_slot")
      down(4 - connector_coin_slot_height) xrot(90) cyl(r=connector_coin_slot_radius, h=connector_coin_slot_thickness, $fn=128, anchor=BACK);
    if (top_pattern == "dimple")
      down(4) cyl(d1=2, d2=0.01, h=1, $fn=128, anchor=BOTTOM);
  }
}
//BEGIN openConnect slot parameters
tile_size = 28;
opengrid_snap_to_edge_offset = (tile_size - 24.8) / 2;

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

ochead_bottom_profile = back(ochead_large_rect_width / 2, rect([ochead_large_rect_width, ochead_large_rect_height], chamfer=[ochead_large_rect_chamfer, ochead_large_rect_chamfer, 0, 0], anchor=BACK));
ochead_top_profile = back(ochead_small_rect_width / 2, rect([ochead_small_rect_width, ochead_small_rect_height], chamfer=[ochead_small_rect_chamfer, ochead_small_rect_chamfer, 0, 0], anchor=BACK));
ochead_total_height = ochead_top_height + ochead_middle_height + ochead_bottom_height;
ochead_middle_to_bottom = ochead_large_rect_height - ochead_large_rect_width / 2;

ochead_side_profile = [
  [0, 0],
  [ochead_large_rect_width / 2, 0],
  [ochead_large_rect_width / 2, ochead_bottom_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height + ochead_top_height],
  [0, ochead_bottom_height + ochead_middle_height + ochead_top_height],
];


ocslot_move_distance = 11; //0.1
ocslot_onramp_clearance = 0.8;
ocslot_bridge_offset = 0.4;
ocslot_side_clearance = 0.15;
ocslot_depth_clearance = 0.12;

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
ocslot_top_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width, ocslot_small_rect_height], chamfer=[ocslot_small_rect_chamfer, ocslot_small_rect_chamfer, 0, 0], anchor=BACK));
ocslot_bottom_profile = back(ocslot_large_rect_width / 2, rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));

ocslot_side_profile = [
  [0, 0],
  [ocslot_large_rect_width / 2, 0],
  [ocslot_large_rect_width / 2, ocslot_bottom_height],
  [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height],
  [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height + ocslot_top_height],
  [0, ocslot_bottom_height + ochead_middle_height + ocslot_top_height],
];

vase_linewidth = 0.6;
vase_wall_thickness = vase_linewidth * 2;
vase_tilt_offset_angle = 0;

ocvase_small_rect_width = ocslot_small_rect_width + vase_wall_thickness * 2;
ocvase_small_rect_height = ocslot_small_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + vase_tilt_offset_angle, ocslot_total_height);
ocvase_small_rect_chamfer = ocslot_small_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_large_rect_width = ocslot_large_rect_width + vase_wall_thickness * 2;
ocvase_large_rect_height = ocslot_large_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + vase_tilt_offset_angle, ocslot_total_height);
ocvase_large_rect_chamfer = ocslot_large_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_middle_to_bottom = ocvase_large_rect_height - ocvase_large_rect_width / 2;

ocvase_nub_to_top_distance = ocslot_nub_to_top_distance + vase_wall_thickness * 1.5;
ocvase_bottom_height = ocslot_bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_top_height = ocslot_top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_total_height = ocvase_top_height + ochead_middle_height + ocvase_bottom_height;
ocvase_top_profile = back(ocvase_small_rect_width / 2, rect([ocvase_small_rect_width, ocvase_small_rect_height], chamfer=[ocvase_small_rect_chamfer, ocvase_small_rect_chamfer, 0, 0], anchor=BACK));
ocvase_bottom_profile = back(ocvase_large_rect_width / 2, rect([ocvase_large_rect_width, ocvase_large_rect_height], chamfer=[ocvase_large_rect_chamfer, ocvase_large_rect_chamfer, 0, 0], anchor=BACK));

//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = "both", nub_flattop = true, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : head_type == "vase" ? ocvase_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : head_type == "vase" ? ocvase_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : head_type == "vase" ? ocvase_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : head_type == "vase" ? ocvase_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : head_type == "vase" ? ocvase_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : head_type == "vase" ? ocvase_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : head_type == "vase" ? ocvase_nub_to_top_distance : ochead_nub_to_top_distance;
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
module openconnect_slot(add_nubs = "left", slot_direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_width, ocslot_total_height]) {
    tag_scope() down(ocslot_total_height / 2) union() {
          if (slot_direction_flip)
            xflip() ocslot_body(excess_thickness);
          else
            ocslot_body(excess_thickness);
        }
    children();
  }
  module ocslot_body(excess_thickness = 0) {
    ocslot_side_excess_profile = [
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
      xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_excess_profile);
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
module openconnect_vase_slot(add_nubs = "", anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocvase_large_rect_width, ocvase_large_rect_width, ocvase_total_height]) {
    tag_scope()
      diff(remove="remove")
        down(ocvase_total_height / 2) {
          tag("") openconnect_head(head_type="vase", add_nubs=add_nubs, nub_flattop=false);
          tag("remove") openconnect_head(head_type="slot", add_nubs=add_nubs, nub_flattop=false);
          tag("remove") cuboid([ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ocslot_large_rect_height, ocslot_total_height], anchor=FRONT + BOTTOM);
          fwd(ocvase_middle_to_bottom) xrot(-(45 + vase_tilt_offset_angle))
              tag("remove") cuboid([ocvase_large_rect_width + eps, 20, 20], anchor=BACK + BOTTOM);
          xrot(90) up(ocslot_middle_to_bottom)
              force_tag("remove") linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_profile);
          up(ocslot_total_height)
            tag("remove") cuboid([50, 50, 50], anchor=BOTTOM);
        }
    children();
  }
}
module openconnect_slot_grid(grid_type = "slot", horizontal_grids = 1, vertical_grids = 1, tile_size = 28, slot_lock_distribution = "None", slot_direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  grid_height = grid_type == "slot" ? ocslot_total_height : ocvase_total_height;
  attachable(anchor, spin, orient, size=[horizontal_grids * tile_size, vertical_grids * tile_size, grid_height]) {
    tag_scope() hide_this() cuboid([horizontal_grids * tile_size, vertical_grids * tile_size, grid_height]) {
          back(opengrid_snap_to_edge_offset) {
            if (slot_lock_distribution == "All" || slot_lock_distribution == "Staggered" || slot_lock_distribution == "None")
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger=slot_lock_distribution == "Staggered")
                attach(BOTTOM, BOTTOM, inside=true) {
                  if (grid_type == "slot")
                    openconnect_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? "left" : "", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                  else
                    openconnect_vase_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? "left" : "");
                }
            if (slot_lock_distribution == "Staggered")
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger="alt")
                attach(BOTTOM, BOTTOM, inside=true) {
                  if (grid_type == "slot")
                    openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                  else
                    openconnect_vase_slot(add_nubs="left");
                }
            if (slot_lock_distribution == "Corners" || slot_lock_distribution == "Top Corners") {
              if (slot_lock_distribution == "Corners")
                grid_copies([tile_size * max(1, horizontal_grids - 1), tile_size * max(1, vertical_grids - 1)], [min(horizontal_grids, 2), min(vertical_grids, 2)])
                  attach(BOTTOM, BOTTOM, inside=true) {
                    if (grid_type == "slot")
                      openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                    else
                      openconnect_vase_slot(add_nubs="left");
                  }
              else {
                back(tile_size * (vertical_grids - 1) / 2)
                  line_copies(spacing=tile_size * max(1, horizontal_grids - 1), n=min(2, horizontal_grids))
                    attach(BOTTOM, BOTTOM, inside=true) {
                      if (grid_type == "slot")
                        openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                      else
                        openconnect_vase_slot(add_nubs="left");
                    }
              }
              omit_edge_rows =
                slot_lock_distribution == "Corners" ? [0, vertical_grids - 1]
                : slot_lock_distribution == "Top Corners" ? [0] : [];
              for (i = [0:1:vertical_grids - 1]) {
                back(tile_size * (vertical_grids - 1) / 2) fwd(tile_size * i) {
                    if (in_list(i, omit_edge_rows)) {
                      if (horizontal_grids > 2)
                        line_copies(spacing=tile_size, n=horizontal_grids - 2)
                          attach(BOTTOM, BOTTOM, inside=true) {
                            if (grid_type == "slot")
                              openconnect_slot(add_nubs="left", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                            else
                              openconnect_vase_slot(add_nubs="left");
                          }
                    }
                    else
                      line_copies(spacing=tile_size, n=horizontal_grids)
                        attach(BOTTOM, BOTTOM, inside=true) {
                          if (grid_type == "slot")
                            openconnect_slot(add_nubs="", slot_direction_flip=slot_direction_flip, excess_thickness=excess_thickness);
                          else
                            openconnect_vase_slot(add_nubs="");
                        }
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
// text_depth = 0.4;
// add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
// fold_gap_width = 0.4;
// fold_gap_height = 0.2;
// connector_coin_slot_height = 2.6;
// connector_coin_slot_width = 13;
// connector_coin_slot_thickness = 2.4;
// connector_coin_slot_radius = connector_coin_slot_height / 2 + connector_coin_slot_width ^ 2 / (8 * connector_coin_slot_height);

// /* [Threads Settings] */
// threads_diameter = 16;
// threads_clearance = 0.5;
// threads_compatiblity_angle = 53.5;
// threads_rotate_angle = 45;
// threads_top_bevel = 0.5; //0.1
// threads_bottom_bevel_standard = 2; //0.1
// threads_bottom_bevel_lite = 1.2; //0.1
// threads_negative_diameter = threads_diameter + threads_clearance;

// threads_profile = [
//   [-1.25 / 3, -1 / 3],
//   [-0.25 / 3, 0],
//   [0.25 / 3, 0],
//   [1.25 / 3, -1 / 3],
// ];

// add_threads_blunt_end_text = true;
// threads_blunt_end_text = "🔓";
// threads_blunt_end_text_font = "Noto Emoji"; // font
// threads_pitch = 3;

// final_add_thickness_text =
//   add_thickness_text == "None" ? false
//   : add_thickness_text == "All" ? true
//   : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
//   : false;

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
module main_generate() {
  if (generate_snap != "None")
    zrot(view_snap_rotated)
      snap();
  if (generate_screw == "multiConnect")
    left(generate_snap == "None" || view_snap_and_connector_overlapped ? 0 : 28) up(view_snap_and_connector_overlapped ? 0 : mchead_total_height) zrot(view_connector_rotated)
          multiconnect_screw();
  if (generate_screw == "openConnect" || generate_screw == "openConnect (Folded)")
    right(generate_snap == "None" || view_snap_and_connector_overlapped ? 0 : 28) fwd(view_snap_and_connector_overlapped && generate_screw == "openConnect (Folded)" ? ochead_middle_to_bottom : 0)
        down(!view_snap_and_connector_overlapped ? 0 : generate_screw == "openConnect (Folded)" ? ochead_total_height : -snap_thickness)
          zrot(view_connector_rotated) xrot(!view_snap_and_connector_overlapped ? 0 : generate_screw == "openConnect (Folded)" ? -90 : -180)
              zrot(view_snap_and_connector_overlapped || generate_screw == "openConnect (Folded)" ? 180 : 0) openconnect_screw(threads_height=snap_thickness, folded=generate_screw == "openConnect (Folded)");
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
