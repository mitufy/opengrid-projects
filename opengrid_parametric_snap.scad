/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <lib/opengrid_variable.scad>
use <lib/util_lib.scad>
use <lib/openconnect_lib.scad>
use <lib/opengrid_snap_lib.scad>
use <lib/opengrid_snap_threads_lib.scad>

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]
//Directional for vertical wall-mounted boards. Symmetric for horizontal boards, often used with Underware.
snap_body_shape = "Directional"; //["Directional","Symmetric"]
generate_snap = "openConnect"; //["None", "Self-Expanding Threads","Basic Threads","openConnect","openConnect (Folded)","multiConnect"]
//Regular version is usually enough. Folded version is stronger but requires thinner layer height, thus taking longer to print.
generate_screw = "None"; //["None", "openConnect", "openConnect (Folded)", "multiConnect"]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol at the bottom.
threads_type = "Blunt"; //["Blunt", "Basic"]

/* [Snap Body Settings] */
snap_width = 24.8;
snap_height = 24.8;

//Offset connector head/threads position in x and y. This does not affect Self-Expanding Snaps.
snap_center_position_offset = [0, 0]; //0.1

snap_corner_edge_height = 1.5;
snap_body_top_corner_extrude = 1.1;
snap_body_bottom_corner_extrude = 0.6;

directional_slant_depth_standard = 0.8;
directional_slant_depth_lite = 0.2;
directional_corner_fillet_radius = 1.5;
directional_arrow_depth = 0.2;

/* [Snap Nub Settings] */
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

/* [Snap Cut Settings] */
bottom_cut_length = 12.4;
bottom_cut_thickness = 0.6;
bottom_cut_offset_to_top = 0.6;
bottom_cut_offset_to_edge = 0.7;

side_cut_thickness = 0.4; //0.1
side_cut_depth = 0.8; //0.1
side_cut_offset_to_top = 0.8; //0.1

/* [Thread Settings] */
//openGrid snap threads are designed to have 16mm diameter and 0.5mm clearance, 16.5mm is the offical diameter for negative parts.
threads_diameter = 16; //0.1
threads_clearance = 0.5;
threads_pitch = 3;
threads_top_bevel = 0.5;
threads_bottom_bevel_standard = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1
threads_offset_angle = 0; //[0:15:345]

/* [Expanding Snap Settings] */
//The default value is tested on Bambu PLA Basic, Bambu PETG HF, and Sunlu PLA+ 2.0. You may need to adjust it depending on the filament you use.
expand_distance_standard = 1.0; //0.05
//Lite snaps have thinner springs, thus a larger expand distance than Standard snaps.
expand_distance_lite = 1.2; //0.05
//A small notch to make uninstalling easier. Set to 0 to disable.
uninstall_notch_width = 5; //0.2

/* [Expanding Snap Advanced Settings] */
uninstall_notch_surface_inset = 1;
uninstall_notch_gap_inset = 1.8;
uninstall_notch_surface_height_standard = 1.2;
uninstall_notch_surface_height_lite = 0.8;
uninstall_notch_gap_height_standard = 1;
uninstall_notch_gap_height_lite = 0.6;
//The part before the threads start expanding. Increase this value if you find it difficult to get the screw started.
expand_entry_height_standard = 0.4;
expand_entry_height_lite = 0.4;
expand_entry_height_blunt = 1;
expand_split_angle = 45;
//Default spring thickness parameters are set to products of 0.42, a common line width for 0.4mm nozzles.
spring_thickness = 1.26;
spring_to_center_thickness = 0.84;
spring_gap = 0.42;
spring_face_chamfer = 0.2;
//The part at the bottom that completely expands to target width. It's not recommended to set this lower than threads_bottom_bevel.
expand_end_height_standard = 2; //0.1
expand_end_height_lite = 1.2; //0.1
//this value dictates how much the width of each layer of threads differs from the last. Setting it lower makes the threads smoother and takes longer to generate. For 3d printing, 0.05 should be more than sufficient.
expansion_distance_step = 0.05;

/* [Text Settings] */
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]
//Useful when experimenting with expansion distance.
add_snap_expansion_distance_text = false;
text_depth = 0.4;

