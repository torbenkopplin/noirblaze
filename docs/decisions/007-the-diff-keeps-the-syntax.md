# 007 — The diff keeps the syntax colours

**Settled 2026-11-10** after reading pull requests in diffview. Status: in force.

`DiffAdd`, `DiffChange` and `DiffText` set a background and no foreground, the
way `Visual` always has. `DiffDelete` is unchanged.

## The defect

In diff mode a foreground on a diff group replaces the syntax colour of every
character on the line. `DiffAdd` was pink on `bg3` and `DiffChange` white on
`bg3`, so new code in a side-by-side diff came out as one solid pink block and
changed code as one solid white block, with no keywords, strings or comments
told apart. That is the code a review is about.

## What replaced it

| group | before | after |
|---|---|---|
| `DiffAdd` | `pink` on `bg3` | `bg3` |
| `DiffChange` | `white` on `bg3` | `bg2` |
| `DiffText` | `white` on `dim1` | `bg3` |
| `DiffDelete` | `pink` on `bg3` | unchanged |

Without a foreground, `DiffAdd` and `DiffChange` on the same shade would only
differ by context, so `DiffChange` moves to the `CursorLine` shade and the
changed span inside it (`DiffText`) to the panel shade. That is the same
1.16:1 step decision 006 keeps between the current line and a selection.

`DiffDelete` keeps its pink because it paints no code: it is the filler on the
side of a diff that has no line. It also keeps `bg3` pinned at `#3a3a3a`
together with `Error`, `Todo` and `VisualNOS`, so no surface moved.

## The cost, measured

The syntax colours are solved to clear their floor exactly at T. A surface is
lighter than T by construction, so the dimmest of them — `dim1` through `dim4`,
which the `aa` solve merges at `#8b8b8b` — falls short of 4.5:1 on any of them:

| surface | groups | dim band | pink |
|---|---|---|---|
| `bg2` `#303030` | `CursorLine`, `DiffChange` | 3.87:1 | 3.52:1 |
| `bg3` `#3a3a3a` | `Visual`, `DiffAdd`, `DiffText` | 3.34:1 | 3.04:1 |
| `dim1` `#606060` | (`DiffText`, rejected) | 1.85:1 | 1.68:1 |

This was already true of the current line and every selection. It was never
measured, because a background-only group has no foreground to check.
`build/check-contrast` now has a **show-through** check: it prints the shortfall
from the text floor on each surface drawn under the buffer's code, and fails
when that code drops under the non-text floor or the accent under its own.

## Settled against

- **Keeping a foreground on the diff groups.** It is the defect.
- **Dropping only the foreground and leaving `DiffText` on `dim1`.** Comments,
  strings and types would sit at 1.85:1 inside every changed span. The
  show-through check fails on it.
