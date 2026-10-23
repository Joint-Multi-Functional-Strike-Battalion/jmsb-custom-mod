#include "script_component.hpp"
/*
 * Author: JMSB
 * Steps the active net left or right through the local player's nets (the
 * device arrows, numpad 0 / .), skipping a net the adapter cannot select.
 * Under TFAR / ACRE the nets are that radio's (fnc_externalTick).
 *
 * Arguments:
 * 0: Direction, +1 or -1 <NUMBER>
 *
 * Return Value:
 * The new active net id <STRING>
 *
 * Example:
 * [1] call jmfsb_voice_fnc_stepActive
 *
 * Public: Yes
 */

params [["_dir", 1, [0]]];

private _ids = GVAR(myNets) apply {_x select 0};
private _n = count _ids;
if (_n == 0) exitWith {GVAR(activeNetId)};
_dir = [-1, 1] select (_dir >= 0);
private _from = _ids find GVAR(activeNetId);
if (_from < 0 && _dir < 0) then {_from = 0};

for "_k" from 1 to _n do {
    private _next = _ids select ((((_from + _dir * _k) mod _n) + _n) mod _n);
    if ([_next] call FUNC(setActive)) exitWith {};
};
GVAR(activeNetId)
