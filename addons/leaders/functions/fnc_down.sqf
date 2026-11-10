#include "script_component.hpp"
/*
 * Author: YonV
 * A leader is spent - killed by a player, or delivered to a prison. FINITE
 * once a PLAYER spends him: nothing replaces him and the asymmetric pool
 * loses its share. A death no player earned goes through FUNC(replace)
 * instead and never reaches here.
 *
 * THE CUT IS REPORTED WHETHER OR NOT IT CAN BE APPLIED. Writing into ALiVE's
 * force accounting is not part of the verified surface, so the honest thing
 * is to state the loss and let the campaign see it, rather than pretend a
 * number changed somewhere.
 *
 * Arguments:
 * 0: Leader index <NUMBER>
 * 1: How - "dead" or "captured" <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_i", "_how"];

if (_i < 0 || {_i >= count GVAR(leaders)}) exitWith {};

private _rec = GVAR(leaders) select _i;
if ((_rec select 2) isNotEqualTo "up") exitWith {};
_rec set [2, _how];

private _left = {(_x select 2) isEqualTo "up"} count GVAR(leaders);

INFO_3("leader %1 %2 - pool cut %3%%",_i + 1,_how,GVAR(poolCut));

["NETWORK", format ["Leader %1 is %2. %3",
    _i + 1,
    ["off the board", "in custody"] select (_how isEqualTo "captured"),
    [format ["%1 still out there.", _left], "That was the last of them."] select (_left <= 0)
]] call EFUNC(notify,broadcast);

missionNamespace setVariable [QGVAR(upCount), _left, true];

[] call FUNC(save);
