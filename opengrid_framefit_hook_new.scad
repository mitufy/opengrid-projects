/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by David D's "openGrid - Minimal Hook". https://www.printables.com/model/1217962-opengrid-minimal-hook
Part of code is based on BlackjackDuck's "openGrid - Tile Generator". https://makerworld.com/en/models/1304337-opengrid-tile-generator

2025-09-14 Update: Added diagonal hook option. Design has been revamped, now the hook consists of multiple cuboid instead of one extruded polygon. 
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
/*[Hook Main Settings]*/
vertical_grids = 1;
//Setting width too low reduces stability. The absolute minimum width is 5.
hook_width = 10;
hook_length = 16;
hook_corner_angle = 0; //[0:Horizontal, 45:Diagonal]
//Increace this value to make the corner of the hook sturdier.
hook_corner_fillet = 6;
hook_back_thickness = 4;
hook_bottom_thickness = 4;

/*[Hook Tip Settings]*/
hook_tip_length = 8;
hook_tip_angle = 45; //[45:5:90]
hook_tip_thickness = 3;
hook_tip_shape = "Rectangular"; //[Round, Rectangular]
hook_tip_corner_fillet = 6;

/*[Advanced Settings]*/
hook_side_chamfer = 0.8;
//Increase this value if you find the snap fit too tight.
snap_clearance = 0.1; //0.01
//3.4mm version makes it possible to install simultaneously on both side of openGrid board (6.8mm thick). If there is no such need, 4mm version is recommended.
snap_depth = 4; //[4:4mm, 3.4:3.4mm]
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
snap_height = 28 - hook_final_side_chamfer * 2;

tileSize = 28;
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
sqrt(tileSize ^ 2 + tileSize ^ 2) - 2 * sqrt(Intersection_Distance ^ 2 / 2) - Intersection_Distance / 2;
Tile_Inner_Size = tileSize - Tile_Inner_Size_Difference; // 25mm default
insideExtrusion = (tileSize - Tile_Inner_Size) / 2 - Outside_Extrusion; // 0.7 default
middleDistance = Tile_Thickness - Top_Capture_Initial_Inset * 2;
cornerChamfer = Top_Capture_Initial_Inset - Inside_Grid_Middle_Chamfer; // 1.4 default

CalculatedCornerChamfer = sqrt(Intersection_Distance ^ 2 / 2);
cornerOffset = CalculatedCornerChamfer + Corner_Square_Thickness; // 5.56985 (half of 11.1397)

path_tile = [[tileSize / 2, -tileSize / 2], [-tileSize / 2, -tileSize / 2]];

//negative part dimensions are based on David D's "openGrid - Minimal Hook"
negative_wall_profile = [
  [0, 0],
  [Outside_Extrusion + insideExtrusion + snap_clearance, 0],
  [Outside_Extrusion + insideExtrusion + snap_clearance, Top_Capture_Initial_Inset - Inside_Grid_Middle_Chamfer],
  [Outside_Extrusion + 0.2 + snap_clearance, Top_Capture_Initial_Inset - 0.4],
  [Outside_Extrusion + 0.2 + snap_clearance, 3.4],
  [Outside_Extrusion + 0.2 + snap_clearance + 0.5, 4],
  [0, 4],
];
negative_corner_profile = [
  [0, 0],
  [cornerOffset - 1.1 + snap_clearance, 0],
  [cornerOffset - 1.1 + snap_clearance, 0.4],
  [cornerOffset + snap_clearance, cornerChamfer + 0.1],
  [cornerOffset + snap_clearance, 4],
  [0, 4],
];

//it seems rounding_mask generation has trouble handling extreme parameters. Setting to minimum to eps won't work here.
hook_final_tip_angle = max(1, hook_tip_angle - hook_corner_angle);
hook_final_tip_thickness = max(eps, min(hook_tip_thickness, hook_final_tip_angle == 90 ? 1000 : ang_adj_to_hyp(hook_final_tip_angle, hook_final_bottom_thickness)), hook_final_tip_angle == 90 ? eps : ang_hyp_to_adj(hook_final_tip_angle, hook_final_bottom_thickness));
hook_min_tip_length = hook_final_tip_angle == 90 ? hook_final_bottom_thickness : ang_hyp_to_opp(hook_final_tip_angle, hook_final_bottom_thickness + hook_final_side_chamfer / 2) + eps;
hook_final_tip_length = max(eps, hook_min_tip_length, hook_tip_length);
hook_final_width = tileSize * (horizontal_grids - 1) + hook_width;
hook_final_height = tileSize * vertical_grids;
hook_final_length = max(eps, hook_length);

