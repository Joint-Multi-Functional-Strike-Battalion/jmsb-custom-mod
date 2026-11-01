#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_seedSample

Description:
    Fills the store with a made-up roster so the panel, the app and the
    reports have something to show before a unit has entered anybody.
    Server only, admin-checked.

    EVERYTHING IS DRAWN FROM THE STRUCTURE THAT IS LOADED - ranks, roles,
    skills, awards and statuses are picked from whatever CfgGFA_PAC declares,
    by index, so the sample fits any mission and never invents an id. Only
    the names are made up.

    DETERMINISTIC AND REVERSIBLE. The same sixteen UIDs every time, so a
    second SEED overwrites rather than doubles; every record carries
    serverId = "sample" and every session names it too, so REMOVE takes out
    exactly what SEED put in and nothing a real player did. Real records
    with one of these UIDs cannot exist - they are outside Steam's range.

    A closed op window ("Sample op night") is added with sessions under it,
    so ATTENDANCE TO CLIPBOARD has a window to report.

Parameters:
    0: Caller <OBJECT>
    1: Mode <STRING> - "add" | "remove"

Returns:
    How many records were written or removed <NUMBER>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_mode", "add", [""]]];

if (!isServer) exitWith {0};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {0};
if (GVAR(readOnly)) exitWith {0};

#define SAMPLE_TAG "sample"
#define SAMPLE_WINDOW "wsample"

