/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>
include <BOSL2/walls.scad>
include <BOSL2/rounding.scad>

generate_drawer_shell = true;
//"Back" is for wall-mounted drawers. "Top" is for underdesk drawers. Other options are more specific and not commonly used. 
shell_slot_position = "Back"; //["Back", "Top", "Bottom", "Left", "Right"]
//Inner size of the shell stay the same regardless of shell_slot_position, so the container is always compatible.
generate_drawer_container = true;
generate_drawer_stopper_clips = true;

/*[Grid Settings]*/
vertical_grids = 2;
horizontal_grids = 5;
depth_grids = 5;

/*[Shell Wall Settings]*/
shell_top_wall_type = "Solid"; //["Solid","Honeycomb"]
shell_bottom_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
shell_side_wall_type = "Solid"; //["Solid","Honeycomb"]

/*[Container Wall Settings]*/
container_solidwall_thickness = 1.68; //0.42
container_honeycombwall_thickness = 2.52; //0.42
//How much lower back and side wall is compared to front wall. stopper_clips_length need to be larger than this value to be effective.
container_front_to_back_height_offset = 4;
container_front_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
container_back_wall_type = "Solid"; //["Solid","Honeycomb"]
//Honeycomb patterns on the side of drawer_shell and drawer_container do not align. If you want to avoid the inconsistent look, use honeycomb side walls on only one part.
container_side_wall_type = "Honeycomb"; //["Solid","Honeycomb"]

/*[Shell Divider Settings]*/
//Divide the drawer shell into several compartments. Enabling this hides containers, as they would need to be generated separately.
add_shell_divider = false;
shell_divider_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
//Divide by height is drawers stacked one above another. Width is drawers side by side.
shell_divider_unit = "Height"; //["Width","Height"]
//Input compartment sizes here. These values also indicate the size of corresponding container.
shell_compartment_grids = "2,1";

/*[Container Divider Settings]*/
//Divide the drawer container into several compartments.
add_container_divider = false;
//The height of divider walls. This value is automatically capped by side wall height.
container_divider_wall_height = 40;
container_divider_wall_thickness = 1.68; //0.42
container_divider_wall_fillet = 2;
container_divider_unit = "Width"; //["Width","Depth","Both"]
//Container compartment's grid size is its inner space divided by total_grids.
container_compartment_total_grid_count = 3;
//Input compartment sizes here. total_grid_count="3" and grids="1,2" means two compartments - one of 1/3, one of 2/3 of container inner size. 
container_compartment_grids = "1,2";

/*[Label and Handle]*/
add_label_holder = true;
//Default label size is recommended for honeycomb front wall. Solid front wall can have larger labels.
label_width = 48;
label_height = 10;
label_depth = 1;
handle_thickness = 2.52; //0.42
//How much the handle protrudes from the front of the drawer container.
handle_depth = 10;

/*[Stopper and Magnet Settings]*/
//Simple drawer stoppers. No magnets needed.
add_stopper_holes = true;
stopper_clips_length = 7;

//Back magnets hold the container securely when it's pushed in.
add_back_magnet_holes = true;
shell_back_magnet_thickness = 2;
container_back_magnet_thickness = 2;
back_magnet_diameter = 6;

//Side magnets act as stoppers by holding the container when it's pulled out.
add_side_magnet_holes = true;
//If wall thickness is not enough for magnets, small "bulges" will be added. 
shell_side_magnet_thickness = 1;
container_side_magnet_thickness = 1;
side_magnet_diameter = 6;

/*[Advanced Settings]*/
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Top Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Slot entry direction can matter when installing in very tight space.
slot_direction_flip = false;
//Note changing shell thickness would also change container size.
shell_thickness = 2.52; //0.42
//The thickness of the strut of honeycomb pattern.
honeycomb_strut_hyp = 5.04; //0.42
shell_to_slot_wall_thickness = 0.84;
//Change this value to adjust how much container would pull out before attaching to side magnets. 
side_magnet_shell_edge_distance = 0.84;
side_magnet_container_edge_distance = 0.84;
container_height_clearance = 0.5; //0.05
container_width_clearance = 0.4; //0.05
container_depth_clearance = 0.4; //0.05

