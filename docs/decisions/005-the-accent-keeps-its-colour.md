# 005 — The accent keeps `#ff0088`, at a stated 3:1

**Settled 2026-09-05.** Status: in force.

`pink` is never solved. It takes the non-text floor, and that is an exception
written down rather than a class it naturally belongs to.

## The number that settles it

For `#ff0088` to clear **4.5:1** the composited background must be at or below
byte **29**. Since `lift = T − own_bg` and `own_bg` is 18, that caps the lift at
**11** — against the `LIFT_MIN = 12` the dots repo's harness enforces.

**An AA accent and visible glass are mutually exclusive by one level of 255.**

## Why not lift it

Because it is chromatic and the ramp is grey. Lifting `#ff0088` to 4.5:1 at the
shipped T, with the hue held, gives **`#ff4fad`** — HSL lightness 50% → 65%, a
pastel. The theme's identity is a near-black ground, a monochrome body and one
hot pink; a pale pink is not that accent, it is a different one.

## Why not substitute it above a backdrop threshold

Because the accent would then change colour when the wallpaper changed. A
solver that "fixes" the accent is a solver that deletes it, and it would do so
on a schedule the user did not choose.

## Why the exception costs nothing

At 3:1 the accent allows T ≤ 58.8, i.e. a lift of 40.8. The grey roles hold T at
36 long before that, so **the accent is never the binding constraint** — and at
T = 36 it lands at **4.14:1**, close enough to AA that the exception is a
formality on the shipped setting rather than a licence.

If the floors ever come down far enough for the accent to bind, that is the
signal to reach for the terminal-background lever recorded in
[003](003-the-knob-order.md), not to repaint the accent.

## The greens are a different exception, and stronger

`green` (`#00ff77`) and `green_bright` (`#2eff8f`) are not solved either, and
not because they cannot be. At **13.89:1** and **14.11:1** opaque — and 4.05:1
against a backdrop of 212 — they never come near a floor. They are held fixed
because a solver that lifts everything by rule is exactly the thing that would
one day derive them from the editor greys, produce a grey-green, and quietly
break `git diff` and `ls`. `build/check-contrast green` asserts, on every
profile and in every class, that they came through untouched.
