/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]
//Blunt end helps prevent cross-threading and overtightening. Models with blunt ends have a decorative 'lock' symbol at the bottom.
threads_end_type = "Blunt"; //["Blunt", "Basic"]
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
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
stopper_depth = 3;
stopper_front_rounding = 0.4; //0.2
stem_top_rounding = 0.8; //0.2
stem_bottom_rounding = 0.8; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.2;
eps = 0.005;

holder_tilt_angle = 0; //[0:5:45]
add_threads_blunt_end_text = true;
threads_blunt_end_text = "🔓";
threads_blunt_end_text_font = "Noto Emoji"; // font
threads_pitch = 3;

threads_offset_angle = 0;
threads_side_slice_off = 1.4; //0.1

threads_compatiblity_angle = 53.5;
threads_diameter = 16;
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1

//thread parameters
threads_bottom_bevel =
  snap_thickness == 6.8 ? threads_bottom_bevel_standard
  : threads_bottom_bevel_lite;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

tilt_angle_back_offset = ang_adj_to_opp(holder_tilt_angle, threads_diameter / 2 - 1);
stem_base_depth = stem_depth * (1 - transition_depth_ratio) + tilt_angle_back_offset;
stem_transition_depth = stem_depth * transition_depth_ratio;

threads_connect_diameter = threads_diameter - 1.5;
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
//align to front and bottom
zrot(180) up(threads_offset) xrot(90) {
      fwd(threads_offset) zrot(180) xrot(90) ycopies(n=plier_count, spacing=-stem_depth - stopper_depth + stopper_front_rounding, sp=[0, 0, 0])
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
        // down(ang_adj_to_opp(holder_tilt_angle, threads_diameter / 2 - 1))
        fwd(ang_hyp_to_opp(holder_tilt_angle, snap_thickness))
          // xrot(-holder_tilt_angle)
          //   back(threads_side_slice_off - 1)
          zrot(threads_offset_angle) {
            zrot(threads_compatiblity_angle) {
              if (threads_end_type == "Blunt")
                blunt_threaded_rod(diameter=threads_diameter, rod_height=snap_thickness, top_cutoff=true);
              else
                generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=threads_pitch, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
            }
            if (add_threads_blunt_end_text && threads_end_type == "Blunt")
              up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0)
                  tag("remove") linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_end_text, size=4, anchor=str("center", CENTER), font=threads_blunt_end_text_font);
            if (final_add_thickness_text)
              up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_end_text && threads_end_type == "Blunt" ? 2.4 : 0)
                  tag("remove") linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
          }
        tag("remove") fwd(threads_offset) cuboid([500, 500, 500], anchor=BACK);
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