large_opp = hook_final_tip_thickness * tan(hook_final_tip_angle);
large_hyp = hook_final_tip_thickness / cos(hook_final_tip_angle);
small_opp = large_hyp - hook_final_bottom_thickness;
small_hyp = small_opp / sin(hook_final_tip_angle);
small_adj = hook_final_tip_angle == 90 ? hook_final_tip_thickness : small_opp / tan(hook_final_tip_angle);

hook_min_tip_fillet = max(eps, min(2, hook_final_tip_length - hook_min_tip_length));
hook_final_corner_fillet = max(min(2, hook_final_bottom_thickness, hook_final_length, hook_final_back_thickness), min(hook_corner_fillet, hook_final_length - hook_min_tip_fillet - hook_final_bottom_thickness * tan(hook_corner_angle) - small_adj, hook_final_height - hook_final_bottom_thickness / cos(hook_corner_angle)));
hook_final_tip_fillet_pos_offset = hook_final_tip_angle == 90 ? hook_final_bottom_thickness : large_opp - small_hyp;
hook_max_tip_fillet = hook_final_tip_length - hook_final_tip_fillet_pos_offset;
hook_final_tip_fillet = max(hook_min_tip_fillet, min(hook_final_length - hook_final_corner_fillet - hook_final_bottom_thickness * tan(hook_corner_angle) - small_adj, hook_max_tip_fillet, hook_tip_corner_fillet));
hook_final_tip_fillet_diff = hook_max_tip_fillet - hook_final_tip_fillet;
hook_tip_point_fillet = max(eps, min(2, hook_final_tip_thickness / 2 - eps));

hook_has_tip = hook_tip_thickness >= eps && hook_tip_length >= eps;
hook_flat_top_width = hook_has_tip ? hook_final_length - hook_final_corner_fillet - hook_final_tip_fillet - small_adj - hook_final_bottom_thickness * tan(hook_corner_angle) : hook_final_length - hook_final_corner_fillet - hook_final_bottom_thickness * tan(hook_corner_angle);
echo(hook_min_tip_fillet=hook_min_tip_fillet, hook_max_tip_fillet=hook_max_tip_fillet, hook_final_tip_fillet=hook_final_tip_fillet);
corner_fillet_cut_shape = difference(
  [
    [[0, 0], [hook_final_corner_fillet * sin(hook_corner_angle), hook_final_corner_fillet * cos(hook_corner_angle)], [hook_final_corner_fillet, 0]],
    mask2d_roundover(joint=hook_final_corner_fillet, mask_angle=90 - hook_corner_angle),
  ]
);
tip_inner_fillet_cut_shape = difference(
  [
    [[0, 0], [-ang_hyp_to_opp(90 - hook_final_tip_angle, hook_final_tip_fillet), ang_hyp_to_adj(90 - hook_final_tip_angle, hook_final_tip_fillet)], [hook_final_tip_fillet, 0]],
    mask2d_roundover(joint=hook_final_tip_fillet, mask_angle=180 - hook_final_tip_angle),
  ]
);

