#include "script_component.hpp"
/*
 * Author: JMSB
 * The reader's thread list (handoff 1a, pane 2): the filter box and NEW, the
 * ALL / OPEN / MINE / ACK tabs, and one row per thread, newest first.
 *
 * THE FILTER IS A REAL BOX. Typing does not redraw - a redraw throws the edit
 * away mid-word - so the text is kept on every key and applied on Enter, and
 * the new box comes back with the caret in it.
 *
 * The tabs are filters over the same rows and keep the meanings they had:
 * OPEN is not CLOSED or ABORTED, MINE is what this player has claimed, ACK is
 * what is still unread - the index carries no per-player acknowledgement, and
 * unread is the nearest thing it has to "waiting on you".
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: Left edge of the list <NUMBER>
 * 2: List width <NUMBER>
 * 3: List height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_root, _lx, _listW, _h] call jmfsb_tacpad_fnc_readerList
 *
 * Public: No
 */

params [["_root", controlNull, [controlNull]], ["_lx", 0, [0]], ["_listW", 0, [0]], ["_h", 0, [0]]];

if (isNull _root) exitWith {};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _surface = ["surface"] call FUNC(theme);
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _side = READER_INSET * _pad;
private _ruleH = RULE_THICK * pixelH;

// ------------------------------------------------------------ filter + NEW --
private _y = READER_INSET * _padY;
private _btnH = ([READER_SUBJECT_SIZE] call FUNC(textH)) + 3 * _padY;
private _newW = _listW * 0.24;
private _boxW = _listW - _newW - 2 * _side - _pad * 2;

[_root, [_lx + _side, _y, _boxW, _btnH], _surface] call FUNC(drawFill);
[_root, [_lx + _side, _y, _boxW, _btnH], _dim, RULE_THIN] call FUNC(drawFrame);

private _hint = controlNull;
if (GVAR(readerFilter) isEqualTo "") then {
    _hint = [_root, [_lx + _side + _pad * 2, _y, _boxW - _pad * 4, _btnH], "Filter traffic - type, grid, callsign", _dim, READER_PREVIEW_SIZE] call FUNC(drawText);
};

private _newX = _lx + _listW - _side - _newW;
[_root, [_newX, _y, _newW, _btnH], _accent] call FUNC(drawFill);
[_root, [_newX, _y, _newW, _btnH], "NEW", _ground, READER_BTN_SIZE, true, "center"] call FUNC(drawText);
// NEW OPENS THE RIGHT PANE, not a window - the traffic stays on screen.
[_root, [_newX, _y, _newW, _btnH], {
    ["", "", false] call FUNC(composeOpen);
}] call FUNC(drawHit);

// The box itself, last in its rectangle so it sits over its own frame and hint.
private _old = (ctrlParent _root) displayCtrl IDC_RD_FILTER;
if (!isNull _old) then {ctrlDelete _old};
private _box = (ctrlParent _root) ctrlCreate [QGVAR(input), IDC_RD_FILTER, _root];
_box ctrlSetPosition [_lx + _side + _pad, _y, _boxW - _pad * 2, _btnH];
_box ctrlSetTextColor _ink;
_box ctrlSetFontHeight (([READER_PREVIEW_SIZE] call FUNC(textH)) / 1.25);
_box ctrlSetText GVAR(readerFilter);
_box ctrlCommit 0;
_box setVariable [QGVAR(hint), _hint];
_box ctrlAddEventHandler ["KeyDown", {
    params ["_ctrl"];
    private _hint = _ctrl getVariable [QGVAR(hint), controlNull];
    if (!isNull _hint) then {_hint ctrlShow false};
    false
}];
_box ctrlAddEventHandler ["KeyUp", {
    params ["_ctrl", "_key"];
    GVAR(readerFilter) = trim (ctrlText _ctrl);
    if (_key in [READER_KEY_ENTER, READER_KEY_NUM_ENTER]) then {
        {
            [] call FUNC(readerDraw);
            private _d = uiNamespace getVariable [QGVAR(reader), displayNull];
            if (!isNull _d) then {ctrlSetFocus (_d displayCtrl IDC_RD_FILTER)};
        } call CBA_fnc_execNextFrame;
    };
    false
}];

_y = _y + _btnH + READER_INSET * _padY;
[_root, [_lx, _y, _listW, _ruleH], _dim] call FUNC(drawFill);
_y = _y + _ruleH;

// ------------------------------------------------------------------- rows ---
private _index = EGVAR(messaging,index);
private _squadBox = format ["G:%1", groupId (group player)];

private _rows = _index select {
    _x isEqualType createHashMap
    && {if (GVAR(readerNet) == "ALL") then {
            // ALL hides what is muted - the same rule as the rail.
            ([_x getOrDefault ["boxId", ""], _x getOrDefault ["threadId", ""]] call EFUNC(messaging,netLevel)) isEqualTo 0
        } else {
            (_x getOrDefault ["boxId", ""]) in [format ["B:%1", GVAR(readerNet)], format ["G:%1", GVAR(readerNet)]]
            || {GVAR(readerNet) == "SQUAD" && {(_x getOrDefault ["boxId", ""]) == _squadBox}}
        }}
};

