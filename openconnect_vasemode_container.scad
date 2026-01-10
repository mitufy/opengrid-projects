/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>

/* [Main Settings] */
//Safe value for vase mode linewidth is 150% of nozzle size, i.e. 0.6mm linewidth for 0.4mm nozzles. But it's usually fine to go up to 200%, so feel free to experiment.
vase_linewidth = 0.6;
//Multiple containers of same texture can be installed side by side as the pattern is designed to be complementary.
vase_surface_texture = "checkers"; //["":None, "cubes":Cubes, "diamonds":Diagonal Ribs,"wave_ribs":Wave Ribs,"checkers":Checkers]

horizontal_grids = 2;
vertical_grids = 3;
//Depth is not technically restrained by grid, so you can override it by enabling "use_custom_depth" below.
depth_grids = 2;

//A tilt_angle can make it easier to take out contents. Set this to 0 for a normal straight up container.
vase_tilt_angle = 15; //[0:5:45]
//Serves similar purpose as tilt_angle by angling the front of the container.
vase_front_inset_angle = 0; //[0:5:45]

/* [Advanced Settings] */
//'Staggered' means every other slot. Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Staggered"; //["All", "Staggered", "Corners", "None"]
use_custom_depth = false;
custom_depth = 60;
surface_texture_size = 7;
surface_texture_depth = 1; //0.2

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN openConnect slot parameters
tile_size = 28;

ochead_bottom_height = 0.6;
ochead_bottom_chamfer = 0;
ochead_top_height = 0.6;
ochead_middle_height = 1.4;
ochead_large_rect_width = 17; //0.1
ochead_large_rect_height = 11.2; //0.1

ochead_nub_to_top_distance = 7.2;
ochead_nub_depth = 0.6;
ochead_nub_tip_height = 1.2;
ochead_nub_inner_fillet = 0.6;
ochead_nub_outer_fillet = 0.8;

ochead_large_rect_chamfer = 4;
ochead_small_rect_width = ochead_large_rect_width - ochead_middle_height * 2;
ochead_small_rect_height = ochead_large_rect_height - ochead_middle_height;
ochead_small_rect_chamfer = ochead_large_rect_chamfer - ochead_middle_height + ang_adj_to_opp(45 / 2, ochead_middle_height);

ocslot_move_distance = 11; //0.1
ocslot_onramp_clearance = 0.8;
ocslot_bridge_offset = 0.4;
ocslot_side_clearance = 0.15;
ocslot_depth_clearance = 0.12;

ochead_bottom_profile = back(ochead_large_rect_width / 2, rect([ochead_large_rect_width, ochead_large_rect_height], chamfer=[ochead_large_rect_chamfer, ochead_large_rect_chamfer, 0, 0], anchor=BACK));
ochead_top_profile = back(ochead_small_rect_width / 2, rect([ochead_small_rect_width, ochead_small_rect_height], chamfer=[ochead_small_rect_chamfer, ochead_small_rect_chamfer, 0, 0], anchor=BACK));
ochead_total_height = ochead_top_height + ochead_middle_height + ochead_bottom_height;
ochead_middle_to_bottom = ochead_large_rect_height - ochead_large_rect_width / 2;

ocslot_bottom_height = ochead_bottom_height + ang_adj_to_opp(45 / 2, ocslot_side_clearance) + ocslot_depth_clearance;
ocslot_top_height = ochead_top_height - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_total_height = ocslot_top_height + ochead_middle_height + ocslot_bottom_height;
ocslot_nub_to_top_distance = ochead_nub_to_top_distance + ocslot_side_clearance * 1.5;

ocslot_small_rect_width = ochead_small_rect_width + ocslot_side_clearance * 2;
ocslot_small_rect_height = ochead_small_rect_height + ocslot_side_clearance * 2;
ocslot_small_rect_chamfer = ochead_small_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_large_rect_width = ochead_large_rect_width + ocslot_side_clearance * 2;
ocslot_large_rect_height = ochead_large_rect_height + ocslot_side_clearance * 2;
ocslot_large_rect_chamfer = ochead_large_rect_chamfer + ocslot_side_clearance - ang_adj_to_opp(45 / 2, ocslot_side_clearance);
ocslot_middle_to_bottom = ocslot_large_rect_height - ocslot_large_rect_width / 2;
ocslot_to_grid_top_offset = (tile_size - 24.8) / 2;
ocslot_top_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width, ocslot_small_rect_height], chamfer=[ocslot_small_rect_chamfer, ocslot_small_rect_chamfer, 0, 0], anchor=BACK));
ocslot_bottom_profile = back(ocslot_large_rect_width / 2, rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=BACK));

