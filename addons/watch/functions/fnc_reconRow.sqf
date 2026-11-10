#include "script_component.hpp"
/*
 * Author: YonV
 * The recon profile's readout for one contact: in sight or lost and for how
 * long, range and bearing from the player, the age of the last SPOTREP he
 * sent on it (design recon row_line_2 / row_line_3).
 *
 * Arguments:
 * 0: The contact <OBJECT>
 *
 * Return Value:
 * [name, state word, colour, [line 2, line 3], live] <ARRAY>
 *
 * Example:
 * [_obj] call jmfsb_watch_fnc_reconRow
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

private _entry = GVAR(contactList) param [GVAR(contactList) findIf {(_x # 0) isEqualTo _obj}, []];
_entry params ["", "", "", "", ["_pos", getPosASL _obj], ["_seen", serverTime], ["_los", true]];
private _at = ASLToAGL _pos;
private _reported = _obj getVariable [QGVAR(reportedAt), -1];
[
    toUpper ([_obj, "recon"] call FUNC(contactName)),
    ["LOST " + ([serverTime - _seen, "MM:SS"] call BIS_fnc_secondsToString), "IN SIGHT"] select _los,
    [COLOUR_GREY, COLOUR_RED] select _los,
    [
        format ["RANGE %1 M   BRG %2", round (player distance _at), [round (player getDir _at), 3] call CBA_fnc_formatNumber],
        format ["SPOTREP %1", ["-", [serverTime - _reported, "MM:SS"] call BIS_fnc_secondsToString] select (_reported >= 0)]
    ],
    _los
]