diff() {
  cuboid([hook_final_width, hook_final_back_thickness, hook_final_height], anchor=FRONT) {
    edge_mask([TOP])
      rounding_edge_mask(r=hook_final_side_chamfer);
    corner_mask([TOP + BACK])
      rounding_corner_mask(r=hook_final_side_chamfer);
    //applying bottom chamfer to diagonal hooks may make print surface too small.
    if (hook_corner_angle == 0)
      edge_mask([BOTTOM + FRONT])
        chamfer_edge_mask(chamfer=hook_final_side_chamfer);
    attach(BOTTOM, FRONT, align=FRONT, spin=90)
      tag("remove") offset_sweep(rect([hook_final_length + hook_final_back_thickness, 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
    attach(BACK, FRONT, align=TOP, spin=90)
      tag("remove") offset_sweep(rect([max(eps, hook_final_height - hook_final_corner_fillet - hook_final_bottom_thickness / cos(hook_corner_angle)), 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
    position(BACK + BOTTOM)
      xrot(hook_corner_angle) cuboid([hook_final_width, hook_final_length, hook_final_bottom_thickness], anchor=FRONT + BOTTOM) {
          //hook flat top chamfer
          back(hook_final_corner_fillet + hook_final_bottom_thickness * tan(hook_corner_angle))
            attach(TOP, FRONT, align=FRONT, spin=90)
              tag("remove") offset_sweep(rect([max(eps, hook_flat_top_width), 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
          back(hook_final_corner_fillet + hook_final_bottom_thickness * tan(hook_corner_angle))
            position(FRONT + TOP)
              yrot(90) zrot(90) offset_sweep(mask2d_roundover(joint=hook_final_corner_fillet, mask_angle=90 - hook_corner_angle), height=hook_final_width, anchor=FRONT + RIGHT);
          back(hook_final_corner_fillet + hook_final_bottom_thickness * tan(hook_corner_angle))
            position(FRONT + TOP)
              tag("remove") yrot(90) zrot(90) offset_sweep(corner_fillet_cut_shape, height=hook_final_width, anchor=FRONT + RIGHT, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
          if (hook_has_tip) {
            position(BACK + BOTTOM)
              xrot(hook_final_tip_angle - 90) cuboid([hook_final_width, hook_final_tip_thickness, hook_final_tip_length], anchor=BACK + BOTTOM) {
                  down(max(eps, hook_final_tip_fillet_diff)) position(FRONT + TOP)
                      yrot(90) zrot(180) offset_sweep(mask2d_roundover(joint=hook_final_tip_fillet, mask_angle=180 - hook_final_tip_angle), height=hook_final_width, anchor=FRONT + RIGHT);
                  down(max(eps, hook_final_tip_fillet_diff)) position(FRONT + TOP)
                      tag("remove") yrot(90) zrot(180) offset_sweep(tip_inner_fillet_cut_shape, height=hook_final_width, anchor=FRONT + RIGHT, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
                  //hook tip front rect chamfer
                  attach(FRONT, FRONT, align=TOP, spin=90)
                    tag("remove") offset_sweep(rect([max(eps, hook_final_tip_fillet_diff), 1]), height=hook_final_width, bottom=os_chamfer(width=-hook_final_side_chamfer), top=os_chamfer(width=-hook_final_side_chamfer));
                  //hook tip back rect chamfer
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
difference() {
  xrot(90) union() {
      //hook snap
      grid_copies([max(horizontal_grids - 1, 1) * tileSize, max(vertical_grids - 1, 1) * tileSize], n=[horizontal_grids > 1 ? 2 : 1, vertical_grids > 1 ? 2 : 1])
        xflip_copy() yflip_copy()
            intersection() {
              difference() {
                down(hook_final_side_chamfer) cube([min(min(hook_width, 11) / 2, tileSize / 2), snap_height / 2, snap_depth + hook_final_side_chamfer]);
                up(3.4) right(1.1 - eps) prismoid(size1=[0, tileSize / 2], h=1, xang=135, yang=90, anchor=BOTTOM + FRONT);
                //a prismoid to cut off overhang from snap. calculated position is not precise but works well enough.
                back(snap_height / 2 - (5.2 - min(min(hook_width, 11), tileSize) / 2)) up(eps) prismoid(size1=[hook_width, 0], xang=90, yang=135, h=tileSize / 2);
              }
              right(tileSize / 2) zrot(-90)
                  difference() {
                    //offset grid created with minkowski
                    union() {
                      minkowski() {
                        path_extrude2d(path_tile) polygon(negative_wall_profile);
                        sphere(framesnap_thickness);
                      }
                      move([-tileSize / 2, -tileSize / 2]) rotate([0, 0, 45]) back(cornerOffset) rotate([90, 0, 0])
                              minkowski() {
                                linear_extrude(cornerOffset * 2) polygon(negative_corner_profile);
                                sphere(framesnap_thickness);
                              }
                    }
                    //original negative grid
                    union() {
                      path_extrude2d(path_tile) polygon(negative_wall_profile);
                      move([-tileSize / 2, -tileSize / 2]) rotate([0, 0, 45]) back(cornerOffset) rotate([90, 0, 0])
                              linear_extrude(cornerOffset * 2) polygon(negative_corner_profile);
                    }
                  }
            }
    }
}
