# noirblaze — design

**Status: agreed 2026-09-05.** Nothing is implemented yet; this is what the
build will follow.

Three things were settled by the reader, and one by a measurement taken after
the first draft:

| | |
|---|---|
| the ramp | **two profiles.** `aa` is the default and what `dist/` ships; `noir` keeps the dim band and states its own ratios |
| the measurement | **taken first.** It moved the design — see §2.2 |
| `bright.green` | **a brighter sibling of `#00ff77`**, by the theme's own convention |

**What the measurement changed: T = 46 became T = 36.** The first draft rested
on decision 011's backdrop sd of 20, which was the only number available and
would have collapsed `Comment`, `String`, `Type`, `Include` **and** `Keyword`
into one grey. Measured on this session, sd is **68.7**. At T = 36 the theme
keeps nine distinct greys instead of five, and `Keyword` stays distinct from the
dim band. This is the whole reason the measurement was worth waiting for.

Every number here is computed or measured, and the method is named each time so
it can be checked. Where a number could not be got, it says so.

---

## 1. Six corrections to the brief

These change the design, so they come first.

**1.1 — Neovim is already transparent.** `nvimrc/init.lua:196-217` runs
immediately after `vim.cmd.colorscheme("noirblaze")` and sets `bg = "none"` on
twenty groups, `Normal` and `NormalNC` among them. The brief says nvim is
"currently unaffected, because `colors/noirblaze.lua` paints `Normal` with
`bg = c.bg`" — the colourscheme does, and the config then undoes it on the very
next line. So the editor composites against the wallpaper *today*: `LineNr` at
`bg3` `#323232` is **1.45:1** over a backdrop of 143. This is not a future risk
to design for, it is the current state.

**1.2 — The terminal block is not verbatim.** Upstream
`n1ghtmare/noirblaze-kitty` (fetched 2026-09-05, MIT, © 2023 Dimitar Dimitrov)
sets `color2 #ff0088` — its ANSI green is *pink*. The dots palette has
`"green": "#00ff77"`. Twenty-one of the twenty-two slots match upstream exactly;
that one does not. So the `_comment` header in
`config/noctalia/palettes/noirblaze.json` credits upstream for the single value
upstream does not have. `#00ff77` is the user's own work and must be attributed
as such — which is convenient, because it is also the one value the brief says
the solver may not touch.

The sibling inconsistency, unresolved: `color10` (`bright.green`) is still
`#fd319e`, pink, in both. `git diff` additions use ANSI 2 and are green;
`ls` executables use ANSI 10 and are pink. If "a real green makes `git diff` and
`ls` readable" is the reason `color2` was changed, `color10` was missed.

**1.3 — The nvim theme is a derivative work.** `n1ghtmare/noirblaze-vim` (MIT,
© 2025 Dimitar Dimitrov) declares the **identical set of fifteen colours** —
`#121212 #212121 #323232 #535353 #737373 #787878 #7a7a7a #949494 #a7a7a7
#b0b0b0 #b4b4b4 #d5d5d5 #f5f5f5 #ff0088 #ffffff` — under different names
(`gray_900`, `zinc_gray_600`, …). Of the 57 highlight groups present in both,
**55 carry the same colour**; the two that differ are `PmenuSel` and
`VertSplit`. 92 further groups (the whole `@*` treesitter set, `@lsp.*`,
diagnostics, devicons, the XML/HTML fallback) are the user's own. So the answer
to "are the nvim highlight groups the user's own work or derived from
something upstream" is: **the palette and the base groups are upstream's, the
modern half is the user's**, and MIT requires the notice be carried.

**1.4 — `nvim-pack-lock.json` is not tracked.** It is in `nvimrc/.gitignore`.
The brief says plugins are "pinned in `nvim-pack-lock.json`"; that pinning is
local to a machine. If this repo is to be pinned in a way that survives a clone,
the pin is a `version` field in the `vim.pack.add` spec, not the lock file.

