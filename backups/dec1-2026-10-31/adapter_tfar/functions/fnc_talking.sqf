#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "talking", client: the other players this one hears on his TFAR
 * nets now. A speaker pushes his own key-down and key-up to his side
 * (fnc_tangent -> fnc_keyed); he counts as talking while his key is down, he
 * is alive, and the net he keys is one this player's sets hear (fnc_voiceView).
 * TFAR's range is TFAR's: a speaker out of its reach is still listed while he
 * keys a net this player is on.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[unit, net], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_talking
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
