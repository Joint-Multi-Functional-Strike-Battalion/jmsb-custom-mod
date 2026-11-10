#include "script_component.hpp"
/*
 * Author: YonV
 * The capture play: a handcuffed leader DELIVERED to a jmfsb_prison* marker
 * is spent as captured - and talks.
 *
 * Taking him alive is worth more than shooting him, which is the entire point
 * of the mechanic: the same leader is one node dead, or two nodes captured.
 *
 * With no prison marker the whole play is off, and that is said out loud
 * rather than leaving players carrying a prisoner to nowhere.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

private _prisons = allMapMarkers select {(toLower _x) find LEADERS_PRISON == 0};
if (_prisons isEqualTo []) exitWith {
    INFO("no jmfsb_prison marker - capture-and-deliver is off");
};

[{
    params ["_args", "_handle"];
    _args params ["_prisons"];

    {
        _x params ["_u", "", "_state"];
        if (_state isNotEqualTo "up") then {continue};
        if (isNull _u || {!alive _u}) then {continue};
        if !(_u getVariable ["ACE_captives_isHandcuffed", false]) then {continue};

        private _at = getPosATL _u;
        if ((_prisons findIf {(getMarkerPos _x) distance2D _at < LEADERS_PRISON_R}) > -1) then {
            [_u getVariable [QGVAR(index), -1], "captured"] call FUNC(down);
            [] call FUNC(reveal);
        };
    } forEach GVAR(leaders);
}, LEADERS_PRISON_TICK, [_prisons]] call CBA_fnc_addPerFrameHandler;
