include <BOSL2/std.scad>

/*[Main Settings]*/
//Emboss and Deboss can be printed in two colors by manually changing filament. Flush requires an automatic system such as bambulab's AMS.
label_text_style = "Emboss"; // [Emboss,Flush,Deboss]
label_left_text = "Tools";
//Default font for the right is Emoji. You can change it with settings below.
label_right_text = "🛠️";

/*[Left Text Settings]*/
left_text_font = "Noto Sans"; // font
left_font_size = 5.4;
left_edge_offset = 3; //0.2

/*[Right Text Settings]*/
right_text_font = "Noto Emoji"; // font
right_font_size = 6.2;
right_edge_offset = 3; //0.2

/*[Advanced Settings]*/
left_text_filled = false;
right_text_filled = false;
label_width = 38;
label_height = 10.4;
label_thickness = 1.2; //0.1

/*[Hidden]*/
$fa = 1;
$fs = 0.4;
eps = 0.005;

left_text_metrics = textmetrics(text=label_left_text, font=str(left_text_font), size=left_font_size, valign="center", halign="center");
right_text_metrics = textmetrics(text=label_right_text, font=str(right_text_font), size=right_font_size, valign="center", halign="center");

module label_text(extrude_depth = label_thickness) {
  union() {
    left(label_width / 2 - left_text_metrics.size.x / 2 - left_edge_offset) linear_extrude(extrude_depth) {
        if (left_text_filled)
          fill() text(text=label_left_text, font=str(left_text_font), size=left_font_size, valign="center", halign="center");
        else
          text(text=label_left_text, font=str(left_text_font), size=left_font_size, valign="center", halign="center");
      }
    if (label_right_text != "") {
      right(label_width / 2 - right_text_metrics.size.x / 2 - right_edge_offset)
        linear_extrude(extrude_depth) {
          if (right_text_filled)
            fill() text(text=label_right_text, font=str(right_text_font), size=right_font_size, valign="center", halign="center");
          else
            text(text=label_right_text, font=str(right_text_font), size=right_font_size, valign="center", halign="center");
        }
    }
  }
}

difference() {
  color("black") diff() cuboid([label_width, label_height, label_text_style == "Deboss" ? label_thickness-0.2 : label_thickness], chamfer=0.4, edges="Z", $fn=64, anchor=BOTTOM) {
        edge_mask([BOTTOM])
          chamfer_edge_mask(chamfer=0.2);
        corner_mask([BOTTOM])
          chamfer_corner_mask(chamfer=0.4);
      }
  if (label_text_style == "Flush")
    label_text(label_thickness + eps);
}
if (label_text_style == "Deboss")
  difference() {
    up(label_thickness-0.2)
      color("white") cuboid([label_width, label_height, 0.2], chamfer=0.4, edges="Z", $fn=64, anchor=BOTTOM);
    label_text();
  }
if (label_text_style != "Deboss")
  color("white") up(label_text_style == "Emboss" ? label_thickness - eps : 0) label_text(label_text_style == "Emboss" ? 0.6 : label_thickness);
