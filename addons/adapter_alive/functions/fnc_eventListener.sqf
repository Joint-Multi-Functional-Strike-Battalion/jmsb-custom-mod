#include "script_component.hpp"
/*
 * Author: JMSB
 * ALiVE's event log calls this for every event once FUNC(eventBridge) has
 * registered it. ALiVE dispatches as [listener, "handleEvent", event] to the
 * function named in the listener's "class" key (x_lib fnc_eventLog.sqf:229).
 *
 * WHAT LEAVES HERE IS A SUMMARY, NOT THE EVENT. The event carries ALiVE hashes
 * (objective hashes, profiles) that no other addon may read - that is the
 * seam. Each type is reduced to plain values here, once, and handed on on the
 * server:
 *
 *   jmfsb_adapter_alive_event    [type <STRING>, summary <ARRAY>]   every type,
 *                                a local CBA event, for mission scripts
 *   FUNC(onCapture) hooks        [sideText, objectiveID, pos, size] OPCOM_CAPTURE
 *                                (review R1: not a CBA event any client can raise)
 *
 * Summaries by type:
 *   OPCOM_CAPTURE / OPCOM_DEFEND / OPCOM_RECON / OPCOM_RESERVE / OPCOM_TERRORIZE
 *       [sideText, objectiveID, center, size]
 *   ASYMM_INSTALLATION_DESTROYED   [installationType, pos, killerSide]
 *   LOGISTICS_INSERTION / LOGISTICS_DESTINATION / LOGISTICS_COMPLETE
 *       [pos, faction, sideText, eventID, eventType]
 *   PROFILE_KILLED                 [pos, faction, sideText, killerSideText]
 *   TASK_* and everything else     [] (the type is the news)
 *
 * Arguments:
 * 0: Listener <ARRAY>
 * 1: Operation <STRING> - only "handleEvent" does anything
 * 2: Event <ARRAY> - an ALiVE event hash
 *
 * Return Value: None
 *
 * Public: No
 */

params ["", ["_op", "", [""]], ["_event", [], [[]]]];
if (_op isNotEqualTo "handleEvent" || {_event isEqualTo []}) exitWith {};

private _type = [_event, "type", ""] call ALiVE_fnc_hashGet;
private _data = [_event, "data", []] call ALiVE_fnc_hashGet;
if (_type isEqualTo "") exitWith {};

private _summary = switch (_type) do {
    case "OPCOM_CAPTURE";
    case "OPCOM_DEFEND";
    case "OPCOM_RECON";
    case "OPCOM_RESERVE";
    case "OPCOM_TERRORIZE": {
        _data params [["_side", ""], ["_obj", []]];
        if (!(_obj isEqualType []) || {_obj isEqualTo []}) exitWith {[]};
        [
            toUpper (if (_side isEqualType "") then {_side} else {str _side}),
            [_obj, "objectiveID", ""] call ALiVE_fnc_hashGet,
            [_obj, "center", []] call ALiVE_fnc_hashGet,
            [_obj, "size", 0] call ALiVE_fnc_hashGet
        ]
    };
    case "ASYMM_INSTALLATION_DESTROYED": {
        _data params [["_kind", ""], ["_building", objNull], ["_killer", objNull]];
        [
            toLower _kind,
            if (isNull _building) then {[]} else {getPosATL _building},
            if (isNull _killer) then {sideUnknown} else {side group _killer}
        ]
    };
    case "LOGISTICS_INSERTION";
    case "LOGISTICS_DESTINATION";
    case "LOGISTICS_COMPLETE": {
        _data params [["_pos", []], ["_faction", ""], ["_side", ""], ["_eid", ""], ["_etype", ""]];
        [_pos, _faction, toUpper str _side, _eid, _etype]
    };
    case "PROFILE_KILLED": {
        _data params [["_pos", []], ["_faction", ""], ["_side", ""], ["_kside", ""]];
        [_pos, _faction, toUpper str _side, toUpper str _kside]
    };
    default {[]};
};

[QGVAR(event), [_type, _summary]] call CBA_fnc_localEvent;
// The capture goes to FUNC(onCapture)'s hooks, not a CBA event any client
// could raise (review R1).
if (_type isEqualTo "OPCOM_CAPTURE" && {_summary isNotEqualTo []}) then {
    {
        _summary call _x;
    } forEach (localNamespace getVariable [QGVAR(captureHooks), []]);
};
