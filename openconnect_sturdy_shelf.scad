/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
connector_cutout_delete_tool() is written by BlackJackDuck. https://github.com/AndyLevesque/QuackWorks
*/

/* [Main Settings] */
horizontal_grids = 3;
//Depth is not technically restrained by grid. You can override this with "use_custom_depth" below.
depth_grids = 3;
//"Standard" for maximum strength, "Slim" for lightweight applications.
shelf_type = "Standard"; //["Standard", "Slim"]
shelf_back_thickness = 4; //0.1
//When connector holes are enabled, bottom thickness would be at least 3.7mm.
shelf_bottom_thickness = 2.6;
//corner_fillet needs to be larger than thickness to have effect.
shelf_corner_fillet = 8;

/* [Truss Settings] */
truss_thickness = 2.6; //0.1
//0.75 means truss would reach 75% of shelf depth.
truss_beam_reach = 0.75; //[0.0:0.05:1]
//Space between each vertical truss strut. Set to 0 to disable.
truss_strut_interval = 28;

/* [Texture Settings] */
//Texture improves the appearance of the shelf by hiding layer lines and other artifacts caused by 3d printing.
add_texture = true;
shelf_texture_depth = 0.3;
//A small texture size makes model generation take longer.
shelf_texture_size = 20;

/* [Shelf Edge Settings] */
add_left_edge = true;
//Connector holes allow you to print shelf parts separately and later combine them together.
add_left_connector_holes = false;
add_right_edge = true;
//Connectors used here are the same as openGrid boards.
add_right_connector_holes = false;
shelf_side_edge_depth = 2;
add_front_edge = true;
shelf_front_edge_depth = 2;

/* [Slot Settings] */
//A slot is generated for every tile by default.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces. When printing on the side, place the locking mechanism side closer to the print bed.
slot_entryramp_flip = false;
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
//Minimum width for bridges. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/* [Advanced Settings] */
use_custom_depth = false;
custom_depth = 80;
truss_rounding = 3; //0.2
shelf_side_edge_thickness = 1;
shelf_front_edge_thickness = 1;

/* [Hidden] */
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>
slot_edge_feature_widen = "Side"; //[Both, Top, Side, None]

_slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance
);

//BEGIN shelf parameters
top_vertical_grids = 1;
bottom_vertical_grids = 1;
//Side edge angle is capped at 45 to avoid sharp overhang.
shelf_side_edge_angle = 45; //[15:15:45]
shelf_front_edge_angle = 45; //[15:15:90]

shelf_depth = use_custom_depth ? custom_depth : OG_TILE_SIZE * depth_grids;
shelf_width = OG_TILE_SIZE * horizontal_grids;

shelf_linewidth = 0.42;
final_shelf_bottom_thickness = add_left_connector_holes || add_right_connector_holes ? max(shelf_bottom_thickness, 2.4 + shelf_linewidth * 3) : shelf_bottom_thickness;
bottom_shelf_back_height = OG_TILE_SIZE * bottom_vertical_grids + final_shelf_bottom_thickness;
top_shelf_back_height = OG_TILE_SIZE * top_vertical_grids - final_shelf_bottom_thickness;

top_sweep_startend_offset = 2;
top_sweep_rect_height = min(shelf_back_thickness, final_shelf_bottom_thickness);
final_shelf_corner_fillet = shelf_corner_fillet < 4 ? 0 : min(top_shelf_back_height, shelf_depth, shelf_corner_fillet);
top_sweep_path = ["setdir", -90, "move", top_sweep_startend_offset, "arcleft", final_shelf_corner_fillet, 90, "move", top_sweep_startend_offset];
top_base_rect_2d = rect([top_sweep_rect_height, shelf_width], anchor=TOP + LEFT);
top_left_edge_2d = right(top_sweep_rect_height, zrot(-90, trapezoid(h=shelf_side_edge_depth, w1=shelf_side_edge_thickness + shelf_side_edge_depth, ang=[90, shelf_side_edge_angle], anchor=LEFT + BOTTOM)));
top_right_edge_2d = right(top_sweep_rect_height, fwd(shelf_width, zrot(-90, trapezoid(h=shelf_side_edge_depth, w1=shelf_side_edge_thickness + shelf_side_edge_depth, ang=[shelf_side_edge_angle, 90], anchor=RIGHT + BOTTOM))));
top_sweep_profile =
  !add_left_edge && !add_right_edge ? top_base_rect_2d
  : add_left_edge && add_right_edge ? union(top_base_rect_2d, top_left_edge_2d, top_right_edge_2d)
  : !add_left_edge ? union(top_base_rect_2d, top_right_edge_2d) : union(top_base_rect_2d, top_left_edge_2d);

