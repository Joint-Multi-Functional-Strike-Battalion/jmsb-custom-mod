#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Kills a round this machine fired, on the server's word (FUNC(resolve)): the
 * round is deleted where it is and a harmless blast (GVAR(blast)) is made in
 * its place. Done HERE because this machine owns the round - it is the copy
 * that would do the damage. A round already landed or split is gone, and
 * nothing happens.
 *
 * Arguments:
 * 0: Shot id <STRING>
 *
 * Return Value: None
 *
 * Example:
 * ["2:14"] call jmfsb_adsite_fnc_kill
 *
 * Public: No
 */

params [["_id", "", [""]]];

private _proj = GVAR(owned) getOrDefault [_id, objNull];
GVAR(owned) deleteAt _id;
if (isNull _proj) exitWith {};

private _at = ASLToAGL getPosASL _proj;
deleteVehicle _proj;
createVehicle [QGVAR(blast), _at, [], 0, "CAN_COLLIDE"];
