/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_version = "Lite Strong"; //[Full:Full - 6.8mm, Lite Strong:Lite Strong - 4mm, Lite Basic:Lite Basic - 3.4mm]

/* [Main Options] */
stem_top_width = 2; //0.4
stem_bottom_width = 10; //0.4
stem_height = 8; //0.4
//This value includes the depth of the transition part.
stem_depth = 12; //0.4
//Set to 1 to merge stem and stopper into a slope.
transition_depth_ratio = 0.2; //[0:0.1:1]
//Stopper is the front part of the holder that stops the plier from sliding off. 
stopper_width_scale = 1; //[0.5:0.1:2]
stopper_height_scale = 1.5; //[0.5:0.1:2]

/* [Advanced Options] */
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
stopper_depth = 3;
stopper_front_rounding = 1; //0.2
stem_top_rounding = 1; //0.2
stem_bottom_rounding = 1; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.2;
eps = 0.005;

threads_offset_angle = 0;
threads_side_slice_off = 1.4; //0.1

threads_compatiblity_angle = 53.5;
threads_diameter = 16;
threads_bottom_bevel_full = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1

snap_thickness =
  snap_version == "Full" ? 6.8
  : snap_version == "Lite Strong" ? 4
  : 3.4;

//thread parameters
threads_bottom_bevel =
  snap_version == "Full" ? threads_bottom_bevel_full
  : threads_bottom_bevel_lite;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

stem_base_depth = stem_depth * (1 - transition_depth_ratio);
stem_transition_depth = stem_depth * transition_depth_ratio;

threads_connect_diameter = threads_diameter - 1.8;
threads_offset = threads_diameter / 2 - threads_side_slice_off;

//text parameters
text_depth = 0.4;
final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

final_stem_top_width = max(eps, min(stem_bottom_width, stem_top_width));
plier_prismoid_top_rounding = max(eps, min(stem_top_rounding, final_stem_top_width, stem_height / 2));
plier_prismoid_bottom_rounding = max(eps, min(stem_bottom_rounding, stem_bottom_width / 2, stem_height / 2));
plier_prismoid_side_angle = opp_adj_to_ang((stem_bottom_width - final_stem_top_width) / 2, stem_height);
stopper_side_angle = opp_adj_to_ang((stem_bottom_width - final_stem_top_width) * stopper_width_scale / 2, stem_height * stopper_height_scale);

fwd(threads_offset) zrot(180) xrot(90) {
      diff() prismoid(size1=[stem_bottom_width, max(eps, stem_base_depth)], size2=[final_stem_top_width, max(eps, stem_base_depth)], h=stem_height, anchor=BACK + BOTTOM) {
          edge_profile([BOTTOM + LEFT, BOTTOM + RIGHT], excess=2)
            mask2d_teardrop(r=plier_prismoid_bottom_rounding, mask_angle=90 - plier_prismoid_side_angle);
          edge_mask([TOP + LEFT, TOP + RIGHT])
            rounding_edge_mask(l=$edge_length, r=plier_prismoid_top_rounding);
        }
      fwd(max(eps, stem_base_depth)) hull() {
          diff() prismoid(size1=[stem_bottom_width, 0.1], size2=[final_stem_top_width, 0.1], h=stem_height, anchor=BACK + BOTTOM) {
              edge_profile([BOTTOM + LEFT, BOTTOM + RIGHT], excess=3)
                mask2d_teardrop(r=plier_prismoid_bottom_rounding, mask_angle=90 - plier_prismoid_side_angle);
              edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=$edge_length, r=plier_prismoid_top_rounding);
            }
          fwd(stem_transition_depth)
            diff() prismoid(size1=[stem_bottom_width * stopper_width_scale, stopper_depth], size2=[final_stem_top_width * stopper_width_scale, stopper_depth], h=stem_height * stopper_height_scale, anchor=BACK + BOTTOM) {
                edge_profile([BOTTOM + LEFT, BOTTOM + RIGHT], excess=3)
                  mask2d_teardrop(r=plier_prismoid_bottom_rounding * stopper_width_scale, mask_angle=90 - stopper_side_angle);
                edge_mask([TOP + LEFT, TOP + RIGHT])
                  rounding_edge_mask(l=$edge_length + 2, r=plier_prismoid_top_rounding * stopper_width_scale);
                edge_mask([TOP + FRONT])
                  rounding_edge_mask(l=$edge_length + 2, r=max(eps, stopper_front_rounding));
                edge_mask([BOTTOM + FRONT], except=BACK)
                  teardrop_edge_mask(l=$edge_length + 2, r=max(eps, stopper_front_rounding));
                edge_mask([FRONT + RIGHT])
                  yrot(-stopper_side_angle) rounding_edge_mask(l=$edge_length + 2, r=max(eps, stopper_front_rounding));
                edge_mask([FRONT + LEFT])
                  yrot(stopper_side_angle) rounding_edge_mask(l=$edge_length + 2, r=max(eps, stopper_front_rounding));
              }
        }
    }

diff() {
  zrot(threads_compatiblity_angle + threads_offset_angle)
    generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=3, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
  if (final_add_thickness_text)
    tag("remove") up(snap_thickness - text_depth + eps / 2)
        linear_extrude(height=text_depth + eps) text(str(snap_thickness), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
  tag("remove") fwd(threads_offset) cuboid([500, 500, 500], anchor=BACK);
}
