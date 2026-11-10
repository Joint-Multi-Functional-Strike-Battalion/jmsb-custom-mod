#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an aircraft that has arrived on station files its AIRFRAME CHECK-IN
 * in the thread that sent it, as itself (user, 2026-11-02: "in the support
 * system an aircraft when it arrives on station needs to send an AIRFRAME
 * CHECK-IN"). The one filler every provider calls - support_air's CAS and
 * the CAS drones - so the card reads the same
 * whoever flies it. It knows no asset kind: the provider says when, where,
 * how high and for how long; the rest is read off the airframe.
 *
 *   Line 1  call sign          the asset's (the server has no "own call
 *                              sign" to autofill it from)
 *   Line 2  number and type    1x the airframe's display name
 *   Line 3  position, altitude the station, at the height given
 *   Line 4  ordnance           the rounds left of what can strike the ground
 *                              (FUNC(ordnanceLeft))
 *   Line 5  time on station    minutes left, a number; left out when unknown
 *   Line 6  abort code         four figures, new for every check-in
 *   CAPABILITIES               the ticks the airframe has (FUNC(airframeCaps))
 *   LASER CODE                 with a designator aboard: ACE's code on the
 *                              airframe, else LASER_CODE_DEFAULT
 *   Line 7  remarks            the provider's words
 *
 * BY KEY, AND ONLY THE KEYS THE CARD HAS (report-card review, 2026-11-02): the
 * deck may still be the seeded card without CAPABILITIES or LASER CODE. The
 * ticks are found by their prefix on the card's Capabilities line, so a deck
 * that ticks other words gets the ones it shares with FUNC(airframeCaps).
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id, one filed to this asset <STRING>
 * 2: The aircraft <OBJECT>
 * 3: Its call sign <STRING>
 * 4: The station, ATL; [] leaves the position out <ARRAY>
 * 5: Altitude (m), -1 for the aircraft's own height now <NUMBER> (optional, default -1)
 * 6: Minutes left on station, -1 when not known <NUMBER> (optional, default -1)
 * 7: Remarks <STRING> (optional, default "")
 *
 * Return Value:
 * The abort code, "" when nothing was filed <STRING>
 *
 * Example:
 * ["air:0", "T0042", _veh, "HOG", _hold, 3000, 10, "HOLDING OFF THE MAP"] call jmfsb_support_fnc_checkIn
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_veh", objNull, [objNull]],
    ["_callsign", "", [""]],
    ["_station", [], [[]]],
    ["_alt", -1, [0]],
    ["_minutes", -1, [0]],
    ["_remarks", "", [""]]
];

if (!isServer || _threadId isEqualTo "" || isNull _veh) exitWith {""};
// A provider's own call from its watch - never a client's: this files a whole
// card as the asset.
if (isRemoteExecuted) exitWith {
    WARNING_1("checkIn: refused - remote call from machine %1",remoteExecutedOwner);
    ""
};

private _template = [CARD_CHECKIN] call EFUNC(messaging,template);
if (_template isEqualTo createHashMap) exitWith {
    INFO_2("%1: no '%2' card on the deck - no check-in",_callsign,CARD_CHECKIN);
    ""
};
private _fields = _template get "fields";

private _abort = str (ABORT_CODE_MIN + floor random ABORT_CODE_SPAN);
if (_alt < 0) then {_alt = (getPosATL _veh) select 2};

private _payload = [
    [CHECKIN_CALLSIGN, _callsign],
    [CHECKIN_TYPE, format [CHECKIN_TYPE_FORMAT, getText (configOf _veh >> "displayName")]],
    [CHECKIN_ALTITUDE, 0 max (round _alt) min CHECKIN_ALT_MAX],
    [CHECKIN_ORDNANCE, [_veh] call FUNC(ordnanceLeft)],
    [CHECKIN_ABORT, _abort]
];
if (_station isNotEqualTo []) then {_payload pushBack [CHECKIN_POSITION, +_station]};
if (_minutes >= 0) then {_payload pushBack [CHECKIN_TIME, 0 max (round _minutes) min CHECKIN_MINUTES_MAX]};
if (_remarks isNotEqualTo "") then {_payload pushBack [CHECKIN_REMARKS, _remarks]};

// CAPABILITIES: a tick for each the airframe has, by the tick's prefix.
private _caps = [_veh] call FUNC(airframeCaps);
{
    if ((_y get "line") isNotEqualTo CHECKIN_CAPS_LINE) then {continue};
    if (_caps getOrDefault [toUpper trim (_y get "prefix"), false]) then {_payload pushBack [_x, true]};
} forEach _fields;

// LASER CODE: with a designator aboard, the code it lases on.
if (_caps getOrDefault [CAP_LASER, false]) then {
    private _code = _veh getVariable [ACE_LASER_CODE_VAR, LASER_CODE_DEFAULT];
    if !(_code isEqualType 0) then {_code = LASER_CODE_DEFAULT};
    _payload pushBack [CHECKIN_LASER, LASER_CODE_MIN max (round _code) min LASER_CODE_MAX];
};

// Only the keys this deck's card has.
_payload = _payload select {(_x select 0) in _fields};

INFO_3("%1 checks in on thread %2 - abort code %3",_callsign,_threadId,_abort);
[_assetId, _threadId, CARD_CHECKIN, _payload, _callsign] call FUNC(fileCard);
_abort
