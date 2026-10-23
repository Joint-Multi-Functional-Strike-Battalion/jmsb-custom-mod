#include "script_component.hpp"
/*
 * Author: JMSB
 * The composer at the foot of an opened thread (handoff 1a): QUICK REPLY and
 * its six tiles, the + TEMPLATE / + GRID / + MARKER / CALL row, and the reply
 * box with SEND.
 *
 * CALL IS A REPLY TOO (user, 2026-10-21: "add to the tac/msg app a call as a
 * reply button"): it rings the thread's people who are in game - its authors
 * and participants (FUNC(readerCallUnits)) - the way the squad roster's CALL
 * does (jmfsb_tacpad_apps_fnc_radioDial: a new call, or into the live one you
 * own). Drawn only with game voice; dim when nobody on the thread is in game.
 *
 * THE TILES ARE THE REGISTRY'S ONE-TAP REPLIES FIRST - every reply template
 * with no fields (ROGER, WILCO, ON TASK), the same set FUNC(composeTiles) puts
 * at the head of the reply picker. A tile the thread's state will not take is
 * drawn dim and cannot be pressed, so the row shows what exists without ever
 * offering what the server refuses. The player's own Quick replies setting
 * fills the slots left; the sixth is VOICE MSG, present and disabled until the
 * voice-message work lands (docs/PLAN_MESSAGING_UI.md, phase 5).
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: Thread <HASHMAP>
 * 2: Reply template ids the thread will take now <ARRAY>
 * 3: [x, width, bottom] of the composer <ARRAY>
 * 4: Measure only - return the height and draw nothing <BOOL> (optional, default false)
 * 5: Uids on the thread, for CALL <ARRAY of STRINGs> (optional, default [])
 *
 * Return Value:
 * Height of the composer <NUMBER>
 *
 * Example:
 * private _h = [_root, _thread, _legal, [_bx, _bw, _h], true] call jmfsb_tacpad_fnc_readerQuick
 *
 * Public: No
 */

params [
    ["_root", controlNull, [controlNull]],
    ["_thread", createHashMap, [createHashMap]],
    ["_legal", [], [[]]],
    ["_at", [0, 0, 0], [[]], 3],
    ["_measure", false, [false]],
    ["_callUids", [], [[]]]
];

_at params ["_bx", "_bw", "_bottom"];

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _btnH = ([READER_BTN_SIZE] call FUNC(textH)) + 3 * _padY;
private _tileH = _btnH * READER_TILE_H;
private _labelH = _rowH;
private _gap = _padY * 2;

private _height = READER_INSET * _padY + _labelH + _tileH + _gap + _btnH + _gap + _btnH + READER_INSET * _padY;
if (_measure || {isNull _root}) exitWith {_height};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _surface = ["surface"] call FUNC(theme);
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _threadId = _thread getOrDefault ["id", ""];
private _closed = _legal isEqualTo [];
private _free = "freetext" in _legal;
private _freeKey = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];

private _y = _bottom - _height;
[_root, [_bx, _y, _bw, RULE_THICK * pixelH], _dim] call FUNC(drawFill);
_y = _y + READER_INSET * _padY;

[_root, [_bx, _y, _bw * 0.4, _labelH], "QUICK REPLY", _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);
_y = _y + _labelH;

// ------------------------------------------------------------- the tiles ---
// [template id or "", label, pressable]. A template only a leader may send is
// not offered to anyone else - the picker's rule.
private _isLeader = (player getVariable ["isLeader", false]) isEqualTo true;
private _tiles = [];
{
    private _t = [_x] call EFUNC(messaging,template);
    if ((_t getOrDefault ["order", []]) isNotEqualTo []) then {continue};
    if ((_t getOrDefault ["senderMustBe", "any"]) isEqualTo "leader" && !_isLeader) then {continue};
    _tiles pushBack [_x, toUpper (_t getOrDefault ["short", _x]), _x in _legal];
} forEach (["reply"] call EFUNC(messaging,templateIds));

