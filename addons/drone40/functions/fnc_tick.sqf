#include "script_component.hpp"
/*
 * Author: YonV
 * Server, every TICK_S: each deployed drone40 variant is
 *
 *   gone    when it is deleted (picked up) or dead - FUNC(remove);
 *   orphaned when its launcher is no longer a player (left, died) - its
 *           node is put up again with no holder (FUNC(deploy));
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
private _orphans = [];
{
    _y params ["_drone", "_role", "_powered"];
    if (isNull _drone || {!alive _drone}) then {
        _gone pushBack _x;
        continue;
    };

    // THE LAUNCHER LEFT (review L3): RF drops a node whose holder is gone, and
    // a dead or disconnected holder gets no slice. The drone stays up, so its
    // node is put up again with no holder. A jammer has no node.
    private _launcher = _drone getVariable QGVAR(launcher);
    if (_role isNotEqualTo ROLE_JAMMER && {!isNil "_launcher"} && {!isPlayer _launcher}) then {
        _orphans pushBack [_x, _drone];
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

{
    _x params ["_id", "_drone"];
    [_id] call FUNC(remove);
    _drone setVariable [QGVAR(launcher), nil];
    _drone setVariable [QGVAR(id), nil];
    [_drone, objNull] call FUNC(deploy);
} forEach _orphans;
