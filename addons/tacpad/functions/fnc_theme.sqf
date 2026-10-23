#include "script_component.hpp"
/*
 * Author: JMSB
 * The colour set every panel paints itself with. Four tokens and nothing else:
 * ground, ink, accent and line. No control anywhere hard-codes a hex, which is
 * what makes a scheme change a repaint rather than a rebuild - and what makes
 * adding a scheme later one entry in this switch.
 *
 * THESE ARE THE DESIGN'S OWN COLOURS, not the player's Arma interface colours.
 * Reading their profile was tried and dropped: it made the tacpad a different
 * mod on every machine, and the near-white ink most people run turned every
 * divider and tile border into a white cage over the map. The suite is set in
 * one palette so it reads as one thing.
 *
 * LIGHT is the Modernist ground the design was drawn on - near-mono red on
 * light grey. DARK is its night ground, for the same reason a map has a night
 * mode: a light panel at 0200 is a torch in the face.
 *
 * Arguments:
 * 0: Token - "ground", "ink", "accent", "line", the derived "accentTint", "accentHover",
 *    "accentText", "accentDeep", "surface", "muted", "dim", the fixed "swatchGreen" / "swatchYellow",
 *    or "" for the first four <STRING> (optional, default "")
 *
 * Return Value:
 * RGBA <ARRAY>, or [ground, ink, accent, line] when no token is named
 *
 * Example:
 * private _ink = ["ink"] call jmfsb_tacpad_fnc_theme
 *
 * Public: Yes
 */

params [["_token", "", [""]]];

private _cached = uiNamespace getVariable [QGVAR(themeCache), []];

// The custom tokens are part of the key. They were not, so picking a different
// custom colour while already on the custom scheme left the key unchanged and
// the cache handed back the colour you had just replaced.
private _key = format [
    "%1/%2/%3/%4/%5",
    GVAR(scheme), GVAR(opacity),
    GVAR(customGround), GVAR(customInk), GVAR(customAccent)
];

