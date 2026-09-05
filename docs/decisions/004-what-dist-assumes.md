# 004 — `dist/` assumes one number, and it is not a colour

**Settled 2026-09-05.** Status: in force.

The committed output assumes a backdrop of **153**, and that assumption reaches
exactly one line of one file: `terminal = 0.87` in `dist/glass.conf.sample`.

Every colour in `dist/` is independent of it, for the reason in
[001](001-adaptive-because-the-glass-is-not-constant.md): the backdrop cancels
out of the contrast constraints, so the ramp is a function of T and T is a
property of the palette.

## Why 153 and not the mean of a wallpaper

Because a window does not sit on the mean of a wallpaper. `blur.xray` is off and
the columns tile, so a terminal samples the image **behind itself**. Measured
over the 41 ultrawide wallpapers, cropped to 3440×1440 the way
`fill_mode = "crop"` presents them:

| | median | p90 | max |
|---|---|---|---|
| whole displayed crop | 101 | 170 | 197 |
| **brightest window-sized tile** | **153** | **212** | **238** |

**A whole-image mean understates the backdrop a window actually sits on by
about 50 levels**, and it errs in the direction that hurts. So the assumption is
the median brightest tile: the wallpaper is as likely to be brighter as darker,
at the worst place you can put a window on it.

`magick identify -format "%[fx:mean*255]"` is doubly wrong for this — it is the
whole image *and* an unweighted RGB mean rather than luma. On
`wallhaven-1klxl3.png` it reads 78.5 where BT.601 luma is 70.4.

## The model was checked against the screen

Predicting a backdrop from an image file is a model, and a model that has not
been compared with a photograph of the actual screen is a guess.
`noct-check glass-visible`, 2026-09-05, wallpaper `wallhaven-6lqwyq.jpg` on
DP-3:

| quantity | predicted from the file | measured on screen | error |
|---|---|---|---|
| backdrop under the window | 139 (centre tile of the displayed crop) | **137.4** | **1.6 levels, 1.2%** |
| backdrop sd | 57.4 (ImageMagick gaussian σ = 8) | **68.7** | 20%, the model under-reads |
| effective α | 0.55 (configured) | 0.546 | 0.7% |

The crop-and-tile model predicts the backdrop to within two levels. The
ImageMagick gaussian is not Hyprland's dual-kawase and under-reads the spatial
variation by a factor of **1.20**, which is the calibration applied wherever sd
is estimated from a file rather than measured.

Predicting from the whole crop would have given 142.0 and from the raw file
147.8, against 137.4 measured. The tile is the right unit.
