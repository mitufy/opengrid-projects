/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Recommended to use with openGrid - Self-Expanding Snap. https://www.printables.com/model/1294247-opengrid-self-expanding-snap
The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/rounding.scad>

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol at the bottom.
threads_type = "Blunt"; //["Blunt", "Basic"]
clip_shape = "Circular"; //["Circular", "Rectangular","Elliptic"]
//Decides the state of the clip when completely screwed in.
clip_orientation = "Horizontal"; //["Horizontal", "Vertical"]
//Inner width of the clip.
clip_main_width = 25;
//Inner depth of the clip. Doesn't affect Circular clips as their depth would be same as the width.
clip_main_depth = 15;

/* [Main Settings] */
//180 means the clip would be completely closed.
clip_surround_angle = 130; //[90:5:180]
//Changes which side the clip entry would face, often used with Vertical clips. Non-Circular shapes only support 90 degree rotation.
clip_entry_tilt_angle = 0; //[-90:15:90]
//Thickness of the clip body. Note that flexiblity of the clip depends not only on thickness, but also wall loops and filament.
clip_thickness = 2.6; //0.2
//The scaling of clip thickness. 0.6 means thickness at the end would be 60% of the beginning.
clip_thickness_scale = 0.6; //[0.1:0.1:1]
//The tip making it easier to putting the object in. Set this value to 0 to disable it.
tip_diameter = 4; //1

/* [Knurling Settings] */
//Add knurling to increase friction of the clip.
knurling_type = "None"; //["None", "Diamond", "Line"]
knurling_texture_size = 4;
knurling_texture_depth = 1; //0.2

/* [Advanced Settings] */
//Height of the clip body. The value for complete symmetry is 13.2.
clip_height = 13.2; //0.2
//A stem to offset the clip from the board. Useful for holding hourglass-shaped items, for example.
clip_stem_length = 0;
//Only affects clips of Rectangular shape.
clip_rect_rounding = 3; //1
tip_angle = 180; //[90:15:270]
//Side chamfer is automatically clamped to ensure a sufficiently large print surface.
body_side_chamfer = 0.8; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
add_thickness_text = "Uncommon Only"; //[All, Uncommon Only, None]
add_threads_blunt_text = true;
threads_blunt_text = "🔓";
threads_blunt_text_font = "Noto Emoji"; // font
threads_pitch = 3;

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

threads_connect_diameter = threads_diameter - 1.5;
threads_offset = threads_diameter / 2 - threads_side_slice_off;
threads_offset_angle = clip_orientation == "Horizontal" ? 0 : 90;

//text parameters
text_depth = 0.4;
final_add_thickness_text =
  add_thickness_text == "None" ? false
  : add_thickness_text == "All" ? true
  : add_thickness_text == "Uncommon Only" && snap_thickness != 3.4 && snap_thickness != 6.8 ? true
  : false;

symmetric_clip_height = 13.2;
final_tip_diameter = max(eps, clip_thickness * clip_thickness_scale + 1, tip_diameter);
final_side_chamfer = max(0, min(clip_thickness / 2 * clip_thickness_scale - 0.84, clip_height / 2 - 0.84, body_side_chamfer));

tip_path = ["arcleft", final_tip_diameter / 2, tip_angle];
circular_clip_path = ["arcright", clip_main_width / 2 + clip_thickness / 2, clip_surround_angle];

//unimplemented customizable inner angle for rect holders
clip_rect_inner_angle = 90; //[0:15:180]

final_clip_rect_rounding = max(eps, min((clip_main_width + clip_thickness) / 2, (clip_main_depth + clip_thickness) / 2, clip_rect_rounding));
final_clip_inner_width = max(eps, clip_main_width / 2 + clip_thickness / 2 - final_clip_rect_rounding);
final_clip_outer_width = max(eps, (clip_main_width / 2 + clip_thickness / 2) * (clip_surround_angle - 90) / 90 - final_clip_rect_rounding);
final_clip_side_depth = max(eps, (clip_main_depth + clip_thickness - final_clip_rect_rounding * 2));

rect_clip_threshold_angle = 90 + (final_clip_rect_rounding * 2) / (clip_main_width / 2 + clip_thickness / 2 + final_clip_rect_rounding * 2) * 90;
rect_clip_has_bottom = clip_surround_angle >= rect_clip_threshold_angle;

clip_rect_nub_angle = 10; //[0:5:90]
rect_path_first_part = ["move", final_clip_inner_width, "arcright", final_clip_rect_rounding, 90, "move", final_clip_side_depth];
rect_path_bottom_corner = ["arcright", final_clip_rect_rounding, clip_surround_angle <= 90 ? 0 : min(90, 90 - (rect_clip_threshold_angle - clip_surround_angle))];
rect_path_bottom_width = ["move", final_clip_outer_width];

