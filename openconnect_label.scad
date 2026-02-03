/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

This model is intended to be used with openConnect models.
openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
*/

include <BOSL2/std.scad>

/*[Main Settings]*/
//"Emboss" and "Deboss" can be printed in two colors by manually changing filaments. "Flush" requires an automatic system such as bambulab's AMS.
label_text_style = "Emboss"; // [Emboss, Flush, Deboss]
label_left_text = "Tools";
//Default font for the right is Emoji. You can change it in settings below.
label_right_text = "🛠️";

/*[Left Text]*/
left_text_font = "Noto Sans"; // font
left_font_size = 5.4;
//Offset the outline of the text, making it thicker.
left_text_bolden = 0.05;//0.05
//Increase or decrease the spacing between each letter.
left_letter_spacing = 1; //0.01
//Left text position offset in x and y.
left_text_position_offset = [0, 0]; //0.2

/*[Right Text]*/
right_text_font = "Noto Emoji"; // font
right_font_size = 6.2;
//Offset the outline of the text, making it thicker.
right_text_bolden = 0.05;//0.05
//Increase or decrease the spacing between each letter.
right_letter_spacing = 1; //0.01
//Right text position offset in x and y.
right_text_position_offset = [0, 0]; //0.2

/*[Label Size]*/
label_width = 48;
label_height = 10;
label_thickness = 1; //0.1

/*[Advanced]*/
//Fill all gaps in text, usually used on Emoji.
right_text_filled = false;
left_text_filled = false;
emboss_text_thickness = 0.6;
deboss_text_thickness = 0.2;
flush_text_thickness = 0.4;

/*[Hidden]*/
$fa = 1;
$fs = 0.4;
eps = 0.005;

text_edge_offset = 3;
left_text_font_str = str(left_text_font);
right_text_font_str = str(right_text_font);
// left_text_font_str = str_join([str(right_text_font), "style=Bold"]);
left_text_metrics = textmetrics(text=label_left_text, font=left_text_font_str, size=left_font_size, valign="center", halign="center");
right_text_metrics = textmetrics(text=label_right_text, font=right_text_font_str, size=right_font_size, valign="center", halign="center");

module text_object(extrude_depth = label_thickness) {
  union() {
    left(label_width / 2 - left_text_metrics.size.x / 2 - text_edge_offset)
      right(left_text_position_offset[0]) back(left_text_position_offset[1])
          linear_extrude(extrude_depth) {
            if (left_text_filled)
              offset(r=left_text_bolden) fill() text(text=label_left_text, font=left_text_font_str, size=left_font_size, valign="center", halign="center", spacing=left_letter_spacing);
            else
              offset(r=left_text_bolden) text(text=label_left_text, font=left_text_font_str, size=left_font_size, valign="center", halign="center", spacing=left_letter_spacing);
          }
    if (label_right_text != "") {
      right(label_width / 2 - right_text_metrics.size.x / 2 - text_edge_offset)
        right(right_text_position_offset[0]) back(right_text_position_offset[1])
            linear_extrude(extrude_depth) {
              if (right_text_filled)
                offset(r=right_text_bolden) fill() text(text=label_right_text, font=right_text_font_str, size=right_font_size, valign="center", halign="center", spacing=right_letter_spacing);
              else
                offset(r=right_text_bolden) text(text=label_right_text, font=right_text_font_str, size=right_font_size, valign="center", halign="center", spacing=right_letter_spacing);
            }
    }
  }
}
module label_body() {
  difference() {
    color("black") diff()
        cuboid([label_width, label_height, label_text_style == "Deboss" ? label_thickness - deboss_text_thickness : label_thickness], chamfer=0.4, edges="Z", $fn=64, anchor=BOTTOM) {
          edge_mask([BOTTOM])
            chamfer_edge_mask(chamfer=0.2);
          corner_mask([BOTTOM])
            chamfer_corner_mask(chamfer=0.4);
        }
    if (label_text_style == "Flush")
      up(label_thickness - flush_text_thickness) text_object(label_thickness + eps);
  }
}
module label_text() {
  if (label_text_style == "Deboss") {
    up(label_thickness - deboss_text_thickness)
      difference() {
        color("white") cuboid([label_width, label_height, deboss_text_thickness], chamfer=0.4, edges="Z", $fn=64, anchor=BOTTOM);
        text_object(deboss_text_thickness + eps);
      }
  } else {
    color("white") up(label_text_style == "Emboss" ? label_thickness - eps : label_thickness - flush_text_thickness)
        text_object(label_text_style == "Emboss" ? emboss_text_thickness : flush_text_thickness);
  }
}

label_body();
label_text();
