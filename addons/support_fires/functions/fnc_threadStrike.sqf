#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a CALL FOR FIRE filed to a cruise missile or loitering munition
 * launcher's box (2026-11-01; user: the @ mention and the TO picker give them
 * the `callforfire` card, and they must act on it as artillery does) -
 * reached from FUNC(srvThread). The core has asked the issuer's tasking gate
 * and his side already; this asks the launcher's own questions again.
 *
 * THE CARD, field by field (EFUNC(support,readOrder), kind "fire"):
 *   Warno 1        FIRE FOR EFFECT, SUPPRESS, none ticked - one launch;
 *                  IMMEDIATE SUPPRESSION - at the launcher's quickest; ADJUST -
 *                  CANTCO "ADJUST NOT AVAILABLE" (no adjusting missile; with
 *                  CANNOT OBSERVE it is fired for effect, as by a battery)
 *   the target     CFF GRID, POLAR or SHIFT (2026-11-02), as for a battery.
 *                  None: "NO TARGET LOCATION"
 *   Engagement     its number is how many missiles / munitions, up to the
 *                  module's salvo (launch) size and what is left; none, one.
 *                  SMOKE or ILLUM - "NO STORES <shell>"; any other shell is
 *                  the warhead it carries
 *   Danger Close   the card's own threshold, as for a battery
 *   Control        AT MY COMMAND - laid, WILCO, it waits for CONFIRM; TIME ON
 *                  TARGET - a missile's first impact at the TOT line's time
 *                  (FUNC(threadTot)); a munition hunts, so "TOT NOT AVAILABLE";
 *                  anything else - fire when ready
 * Busy, rearming, spent, out of reach: the reach card's words (FUNC(reach)).
 * A munition searches the board's least radius (SEARCH_MIN) round the point.
 *
 * ACCEPTED: WILCO "ETA m:ss - <mission> - <n> MISSILES - TOF n S - <target>"
 * (a munition: "<n> MUNITIONS - TRANSIT n S", the ETA its time on station),
 * then the launch (FUNC(threadLaunch)) - or, AT MY COMMAND, the prompt for it.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fire <ARRAY>
 *
 * Example:
 * ["fires:2", _thread, _message, _issuer] call jmfsb_support_fires_fnc_threadStrike
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]]
];

if (!isServer) exitWith {[]};
// The support core's own call, through FUNC(srvThread) - never a client's.
if (isRemoteExecuted) exitWith {
    WARNING_1("threadStrike: refused - remote call from machine %1",remoteExecutedOwner);
    []
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, WHY_LOST]};
private _type = _logic getVariable [QGVAR(type), ""];
if !(_type in [TYPE_CRUISE, TYPE_LOITER]) exitWith {[]};

private _order = [_thread, _message] call EFUNC(support,readOrder);
if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_FIRE) exitWith {[]};

// THE MISSION: no adjusting missile. Unobserved, an adjust is fired for effect.
private _control = _order getOrDefault ["control", ""];
private _mission = _order getOrDefault ["mission", ""];
if (_control isEqualTo CONTROL_CANNOT && _mission isEqualTo MISSION_ADJUST) then {_mission = MISSION_FFE};
if (_mission isEqualTo MISSION_ADJUST) exitWith {[false, WHY_NO_ADJUST]};
if (_mission isEqualTo "") then {_mission = MISSION_FFE};

private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {[false, WHY_NO_TARGET]};

// BUSY, REARMING, SPENT, OUT OF REACH - the reach card's words, and its ETA:
// the least response time plus the flight (a missile) or the transit (a
// munition; -1 when the airframe gives none).
([_assetId, _target] call FUNC(reach)) params ["_can", "_reachEta", "_why"];
if (!_can) exitWith {[false, _why]};

private _shell = _order getOrDefault ["shell", ""];
if (_shell in STRIKE_SHELLS_NONE) exitWith {[false, format [WHY_NO_STORES_OF, _shell]]};