temp_rect_path =
  clip_surround_angle == 90 ? concat(rect_path_first_part, rect_path_bottom_corner, rect_clip_has_bottom ? rect_path_bottom_width : [])
  : concat(rect_path_first_part, rect_path_bottom_corner, rect_clip_has_bottom ? rect_path_bottom_width : []);
rect_side_ratio = path_length(turtle(["move", final_clip_side_depth])) / path_length(turtle(temp_rect_path));
rect_offset_angle = opp_adj_to_ang(clip_thickness * (1 - clip_thickness_scale) * rect_side_ratio / 2, final_clip_side_depth);

rect_path_part1 = ["move", final_clip_inner_width, "arcright", final_clip_rect_rounding, 90 + rect_offset_angle, "move", final_clip_side_depth];
elliptic_ratio = clip_shape == "Elliptic" ? (clip_main_depth + clip_thickness) / (clip_main_width + clip_thickness) : 1;
elliptic_clip_path = scale([1, elliptic_ratio, 1], fwd(clip_main_width / 2 + clip_thickness / 2, arc(r=clip_main_width / 2 + clip_thickness / 2, angle=-clip_surround_angle, start=90)));

final_clip_path =
  clip_shape == "Circular" ? turtle(circular_clip_path)
  : clip_shape == "Rectangular" ? turtle(concat(rect_path_part1, rect_path_bottom_corner, rect_clip_has_bottom ? rect_path_bottom_width : []))
  : elliptic_clip_path;

knurling_outer_offset = 0;

clip_profile = rect([clip_thickness, clip_height], chamfer=final_side_chamfer);
final_clip_entry_tilt_angle = (clip_shape == "Circular" || abs(clip_entry_tilt_angle) == 90) ? clip_entry_tilt_angle : 0;
tip_rounding_radius = max(0, min(clip_thickness * clip_thickness_scale - final_side_chamfer * 2, clip_height - final_side_chamfer * 2) / 2 - eps);
connect_cuboid_height =
  clip_shape == "Circular" || (clip_shape == "Elliptic" && abs(final_clip_entry_tilt_angle) == 90) ? clip_main_width / 2 + clip_thickness
  : clip_main_depth / 2;
