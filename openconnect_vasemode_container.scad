/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
//Recommended: 150-200% of nozzle size (e.g. 0.6–0.8mm for a 0.4mm nozzle). Higher values may work, feel free to experiment.
vase_linewidth = 0.6;
//Multiple containers of same texture can be installed side by side as the pattern is designed to be complementary.
vase_surface_texture = "checkers"; //["":None, "cubes":Cubes, "diamonds":Diagonal Ribs,"wave_ribs":Wave Ribs,"checkers":Checkers]

horizontal_grids = 2;
vertical_grids = 3;
//Depth is not technically restrained by grid. You can override this with "use_custom_depth" below.
depth_grids = 2;

//Tilt the container forward for easier access of content. Set to 0 for a standard vertical container.
vase_tilt_angle = 15; //[0:5:45]
//Serves similar purpose as tilt_angle by insetting the front face of the container.
vase_front_inset_angle = 0; //[0:5:45]

/* [Label Settings] */
//"Split" option allows two narrow containers placed side-by-side to share a single, long label.
label_holder_type = "None"; //["None", "Standard", "Split-Left", "Split-Right"]
label_width = 48;
label_height = 10;
label_thickness = 1;

/* [Advanced Settings] */
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Manually offset the horizontal position of the slots.
slot_horizontal_offset = 0; //0.1
//Manually offset the vertical position of the slots.
slot_vertical_offset = 0; //0.1
//Increase clearances if the slots feel too tight.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
use_custom_depth = false;
custom_depth = 60;
surface_texture_size = 7;
surface_texture_depth = 1; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;
// Render-only approximation of the single-wall object produced by slicer vase mode.
render_vase_print_preview = false;
include <lib/annotation_metadata.scad>
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>

//BEGIN container parameters
final_horizontal_grids = max(1, floor(horizontal_grids));
final_vertical_grids = max(1, floor(vertical_grids));
final_depth_grids = max(1, floor(depth_grids));
final_vase_linewidth = max(0.01, vase_linewidth);
final_slot_side_clearance = max(0, slot_side_clearance);
final_slot_depth_clearance = max(0, slot_depth_clearance);
final_label_width = max(0.01, label_width);
final_label_height = max(0.01, label_height);
final_label_thickness = max(0.01, label_thickness);
final_surface_texture_depth = max(EPS, surface_texture_depth);
final_vase_tilt_limit = min(45, max(0, vase_tilt_angle));
final_vase_front_inset_limit = min(45, max(0, vase_front_inset_angle));

vase_width = OG_TILE_SIZE * final_horizontal_grids;
vase_depth = max(1, use_custom_depth ? custom_depth : OG_TILE_SIZE * final_depth_grids);
vase_grid_height = OG_TILE_SIZE * final_vertical_grids;
final_vase_tilt_angle = min(adj_opp_to_ang(vase_grid_height, vase_depth - 1), final_vase_tilt_limit);
vase_slot_overhang_angle = max(45, 45 + final_vase_tilt_angle - 15);
vase_height = ang_hyp_to_adj(final_vase_tilt_angle, vase_grid_height);
_slot_cfg = ocslot_cfg(
  side_clearance=final_slot_side_clearance,
  depth_clearance=final_slot_depth_clearance,
  vase_linewidth=final_vase_linewidth,
  vase_overhang_angle=vase_slot_overhang_angle
);
final_vase_front_inset_angle = min(adj_opp_to_ang(vase_height, max(0, vase_depth - ang_adj_to_opp(final_vase_tilt_angle, vase_height) - 1)), final_vase_front_inset_limit);
final_surface_texture_size = max(1, surface_texture_size) * (vase_surface_texture == "checkers" || vase_surface_texture == "cubes" ? 2 : 1);
vase_bottom_edge_back_offset = ang_hyp_to_opp(final_vase_tilt_angle, vase_grid_height) / 2;

label_overhang_angle = max(10, 45 - final_vase_front_inset_angle);
label_side_clearance = 0.2;
label_depth_clearance = 0.3;
label_holder_wall_thickness = final_vase_linewidth * 2;
label_holder_depth = final_label_thickness + label_depth_clearance + label_holder_wall_thickness;
label_holder_side_width = final_vase_linewidth * 4;
label_move =
  label_holder_type == "Split-Left" ? -vase_width / 2
  : label_holder_type == "Split-Right" ? vase_width / 2 : 0;
