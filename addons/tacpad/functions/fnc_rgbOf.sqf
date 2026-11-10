#include "script_component.hpp"
/*
 * Author: YonV
 * A colour written down, as RGBA. The other half of FUNC(hexOf).
 *
 * HEX OR r,g,b. The design writes its tokens as #F3F2F2 and that is what anyone
 * picking a colour has in their hand; the older "0.95,0.95,0.95" form still
 * parses, because someone's profile has it in there already. A hash is optional
 * and so is the whitespace.
 *
 * Anything it cannot read comes back as the fallback rather than as black - a
 * half-filled custom scheme should be a usable one, not a panel painted
 * invisible.
 *
 * Arguments:
 * 0: "#RRGGBB", "RRGGBB" or "r,g,b" <STRING>
 * 1: Returned when the string cannot be read <ARRAY> (optional, default [0,0,0,1])
 *
 * Return Value:
 * RGBA <ARRAY>
 *
 * Example:
 * private _accent = ["#EC3013"] call jmfsb_tacpad_fnc_rgbOf
 *
 * Public: Yes
 */

params [["_text", "", [""]], ["_fallback", [0, 0, 0, 1], [[]]]];

private _hex = toUpper (_text splitString " #" joinString "");

if (count (toArray _hex) == 6 && {_hex regexMatch "[0-9A-F]{6}"}) exitWith {
    private _digits = "0123456789ABCDEF";
    private _fnc_byte = {
        params ["_pair"];
        16 * (_digits find (_pair select [0, 1])) + (_digits find (_pair select [1, 1]))
    };

    [
        ([_hex select [0, 2]] call _fnc_byte) / 255,
        ([_hex select [2, 2]] call _fnc_byte) / 255,
        ([_hex select [4, 2]] call _fnc_byte) / 255,
        1
    ]
};

private _parts = (_text splitString " ,") select {_x != ""};
if (count _parts < 3) exitWith {_fallback};

[parseNumber (_parts # 0), parseNumber (_parts # 1), parseNumber (_parts # 2), 1]
