#include "script_component.hpp"
/*
    File: fnc_pgPlayer.sqf
    Author: YonV
    Description: One operator - the website's ?page=player, its blocks as
        tabs because a page in game cannot scroll: DETAILS, SKILLS,
        QUALIFICATIONS, TRAINING, RANGES, AWARDS, NOTES, THE REST.

        THE WHOLE RECORD comes from the server (FUNC(adminGet)) - the roster
        a client holds is the published row, which has no notes, no
        training, no Discord id. Every save is one FUNC(adminSet) per field
        that changed, and the server answers with the record again, which
        redraws this page.

    Parameters:
        None - reads GVAR(uiArgs): uid, s (the tab)

    Returns:
        Nothing
*/

private _uid = GVAR(uiArgs) getOrDefault ["uid", ""];
private _sec = GVAR(uiArgs) getOrDefault ["s", "details"];
private _key = "record:" + _uid;

private _row = (missionNamespace getVariable [QGVAR(roster), []]) select {(_x # 0) isEqualTo _uid};
private _name = if (_row isEqualTo []) then {_uid} else {(_row # 0) # 1};
[_name, format ["Roster  -  %1", _uid]] call FUNC(uiTitle);

if !([_key] call FUNC(uiAsk)) exitWith {};
private _rec = GVAR(uiData) get _key;
if !(_rec isEqualType createHashMap) exitWith {["That record is not on the server.", true] call FUNC(uiHint)};

private _structure = GVAR(structure);
private _fnc_opts = {
    // [[id, name], ...] for a combo, with "- none -" first
    params ["_section", ["_current", ""]];
    private _items = _structure getOrDefault [_section, createHashMap];
    private _out = [["", "- none -"]];
    private _ids = keys _items;
    _ids sort true;
    {_out pushBack [_x, (_items get _x) getOrDefault ["name", _x]]} forEach _ids;
    if (_current isNotEqualTo "" && {!(_current in _items)}) then {_out pushBack [_current, _current + " - not in the structure"]};
    _out
};

[[
    ["DETAILS", "details"], ["SKILLS", "skills"], ["QUALIFICATIONS", "quals"], ["TRAINING", "training"],
    ["RANGES", "ranges"], ["AWARDS", "awards"], ["NOTES", "notes"], ["THE REST", "rest"]
], _sec, {
    params ["_id"];
    ["player", createHashMapFromArray [["uid", GVAR(uiArgs) get "uid"], ["s", _id]]] call FUNC(uiSub);
}] call FUNC(uiSubs);

// The tiles are on every tab, as the website's are at the top of the page.
private _y = [[
    [_rec getOrDefault ["operatorId", ""], "operator id"],
    [["ranks", _rec getOrDefault ["rankId", ""]] call FUNC(lookup), "rank"],
    [["statuses", _rec getOrDefault ["statusId", ""]] call FUNC(lookup), "status"],
    [_rec getOrDefault ["enlistedAt", ""], "enlisted"]
]] call FUNC(uiTiles);
private _h = PAC_UI_BOTTOM - _y;

switch (_sec) do {
    case "details": {
        private _squads = ((_structure getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []]) apply {_x # 0};
        private _groupOpts = [["", "- none -"]] + (_squads apply {[_x, _x]});
        private _g = _rec getOrDefault ["groupId", ""];
        if (_g isNotEqualTo "" && {!(_g in _squads)}) then {_groupOpts pushBack [_g, _g + " - not in the order of battle"]};
        [[
            ["name", "Name", "r", _rec getOrDefault ["name", ""]],
            ["milsimName", "Milsim name", "t", _rec getOrDefault ["milsimName", ""]],
            ["rankId", "Rank", "c", _rec getOrDefault ["rankId", ""], ["ranks", _rec getOrDefault ["rankId", ""]] call _fnc_opts],
            ["roleId", "Role", "c", _rec getOrDefault ["roleId", ""], ["roles", _rec getOrDefault ["roleId", ""]] call _fnc_opts],
            ["groupId", "Group", "c", _g, _groupOpts],
            ["statusId", "Status", "c", _rec getOrDefault ["statusId", ""], ["statuses", _rec getOrDefault ["statusId", ""]] call _fnc_opts],
            ["company", "Company", "t", _rec getOrDefault ["company", ""]],
            ["clearance", "Clearance", "t", _rec getOrDefault ["clearance", ""]],
            ["discordId", "Discord id", "t", _rec getOrDefault ["discordId", ""]],
            ["email", "Email", "t", _rec getOrDefault ["email", ""]],
            ["reportsTo", "Reports to", "t", _rec getOrDefault ["reportsTo", ""]],
            ["enlistedAt", "Enlisted (YYYY-MM-DD)", "t", _rec getOrDefault ["enlistedAt", ""]],
            ["promotedAt", "Promoted (YYYY-MM-DD)", "t", _rec getOrDefault ["promotedAt", ""]]
        ], _y] call FUNC(uiForm);
        [[
            ["SAVE DETAILS", {
                private _f = [] call FUNC(uiFormRead);
                private _rec = GVAR(uiData) get ("record:" + (GVAR(uiArgs) get "uid"));
                private _n = 0;
                {
                    private _was = _rec getOrDefault [_x, ""];
                    if !(_was isEqualType "") then {_was = str _was};
                    private _now = _f getOrDefault [_x, ""];
                    if (_now isEqualType "") then {_now = trim _now};
                    if (_now isNotEqualTo _was) then {
                        [_x, _now] call FUNC(uiSet);
                        _n = _n + 1;
                    };
                } forEach ["milsimName", "rankId", "roleId", "groupId", "statusId", "company", "clearance", "discordId", "email", "reportsTo", "enlistedAt", "promotedAt"];
                [[format ["%1 field(s) sent", _n], "Nothing changed"] select (_n isEqualTo 0), false] call FUNC(uiHint);
            }]
        ]] call FUNC(uiButtons);
    };

    case "skills": {
        // The website's checkgrid. Click a row to tick or untick it, then SAVE.
        if ((missionNamespace getVariable [QGVAR(uiSkillUid), ""]) isNotEqualTo _uid) then {
            GVAR(uiSkillSel) = +(_rec getOrDefault ["skillIds", []]);
            GVAR(uiSkillUid) = _uid;
        };
        private _skills = _structure getOrDefault ["skills", createHashMap];
        private _ids = keys _skills;
        _ids sort true;
        private _rows = _ids apply {
            private _s = _skills get _x;
            [[["[  ]", "[ x ]"] select (_x in GVAR(uiSkillSel)), _s getOrDefault ["name", _x], _s getOrDefault ["abbrev", ""], (_s getOrDefault ["effects", []]) joinString ", "], _x]
        };
        [PAC_IDC_LIST, ["", "Skill", "Abbrev", "Effects"], [0, 0.06, 0.40, 0.55], _rows, {
            params ["_id"];
            if (_id in GVAR(uiSkillSel)) then {GVAR(uiSkillSel) deleteAt (GVAR(uiSkillSel) find _id)} else {GVAR(uiSkillSel) pushBack _id};
            [] call FUNC(uiDraw);
        }, _y, _h, "Skills  -  click to tick"] call FUNC(uiList);
        [[
            ["SAVE SKILLS", {
                ["skillIds", +GVAR(uiSkillSel)] call FUNC(uiSet);
                ["Skills sent - the first grant of a skill dates a qualification.", false] call FUNC(uiHint);
            }]
        ]] call FUNC(uiButtons);
    };

    case "quals": {
        private _rows = (_rec getOrDefault ["qualifications", []]) apply {
            _x params [["_sid", ""], ["_sname", ""], ["_since", ""]];
            [[[_sname, ["skills", _sid] call FUNC(lookup)] select (_sname isEqualTo ""), _since], ""]
        };
        if (_rows isEqualTo []) then {_rows = [[["None yet", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Skill", "Since"], [0, 0.40], _rows, {}, _y, _h, format ["Qualifications  %1", count (_rec getOrDefault ["qualifications", []])]] call FUNC(uiList);
    };

    case "training": {
        private _tr = _rec getOrDefault ["training", []];
        private _rows = [];
        {
            _x params [["_when", ""], ["_by", ""], ["_text", ""], ["_course", ""]];
            _rows pushBack [[_when select [0, 10], ["trainings", _course] call FUNC(lookup), _text, _by], str _forEachIndex];
        } forEach _tr;
        if (_rows isEqualTo []) then {_rows = [[["", "None yet", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        private _listH = _h - 0.090;
        [PAC_IDC_LIST, ["When", "Course", "Note", "By"], [0, 0.14, 0.40, 0.84], _rows, {
            params ["_i"];
            if (_i isEqualTo "") exitWith {};
            [format ["Remove training row %1?", (parseNumber _i) + 1], {
                ["trainingRemove", parseNumber _this] call FUNC(uiSet);
            }, _i] call FUNC(uiConfirm);
        }, _y, _listH, format ["Training  %1  -  click a row to remove it", count _tr]] call FUNC(uiList);
        private _courses = [["", "- course -"]];
        {_courses pushBack [_x, _y getOrDefault ["name", _x]]} forEach (_structure getOrDefault ["trainings", createHashMap]);
        [[
            ["courseId", "Course", "c", "", _courses],
            ["text", "Note - lead with 2026-08-01 to back-date it", "t", ""]
        ], _y + _listH + 0.008] call FUNC(uiForm);
        [[
            ["ADD TRAINING", {
                private _f = [] call FUNC(uiFormRead);
                ["trainingAdd", [_f getOrDefault ["courseId", ""], trim (_f getOrDefault ["text", ""])]] call FUNC(uiSet);
            }]
        ]] call FUNC(uiButtons);
    };

    case "awards": {
        private _aw = _rec getOrDefault ["awards", []];
        private _rows = _aw apply {
            _x params [["_aid", ""], ["_when", ""], ["_by", ""], ["_cit", ""]];
            [[["awards", _aid] call FUNC(lookup), _when select [0, 10], _cit, _by], _aid]
        };
        if (_rows isEqualTo []) then {_rows = [[["None", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        private _listH = _h - 0.090;
        [PAC_IDC_LIST, ["Award", "When", "Citation", "By"], [0, 0.26, 0.44, 0.80], _rows, {
            params ["_aid"];
            if (_aid isEqualTo "") exitWith {};
            [format ["Remove the award %1?", ["awards", _aid] call FUNC(lookup)], {
                ["awardRemove", _this] call FUNC(uiSet);
            }, _aid] call FUNC(uiConfirm);
        }, _y, _listH, format ["Awards  %1  -  click a row to remove it", count _aw]] call FUNC(uiList);
        private _opts = [["", "- award -"]];
        {_opts pushBack [_x, _y getOrDefault ["name", _x]]} forEach (_structure getOrDefault ["awards", createHashMap]);
        [[
            ["awardId", "Award", "c", "", _opts],
            ["citation", "Citation", "t", ""]
        ], _y + _listH + 0.008] call FUNC(uiForm);
        [[
            ["AWARD IT", {
                private _f = [] call FUNC(uiFormRead);
                private _id = _f getOrDefault ["awardId", ""];
                if (_id isEqualTo "") exitWith {["Pick an award.", true] call FUNC(uiHint)};
                ["awardAdd", [_id, trim (_f getOrDefault ["citation", ""])]] call FUNC(uiSet);
            }]
        ]] call FUNC(uiButtons);
    };

    case "notes": {
        private _notes = _rec getOrDefault ["notes", []];
        private _rows = _notes apply {
            _x params [["_when", ""], ["_by", ""], ["_text", ""]];
            [[_when select [0, 16], _by, _text], ""]
        };
        if (_rows isEqualTo []) then {_rows = [[["", "", "No notes"], "", [0.545, 0.592, 0.639, 1]]]};
        private _listH = _h - 0.120;
        [PAC_IDC_LIST, ["When", "By", "Note"], [0, 0.16, 0.32], _rows, {}, _y, _listH, format ["Notes  %1  -  admins only, never published", count _notes]] call FUNC(uiList);
        [[["text", "Note", "m", "", 2]], _y + _listH + 0.008] call FUNC(uiForm);
        [[
            ["ADD NOTE", {
                private _f = [] call FUNC(uiFormRead);
                private _t = trim (_f getOrDefault ["text", ""]);
                if (_t isEqualTo "") exitWith {["Nothing to add.", true] call FUNC(uiHint)};
                ["noteAdd", _t] call FUNC(uiSet);
            }]
        ]] call FUNC(uiButtons);
    };

    case "ranges": {
        // Shooting-range runs (FUNC(rangeStore)): by range, newest first, the
        // latest run of each range in PAC_RANGE_LATEST.
        private _runs = _rec getOrDefault ["ranges", []];
        private _names = [];
        {_names pushBackUnique (_x param [1, ""])} forEach _runs;
        _names sort true;
        private _rows = [];
        {
            private _name = _x;
            // the stamps sort as text, so descending is newest first
            private _of = (_runs select {(_x param [1, ""]) isEqualTo _name}) apply {[_x param [0, ""], _x]};
            _of sort false;
            {
                (_x # 1) params [["_when", ""], ["_range", ""], ["_mode", ""], ["_detail", ""], ["_hits", 0], ["_shown", 0], ["_secs", 0]];
                private _pct = if (_shown > 0) then {round (100 * _hits / _shown)} else {0};
                private _row = [[_range, _when select [0, 16], format ["%1 / %2  (%3%%)  %4 s", _hits, _shown, _pct, _secs],
                    format ["%1 - %2", _mode, _detail]], ""];
                if (_forEachIndex isEqualTo 0) then {_row pushBack PAC_RANGE_LATEST};
                _rows pushBack _row;
            } forEach _of;
        } forEach _names;
        if (_rows isEqualTo []) then {_rows = [[["None yet", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Range", "When", "Score", "Mode"], [0, 0.26, 0.44, 0.66], _rows, {}, _y, _h,
            format ["Ranges  %1 runs  -  the latest of each range is highlighted", count _runs]] call FUNC(uiList);
    };

    case "rest": {
        (_rec getOrDefault ["_promotion", [0, [], "", 0, 0]]) params [["_pts", 0], ["_breakdown", []], ["_next", ""], ["_need", 0]];
        (_rec getOrDefault ["attendanceSummary", [0, 0, 0, 0, 0]]) params [["_sched", 0], ["_attended", 0], ["_excused", 0], ["_unexcused", 0], ["_pct", 0]];
        private _kv = [
            ["Admin actions", str (count (_rec getOrDefault ["adminActions", []]))],
            ["Loadouts kept", str (count (_rec getOrDefault ["loadouts", createHashMap]))],
            ["Promoted", _rec getOrDefault ["promotedAt", ""]],
            ["Last updated", _rec getOrDefault ["updatedAt", ""]],
            ["Server", _rec getOrDefault ["serverId", ""]],
            ["Promotion points", format ["%1  (next %2, %3 more needed)", round _pts, ["ranks", _next] call FUNC(lookup), round (_need max 0)]],
            ["Attendance", format ["%1 of %2 windows, %3 excused, %4 unexcused  (%5%6)", _attended, _sched, _excused, _unexcused, round _pct, "%"]]
        ];
        private _kvH = 0.028 + (count _kv) * 0.032;
        [PAC_IDC_LIST, [], [0, 0.26], _kv apply {[_x, ""]}, {}, _y, _kvH, "The rest"] call FUNC(uiList);
        private _bd = _breakdown apply {
            _x params [["_what", ""], ["_qty", 0], ["_weight", 0], ["_p", 0]];
            [[_what, str _qty, str _weight, str (round _p)], ""]
        };
        [PAC_IDC_LIST2, ["What", "Quantity", "Weight", "Points"], [0, 0.40, 0.58, 0.76], _bd, {}, _y + _kvH + 0.008, _h - _kvH - 0.008, "How the points add up"] call FUNC(uiList);
        private _unit = objNull;
        {if (([_x] call FUNC(uid)) isEqualTo _uid) exitWith {_unit = _x}} forEach allPlayers;
        private _btns = [
            ["EXPORT RECORD", {
                [player, "operator", GVAR(uiArgs) get "uid"] remoteExec [QFUNC(adminText), 2];
                ["The record goes to your clipboard and the .rpt when it arrives.", false] call FUNC(uiHint);
            }]
        ];
        if (!isNull _unit) then {
            _btns pushBack ["KICK", {
                private _u = objNull;
                {if (([_x] call FUNC(uid)) isEqualTo (GVAR(uiArgs) get "uid")) exitWith {_u = _x}} forEach allPlayers;
                if (isNull _u) exitWith {};
                [format ["Kick %1 from the server?", name _u], {
                    params ["_u"];
                    // By player id, not name (review L1): a name can be shared
                    // or carry spaces. serverCommand works only for the logged-in
                    // server admin, and only a kick that went out is logged.
                    if !(serverCommandAvailable "#kick") exitWith {["Log in as the server's admin (#login) to kick.", true] call FUNC(uiHint)};
                    private _id = getPlayerID _u;
                    if (_id isEqualTo "") exitWith {["That player has left.", true] call FUNC(uiHint)};
                    if !(serverCommand format ["#kick %1", _id]) exitWith {["The server did not take the kick.", true] call FUNC(uiHint)};
                    [player, "kick", [_u] call FUNC(uid), format ["kicked %1", name _u]] remoteExec [QFUNC(adminLogAdd), 2];
                }, _u] call FUNC(uiConfirm);
            }, true];
            _btns pushBack ["BAN", {
                private _u = objNull;
                {if (([_x] call FUNC(uid)) isEqualTo (GVAR(uiArgs) get "uid")) exitWith {_u = _x}} forEach allPlayers;
                if (isNull _u) exitWith {};
                [format ["BAN %1 from the server? This is not a kick.", name _u], {
                    params ["_u"];
                    // As the kick (review L1): by player id, logged-in admin
                    // only, logged only when the server took it.
                    if !(serverCommandAvailable "#kick") exitWith {["Log in as the server's admin (#login) to ban.", true] call FUNC(uiHint)};
                    private _id = getPlayerID _u;
                    if (_id isEqualTo "") exitWith {["That player has left.", true] call FUNC(uiHint)};
                    if !(serverCommand format ["#exec ban %1", _id]) exitWith {["The server did not take the ban.", true] call FUNC(uiHint)};
                    [player, "ban", [_u] call FUNC(uid), format ["banned %1", name _u]] remoteExec [QFUNC(adminLogAdd), 2];
                }, _u] call FUNC(uiConfirm);
            }, true];
        };
        [_btns] call FUNC(uiButtons);
    };
};