ochead_side_profile = [
  [0, 0],
  [ochead_large_rect_width / 2, 0],
  [ochead_large_rect_width / 2, ochead_bottom_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height],
  [ochead_small_rect_width / 2, ochead_bottom_height + ochead_middle_height + ochead_top_height],
  [0, ochead_bottom_height + ochead_middle_height + ochead_top_height],
];
//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = "both", nub_flattop = true, nub_taperin = true, excess_thickness = 0, size_offset = 0) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : head_type == "vase" ? ocvase_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : head_type == "vase" ? ocvase_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : head_type == "vase" ? ocvase_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : head_type == "vase" ? ocvase_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : head_type == "vase" ? ocvase_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : head_type == "vase" ? ocvase_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : head_type == "vase" ? ocvase_nub_to_top_distance : ochead_nub_to_top_distance;
  nub_angle = nub_taperin ? adj_opp_to_ang(ochead_middle_height, ochead_middle_height - ochead_nub_depth) : 0;
  tag_scope() difference() {
      union() {
        linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
        up(bottom_height - eps) hull() {
            up(ochead_middle_height) linear_extrude(h=eps) polygon(offset(top_profile, delta=size_offset));
            linear_extrude(h=eps) polygon(offset(bottom_profile, delta=size_offset));
          }
        if (top_height + excess_thickness > 0)
          up(bottom_height + ochead_middle_height - eps)
            linear_extrude(h=top_height + excess_thickness + eps) polygon(offset(top_profile, delta=size_offset));
      }
      back(large_rect_width / 2 - nub_to_top_distance) {
        if (add_nubs == "left" || add_nubs == "both")
          left(large_rect_width / 2 + size_offset - ochead_nub_depth + eps) zrot(-90) {
              linear_extrude(bottom_height) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
              up(bottom_height) linear_extrude(1 / cos(nub_angle) * ochead_middle_height, v=[0, tan(nub_angle), 1]) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[nub_flattop ? 90 : 45, 45], rounding=[ochead_nub_inner_fillet, nub_flattop ? 0 : ochead_nub_inner_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet, -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
            }
        if (add_nubs == "right" || add_nubs == "both")
          right(large_rect_width / 2 + size_offset - ochead_nub_depth + eps) zrot(90) {
              linear_extrude(bottom_height) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
              up(bottom_height) linear_extrude(1 / cos(nub_angle) * ochead_middle_height, v=[0, tan(nub_angle), 1]) trapezoid(h=ochead_nub_depth, w2=ochead_nub_tip_height, ang=[45, nub_flattop ? 90 : 45], rounding=[nub_flattop ? 0 : ochead_nub_inner_fillet, ochead_nub_inner_fillet, -ochead_nub_outer_fillet, nub_flattop ? 0 : -ochead_nub_outer_fillet], anchor=BACK, $fn=64);
            }
      }
    }
}
module openconnect_slot(add_nubs = "left", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_height, ocslot_total_height]) {
    tag_scope() up(ocslot_total_height / 2) yrot(180) union() {
          if (direction_flip)
            xflip() ocslot_body(excess_thickness);
          else
            ocslot_body(excess_thickness);
        }
    children();
  }
  module ocslot_body(excess_thickness = 0) {
    ocslot_side_profile = [
      [0, 0],
      [ocslot_large_rect_width / 2, 0],
      [ocslot_large_rect_width / 2, ocslot_bottom_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height],
      [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness],
      [0, ocslot_bottom_height + ochead_middle_height + ocslot_top_height + excess_thickness],
    ];
    ocslot_bridge_offset_profile = back(ocslot_small_rect_width / 2, rect([ocslot_small_rect_width / 2 + ocslot_bridge_offset, ocslot_small_rect_height + ocslot_move_distance + ocslot_onramp_clearance], chamfer=[ocslot_small_rect_chamfer + ocslot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(head_type="slot", add_nubs=add_nubs, excess_thickness=excess_thickness);
      xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocslot_side_profile);
      up(ocslot_bottom_height) linear_extrude(ocslot_top_height + ochead_middle_height) polygon(ocslot_bridge_offset_profile);
      fwd(ocslot_move_distance) {
        linear_extrude(ocslot_bottom_height) onramp_2d();
        up(ocslot_bottom_height)
          linear_extrude(ochead_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(ochead_middle_height) up(ocslot_bottom_height + ochead_middle_height)
            linear_extrude(ocslot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(ocslot_small_rect_chamfer) cuboid([ocslot_small_rect_width, ocslot_small_rect_height, ocslot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=ocslot_onramp_clearance)
        left(ocslot_onramp_clearance + ochead_middle_height) back(ocslot_large_rect_width / 2) {
            rect([ocslot_large_rect_width, ocslot_large_rect_height], chamfer=[ocslot_large_rect_chamfer, ocslot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
module openconnect_slot_grid(h_grid = 1, v_grid = 1, grid_size = 28, lock_distribution = "None", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[h_grid * grid_size, v_grid * grid_size, ocslot_total_height]) {
    tag_scope() hide_this() cuboid([h_grid * grid_size, v_grid * grid_size, ocslot_total_height]) {
          back(ocslot_to_grid_top_offset) {
            if (lock_distribution == "All" || lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? "left" : "", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Corners") {
              grid_copies([grid_size * max(1, h_grid - 1), grid_size * max(1, v_grid - 1)], [min(h_grid, 2), min(v_grid, 2)])
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
              for (i = [0:1:v_grid - 1]) {
                back(grid_size * (v_grid - 1) / 2) fwd(grid_size * i) {
                    if (i == 0 || i == v_grid - 1) {
                      if (h_grid > 2)
                        line_copies(spacing=grid_size, n=h_grid - 2)
                          attach(TOP, BOTTOM, inside=true)
                            openconnect_slot(add_nubs="", direction_flip=direction_flip, excess_thickness=excess_thickness);
                    }
                    else
                      line_copies(spacing=grid_size, n=h_grid)
                        attach(TOP, BOTTOM, inside=true)
                          openconnect_slot(add_nubs="", direction_flip=direction_flip, excess_thickness=excess_thickness);
                  }
              }
            }
          }
        }
    children();
  }
}
//END openConnect slot modules

vase_wall_thickness = vase_linewidth * 2;
vase_width = tile_size * horizontal_grids;
vase_depth = use_custom_depth ? custom_depth : tile_size * depth_grids;
final_vase_tilt_angle = min(adj_opp_to_ang(tile_size * vertical_grids, vase_depth - 1), vase_tilt_angle);
vase_height = ang_hyp_to_adj(final_vase_tilt_angle, tile_size * vertical_grids);
final_vase_front_inset_angle = min(adj_opp_to_ang(vase_height, max(0, vase_depth - ang_adj_to_opp(final_vase_tilt_angle, vase_height) - 1)), vase_front_inset_angle);

final_surface_texture_size = surface_texture_size * (vase_surface_texture == "checkers" || vase_surface_texture == "cubes" ? 2 : 1);

ocvase_cut_side_profile = [
  [0, 0],
  [ocslot_large_rect_width / 2, 0],
  [ocslot_large_rect_width / 2, ocslot_bottom_height],
  [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height],
  [ocslot_small_rect_width / 2, ocslot_bottom_height + ochead_middle_height + ocslot_top_height],
  [0, ocslot_bottom_height + ochead_middle_height + ocslot_top_height],
];

tilt_offset_angle = max(0, final_vase_tilt_angle - 20);

ocvase_small_rect_width = ocslot_small_rect_width + vase_wall_thickness * 2;
ocvase_small_rect_height = ocslot_small_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + tilt_offset_angle, ocslot_total_height);
ocvase_small_rect_chamfer = ocslot_small_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_large_rect_width = ocslot_large_rect_width + vase_wall_thickness * 2;
ocvase_large_rect_height = ocslot_large_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + tilt_offset_angle, ocslot_total_height);
ocvase_large_rect_chamfer = ocslot_large_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_middle_to_bottom = ocvase_large_rect_height - ocvase_large_rect_width / 2;

ocvase_nub_to_top_distance = ocslot_nub_to_top_distance + vase_wall_thickness;
ocvase_bottom_height = ocslot_bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness);
ocvase_top_height = ocslot_top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness);

ocvase_top_profile = back(ocvase_small_rect_width / 2, rect([ocvase_small_rect_width, ocvase_small_rect_height], chamfer=[ocvase_small_rect_chamfer, ocvase_small_rect_chamfer, 0, 0], anchor=BACK));
ocvase_bottom_profile = back(ocvase_large_rect_width / 2, rect([ocvase_large_rect_width, ocvase_large_rect_height], chamfer=[ocvase_large_rect_chamfer, ocvase_large_rect_chamfer, 0, 0], anchor=BACK));

module openconnect_vase_slot(add_nubs = "") {
  difference() {
    openconnect_head(head_type="vase", add_nubs=add_nubs, nub_flattop=false);
    openconnect_head(head_type="slot", add_nubs=add_nubs, nub_flattop=false);
    cuboid([ocslot_large_rect_width - ocslot_large_rect_chamfer * 2, ocslot_large_rect_height, ocslot_total_height], anchor=FRONT + BOTTOM);
    fwd(ocvase_middle_to_bottom)
      xrot(-(45 + tilt_offset_angle)) cuboid([ocvase_large_rect_width + eps, 20, 20], anchor=BACK + BOTTOM);
    xrot(90) up(ocslot_middle_to_bottom) linear_extrude(ocslot_move_distance + ocslot_onramp_clearance) xflip_copy() polygon(ocvase_cut_side_profile);
    up(ocslot_total_height) cuboid([50, 50, 50], anchor=BOTTOM);
  }
}

up(vase_height / 2) xrot(90 + final_vase_tilt_angle) {
    grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger=slot_lock_distribution == "Staggered")
      openconnect_vase_slot(add_nubs=(horizontal_grids == 1 && vertical_grids == 1 && slot_lock_distribution == "Staggered") || slot_lock_distribution == "All" ? "left" : "");
    if (slot_lock_distribution == "Staggered")
      grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger="alt")
        openconnect_vase_slot(add_nubs="left");
    right(vase_surface_texture != "" ? surface_texture_depth / 2 : 0) xrot(-final_vase_tilt_angle) diff(remove="root_rm") diff(remove="remove", keep="keep root_rm")
            prismoid(size1=[vase_width, vase_depth], h=vase_height, xang=[90, 90], yang=[90 - final_vase_front_inset_angle, 90 - final_vase_tilt_angle], chamfer=vase_surface_texture != "" ? [0, 0, 0, 0] : [0, 0, 1, 1], orient=FRONT, anchor=BACK) {
              if (vase_surface_texture != "") {
                frontwall_height = ang_adj_to_hyp(final_vase_front_inset_angle, vase_height) + ang_adj_to_opp(final_vase_front_inset_angle, surface_texture_depth);
                quant_texture_size = vase_surface_texture == "cubes" ? sqrt(3) * final_surface_texture_size : final_surface_texture_size;
                final_wall_height = quantup(frontwall_height, quant_texture_size);
                final_wall_width = quantup(vase_width, quant_texture_size);
                final_wall_depth = quantup(vase_depth, quant_texture_size);
                final_texture = vase_surface_texture == "checkers" ? texture(vase_surface_texture, border=0.2) : texture(vase_surface_texture);
                diff(remove="frontwall_rm") {
                  attach(FRONT, BOTTOM, align=BOTTOM)
                    textured_tile(final_texture, w1=final_wall_width, w2=final_wall_width, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
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
                    tag("sidewall_rm") attach(FRONT, BACK, shiftout=eps)
                        cuboid([400, 400, 400]);
                    tag("sidewall_rm") attach(BACK, BACK, shiftout=eps)
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
            }
  }
