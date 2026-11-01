#include "script_component.hpp"
/*
 * Author: JMSB
 * ACE > Jammer > Disable: kneel at the terminal for the disable time, then
 * the server ends its zone for good (FUNC(disableSite)). Walking off or
 * being interrupted cancels it; the site goes on jamming.
 *
 * Arguments:
 * 0: The terminal <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorObject, player] call jmfsb_jamming_fnc_disableStart
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if !([_obj, _unit] call FUNC(canDisable)) exitWith {};

if (isNull objectParent _unit) then {
    [_unit] call ace_common_fnc_goKneeling;
};

[
    GVAR(disableTime),
    [_obj, _unit],
    {
        (_this select 0) params ["_obj", "_unit"];
        if !([_obj, _unit] call FUNC(canDisable)) exitWith {
            ["JAMMER", "Already off the air.", NOTIFY_WARN] call EFUNC(notify,notify);
        };
        // By remoteExec: the server checks who and where (review R1).
        [_obj, _unit] remoteExecCall [QFUNC(disableSite), SERVER_OWNER];
    },
    {
        ["JAMMER", "Stopped - the site is still jamming.", NOTIFY_WARN] call EFUNC(notify,notify);
    },
    "Disabling jammer...",
    {
        (_this select 0) params ["_obj", "_unit"];
        alive _unit && {alive _obj} && {_unit distance _obj <= DISABLE_RANGE}
    },
    ["isNotInside"]
] call ace_common_fnc_progressBar;