truss_depth = truss_beam_reach <= 0 ? 0 : (shelf_depth - shelf_back_thickness) * truss_beam_reach;
truss_height = truss_beam_reach <= 0 ? 0 : bottom_shelf_back_height - final_shelf_bottom_thickness;
truss_angle = truss_beam_reach <= 0 ? 0 : adj_opp_to_ang(truss_depth, truss_height);
truss_inner_depth = truss_beam_reach <= 0 ? 0 : truss_depth - ang_opp_to_hyp(truss_angle, truss_thickness);
truss_inner_height = truss_beam_reach <= 0 ? 0 : truss_height - ang_adj_to_hyp(truss_angle, truss_thickness);
//END shelf parameters

shelf_annotation_y = -bottom_shelf_back_height + final_shelf_bottom_thickness;
shelf_annotation_z = shelf_width;

module emit_dimension_annotation(id, label, axis, value, start, end, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=dimension",
      "|label=", label,
      "|axis=", axis,
      "|value=", value,
      "|start=", start[0], ",", start[1], ",", start[2],
      "|end=", end[0], ",", end[1], ",", end[2],
      "|basis=", basis
    ));
}

function _fmt_context_values(names, values, index=0) =
  index >= len(names) ? "" :
  str(index == 0 ? "" : ";", names[index], "=", values[index], _fmt_context_values(names, values, index + 1));

module emit_context_values(id, names, values) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=context",
      "|values=", _fmt_context_values(names, values)
    ));
}

module emit_radius_annotation(id, label, value, center, edge, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=radius",
      "|label=", label,
      "|value=", value,
      "|center=", center[0], ",", center[1], ",", center[2],
      "|edge=", edge[0], ",", edge[1], ",", edge[2],
      "|basis=", basis
    ));
}

