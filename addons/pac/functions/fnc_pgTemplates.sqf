#include "script_component.hpp"
/*
    File: fnc_pgTemplates.sqf
    Author: YonV
    Description: Templates - the website's ?page=config: a tab a template
        (Welcome screen, Common arsenal, Motorpool, Vehicle cosmetics,
        Logistics, Pylons), then Report deck and System. A tab lists the
        versions the game knows and the one the mission runs; a row opens
        the editor for it.

        THE GAME HOLDS THE RUNNING VERSION. The arsenal's and motorpool's
        variants (plt_*, sqd_*, role_* and any named one) come down with the
        structure and open here; another version of anything else is a
        document only the database has - its row opens it as a Mongo doc.

    Parameters:
        None - reads GVAR(uiArgs): t (the tab)

    Returns:
        Nothing
*/

GVAR(uiLive) = true;
private _t = GVAR(uiArgs) getOrDefault ["t", "welcome"];
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _structure = GVAR(structure);
private _svc = "service" in ((missionNamespace getVariable [QGVAR(summary), createHashMap]) getOrDefault ["backend", ""]);

["Templates", "What a mission is given unless it names a version of its own - settings current<Name> says which"] call FUNC(uiTitle);
[[
    ["WELCOME SCREEN", "welcome"], ["COMMON ARSENAL", "arsenal"], ["MOTORPOOL", "motorpool"], ["VEHICLE COSMETICS", "cosmetics"],
    ["LOGISTICS", "logistics"], ["PYLONS", "pylons"], ["REPORT DECK", "deck"], ["SYSTEM", "system"]
], _t, {
    params ["_id"];
    ["templates", createHashMapFromArray [["t", _id]]] call FUNC(uiSub);
}] call FUNC(uiSubs);

private _fnc_current = {
    // the version the mission runs, "" for Default
    params ["_key"];
    private _c = GVAR(settings) getOrDefault [_key, ""];
    if !(_c isEqualType "") then {_c = ""};
    _c
};
private _btns = [];

