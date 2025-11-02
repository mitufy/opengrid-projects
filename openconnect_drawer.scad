include <BOSL2/std.scad>
include <BOSL2/walls.scad>
include <BOSL2/rounding.scad>
include <BOSL2/threading.scad>

generate_shell = true;
generate_container = true;
generate_stoppers = true;
flip_slot_direction = false;

/* [View Options] */
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_drawer_overlapped = false;

/*[Grid Settings]*/
vertical_grids = 2;
horizontal_grids = 5;
//Depth is not restricted by grids, so this is just a convenient way to increment value by 28mm. You can override this with override_depth.
depth_grids = 5;

/*[Honeycomb Settings]*/
honeycomb_strut_hyp = 5.04; //0.42

/*[Shell Settings]*/
shell_thickness = 2.52; //0.42
shell_top_wall_type = "Solid"; //["Solid","Honeycomb"]
shell_bottom_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
shell_side_wall_type = "Solid"; //["Solid","Honeycomb"]

/*[Shell Divider]*/
add_shell_divider = false;
shell_main_divide_unit = "Width"; //["Width","Height"]
shell_width_dividers = "1,4";
shell_height_dividers = "2 3";
shell_divider_wall_type = "Honeycomb"; //["Solid","Honeycomb"]

/*[Container Settings]*/
container_solidwall_thickness = 1.68; //0.42
container_honeycombwall_thickness = 2.52; //0.42
container_height_clearance = 0.4; //0.05
container_width_clearance = 0.4; //0.05
container_depth_clearance = 0.2; //0.05

container_front_wall_type = "Honeycomb"; //["Solid","Honeycomb"]
container_back_wall_type = "Solid"; //["Solid","Honeycomb"]
container_bottom_wall_type = "Solid"; //["Solid","Honeycomb"]
//Because of print direction, Honeycomb pattern on the side of the shell and container are not aligned. Enabling honeycomb on the side walls of both part can make the drawer look a bit inconsistent.  
container_side_wall_type = "Solid"; //["Solid","Honeycomb"]

/*[Container Divider]*/
add_container_divider = false;
container_divider_wall_height_diff = 6;
container_divider_wall_thickness = 1.68; //0.42
container_divide_direction = "Width"; //["Width","Depth"]
container_divider_list = "2,1";

/*[Handle Settings]*/
handle_thickness = 2.52; //0.42
handle_depth = 10;
handle_chamfer = 0.4;
add_label_holder = true;

/*[Magnet Settings]*/
add_back_magnet_holes = true;
back_magnet_thickness = 2;
back_magnet_diameter = 6;
back_magnet_hole_position = "Bottom Corners"; //["All","Corners","Bottom Corners"]

add_side_magnet_holes = true;
side_magnet_thickness = 1;
side_magnet_diameter = 6;
side_magnet_back_offset = 2.52;
side_magnet_front_offset = 2.52;

magnet_hole_clearance = 0.1;

back_magnet_hole_thickness = back_magnet_thickness + magnet_hole_clearance;
back_magnet_hole_diameter = back_magnet_diameter + magnet_hole_clearance * 2;
side_magnet_hole_thickness = side_magnet_thickness + magnet_hole_clearance;
side_magnet_hole_diameter = side_magnet_diameter + +magnet_hole_clearance * 2;

/*[Stopper Settings]*/
add_stopper_holes = true;

/*[Advanced Settings]*/

/*[Hidden]*/
$fa = 1;
$fs = 0.4;
eps = 0.005;

stopper_angles = [60, 60];
stopper_width = 10;
stopper_height = 3;
stopper_depth = 8;
stopper_height_clearance = 0.1;
stopper_width_clearance = 0.0;
stopper_chamfer = 0.6;

threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

// /*[Connector Parameters]*/
head_bottom_height = 0.6;
head_bottom_chamfer = 0.2;
head_top_height = 0.4;
head_middle_height = 1.6;
head_large_rect_width = 17; //0.1
head_large_rect_height = 17; //0.1

nub_depth = 0.6;
nub_tip_height = 1; //0.1
nub_inner_fillet = 0.2;
nub_outer_fillet = 0.8;

head_large_rect_chamfer = 4; //0.1
head_small_rect_width = head_large_rect_width - head_middle_height * 2;
head_small_rect_height = head_large_rect_height - head_middle_height * 2;
head_small_rect_chamfer = head_large_rect_chamfer - head_middle_height + ang_adj_to_opp(45 / 2, head_middle_height);

// /*[Slot Parameters]*/
slot_ramp_clearance = 2;
slot_move_distance = 9.4; //0.1
slot_side_clearance = 0.15;
slot_depth_clearance = 0.12;

head_bottom_profile = rect([head_large_rect_width, head_large_rect_height], chamfer=head_large_rect_chamfer);
head_top_profile = offset(head_bottom_profile, delta=-head_middle_height);
head_total_height = head_top_height + head_middle_height + head_bottom_height;

slot_top_profile = offset(head_top_profile, delta=slot_side_clearance);
slot_bottom_profile = offset(head_bottom_profile, delta=slot_side_clearance);

slot_bottom_height = head_bottom_height + ang_adj_to_opp(45 / 2, slot_side_clearance);
slot_middle_height = head_middle_height;
slot_top_height = head_top_height - ang_adj_to_opp(45 / 2, slot_side_clearance) + slot_depth_clearance;
slot_total_height = slot_top_height + slot_middle_height + slot_bottom_height;

