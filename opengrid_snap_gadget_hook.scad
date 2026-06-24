/*
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

Recommended to use with openGrid - Self-Expanding Snap. https://www.printables.com/model/1294247-opengrid-self-expanding-snap
The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

snap_thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm]
//Blunt threads help prevent cross-threading and overtightening. Models with blunt threads have a decorative 'lock' symbol.
threads_type = "Blunt"; //["Blunt", "Basic"]
hook_shape_type = "Centered"; //["Straight", "Centered", "Loop"]
corner_type = "Circular"; //["Circular", "Rectangular"]

/* [Hook Settings] */
//Width of hook body. The value for complete symmetry is 13.2.
body_width = 8; //0.4
//Thickness of hook body.
body_thickness = 6; //0.4
//Size of the main hook shape.
hook_main_size = 20; //0.4
hook_stem_length = 8; //0.4
//Scaling of body thickness. 0.6 means thickness at the end of the hook would be 60% of the beginning.
body_thickness_scale = 0.6; //[0.1:0.1:1]
//Angle affects Centered and Straight hooks.
hook_tip_angle = 165; //[15:15:255]

/* [Advanced Settings] */
//Counterclockwisely offset which direction the gadget faces when it's completely screwed in. 270 means it would face 3 o'clock direction.
threads_offset_angle = 0; //[0:15:345]
//Size of fillet at the part hook stem connects to threads.
hook_stem_fillet = 4; //0.4
//Chamfer is automatically clamped to ensure a sufficiently large print surface.
body_max_chamfer = 0.8; //0.2
//Uncommon means snap thickness that is neither 3.4mm or 6.8mm.
thickness_text_mode = "Uncommon"; //[All, Uncommon, None]

/* [Experimental Settings] */
//Enable this to draw a custom hook shape with custom_shape_commands. For those who want wacky hooks.
use_custom_shape = false;
//Only supports basic commands, not vectors. For more info, check out BOSL2 wiki for turtle().
custom_shape_commands = "setdir,90,arcright,5,45,move,15,arcleft,5,135,move,30";

/* [Hidden] */
$fa = 1;
$fs = 0.4;
emit_annotation_metadata = false;
include <lib/annotation_metadata.scad>

include <lib/opengrid_base.scad>
use <lib/opengrid_threads_lib.scad>

_add_blunt_text = threads_type == "Blunt";
_add_thickness_text = thickness_text_mode == "All" || (thickness_text_mode == "Uncommon" && snap_thickness != OG_LITE_BASIC_THICKNESS && snap_thickness != OG_STANDARD_THICKNESS);

_snaptext_texts = [_add_blunt_text ? OG_SNAP_BLUNT_TEXT : "", _add_thickness_text ? str(floor(snap_thickness)) : ""];

text_depth = 0.4;
_text_cfg = text_cfg(
  texts=_snaptext_texts,
  pos_offsets=(_add_blunt_text && _add_thickness_text) ? OG_GADGET_TEXT_POSITIONS : [[0, 0], [0, 0]],
  text_depth=text_depth
);

_threads_cfg = threads_cfg(
  threads_type=threads_type,
  threads_offset_angle=threads_offset_angle
);
_threads_diameter = struct_val(_threads_cfg, "threads_diameter");
_threads_pitch = struct_val(_threads_cfg, "threads_pitch");

_threads_connect_diameter = _threads_diameter - OG_THREADS_CONNECT_OFFSET;
_threads_side_offset = _threads_diameter / 2 - OG_SNAP_THREADS_SIDE_OFFSET;

square_corner_radius = 2;
min_ang_radius = 1;
//The minimum chamfer to make the threads_connect_diameter cutoff and a thick hook stem consistent.
overlap_chamfer = calculate_overlap_chamfer(body_width, body_thickness, _threads_connect_diameter);
final_tip_size = max(EPS, hook_main_size);
final_stem_length = max(EPS, hook_stem_length);
final_thickness_scale = !use_custom_shape && hook_shape_type == "Loop" ? 1 : body_thickness_scale;
final_side_chamfer = max(0, min((body_thickness * final_thickness_scale - OG_MIN_WALL_WIDTH) / 2, (body_width - OG_MIN_WALL_WIDTH) / 2, max(overlap_chamfer, body_max_chamfer)));

circular_straight_hook_path = ["setdir", 90, "arcleft", final_tip_size / 2, hook_tip_angle];
circular_center_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "arcleft", final_tip_size / 2, hook_tip_angle + 90];
circular_loop_hook_path = ["setdir", 0, "arcleft", final_tip_size / 2, 359.9];

rect_offset_angle = opp_adj_to_ang((body_thickness - body_thickness * final_thickness_scale) / 2, final_tip_size);
rect_corner_arc_length = PI / 2 * square_corner_radius;
rect_tip_corner_length = max(EPS, (hook_main_size - square_corner_radius * 2) * (hook_tip_angle - 135) / 90);
rect_straight_middle_ratio = (hook_main_size - square_corner_radius) / (hook_tip_angle > 135 ? (rect_corner_arc_length + rect_tip_corner_length + hook_main_size * 1.5 + rect_corner_arc_length - square_corner_radius) : (hook_main_size * 1.5 + rect_corner_arc_length - square_corner_radius));
rect_center_middle_ratio = (hook_main_size - square_corner_radius) / (hook_tip_angle > 135 ? (rect_corner_arc_length + rect_tip_corner_length + hook_main_size * 2.5 - square_corner_radius * 4 + rect_corner_arc_length * 2) : (hook_main_size * 2.5 - square_corner_radius * 4 + rect_corner_arc_length * 2));