/*[Hidden]*/
// /* [Debug Settings] */
container_bottom_wall_type = "Solid"; //["Solid","Honeycomb"]
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_drawer_overlapped = false;
//Ratio of divider wall to side wall height. 0.9 means the divider walls are 70% as tall as the side walls.
// container_divider_wall_height_scale = 0.9; //[0:0.01:1]
// container_body_height_scale = 0.7; //[0.6:0.05:1]
//unimplemented shell dividers that deal with 2 dimensions at the same time. way too messy.
// shell_main_divide_unit = "Width"; //["Width","Height"]
// shell_width_dividers = "1,4";
// shell_height_dividers = "2 3";
back_magnet_hole_position = "Bottom Corners"; //["All","Corners","Bottom Corners"]
magnet_hole_side_clearance = 0.1;
magnet_hole_depth_clearance = 0.1;

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
module openconnect_head(head_type = "head", add_nubs = "both", nub_flattop = true, nub_taperin = true, excess_thickness = 0, size_offset = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  bottom_profile = head_type == "slot" ? ocslot_bottom_profile : ochead_bottom_profile;
  top_profile = head_type == "slot" ? ocslot_top_profile : ochead_top_profile;
  bottom_height = head_type == "slot" ? ocslot_bottom_height : ochead_bottom_height;
  top_height = head_type == "slot" ? ocslot_top_height : ochead_top_height;
  large_rect_width = head_type == "slot" ? ocslot_large_rect_width : ochead_large_rect_width;
  large_rect_height = head_type == "slot" ? ocslot_large_rect_height : ochead_large_rect_height;
  nub_to_top_distance = head_type == "slot" ? ocslot_nub_to_top_distance : ochead_nub_to_top_distance;
  nub_angle = nub_taperin ? adj_opp_to_ang(ochead_middle_height, ochead_middle_height - ochead_nub_depth) : 0;
  total_height = bottom_height + top_height + ochead_middle_height;

  attachable(anchor, spin, orient, size=[large_rect_width, large_rect_width, total_height]) {
    tag_scope() down(total_height / 2) difference() {
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
    children();
  }
}
module openconnect_slot(add_nubs = "left", direction_flip = false, excess_thickness = 0, anchor = BOTTOM, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[ocslot_large_rect_width, ocslot_large_rect_width, ocslot_total_height]) {
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
            if (lock_distribution == "All" || lock_distribution == "Staggered" || lock_distribution == "None")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger=lock_distribution == "Staggered")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs=(h_grid == 1 && v_grid == 1 && lock_distribution == "Staggered") || lock_distribution == "All" ? "left" : "", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Staggered")
              grid_copies([grid_size, grid_size], [h_grid, v_grid], stagger="alt")
                attach(TOP, BOTTOM, inside=true)
                  openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
            if (lock_distribution == "Corners" || lock_distribution == "Top Corners") {
              if (lock_distribution == "Corners")
                grid_copies([grid_size * max(1, h_grid - 1), grid_size * max(1, v_grid - 1)], [min(h_grid, 2), min(v_grid, 2)])
                  attach(TOP, BOTTOM, inside=true)
                    openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
              else {
                back(grid_size * (v_grid - 1) / 2)
                  line_copies(spacing=grid_size * max(1, h_grid - 1), n=min(2, h_grid))
                    attach(TOP, BOTTOM, inside=true)
                      openconnect_slot(add_nubs="left", direction_flip=direction_flip, excess_thickness=excess_thickness);
              }
              omit_edge_rows =
                lock_distribution == "Corners" ? [0, v_grid - 1]
                : lock_distribution == "Top Corners" ? [0] : [];
              for (i = [0:1:v_grid - 1]) {
                back(grid_size * (v_grid - 1) / 2) fwd(grid_size * i) {
                    if (in_list(i, omit_edge_rows)) {
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

shell_ocslot_part_thickness = ocslot_total_height + shell_to_slot_wall_thickness;
shell_outer_chamfer = 2; //0.2
shell_inner_chamfer = 0.8;
container_outer_chamfer = 0.8;
container_inner_chamfer = 0;

//shell parameters
shell_width = horizontal_grids * tile_size + (shell_slot_position == "Left" || shell_slot_position == "Right" ? shell_ocslot_part_thickness - shell_thickness : 0);
shell_height = vertical_grids * tile_size + (shell_slot_position == "Top" || shell_slot_position == "Bottom" ? shell_ocslot_part_thickness - shell_thickness : 0);
shell_depth = depth_grids * tile_size;
shell_inner_width = horizontal_grids * tile_size - shell_thickness * 2;
shell_inner_height = vertical_grids * tile_size - shell_thickness * 2;
shell_inner_depth = depth_grids * tile_size - shell_ocslot_part_thickness;
//hexpanel size is calculated so outer strut overlap with shell wall
shell_hexpanel_width = shell_width - shell_inner_chamfer * 2;
shell_hexpanel_height = shell_height - shell_inner_chamfer * 2;
shell_hexpanel_depth = shell_depth + shell_thickness - shell_ocslot_part_thickness;

//shell divider parameter
shell_divideW = (shell_divider_unit == "Width");
shell_main_divide_grids = shell_divideW ? horizontal_grids : vertical_grids;
shell_main_divide_strs = str_split(str_strip(str_replace_char(shell_compartment_grids, " ", ","), ","), ",");
shell_main_divide_nums = [for (i = [0:len(shell_main_divide_strs) - 1]) parse_num(shell_main_divide_strs[i])];
shell_main_divide_cumnums = add_shell_divider ? [for (i = cumsum(shell_main_divide_nums)) if (i < shell_main_divide_grids) i] : [shell_main_divide_grids];
shell_main_divide_tmp =
  len(shell_main_divide_cumnums) == 0 ? []
  : slice(shell_main_divide_nums, 0, len(shell_main_divide_cumnums) - 1);
shell_main_divide_list =
  len(shell_main_divide_tmp) == 0 ? []
  : last(shell_main_divide_cumnums) == shell_main_divide_grids ? shell_main_divide_tmp
  : concat(shell_main_divide_tmp, [shell_main_divide_grids - last(shell_main_divide_cumnums)]);
shell_horizontal_compartments = add_shell_divider && shell_divideW ? shell_main_divide_list : [horizontal_grids];

//container parameters
container_width = shell_inner_width - container_width_clearance * 2;
container_height = shell_inner_height - container_height_clearance * 2;
container_depth = shell_inner_depth - container_depth_clearance;
container_front_wall_thickness = container_front_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_bottom_wall_thickness = container_bottom_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_side_wall_thickness = container_side_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
container_back_wall_thickness = container_back_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;

//hexwall parameters
honeycomb_unit_space_adj = 14;
honeycomb_unit_space_hyp = ang_adj_to_hyp(30, honeycomb_unit_space_adj);
honeycomb_strut_adj = ang_hyp_to_adj(30, honeycomb_strut_hyp);
hex_ir = (honeycomb_unit_space_hyp - honeycomb_strut_adj) / 2;
hex_or = hex_ir * 2 / sqrt(3);
fronthex_width_struts = floor(container_width / honeycomb_unit_space_adj);
fronthex_width = fronthex_width_struts * honeycomb_unit_space_adj;
fronthex_width_offset = (container_width - fronthex_width) / 2;
//height struts is round to nearest 0.5
fronthex_height_struts = floor(container_height / honeycomb_unit_space_hyp * 2) / 2;
fronthex_height = fronthex_height_struts * honeycomb_unit_space_hyp;
fronthex_height_offset = (container_height - fronthex_height) / 2;
fronthex_bottom_strut_height = honeycomb_unit_space_hyp / 2 + honeycomb_strut_adj / 2 + fronthex_height_offset - honeycomb_strut_adj;
height_adj_to_width_opp = ang_adj_to_opp(30, abs(fronthex_height_offset));
// container_front_to_back_height_offset = 2.1;
//this is a magic number because I don't want to calculate hexagon anymore
shell_front_hex_offset = 4.05;

stopper_width = 4.8;
stopper_height = 2.4;
stopper_rounding = 0.4;
stopper_flank_width = 2;
stopper_flank_depth = 0.84;
//when set to 0, the center of the stopper is tile_size/2 to the edge of the drawer.
stopper_to_edge_offset = 7;

handle_chamfer = 0.4;

//magnet parameters
shell_back_magnet_hole_thickness = shell_back_magnet_thickness + magnet_hole_depth_clearance;
container_back_magnet_hole_thickness = container_back_magnet_thickness + magnet_hole_depth_clearance;
back_magnet_hole_diameter = back_magnet_diameter + magnet_hole_side_clearance * 2;
back_magnet_ocslot_offset = 3;
back_magnet_grid_space =
  back_magnet_hole_position == "Corners" ? [tile_size * (horizontal_grids - 2), tile_size * (vertical_grids - 1)]
  : back_magnet_hole_position == "Bottom Corners" ? [tile_size * (horizontal_grids - 2), tile_size * (vertical_grids - 1)]
  : [tile_size, tile_size];
back_back_magnet_grid_count =
  back_magnet_hole_position == "Corners" ? [min(horizontal_grids - 1, 2), min(vertical_grids, 2)]
  : back_magnet_hole_position == "Bottom Corners" ? [min(horizontal_grids - 1, 2), 1]
  : [horizontal_grids - 1, vertical_grids];

shell_side_magnet_hole_thickness = shell_side_magnet_thickness + magnet_hole_depth_clearance;
container_side_magnet_hole_thickness = container_side_magnet_thickness + magnet_hole_depth_clearance;
side_magnet_hole_diameter = side_magnet_diameter + magnet_hole_side_clearance * 2;

function calc_inner_chamfer(outer_chamfer, wall_thickness) = (outer_chamfer / sqrt(2) + wall_thickness - wall_thickness * sqrt(2)) * sqrt(2);

half_of_anchor =
  view_cross_section == "Right" ? RIGHT
  : view_cross_section == "Back" ? BACK
  : view_cross_section == "Diagonal" ? RIGHT + BACK
  : 0;

if (half_of_anchor != 0) {
  if (generate_drawer_shell)
    half_of(half_of_anchor, s=300)
      down(shell_ocslot_part_thickness)
        back(shell_slot_position == "Top" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Bottom" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
          left(shell_slot_position == "Left" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Right" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
            drawer_shell();
  if (generate_drawer_container && !add_shell_divider)
    half_of(half_of_anchor, s=300)
      left(view_drawer_overlapped ? 0 : horizontal_grids * tile_size)
        up(container_depth_clearance)
          drawer_container();
} else {
  if (generate_drawer_shell)
    down(view_drawer_overlapped ? shell_ocslot_part_thickness : 0)
      back(shell_slot_position == "Top" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Bottom" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
        left(shell_slot_position == "Left" ? (shell_ocslot_part_thickness - shell_thickness) / 2 : shell_slot_position == "Right" ? -(shell_ocslot_part_thickness - shell_thickness) / 2 : 0)
          drawer_shell();
  if (generate_drawer_container && !add_shell_divider)
    fwd(view_drawer_overlapped || !generate_drawer_shell ? 0 : vertical_grids * tile_size / 2 + 10)
      up(view_drawer_overlapped ? container_depth_clearance : container_height / 2)
        xrot(view_drawer_overlapped ? 0 : 90)
          drawer_container();
  if (generate_drawer_stopper_clips)
    right(generate_drawer_shell ? horizontal_grids * tile_size / 2 + 10 : 0) {
      drawer_stopper();
      right(tile_size)
        drawer_stopper();
    }
}

module drawer_shell() {
  difference() {
    intersection() {
      diff(remove="rm_outer", keep="") diff(keep="keep rm_outer") {
          cuboid([shell_width, shell_height, shell_depth], anchor=BOTTOM) {
            shell_inner_cut_align =
              shell_slot_position == "Bottom" ? BACK
              : shell_slot_position == "Top" ? FRONT
              : shell_slot_position == "Left" ? RIGHT
              : shell_slot_position == "Right" ? LEFT : CENTER;
            left_hc = shell_side_wall_type == "Honeycomb" && shell_slot_position != "Left";
            right_hc = shell_side_wall_type == "Honeycomb" && shell_slot_position != "Right";
            top_hc = shell_top_wall_type == "Honeycomb" && shell_slot_position != "Top";
            bottom_hc = shell_bottom_wall_type == "Honeycomb" && shell_slot_position != "Bottom";
            attach(TOP, TOP, align=shell_inner_cut_align, inset=shell_thickness, inside=true)
              tag("remove") cuboid([shell_inner_width, shell_inner_height, shell_inner_depth], edges="Z", chamfer=shell_inner_chamfer);
            //left wall
            if (left_hc)
              attach(TOP, RIGHT, align=LEFT, inside=true, spin=90)
                tag("keep") hex_panel([shell_hexpanel_depth, shell_hexpanel_height, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, TOP, align=LEFT, inside=true)
              tag(left_hc ? "remove" : "keep") cuboid([shell_thickness + (left_hc ? eps : 0), shell_inner_height - shell_inner_chamfer * 2, shell_inner_depth]);
            //right wall
            if (right_hc)
              attach(TOP, RIGHT, align=RIGHT, inside=true, spin=90)
                tag("keep") hex_panel([shell_hexpanel_depth, shell_hexpanel_height, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, TOP, align=RIGHT, inside=true)
              tag(right_hc ? "remove" : "keep") cuboid([shell_thickness + (right_hc ? eps : 0), shell_inner_height - shell_inner_chamfer * 2, shell_inner_depth]);
            //top wall
            if (top_hc)
              attach(TOP, RIGHT, align=BACK, inside=true)
                tag("keep") hex_panel([shell_hexpanel_depth, shell_hexpanel_width, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            if (add_stopper_holes)
              attach(BACK, BACK, align=TOP, inset=shell_thickness, inside=true)
                tag("keep") cuboid([shell_inner_width, shell_thickness, shell_front_hex_offset]);
            attach(TOP, TOP, align=BACK, inside=true)
              tag(top_hc ? "remove" : "keep") cuboid([shell_inner_width - shell_inner_chamfer * 2, shell_thickness + (top_hc ? eps : 0), shell_inner_depth]);
            //bottom wall
            if (bottom_hc)
              attach(TOP, RIGHT, align=FRONT, inside=true)
                tag("keep") hex_panel([shell_hexpanel_depth, shell_hexpanel_width, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, TOP, align=FRONT, inside=true)
              tag(bottom_hc ? "remove" : "keep") cuboid([shell_inner_width - shell_inner_chamfer * 2, shell_thickness + (bottom_hc ? eps : 0), shell_inner_depth]);
            //openconnect slot
            if (shell_slot_position == "Back")
              attach(BOTTOM, TOP, inside=true)
                tag("rm_outer") openconnect_slot_grid(h_grid=horizontal_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
            else if (shell_slot_position == "Top")
              attach(BACK, TOP, inside=true, spin=slot_direction_flip ? 90 : -90, shiftout=eps)
                tag("rm_outer") xflip() openconnect_slot_grid(h_grid=depth_grids, v_grid=horizontal_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
            else if (shell_slot_position == "Bottom")
              attach(FRONT, TOP, inside=true, spin=slot_direction_flip ? 90 : -90, shiftout=eps)
                tag("rm_outer") xflip() openconnect_slot_grid(h_grid=depth_grids, v_grid=horizontal_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
            else if (shell_slot_position == "Left")
              attach(LEFT, TOP, align=BOTTOM, inside=true, spin=90)
                tag("rm_outer") openconnect_slot_grid(h_grid=add_side_magnet_holes ? depth_grids - 1 : depth_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=slot_direction_flip, excess_thickness=0);
            else if (shell_slot_position == "Right")
              attach(RIGHT, TOP, align=BOTTOM, inside=true, spin=-90)
                tag("rm_outer") openconnect_slot_grid(h_grid=add_side_magnet_holes ? depth_grids - 1 : depth_grids, v_grid=vertical_grids, grid_size=tile_size, lock_distribution=slot_lock_distribution, direction_flip=!slot_direction_flip, excess_thickness=0);
            if (add_side_magnet_holes) {
              if (left_hc)
                attach(LEFT + FRONT, LEFT + FRONT, align=TOP, inside=true)
                  tag("keep") cuboid([shell_thickness, shell_height, 10.8]);
              ycopies(tile_size, vertical_grids)
                right(shell_slot_position == "Left" ? shell_ocslot_part_thickness : shell_thickness) left(shell_side_magnet_hole_thickness - eps * 2) attach(LEFT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                      tag("rm_outer") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
              if (right_hc)
                attach(RIGHT + FRONT, RIGHT + FRONT, align=TOP, inside=true)
                  tag("keep") cuboid([shell_thickness, shell_height, 10.8]);
              ycopies(tile_size, vertical_grids)
                left(shell_slot_position == "Right" ? shell_ocslot_part_thickness : shell_thickness) right(shell_side_magnet_hole_thickness - eps * 2) attach(RIGHT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                      tag("rm_outer") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
            }
            if (add_shell_divider)
              shell_divider();
            if (add_back_magnet_holes) {
              back(back_magnet_ocslot_offset + ocslot_to_grid_top_offset)
                grid_copies(spacing=[tile_size, tile_size], n=[horizontal_grids - 1, vertical_grids])
                  attach(BOTTOM, BOTTOM, inside=true)
                    tag("rm_outer") cyl(h=shell_back_magnet_hole_thickness, d=back_magnet_hole_diameter);
            }

            for (i = [0:len(shell_horizontal_compartments) - 1]) {
              right(i == 0 ? 0 : shell_main_divide_cumnums[i - 1] * tile_size) {
                if (add_stopper_holes)
                  left(shell_width / 2 - tile_size / 2)for (j = [0:shell_horizontal_compartments[i] == 1 ? 0 : 1]) {
                    left(shell_horizontal_compartments[i] == 1 ? 0 : j == 0 ? stopper_to_edge_offset : -stopper_to_edge_offset)
                      right(j * (shell_horizontal_compartments[i] - 1) * tile_size)
                        tag("rm_outer") attach(BACK, TOP, align=TOP, inset=shell_thickness, inside=true)
                            cuboid([stopper_width + stopper_flank_width, stopper_height, stopper_flank_depth])
                              attach(BOTTOM, TOP)
                                cuboid([stopper_width, stopper_height, max(shell_thickness, shell_ocslot_part_thickness) - stopper_flank_depth + eps], rounding=-stopper_rounding, edges=[TOP + LEFT, TOP + RIGHT], $fn=64);
                  }
              }
            }
          }
        }
      shell_chamfer_edge_except =
        shell_slot_position == "Bottom" ? [FRONT + LEFT, FRONT + RIGHT]
        : shell_slot_position == "Top" ? [BACK + LEFT, BACK + RIGHT]
        : shell_slot_position == "Left" ? [BACK + LEFT, FRONT + LEFT]
        : shell_slot_position == "Right" ? [BACK + RIGHT, FRONT + RIGHT]
        : [];
      cuboid([shell_width, shell_height, shell_depth], edges="Z", chamfer=shell_outer_chamfer, except=shell_chamfer_edge_except, anchor=BOTTOM);
    }
  }
}
module shell_divider() {
  //Divider wall must be double the thickness of outer wall thickness, to keep the size of container consistent between divided and standalone drawers.
  shell_divider_wall_thickness = shell_thickness * 2;

  // shell_main_divide_cumnums = cumsum(shell_main_divide_nums);

  mainwall_alignment = shell_divideW ? LEFT : BACK;
  mainsolidwall_anchor = shell_divideW ? TOP : LEFT;
  mainhexwall_anchor = shell_divideW ? TOP : TOP;
  mainhexwall_spin = shell_divideW ? 90 : 0;

  mainsolidwall_x = shell_divideW ? shell_divider_wall_thickness : shell_width;
  mainsolidwall_y = shell_divideW ? shell_height : shell_divider_wall_thickness;
  mainsolidwall_z = shell_depth;
  mainhexwall_length = !shell_divideW ? shell_hexpanel_width : shell_hexpanel_height;
  shell_first_wall_offset = (shell_slot_position == "Bottom" && !shell_divideW) || (shell_slot_position == "Left" && shell_divideW) ? shell_divider_wall_thickness - shell_ocslot_part_thickness : shell_divider_wall_thickness - shell_thickness;

  for (i = [0:len(shell_main_divide_cumnums) - 1]) {
    if (shell_main_divide_cumnums[i] > 0 && shell_main_divide_cumnums[i] < shell_main_divide_grids) {
      main_compartment_inset = shell_main_divide_cumnums[i] * tile_size - shell_first_wall_offset;
      tag_intersect(tag="keep", intersect="msk0", keep="kp1") {
        attach(mainsolidwall_anchor, mainsolidwall_anchor, align=mainwall_alignment, inset=main_compartment_inset, inside=true)
          tag_diff(tag=shell_divider_wall_type == "Honeycomb" ? "" : "kp1", remove="rm1") {
            cuboid([mainsolidwall_x, mainsolidwall_y, mainsolidwall_z]) {
              if (!shell_divideW && add_stopper_holes) {
                tag("rm1") line_copies(tile_size * (horizontal_grids - 1), 2)
                    attach(BACK, TOP, align=TOP, inset=shell_thickness, inside=true)
                      cuboid([stopper_width + stopper_flank_width, stopper_height, stopper_flank_depth])
                        attach(BOTTOM, TOP)
                          cuboid([stopper_width, stopper_height, shell_divider_wall_thickness - stopper_flank_depth + eps], rounding=-stopper_rounding, edges=[TOP + LEFT, TOP + RIGHT], $fn=64);
              }
              if (shell_divideW && add_side_magnet_holes) {
                ycopies(tile_size, vertical_grids)
                  attach(LEFT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                    tag("rm1") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                ycopies(tile_size, vertical_grids)
                  attach(RIGHT, FRONT, align=TOP, inset=side_magnet_shell_edge_distance, inside=true)
                    tag("rm1") teardrop(h=shell_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
              }
            }
          }
        if (shell_divider_wall_type == "Honeycomb")
          tag_diff(tag="msk0", remove="rm0")
            attach(TOP, RIGHT, align=mainwall_alignment, inset=main_compartment_inset, inside=true, spin=mainhexwall_spin)
              hex_panel([shell_hexpanel_depth, mainhexwall_length, shell_divider_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness) {
                if (!shell_divideW && add_stopper_holes)
                  attach(RIGHT, TOP, inside=true)
                    tag("") cuboid([shell_width, shell_divider_wall_thickness, 10.8]);
                if (shell_divideW && add_side_magnet_holes)
                  attach(RIGHT, TOP, inside=true)
                    tag("") cuboid([shell_height, shell_divider_wall_thickness, 10.8]);
              }
      }
    }
  }
}
// module shell_divider() {
//   //Divider wall must be double the thickness of outer wall thickness, to keep the size of container consistent between divided and standalone drawers.
//   divider_wall_thickness = shell_thickness * 2;
//   shell_divideW = shell_main_divide_unit == "Width";

//   shell_main_divide_strs = str_split(str_strip(str_replace_char(container_divideW ? shell_width_dividers : shell_height_dividers, " ", ","), ","), ",");
//   shell_main_divide_nums = [for (i = [0:len(main_divide_strs) - 1]) parse_num(main_divide_strs[i])];
//   shell_main_divide_cumnums = cumsum(main_divide_nums);
//   sub_divide_strs_vecs = str_split(str_strip(!mainW ? shell_width_dividers : shell_height_dividers, " "), " ");
//   sub_divide_nums_vecs = [for (i = [0:len(sub_divide_strs_vecs) - 1]) [for (j = [0:len(str_split(str_strip(sub_divide_strs_vecs[i], ","), ",")) - 1]) parse_num(str_split(str_strip(sub_divide_strs_vecs[i], ","), ",")[j])]];
//   sub_divide_cumnums_vecs = [for (i = [0:len(sub_divide_nums_vecs) - 1]) cumsum(sub_divide_nums_vecs[i])];

//   mainwall_alignment = mainW ? LEFT : BACK;
//   mainhexwall_spin = mainW ? 90 : 0;
//   mainhexwall_length = !mainW ? shell_hexpanel_width : shell_hexpanel_height;
//   mainsolidwall_size = mainW ? [divider_wall_thickness, shell_inner_height, shell_inner_depth] : [shell_inner_width, divider_wall_thickness, shell_inner_depth];

//   subwall_alignment = mainW ? BACK : LEFT;
//   subhexwall_spin = mainW ? 0 : 90;
//   subhexwall_length = mainW ? shell_hexpanel_width : shell_hexpanel_height;

//   for (i = [0:len(main_divide_cumnums) - 1]) {
//     if (main_divide_cumnums[i] > 0 && main_divide_cumnums[i] < (mainW ? horizontal_grids : vertical_grids)) {
//       main_compartment_inset = main_divide_cumnums[i] * tile_size - divider_wall_thickness / 2;
//       sub_compartment_size = main_divide_nums[i] * tile_size - divider_wall_thickness;

//       subwall_translate_base = mainW ? [-(shell_width / 2 - sub_compartment_size / 2 - shell_thickness), 0, 0] : [0, (shell_height / 2 - sub_compartment_size / 2 - shell_thickness), 0];
//       subsolidwall_size = mainW ? [sub_compartment_size, divider_wall_thickness, shell_depth] : [divider_wall_thickness, sub_compartment_size, shell_inner_depth];

//       if (len(sub_divide_cumnums_vecs) > i) {
//         for (j = [0:len(sub_divide_cumnums_vecs[i]) - 1]) {
//           subwall_translate_offset = mainW ? [(i > 0 ? main_divide_cumnums[i - 1] * tile_size : 0), 0, 0] : [0, -(i > 0 ? main_divide_cumnums[i - 1] * tile_size : 0), 0];
//           if (sub_divide_cumnums_vecs[i][j] > 0 && sub_divide_cumnums_vecs[i][j] < (!mainW ? horizontal_grids : vertical_grids)) {
//             if (shell_divider_wall_type == "Honeycomb") {
//               tag_intersect(tag="keep", intersect="msk0", keep="kp1") {
//                 attach(TOP, RIGHT, align=subwall_alignment, inset=sub_divide_cumnums_vecs[i][j] * tile_size - divider_wall_thickness / 2, inside=true, spin=subhexwall_spin)
//                   tag("") hex_panel([shell_hexpanel_depth, subhexwall_length, divider_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
//                 translate(subwall_translate_base) translate(subwall_translate_offset)
//                     attach(TOP, TOP, align=subwall_alignment, inset=sub_divide_cumnums_vecs[i][j] * tile_size - divider_wall_thickness / 2, inside=true)
//                       tag("msk0") cuboid(subsolidwall_size);
//               }
//             }
//             else
//               translate(subwall_translate_base) translate(subwall_translate_offset)
//                   attach(TOP, TOP, align=subwall_alignment, inset=sub_divide_cumnums_vecs[i][j] * tile_size - divider_wall_thickness / 2, inside=true)
//                     tag("keep") cuboid(subsolidwall_size);
//           }
//         }
//       }
//       if (shell_divider_wall_type == "Honeycomb") {
//         tag_intersect(tag="keep", intersect="msk0", keep="kp1") {
//           attach(TOP, RIGHT, align=mainwall_alignment, inset=main_compartment_inset, inside=true, spin=mainhexwall_spin)
//             tag("") hex_panel([shell_hexpanel_depth, mainhexwall_length, divider_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
//           attach(TOP, TOP, align=mainwall_alignment, inset=main_compartment_inset, inside=true)
//             tag("msk0") cuboid(mainsolidwall_size);
//         }
//       }
//       else
//         attach(TOP, TOP, align=mainwall_alignment, inset=main_compartment_inset, inside=true)
//           tag("keep") cuboid(mainsolidwall_size);
//     }
//   }
// }
module drawer_container() {
  intersect(intersect="mask", keep="kp_root") {
    diff(remove="rm_outer", keep="mask kp_root") diff(remove="remove", keep="keep mask rm_outer kp_root")
        cuboid([container_width, container_height, container_depth], anchor=BOTTOM) {
          attach(BACK, BACK, align=BOTTOM, inset=container_back_wall_thickness, inside=true)
            tag("remove") cuboid([container_width - container_side_wall_thickness * 2, container_height - container_bottom_wall_thickness, container_depth - container_back_wall_thickness - container_front_wall_thickness], edges=[FRONT + LEFT, FRONT + RIGHT], chamfer=container_inner_chamfer);
          left_hc = container_side_wall_type == "Honeycomb";
          right_hc = container_side_wall_type == "Honeycomb";
          bottom_hc = container_bottom_wall_type == "Honeycomb";
          front_hc = container_front_wall_type == "Honeycomb";
          back_hc = container_back_wall_type == "Honeycomb";
          // container_back_wall_height = container_height * container_body_height_scale;
          container_back_wall_height = container_height - container_front_to_back_height_offset;
          container_side_wall_height = container_back_wall_height - container_outer_chamfer;
          //front wall
          if (front_hc)
            attach(FRONT, LEFT, align=TOP, inside=true)
              tag("keep") hex_panel([container_height, container_width, container_front_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness + container_inner_chamfer));
          attach(TOP, TOP, align=FRONT, inset=container_bottom_wall_thickness, inside=true)
            tag(front_hc ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2, container_height - container_bottom_wall_thickness, container_front_wall_thickness + (front_hc ? eps : 0)], edges="Z", chamfer=container_inner_chamfer);
          //back wall
          if (back_hc)
            attach(FRONT, LEFT, align=BOTTOM, inside=true)
              tag("keep") hex_panel([container_height, container_width, container_back_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness + container_inner_chamfer));
          attach(BOTTOM, BOTTOM, align=FRONT, inset=container_bottom_wall_thickness, inside=true)
            tag(back_hc ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2, back_hc ? container_back_wall_height - container_bottom_wall_thickness * 2 : container_back_wall_height, container_back_wall_thickness + (back_hc ? eps : 0)], edges="Z", chamfer=container_inner_chamfer);
          //side walls
          if (left_hc)
            attach(FRONT, LEFT, align=LEFT, inside=true, spin=90)
              tag("keep") hex_panel([container_height, container_depth, container_side_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness + container_inner_chamfer));
          if (right_hc)
            attach(FRONT, LEFT, align=RIGHT, inside=true, spin=90)
              tag("keep") hex_panel([container_height, container_depth, container_side_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_bottom_wall_thickness + container_inner_chamfer));
          down(container_front_wall_thickness) attach(LEFT + TOP, LEFT + TOP, align=FRONT, inset=container_bottom_wall_thickness + container_inner_chamfer, inside=true)
              tag(left_hc ? "remove" : "keep") cuboid([container_side_wall_thickness + (left_hc ? eps : 0), container_side_wall_height - container_bottom_wall_thickness - container_inner_chamfer - (left_hc ? container_side_wall_thickness : 0), container_depth - container_front_wall_thickness - container_back_wall_thickness]);
          down(container_front_wall_thickness) attach(RIGHT + TOP, RIGHT + TOP, align=FRONT, inset=container_bottom_wall_thickness + container_inner_chamfer, inside=true)
              tag(right_hc ? "remove" : "keep") cuboid([container_side_wall_thickness + (right_hc ? eps : 0), container_side_wall_height - container_bottom_wall_thickness - container_inner_chamfer - (right_hc ? container_side_wall_thickness : 0), container_depth - container_front_wall_thickness - container_back_wall_thickness]);

          
          //bottom wall
          if (bottom_hc)
            attach(TOP, LEFT, align=FRONT, inside=true)
              tag("keep") hex_panel([container_depth, container_width, container_bottom_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=min(container_side_wall_thickness, container_back_wall_thickness, container_front_wall_thickness));
          attach(FRONT, FRONT, align=BOTTOM, inset=container_back_wall_thickness, inside=true)
            tag(bottom_hc ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2 - container_inner_chamfer * 2, container_bottom_wall_thickness + (bottom_hc ? eps : 0), container_depth - container_front_wall_thickness - container_back_wall_thickness]);

          
          tag("mask") {
            attach(FRONT, FRONT, align=TOP, inset=-handle_depth, inside=true)
              cuboid([container_width, container_height, container_front_wall_thickness + handle_depth], edges="Z", chamfer=container_outer_chamfer);
            attach(FRONT, FRONT, align=TOP, inset=container_front_wall_thickness, inside=true)
              cuboid([container_width, container_side_wall_height, container_depth - container_front_wall_thickness - container_back_wall_thickness], edges=[FRONT + LEFT, FRONT + RIGHT], chamfer=container_outer_chamfer);
            attach(BOTTOM, BOTTOM, align=FRONT, inside=true)
              cuboid([container_width, container_back_wall_height, container_back_wall_thickness], edges=["Z"], chamfer=container_outer_chamfer);
          }
          container_handle();
          if (add_label_holder)
            container_label_holder();
          if (add_container_divider)
            container_divider();
          if (add_side_magnet_holes)
            xflip_copy() {
              hole_extrude_thickness = container_side_magnet_hole_thickness - container_side_wall_thickness + 0.42 + eps;
              if (container_side_wall_type == "Honeycomb")
                attach(LEFT + FRONT, LEFT + FRONT, align=BOTTOM, inside=true)
                  tag("keep") cuboid([container_side_wall_thickness, container_height - container_front_to_back_height_offset - container_outer_chamfer, shell_front_hex_offset + honeycomb_unit_space_hyp / 2]);
              ycopies(tile_size, vertical_grids) {
                attach(LEFT, FRONT, align=BOTTOM, inset=side_magnet_container_edge_distance, inside=true, spin=90)
                  tag("rm_outer") teardrop(h=container_side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                if (hole_extrude_thickness > eps)
                  right(container_side_wall_thickness) attach(LEFT, FRONT, align=BOTTOM, inset=side_magnet_container_edge_distance, inside=true, spin=90)
                      tag("kp_root") teardrop(h=hole_extrude_thickness, d=side_magnet_hole_diameter + 0.2, cap_h=side_magnet_hole_diameter / 2 + 0.2, chamfer1=-hole_extrude_thickness);
              }
            }
          if (add_back_magnet_holes) {
            hole_extrude_thickness = container_back_magnet_hole_thickness - container_back_wall_thickness + 0.42 + eps;
            if (back_hc)
              line_copies(back_magnet_grid_space[0], back_back_magnet_grid_count[0])
                attach(BOTTOM + FRONT, BOTTOM + FRONT, inside=true)
                  tag("keep") cuboid([back_magnet_hole_diameter + 4.2, container_height - container_front_to_back_height_offset, container_back_wall_thickness]);
            back(ocslot_to_grid_top_offset) back(back_magnet_ocslot_offset) fwd(back_magnet_hole_position == "Bottom Corners" ? (vertical_grids - 1) / 2 * tile_size : 0)
                  grid_copies(back_magnet_grid_space, back_back_magnet_grid_count) {
                    attach(BOTTOM, FRONT, inside=true)
                      tag("rm_outer") teardrop(h=container_back_magnet_hole_thickness, d=back_magnet_hole_diameter, cap_h=back_magnet_hole_diameter / 2 + 0.2);
                    if (hole_extrude_thickness > eps)
                      up(container_back_wall_thickness) attach(BOTTOM, FRONT, inside=true)
                          tag("kp_root") teardrop(h=hole_extrude_thickness, d=back_magnet_hole_diameter + 0.2, cap_h=back_magnet_hole_diameter / 2 + 0.2, chamfer1=-hole_extrude_thickness);
                  }
          }
        }
  }
}
module container_divider() {
  container_main_divide_strs = str_split(str_strip(str_replace_char(container_compartment_grids, " ", ","), ","), ",");
  container_main_divide_nums = [for (i = [0:len(container_main_divide_strs) - 1]) parse_num(container_main_divide_strs[i])];
  container_main_divide_cumnums = [for (i = cumsum(container_main_divide_nums)) if (i < container_compartment_total_grid_count) i];
  if (container_divider_unit != "Both")
    sub_divider(container_divider_unit == "Width");
  else {
    sub_divider(true);
    sub_divider(false);
  }
  module sub_divider(container_divideW) {
    container_inner_size =
      container_divideW ? container_width - container_side_wall_thickness * 2 - container_divider_wall_thickness * len(container_main_divide_cumnums)
      : container_depth - container_front_wall_thickness - container_back_wall_thickness - container_divider_wall_thickness * len(container_main_divide_cumnums);
    container_mainwall_alignment = container_divideW ? LEFT : TOP;
    container_mainsolidwall_anchor = container_divideW ? FRONT + TOP : FRONT;

    container_mainsolidwall_x = container_divideW ? container_divider_wall_thickness : container_width;
    container_mainsolidwall_y = min((container_height - container_front_to_back_height_offset - container_outer_chamfer), container_divider_wall_height + container_bottom_wall_thickness);
    container_mainsolidwall_z = container_divideW ? container_depth : container_divider_wall_thickness;
    container_compartment_size_unit = container_inner_size / container_compartment_total_grid_count;
    container_first_wall_offset = container_divideW ? container_side_wall_thickness : container_front_wall_thickness;

    container_divider_fillet_edges = container_divideW ? [FRONT + LEFT, FRONT + RIGHT] : [FRONT + TOP, FRONT + BOTTOM];
    for (i = [0:len(container_main_divide_cumnums) - 1]) {
      container_main_compartment_inset = container_main_divide_cumnums[i] * container_compartment_size_unit + container_first_wall_offset + i * container_divider_wall_thickness;
      if (container_main_divide_cumnums[i] > 0 && container_main_compartment_inset < container_inner_size) {
        attach(container_mainsolidwall_anchor, container_mainsolidwall_anchor, align=container_mainwall_alignment, inset=container_main_compartment_inset, inside=true)
          tag("keep") cuboid([container_mainsolidwall_x, container_mainsolidwall_y, container_mainsolidwall_z]) {
              back(container_bottom_wall_thickness) edge_mask(container_divider_fillet_edges)
                  rounding_edge_mask(r=container_divider_wall_fillet, spin=container_divideW ? 90 : -90);
            }
      }
    }
  }
}

module container_handle() {
  //Calculate honeycomb pattern so I can align the stem of the handle in a way that looks natural. I'm pretty sure some of the calculations are redundant, but I cannot improve the code because I forgot how they work an hour after typing them.
  handle_strut_number = fronthex_width < 100 ? 0 : (fronthex_width_struts - 1) / 2 % 2;
  hexpanel_edge_to_strut_offset = hex_or * 2 + honeycomb_strut_hyp / 2 - height_adj_to_width_opp;
  leftcol1_rightcol2 = honeycomb_unit_space_adj * (handle_strut_number - 1) + hexpanel_edge_to_strut_offset;
  leftcol2_rightcol1 = honeycomb_unit_space_adj * ( -handle_strut_number + fronthex_width_struts - 2) + hexpanel_edge_to_strut_offset;
  left_strut_offset = handle_strut_number % 2 == 0 ? leftcol1_rightcol2 : leftcol2_rightcol1;
  right_strut_offset = handle_strut_number % 2 == 0 ? leftcol2_rightcol1 : leftcol1_rightcol2;

  handle_strut_slant_width = ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer);

  fill_handle_width_inset = handle_strut_number * honeycomb_unit_space_adj;
  turtle_start_offset = 0.2;
  pull_handle_transition_depth = handle_depth - handle_thickness - handle_thickness / 2 - turtle_start_offset;

  left_transition_offset = fronthex_width / 2 - left_strut_offset;
  right_transition_offset = fronthex_width / 2 - right_strut_offset;

  left_transition_target_x = ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer) / 2 - (handle_thickness - honeycomb_strut_hyp);
  right_transition_target_x = fronthex_width - (right_strut_offset + honeycomb_strut_hyp) - (left_strut_offset + left_transition_target_x) - (handle_thickness - honeycomb_strut_hyp);

  left_turtle_offset = fronthex_width / 2 - left_strut_offset - handle_thickness / 2 - left_transition_target_x;
  right_turtle_offset = fronthex_width / 2 - right_strut_offset - handle_thickness / 2 - right_transition_target_x;

  turtle_handle_width =
    handle_strut_number % 2 == 0 ? fronthex_width / 2 - left_strut_offset - left_transition_target_x - handle_thickness - handle_thickness / 2
    : fronthex_width / 2 - right_strut_offset - right_transition_target_x - handle_thickness - handle_thickness / 2;

  handle_sweep_turtle_path_left = ["move", turtle_start_offset, "arcleft", handle_thickness, 90, "move", turtle_handle_width];
  handle_sweep_turtle_path_right = ["move", turtle_start_offset, "arcright", handle_thickness, 90, "move", turtle_handle_width];

  up(pull_handle_transition_depth - eps) fwd(container_height / 2 - fronthex_bottom_strut_height / 2) left(handle_strut_number % 2 == 0 ? left_turtle_offset : -left_turtle_offset)
        attach(TOP, "start-centroid")
          path_sweep(rect([handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_left));
  up(pull_handle_transition_depth - eps) fwd(container_height / 2 - fronthex_bottom_strut_height / 2) left(handle_strut_number % 2 == 0 ? right_turtle_offset : -right_turtle_offset)
        attach(TOP, "start-centroid")
          path_sweep(rect([handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_right));
  //middle truss
  if (turtle_handle_width > 50) {
    up((container_depth) / 2 - eps) fwd(container_height / 2) {
        left(handle_strut_number % 2 == 0 ? left_transition_offset : -left_transition_offset) {
          if ( (fronthex_width_struts - 1) / 2 % 2 == 0)
            right((fronthex_width_struts - handle_strut_number * 2 - 1) / 2 * honeycomb_unit_space_adj)
              handle_transition(trans_offset=(left_transition_target_x + right_transition_target_x) / 2, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness, add_front=handle_thickness - handle_chamfer);
          else
            right((fronthex_width_struts - handle_strut_number * 2 - 1) / 2 * honeycomb_unit_space_adj)
              xflip() handle_transition(trans_offset=(left_transition_target_x + right_transition_target_x) / 2, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness, add_front=handle_thickness - handle_chamfer);
        }
      }
  }
  up((container_depth) / 2 - eps) fwd(container_height / 2)
      left(handle_strut_number % 2 == 0 ? left_transition_offset : -left_transition_offset) {
        if (handle_strut_number % 2 == 0)
          handle_transition(trans_offset=left_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
        else
          xflip() handle_transition(trans_offset=left_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
      }
  up((container_depth) / 2 - eps) fwd(container_height / 2)
      left(handle_strut_number % 2 == 0 ? right_transition_offset : -right_transition_offset) {
        if (handle_strut_number % 2 == 0)
          handle_transition(trans_offset=right_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
        else
          xflip() handle_transition(trans_offset=right_transition_target_x, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness);
      }
  function handle_profile_func(first_ang, second_ang = 30, thickness = honeycomb_strut_hyp) =
    [
      [ang_adj_to_opp(first_ang, handle_chamfer), handle_chamfer],
      [ang_adj_to_opp(first_ang, fronthex_bottom_strut_height - handle_chamfer), fronthex_bottom_strut_height - handle_chamfer],
      [ang_adj_to_opp(first_ang, fronthex_bottom_strut_height - handle_chamfer) + handle_chamfer, fronthex_bottom_strut_height],
      [thickness + ang_adj_to_opp(first_ang, fronthex_bottom_strut_height) - handle_chamfer - ang_adj_to_opp(first_ang, handle_chamfer), fronthex_bottom_strut_height],
      [thickness + ang_adj_to_opp(first_ang, fronthex_bottom_strut_height - handle_chamfer), fronthex_bottom_strut_height - handle_chamfer],
      [thickness + ang_adj_to_opp(first_ang, handle_chamfer) + ang_adj_to_opp(30 - second_ang, fronthex_bottom_strut_height - handle_chamfer * 2), handle_chamfer],
      [thickness + ang_adj_to_opp(first_ang, handle_chamfer) + ang_adj_to_opp(30 - second_ang, fronthex_bottom_strut_height - handle_chamfer * 2) - ang_adj_to_opp(45, handle_chamfer), 0],
      [ang_adj_to_opp(first_ang, handle_chamfer) + handle_chamfer, 0],
    ];
  module handle_transition(steps = 90, trans_offset = "Left", starting_thickness = honeycomb_strut_hyp, target_thickness = honeycomb_strut_hyp, starting_angle = 30, wide_bottom = true, add_front = 0) {
    ang_unit = starting_angle / steps;
    up_unit = pull_handle_transition_depth / steps;
    thickness_unit = (target_thickness - starting_thickness) / steps;
    target_x =
      trans_offset == "Left" ? ang_adj_to_opp(starting_angle, fronthex_bottom_strut_height - handle_chamfer)
      : trans_offset == "Middle" ? ang_adj_to_opp(starting_angle, fronthex_bottom_strut_height - handle_chamfer) / 2 - (target_thickness - starting_thickness)
      : trans_offset == "Right" ? 0
      : trans_offset;
    x_unit = target_x / steps;
    render() {
      if (wide_bottom) {
        down(container_front_wall_thickness - eps) linear_extrude(container_front_wall_thickness) polygon(handle_profile_func(first_ang=starting_angle, second_ang=0, thickness=starting_thickness));
      }
      for (i = [1:1:steps]) {
        handle_profile1 = handle_profile_func(first_ang=starting_angle - ang_unit * (i - 1), second_ang=wide_bottom ? ang_unit * (i - 1) : starting_angle, thickness=starting_thickness + thickness_unit * (i - 1));
        handle_profile2 = handle_profile_func(first_ang=starting_angle - ang_unit * (i), second_ang=wide_bottom ? ang_unit * (i) : starting_angle, thickness=starting_thickness + thickness_unit * (i));
        hull() {
          right(x_unit * (i - 1)) up(up_unit * (i - 1)) linear_extrude(eps) polygon(handle_profile1);
          right(x_unit * i) up(up_unit * i) linear_extrude(eps) polygon(handle_profile2);
        }
      }
      if (add_front > 0) {
        right(x_unit * steps) up(up_unit * steps) linear_extrude(add_front) polygon(handle_profile_func(first_ang=starting_angle - ang_unit * steps, second_ang=wide_bottom ? ang_unit * steps : starting_angle, thickness=starting_thickness + thickness_unit * steps));
      }
    }
  }
}
module container_label_holder() {
  frontplate_width = honeycomb_unit_space_adj * 4;
  frontplate_offset_mode = (fronthex_width_struts - 1) / 2 % 2 == fronthex_height_struts % 1 * 2;
  label_side_clearance = 0.2;
  label_depth_clearance = 0.3;
  label_holder_wall_thickness = 0.84;
  label_holder_width = label_width + label_holder_wall_thickness * 2 + label_side_clearance * 2;
  label_holder_depth = label_depth + label_depth_clearance + label_holder_wall_thickness;
  label_holder_height = label_height + label_holder_depth + label_side_clearance;
  if (container_front_wall_type == "Honeycomb") {
    left(honeycomb_unit_space_adj / 2 - ang_hyp_to_adj(30, honeycomb_strut_adj) / 2) {
      right(frontplate_offset_mode ? hex_or : hex_or / 2)
        attach(TOP, FRONT, align=FRONT, inset=fronthex_height_offset + (fronthex_height_struts - 0.5) * honeycomb_unit_space_hyp, inside=true)
          tag("keep") prismoid(size1=[frontplate_width, container_front_wall_thickness], xang=frontplate_offset_mode ? [120, 60] : [60, 120], yang=[90, 90], h=honeycomb_unit_space_hyp / 2 + fronthex_height_offset);
      right(frontplate_offset_mode ? hex_or / 2 : hex_or)
        attach(TOP, FRONT, align=FRONT, inset=fronthex_height_offset + (fronthex_height_struts - 1) * honeycomb_unit_space_hyp, inside=true)
          tag("keep") prismoid(size1=[frontplate_width, container_front_wall_thickness], xang=frontplate_offset_mode ? [60, 120] : [120, 60], yang=[90, 90], h=honeycomb_unit_space_hyp / 2);
    }
    attach(TOP, TOP, align=BACK, inset=honeycomb_strut_adj / 2, inside=true)
      tag("keep") cuboid([label_holder_width, label_holder_height, container_front_wall_thickness]);
  }
  tag_diff(tag="keep", remove="label_remove") {
    attach(TOP, BOTTOM, align=BACK, inset=honeycomb_strut_adj / 2)
      tag("") prismoid(size1=[label_holder_width, label_holder_height], xang=[90, 90], yang=[45, 90], h=label_holder_depth, rounding=[0, 0, 0.8, 0.8], $fn=64) {
          edge_mask([TOP + LEFT, TOP + RIGHT])
            tag("label_remove") rounding_edge_mask(r=0.4, l=$edge_length + 5);
          back(eps) attach(BACK, BACK, align=BOTTOM, inside=true)
              tag("label_remove") cuboid([label_holder_width - label_holder_wall_thickness * 2, label_height + label_side_clearance, label_holder_depth - label_holder_wall_thickness]);
          attach(BACK, BACK, align=TOP, inside=true, shiftout=eps)
            tag("label_remove") cuboid([label_holder_width - label_holder_wall_thickness * 2 - label_holder_wall_thickness * 4, label_height + label_side_clearance, label_holder_depth - label_holder_wall_thickness]);
        }
  }
}

module drawer_stopper() {
  stopper_leg_thickness = 1.68;
  stopper_leg_outer_round = stopper_clips_length - stopper_rounding < 0.6 ? 0 : stopper_rounding;
  stopper_leg_inner_round = min(stopper_rounding, stopper_clips_length / 2);
  stopper_leg_nub_length = min(3, stopper_clips_length - stopper_leg_outer_round);
  stopper_leg_nub_width = min(0.6, stopper_leg_nub_length);

  stopper_width_clearance = 0.1;
  stopper_height_clearance = 0.15;
  stopper_clips_length_clearance = 0.1;
  xrot(-90) diff()
      cuboid([stopper_width + stopper_flank_width - stopper_width_clearance * 2, stopper_height - stopper_height_clearance * 2, stopper_flank_depth - stopper_clips_length_clearance], anchor=TOP + BACK) {
        attach(BOTTOM, TOP)
          cuboid([stopper_width - stopper_width_clearance * 2, stopper_height - stopper_height_clearance * 2, shell_thickness - stopper_flank_depth], rounding=-stopper_rounding, edges=[TOP + LEFT, TOP + RIGHT], $fn=64) {
            *edge_mask([BOTTOM + LEFT, BOTTOM + RIGHT])
              rounding_edge_mask(r=stopper_rounding);
            if (stopper_clips_length > eps)
              attach(BOTTOM, TOP)
                cuboid([stopper_width - stopper_width_clearance * 2, stopper_height - stopper_height_clearance * 2, stopper_clips_length], rounding=stopper_leg_outer_round, edges=[BOTTOM + LEFT, BOTTOM + RIGHT], $fn=64) {
                  attach(BOTTOM, BOTTOM, inside=true)
                    cuboid([stopper_width - stopper_leg_thickness * 2 - stopper_width_clearance * 2, stopper_height - stopper_height_clearance * 2 + eps, stopper_clips_length], rounding=stopper_leg_inner_round, edges=[TOP + LEFT, TOP + RIGHT], $fn=64) {
                      edge_mask([BOTTOM + LEFT, BOTTOM + RIGHT])
                        rounding_edge_mask(r=stopper_leg_inner_round, spin=90);
                    }
                  attach(RIGHT, BOTTOM, align=TOP)
                    prismoid(size1=[stopper_height - stopper_height_clearance * 2, stopper_leg_nub_length], size2=[stopper_height - stopper_height_clearance * 2, 0], shift=[0, stopper_leg_nub_length / 2], h=stopper_leg_nub_width);
                  attach(LEFT, BOTTOM, align=TOP)
                    prismoid(size1=[stopper_height - stopper_height_clearance * 2, stopper_leg_nub_length], size2=[stopper_height - stopper_height_clearance * 2, 0], shift=[0, stopper_leg_nub_length / 2], h=stopper_leg_nub_width);
                }
          }
      }
}
