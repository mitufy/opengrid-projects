/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by David D's "openGrid - Minimal Hook". https://www.printables.com/model/1217962-opengrid-minimal-hook
Part of code is based on BlackjackDuck's "openGrid - Tile Generator". https://makerworld.com/en/models/1304337-opengrid-tile-generator
*/

include <BOSL2/std.scad>

/*[Main Settings]*/
vertical_grids = 1;
//Recommended width range is 6~20mm. For hooks wider than 20mm, check out openConnect Sturdy Hook Generator.
hook_width = 10;
hook_length = 16;
hook_back_thickness = 4;
hook_bottom_thickness = 4;
hook_corner_angle = 0; //[0:Horizontal, 45:Diagonal]
//Increace this value to make the corner of the hook sturdier.
hook_corner_fillet = 6;

/*[Hook Tip]*/
hook_tip_length = 8;
hook_tip_angle = 45; //[45:5:90]
hook_tip_thickness = 3;
hook_tip_shape = "Rectangular"; //[Round, Rectangular]
hook_tip_corner_fillet = 6;

/*[Hook Truss]*/
//Add a truss for more strength. Thanks to @agentharm for the idea!
truss_vertical_grid = 0;
truss_thickness = 3;
truss_rounding = 3;
//Truss angle is calculated according to truss height and hook length, then capped by truss_max_angle. Print with support if the result angle exceeds 45 degrees.
truss_max_angle = 45; //[15:5:75]

/*[Advanced Settings]*/
//Increase this value if you find the snap fit too tight.
framefit_snap_clearance = 0.1; //0.01
//3.4mm version can be installed simultaneously on both side of openGrid Standard board (6.8mm thick). Choose 4mm if there is no such need.
framefit_snap_depth = 4; //[4:"Lite - 4mm", 3.4:"Lite Basic - 3.4mm"]
hook_side_chamfer = 0.8;
//What is a hook anyways?
horizontal_grids = 1;

/*[Hidden]*/
$fa = 1;
$fs = 0.2;
eps = 0.005;
//0.42 is a common line width for 0.4mm nozzles.
framesnap_thickness = 0.84; // 0.42

hook_final_back_thickness = max(eps, hook_back_thickness);
hook_final_bottom_thickness = max(eps, hook_bottom_thickness);
hook_final_side_chamfer = max(eps, min(hook_final_back_thickness / 2 - eps, hook_final_bottom_thickness / 2 - eps, hook_side_chamfer));

tile_size = 28;
Tile_Thickness = 6.8;
Outside_Extrusion = 0.8;
Inside_Grid_Top_Chamfer = 0.4;
Inside_Grid_Middle_Chamfer = 1;
Top_Capture_Initial_Inset = 2.4;
Corner_Square_Thickness = 2.6;
Intersection_Distance = 4.2;
Tile_Inner_Size_Difference = 3;

//openGrid paramters
calculatedCornerSquare =
sqrt(tile_size ^ 2 + tile_size ^ 2) - 2 * sqrt(Intersection_Distance ^ 2 / 2) - Intersection_Distance / 2;
Tile_Inner_Size = tile_size - Tile_Inner_Size_Difference; // 25mm default
insideExtrusion = (tile_size - Tile_Inner_Size) / 2 - Outside_Extrusion; // 0.7 default
middleDistance = Tile_Thickness - Top_Capture_Initial_Inset * 2;
cornerChamfer = Top_Capture_Initial_Inset - Inside_Grid_Middle_Chamfer; // 1.4 default

CalculatedCornerChamfer = sqrt(Intersection_Distance ^ 2 / 2);
cornerOffset = CalculatedCornerChamfer + Corner_Square_Thickness; // 5.56985 (half of 11.1397)

path_tile = [[tile_size / 2, -tile_size / 2], [-tile_size / 2, -tile_size / 2]];

//negative part dimensions are based on David D's "openGrid - Minimal Hook"
negative_wall_profile = [
  [0, 0],
  [Outside_Extrusion + insideExtrusion + framefit_snap_clearance, 0],
  [Outside_Extrusion + insideExtrusion + framefit_snap_clearance, Top_Capture_Initial_Inset - Inside_Grid_Middle_Chamfer],
  [Outside_Extrusion + 0.2 + framefit_snap_clearance, Top_Capture_Initial_Inset - 0.4],
  [Outside_Extrusion + 0.2 + framefit_snap_clearance, 3.4],
  [Outside_Extrusion + 0.2 + framefit_snap_clearance + 0.5, 4],
  [0, 4],
];
negative_corner_profile = [
  [0, 0],
  [cornerOffset - 1.1 + framefit_snap_clearance, 0],
  [cornerOffset - 1.1 + framefit_snap_clearance, 0.4],
  [cornerOffset + framefit_snap_clearance, cornerChamfer + 0.1],
  [cornerOffset + framefit_snap_clearance, 4],
  [0, 4],
];

