include <BOSL2/std.scad>

EPS = 0.005;
OG_TILE_SIZE = 28;
OG_STANDARD_THICKNESS = 6.8;
OG_LITE_THICKNESS = 4;
OG_LITE_BASIC_THICKNESS = 3.4;

OG_SNAP_WIDTH = 24.8;
OG_SNAP_CORNER_OUTER_DIAGONAL = 2.7 + 1 / sqrt(2);
OG_SNAP_CORNER_CHAMFER = OG_SNAP_CORNER_OUTER_DIAGONAL * sqrt(2);
OG_SNAP_CORNER_INNER_DIAGONAL = OG_SNAP_WIDTH * sqrt(2) / 2 - OG_SNAP_CORNER_OUTER_DIAGONAL;
OG_SNAP_TEXT_FONT = "Merriweather Sans:style=Bold";
OG_SNAP_EMOJI_FONT = "Noto Emoji";
OG_SNAP_BLUNT_TEXT = "🔓";
OG_SNAP_DIRECTIONAL_ARROW_TEXT = "🔺";

OG_SNAP_THREADS_PROFILE = [
  [-1.25 / 3, -1 / 3],
  [-0.25 / 3, 0],
  [0.25 / 3, 0],
  [1.25 / 3, -1 / 3],
];
OG_SNAP_THREADS_DIAMETER = 16;
OG_SNAP_THREADS_CLEARANCE = 0.5;
OG_SNAP_THREADS_COMPATIBILITY_ANGLE = 53.5;

OG_SNAP_THREADS_PITCH = 3;
OG_SNAP_THREADS_SIDE_OFFSET = 1.4;
OG_THREADS_CONNECT_OFFSET = 1.5;
OG_MIN_WALL_WIDTH = 0.8;

OG_SNAP_TEXT_SIZE = 4;
OG_GADGET_TEXT_SIZES = [OG_SNAP_TEXT_SIZE, OG_SNAP_TEXT_SIZE];
OG_GADGET_TEXT_FONTS = [OG_SNAP_EMOJI_FONT, OG_SNAP_TEXT_FONT];
OG_GADGET_TEXT_FILLS = [true, false];
OG_GADGET_TEXT_POSITIONS = [[2.4, 0], [-2.4, 0]];

OG_SNAP_TEXT_SIZES = [OG_SNAP_TEXT_SIZE, OG_SNAP_TEXT_SIZE, 3.6];
OG_SNAP_TEXT_FONTS = [OG_SNAP_EMOJI_FONT, OG_SNAP_TEXT_FONT, OG_SNAP_EMOJI_FONT];
OG_SNAP_TEXT_FILLS = [true, false, true];

OCHEAD_BOTTOM_HEIGHT = 0.6;
OCHEAD_TOP_HEIGHT = 0.6;
OCHEAD_MIDDLE_HEIGHT = 1.4;
OCHEAD_LARGE_RECT_WIDTH = 17;
OCHEAD_LARGE_RECT_HEIGHT = 10.6;
OCHEAD_LARGE_RECT_CHAMFER = 4;

OCHEAD_NUB_TO_TOP_DISTANCE = 7.2;
OCHEAD_NUB_DEPTH = 0.6;
OCHEAD_NUB_TIP_HEIGHT = 1.2;
OCHEAD_NUB_FILLET = 0.8;

OCHEAD_BACK_POS_OFFSET = 0.4;
OCHEAD_TOTAL_HEIGHT = OCHEAD_TOP_HEIGHT + OCHEAD_MIDDLE_HEIGHT + OCHEAD_BOTTOM_HEIGHT;
OCHEAD_MIDDLE_TO_BOTTOM = OCHEAD_LARGE_RECT_HEIGHT - OCHEAD_LARGE_RECT_WIDTH / 2 - OCHEAD_BACK_POS_OFFSET;

OCSLOT_MOVE_DISTANCE = 10.6;
OCSLOT_ONRAMP_CLEARANCE = 0.8;

// ── Configuration Structs ────────────────────────────────────────────────────

// Helper function to safely merge two structs or a struct and a flat override list
function _flatten_struct(s) = [for (i = [0:len(s) - 1], j = [0:1]) s[i][j]];
function struct_merge(struct_a, struct_b) =
  len(struct_b) == 0 ? struct_a
  : is_string(struct_b[0]) ? struct_set(struct_a, struct_b)
  : struct_set(struct_a, _flatten_struct(struct_b));

function text_cfg(
  texts = [],
  sizes = OG_GADGET_TEXT_SIZES,
  fonts = OG_GADGET_TEXT_FONTS,
  fills = OG_GADGET_TEXT_FILLS,
  pos_offsets = [[0, 0]],
  text_depth = 0.4,
  add_expand_distance_text = false
) =
  struct_set(
    [], [
      "texts",
      texts,
      "sizes",
      sizes,
      "fonts",
      fonts,
      "fills",
      fills,
      "pos_offsets",
      pos_offsets,
      "text_depth",
      text_depth,
      "add_expand_distance_text",
      add_expand_distance_text,
    ]
  );

