/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Recommended to use with openGrid - Self-Expanding Snap. https://www.printables.com/model/1294247-opengrid-self-expanding-snap
The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <lib/opengrid_base.scad>
include <BOSL2/threading.scad>
use <lib/opengrid_threads_lib.scad>

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol.
threads_type = "Blunt"; //["Blunt", "Basic"]
plier_count = 1;

/* [Main Settings] */
stem_top_width = 2; //0.4
stem_bottom_width = 10; //0.4
stem_height = 8; //0.4
//This value includes the depth of the transition part.
stem_depth = 12; //0.4
//Set to 1 to merge stem and stopper into a slope.
transition_depth_ratio = 0.2; //[0:0.1:1]
//Stopper is the front part of the holder which prevents the plier from sliding off. 
stopper_width_scale = 1; //[0.5:0.1:2]
stopper_height_scale = 1.4; //[0.5:0.1:2]

add_spring_hole = false;
spring_hole_radius = 2.6;
spring_hole_position_offset = 0;

/* [Advanced Settings] */
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]
stopper_depth = 3;
stopper_front_rounding = 0.4; //0.2
stem_top_rounding = 0.8; //0.2
stem_bottom_rounding = 0.8; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.2;

holder_tilt_angle = 0; //[0:5:45]

_add_blunt_text = threads_type == "Blunt";
_add_thickness_text = thickness_text_mode == "All" || (thickness_text_mode == "Uncommon" && snap_thickness != OG_LITE_BASIC_THICKNESS && snap_thickness != OG_STANDARD_THICKNESS);

_snaptext_texts = [if (_add_blunt_text) OG_SNAP_BLUNT_TEXT, if (_add_thickness_text) str(floor(snap_thickness))];
_snaptext_sizes = [if (_add_blunt_text) 4, if (_add_thickness_text) 4.5];
_snaptext_fonts = [if (_add_blunt_text) OG_SNAP_EMOJI_FONT, if (_add_thickness_text) OG_SNAP_TEXT_FONT];
_snaptext_fills = [if (_add_blunt_text) true, if (_add_thickness_text) false];
_snaptext_pos = [if (_add_blunt_text) [_add_thickness_text ? 2.4 : 0, 0], if (_add_thickness_text) [-(_add_blunt_text ? 2.4 : 0), 0]];

text_depth = 0.4;
_text_cfg = text_cfg(texts=_snaptext_texts, sizes=_snaptext_sizes, fonts=_snaptext_fonts, fills=_snaptext_fills, pos_offsets=_snaptext_pos, text_depth=text_depth);

_threads_cfg = threads_cfg(
  threads_type=threads_type
);
_threads_diameter = struct_val(_threads_cfg, "threads_diameter");
_threads_pitch = struct_val(_threads_cfg, "threads_pitch");

tilt_angle_back_offset = ang_adj_to_opp(holder_tilt_angle, _threads_diameter / 2 - 1);
stem_base_depth = stem_depth * (1 - transition_depth_ratio) + tilt_angle_back_offset;
stem_transition_depth = stem_depth * transition_depth_ratio;

_threads_connect_diameter = _threads_diameter - 1.5;
_threads_side_offset = _threads_diameter / 2 - 1.4;

final_stem_top_width = max(EPS, min(stem_bottom_width, stem_top_width));
plier_prismoid_top_rounding = max(EPS, min(stem_top_rounding, final_stem_top_width, stem_height / 2));
plier_prismoid_bottom_rounding = max(EPS, min(stem_bottom_rounding, stem_bottom_width / 2, stem_height / 2));
plier_prismoid_side_angle = opp_adj_to_ang((stem_bottom_width - final_stem_top_width) / 2, stem_height);
stopper_side_angle = opp_adj_to_ang((stem_bottom_width - final_stem_top_width) * stopper_width_scale / 2, stem_height * stopper_height_scale);
//align to front and bottom
zrot(180) up(_threads_side_offset) xrot(90) {
      fwd(_threads_side_offset) zrot(180) xrot(90) ycopies(n=plier_count, spacing=-stem_depth - stopper_depth + stopper_front_rounding, sp=[0, 0, 0])
              diff(remove="root_rm") {
                diff() prismoid(size1=[stem_bottom_width, max(eps, stem_base_depth)], size2=[final_stem_top_width, max(eps, stem_base_depth)], h=stem_height, anchor=BACK + BOTTOM) {
                    edge_profile([BOTTOM + LEFT, BOTTOM + RIGHT], excess=2)
                      mask2d_teardrop(r=plier_prismoid_bottom_rounding, mask_angle=90 - plier_prismoid_side_angle);
                    edge_mask([TOP + LEFT, TOP + RIGHT])
                      rounding_edge_mask(l=$edge_length, r=plier_prismoid_top_rounding);
                  }
                fwd(max(eps, stem_base_depth))
                  hull() {
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
                if (add_spring_hole)
                  up(stem_height + stem_height * (stopper_height_scale - 1) * max(0, (transition_depth_ratio - 0.5)))
                    fwd(stem_depth / 2 + spring_hole_position_offset)
                      tag("root_rm") xcyl(h=20, r=spring_hole_radius);
              }

      diff() {
        fwd(ang_hyp_to_opp(holder_tilt_angle, snap_thickness))
          snap_threads(threads_height=snap_thickness, threads_cfg=_threads_cfg, text_cfg=_text_cfg);
        tag("remove") fwd(_threads_side_offset) cuboid([500, 500, 500], anchor=BACK);
      }
    }
