function _fmt_annotation_vec(point) = str(point[0], ",", point[1], ",", point[2]);
function _fmt_annotation_vec_list(points, index=0) =
  index >= len(points) ? "" :
  str(index == 0 ? "" : ";", _fmt_annotation_vec(points[index]), _fmt_annotation_vec_list(points, index + 1));

function annot_translate(point, offset) = [
  point[0] + offset[0],
  point[1] + offset[1],
  point[2] + offset[2],
];
function annot_xrot(point, angle) = [
  point[0],
  point[1] * cos(angle) - point[2] * sin(angle),
  point[1] * sin(angle) + point[2] * cos(angle),
];
function annot_yrot(point, angle) = [
  point[0] * cos(angle) + point[2] * sin(angle),
  point[1],
  -point[0] * sin(angle) + point[2] * cos(angle),
];
function annot_zrot(point, angle) = [
  point[0] * cos(angle) - point[1] * sin(angle),
  point[0] * sin(angle) + point[1] * cos(angle),
  point[2],
];
function annot_translate_points(points, offset) = [for (point = points) annot_translate(point, offset)];
function annot_xrot_points(points, angle) = [for (point = points) annot_xrot(point, angle)];
function annot_yrot_points(points, angle) = [for (point = points) annot_yrot(point, angle)];
function annot_zrot_points(points, angle) = [for (point = points) annot_zrot(point, angle)];
function annot_transform_point(point, translate=[0, 0, 0], rotate=[0, 0, 0]) =
  annot_translate(annot_zrot(annot_yrot(annot_xrot(point, rotate[0]), rotate[1]), rotate[2]), translate);
function annot_transform_points(points, translate=[0, 0, 0], rotate=[0, 0, 0]) =
  [for (point = points) annot_transform_point(point, translate=translate, rotate=rotate)];

function _fmt_context_values(names, values, index=0) =
  index >= len(names) ? "" :
  str(index == 0 ? "" : ";", names[index], "=", values[index], _fmt_context_values(names, values, index + 1));

module emit_dimension_annotation(id, label, axis, value, start, end, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=dimension",
      "|label=", label,
      "|axis=", axis,
      "|value=", value,
      "|start=", start[0], ",", start[1], ",", start[2],
      "|end=", end[0], ",", end[1], ",", end[2],
      "|basis=", basis
    ));
}

module emit_context_values(id, names, values) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=context",
      "|values=", _fmt_context_values(names, values)
    ));
}

module emit_feature_annotation(id, label, value, anchor, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=feature",
      "|label=", label,
      "|value=", value,
      "|anchor=", anchor[0], ",", anchor[1], ",", anchor[2],
      "|basis=", basis
    ));
}

module emit_radius_annotation(id, label, value, center, edge, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=radius",
      "|label=", label,
      "|value=", value,
      "|center=", center[0], ",", center[1], ",", center[2],
      "|edge=", edge[0], ",", edge[1], ",", edge[2],
      "|basis=", basis
    ));
}

module emit_arc_annotation(id, label, value, points, basis) {
  if (emit_annotation_metadata)
    echo(str(
      "OPENGRID_ANNOTATION_V1|",
      "id=", id,
      "|kind=arc",
      "|label=", label,
      "|value=", value,
      "|start=", points[0][0], ",", points[0][1], ",", points[0][2],
      "|end=", points[len(points) - 1][0], ",", points[len(points) - 1][1], ",", points[len(points) - 1][2],
      "|points=", _fmt_annotation_vec_list(points),
      "|basis=", basis
    ));
}