module emit_sturdy_shelf_annotations() {
  emit_context_values(
    "sturdy_shelf_context",
    [
      "OG_TILE_SIZE",
      "horizontal_grids",
      "depth_grids",
      "shelf_back_thickness",
      "shelf_bottom_thickness",
      "final_shelf_bottom_thickness",
      "shelf_corner_fillet",
      "final_shelf_corner_fillet",
      "shelf_depth",
      "shelf_width",
      "shelf_type",
      "truss_beam_reach",
      "truss_thickness",
      "truss_strut_interval",
      "truss_depth",
      "truss_height",
      "shelf_side_edge_depth",
      "shelf_front_edge_depth",
      "shelf_texture_depth"
    ],
    [
      OG_TILE_SIZE,
      horizontal_grids,
      depth_grids,
      shelf_back_thickness,
      shelf_bottom_thickness,
      final_shelf_bottom_thickness,
      shelf_corner_fillet,
      final_shelf_corner_fillet,
      shelf_depth,
      shelf_width,
      shelf_type,
      truss_beam_reach,
      truss_thickness,
      truss_strut_interval,
      truss_depth,
      truss_height,
      shelf_side_edge_depth,
      shelf_front_edge_depth,
      shelf_texture_depth
    ]
  );
  emit_dimension_annotation(
    id="shelf_depth",
    label=str("depth_grids x ", OG_TILE_SIZE, "mm"),
    axis="x",
    value=shelf_depth,
    start=[0, shelf_annotation_y, shelf_annotation_z],
    end=[shelf_depth, shelf_annotation_y, shelf_annotation_z],
    basis="front_to_back_depth"
  );
  emit_dimension_annotation(
    id="shelf_width",
    label=str("horizontal_grids x ", OG_TILE_SIZE, "mm"),
    axis="z",
    value=shelf_width,
    start=[0, shelf_annotation_y, 0],
    end=[0, shelf_annotation_y, shelf_width],
    basis="left_to_right_width"
  );
  emit_dimension_annotation(
    id="shelf_back_thickness",
    label="shelf_back_thickness",
    axis="x",
    value=shelf_back_thickness,
    start=[0, top_vertical_grids * OG_TILE_SIZE, shelf_width],
    end=[shelf_back_thickness, top_vertical_grids * OG_TILE_SIZE, shelf_width],
    basis="rear_lip_top_depth"
  );
  emit_dimension_annotation(
    id="shelf_bottom_thickness",
    label="shelf_bottom_thickness",
    axis="y",
    value=final_shelf_bottom_thickness,
    start=[shelf_depth, 0, shelf_width],
    end=[shelf_depth, final_shelf_bottom_thickness, shelf_width],
    basis="bottom_plate_thickness"
  );
  if (final_shelf_corner_fillet > EPS) {
    emit_radius_annotation(
      id="shelf_corner_fillet",
      label="shelf_corner_fillet",
      value=final_shelf_corner_fillet,
      center=[shelf_back_thickness + final_shelf_corner_fillet, bottom_shelf_back_height - final_shelf_corner_fillet, shelf_width],
      edge=[shelf_back_thickness, bottom_shelf_back_height - final_shelf_corner_fillet, shelf_width],
      basis="upper_back_shelf_corner_fillet"
    );
  }
  if (truss_beam_reach > EPS && truss_depth > EPS) {
    emit_dimension_annotation(
      id="truss_beam_reach",
      label="truss_beam_reach",
      axis="x",
      value=truss_depth,
      start=[shelf_back_thickness, shelf_annotation_y, shelf_width],
      end=[shelf_back_thickness + truss_depth, shelf_annotation_y, shelf_width],
      basis="bottom_truss_reach_from_back_wall"
    );
    emit_dimension_annotation(
      id="truss_thickness",
      label="truss_thickness",
      axis="x",
      value=truss_thickness,
      start=[shelf_back_thickness, final_shelf_bottom_thickness, shelf_width],
      end=[shelf_back_thickness + truss_thickness, final_shelf_bottom_thickness, shelf_width],
      basis="nominal_truss_member_thickness"
    );
  }
  if (truss_strut_interval > EPS && truss_depth > truss_strut_interval * 2) {
    emit_dimension_annotation(
      id="truss_strut_interval",
      label="truss_strut_interval",
      axis="x",
      value=truss_strut_interval,
      start=[shelf_back_thickness + truss_strut_interval, final_shelf_bottom_thickness, shelf_width],
      end=[shelf_back_thickness + truss_strut_interval * 2, final_shelf_bottom_thickness, shelf_width],
      basis="nominal_spacing_between_vertical_truss_struts"
    );
  }
  if (add_left_edge || add_right_edge) {
    emit_dimension_annotation(
      id="shelf_side_edge_depth",
      label="shelf_side_edge_depth",
      axis="z",
      value=shelf_side_edge_depth,
      start=[shelf_depth, final_shelf_bottom_thickness, 0],
      end=[shelf_depth, final_shelf_bottom_thickness, shelf_side_edge_depth],
      basis="nominal_side_edge_profile_depth"
    );
  }
  if (add_front_edge) {
    emit_dimension_annotation(
      id="shelf_front_edge_depth",
      label="shelf_front_edge_depth",
      axis="x",
      value=shelf_front_edge_depth,
      start=[shelf_depth - shelf_front_edge_depth, final_shelf_bottom_thickness, shelf_width],
      end=[shelf_depth, final_shelf_bottom_thickness, shelf_width],
      basis="nominal_front_edge_profile_depth"
    );
  }
}

emit_sturdy_shelf_annotations();