//align to front and bottom
zrot(180) xrot(90) back(threads_offset)
      //main diff
      diff() {
        zrot(threads_offset_angle) {
          zrot(threads_compatiblity_angle) {
            if (threads_type == "Blunt")
              blunt_threaded_rod(diameter=threads_diameter, rod_height=snap_thickness, top_cutoff=true);
            else
              generic_threaded_rod(d=threads_diameter, l=snap_thickness, pitch=threads_pitch, profile=threads_profile, bevel1=0.5, bevel2=threads_bottom_bevel, blunt_start=false, anchor=BOTTOM, internal=false);
          }
          if (add_threads_blunt_text && threads_type == "Blunt")
            up(snap_thickness - text_depth + eps / 2) right(final_add_thickness_text ? 2.4 : 0)
                tag("remove") linear_extrude(height=text_depth + eps) zrot(0) fill() text(threads_blunt_text, size=4, anchor=str("center", CENTER), font=threads_blunt_text_font);
          if (final_add_thickness_text)
            up(snap_thickness - text_depth + eps / 2) left(add_threads_blunt_text && threads_type == "Blunt" ? 2.4 : 0)
                tag("remove") linear_extrude(height=text_depth + eps) text(str(floor(snap_thickness)), size=4.5, anchor=str("center", CENTER), font="Merriweather Sans:style=Bold");
        }
        //first inner diff
        diff(remove="rm1") {
          fwd(threads_offset - clip_height / 2) {
            //second inner diff
            diff(remove="rm2", keep="kp2") {
              //Added shape connects the print surface of the threads to gadget.
              fwd((clip_height - symmetric_clip_height) / 2 + threads_offset) diff(remove="rm3") {
                  teardrop(r=symmetric_clip_height / 2, h=connect_cuboid_height + clip_stem_length, anchor=BACK + TOP, orient=FRONT);
                  tag("rm3") back(clip_height) cuboid([30, 30, connect_cuboid_height + clip_stem_length], anchor=TOP + FRONT);
                }
              down(clip_shape != "Circular" ? (clip_main_width / 2 + clip_thickness) * abs(final_clip_entry_tilt_angle) / 90 : -clip_thickness / 2 * (1 - clip_thickness_scale) * (abs(final_clip_entry_tilt_angle)) / 90 + clip_stem_length)
                right(clip_shape != "Circular" ? (clip_main_depth / 2 + clip_thickness) * final_clip_entry_tilt_angle / 90 : 0)
                  yrot(final_clip_entry_tilt_angle, cp=[0, 0, clip_shape != "Circular" ? 0 : -(clip_main_width / 2 + clip_thickness)])
                    down(clip_thickness / 2) {
                      //used to cut off excessive part of connecting cuboid. remove by second inner diff("rm2","kp2") 
                      if (clip_shape == "Rectangular")
                        tag("rm2") cuboid([clip_main_width + clip_thickness, 200, clip_main_depth + clip_thickness], edges="Y", rounding=final_clip_rect_rounding, anchor=TOP);
                      else
                        tag("rm2") scale([1, 1, elliptic_ratio]) ycyl(d=clip_main_width + clip_thickness, l=200, anchor=TOP);
                      //mess of codes to implement knurling.
                      if (knurling_type != "None")
                        fwd((clip_height - symmetric_clip_height) / 2) {
                          if (clip_shape == "Rectangular") {
                            rectangular_knurling_shape = difference(
                              back(final_clip_rect_rounding * (180 - clip_surround_angle) / 90 + knurling_outer_offset, rect([clip_main_width + clip_thickness * 2, clip_main_depth + clip_thickness], anchor=FRONT)),
                              rect([clip_main_width, clip_main_depth], rounding=final_clip_rect_rounding, anchor=FRONT)
                            );
                            tag("kp2") back(clip_height - threads_offset) intersection() {
                                  down(clip_main_depth + clip_thickness / 2) xrot(90) linear_sweep(
                                        rectangular_knurling_shape, clip_height, texture="diamonds", tex_size=[knurling_texture_size, knurling_texture_size],
                                        tex_depth=knurling_texture_depth, style=knurling_type == "Line" ? "default" : "concave"
                                      );
                                  cuboid([clip_main_width + clip_thickness / 2, 200, clip_main_depth + clip_thickness / 2], rounding=final_clip_rect_rounding / 2, edges="Y", anchor=TOP);
                                }
                          } else if (clip_shape == "Circular" || clip_shape == "Elliptic") {
                            //calculate the outline of the circular/elliptic clip accounting for clip_thickness_scale.
                            width_radius_start = clip_main_width / 2;
                            width_radius_target = clip_main_width / 2 + (clip_thickness / 2) * clip_thickness_scale - clip_thickness / 2;
                            height_radius_start = clip_shape == "Circular" ? width_radius_start : clip_main_depth / 2;
                            height_radius_target = clip_shape == "Circular" ? width_radius_target : clip_main_depth / 2 + (clip_thickness / 2) * clip_thickness_scale - clip_thickness / 2;
                            segment_count = 20;
                            half_ellipse = [
                              for (i = [0:segment_count]) [
                                (width_radius_start + (width_radius_start - width_radius_target) / segment_count * i) * sin(i * (clip_surround_angle / segment_count)),
                                (height_radius_start + (height_radius_start - height_radius_target) / segment_count * i) * cos(i * (clip_surround_angle / segment_count)),
                              ],
                              // [(width_radius_start * 2 - width_radius_target) * sin(clip_surround_angle), (width_radius_start * 2 - width_radius_target) * cos(clip_surround_angle)],
                              [0, (height_radius_start * 2 - height_radius_target) * cos(clip_surround_angle)],
                            ];
                            final_cos = abs((height_radius_start * 2 - height_radius_target) * cos(clip_surround_angle));

                            elliptic_part1 = fwd(final_cos - knurling_outer_offset, rect([clip_main_width + clip_thickness * 2, (final_cos + height_radius_start)], anchor=FRONT));
                            elliptic_part2 = union(half_ellipse, xflip(half_ellipse));
                            elliptic_knurling_shape = difference(
                              elliptic_part1, elliptic_part2
                            );
                            tag("kp2") back(clip_height - threads_offset) intersection() {
                                  down(clip_thickness / 2 + height_radius_start)
                                    xrot(90)
                                      linear_sweep(
                                        elliptic_knurling_shape, clip_height,
                                        texture="diamonds", tex_size=[knurling_texture_size, knurling_texture_size],
                                        tex_depth=knurling_texture_depth, style=knurling_type == "Line" ? "default" : "concave"
                                      );
                                  scale([1, 1, elliptic_ratio]) ycyl(d=clip_main_width + clip_thickness, l=200, anchor=TOP);
                                }
                          }
                        }
                      xflip_copy() xrot(90)
                          tag("kp2") path_sweep(clip_profile, path=final_clip_path, scale=[clip_thickness_scale, 1]) {
                              if (tip_diameter > 0)
                                attach("end", "start")
                                  path_sweep(scale([clip_thickness_scale, 1, 1], clip_profile), path=turtle(tip_path))
                                    attach("end", "top")
                                      offset_sweep(scale([clip_thickness_scale, 1, 1], clip_profile), height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius));
                              else {
                                attach("end", "top")
                                  offset_sweep(scale([clip_thickness_scale, 1, 1], clip_profile), height=tip_rounding_radius + eps, bottom=os_circle(r=tip_rounding_radius));
                              }
                            }
                    }
            }
          }
          tag("rm1") cuboid([500, 500, 500], anchor=BOTTOM);
        }
        tag("remove") fwd(threads_offset) cuboid([500, 500, 500], anchor=BACK);
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
