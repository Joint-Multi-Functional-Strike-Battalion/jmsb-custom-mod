#include "script_component.hpp"
/*
 * Author: JMSB
 * Hook "talking": who is talking on which net, every frame - the speakers
 * who pushed their key (FUNC(keyed)) and have not released it, while they
 * live. Local voice keys no net and is not listed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[speaker, net id], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_talking
 *
 * Public: No
 */

private _out = [];
private _gone = [];
{
    _y params ["_unit", "_net"];
    if (isNull _unit || {!alive _unit}) then {
        _gone pushBack _x;
        continue;
    };
    if (_net isNotEqualTo LOCAL_NET) then {_out pushBack [_unit, _net]};
} forEach GVAR(keyed);
{GVAR(keyed) deleteAt _x} forEach _gone;
_out