if (_cached isEqualTo [] || {(_cached # 0) != _key}) then {
    private _set = switch (GVAR(scheme)) do {
        // FIELD GREY, the Modernist ground as drawn: #f3f2f2 on #201e1d,
        // accent #ec3013. The design's four presets are three tokens each and
        // nothing else - every divider, tint and pressed state is derived.
        case "light": {
            [
                [0.953, 0.949, 0.949, 1],
                [0.125, 0.118, 0.114, 1],
                [0.925, 0.188, 0.075, 1],
                [0.125, 0.118, 0.114, 0.22]
            ]
        };

        // OLIVE: #e8e7e2 ground, #16281d ink, #b5cc4a accent.
        case "olive": {
            [
                [0.910, 0.906, 0.886, 1],
                [0.086, 0.157, 0.114, 1],
                [0.710, 0.800, 0.290, 1],
                [0.086, 0.157, 0.114, 0.22]
            ]
        };

        // SAND: #efece4 ground, #2b2119 ink, #d99427 accent.
        case "sand": {
            [
                [0.937, 0.925, 0.894, 1],
                [0.169, 0.129, 0.098, 1],
                [0.851, 0.580, 0.153, 1],
                [0.169, 0.129, 0.098, 0.22]
            ]
        };

        // NIGHT / RED, the design's night ground: #141514 on #e6e5e2, accent
        // #ff563c. A light panel at 0200 is a torch in the face.
        //
        // It was called NIGHT / NVG, which claimed something it never did - no
        // scheme here knows or cares whether the player is wearing tubes. It is
        // the red night ground, and the two below it are the same night ground
        // under the other two accents, so a unit that runs olive by day is not
        // forced onto red the moment the sun goes down.
        case "dark": {
            [
                [0.078, 0.082, 0.078, 1],
                [0.902, 0.898, 0.886, 1],
                [1, 0.337, 0.235, 1],
                [0.902, 0.898, 0.886, 0.20]
            ]
        };

        // NIGHT OLIVE: the night ground, olive ink, and the olive accent pulled
        // down from #b5cc4a - full-strength lime on black is a headlight.
        case "nightOlive": {
            [
                [0.063, 0.078, 0.067, 1],
                [0.851, 0.878, 0.831, 1],
                [0.612, 0.706, 0.235, 1],
                [0.851, 0.878, 0.831, 0.20]
            ]
        };

        // NIGHT SAND: the night ground warmed, with the sand accent held to an
        // amber that reads on it.
        case "nightSand": {
            [
                [0.086, 0.075, 0.063, 1],
                [0.898, 0.878, 0.839, 1],
                [0.780, 0.510, 0.129, 1],
                [0.898, 0.878, 0.839, 0.20]
            ]
        };

        // JMSB DAY, the unit's palette (the G logo, 2026-10-08: ranger green and
        // tan) on its paper: #e9e4d3 ground, #20261c ink, and a darker tan
        // #8a7550 for the accent - the logo's #c2a878 is too pale to read on
        // a light ground, as the brass before it was.
        case "jmsb": {
            [
                [0.914, 0.894, 0.831, 1],
                [0.125, 0.149, 0.110, 1],
                [0.541, 0.459, 0.314, 1],
                [0.125, 0.149, 0.110, 0.22]
            ]
        };

        // JMSB NIGHT, the unit's own look and the default: #20261c ground,
        // #e9e4d3 ink, #c2a878 tan - what jmsb.info and pac.jmsb.info paint with.
        case "nightJmsb": {
            [
                [0.125, 0.149, 0.110, 1],
                [0.914, 0.894, 0.831, 1],
                [0.761, 0.659, 0.471, 1],
                [0.914, 0.894, 0.831, 0.20]
            ]
        };

        // Yours. Three "r,g,b" settings, 0-1 each; anything empty or malformed
        // falls back to the light answer rather than painting a panel invisible.
        default {
            // Yours. Three colours, each hex or the older r,g,b; anything empty
            // or malformed falls back to the Field Grey answer rather than
            // painting a panel invisible. FUNC(rgbOf) does the reading, so the
            // settings screen and this agree on what a colour string means.
            private _ink = [GVAR(customInk), [0.125, 0.118, 0.114, 1]] call FUNC(rgbOf);
            [
                [GVAR(customGround), [0.953, 0.949, 0.949, 1]] call FUNC(rgbOf),
                _ink,
                [GVAR(customAccent), [0.925, 0.188, 0.075, 1]] call FUNC(rgbOf),
                [_ink # 0, _ink # 1, _ink # 2, 0.22]
            ]
        };
    };

    // Opacity is applied to the ground only. Making the ink translucent too is
    // how a readable panel becomes a smear over a contour line.
    private _ground = +(_set # 0);
    _ground set [3, GVAR(opacity)];
    _set set [0, _ground];

    _cached = [_key, _set];
    uiNamespace setVariable [QGVAR(themeCache), _cached];
};

private _set = _cached # 1;

// THE DERIVED STEPS (docs/PLAN_MESSAGING_UI.md, phase 1). The handoffs use an
// accent ramp and a neutral ramp; here every step is MIXED from the three
// tokens, never typed, so Night/NVG and a custom scheme repaint them too.
// _mix [a, b, t] = a moved t of the way to b, alpha from a.
private _mix = {
    params ["_a", "_b", "_t"];
    ([0, 1, 2] apply {(_a # _x) + ((_b # _x) - (_a # _x)) * _t}) + [_a param [3, 1]]
};
private _ground = _set # 0;
private _ink = _set # 1;
private _accent = _set # 2;
private _solidGround = [_ground # 0, _ground # 1, _ground # 2, 1];

switch (_token) do {
    case "ground": {_ground};
    case "ink": {_ink};
    case "accent": {_accent};
    case "line": {_set # 3};
    // the selected-row wash (accent-100)
    case "accentTint": {[_solidGround, _accent, TINT_ACCENT] call _mix};
    // hover / pressed on an accent fill (accent-600)
    case "accentHover": {[_accent, _ink, MIX_ACCENT_HOVER] call _mix};
    // accent at body size, where full accent is too light to read (accent-700)
    case "accentText": {[_accent, _ink, MIX_ACCENT_TEXT] call _mix};
    // reply meta on a selected row (accent-800)
    case "accentDeep": {[_accent, _ink, MIX_ACCENT_DEEP] call _mix};
    // the rail and badge-strip fill (surface / neutral-200)
    case "surface": {[_solidGround, _ink, TINT_SURFACE] call _mix};
    // secondary text (neutral-700) and micro-labels (neutral-600)
    case "muted": {[_ink, _solidGround, MIX_MUTED] call _mix};
    case "dim": {[_ink, _solidGround, MIX_DIM] call _mix};
    // a report card's GREEN and YELLOW swatches - fixed hues, the one place a
    // scheme does not repaint, because GREEN must still read as green on it
    case "swatchGreen": {SWATCH_GREEN};
    case "swatchYellow": {SWATCH_YELLOW};
    default {_set};
};
