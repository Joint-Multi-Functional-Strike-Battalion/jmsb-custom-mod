#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setActive", client: makes a net the voice API's active net - the
 * set that hears it becomes the picked set and the net its active channel
 * (fnc_selectNet), so the set's own PTT keys it. A net no set hears yet is
 * looked for in the handheld's fill, then the long range set's.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["C2"] call jmfsb_adapter_tfar_fnc_setActive
 *
 * Public: No
 */

params [["_net", "", [""]]];

if (_net isEqualTo "") exitWith {false};
private _slot = GVAR(slots) getOrDefault [_net, []];
private _try = [NODE_SR, NODE_LR];
if (_slot isNotEqualTo []) then {
    _try = [[NODE_LR, NODE_SR] select ((_slot select 0) isEqualTo NODE_SR)];
};

private _done = false;
{
    if ([_net, _x] call FUNC(selectNet)) exitWith {
        GVAR(activeKind) = _x;
        _done = true;
    };
} forEach _try;

if (_done) then {[[], -1] call FUNC(poll)};
_done
