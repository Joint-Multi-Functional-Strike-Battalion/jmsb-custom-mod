#include "script_component.hpp"
/*
 * Author: YonV
 * A player's nets AS THE SERVER HAS THEM: the radio nets of his RF fill from
 * the published roster, and every CALL he is on or ringing on from the
 * published call table. Nothing of this machine's own reading of his group,
 * squad or plan goes in - a stale or JIP view here cannot drop a net the
 * server gave him (PLAN_VOICE_EW_PLAY V6). VEH and DIRECT are not listed:
 * they are where he stands, not a membership.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Net ids <ARRAY of STRINGs>
 *
 * Example:
 * [_unit] call jmfsb_voice_fnc_rosterNets
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};
private _out = +((GVAR(rosterIndex) getOrDefault [getPlayerUID _unit, [objNull, "", [], 0]]) select 2);
{
    _x params ["", "_slot", "", "_members", "_ringing"];
    if (_unit in _members || _unit in _ringing) then {_out pushBack format [CALL_FORMAT, _slot]};
} forEach GVAR(callTable);
_out
