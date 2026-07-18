## Branch purpose

This branch is dedicated to the annotation image generation utility. It turns my openGrid models into annotated technical images using OpenSCAD, Blender, and Pillow. Most of the utility was created with OpenAI Codex.

This utility can be used on other OpenSCAD models, but the .scad file would need to be modified to emit values and geometry-aware anchors.

# OpenGrid Projects

A place to store my OpenSCAD models for openGrid.

## Quick Setup

To generate the models locally, download the repository and install **OpenSCAD** and the **BOSL2 library** on your computer. This is faster and more reliable than rendering online. However, if you prefer a simpler method, you can just use the customizer on the MakerWorld model pages.

- **OpenSCAD Snapshot:** The stable version is outdated. Use the Snapshot version here: [openscad.org/downloads.html#snapshots](https://openscad.org/downloads.html#snapshots)
- **BOSL2 Library:** Files and installation instructions can be found here: [github.com/BelfrySCAD/BOSL2](https://github.com/BelfrySCAD/BOSL2)

After installing OpenSCAD, go to **Edit -> Preferences -> Advanced** and ensure the 3D Rendering Backend is set to **"Manifold."** This significantly shortens rendering times.

## [openConnect](https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system) Models

Inspired by David's [MultiConnect](https://www.printables.com/model/1074671-raised-multiconnect-generic-connector-for-multiboa), [openConnect](https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system) is a connector system designed specifically for openGrid. It is backwards compatible with MultiConnect while offering multiple improvements, including more printing orientations, a smaller footprint, and support for Vase Mode.

### openconnect_plate.scad[(online)](https://makerworld.com/en/models/2257440-openconnect-opengrid-s-own-connector-system)

<p><img src="images/openconnect_plate_default.jpg" width="360" alt="openConnect standard slot plate"> <img src="images/openconnect_plate_neg.jpg" width="360" alt="openConnect negative slot plate"></p>

Generates grids of openConnect slots (default, negative and vase mode) that can be attached to other models. The reusable openConnect implementation lives in the `lib/` files.

### openconnect_sturdy_hook.scad [(online)](https://makerworld.com/en/models/2257476-openconnect-sturdy-hook-generator)

<p><img src="images/openconnect_sturdy_hook_default.jpg" width="360" alt="openConnect sturdy hook default render"> <img src="images/openconnect_sturdy_hook_gallery.jpg" width="360" alt="openConnect sturdy hook gallery render"></p>

A hook generator for openGrid. Like the sturdy shelf, it is printed on its side for maximum strength. Recommended minimum width is 20mm. For thinner hooks, see `opengrid_framefit_hook` below.

Customizable: shape, size, radius, thickness, truss, tip sliceoff, thickness scaling.

### openconnect_sturdy_shelf.scad [(online)](https://makerworld.com/en/models/2257523-openconnect-sturdy-shelf-generator)

<p><img src="images/openconnect_sturdy_shelf_default.jpg" width="360" alt="openConnect sturdy shelf default render"> <img src="images/openconnect_sturdy_shelf_gallery.jpg" width="360" alt="openConnect sturdy shelf gallery render"></p>

A wall-mounted shelf generator. It is "sturdy" because it is designed to be printed on its side, which eliminates the most common failure point in 3D prints: layer line separation.

Customizable: type (standard/slim), size, thickness, truss length, edge styles, surface textures.

### openconnect_general_holder.scad [(online)](https://makerworld.com/en/models/2257483-openconnect-general-holder-generator)

<p><img src="images/openconnect_general_holder_default.jpg" width="360" alt="openConnect general holder default render"> <img src="images/openconnect_general_holder_gallery.jpg" width="360" alt="openConnect general holder gallery render"></p>

A general-purpose openConnect holder generator for rectangular, circular, or elliptic compartments.

Customizable: compartment shape and count, holder size, tilt angle, front opening, taper, and slot settings.

### openconnect_vasemode_container.scad [(online)](https://makerworld.com/en/models/2257502-openconnect-vase-mode-container-generator)

<p><img src="images/openconnect_vasemode_container_default.jpg" width="360" alt="openConnect vase mode container default render"> <img src="images/openconnect_vasemode_container_gallery.jpg" width="360" alt="openConnect vase mode container gallery render"></p>

A container generator utilizing the openConnect system. Designed to be printed in **Vase Mode**, it offers fast print times, low filament usage, and a striking appearance when used with transparent filament.

Customizable: rectangular or rounded shape, size, line width, tilt angle, surface texture.

Rounded mode cuts an unshifted elliptical linear sweep to create its flat back. A prismoid is added only when back tilt is enabled, filling the gap to the tilted mounting face without distorting the texture.

### openconnect_drawer.scad [(online)](https://makerworld.com/en/models/2257496-openconnect-drawer-generator)

<p><img src="images/openconnect_drawer_default.jpg" width="360" alt="openConnect drawer default render"> <img src="images/openconnect_drawer_gallery.jpg" width="360" alt="openConnect drawer gallery render"></p>

A drawer generator that creates drawer shells, containers, stopper clips. Depending on the slot positions chosen, the drawer can be wall-mounted or underdesk mounted.

Customizable: size, slot positions, wall patterns (solid/honeycomb), and drawer compartments.

### openconnect_label.scad [(online)](https://makerworld.com/en/models/2257496-openconnect-drawer-generator)

A label generator for the openConnect drawer and vasemode container.

Customizable: style (Emboss/Flush/Deboss), text, and fonts (including emojis).

### openconnect_clamshell_holder.scad [(online)](https://makerworld.com/en/models/2257487-openconnect-clamshell-holder-generator)

<p><img src="images/openconnect_clamshell_holder_default.jpg" width="360" alt="openConnect clamshell holder default render"> <img src="images/openconnect_clamshell_holder_gallery.jpg" width="360" alt="openConnect clamshell holder gallery render"></p>

A clamshell holder generator for larger items such as power strips or small devices. Usually used with Underware.

Customizable: item size, slot placement, front opening, side openings, and generated holder half.

### openconnect_gridfinity_shelf.scad [(online)](https://makerworld.com/en/models/3055852-openconnect-gridfinity-shelf-generator)

<p><img src="images/openconnect_gridfinity_shelf_default.jpg" width="360" alt="openConnect Gridfinity shelf default render"> <img src="images/openconnect_gridfinity_shelf_gallery.jpg" width="360" alt="openConnect Gridfinity shelf gallery render"></p>

A wall-mounted openConnect shelf with an integrated lightweight Gridfinity-compatible baseplate.

Customizable: Gridfinity unit count, baseplate style, side/front rim and lip, magnet layout.

## openGrid Snaps and Framefit

Snaps and framefit models, which attach to the openGrid board directly.

### opengrid_parametric_snap.scad [(online)](https://makerworld.com/en/models/1680432-opengrid-snap-generator)

<p><img src="images/opengrid_parametric_snap_default.jpg" width="360" alt="openGrid parametric snap default render"></p>

A generator for openGrid snaps and openConnect connectors. This file includes recreations of official snaps, as well as self-expanding snaps, openConnect snaps, and screws (available in regular and folded versions). Most parameters are exposed, making it ideal for experimenting with snap geometry.

### opengrid_expanding_snap.scad [(online)](https://makerworld.com/en/models/1412027-opengrid-self-expanding-snap)

<p><img src="images/opengrid_expanding_snap_default.jpg" width="360" alt="openGrid expanding snap default render"> <img src="images/opengrid_expanding_snap_installed.jpg" width="360" alt="openGrid expanding snap alternate render"></p>

A simplified version of the parametric snap generator, focused solely on the self-expanding snap. Expand distance can be adjusted to suit different filaments.

### opengrid_framefit_hook.scad [(online)](https://makerworld.com/en/models/1586090-opengrid-framefit-hook-generator)

<p><img src="images/opengrid_framefit_hook_default.jpg" width="360" alt="openGrid framefit hook default render"> <img src="images/opengrid_framefit_hook_side.jpg" width="360" alt="openGrid framefit hook side render"></p>

A generator for hooks that attach to the frame of an openGrid board, inspired by David’s [minimal hook](https://www.printables.com/model/1217962-opengrid-minimal-hook). Size, fillet, angle are all customizable.

## Snap Gadgets and Utility

A series of gadgets that attach to the openGrid board via snaps. These models are designed for space efficiency and low filament usage, while still being decently strong. **Recommended for use with self-expanding snaps.**

### opengrid_snap_gadget_clip.scad [(online)](https://makerworld.com/en/models/1817059-opengrid-gadget-generic-holder-clip-generator)

<p><img src="images/opengrid_snap_gadget_clip_default.jpg" width="360" alt="openGrid snap gadget clip default render"> <img src="images/opengrid_snap_gadget_clip_gallery.jpg" width="360" alt="openGrid snap gadget clip gallery render"></p>

A generator for gadget clips that function as generic holders. Includes a tapered front tip for easier insertion and an optional knurling pattern for extra grip.

Customizable: size, shape (circular/rectangular/elliptic), entry size, orientation, and knurling pattern.

### opengrid_snap_gadget_hook.scad [(online)](https://makerworld.com/en/models/1771774-opengrid-snap-gadget-hook-generator)

<p><img src="images/opengrid_snap_gadget_hook_default.jpg" width="360" alt="openGrid snap gadget hook default render"> <img src="images/opengrid_snap_gadget_hook_gallery.jpg" width="360" alt="openGrid snap gadget hook gallery render"></p>

A generator for gadget hooks, ideal for hanging items under a desk (useful for Underware users).

Customizable: size, shape (straight/centered/loop), angle.

### opengrid_snap_gadget_plier_holder.scad [(online)](https://makerworld.com/en/models/1817025-opengrid-gadget-plier-holder-generator)

<p><img src="images/opengrid_snap_gadget_plier_holder_default.jpg" width="360" alt="openGrid snap gadget plier holder default render"> <img src="images/opengrid_snap_gadget_plier_holder_gallery.jpg" width="360" alt="openGrid snap gadget plier holder gallery render"></p>

A simple generator for plier holders.

Customizable: size, plier count, spring hole.

### coin_hex_bit.scad [(online)](https://makerworld.com/en/models/1412021-multiconnect-coin-screwdriver-6-35mm-hex-bit)

<p><img src="images/coin_hex_bit_hex_default.jpg" width="360" alt="coin hex bit first use photo"> <img src="images/coin_hex_bit_hex_default2.jpg" width="360" alt="coin hex bit second use photo"></p>

A generator for a "coin screwdriver" hex bit. Often used for installing self-expanding snaps, but customizable to fit various coin-slot geometries.

## Repository Notes

Following a recent refactor, the codebase is split into modular library files. Standalone files for publishing can be bundled from this repository using [`openscad-toolkit`](https://github.com/zing3d-labs/openscad-toolkit) by `zing3d-labs`. A huge thanks to the creator of that tool.

Feel free to use the code; feedback and suggestions are always welcome.

## License

- The openConnect connector libraries and connector/snap generators are licensed under **CC-BY 4.0**.
- Most holder, drawer, shelf, hook, label, and gadget model generators are licensed under **CC-BY-SA 4.0**.