module snap_text(
  text_cfg = [],
  snapbody_cfg = [],
  anchor = BOTTOM,
  spin = 0,
  orient = UP
) {
  _cfg = struct_merge(text_cfg(), text_cfg);
  _texts = struct_val(_cfg, "texts");
  _sizes = struct_val(_cfg, "sizes");
  _fonts = struct_val(_cfg, "fonts");
  _fills = struct_val(_cfg, "fills");
  _offsets = struct_val(_cfg, "pos_offsets");
  _depth = struct_val(_cfg, "text_depth");

  _text_count = len(_texts);
  if (_text_count > 0)
    attachable(anchor, spin, orient, size=[1, 1, _depth]) {
      tag_scope() down(_depth / 2)for (i = [0:_text_count - 1]) {
          if (_texts[i] != "") {
            _size = len(_sizes) > i ? _sizes[i] : _sizes[0];
            _font = len(_fonts) > i ? _fonts[i] : _fonts[0];
            _fill = len(_fills) > i ? _fills[i] : _fills[0];

            _offset = len(_offsets) > i ? _offsets[i] : _offsets[0];
            right(_offset[0]) back(_offset[1])
                linear_extrude(height=_depth + EPS) if (_fill)
                  fill() text(_texts[i], size=_size, anchor=str("center", CENTER), font=_font);
                else
                  text(_texts[i], size=_size, anchor=str("center", CENTER), font=_font);
          }
        }
      children();
    }
}

// ── Utility Functions & Modules ──────────────────────────────────────────────

// Returns true if the position [hgrid, vgrid] fits the description.
function is_grid_pos_described(hgrid, vgrid, max_hgrid, max_vgrid, description, except_pos = []) =
  let (
    is_exception = in_list([hgrid, vgrid], except_pos),
    is_stagger = hgrid % 2 == vgrid % 2,
    is_top_row = vgrid == 0,
    is_bottom_row = vgrid == max_vgrid - 1,
    is_left_column = hgrid == 0,
    is_right_column = hgrid == max_hgrid - 1,
    is_edge_row = is_top_row || is_bottom_row,
    is_edge_column = is_left_column || is_right_column,
    is_corner = is_edge_row && is_edge_column,
    is_top_corner = is_corner && is_top_row,
    is_bottom_corner = is_corner && is_bottom_row,
    matches_pattern = description == "All" || (description == "Staggered" && is_stagger) || (description == "Corners" && is_corner) || (description == "Top Corners" && is_top_corner) || (description == "Bottom Corners" && is_bottom_corner) || (description == "Edge Rows" && is_edge_row) || (description == "Edge Columns" && is_edge_column)
  ) !is_exception && matches_pattern;

// Returns true if the footprint at cp lies fully within limit_region.
function is_pos_shape_in_region(cp, footprint, limit_region) =
  let (
    result = [for (i = footprint) point_in_region(cp + i, limit_region) == 1]
  ) !in_list(list=result, val=false);

// Conditionally flips children along the given axis. If copy=true, keep the original.
module conditional_flip(axis = "X", coordinate = 0, copy = false, condition) {
  if (condition) {
    if (axis == "X")
      xflip(x=coordinate) tag_scope() children();
    else if (axis == "Y")
      yflip(y=coordinate) tag_scope() children();
    else if (axis == "Z")
      zflip(z=coordinate) tag_scope() children();
    if (copy)
      tag_scope() children();
  }
  else
    children();
}

// Conditionally cuts children to the given half-space along v.
module conditional_half(v = LEFT, pos_offset = 0, mask_size = 100, condition) {
  if (condition) {
    if (v == LEFT || v == RIGHT)
      half_of(v=v, cp=[pos_offset, 0, 0], s=mask_size) tag_scope() children();
    else if (v == FRONT || v == BACK)
      half_of(v=v, cp=[0, pos_offset, 0], s=mask_size) tag_scope() children();
    else if (v == TOP || v == BOTTOM)
      half_of(v=v, cp=[0, 0, pos_offset], s=mask_size) tag_scope() children();
    else
      half_of(v, cp=pos_offset == 0 ? [0, 0, 0] : pos_offset, s=mask_size) tag_scope() children();
  }
  else
    children();
}

module conditional_fold(body_thickness, fold_position = 0, fold_gap_width = 0.4, fold_gap_height = 0.2, fold_sliceoff = 0, mask_size = 100, condition = true) {
  if (condition) {
    back(fold_position) yrot(180) {
        xrot(-90, cp=[0, -fold_position, 0])
          difference() {
            children();
            fwd(fold_position) cuboid([mask_size, mask_size, mask_size], anchor=BACK);
          }
        fwd(fold_gap_width - EPS) up(fold_sliceoff)
            xrot(90, cp=[0, -fold_position, 0])
              difference() {
                children();
                fwd(fold_position + fold_sliceoff)
                  cuboid([mask_size, mask_size, mask_size], anchor=FRONT);
              }
        fwd(fold_gap_width) xrot(-90, cp=[0, -fold_position, 0])
            linear_extrude(fold_gap_width + EPS * 2) difference() {
                projection(cut=true)
                  down(0.01)
                    children();
                fwd(fold_position - fold_gap_height) rect([mask_size, mask_size], anchor=FRONT);
                fwd(fold_position) rect([mask_size, mask_size], anchor=BACK);
              }
      }
  }
  else
    children();
}
