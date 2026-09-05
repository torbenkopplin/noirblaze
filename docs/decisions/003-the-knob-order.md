# 003 — Ramp, then opacity, then the blur; then refuse

**Settled 2026-09-05.** Status: in force.

| # | knob | costs | bounded by | lives in |
|---|---|---|---|---|
| 1 | the ramp | the theme's value hierarchy | the ceiling table (002) | this repo |
| 2 | `terminal` opacity | lift, and structure | `LIFT_MIN` below, `STRUCTURE_MIN` above | `glass.conf`, live |
| 3 | `blur_brightness` | the photograph | decision 011 in the dots repo | `glass.conf`, live |
| 4 | refuse | — | — | `build/solve`'s exit status |

**The ramp first**, because it is the only knob that fixes the opaque case and
the only one a stranger with no Noctalia gets. `dist/` has to be right with no
solver run at all, so the ramp cannot be the adaptive half.

**Opacity second**, because glassiness bought through `terminal` costs no
contrast at all — kitty fades its background and leaves glyphs alone, which is
the whole finding of decision 010 in the dots repo — and it is live, per-scheme
and per-machine reversible.

**`blur_brightness` third, downward only, and only above the backdrop where
`STRUCTURE_MIN` caps α.** Decision 011 fixed it at 1.00 because *lowering it on
a dark wallpaper destroys the lift*: measured lift 3, "nothing on screen saying
the glass was on". That reasoning is about dark wallpapers. The case here is the
opposite one — a backdrop bright enough that α has to rise past what leaves any
structure visible — and `glass.local.conf.example` already proposes exactly this
move for exactly this symptom ("a dimmer backdrop, for a screen where the
wallpaper reads too bright through a terminal"). So 011 keeps its force and
gains a stated exception rather than being reversed.

Measured, it is rarer than it looked: at the sd of **68.7** this session
recorded, `STRUCTURE_MIN` allows α ≤ 0.94. It is the flattest tenth of the
library (calibrated sd ≈ 21, α ≤ 0.81) that reaches for this knob — six
wallpapers out of forty-one.

**Then refuse.** When all three are exhausted, `build/solve` prints which
constraint it broke and by how much, and yields **structure**, never contrast. A
wallpaper with nothing behind the window to see is a property of the image; text
you cannot read is a defect.

## Settled against

**Lowering the terminal's own background below `#121212`.** This is the
strongest lever on the table and it is not being pulled. Since
`T = own × α + backdrop × (1 − α)`, darkening `own` lowers T *and* raises lift —
both directions help — and at α = 0.80 an `own` of `#000000` is worth 14 bytes
of T, about the difference between T = 46 and T = 32.

Not done because `terminal.background` is also `mOnPrimary`, `cursorText`,
`selectionFg` and ANSI 0, and ANSI 0 is painted as a foreground by some TUIs.
Recorded here so it is not re-derived from scratch; it is the first place to
look if the floors ever need to come down.
