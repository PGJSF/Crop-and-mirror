# Crop & Mirror

[English](README.md) | [한국어](README.ko.md)

A Godot editor plugin that crops a region from an image and exports it as a PNG. Optionally, it mirrors the region horizontally and/or vertically, so a single corner can be expanded into a full symmetric image such as a dialog box or UI frame. With mirroring turned off, it works as a simple crop tool.

Target version: **Godot 4.7**.

## Features

- Select a region on a zoomable, pannable canvas, or enter exact pixel values.
- Mirror the region horizontally, vertically, or both, from any of the four corners.
- Adjustable overlap (0-32 px) where the mirrored halves meet in the center.
- Live preview and output size display before exporting.
- Export to PNG next to the source image, or to any `res://` path.
- Load images with a file dialog or by dragging them from the FileSystem dock.
- English and Korean interface, switchable at any time.

## Installation

1. Copy the `addons/crop_and_mirror` folder into your project's `res://addons/` folder.
2. Open **Project > Project Settings > Plugins** and enable **Crop & Mirror**.
3. Open the **Crop & Mirror** panel at the bottom of the editor.

## Quick start

1. Click **Load Image** and choose a source image. You can also drag an image file from the FileSystem dock onto the canvas or the preview area.
2. Drag on the left canvas to select the region you want to use. After loading, the top-left quarter of the image is selected by default.
3. Set **Source Corner** to the corner of the final image that the selected region represents.
4. Toggle **Mirror H** and **Mirror V**, and check the result in **Live Preview**.
5. Check the **Output Path** and click **Export Dialog Box Image**.

For example, if you have the top-left corner of a dialog box, select that region, set **Top-Left** as the source corner, and enable both mirror options.

To crop without mirroring, turn off both **Mirror H** and **Mirror V**. The exported image is then just the selected region.

## Canvas controls

| Input | Action |
| --- | --- |
| Left mouse drag | Select a new region |
| Left mouse drag on a red handle | Resize the selection on that edge |
| Right mouse drag | Pan the canvas |
| Mouse wheel | Zoom around the cursor |
| Select All | Select the entire source image |
| Reset Zoom | Reset the zoom to 100% and restore the canvas position |

## Region and mirror settings

| Setting | Description |
| --- | --- |
| X, Y | Top-left coordinates of the selection in the source image, in pixels. |
| Width, Height | Size of the selection. Type values for precise control. |
| Source Corner | Top-left, top-right, bottom-left or bottom-right. The selection is normalized to the top-left orientation before it is mirrored. |
| Mirror H | Mirror the selection horizontally. |
| Mirror V | Mirror the selection vertically. |
| Horizontal Overlap | Number of pixels the left and right halves overlap in the center (0-32). Disabled when Mirror H is off. |
| Vertical Overlap | Number of pixels the top and bottom halves overlap in the center (0-32). Disabled when Mirror V is off. |
| Output Size | Final size of the image generated with the current settings. |

If the selection is `W x H` and both overlaps are `0`, the output size with both mirror options enabled is `2W x 2H`. For example, a `64 x 32` region becomes a `128 x 64` image.

With both mirror options enabled, the output size is `(2W - horizontal overlap) x (2H - vertical overlap)`. A `64 x 32` region with a horizontal overlap of `2` and a vertical overlap of `0` produces a `126 x 64` image.

The effective overlap is limited to at least 1 pixel less than the selection size on that axis. Overlap is not applied on an axis whose mirror option is off, but the value is kept and reused when the mirror option is turned back on. Overlapping pixels are overwritten by the mirrored copy that is drawn later.

## Language

Choose **English** or **한국어** from the dropdown at the right side of the top toolbar.

- English is the default.
- Buttons, settings, hints, status messages and the bottom panel title change immediately.
- Success and error messages that are already displayed are refreshed in the selected language.
- The image, selection, zoom, mirror settings and output path are preserved.
- The choice is stored in the project's editor metadata and persists after restarting the editor.
- This only affects the plugin, not the language of the whole Godot editor.

## Loading and exporting

- The file dialog and drag and drop from the FileSystem dock both support PNG, WebP, JPG, JPEG, BMP and SVG.
- The output format is PNG. A `.png` extension is appended automatically if the output path does not have one.
- By default, the output path is `<source file name>_full.png` in the same folder as the source image. Example: `res://UI/dialog_corner.png` becomes `res://UI/dialog_corner_full.png`.
- Missing output folders are created. The saved image is scanned or reimported by the editor.
- An output path identical to the source image is blocked. An existing file at a different path is overwritten.

## Troubleshooting

| Message / symptom | What to check |
| --- | --- |
| The panel is not visible | Make sure **Crop & Mirror** is enabled in the Plugins tab. |
| Cannot load the image | Check the file path, the extension and whether the image file is valid. |
| No image selected | Load a source image first. |
| The selection is empty | Select a region on the canvas and check the width and height. |
| The output path is empty | Enter an output file path such as `res://UI/dialog_full.png`. |
| The output path is the same as the source | Use a file name different from the source image. |
| Saving failed | Read the error in the status message and check write permission of the output folder. |

## License

Released under the [MIT License](LICENSE). Redistributions must include the copyright notice and permission notice from the LICENSE file.
