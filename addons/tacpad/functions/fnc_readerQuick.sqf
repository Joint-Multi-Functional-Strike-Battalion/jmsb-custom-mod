#include "script_component.hpp"
/*
 * Author: YonV
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
 * THE TILES ARE FUNC(readerQuickTiles): what the asset just asked (a
 * `prompt` card's answers), a support card's own row to its sender (doc 6.2,
 * user 2026-11-01), or the registry's one-tap replies (ROGER, WILCO, ON TASK)
 * and the player's own Quick replies setting - after SEND SITREP on a TIC
 * thread, for its sender and his squad leader (user, 2026-11-02), under
 * CONTACT OVER? SEND SITREP in the accent once the sender's contact has gone
 * quiet (FUNC(contactCheck)). Only what the server would
 * take is on the row (tablet review 2026-11-01, 3.1). A support row may run
 * onto a second row of tiles (READER_TILE_ROWS); the first row's sixth slot is
 * VOICE MSG, present and disabled until the voice-message work lands
 * (docs/PLAN_MESSAGING_UI.md, phase 5), and BACK while the ADJUST distance
 * pick is open.
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: Thread <HASHMAP>
 * 2: Reply template ids the thread will take now <ARRAY>
 * 3: [x, width, bottom] of the composer <ARRAY>
 * 4: Measure only - return the height and draw nothing <BOOL> (optional, default false)
 * 5: Uids on the thread, for CALL <ARRAY of STRINGs> (optional, default [])
 * 6: The thread's messages, root first <ARRAY> (optional, default [])
 *
 * Return Value:
 * Height of the composer <NUMBER>
 *
 * Example:
 * private _h = [_root, _thread, _legal, [_bx, _bw, _h], true, [], _messages] call jmfsb_tacpad_fnc_readerQuick
 *
 * Public: No
 */

params [
    ["_root", controlNull, [controlNull]],
    ["_thread", createHashMap, [createHashMap]],
    ["_legal", [], [[]]],
    ["_at", [0, 0, 0], [[]], 3],
    ["_measure", false, [false]],
    ["_callUids", [], [[]]],
    ["_messages", [], [[]]]
];

_at params ["_bx", "_bw", "_bottom"];

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _btnH = ([READER_BTN_SIZE] call FUNC(textH)) + 3 * _padY;
private _tileH = _btnH * READER_TILE_H;
private _labelH = _rowH;
private _gap = _padY * 2;

// The tiles first: how many rows of them is the composer's height.
([_thread, _messages, _legal] call FUNC(readerQuickTiles)) params ["_kicker", "_tiles", "_picking", ["_alert", false]];
private _firstRow = READER_TILES - ([1, 0] select _picking);
private _tileRows = [1, READER_TILE_ROWS] select (count _tiles > _firstRow);
private _tilesH = _tileRows * _tileH + (_tileRows - 1) * _gap;

private _height = READER_INSET * _padY + _labelH + _tilesH + _gap + _btnH + _gap + _btnH + READER_INSET * _padY;
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

// CONTACT OVER? SEND SITREP (user, 2026-11-02) is the row's label in the
// accent, across the pane - the sender's TIC has gone quiet.
[_root, [_bx, _y, [_bw * 0.4, _bw] select _alert, _labelH], _kicker, [_muted, _accent] select _alert, READER_K_SIZE, true, "left", true] call FUNC(drawText);
_y = _y + _labelH;

