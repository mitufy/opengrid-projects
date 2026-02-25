/*
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <lib/opengrid_variable.scad>
include <BOSL2/threading.scad>
use <lib/util_lib.scad>
use <lib/openconnect_lib.scad>
use <lib/opengrid_snap_threads_lib.scad>

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm]
//Directional for vertical wall-mounted boards. Symmetric for horizontal boards, often used with Underware.
snap_body_shape = "Directional"; //["Directional","Symmetric"]
//Regular version is usually enough. Folded version is stronger but requires thinner layer height, thus taking longer to print.
generate_screw = "openConnect"; //["None", "openConnect", "openConnect (Folded)", "multiConnect"]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol at the bottom.
threads_type = "Blunt"; //["Blunt", "Basic"]

/* [Expanding Snap Settings] */
//Default value is tested on Bambu PLA Basic, Bambu PETG HF, and Sunlu PLA+ 2.0. You may need to adjust it depending on the filament you use.
expand_distance_standard = 1.0; //0.05
//Lite snaps have thinner springs, thus a larger expand distance than Standard snaps.
expand_distance_lite = 1.2; //0.05
//A small notch to make uninstalling easier. Set to 0 to disable.
uninstall_notch_width = 5; //0.2

/* [Text Settings] */
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]
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

module snap() {
  conditional_fold(body_thickness=snap_thickness + OCHEAD_TOTAL_HEIGHT, fold_position=OCHEAD_MIDDLE_TO_BOTTOM + EPS, condition=generate_snap == "openConnect (Folded)")
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
                if (!disable_snap_directional_slants && snap_body_shape == "Directional")
                  tag("remove") snap_directional_slant();
                if (uninstall_notch_width > EPS)
                  tag("remove") snap_uninstall_notch();
              }
              if (!disable_snap_expanding_springs) {
                tag("remove") down(EPS / 2) zrot(expand_split_angle) expanding_spring(snap_body_shape == "Directional" && snap_thickness == OG_STANDARD_THICKNESS ? "Corners" : "None");
                tag("remove") down(EPS / 2) zrot(expand_split_angle - 180) expanding_spring(snap_body_shape == "Directional" ? "Slant" : "None");
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
                if (!disable_snap_directional_slants && snap_body_shape == "Directional")
                  tag("remove") snap_directional_slant();
                if (uninstall_notch_width > EPS)
                  tag("remove") snap_uninstall_notch();
              }
              left(snap_center_position_offset[0]) back(snap_center_position_offset[1]) {
                  if (generate_snap == "Basic Threads" && !disable_snap_threads) {
                    tag_diff(tag="remove", remove="rm0")
                      down(EPS / 2) up(reverse_threads_entryside ? snap_thickness + EPS / 2 : 0) yrot(reverse_threads_entryside ? 180 : 0)
                            zrot(threads_compatibility_angle + threads_offset_angle) {
                              if (threads_type == "Blunt")
                                blunt_threads(diameter=(OG_SNAP_THREADS_DIAMETER + OG_SNAP_THREADS_CLEARANCE), threads_height=snap_thickness + EPS);
                              else
                                generic_threaded_rod(d=(OG_SNAP_THREADS_DIAMETER + OG_SNAP_THREADS_CLEARANCE), l=snap_thickness + EPS, pitch=threads_pitch, profile=threads_profile, bevel1=0, bevel2=min(threads_bottom_bevel, snap_thickness), anchor=BOTTOM, blunt_start=false, internal=false);
                            }
                  }
                  if (generate_snap == "openConnect" || generate_snap == "openConnect (Folded)")
                    down(OCHEAD_TOTAL_HEIGHT) force_tag("") openconnect_head(add_nubs="Both");
                  if (generate_snap == "multiConnect")
                    multiconnect_head("dimple");
                }
            }
          }
          if (add_threads_blunt_text && threads_type == "Blunt" && generate_snap != "openConnect" && generate_snap != "multiConnect")
            up(snap_thickness - text_depth) fwd(0) left(expand_split_angle < 0 ? 0.5 : -0.5) zrot(-expand_split_angle) linear_extrude(height=text_depth) back(OG_SNAP_WIDTH / 2 - 2) zrot(45) fill() text(OG_SNAP_THREADS_BLUNT_TEXT, size=4, anchor=str("center", CENTER), font=OG_SNAP_THREADS_BLUNT_TEXT_FONT);
          if (final_add_thickness_text)
            up(snap_thickness - text_depth) fwd(1.1) left(expand_split_angle < 0 ? -0.7 : 0.7) zrot(-expand_split_angle) linear_extrude(height=text_depth) fwd(OG_SNAP_WIDTH / 2 - 2) zrot(45) text(str(floor(snap_thickness)), size=4, anchor=str("baseline", CENTER), font=OG_SNAP_TEXT_FONT);
          if (add_snap_expansion_distance_text && generate_snap == "Self-Expanding Threads")
            up(snap_thickness - text_depth) linear_extrude(height=text_depth + EPS) fwd(OG_SNAP_WIDTH / 2 - 1.6) text(str(expand_distance), size=3.2, anchor=str("baseline", CENTER), font=OG_SNAP_TEXT_FONT);
          //arrow
          if (snap_body_shape == "Directional")
            zrot(-90) up(snap_thickness + EPS / 2) left(OG_SNAP_WIDTH / 2 - 1.1) zrot(180) regular_prism(3, side=3.3, h=directional_arrow_depth + EPS, chamfer1=directional_arrow_depth, anchor=RIGHT + TOP);
        }
}

module main_generate() {
  if (generate_snap != "None")
    zrot(view_snap_rotated)
      snap();
  if (generate_screw == "multiConnect")
    left(generate_snap == "None" || view_snap_and_connector_overlapped ? 0 : 28) up(view_snap_and_connector_overlapped ? 0 : mchead_total_height) zrot(view_connector_rotated)
          multiconnect_screw();
  if (generate_screw == "openConnect" || generate_screw == "openConnect (Folded)")
    right(generate_snap == "None" || view_snap_and_connector_overlapped ? 0 : 28) fwd(view_snap_and_connector_overlapped && generate_screw == "openConnect (Folded)" ? OCHEAD_MIDDLE_TO_BOTTOM : 0)
        down(!view_snap_and_connector_overlapped ? 0 : generate_screw == "openConnect (Folded)" ? OCHEAD_TOTAL_HEIGHT : -snap_thickness)
          zrot(view_connector_rotated) xrot(!view_snap_and_connector_overlapped ? 0 : generate_screw == "openConnect (Folded)" ? -90 : -180)
              zrot(view_snap_and_connector_overlapped || generate_screw == "openConnect (Folded)" ? 180 : 0) openconnect_screw(snap_thickness=snap_thickness, threads_type=threads_type, folded=generate_screw == "openConnect (Folded)");
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