**1.5 — The backdrop that matters is local, not global.** `blur.xray = false`
and the columns tile, so a terminal samples the wallpaper *behind itself*.
Measured over the 41 ultrawide wallpapers, cropped to 3440×1440 as
`fill_mode = "crop"` presents them, and reduced to window-sized tiles:

| | whole displayed crop | brightest window-sized tile |
|---|---|---|
| median | 101 | **153** |
| p90 | 170 | **212** |
| max | 197 | **238** |

The brief's suggested `magick identify -format "%[fx:mean*255]"` returns the
first column and **understates the backdrop a window actually sits on by about
50 levels at the median.** (It is also an unweighted RGB mean, not luma: on
`wallhaven-1klxl3.png` it reads 78.5 where BT.601 luma is 70.4.)

**1.6 — The shipped glass is not one level, it is a range of ten to one.**
`lift = (backdrop − own) × (1 − α)`. At the shipped `α = 0.55`, across the
measured library:

| backdrop | 38 | 101 | 153 | 212 | 238 |
|---|---|---|---|---|---|
| lift at α = 0.55 | **9.0** | 37.4 | 60.8 | 87.3 | **99.0** |

Decision 011 tuned the blur against a lift of 17, measured on a wallpaper of
mean luma 99 with the backdrop reaching 72. On the median wallpaper in the
library today the same settings deliver 61, and on the darkest they deliver 9 —
below the harness's own `LIFT_MIN = 12`. **Adaptive opacity is not "less glass".
It is the thing that makes the glass a constant instead of a lottery.** That is
the argument for the whole exercise, and it is stronger than the contrast one.

---

## 2. The problem has one variable

The brief frames this as a two-dimensional search over ramp and opacity. It is
not. Substituting the composite into the lift:

```
seen_bg = own_bg × α + backdrop × (1 − α)
lift    = seen_bg − own_bg
```

so, writing **T** for the composited background byte,

> **lift = T − own_bg = T − 18.**

The backdrop cancels. Every constraint in the brief is a constraint on **T
alone**:

| constraint | in terms of T |
|---|---|
| `LIFT_MIN = 12` | T ≥ 30 |
| a role at floor R must clear it | T ≤ maxT(role, R) |
| `STRUCTURE_MIN = 4` | sd × (1 − α) ≥ 4 |

and the backdrop enters exactly once, at the end:

```
α = (backdrop − T) / (backdrop − own_bg)
```

**Consequences.**

- The ramp is a function of T, and T is a property of the palette. **The ramp
  does not depend on the wallpaper at all.** Only the opacity does.
- `dist/` therefore needs no "worst-case backdrop assumption" for the colours.
  It is not an approximation of the adaptive answer, it *is* the answer, for
  every wallpaper. The backdrop assumption applies only to the one recommended
  opacity `dist/` ships for people with no solver.
- The solver is closed-form in one pass. No search, no bisection.

The contrast floor and the byte inversion are the brief's two formulas:
`L_fg ≥ R × (L_bg + 0.05) − 0.05`, then
`c = 1.055 × L^(1/2.4) − 0.055`. Verified against the brief's worked example:
Comment at T = 74 needs byte 184.7 → `#b9b9b9` ✓; capped at `mid` it needs
T ≤ 45.7 → α ≥ 0.776 at backdrop 143, lift 28.0 ✓.

### 2.1 The frontier

`minFG(T, R)` is the dimmest byte that clears floor R over composited background
T. This is the entire design space:

| T | lift | glass? | 4.5:1 text floor | 3:1 chrome floor |
|---|---|---|---|---|
| 18 (opaque) | 0 | no | `#7c7c7c` (124) | `#606060` (97) |
| 30 | 12 | **minimum** | `#858585` (133) | `#686868` (104) |
| 36 | 18 | yes | `#8a8a8a` (138) | `#6d6d6d` (109) |
| **46** | **28** | **yes** | **`#949494` (148)** | **`#787878` (118)** |
| 60 | 42 | yes | `#a5a5a5` (165) | `#858585` (133) |

Against the current ramp — `bg3` 50, `dim1` 83, `dim2` 115, `dim3` 120,
`dim4` 122, `mid` 148:

