#include "script_component.hpp"
/*
 * Author: YonV
 * Killed, on an FPV (FUNC(fpvWatch)): the wreck stops where it blew and goes
 * next frame, crew with it (user, 2026-10-25: "despawn an exploded drone right
 * after it explodes").
 *
 * Arguments:
 * 0: The drone <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drone] call jmfsb_uas_fnc_fpvWreck
 *
 * Public: No
 */

params [["_drone", objNull, [objNull]]];

if (isNull _drone) exitWith {};

// STOPPED FIRST, in the Killed handler itself. A killed airframe keeps its
// velocity, and the Switchblade is a Greyhawk's weight of metal at 45-60 m/s:
// the fifth of a second this once waited was ten metres of wreck through the
// people it had just dived on (user, 2026-11-06: "the remains bounce around
// and kill folks"). The delete waits only for the frame to end - every other
// Killed handler, the IED Pelican's charge (FUNC(iedDrone)) among them, has
// run by then, and deleting from inside the Killed chain would hand the
// handlers after this one a null.
_drone setVelocity [0, 0, 0];
[{
    params ["_d"];
    if (isNull _d) exitWith {};
    {_d deleteVehicleCrew _x} forEach (crew _d);
    deleteVehicle _d;
}, [_drone]] call CBA_fnc_execNextFrame;
