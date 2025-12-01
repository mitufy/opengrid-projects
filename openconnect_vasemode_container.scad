  
include <BOSL2/std.scad>

/* [Main Settings] */
//Safe value for vase mode linewidth is 150% of nozzle size, i.e. 0.6mm linewidth for 0.4mm nozzles. But it's usually fine to go up to 200%, so feel free to experiment.
vase_linewidth = 0.6;
vase_surface_texture = "diamonds"; //[None:None, wave_ribs:Wave Ribs,diamonds:Diagonal Ribs,checkers:Checkers,cubes:Cubes]

horizontal_grids = 2;
vertical_grids = 3;
//As depth is not restrained by grid, this is just a convenient way to increment value by 28mm. You can override it by enabling "use_custom_depth" below.
depth_grids = 2;

vase_tilt_angle = 15; //[0:5:45]
vase_front_inset_angle = 0; //[0:5:45]

/* [Advanced Settings] */
use_custom_depth = false;
custom_depth = 60;
surface_texture_size = 7;
surface_texture_depth = 1; //0.2
slot_locking_nubs = 2; //[2:Both Sides, 1:One Side,0:None]

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;

//BEGIN openConnect slot parameters
tile_size = 28;

openconnect_head_bottom_height = 0.4;
openconnect_head_bottom_chamfer = 0;
openconnect_head_top_height = 0.6;
openconnect_middle_height = 1.6;
openconnect_head_large_rect_width = 17; //0.1
openconnect_head_large_rect_height = 11.2; //0.1

openconnect_head_nub_to_top_distance = 7.2;
openconnect_lock_nub_depth = 0.4;
openconnect_lock_nub_tip_height = 1;
openconnect_lock_nub_inner_fillet = 0.2;
openconnect_lock_nub_outer_fillet = 0.8;

openconnect_head_large_rect_chamfer = 4;
openconnect_head_small_rect_width = openconnect_head_large_rect_width - openconnect_middle_height * 2;
openconnect_head_small_rect_height = openconnect_head_large_rect_height - openconnect_middle_height;
openconnect_head_small_rect_chamfer = openconnect_head_large_rect_chamfer - openconnect_middle_height + ang_adj_to_opp(45 / 2, openconnect_middle_height);

openconnect_slot_move_distance = 11; //0.1
openconnect_slot_onramp_clearance = 0.8;
openconnect_slot_bridge_offset = 0.4;
openconnect_slot_side_clearance = 0.18;
openconnect_slot_depth_clearance = 0.12;

