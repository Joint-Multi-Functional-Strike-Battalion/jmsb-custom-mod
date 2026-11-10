#include "script_component.hpp"
/*
    File: fnc_pgDeckTemplate.sqf
    Author: YonV
    Description: One report-deck template - the website's
        ?page=template_edit: the card (id, title, short), its behaviour
        (kind, priority, subject, anchor, transitions, sender, replies,
        danger close),
        and its lines as a table. A line opens on its own page; the fields
        of a line on theirs - the shape is three deep and each level gets a
        page rather than one screen that lies about the depth.

        STORED AS THE TACPAD REGISTERS IT: {id, title, short, lines:
        [[key, label, [[prefix, hint, type, opts], ...]], ...], options:
        [[k, v], ...]} - the same document the website writes.

    Parameters:
        None - reads GVAR(uiArgs): id ("" = new)

    Returns:
        Nothing
*/

private _id = GVAR(uiArgs) getOrDefault ["id", ""];
private _new = _id isEqualTo "";
private _tpl = GVAR(structure) getOrDefault ["templates", createHashMap];
private _rec = _tpl getOrDefault [_id, createHashMap];
if !(_rec isEqualType createHashMap) then {_rec = createHashMap};
private _opts = createHashMap;
{if (_x isEqualType [] && {count _x >= 2}) then {_opts set [_x # 0, _x # 1]}} forEach (_rec getOrDefault ["options", []]);
private _unit = GVAR(settings) getOrDefault ["unitId", ""];

[[_rec getOrDefault ["title", _id], "New template"] select _new, format ["Templates  -  Report deck  -  %1.templates", _unit]] call FUNC(uiTitle);

private _reply = _opts getOrDefault ["replyableWith", []];
if (_reply isEqualType []) then {_reply = _reply joinString ", "};
private _colW = (PAC_UI_W - 0.016) / 2;
[[
    ["id", "Id  (lower case, no spaces)", ["r", "t"] select _new, _id],
    ["title", "Title", "t", _rec getOrDefault ["title", ""]],
    ["short", "Short", "t", _rec getOrDefault ["short", ""]],
    ["kind", "Kind", "c", _opts getOrDefault ["kind", "root"], [["root", "root - opens a thread"], ["reply", "reply - answers one"], ["both", "both"]]],
    ["priority", "Priority", "c", _opts getOrDefault ["priority", "normal"], [["normal", "normal"], ["high", "high - FLASH"]]],
    ["subject", "Subject  e.g. TASKING {Unit.A}", "t", _opts getOrDefault ["subject", ""]],
    ["anchor", "Anchor  (a produced key)", "t", _opts getOrDefault ["anchor", ""]],
    ["transitionsTo", "Transitions to", "t", _opts getOrDefault ["transitionsTo", ""]],
    ["senderMustBe", "Sender must be", "t", _opts getOrDefault ["senderMustBe", ""]],
    ["replyableWith", "Repliable with  (ids, comma separated)", "t", _reply],
    ["dangerClose", "Danger close  (m, 0 = none)", "n", _opts getOrDefault ["dangerClose", DECK_DANGER_CLOSE_NONE]]
], PAC_UI_TOP, PAC_UI_X, _colW] call FUNC(uiForm);

private _lines = _rec getOrDefault ["lines", []];
if !(_lines isEqualType []) then {_lines = []};
private _rows = [];
{
    private _l = _x;
    if !(_l isEqualType []) then {continue};
    private _fields = _l param [2, []];
    if !(_fields isEqualType []) then {_fields = []};
    private _fieldText = [];
    {
        if (_x isEqualType []) then {
            _fieldText pushBack format ["%1.%2 %3", _l param [0, ""], toString [65 + (_forEachIndex min 25)], _x param [2, "text"]];
        };
    } forEach _fields;
    _rows pushBack [[_l param [0, ""], _l param [1, ""], _fieldText joinString "  "], str _forEachIndex];
} forEach _lines;
if (_rows isEqualTo []) then {_rows = [[["No lines yet", "", ""], "", [0.545, 0.592, 0.639, 1]]]};
[PAC_IDC_LIST, ["Key", "Label", "Fields"], [0, 0.22, 0.46], _rows, {
    params ["_i"];
    if (_i isEqualTo "") exitWith {};
    ["deckLine", createHashMapFromArray [["id", GVAR(uiArgs) getOrDefault ["id", ""]], ["i", parseNumber _i]]] call FUNC(uiGo);
}, PAC_UI_TOP, PAC_UI_BOTTOM - PAC_UI_TOP, format ["Lines  %1", count _lines], PAC_UI_X + _colW + 0.016, _colW] call FUNC(uiList);

private _btns = [
    ["SAVE", {
        private _f = [] call FUNC(uiFormRead);
        private _id = toLower (trim (_f getOrDefault ["id", ""]));
        if (_id isEqualTo "" || {(toArray _id) findIf {!(_x isEqualTo 95 || {_x >= 48 && _x <= 57} || {_x >= 97 && _x <= 122})} >= 0}) exitWith {["An id is lower case letters, digits and underscore.", true] call FUNC(uiHint)};
        private _was = (GVAR(structure) getOrDefault ["templates", createHashMap]) getOrDefault [_id, createHashMap];
        private _opts = [["kind", _f getOrDefault ["kind", "root"]], ["priority", _f getOrDefault ["priority", "normal"]]];
        {
            private _v = trim (_f getOrDefault [_x, ""]);
            if (_v isNotEqualTo "") then {_opts pushBack [_x, _v]};
        } forEach ["subject", "anchor", "transitionsTo", "senderMustBe"];
        private _reply = ((_f getOrDefault ["replyableWith", ""]) splitString ",") apply {trim _x};
        _reply = _reply select {_x isNotEqualTo ""};
        if (_reply isNotEqualTo []) then {_opts pushBack ["replyableWith", _reply]};
        // A card's own danger-close threshold, metres (user, 2026-11-01, D8).
        private _dangerClose = _f getOrDefault ["dangerClose", DECK_DANGER_CLOSE_NONE];
        if !(_dangerClose isEqualType 0) then {_dangerClose = DECK_DANGER_CLOSE_NONE};
        if (_dangerClose > DECK_DANGER_CLOSE_NONE) then {_opts pushBack ["dangerClose", _dangerClose]};
        private _rec = createHashMapFromArray [
            ["id", _id], ["title", trim (_f getOrDefault ["title", ""])], ["short", trim (_f getOrDefault ["short", ""])],
            ["lines", _was getOrDefault ["lines", []]], ["options", _opts]
        ];
        [player, "set", _id, _rec] remoteExec [QFUNC(adminTemplate), 2];
        if ((GVAR(uiArgs) getOrDefault ["id", ""]) isEqualTo "") then {
            GVAR(uiArgs) set ["id", _id];
            GVAR(uiHistory) set [(count GVAR(uiHistory)) - 1, ["deckTemplate", GVAR(uiArgs)]];
        };
        ["Saved - the deck re-registers when the server answers.", false] call FUNC(uiHint);
    }]
];
if (!_new) then {
    _btns pushBack ["ADD LINE", {["deckLine", createHashMapFromArray [["id", GVAR(uiArgs) getOrDefault ["id", ""]], ["i", -1]]] call FUNC(uiGo)}];
    _btns pushBack ["DELETE", {
        [format ["Delete the template %1?", GVAR(uiArgs) getOrDefault ["id", ""]], {
            [player, "remove", GVAR(uiArgs) getOrDefault ["id", ""], createHashMap] remoteExec [QFUNC(adminTemplate), 2];
            ["templates", createHashMapFromArray [["t", "deck"]]] call FUNC(uiGo);
        }] call FUNC(uiConfirm);
    }, true];
};
[_btns] call FUNC(uiButtons);