// The player's phrases into what is left. A template id already on the row is
// not repeated; one the thread will not take is not sent as words either.
private _known = missionNamespace getVariable [QEGVAR(messaging,templateIds), []];
{
    private _entry = trim _x;
    private _id = toLower _entry;
    if (_entry isEqualTo "" || {(_tiles findIf {(_x # 0) isEqualTo _id}) >= 0}) then {continue};
    if (_id in _known) then {
        if (_id in _legal) then {_tiles pushBack [_id, toUpper (([_id] call EFUNC(messaging,template)) getOrDefault ["short", _entry]), true]};
        continue;
    };
    _tiles pushBack ["", toUpper _entry, _free];
} forEach (GVAR(quickReplies) splitString ",");

if (count _tiles > READER_TILES - 1) then {_tiles resize (READER_TILES - 1)};

private _tileW = (_bw - _pad * 2 * (READER_TILES - 1)) / READER_TILES;
{
    _x params ["_id", "_label", "_live"];
    private _tx = _bx + _forEachIndex * (_tileW + _pad * 2);

    [_root, [_tx, _y, _tileW, _tileH], [_dim, _ink] select _live, RULE_THICK] call FUNC(drawFrame);
    [_root, [_tx + _pad * 3, _y, _tileW - _pad * 4, _tileH], _label, [_dim, _ink] select _live, READER_TILE_SIZE, true] call FUNC(drawText);

    if (_live) then {
        private _hit = [_root, [_tx, _y, _tileW, _tileH], {
            params ["_ctrl"];
            private _id = _ctrl getVariable [QGVAR(quickId), ""];
            private _key = _ctrl getVariable [QGVAR(quickKey), ""];

            // A phrase is a free-text reply carrying the words on the tile; a
            // template id is the template, so the thread's state still moves.
            if (_id isEqualTo "") then {
                ["freetext", [[_key, _ctrl getVariable [QGVAR(quickText), ""]]], [], GVAR(readerThread)] call EFUNC(messaging,submit);
            } else {
                [_id, [], [], GVAR(readerThread)] call EFUNC(messaging,submit);
            };
        }] call FUNC(drawHit);
        _hit setVariable [QGVAR(quickId), _id];
        _hit setVariable [QGVAR(quickText), _label];
        _hit setVariable [QGVAR(quickKey), _freeKey];
    };
} forEach _tiles;

// VOICE MSG: the design's inverted sixth tile, with the accent square that will
// be the record light. Disabled - no hit - until the voice work is decided.
private _vx = _bx + _bw - _tileW;
private _sq = _tileH * 0.22;
[_root, [_vx, _y, _tileW, _tileH], _dim] call FUNC(drawFill);
[_root, [_vx + _pad * 3, _y, _tileW * 0.7, _tileH * 0.6], "VOICE MSG", _ground, READER_TILE_SIZE, true] call FUNC(drawText);
[_root, [_vx + _pad * 3, _y + _tileH * 0.5, _tileW * 0.7, _tileH * 0.45], "COMING", _ground, READER_K_SIZE, true, "left", true] call FUNC(drawText);
[_root, [_vx + _tileW - _pad * 3 - _sq / pixelH * pixelW, _y + (_tileH - _sq) * 0.5, _sq / pixelH * pixelW, _sq], _accent] call FUNC(drawFill);

_y = _y + _tileH + _gap;

// ------------------------------------------------------------ action row ---
private _actW = _bw * 0.15;
private _fnc_action = {
    params ["_ax", "_label", "_live", "_on", "_code"];
    private _c = [[_dim, _ink] select _live, _accent] select _on;
    [_root, [_ax, _y, _actW, _btnH], _c, [RULE_THIN, RULE_THICK] select _on] call FUNC(drawFrame);
    [_root, [_ax + _pad * 2, _y, _actW - _pad * 4, _btnH], _label, _c, READER_BTN_SIZE, true] call FUNC(drawText);
    if (_live) then {[_root, [_ax, _y, _actW, _btnH], _code] call FUNC(drawHit)};
};

// + TEMPLATE turns this pane into the composer, on this thread.
[_bx, "+ TEMPLATE", !_closed, false, {
    [GVAR(readerThread), "", true] call FUNC(composeOpen);
}] call _fnc_action;

// + GRID: your own grid, into the box - your GPS grid (jmfsb_ew_fnc_gpsHere,
// when EW is loaded): the false one when spoofed, nothing and a word on the
// rail when it is denied.
private _gridX = _bx + _actW + _pad * 2;
[_gridX, "+ GRID", _free, false, {
    private _d = uiNamespace getVariable [QGVAR(reader), displayNull];
    if (isNull _d) exitWith {};
    private _ctrl = _d displayCtrl IDC_RD_INPUT;
    private _at = if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[true] call EFUNC(ew,gpsHere)};
    if (_at isEqualTo []) exitWith {};
    _ctrl ctrlSetText trim format ["%1 %2", trim (ctrlText _ctrl), mapGridPosition _at];
    ctrlSetFocus _ctrl;
}] call _fnc_action;

// + MARKER: a marker's name and grid, sent in one press, off a list that opens
// upwards over the spine.
private _markerX = _gridX + _actW + _pad * 2;
private _markerOpen = GVAR(readerMarkers) && _free;
[_markerX, "+ MARKER", _free, _markerOpen, {
    GVAR(readerMarkers) = !GVAR(readerMarkers);
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call _fnc_action;

// CALL: ring the thread's people in game. Only with game voice and the
// tablet apps' dialler; dim, with no press, when none of them is in game.
private _callX = _markerX + _actW + _pad * 2;
if (!isNil QEFUNC(tacpad_apps,radioDial) && {!isNil QEFUNC(voice,call)}) then {
    private _reachable = ([_callUids] call FUNC(readerCallUnits)) isNotEqualTo [];
    [_callX, "CALL", _reachable, false, compile format [
        "private _units = [%1] call %2; if (_units isEqualTo []) exitWith {['READER', 'CALL - nobody on this thread is in game', 'normal'] call %3}; [_units] call %4",
        str _callUids, QFUNC(readerCallUnits), QEFUNC(messaging,notify), QEFUNC(tacpad_apps,radioDial)
    ]] call _fnc_action;
};

[
    _root, [_callX + _actW + _pad * 2, _y, _bx + _bw - _callX - _actW - _pad * 2, _btnH],
    format ["REPLY IN THREAD %1", _threadId], _muted, READER_K_SIZE, true, "right", true
] call FUNC(drawText);

if (_markerOpen) then {
    [_root, [_markerX, _y, _bw * 0.5, _rowH * 0.95]] call FUNC(readerMarkers);
};

_y = _y + _btnH + _gap;

// ------------------------------------------------------------- input row ---
private _sendW = _bw * 0.14;
private _boxW = _bw - _sendW - _pad * 2;
[_root, [_bx, _y, _boxW, _btnH], _surface] call FUNC(drawFill);
[_root, [_bx, _y, _boxW, _btnH], _dim, RULE_THIN] call FUNC(drawFrame);

// Made into the group, last in its rectangle - see FUNC(readerInput).
[_root, [_bx + _pad * 2, _y, _boxW - _pad * 4, _btnH], _ink, !_closed] call FUNC(readerInput);

private _sendX = _bx + _bw - _sendW;
[_root, [_sendX, _y, _sendW, _btnH], [_dim, _accent] select _free] call FUNC(drawFill);
[_root, [_sendX, _y, _sendW, _btnH], "SEND", _ground, READER_BTN_SIZE, true, "center"] call FUNC(drawText);

if (_free) then {
    private _send = [_root, [_sendX, _y, _sendW, _btnH], {
        params ["_ctrl"];
        private _d = uiNamespace getVariable [QGVAR(reader), displayNull];
        if (isNull _d) exitWith {};

        private _box = _d displayCtrl IDC_RD_INPUT;
        private _text = ctrlText _box;
        if (trim _text == "") exitWith {};

        _box ctrlSetText "";
        ["freetext", [[_ctrl getVariable [QGVAR(quickKey), ""], _text]], [], GVAR(readerThread)] call EFUNC(messaging,submit);
    }] call FUNC(drawHit);
    _send setVariable [QGVAR(quickKey), _freeKey];
};

_height
