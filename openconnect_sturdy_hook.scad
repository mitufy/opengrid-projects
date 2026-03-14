/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

/* [Main Settings] */
//Default height is vertical_grids × 28mm, which aligns with openGrid tiles. You can override it by enabling "use_custom_height" below.
vertical_grids = 1;
//Recommened minimum width is 20mm. For smaller hooks, try "openGrid framefit hook generator".
hook_width = 28;
//Total inner length of the hook = corner_radius + flat_length + tip_radius - hook_thickness. This assumes thickness_scale = 1 and tip_angle = 180.
hook_thickness = 7;
//Corner_radius is capped by hook_height (vertical_grids x 28mm). For example, a hook needs at least 2 vertical_grids to truly have a 40mm corner_radius.
hook_corner_radius = 16;
//The length of the flat bottom part of the hook.
hook_flat_length = 0;
//The radius of the tip of the hook.
hook_tip_radius = 16;
//0.8 means thickness at the end of the hook would be 80% of the beginning. 
hook_thickness_scale = 0.8; //[0.5:0.1:1]
//Angle of the tip of the hook. Set this value to 90 and increase flat_length to generate a flat hook.
hook_tip_angle = 165; //[90:15:210]



/* [Slot Settings] */
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
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
use_custom_height = false;
custom_hook_height = 70;
//As custom height is not multiples of 28mm (otherwise there is no reason to use custom height), a position alignment needs to be chosen.
custom_height_slot_alignment = "Center"; //[Center,Top, Bottom]
hook_side_rounding = 2.4; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
include <lib/opengrid_base.scad>
use <lib/openconnect_lib.scad>
// /* [Truss Settings] */
truss_vertical_grids = 0;
truss_rounding = 1;
truss_thickness = 5;
//Double Lock is intended for small models that only use one or two slots.
slot_lock_side = "Left"; //[Left:Standard, Both:Double]
slot_edge_feature_widen = "Side"; //[Both, Top, Side, None]

_slot_cfg = ocslot_cfg(
  edge_feature=slot_edge_feature_widen,
  edge_bridge_min_w=slot_edge_bridge_min_width,
  edge_wall_min_w=slot_edge_wall_min_width,
  side_clearance=slot_side_clearance,
  depth_clearance=slot_depth_clearance
);

horizontal_grids = max(1, floor(hook_width / OG_TILE_SIZE));

hook_stem_height = use_custom_height ? custom_hook_height : vertical_grids * OG_TILE_SIZE;
hook_slot_alignment =
  !use_custom_height || custom_height_slot_alignment == "Center" ? CENTER
  : custom_height_slot_alignment == "Top" ? BACK : FRONT;
final_hook_corner_radius = min(hook_corner_radius, hook_stem_height - hook_thickness / 2 - hook_side_rounding);
stem_first_height = max(EPS, hook_stem_height - final_hook_corner_radius);

final_side_chamfer = max(0, min(hook_thickness / 2 * hook_thickness_scale - 0.84, hook_width / 2 - 0.84, hook_side_rounding));

hook_path =
  hook_tip_radius <= 0 || hook_tip_angle <= 90 ? ["setdir", -90, "arcleft", final_hook_corner_radius, "move", max(EPS, hook_flat_length)]
  : ["setdir", -90, "arcleft", final_hook_corner_radius, "move", max(EPS, hook_flat_length), "arcleft", hook_tip_radius, max(1, hook_tip_angle - 90)];
hook_path_first_part = ["setdir", -90, "arcleft", final_hook_corner_radius];

tip_rounding_radius = max(0, min(hook_thickness * hook_thickness_scale, hook_width - final_side_chamfer * 2) / 2 - EPS);
path_first_ratio = path_length(turtle(hook_path_first_part)) / path_length(turtle(hook_path));

final_sweep_profile = difference(
  rect([hook_thickness, hook_width]),
  right(hook_thickness / 2, fwd(hook_width / 2, yflip(zrot(-180, mask2d_teardrop(r=final_side_chamfer, $fn=64))))),
  right(hook_thickness / 2, back(hook_width / 2, zrot(-180, mask2d_teardrop(r=final_side_chamfer, $fn=64))))
);
offset_sweep_profile = scale([hook_thickness_scale, 1, 1], final_sweep_profile);

