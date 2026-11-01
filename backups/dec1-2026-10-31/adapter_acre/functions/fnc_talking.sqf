#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "talking", client: the other players talking on a radio now
 * whose net is one of his radios' nets (fnc_heard keeps them from ACRE's
 * remote speaking events). Whether he really hears them is ACRE's signal
 * model's business; this lists the transmissions on his nets.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[unit, net], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_acre_fnc_talking
 *
 * Public: No
 */

private _mine = GVAR(nets) apply {_x select 0};
private _out = [];
private _gone = [];
{
    _y params ["_unit", "_net"];
    if (isNull _unit || {!alive _unit}) then {
        _gone pushBack _x;
        continue;
    };
    if (_net in _mine) then {_out pushBack [_unit, _net]};
} forEach GVAR(heard);
{GVAR(heard) deleteAt _x} forEach _gone;

_out