//function difference() has trouble handling extreme parameters and got worse when I updated BOSL2 on 2026-01-10. had to change minimum tip_angle from 1 to 3.
hook_final_tip_angle = max(3, hook_tip_angle - hook_corner_angle);
hook_final_tip_thickness = max(eps, min(hook_tip_thickness, hook_final_tip_angle == 90 ? 1000 : ang_adj_to_hyp(hook_final_tip_angle, hook_final_bottom_thickness)), hook_final_tip_angle == 90 ? eps : ang_hyp_to_adj(hook_final_tip_angle, hook_final_bottom_thickness));
hook_min_tip_length = hook_final_tip_angle == 90 ? hook_final_bottom_thickness : ang_hyp_to_opp(hook_final_tip_angle, hook_final_bottom_thickness + hook_final_side_chamfer / 2) + eps;
hook_final_tip_length = max(eps, hook_min_tip_length, hook_tip_length);
hook_final_width = tile_size * (horizontal_grids - 1) + hook_width;
hook_final_height = tile_size * vertical_grids;
hook_final_length = max(eps, hook_length);

large_opp = hook_final_tip_thickness * tan(hook_final_tip_angle);
large_hyp = hook_final_tip_thickness / cos(hook_final_tip_angle);
small_opp = large_hyp - hook_final_bottom_thickness;
small_hyp = small_opp / sin(hook_final_tip_angle);
small_adj = hook_final_tip_angle == 90 ? hook_final_tip_thickness : small_opp / tan(hook_final_tip_angle);

hook_min_tip_fillet = max(eps, min(1, hook_final_tip_length - hook_min_tip_length));
hook_final_corner_fillet = max(min(1, hook_final_bottom_thickness, hook_final_length, hook_final_back_thickness), min(hook_corner_fillet, hook_final_length - hook_min_tip_fillet - hook_final_bottom_thickness * tan(hook_corner_angle) - small_adj, hook_final_height - hook_final_bottom_thickness / cos(hook_corner_angle)));
hook_final_tip_fillet_pos_offset = hook_final_tip_angle == 90 ? hook_final_bottom_thickness : large_opp - small_hyp;
hook_max_tip_fillet = hook_final_tip_length - hook_final_tip_fillet_pos_offset;
hook_final_tip_fillet = max(hook_min_tip_fillet, min(hook_final_length - hook_final_corner_fillet - hook_final_bottom_thickness * tan(hook_corner_angle) - small_adj, hook_max_tip_fillet, hook_tip_corner_fillet));
hook_final_tip_fillet_diff = hook_max_tip_fillet - hook_final_tip_fillet;
hook_tip_point_fillet = max(eps, min(1, hook_final_tip_thickness / 2 - eps));

hook_has_tip = hook_tip_thickness >= eps && hook_tip_length >= eps;
hook_flat_top_width = hook_has_tip ? hook_final_length - hook_final_corner_fillet - hook_final_tip_fillet - small_adj - hook_final_bottom_thickness * tan(hook_corner_angle) : hook_final_length - hook_final_corner_fillet - hook_final_bottom_thickness * tan(hook_corner_angle);
corner_fillet_cut_shape = difference(
  [
    path_merge_collinear([[0, 0], [hook_final_corner_fillet * sin(hook_corner_angle), hook_final_corner_fillet * cos(hook_corner_angle)], [hook_final_corner_fillet, 0]]),
    path_merge_collinear(mask2d_roundover(joint=hook_final_corner_fillet, mask_angle=90 - hook_corner_angle)),
  ]
);
tip_inner_fillet_cut_shape = difference(
  [
    path_merge_collinear([[0, 0], [-ang_hyp_to_opp(90 - hook_final_tip_angle, hook_final_tip_fillet), ang_hyp_to_adj(90 - hook_final_tip_angle, hook_final_tip_fillet)], [hook_final_tip_fillet, 0]]),
    path_merge_collinear(mask2d_roundover(joint=hook_final_tip_fillet, mask_angle=180 - hook_final_tip_angle)),
  ]
);

