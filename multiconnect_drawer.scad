include <BOSL2/std.scad>
include <BOSL2/walls.scad>
include <BOSL2/threading.scad>
//It seems as of now (2025-08) makerworld's customizer needs rounding.scad to be included manually, despite the fact it should be included in std.scad according to BOSL2 wiki.
include <BOSL2/rounding.scad>

generate_shell = true;
generate_container = true;

/* [Slot Parameters] */
multiconnect_type = "Full"; //["Full","Lite"]
//Either a Continuous rail or Separate slots. Separate is always chosen for Multiconnect Lite.
slot_rail_type = "Separate"; //[Continuous, Separate]
slot_v2_bump_width = 0.4;

/* [View Options] */
view_cross_section = "None"; //["None","Right","Back","Diagonal"]
view_drawer_overlapped = false;

/*[Grid Parameters]*/
vertical_grids = 2;
horizontal_grids = 1;
drawer_depth = 28;

/*[Honeycomb Parameters]*/
honeycomb_wall_type = "Standard"; //["Standard","Big"]
honeycomb_strut_hyp_standard = 2.52; //0.42
honeycomb_strut_hyp_big = 4.2; //0.42

/*[Shell Parameters]*/
shell_chamfer = 0.8;
shell_thickness = 2.1; //0.42
shell_top_wall_type = "Solid"; //["Solid","Honeycomb","Textured"]
shell_bottom_wall_type = "Honeycomb"; //["Solid","Honeycomb","Textured"]
shell_side_wall_type = "Honeycomb"; //["Solid","Honeycomb","Textured"]

/*[Container Parameters]*/
container_back_height_diff = 3;
container_thickness = 2.1; //0.42
container_vertical_clearance = 0.5;
container_horizontal_clearance = 0.3;
container_depth_clearance = 0.1;

container_front_wall_type = "Honeycomb"; //["Solid","Honeycomb","Textured"]
container_back_wall_type = "Solid"; //["Solid","Honeycomb","Textured"]
container_bottom_wall_type = "Solid"; //["Solid","Honeycomb","Textured"]
container_side_wall_type = "Solid"; //["Solid","Honeycomb","Textured"]

/*[Handle Parameters]*/
handle_type = "Filled"; //["Pull","Filled","Bridge","Gap","Knob-Separate"]
handle_strut_number = 0;
handle_thickness = 2.52; //0.42
handle_depth = 5;
handle_chamfer = 0.4;
handle_height_offset = 1.05; //0.21

gap_width_unit = 3;
gap_height_unit = 1;

/*[Hidden]*/
$fa = 1;
$fs = 0.4;
eps = 0.005;

tile_size = 28;

honeycomb_unit_space_adj =
  honeycomb_wall_type == "Standard" ? 28 / 4
  : honeycomb_wall_type == "Big" ? 14 : 4;
honeycomb_unit_space_hyp = ang_adj_to_hyp(30, honeycomb_unit_space_adj);
honeycomb_strut_hyp = honeycomb_wall_type == "Big" ? honeycomb_strut_hyp_big : honeycomb_strut_hyp_standard;
honeycomb_strut_adj = ang_hyp_to_adj(30, honeycomb_strut_hyp);
// honeycomb_strut_adj = honeycomb_wall_type == "Big" ? honeycomb_strut_adj_big : honeycomb_strut_adj_standard;
// honeycomb_strut_hyp = ang_adj_to_hyp(30, honeycomb_strut_adj);

//The official multiconnect threads are designed in shapr3d and have a different starting point than those made in openscad. Rotating by 53.5 degrees makes them conform.
threads_compatiblity_angle = 53.5;
threads_profile = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];

// /* [threads Options] */
//Multiconnect threads are designed to have 16mm diameter and 0.5mm clearance, 16.5mm is the offical diameter for negative parts.
multiconnect_threads_positive_diameter = 16;
multiconnect_threads_clearance = 0.5;
threads_top_bevel = 0.5; //0.1
threads_bottom_bevel_full = 2; //0.1
threads_bottom_bevel_lite = 1.2; //0.1

mc_index = multiconnect_type == "Full" ? 0 : 1;
//multiconnect head paramaters
on_ramp_clearance = 1;

