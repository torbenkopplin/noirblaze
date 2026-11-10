# noirblaze

A near-black colourscheme with one hot pink accent, for **neovim** and for the
**terminal**, solved so that its dim text is actually readable — including
through a translucent terminal over a bright wallpaper.

Dark only. One source of truth. Every colour below is computed, not chosen.

```
palette.toml ──► build/solve ──► build/emit ──► colors/noirblaze.lua
  the 15 colours   the contrast     the artefacts   dist/noirblaze.json
  and the floors   solve, closed                    dist/kitty-colors.conf
                   form                             dist/glass.conf.sample
```

## Install

**neovim** — no plugin manager needed beyond the one built in:

```lua
vim.pack.add({ "https://github.com/torbenkopplin/noirblaze" })
vim.cmd.colorscheme("noirblaze")
```

That is the whole thing. No Noctalia, no solver run, no generated file: the
colours in `colors/noirblaze.lua` are committed and correct. See
[why](docs/decisions/001-adaptive-because-the-glass-is-not-constant.md).

**kitty**, standalone:

```
include /path/to/noirblaze/dist/kitty-colors.conf
```

**A Noctalia desktop** — the palette drives the bar, the launcher, the panels,
GTK, Qt and every shell tool that paints with the 16 ANSI slots:

```sh
ln -s /path/to/noirblaze/dist/noirblaze.json ~/.config/noctalia/palettes/noirblaze.json
noctalia msg color-scheme-set custom noirblaze
```

## The problem it solves

Comments and dim text in this theme were hard to read, and transparency was only
half of why.

**The dim band was already below WCAG AA on its own background.** On `#121212`,
4.5:1 needs byte 124; `dim1` through `dim4` are 83, 115, 120 and 122. Every one
of them fails at zero transparency. Put the same text behind a terminal at
`background_opacity 0.55` over a bright wallpaper and `Comment` reaches
**1.02:1** — the composited background passes the text's own luminance and the
two swap places.

That last number is worth dwelling on, because it is why this cannot be eyeballed:
**contrast is not monotonic in the backdrop.** `#535353` measures 1.60:1 over a
backdrop of 95, 1.15 at 143, **1.02 at 160**, and 1.41 at 212 — having crossed
over and come out inverted. A solver that searched would find the wrong side of
that crossing. This one does not search.

## How it works

A translucent terminal composites as

```
seen_bg = own_bg × α + backdrop × (1 − α)
```

and kitty fades only the *background* — glyphs stay fully opaque. So the
foreground byte is fixed, only the background moves, and writing **T** for that
composited background byte:

> **lift = T − own_bg.** The backdrop cancels.

Every constraint is a constraint on T alone, so the ramp is a function of the
palette and **not of the wallpaper**. The backdrop enters exactly once, at the
end, to say what opacity reaches T:

```
α = (backdrop − T) / (backdrop − own_bg)
```

Given a floor R the minimum foreground luminance is closed-form,
`L_fg ≥ R × (L_bg + 0.05) − 0.05`, and inverting the sRGB transfer gives the
byte directly. No bisection; `build/solve` is about twenty lines of awk.

```console
$ build/solve --backdrop 153 --sd 68.7
profile      aa   (WCAG 2.2 AA: 4.5:1 for text, 3:1 for non-text)
T            36   the composited background byte the ramp is solved against
own_bg       #121212
backdrop     153
alpha        0.87   terminal opacity that reaches T on this backdrop
lift         18.0   (want >= 12)
structure    9.2   (want >= 4, at sd 68.7)
floors       text 4.5:1 -> #8b8b8b        chrome 3.0:1 -> #6d6d6d        accent 3.0:1
verdict      ok
```

## Before and after

Measured with `build/check-contrast --table`, profile `aa`.

Ratios are WCAG 2.x, sRGB linearisation. "on `#121212`" is the theme opaque;
"at T=36" is the same text seen through a terminal at the recommended opacity
over a backdrop of 153.