openconnect_head_bottom_profile = back(openconnect_head_large_rect_width / 2, rect([openconnect_head_large_rect_width, openconnect_head_large_rect_height], chamfer=[openconnect_head_large_rect_chamfer, openconnect_head_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_top_profile = back(openconnect_head_small_rect_width / 2, rect([openconnect_head_small_rect_width, openconnect_head_small_rect_height], chamfer=[openconnect_head_small_rect_chamfer, openconnect_head_small_rect_chamfer, 0, 0], anchor=BACK));
openconnect_head_total_height = openconnect_head_top_height + openconnect_middle_height + openconnect_head_bottom_height;
openconnect_head_middle_to_bottom = openconnect_head_large_rect_height - openconnect_head_large_rect_width / 2;

openconnect_slot_bottom_height = openconnect_head_bottom_height + ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance) + openconnect_slot_depth_clearance;
openconnect_slot_top_height = openconnect_head_top_height - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_total_height = openconnect_slot_top_height + openconnect_middle_height + openconnect_slot_bottom_height;
openconnect_slot_nub_to_top_distance = openconnect_head_nub_to_top_distance + openconnect_slot_side_clearance;

openconnect_slot_small_rect_width = openconnect_head_small_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_height = openconnect_head_small_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_small_rect_chamfer = openconnect_head_small_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_large_rect_width = openconnect_head_large_rect_width + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_height = openconnect_head_large_rect_height + openconnect_slot_side_clearance * 2;
openconnect_slot_large_rect_chamfer = openconnect_head_large_rect_chamfer + openconnect_slot_side_clearance - ang_adj_to_opp(45 / 2, openconnect_slot_side_clearance);
openconnect_slot_middle_to_bottom = openconnect_slot_large_rect_height - openconnect_slot_large_rect_width / 2;
openconnect_slot_to_grid_top_offset = (tile_size - 24.8) / 2;
openconnect_slot_top_profile = back(openconnect_slot_small_rect_width / 2, rect([openconnect_slot_small_rect_width, openconnect_slot_small_rect_height], chamfer=[openconnect_slot_small_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_slot_bottom_profile = back(openconnect_slot_large_rect_width / 2, rect([openconnect_slot_large_rect_width, openconnect_slot_large_rect_height], chamfer=[openconnect_slot_large_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=BACK));

openconnect_head_side_profile = [
  [0, 0],
  [openconnect_head_large_rect_width / 2 - openconnect_head_bottom_chamfer, 0],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_chamfer],
  [openconnect_head_large_rect_width / 2, openconnect_head_bottom_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_middle_height],
  [openconnect_head_small_rect_width / 2, openconnect_head_bottom_height + openconnect_middle_height + openconnect_head_top_height],
  [0, openconnect_head_bottom_height + openconnect_middle_height + openconnect_head_top_height],
];
//END openConnect slot parameters

//BEGIN openConnect slot modules
module openconnect_head(head_type = "head", add_nubs = 2, excess_thickness = 0, size_offset = 0) {
  bottom_profile =
    head_type == "slot" ? openconnect_slot_bottom_profile
    : head_type == "vase" ? openconnect_vase_bottom_profile
    : openconnect_head_bottom_profile;
  top_profile =
    head_type == "slot" ? openconnect_slot_top_profile
    : head_type == "vase" ? openconnect_vase_top_profile
    : openconnect_head_top_profile;
  bottom_height =
    head_type == "slot" ? openconnect_slot_bottom_height
    : head_type == "vase" ? openconnect_vase_bottom_height
    : openconnect_head_bottom_height;
  top_height =
    head_type == "slot" ? openconnect_slot_top_height
    : head_type == "vase" ? openconnect_vase_top_height
    : openconnect_head_top_height;
  large_rect_width =
    head_type == "slot" ? openconnect_slot_large_rect_width
    : head_type == "vase" ? openconnect_vase_large_rect_width
    : openconnect_head_large_rect_width;
  large_rect_height =
    head_type == "slot" ? openconnect_slot_large_rect_height
    : head_type == "vase" ? openconnect_vase_large_rect_height
    : openconnect_head_large_rect_height;
  nub_to_top_distance =
    head_type == "slot" ? openconnect_slot_nub_to_top_distance
    : head_type == "vase" ? openconnect_vase_nub_to_top_distance
    : openconnect_head_nub_to_top_distance;

  difference() {
    union() {
      linear_extrude(h=bottom_height) polygon(offset(bottom_profile, delta=size_offset));
      up(bottom_height - eps) hull() {
          up(openconnect_middle_height) linear_extrude(h=eps) polygon(offset(top_profile, delta=size_offset));
          linear_extrude(h=eps) polygon(offset(bottom_profile, delta=size_offset));
        }
      if (top_height + excess_thickness > 0)
        up(bottom_height + openconnect_middle_height - eps)
          linear_extrude(h=top_height + excess_thickness + eps) polygon(offset(top_profile, delta=size_offset));
    }
    back(large_rect_width / 2 - nub_to_top_distance)
      rot_copies([90, 0, 0], n=add_nubs)
        left(large_rect_width / 2 + size_offset - openconnect_lock_nub_depth / 2 + eps) zrot(-90)
            linear_extrude(4) trapezoid(h=openconnect_lock_nub_depth, w2=openconnect_lock_nub_tip_height, ang=[45, 45], rounding=[openconnect_lock_nub_inner_fillet, openconnect_lock_nub_inner_fillet, -openconnect_lock_nub_outer_fillet, -openconnect_lock_nub_outer_fillet], $fn=64);
  }
}
module openconnect_slot(add_nubs = 1, direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[openconnect_slot_large_rect_width, openconnect_slot_large_rect_height, openconnect_slot_total_height]) {
    up(openconnect_slot_total_height / 2) yrot(180) union() {
          if (direction_flip)
            xflip() openconnect_slot_body(excess_thickness);
          else
            openconnect_slot_body(excess_thickness);
        }
    children();
  }
  module openconnect_slot_body(excess_thickness = 0) {
    openconnect_slot_side_profile = [
      [0, 0],
      [openconnect_slot_large_rect_width / 2, 0],
      [openconnect_slot_large_rect_width / 2, openconnect_slot_bottom_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_middle_height],
      [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_middle_height + openconnect_slot_top_height + excess_thickness],
      [0, openconnect_slot_bottom_height + openconnect_middle_height + openconnect_slot_top_height + excess_thickness],
    ];
    openconnect_slot_bridge_offset_profile = back(openconnect_slot_small_rect_width / 2, rect([openconnect_slot_small_rect_width / 2 + openconnect_slot_bridge_offset, openconnect_slot_small_rect_height + openconnect_slot_move_distance + openconnect_slot_onramp_clearance], chamfer=[openconnect_slot_small_rect_chamfer + openconnect_slot_bridge_offset, 0, 0, 0], anchor=BACK + LEFT));
    union() {
      openconnect_head(head_type="slot", add_nubs=add_nubs ? 1 : 0, excess_thickness=excess_thickness);
      xrot(90) linear_extrude(openconnect_slot_middle_to_bottom + openconnect_slot_move_distance + openconnect_slot_onramp_clearance) xflip_copy() polygon(openconnect_slot_side_profile);
      up(openconnect_slot_bottom_height) linear_extrude(openconnect_slot_top_height + openconnect_middle_height) polygon(openconnect_slot_bridge_offset_profile);
      fwd(openconnect_slot_move_distance) {
        linear_extrude(openconnect_slot_bottom_height) onramp_2d();
        up(openconnect_slot_bottom_height)
          linear_extrude(openconnect_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(openconnect_middle_height) up(openconnect_slot_bottom_height + openconnect_middle_height)
            linear_extrude(openconnect_slot_top_height + excess_thickness) onramp_2d();
      }
      if (excess_thickness > 0)
        fwd(openconnect_slot_small_rect_chamfer) cuboid([openconnect_slot_small_rect_width, openconnect_slot_small_rect_height, openconnect_slot_total_height + excess_thickness], anchor=BOTTOM);
    }
  }
  module onramp_2d() {
    union() {
      offset(delta=openconnect_slot_onramp_clearance)
        left(openconnect_slot_onramp_clearance + openconnect_middle_height) back(openconnect_slot_large_rect_width / 2) {
            rect([openconnect_slot_large_rect_width, openconnect_slot_large_rect_height], chamfer=[openconnect_slot_large_rect_chamfer, openconnect_slot_large_rect_chamfer, 0, 0], anchor=TOP);
            trapezoid(h=4, w1=openconnect_slot_large_rect_width - openconnect_slot_large_rect_chamfer * 2, ang=[45, 45], anchor=BOTTOM);
          }
    }
  }
}
module openconnect_slot_grid(h_grid = 1, v_grid = 1, grid_size = 28, lock_distribution = "None", direction_flip = false, excess_thickness = 0, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[h_grid * grid_size, v_grid * grid_size, openconnect_slot_total_height]) {
    tag_scope() hide_this() cuboid([h_grid * grid_size, v_grid * grid_size, openconnect_slot_total_height]) {
          back(openconnect_slot_to_grid_top_offset) {
            grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
              attach(TOP, BOTTOM, inside=true)
                openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? 1 : 0, direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs=1, direction_flip=direction_flip, excess_thickness=excess_thickness);
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

openconnect_vasecut_side_profile = [
  [0, 0],
  [openconnect_slot_large_rect_width / 2, 0],
  [openconnect_slot_large_rect_width / 2, openconnect_slot_bottom_height],
  [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_middle_height],
  [openconnect_slot_small_rect_width / 2, openconnect_slot_bottom_height + openconnect_middle_height + openconnect_slot_top_height],
  [0, openconnect_slot_bottom_height + openconnect_middle_height + openconnect_slot_top_height],
];

tilt_offset_angle = max(0, final_vase_tilt_angle - 20);

openconnect_vase_small_rect_width = openconnect_slot_small_rect_width + vase_wall_thickness * 2;
openconnect_vase_small_rect_height = openconnect_slot_small_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + tilt_offset_angle, openconnect_slot_total_height);
openconnect_vase_small_rect_chamfer = openconnect_slot_small_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
openconnect_vase_large_rect_width = openconnect_slot_large_rect_width + vase_wall_thickness * 2;
openconnect_vase_large_rect_height = openconnect_slot_large_rect_height + vase_wall_thickness + ang_adj_to_opp(45 + tilt_offset_angle, openconnect_slot_total_height);
openconnect_vase_large_rect_chamfer = openconnect_slot_large_rect_chamfer + vase_wall_thickness - ang_adj_to_opp(45 / 2, vase_wall_thickness);
openconnect_vase_middle_to_bottom = openconnect_vase_large_rect_height - openconnect_vase_large_rect_width / 2;

openconnect_vase_nub_to_top_distance = openconnect_slot_nub_to_top_distance + vase_wall_thickness;
openconnect_vase_bottom_height = openconnect_slot_bottom_height + ang_adj_to_opp(45 / 2, vase_wall_thickness);
openconnect_vase_top_height = openconnect_slot_top_height - ang_adj_to_opp(45 / 2, vase_wall_thickness);

openconnect_vase_top_profile = back(openconnect_vase_small_rect_width / 2, rect([openconnect_vase_small_rect_width, openconnect_vase_small_rect_height], chamfer=[openconnect_vase_small_rect_chamfer, openconnect_vase_large_rect_chamfer, 0, 0], anchor=BACK));
openconnect_vase_bottom_profile = back(openconnect_vase_large_rect_width / 2, rect([openconnect_vase_large_rect_width, openconnect_vase_large_rect_height], chamfer=[openconnect_vase_large_rect_chamfer, openconnect_vase_large_rect_chamfer, 0, 0], anchor=BACK));

up(vase_height / 2) xrot(90 + final_vase_tilt_angle) {
    grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids])
      difference() {
        openconnect_head(head_type="vase", add_nubs=slot_locking_nubs);
        openconnect_head(head_type="slot", add_nubs=slot_locking_nubs);
        cuboid([openconnect_slot_large_rect_width - openconnect_slot_large_rect_chamfer * 2, openconnect_slot_large_rect_height, openconnect_slot_total_height], anchor=FRONT + BOTTOM);
        fwd(openconnect_vase_middle_to_bottom)
          xrot(-(45 + tilt_offset_angle)) cuboid([openconnect_vase_large_rect_width + eps, 20, 20], anchor=BACK + BOTTOM);
        xrot(90) linear_extrude(openconnect_slot_middle_to_bottom + openconnect_slot_move_distance + openconnect_slot_onramp_clearance) xflip_copy() polygon(openconnect_vasecut_side_profile);
        up(openconnect_slot_total_height) cuboid([50, 50, 50], anchor=BOTTOM);
      }
    right(vase_surface_texture != "None" ? surface_texture_depth / 2 : 0) xrot(-final_vase_tilt_angle) diff(remove="root_rm") diff(remove="remove", keep="keep root_rm")
            prismoid(size1=[vase_width, vase_depth], h=vase_height, xang=[90, 90], yang=[90 - final_vase_front_inset_angle, 90 - final_vase_tilt_angle], chamfer=vase_surface_texture != "None" ? [0, 0, 0, 0] : [0, 0, 1, 1], orient=FRONT, anchor=BACK) {
              if (vase_surface_texture != "None") {
                frontwall_height = ang_adj_to_hyp(final_vase_front_inset_angle, vase_height) + ang_adj_to_opp(final_vase_front_inset_angle, surface_texture_depth);
                final_wall_height = ceil(max(frontwall_height, vase_height) / final_surface_texture_size) * final_surface_texture_size;
                final_texture = vase_surface_texture == "checkers" ? texture(vase_surface_texture, border=0.2) : texture(vase_surface_texture);
                diff(remove="frontwall_rm") {
                  attach(FRONT, BOTTOM, align=BOTTOM)
                    textured_tile(final_texture, w1=vase_width, w2=vase_width, shift=0, ysize=final_wall_height,tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                  tag("frontwall_rm") attach(BOTTOM, BACK)
                      cuboid([400, 400, 400]);
                }
                diff(remove="sidewall_rm") {
                  attach(LEFT, BOTTOM, align=BOTTOM)
                    textured_tile(final_texture, w1=vase_depth, w2=vase_depth, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
                  tag("sidewall_rm") attach(FRONT, BACK)
                      cuboid([400, 400, 400]);
                  tag("sidewall_rm") attach(BACK, BACK)
                      cuboid([400, 400, 400]);
                }
                tag("remove") diff(remove="sidewall_rm") {
                    attach(RIGHT, BOTTOM, inside=true, align=BOTTOM)
                      textured_tile(final_texture, w1=vase_depth, w2=vase_depth, shift=0, ysize=final_wall_height, tex_depth=surface_texture_depth, tex_size=[final_surface_texture_size, final_surface_texture_size * (vase_surface_texture == "cubes" ? sqrt(3) : 1)]);
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