slot_small_rect_width = head_small_rect_width + slot_side_clearance * 2;
slot_small_rect_height = head_small_rect_height + slot_side_clearance * 2;
slot_small_rect_chamfer = head_small_rect_chamfer + slot_side_clearance - ang_adj_to_opp(45 / 2, slot_side_clearance);
slot_large_rect_width = head_large_rect_width + slot_side_clearance * 2;
slot_large_rect_height = head_large_rect_height + slot_side_clearance * 2;
slot_large_rect_chamfer = head_large_rect_chamfer + slot_side_clearance - ang_adj_to_opp(45 / 2, slot_side_clearance);

head_side_profile = [
  [0, 0],
  [head_large_rect_width / 2 - head_bottom_chamfer, 0],
  [head_large_rect_width / 2, head_bottom_chamfer],
  [head_large_rect_width / 2, head_bottom_height],
  [head_small_rect_width / 2, head_bottom_height + head_middle_height],
  [head_small_rect_width / 2, head_bottom_height + head_middle_height + head_top_height],
  [0, head_bottom_height + head_middle_height + head_top_height],
];

slot_side_profile = [
  [0, 0],
  [slot_large_rect_width / 2, 0],
  [slot_large_rect_width / 2, slot_bottom_height],
  [slot_small_rect_width / 2, slot_bottom_height + slot_middle_height],
  [slot_small_rect_width / 2, slot_bottom_height + slot_middle_height + slot_top_height],
  [0, slot_bottom_height + slot_middle_height + slot_top_height],
];

tile_size = 28;
//make the center of drawer lower to reduce vertical space needed for installing slot
tile_edge_offset = 1.2;

honeycomb_unit_space_adj = 14;
honeycomb_unit_space_hyp = ang_adj_to_hyp(30, honeycomb_unit_space_adj);
honeycomb_strut_adj = ang_hyp_to_adj(30, honeycomb_strut_hyp);

//back magnet parameters
back_magnet_slot_offset = 3;
back_magnet_grid_space =
  back_magnet_hole_position == "Corners" ? [tile_size * (horizontal_grids - 2), tile_size * (vertical_grids - 1)]
  : back_magnet_hole_position == "Bottom Corners" ? [tile_size * (horizontal_grids - 2), tile_size * (vertical_grids - 1)]
  : [tile_size, tile_size];
back_back_magnet_grid_count =
  back_magnet_hole_position == "Corners" ? [min(horizontal_grids - 1, 2), min(vertical_grids, 2)]
  : back_magnet_hole_position == "Bottom Corners" ? [min(horizontal_grids - 1, 2), 1]
  : [horizontal_grids - 1, vertical_grids];

shell_to_slot_wall_thickness = 0.8;
shell_slot_part_thickness = slot_total_height + shell_to_slot_wall_thickness;

function calc_inner_chamfer(outer_chamfer, wall_thickness) = (outer_chamfer / sqrt(2) + wall_thickness - wall_thickness * sqrt(2)) * sqrt(2);

shell_chamfer = 2.4; //0.2
shell_inner_chamfer = 1.2;
container_outer_chamfer = 1.2;
container_inner_chamfer = 0.6;

half_of_anchor =
  view_cross_section == "Right" ? RIGHT
  : view_cross_section == "Back" ? BACK
  : view_cross_section == "Diagonal" ? RIGHT + BACK
  : 0;

