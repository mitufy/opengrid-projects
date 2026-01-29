/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid and Multiconnect is created by David. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>

/* [Hex Rod Settings] */
hex_rod_height = 13;
hex_rod_to_coin_transition_height = 10;

coin_tip_height = 2.6;
coin_tip_width = 13;
coin_thickness = 2;//0.05

/* [Advanced Settings] */
flat_tip_width = 17;
flat_tip_height = 2;//0.2
hex_rod_width = 6.3;//0.05

/* [Hidden] */
$fa = 1;
$fs = 0.4;
eps = 0.005;
hex_rod_bottom_chamfer = 0.4;
coin_radius = coin_tip_height / 2 + coin_tip_width ^ 2 / (8 * coin_tip_height);

yrot(180) down(hex_rod_height) {
    regular_prism(6, id=hex_rod_width, h=hex_rod_height, chamfer2=hex_rod_bottom_chamfer, anchor=BOTTOM);
    hull() {
      regular_prism(6, id=hex_rod_width, h=0.01, anchor=TOP);
      down(hex_rod_to_coin_transition_height) cuboid([flat_tip_width, coin_thickness, flat_tip_height], anchor=BOTTOM);
    }
    down(hex_rod_to_coin_transition_height) difference() {
        down(coin_tip_height) xrot(90) cyl(r=coin_radius, h=coin_thickness, $fn=128, anchor=FRONT);
        cuboid([500, 500, 500], anchor=BOTTOM);
      }
  }
