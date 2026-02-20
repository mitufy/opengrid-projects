/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/
include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <util_lib.scad>

uninstall_notch_width = 5; //0.2

add_thickness_text = "Uncommon"; //[All, Uncommon, None]
text_depth = 0.4;
threads_offset_angle = 0; //[0:15:345]

// /* [Snap Body Settings] */
snap_body_width = 24.8;

//Offset connector head/threads position, in x and y.
snap_center_position_offset = [0, 0];

snap_corner_edge_height = 1.5;
snap_body_top_corner_extrude = 1.1;
snap_body_bottom_corner_extrude = 0.6;

directional_slant_depth_standard = 0.8;
directional_slant_depth_lite = 0.2;
directional_corner_fillet_radius = 1.5;
directional_arrow_depth = 0.2;

// /* [Snap Nub Settings] */
basic_nub_width = 10.8;
basic_nub_height_standard = 2;
basic_nub_height_lite = 1.8;
basic_nub_depth = 0.4;
basic_nub_top_width = 6.8;
basic_nub_top_angle = 35;
basic_nub_bottom_angle = 35;
basic_nub_fillet_radius = 15;

directional_nub_width = 14.8;
directional_nub_height_standard = 4;
directional_nub_height_lite = 2.4;
directional_nub_depth = 0.8;
directional_nub_top_width = 13.2;
directional_nub_top_angle = 35;
directional_nub_bottom_angle_standard = 35;
directional_nub_bottom_angle_lite = 45;
directional_nub_fillet_radius = 2.8;

antidirect_nub_height_standard = 2;
antidirect_nub_height_lite = 1.4;

nub_offset_to_top = 1.4;

// /* [Snap Cut Settings] */
back_cut_length = 12.4;
back_cut_thickness = 0.6;
back_cut_offset_to_top = 0.6;
back_cut_offset_to_edge = 0.7;

side_cut_thickness = 0.4;
side_cut_depth = 0.8;
side_cut_offset_to_top = 0.8;

directional_slant_height_standard = 3.4;
directional_slant_height_lite = 1.2;

// /* [Expanding Snap Advanced Settings] */
uninstall_notch_surface_inset = 1;
uninstall_notch_gap_inset = 1.8;
uninstall_notch_surface_height_standard = 1.2;
uninstall_notch_surface_height_lite = 0.8;
uninstall_notch_gap_height_standard = 1;
uninstall_notch_gap_height_lite = 0.6;

snap_body_corner_outer_diagonal = 2.7 + 1 / sqrt(2);
snap_body_corner_chamfer = snap_body_corner_outer_diagonal * sqrt(2);
snap_body_corner_inner_diagonal = snap_body_width * sqrt(2) / 2 - snap_body_corner_outer_diagonal;

corner_anchors = [FRONT + LEFT, FRONT + RIGHT, BACK + LEFT, BACK + RIGHT];
side_anchors = [FRONT, LEFT, RIGHT, BACK];