//BEGIN generation
diff(remove="outer_rm")
  cuboid([shelf_depth, final_shelf_bottom_thickness, shelf_width], anchor=FRONT + LEFT + BOTTOM) {
    rough_wall_alignment =
      add_left_edge == add_right_edge ? CENTER
      : add_left_edge ? BOTTOM : TOP;
    rough_wall_width_offset = (add_left_edge ? shelf_side_edge_depth + shelf_side_edge_thickness : 0) + (add_right_edge ? shelf_side_edge_depth + shelf_side_edge_thickness : 0);
    if (add_left_connector_holes)
      left(shelf_depth % OG_TILE_SIZE / 2)
        attach(TOP, LEFT, inside=true, align=FRONT, inset=shelf_linewidth * 2)
          tag("outer_rm") line_copies(spacing=OG_TILE_SIZE, n=floor(shelf_depth / OG_TILE_SIZE)) connector_cutout_delete_tool(anchor=LEFT);
    if (add_right_connector_holes)
      left(shelf_depth % OG_TILE_SIZE / 2)
        attach(BOTTOM, LEFT, inside=true, align=FRONT, inset=shelf_linewidth * 2)
          tag("outer_rm") line_copies(spacing=OG_TILE_SIZE, n=floor(shelf_depth / OG_TILE_SIZE)) connector_cutout_delete_tool(anchor=LEFT);
    if (add_texture)
      attach(BACK, BOTTOM, align=rough_wall_alignment)
        textured_tile("rough", w1=shelf_depth, w2=shelf_depth, ysize=shelf_width - rough_wall_width_offset, tex_depth=shelf_texture_depth, tex_size=[shelf_texture_size, shelf_texture_size], style="min_edge");
    if (add_left_edge)
      tag("") edge_profile([TOP + BACK], excess=0)
          back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
            yflip()
              mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
    if (add_right_edge)
      tag("") edge_profile([BOTTOM + BACK], excess=0)
          back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
            yflip()
              mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
    if (add_front_edge)
      tag("") edge_profile([BACK + RIGHT], excess=0)
          right(shelf_front_edge_thickness + (shelf_front_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_front_edge_angle, shelf_front_edge_depth)))
            mask2d_rabbet(size=[shelf_front_edge_thickness, shelf_front_edge_depth], mask_angle=shelf_front_edge_angle, spin=180);

    if (shelf_type != "Slim") {
      if (truss_inner_depth <= 0 || truss_inner_height <= 0 || truss_thickness <= EPS)
        right(shelf_back_thickness) edge_mask(LEFT + FRONT)
            tag("") rounding_edge_mask(r=min(truss_thickness * 3, OG_TILE_SIZE - final_shelf_bottom_thickness), spin=-90);
      //bottom shelf truss
      else {
        if (truss_inner_depth > 0 && truss_inner_height > 0) {
          truss_profile = difference(
            right_triangle([truss_depth, truss_height]),
            round_corners(joint=min(truss_rounding, truss_inner_depth / 2 - EPS, truss_inner_height / 2 - EPS), path=right_triangle([truss_inner_depth, truss_inner_height]))
          );
          if (truss_strut_interval > EPS) {
            truss_strut_count = floor((truss_inner_depth - floor(truss_inner_depth / truss_strut_interval) * truss_thickness) / truss_strut_interval);
            intersect() {
              for (i = [0:truss_strut_count - 1]) {
                attach(FRONT, BACK, align=LEFT, inset=(i + 1) * truss_strut_interval - i * truss_thickness)
                  tag("") cuboid([truss_thickness, truss_height, shelf_width]);
              }
              right(shelf_back_thickness) xflip()
                  attach(FRONT, FRONT, align=RIGHT)
                    tag("intersect") linear_sweep(right_triangle([truss_depth, truss_height]), shelf_width);
            }
          }
          right(shelf_back_thickness) xflip()
              attach(FRONT, FRONT, align=RIGHT)
                linear_sweep(truss_profile, shelf_width) {
                  if (truss_beam_reach < 1)
                    edge_mask([RIGHT + FRONT])
                      tag("") rounding_edge_mask(r=min(20, (shelf_depth - shelf_back_thickness) * (1 - truss_beam_reach)), h=shelf_width, ang=180 - truss_angle, spin=truss_angle);
                }
        }
      }
    }
    //unused top shelf corner filler
    if (final_shelf_corner_fillet > EPS)
      tag_diff(tag="", remove="remove") {
        attach(BACK, FRONT, align=LEFT, inset=shelf_back_thickness)
          cuboid([final_shelf_corner_fillet, final_shelf_corner_fillet, shelf_width])
            back(final_shelf_corner_fillet / 2 - final_shelf_bottom_thickness / 2) right(final_shelf_corner_fillet / 2 - shelf_back_thickness / 2)
                tag("remove") cyl(r=final_shelf_corner_fillet, h=shelf_width + EPS * 2);
      }
    //top shelf back
    tag_diff(tag="", remove="remove")
      attach(BACK, FRONT, align=LEFT)
        cuboid([shelf_back_thickness, top_shelf_back_height, shelf_width]) {
          if (add_texture)
            attach(RIGHT, BOTTOM, align=rough_wall_alignment)
              textured_tile("rough", w1=top_shelf_back_height, w2=top_shelf_back_height, ysize=shelf_width - rough_wall_width_offset, tex_depth=shelf_texture_depth, tex_size=[shelf_texture_size, shelf_texture_size], style="min_edge");
          if (add_left_edge)
            edge_profile([TOP + RIGHT], excess=0)
              back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
                yflip()
                  tag("") mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
          if (add_right_edge)
            edge_profile([BOTTOM + RIGHT], excess=0)
              back(shelf_side_edge_thickness + (shelf_side_edge_angle == 90 ? 0 : ang_opp_to_adj(shelf_side_edge_angle, shelf_side_edge_depth)))
                yflip()
                  tag("") mask2d_rabbet(size=[shelf_side_edge_thickness, shelf_side_edge_depth], mask_angle=shelf_side_edge_angle, spin=90);
          if (final_shelf_corner_fillet > EPS)
            right(max(0, shelf_back_thickness - final_shelf_bottom_thickness)) back(max(0, final_shelf_bottom_thickness - shelf_back_thickness)) fwd(final_shelf_bottom_thickness) fwd(top_shelf_back_height - final_shelf_corner_fillet - top_sweep_startend_offset)
                    attach(BACK + LEFT, BACK + LEFT, inside=true)
                      tag("") path_sweep(top_sweep_profile, path=path_merge_collinear(turtle(top_sweep_path)), scale=[1, 1], $fn=128);
          if (shelf_type == "Slim")
            attach(LEFT, TOP, inside=true, spin=90)
              tag("remove") openconnect_slot_grid(slot_cfg=_slot_cfg, horizontal_grids=horizontal_grids, vertical_grids=top_vertical_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=EPS);
        }
    //bottom back and slots
    fwd(shelf_type == "Slim" ? 0 : OG_TILE_SIZE)
      attach(FRONT + LEFT, FRONT + LEFT, inside=true)
        cuboid([shelf_back_thickness, shelf_type == "Slim" ? OG_TILE_SIZE : OG_TILE_SIZE * 2, shelf_width])
          attach(LEFT, TOP, align=BACK, inside=true, spin=90)
            tag("outer_rm") openconnect_slot_grid(slot_cfg=_slot_cfg, horizontal_grids=horizontal_grids, vertical_grids=shelf_type == "Standard" ? top_vertical_grids + bottom_vertical_grids : top_vertical_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=EPS);
  }
