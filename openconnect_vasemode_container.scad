/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
//Recommended: 150-200% of nozzle size (e.g. 0.6–0.8mm for a 0.4mm nozzle). Higher values may work, feel free to experiment.
ocvase_linewidth = 0.6;
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
label_depth = 1;

/* [Advanced Settings] */
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
use_custom_depth = false;
custom_depth = 60;
surface_texture_size = 7;
surface_texture_depth = 1; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>

//BEGIN container parameters
vase_width = OG_TILE_SIZE * horizontal_grids;
vase_depth = use_custom_depth ? custom_depth : OG_TILE_SIZE * depth_grids;
final_vase_tilt_angle = min(adj_opp_to_ang(OG_TILE_SIZE * vertical_grids, vase_depth - 1), vase_tilt_angle);
vase_slot_overhang_angle = max(45, 45 + final_vase_tilt_angle - 15);
vase_height = ang_hyp_to_adj(final_vase_tilt_angle, OG_TILE_SIZE * vertical_grids);
_slot_cfg = ocslot_cfg(
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance,
  vase_overhang_angle=vase_slot_overhang_angle
);
final_vase_front_inset_angle = min(adj_opp_to_ang(vase_height, max(0, vase_depth - ang_adj_to_opp(final_vase_tilt_angle, vase_height) - 1)), vase_front_inset_angle);
final_surface_texture_size = surface_texture_size * (vase_surface_texture == "checkers" || vase_surface_texture == "cubes" ? 2 : 1);

label_overhang_angle = max(10, 45 - final_vase_front_inset_angle);
label_side_clearance = 0.2;
label_depth_clearance = 0.3;
label_holder_wall_thickness = ocvase_linewidth * 2;
label_holder_depth = label_depth + label_depth_clearance + label_holder_wall_thickness;
label_holder_side_width = ocvase_linewidth * 4;
label_move =
  label_holder_type == "Split-Left" ? -vase_width / 2
  : label_holder_type == "Split-Right" ? vase_width / 2 : 0;
//END container parameters

//BEGIN generation
up(vase_height / 2) xrot(90 + final_vase_tilt_angle) {
    xrot(-final_vase_tilt_angle)
      diff(remove="root_rm") diff(remove="remove", keep="keep root_rm")
          prismoid(size1=[vase_width, vase_depth], h=vase_height, xang=[90, 90], yang=[90 - final_vase_front_inset_angle, 90 - final_vase_tilt_angle], chamfer=0, orient=FRONT, anchor=BACK) {
            attach(BACK, BOTTOM, spin=180)
              openconnect_slot_grid(slot_cfg=_slot_cfg, slot_type="vase", horizontal_grids=horizontal_grids, vertical_grids=vertical_grids, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution);
            if (vase_surface_texture != "") {
              frontwall_height = ang_adj_to_hyp(final_vase_front_inset_angle, vase_height) + ang_adj_to_opp(final_vase_front_inset_angle, surface_texture_depth);
              quant_texture_size = vase_surface_texture == "cubes" ? sqrt(3) * final_surface_texture_size : final_surface_texture_size;
              final_wall_height = quantup(frontwall_height, quant_texture_size);
              final_wall_width = quantup(vase_width, quant_texture_size);
              final_wall_depth = quantup(vase_depth, quant_texture_size);
              final_texture = vase_surface_texture == "checkers" ? texture(vase_surface_texture, border=0.2) : texture(vase_surface_texture);
              diff(remove="frontwall_rm") {
                attach(FRONT, BOTTOM, align=BOTTOM)
                  textured_tile(final_texture, w1=final_wall_width, w2=final_wall_width, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]) {
                    if (label_holder_type != "None")
                      right(label_move) tag("frontwall_rm")
                          attach(TOP, BOTTOM, align=FRONT, inside=true, shiftout=EPS)
                            prismoid(size2=[label_width + label_side_clearance * 2, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=surface_texture_depth);
                  }
                tag("frontwall_rm") attach(BOTTOM, BACK)
                    cuboid([400, 400, 400]);
                tag("frontwall_rm") attach(LEFT, BACK)
                    cuboid([400, 400, 400]);
                tag("frontwall_rm") attach(RIGHT, BACK)
                    cuboid([400, 400, 400]);
              }
              diff(remove="sidewall_rm") {
                attach(LEFT, BOTTOM, align=BOTTOM)
                  textured_tile(final_texture, w1=final_wall_depth, w2=final_wall_depth, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                tag("sidewall_rm") attach(FRONT, BACK)
                    cuboid([400, 400, 400]);
                tag("sidewall_rm") attach(BACK, BACK)
                    cuboid([400, 400, 400]);
              }
              tag("remove") diff(remove="sidewall_rm") {
                  attach(RIGHT, BOTTOM, inside=true, align=BOTTOM)
                    textured_tile(final_texture, w1=final_wall_depth, w2=final_wall_depth, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                  tag("sidewall_rm") attach(FRONT, BACK, shiftout=EPS)
                      cuboid([400, 400, 400]);
                  tag("sidewall_rm") attach(BACK, BACK, shiftout=EPS)
                      cuboid([400, 400, 400]);
                }
              tag("root_rm")
                left(surface_texture_depth + 1) fwd(surface_texture_depth + 1)
                    edge_profile([LEFT + FRONT], excess=10)
                      mask2d_chamfer(x=surface_texture_depth * 2 + 2);
              tag("root_rm")
                right(surface_texture_depth) fwd(surface_texture_depth + 1)
                    edge_profile([RIGHT + FRONT], excess=10)
                      mask2d_chamfer(x=surface_texture_depth * 3 + 1);
              tag("root_rm") attach(TOP, BACK)
                  cuboid([400, 400, 400]);
            }
            else
              tag("root_rm")
                edge_profile([LEFT + FRONT, RIGHT + FRONT], excess=10)
                  mask2d_chamfer(x=1);
            if (label_holder_type != "None")
              right(label_move)
                tag_diff(tag="keep", remove="rm0") {
                  if (label_holder_type != "Split-Right")
                    right((label_width + label_side_clearance * 2) / 2)
                      attach(FRONT, BOTTOM, align=BOTTOM)
                        tag("") prismoid(size2=[label_holder_side_width, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth) {
                            attach(LEFT + BOTTOM, LEFT + BOTTOM, align=FRONT, inside=true)
                              tag("rm0") prismoid(size2=[label_holder_side_width - ocvase_linewidth * 2, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth - label_holder_wall_thickness);
                          }
                  if (label_holder_type != "Split-Left")
                    left((label_width + label_side_clearance * 2) / 2)
                      attach(FRONT, BOTTOM, align=BOTTOM)
                        tag("") prismoid(size2=[label_holder_side_width, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth) {
                            attach(RIGHT + BOTTOM, RIGHT + BOTTOM, align=FRONT, inside=true)
                              tag("rm0") prismoid(size2=[label_holder_side_width - ocvase_linewidth * 2, label_height + label_side_clearance], xang=[90, 90], yang=[90, label_overhang_angle], h=label_holder_depth - label_holder_wall_thickness);
                          }
                }
          }
  }
//END generation
