# 001 — Adaptive, because the glass is not a level — it is a lottery

**Settled 2026-09-05** by measurement. Status: in force.

The opacity is derived from the wallpaper actually on screen. The colours are
not: they are static, committed, and correct on every wallpaper.

## Why not static everything

The obvious reason to go adaptive is contrast, and it is the weaker one. The
strong reason is that **the shipped glass is not one level.**

`lift = (backdrop − own colour) × (1 − α)`. At the `terminal = 0.55` the dots
repo ships, measured across the 41 ultrawide wallpapers in the library:

| backdrop (brightest window-sized tile) | 38 | 101 | 153 | 212 | 238 |
|---|---|---|---|---|---|
| lift at α = 0.55 | **9.0** | 37.4 | 60.8 | 87.3 | **99.0** |

Ten to one, and the bottom end is **below the `LIFT_MIN = 12` the dots repo's
own harness enforces**. On the darkest wallpapers in the folder the frosted
glass is not visible at all, and on the brightest it is a wash.

[Decision 011 over there](https://github.com/torbenkopplin/cachyos-hyprland-dots)
tuned the blur against a lift of 17, on a wallpaper of mean luma 99 whose
backdrop reached 72. That was a correct measurement of one image.

**So the adaptive layer does not make the desktop less glassy. It makes it the
same every time.** At the shipped profile it holds the lift at 18 — one above
the number that was tuned for and liked.

## Why the colours are static anyway

Substituting the composite into the lift:

```
seen_bg = own_bg × α + backdrop × (1 − α)
lift    = seen_bg − own_bg
```

so writing **T** for the composited background byte, `lift = T − own_bg` and
**the backdrop cancels**. Every contrast constraint is a constraint on T, T is a
property of the palette, and the backdrop enters exactly once:

```
α = (backdrop − T) / (backdrop − own_bg)
```

The ramp is therefore a function of T alone and does not depend on the wallpaper
at all. Only the opacity does.

Three things fall out of that, and they are why the design is small:

- **`dist/` is exact, not a worst-case guess.** The committed colours are the
  answer for every wallpaper, not an approximation of it.
- **Neovim has nothing to learn at runtime.** No generated Lua to load, no
  signal to catch, no drift between the editor and the terminal.
- **Hysteresis is nearly a non-question.** `dα/db = (T − own)/(backdrop − own)²`
  — at backdrop 153 and T = 36 that is 0.0009 per level, so a one-level change
  in the wallpaper moves α by a thousandth. See 004.

## What it costs

A stranger who clones this and runs no solver gets the colours exactly right and
one opacity that assumes a backdrop — stated in `dist/glass.conf.sample`, which
is the only file in the repository that assumes anything about a wallpaper.
