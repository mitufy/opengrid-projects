A place to store my OpenSCAD models for openGrid.

# How to use:
I recommend installing **OpenSCAD** and the **BOSL2 library** on your computer to generate 3D models locally using the `.scad` files. This is faster and more reliable than rendering online. However, if you prefer a simpler method, you can just use the customizer on the **MakerWorld** model pages.

* **OpenSCAD Snapshot:** The stable version is currently outdated; the Snapshot version is recommended. Find it here: [openscad.org/downloads.html#snapshots](https://openscad.org/downloads.html#snapshots)
* **BOSL2 Library:** Files and installation instructions can be found here: [github.com/BelfrySCAD/BOSL2](https://github.com/BelfrySCAD/BOSL2)


After installing and opening OpenSCAD, go to **Edit -> Preferences -> Advanced** and ensure the **3D Rendering Backend** is set to **"Manifold."** This significantly shortens rendering times. 

While there, you can also go to **Edit -> Preferences -> 3D Print -> Local Application** and input the path to your slicer. This allows you to press **F8** to send a model directly to your slicer, which can be quite convenient.

---

## openConnect
Inspired by David's MultiConnect, openConnect is a connector system designed specifically for openGrid. It is backwards compatible with MultiConnect while offering multiple improvements, including more printing orientations, a smaller footprint, and support for Vase Mode.

#### openconnect [(online)](https://makerworld.com/en/models/2257440-openconnect-opengrid-s-own-connector-system)
This file contains most code for openConnect. Its customizer options are primarily used to generate grids of openConnect slots (regular and vase mode) that can be attached to other models.

#### openconnect_vasemode_container [(online)](https://makerworld.com/en/models/2257502-openconnect-vase-mode-container-generator)
A container generator utilizing the openConnect system. Designed to be printed in **Vase Mode**, it offers fast print times, low filament usage, and a striking appearance when used with transparent filament. 
**Customizable:** size, line width, tilt angle, surface texture.

#### openconnect_drawer [(online)](https://makerworld.com/en/models/2257496-openconnect-drawer-generator)
A drawer generator that creates drawer shells, containers, stopper clips. Depending on the slot positions chosen, the drawer can be wall-mounted or underdesk mounted.
**Customizable:** size, slot positions, wall patterns (solid/honeycomb), and compartments.

#### openconnect_drawer_label [(online)](https://makerworld.com/en/models/2257496-openconnect-drawer-generator)
A label generator for the openConnect drawer. 
**Customizable:** style (Emboss/Flush/Deboss), text, and fonts (including emojis).

#### openconnect_sturdy_shelf [(online)](https://makerworld.com/en/models/2257523-openconnect-sturdy-shelf-generator)
A wall-mounted shelf generator. It is "sturdy" because it is designed to be printed on its side, which eliminates the most common failure point in 3D prints: layer line separation. 
**Customizable:** type (standard/slim), size, thickness, truss length, edge styles, and surface textures.

#### openconnect_sturdy_hook [(online)](https://makerworld.com/en/models/2257476-openconnect-sturdy-hook-generator)
A hook generator for openGrid. Like the sturdy shelf, it is printed on its side for maximum strength. Note its minimum width is 20mm. For thinner hooks, see `opengrid_framefit_hook_new` below.
**Customizable:** size, radius, thickness, tip angle, and thickness scaling. 

---
## openGrid Snaps and Framefit
Snaps and framefit models, which attach to the openGrid board directly.

#### opengrid_parametric_snap [(online)](https://makerworld.com/en/models/1680432-opengrid-snap-generator)
A generator for openGrid snaps and openConnect connectors. This file includes recreations of official snaps, as well as **self-expanding snaps**, openConnect snaps, and screws (available in regular and folded versions). Most parameters are exposed, making it ideal for experimenting with snap geometry.

#### opengrid_expanding_snap [(online)](https://makerworld.com/en/models/1412027-opengrid-self-expanding-snap)
A simplified version of the parametric snap generator, focused solely on the **self-expanding snap**. Expand distance can be adjusted to suit different filaments.

#### opengrid_framefit_hook_new [(online)](https://makerworld.com/en/models/1586090-opengrid-framefit-hook-generator)
A generator for hooks that attach to the frame of an openGrid board, inspired by David’s [minimal hook](https://www.printables.com/model/1217962-opengrid-minimal-hook). Size, fillet, angle are all customizable.

---
## Snap Gadgets
A series of gadgets that attach to the openGrid board via snaps. These models are designed for space efficiency and low filament usage, while still being decently strong. **Recommended for use with self-expanding snaps.**

#### opengrid_snap_gadget_clip [(online)](https://makerworld.com/en/models/1817059-opengrid-gadget-generic-holder-clip-generator)
A generator for gadget clips that function as generic holders. Includes a tapered front tip for easier insertion and an optional knurling pattern for extra grip.
**Customizable:** size, shape (circular/rectangular/elliptic), entry size, orientation, and knurling pattern.

#### opengrid_snap_gadget_hook [(online)](https://makerworld.com/en/models/1771774-opengrid-snap-gadget-hook-generator)
A generator for gadget hooks, ideal for hanging items under a desk (useful for Underware users).
**Customizable:** size, shape (straight/centered/loop), angle.

#### opengrid_snap_gadget_plier_holder [(online)](https://makerworld.com/en/models/1817025-opengrid-gadget-plier-holder-generator)
A simple generator for plier holders.
**Customizable:** size, plier count, spring hole.

---
### Other

#### coin_hex_bit [(online)](https://makerworld.com/en/models/1412021-multiconnect-coin-screwdriver-6-35mm-hex-bit)
A generator for a "coin screwdriver" hex bit. Often used for installing self-expanding snaps, but customizable to fit various coin-slot geometries.

---

**License:**
* The **openConnect system** is licensed under **CC-BY 4.0**.
* All **other customizable models** are licensed under **CC-BY-SA 4.0**.

Feel free to use the code; feedback and suggestions are always welcome.