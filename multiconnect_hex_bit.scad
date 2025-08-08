/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openGrid and Multiconnect is created by David. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>

tip_slot_height = 2.8;
tip_slot_width = 14;
tip_slot_thickness = 2.1;
tip_slot_radius = tip_slot_height / 2 + tip_slot_width ^ 2 / (8 * tip_slot_height);

hex_rod_width = 6.3;
hex_rod_height = 13;
hex_rod_bottom_chamfer = 0.4;
hex_rod_to_tip_height = 10;
tip_flat_width = 18;
tip_flat_height = 2;

yrot(180)down(hex_rod_height) {
  regular_prism(6, id=hex_rod_width, h=hex_rod_height, chamfer2=hex_rod_bottom_chamfer, anchor=BOTTOM);
  hull() {
    regular_prism(6, id=hex_rod_width, h=0.01, anchor=TOP);
    down(hex_rod_to_tip_height) cuboid([tip_flat_width, tip_slot_thickness, tip_flat_height], anchor=BOTTOM);
  }
  down(hex_rod_to_tip_height) difference() {
      down(tip_slot_height) xrot(90) cyl(r=tip_slot_radius, h=tip_slot_thickness, $fn=64, anchor=FRONT);
      cuboid([30, 10, 30], anchor=BOTTOM);
    }
}