/* [multiConnect Settings] */
mchead_large_diameter = 20;
mchead_small_diameter = 15;
mchead_top_height = 0.5;
mchead_middle_height = 2.5;
mchead_bottom_height = 1;
mchead_total_height = mchead_top_height + mchead_middle_height + mchead_bottom_height;
connector_coin_slot_height = 2.6;
connector_coin_slot_width = 13;
connector_coin_slot_thickness = 2.2;
connector_flat_slot_height = 4.4;
connector_flat_slot_width = 6.5;
connector_flat_slot_height_offset = 0.7;
connector_flat_slot_start_thickness = 1.8;
connector_flat_slot_end_thickness = 1.2;
//The following formula is derived from intersecting chord theorem. Don't ask.
connector_coin_slot_radius = connector_coin_slot_height / 2 + connector_coin_slot_width ^ 2 / (8 * connector_coin_slot_height);

/* [View Settings] */
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
//Use with cross-section view to see how threads of snap and connector fit together.
view_snap_and_connector_overlapped = false;
view_snap_rotated = 0;
view_connector_rotated = 0;

/* [Experimental Settings] */
override_snap_thickness = false;
//Custom thickness only applies when override_snap_thickness is checked.
custom_snap_thickness = 3.4;
//Making multiconnect connector attach to the backside, opening up a new option for mounting the board. Idea suggested by @ljhms.
reverse_threads_entryside = false;

/* [Disable Part Settings] */
disable_snap_threads = false;
disable_snap_corners = false;
disable_snap_cuts = false;
disable_snap_nubs = false;
disable_snap_directional_slants = false;
disable_snap_expanding_springs = false;

/* [Hidden] */
$fa = 1;
$fs = 0.4;

// ── Derived per-thickness values ─────────────────────────────────────────────
_snap_thickness = override_snap_thickness ? custom_snap_thickness : snap_thickness;
_is_standard = _snap_thickness >= OG_STANDARD_THICKNESS;

expand_distance = _is_standard ? expand_distance_standard : expand_distance_lite;
expand_entry_height = threads_type == "Blunt" ? expand_entry_height_blunt : (_is_standard ? expand_entry_height_standard : expand_entry_height_lite);
expand_end_height = _is_standard ? expand_end_height_standard : expand_end_height_lite;
add_thickness_text = thickness_text_mode;

// ── Cfg packing ──────────────────────────────────────────────────────────────
_snapbody_cfg = snap_body_cfg(
  snap_width=snap_width,
  snap_height=snap_height,
  snap_thickness=_snap_thickness,
  snap_body_shape=snap_body_shape
);
_snapcorner_cfg = snap_corner_cfg(
  directional_corner_fillet_radius=directional_corner_fillet_radius,
  snap_corner_edge_height=snap_corner_edge_height,
  snap_body_top_corner_extrude=snap_body_top_corner_extrude,
  snap_body_bottom_corner_extrude=snap_body_bottom_corner_extrude
);
_snapnub_cfg = snap_nub_cfg(
  basic_nub_width=basic_nub_width,
  basic_nub_depth=basic_nub_depth,
  basic_nub_top_width=basic_nub_top_width,
  basic_nub_top_angle=basic_nub_top_angle,
  basic_nub_bottom_angle=basic_nub_bottom_angle,
  basic_nub_fillet_radius=basic_nub_fillet_radius,
  basic_nub_height_standard=basic_nub_height_standard,
  basic_nub_height_lite=basic_nub_height_lite,
  directional_nub_width=directional_nub_width,
  directional_nub_depth=directional_nub_depth,
  directional_nub_top_width=directional_nub_top_width,
  directional_nub_top_angle=directional_nub_top_angle,
  directional_nub_height_standard=directional_nub_height_standard,
  directional_nub_height_lite=directional_nub_height_lite,
  directional_nub_bottom_angle_standard=directional_nub_bottom_angle_standard,
  directional_nub_bottom_angle_lite=directional_nub_bottom_angle_lite,
  directional_nub_fillet_radius=directional_nub_fillet_radius,
  antidirect_nub_height_standard=antidirect_nub_height_standard,
  antidirect_nub_height_lite=antidirect_nub_height_lite,
  nub_offset_to_top=nub_offset_to_top
);
_snapcut_cfg = snap_cut_cfg(
  bottom_cut_length=bottom_cut_length,
  bottom_cut_thickness=bottom_cut_thickness,
  bottom_cut_offset_to_top=bottom_cut_offset_to_top,
  bottom_cut_offset_to_edge=bottom_cut_offset_to_edge,
  side_cut_thickness=side_cut_thickness,
  side_cut_depth=side_cut_depth,
  side_cut_offset_to_top=side_cut_offset_to_top,
  directional_slant_depth_standard=directional_slant_depth_standard,
  directional_slant_depth_lite=directional_slant_depth_lite
);
_snapnotch_cfg = snap_notch_cfg(
  notch_width=uninstall_notch_width,
  notch_surface_inset=uninstall_notch_surface_inset,
  notch_gap_inset=uninstall_notch_gap_inset,
  notch_surface_height_standard=uninstall_notch_surface_height_standard,
  notch_surface_height_lite=uninstall_notch_surface_height_lite,
  notch_gap_height_standard=uninstall_notch_gap_height_standard,
  notch_gap_height_lite=uninstall_notch_gap_height_lite
);
_snaptext_cfg = snap_text_cfg(
  text_depth=text_depth,
  thickness_text_mode=thickness_text_mode,
  directional_arrow_depth=directional_arrow_depth,
  add_blunt_text=threads_type == "Blunt",
  add_arrow=snap_body_shape == "Directional"
);
_snapspring_cfg = expanding_spring_cfg(
  spring_thickness=spring_thickness,
  spring_to_center_thickness=spring_to_center_thickness,
  spring_gap=spring_gap,
  spring_face_chamfer=spring_face_chamfer
);

