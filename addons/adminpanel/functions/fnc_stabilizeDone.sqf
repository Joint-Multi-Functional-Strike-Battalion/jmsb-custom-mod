#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the patient's machine says what STABILIZE did (FUNC(stabilizeLocal)),
 * and the admin who asked is told. Taken only from the machine that holds the
 * patient, and only while the server is waiting for that patient's answer -
 * the admin is the one the server kept, never one the sender names (review R1:
 * this was the notify post event, which any client could aim at anyone).
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: What was done <STRING>
 * 2: Something failed <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "Bob: bandaged", false] remoteExecCall ["jmfsb_adminpanel_fnc_stabilizeDone", 2]
 *
 * Public: No
 */

params [["_patient", objNull, [objNull]], ["_said", "", [""]], ["_failed", false, [false]]];

if (!isServer || isNull _patient || _said isEqualTo "") exitWith {};
if !([_patient] call EFUNC(common,senderIs)) exitWith {
    WARNING_1("stabilizeDone: refused - machine %1 does not hold the patient",remoteExecutedOwner);
};

private _pending = localNamespace getVariable [QGVAR(stabilizePending), createHashMap];
(_pending getOrDefault [netId _patient, [objNull, -1]]) params ["_admin", "_until"];
_pending deleteAt (netId _patient);
if (isNull _admin) exitWith {};
if (CBA_missionTime > _until) exitWith {};

["Admin Panel", _said, [NOTE_DONE, NOTE_FAIL] select _failed, _admin] call EFUNC(notify,broadcast);
