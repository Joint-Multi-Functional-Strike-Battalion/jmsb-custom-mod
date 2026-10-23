#include "script_component.hpp"
/*
 * Author: JMSB
 * Who a quick add offers (DESIGN_VOICE.md, "Add people": the recent contacts
 * list, and the walking view's F2 quick add): the people of the player's recent
 * calls first, newest first (GVAR(radioRecent), kept by FUNC(radioCalls)), then
 * his own group, then everyone else in the voice contacts - only those in reach,
 * never himself, never anyone already on the call.
 *
 * Arguments:
 * 0: Units to leave out <ARRAY> (optional, default [])
 *
 * Return Value:
 * Units, in offer order <ARRAY of OBJECTs>
 *
 * Example:
 * private _offer = [_members] call jmfsb_tacpad_apps_fnc_radioQuick
 *
 * Public: No
 */

params [["_exclude", [], [[]]]];

if (isNil QEFUNC(voice,contacts)) exitWith {[]};

private _me = call CBA_fnc_currentUnit;
private _reach = [];
{
    _x params [["_unit", objNull, [objNull]], "", "", "", ["_ok", false, [false]]];
    if (_ok && {!isNull _unit} && _unit isNotEqualTo _me) then {_reach pushBack _unit};
} forEach ([] call EFUNC(voice,contacts));

private _recent = (missionNamespace getVariable [QGVAR(radioRecent), []]) select {_x in _reach};
private _team = _reach select {group _x isEqualTo group _me};
private _out = _recent + _team + _reach;
_out = _out arrayIntersect _out;

_out - _exclude
