#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_csvImport

Description:
    Reads a CSV of roster rows shipped in the mission and writes it into the
    store - one record per row, keyed by Steam id. Server only, admin-checked,
    logged. The server reads the file from ITS OWN mission copy with loadFile,
    so it works on a dedicated server where the admin is a remote client.

    THE FILE. A mission carries `pac_roster.csv` at its root (or the path in
    the caller's argument). loadFile takes a path relative to the mission.
    First line is the header; column order is free, columns are matched by
    name, unknown columns are ignored, missing columns are left alone.

    COLUMNS (header names, case and spaces ignored):
        steamId        REQUIRED - the record key (a 17-digit id)
        name           the display name
        milsimName     the unit's name for them ("Cpl J. Miller")
        rank           a rank: its id (sergeant), name (Sergeant) or abbrev (SGT)
        group          the squad id
        role           a role: its class id or its name
        status         a status: its id or name
        skills         skill ids, separated by ; or space or |
        discordId, enlisted (YYYY-MM-DD), promoted, clearance, company,
        reportsTo, operatorId    written as given

    IT UPDATES, IT DOES NOT REPLACE. A row for a Steam id already on the
    roster fills the columns the CSV names and leaves the rest - awards,
    notes, attendance - untouched. A row for a new id seeds a fresh record
    (an operator id and today's enlistment unless the CSV gives them). Ids
    that are not ranks / roles / statuses / skills the structure has are
    skipped with a count, never written as orphans.

    A FORCED SAVE AND A PUBLISH at the end - the whole point is that the
    roster is durable and on every client at once.

Parameters:
    0: Caller <OBJECT>
    1: File path in the mission <STRING> (optional, default "pac_roster.csv")

Returns:
    How many rows were written <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_path", "pac_roster.csv", [""]]];

if (!isServer) exitWith {0};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {0};

private _red = [0.831, 0.267, 0.267, 1];
private _green = [0.4, 0.702, 0.4, 1];
private _fnc_tell = {
    params ["_msg", "_colour"];
    ["TAC//PAC", _msg, _colour] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

if (GVAR(readOnly)) exitWith {["Store is read-only - not imported.", _red] call _fnc_tell; 0};

// The file, from the server's own mission. loadFile tries a couple of the
// obvious places so a maker can drop it at the root or under config\.
private _text = "";
{
    if (_text isEqualTo "") then {
        private _try = loadFile _x;
        if (_try isNotEqualTo "") then {_text = _try};
    };
} forEach [_path, "config\" + _path, "pac_roster.csv", "config\pac_roster.csv"];

if (_text isEqualTo "") exitWith {
    [format ["No CSV found - put '%1' in the mission (its root or config\\).", _path], _red] call _fnc_tell;
    0
};

// ---- rows ------------------------------------------------------------------
// Split on either newline; a field may be quoted, and a quoted field may hold
// a comma. Small, because a roster CSV is small.
private _fnc_split = {
    params ["_line"];
    private _out = [];
    private _cur = "";
    private _inq = false;
    {
        private _c = _x;
        switch (true) do {
            case (_c isEqualTo 34): {_inq = !_inq};                       // "
            case (_c isEqualTo 44 && !_inq): {_out pushBack _cur; _cur = ""};   // ,
            default {_cur = _cur + toString [_c]};
        };
    } forEach toArray _line;
    _out pushBack _cur;
    _out apply {trim _x}
};

private _lines = (_text splitString (toString [13, 10])) select {trim _x isNotEqualTo ""};
if (count _lines < 2) exitWith {["The CSV has no rows under its header.", _red] call _fnc_tell; 0};

private _header = ([_lines # 0] call _fnc_split) apply {((toLower _x) splitString " _") joinString ""};
private _col = {_header find (((toLower _this) splitString " _") joinString "")};   // column index of a name, -1 if absent

private _ranks = GVAR(structure) getOrDefault ["ranks", createHashMap];
private _roles = GVAR(structure) getOrDefault ["roles", createHashMap];
private _statuses = GVAR(structure) getOrDefault ["statuses", createHashMap];
private _skills = GVAR(structure) getOrDefault ["skills", createHashMap];

// a value -> a section id: the id itself, or the id whose name/abbrev matches
private _fnc_id = {
    params ["_v", "_map", "_extra"];
    private _lc = toLower trim _v;
    if (_lc isEqualTo "") exitWith {""};
    if (_lc in (keys _map)) exitWith {_lc};
    private _hit = "";
    {
        private _rec = _y;
        private _names = [toLower (_rec getOrDefault ["name", ""])];
        {_names pushBack toLower (_rec getOrDefault [_x, ""])} forEach _extra;
        if (_lc in _names) exitWith {_hit = _x};
    } forEach _map;
    _hit
};

private _now = [] call FUNC(stamp);
private _wrote = 0;
private _skipped = 0;
private _bad = [];

{
    if (_forEachIndex isEqualTo 0) then {continue};      // header
    private _row = [_x] call _fnc_split;
    private _get = {
        private _i = _this call _col;
        if (_i < 0 || {_i >= count _row}) then {""} else {_row # _i}
    };

    private _uid = "steamId" call _get;
    if (_uid isEqualTo "") then {_uid = "steamid64" call _get};
    private _digits = (toArray _uid) select {_x >= 48 && _x <= 57};
    if (count _digits < 17) then {_skipped = _skipped + 1; _bad pushBack (_uid + " (not a Steam id)"); continue};

    private _name = "name" call _get;
    private _rec = [_uid, _name] call FUNC(record);
    if (count _rec isEqualTo 0) then {continue};

    private _changed = false;
    private _fnc_set = {
        params ["_key", "_val"];
        if (_val isNotEqualTo "" && {(_rec getOrDefault [_key, ""]) isNotEqualTo _val}) then {
            _rec set [_key, _val]; _changed = true;
        };
    };

    ["name", _name] call _fnc_set;
    ["milsimName", "milsimName" call _get] call _fnc_set;
    ["discordId", "discordId" call _get] call _fnc_set;
    ["clearance", "clearance" call _get] call _fnc_set;
    ["company", "company" call _get] call _fnc_set;
    ["reportsTo", "reportsTo" call _get] call _fnc_set;
    ["groupId", "group" call _get] call _fnc_set;
    private _op = "operatorId" call _get;
    if (_op isNotEqualTo "") then {["operatorId", _op] call _fnc_set};
    {
        _x params ["_key", "_name"];
        private _v = trim (_name call _get);
        if (_v isNotEqualTo "") then {
            private _digits2 = (toArray _v) select {_x >= 48 && _x <= 57};
            if (count _v isEqualTo 10 && {count _digits2 isEqualTo 8}) then {[_key, _v] call _fnc_set};
        };
    } forEach [["enlistedAt", "enlisted"], ["promotedAt", "promoted"]];

    private _rank = ["rank" call _get, _ranks, ["abbrev"]] call _fnc_id;
    if (("rank" call _get) isNotEqualTo "" && _rank isEqualTo "") then {_bad pushBack ("rank " + ("rank" call _get))};
    ["rankId", _rank] call _fnc_set;

    private _role = ["role" call _get, _roles, []] call _fnc_id;
    if (("role" call _get) isNotEqualTo "" && _role isEqualTo "") then {_bad pushBack ("role " + ("role" call _get))};
    ["roleId", _role] call _fnc_set;

    private _status = ["status" call _get, _statuses, []] call _fnc_id;
    ["statusId", _status] call _fnc_set;

    private _skillStr = "skills" call _get;
    if (_skillStr isNotEqualTo "") then {
        private _want = ((_skillStr splitString "; |,") apply {toLower trim _x}) select {_x isNotEqualTo ""};
        private _ok = _want select {_x in (keys _skills)};
        (_want select {!(_x in (keys _skills))}) apply {_bad pushBack ("skill " + _x)};
        _ok sort true;
        if (_ok isNotEqualTo (_rec getOrDefault ["skillIds", []])) then {_rec set ["skillIds", _ok]; _changed = true};
    };

    if (_changed) then {
        _rec set ["updatedAt", _now];
        _rec set ["serverId", GVAR(settings) getOrDefault ["serverId", ""]];
        GVAR(players) set [_uid, _rec];
        _wrote = _wrote + 1;
    };
} forEach _lines;

[] call FUNC(recordUpgrade);
[getPlayerUID _caller, name _caller, "import", "", format ["CSV import: %1 row(s) written, %2 skipped", _wrote, _skipped]] call FUNC(logAction);
[true] call FUNC(storeSave);
[] call FUNC(publish);

private _msg = format ["CSV import: %1 row(s) written%2.", _wrote, [format [", %1 skipped", _skipped], ""] select (_skipped isEqualTo 0)];
if (_bad isNotEqualTo []) then {
    _bad = _bad arrayIntersect _bad;      // unique
    _msg = _msg + format [" Unknown, left blank: %1.", (_bad select [0, 6]) joinString ", "];
};
[_msg, [_green, _red] select (_wrote isEqualTo 0)] call _fnc_tell;
INFO_2("%1 CSV import: %2 row(s)",name _caller,_wrote);

_wrote
