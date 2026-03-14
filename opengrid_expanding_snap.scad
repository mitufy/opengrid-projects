/*
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

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

/* [Advanced Settings] */
//A small notch to make uninstalling easier. Set to 0 to disable.
uninstall_notch_width = 5; //0.2
//Useful when experimenting with expansion distance.
add_snap_expansion_distance_text = false;
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]
threads_offset_angle = 0; //[0:15:345]

/* [Hidden] */
$fa = 1;
$fs = 0.4;

include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>
use <lib/opengrid_threads_lib.scad>
use <lib/opengrid_snap_lib.scad>

expand_split_angle = 45;
_snap_thickness = snap_thickness;
mchead_large_diameter = 20;
mchead_small_diameter = 15;
mchead_top_height = 0.5;
mchead_middle_height = 2.5;
mchead_bottom_height = 1;
mchead_total_height = mchead_top_height + mchead_middle_height + mchead_bottom_height;

// ── Cfg packing ──────────────────────────────────────────────────────────────
_snapnotch_cfg = snap_notch_cfg(
  notch_width=uninstall_notch_width
);
_add_blunt_text = threads_type == "Blunt";
_add_thickness_text = thickness_text_mode == "All" || (thickness_text_mode == "Uncommon" && _snap_thickness != OG_LITE_BASIC_THICKNESS && _snap_thickness != OG_STANDARD_THICKNESS);
_add_arrow = snap_body_shape == "Directional";

_snaptext_texts = [
  if (_add_blunt_text) OG_SNAP_BLUNT_TEXT,
  if (_add_thickness_text) str(floor(_snap_thickness)),
  if (_add_arrow) OG_SNAP_DIRECTIONAL_ARROW_TEXT,
];
_snaptext_sizes = [
  if (_add_blunt_text) 4,
  if (_add_thickness_text) 4,
  if (_add_arrow) 3.6,
];
_snaptext_fonts = [
  if (_add_blunt_text) OG_SNAP_EMOJI_FONT,
  if (_add_thickness_text) OG_SNAP_TEXT_FONT,
  if (_add_arrow) OG_SNAP_EMOJI_FONT,
];
_snaptext_fills = [
  if (_add_blunt_text) true,
  if (_add_thickness_text) false,
  if (_add_arrow) true,
];
_snaptext_body_pos = [
  if (_add_blunt_text) [OG_SNAP_WIDTH / 2 - 4.6, OG_SNAP_WIDTH / 2 - 4.6],
  if (_add_thickness_text) [-(OG_SNAP_WIDTH / 2 - 4.2), -(OG_SNAP_WIDTH / 2 - 6)],
  if (_add_arrow) [0, OG_SNAP_WIDTH / 2 - 2.6],
];
_snaptext_screw_pos = [
  if (_add_blunt_text) [_add_thickness_text ? 2.4 : 0, 0],
  if (_add_thickness_text) [-(_add_blunt_text ? 2.4 : 0), 0],
];

_snapbody_text_cfg = text_cfg(
  texts=_snaptext_texts, sizes=_snaptext_sizes, fonts=_snaptext_fonts, fills=_snaptext_fills,
  pos_offsets=_snaptext_body_pos
);
_screw_text_cfg = text_cfg(
  texts=[if (_add_blunt_text) OG_SNAP_BLUNT_TEXT, if (_add_thickness_text) str(floor(_snap_thickness))],
  sizes=[for (s = _snaptext_sizes) _add_blunt_text && s == 4 ? 4 : 4.5],
  fonts=[if (_add_blunt_text) OG_SNAP_EMOJI_FONT, if (_add_thickness_text) OG_SNAP_TEXT_FONT],
  fills=[if (_add_blunt_text) true, if (_add_thickness_text) false],
  pos_offsets=_snaptext_screw_pos
);

