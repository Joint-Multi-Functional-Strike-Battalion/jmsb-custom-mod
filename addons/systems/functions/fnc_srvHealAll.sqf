#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the Heal All action on a heal object (FUNC(addHealall)). Every
 * player within HEALALL_RADIUS of the object is fully healed and told so.
 *
 * Review R1: the healed were told by the notify post CBA event, which any
 * client could aim at anyone with any text. The action now comes here by
 * remoteExec; the caller is the sender's own unit, and he must be alive and
 * at the object.
 *
 * Arguments:
 * 0: The heal object <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_target] remoteExecCall ["jmfsb_systems_fnc_srvHealAll", 2]
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

if (!isServer || isNull _object) exitWith {};
([] call JMFSBFUNC(common,sender)) params ["_owner", "_caller"];
if (isRemoteExecuted && {!alive _caller || _caller distance _object > HEALALL_CALLER_RANGE}) exitWith {
    WARNING_1("Systems","srvHealAll: refused - machine %1 is not at the heal object",_owner);
};

{
    [_x, _x] call ace_medical_treatment_fnc_fullHeal;
    ["Medical", "You have been healed.", NOTE_GOOD, _x] call JMFSBFUNC(notify,broadcast);
} forEach (allPlayers select {(_x distance _object) < HEALALL_RADIUS});