//END container parameters

function vase_annotation_back_y_at_z(z) = ang_adj_to_opp(final_vase_tilt_angle, z);
function vase_annotation_front_y_at_z(z) = vase_annotation_back_y_at_z(z) - vase_depth + ang_adj_to_opp(final_vase_front_inset_angle, z);
vase_annotation_x_min = 0;
vase_annotation_x_max = vase_width;
vase_annotation_z_min = 0;
vase_annotation_z_max = vase_height;
vase_annotation_back_y = vase_annotation_back_y_at_z(vase_annotation_z_min);
vase_annotation_back_top_y = vase_annotation_back_y_at_z(vase_annotation_z_max);
vase_annotation_front_top_y = vase_annotation_front_y_at_z(vase_annotation_z_max);
vase_annotation_mid_y = (vase_annotation_back_top_y + vase_annotation_front_top_y) / 2;
vase_annotation_visible_x = vase_annotation_x_max;
vase_tilt_angle_anchor = [vase_annotation_x_max, vase_annotation_back_y, vase_annotation_z_min];
vase_tilt_angle_arc_radius = max(vase_height, OG_TILE_SIZE);
vase_tilt_angle_arc_segments = 12;
function vase_tilt_angle_arc_point(angle) =
  [
    vase_tilt_angle_anchor[0],
    vase_tilt_angle_anchor[1] + sin(angle) * vase_tilt_angle_arc_radius,
    vase_tilt_angle_anchor[2] + cos(angle) * vase_tilt_angle_arc_radius,
  ];
vase_tilt_angle_arc_points = [
  for (i = [0:vase_tilt_angle_arc_segments]) vase_tilt_angle_arc_point(final_vase_tilt_angle * i / vase_tilt_angle_arc_segments),
];
vase_tilt_angle_radius_edge = vase_tilt_angle_arc_point(final_vase_tilt_angle / 2);

vase_front_inset_angle_anchor = [vase_annotation_x_max, vase_annotation_front_top_y, vase_annotation_z_max];
vase_front_inset_angle_arc_radius = max(OG_TILE_SIZE, vase_height / 2);
vase_front_inset_angle_arc_segments = 12;
function vase_front_inset_angle_arc_point(angle) =
  [
    vase_front_inset_angle_anchor[0],
    vase_front_inset_angle_anchor[1] - sin(angle) * vase_front_inset_angle_arc_radius,
    vase_front_inset_angle_anchor[2] - cos(angle) * vase_front_inset_angle_arc_radius,
  ];
vase_front_inset_angle_arc_points = [
  for (i = [0:vase_front_inset_angle_arc_segments]) vase_front_inset_angle_arc_point(final_vase_front_inset_angle * i / vase_front_inset_angle_arc_segments),
];
vase_front_inset_angle_radius_edge = vase_front_inset_angle_arc_point(final_vase_front_inset_angle / 2);

label_annotation_x_min = vase_width / 2 + label_move - final_label_width / 2;
label_annotation_x_max = vase_width / 2 + label_move + final_label_width / 2;
label_annotation_y = vase_annotation_front_top_y - label_holder_depth;
label_annotation_z_min = max(0, vase_annotation_z_max - final_label_height);
label_annotation_z_max = vase_annotation_z_max;

