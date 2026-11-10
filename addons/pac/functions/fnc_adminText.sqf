#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminText

Description:
    Builds a block of text on the server and hands it to the admin who asked,
    who gets it on their clipboard (FUNC(textRecv)). Admin-checked like every
    other door on the server.

    ONE FUNCTION FOR EVERY "GIVE ME THE TEXT". The attendance report now; the
    export and the delta tool's structure dump use the same path, because a
    thing that goes to a clipboard is a thing that goes to a clipboard.

Parameters:
    0: Caller <OBJECT>
    1: Kind <STRING> - "report" | "export" | "structure"
    2: Argument <ANY> - report: window id, "" for the open window, else the
                        latest, else all time

Returns:
    Whether text was sent <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_kind", "", [""]], ["_arg", ""]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {false};

private _title = "";
private _text = "";

switch (_kind) do {
    case "report": {
        private _id = _arg;
        if (_id isEqualTo "") then {_id = GVAR(windowOpen)};
        if (_id isEqualTo "" && {GVAR(windows) isNotEqualTo []}) then {_id = (GVAR(windows) # (count GVAR(windows) - 1)) # 0};
        _title = "Attendance";
        _text = [_id] call FUNC(attendanceReport);
    };
    case "export": {
        _title = "Store export";
        _text = [true] call FUNC(storeJson);
    };
    case "structure": {
        // The delta tool's input: the structure as it compiled here, with the
        // hash the tile shows. Two servers' dumps diffed side by side is the
        // whole tool in v0.
        // STRUCTURE OUT: the same shape STRUCTURE IN takes and pac_sync.py pull
        // writes, so one server's export goes straight into another
        private _s = +GVAR(settings);
        {_s deleteAt _x} forEach ["unitId", "serverId", "sync"];
        _title = format ["Structure %1", GVAR(structureHash)];
        _text = [createHashMapFromArray [["hash", GVAR(structureHash)], ["unitId", GVAR(settings) getOrDefault ["unitId", ""]], ["structure", GVAR(structure)], ["settings", _s], ["exportedAt", [] call FUNC(stamp)]], "  "] call FUNC(toJson);
    };
    case "operator": {
        // one player's file in the unit's own shape - see FUNC(operatorJson)
        private _doc = [_arg] call FUNC(operatorJson);
        if (count _doc isEqualTo 0) exitWith {};
        _title = format ["Operator file %1", _doc getOrDefault ["operator_id", _arg]];
        _text = [_doc, "  "] call FUNC(toJson);
    };
    case "orbat": {
        _title = "ORBAT";
        _text = [GVAR(structure) getOrDefault ["orbat", createHashMap], "  "] call FUNC(toJson);
    };
    default {
        WARNING_1("adminText: '%1' is not a kind",_kind);
    };
};

if (_text isEqualTo "") exitWith {false};

[_title, _text] remoteExec [QFUNC(textRecv), owner _caller];
true
