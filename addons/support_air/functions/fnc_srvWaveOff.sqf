#include "script_component.hpp"
/*
 * Author: YonV
 * Server: WAVE OFF from aboard (user, 2026-11-08: "on insertion add a wave off
 * scroll command", "then send a notice to who tole the flight to wave off").
 * The sender is checked as FUNC(canWaveOff) does. The insertion goes around:
 * ropes in (ACE's cut, the rappel's taken in - a man already on one finishes
 * his slide), the flight control let go, the leg flown again straight at the
 * LZ (its ROUTE is behind it), and on the way the LZ STATUS? asked again -
 * holding short until it is answered (FUNC(liftTick)). Everyone on the side
 * gets the notice, upper right.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [vehicle player] remoteExecCall ["jmfsb_support_air_fnc_srvWaveOff", 2]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (!isServer || {isNull _veh}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_who", "_uid"];
if (isNull _who) exitWith {
    WARNING_1("srvWaveOff: refused - machine %1 has no player",_owner);
};
if !(_who in crew _veh) exitWith {
    WARNING_2("srvWaveOff: refused - %1 is not aboard %2",name _who,_veh);
};
private _logic = _veh getVariable [QGVAR(owner), objNull];
if (isNull _logic || !(_logic in (missionNamespace getVariable [QGVAR(entities), []]))) exitWith {
    WARNING_2("srvWaveOff: refused - %1 from %2 is not a support transport",_veh,name _who);
};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
if (count _job isEqualTo 0 || {(_veh getVariable [QGVAR(waveOff), []]) isEqualTo []}) exitWith {
    INFO_2("srvWaveOff: %1 - %2 is not on an insertion",name _who,_logic getVariable [ARR_2(QGVAR(callsign),"AIR")]);
};
private _issuer = _job getOrDefault ["issuer", objNull];
if (_uid isNotEqualTo (getPlayerUID _issuer) && {(leader group _who) isNotEqualTo _who}) exitWith {
    WARNING_2("srvWaveOff: refused - %1 is not the issuer or a group leader (%2)",name _who,_job getOrDefault [ARR_2("thread","")]);
};

// THE GO-AROUND (FUNC(liftGoAround), shared with the GO AROUND command since
// 2026-11-09): ropes in, the leg again straight at the LZ, LZ STATUS? asked on
// the way.
private _lz = [_logic] call FUNC(liftGoAround);
if (_lz isEqualTo "") exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
INFO_3("srvWaveOff: %1 waved off by %2 (%3)",_callsign,name _who,_job getOrDefault [ARR_2("thread","")]);
// Everyone on the side gets the notice (user, 2026-11-08: "ever one gets the
// wave off notice"), one FLASH popup - not FUNC(say) as well, never twice.
[format ["%1 WAVED OFF BY %2 - GOING AROUND, HOLDING SHORT OF %3", _callsign, toUpper name _who, _lz]] remoteExecCall [QEFUNC(support,alertLocal), _logic getVariable [QGVAR(side), sideUnknown]];
