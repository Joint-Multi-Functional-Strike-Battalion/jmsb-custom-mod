#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a FRAGO of the JUMP REQUEST (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * 2026-11-09), from FUNC(srvReply): the order with its changes laid over it
 * (EFUNC(support,srvFollowUp)), read as the card is (EFUNC(support,readOrder))
 * and put into the run - the type and its altitude, the red and green light
 * (shifted for the wind again), the passes and the stick split over them, the
 * exit, the pickup. Only before the run starts: before BOARD (a module's
 * aircraft) or WHEELS UP (a side's own). After it: FRAGO NOT TAKEN. A change
 * the card would refuse (no type, no light, the lights too close) is said
 * and the run kept as it was.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: Thread <HASHMAP>
 * 2: The order with the FRAGO laid over it <HASHMAP>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [_st, _thread, _message] call jmfsb_jumpmaster_fnc_srvFrago
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_thread", createHashMap, [createHashMap]], ["_message", createHashMap, [createHashMap]]];

if (!isServer) exitWith {false};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvFrago: refused - remote call from machine %1",remoteExecutedOwner);
    false
};

private _assetId = _st get "assetId";
private _threadId = _st get "thread";
private _callsign = _st get "callsign";
private _fnc_say = {
    params ["_line"];
    [_assetId, _threadId, _line, false, _callsign] call EFUNC(support,threadEvent);
};

if (!isNull (_st get "veh") || {(_st get "phase") isNotEqualTo PHASE_BOARD && {_st getOrDefault ["module", false]}}) exitWith {
    [SAID_FRAGO_LATE] call _fnc_say;
    false
};

private _order = [_thread, _message] call EFUNC(support,readOrder);
if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_JUMP) exitWith {false};
private _asset = [_assetId] call FUNC(asset);

private _type = _order getOrDefault ["type", ""];
private _red = _order getOrDefault ["red", []];
private _green = _order getOrDefault ["green", []];
private _why = switch (true) do {
    case !(_type in TYPES): {WHY_NO_TYPE};
    case (_red isEqualTo []): {WHY_NO_RED};
    case (_green isEqualTo []): {WHY_NO_GREEN};
    case ((_red distance2D _green) < JUMP_RUN_MIN): {WHY_RUN_SHORT};
    default {""};
};
if (_why isNotEqualTo "") exitWith {
    [format [SAID_FRAGO, _why]] call _fnc_say;
    false
};

private _passes = _order getOrDefault ["passes", -1];
if (_passes < PASSES_MIN) then {_passes = _asset getOrDefault ["passes", _st get "passes"]};
_passes = (round _passes) max PASSES_MIN min PASSES_MAX;
private _exit = _order getOrDefault ["exit", ""];
if !(_exit in EXITS) then {_exit = _st get "exit"};
private _pickup = _order getOrDefault ["pickup", []];
if (_pickup isEqualTo []) then {_pickup = _st get "pickup"};

private _alt = [_type, _asset] call FUNC(typeAlt);
([_type, _red, _green, _alt] call FUNC(windShift)) params ["_redFlown", "_greenFlown", "_shift"];

{_st set _x} forEach [
    ["type", _type],
    ["alt", _alt],
    ["red", _redFlown],
    ["green", _greenFlown],
    ["dir", _redFlown getDir _greenFlown],
    ["passes", _passes],
    ["exit", _exit],
    ["pickup", _pickup],
    ["stick", [_st get "jumpers", _passes] call FUNC(stick)]
];

private _zones = [[toLower _type, _green, _callsign]];
if (_shift > 0) then {_zones pushBack [ZONE_RELEASE, _greenFlown, _callsign]};
[_threadId, _zones, side group (_st get "leader")] call EFUNC(support,zones);

private _words = [
    format [WILCO_TYPE, _type, round _alt],
    format [WILCO_PASSES, _passes, ["", "ES"] select (_passes > 1)],
    ((WILCO_EXITS select {(_x select 0) isEqualTo _exit}) param [0, ["", ""]]) select 1
];
if (_shift > 0) then {_words pushBack format [WILCO_WIND, _shift]};
[format [SAID_FRAGO, (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP]] call _fnc_say;
INFO_3("srvFrago: %1 %2, %3 passes",_callsign,_type,_passes);
true