if (half_of_anchor != 0) {
  half_of(half_of_anchor, s=300) {
    if (generate_shell)
      down(shell_slot_part_thickness)
        drawer_shell();
    if (generate_container)
      left(view_drawer_overlapped ? 0 : horizontal_grids * tile_size)
        up(container_depth_clearance) drawer_container();
  }
} else {
  if (generate_shell)
    down(shell_slot_part_thickness)
      drawer_shell();
  if (generate_container)
    left(view_drawer_overlapped ? 0 : horizontal_grids * tile_size)
      up(container_depth_clearance) drawer_container();
  if (generate_stoppers)
    right(horizontal_grids * tile_size) stoppers();
}
module stoppers() {
  stopper_bottom_height = 0.84;
  stopper_increment_line = 0.42;
  stopper_increment_layer = 0.2;
  stopper_increment_count = 4;
  st_height_diff = 0;
  st_width_diff = (shell_thickness - stopper_bottom_height) / 2;
  left(-30)
    difference() {
      cuboid([stopper_width + 4, shell_thickness, stopper_height + 5], anchor=BOTTOM + BACK);
      #up(2.4) xrot(90) {
          linear_extrude(stopper_bottom_height) trapezoid(h=stopper_height, w1=stopper_width, ang=60, anchor=FRONT);
          up(stopper_bottom_height) hull() {
              linear_extrude(eps) trapezoid(h=stopper_height, w1=stopper_width, ang=60, anchor=FRONT);
              up(shell_thickness - stopper_bottom_height)
                linear_extrude(eps) trapezoid(h=stopper_height - st_height_diff, w1=stopper_width - st_width_diff, ang=60, anchor=FRONT);
            }
        }
    }
  left(-10) xrot(90) {
      linear_extrude(stopper_bottom_height) trapezoid(h=stopper_height - stopper_height_clearance * 2, w1=stopper_width - stopper_width_clearance * 2, ang=60, anchor=FRONT);
      up(stopper_bottom_height) hull() {
          linear_extrude(eps) trapezoid(h=stopper_height - stopper_height_clearance * 2, w1=stopper_width - stopper_width_clearance * 2, ang=60, anchor=FRONT);
          up(shell_thickness - stopper_bottom_height)
            linear_extrude(eps) trapezoid(h=stopper_height - stopper_height_clearance * 2 - st_height_diff, w1=stopper_width - stopper_width_clearance * 2 - st_width_diff, ang=60, anchor=FRONT);
        }
      up(shell_thickness) linear_extrude(stopper_depth) trapezoid(h=stopper_height - stopper_height_clearance * 2 - st_height_diff, w1=stopper_width - stopper_width_clearance * 2 - st_width_diff, ang=60, anchor=FRONT);
    }
  // left(-30)
  //   difference() {
  //     cuboid([stopper_width + 4, shell_thickness, stopper_height + 5], anchor=BOTTOM + BACK);
  //     #up(2.4) xrot(90) {
  //         linear_extrude(stopper_bottom_height) trapezoid(h=stopper_height, w1=stopper_width, ang=60, anchor=FRONT);
  //         up(stopper_bottom_height) hull() {
  //             linear_extrude(eps) trapezoid(h=stopper_height, w1=stopper_width, ang=60, anchor=FRONT);
  //             up(stopper_increment_line * stopper_increment_count)
  //               linear_extrude(eps) trapezoid(h=stopper_height - stopper_increment_layer * stopper_increment_count, w1=stopper_width - stopper_increment_line * stopper_increment_count, ang=60, anchor=FRONT);
  //           }
  //         up(stopper_bottom_height + stopper_increment_line * stopper_increment_count) hull() {
  //             linear_extrude(eps) trapezoid(h=stopper_height - stopper_increment_layer * stopper_increment_count, w1=stopper_width - stopper_increment_line * stopper_increment_count, ang=60, anchor=FRONT);
  //             up(stopper_depth)
  //               linear_extrude(eps) trapezoid(h=stopper_height - stopper_increment_layer * stopper_increment_count, w1=stopper_width - stopper_increment_line * stopper_increment_count - 1, ang=60, anchor=FRONT);
  //           }
  //       }
  //   }
  // left(-10) xrot(90) {
  //     linear_extrude(stopper_bottom_height) trapezoid(h=stopper_height - stopper_height_clearance * 2, w1=stopper_width - stopper_width_clearance * 2, ang=60, anchor=FRONT);
  //     up(stopper_bottom_height) hull() {
  //         linear_extrude(eps) trapezoid(h=stopper_height - stopper_height_clearance * 2, w1=stopper_width - stopper_width_clearance * 2, ang=60, anchor=FRONT);
  //         up(stopper_increment_line * stopper_increment_count)
  //           linear_extrude(eps) trapezoid(h=stopper_height - stopper_height_clearance * 2 - stopper_increment_layer * stopper_increment_count, w1=stopper_width - stopper_width_clearance * 2 - stopper_increment_line * stopper_increment_count, ang=60, anchor=FRONT);
  //       }
  //     up(stopper_bottom_height + stopper_increment_line * stopper_increment_count) hull() {
  //         linear_extrude(eps) trapezoid(h=stopper_height - stopper_height_clearance * 2 - stopper_increment_layer * stopper_increment_count, w1=stopper_width - stopper_width_clearance * 2 - stopper_increment_line * stopper_increment_count, ang=60, anchor=FRONT);
  //         up(stopper_depth)
  //           linear_extrude(eps) trapezoid(h=stopper_height - stopper_height_clearance * 2 - stopper_increment_layer * stopper_increment_count, w1=stopper_width - stopper_width_clearance * 2 - stopper_increment_line * stopper_increment_count - 1, ang=60, anchor=FRONT);
  //       }
  //   }

  // left(10) diff() prismoid(size1=[stopper_width - stopper_width_clearance * 2, shell_thickness - 0.84 - stopper_depth_clearance], xang=stopper_angles, yang=[90, 90], h=stopper_height - stopper_height_clearance * 2) {
  //       edge_profile([FRONT], except=BOTTOM)
  //         mask2d_chamfer(h=stopper_chamfer);
  //       attach(FRONT, BACK, align=BOTTOM)
  //         prismoid(size1=[stopper_width - stopper_width_clearance * 2 - stopper_chamfer * 3, stopper_depth], xang=stopper_angles, yang=[90, 90], h=stopper_height - stopper_height_clearance * 2 - stopper_chamfer)
  //           attach(FRONT + BOTTOM, FRONT + BOTTOM, inside=true)
  //             cuboid([stopper_width - stopper_width_clearance * 2 - stopper_chamfer * 3 - 6.3, stopper_depth - 1.26, stopper_height]);
  //     }
  // left(30) diff()
  //     cuboid([stopper_width + 4, shell_thickness, stopper_height + 4], anchor=BOTTOM)
  //       tag_diff(tag="remove", remove="inner_remove", keep="inner_keep") {
  //         attach(BACK, BACK, inside=true)
  //           prismoid(size1=[stopper_width, shell_thickness - 0.84], xang=stopper_angles, yang=[90, 90], h=stopper_height) {
  //             edge_profile([FRONT], except=BOTTOM)
  //               tag("inner_remove") mask2d_chamfer(h=stopper_chamfer);
  //             attach(FRONT, BACK, align=BOTTOM)
  //               prismoid(size1=[stopper_width - stopper_chamfer * 3, stopper_depth], xang=stopper_angles, yang=[90, 90], h=stopper_height - stopper_chamfer);
  //           }
  //       }
}
module drawer_container(h_grids = horizontal_grids, v_grids = vertical_grids) {

  _shell_depth = depth_grids * tile_size;
  _shell_width = h_grids * tile_size;
  _shell_height = v_grids * tile_size;

  container_width = _shell_width - container_width_clearance * 2 - shell_thickness * 2;
  container_height = _shell_height - container_height_clearance * 2 - shell_thickness * 2;
  container_depth = _shell_depth - container_depth_clearance - shell_slot_part_thickness;

  container_front_wall_thickness = container_front_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
  container_bottom_wall_thickness = container_bottom_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
  container_side_wall_thickness = container_side_wall_type == "Solid" ? container_solidwall_thickness : container_honeycombwall_thickness;
  container_back_wall_thickness =
    container_back_wall_type == "Honeycomb" ? container_honeycombwall_thickness
    : container_solidwall_thickness;

