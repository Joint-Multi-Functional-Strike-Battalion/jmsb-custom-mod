#include "script_component.hpp"
/*
 * Author: JMSB
 * Every net a set of this kind can carry, with the frequency it is carried on:
 * the plan's nets of that kind (fnc_planNets) and any other net this player
 * has had loaded by a fill (fnc_fill). The reverse of fnc_netFrequency - what
 * lets a channel's frequency be read back as a net (fnc_radioNets).
 *
 * Arguments:
 * 0: Kind of set "sr" | "lr" <STRING>
 * 1: The plan, if the caller already has it <ARRAY> (default: read it)
 *
 * Return Value:
 * [[net id, frequency key (FREQ_KEY), plan channel or NO_CHANNEL], ...] <ARRAY>
 *
 * Example:
 * ["sr"] call jmfsb_adapter_tfar_fnc_netTable
 *
 * Public: No
 */

params [["_kind", NODE_SR, [""]], ["_plan", nil, [[]]]];

if (isNil "_plan") then {_plan = [] call FUNC(planNets)};

private _out = [];
{
    _x params ["_id", "", "_netKind", "_channel"];
    if (_netKind isEqualTo _kind) then {
        private _freq = [_id, _kind, _plan] call FUNC(netFrequency);
        _out pushBack [_id, FREQ_KEY(_freq), _channel];
    };
} forEach _plan;

{
    private _id = _x;
    if ((_out findIf {(_x select 0) isEqualTo _id}) < 0) then {
        private _freq = [_id, _kind, _plan] call FUNC(netFrequency);
        _out pushBack [_id, FREQ_KEY(_freq), NO_CHANNEL];
    };
} forEach (GVAR(fillNets) getOrDefault [_kind, []]);

_out
