# 002 — The ramp ceiling is a fixed table, and its job is to refuse

**Settled 2026-09-05.** Status: in force.

`palette.toml` names, per role, the brightest role it may be lifted to. The
ceiling never shapes the output. It exists to **detect** the case where a
contrast floor has climbed past what the theme can absorb, so `build/solve`
refuses with a number instead of quietly flattening.

## Why not "N steps below the role above"

Because the theme's roles are not evenly spaced, and a relative rule cannot know
which of them are already one band:

| pair | gap |
|---|---|
| `dim3` → `dim4` | **2 bytes** |
| `dim2` → `dim3` | 5 |
| `dim1` → `dim2` | 32 |
| `mid` → `fg4` | 19 |

Any N ≥ 3 declares the shipped theme in violation of itself before the solver
has done anything. `dim2`, `dim3` and `dim4` span seven bytes and are visually
one level already; `dim1` sits 32 below them and is genuinely another. Which
roles share a band is authorial knowledge, and the table is where it is written
down.

The ceiling is named as a **role**, not a byte — `dim1.ceiling = "mid"` — so
re-spacing the palette re-derives every ceiling for free.

## What it caught

Nothing yet, which is the point of having it. `build/check-contrast ceilings`
asserts all nine on every run and every profile, so the first time a floor rises
past a band boundary the build says which role and by how much.

## The related thing it does not do

It does not prevent roles **merging**. At the shipped profile `dim1` through
`dim4` all solve to `#8b8b8b`, and that is the documented cost — see 003.
Merging is allowed; swapping places is not, and
`build/check-contrast hierarchy` is the assertion that they never do.