// HOW MANY, read the board's way (FUNC(readOpts)): up to the salvo size and
// what is left.
private _slot = [SLOT_MISSILES, SLOT_MUNITIONS] select (_type isEqualTo TYPE_LOITER);
private _prm = [];
_prm resize (_slot + 1);
private _rounds = _order getOrDefault ["rounds", -1];
if (_rounds > 0) then {_prm set [_slot, _rounds]};
([_logic, _prm] call FUNC(readOpts)) params [["_count", 0], ["_radius", SEARCH_MIN]];
_count = _count min (_logic getVariable [QGVAR(left), 0]);
if (_count < 1) exitWith {[false, WHY_NO_STORES]};
if (_type isEqualTo TYPE_CRUISE) then {_radius = 0};

// DANGER CLOSE (doc 5.3, D5): the card's own threshold.
([_order, _logic getVariable [QGVAR(side), west]] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy"];
if (!_safe) exitWith {[false, _unsafeWhy]};

// THE TIME: the flight from the reach card, and the wait before the launch.
(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0], ["_respMax", 0]];
private _flight = REACH_ETA_UNKNOWN;
if (_reachEta >= 0) then {_flight = _reachEta - _respMin};
private _wait = _respMin + random (_respMax - _respMin);
if (_mission isEqualTo MISSION_IMMEDIATE || _control isEqualTo CONTROL_COMMAND) then {_wait = _respMin};

private _when = "";
if (_flight >= 0) then {_when = [_wait + _flight] call EFUNC(support,etaText)};
private _totWhy = "";
if (_control isEqualTo CONTROL_TOT) then {
    if (_type isEqualTo TYPE_LOITER) exitWith {_totWhy = WHY_TOT_HUNT};
    ([_order getOrDefault ["tot", ""], _flight, _respMin] call FUNC(threadTot)) params ["_totWait", "_totWhen", "_tw"];
    _totWhy = _tw;
    _wait = _totWait;
    _when = _totWhen;
};
if (_totWhy isNotEqualTo "") exitWith {[false, _totWhy]};
if (_control isEqualTo CONTROL_COMMAND) then {_when = WHEN_COMMAND};

// WILCO's words: when, what, how many, the flight, the target.
private _what = (MISSION_WORDS select {(_x select 0) isEqualTo _mission}) param [0, ["", ""]];
private _load = [LOAD_MISSILES, LOAD_MUNITIONS] select (_type isEqualTo TYPE_LOITER);
private _words = [_when, _what select 1, format ["%1 %2", _count, _load select (_count > 1)]];
if (_flight >= 0) then {
    _words pushBack ([format ["TOF %1 S", round _flight], format [WORDS_TRANSIT, round _flight]] select (_type isEqualTo TYPE_LOITER));
};
if (_order getOrDefault ["dcTick", false]) then {_words pushBack WORD_DANGER_CLOSE};
private _desc = _order getOrDefault ["description", ""];
if (_desc isNotEqualTo "") then {_words pushBack (toUpper (_desc select [0, DESCRIPTION_MAX]))};
private _wilco = (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP;

// LAID: the launcher's mission, its thread and the launch it makes.
private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
[_logic] call FUNC(openMission);
_logic setVariable [QGVAR(thread), _threadId];
_logic setVariable [QGVAR(threadOrder), createHashMapFromArray [
    ["target", _target],
    ["count", _count],
    ["radius", _radius],
    ["wait", _wait],
    ["observer", _order getOrDefault ["observer", objNull]],
    ["observerPos", _order getOrDefault ["observerPos", []]],
    ["observed", _control isNotEqualTo CONTROL_CANNOT],
    ["dcTick", _order getOrDefault ["dcTick", false]],
    ["dangerClose", _order getOrDefault ["dangerClose", 0]],
    ["issuer", _issuer]
]];
_logic setVariable [QGVAR(status), STATUS_LAID, true];
INFO_4("%1 call for fire %2 on %3 for %4",_callsign,_mission,mapGridPosition _target,name _issuer);

[_assetId, "ACCEPTED", _wilco, _callsign, false, _threadId] call EFUNC(support,state);

if (_control isEqualTo CONTROL_COMMAND) exitWith {
    [_logic, PROMPT_COMMAND, ANSWERS_COMMAND] call FUNC(threadPrompt);
    [true, ""]
};
[_logic, _issuer] call FUNC(threadLaunch);
[true, ""]