// THE FILTER: subject, report type and mailbox, which between them carry the
// type, the grid and the call sign the hint promises.
if (GVAR(readerFilter) isNotEqualTo "") then {
    private _needle = toLower GVAR(readerFilter);
    _rows = _rows select {
        private _t = [_x getOrDefault ["templateId", ""]] call EFUNC(messaging,template);
        private _hay = toLower format [
            "%1 %2 %3 %4",
            _x getOrDefault ["subject", ""], _t getOrDefault ["short", ""],
            _t getOrDefault ["title", ""], _x getOrDefault ["boxId", ""]
        ];
        (_hay find _needle) >= 0
    };
};

// ONE ROW PER THREAD. The index holds a row per thread PER MAILBOX; keep the
// one with the most unread on it.
private _byThread = createHashMap;
{
    private _id = _x getOrDefault ["threadId", ""];
    private _have = _byThread getOrDefault [_id, createHashMap];
    if (_have isEqualTo createHashMap
        || {(_x getOrDefault ["unread", 0]) > (_have getOrDefault ["unread", 0])}) then {
        _byThread set [_id, _x];
    };
} forEach _rows;
_rows = values _byThread;

private _uid = getPlayerUID player;
private _isOpen = {!((_this getOrDefault ["status", ""]) in ["CLOSED", "ABORTED"])};
private _isMine = {(_this getOrDefault ["claimedBy", ""]) == _uid};
private _isAck = {(_this getOrDefault ["unread", 0]) > 0};

private _tabbed = switch (GVAR(readerTab)) do {
    case "open": {_rows select {_x call _isOpen}};
    case "mine": {_rows select {_x call _isMine}};
    case "ack": {_rows select {_x call _isAck}};
    default {_rows};
};

// ------------------------------------------------------------------- tabs ---
private _tabH = _rowH * 1.4;
private _tabW = (_listW - _side) / 4;

// The rule under the strip first, so the active tab's underline lands ON it, as
// the design has it, rather than being painted over.
[_root, [_lx, _y + _tabH, _listW, _ruleH], _dim] call FUNC(drawFill);

{
    _x params ["_key", "_label", "_n"];
    private _on = _key == GVAR(readerTab);
    private _tx = _lx + _side + _forEachIndex * _tabW;

    [_root, [_tx, _y, _tabW, _tabH], format ["%1 %2", _label, _n], [_muted, _accent] select _on, READER_K_SIZE, true, "left", true] call FUNC(drawText);
    if (_on) then {
        [_root, [_tx, _y + _tabH, _tabW - _side, _ruleH], _accent] call FUNC(drawFill);
    };

    private _hit = [_root, [_tx, _y, _tabW, _tabH], {
        params ["_ctrl"];
        GVAR(readerTab) = _ctrl getVariable [QGVAR(tab), "all"];
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(tab), _key];
} forEach [
    ["all", "ALL", count _rows],
    ["open", "OPEN", {_x call _isOpen} count _rows],
    ["mine", "MINE", {_x call _isMine} count _rows],
    ["ack", "ACK", {_x call _isAck} count _rows]
];

_y = _y + _tabH + _ruleH;

// Newest first.
private _keyed = [];
{_keyed pushBack [_x getOrDefault ["lastActivity", 0], _forEachIndex]} forEach _tabbed;
_keyed sort false;
_tabbed = _keyed apply {_tabbed # (_x # 1)};

if (_tabbed isEqualTo []) exitWith {
    [_root, [_lx + _side, _y + _padY * 2, _listW - 2 * _side, _rowH], ["NO TRAFFIC", "NOTHING MATCHES"] select (GVAR(readerFilter) isNotEqualTo ""), _dim, READER_K_SIZE, true, "left", true] call FUNC(drawText);
};

private _entryH = _rowH * 3.5 + _padY * (2 * READER_INSET + 2);
private _room = floor ((_h - _y) / _entryH) max 1;
private _more = (count _tabbed) - _room;
if (_more > 0) then {
    _tabbed resize (_room - 1 max 1);
};

{
    [_root, _x, [_lx, _y + _forEachIndex * _entryH, _listW, _entryH]] call FUNC(readerRow);
} forEach _tabbed;

if (_more > 0) then {
    [
        _root, [_lx + _side, _y + (count _tabbed) * _entryH + _padY, _listW - 2 * _side, _rowH],
        format ["%1 MORE - NARROW WITH THE FILTER OR A TAB", (count _keyed) - count _tabbed], _dim, READER_K_SIZE, true, "left", true
    ] call FUNC(drawText);
};
