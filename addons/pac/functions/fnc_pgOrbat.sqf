#include "script_component.hpp"
/*
    File: fnc_pgOrbat.sqf
    Author: YonV
    Description: The ORBAT - the website's ?page=orbat and its tabs: ORDERS
        OF BATTLE (the versions), COMMUNICATIONS (nets, ACRE, net plan), ROLES,
        SQUADS, PLATOONS, VARIABLES. Each a table; a row opens the thing.

    Parameters:
        None - reads GVAR(uiArgs): s (the tab)

    Returns:
        Nothing
*/

GVAR(uiLive) = true;
private _s = GVAR(uiArgs) getOrDefault ["s", "versions"];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _structure = GVAR(structure);
private _orbat = _structure getOrDefault ["orbat", createHashMap];
private _groups = _orbat getOrDefault ["groups", []];
private _platoons = _orbat getOrDefault ["platoons", []];
private _roles = _structure getOrDefault ["roles", createHashMap];
private _radio = _structure getOrDefault ["radio", createHashMap];
private _cur = GVAR(settings) getOrDefault ["currentOrbat", ""];
if !(_cur isEqualType "") then {_cur = ""};
private _fed = ["orbat"] call FUNC(fileFed);

["ORBAT", format ["%1.orbat%2  -  squad channels in %1.radio  -  replaces config_groups.hpp%3", _unit, ["", "." + _cur] select (_cur isNotEqualTo ""),
    ["", "  -  FROM THE MISSION'S CONFIG FOLDER, read only in game"] select _fed]] call FUNC(uiTitle);
[[
    ["ORDERS OF BATTLE", "versions"], ["COMMUNICATIONS", "radio"], ["ROLES", "roles"], ["SQUADS", "squads"], ["PLATOONS", "platoons"], ["VARIABLES", "variables"]
], _s, {
    params ["_id"];
    ["orbat", createHashMapFromArray [["s", _id]]] call FUNC(uiSub);
}] call FUNC(uiSubs);