> **The whole dim band lies below the AA floor for its own background, at zero
> transparency.** Even opaque, 4.5:1 on `#121212` needs byte 124, and `dim1`
> through `dim4` are 83–122. The glass is not the cause. The glass moves the
> floor from 124 to 148.

So the loss the brief anticipated is real, unavoidable, and larger than the
transparency: **"comments recede" and "comments meet WCAG AA" are incompatible
in this theme at any opacity, including none.** A comment that recedes is a
comment at low contrast, and `dim1` at 2.44:1 is a deliberate aesthetic.

### 2.2 T = 36, and how the measurement settled it

The choice of T is capped from above by contrast and from below by
`STRUCTURE_MIN = 4`, since `structure = sd × (1 − α)`. Everything turns on sd,
and the only figure available when this was drafted was decision 011's **20**,
measured on a wallpaper of mean luma 99. That number chooses T = 46 and costs
the dim ramp entirely.

**Measured instead**, `noct-check glass-visible`, this session, 2026-09-05,
wallpaper `wallhaven-6lqwyq.jpg` on DP-3:

```
captures: configured 202.583, opaque 255, backdrop-only 139.732 (of 255)
backdrop 137.4 of 255 (variation 68.7), terminal effective opacity 0.55
lift 53.7 (want >= 12), structure 30.9 (want >= 4)
```

**sd is 68.7, not 20.** Decision 011's figure was a property of the wallpaper it
was taken on, not of the blur.

That also validates the model this design is built from, which the brief was
right to insist on:

| quantity | predicted from the file | measured on screen | error |
|---|---|---|---|
| backdrop under the window | 139 (centre tile of the displayed crop) | **137.4** | **1.6 levels, 1.2%** |
| backdrop sd | 57.4 (gaussian σ = 8) | **68.7** | 20%, model under-reads |
| effective α | 0.55 (configured) | 0.546 | 0.7% |

So the crop-and-tile model predicts the backdrop to within two levels, and the
ImageMagick gaussian under-reads sd by a factor of **1.20**, which is the
calibration applied to the library below. Note that predicting the backdrop from
the *whole* displayed crop would have given 142.0 against a measured 137.4, and
from the raw file 147.8 — the tile is the right unit, as §1.5 argued.

Calibrating the library by 1.20 and asking, per wallpaper, whether the α that
T demands is one that `STRUCTURE_MIN` still allows:

| T | lift | 4.5 floor | 3:1 floor | feasible, worst window position | median α | distinct greys kept |
|---|---|---|---|---|---|---|
| 30 | 12 | `#858585` | `#686868` | 29/41 (71%) | 0.84 | 9 |
| **36** | **18** | **`#8b8b8b`** | **`#6d6d6d`** | **35/41 (85%)** | **0.78** | **9** |
| 46 | 28 | `#949494` | `#767676` | 37/41 (90%) | 0.66 | 5 |

**T = 36.** It costs five percentage points of wallpaper feasibility against
T = 46 — two wallpapers out of forty-one — and buys back `Keyword` as a colour
distinct from `Comment`, `String` and `Type`, which is the main syntactic signal
in a monochrome theme. T = 30 buys nothing further and costs fourteen points.

Its lift is **18**, against the **17** decision 011 measured and shipped. Two
independent routes to the same level of glass.

The six infeasible wallpapers are the flattest ones — low sd, nothing behind the
window to see. That is a property of the image, not a failure of the solve, and
the solver says so rather than pretending otherwise.

### 2.3 The knobs, in order

| # | knob | costs | bounded by | lives in |
|---|---|---|---|---|
| 1 | **ramp** | the value hierarchy | the ceiling table (§4, Q3) | this repo |
| 2 | **`terminal` opacity** | lift, and structure | `LIFT_MIN` below, `STRUCTURE_MIN` above | `glass.conf`, live |
| 3 | **`blur_brightness`** | the photograph | decision 011 | `glass.conf`, live |
| 4 | **refuse** | — | — | the solver's exit code |

**Ramp first**, because it is the only knob that fixes the opaque case, and the
only one a stranger with no Noctalia gets. `dist/` has to be right with no
solver run at all, so the ramp cannot be the adaptive half.

