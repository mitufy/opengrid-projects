/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

Inspired by David D's "openGrid - Minimal Hook". https://www.printables.com/model/1217962-opengrid-minimal-hook
Part of code is based on BlackjackDuck's "openGrid - Tile Generator". https://makerworld.com/en/models/1304337-opengrid-tile-generator

2025-07-30 Update: Add a maximum side chamfer calculation to better handle extremely small parameters.
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
/*[Basic Settings]*/
vertical_grids = 1;
hook_length = 20;
hook_tip_length = 4;

hook_tip_angle = 45; //[30:5:90]
//Setting width too low reduces stability. The absolute minimum width is 5.
hook_width = 10;
//Increace this value to make the corner of the hook sturdier.
hook_corner_length = 3;
//Increase this value if you find the snap fit too tight.
snap_clearance = 0.1; //0.01

hook_back_thickness = 4;
hook_bottom_thickness = 4;
hook_tip_thickness = 3;

/*[Advanced Settings]*/
//What is a hook anyways?
horizontal_grids = 1;

//Difference between top and bottom tip angles. Bottom angle is clamped to be at least 45 degrees to avoid overhang.
hook_tip_diff_angle = 10; //[0:5:60]

//3.4mm version makes it possible to install simultaneously on both side of openGrid board (6.8mm thick). If there is no such need, 4mm version is recommended.
snap_depth = 4; //[4, 3.4]

/*[Hidden]*/
$fa = 1;
$fs = 0.4;
eps = 0.005;
//0.42 is a common line width for 0.4mm nozzles.
snap_thickness = 0.84; // 0.42

hook_length_chamfer_limit = (hook_length / 2 - eps <= 0 || hook_bottom_thickness / 2 - eps <= 0) && (hook_tip_length / 2 - eps <= 0 || hook_tip_thickness / 2 - eps <= 0) ? 10000 : min(hook_length / 2 - eps, hook_bottom_thickness / 2 - eps);
tip_length_chamfer_limit = hook_tip_length / 2 - eps <= 0 || hook_tip_thickness / 2 - eps <= 0 ? 10000 : min(hook_tip_length / 2 - eps, hook_tip_thickness / 2 - eps);

hook_side_chamfer = max(0, min(hook_back_thickness / 2 - eps, hook_length_chamfer_limit, tip_length_chamfer_limit, 0.84)); // 0.42

snap_height = 28 - hook_side_chamfer * 2;

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

hook_final_back_thickness = max(0, hook_back_thickness - eps);
hook_final_bottom_thickness = max(0, hook_bottom_thickness - eps);
hook_final_tip_thickness = max(0, hook_tip_thickness - eps);
hook_final_width = tileSize * (horizontal_grids - 1) + hook_width;
hook_final_height = tileSize * vertical_grids;

corner_inner_xy = ang_hyp_to_adj(45, hook_corner_length);

tip_inner_x = hook_tip_angle >= 90 ? 0 : ang_hyp_to_adj(hook_tip_angle, hook_tip_length);
tip_inner_y = hook_tip_angle >= 90 ? hook_tip_length : ang_hyp_to_opp(hook_tip_angle, hook_tip_length);
tip_inset = hook_tip_angle + hook_tip_diff_angle >= 90 ? 0 : ang_opp_to_adj(max(45, hook_tip_angle + hook_tip_diff_angle), hook_final_bottom_thickness + tip_inner_y);
hook_profile = [
  [0, 0],
  [0, hook_final_height],
  [hook_final_back_thickness, hook_final_height],
  [hook_final_back_thickness, hook_final_bottom_thickness + corner_inner_xy],
  [hook_final_back_thickness + corner_inner_xy, hook_final_bottom_thickness],
  [hook_final_back_thickness + hook_length - tip_inner_x, hook_final_bottom_thickness],
  [hook_final_back_thickness + hook_length, hook_final_bottom_thickness + tip_inner_y],
  [hook_final_back_thickness + hook_length + hook_final_tip_thickness, hook_final_bottom_thickness + tip_inner_y],
  [hook_final_back_thickness + hook_length + hook_final_tip_thickness - tip_inset, 0],
];

hook_corner_rounding_space_x = (hook_length - corner_inner_xy - tip_inner_x) / 2;
hook_corner_rounding_space_y = hook_final_height - corner_inner_xy - hook_side_chamfer - hook_final_bottom_thickness;
//list of joint rounding parameters for round_corners. minus 0.1 to prevent offset_sweep's "very short segment" error and floating point shenanigans.
hook_joint_values = [
  0,
  0,
  max(0, min(hook_side_chamfer, hook_final_back_thickness / 2) - 0.1),
  max(0, min(hook_corner_rounding_space_y, hook_corner_length / 2) - 0.1),
  //half of space reserved for rounding the corner angle
  max(0, min(hook_corner_rounding_space_x, hook_corner_length / 2) - 0.1),
  //one quarter of space reserved for rounding the tip angle
  max(0, min(hook_tip_length / 2, (hook_length - corner_inner_xy - tip_inner_x) / 4) - 0.1),
  max(0, min(hook_tip_length / 2, hook_final_tip_thickness / 2) - 0.1),
  max(0, min(hook_tip_length / 2, hook_final_tip_thickness / 2) - 0.1),
  0,
];
rounded_hook_profile = round_corners(hook_profile, joint=hook_joint_values, closed=false);

echo(hook_length_chamfer_limit, tip_length_chamfer_limit, hook_side_chamfer, rounded_hook_profile);
difference() {
  xrot(90) union() {
      //hook body
      render() translate([-hook_final_width / 2, -hook_final_height / 2, 0]) yrot(90)
            offset_sweep(rounded_hook_profile, height=hook_final_width, bottom=os_chamfer(width=hook_side_chamfer), top=os_chamfer(width=hook_side_chamfer), offset="delta");
      //hook snap
      grid_copies([max(horizontal_grids - 1, 1) * tileSize, max(vertical_grids - 1, 1) * tileSize], n=[horizontal_grids > 1 ? 2 : 1, vertical_grids > 1 ? 2 : 1])
        xflip_copy() yflip_copy()
            intersection() {
              difference() {
                down(hook_side_chamfer) cube([min(hook_width / 2, tileSize / 2), snap_height / 2, snap_depth + hook_side_chamfer]);
                up(3.4) right(1.1 - eps) prismoid(size1=[0, tileSize / 2], h=1, xang=135, yang=90, anchor=BOTTOM + FRONT);
                //a prismoid to cut off overhang from snap. calculated position is not precise but works well enough.
                back(snap_height / 2 - (5.2 - min(hook_width, tileSize) / 2)) up(eps) prismoid(size1=[hook_width, 0], xang=90, yang=135, h=tileSize / 2);
              }
              right(tileSize / 2) zrot(-90)
                  difference() {
                    //offset grid created with minkowski
                    union() {
                      minkowski() {
                        path_extrude2d(path_tile) polygon(negative_wall_profile);
                        sphere(snap_thickness);
                      }
                      move([-tileSize / 2, -tileSize / 2]) rotate([0, 0, 45]) back(cornerOffset) rotate([90, 0, 0])
                              minkowski() {
                                linear_extrude(cornerOffset * 2) polygon(negative_corner_profile);
                                sphere(snap_thickness);
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