// ── Modules ───────────────────────────────────────────────────────────────────
module multiconnect_screw() {
  //In David's original design the slot is created in shapr3d by a fillet with a mysterious curvature parameter. I have no idea how to replicate that so here's a circle. Difference in geometry is negligible.
  difference() {
    union() {
      snap_threads(threads_type=threads_type, snap_thickness=_snap_thickness, text_depth=text_depth, thickness_text_mode=thickness_text_mode);
      multiconnect_head(top_pattern="coin_slot");
    }
  }
}
module multiconnect_head(top_pattern = "coin_slot") {
  difference() {
    up(EPS) cylinder(h=mchead_top_height, r=mchead_small_diameter / 2, anchor=TOP)
        attach(BOTTOM, TOP) cylinder(h=mchead_middle_height, r2=mchead_large_diameter / 2 - mchead_middle_height, r1=mchead_large_diameter / 2)
            attach(BOTTOM, TOP) cylinder(h=mchead_bottom_height, r=mchead_large_diameter / 2);
    //In David's original design the slot is created in shapr3d by a fillet with a mysterious curvature parameter. I have no idea how to replicate that so here's a circle. Difference in geometry is negligible.
    if (top_pattern == "coin_slot")
      down(4 - connector_coin_slot_height) xrot(90) cyl(r=connector_coin_slot_radius, h=connector_coin_slot_thickness, $fn=128, anchor=BACK);
    if (top_pattern == "dimple")
      down(4) cyl(d1=2, d2=0.01, h=1, $fn=128, anchor=BOTTOM);
  }
}
module expanding_snap(
  threads_type,
  snapbody_cfg = [],
  snapcorner_cfg = [],
  snapnub_cfg = [],
  snapcut_cfg = [],
  snapnotch_cfg = [],
  snaptext_cfg = [],
  snapspring_cfg = []
) {
  _snap_body_shape = struct_val(snapbody_cfg, "snap_body_shape", "Directional");
  _snap_thickness = struct_val(snapbody_cfg, "snap_thickness", OG_STANDARD_THICKNESS);
  expand_cut_cfg = struct_set(snapcut_cfg, ["disable_all_side_cut", true, "disable_all_bottom_cut", true]);
  expand_text_cfg = struct_set(
    snaptext_cfg, [
      "add_custom_text",
      add_snap_expansion_distance_text,
      "custom_text",
      str(expand_distance),
      "custom_text_size",
      3.2,
      "add_blunt_text",
      false,
      "add_arrow",
      false,
    ]
  );
  difference() {
    up(_snap_thickness) yrot(180)
        base_snap(
          snapbody_cfg=snapbody_cfg, snapcorner_cfg=snapcorner_cfg, snapnub_cfg=snapnub_cfg,
          snapcut_cfg=expand_cut_cfg, snapnotch_cfg=snapnotch_cfg, snaptext_cfg=expand_text_cfg
        );
    down(EPS) expanding_threads(
        threads_type=threads_type, threads_height=_snap_thickness,
        expand_distance=expand_distance, entry_height=expand_entry_height, end_height=expand_end_height
      );
    zrot(expand_split_angle)
      expanding_spring(
        snapbody_cfg, _snap_body_shape == "Directional" && _snap_thickness == OG_STANDARD_THICKNESS ? "Corners" : "None",
        snapspring_cfg, snapcorner_cfg, snapcut_cfg
      );
    zrot(expand_split_angle - 180)
      expanding_spring(
        snapbody_cfg, _snap_body_shape == "Directional" ? "Slant" : "None",
        snapspring_cfg, snapcorner_cfg, snapcut_cfg
      );
  }
}
module opengrid_snap(
  threads_type,
  snapbody_cfg = [],
  snapcorner_cfg = [],
  snapnub_cfg = [],
  snapcut_cfg = [],
  snapnotch_cfg = [],
  snaptext_cfg = [],
  snapspring_cfg = []
) {
  _snap_body_shape = struct_val(snapbody_cfg, "snap_body_shape", "Directional");
  _snap_thickness = struct_val(snapbody_cfg, "snap_thickness", OG_STANDARD_THICKNESS);
  conditional_fold(body_thickness=_snap_thickness + OCHEAD_TOTAL_HEIGHT, fold_position=OCHEAD_MIDDLE_TO_BOTTOM + EPS, condition=generate_snap == "openConnect (Folded)") if (generate_snap == "Self-Expanding Threads")
    expanding_snap(
      threads_type=threads_type,
      snapbody_cfg=snapbody_cfg, snapcorner_cfg=snapcorner_cfg, snapnub_cfg=snapnub_cfg,
      snapcut_cfg=snapcut_cfg, snapnotch_cfg=snapnotch_cfg, snaptext_cfg=snaptext_cfg, snapspring_cfg=snapspring_cfg
    );
  else {
    disable_features = concat(
      disable_snap_corners ? ["snap_corner"] : [],
      disable_snap_nubs ? ["snap_nub"] : [],
      disable_snap_cuts ? ["snap_cut"] : [],
      !in_list(list=[disable_snap_cuts], val=true) && uninstall_notch_width <= EPS ? ["snap_uninstall_notch"] : []
    );
    base_snap(
      snapbody_cfg=snapbody_cfg, disable_features=disable_features,
      snapcorner_cfg=snapcorner_cfg, snapnub_cfg=snapnub_cfg,
      snapcut_cfg=snapcut_cfg, snapnotch_cfg=snapnotch_cfg, snaptext_cfg=snaptext_cfg
    ) {
      left(snap_center_position_offset[0]) back(snap_center_position_offset[1]) {
          if (generate_snap == "Basic Threads" && !disable_snap_threads)
            snap_threads(threads_type=threads_type, snap_thickness=_snap_thickness + EPS);
          if (generate_snap == "openConnect" || generate_snap == "openConnect (Folded)")
            attach(TOP, TOP)
              openconnect_head(add_nubs="Both");
          if (generate_snap == "multiConnect")
            xrot(180) multiconnect_head("dimple");
        }
    }
  }
}
module main_generate() {
  if (generate_snap != "None")
    zrot(view_snap_rotated)
      opengrid_snap(
        threads_type=threads_type,
        snapbody_cfg=_snapbody_cfg,
        snapcorner_cfg=_snapcorner_cfg, snapnub_cfg=_snapnub_cfg, snapcut_cfg=_snapcut_cfg,
        snapnotch_cfg=_snapnotch_cfg, snaptext_cfg=_snaptext_cfg, snapspring_cfg=_snapspring_cfg
      );
  if (generate_screw == "multiConnect")
    left(generate_snap == "None" || view_snap_and_connector_overlapped ? 0 : 28) up(view_snap_and_connector_overlapped ? 0 : mchead_total_height) zrot(view_connector_rotated)
          multiconnect_screw();
  if (generate_screw == "openConnect" || generate_screw == "openConnect (Folded)")
    right(generate_snap == "None" || view_snap_and_connector_overlapped ? 0 : 28) fwd(view_snap_and_connector_overlapped && generate_screw == "openConnect (Folded)" ? OCHEAD_MIDDLE_TO_BOTTOM : 0)
        down(!view_snap_and_connector_overlapped ? 0 : generate_screw == "openConnect (Folded)" ? OCHEAD_TOTAL_HEIGHT : -_snap_thickness)
          zrot(view_connector_rotated) xrot(!view_snap_and_connector_overlapped ? 0 : generate_screw == "openConnect (Folded)" ? -90 : -180)
              zrot(view_snap_and_connector_overlapped || generate_screw == "openConnect (Folded)" ? 180 : 0) openconnect_screw(octhreads_height=_snap_thickness, folded=generate_screw == "openConnect (Folded)");
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
