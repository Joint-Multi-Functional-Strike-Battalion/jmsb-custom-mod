#include "script_component.hpp"
/*
 * Author: JMSB
 * The call a unit is in, as a member or ringing. The server reads its own
 * call registry; a client reads the published table.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Call id, "" when in none <STRING>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_inCall
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {""};

private _found = "";
if (isServer) then {
    {
        if (_unit in (_y get "members") || {((_y get "ringing") findIf {(_x select 0) isEqualTo _unit}) >= 0}) exitWith {_found = _x};
    } forEach GVAR(calls);
} else {
    private _i = GVAR(callTable) findIf {_unit in (_x select 3) || _unit in (_x select 4)};
    if (_i >= 0) then {_found = (GVAR(callTable) select _i) select 0};
};
_found
