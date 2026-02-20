/* 
Licensed Creative Commons Attribution 4.0 International

Created by mitufy. https://github.com/mitufy

openConnect is a connector system designed for openGrid. https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system
openGrid is created by David D: https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem.
Inspired by David's multiConnect: https://www.printables.com/model/1008622-multiconnect-for-multiboard-v2-modeling-files.
*/

/* [Plate Settings] */
plate_size_unit = "mm"; //[grid:Grid Count, mm:Millimeter]
//Depending on the plate_size_unit selected, you can input number either in grids or in millimeters.
plate_horizontal_size = 84;
plate_vertical_size = 56;
//You can set this to 0 if your model already has a wall and you don't want to thicken it. Does not affect Negative slots.
plate_extra_thickness = 0.5;
//Slot alignment applies when the plate size is entered in millimeters and is not divisible by the tile_size (28mm).
plate_slot_alignment = "Center"; //["Center", "Top", "Bottom", "Left", "Right"]
plate_corner_rounding = "None"; //["None", "Chamfer", "Fillet"]
plate_corner_rounding_size = 0;

/* [Slot Settings] */
//"Standard" to add to models. "Negative" to subtract from models. "Vase Mode" to add to specific models designed for vase mode.
slot_type = "slot"; //[slot:Standard, negslot:Negative, vase:Vase Mode]
//A slot is generated for every tile by default.
slot_position = "All"; //["All", "Staggered", "Edge Rows", "Edge Columns", "Corners"]
//Adding locking mechanism to more slots makes the fit tighter, but also more difficult to install.
slot_lock_distribution = "Corners"; //["All", "Staggered", "Corners", "Top Corners", "None"]
//Entry ramp direction can matter in tight spaces. When printing the slots on the side, place the locking mechanism side closer to the print bed.
slot_entryramp_flip = false;
//For vase mode slots. This value should match the slicer's linewidth setting when printing in vase mode.
vase_linewidth = 0.6;
//Increase clearances if the slots feel too tight. Reduce it if they are too loose.
slot_side_clearance = 0.1; //0.01
slot_depth_clearance = 0.1; //0.01
//Ensures minimum feature width for 3d printing. "Both" is default for compatibility, though only one (or none) may be needed depending on orientation.
slot_edge_feature_widen = "Both"; //[Both, Top, Side, None]
//Minimum width for bridges under slot_edge_feature_widen. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_bridge_min_width = 0.8; //0.01
//Minimum width for walls under slot_edge_feature_widen. Default is suitable for 0.4mm nozzles, consider increasing when using a larger nozzle.
slot_edge_wall_min_width = 0.6; //0.01

/* [Hidden] */
//putting the include statement here, so is_undef() function in the library can access customizer values.
include <include/openconnect_lib.scad>

slot_lock_side = "Left";
final_plate_width = max(1, plate_size_unit == "mm" ? plate_horizontal_size : plate_horizontal_size * tile_size);
final_plate_h_grids = max(1, plate_size_unit == "mm" ? floor(plate_horizontal_size / tile_size) : plate_horizontal_size);
final_plate_height = max(1, plate_size_unit == "mm" ? plate_vertical_size : plate_vertical_size * tile_size);
final_plate_v_grids = max(1, plate_size_unit == "mm" ? floor(plate_vertical_size / tile_size) : plate_vertical_size);
final_plate_thickness = slot_type == "negslot" ? eps : max(eps, slot_type == "vase" ? plate_extra_thickness : ocslot_total_height + plate_extra_thickness);
final_plate_alignment =
  plate_slot_alignment == "Center" ? CENTER
  : plate_slot_alignment == "Top" ? BACK
  : plate_slot_alignment == "Bottom" ? FRONT
  : plate_slot_alignment == "Left" ? LEFT : RIGHT;

//BEGIN generation
down(final_plate_thickness == eps ? eps : 0) diff()
    hide("hidden") tag(final_plate_thickness == eps ? "hidden" : "")
        cuboid([final_plate_width, final_plate_height, final_plate_thickness], anchor=BOTTOM + FRONT + LEFT) {
          if (plate_corner_rounding != "None" && plate_corner_rounding_size > 0)
            edge_mask("Z") {
              if (plate_corner_rounding == "Chamfer")
                chamfer_edge_mask(chamfer=plate_corner_rounding_size);
              if (plate_corner_rounding == "Fillet")
                rounding_edge_mask(r=plate_corner_rounding_size);
            }
          if (slot_type == "slot")
            attach(TOP, TOP, align=final_plate_alignment, inside=true)
              tag("remove") openconnect_slot_grid(grid_type="slot", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, tile_size=tile_size, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=eps);
          else if (slot_type == "negslot")
            attach(TOP, BOTTOM, align=final_plate_alignment)
              tag("") openconnect_slot_grid(grid_type="slot", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, tile_size=tile_size, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=0);
          else if (slot_type == "vase")
            attach(TOP, BOTTOM, align=final_plate_alignment)
              tag("") openconnect_slot_grid(grid_type="vase", horizontal_grids=final_plate_h_grids, vertical_grids=final_plate_v_grids, tile_size=tile_size, slot_position=slot_position, slot_lock_distribution=slot_lock_distribution, slot_lock_side=slot_lock_side, slot_entryramp_flip=slot_entryramp_flip, excess_thickness=0);
        }

//END generation