private _fnc_platoonOf = {
    params ["_squad"];
    private _p = _platoons select {_squad in (_x param [4, []])};
    if (_p isEqualTo []) then {""} else {(_p # 0) param [1, (_p # 0) param [0, ""]]}
};
private _fnc_row = {
    params ["_table", "_key"];
    private _rows = _radio getOrDefault [_table, []];
    if !(_rows isEqualType []) then {_rows = []};
    private _r = _rows select {_x isEqualType [] && {toUpper (_x param [0, ""]) isEqualTo toUpper _key}};
    if (_r isEqualTo []) then {[]} else {_r # 0}
};
private _btns = [];
private _h = PAC_UI_BOTTOM - PAC_UI_TOP;

switch (_s) do {
    case "versions": {
        private _known = _structure getOrDefault ["orbatVersions", []];
        if (_known isEqualType createHashMap) then {_known = keys _known};
        if !(_known isEqualType []) then {_known = []};
        private _versions = [""] + (_known select {_x isEqualType "" && _x isNotEqualTo ""});
        private _rows = _versions apply {
            private _isCur = _x isEqualTo _cur;
            private _slots = 0;
            {_slots = _slots + count (_x param [1, []])} forEach _groups;
            [[
                ["", "DEFAULT"] select _isCur,
                _unit + ".orbat" + (["", "." + _x] select (_x isNotEqualTo "")),
                [_orbat getOrDefault ["faction", ""], "(not loaded)"] select (!_isCur),
                [str (count _platoons), ""] select (!_isCur),
                [format ["%1 + %2 slots", count _groups, _slots], ""] select (!_isCur),
                [format ["%1 / %2", [_orbat getOrDefault ["netsVersion", ""], "Default"] select ((_orbat getOrDefault ["netsVersion", ""]) isEqualTo ""), [_orbat getOrDefault ["radioVersion", ""], "Default"] select ((_orbat getOrDefault ["radioVersion", ""]) isEqualTo "")], ""] select (!_isCur)
            ], ["default", _x] select (_x isNotEqualTo "")]
        };
        [PAC_IDC_LIST, ["Default", "Order of battle", "Faction", "Platoons", "Squads", "Comms"], [0, 0.10, 0.40, 0.58, 0.70, 0.84], _rows, {
            params ["_v"];
            ["orbatOne", createHashMapFromArray [["v", ["", _v] select (_v isNotEqualTo "default")]]] call FUNC(uiGo);
        }, PAC_UI_TOP, _h, format ["Orders of battle  %1  -  the mission runs the one marked DEFAULT (settings currentOrbat)", count _versions]] call FUNC(uiList);
        if (!_fed) then {_btns pushBack ["NEW ORDER OF BATTLE", {["orbatNew"] call FUNC(uiGo)}]};
    };

    case "radio": {
        private _nets = _structure getOrDefault ["nets", createHashMap];
        // in their ORDER, as the website lists them, then by id
        private _ids = (keys _nets) apply {[(_nets get _x) getOrDefault ["order", 0], _x]};
        _ids sort true;
        _ids = _ids apply {_x # 1};
        private _netRows = _ids apply {
            private _netId = _x;
            private _n = _nets get _netId;
            private _readers = 0;
            {if (_netId in ((_y getOrDefault ["nets", []]) apply {_x param [0, ""]})) then {_readers = _readers + 1}} forEach _roles;
            [[str (_n getOrDefault ["order", 0]), _netId, _n getOrDefault ["name", ""], format ["%1 role(s)", _readers]], _netId]
        };
        if (_netRows isEqualTo []) then {_netRows = [[["", "No nets", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        // the nets get half the page - there are fourteen; ACRE is four rows and the net plan two
        private _third = (_h - 0.024) * 0.25;
        private _netsH = (_h - 0.024) * 0.5;
        [PAC_IDC_LIST, ["Order", "Net", "What it is for", "Read by"], [0, 0.10, 0.36, 0.76], _netRows, {
            params ["_id"];
            if (_id isEqualTo "") exitWith {};
            ["recordItem", createHashMapFromArray [["sec", "nets"], ["id", _id]]] call FUNC(uiGo);
        }, PAC_UI_TOP, _netsH, format ["Messaging nets  %1  -  %2.nets", count _nets, _unit]] call FUNC(uiList);

        private _fnc_n = {private _v = _radio getOrDefault [_this, []]; if (_v isEqualType []) then {count _v} else {0}};
        [PAC_IDC_LIST2, ["ACRE", "", ""], [0, 0.30, 0.60], [
            [["Short range channels", format ["%1 channel(s)", "srChannels" call _fnc_n], "index, frequency, label"], "sr"],
            [["Medium range channels", format ["%1 channel(s)", "mrChannels" call _fnc_n], "index, frequency, label"], "mr"],
            [["Long range channels", format ["%1 channel(s)", "lrChannels" call _fnc_n], "index, frequency, label, power"], "lr"],
            [["Radios and power", _radio getOrDefault ["acreActiveRadio", ""], "radio in hand on spawn, power, fallbacks, which radios"], "acre"]
        ], {
            params ["_what"];
            if (_what isEqualTo "acre") exitWith {["radioSettings", createHashMapFromArray [["which", "acre"]]] call FUNC(uiGo)};
            ["radioChannels", createHashMapFromArray [["band", _what]]] call FUNC(uiGo);
        }, PAC_UI_TOP + _netsH + 0.012, _third, format ["ACRE  -  %1.radio", _unit]] call FUNC(uiList);

        // THE NET PLAN (game voice): nets on slots, per squad - no frequencies.
        // A squad's slots are edited on the squad (SQUADS tab); the fallbacks here.
        [PAC_IDC_LIST3, ["NET PLAN", "", ""], [0, 0.30, 0.60], [
            [["Fallbacks", format ["%1 squad row(s), %2 net(s)", "tfarNets" call _fnc_n, count ([] call FUNC(netPlan))], "net slots before a man joins a squad"], "nets"]
        ], {
            params ["_what"];
            if (_what isEqualTo "") exitWith {};
            ["radioSettings", createHashMapFromArray [["which", "nets"]]] call FUNC(uiGo);
        }, PAC_UI_TOP + _netsH + _third + 0.024, _third, "NET PLAN  -  game voice: nets, not frequencies; squad slots on the SQUADS tab"] call FUNC(uiList);
        if !(["nets"] call FUNC(fileFed)) then {_btns pushBack ["NEW NET", {["recordItem", createHashMapFromArray [["sec", "nets"], ["id", ""]]] call FUNC(uiGo)}]};
    };

    case "roles": {
        private _f = [] call FUNC(uiFilterShow);
        private _ids = keys _roles;
        _ids sort true;
        private _rows = [];
        {
            private _rid = _x;
            private _r = _roles get _rid;
            private _name = _r getOrDefault ["name", _rid];
            private _used = (_groups select {_rid in (_x param [1, []])}) apply {_x # 0};
            if (_f isNotEqualTo "" && {!(_f in toLower (_rid + " " + _name + " " + (_used joinString " ")))}) then {continue};
            _rows pushBack [[
                _name, _rid,
                [_used joinString ", ", "unused"] select (_used isEqualTo []),
                [_r getOrDefault ["minRank", ""], "-"] select ((_r getOrDefault ["minRank", ""]) isEqualTo ""),
                ["", "locked"] select ((_r getOrDefault ["uids", []]) isNotEqualTo [])
            ], _rid];
        } forEach _ids;
        // a slot that names a role nobody has written - red, and a row that creates it
        {
            _x params [["_gname", ""], ["_slots", []]];
            {
                if !(_x in _roles) then {_rows pushBack [[_x + "  -  NO DOCUMENT", _x, "asked for by " + _gname, "", ""], "+" + _x, [0.894, 0.341, 0.290, 1]]};
            } forEach _slots;
        } forEach _groups;
        if (_rows isEqualTo []) then {_rows = [[["No roles", "", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Role", "Id", "Used by", "Min rank", ""], [0, 0.24, 0.44, 0.78, 0.90], _rows, {
            params ["_id"];
            if (_id isEqualTo "") exitWith {};
            if ((_id select [0, 1]) isEqualTo "+") exitWith {["role", createHashMapFromArray [["id", ""], ["s", "new"], ["want", _id select [1]]]] call FUNC(uiGo)};
            ["role", createHashMapFromArray [["id", _id]]] call FUNC(uiGo);
        }, PAC_UI_TOP, _h, format ["Roles  %1  -  %2.role.<id>", count _roles, _unit]] call FUNC(uiList);
        if !(["roles"] call FUNC(fileFed)) then {_btns pushBack ["NEW ROLE", {["role", createHashMapFromArray [["id", ""], ["s", "new"]]] call FUNC(uiGo)}]};
    };

    case "squads": {
        private _f = [] call FUNC(uiFilterShow);
        private _rows = [];
        {
            _x params [["_name", ""], ["_slots", []], ["_cond", "true"]];
            private _plt = [_name] call _fnc_platoonOf;
            if (_f isNotEqualTo "" && {!(_f in toLower (_name + " " + _plt))}) then {continue};
            private _acre = ["srSquadChannel", _name] call _fnc_row;
            private _tf = ["tfarNets", _name] call _fnc_row;
            private _bad = count (_slots select {!(_x in _roles)});
            _rows pushBack [[
                _name, str (count _slots), [_plt, "no platoon"] select (_plt isEqualTo ""),
                [str (_acre param [1, ""]), "-"] select (_acre isEqualTo []),
                [format ["%1 / %2", _tf param [1, ""], _tf param [2, ""]], "-"] select (_tf isEqualTo []),
                [_cond, ""] select (_cond isEqualTo "true"),
                ["", format ["%1 bad slot(s)", _bad]] select (_bad > 0)
            ], _name, [[], [0.894, 0.341, 0.290, 1]] select (_bad > 0)];
        } forEach _groups;
        if (_rows isEqualTo []) then {_rows = [[["No squads", "", "", "", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Squad", "Slots", "Platoon", "ACRE", "Net sr / lr", "Offered when", ""], [0, 0.22, 0.30, 0.48, 0.56, 0.68, 0.88], _rows, {
            params ["_name"];
            if (_name isEqualTo "") exitWith {};
            ["squad", createHashMapFromArray [["name", _name]]] call FUNC(uiGo);
        }, PAC_UI_TOP, _h, format ["Squads  %1  -  the order is the short range channel order", count _groups]] call FUNC(uiList);
        if (!_fed) then {_btns pushBack ["NEW SQUAD", {["squad", createHashMapFromArray [["name", ""], ["s", "new"]]] call FUNC(uiGo)}]};
    };

    case "platoons": {
        private _rows = _platoons apply {
            _x params [["_id", ""], ["_name", ""], ["_callsign", ""], ["_net", ""], ["_squads", []]];
            private _missing = _squads select {(_groups findIf {(_x # 0) isEqualTo _x}) < 0};
            [[_id, _name, _callsign, _net, _squads joinString ", ", ["", format ["%1 missing", count _missing]] select (_missing isNotEqualTo [])], _id]
        };
        if (_rows isEqualTo []) then {_rows = [[["No platoons", "", "", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Id", "Platoon", "Callsign", "Net", "Squads", ""], [0, 0.12, 0.30, 0.44, 0.56, 0.90], _rows, {
            params ["_id"];
            if (_id isEqualTo "") exitWith {};
            ["platoon", createHashMapFromArray [["id", _id]]] call FUNC(uiGo);
        }, PAC_UI_TOP, _h, format ["Platoons  %1", count _platoons]] call FUNC(uiList);
        if (!_fed) then {_btns pushBack ["NEW PLATOON", {["platoon", createHashMapFromArray [["id", ""], ["s", "new"]]] call FUNC(uiGo)}]};
    };

    case "variables": {
        private _traits = ["traits"] call FUNC(structItems);
        private _ids = keys _traits;
        _ids sort true;
        private _rows = _ids apply {
            private _t = _traits get _x;
            [[_x, _t getOrDefault ["label", _x], _t getOrDefault ["kind", "bool"], _t getOrDefault ["help", ""]], _x]
        };
        if (_rows isEqualTo []) then {_rows = [[["No custom variables - roles set the four engine traits and ACE3's own", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Variable", "Shown as", "Kind", "What it does"], [0, 0.24, 0.46, 0.58], _rows, {
            params ["_id"];
            if (_id isEqualTo "") exitWith {};
            ["recordItem", createHashMapFromArray [["sec", "traits"], ["id", _id]]] call FUNC(uiGo);
        }, PAC_UI_TOP, _h, format ["Custom variables  %1  -  the unit's own; a role sets them on a man", count _traits]] call FUNC(uiList);
        if !(["traits"] call FUNC(fileFed)) then {_btns pushBack ["NEW VARIABLE", {["recordItem", createHashMapFromArray [["sec", "traits"], ["id", ""]]] call FUNC(uiGo)}]};
    };
};
[_btns] call FUNC(uiButtons);
