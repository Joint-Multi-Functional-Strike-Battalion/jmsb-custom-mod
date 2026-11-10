#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_storeMerge

Description:
    Folds the database's copy of the store into this server's, so a save
    carries what the other servers wrote since this one loaded (user,
    2026-11-07: one ops, one training and one dev server, up at the same time).
    Server only; unscheduled - nothing may change the store halfway through.

    WHO WINS, PER PART:
        sessions   a row is [.., windowId, serverId]; this server's own rows are
                   this server's word, every other row is the database's. Keyed
                   uid|joinedAt|serverId; a row only one side has is kept.
        windows    the same, keyed by id.
        players    the record with the later updatedAt (the merge key every
                   edit stamps - FUNC(adminSet)); a tie keeps this server's.
        opords     both; this server's on a clash.
        log        both, keyed by row id, oldest first, the newest PAC_LOG_MAX.
    structureEdited is left alone: it is this server's in-game edits.

Parameters:
    0: The database's store document <HASHMAP>

Returns:
    Whether any player record came from the database <BOOL>

Example:
    [_doc] call jmfsb_pac_fnc_storeMerge

Public: No

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_doc", createHashMap, [createHashMap]]];

if (!isServer) exitWith {false};

private _me = GVAR(settings) getOrDefault ["serverId", PAC_SERVER_DEV];

// ---- sessions and windows: own rows ours, the rest theirs ---------------------
private _fnc_rows = {
    params ["_local", "_remote", "_fnc_key"];
    private _mine = createHashMap;
    {_mine set [_x call _fnc_key, _x]} forEach _local;
    private _out = [];
    private _seen = createHashMap;
    {
        if !(_x isEqualType []) then {continue};
        private _k = _x call _fnc_key;
        private _own = (_x param [PAC_ROW_SERVER, ""]) isEqualTo _me;
        _out pushBack ([_x, _mine getOrDefault [_k, _x]] select _own);
        _seen set [_k, true];
    } forEach _remote;
    {
        if !((_x call _fnc_key) in _seen) then {_out pushBack _x};
    } forEach _local;
    _out
};

private _rs = _doc getOrDefault ["sessions", []];
if (_rs isEqualType []) then {
    GVAR(sessions) = [GVAR(sessions), _rs, {format ["%1|%2|%3", _this # 0, _this # 2, _this param [PAC_ROW_SERVER, ""]]}] call _fnc_rows;
};
private _rw = _doc getOrDefault ["windows", []];
if (_rw isEqualType []) then {
    GVAR(windows) = [GVAR(windows), _rw, {_this # 0}] call _fnc_rows;
};

// ---- players: the later edit -------------------------------------------------
private _took = false;
private _rp = _doc getOrDefault ["players", createHashMap];
if (_rp isEqualType createHashMap) then {
    {
        if !(_y isEqualType createHashMap) then {continue};
        private _ours = GVAR(players) getOrDefault [_x, createHashMap];
        if ((_y getOrDefault ["updatedAt", ""]) > (_ours getOrDefault ["updatedAt", ""])) then {
            GVAR(players) set [_x, _y];
            _took = true;
        };
    } forEach _rp;
};

// ---- orders and the log: both ------------------------------------------------
private _ro = _doc getOrDefault ["opords", createHashMap];
if (_ro isEqualType createHashMap) then {
    {
        if !(_x in GVAR(opordArchive)) then {GVAR(opordArchive) set [_x, _y]};
    } forEach _ro;
};
private _rl = _doc getOrDefault ["log", []];
if (_rl isEqualType []) then {
    private _byId = createHashMap;
    {
        if (_x isEqualType [] && {count _x > 1}) then {_byId set [_x # 0, _x]};
    } forEach (_rl + GVAR(log));
    // by stamp, then id (unique, so the row itself is never compared)
    private _all = (values _byId) apply {[_x # 1, _x # 0, _x]};
    _all sort true;
    _all = _all apply {_x # 2};
    GVAR(log) = _all select [((count _all) - PAC_LOG_MAX) max 0, PAC_LOG_MAX];
};

if (_took) then {[] call FUNC(recordUpgrade)};
TRACE_3("store merged",count GVAR(players),count GVAR(sessions),_took);

_took
