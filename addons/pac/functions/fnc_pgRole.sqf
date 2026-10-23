#include "script_component.hpp"
/*
    File: fnc_pgRole.sqf
    Author: YonV
    Description: One role - the website's ?page=role and its sections:
        IDENTITY, WHO MAY TAKE IT, NETS, TILES, TRAITS, VARIABLES, LOADOUT,
        ARSENAL. Every save is one FUNC(adminStructure) "roles" set with
        that section's fields, merged over the rest on the server.

        The four engine traits, ACE3's variables and the unit's own
        (Configs, or ORBAT > Variables) are three lists, as on the website
        (user, 2026-09-09).

    Parameters:
        None - reads GVAR(uiArgs): id ("" + s "new" = new), s, want

    Returns:
        Nothing
*/

private _id = GVAR(uiArgs) getOrDefault ["id", ""];
private _s = GVAR(uiArgs) getOrDefault ["s", "identity"];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _structure = GVAR(structure);
private _roles = _structure getOrDefault ["roles", createHashMap];
private _fed = ["roles"] call FUNC(fileFed);

// ---- a new one ------------------------------------------------------------
if (_s isEqualTo "new" || {!(_id in _roles)}) exitWith {
    ["New role", "ORBAT  -  Roles"] call FUNC(uiTitle);
    private _y = [[
        ["id", "Id  (the class - letters, digits, underscore)", "t", GVAR(uiArgs) getOrDefault ["want", _id]],
        ["name", "Shown as", "t", ""]
    ], PAC_UI_TOP] call FUNC(uiForm);
    ["A role's id is the class a squad slot names. Create it, then fill in the rest section by section.", _y + 0.006, 0.06, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
    if (_fed) exitWith {};
    [[["CREATE IT", {
        private _f = [] call FUNC(uiFormRead);
        private _id = trim (_f getOrDefault ["id", ""]);
        if (_id isEqualTo "" || {(toArray _id) findIf {!(_x isEqualTo 95 || {_x >= 48 && _x <= 57} || {_x >= 65 && _x <= 90} || {_x >= 97 && _x <= 122})} >= 0}) exitWith {["Letters, digits and underscore.", true] call FUNC(uiHint)};
        [player, "roles", "set", _id, createHashMapFromArray [["name", trim (_f getOrDefault ["name", ""])]]] remoteExec [QFUNC(adminStructure), 2];
        GVAR(uiHistory) deleteAt ((count GVAR(uiHistory)) - 1);
        ["role", createHashMapFromArray [["id", _id]]] call FUNC(uiGo);
    }]]] call FUNC(uiButtons);
};

private _r = _roles get _id;
private _groups = (_structure getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []];
private _used = (_groups select {_id in (_x param [1, []])}) apply {_x # 0};
[_r getOrDefault ["name", _id], format ["ORBAT  -  Roles  -  %1.role.%2  -  %3%4", _unit, _id, ["used by nothing", "in " + (_used joinString ", ")] select (_used isNotEqualTo []),
    ["", "  -  from the config folder, read only in game"] select _fed]] call FUNC(uiTitle);

[[
    ["IDENTITY", "identity"], ["WHO MAY TAKE IT", "gates"], ["NETS", "nets"], ["TILES", "tiles"],
    ["TRAITS", "traits"], ["VARIABLES", "vars"], ["LOADOUT", "loadout"], ["ARSENAL", "arsenal"]
], _s, {
    params ["_sec"];
    ["role", createHashMapFromArray [["id", GVAR(uiArgs) get "id"], ["s", _sec]]] call FUNC(uiSub);
}] call FUNC(uiSubs);

private _h = PAC_UI_BOTTOM - PAC_UI_TOP;
private _btns = [];
private _fnc_pairs = {
    // [[name, flag], ...] -> the names whose flag is on
    params ["_rows"];
    (_rows select {_x isEqualType [] && {(toLower (str (_x param [1, "true"]))) in ["true", "1", "yes", """true"""]}}) apply {_x param [0, ""]}
};

switch (_s) do {
    case "identity": {
        [[
            ["id", "Id", "r", _id],
            ["name", "Shown as", "t", _r getOrDefault ["name", ""]],
            ["description", "Description", "m", _r getOrDefault ["description", ""], 3],
            ["icon", "Icon", "t", _r getOrDefault ["icon", ""]],
            ["slotTag", "Slot tag", "t", _r getOrDefault ["slotTag", ""]]
        ], PAC_UI_TOP] call FUNC(uiForm);
        if (!_fed) then {
            _btns pushBack ["SAVE IDENTITY", {
                private _f = [] call FUNC(uiFormRead);
                private _out = createHashMap;
                {_out set [_x, trim (_f getOrDefault [_x, ""])]} forEach ["name", "description", "icon", "slotTag"];
                [player, "roles", "set", GVAR(uiArgs) get "id", _out] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
            _btns pushBack ["DELETE ROLE", {
                private _id = GVAR(uiArgs) get "id";
                private _groups = (GVAR(structure) getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []];
                private _used = (_groups select {_id in (_x param [1, []])}) apply {_x # 0};
                [format ["Delete the role %1?%2", _id, ["", format [" It fills slots in %1 - those slots will name a role that does not exist.", _used joinString ", "]] select (_used isNotEqualTo [])], {
                    [player, "roles", "remove", GVAR(uiArgs) get "id", createHashMap] remoteExec [QFUNC(adminStructure), 2];
                    ["orbat", createHashMapFromArray [["s", "roles"]]] call FUNC(uiGo);
                }] call FUNC(uiConfirm);
            }, true];
        };
    };

    case "gates": {
        private _ranks = [["", "- no rank gate -"]];
        {_ranks pushBack [_x, _y getOrDefault ["name", _x]]} forEach (_structure getOrDefault ["ranks", createHashMap]);
        private _y = [[["minRank", "Minimum rank", "c", _r getOrDefault ["minRank", ""], _ranks]], PAC_UI_TOP] call FUNC(uiForm);
        private _skills = _structure getOrDefault ["skills", createHashMap];
        private _ids = keys _skills;
        _ids sort true;
        private _choices = _ids apply {[_x, (_skills get _x) getOrDefault ["name", _x], _x]};
        private _colW = (PAC_UI_W - 0.016) / 2;
        private _listH = _h - (_y - PAC_UI_TOP) - 0.120;
        ["req", _choices, _r getOrDefault ["requiredSkills", []], PAC_IDC_LIST, _y, _listH, "Skills required", PAC_UI_X, _colW] call FUNC(uiToggle);
        ["grant", _choices, _r getOrDefault ["defaultSkills", []], PAC_IDC_LIST2, _y, _listH, "Skills it grants", PAC_UI_X + _colW + 0.016, _colW] call FUNC(uiToggle);
        [[["uids", "Locked to  (Steam ids, one per line)", "m", (_r getOrDefault ["uids", []]) joinString (toString [10]), 3]], _y + _listH + 0.008] call FUNC(uiForm);
        if (!_fed) then {
            _btns pushBack ["SAVE WHO MAY TAKE IT", {
                private _f = [] call FUNC(uiFormRead);
                private _uids = ((_f getOrDefault ["uids", ""]) splitString (toString [10] + " ,")) select {_x isNotEqualTo ""};
                [player, "roles", "set", GVAR(uiArgs) get "id", createHashMapFromArray [
                    ["minRank", _f getOrDefault ["minRank", ""]],
                    ["requiredSkills", +(GVAR(uiSel) getOrDefault ["req", []])],
                    ["defaultSkills", +(GVAR(uiSel) getOrDefault ["grant", []])],
                    ["uids", _uids]
                ]] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "nets": {
        private _nets = _structure getOrDefault ["nets", createHashMap];
        private _ids = keys _nets;
        {_ids pushBackUnique (_x param [0, ""])} forEach (_r getOrDefault ["nets", []]);
        _ids = _ids select {_x isNotEqualTo ""};
        _ids sort true;
        private _choices = _ids apply {[_x, _x, [(_nets getOrDefault [_x, createHashMap]) getOrDefault ["name", ""], "not in the net list"] select (!(_x in _nets))]};
        ["nets", _choices, [_r getOrDefault ["nets", []]] call _fnc_pairs, PAC_IDC_LIST, PAC_UI_TOP, _h, "Messaging nets this role reads  -  the list itself is under Communications"] call FUNC(uiToggle);
        if (!_fed) then {
            _btns pushBack ["SAVE NETS", {
                [player, "roles", "set", GVAR(uiArgs) get "id", createHashMapFromArray [["nets", (GVAR(uiSel) getOrDefault ["nets", []]) joinString ", "]]] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "tiles": {
        private _choices = [
            ["drones", "drones", "Drone picture - contacts, bearing, range"], ["jam", "jam", "Jamming state"], ["hack", "hack", "Hacking suite"],
            ["weather", "weather", "Weather and light"], ["timer", "timer", "Mission timer"], ["radio", "radio", "Radio state"],
            ["intel", "intel", "Intel take"], ["support", "support", "Supports available"], ["pac", "pac", "The PAC tile"]
        ];
        ["tiles", _choices, [_r getOrDefault ["tiles", []]] call _fnc_pairs, PAC_IDC_LIST, PAC_UI_TOP, _h, "TAC//PAD tiles this role gets"] call FUNC(uiToggle);
        if (!_fed) then {
            _btns pushBack ["SAVE TILES", {
                [player, "roles", "set", GVAR(uiArgs) get "id", createHashMapFromArray [["tiles", (GVAR(uiSel) getOrDefault ["tiles", []]) joinString ", "]]] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "traits": {
        // a trait a SKILL sets (effects "trait:NAME") is the skill's to give, not the role's
        private _owned = [];
        {
            {
                if (_x isEqualType "" && {(toLower (_x select [0, 6])) isEqualTo "trait:"}) then {_owned pushBackUnique (toLower (_x select [6]))};
            } forEach (_y getOrDefault ["effects", []]);
        } forEach (_structure getOrDefault ["skills", createHashMap]);
        private _choices = [
            ["medic", "medic", "the engine's medic - can use a medikit"], ["engineer", "engineer", "the engine's engineer - can repair"],
            ["explosiveSpecialist", "explosiveSpecialist", "the engine's EOD - can defuse"], ["UAVHacker", "UAVHacker", "can take a UAV terminal"]
        ] select {!((toLower (_x # 0)) in _owned)};
        ["traits", _choices, [_r getOrDefault ["traits", []]] call _fnc_pairs, PAC_IDC_LIST, PAC_UI_TOP, _h - 0.05, "The four engine traits  -  one a skill already sets is not offered"] call FUNC(uiToggle);
        ["ACE3's variables and the unit's own are under VARIABLES.", PAC_UI_BOTTOM - 0.046, 0.046, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        if (!_fed) then {
            _btns pushBack ["SAVE TRAITS", {
                [player, "roles", "set", GVAR(uiArgs) get "id", createHashMapFromArray [["traits", (GVAR(uiSel) getOrDefault ["traits", []]) joinString ", "]]] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "vars": {
        private _y = [[["customVariables", "Variables  (name=value, comma separated)", "m", ["customVariables", _r getOrDefault ["customVariables", []]] call FUNC(roleFieldText), 3]], PAC_UI_TOP] call FUNC(uiForm);
        private _rows = [
            [["ace_medical_medicClass", "ACE3", "a number: 0 none, 1 medic, 2 doctor"], ""],
            [["ace_isEngineer", "ACE3", "a number: 0 none, 1 engineer, 2 advanced"], ""],
            [["ace_isEOD", "ACE3", "yes / no"], ""]
        ];
        private _traits = ["traits"] call FUNC(structItems);
        private _ids = keys _traits;
        _ids sort true;
        {
            private _t = _traits get _x;
            _rows pushBack [[_x, "this unit's own", format ["%1  -  %2", ["yes / no", "a number"] select ((_t getOrDefault ["kind", "bool"]) isEqualTo "number"), _t getOrDefault ["help", _t getOrDefault ["label", ""]]]], ""];
        } forEach _ids;
        [PAC_IDC_LIST, ["Variable", "Whose", "Takes"], [0, 0.30, 0.44], _rows, {}, _y + 0.006, PAC_UI_BOTTOM - _y - 0.006, "What there is to set  -  isLeader=true, ace_medical_medicClass=1"] call FUNC(uiList);
        if (!_fed) then {
            _btns pushBack ["SAVE VARIABLES", {
                private _f = [] call FUNC(uiFormRead);
                [player, "roles", "set", GVAR(uiArgs) get "id", createHashMapFromArray [["customVariables", trim (_f getOrDefault ["customVariables", ""])]]] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "loadout": {
        disableSerialization;
        private _head = [PAC_IDC_BIGEDIT_HEAD, PAC_UI_X, PAC_UI_TOP, PAC_UI_W, 0.026] call FUNC(uiPlace);
        _head ctrlSetStructuredText parseText "<t color='#93cf72' size='0.7'>DEFAULT LOADOUT  -  the config's own spelling, {} for []; empty = the role's class default</t>";
        private _edit = [PAC_IDC_BIGEDIT, PAC_UI_X, PAC_UI_TOP + 0.028, PAC_UI_W, _h - 0.028] call FUNC(uiPlace);
        _edit ctrlSetText (["defaultLoadout", _r getOrDefault ["defaultLoadout", []]] call FUNC(roleFieldText));
        if (!_fed) then {
            _btns pushBack ["SAVE LOADOUT", {
                disableSerialization;
                [player, "roles", "set", GVAR(uiArgs) get "id", createHashMapFromArray [["defaultLoadout", ctrlText ([PAC_IDC_BIGEDIT] call FUNC(uiCtrl))]]] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "arsenal": {
        private _fnc_lines = {(_r getOrDefault [_this, []]) joinString (toString [10])};
        private _y = [[
            ["arsenalWeapons", "Weapons  (one per line)", "m", "arsenalWeapons" call _fnc_lines, 2],
            ["arsenalMagazines", "Magazines", "m", "arsenalMagazines" call _fnc_lines, 2],
            ["arsenalItems", "Items", "m", "arsenalItems" call _fnc_lines, 2],
            ["arsenalBackpacks", "Backpacks", "m", "arsenalBackpacks" call _fnc_lines, 2],
            ["arsenalWhitelist", "Whitelist  (kept loadouts may only hold these)", "m", "arsenalWhitelist" call _fnc_lines, 2]
        ], PAC_UI_TOP] call FUNC(uiForm);
        private _slug = "role_" + ([_id] call FUNC(uiSlug));
        private _own = ((_structure getOrDefault ["arsenal", createHashMap]) getOrDefault ["variants", createHashMap]) getOrDefault [_slug, createHashMap];
        [format ["This role's own gear above is what the role carries. This role's ARSENAL - %1.arsenal.%2 - is %3; OPEN ROLE ARSENAL edits it.", _unit, _slug, [format ["%1 list(s)", count _own], "not written yet"] select (count _own isEqualTo 0)], _y + 0.006, 0.06, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        if (!_fed) then {
            _btns pushBack ["SAVE ARSENAL", {
                private _f = [] call FUNC(uiFormRead);
                private _out = createHashMap;
                {_out set [_x, ((_f getOrDefault [_x, ""]) splitString (toString [10] + " ,")) select {_x isNotEqualTo ""}]} forEach ["arsenalWeapons", "arsenalMagazines", "arsenalItems", "arsenalBackpacks", "arsenalWhitelist"];
                [player, "roles", "set", GVAR(uiArgs) get "id", _out] remoteExec [QFUNC(adminStructure), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
        _btns pushBack ["OPEN ROLE ARSENAL", {
            ["arsenalLists", createHashMapFromArray [["v", "role_" + ([GVAR(uiArgs) get "id"] call FUNC(uiSlug))]]] call FUNC(uiGo);
        }];
    };
};
[_btns] call FUNC(uiButtons);