head_top_radiuss = [7.5, 7.5];
head_bottom_radiuss = [10, 8.5];
head_top_heights = [0.5, 0.4];
head_middle_heights = [2.5, 1];
head_bottom_heights = [1, 0.6];
head_bottom_chamfers = [0, 0.2];
slot_side_clearances = [0.15, 0.1];
slot_depth_clearances = [0.15, 0.1];
slot_depth_offsets = [tan(45 / 2) * slot_side_clearances[0], tan(45 / 2) * slot_side_clearances[1]];
head_total_heights = [head_top_heights[0] + head_middle_heights[0] + head_bottom_heights[0], head_top_heights[1] + head_middle_heights[1] + head_bottom_heights[1]];
slot_total_heights = [head_top_heights[0] + head_middle_heights[0] + head_bottom_heights[0] + slot_depth_clearances[0], head_top_heights[1] + head_middle_heights[1] + head_bottom_heights[1] + slot_depth_clearances[1]];

shell_to_slot_wall_thickness = 0.8;
shell_slot_part_thickness = slot_total_heights[mc_index] + shell_to_slot_wall_thickness;
// depth_conversion = 28;

coin_slot_heights = [3, 3, 1, 2];
coin_slot_widths = [14, 14, 8.5, 11.6];
coin_slot_thickness = 2.4;

full_head_profile = [
  [0, 0],
  [head_bottom_radiuss[0], 0],
  [head_bottom_radiuss[0], head_bottom_heights[0]],
  [head_top_radiuss[0], head_bottom_heights[0] + head_middle_heights[0]],
  [head_top_radiuss[0], head_bottom_heights[0] + head_middle_heights[0] + head_top_heights[0]],
  [0, head_bottom_heights[0] + head_middle_heights[0] + head_top_heights[0]],
];
full_slot_profile = [
  [0, 0],
  [head_bottom_radiuss[0] + slot_side_clearances[0], 0],
  [head_bottom_radiuss[0] + slot_side_clearances[0], head_bottom_heights[0] + slot_depth_offsets[0] + slot_depth_clearances[0]],
  [head_top_radiuss[0] + slot_side_clearances[0], head_bottom_heights[0] + head_middle_heights[0] + slot_depth_offsets[0] + slot_depth_clearances[0]],
  [head_top_radiuss[0] + slot_side_clearances[0], head_bottom_heights[0] + head_middle_heights[0] + head_top_heights[0] + slot_depth_clearances[0]],
  [0, head_bottom_heights[0] + head_middle_heights[0] + head_top_heights[0] + slot_depth_clearances[0]],
];
lite_head_profile = [
  [0, 0],
  [head_bottom_radiuss[1] - head_bottom_chamfers[1], 0],
  [head_bottom_radiuss[1], head_bottom_chamfers[1]],
  [head_bottom_radiuss[1], head_bottom_heights[1]],
  [head_top_radiuss[1], head_bottom_heights[1] + head_middle_heights[1]],
  [head_top_radiuss[1], head_bottom_heights[1] + head_middle_heights[1] + head_top_heights[1]],
  [0, head_bottom_heights[1] + head_middle_heights[1] + head_top_heights[1]],
];
lite_slot_profile = [
  [0, 0],
  [head_bottom_radiuss[1] + slot_side_clearances[1], 0],
  [head_bottom_radiuss[1] + slot_side_clearances[1], head_bottom_heights[1] + slot_depth_offsets[1] + slot_depth_clearances[1]],
  [head_top_radiuss[1] + slot_side_clearances[1], head_bottom_heights[1] + head_middle_heights[1] + slot_depth_offsets[1] + slot_depth_clearances[1]],
  [head_top_radiuss[1] + slot_side_clearances[1], head_bottom_heights[1] + head_middle_heights[1] + head_top_heights[1] + slot_depth_clearances[1]],
  [0, head_bottom_heights[1] + head_middle_heights[1] + head_top_heights[1] + slot_depth_clearances[1]],
];
slot_profiles = [full_slot_profile, lite_slot_profile];
head_profiles = [full_head_profile, lite_head_profile];

//calculated parameters
shell_width = horizontal_grids * tile_size;
shell_height = vertical_grids * tile_size;
// drawer_depth = depth_grids * depth_conversion;
container_width = shell_width - container_horizontal_clearance * 2 - shell_thickness * 2;
container_height = shell_height - container_vertical_clearance * 2 - shell_thickness * 2;

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
fronthex_bottom_strut_height = hex_ir + honeycomb_strut_adj + fronthex_height_offset - handle_height_offset;
height_adj_to_width_opp = ang_adj_to_opp(30, abs(fronthex_height_offset));

