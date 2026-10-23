#include "script_component.hpp"
/*
 * Author: JMSB
 * The reader's right-hand pane: the opened thread (handoff 1a, pane 3). Header
 * with the priority chip, subject and NOTIFY / PIN TO MAP / ACK; the submitted
 * template as a read-only card (FUNC(readerCard)); the reply spine
 * (FUNC(readerReplies)); the composer at the foot (FUNC(readerQuick)).
 *
 * WHAT THE SERVER WOULD TAKE IS WORKED OUT ONCE, here, and handed to ACK and to
 * the composer alike - so neither can offer a reply the engine refuses.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: Messages <ARRAY>
 * 2: [x, width] of the pane, in the content group's own coordinates <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_thread, _messages, [_detailX, _detailW]] call jmfsb_tacpad_fnc_readerThreadView
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]], ["_messages", [], [[]]], ["_pane", [0, 0], [[]], 2]];

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

_pane params ["_dx", "_dw"];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _h = (ctrlPosition _root) # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _side = READER_INSET * _pad;
private _bx = _dx + _side;
private _bw = _dw - 2 * _side;

private _threadId = _thread getOrDefault ["id", ""];

// The engine's states are uppercase and the thread carries a real closed flag.
private _closed = (_thread getOrDefault ["closed", false]) isEqualTo true
    || {(_thread getOrDefault ["status", ""]) in ["CLOSED", "ABORTED"]};

private _legal = if (_closed) then {[]} else {
    ["reply", _thread getOrDefault ["status", ""]] call EFUNC(messaging,templateIds)
};

// ---------------------------------------------------------------- header ---
private _y = READER_INSET * _padY;
private _btnH = ([READER_BTN_SIZE] call FUNC(textH)) + 3 * _padY;
private _btnW = _dw * READER_HEAD_BTN_W;

// Right to left: CLOSE (drawn by FUNC(readerDraw) on every view), ACK, PIN TO
// MAP, NOTIFY. The subject stops where the buttons start.
private _ackX = _dx + _dw - _side - 2 * _btnW - _pad * 2;
private _pinX = _ackX - _btnW - _pad * 2;
private _folX = _pinX - _btnW - _pad * 2;

private _chipH = _rowH * 0.85;
private _chipW = [_root, [_bx, _y + (_btnH - _chipH) * 0.5], _chipH, _thread getOrDefault ["priority", ""]] call FUNC(readerChip);
private _titleX = _bx + _chipW + _pad * 3;
[_root, [_titleX, _y, _folX - _titleX - _pad * 2, _btnH], toUpper (_thread getOrDefault ["subject", ""]), _ink, READER_TITLE_SIZE, true] call FUNC(drawText);

// FOLLOW / MUTE - the per-thread override. NET (the net's level decides) ->
// FOLLOWING (always rings) -> MUTED (badges; FLASH and callouts break through).
private _over = (missionNamespace getVariable [QEGVAR(messaging,threadFollow), createHashMap]) getOrDefault [_threadId, -1];
private _folLabel = switch (_over) do {
    case 0: {"FOLLOWING"};
    case 1: {"MUTED"};
    default {"NOTIFY: NET"};
};
[_root, [_folX, _y, _btnW, _btnH], _ink, RULE_THIN] call FUNC(drawFrame);
[_root, [_folX + _pad * 2, _y, _btnW - _pad * 4, _btnH], _folLabel, [_ink, _accent] select (_over >= 0), READER_BTN_SIZE, true] call FUNC(drawText);
private _folHit = [_root, [_folX, _y, _btnW, _btnH], {
    params ["_ctrl"];
    private _th = _ctrl getVariable [QGVAR(followThread), ""];
    if (_th == "" || {isNil QEFUNC(messaging,follow)}) exitWith {};

    private _cur = (missionNamespace getVariable [QEGVAR(messaging,threadFollow), createHashMap]) getOrDefault [_th, -1];
    [_th, [0, 1, -1] select (_cur + 1)] call EFUNC(messaging,follow);
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);
_folHit setVariable [QGVAR(followThread), _threadId];

// PIN TO MAP: the thread's anchor, as a marker on this player's map.
[_root, [_pinX, _y, _btnW, _btnH], _ink, RULE_THIN] call FUNC(drawFrame);
[_root, [_pinX + _pad * 2, _y, _btnW - _pad * 4, _btnH], "PIN TO MAP", _ink, READER_BTN_SIZE, true] call FUNC(drawText);
[_root, [_pinX, _y, _btnW, _btnH], {
    private _t = ((missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [GVAR(readerThread), []]) param [0, createHashMap];
    private _anchor = _t getOrDefault ["anchorPos", []];
    if (_anchor isEqualTo []) exitWith {
        ["READER", "This thread has no grid to pin.", "high"] call EFUNC(messaging,notify);
    };

    private _m = createMarkerLocal [format ["jmfsb_reader_%1_%2", GVAR(readerThread), diag_frameNo], _anchor];
    _m setMarkerTypeLocal "mil_objective";
    _m setMarkerColorLocal "ColorRed";
    _m setMarkerTextLocal (_t getOrDefault ["subject", "THREAD"]);
    ["READER", "Pinned to your map.", "normal"] call EFUNC(messaging,notify);
}] call FUNC(drawHit);

// ACK SENDS WHAT THE STATE MACHINE WILL TAKE: roger where roger is legal (it
// moves the task to RECEIPT), otherwise the word itself as free text.
private _ackId = switch (true) do {
    case ("roger" in _legal): {"roger"};
    case ("freetext" in _legal): {"freetext"};
    default {""};
};
[_root, [_ackX, _y, _btnW, _btnH], [_accent, _dim] select (_ackId == "")] call FUNC(drawFill);
[_root, [_ackX + _pad * 2, _y, _btnW - _pad * 4, _btnH], ["ACK", "CLOSED"] select _closed, _ground, READER_BTN_SIZE, true] call FUNC(drawText);
if (_ackId != "") then {
    private _hit = [_root, [_ackX, _y, _btnW, _btnH], {
        params ["_ctrl"];
        if ((_ctrl getVariable [QGVAR(ackTemplate), ""]) == "roger") exitWith {
            ["roger", [], [], GVAR(readerThread)] call EFUNC(messaging,submit);
        };
        private _key = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];
        ["freetext", [[_key, "ROGER"]], [], GVAR(readerThread)] call EFUNC(messaging,submit);
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(ackTemplate), _ackId];
};

_y = _y + _btnH + _padY;

// THREAD id - NET - OPENED time BY whom - n REPLIES - status.
private _root0 = _messages param [0, createHashMap];
private _rowAt = EGVAR(messaging,index) findIf {
    _x isEqualType createHashMap && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
};
private _net = "";
if (_rowAt >= 0) then {
    _net = ((EGVAR(messaging,index) # _rowAt) getOrDefault ["boxId", ""]) select [2];
};
private _meta = [format ["THREAD %1", _threadId]];
if (_net isNotEqualTo "") then {_meta pushBack format ["%1 NET", _net]};
_meta pushBack format ["OPENED %1 BY %2", [_root0 getOrDefault ["sentTime", 0]] call FUNC(clock), _root0 getOrDefault ["fromCallsign", "?"]];
_meta pushBack format ["%1 REPLIES", (count _messages) - 1 max 0];
_meta pushBack toUpper (_thread getOrDefault ["status", ""]);
[_root, [_bx, _y, _bw, _rowH * 0.8], _meta joinString " - ", _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);
_y = _y + _rowH + READER_INSET * _padY;

[_root, [_dx, _y, _dw, RULE_THICK * pixelH], _dim] call FUNC(drawFill);
_y = _y + RULE_THICK * pixelH + READER_INSET * _padY;

// ------------------------------------------------------------------ body ---
// The composer's height first: the spine stops where it starts.
// Who the composer's CALL rings: every author on the thread and its
// participants, by uid (FUNC(readerCallUnits) finds them in game).
private _callUids = ((_messages apply {_x getOrDefault ["fromUid", ""]}) + (_thread getOrDefault ["participants", []])) select {
    _x isEqualType "" && _x isNotEqualTo ""
};
_callUids = _callUids arrayIntersect _callUids;
private _composerH = [_root, _thread, _legal, [_bx, _bw, _h], true] call FUNC(readerQuick);
private _floor = _h - _composerH;

_y = [_root, _root0, [_bx, _y, _bw]] call FUNC(readerCard);
_y = _y + READER_INSET * _padY;

[_root, _messages, [_bx, _y, _bw, _floor - _padY]] call FUNC(readerReplies);

// Last, so the + MARKER list it may open is on top of the replies.
[_root, _thread, _legal, [_bx, _bw, _h], false, _callUids] call FUNC(readerQuick);
