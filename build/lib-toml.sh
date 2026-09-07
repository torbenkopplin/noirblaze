# lib-toml.sh -- the strict-subset TOML reader, and the colour maths.
#
# Sourced by build/emit and build/check-contrast; build/solve carries its own
# copy of toml_get so that it stays a single file with no dependency but awk,
# which is what lets a Noctalia hook run it directly.
#
# The subset is "key = value" under simple [table] headers. That is nine lines
# of awk and the same shape bin/noct-glass already parses in the dots repo. CI
# validates palette.toml with python3's tomllib, so the subset cannot drift away
# from real TOML without the build going red.

# toml_get <table> <key>
#
# Split on the FIRST "=", and read a quoted value to its closing quote BEFORE
# stripping any trailing comment. Both matter: every colour here is a "#rrggbb"
# string, so a naive sub(/#.*$/) comment strip removes the value itself.
toml_get() {
    awk -v want="$1" -v k="$2" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*\[/ { t = $0; gsub(/[][[:space:]]/, "", t); tbl = t; next }
        tbl == want {
            eq = index($0, "="); if (!eq) next
            key = substr($0, 1, eq - 1); gsub(/[[:space:]]/, "", key)
            if (key != k) next
            v = substr($0, eq + 1); sub(/^[[:space:]]+/, "", v)
            if (substr(v, 1, 1) == "\"") { v = substr(v, 2); q = index(v, "\""); if (q) v = substr(v, 1, q - 1) }
            else { sub(/#.*$/, "", v); sub(/[[:space:]]+$/, "", v) }
            print v; found = 1; exit
        }
        END { if (!found) exit 1 }
    ' "$PALETTE"
}

# toml_section <table> -- every "key<TAB>value" in a table, in file order.
toml_section() {
    awk -v want="$1" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*\[/ { t = $0; gsub(/[][[:space:]]/, "", t); tbl = t; next }
        tbl == want {
            eq = index($0, "="); if (!eq) next
            key = substr($0, 1, eq - 1); gsub(/[[:space:]]/, "", key)
            if (key == "") next
            v = substr($0, eq + 1); sub(/^[[:space:]]+/, "", v)
            if (substr(v, 1, 1) == "\"") { v = substr(v, 2); q = index(v, "\""); if (q) v = substr(v, 1, q - 1) }
            else { sub(/#.*$/, "", v); sub(/[[:space:]]+$/, "", v) }
            printf "%s\t%s\n", key, v
        }
    ' "$PALETTE"
}

# The colour maths. WCAG 2.x relative luminance, sRGB linearisation, and the
# closed-form inverse -- no bisection, because contrast is not monotonic in the
# backdrop and a search would find the wrong side of the crossing.
AWK_LIB='
function lin(v,   c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
function unlin(L) { if (L <= 0.0031308) return (L * 12.92) * 255
                    return (1.055 * (L ^ (1 / 2.4)) - 0.055) * 255 }
function hex2(s,   i, c, n, d) { n = 0
    for (i = 1; i <= length(s); i++) { c = tolower(substr(s, i, 1))
        d = index("0123456789abcdef", c) - 1; n = n * 16 + d }
    return n }
function lum(hex) { return 0.2126 * lin(hex2(substr(hex, 2, 2))) \
                         + 0.7152 * lin(hex2(substr(hex, 4, 2))) \
                         + 0.0722 * lin(hex2(substr(hex, 6, 2))) }
function ratio(La, Lb) { return (La > Lb) ? (La + 0.05) / (Lb + 0.05) : (Lb + 0.05) / (La + 0.05) }
function minfg(Lbg, R,   L) { L = R * (Lbg + 0.05) - 0.05; if (L < 0) L = 0; return unlin(L) }
# the BRIGHTEST foreground that still clears R going the other way -- dark text
# on a light background, where contrast is bought by getting darker
function maxfg(Lbg, R,   L) { L = (Lbg + 0.05) / R - 0.05; if (L < 0) L = 0; return unlin(L) }
# the brightest BACKGROUND a fixed foreground still clears R against -- the same
# arithmetic read the other way, used to cap how far a surface may be lifted
function maxbg(Lfg, R,   L) { L = (Lfg + 0.05) / R - 0.05; if (L < 0) L = 0; return unlin(L) }
function ceilb(x) { return (x == int(x)) ? x : int(x) + 1 }
function hexb(b,   n) { n = int(b + 0.5); if (n < 0) n = 0; if (n > 255) n = 255
                        return sprintf("#%02x%02x%02x", n, n, n) }
'

# solve_surface <surface #rrggbb> <floor text> <floor chrome> <floor accent> <floor surface>
#
# Reads "role<TAB>hex" on stdin, writes "role<TAB>class<TAB>hex".
#
# The first argument is the BYTE OF THE BACKGROUND THE TEXT SITS ON, and that is
# the whole generalisation: a group whose background is the default background
# composites, so its surface is T; a group with an explicit background is drawn
# opaque (kitty makes only default-background cells translucent) and its surface
# is that colour.
#
# It matters which. bg3 is byte 50 and T is 36, so the panel shade -- Pmenu,
# StatusLine, TabLine, Folded, WildMenu -- is LIGHTER than the composited
# background, and a foreground that clears 4.5:1 against T lands at 3.76:1
# inside every popup menu. Checking everything against T alone passes a theme
# that is wrong wherever it draws a panel.
#
# The surface is a COLOUR, not a byte. Passing a byte works for the grey
# backgrounds and is wrong for the accent: byteof("#ff0088") is 255, so a
# foreground on a pink background was solved as though it sat on white and
# CurSearch\'s dark text came out #ffffff.
#
# The solve is DIRECTIONAL. A foreground darker than its background is half of a
# dark-on-light pair -- Search, IncSearch, CurSearch, MoreMsg -- and the way to
# give it contrast is to make it darker still, not brighter. Solving everything
# upward turns the dark half of every inverse pair white.
solve_surface() {
    awk -F'\t' -v S="$1" -v ft="$2" -v fc="$3" -v fa="$4" -v fs="$5" -v base="$6" "$AWK_LIB"'
    BEGIN { Ls = lum(S); Lbase = lum(base) }
    {
        role = $1; hex = $2
        r = hex2(substr(hex, 2, 2)); g = hex2(substr(hex, 4, 2)); b = hex2(substr(hex, 6, 2))
        grey = (r == g && g == b)
        for (i = 1; i <= 4; i++) {
            cls = (i == 1) ? "text" : (i == 2) ? "chrome" : (i == 3) ? "accent" : "surface"
            fl  = (i == 1) ? ft : (i == 2) ? fc : (i == 3) ? fa : fs
            # A hue is never lifted: a grey ramp cannot raise one without
            # desaturating it, and `green` is the whole reason the ANSI block
            # is readable. build/check-contrast asserts this held.
            if (!grey) { print role "\t" cls "\t" hex; continue }
            # A SURFACE is always solved upward, whatever the arithmetic would
            # prefer. The theme declares one stacking order -- bg < bg2 < bg3 --
            # and CursorLine is a band lighter than the buffer, not darker.
            # Solved by luminance alone, bg2 (byte 33) sitting under a
            # composited background of 36 takes the "dark on light" branch and
            # comes out #161616: visible again, and the layer stack inverted.
            # A surface floor is not one number for all of them: it is the
            # separation THIS role already has from the palette background.
            # bg2 is 1.163:1 above bg and bg3 is 1.461:1, and they have to stay
            # that far apart from each other as well as from the buffer: lift
            # bg2 alone and CursorLine lands two bytes from Visual, so selecting
            # text on the current line stops being visible. Derived, so no
            # number is typed twice and re-spacing the palette re-derives them.
            if (cls == "surface") fl = ratio(lum(hex), Lbase)
            if (cls == "surface" || lum(hex) >= Ls) {   # light on dark: lift
                want = ceilb(minfg(Ls, fl))
                out  = (r > want) ? r : want
            } else {                                    # dark on light: deepen
                want = int(maxfg(Ls, fl))
                out  = (r < want) ? r : want
                if (out < 0) out = 0
            }
            printf "%s\t%s\t%s\n", role, cls, hexb(out)
        }
        print role "\tfixed\t" hex
        print role "\tinverse\t" hex
    }'
}

# byteof <#rrggbb> -- the red channel, which for a grey is the byte.
byteof() { awk -v h="$1" "$AWK_LIB"'BEGIN { print hex2(substr(h, 2, 2)) }'; }

# surface_of <bg field> -- normalise a groups.tsv background into a surface.
#
# "-" and "none" are the default background. So is any role whose colour EQUALS
# the palette's own `bg`: kitty makes a cell translucent when its background
# matches the default terminal background, and a cell nvim paints #121212 on a
# terminal whose background is #121212 is exactly that cell. It composites, so
# its surface is T and not byte 18.
#
# Getting this wrong is not academic. LineNr is `bg = c.bg`, and solved against
# an opaque #121212 it came out #616161 -- which is 3.0:1 there and 2.5:1 once
# nvimrc/init.lua sets `bg = "none"` on it, which it does on the line after
# loading the colourscheme.
surface_of() {
    case $1 in
        -|none) printf 'default'; return ;;
    esac
    local c bgc
    c=$(printf '%s\n' "$RAMP" | awk -F'\t' -v r="$1" '$1==r{print $2;exit}')
    bgc=$(printf '%s\n' "$RAMP" | awk -F'\t' '$1=="bg"{print $2;exit}')
    [[ ${c,,} == "${bgc,,}" ]] && printf 'default' || printf '%s' "$1"
}

# surfaces -- every background role in groups.tsv that carries a solvable
# foreground, plus "default" for the composited one. Discovered rather than
# listed, so a new panel colour cannot be missed.
surfaces() {
    awk -F'\t' '
        /^#/ || NF < 6 { next }
        $5 != "fixed" && $5 != "inverse" && $2 != "-" && $3 != "-" && $3 != "none" { print $3 }
    ' "$GROUPS_TSV" | sort -u
}

# bg_hex <role> -- the colour a background role is actually painted, which is
# the solved value CAPPED by what is drawn on it.
#
# Lifting a surface to keep it visible against the composited background can
# push a FIXED foreground off its floor, and a fixed foreground cannot follow:
# the accent is #ff0088 by decision and a grey ramp cannot lift a hue. Measured:
# bg3 solved to its declared 1.461:1 lands at #3f3f3f, where pink is 2.81:1 --
# under the 3:1 the accent exception is stated at -- and Error, Todo, VisualNOS,
# DiffAdd and DiffDelete all put pink on bg3.
#
# So a surface rises no further than the dimmest thing pinned to it allows. The
# cap is derived from groups.tsv and the palette, not chosen: no number here.
bg_hex() {
    local role=$1 want cap
    want=$(hex "$role" "$(bg_class "$role")")
    cap=$(surface_cap "$role") || { printf '%s' "$want"; return; }
    awk -v a="$want" -v b="$cap" "$AWK_LIB"'BEGIN { print (lum(a) <= lum(b)) ? a : b }'
}

# surface_cap <role> -- the brightest that background may become before a fixed
# foreground drawn on it stops clearing its floor. Fails if nothing pins it.
#
# Only CHROMATIC foregrounds pin a surface. A grey one is re-solved on the
# surface and simply follows it up; a hue cannot.
surface_cap() {
    local bgrole=$1 fg cls floor c out=""
    while IFS=$'\t' read -r _g fg _bg _sp cls _a; do
        [[ $fg == - ]] && continue
        c=$(printf '%s\n' "$RAMP" | awk -F'\t' -v r="$fg" '$1==r{print $2;exit}')
        [[ -n $c ]] || continue
        # grey foregrounds follow the surface; only a fixed hue pins it
        [[ ${c:1:2} == "${c:3:2}" && ${c:3:2} == "${c:5:2}" ]] && continue
        case $cls in text) floor=$FT ;; chrome) floor=$FC ;; accent) floor=$FA ;; *) continue ;; esac
        out=$(awk -v f="$c" -v R="$floor" -v prev="$out" "$AWK_LIB"'
              # int(), not a round: the cap is a limit, and rounding UP past it
              # puts the thing it protects a hundredth under its floor. Measured:
              # 58.8 rounded to 59 left pink at 2.99:1 against a 3.0 floor.
              BEGIN { b = hexb(int(maxbg(lum(f), R)))
                      if (prev == "" || lum(b) < lum(prev)) print b; else print prev }')
    done < <(awk -F'\t' -v b="$bgrole" '!/^#/ && NF >= 6 && $3 == b' "$GROUPS_TSV")
    [[ -n $out ]] || return 1
    printf '%s' "$out"
}

# bg_class <role> -- which class a role is solved in when used AS a background.
#
# `bg` is exempt and must stay exactly as written: it IS the default background,
# so lifting it would move T itself and the solve would chase its own tail.
# Chromatic backgrounds are never solved anyway. Everything else takes the
# surface floor, so a panel cannot become indistinguishable from the buffer.
bg_class() {
    [[ $1 == bg ]] && { printf 'fixed'; return; }
    local c
    c=$(printf '%s\n' "$RAMP" | awk -F'\t' -v r="$1" '$1==r{print $2;exit}')
    [[ ${c:1:2} == "${c:3:2}" && ${c:3:2} == "${c:5:2}" ]] && printf 'surface' || printf 'fixed'
}

# hex <role> <class> [surface] -- the solved colour.
#
# An inverse row is looked up in the `text` class -- a highlighted match or a
# ":more" prompt is text and takes the text floor; what makes it inverse is only
# which of the two roles moves.
hex() {
    local tbl cls=$2
    [[ $cls == inverse ]] && cls=text
    if [[ ${3:-default} == default ]]; then tbl=$SOLVED
    else tbl=$(solved_on "$(surface_hex "$3")"); fi
    printf '%s\n' "$tbl" | awk -F'\t' -v r="$1" -v c="$cls" '$1==r && $2==c {print $3; exit}'
}

# pairs_used -- "class<TAB>surface<TAB>role" for every combination groups.tsv
# needs.
#
# An `inverse` row is the same machinery with the two roles swapped. Its
# foreground is already the darkest colour in the theme, so contrast is bought
# by lifting the BACKGROUND -- and "lift this role until it clears R against
# that colour" is exactly what solve_surface does. So the surface for an inverse
# row is its FOREGROUND, and the role being solved is its background.
#
# MoreMsg is the one that needs it: #121212 on dim3 is 4.24:1, and the fix is
# dim3 -> #7c7c7c, four bytes.
pairs_used() {
    awk -F'\t' -v bgrole="$(default_bg_roles)" '
        /^#/ || NF < 6 { next }
        {
            cls = $5
            if (cls == "fixed") next
            if (cls == "inverse") {
                if ($2 != "-" && $3 != "-" && $3 != "none") print "inverse\t" $2 "\t" $3
                next
            }
            surf = ($3 == "-" || $3 == "none" || $3 == bgrole) ? "default" : $3
            if ($2 != "-") print cls "\t" surf "\t" $2
            if ($4 != "-") print cls "\t" surf "\t" $4
        }' "$GROUPS_TSV" | sort -u
}

# default_bg_roles -- the role name whose colour IS the default background.
# Any group painted in it composites; see surface_of in build/lib-toml.sh.
default_bg_roles() { printf 'bg'; }

# tbl_name <class> <surface>
tbl_name() {
    case $1 in text) n=t ;; chrome) n=k ;; accent) n=a ;; inverse) n=b ;; *) n=c ;; esac
    [[ $2 == default ]] && printf '%s' "$n" || printf '%s_%s' "$n" "$2"
}

# toml_profiles -- the names under [profile.*], in file order.
toml_profiles() {
    sed -n 's/^[[:space:]]*\[profile\.\([a-z0-9_]*\)\].*/\1/p' "$PALETTE"
}
