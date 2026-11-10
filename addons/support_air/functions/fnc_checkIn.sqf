#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a CAS aircraft on station checks in, in the thread it was sent there
 * by (DESIGN_SUPPORT_MESSAGING 1.1, user 2026-11-01) - an AIRFRAME CHECK-IN
 * filed as the aircraft by the support core's filler (EFUNC(support,checkIn)).
 * Every CAS aircraft, not the fixed-wing only (user, 2026-11-02: "in the
 * support system an aircraft when it arrives on station needs to send an
 * AIRFRAME CHECK-IN"):
 *
 *   a fixed-wing    at its off-map hold          CHECKIN_REMARKS_HOLD
 *   a helicopter    over the grid (SAD, LOITER)  CHECKIN_REMARKS_GRID
 *   a helicopter    its thread's ATTACK RUN held CHECKIN_REMARKS_SHORT
 *                   short of the target
 *
 * Once a sortie: back at the hold after a strike, or moved on station, it does
 * not check in again. A sortie the board launched has no thread and checks in
 * nowhere.
 *
 * What this module gives the card: its call sign (the old doc's T8), the
 * station (the hold, or the point it holds short at), the station height
 * (EFUNC(support,flightHeight); a run held short - its own), the minutes left
 * (no more than the module's Time on Station for a run, as from its first
 * pass). The airframe, ordnance, capabilities and laser code the core reads
 * off the aircraft; the abort code is the core's, kept here.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The sortie's state <HASHMAP>
 * 3: Where it holds, [] for the sortie's hold <ARRAY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_checkIn
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_at", [], [[]]]];

if (!isServer || {isNull _logic}) exitWith {};
private _threadId = _logic getVariable [QGVAR(sortieThread), ""];
if (_threadId isEqualTo "") exitWith {};
if (_st getOrDefault ["checkedIn", false]) exitWith {};
_st set ["checkedIn", true];

private _fw = _st getOrDefault ["fw", false];
private _short = (_st get "phase") isEqualTo "short";
if (_at isEqualTo []) then {_at = _st getOrDefault ["hold", []]};

private _left = (_st get "until") - CBA_missionTime;
if (_short) then {_left = _left min (_logic getVariable [QGVAR(stationTime), SORTIE_TIMEOUT])};
private _alt = [[_veh, FLY_STATION] call EFUNC(support,flightHeight), -1] select _short;
private _remarks = [[CHECKIN_REMARKS_GRID, CHECKIN_REMARKS_HOLD] select _fw, CHECKIN_REMARKS_SHORT] select _short;

private _abort = [
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _threadId,
    _veh,
    _logic getVariable [QGVAR(callsign), "AIR"],
    _at,
    _alt,
    (_left max 0) / SECONDS_PER_MINUTE,
    _remarks
] call EFUNC(support,checkIn);
_logic setVariable [QGVAR(abortCode), _abort];