//END generation

//code by BlackJackDuck
module connector_cutout_delete_tool(anchor = CENTER, spin = 0, orient = UP) {
  //Begin connector cutout profile
  connector_cutout_radius = 2.6;
  connector_cutout_dimple_radius = 2.7;
  connector_cutout_separation = 2.5;
  connector_cutout_height = 2.4;
  dimple_radius = 0.75 / 2;

  attachable(anchor, spin, orient, size=[connector_cutout_radius * 2 - 0.1, connector_cutout_radius * 2, connector_cutout_height]) {
    //connector cutout tool
    tag_scope()
      translate([-connector_cutout_radius + 0.05, 0, -connector_cutout_height / 2])
        render()
          half_of(RIGHT, s=connector_cutout_dimple_radius * 4)
            linear_extrude(height=connector_cutout_height)
              union() {
                left(0.1)
                  diff() {
                    $fn = 50;
                    //primary round pieces
                    hull()
                      xcopies(spacing=connector_cutout_radius * 2)
                        circle(r=connector_cutout_radius);
                    //inset clip
                    tag("remove")
                      right(connector_cutout_radius - connector_cutout_separation)
                        ycopies(spacing=(connector_cutout_radius + connector_cutout_separation) * 2)
                          circle(r=connector_cutout_dimple_radius);
                    //dimple (ass) to force seam. Only needed for positive connector piece (not delete tool)
                    //tag("remove")
                    //right(connector_cutout_radius*2 + 0.45 )//move dimple in or out
                    //    yflip_copy(offset=(dimple_radius+connector_cutout_radius)/2)//both sides of the dimpme
                    //        rect([1,dimple_radius+connector_cutout_radius], rounding=[0,-connector_cutout_radius,-dimple_radius,0], $fn=32); //rect with rounding of inner flare and outer smoothing
                  }
                //outward flare fillet for easier insertion
                rect([1, connector_cutout_separation * 2 - (connector_cutout_dimple_radius - connector_cutout_separation)], rounding=[0, -.25, -.25, 0], $fn=32, corner_flip=true, anchor=LEFT);
              }
    children();
  }
}
