#include "script_component.hpp"
/*
 * Author: YonV
 * ACE > Jammer > Hack: puts this terminal on the HACK board as the selected
 * device (jmfsb_hacking_fnc_selectTarget) and opens the board - on the tablet
 * where there is one, else on the map - so the hack runs there with its own
 * clock, fail roll and product pick. A hack that completes ends the zone, as
 * it always has (FUNC(pruneJammers)).
 *
 * Arguments:
 * 0: The terminal <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value:
 * The board was opened <BOOL>
 *
 * Example:
 * [cursorObject, player] call jmfsb_jamming_fnc_hackStart
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNil QEFUNC(hacking,selectTarget)) exitWith {false};
if !([_obj, "tower"] call EFUNC(hacking,selectTarget)) exitWith {
    ["HACK", "A hack is already running.", NOTIFY_WARN] call EFUNC(notify,notify);
    false
};

private _open = {["hack", [], true] call EFUNC(tacpad,openApp)};
if (!isNil QEFUNC(devices,open)) then {
    if (["large"] call EFUNC(devices,open)) then {
        [_open] call CBA_fnc_execNextFrame;
    };
} else {
    openMap true;
    [_open] call CBA_fnc_execNextFrame;
};
true
