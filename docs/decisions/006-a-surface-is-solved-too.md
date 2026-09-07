# 006 — A background is solved too, and it is capped by what sits on it

**Settled 2026-09-07** by measurement, after the adaptive opacity shipped.
Status: in force.

`bg2`, `bg3` and `dim1` used as backgrounds are lifted to keep the separation
the palette declares for them — measured against the **composited** background
rather than against `#121212`.

## The regression this fixes

kitty makes a cell translucent only when its background matches the default
background. A panel does not: `CursorLine` is `#212121` and is painted opaque,
so it did not move when the thing underneath it did.

| | designed | at T = 84 | at T = 36 |
|---|---|---|---|
| `CursorLine` vs the buffer | 1.16:1 | 2.13:1 | **1.04:1** |

At the shipped profile the cursor line ended up **three levels darker** than the
buffer around it. It had crossed over and vanished. This is a regression the
adaptive opacity introduced, not an old defect — at the old fixed `terminal =
0.55` the composited background was 84 and the band was clearly visible.

Nothing caught it because a background-only group has no foreground, and every
check in `build/check-contrast` was a check on a foreground.

## Where the floor comes from

Each surface keeps **its own** declared separation, read out of the static
palette: `bg2` is 1.163:1 above `bg`, `bg3` is 1.461:1, `dim1` is 2.435:1. No
number is typed for this, and re-spacing the palette re-derives all three.

A single global floor was tried first — the smallest of the three, 1.163 — on
the grounds that only `bg2` was actually broken. It lifts `bg2` to `#303030`
and leaves `bg3` at `#323232`, **two bytes apart**, so selecting text on the
current line stops being visible. A layer stack has to move as a stack.

Surfaces are also solved **upward** unconditionally, unlike every other class.
Solved by luminance alone, `bg2` at byte 33 sitting under a composited
background of 36 takes the dark-on-light branch and comes out `#161616`:
visible again, and the layer order inverted.

## The cap, and the trade it makes

Lifting a surface can push a **fixed** foreground off its floor, and a fixed
foreground cannot follow — the accent is `#ff0088` by
[005](005-the-accent-keeps-its-colour.md) and a grey ramp cannot lift a hue.
Solved to its full declared 1.461:1, `bg3` lands at `#3f3f3f`, where pink is
**2.81:1** against the 3:1 the accent exception is stated at. `Error`, `Todo`,
`VisualNOS`, `DiffAdd` and `DiffDelete` all put pink on `bg3`.

So a surface rises no further than the dimmest thing pinned to it allows.
`bg3` stops at `#3a3a3a`, where pink is **3.04:1**, and reaches 1.36:1 against
the buffer instead of its declared 1.461. `build/check-contrast surfaces`
prints that shortfall and the reason rather than failing on it: it is a stated
trade between two floors, and the number is there to be argued with.

Only chromatic foregrounds pin a surface. A grey one is re-solved on that
surface and follows it up.

The cap is floored, not rounded. `maxbg` gave 58.8 for pink at 3:1, rounding
put the surface at 59, and pink came out at **2.99:1** — a hundredth under the
floor the cap exists to protect.

## What it costs

On a fully opaque terminal the committed values are more separated than the
palette designed: `CursorLine` reads 1.42:1 against `#121212` rather than 1.16.
That is the same trade every colour in `dist/` makes — solved for T = 36 and
therefore more contrasty than necessary when there is no glass — and it is the
one place where "more" is a visible change rather than a free improvement.

## Result

| layer | before | after | vs buffer | vs the layer below |
|---|---|---|---|---|
| `bg2` `CursorLine` | `#212121` | `#303030` | 1.04 → **1.18** | 1.18 |
| `bg3` `Visual`, `Pmenu` | `#323232` | `#3a3a3a` | 1.21 → **1.36** | 1.16 |
| `dim1` `PmenuSel`, `DiffText` | `#535353` | `#606060` | 2.02 → **2.47** | 1.81 |
