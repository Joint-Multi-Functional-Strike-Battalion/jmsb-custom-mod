#include "script_component.hpp"
/*
 * Author: JMSB
 * The people one group add would ring (DESIGN_VOICE.md, "Add people"): + MY
 * TEAM is the player's own group, the others are the voice contacts carrying
 * that group's tag (RADIO_GROUPS). Group adds skip anyone out of reach, so only
 * contacts the voice API marks reachable are answered; the cap at a call's
 * size is FUNC(radioDial)'s, which knows how many are on the call already.
 *
 * Arguments:
 * 0: Group id from RADIO_GROUPS - "team", "sl", "rto", "medic", "hq" <STRING>
 * 1: Units to leave out (already on the call) <ARRAY> (optional, default [])
 *
 * Return Value:
 * Units <ARRAY of OBJECTs>
 *
 * Example:
 * private _medics = ["medic"] call jmfsb_tacpad_apps_fnc_radioGroup
 *
 * Public: No
 */

params [["_id", "", [""]], ["_exclude", [], [[]]]];

if (isNil QEFUNC(voice,contacts)) exitWith {[]};

private _i = RADIO_GROUPS findIf {(_x select 0) isEqualTo _id};
if (_i < 0) exitWith {[]};
private _tag = (RADIO_GROUPS select _i) select 2;
private _me = call CBA_fnc_currentUnit;

private _out = [];
{
    _x params [["_unit", objNull, [objNull]], "", "", ["_tags", [], [[]]], ["_reach", false, [false]]];
    if (isNull _unit || !_reach || _unit isEqualTo _me || {_unit in _exclude}) then {continue};
    private _match = [_tag in _tags, group _unit isEqualTo group _me] select (_tag isEqualTo "");
    if (_match) then {_out pushBackUnique _unit};
} forEach ([] call EFUNC(voice,contacts));

_out