module emit_vasemode_container_annotations() {
  emit_context_values(
    "vasemode_container_context",
    [
      "OG_TILE_SIZE",
      "vase_linewidth",
      "final_vase_linewidth",
      "vase_surface_texture",
      "horizontal_grids",
      "vertical_grids",
      "depth_grids",
      "final_horizontal_grids",
      "final_vertical_grids",
      "final_depth_grids",
      "vase_width",
      "vase_depth",
      "vase_grid_height",
      "vase_height",
      "vase_tilt_angle",
      "final_vase_tilt_angle",
      "vase_front_inset_angle",
      "final_vase_front_inset_angle",
      "label_holder_type",
      "label_width",
      "label_height",
      "label_thickness",
      "slot_position",
      "slot_lock_distribution",
      "slot_side_clearance",
      "slot_depth_clearance",
      "surface_texture_size",
      "surface_texture_depth",
      "final_surface_texture_size",
    ],
    [
      OG_TILE_SIZE,
      vase_linewidth,
      final_vase_linewidth,
      vase_surface_texture,
      horizontal_grids,
      vertical_grids,
      depth_grids,
      final_horizontal_grids,
      final_vertical_grids,
      final_depth_grids,
      vase_width,
      vase_depth,
      vase_grid_height,
      vase_height,
      vase_tilt_angle,
      final_vase_tilt_angle,
      vase_front_inset_angle,
      final_vase_front_inset_angle,
      label_holder_type,
      label_width,
      label_height,
      label_thickness,
      slot_position,
      slot_lock_distribution,
      slot_side_clearance,
      slot_depth_clearance,
      surface_texture_size,
      final_surface_texture_depth,
      final_surface_texture_size,
    ]
  );
  emit_dimension_annotation(
    id="horizontal_grids",
    label="horizontal_grids",
    axis="x",
    value=vase_width,
    start=[vase_annotation_x_min, vase_annotation_back_top_y, vase_annotation_z_max],
    end=[vase_annotation_x_max, vase_annotation_back_top_y, vase_annotation_z_max],
    basis="overall_container_width_from_horizontal_grids"
  );
  emit_dimension_annotation(
    id="vertical_grids",
    label="vertical_grids",
    axis="z",
    value=vase_grid_height,
    start=[vase_annotation_visible_x, vase_annotation_back_y, vase_annotation_z_min],
    end=[vase_annotation_visible_x, vase_annotation_back_top_y, vase_annotation_z_max],
    basis="nominal_container_height_from_vertical_grids"
  );
  emit_dimension_annotation(
    id="depth_grids",
    label="depth_grids",
    axis="y",
    value=vase_depth,
    start=[vase_annotation_visible_x, vase_annotation_back_top_y, vase_annotation_z_max],
    end=[vase_annotation_visible_x, vase_annotation_front_top_y, vase_annotation_z_max],
    basis="container_depth_from_depth_grids_or_custom_depth"
  );
  emit_dimension_annotation(
    id="vase_linewidth",
    label="vase_linewidth",
    axis="x",
    value=final_vase_linewidth,
    start=[vase_annotation_visible_x - final_vase_linewidth, vase_annotation_back_top_y, vase_annotation_z_max],
    end=[vase_annotation_visible_x, vase_annotation_back_top_y, vase_annotation_z_max],
    basis="single_wall_vase_mode_line_width"
  );
  emit_feature_annotation(
    id="vase_tilt_angle",
    label="vase_tilt_angle",
    value=final_vase_tilt_angle,
    anchor=vase_tilt_angle_anchor,
    basis="bottom_side_corner_for_vase_tilt_angle"
  );
  if (final_vase_tilt_angle > 0) {
    emit_radius_annotation(
      id="vase_tilt_angle_radius",
      label="vase_tilt_angle_radius",
      value=vase_tilt_angle_arc_radius,
      center=vase_tilt_angle_anchor,
      edge=vase_tilt_angle_radius_edge,
      basis="vase_tilt_angle_anchor_to_arc_midpoint"
    );
    emit_arc_annotation(
      id="vase_tilt_angle_extent",
      label="vase_tilt_angle_extent",
      value=final_vase_tilt_angle,
      points=vase_tilt_angle_arc_points,
      basis="side_arc_for_vase_tilt_angle"
    );
  }
  emit_feature_annotation(
    id="vase_front_inset_angle",
    label="vase_front_inset_angle",
    value=final_vase_front_inset_angle,
    anchor=vase_front_inset_angle_anchor,
    basis="top_front_side_corner_for_vase_front_inset_angle"
  );
  if (final_vase_front_inset_angle > 0) {
    emit_radius_annotation(
      id="vase_front_inset_angle_radius",
      label="vase_front_inset_angle_radius",
      value=vase_front_inset_angle_arc_radius,
      center=vase_front_inset_angle_anchor,
      edge=vase_front_inset_angle_radius_edge,
      basis="front_inset_angle_anchor_to_arc_midpoint"
    );
    emit_arc_annotation(
      id="vase_front_inset_angle_extent",
      label="vase_front_inset_angle_extent",
      value=final_vase_front_inset_angle,
      points=vase_front_inset_angle_arc_points,
      basis="side_arc_for_vase_front_inset_angle"
    );
  }
  if (vase_surface_texture != "") {
    emit_dimension_annotation(
      id="surface_texture_size",
      label="surface_texture_size",
      axis="z",
      value=final_surface_texture_size,
      start=[vase_annotation_visible_x, vase_annotation_mid_y, vase_annotation_z_min],
      end=[vase_annotation_visible_x, vase_annotation_mid_y, vase_annotation_z_min + final_surface_texture_size],
      basis="visible_surface_texture_repeat_size"
    );
    emit_dimension_annotation(
      id="surface_texture_depth",
      label="surface_texture_depth",
      axis="y",
      value=final_surface_texture_depth,
      start=[vase_annotation_visible_x, vase_annotation_front_top_y, vase_annotation_z_max / 2],
      end=[vase_annotation_visible_x, vase_annotation_front_top_y - final_surface_texture_depth, vase_annotation_z_max / 2],
      basis="surface_texture_relief_depth"
    );
  }
  if (label_holder_type != "None") {
    emit_dimension_annotation(
      id="label_width",
      label="label_width",
      axis="x",
      value=final_label_width,
      start=[label_annotation_x_min, label_annotation_y, label_annotation_z_max],
      end=[label_annotation_x_max, label_annotation_y, label_annotation_z_max],
      basis="label_slot_clear_width"
    );
    emit_dimension_annotation(
      id="label_height",
      label="label_height",
      axis="z",
      value=final_label_height,
      start=[label_annotation_x_max, label_annotation_y, label_annotation_z_min],
      end=[label_annotation_x_max, label_annotation_y, label_annotation_z_max],
      basis="label_slot_clear_height"
    );
    emit_dimension_annotation(
      id="label_thickness",
      label="label_thickness",
      axis="y",
      value=final_label_thickness,
      start=[label_annotation_x_max, vase_annotation_front_top_y, label_annotation_z_min],
      end=[label_annotation_x_max, vase_annotation_front_top_y - final_label_thickness, label_annotation_z_min],
      basis="label_insert_depth"
    );
  }
}