| role | used by | before | on `#121212` | after | at T=36 |
|---|---|---|---|---|---|
| `bg3` | `LineNr`, `NonText` | `#323232` | **1.46** | `#6d6d6d` | 3.00 |
| `dim1` | `WinSeparator`, `Conceal`, tag delimiters | `#535353` | **2.44** | `#6d6d6d` | 3.00 |
| `dim1` | `Comment`, `@comment` | `#535353` | **2.44** | `#8b8b8b` | 4.56 |
| `dim2` | `Include`, `@punctuation.*`, ANSI `bright.black` | `#737373` | **3.95** | `#8b8b8b` | 4.56 |
| `dim3` | `String`, `Character`, ANSI `normal.cyan` | `#787878` | **4.24** | `#8b8b8b` | 4.56 |
| `dim4` | `Type`, `@type`, ANSI `normal.magenta` | `#7a7a7a` | **4.36** | `#8b8b8b` | 4.56 |
| `mid` | `Keyword`, `Conditional`, `DiagnosticWarn` | `#949494` | 6.18 | `#949494` *(unchanged)* | 5.12 |
| `fg4` | `@attribute`, `@lsp.type.decorator` | `#a7a7a7` | 7.79 | `#a7a7a7` *(unchanged)* | 6.45 |
| `fg3` | `Statement`, `Operator`, ANSI `normal.blue` | `#b0b0b0` | 8.64 | `#b0b0b0` *(unchanged)* | 7.16 |
| `fg2` | `Normal` | `#b4b4b4` | 9.04 | `#b4b4b4` *(unchanged)* | 7.49 |
| `fg1` | `@variable`, `@property`, ANSI `normal.white` | `#d5d5d5` | 12.76 | `#d5d5d5` *(unchanged)* | 10.58 |
| `fg0` | `@function.method`, `Question` | `#f5f5f5` | 17.18 | `#f5f5f5` *(unchanged)* | 14.24 |
| `white` | `Identifier`, `@function` | `#ffffff` | 18.73 | `#ffffff` *(unchanged)* | 15.52 |
| `pink` | accent, cursor, `Function`, `Constant` | `#ff0088` | 5.00 | `#ff0088` *(unchanged)* | 4.14 |
| `green` | ANSI `normal.green`, `git diff +` | `#00ff77` | 13.89 | `#00ff77` *(unchanged)* | 11.51 |
| `green_bright` | ANSI `bright.green`, `ls` executables | `#2eff8f` | 14.11 | `#2eff8f` *(unchanged)* | 11.69 |

**Bold** is below the floor for its class (text 4.5:1, chrome 3.0:1, accent 3.0:1).

**What changed, in one line:** `dim1` through `dim4` merge into `#8b8b8b`, and
the gutter roles move to `#6d6d6d`. Nine of the twelve greys survive. Comments
stop being dimmer than strings — that distinction is not recoverable, because
`dim1` is 2.44:1 and the floor is 4.5:1 even with no transparency at all.
`Keyword` stays distinct from the dim band, which it would not at a heavier
glass setting.

**Backgrounds move too, and for a different reason.** kitty makes a cell
translucent only when its background matches the default background, so a panel
is painted opaque and does not follow the buffer up. `CursorLine` ended up
**1.04:1** against the composited background — three levels darker, crossed over
and invisible. Each surface is now lifted to keep the separation the palette
declares for it, capped by the dimmest fixed colour drawn on it:

| layer | before | after | vs the buffer |
|---|---|---|---|
| `bg2` `CursorLine` | `#212121` | `#303030` | 1.04 → **1.18** |
| `bg3` `Visual`, `Pmenu` | `#323232` | `#3a3a3a` | 1.21 → **1.36** |
| `dim1` `PmenuSel` | `#535353` | `#606060` | 2.02 → **2.47** |

`bg3` stops short of its declared 1.461:1 because pink is fixed and would fall
under 3:1 on anything lighter — see
[006](docs/decisions/006-a-surface-is-solved-too.md).

**The terminal block barely moves.** Three slots change for contrast —
`bright.black` (the fish prompt, `git diff` context, `ls`, `fzf`, `bat`,
`delta`), `normal.cyan` and `normal.magenta`. The rest already cleared their
floors.

## Two profiles

Both ship. They differ only in what they **claim**, not in how much glass you
get — both are solved at the same T, so their ratios are directly comparable.

| | `aa` (default) | `noir` |
|---|---|---|
| text floor | 4.5:1 | 3.0:1, **stated as below AA** |
| chrome floor | 3.0:1 | 1.8:1 |
| `Comment` | `#8b8b8b` | `#6d6d6d` |
| `LineNr` | `#6d6d6d` | `#4c4c4c` |
| claims | WCAG 2.2 AA | nothing; it prints its own ratios |