switch (_t) do {
    case "welcome";
    case "cosmetics";
    case "logistics";
    case "pylons": {
        private _sec = _t;
        ([_sec] call FUNC(uiSectionLabel)) params ["_label", "_blurb"];
        private _cur = [format ["current%1", toUpper (_t select [0, 1]) + (_t select [1])]] call _fnc_current;
        private _fed = [_sec] call FUNC(fileFed);
        private _n = count ([_sec] call FUNC(structItems));
        private _rows = [[[[_cur, "Default"] select (_cur isEqualTo ""), _unit + "." + _sec + (["", "." + _cur] select (_cur isNotEqualTo "")), str _n, "the version the mission runs" + (["", "  -  from the config folder, read only in game"] select _fed)], "loaded"]];
        [PAC_IDC_LIST, ["Version", "Mongo doc", "Entries", ""], [0, 0.20, 0.50, 0.60], _rows, {
            params ["_data"];
            private _t = GVAR(uiArgs) getOrDefault ["t", "welcome"];
            if (_t isEqualTo "welcome") exitWith {["recordItem", createHashMapFromArray [["sec", "welcome"], ["id", "welcome"]]] call FUNC(uiGo)};
            ["record", createHashMapFromArray [["sec", _t]]] call FUNC(uiGo);
        }, PAC_UI_TOP, 0.12, _label] call FUNC(uiList);
        [_blurb + "  Other versions live in the database - open them under Mongo docs, or switch the mission to one with settings current" + toUpper (_t select [0, 1]) + (_t select [1]) + ".", PAC_UI_TOP + 0.13, 0.10, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);
    };

    case "arsenal": {
        private _cur = ["currentArsenal"] call _fnc_current;
        private _ars = _structure getOrDefault ["arsenal", createHashMap];
        private _variants = _ars getOrDefault ["variants", createHashMap];
        private _rows = [[[[_cur, "Default"] select (_cur isEqualTo ""), _unit + ".arsenal" + (["", "." + _cur] select (_cur isNotEqualTo "")), str (count (_ars getOrDefault ["lists", createHashMap])), "the version the mission runs"], ""]];
        private _ids = keys _variants;
        _ids sort true;
        {
            private _owned = (_x select [0, 4]) in ["plt_", "sqd_"] || {(_x select [0, 5]) isEqualTo "role_"};
            if (_owned) then {continue};
            _rows pushBack [[_x, _unit + ".arsenal." + _x, str (count (_variants get _x)), "a named version"], _x];
        } forEach _ids;
        [PAC_IDC_LIST, ["Version", "Mongo doc", "Lists", ""], [0, 0.20, 0.50, 0.60], _rows, {
            params ["_v"];
            ["arsenalLists", createHashMapFromArray [["v", _v]]] call FUNC(uiGo);
        }, PAC_UI_TOP, PAC_UI_BOTTOM - PAC_UI_TOP, "Common arsenal  -  a platoon's, a squad's and a role's own arsenals open from their pages under ORBAT"] call FUNC(uiList);
        _btns pushBack ["NEW VERSION", {["arsenalLists", createHashMapFromArray [["v", "?"]]] call FUNC(uiGo)}];
    };

    case "motorpool": {
        private _cur = ["currentMotorpool"] call _fnc_current;
        private _variants = _structure getOrDefault ["motorpoolVariants", createHashMap];
        private _rows = [[[[_cur, "Default"] select (_cur isEqualTo ""), _unit + ".motorpool" + (["", "." + _cur] select (_cur isNotEqualTo "")), str (count (["motorpool"] call FUNC(structItems))), "the version the mission runs"], ""]];
        private _ids = keys _variants;
        _ids sort true;
        {
            if ((_x select [0, 4]) in ["plt_", "sqd_"]) then {continue};
            _rows pushBack [[_x, _unit + ".motorpool." + _x, str (count (_variants get _x)), "a named version"], _x];
        } forEach _ids;
        [PAC_IDC_LIST, ["Version", "Mongo doc", "Headings", ""], [0, 0.20, 0.50, 0.60], _rows, {
            params ["_v"];
            ["record", createHashMapFromArray [["sec", "motorpool"], ["v", _v]]] call FUNC(uiGo);
        }, PAC_UI_TOP, PAC_UI_BOTTOM - PAC_UI_TOP, "Motorpool  -  a platoon's and a squad's own open from their pages under ORBAT"] call FUNC(uiList);
    };

    case "deck": {
        private _tpl = _structure getOrDefault ["templates", createHashMap];
        private _ids = keys _tpl;
        _ids sort true;
        private _rows = _ids apply {
            private _r = _tpl get _x;
            private _opts = createHashMap;
            {if (_x isEqualType [] && {count _x >= 2}) then {_opts set [_x # 0, _x # 1]}} forEach (_r getOrDefault ["options", []]);
            [[_x, _r getOrDefault ["title", ""], _opts getOrDefault ["kind", "root"], ["", "FLASH"] select ((_opts getOrDefault ["priority", "normal"]) isEqualTo "high"), str (count (_r getOrDefault ["lines", []]))], _x]
        };
        if (_rows isEqualTo []) then {_rows = [[["No templates", "", "", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
        [PAC_IDC_LIST, ["Id", "Title", "Kind", "", "Lines"], [0, 0.18, 0.60, 0.72, 0.84], _rows, {
            params ["_id"];
            if (_id isEqualTo "") exitWith {};
            ["deckTemplate", createHashMapFromArray [["id", _id]]] call FUNC(uiGo);
        }, PAC_UI_TOP, PAC_UI_BOTTOM - PAC_UI_TOP, format ["Report deck  %1  -  %2.templates", count _tpl, _unit]] call FUNC(uiList);
        if !(["templates"] call FUNC(fileFed)) then {
            _btns pushBack ["NEW TEMPLATE", {["deckTemplate", createHashMapFromArray [["id", ""]]] call FUNC(uiGo)}];
        };
        // SIMPLE OR REAL WORLD TEMPLATES (user, 2026-11-09): the unit's view
        // of every card in TAC//MSG - the short form or the doctrinal one,
        // REAL WORLD unless set. One press flips it, at once
        // (FUNC(adminSetting) -> FUNC(templateFormPublish)).
        private _form = GVAR(settings) getOrDefault [TEMPLATE_FORM_KEY, TEMPLATE_FORM_REAL];
        private _simple = _form isEqualTo TEMPLATE_FORM_SIMPLE;
        _btns pushBack [["TEMPLATES: REAL WORLD", "TEMPLATES: SIMPLE"] select _simple, {
            private _now = GVAR(settings) getOrDefault [TEMPLATE_FORM_KEY, TEMPLATE_FORM_REAL];
            private _next = [TEMPLATE_FORM_SIMPLE, TEMPLATE_FORM_REAL] select (_now isEqualTo TEMPLATE_FORM_SIMPLE);
            GVAR(settings) set [TEMPLATE_FORM_KEY, _next];
            [player, TEMPLATE_FORM_KEY, _next] remoteExec [QFUNC(adminSetting), 2];
            ["templates", createHashMapFromArray [["t", "deck"]]] call FUNC(uiSub);
        }];
    };

    case "system": {
        private _kinds = GVAR(uiData) getOrDefault ["ticketKinds", createHashMap];
        private _rows = [
            [["Operation order sections", format ["%1 section(s)", count ([] call FUNC(opordDef))], "what an order holds - edited on the website, read here"], "opordDef"],
            [["PAC request kinds", [format ["%1 kind(s)", count _kinds], "database only"] select (!_svc), "what a member can raise"], ["", "ticketKinds"] select _svc],
            [["Colour schemes", format ["%1 of the unit's", count (["schemes"] call FUNC(structItems))], "ground, ink and accent for the tacpad"], "schemes"]
        ];
        [PAC_IDC_LIST, ["", "", ""], [0, 0.30, 0.50], _rows, {
            params ["_what"];
            switch (_what) do {
                case "opordDef": {["opordDef"] call FUNC(uiGo)};
                case "ticketKinds": {["ticketKinds"] call FUNC(uiGo)};
                case "schemes": {["record", createHashMapFromArray [["sec", "schemes"]]] call FUNC(uiGo)};
            };
        }, PAC_UI_TOP, 0.20, "System"] call FUNC(uiList);
    };
};
[_btns] call FUNC(uiButtons);
