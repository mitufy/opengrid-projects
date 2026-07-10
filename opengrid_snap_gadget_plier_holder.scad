/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Recommended to use with openGrid - Self-Expanding Snap. https://www.printables.com/model/1294247-opengrid-self-expanding-snap
The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol.
threads_type = "Blunt"; //["Blunt", "Basic"]
//Increase the value to generate a holder for multiple pliers.
plier_count = 1;

/* [Stem Settings] */
stem_top_width = 2; //0.4
stem_bottom_width = 10; //0.4
stem_height = 8; //0.4
//stem_depth and stopper_depth add up to the total depth of the holder. stem_depth includes the depth of the transition part.
stem_depth = 12; //0.4

/* [Stopper Settings] */
//Stopper is the front part of the holder which prevents the plier from sliding off.
stopper_depth = 3;
stopper_width_scale = 1; //[0.5:0.1:2]
stopper_height_scale = 1.4; //[0.5:0.1:2]
//Set to 1 to merge stem and stopper into a slope.
transition_depth_ratio = 0.2; //[0:0.1:1]

/* [Spring Holes] */
add_spring_holes = false;
spring_hole_radius = 2.6;
spring_hole_position_offset = 0;

/* [Hidden] */
$fa = 1;
$fs = 0.2;
emit_annotation_metadata = false;
include <lib/annotation_metadata.scad>
include <lib/opengrid_base.scad>
use <lib/opengrid_threads_lib.scad>

//Tilts the plier holder upward from the snap.
holder_tilt_angle = 0; //[0:5:45]
stopper_front_rounding = 0.4; //0.2
stem_top_rounding = 0.8; //0.2
stem_bottom_rounding = 0.8; //0.2
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]

_add_blunt_text = threads_type == "Blunt";
_add_thickness_text = thickness_text_mode == "All" || (thickness_text_mode == "Uncommon" && snap_thickness != OG_LITE_BASIC_THICKNESS && snap_thickness != OG_STANDARD_THICKNESS);

_snaptext_texts = [_add_blunt_text ? OG_SNAP_BLUNT_TEXT : "", _add_thickness_text ? str(floor(snap_thickness)) : ""];

text_depth = 0.4;
_text_cfg = text_cfg(
  texts=_snaptext_texts,
  pos_offsets=(_add_blunt_text && _add_thickness_text) ? OG_GADGET_TEXT_POSITIONS : [[0, 0], [0, 0]]
);

_threads_cfg = positive_threads_cfg(
  threads_cfg(
    threads_type=threads_type
  )
);
_threads_diameter = struct_val(_threads_cfg, "threads_diameter");
_threads_pitch = struct_val(_threads_cfg, "threads_pitch");

final_holder_tilt_angle = max(0, min(45, holder_tilt_angle));
tilt_angle_back_offset = ang_adj_to_opp(final_holder_tilt_angle, _threads_diameter / 2 - 1);
stem_base_depth = stem_depth * (1 - transition_depth_ratio) + tilt_angle_back_offset;
stem_transition_depth = stem_depth * transition_depth_ratio;
holder_spacing = stem_base_depth + stem_transition_depth + stopper_depth - stopper_front_rounding;
thread_clearance_offset = ang_hyp_to_opp(final_holder_tilt_angle, snap_thickness);
//Move the holder root with the tilted screw so their bottom planes stay aligned.
holder_root_offset = thread_clearance_offset;
model_z_offset = thread_clearance_offset;

_threads_connect_diameter = _threads_diameter - OG_THREADS_CONNECT_OFFSET;
_threads_side_offset = _threads_diameter / 2 - OG_SNAP_THREADS_SIDE_OFFSET;
thread_join_overlap = EPS * 2;
//Move the screw cutoff with the shifted thread center so only OG_SNAP_THREADS_SIDE_OFFSET is removed.
thread_cutoff_offset = thread_clearance_offset + _threads_side_offset;
//Keeps the trimmed holder joined to the flat side of the screw threads.
holder_thread_overlap = 0.2;
holder_thread_cutoff_offset = _threads_side_offset - holder_thread_overlap;

final_stem_top_width = max(EPS, min(stem_bottom_width, stem_top_width));
plier_prismoid_top_rounding = max(EPS, min(stem_top_rounding, final_stem_top_width, stem_height / 2));
plier_prismoid_bottom_rounding = max(EPS, min(stem_bottom_rounding, stem_bottom_width / 2, stem_height / 2));
plier_prismoid_side_angle = opp_adj_to_ang((stem_bottom_width - final_stem_top_width) / 2, stem_height);
stopper_side_angle = opp_adj_to_ang((stem_bottom_width - final_stem_top_width) * stopper_width_scale / 2, stem_height * stopper_height_scale);

annotation_side_x = stem_bottom_width / 2;
annotation_stem_y = _threads_side_offset;
annotation_stem_back_y = 0;
annotation_stem_z = 0;
annotation_transition_start_y = -stem_depth * (1 - transition_depth_ratio);
annotation_transition_end_y = -stem_depth;

