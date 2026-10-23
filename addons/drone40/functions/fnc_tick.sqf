#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, every TICK_S: each deployed drone40 variant is
 *
 *   gone    when it is deleted (picked up) or dead - FUNC(remove);
 *   powered while it has battery (fuel) - mirrored as RF "on", so a flat
 *           relay or decoy stops emitting and a recharged one starts again,
 *           and a flat jammer stops counting in FUNC(noise).
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_drone40_fnc_tick
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

private _gone = [];
{
    _y params ["_drone", "_role", "_powered"];
    if (isNull _drone || {!alive _drone}) then {
        _gone pushBack _x;
        continue;
    };

    private _power = (fuel _drone) > 0;
    if (_power isNotEqualTo _powered) then {
        _y set [2, _power];
        if (_role isNotEqualTo ROLE_JAMMER) then {
            [_x, [["on", _power]]] call EFUNC(rf,setState);
        };
    };
} forEach GVAR(drones);

{
    [_x] call FUNC(remove);
} forEach _gone;
