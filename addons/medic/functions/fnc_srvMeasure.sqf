#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a medic's hand check (FUNC(recordCheck), by remoteExec). The medic
 * is the sender himself and must be alive and within CHECK_RANGE of the
 * patient; then the reading is taken on the patient's machine
 * (FUNC(measureLocal), which takes a remote call only from the server).
 *
 * Review R1: it was the measure CBA event, so any client could stamp a check
 * on anyone with any medic's name, from anywhere.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Kind - "hr", "bp" or "rr" <STRING>
 * 2: Body part the check was made on <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_patient, "hr", "leftarm"] remoteExecCall ["jmfsb_medic_fnc_srvMeasure", 2]
 *
 * Public: No
 */

params [["_patient", objNull, [objNull]], ["_kind", "", [""]], ["_bodyPart", "", [""]]];

if (!isServer || {isNull _patient} || {!(_kind in CHECK_KINDS)}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_medic"];
if (isNull _medic || {!alive _medic} || {_medic distance _patient > CHECK_RANGE}) exitWith {
    WARNING_2("srvMeasure: refused - machine %1 is not a medic beside %2",_owner,_patient);
};

[_patient, _kind, _bodyPart, name _medic] remoteExecCall [QFUNC(measureLocal), _patient];
