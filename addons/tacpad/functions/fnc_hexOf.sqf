#include "script_component.hpp"
/*
 * Author: YonV
 * An RGBA array as the hex the design writes its tokens in - #F3F2F2.
 *
 * The settings screen shows the three tokens a scheme is made of, and a colour
 * shown as "0.953,0.949,0.949" is a colour nobody can compare against the swatch
 * beside it. FUNC(theme) reads hex back in, so this is the other half of one
 * round trip rather than a second way of writing a colour down.
 *
 * Arguments:
 * 0: RGBA, 0-1 each <ARRAY>
 * 1: Include the leading hash <BOOL> (optional, default true)
 *
 * Return Value:
 * Hex <STRING>
 *
 * Example:
 * private _hex = [[0.925, 0.188, 0.075, 1]] call jmfsb_tacpad_fnc_hexOf
 *
 * Public: Yes
 */

params [["_colour", [0, 0, 0, 1], [[]]], ["_hash", true, [false]]];

private _digits = "0123456789ABCDEF";

private _out = "";
{
    private _byte = round (255 * (0 max ((_colour param [_x, 0]) min 1)));
    _out = _out + (_digits select [floor (_byte / 16), 1]) + (_digits select [_byte mod 16, 1]);
} forEach [0, 1, 2];

(["", "#"] select _hash) + _out