// ------------------------------------------------------------- the tiles ---
// ONLY WHAT THE THREAD TAKES IS DRAWN (tablet review 2026-11-01, 3.1) - see
// FUNC(readerQuickTiles). A reply it would refuse is not on the row at all; it
// was drawn dim, which still read as an offer. A word is a word and a distance
// a value: neither is tracked.
private _tileW = (_bw - _pad * 2 * (READER_TILES - 1)) / READER_TILES;
{
    _x params ["_word", "_act", "_id", "_payload"];
    private _second = _forEachIndex >= _firstRow;
    private _col = [_forEachIndex, _forEachIndex - _firstRow] select _second;
    private _tx = _bx + _col * (_tileW + _pad * 2);
    private _ty = _y + ([0, _tileH + _gap] select _second);

    [_root, [_tx, _ty, _tileW, _tileH], _ink, RULE_THICK] call FUNC(drawFrame);
    [_root, [_tx + _pad * 3, _ty, _tileW - _pad * 4, _tileH], _word, _ink, READER_TILE_SIZE, true] call FUNC(drawText);

    private _hit = [_root, [_tx, _ty, _tileW, _tileH], {
        params ["_ctrl"];
        private _act = _ctrl getVariable [QGVAR(quickAct), ""];
        private _id = _ctrl getVariable [QGVAR(quickId), ""];
        private _payload = _ctrl getVariable [QGVAR(quickPayload), []];

        // A card is filed as itself, so the thread's state still moves; one
        // with a line left to fill opens in the composer, on this thread; a
        // phrase is a free-text reply carrying the words on the tile.
        switch (_act) do {
            case QUICK_FILE: {
                [_id, _payload, [], GVAR(readerThread)] call EFUNC(messaging,submit);
                if (GVAR(readerAdjust) isNotEqualTo []) then {
                    GVAR(readerAdjust) = [];
                    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
                };
            };
            case QUICK_OPEN: {
                [GVAR(readerThread), _id] call FUNC(composeOpen);
            };
            case QUICK_PICK: {
                GVAR(readerAdjust) = [GVAR(readerThread), _payload param [0, ""]];
                {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
            };
            case QUICK_BACK: {
                GVAR(readerAdjust) = [];
                {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
            };
            // SEND SITREP on a TIC thread (user, 2026-11-02): the SITREP in
            // the composer, in this thread, its location and ACE state filled.
            case QUICK_SITREP: {
                [GVAR(readerThread)] call FUNC(sitrepAfterTic);
            };
            // A NEW TASK IN THE THREAD (2026-11-02): the asset's own card -
            // a new CAS REQUEST, a NEXT LIFT - in the composer, in this thread.
            case QUICK_TASK: {
                [GVAR(readerThread), _id] call FUNC(taskInThread);
            };
            default {
                ["freetext", [[_ctrl getVariable [QGVAR(quickKey), ""], _ctrl getVariable [QGVAR(quickText), ""]]], [], GVAR(readerThread)] call EFUNC(messaging,submit);
            };
        };
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(quickAct), _act];
    _hit setVariable [QGVAR(quickId), _id];
    _hit setVariable [QGVAR(quickPayload), _payload];
    _hit setVariable [QGVAR(quickText), _word];
    _hit setVariable [QGVAR(quickKey), _freeKey];
} forEach _tiles;

// VOICE MSG: the design's inverted sixth tile, with the accent square that will
// be the record light. Disabled - no hit - until the voice work is decided.
// BACK has the slot while the distance pick is open.
if (!_picking) then {
    private _vx = _bx + _bw - _tileW;
    private _sq = _tileH * 0.22;
    [_root, [_vx, _y, _tileW, _tileH], _dim] call FUNC(drawFill);
    [_root, [_vx + _pad * 3, _y, _tileW * 0.7, _tileH * 0.6], "VOICE MSG", _ground, READER_TILE_SIZE, true] call FUNC(drawText);
    [_root, [_vx + _pad * 3, _y + _tileH * 0.5, _tileW * 0.7, _tileH * 0.45], "COMING", _ground, READER_K_SIZE, true, "left", true] call FUNC(drawText);
    [_root, [_vx + _tileW - _pad * 3 - _sq / pixelH * pixelW, _y + (_tileH - _sq) * 0.5, _sq / pixelH * pixelW, _sq], _accent] call FUNC(drawFill);
};

_y = _y + _tilesH + _gap;

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
    // At the player's own figures, jmfsb_devices_gridDigits (tablet review
    // 2026-11-01, 2.7), through the devices' one grid formatter; the engine's
    // square where the devices are not loaded.
    private _grid = if (isNil QEFUNC(devices,overlayGrid)) then {mapGridPosition _at} else {([_at] call EFUNC(devices,overlayGrid)) select 0};
    _ctrl ctrlSetText trim format ["%1 %2", trim (ctrlText _ctrl), _grid];
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
