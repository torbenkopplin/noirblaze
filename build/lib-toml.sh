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
function ceilb(x) { return (x == int(x)) ? x : int(x) + 1 }
function hexb(b,   n) { n = int(b + 0.5); if (n < 0) n = 0; if (n > 255) n = 255
                        return sprintf("#%02x%02x%02x", n, n, n) }
'

# solve_surface <surface #rrggbb> <floor text> <floor chrome> <floor accent>
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
    awk -F'\t' -v S="$1" -v ft="$2" -v fc="$3" -v fa="$4" "$AWK_LIB"'
    BEGIN { Ls = lum(S) }
    {
        role = $1; hex = $2
        r = hex2(substr(hex, 2, 2)); g = hex2(substr(hex, 4, 2)); b = hex2(substr(hex, 6, 2))
        grey = (r == g && g == b)
        for (i = 1; i <= 3; i++) {
            cls = (i == 1) ? "text" : (i == 2) ? "chrome" : "accent"
            fl  = (i == 1) ? ft : (i == 2) ? fc : fa
            # A hue is never lifted: a grey ramp cannot raise one without
            # desaturating it, and `green` is the whole reason the ANSI block
            # is readable. build/check-contrast asserts this held.
            if (!grey) { print role "\t" cls "\t" hex; continue }
            if (lum(hex) >= Ls) {                       # light on dark: lift
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

# toml_profiles -- the names under [profile.*], in file order.
toml_profiles() {
    sed -n 's/^[[:space:]]*\[profile\.\([a-z0-9_]*\)\].*/\1/p' "$PALETTE"
}