  //hexwall parameters
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
  container_back_height_diff = 2.1;

  intersect(intersect="mask", keep="kp_root") {
    diff(remove="rm_outer", keep="mask kp_root") diff(remove="remove", keep="keep mask rm_outer kp_root") cuboid([container_width, container_height, container_depth], anchor=BOTTOM) {
          attach(BACK, BACK, align=BOTTOM, inset=container_back_wall_thickness, inside=true)
            tag("remove") cuboid([container_width - container_side_wall_thickness * 2, container_height - container_bottom_wall_thickness, container_depth - container_back_wall_thickness - container_front_wall_thickness], edges=[FRONT + LEFT, FRONT + RIGHT], chamfer=container_inner_chamfer);
          //front top edge rounding
          // attach(TOP, TOP, align=BACK, inset=-1, inside=true)
          //   tag("gap_remove") offset_sweep(rect([container_width, 1]), height=container_front_wall_thickness, top=os_circle(r=-0.4), bottom=os_circle(r=-0.4));

          //front_wall
          if (container_front_wall_type == "Honeycomb")
            attach(FRONT, LEFT, align=TOP, inside=true)
              tag("keep") hex_panel([container_height, container_width, container_front_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_front_wall_thickness);
          attach(TOP, TOP, align=FRONT, inset=container_bottom_wall_thickness, inside=true)
            tag(container_front_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2, container_height - container_bottom_wall_thickness, container_front_wall_thickness + eps], edges="Z", chamfer=container_inner_chamfer);
          //backwall
          if (container_back_wall_type == "Honeycomb")
            attach(FRONT, LEFT, align=BOTTOM, inside=true)
              tag("keep") hex_panel([container_height, container_width, container_back_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_back_wall_thickness);
          attach(BOTTOM, BOTTOM, align=FRONT, inset=container_bottom_wall_thickness, inside=true)
            tag(container_back_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2, container_back_wall_type == "Honeycomb" ? container_height - container_back_height_diff - container_bottom_wall_thickness * 2 : container_height - container_back_height_diff, container_back_wall_thickness + eps], edges="Z", chamfer=container_inner_chamfer);

          // side walls
          if (container_side_wall_type == "Honeycomb") {
            attach(FRONT, LEFT, align=RIGHT, inside=true, spin=90)
              tag("keep") hex_panel([container_height, container_depth, container_side_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_side_wall_thickness);
            attach(FRONT, LEFT, align=LEFT, inside=true, spin=90)
              tag("keep") hex_panel([container_height, container_depth, container_side_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_side_wall_thickness);
          }
          attach(LEFT, LEFT, align=FRONT, inset=container_bottom_wall_thickness + container_inner_chamfer, inside=true)
            tag(container_side_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([container_side_wall_thickness + eps, container_side_wall_type == "Honeycomb" ? container_height - container_back_height_diff - container_bottom_wall_thickness * 2 - container_inner_chamfer * 2 - container_side_wall_thickness : container_height - container_back_height_diff, container_depth - container_front_wall_thickness - container_back_wall_thickness]);
          attach(RIGHT, RIGHT, align=FRONT, inset=container_bottom_wall_thickness + container_inner_chamfer, inside=true)
            tag(container_side_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([container_side_wall_thickness + eps, container_side_wall_type == "Honeycomb" ? container_height - container_back_height_diff - container_bottom_wall_thickness * 2 - container_inner_chamfer * 2 - container_side_wall_thickness : container_height - container_back_height_diff, container_depth - container_front_wall_thickness - container_back_wall_thickness]);

          //bottom wall
          if (container_bottom_wall_type == "Honeycomb")
            attach(TOP, LEFT, align=FRONT, inside=true)
              tag("keep") hex_panel([container_depth, container_width, container_bottom_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_bottom_wall_thickness);
          attach(FRONT, FRONT, align=BOTTOM, inset=container_back_wall_thickness, inside=true)
            tag(container_bottom_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([container_width - container_side_wall_thickness * 2 - container_inner_chamfer * 2, container_bottom_wall_thickness + eps, container_depth - container_front_wall_thickness - container_back_wall_thickness]);

          
          tag("mask") {
            attach(FRONT, FRONT, align=TOP, inset=-handle_depth, inside=true)
              cuboid([container_width, container_height, container_front_wall_thickness + handle_depth], edges="Z", chamfer=container_outer_chamfer);
            attach(FRONT, FRONT, align=TOP, inset=container_front_wall_thickness, inside=true)
              cuboid([container_width, container_height - container_back_height_diff - container_outer_chamfer, container_depth - container_front_wall_thickness - container_back_wall_thickness], edges=[FRONT + LEFT, FRONT + RIGHT], chamfer=container_outer_chamfer);
            attach(BOTTOM, BOTTOM, align=FRONT, inside=true)
              cuboid([container_width, container_height - container_back_height_diff, container_back_wall_thickness], edges=["Z"], chamfer=container_outer_chamfer);
          }
          container_handle();
          if (add_label_holder)
            container_label_holder();
          if (add_container_divider)
            container_divider();
          if (add_side_magnet_holes)
            xflip_copy() {
              hole_extrude_thickness = side_magnet_hole_thickness - container_side_wall_thickness + 0.42 + eps;
              if (container_side_wall_type == "Honeycomb")
                attach(LEFT + FRONT, LEFT + FRONT, align=BOTTOM, inside=true) //depth is magic number 12 because I don't want to calculate hexagon anymore
                  tag("keep") cuboid([container_side_wall_thickness, container_height - container_back_height_diff - container_outer_chamfer, 12.1]);
              ycopies(tile_size, vertical_grids) {
                attach(LEFT, FRONT, align=BOTTOM, inset=side_magnet_back_offset, inside=true, spin=90)
                  tag("rm_outer") teardrop(h=side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                if (hole_extrude_thickness > eps)
                  right(container_side_wall_thickness) attach(LEFT, FRONT, align=BOTTOM, inset=side_magnet_back_offset - (side_magnet_hole_diameter + 0.2) / 2, inside=true, spin=90)
                      tag("kp_root") teardrop(h=hole_extrude_thickness, d=side_magnet_hole_diameter + 0.2, cap_h=side_magnet_hole_diameter / 2 + 0.2, chamfer1=-hole_extrude_thickness);
              }
            }
          if (add_back_magnet_holes) {
            hole_extrude_thickness = side_magnet_hole_thickness - container_back_wall_thickness + 0.42 + eps;
            if (container_back_wall_type == "Honeycomb")
              line_copies(back_magnet_grid_space[0], back_back_magnet_grid_count[0])
                attach(BOTTOM + FRONT, BOTTOM + FRONT, inside=true)
                  tag("keep") cuboid([side_magnet_hole_diameter + 4.2, container_height - container_back_height_diff, container_back_wall_thickness]);
            back(tile_edge_offset) back(back_magnet_slot_offset) fwd(back_magnet_hole_position == "Bottom Corners" ? (vertical_grids - 1) / 2 * tile_size : 0)
                  grid_copies(back_magnet_grid_space, back_back_magnet_grid_count) {
                    attach(BOTTOM, FRONT, inside=true)
                      tag("rm_outer") teardrop(h=side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                    if (hole_extrude_thickness > eps)
                      up(container_back_wall_thickness) attach(BOTTOM, FRONT, inside=true)
                          tag("kp_root") teardrop(h=hole_extrude_thickness, d=side_magnet_hole_diameter + 0.2, cap_h=side_magnet_hole_diameter / 2 + 0.2, chamfer1=-hole_extrude_thickness);
                  }
          }
        }
  }

  module container_divider() {
    mainW = (container_divide_direction == "Width");
    main_divide_strs = str_split(str_strip(str_replace_char(container_divider_list, " ", ","), ","), ",");
    main_divide_nums = [for (i = [0:len(main_divide_strs) - 1]) parse_num(main_divide_strs[i])];
    main_divide_cumnums = cumsum(main_divide_nums);

    mainwall_alignment = mainW ? LEFT : BOTTOM;
    mainsolidwall_anchor = mainW ? TOP : FRONT;

    mainsolidwall_x = mainW ? container_divider_wall_thickness : container_width;
    mainsolidwall_y = container_height - container_back_height_diff - container_divider_wall_height_diff;
    mainsolidwall_z = mainW ? container_depth : container_divider_wall_thickness;

    compartment_size_unit = mainW ? container_width / sum(main_divide_nums) : container_depth / sum(main_divide_nums);

    for (i = [0:len(main_divide_cumnums) - 2]) {
      if (main_divide_cumnums[i] > 0) {
        main_compartment_inset = main_divide_cumnums[i] * compartment_size_unit - main_divide_cumnums[i] * container_divider_wall_thickness / 2;
        fwd((container_height - mainsolidwall_y) / 2)
          #attach(mainsolidwall_anchor, mainsolidwall_anchor, align=mainwall_alignment, inset=main_compartment_inset, inside=true)
            tag("keep") cuboid([mainsolidwall_x, mainsolidwall_y, mainsolidwall_z]);
      }
    }
  }

  module container_handle() {
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
    // if ( (fronthex_width_struts - 1) / 2 % 2 == handle_strut_number % 2 && turtle_handle_width > 50) {
    //   up((container_depth) / 2 - eps) fwd(container_height / 2) {
    //       left(fronthex_width / 2 + honeycomb_unit_space_adj - hexpanel_edge_to_strut_offset) {
    //         if ( (fronthex_width_struts - 1) / 2 % 2 == 0)
    //           left(-(fronthex_width_struts - 1) / 2 * honeycomb_unit_space_adj)
    //             handle_transition(trans_offset=(left_transition_target_x + right_transition_target_x) / 2, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness, add_front=handle_thickness - handle_chamfer);
    //         else
    //           left(-(fronthex_width_struts + 1) / 2 * honeycomb_unit_space_adj)
    //             xflip() handle_transition(trans_offset=(left_transition_target_x + right_transition_target_x) / 2, starting_thickness=honeycomb_strut_hyp, target_thickness=handle_thickness, add_front=handle_thickness - handle_chamfer);
    //       }
    //     }
    // }
    // right(100) debug_polygon(points=handle_profile_func(first_ang=30, second_ang=0, thickness=honeycomb_strut_hyp));
    echo(fronthex_width_struts=fronthex_width_struts, fronthex_width=fronthex_width, (fronthex_width_struts - 1) / 2 % 2);

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
    label_depth = 1;
    label_width = 48;
    label_height = 12;
    label_clearance = 0.2;
    label_holder_wall_thickness = 0.84;
    label_holder_width = label_width + label_holder_wall_thickness * 2 + label_clearance * 2;
    label_holder_height = label_height + 0.6 + label_clearance;
    label_holder_depth = 2.1;
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
                tag("label_remove") cuboid([label_holder_width - label_holder_wall_thickness * 2, label_holder_height - label_holder_depth, label_holder_depth - label_holder_wall_thickness]);
            attach(BACK, BACK, align=TOP, inside=true, shiftout=eps)
              tag("label_remove") cuboid([label_holder_width - label_holder_wall_thickness * 2 - label_holder_wall_thickness * 4, label_holder_height - label_holder_depth, label_holder_depth - label_holder_wall_thickness]);
          }
    }
    // echo("label_holder_width old", frontplate_width - honeycomb_strut_hyp * 2, "label_holder_height old", honeycomb_unit_space_hyp - fronthex_height_offset);
  }
}

module drawer_shell() {
  //calculated parameters
  shell_depth = depth_grids * tile_size;
  shell_width = horizontal_grids * tile_size;
  shell_height = vertical_grids * tile_size;
  difference() {
    intersection() {
      diff(remove="rm_outer", keep="") diff(keep="keep rm_outer") {
          cuboid([shell_width, shell_height, shell_depth], anchor=BOTTOM) {
            attach(TOP, TOP, inside=true)
              tag("remove") cuboid([shell_width - shell_thickness * 2, shell_height - shell_thickness * 2, shell_depth - shell_slot_part_thickness], edges="Z", chamfer=shell_inner_chamfer);
            if (shell_side_wall_type == "Honeycomb") {
              attach(TOP, RIGHT, align=LEFT, inside=true, spin=90)
                tag("keep") hex_panel([shell_depth - shell_slot_part_thickness + shell_thickness, shell_height - shell_inner_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
              attach(TOP, RIGHT, align=RIGHT, inside=true, spin=90)
                tag("keep") hex_panel([shell_depth - shell_slot_part_thickness + shell_thickness, shell_height - shell_inner_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            }
            attach(TOP, TOP, align=LEFT, inside=true)
              tag(shell_side_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([shell_thickness + eps, shell_height - shell_thickness * 2 - shell_inner_chamfer * 2, shell_depth - shell_slot_part_thickness]);
            attach(TOP, TOP, align=RIGHT, inside=true)
              tag(shell_side_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([shell_thickness + eps, shell_height - shell_thickness * 2 - shell_inner_chamfer * 2, shell_depth - shell_slot_part_thickness]);
            if (shell_top_wall_type == "Honeycomb")
              attach(TOP, RIGHT, align=BACK, inside=true)
                tag("keep") hex_panel([shell_depth - shell_slot_part_thickness + shell_thickness, shell_width - shell_inner_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, TOP, align=BACK, inside=true)
              tag(shell_top_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([shell_width - shell_thickness * 2 - shell_inner_chamfer * 2, shell_thickness + eps, shell_depth - shell_slot_part_thickness]);
            if (shell_bottom_wall_type == "Honeycomb")
              attach(TOP, RIGHT, align=FRONT, inside=true)
                tag("keep") hex_panel([shell_depth - shell_slot_part_thickness + shell_thickness, shell_width - shell_inner_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, TOP, align=FRONT, inside=true)
              tag(shell_bottom_wall_type == "Honeycomb" ? "remove" : "keep") cuboid([shell_width - shell_thickness * 2 - shell_inner_chamfer * 2, shell_thickness + eps, shell_depth - shell_slot_part_thickness]);
            if (add_side_magnet_holes)
              xflip_copy() {
                if (shell_side_wall_type == "Honeycomb")
                  attach(LEFT + FRONT, LEFT + FRONT, align=TOP, inside=true)
                    tag("keep") cuboid([shell_thickness, shell_height, 10.8]);
                ycopies(tile_size, vertical_grids) {
                  right(shell_thickness - side_magnet_hole_thickness + eps * 2) attach(LEFT, FRONT, align=TOP, inset=side_magnet_front_offset, inside=true)
                      tag("rm_outer") teardrop(h=side_magnet_hole_thickness, d=side_magnet_hole_diameter, cap_h=side_magnet_hole_diameter / 2 + 0.2);
                }
              }
            if (add_shell_divider)
              shell_divider();
            if (add_stopper_holes) {
              line_copies(tile_size * (horizontal_grids - 1), 2)
                tag_diff(tag="rm_outer", remove="inner_remove", keep="inner_keep") {
                  attach(BACK, BACK, align=TOP, inset=shell_thickness, inside=true)
                    prismoid(size1=[stopper_width, shell_thickness - 0.84], xang=stopper_angles, yang=[90, 90], h=stopper_height) {
                      edge_profile([FRONT], except=BOTTOM)
                        tag("inner_remove") mask2d_chamfer(h=stopper_chamfer);
                      attach(FRONT, BACK, align=BOTTOM)
                        prismoid(size1=[stopper_width - stopper_chamfer * 3, stopper_depth], xang=stopper_angles, yang=[90, 90], h=stopper_height - stopper_chamfer);
                    }
                }
              // attach(BACK, BACK, align=TOP, inset=shell_thickness, inside=true)
              //   cuboid([stopper_width + stopper_width_clearance, stopper_depth_diff + stopper_depth_clearance, stopper_height + stopper_height_clearance], edges="Y", chamfer=0)
              //     attach(FRONT, BACK, align=TOP)
              //       cuboid([stopper_width + stopper_width_clearance, shell_thickness - stopper_depth_diff + stopper_depth_clearance + eps, stopper_height - stopper_height_diff + stopper_height_clearance], edges="Y", chamfer=0)
              //         edge_mask([BACK + BOTTOM])
              //           tag("inner_keep") rounding_edge_mask(r=stopper_height_diff, $fn=64, spin=-90);
            }
            back(tile_edge_offset) {
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger=true)
                attach(BOTTOM, BOTTOM, inside=true, shiftout=0.001)
                  tag("rm_outer") openconnect_slot(add_nub=0);
              grid_copies([tile_size, tile_size], [horizontal_grids, vertical_grids], stagger="alt")
                attach(BOTTOM, BOTTOM, inside=true, shiftout=0.001)
                  tag("rm_outer") openconnect_slot(add_nub=1);
              if (add_back_magnet_holes) {
                back(back_magnet_slot_offset) fwd(back_magnet_hole_position == "Bottom Corners" ? (vertical_grids - 1) / 2 * tile_size : 0)
                    grid_copies(back_magnet_grid_space, back_back_magnet_grid_count)
                      attach(BOTTOM, BOTTOM, inside=true)
                        tag("rm_outer") cyl(h=back_magnet_hole_thickness, d=back_magnet_hole_diameter);
              }
            }
          }
        }
      cuboid([shell_width, shell_height, shell_depth], edges="Z", chamfer=shell_chamfer, anchor=BOTTOM);
    }
    // slot_stagger =
    //   slot_rail_type == "Auto" && (vertical_grids > 2 && horizontal_grids % 2 == 0) ? false
    //   : slot_rail_type == "Auto" && vertical_grids % 2 != horizontal_grids % 2 ? "alt"
    //   : slot_rail_type == "Auto" && vertical_grids % 2 == horizontal_grids % 2 ? true : false;
    // slot_copy_spacing =
    //   slot_rail_type == "All" || slot_stagger != false ? [tile_size, tile_size]
    //   : slot_rail_type == "Top-Bottom" ? [tile_size, tile_size * (vertical_grids - 1)]
    //   : [tile_size, tile_size * (vertical_grids - 1)];
    // slot_copy_n =
    //   slot_rail_type == "All" || slot_stagger != false ? [horizontal_grids, vertical_grids]
    //   : slot_rail_type == "Top-Bottom" ? [horizontal_grids, 2]
    //   : [horizontal_grids, 2];
    // grid_copies(slot_copy_spacing, n=slot_copy_n, stagger=slot_stagger)
    //   down(eps) tag("remove") multiconnect_slot(multiconnect_type, anchor=BOTTOM);
    // if (slot_rail_type == "Auto" && (vertical_grids > 4 && slot_stagger == false)) {
    //   for (i = [1:ceil((vertical_grids - 2) / 2) - 1]) {
    //     back(tile_size * (floor(vertical_grids - 1) / 2)) fwd(tile_size * 2 * i) line_copies(tile_size, n=horizontal_grids)
    //           down(eps) tag("remove") multiconnect_slot(multiconnect_type, anchor=BOTTOM);
    //   }
    // }
  }
  module shell_divider() {
    //Divider wall must be double the thickness of outer wall thickness, to keep the size of container consistent between divided and standalone drawers. A bit thick 
    divider_wall_thickness = shell_thickness * 2;
    mainW = shell_main_divide_unit == "Width";

    main_divide_strs = str_split(str_strip(str_replace_char(mainW ? shell_width_dividers : shell_height_dividers, " ", ","), ","), ",");
    main_divide_nums = [for (i = [0:len(main_divide_strs) - 1]) parse_num(main_divide_strs[i])];
    main_divide_cumnums = cumsum(main_divide_nums);
    sub_divide_strs_vecs = str_split(str_strip(!mainW ? shell_width_dividers : shell_height_dividers, " "), " ");
    sub_divide_nums_vecs = [for (i = [0:len(sub_divide_strs_vecs) - 1]) [for (j = [0:len(str_split(str_strip(sub_divide_strs_vecs[i], ","), ",")) - 1]) parse_num(str_split(str_strip(sub_divide_strs_vecs[i], ","), ",")[j])]];
    sub_divide_cumnums_vecs = [for (i = [0:len(sub_divide_nums_vecs) - 1]) cumsum(sub_divide_nums_vecs[i])];

    mainwall_alignment = mainW ? LEFT : BACK;
    mainhexwall_spin = mainW ? 90 : 0;
    mainhexwall_length = !mainW ? shell_width - shell_inner_chamfer * 2 : shell_height - shell_inner_chamfer * 2;
    mainsolidwall_size = mainW ? [divider_wall_thickness, shell_height - shell_thickness * 2, shell_depth - shell_slot_part_thickness] : [shell_width - shell_thickness * 2, divider_wall_thickness, shell_depth - shell_slot_part_thickness];

    subwall_alignment = mainW ? BACK : LEFT;
    subhexwall_spin = mainW ? 0 : 90;
    subhexwall_length = mainW ? shell_width - shell_inner_chamfer * 2 : shell_height - shell_inner_chamfer * 2;

    for (i = [0:len(main_divide_cumnums) - 1]) {
      if (main_divide_cumnums[i] > 0 && main_divide_cumnums[i] < (mainW ? horizontal_grids : vertical_grids)) {
        main_compartment_inset = main_divide_cumnums[i] * tile_size - divider_wall_thickness / 2;
        sub_compartment_size = main_divide_nums[i] * tile_size - divider_wall_thickness;

        subwall_translate_base = mainW ? [-(shell_width / 2 - sub_compartment_size / 2 - shell_thickness), 0, 0] : [0, (shell_height / 2 - sub_compartment_size / 2 - shell_thickness), 0];
        subsolidwall_size = mainW ? [sub_compartment_size, divider_wall_thickness, shell_depth] : [divider_wall_thickness, sub_compartment_size, shell_depth - shell_slot_part_thickness];

        if (len(sub_divide_cumnums_vecs) > i) {
          for (j = [0:len(sub_divide_cumnums_vecs[i]) - 1]) {
            subwall_translate_offset = mainW ? [(i > 0 ? main_divide_cumnums[i - 1] * tile_size : 0), 0, 0] : [0, -(i > 0 ? main_divide_cumnums[i - 1] * tile_size : 0), 0];
            if (sub_divide_cumnums_vecs[i][j] > 0 && sub_divide_cumnums_vecs[i][j] < (!mainW ? horizontal_grids : vertical_grids)) {
              if (shell_divider_wall_type == "Honeycomb") {
                tag_intersect(tag="keep", intersect="divider_mask", keep="divider_keep") {
                  attach(TOP, RIGHT, align=subwall_alignment, inset=sub_divide_cumnums_vecs[i][j] * tile_size - divider_wall_thickness / 2, inside=true, spin=subhexwall_spin)
                    tag("") hex_panel([shell_depth - shell_slot_part_thickness + shell_thickness, subhexwall_length, divider_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
                  translate(subwall_translate_base) translate(subwall_translate_offset)
                      attach(TOP, TOP, align=subwall_alignment, inset=sub_divide_cumnums_vecs[i][j] * tile_size - divider_wall_thickness / 2, inside=true)
                        tag("divider_mask") cuboid(subsolidwall_size);
                }
              }
              else
                translate(subwall_translate_base) translate(subwall_translate_offset)
                    attach(TOP, TOP, align=subwall_alignment, inset=sub_divide_cumnums_vecs[i][j] * tile_size - divider_wall_thickness / 2, inside=true)
                      tag("keep") cuboid(subsolidwall_size);
            }
          }
        }
        if (shell_divider_wall_type == "Honeycomb") {
          tag_intersect(tag="keep", intersect="divider_mask", keep="divider_keep") {
            attach(TOP, RIGHT, align=mainwall_alignment, inset=main_compartment_inset, inside=true, spin=mainhexwall_spin)
              tag("") hex_panel([shell_depth - shell_slot_part_thickness + shell_thickness, mainhexwall_length, divider_wall_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, TOP, align=mainwall_alignment, inset=main_compartment_inset, inside=true)
              tag("divider_mask") cuboid(mainsolidwall_size);
          }
        }
        else
          attach(TOP, TOP, align=mainwall_alignment, inset=main_compartment_inset, inside=true)
            tag("keep") cuboid(mainsolidwall_size);
      }
    }
  }
}

module openconnect_head(is_negative = false, add_nub = 2) {
  bottom_profile = is_negative ? slot_bottom_profile : head_bottom_profile;
  top_profile = is_negative ? slot_top_profile : head_top_profile;

  bottom_height = is_negative ? slot_bottom_height : head_bottom_height;
  middle_height = is_negative ? slot_middle_height : head_middle_height;
  top_height = is_negative ? slot_top_height : head_top_height;
  large_rect_width = is_negative ? slot_large_rect_width : head_large_rect_width;

  bottom_chamfer = is_negative ? 0 : head_bottom_chamfer;

  difference() {
    union() {
      if (bottom_chamfer > eps) {
        hull() {
          linear_extrude(h=eps) polygon(offset(bottom_profile, delta=-bottom_chamfer));
          up(bottom_chamfer) linear_extrude(h=eps) polygon(bottom_profile);
        }
      }
      up(bottom_chamfer) linear_extrude(h=bottom_height - bottom_chamfer) polygon(bottom_profile);
      up(bottom_height - eps) hull() {
          up(middle_height) linear_extrude(h=eps) polygon(top_profile);
          linear_extrude(h=eps) polygon(bottom_profile);
        }
      up(bottom_height + middle_height - eps)
        linear_extrude(h=top_height + eps) polygon(top_profile);
    }
    rot_copies([90, 0, 0], n=add_nub)
      left(large_rect_width / 2 - nub_depth / 2 + eps) zrot(-90) linear_extrude(4) trapezoid(h=nub_depth, w2=nub_tip_height, ang=[45, 45], rounding=[nub_inner_fillet, nub_inner_fillet, -nub_outer_fillet, -nub_outer_fillet], $fn=64);
  }
}

module openconnect_slot(add_nub = 1, anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[slot_large_rect_width, slot_large_rect_height, slot_total_height]) {
    up(slot_total_height / 2) yrot(180) union() {
          if (flip_slot_direction)
            xflip() slot_body();
          else
            slot_body();
        }
    children();
  }
  module onramp_2d() {
    intersection() {
      union() {
        offset(delta=slot_ramp_clearance)
          rect([slot_large_rect_width, slot_large_rect_height], chamfer=slot_large_rect_chamfer);
        left(slot_ramp_clearance * sqrt(2) / 2) back(slot_large_rect_height / 2) trapezoid(h=slot_ramp_clearance * sqrt(2), w1=slot_large_rect_width - slot_large_rect_chamfer * 2 + slot_ramp_clearance * sqrt(2), ang=[45, 45], anchor=BOTTOM);
      }
      union() {
        rect([slot_large_rect_width, slot_large_rect_height], chamfer=slot_large_rect_chamfer);
        back(slot_ramp_clearance * sqrt(2) / 2) left(slot_large_rect_chamfer) rect([slot_large_rect_width, slot_large_rect_height + slot_ramp_clearance * sqrt(2)], chamfer=[slot_ramp_clearance * sqrt(2), 0, 0, 0]);
      }
    }
  }
  module slot_body() {
    union() {
      openconnect_head(is_negative=true, add_nub=add_nub ? 1 : 0);
      xrot(90) linear_extrude(slot_large_rect_height / 2) polygon(slot_side_profile);
      fwd(slot_move_distance) {
        linear_extrude(slot_bottom_height) onramp_2d();
        up(slot_bottom_height)
          linear_extrude(slot_middle_height * sqrt(2), v=[-1, 0, 1]) onramp_2d();
        left(slot_middle_height) up(slot_bottom_height + slot_middle_height)
            linear_extrude(slot_top_height) onramp_2d();
      }
    }
  }
}