module snap_corner(snap_thickness, snap_base_shape) {
  down(snap_thickness / 2 - snap_corner_edge_height / 2) {
    for (i = corner_anchors) {
      attach(i, BOTTOM, shiftout=-snap_body_corner_outer_diagonal - eps)
        prismoid(size1=[snap_body_corner_chamfer * sqrt(2), snap_corner_edge_height], xang=45, yang=[90, 45], h=snap_body_top_corner_extrude);
    }
  }
  //bottom corners for directional full snaps
  if (snap_base_shape == "Directional" && snap_thickness >= 6.8) {
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
module snap_cut(snap_thickness, snap_base_shape) {
  directional_slant_height = max(snap_thickness - nub_offset_to_top - (snap_thickness >= 6.8 ? antidirect_nub_height_standard : antidirect_nub_height_lite), eps);
  directional_slant_depth = snap_thickness >= 6.8 ? directional_slant_depth_standard : directional_slant_depth_lite;
  directional_corner_slant_depth = directional_slant_depth / sqrt(2);
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
      //make the slanted side cut
      tag_diff("remove", "inner_remove") {
        //the triangle used for cutting
        attach(FRONT, FRONT, inside=true, shiftout=-back_cut_offset_to_edge - back_cut_thickness)
          tag("") prismoid(size2=[back_cut_length, directional_slant_depth], size1=[back_cut_length, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
        //the triangle used for cutting the triangle used for cutting
        attach(FRONT, FRONT, inside=true, shiftout=-back_cut_offset_to_edge)
          tag("inner_remove") prismoid(size2=[back_cut_length, directional_slant_depth], size1=[back_cut_length, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
      }
      //fill the outer wall. the keep tag makes resulting shape invulnerable to diff()
      tag_diff("keep", "inner_remove") {
        attach(FRONT, FRONT, inside=true, shiftout=-back_cut_offset_to_edge)
          tag("") prismoid(size2=[back_cut_length, directional_slant_depth], size1=[back_cut_length, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
        attach(FRONT, FRONT, inside=true)
          tag("inner_remove") prismoid(size2=[snap_body_width, directional_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
      }
      //cutoff the rest of the slant
      attach(FRONT + LEFT, FRONT, inside=true, shiftout=-snap_body_corner_outer_diagonal)
        prismoid(size2=[snap_body_width, directional_corner_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_corner_slant_depth / 2], h=directional_slant_height);
      attach(FRONT + RIGHT, FRONT, inside=true, shiftout=-snap_body_corner_outer_diagonal)
        prismoid(size2=[snap_body_width, directional_corner_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_corner_slant_depth / 2], h=directional_slant_height);
      attach(FRONT, FRONT, inside=true)
        prismoid(size2=[snap_body_width, directional_slant_depth], size1=[snap_body_width, 0], shift=[0, directional_slant_depth / 2], h=directional_slant_height);
    }
  }
}
module snap_nub(snap_thickness, snap_base_shape) {
  //nub paramters
  basic_nub_height =
    snap_thickness >= 6.8 ? basic_nub_height_standard
    : basic_nub_height_lite;
  directional_nub_height =
    snap_thickness >= 6.8 ? directional_nub_height_standard
    : directional_nub_height_lite;
  antidirect_nub_height =
    snap_thickness >= 6.8 ? antidirect_nub_height_standard
    : antidirect_nub_height_lite;
  directional_nub_bottom_angle =
    snap_thickness >= 6.8 ? directional_nub_bottom_angle_standard
    : directional_nub_bottom_angle_lite;
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

module snap_uninstall_notch(snap_thickness, anchor = BOTTOM, spin = 0, orient = UP) {
  uninstall_notch_surface_height =
    snap_thickness >= 6.8 ? uninstall_notch_surface_height_standard
    : uninstall_notch_surface_height_lite;
  uninstall_notch_gap_height =
    snap_thickness >= 6.8 ? uninstall_notch_gap_height_standard
    : uninstall_notch_gap_height_lite;
  cuboid([uninstall_notch_width, uninstall_notch_surface_inset, uninstall_notch_surface_height], anchor=anchor, spin=spin, orient=orient)
    attach(TOP, BOTTOM, align=FRONT)
      cuboid([uninstall_notch_width, uninstall_notch_gap_inset, uninstall_notch_gap_height])
        //cut off remaining snap extrusion
        attach(FRONT, BACK, align=TOP)
          cuboid([uninstall_notch_width, uninstall_notch_gap_inset, uninstall_notch_gap_height]);
}

module bare_snap(snap_thickness = 6.8, snap_base_shape = "Directional") {
  up(snap_thickness) yrot(180)
      diff() {
        cuboid([snap_body_width, snap_body_width, snap_thickness], chamfer=snap_body_corner_chamfer, edges="Z", anchor=BOTTOM) {
          snap_corner(snap_thickness=snap_thickness, snap_base_shape=snap_base_shape);
          snap_nub(snap_thickness=snap_thickness, snap_base_shape=snap_base_shape);
          snap_cut(snap_thickness=snap_thickness, snap_base_shape=snap_base_shape);
          if (uninstall_notch_width > eps)
            attach(BOTTOM, BOTTOM, align=FRONT, shiftout=eps, inside=true)
              tag("remove") snap_uninstall_notch(snap_thickness=snap_thickness);
        }
        //arrow
        if (snap_base_shape == "Directional")
          zrot(-90) up(snap_thickness + eps / 2) left(snap_body_width / 2 - 1.1) zrot(180)
                  tag("remove") regular_prism(3, side=3.3, h=directional_arrow_depth + eps, chamfer1=directional_arrow_depth, anchor=RIGHT + TOP);
      }
}

bare_snap(snap_thickness=10,snap_base_shape = "Directional");