rect_straight_hook_path = ["setdir", 90, "move", hook_main_size / 2, "arcleft", min_ang_radius, 90 + rect_offset_angle * rect_straight_middle_ratio, "move", hook_main_size - square_corner_radius];
rect_center_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "move", hook_main_size / 2 - square_corner_radius, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90 + rect_offset_angle * rect_center_middle_ratio, "move", hook_main_size - square_corner_radius];
rect_hook_tip_path = ["arcleft", square_corner_radius, 90, "move", rect_tip_corner_length];
rect_loop_hook_path = ["setdir", 90, "arcright", min_ang_radius, 90, "move", hook_main_size / 2 - square_corner_radius - min_ang_radius, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2, "arcleft", square_corner_radius, 90, "move", hook_main_size - square_corner_radius * 2];

function to_turtle(x) = is_num(parse_num(x)) ? parse_num(x) : x;
temp_path = str_split(str_strip(str_replace_char(str_replace_char(custom_shape_commands, " ", ""), "\"", ""), ","), ",");
custom_hook_path = [for (i = [0:len(temp_path) - 1]) to_turtle(temp_path[i])];

circular_hook_path =
  hook_shape_type == "Loop" ? circular_loop_hook_path
  : hook_shape_type == "Centered" ? circular_center_hook_path
  : circular_straight_hook_path;

rect_hook_path =
  hook_shape_type == "Centered" && hook_tip_angle > 135 ? concat(rect_center_hook_path, rect_hook_tip_path)
  : hook_shape_type == "Centered" ? rect_center_hook_path
  : hook_shape_type == "Straight" && hook_tip_angle > 135 ? concat(rect_straight_hook_path, rect_hook_tip_path)
  : hook_shape_type == "Straight" ? rect_straight_hook_path
  : rect_loop_hook_path;

hook_path =
  use_custom_shape ? custom_hook_path
  : corner_type == "Circular" ? circular_hook_path
  : rect_hook_path;

tip_rounding_radius = max(0, min(body_thickness * final_thickness_scale, body_width - final_side_chamfer * 2) / 2 - EPS);
artifact_cutoff_depth = EPS;
sweep_profile = rect([body_thickness, body_width], chamfer=final_side_chamfer);
offset_sweep_profile = scale([final_thickness_scale, 1, 1], sweep_profile);
fillet_sweep_profile = rect([body_thickness, body_width - artifact_cutoff_depth], chamfer=final_side_chamfer);
prism_fillet = max(0, min(final_stem_length, hook_stem_fillet));
thread_join_overlap = EPS * 2;


annotation_body_center_x = 0;
annotation_body_side_x = body_thickness / 2;
annotation_body_center_y = -final_stem_length / 2;
annotation_body_center_z = body_width / 2;
annotation_body_top_z = body_width;
annotation_hook_start_y = -final_stem_length;
annotation_hook_end_y = annotation_hook_start_y - hook_main_size;
annotation_hook_tip_path_radius = final_tip_size / 2;
annotation_hook_tip_angle_radius = max(3, annotation_hook_tip_path_radius - body_thickness * final_thickness_scale / 2);
annotation_hook_tip_angle_segments = 16;
annotation_hook_tip_angle_center_path =
  hook_shape_type == "Centered"
  ? [min_ang_radius, min_ang_radius + annotation_hook_tip_path_radius]
  : [-annotation_hook_tip_path_radius, 0];
function annotation_hook_path_point_to_model(point) = [
  point[0],
  annotation_hook_start_y - point[1],
  annotation_body_center_z
];
function annotation_hook_tip_angle_path_point(angle) = [
  annotation_hook_tip_angle_center_path[0] + annotation_hook_tip_angle_radius * cos(angle),
  annotation_hook_tip_angle_center_path[1] + annotation_hook_tip_angle_radius * sin(angle)
];
annotation_hook_tip_angle_center = annotation_hook_path_point_to_model(annotation_hook_tip_angle_center_path);
annotation_hook_tip_angle_mid = annotation_hook_path_point_to_model(annotation_hook_tip_angle_path_point(hook_tip_angle / 2));
annotation_hook_tip_angle_points = [
  for (i = [0:annotation_hook_tip_angle_segments])
    annotation_hook_path_point_to_model(annotation_hook_tip_angle_path_point(hook_tip_angle * i / annotation_hook_tip_angle_segments))
];