//BEGIN generation
diff(remove="rm0")
  diff(remove="rm1", keep="kp1 rm0") {
    cuboid([hook_thickness, hook_stem_height, hook_width], anchor=BACK + BOTTOM, rounding=final_side_chamfer, edges=[BACK + RIGHT], $fn=128) {
      tag("rm1") edge_profile([TOP + RIGHT, BOTTOM + RIGHT, BACK + TOP, BACK + BOTTOM], excess=0)
          mask2d_teardrop(r=final_side_chamfer, $fn=64);
      tag("rm1") corner_profile([BACK + TOP + RIGHT, BACK + BOTTOM + RIGHT], r=final_side_chamfer)
          mask2d_teardrop(r=final_side_chamfer, $fn=128);
      tag_diff(remove="rm2", tag="kp1") {
        attach(FRONT, FRONT, align=LEFT, inside=true, shiftout=0)
          tag("") cuboid([final_hook_corner_radius + hook_thickness / 2, final_hook_corner_radius + hook_thickness / 2, hook_width], chamfer=final_side_chamfer, edges=[LEFT + TOP, LEFT + BOTTOM])
              back(final_hook_corner_radius / 2) right(final_hook_corner_radius / 2)
                  tag("rm2") zcyl(r=final_hook_corner_radius, h=hook_width + EPS * 2);
      }
      attach(LEFT, TOP, align=hook_slot_alignment, inside=true, spin=90)
        tag("rm0") openconnect_slot_grid(slot_cfg=_slot_cfg, horizontal_grids=horizontal_grids, vertical_grids=vertical_grids, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=EPS);
      //truss begin
      truss_height = truss_vertical_grids * OG_TILE_SIZE;
      truss_depth = final_hook_corner_radius + hook_flat_length - hook_thickness / 2;
      truss_angle = adj_opp_to_ang(truss_depth, truss_height);
      truss_final_thickness = max(EPS, min(truss_depth / 2 - EPS, truss_thickness));
      truss_inner_depth = max(0, truss_depth - ang_adj_to_hyp(truss_angle, truss_final_thickness));
      truss_inner_height = max(0, (truss_height - ang_adj_to_hyp(truss_angle, truss_final_thickness)));

      truss_height_offset = (1 - hook_thickness_scale) / 2 * hook_thickness;
      trap_large = trapezoid(w1=truss_height + truss_height_offset, w2=EPS, h=truss_depth + truss_height_offset, shift=-(truss_height + truss_height_offset - EPS) / 2, anchor=FRONT + LEFT);
      trap_small = truss_inner_depth <= 0 || truss_inner_height <= 0 ? undef : trapezoid(w1=truss_inner_height + truss_height_offset, w2=EPS, h=truss_inner_depth + truss_height_offset, shift=-(truss_inner_height + truss_height_offset - EPS) / 2, anchor=FRONT + LEFT);
      truss_profile_trap = is_undef(trap_small) ? zrot(-90, trap_large) : zrot(-90, difference(trap_large, round_corners(joint=min(truss_rounding, truss_inner_depth / 2 - EPS, truss_inner_height / 2 - EPS), path=remove_eps_points(trap_small))));
      attach(FRONT, BACK)
        cuboid([hook_thickness, truss_height, hook_width])
          back(truss_height_offset) down(hook_width / 2) position(RIGHT + BACK)
                linear_sweep(region=truss_profile_trap, height=hook_width);
      //truss end
    }
    tag("kp1") up(hook_width / 2) fwd(stem_first_height - hook_thickness / 2 * (1 - ( (1 - hook_thickness_scale) * path_first_ratio))) {
          path_sweep(final_sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[hook_thickness_scale, 1])
            attach("end", "top")
              offset_sweep(offset_sweep_profile, height=tip_rounding_radius + EPS, bottom=os_circle(r=tip_rounding_radius), spin=180, $fn=128);
        }
  }
//END generation
function remove_eps_points(points) = [for (i = points) if (!(abs(i[0]) != 0 && abs(i[0]) <= EPS) && !(abs(i[1]) != 0 && abs(i[1]) <= EPS)) i];
