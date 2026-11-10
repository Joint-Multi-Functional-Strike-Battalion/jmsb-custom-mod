#include "script_component.hpp"
/*
 * Author: YonV
 * Server: ALL IN from the ACE self action or the scroll action aboard a support
 * helicopter (user, 2026-11-02: "troop load, all in (need an ace interaction
 * while in heli for all in)"; 2026-11-06: "or scroll action") - reached by
 * remoteExecCall from either (XEH_postInit). The
 * sender is the sending machine's own player (EFUNC(common,sender)), never the
 * arguments: he must be inside the helicopter, the helicopter loading at the
 * pickup of its module's lift job (JOB_ALL_IN), and he the request's issuer or
 * the leader of his group. Then the troop load is done and it lifts - the same
 * as the `allin` reply (FUNC(liftReply), FUNC(transportStep)).
 *
 * Arguments:
 * 0: The helicopter <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [vehicle player] remoteExecCall ["jmfsb_support_air_fnc_srvAllIn", 2]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (!isServer || {isNull _veh}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_who", "_uid"];
if (isNull _who) exitWith {
    WARNING_1("srvAllIn: refused - machine %1 has no player",_owner);
};
if !(_who in crew _veh) exitWith {
    WARNING_2("srvAllIn: refused - %1 is not aboard %2",name _who,_veh);
};

private _logic = _veh getVariable [QGVAR(owner), objNull];
if (isNull _logic || !(_logic in (missionNamespace getVariable [QGVAR(entities), []]))) exitWith {
    WARNING_2("srvAllIn: refused - %1 from %2 is not a support helicopter",_veh,name _who);
};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if ((_job getOrDefault ["step", ""]) isNotEqualTo JOB_ALL_IN) exitWith {
    INFO_2("srvAllIn: %1 - %2 is not loading at a pickup",name _who,_logic getVariable [ARR_2(QGVAR(callsign),"AIR")]);
};

private _issuer = _job getOrDefault ["issuer", objNull];
private _isIssuer = _uid isEqualTo (getPlayerUID _issuer);
if (!_isIssuer && (leader group _who) isNotEqualTo _who) exitWith {
    WARNING_2("srvAllIn: refused - %1 is not the issuer or a group leader (%2)",name _who,_job getOrDefault [ARR_2("thread","")]);
};

_job set ["allIn", true];
INFO_3("srvAllIn: %1 all in by %2 (%3)",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],name _who,_job getOrDefault [ARR_2("thread","")]);
[_logic, format ["all in by %1, lifting", name _who], "normal", _issuer] call FUNC(say);