`noir` exists because the alternative to shipping it is people editing the ramp
by hand, which is the duplication this repo was made to end. What it may not do
is lie: `build/check-contrast --all` runs against it too, asserting its
*declared* floors. It still fixes the two things that are not aesthetics —
`bg3` at 1.46:1, which is invisible rather than dim, and `dim1` crossing through
1.02:1.

```sh
build/emit --profile noir     # rewrites colors/ and dist/
```

## The adaptive layer

Optional, and it lives in the desktop repo rather than here. On a wallpaper or
scheme change: measure the displayed crop's centre tile, run `build/solve`,
write `terminal` into the glass config, poke kitty. The colours never move —
only the opacity.

It is worth having for a reason that is not contrast. At a fixed
`terminal = 0.55`, measured across 41 wallpapers, the lift ranges from **9.0**
(below the level at which glass is visible at all) to **99.0**. Ten to one,
depending on which image is on screen. Holding T constant holds the lift at 18 —
one above the value the desktop's own
[decision 011](https://github.com/torbenkopplin/cachyos-hyprland-dots) was tuned
for. **The adaptive layer does not make the desktop less glassy; it makes it the
same every time.**

## Repo shape

| Path | What |
|---|---|
| `palette.toml` | the only place a colour is typed by hand |
| `groups.tsv` | highlight group → role, class and background. No colours |
| `build/solve` | the closed-form solve. bash + awk, no desktop |
| `build/emit` | palette → every artefact. `--check` diffs the committed output |
| `build/check-contrast` | every group against its own floor on its own background, and every layer against the one below |
| `colors/noirblaze.lua` | generated, committed, loadable by `vim.pack` |
| `dist/` | generated, committed: Noctalia palette, kitty colours, glass sample |
| `docs/design.md` | how the numbers were arrived at |
| `docs/decisions/` | five records, and what each was settled against |

Generated files are committed *and* checked: CI regenerates them and fails on a
diff, so "one source of truth" is enforced rather than asserted.

**Language.** bash + awk, argued in [docs/design.md §5](docs/design.md). Briefly:
the live consumer is a bash hook, awk needs no install on a GitHub runner or a
CachyOS box, the locale trap (`LC_ALL=C`, or a Swedish session emits `0,90` and
Hyprland refuses the config) is already documented in the desktop repo, and the
maths is two exponentials and a clamp.

## Attribution

This is a derivative work, and the two upstreams are both MIT.

| What | From | Licence |
|---|---|---|
| the fifteen ramp colours, and 55 of the 57 base highlight groups | [n1ghtmare/noirblaze-vim](https://github.com/n1ghtmare/noirblaze-vim) | MIT, © 2025 Dimitar Dimitrov |
| nineteen of the twenty-two terminal values | [n1ghtmare/noirblaze-kitty](https://github.com/n1ghtmare/noirblaze-kitty) | MIT, © 2023 Dimitar Dimitrov |

`build/check-contrast upstream` asserts those nineteen still match upstream
byte for byte, so the claim above cannot quietly stop being true.

**What is not upstream's**, and is MIT © 2026 Torben Kopplin: the 92 treesitter
(`@*`), LSP semantic token, diagnostic, devicon and XML/HTML groups; the
contrast solve and the adaptive opacity; and two colours —

- **`green` `#00ff77`.** Upstream sets ANSI 2 to `#ff0088`, i.e. pink. This is
  the one real colour in the block and the reason `git diff` and `ls` are
  readable; deriving it from the editor greys gives a grey-green and breaks
  both. The solver is forbidden from touching it and a test says so.
- **`green_bright` `#2eff8f`.** Upstream leaves ANSI 10 at `#fd319e`, also pink,
  so `ls` disagreed with `git diff` about what green means. Derived rather than
  picked: every normal/bright pair in this block is the same hue at higher HSL
  lightness (`red` +9.2, `magenta` +9.8, `cyan` +9.8), and this is the `red`
  pair's own +9.2 applied to `green`.

## Licence

MIT. See [LICENCE](LICENCE), which carries both upstream notices as MIT
requires.