module emit_snap_gadget_plier_holder_annotations() {
  emit_context_values(
    "snap_gadget_plier_holder_context",
    [
      "snap_thickness",
      "plier_count",
      "stem_top_width",
      "stem_bottom_width",
      "stem_height",
      "stem_depth",
      "transition_depth_ratio",
      "stopper_width_scale",
      "stopper_height_scale",
      "stopper_depth"
    ],
    [
      snap_thickness,
      plier_count,
      stem_top_width,
      stem_bottom_width,
      stem_height,
      stem_depth,
      transition_depth_ratio,
      stopper_width_scale,
      stopper_height_scale,
      stopper_depth
    ]
  );
  emit_dimension_annotation(
    id="stem_bottom_width",
    label="stem_bottom_width",
    axis="x",
    value=stem_bottom_width,
    start=[-stem_bottom_width / 2, annotation_stem_back_y, annotation_stem_z],
    end=[stem_bottom_width / 2, annotation_stem_back_y, annotation_stem_z],
    basis="stem_bottom_width_on_stem_back_bottom_edge"
  );
  emit_dimension_annotation(
    id="stem_top_width",
    label="stem_top_width",
    axis="x",
    value=final_stem_top_width,
    start=[-final_stem_top_width / 2, annotation_stem_back_y, stem_height],
    end=[final_stem_top_width / 2, annotation_stem_back_y, stem_height],
    basis="stem_top_width_on_stem_back_top_edge"
  );
  emit_dimension_annotation(
    id="stem_height",
    label="stem_height",
    axis="z",
    value=stem_height,
    start=[annotation_side_x, annotation_stem_back_y, 0],
    end=[annotation_side_x, annotation_stem_back_y, stem_height],
    basis="stem_height"
  );
  emit_dimension_annotation(
    id="stem_depth",
    label="stem_depth",
    axis="y",
    value=stem_depth,
    start=[annotation_side_x, 0, annotation_stem_z],
    end=[annotation_side_x, -stem_depth, annotation_stem_z],
    basis="stem_depth_including_transition"
  );
  if (transition_depth_ratio > 0) {
    emit_dimension_annotation(
      id="transition_depth_ratio",
      label="transition_depth_ratio",
      axis="y",
      value=transition_depth_ratio,
      start=[annotation_side_x, annotation_transition_start_y, annotation_stem_z],
      end=[annotation_side_x, annotation_transition_end_y, annotation_stem_z],
      basis="transition_region_from_transition_depth_ratio"
    );
  }
  emit_dimension_annotation(
    id="stopper_depth",
    label="stopper_depth",
    axis="y",
    value=stopper_depth,
    start=[annotation_side_x, -stem_depth, annotation_stem_z],
    end=[annotation_side_x, -(stem_depth + stopper_depth), annotation_stem_z],
    basis="front_stopper_depth"
  );
}

emit_snap_gadget_plier_holder_annotations();
//align to front and bottom
up(model_z_offset) zrot(180) up(_threads_side_offset) xrot(90) {
    diff(remove="holder_thread_rm") {
      up(thread_join_overlap) fwd(_threads_side_offset + holder_root_offset) zrot(180) xrot(90) ycopies(n=plier_count, spacing=-holder_spacing, sp=[0, 0, 0])
          xrot(-final_holder_tilt_angle)
              diff(remove="root_rm") {
                diff() prismoid(size1=[stem_bottom_width, max(EPS, stem_base_depth)], size2=[final_stem_top_width, max(EPS, stem_base_depth)], h=stem_height, anchor=BACK + BOTTOM) {
                    edge_profile([BOTTOM + LEFT, BOTTOM + RIGHT], excess=2)
                      mask2d_teardrop(r=plier_prismoid_bottom_rounding, mask_angle=90 - plier_prismoid_side_angle);
                    edge_mask([TOP + LEFT, TOP + RIGHT])
                      rounding_edge_mask(l=$edge_length, r=plier_prismoid_top_rounding);
                  }
                fwd(max(EPS, stem_base_depth))
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
                            rounding_edge_mask(l=$edge_length + 2, r=max(EPS, stopper_front_rounding));
                          edge_mask([BOTTOM + FRONT], except=BACK)
                            teardrop_edge_mask(l=$edge_length + 2, r=max(EPS, stopper_front_rounding));
                          edge_mask([FRONT + RIGHT])
                            yrot(-stopper_side_angle) rounding_edge_mask(l=$edge_length + 2, r=max(EPS, stopper_front_rounding));
                          edge_mask([FRONT + LEFT])
                            yrot(stopper_side_angle) rounding_edge_mask(l=$edge_length + 2, r=max(EPS, stopper_front_rounding));
                        }
                  }
                if (add_spring_holes)
                  up(stem_height + stem_height * (stopper_height_scale - 1) * max(0, (transition_depth_ratio - 0.5)))
                    fwd(stem_depth / 2 + spring_hole_position_offset)
                      tag("root_rm") xcyl(h=20, r=spring_hole_radius);
              }
      tag("holder_thread_rm") up(thread_join_overlap) fwd(holder_thread_cutoff_offset + holder_root_offset)
        cuboid([500, 500, snap_thickness + thread_join_overlap * 2], anchor=FRONT + BOTTOM);
    }

      diff() {
        fwd(thread_clearance_offset)
          positive_snap_threads(threads_height=snap_thickness, threads_cfg=_threads_cfg, text_cfg=_text_cfg);
        tag("remove") fwd(thread_cutoff_offset - EPS) cuboid([500, 500, 500], anchor=BACK);
      }
    }