private _fnc_tell = {
    params ["_msg"];
    ["TAC//PAC", _msg, [0.4, 0.702, 0.4, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _caller];
};

// ---- remove ---------------------------------------------------------------
if (_mode isEqualTo "remove") exitWith {
    private _gone = 0;
    {
        if ((_y getOrDefault ["serverId", ""]) isEqualTo SAMPLE_TAG) then {
            GVAR(players) deleteAt _x;
            _gone = _gone + 1;
        };
    } forEach +GVAR(players);
    GVAR(sessions) = GVAR(sessions) select {(_x # 5) isNotEqualTo SAMPLE_WINDOW};
    GVAR(windows) = GVAR(windows) select {(_x # 0) isNotEqualTo SAMPLE_WINDOW};

    [true] call FUNC(storeSave);
    [] call FUNC(publish);
    [format ["Sample data removed: %1 record(s).", _gone]] call _fnc_tell;
    INFO_2("%1 removed the sample data (%2 records)",name _caller,_gone);
    _gone
};

// ---- add ------------------------------------------------------------------
private _fnc_ids = {
    params ["_section"];
    private _ids = keys (GVAR(structure) getOrDefault [_section, createHashMap]);
    _ids sort true;
    _ids
};
private _ranks = ["ranks"] call _fnc_ids;
private _roles = ["roles"] call _fnc_ids;
private _skills = ["skills"] call _fnc_ids;
private _awards = ["awards"] call _fnc_ids;
private _statuses = ["statuses"] call _fnc_ids;

// pick by index, safely, off a possibly empty list
private _fnc_pick = {
    params ["_list", "_i"];
    if (_list isEqualTo []) exitWith {""};
    _list # (_i mod count _list)
};

private _now = [] call FUNC(stamp);
private _nowMin = ([_now] call FUNC(stampMinutes)) # 0;

// [name, groupId, rankIndex, roleIndex, skillIndexes, awardIndexes, statusIndex, note]
private _people = [
    ["Marcus Hale",        "JMFSB 6",     6, 2, [7],    [0],    0, "Task force commander. Runs the brief."],
    ["Priya Venkataraman", "JMFSB 6",     5, 2, [7, 5], [],     0, "XO. Holds the roster between ops."],
    ["Tomasz Wrona",       "BANSHEE 1-1", 3, 2, [7],    [0],    0, "Steady squad lead. Ask him about the 433."],
    ["Aiden Okafor",       "BANSHEE 1-1", 1, 1, [1],    [],     0, ""],
    ["Lena Storgaard",     "BANSHEE 1-1", 0, 0, [],     [],     0, "New. Second op."],
    ["Diego Marchetti",    "BANSHEE 1-2", 2, 2, [7, 4], [1],    0, "JFO qualified last month."],
    ["Kwame Asante",       "BANSHEE 1-2", 1, 0, [3],    [],     0, ""],
    ["Sofia Lindqvist",    "BANSHEE 1-2", 1, 1, [0],    [],     1, "On leave until the 20th."],
    ["Ryo Takahashi",      "NOMAD 2-1",   3, 2, [7],    [0, 1], 0, "Best Marshall commander we have."],
    ["Elias Brandt",       "NOMAD 2-1",   0, 0, [2],    [],     0, ""],
    ["Nia Campbell",       "NOMAD 2-2",   2, 0, [2],    [],     0, "Driver. Wants gunner."],
    ["Jonah Reyes",        "TALON 3-1",   3, 2, [6],    [0],    0, "Lead pilot."],
    ["Freya Halvorsen",    "TALON 3-1",   1, 0, [6],    [],     0, ""],
    ["Caleb Nwosu",        "WRAITH 4-1",  2, 1, [1],    [1],    0, "CASEVAC crew chief."],
    ["Mateo Salinas",      "WRAITH 4-1",  0, 0, [],     [],     2, "Reserve list."],
    ["Ingrid Vos",         "BANSHEE 1-3", 4, 2, [7, 5], [0],    0, "Platoon sergeant."]
];

// One closed op window, eight days ago, for the sessions to sit under.
private _winStart = [_nowMin - 8 * 1440 - 180] call FUNC(minutesStamp);
private _winEnd = [_nowMin - 8 * 1440] call FUNC(minutesStamp);
if ((GVAR(windows) findIf {(_x # 0) isEqualTo SAMPLE_WINDOW}) < 0) then {
    GVAR(windows) pushBack [SAMPLE_WINDOW, "Sample op night", _winStart, _winEnd, "manual"];
};

private _written = 0;
{
    _x params ["_name", "_group", "_ri", "_oi", "_si", "_ai", "_ti", "_note"];
    private _i = _forEachIndex;
    private _uid = format ["9000000000000%1", [_i + 1, 3] call CBA_fnc_formatNumber];

    private _stamp = [_nowMin - (30 - _i) * 1440] call FUNC(minutesStamp);
    private _rec = createHashMapFromArray [
        ["name", _name],
        ["rankId", [_ranks, _ri] call _fnc_pick],
        ["groupId", _group],
        ["roleId", [_roles, _oi] call _fnc_pick],
        ["skillIds", (_si apply {[_skills, _x] call _fnc_pick}) select {_x isNotEqualTo ""}],
        ["awards", (_ai apply {[[_awards, _x] call _fnc_pick, _stamp, "Sample"]}) select {(_x # 0) isNotEqualTo ""}],
        ["statusId", [_statuses, _ti] call _fnc_pick],
        ["notes", [[_stamp, "Sample", _note]] select {_note isNotEqualTo ""}],
        ["loadouts", createHashMap],
        ["updatedAt", _stamp],
        ["serverId", SAMPLE_TAG]
    ];
    GVAR(players) set [_uid, _rec];
    _written = _written + 1;

    // Most of them were on for the sample op night; a few were not.
    if (_ti isEqualTo 0 && {_i mod 5 isNotEqualTo 4}) then {
        private _joined = [_nowMin - 8 * 1440 - 180 + (_i mod 4) * 10] call FUNC(minutesStamp);
        private _left = [_nowMin - 8 * 1440 - (_i mod 3) * 15] call FUNC(minutesStamp);
        private _row = [_uid, _name, _joined, _left, _left, SAMPLE_WINDOW];
        GVAR(sessions) pushBackUnique _row;
    };
} forEach _people;

[true] call FUNC(storeSave);
[] call FUNC(publish);

[] call FUNC(recordUpgrade);
[getPlayerUID _caller, name _caller, "sample", "", format ["seeded %1 sample record(s)", _written]] call FUNC(logAction);
[format ["Sample data: %1 record(s), one closed op window, and their attendance. REMOVE SAMPLE takes it all out.", _written]] call _fnc_tell;
INFO_2("%1 seeded the sample data (%2 records)",name _caller,_written);

_written