diff() {
  cuboid([hook_final_width, hook_final_back_thickness, hook_final_height], anchor=FRONT) {
    zcopies(spacing=tile_size, n=vertical_grids)
      attach(FRONT, BOTTOM)
        frame_snap();
    //bottom truss
    if (truss_vertical_grid > 0 && hook_corner_angle == 0) {
      truss_angle = min(truss_max_angle, adj_opp_to_ang(truss_vertical_grid * tile_size, hook_final_length));
      attach(BOTTOM, TOP)
        cuboid([hook_final_width, hook_final_back_thickness, truss_vertical_grid * tile_size], anchor=FRONT) {
          zcopies(spacing=tile_size, n=truss_vertical_grid)
            attach(FRONT, BOTTOM)
              frame_snap();
          for (i = [1:truss_vertical_grid])
            attach(BACK, LEFT, align=TOP, spin=-90)
              truss_sweep(truss_height=i * tile_size, truss_thickness=truss_thickness, truss_width=hook_final_width, truss_rounding=truss_rounding, truss_angle=truss_angle);
        }
    }
    edge_mask([TOP + BACK])
      chamfer_edge_mask(chamfer=hook_final_side_chamfer);
    // corner_mask([TOP + BACK])
    // chamfer_corner_mask(chamfer=hook_final_side_chamfer);
    //applying bottom chamfer to diagonal hooks may make print surface too small.
    if (hook_corner_angle == 0 && truss_vertical_grid <= 0)
      edge_mask([BOTTOM + FRONT])
        chamfer_edge_mask(chamfer=hook_final_side_chamfer);
    //hook length bottom chamfer
    if (truss_vertical_grid <= 0)
      attach(BOTTOM, FRONT, align=FRONT, spin=90)
        tag("remove") offset_sweep(rect([hook_final_length + hook_final_back_thickness, 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
    //hook height front chamfer
    if (hook_final_length - hook_final_tip_fillet - hook_final_corner_fillet > hook_final_side_chamfer)
      attach(BACK, FRONT, align=TOP, spin=90)
        tag("remove") offset_sweep(rect([max(eps, hook_final_height - hook_final_corner_fillet - hook_final_bottom_thickness / cos(hook_corner_angle)), 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
    position(BACK + BOTTOM)
      xrot(hook_corner_angle) cuboid([hook_final_width, hook_final_length, hook_final_bottom_thickness], anchor=FRONT + BOTTOM) {
          //hook flat top chamfer
          if (hook_final_length - hook_final_tip_fillet - hook_final_corner_fillet > hook_final_side_chamfer)
            back(hook_final_corner_fillet + hook_final_bottom_thickness * tan(hook_corner_angle))
              attach(TOP, FRONT, align=FRONT, spin=90)
                tag("remove") offset_sweep(rect([max(eps, hook_flat_top_width), 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
          //hook corner fillet fill
          back(hook_final_corner_fillet + hook_final_bottom_thickness * tan(hook_corner_angle))
            position(FRONT + TOP)
              yrot(90) zrot(90) offset_sweep(mask2d_roundover(joint=hook_final_corner_fillet, mask_angle=90 - hook_corner_angle), height=hook_final_width, anchor=FRONT + RIGHT);
          //hook corner fillet chamfer
          if (hook_final_length - hook_final_tip_fillet - hook_final_corner_fillet > hook_final_side_chamfer)
            back(hook_final_corner_fillet + hook_final_bottom_thickness * tan(hook_corner_angle))
              position(FRONT + TOP)
                tag("remove") yrot(90) zrot(90) offset_sweep(corner_fillet_cut_shape, height=hook_final_width, anchor=FRONT + RIGHT, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
          if (hook_has_tip) {
            position(BACK + BOTTOM)
              xrot(hook_final_tip_angle - 90) cuboid([hook_final_width, hook_final_tip_thickness, hook_final_tip_length], anchor=BACK + BOTTOM) {
                  //hook tip fillet fill
                  down(max(eps, hook_final_tip_fillet_diff)) position(FRONT + TOP)
                      yrot(90) zrot(180) offset_sweep(mask2d_roundover(joint=hook_final_tip_fillet, mask_angle=180 - hook_final_tip_angle), height=hook_final_width, anchor=FRONT + RIGHT);
                  //hook tip fillet chamfer
                  if (hook_final_length - hook_final_tip_fillet - hook_final_corner_fillet > hook_final_side_chamfer)
                    down(max(eps, hook_final_tip_fillet_diff)) position(FRONT + TOP)
                        tag("remove") yrot(90) zrot(180) offset_sweep(tip_inner_fillet_cut_shape, height=hook_final_width, anchor=FRONT + RIGHT, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
                  //hook tip rect top chamfer
                  if (hook_final_length - hook_final_tip_fillet - hook_final_corner_fillet > hook_final_side_chamfer)
                    attach(FRONT, FRONT, align=TOP, spin=90)
                      tag("remove") offset_sweep(rect([max(eps, hook_final_tip_fillet_diff), 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
                  //hook tip rect bottom chamfer
                  if (truss_vertical_grid <= 0)
                    attach(BACK, FRONT, align=BOTTOM, spin=90)
                      tag("remove") offset_sweep(rect([hook_final_tip_length, 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
                  if (hook_tip_shape == "Rectangular" || horizontal_grids > 1) {
                    edge_mask(FRONT + TOP)
                      rounding_edge_mask(r=min(max(eps, hook_final_tip_fillet / 5), hook_tip_point_fillet, hook_final_side_chamfer, hook_final_tip_length - hook_min_tip_length), ang=95);
                    edge_mask(BACK + TOP)
                      chamfer_edge_mask(chamfer=hook_final_side_chamfer);
                    corner_mask([TOP + LEFT + BACK, TOP + RIGHT + BACK])
                      chamfer_corner_mask(chamfer=hook_final_side_chamfer);
                    edge_mask([TOP + LEFT, TOP + RIGHT])
                      chamfer_edge_mask(chamfer=hook_final_side_chamfer);
                  } else {
                    edge_mask([TOP + LEFT, TOP + RIGHT])
                      rounding_edge_mask(l=hook_final_tip_thickness + hook_final_tip_fillet, r=hook_final_width / 2);
                  }
                }
          }
        }
  }
  if (hook_corner_angle != 0)
    tag("remove") down(hook_final_height / 2) left(hook_final_width / 2) back(hook_final_back_thickness) zrot(90) xrot(90) offset_sweep(mask2d_chamfer(hook_final_length, mask_angle=hook_corner_angle), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
}
module frame_snap(anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[tile_size, tile_size, framefit_snap_depth]) {
    down(framefit_snap_depth / 2) xflip_copy() yflip_copy()
          intersection() {
            difference() {
              cube([min(min(hook_width, 11) / 2, tile_size / 2), tile_size / 2, framefit_snap_depth]);
              up(3.4) right(1.1 - eps) prismoid(size1=[0, tile_size / 2], h=1, xang=135, yang=90, anchor=BOTTOM + FRONT);
              //a prismoid to cut off overhang from snap. calculated position is not precise but works well enough.
              back(tile_size / 2 - (5.2 - min(min(hook_width, 11), tile_size) / 2)) up(eps) prismoid(size1=[hook_width, 0], xang=90, yang=135, h=tile_size / 2);
            }
            right(tile_size / 2) zrot(-90)
                difference() {
                  //offset grid created with minkowski
                  union() {
                    minkowski() {
                      path_extrude2d(path_tile) polygon(negative_wall_profile);
                      sphere(framesnap_thickness);
                    }
                    move([-tile_size / 2, -tile_size / 2]) rotate([0, 0, 45]) back(cornerOffset) rotate([90, 0, 0])
                            minkowski() {
                              linear_extrude(cornerOffset * 2) polygon(negative_corner_profile);
                              sphere(framesnap_thickness);
                            }
                  }
                  //original negative grid
                  union() {
                    path_extrude2d(path_tile) polygon(negative_wall_profile);
                    move([-tile_size / 2, -tile_size / 2]) rotate([0, 0, 45]) back(cornerOffset) rotate([90, 0, 0])
                            linear_extrude(cornerOffset * 2) polygon(negative_corner_profile);
                  }
                }
          }

    children();
  }
}
module truss_sweep(truss_height, truss_thickness, truss_width, truss_rounding = eps, truss_angle = 45) {
  truss_depth = ang_adj_to_opp(truss_angle, truss_height);
  truss_final_thickness = max(eps, min(truss_depth / 2 - eps, truss_thickness));
  truss_inner_depth = truss_depth - ang_adj_to_hyp(truss_angle, truss_final_thickness);
  truss_inner_height = truss_height - ang_opp_to_hyp(truss_angle, truss_final_thickness);
  truss_final_rounding = max(eps, min(truss_inner_depth / 2 - eps, truss_inner_height / 2 - eps, truss_rounding));
  truss_profile = difference(
    right_triangle([truss_depth, truss_height]),
    round_corners(joint=truss_final_rounding, path=right_triangle([truss_inner_depth, truss_inner_height]))
  );
  linear_sweep(truss_profile, hook_final_width);
}
