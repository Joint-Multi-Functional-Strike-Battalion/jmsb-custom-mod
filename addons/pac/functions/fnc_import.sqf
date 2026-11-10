#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_import

Description:
    Reads a store document (FUNC(storeJson)'s shape) that an admin pasted,
    and either merges it into this server's store or replaces the store with
    it. Server only, admin-checked, and it answers the admin with a
    notification either way.

    MERGE IS BY updatedAt, LAST WRITER WINS, per record - the handoff's rule
    for two servers that both edited the same player. Stamps are turned into
    seconds first: SQF has no > on strings. Sessions and
    windows never merge: a row that is not already here is appended, one that
    is here is left alone.

    RESTORE FULL replaces players, sessions and windows with the document's,
    for the case the profile is gone and the .rpt backup is all there is.
    Meta stays this server's.

    A DOCUMENT FROM A NEWER PAC IS REFUSED - its records may have fields this
    build would drop on the next save. A document that does not parse is
    refused with the character it failed at, which is more use than "no".

    IT IS A FORCED SAVE. An import is one of the handoff's three moments.

Parameters:
    0: Caller <OBJECT>
    1: JSON text <STRING>
    2: Mode <STRING> - "merge" | "restore"

Returns:
    Whether the store changed <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_text", "", [""]], ["_mode", "merge", [""]]];

if (!isServer) exitWith {false};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {false};

private _red = [0.831, 0.267, 0.267, 1];
private _green = [0.4, 0.702, 0.4, 1];
private _fnc_tell = {
    params ["_msg", "_colour"];
    ["TAC//PAC", _msg, _colour] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

if (GVAR(readOnly)) exitWith {["Store is read-only: it was written by a newer PAC.", _red] call _fnc_tell; false};
if (_text isEqualTo "") exitWith {["Nothing to import - the clipboard is empty.", _red] call _fnc_tell; false};

([_text] call FUNC(fromJson)) params ["_doc", "_ok", "_where"];
if (!_ok) exitWith {[format ["Import refused: not valid JSON (at character %1).", _where], _red] call _fnc_tell; false};
if !(_doc isEqualType createHashMap) exitWith {["Import refused: the document is not a store.", _red] call _fnc_tell; false};

if ((_doc getOrDefault ["schemaVersion", PAC_SCHEMA]) > PAC_SCHEMA) exitWith {
    ["Import refused: the document is from a newer PAC.", _red] call _fnc_tell;
    false
};

private _players = _doc getOrDefault ["players", createHashMap];
private _sessions = _doc getOrDefault ["sessions", []];
private _windows = _doc getOrDefault ["windows", []];
private _opordsIn = _doc getOrDefault ["opords", createHashMap];
if !(_opordsIn isEqualType createHashMap) then {_opordsIn = createHashMap};
private _logIn = _doc getOrDefault ["log", []];
if !(_logIn isEqualType []) then {_logIn = []};
if !(_players isEqualType createHashMap && _sessions isEqualType [] && _windows isEqualType []) exitWith {
    ["Import refused: players/sessions/windows are not the right shapes.", _red] call _fnc_tell;
    false
};

private _newer = 0;
private _added = 0;

// A stamp as seconds. SQF has no > on strings, and last-writer-wins needs to
// be right to the second, which FUNC(stampMinutes) alone is not.
private _fnc_order = {
    params ["_s"];
    ((([_s] call FUNC(stampMinutes)) # 0) * 60) + parseNumber ((_s splitString "-: ") param [5, "0"])
};

switch (_mode) do {
    case "merge": {
        {
            if !(_y isEqualType createHashMap) then {continue};
            private _mine = GVAR(players) getOrDefault [_x, createHashMap];
            if (count _mine isEqualTo 0 || {([_y getOrDefault ["updatedAt", ""]] call _fnc_order) > ([_mine getOrDefault ["updatedAt", ""]] call _fnc_order)}) then {
                GVAR(players) set [_x, _y];
                _newer = _newer + 1;
            };
        } forEach _players;
        {
            if !(_x in GVAR(sessions)) then {GVAR(sessions) pushBack _x; _added = _added + 1};
        } forEach _sessions;
        {
            if !(_x in GVAR(windows)) then {GVAR(windows) pushBack _x; _added = _added + 1};
        } forEach _windows;
        {
            if !(_x in GVAR(opordArchive)) then {GVAR(opordArchive) set [_x, _y]; _added = _added + 1};
        } forEach _opordsIn;
        {
            if !(_x in GVAR(log)) then {GVAR(log) pushBack _x; _added = _added + 1};
        } forEach _logIn;
    };
    case "restore": {
        GVAR(players) = _players;
        GVAR(sessions) = _sessions;
        GVAR(windows) = _windows;
        GVAR(opordArchive) = _opordsIn;
        GVAR(log) = _logIn;
        // a restore is the whole store: the next database write is it, not a merge (FUNC(storeSync))
        GVAR(syncReplace) = true;
        _newer = count _players;
        _added = count _sessions + count _windows;
    };
    default {
        [format ["Import refused: '%1' is not a mode.", _mode], _red] call _fnc_tell;
    };
};

if (_newer isEqualTo 0 && _added isEqualTo 0) exitWith {["Import: nothing here was older than what came in.", _green] call _fnc_tell; false};

INFO_4("%1 imported (%2): %3 player record(s), %4 session/window row(s)",name _caller,_mode,_newer,_added);
[] call FUNC(recordUpgrade);
[getPlayerUID _caller, name _caller, "import", "", format ["%1: %2 record(s), %3 row(s)", _mode, _newer, _added]] call FUNC(logAction);
[true] call FUNC(storeSave);
[] call FUNC(publish);

[format ["Import (%1): %2 player record(s), %3 session/window row(s).", _mode, _newer, _added], _green] call _fnc_tell;
true
