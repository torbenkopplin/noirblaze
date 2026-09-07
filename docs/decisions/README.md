# Decisions

One file per decision, dated, with the measurement that settled it. Append-only:
a decision that turns out wrong gets a new entry that supersedes it rather than
an edit that hides it.

Format and reasoning borrowed wholesale from
[cachyos-hyprland-dots](https://github.com/torbenkopplin/cachyos-hyprland-dots)
`docs/decisions/`, which this repository was extracted from and which explains
better than this one can why the **Settled against** sections are the
load-bearing half.

## The log

| # | Decision | Settled |
|---|---|---|
| 001 | [Adaptive, because the glass is not a level — it is a lottery](001-adaptive-because-the-glass-is-not-constant.md) | 2026-09-05 |
| 002 | [The ramp ceiling is a fixed table, and its job is to refuse](002-the-ramp-ceiling-is-a-table.md) | 2026-09-05 |
| 003 | [Ramp, then opacity, then the blur; then refuse](003-the-knob-order.md) | 2026-09-05 |
| 004 | [`dist/` assumes one number, and it is not a colour](004-what-dist-assumes.md) | 2026-09-05 |
| 005 | [The accent keeps `#ff0088`, at a stated 3:1](005-the-accent-keeps-its-colour.md) | 2026-09-05 |
| 006 | [A background is solved too, and it is capped by what sits on it](006-a-surface-is-solved-too.md) | 2026-09-07 |

## Settled against, in one place

| Not doing | Because | Where |
|---|---|---|
| Deriving the ramp from the wallpaper | The backdrop cancels out of every contrast constraint, so the ramp is a property of the palette. Only the opacity is adaptive | [001](001-adaptive-because-the-glass-is-not-constant.md) |
| A generated Lua ramp that nvim loads at runtime | Same reason. There is nothing for it to learn, and a seam that is never exercised is a seam that is broken | [001](001-adaptive-because-the-glass-is-not-constant.md) |
| "Each role stays N steps below the role above" | `dim3` and `dim4` are two bytes apart, so any N ≥ 3 declares the shipped theme in violation of itself before the solver runs | [002](002-the-ramp-ceiling-is-a-table.md) |
| Lowering the terminal's own background below `#121212` | The strongest lever there is — 14 bytes of T at α = 0.80 — but it is also ANSI 0, `mOnPrimary`, `cursorText` and `selectionFg`, and some TUIs paint text in ANSI 0 | [003](003-the-knob-order.md) |
| Estimating the backdrop from a whole-image mean | A window samples the wallpaper behind itself. Measured, the brightest window-sized tile runs ~50 levels above the image mean — median 153 against 101 | [004](004-what-dist-assumes.md) |
| Lifting the accent to 4.5:1 | It needs T ≤ 29, which caps lift at 11 against a `LIFT_MIN` of 12. With the hue held it becomes `#ff4fad`, a pastel | [005](005-the-accent-keeps-its-colour.md) |
| Substituting the accent above a backdrop threshold | The theme's identity colour would change with the wallpaper | [005](005-the-accent-keeps-its-colour.md) |
| One global floor for every surface | Only `bg2` had actually inverted, but lifting it alone puts `CursorLine` two bytes from `Visual`, so a selection on the current line disappears. A layer stack moves as a stack | [006](006-a-surface-is-solved-too.md) |
| Solving a surface by luminance like everything else | `bg2` at byte 33 under a composited background of 36 takes the dark-on-light branch and comes out `#161616` — visible, and the layer order inverted | [006](006-a-surface-is-solved-too.md) |
| Deriving the ANSI greens from the editor greys | It produces a grey-green and breaks `git diff` and `ls`. Asserted against, not merely avoided | [005](005-the-accent-keeps-its-colour.md) |

## Adding one

Next number, `NNN-short-kebab-title.md`, and a line in both tables above if it
settles something against. `build/check-contrast` does not police this;
`.github/workflows/ci.yml` runs a link check that does.