module emit_snap_gadget_hook_annotations() {
  emit_context_values(
    "snap_gadget_hook_context",
    [
      "snap_thickness",
      "body_width",
      "body_thickness",
      "hook_main_size",
      "hook_stem_length",
      "body_thickness_scale",
      "hook_tip_angle",
      "hook_stem_fillet"
    ],
    [
      snap_thickness,
      body_width,
      body_thickness,
      hook_main_size,
      hook_stem_length,
      body_thickness_scale,
      hook_tip_angle,
      hook_stem_fillet
    ]
  );
  emit_dimension_annotation(
    id="body_width",
    label="body_width",
    axis="z",
    value=body_width,
    start=[annotation_body_center_x, annotation_body_center_y, 0],
    end=[annotation_body_center_x, annotation_body_center_y, body_width],
    basis="hook_body_width_across_body_profile"
  );
  emit_dimension_annotation(
    id="body_thickness",
    label="body_thickness",
    axis="x",
    value=body_thickness,
    start=[-body_thickness / 2, annotation_body_center_y, annotation_body_center_z],
    end=[body_thickness / 2, annotation_body_center_y, annotation_body_center_z],
    basis="hook_body_thickness_across_body_profile"
  );
  emit_dimension_annotation(
    id="hook_main_size",
    label="hook_main_size",
    axis="y",
    value=hook_main_size,
    start=[annotation_body_side_x, annotation_hook_start_y, annotation_body_center_z],
    end=[annotation_body_side_x, annotation_hook_end_y, annotation_body_center_z],
    basis="nominal_main_hook_size_after_stem"
  );
  emit_dimension_annotation(
    id="hook_stem_length",
    label="hook_stem_length",
    axis="y",
    value=final_stem_length,
    start=[annotation_body_side_x, 0, annotation_body_center_z],
    end=[annotation_body_side_x, annotation_hook_start_y, annotation_body_center_z],
    basis="hook_stem_length_from_thread_connector"
  );
  if (!use_custom_shape && hook_shape_type != "Loop") {
    emit_radius_annotation(
      id="hook_tip_angle_radius",
      label="hook_tip_angle_radius",
      value=annotation_hook_tip_angle_radius,
      center=annotation_hook_tip_angle_center,
      edge=annotation_hook_tip_angle_mid,
      basis="hook_tip_angle_radius_centered_on_hook_path"
    );
    emit_arc_annotation(
      id="hook_tip_angle_extent",
      label="hook_tip_angle_extent",
      value=hook_tip_angle,
      points=annotation_hook_tip_angle_points,
      basis="hook_tip_angle_arc_on_hook_path"
    );
  }
}

emit_snap_gadget_hook_annotations();
zrot(180) up(_threads_side_offset) xrot(90)
      diff() {
        zrot(90)
          snap_threads(threads_height=snap_thickness, threads_cfg=_threads_cfg, text_cfg=_text_cfg);
        up(thread_join_overlap) {
          fwd(_threads_side_offset - body_width / 2)
            down(final_stem_length - EPS) xrot(-90)
                tag_diff("", remove="rm0") path_sweep(sweep_profile, path=path_merge_collinear(turtle(hook_path)), scale=[final_thickness_scale, 1]) {
                    attach("end", "top")
                      offset_sweep(offset_sweep_profile, height=tip_rounding_radius + EPS, bottom=os_circle(r=tip_rounding_radius), quality=256);
                    attach(TOP, BOTTOM, shiftout=-artifact_cutoff_depth)
                      tag("rm0") cuboid([100, 100, 10]);
                  }
          diff("rm2") {
            fwd(_threads_side_offset - body_width / 2)
              down(artifact_cutoff_depth / 2) zrot(180) xrot(180)
                    join_prism(fillet_sweep_profile, base="plane", length=final_stem_length, base_fillet=prism_fillet, overlap=thread_join_overlap) {
                      up(EPS) tag_diff(tag="rm2", remove="rm1")
                          cuboid([100, 100, prism_fillet], anchor=TOP) {
                            tag("rm1") cuboid([body_thickness, body_width, final_stem_length + EPS * 2], chamfer=final_side_chamfer, edges="Z", anchor=TOP);
                            tag("rm1") back(_threads_side_offset - body_width / 2 + 0.1)
                                cyl(l=final_stem_length + EPS * 2, d=_threads_connect_diameter, anchor=TOP);
                          }
                    }
            tag_diff(tag="rm2", remove="rm1")
              cyl(l=hook_stem_length, d=max(body_thickness, body_width, _threads_connect_diameter) * 2, anchor=TOP)
                attach(CENTER, CENTER, inside=true)
                  tag("rm1") cyl(l=hook_stem_length + EPS * 2, d=_threads_connect_diameter);
          }
        }
        tag("remove") fwd(_threads_side_offset - EPS) cuboid([500, 500, 500], anchor=BACK);
      }

function calculate_overlap_chamfer(rect_width, rect_height, circ_diameter) =
  let (
    arg1 = max(0, circ_diameter ^ 2 / 4 - rect_width ^ 2 / 4),
    arg2 = max(0, circ_diameter ^ 2 / 4 - rect_height ^ 2 / 4),
    chamf1 = rect_height / 2 - sqrt(arg1),
    chamf2 = rect_width / 2 - sqrt(arg2),
  ) max(0, chamf1, chamf2);
