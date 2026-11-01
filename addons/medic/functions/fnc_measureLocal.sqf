#include "script_component.hpp"
/*
 * Author: JMSB
 * Takes a hand reading on the machine where the patient is local, and
 * publishes it on him - value, mission time and who took it - so every medic
 * in the section sees the same "last measured" line. Sent by the server
 * (FUNC(srvMeasure)) by remoteExec and taken only from it (review R1).
 *
 * A LIMB UNDER A TOURNIQUET HAS NO PULSE. A check taken on a tourniqueted arm
 * reads zero, the way ACE's own pulse and pressure checks do.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Kind - "hr", "bp" or "rr" <STRING>
 * 2: Body part the check was made on <STRING>
 * 3: Name of the medic <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_patient, "hr", "leftarm", "Smith"] call jmfsb_medic_fnc_measureLocal
 *
 * Public: No
 */

params [["_patient", objNull, [objNull]], ["_kind", "", [""]], ["_bodyPart", "", [""]], ["_by", "", [""]]];

if (isNull _patient || {!local _patient}) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("measureLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

private _slot = CHECK_KINDS find _kind;
if (_slot < 0) exitWith {};

private _part = BODY_PARTS find _bodyPart;
private _tourniquets = _patient getVariable [ACEV_TOURNIQUETS, []];
private _blocked = _part > -1 && {(_tourniquets param [_part, 0]) isNotEqualTo 0};

private _value = switch (_kind) do {
    case "hr": {
        [round (_patient getVariable [ACEV_HEART_RATE, 0]), 0] select _blocked
    };
    case "bp": {
        [(_patient getVariable [ACEV_BLOOD_PRESSURE, [0, 0]]) apply {round _x}, [0, 0]] select _blocked
    };
    default {
        round (_patient getVariable [ACMV_RESP_RATE, 0])
    };
};

_patient setVariable [CHECK_VARS select _slot, [_value, CBA_missionTime, _by], true];