**Opacity second**, because decision 010's whole finding is that glassiness
bought through `terminal` costs no contrast, and it is live, per-scheme, and
per-machine reversible.

**`blur_brightness` third, downward only, and only above the backdrop where
α is capped by structure.** Decision 011 fixed it at 1.00 because *lowering it
on a dark wallpaper destroys the lift* — measured lift 3. That reasoning does
not apply on a bright one, where the problem is the opposite, and
`glass.local.conf.example` already suggests exactly this move ("a dimmer
backdrop, for a screen where the wallpaper reads too bright through a
terminal"). So decision 011 stays in force and gains a stated exception rather
than being reversed.

**Then refuse.** Above backdrop ≈158 no setting satisfies contrast, lift and
structure together. The solver prints which constraint it broke and by how much,
and yields **structure**, never contrast. A theme that silently flattens is the
failure this whole exercise exists to prevent.

*Considered and not proposed:* lowering the terminal's own background below
`#121212`. `T = own × α + b(1 − α)`, so darkening `own` lowers T **and** raises
lift — at α = 0.80 an own of `#000000` is worth 14 bytes of T, about the
difference between T = 46 and T = 32. It is the strongest lever on the table.
It is not proposed for v1 because `terminal.background` is also `mOnPrimary`,
`cursorText`, `selectionFg` and ANSI 0, which some TUIs paint text in. Recorded
so it is not re-derived.

---

## 3. What actually changes

The `aa` profile at T = 36 — floors 4.5 text / 3.0 chrome / 3.0 accent — solved
as `fg = max(static, minFG(T, floor))`. Roles already above their floor are left
alone; nothing is brightened that did not have to be.

### 3.1 The terminal block barely moves

| slot | now | on `#121212` | becomes | at T = 36 |
|---|---|---|---|---|
| `color8` bright.black | `#737373` | **3.95** | `#8b8b8b` | 4.56 |
| `color6` normal.cyan | `#787878` | **4.24** | `#8b8b8b` | 4.56 |
| `color5` normal.magenta | `#7a7a7a` | **4.36** | `#8b8b8b` | 4.56 |
| `color2` normal.green | `#00ff77` | 13.89 | **untouched** | 11.51 |
| `color10` bright.green | `#fd319e` | 5.45 | **`#2eff8f`** | 11.69 |
| every other slot | | ≥ 5.00 | untouched | ≥ 4.14 |

**Three slots move for contrast**, and `bright.black` is the brief's "one that
bites hardest" — right: the fish prompt, `git diff` context, `ls`, `fzf`, `bat`
and `delta` all take it, and it moves 115 → 139. `bright.cyan` (`#919191`) and
`bright.magenta` (`#939393`) now clear the floor on their own and are left
alone, which T = 46 would not have allowed.

`normal.green` is never touched: 13.89:1 opaque, 11.51:1 at T = 36, and 4.05:1
even at a backdrop of 212. The solver has no reason to reach for it, and
`build/check-contrast` will assert that it did not.

**`bright.green` becomes `#2eff8f`** — agreed, and derived rather than picked.
Every normal/bright pair in this block is the same hue at higher HSL lightness,
and the deltas are `red` +9.2, `magenta` +9.8, `cyan` +9.8, `blue` +5.5. Applying
the `red` pair's own +9.2 to `#00ff77` gives `#2eff8f`. So ANSI 10 becomes a
green that reads as ANSI 2's bright sibling, `ls` agrees with `git diff`, and
the pair is built by the same rule as the five pairs around it. This is the
second deliberate departure from upstream (§1.2) and is attributed as the
user's, alongside `#00ff77`.

### 3.2 The editor is where the theme changes

| role | now | on `#121212` | becomes | at T = 36 | why |
|---|---|---|---|---|---|
| `LineNr`, `NonText` (`bg3`) | `#323232` | **1.46** | `#6d6d6d` | 3.00 | chrome, 3:1 |
| `WinSeparator`, `VertSplit`, `Conceal`, tag delimiters (`dim1`) | `#535353` | **2.44** | `#6d6d6d` | 3.00 | decoration, 3:1 |
| **`Comment`, `@comment`** (`dim1`) | `#535353` | **2.44** | **`#8b8b8b`** | 4.56 | text, 4.5:1 |
| `Include`, `StorageClass`, `@punctuation.*` (`dim2`) | `#737373` | **3.95** | `#8b8b8b` | 4.56 | text |
| `String`, `Character`, `Special` (`dim3`) | `#787878` | **4.24** | `#8b8b8b` | 4.56 | text |
| `Type`, `@type` (`dim4`) | `#7a7a7a` | **4.36** | `#8b8b8b` | 4.56 | text |
| `Keyword`, `Conditional` (`mid`) | `#949494` | 6.18 | **`#949494`** | 5.12 | **stays distinct** |
| `fg4` and above | | ≥ 7.79 | unchanged | ≥ 6.45 | already clear |
| accent (`pink`) | `#ff0088` | 5.00 | unchanged | 4.14 | Q2 |

**Nine distinct greys survive, out of twelve.** The three that merge are the dim
band: `dim1`, `dim2`, `dim3` and `dim4` all become `#8b8b8b`, and `bg3` joins
`dim1`-as-decoration at `#6d6d6d`.

So the loss is exactly one distinction — **comments stop being dimmer than
strings** — and it is unavoidable: `dim1` is 2.44:1 and the floor is 4.5:1 even
opaque (§2.1). What T = 36 saves, and T = 46 would not have, is `Keyword`
sitting nine bytes above the dim band, so keywords still read as keywords.

The `noir` profile keeps the dim band where it is and lifts only what is
invisible or inverting — see §8.

---

## 4. The open questions, answered

**Q1 — the non-text floor. → 3:1** (WCAG 1.4.11), for `LineNr`, `NonText`,
`WinSeparator`, `VertSplit`, `Conceal`, `IndentLine`, `PmenuThumb` and the
XML/HTML tag delimiters. At T = 36 that is `#6d6d6d`.
**With one promotion: `CursorLineNr` takes the 4.5 floor,** because the current
line's number is the one gutter figure that is actually read; the rest are
scanned past. Cost: `#8b8b8b` for one line, `#6d6d6d` for the others — a
distinction the theme already draws, and one the gutter needs more than ever now
that `bg3` has left 1.46:1.

**Q2 — the accent. → keep `#ff0088` exactly, at a stated 3:1 floor.** The
numbers that settle it:

- 4.5:1 requires **T ≤ 29**, hence **lift ≤ 11**, against `LIFT_MIN = 12`.
  **An AA accent and visible glass are mutually exclusive by one level of 255.**
- Lifting it to 4.5:1 at T = 46 with the hue held means `#ff4fad` — HSL
  lightness 50% → 65%, a pastel. That is not the theme's accent.
- At 3:1 it allows T ≤ 58.8, i.e. lift 40.8. Since the grey roles hold T at 36,
  **the accent never binds** — and at T = 36 it lands at **4.14:1**, close
  enough to AA that the exception is a formality on this setting rather than a
  licence. The exception costs nothing, which is why
  it is the right one: a fixed substitute above a backdrop threshold would make
  the theme's identity colour change with the wallpaper, and a solver that
  "fixes" the accent is a solver that deletes it.

**Q3 — where the ramp ceiling comes from. → a fixed table, naming the role
above, and its job is to fail rather than to shape.** Because T is fixed by the
constraints, the output is fully determined by
`fg = max(static, minFG(T, floor))`; the ceiling never shapes it. What the
ceiling does is **detect** the case where the floor has climbed past a role's
allowance, and refuse with a number.

A relative rule — "N steps below the role above" — cannot be used here: `dim3`
and `dim4` are **two bytes apart** (120, 122) and `dim2`/`dim3` are five, so any
N ≥ 3 declares the shipped theme in violation of itself. The theme's fifteen
colours occupy about six distinguishable bands, and which roles share a band is
authorial knowledge a generic rule does not have. The table is written in
`palette.toml` as `dim1.ceiling = "mid"` — a role name, not a byte — so
re-spacing the palette re-derives every ceiling for free.

**Q4 — how nvim learns the ramp. → it does not need to.** This falls out of §2:
T is a property of the palette, so **the ramp is static** and
`colors/noirblaze.lua` is a plain committed file that works identically for the
user and for a stranger with `vim.pack.add`. This is the design's main
simplification and the reason to prefer it.

A four-line seam is kept anyway, because it costs nothing and makes the adaptive
layer possible later without touching the plugin: the colourscheme `pcall`s
`loadfile("$XDG_STATE_HOME/noirblaze/ramp.lua")` and falls back to the baked
table when it is absent — which it is, in v1; nothing writes it. If it is ever
written, `Signal`/`SIGUSR1` is the reload path (**verified present in this
machine's nvim, 0.13.0-dev-1418**), matching the `pkill -USR1 -x kitty` that
`noct-glass` already does.

**Q5 — hysteresis. → repaint when the recomputed α differs from the applied α by
≥ 0.02.** Justification, not a guess: `dα/db = (T − own) / (backdrop − own)²`.
At backdrop 153 and T = 36 that is **0.0009 per level** — a one-level luma
change moves α by less than a tenth of the two decimals `noct-glass` writes, so
it is *literally* a no-op that still costs a `hyprctl reload` and a
`pkill -USR1` repaint of every terminal on screen. 0.02 is the write precision;
below it there is nothing to apply. In backdrop terms that is ≈22 levels at 153
and ≈11 at 100. Since the ramp is static, nothing else can change at all.

**Q6 — `blur_brightness`. → yes, as the third knob, downward only, above the
backdrop where structure caps α — which the measurement makes rarer than
feared.** At the measured sd of 68.7, `STRUCTURE_MIN` allows α ≤ 0.94, and it is
only the flattest tenth of the library (calibrated sd ≈ 21) that caps α at 0.81.
So this knob is reached on six wallpapers out of forty-one, not routinely. Decision 011 is load-bearing and stays in
force: at brightness 0.65 on a wallpaper of mean luma 99 the lift measured 3,
and that is the case it was written about. The case here is the opposite one — a
backdrop above ~158, where α is capped at 0.80 by `STRUCTURE_MIN` and contrast
cannot be reached. Scaling a backdrop of 212 by 0.75 gives 159, back inside
range. `glass.local.conf.example` already proposes exactly this for exactly this
symptom. So: an exception with a stated trigger, not a reversal.

---

## 5. Language: bash + awk

Not a default — the constraint is real and it argues this way.

1. **The live consumer is a bash script.** The adaptive path runs from
   `bin/noct-glass`, invoked by Noctalia's `colors_changed` hook. Python would
   add a runtime dependency to a hook path that has none, and the dots repo
   would have to declare it in `tests/deps.tsv`.
2. **awk needs no install anywhere.** It is on the GitHub runner, on CachyOS and
   in any container. The dots CI already spends `apt-get install lua5.4
   shellcheck`; adding nothing beats adding a third.
3. **The locale trap is already documented here.** `noct-glass` pins `LC_ALL=C`
   because awk formats and compares numbers per locale and a `sv_SE` session
   emits `0,90`, which Hyprland refuses. A second implementation in another
   language re-opens a bug this project has already paid for once.
4. **The maths is twenty lines.** Two exponentials, a clamp and a comparison.
   Nothing here wants data structures.
5. **`palette.toml` is parsed as a strict subset** — `key = value` under simple
   tables, the same shape `read_from()` in `noct-glass` already parses in nine
   lines of awk. CI validates the file with `python3 -c "tomllib.load(...)"`,
   exactly as `tests/lint.sh toml-syntax` does, so the subset can never drift
   from real TOML without the build going red.

Lua was considered — nvim could then read the solver directly — and rejected:
it buys nothing once the ramp is static (Q4), and it puts a `luac`/`lua`
install into this repo's CI to serve a file nvim already reads as data.

---

## 6. Repo shape

```
noirblaze/
  palette.toml              the only place a colour is typed by hand:
                            roles, ANSI slots, floors, ceilings, backdrop
                            assumption, attribution
  colors/noirblaze.lua      GENERATED, COMMITTED. Repo root so vim.pack puts
                            colors/ on runtimepath. Static ramp + a pcall'd
                            seam for a generated override that v1 never writes
  build/solve               closed-form: --backdrop --opacity --floor, prints
                            T, alpha, lift, structure, and the refusal reason
  build/emit                palette.toml -> colors/noirblaze.lua + dist/*
  build/check-contrast      every role against its floor, no desktop needed
  dist/noirblaze.json       Noctalia palette (20 Material roles + 22 terminal)
  dist/kitty-colors.conf    the 16 ANSI slots, for a kitty with no Noctalia
  dist/glass.conf.sample    the recommended `terminal` level and the backdrop
                            it assumes, stated in the file
  docs/design.md            this
  docs/decisions/           001..005, format copied from the dots repo
  README.md                 the before/after contrast table, attribution
  LICENSE                   MIT
  .github/workflows/ci.yml  emit, then `git diff --exit-code`, then check
```

`colors/noirblaze.lua` is generated *and* committed. CI regenerates and diffs,
so "palette.toml is the only place a colour is typed by hand" is enforced rather
than asserted.

Decision records to write: **001** why adaptive over static (and it is the
*constancy* argument of §1.6, not the contrast one); **002** why the ramp
ceiling exists and why it is a table; **003** the knob order and why
`blur_brightness` gets a stated exception rather than a reversal of 011;
**004** what `dist/` assumes; **005** the accent exception.

---

## 7. Wiring, and the four traps

**nvimrc — `vim.pack`, no submodule.**
- `colors/noirblaze.lua` at the repo root. ✔ planned.
- **`nvimrc/colors/noirblaze.lua` must be deleted**, or the config directory
  shadows the package on `runtimepath`.
- **`~/.config/nvim` is a second clone, not a symlink** — verified: it is its
  own git checkout of the same remote, currently at the same commit (`a1c0f26`)
  with identical files. Deploying is `git pull` in *that* clone. Committing here
  changes nothing on screen until it happens.
- `init.lua`'s `bg = "none"` block stays; the theme is designed for it (§1.1).

**cachyos-hyprland-dots — submodule at `vendor/noirblaze`.**
- **`config/noctalia/palettes/noirblaze.json` must be deleted from that repo**,
  or the existing `configs⇥tree⇥config/noctalia⇥config⇥noctalia` row and the new
  file row both claim `~/.config/noctalia/palettes/noirblaze.json`.
  `tests/lint.sh manifest-collisions` catches it, which is how we will know.
- **A source outside `config/` is already handled** — verified in
  `install/lib/link.sh`: `do_link` calls `link "$REPO/$src" "$dst"`, so the row
  `configs⇥file⇥vendor/noirblaze/dist/noirblaze.json⇥config⇥noctalia/palettes/noirblaze.json`
  needs no change to the engine.
- `.github/workflows/ci.yml` needs `submodules: recursive`, or
  `tests/lint.sh manifest-sources` fails on a row pointing into an empty
  submodule directory.
- **`install.sh --update` has a trap the brief does not mention.** `do_update`
  refuses to pull while `git status --porcelain` is non-empty, and a submodule
  whose checkout has drifted from the recorded commit shows as ` M
  vendor/noirblaze`. So `git submodule update --init --recursive` has to run
  *after* the pull and before the relink, and the refusal message needs to name
  the submodule case — otherwise "commit them, or git stash" is advice that does
  not apply.
- The adaptive hook belongs in `bin/noct-glass`, which already runs from
  `colors_changed`.

**Nothing generated is written to a path either consumer tracks.** ✔ by
construction: `dist/` is in this repo, `~/.config/kitty/generated-*.conf` and
`~/.config/hypr/generated/` are already untracked.

---

## 8. The two profiles

`palette.toml` declares both. They share every colour, every role assignment and
every floor; they differ only in the value of **T** they are solved at, and in
what they claim.

| | `aa` (default) | `noir` |
|---|---|---|
| T | 36 | 18 (opaque), floors relaxed |
| text floor | 4.5:1 | 3.0:1, **stated as below AA** |
| chrome floor | 3.0:1 | 1.8:1 |
| `Comment` | `#8b8b8b` (4.56:1) | `#6d6d6d` (3.00:1 opaque) |
| `LineNr` | `#6d6d6d` (3.00:1) | `#4a4a4a` (2.0:1 opaque) |
| distinct greys | 9 of 12 | 11 of 12 |
| claims | WCAG 2.2 AA for text, AA non-text for chrome | nothing; it prints its own ratios |

`aa` is what `dist/` ships, what the Noctalia palette carries and what the dots
repo consumes. `noir` exists because the alternative to shipping it is people
editing the ramp by hand, which is the duplication this repo was made to end.

**What `noir` may not do is lie.** Its README table gives every ratio, and
`build/check-contrast` runs against it too — asserting its *declared* floors,
not AA. A profile that quietly fails a check it claims to pass would be worse
than no profile.

Two things `noir` still fixes, because they are not aesthetics:

- `bg3` as a foreground is **1.46:1** on its own background. There is no reading
  of "dim on purpose" that reaches 1.46:1; it is invisible, and 5% of the
  ultrawide library puts a backdrop behind it bright enough to invert it.
- `dim1` crosses through **1.02:1** at a backdrop of 160 — the composited
  background passes the text's own luminance and the two swap places. Contrast
  is not monotonic in the backdrop (1.60 at 95, 1.15 at 143, **1.02** at 160,
  1.41 at 212), which is why the closed form solves upward and never bisects.

---

## 9. Build order

1. **`palette.toml`** — the fifteen colours, the role table (each role: its
   palette colour, its floor, its ceiling, and the background it sits on), the
   ANSI map, both profiles, the attribution block.
2. **`build/solve`** — bash + awk, closed form, `--backdrop --opacity --floor`,
   prints T, α, lift, structure and the refusal reason. No desktop.
3. **`build/emit`** — `palette.toml` → `colors/noirblaze.lua`, `dist/*`.
4. **`build/check-contrast`** — every role against its own floor and its own
   background, both profiles; plus the two assertions that keep the solver
   honest: `normal.green` is untouched, and no role exceeds its ceiling.
5. **`dist/`**, committed; CI regenerates and `git diff --exit-code`.
6. **Decision records 001–005.**
7. **`nvimrc`** — delete `colors/noirblaze.lua`, add the `vim.pack` spec, pull
   in `~/.config/nvim` (the second clone), start clean.
8. **`cachyos-hyprland-dots`** — submodule, delete
   `palettes/noirblaze.json`, two `links.tsv` rows, `submodules: recursive` in
   CI, the `--update` submodule step and its refusal message (§7), then
   `./install.sh --status`, `--unlink` round trip, and `tests/lint.sh`.
9. **The adaptive layer in `bin/noct-glass`** — measure the displayed crop's
   centre tile, run the solver, write `terminal`, apply the 0.02 hysteresis.
10. **The README table** — before/after, measured, both profiles.

## 10. What is still unmeasured

Everything the design rests on has now been measured except two things, and
neither blocks the build:

- **The other two monitors.** All the library statistics are the 41 ultrawide
  wallpapers on DP-3. The portrait set (HDMI-A-1) measured a brighter brightest
  tile — median 156.5, p90 216.5 — so the feasibility percentages in §2.2 are
  slightly optimistic for that screen. `build/solve` takes a backdrop argument,
  so this changes no code, only the number the hook feeds it per monitor.
- **`glass-legible` only tests the brightest text there is.** It reads
  `foreground` (`#d5d5d5`, luma 213) from `generated-colors.conf` and reports
  5.16:1 — passing, on a palette whose `bright.black` is at 3.95:1 before any
  transparency. **That is why a fully green suite never noticed this.** The fix
  belongs in the dots repo: have it check the dimmest slot that carries text,
  not the brightest. Worth a decision record there rather than a silent edit.
