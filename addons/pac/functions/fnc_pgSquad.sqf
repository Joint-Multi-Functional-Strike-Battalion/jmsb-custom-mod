#include "script_component.hpp"
/*
    File: fnc_pgSquad.sqf
    Author: YonV
    Description: One squad - the website's ?page=squad and its sections:
        IDENTITY, SLOTS, RADIO, ARSENAL, MOTORPOOL, COPY. A squad is a row
        of the ORBAT's groups - [name, roles, condition, kind] - and every
        save is one FUNC(adminOrbat) "squad" set.

    Parameters:
        None - reads GVAR(uiArgs): name ("" + s "new" = new), s, pick

    Returns:
        Nothing
*/

private _name = GVAR(uiArgs) getOrDefault ["name", ""];
private _s = GVAR(uiArgs) getOrDefault ["s", "identity"];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _structure = GVAR(structure);
private _orbat = _structure getOrDefault ["orbat", createHashMap];
private _groups = _orbat getOrDefault ["groups", []];
private _roles = _structure getOrDefault ["roles", createHashMap];
private _radio = _structure getOrDefault ["radio", createHashMap];
private _fed = ["orbat"] call FUNC(fileFed);
private _at = _groups findIf {toUpper (_x # 0) isEqualTo toUpper _name};

private _roleOpts = [["", "- empty -"]];
private _rids = keys _roles;
_rids sort true;
{_roleOpts pushBack [_x, format ["%1  (%2)", (_roles get _x) getOrDefault ["name", _x], _x]]} forEach _rids;

// ---- a new one ------------------------------------------------------------
if (_s isEqualTo "new" || _at < 0) exitWith {
    ["New squad", "ORBAT  -  Squads"] call FUNC(uiTitle);
    private _y = [[
        ["name", "Name  (JMFSB 6, BANSHEE 1-1)", "t", _name],
        ["role", "First slot's role", "c", "", _roleOpts select [1]]
    ], PAC_UI_TOP] call FUNC(uiForm);
    ["A squad needs at least one slot. It is added at the end of the list - the order is the short range channel order.", _y + 0.006, 0.06, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
    if (_fed) exitWith {};
    [[["CREATE IT", {
        private _f = [] call FUNC(uiFormRead);
        private _name = trim (_f getOrDefault ["name", ""]);
        private _role = _f getOrDefault ["role", ""];
        if (_name isEqualTo "") exitWith {["A squad needs a name.", true] call FUNC(uiHint)};
        if (_role isEqualTo "") exitWith {["Pick a role for the first slot.", true] call FUNC(uiHint)};
        [player, "squad", "set", "", createHashMapFromArray [["name", _name], ["roles", [_role]], ["condition", "true"]]] remoteExec [QFUNC(adminOrbat), 2];
        GVAR(uiHistory) deleteAt ((count GVAR(uiHistory)) - 1);
        ["squad", createHashMapFromArray [["name", _name]]] call FUNC(uiGo);
    }]]] call FUNC(uiButtons);
};

private _row = _groups # _at;
_row params [["_sqName", ""], ["_slots", []], ["_cond", "true"], ["_kind", ""]];
if !(_kind isEqualType "") then {_kind = ""};
private _platoons = _orbat getOrDefault ["platoons", []];
private _plt = _platoons select {_sqName in (_x param [4, []])};
[_sqName, format ["ORBAT  -  Squads  -  %1.orbat  -  %2%3", _unit, [format ["in %1", (_plt # 0) param [1, ""]], "no platoon lists it - the roster page shows it under none"] select (_plt isEqualTo []),
    ["", "  -  from the config folder, read only in game"] select _fed]] call FUNC(uiTitle);

[[
    ["IDENTITY", "identity"], ["SLOTS", "slots"], ["RADIO", "radio"], ["ARSENAL", "arsenal"], ["MOTORPOOL", "motorpool"], ["COPY", "copy"]
], _s, {
    params ["_sec"];
    ["squad", createHashMapFromArray [["name", GVAR(uiArgs) get "name"], ["s", _sec]]] call FUNC(uiSub);
}] call FUNC(uiSubs);

private _h = PAC_UI_BOTTOM - PAC_UI_TOP;
private _btns = [];
private _slug = "sqd_" + ([_sqName] call FUNC(uiSlug));

switch (_s) do {
    case "identity": {
        [[
            ["name", "Name", "t", _sqName],
            ["kind", "Kind  (inf, motor_inf, mech_inf, air, armor, recon, hq, med, mortar, uav ...)", "t", _kind],
            ["condition", "Offered when  (SQF, true = always)", "t", _cond]
        ], PAC_UI_TOP] call FUNC(uiForm);
        ["The condition is evaluated on the slotting screen; a squad whose condition is false is not offered. Renaming moves the roster's group ids with it.", PAC_UI_TOP + 0.12, 0.06, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        if (!_fed) then {
            _btns pushBack ["SAVE IDENTITY", {
                private _f = [] call FUNC(uiFormRead);
                private _key = GVAR(uiArgs) get "name";
                private _groups = (GVAR(structure) getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []];
                private _at = _groups findIf {toUpper (_x # 0) isEqualTo toUpper _key};
                if (_at < 0) exitWith {};
                private _newName = trim (_f getOrDefault ["name", ""]);
                if (_newName isEqualTo "") exitWith {["A squad needs a name.", true] call FUNC(uiHint)};
                [player, "squad", "set", _key, createHashMapFromArray [["name", _newName], ["roles", (_groups # _at) param [1, []]], ["condition", trim (_f getOrDefault ["condition", "true"])], ["type", trim (_f getOrDefault ["kind", ""])]]] remoteExec [QFUNC(adminOrbat), 2];
                if (_newName isNotEqualTo _key) then {
                    GVAR(uiArgs) set ["name", _newName];
                    GVAR(uiHistory) set [(count GVAR(uiHistory)) - 1, ["squad", GVAR(uiArgs)]];
                };
                ["Saved.", false] call FUNC(uiHint);
            }];
            _btns pushBack ["DELETE SQUAD", {
                [format ["Delete the squad %1? Anybody whose record names it keeps the name until it is re-picked.", GVAR(uiArgs) get "name"], {
                    [player, "squad", "remove", GVAR(uiArgs) get "name", createHashMap] remoteExec [QFUNC(adminOrbat), 2];
                    ["orbat", createHashMapFromArray [["s", "squads"]]] call FUNC(uiGo);
                }] call FUNC(uiConfirm);
            }, true];
        };
    };

    case "slots": {
        // a working copy of the slots until SAVE SLOTS
        if (isNil QGVAR(uiSlots) || {(missionNamespace getVariable [QGVAR(uiSlotsKey), ""]) isNotEqualTo _sqName}) then {
            GVAR(uiSlots) = +_slots;
            GVAR(uiSlotsKey) = _sqName;
        };
        private _pick = GVAR(uiArgs) getOrDefault ["pick", -1];
        private _rows = [];
        {
            _rows pushBack [[str (_forEachIndex + 1), (_roles getOrDefault [_x, createHashMap]) getOrDefault ["name", _x + "  -  NO DOCUMENT"], _x, ["", "lead"] select (_forEachIndex isEqualTo 0), ["", "<"] select (_forEachIndex isEqualTo _pick)], str _forEachIndex, [[], [0.894, 0.341, 0.290, 1]] select (!(_x in _roles))];
        } forEach GVAR(uiSlots);
        if (_rows isEqualTo []) then {_rows = [[["", "No slots", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        private _listH = _h - 0.060;
        [PAC_IDC_LIST, ["Slot", "Role", "Id", "", ""], [0, 0.08, 0.50, 0.80, 0.90], _rows, {
            params ["_i"];
            if (_i isEqualTo "") exitWith {};
            private _a = +GVAR(uiArgs);
            _a set ["pick", parseNumber _i];
            ["squad", _a] call FUNC(uiSub);
        }, PAC_UI_TOP, _listH, format ["Slots  %1  -  click one, pick its role below, SET  -  SAVE SLOTS writes them%2", count GVAR(uiSlots), ["", "  (unsaved changes)"] select (GVAR(uiSlots) isNotEqualTo _slots)]] call FUNC(uiList);
        [[["role", ["Role for slot " + str (_pick + 1), "Role for a new slot"] select (_pick < 0), "c", GVAR(uiSlots) param [_pick, ""], _roleOpts]], PAC_UI_TOP + _listH + 0.008, PAC_UI_X, PAC_UI_W / 2] call FUNC(uiForm);
        if (!_fed) then {
            _btns pushBack [["ADD SLOT", "SET SLOT"] select (_pick >= 0), {
                private _f = [] call FUNC(uiFormRead);
                private _role = _f getOrDefault ["role", ""];
                private _pick = GVAR(uiArgs) getOrDefault ["pick", -1];
                if (_role isEqualTo "") exitWith {["Pick a role.", true] call FUNC(uiHint)};
                if (_pick >= 0 && _pick < count GVAR(uiSlots)) then {GVAR(uiSlots) set [_pick, _role]} else {GVAR(uiSlots) pushBack _role};
                private _a = +GVAR(uiArgs);
                _a set ["pick", -1];
                ["squad", _a] call FUNC(uiSub);
            }];
            _btns pushBack ["REMOVE LAST SLOT", {
                if (count GVAR(uiSlots) > 1) then {GVAR(uiSlots) deleteAt ((count GVAR(uiSlots)) - 1)} else {["A squad keeps at least one slot.", true] call FUNC(uiHint)};
                private _a = +GVAR(uiArgs);
                _a set ["pick", -1];
                ["squad", _a] call FUNC(uiSub);
            }, true];
            _btns pushBack ["SAVE SLOTS", {
                private _key = GVAR(uiArgs) get "name";
                private _groups = (GVAR(structure) getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []];
                private _at = _groups findIf {toUpper (_x # 0) isEqualTo toUpper _key};
                if (_at < 0) exitWith {};
                private _row = _groups # _at;
                [player, "squad", "set", _key, createHashMapFromArray [["name", _key], ["roles", +GVAR(uiSlots)], ["condition", _row param [2, "true"]], ["type", _row param [3, ""]]]] remoteExec [QFUNC(adminOrbat), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "radio": {
        private _fnc_row = {
            params ["_table"];
            private _rows = _radio getOrDefault [_table, []];
            if !(_rows isEqualType []) then {_rows = []};
            private _r = _rows select {_x isEqualType [] && {toUpper (_x param [0, ""]) isEqualTo toUpper _sqName}};
            if (_r isEqualTo []) then {[]} else {_r # 0}
        };
        private _acre = ["srSquadChannel"] call _fnc_row;
        private _tf = ["tfarNets"] call _fnc_row;
        [[
            ["acre", "ACRE short range channel  (blank = none)", "t", [str (_acre param [1, ""]), ""] select (_acre isEqualTo [])],
            ["tfarSw", "Short range net slot  (0-8, blank = none)", "t", [str (_tf param [1, ""]), ""] select (_tf isEqualTo [])],
            ["tfarLr", "Long range net slot  (0-8)", "t", [str (_tf param [2, ""]), ""] select (_tf isEqualTo [])]
        ], PAC_UI_TOP] call FUNC(uiForm);
        ["Written to " + _unit + ".radio - srSquadChannel (ACRE) and tfarNets (the net plan), keyed by the squad's name.", PAC_UI_TOP + 0.12, 0.05, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        if !(["radio"] call FUNC(fileFed)) then {
            _btns pushBack ["SAVE CHANNELS", {
                private _f = [] call FUNC(uiFormRead);
                [player, "squadRadio", "set", GVAR(uiArgs) get "name", createHashMapFromArray [["acre", trim (_f getOrDefault ["acre", ""])], ["tfarSw", trim (_f getOrDefault ["tfarSw", ""])], ["tfarLr", trim (_f getOrDefault ["tfarLr", ""])]]] remoteExec [QFUNC(adminOrbat), 2];
                ["Saved.", false] call FUNC(uiHint);
            }];
        };
    };

    case "arsenal": {
        private _own = ((_structure getOrDefault ["arsenal", createHashMap]) getOrDefault ["variants", createHashMap]) getOrDefault [_slug, createHashMap];
        [format ["This squad's arsenal is %1.arsenal.%2 - %3. It is laid over the common arsenal and the platoon's for everybody slotted here.", _unit, _slug, [format ["%1 list(s)", count _own], "not written yet"] select (count _own isEqualTo 0)], PAC_UI_TOP, 0.08, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        _btns pushBack ["OPEN SQUAD ARSENAL", {["arsenalLists", createHashMapFromArray [["v", "sqd_" + ([GVAR(uiArgs) get "name"] call FUNC(uiSlug))]]] call FUNC(uiGo)}];
    };

    case "motorpool": {
        private _own = (_structure getOrDefault ["motorpoolVariants", createHashMap]) getOrDefault [_slug, createHashMap];
        [format ["This squad's motorpool is %1.motorpool.%2 - %3.", _unit, _slug, [format ["%1 heading(s)", count _own], "not written yet"] select (count _own isEqualTo 0)], PAC_UI_TOP, 0.08, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        _btns pushBack ["OPEN SQUAD MOTORPOOL", {["record", createHashMapFromArray [["sec", "motorpool"], ["v", "sqd_" + ([GVAR(uiArgs) get "name"] call FUNC(uiSlug))]]] call FUNC(uiGo)}];
    };

    case "copy": {
        [[["to", "Copy to  (the new squad's name)", "t", ""]], PAC_UI_TOP] call FUNC(uiForm);
        ["The slots, the condition and the kind are copied; channels are not - set them on the new squad.", PAC_UI_TOP + 0.05, 0.05, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
        if (!_fed) then {
            _btns pushBack ["COPY", {
                private _f = [] call FUNC(uiFormRead);
                private _to = trim (_f getOrDefault ["to", ""]);
                if (_to isEqualTo "") exitWith {["Name the new squad.", true] call FUNC(uiHint)};
                private _key = GVAR(uiArgs) get "name";
                private _groups = (GVAR(structure) getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []];
                private _at = _groups findIf {toUpper (_x # 0) isEqualTo toUpper _key};
                if (_at < 0) exitWith {};
                private _row = _groups # _at;
                [player, "squad", "set", "", createHashMapFromArray [["name", _to], ["roles", +(_row param [1, []])], ["condition", _row param [2, "true"]], ["type", _row param [3, ""]]]] remoteExec [QFUNC(adminOrbat), 2];
                ["squad", createHashMapFromArray [["name", _to]]] call FUNC(uiGo);
            }];
        };
    };
};
[_btns] call FUNC(uiButtons);
