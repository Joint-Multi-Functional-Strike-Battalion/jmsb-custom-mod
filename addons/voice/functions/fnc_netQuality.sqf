#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: how well the local player reaches a net of his, 0 to 1 - the colour
 * round a net chip on the devices (user, 2026-10-21: "put net state as a
 * color around the net chips"). A radio net: the best quality any of his
 * nodes has to a peer on it; a CALL: the best link on DATA to another member.
 * VEH and DIRECT always 1. Above 0 is reachable (FUNC(reachable)).
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Quality 0-1 <NUMBER>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_netQuality
 *
 * Public: Yes
 */

params [["_net", "", [""]]];

private _kind = [_net] call FUNC(netKind);
if (_kind in [KIND_VEH, KIND_DIRECT]) exitWith {1};

private _best = 0;
if (_kind isEqualTo KIND_CALL) exitWith {
    private _slot = parseNumber (_net select [count CALL_PREFIX]);
    private _i = GVAR(callTable) findIf {(_x select 1) isEqualTo _slot};
    private _row = if (_i < 0) then {[]} else {GVAR(callTable) select _i};
    {
        _best = _best max ([_x, NET_DATA] call FUNC(linkQuality));
    } forEach (((_row param [3, []]) + (_row param [4, []])) - [player]);
    _best
};

{
    _best = _best max ([_x, _net] call EFUNC(rf,quality));
} forEach GVAR(myNodes);
_best
