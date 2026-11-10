#include "script_component.hpp"
/*
 * Author: YonV
 * A leader died to something that was not a player - crossfire, a mine,
 * ALiVE's own war - and the network quietly promotes a successor.
 *
 * THE CHAIN IS ONLY EVER CUT BY PLAYERS. A kill nobody earned would end a
 * hunt nobody got to run, so the record keeps its index and gets a new man
 * in a new safe house. The corpse stops being worth searching - the phone
 * travels with the succession, not the body - and his car is cleared away
 * if nobody is in it, or the map fills with orphaned sedans.
 *
 * Arguments:
 * 0: Leader index <NUMBER>
 * 1: The dead man <OBJECT>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["_i", ["_old", objNull, [objNull]]];

if (_i < 0 || {_i >= count GVAR(leaders)}) exitWith {};

private _rec = GVAR(leaders) select _i;
if ((_rec select 2) isNotEqualTo "up") exitWith {};

if (!isNull _old) then {
    _old setVariable ["jmfsb_hacking_carriesPhone", nil, true];

    private _car = _old getVariable [QGVAR(car), objNull];
    if (!isNull _car && {(crew _car) isEqualTo []}) then {deleteVehicle _car};
};

private _fresh = [_i] call FUNC(spawnLeader);

// The faction can genuinely have nobody left to send - then the chain loses
// him for real, by the same door a player kill uses.
if ((_fresh select 2) isNotEqualTo "up") exitWith {
    [_i, "dead"] call FUNC(down);
};

GVAR(leaders) set [_i, _fresh];

INFO_1("leader %1 died to no player - replaced",_i + 1);

["NETWORK", format ["Leader %1 is dead - not by our hand. The network is already moving a successor.", _i + 1]] call EFUNC(notify,broadcast);

[] call FUNC(save);
