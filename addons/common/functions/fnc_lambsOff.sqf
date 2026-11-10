#include "script_component.hpp"
/*
 * Author: YonV
 * Takes one aircraft (and its crew's group) out of LAMBS Danger's hands.
 *
 * LAMBS is written for infantry in contact - take cover, suppress, flank,
 * flee the tank - and an aircraft that starts obeying any of it stops
 * flying the task it was given. A support helicopter that breaks off a
 * pickup to hide from a threat is not doing the job the player asked for,
 * and a CAS jet manoeuvring "autonomously" is one that never arrives.
 *
 * The variables are LAMBS' own, on the unit and on the group: the mod reads
 * them before it does anything, so setting them is the supported way to be
 * left alone. Harmless when LAMBS is not loaded - nothing reads them.
 *
 * Arguments:
 * 0: The vehicle or man <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_heli] call jmfsb_common_fnc_lambsOff
 *
 * Public: Yes
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj) exitWith {};
if (_obj getVariable [QGVAR(lambsOff), false]) exitWith {};
_obj setVariable [QGVAR(lambsOff), true];

_obj setVariable ["lambs_danger_disableAI", true, true];

// The crew's own group, not the vehicle's - a UAV's autonomy and a
// helicopter's pilots live in the group their crew is in.
{
    private _grp = group _x;
    if (isNull _grp) then {continue};
    _grp setVariable ["lambs_danger_disableGroupAI", true, true];
    _grp setVariable ["lambs_danger_disableAI", true, true];
    _x setVariable ["lambs_danger_disableAI", true, true];
} forEach ([_obj] + crew _obj);