//handle parameters
//math to calculate the location of struts of hexagon.
leftcol1_rightcol2 = fronthex_width / 2 - honeycomb_unit_space_adj * (handle_strut_number - 1) - hex_or * 2 - honeycomb_strut_hyp / 2 + height_adj_to_width_opp;
leftcol2_rightcol1 = fronthex_width / 2 - honeycomb_unit_space_adj * (floor(container_width / honeycomb_unit_space_adj) - handle_strut_number - 2) - hex_or * 2 - honeycomb_strut_hyp / 2 + height_adj_to_width_opp;
// leftcol2_rightcol1 = fronthex_width / 2 - honeycomb_unit_space_adj * handle_strut_number + height_adj_to_width_opp + honeycomb_strut_hyp / 2;
leftright_balance = (leftcol1_rightcol2 + leftcol2_rightcol1) / 2;
// left_strut_offset = fronthex_width / 2 - honeycomb_strut_hyp / 2 - honeycomb_unit_space_adj * 2 + hex_or + honeycomb_strut_hyp;
// right_strut_offset = left_strut_offset;
left_strut_offset = handle_strut_number % 2 == 0 ? leftcol1_rightcol2 : leftcol2_rightcol1;
right_strut_offset = handle_strut_number % 2 == 0 ? leftcol2_rightcol1 : leftcol1_rightcol2;

handle_strut_slant_width = ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer);
// handle_rounding = honeycomb_strut_hyp + ang_adj_to_opp(30, fronthex_bottom_strut_height) - handle_chamfer / 2;
final_handle_thickness = min(handle_thickness, honeycomb_strut_hyp);
handle_rounding = final_handle_thickness;

left_handle_width = (left_strut_offset - honeycomb_strut_hyp / 2 - handle_strut_slant_width / 2) - handle_rounding;
right_handle_width = -(right_strut_offset - honeycomb_strut_hyp / 2 - handle_strut_slant_width / 2) - handle_rounding;
handle_width_inset = handle_strut_number * honeycomb_unit_space_adj;
pull_diagonal_distance = handle_depth - handle_thickness;
turtle_start_offset = 0.2;
pull_handle_transition_depth = handle_depth - handle_rounding - final_handle_thickness / 2 - turtle_start_offset;
handle_sweep_turtle_path_left = ["move", turtle_start_offset, "arcleft", handle_rounding, 90, "move", left_handle_width];
handle_sweep_turtle_path_right = ["move", turtle_start_offset, "arcright", handle_rounding, 90, "move", right_handle_width];
handle_sweep_turtle_path_fill = ["move", handle_depth - handle_rounding - final_handle_thickness / 2, "arcleft", handle_rounding, 90, "move", (container_width - handle_width_inset - hex_or - handle_rounding * 2 - handle_thickness) / 2];

half_of_anchor =
  view_cross_section == "Right" ? RIGHT
  : view_cross_section == "Back" ? BACK
  : view_cross_section == "Diagonal" ? RIGHT + BACK
  : 0;