emit_vasemode_container_annotations();

//BEGIN generation
module render_vasemode_container_source_mesh(addgrid = true) {
  right(vase_width / 2) zrot(180) fwd(vase_bottom_edge_back_offset)
        up(vase_height / 2) xrot(90 + final_vase_tilt_angle) {
            xrot(-final_vase_tilt_angle)
              diff(remove="root_rm") diff(remove="remove", keep="keep root_rm")
                  prismoid(size1=[vase_width, vase_depth], h=vase_height, xang=[90, 90], yang=[90 - final_vase_front_inset_angle, 90 - final_vase_tilt_angle], chamfer=0, orient=FRONT, anchor=BACK) {
                    if (addgrid)
                      attach(BACK, BOTTOM, spin=180)
                        right(slot_horizontal_offset) back(slot_vertical_offset)
                          openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="vase", horizontal_grids=final_horizontal_grids, vertical_grids=final_vertical_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution);
                    if (vase_surface_texture != "") {
                      frontwall_height = ang_adj_to_hyp(final_vase_front_inset_angle, vase_height) + ang_adj_to_opp(final_vase_front_inset_angle, final_surface_texture_depth);
                      quant_texture_size = vase_surface_texture == "cubes" ? sqrt(3) * final_surface_texture_size : final_surface_texture_size;
                      final_wall_height = quantup(frontwall_height, quant_texture_size);
                      final_wall_width = quantup(vase_width, quant_texture_size);
                      final_wall_depth = quantup(vase_depth, quant_texture_size);
                      final_texture = vase_surface_texture == "checkers" ? texture(vase_surface_texture, border=0.2) : texture(vase_surface_texture);
                      texture_trim_mask_size = max(400, max([final_wall_width, final_wall_depth, final_wall_height, vase_width, vase_depth, vase_height]) + max(final_surface_texture_depth, label_holder_depth) * 4 + OG_TILE_SIZE * 2);
                      texture_trim_mask = [texture_trim_mask_size, texture_trim_mask_size, texture_trim_mask_size];
                      diff(remove="frontwall_rm") {
                        attach(FRONT, BOTTOM, align=BOTTOM)
                          textured_tile(final_texture, w1=final_wall_width, w2=final_wall_width, shift=0, ysize=final_wall_height, tex_depth=final_surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]) {
                            if (label_holder_type != "None")
                              right(label_move) tag("frontwall_rm")
                                  attach(TOP, BOTTOM, align=FRONT, inside=true, shiftout=EPS)
                                    prismoid(size2=[final_label_width + label_side_clearance * 2, final_label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=final_surface_texture_depth);
                          }
                        tag("frontwall_rm") attach(BOTTOM, BACK)
                            cuboid(texture_trim_mask);
                        tag("frontwall_rm") attach(LEFT, BACK)
                            cuboid(texture_trim_mask);
                        tag("frontwall_rm") attach(RIGHT, BACK)
                            cuboid(texture_trim_mask);
                      }
                      diff(remove="sidewall_rm") {
                        attach(LEFT, BOTTOM, align=BOTTOM)
                          textured_tile(final_texture, w1=final_wall_depth, w2=final_wall_depth, shift=0, ysize=final_wall_height, tex_depth=final_surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                        tag("sidewall_rm") attach(FRONT, BACK)
                            cuboid(texture_trim_mask);
                        tag("sidewall_rm") attach(BACK, BACK)
                            cuboid(texture_trim_mask);
                      }
                      tag("remove") diff(remove="sidewall_rm") {
                          attach(RIGHT, BOTTOM, inside=true, align=BOTTOM)
                            textured_tile(final_texture, w1=final_wall_depth, w2=final_wall_depth, shift=0, ysize=final_wall_height, tex_depth=final_surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                          tag("sidewall_rm") attach(FRONT, BACK, shiftout=EPS)
                              cuboid(texture_trim_mask);
                          tag("sidewall_rm") attach(BACK, BACK, shiftout=EPS)
                              cuboid(texture_trim_mask);
                        }
                      tag("root_rm")
                        left(final_surface_texture_depth + 1) fwd(final_surface_texture_depth + 1)
                            edge_profile([LEFT + FRONT], excess=10)
                              mask2d_chamfer(x=final_surface_texture_depth * 2 + 2);
                      tag("root_rm")
                        right(final_surface_texture_depth) fwd(final_surface_texture_depth + 1)
                            edge_profile([RIGHT + FRONT], excess=10)
                              mask2d_chamfer(x=final_surface_texture_depth * 3 + 1);
                      tag("root_rm") attach(TOP, BACK)
                          cuboid(texture_trim_mask);
                    }
                    else
                      tag("root_rm")
                        edge_profile([LEFT + FRONT, RIGHT + FRONT], excess=10)
                          mask2d_chamfer(x=1);
                    if (label_holder_type != "None")
                      right(label_move)
                        tag_diff(tag="keep", remove="rm0") {
                          if (label_holder_type != "Split-Right")
                            right((final_label_width + label_side_clearance * 2) / 2)
                              attach(FRONT, BOTTOM, align=BOTTOM)
                                tag("") prismoid(size2=[label_holder_side_width, final_label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth) {
                                    attach(LEFT + BOTTOM, LEFT + BOTTOM, align=FRONT, inside=true)
                                      tag("rm0") prismoid(size2=[label_holder_side_width - final_vase_linewidth * 2, final_label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth - label_holder_wall_thickness);
                                  }
                          if (label_holder_type != "Split-Left")
                            left((final_label_width + label_side_clearance * 2) / 2)
                              attach(FRONT, BOTTOM, align=BOTTOM)
                                tag("") prismoid(size2=[label_holder_side_width, final_label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth) {
                                    attach(RIGHT + BOTTOM, RIGHT + BOTTOM, align=FRONT, inside=true)
                                      tag("rm0") prismoid(size2=[label_holder_side_width - final_vase_linewidth * 2, final_label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth - label_holder_wall_thickness);
                                  }
                        }
                  }
          }
}

if (render_vase_print_preview)
  difference() {
    render_vasemode_container_source_mesh();
    up(final_vase_linewidth)
      right(final_vase_linewidth)
        scale([1 - final_vase_linewidth * 2 / vase_width, 1 - final_vase_linewidth * 2 / vase_depth, 1])
          render_vasemode_container_source_mesh(addgrid=false);
  }
else
  render_vasemode_container_source_mesh();
//END generation
