#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_windowSet

Description:
    Starts or stops a manual op window. Server only, admin-checked the way
    FUNC(adminSet) is.

    A WINDOW IS ONE ROW, APPEND-ONLY:

        [id, name, startedAt, endedAt, source, kind]

    source is "manual" for these; FUNC(windowCurrent) also answers windows
    that come from the config's opWindows and from the current OPORD, but
    those are never rows here - they are read off the structure when asked.
    Only what an admin did by hand is stored, because only that cannot be
    recomputed.

    ONE MANUAL WINDOW AT A TIME. Starting while one is open stops the open one
    first, at the same stamp, so there is never a gap or an overlap to argue
    about in a report.

    KIND says what the window was (user, 2026-10-11: "define what is an
    operation and what's training or special ... only operation missions
    count toward promotion and an option for training time"):
    "operation", "training" or "special". FUNC(attendanceOf) and
    FUNC(promotionPoints) count operations as ops; training has its own
    promotion weights; special counts for nothing. A row from before kinds
    has no 6th element and reads as an operation.

    STOP IS A FORCED SAVE, per the handoff: the window closing is one of the
    moments where losing the last thirty seconds would actually cost.

Parameters:
    0: Caller <OBJECT>
    1: Mode <STRING> - "start" | "stop"
    2: Name <STRING> (start only; "" gets a name from the stamp)
    3: Kind <STRING> (start only) - "operation" (default) | "training" | "special"

Returns:
    The id of the window started or stopped, "" if nothing happened <STRING>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_mode", "", [""]], ["_name", "", [""]], ["_kind", "operation", [""]]];

if !(_kind in ["operation", "training", "special"]) then {_kind = "operation"};

if (!isServer) exitWith {""};
if (isNull _caller || {!([_caller] call jmfsb_adminpanel_fnc_isAdmin)}) exitWith {
    WARNING_2("windowSet refused: %1 is not an admin (%2)",name _caller,_mode);
    ""
};
if (GVAR(readOnly)) exitWith {""};

private _now = [] call FUNC(stamp);
private _id = "";

private _fnc_stopOpen = {
    {
        if ((_x # 0) isEqualTo GVAR(windowOpen)) then {_x set [3, _now]};
    } forEach GVAR(windows);
    GVAR(windowOpen) = "";
};

switch (_mode) do {
    case "start": {
        if (GVAR(windowOpen) isNotEqualTo "") then {call _fnc_stopOpen};

        // Digits of the stamp: unique to the second, sorts in time order,
        // and safe in every place an id ends up.
        _id = "w" + ((_now splitString "-: ") joinString "");
        if (_name isEqualTo "") then {_name = "Op window " + _now};

        GVAR(windows) pushBack [_id, _name, _now, "", "manual", _kind];
        GVAR(windowOpen) = _id;
        INFO_4("%1 started %4 window %2 (%3)",name _caller,_name,_id,_kind);
        [getPlayerUID _caller, name _caller, "window", "", format ["started %3 window '%1' (%2)", _name, _id, _kind]] call FUNC(logAction);
        [] call FUNC(storeSave);
    };
    case "stop": {
        if (GVAR(windowOpen) isEqualTo "") exitWith {};
        _id = GVAR(windowOpen);
        call _fnc_stopOpen;
        INFO_2("%1 stopped op window %2",name _caller,_id);
        [getPlayerUID _caller, name _caller, "window", "", format ["stopped op window %1", _id]] call FUNC(logAction);
        [true] call FUNC(storeSave);
        ["op window stop"] call FUNC(backupDump);
    };
    default {
        WARNING_1("windowSet: '%1' is not a mode",_mode);
    };
};

if (_id isNotEqualTo "") then {[] call FUNC(publish)};

_id