if (half_of_anchor != 0) {
  half_of(half_of_anchor) {
    if (generate_shell)
      down(shell_slot_part_thickness)
        drawer_shell();
    if (generate_container)
      left(view_drawer_overlapped ? 0 : shell_width)
        up(container_depth_clearance) drawer_container();
  }
} else {
  if (generate_shell)
    down(shell_slot_part_thickness)
      drawer_shell();
  if (generate_container)
    left(view_drawer_overlapped ? 0 : shell_width)
      up(container_depth_clearance) drawer_container();
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
// !union() {
//   debug_polygon(handle_profile_func(10, 30), size=0.2);
//   color("yellow") up(2) debug_polygon(handle_profile_func(10), size=0.2);
//   //  echo("1",handle_profile_func(30));
//   //  echo("2",handle_profile_func(30,30));
// }

module handle_transition(steps = 90, direction = "Left", thickness = honeycomb_strut_hyp, wide_bottom = false) {
  ang_unit = 30 / steps;
  up_unit = pull_handle_transition_depth / steps;
  x_unit =
    direction == "Left" ? (ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer)) / steps
    : direction == "Middle" ? ang_adj_to_opp(30, fronthex_bottom_strut_height - handle_chamfer) / 2 / steps
    : 0;
  render()for (i = [1:1:steps]) {
    handle_profile1 = handle_profile_func(first_ang=30 - ang_unit * (i - 1), second_ang=wide_bottom ? ang_unit * (i - 1) : 30, thickness=thickness);
    handle_profile2 = handle_profile_func(first_ang=30 - ang_unit * (i), second_ang=wide_bottom ? ang_unit * (i) : 30, thickness=thickness);
    hull() {
      right(x_unit * (i - 1)) up(up_unit * (i - 1)) linear_extrude(eps) polygon(handle_profile1);
      right(x_unit * i) up(up_unit * i) linear_extrude(eps) polygon(handle_profile2);
      // echo("i", i, "up", up_unit * i, "x", x_unit * i, "ang", ang_unit * i);
    }
  }
}
module drawer_shell() {
  difference() {
    intersection() {
      diff() {
        cuboid([shell_width, shell_height, drawer_depth + container_depth_clearance + shell_slot_part_thickness], anchor=BOTTOM) {
          attach(TOP, TOP, inside=true)
            tag("remove") cuboid([shell_width - shell_thickness * 2 + eps, shell_height - shell_thickness * 2 + eps, drawer_depth + container_depth_clearance], edges="Z", chamfer=shell_chamfer);
          if (shell_side_wall_type == "Honeycomb") {
            attach(TOP, TOP, align=LEFT, inside=true)
              tag("remove") cuboid([shell_thickness + eps, shell_height - shell_thickness * 2 - shell_chamfer * 2, drawer_depth + container_depth_clearance]);
            attach(TOP, TOP, align=RIGHT, inside=true)
              tag("remove") cuboid([shell_thickness + eps, shell_height - shell_thickness * 2 - shell_chamfer * 2, drawer_depth + container_depth_clearance]);
            attach(TOP, RIGHT, align=LEFT, inside=true, spin=90)
              tag("keep") hex_panel([drawer_depth + container_depth_clearance + shell_thickness, shell_height - shell_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
            attach(TOP, RIGHT, align=RIGHT, inside=true, spin=90)
              tag("keep") hex_panel([drawer_depth + container_depth_clearance + shell_thickness, shell_height - shell_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
          }
          if (shell_top_wall_type == "Honeycomb") {
            attach(TOP, TOP, align=BACK, inside=true)
              tag("remove") cuboid([shell_width - shell_thickness * 2 - shell_chamfer * 2, shell_thickness + eps, drawer_depth + container_depth_clearance]);
            attach(TOP, RIGHT, align=BACK, inside=true)
              tag("keep") hex_panel([drawer_depth + container_depth_clearance + shell_thickness, shell_width - shell_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
          }
          if (shell_bottom_wall_type == "Honeycomb") {
            attach(TOP, TOP, align=FRONT, inside=true)
              tag("remove") cuboid([shell_width - shell_thickness * 2 - shell_chamfer * 2, shell_thickness + eps, drawer_depth + container_depth_clearance]);
            attach(TOP, RIGHT, align=FRONT, inside=true)
              tag("keep") hex_panel([drawer_depth + container_depth_clearance + shell_thickness, shell_width - shell_chamfer * 2, shell_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=shell_thickness);
          }
          // tag("inner_remove") attach(RIGHT, BOT, align=[TOP, DOWN], inset=3, inside=true, spin=threads_compatiblity_angle)
          // zrot(0) generic_threaded_rod(d=multiconnect_threads_positive_diameter, l=shell_thickness + eps, pitch=3, profile=threads_profile, bevel1=0, bevel2=1.2, blunt_start=false, anchor=BOTTOM, internal=false);
          // tag_diff(tag="keep", remove="inner_remove"){}
        }
      }
      cuboid([shell_width, shell_height, drawer_depth + container_depth_clearance + shell_slot_part_thickness], edges="Z", chamfer=shell_chamfer, anchor=BOTTOM);
    }
    grid_copies([tile_size, tile_size], n=[horizontal_grids, vertical_grids])
      down(eps) tag("remove") multiconnect_slot(multiconnect_type, anchor=BOTTOM);
  }
}
module drawer_container() {
  intersect(intersect="mask", keep="tag_keep") {
    hide("empty") tag_this("empty")
        //the parent cuboid is hidden and used as an anchor point
        cuboid([container_width, container_height, drawer_depth - container_depth_clearance], anchor=BOTTOM) diff(remove="sp_remove", keep="mask") {
            if (handle_type == "Pull") {
              up((drawer_depth - container_depth_clearance) / 2 - eps) fwd(container_height / 2) left(left_strut_offset)
                    handle_transition(direction="Middle", thickness=final_handle_thickness);
              up((drawer_depth - container_depth_clearance) / 2 - eps) fwd(container_height / 2) left(right_strut_offset)
                    handle_transition(direction="Middle", thickness=final_handle_thickness);
              up(pull_handle_transition_depth - eps) left(left_strut_offset - final_handle_thickness / 2 - handle_strut_slant_width / 2)
                  fwd(container_height / 2 - fronthex_bottom_strut_height / 2)
                    attach(TOP, "start-centroid")
                      path_sweep(rect([final_handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_left));
              up(pull_handle_transition_depth - eps) left(right_strut_offset - final_handle_thickness / 2 - handle_strut_slant_width / 2)
                  fwd(container_height / 2 - fronthex_bottom_strut_height / 2)
                    attach(TOP, "start-centroid")
                      path_sweep(rect([final_handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_right));
            } else if (handle_type == "Filled") {
              attach(TOP, TOP, align=FRONT, inside=true)
                cuboid([container_width, fronthex_bottom_strut_height, container_thickness]);
              xflip_copy() left(fronthex_width / 2 - handle_thickness / 2 - handle_width_inset / 2 - hex_or)
                  fwd(container_height / 2 - fronthex_bottom_strut_height / 2) attach(TOP, "start-centroid")
                      path_sweep(rect([final_handle_thickness, fronthex_bottom_strut_height], chamfer=handle_chamfer), path=turtle(handle_sweep_turtle_path_fill));
            } else if (handle_type == "Gap") {
              // gap_first_width = honeycomb_unit_space_adj * fronthex_width_struts-hex_or*gap_width_unit;
              gap_first_width = honeycomb_unit_space_adj * gap_width_unit / 2;
              gap_height = honeycomb_unit_space_hyp * gap_height_unit / 2 + fronthex_height_offset + honeycomb_strut_adj / 2;
              gap_side_rounding = 2;
              gap_edge_rounding = 0.4;
              gap_profile = trapezoid(h=gap_height - honeycomb_strut_adj, w1=gap_first_width, ang=120, rounding=[-gap_side_rounding, -gap_side_rounding, gap_side_rounding, gap_side_rounding], $fn=64);
              attach(TOP, TOP, align=BACK, inside=true)
                cuboid([container_width, gap_height, container_thickness]);
              attach(TOP, TOP, align=BACK, inside=true)
                tag("sp_remove") offset_sweep(gap_profile, height=container_thickness + eps * 4, top=os_circle(r=-gap_edge_rounding), bottom=os_circle(r=-gap_edge_rounding));
              // *tag_diff(tag="sp_remove", remove="rm2")
              //   attach(TOP, FRONT, align=BACK, inside=true, shiftout=eps)
              //     tag("") prismoid(size1=[gap_first_width, container_thickness + eps * 4], xang=[120, 120], yang=[90, 90], h=gap_height - honeycomb_strut_adj, rounding=0) {
              //         edge_mask([BOTTOM + RIGHT, BOTTOM + LEFT])
              //           tag("rm2") rounding_edge_mask(r=gap_side_rounding);
              //         edge_mask([TOP + RIGHT, TOP + LEFT])
              //           tag("") rounding_edge_mask(r=gap_side_rounding, spin=60, ang=180 - $edge_angle, $fn=64);
              //       }
              // attach(TOP, TOP, align=BACK, inside=true)
              // tag("sp_remove") cuboid([gap_first_width, gap_height- honeycomb_strut_adj, container_thickness],edges=[FRONT+LEFT,FRONT+RIGHT],rounding=0.6);
              // *attach(TOP, FRONT, align=BACK, inset=fronthex_height_offset, inside=true)
              //     prismoid(size2=[gap_first_width + honeycomb_strut_hyp * 2, container_thickness], xang=[120, 120], yang=[90, 90], h=gap_height + honeycomb_strut_adj, rounding=0);
              // attach(TOP, TOP, align=BACK, inside=true)
              //     tag("sp_remove") cuboid([gap_first_width, fronthex_height_offset, container_thickness]);
              // echo(gap_first_width, gap_first_width - ang_adj_to_opp(30, gap_height) * 2, gap_height);
              // handle_hex_scale = 2;
              // attach(TOP, TOP, align=BACK, inset=fronthex_height_offset -honeycomb_strut_adj/2 -honeycomb_unit_space_hyp * handle_hex_scale, inside=true)
              // #regular_prism(6, r=honeycomb_unit_space_adj * handle_hex_scale, h=container_thickness);
            }
            // else if (handle_type == "Bridge") {
            //   $fn = 64;
            //   bridge_width = handle_strut_number == 0 ? container_width : honeycomb_unit_space_adj * (fronthex_width_struts - handle_strut_number) + handle_thickness;
            //   bridge_height = honeycomb_unit_space_hyp * bridge_height_unit - honeycomb_strut_adj;
            //   bridge_depth = max(handle_thickness, min(bridge_height - handle_thickness - 6, 10 + handle_thickness));
            //   // bridge_depth = min(bridge_height - handle_thickness, bridge_height / 2);
            //   fwd(fronthex_height_offset + bridge_position_down_unit * honeycomb_unit_space_hyp + honeycomb_strut_adj / 2) attach(TOP, BOTTOM, align=BACK)
            //       tag_this("empty") prismoid(size1=[bridge_width, bridge_height], xang=[90, 90], yang=[45, 90], h=bridge_depth, rounding=handle_chamfer) {
            //           tag_diff("", remove="handle_remove1") {
            //             attach(BOTTOM, BOTTOM, align=LEFT, inside=true)
            //               tag("") prismoid(size1=[handle_thickness, bridge_height], xang=[90, 90], yang=[45, 90], h=bridge_depth, rounding=handle_chamfer)
            //                   attach(BOTTOM, TOP)
            //                     cuboid([handle_thickness, bridge_height, container_thickness], edges="Z", rounding=handle_chamfer);
            //             attach(BOTTOM, BOTTOM, align=RIGHT, inside=true)
            //               tag("") prismoid(size1=[handle_thickness, bridge_height], xang=[90, 90], yang=[45, 90], h=bridge_depth, rounding=handle_chamfer)
            //                   attach(BOTTOM, TOP)
            //                     cuboid([handle_thickness, bridge_height, container_thickness], edges="Z", rounding=handle_chamfer);
            //             attach(BACK, BACK, align=LEFT, inside=true)
            //               tag("") cuboid([bridge_width, handle_thickness, bridge_depth], except=[BOTTOM, TOP + FRONT, TOP + BACK], rounding=handle_chamfer)
            //                   attach(BOTTOM, TOP)
            //                     cuboid([bridge_width, handle_thickness, container_thickness], edges="Z", rounding=handle_chamfer);
            //             tag_diff("", remove="handle_remove2")
            //               attach(TOP, TOP, align=RIGHT, inside=true)
            //                 tag("") prismoid(size2=[bridge_width, bridge_height - bridge_depth], xang=[90, 90], yang=[45, 90], h=handle_thickness, rounding=handle_chamfer)
            //                     edge_mask([BOTTOM + FRONT])
            //                       tag("handle_remove2") rounding_edge_mask(r=handle_chamfer);
            //             edge_mask([TOP + LEFT, TOP + RIGHT, BACK + FRONT, BACK + TOP])
            //               tag("handle_remove1") rounding_edge_mask(r=handle_chamfer);
            //             edge_mask([TOP + FRONT])
            //               tag("handle_remove1") rounding_edge_mask(r=handle_chamfer);
            //             corner_mask([TOP + BACK])
            //               tag("handle_remove1") rounding_corner_mask(r=handle_chamfer);
            //           }
            //         }
            // } 
            //front top edge rounding
              // attach(TOP, TOP, align=BACK, inset=-1, inside=true)
                // tag("sp_remove") offset_sweep(rect([container_width, 1]), height=container_thickness + eps * 2, top=os_circle(r=-0.4), bottom=os_circle(r=-0.4));
            //frontwall
            if (container_front_wall_type == "Honeycomb")
              attach(FRONT, LEFT, align=TOP, inside=true, shiftout=0)
                hex_panel([container_height, container_width, container_thickness + eps], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_thickness);
            else
              attach(TOP, TOP, align=FRONT, inside=true, shiftout=eps)
                cuboid([container_width - container_thickness * 2 + eps, container_height - container_thickness, container_thickness + eps * 2]);
            //backwall
            if (container_back_wall_type == "Honeycomb")
              attach(FRONT, LEFT, align=BOTTOM, inside=true)
                hex_panel([container_height - container_back_height_diff, container_width, container_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_thickness + shell_chamfer);
            else
              attach(BOTTOM, BOTTOM, align=FRONT, inside=true)
                cuboid([container_width, container_height - container_back_height_diff, container_thickness]);
            //side walls
            // if (container_side_wall_type == "Honeycomb") {
            //   attach(FRONT, LEFT, align=RIGHT, inside=true, spin=90)
            //     hex_panel([container_height - container_back_height_diff, drawer_depth - container_depth_clearance, container_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_thickness);
            //   attach(FRONT, LEFT, align=LEFT, inside=true, spin=90)
            //     hex_panel([container_height - container_back_height_diff, drawer_depth - container_depth_clearance, container_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_thickness);
            // } else {
            attach(LEFT, LEFT, align=FRONT, inside=true)
              cuboid([container_thickness, container_height - container_back_height_diff, drawer_depth - container_depth_clearance]);
            attach(RIGHT, RIGHT, align=FRONT, inside=true)
              cuboid([container_thickness, container_height - container_back_height_diff, drawer_depth - container_depth_clearance]);
            // }
            //bottom
            if (container_bottom_wall_type == "Honeycomb")
              attach(TOP, LEFT, align=FRONT, inside=true)
                hex_panel([drawer_depth - container_depth_clearance, container_width, container_thickness], strut=honeycomb_strut_adj, spacing=honeycomb_unit_space_hyp, frame=container_thickness);
            else
              attach(FRONT, FRONT, align=BOTTOM, inside=true)
                cuboid([container_width, container_thickness, drawer_depth - container_depth_clearance]);
            tag_diff(tag="mask", remove="inner_remove") {
              attach(FRONT, FRONT, align=TOP, inset=-handle_depth, inside=true)
                cuboid([container_width, container_height, container_thickness + handle_depth], edges="Z", chamfer=shell_chamfer);
              attach(BOTTOM, BOTTOM, align=FRONT, inside=true)
                cuboid([container_width, container_height - container_back_height_diff, drawer_depth - container_depth_clearance - container_thickness], edges=["Z", BOTTOM], chamfer=shell_chamfer);
            }
          }
  }
}

module multiconnect_slot(multiconnect_type = "Full", on_ramp = true, anchor = CENTER, spin = 0, orient = UP) {
  i = multiconnect_type == "Full" ? 0 : multiconnect_type == "Lite" ? 1 : 2;
  attachable(anchor, spin, orient, size=[(head_bottom_radiuss[i] + slot_side_clearances[i]) * 2, (head_bottom_radiuss[i] + slot_side_clearances[i]) * 2, slot_total_heights[i]]) {
    down(slot_total_heights[i] / 2) yrot(180) union() {
          rotate_sweep(slot_profiles[i], anchor=TOP);
          if (on_ramp) {
            // fwd(head_bottom_radiuss[i] + slot_side_clearances[i]) cyl(h=slot_total_heights[i], r2=head_bottom_radiuss[i] + slot_side_clearances[i] + 1, r1=head_bottom_radiuss[i] + slot_side_clearances[i], chamfer2=0, anchor=TOP);
            fwd(head_bottom_radiuss[i] + slot_side_clearances[i])
              cyl(h=slot_total_heights[i] - head_bottom_heights[i] - slot_depth_clearances[i], r2=head_bottom_radiuss[i] + slot_side_clearances[i] + on_ramp_clearance, r1=head_bottom_radiuss[i] + slot_side_clearances[i], anchor=TOP)
                attach(BOTTOM, TOP)
                  cyl(h=head_bottom_heights[i] + slot_depth_clearances[i], r=head_bottom_radiuss[i] + slot_side_clearances[i]);
            xflip_copy() difference() {
                down(slot_total_heights[i]) xrot(90) linear_sweep(slot_profiles[i], height=slot_rail_type == "Separate" || multiconnect_type == "Lite" ? head_bottom_radiuss[i] : tile_size);
                right(head_bottom_radiuss[i] + slot_side_clearances[i]) prismoid([0, slot_total_heights[i]], [slot_v2_bump_width, slot_total_heights[i]], h=8, shift=[-slot_v2_bump_width / 2, 0], orient=BACK, anchor=TOP + RIGHT + FRONT);
              }
          }
        }
    children();
  }
}
