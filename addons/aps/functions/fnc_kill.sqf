#include "script_component.hpp"
/*
 * Author: JMSB
 * One launcher charge kills one incoming round: the round is deleted, a
 * flash goes off where it died, and the charge is spent and reported.
 *
 * The round is deleted on the machine that owns it as well as here: a
 * player's rocket is local to him, and a delete on the server alone may
 * leave his copy flying on into the hull.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Projectile <OBJECT>
 * 2: Charge pool variable (left or right side) <STRING>
 * 3: Bearing the round came from, relative to the turret (deg) <NUMBER>
 * 4: Where the flash goes, ATL <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, _p, QGVAR(ammoR), 10, getPosATL _p] call jmfsb_aps_fnc_kill
 *
 * Public: No
 */

params ["_veh", "_p", "_pool", "_rel", "_at"];

if (GVAR(debug)) then { INFO_3("%1 killed %2 from %3 deg",typeOf _veh,typeOf _p,round _rel) };

if (!isNull _p && {!local _p}) then {
    [_p] remoteExecCall ["deleteVehicle", _p];
};
deleteVehicle _p;

createVehicle [QGVAR(blast), _at, [], 0, "CAN_COLLIDE"];

_veh setVariable [_pool, ((_veh getVariable [_pool, 0]) - 1) max 0, true];
[_veh, _rel, "INTERCEPT"] remoteExec [QFUNC(report), [0, -2] select isDedicatedServer];