_espring_cfg = snap_spring_cfg();
_snapbody_cfg = snap_body_cfg(
  snap_width=OG_SNAP_WIDTH,
  snap_height=OG_SNAP_WIDTH,
  snap_thickness=snap_thickness,
  snap_body_shape=snap_body_shape
);
_snapcorner_cfg = snap_corner_cfg();
_snapnub_cfg = snap_nub_cfg();
_snapcut_cfg = snap_cut_cfg();

_expand_cfg = snap_expand_cfg(
  expand_distance_standard=expand_distance_standard,
  expand_distance_lite=expand_distance_lite
);
_threads_cfg = threads_cfg(
  threads_type=threads_type,
  threads_offset_angle=threads_offset_angle
);

_ochead_cfg = ochead_cfg();

_connectorslot_cfg = connector_slot_cfg();

module multiconnect_screw(connectorslot_cfg = [], text_cfg = [], threads_cfg = []) {
  tag_scope() {
    multiconnect_head(connectorslot_cfg=connectorslot_cfg, top_pattern="coin_slot", anchor=BOTTOM)
      attach(TOP, BOTTOM)
        snap_threads(threads_height=_snap_thickness, text_cfg=text_cfg, threads_cfg=struct_set(threads_cfg, ["threads_clearance", 0]));
  }
}

module multiconnect_head(connectorslot_cfg = [], top_pattern = "coin_slot", anchor = BOTTOM, spin = 0, orient = UP) {
  _coin_slot_height = struct_val(connectorslot_cfg, "coin_slot_height", 2.6);
  _coin_slot_radius = struct_val(connectorslot_cfg, "coin_slot_radius", 13);
  _coin_slot_thickness = struct_val(connectorslot_cfg, "coin_slot_thickness", 2.4);
  attachable(anchor, spin, orient, r=mchead_small_diameter / 2, h=mchead_total_height) {
    tag_scope() up(mchead_total_height / 2) difference() {
          cylinder(h=mchead_top_height, r=mchead_small_diameter / 2, anchor=TOP)
            attach(BOTTOM, TOP) cylinder(h=mchead_middle_height, r2=mchead_large_diameter / 2 - mchead_middle_height, r1=mchead_large_diameter / 2)
                attach(BOTTOM, TOP) cylinder(h=mchead_bottom_height, r=mchead_large_diameter / 2);
          //In David's original design the slot is created in shapr3d by a fillet with a mysterious curvature parameter. I have no idea how to replicate that so here's a circle. Difference in geometry is negligible.
          if (top_pattern == "coin_slot")
            down(mchead_total_height - _coin_slot_height) xrot(90) cyl(r=_coin_slot_radius, h=_coin_slot_thickness, $fn=128, anchor=BACK);
          if (top_pattern == "dimple")
            down(mchead_total_height) cyl(d1=2, d2=EPS, h=1, $fn=128, anchor=BOTTOM);
        }
    children();
  }
}
expanding_snap(
  snapbody_cfg=_snapbody_cfg, snapcorner_cfg=_snapcorner_cfg, snapnub_cfg=_snapnub_cfg,
  snapcut_cfg=_snapcut_cfg, snapnotch_cfg=_snapnotch_cfg, text_cfg=_snapbody_text_cfg,
  spring_cfg=_espring_cfg, expand_cfg=_expand_cfg,
  threads_cfg=_threads_cfg, add_expand_distance_text=add_snap_expansion_distance_text
);
if (generate_screw == "multiConnect")
  right(OG_TILE_SIZE)
    multiconnect_screw(connectorslot_cfg=_connectorslot_cfg, text_cfg=_screw_text_cfg, threads_cfg=_threads_cfg);
if (generate_screw == "openConnect" || generate_screw == "openConnect (Folded)")
  right(OG_TILE_SIZE)
    zrot(generate_screw == "openConnect (Folded)" ? 180 : 0)
      openconnect_screw(threads_height=_snap_thickness, head_cfg=_ochead_cfg, text_cfg=_screw_text_cfg, connectorslot_cfg=_connectorslot_cfg, threads_cfg=_threads_cfg, folded=generate_screw == "openConnect (Folded)");
