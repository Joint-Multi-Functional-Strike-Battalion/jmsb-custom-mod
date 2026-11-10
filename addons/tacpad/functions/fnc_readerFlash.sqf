#include "script_component.hpp"
/*
 * Author: YonV
 * The FLASH banner (handoff 1a, "incoming FLASH traffic"; drawn as in 1d panel
 * 03): an accent strip naming the net, the subject and a preview, and three
 * actions - the first one-tap reply the thread will take, OPEN THREAD, and
 * SNOOZE 60S.
 *
 * OVER THE CURRENT VIEW. The reader when it is open; otherwise the host - the
 * vanilla map in native mode, the device's dialog in tablet mode. With neither
 * up there is nothing to lay it over, and the notification stack has already
 * said it; the banner is kept and shown the next time the reader draws.
 *
 * ONE BANNER, THE NEWEST. Called with a [row, message] pair it replaces what is
 * showing; called with nothing it puts the current one back (FUNC(readerDraw)
 * does that after every redraw, which would otherwise bury it), or clears it
 * when GVAR(readerFlashEntry) has been emptied.
 *
 * Arguments:
 * 0: [index row, message] of the FLASH traffic, [] to redraw what is held <ARRAY> (optional, default [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_entry, _message]] call jmfsb_tacpad_fnc_readerFlash
 *
 * Public: No
 */

params [["_pair", [], [[]]]];

if (!hasInterface) exitWith {};

if (_pair isNotEqualTo []) then {GVAR(readerFlashEntry) = _pair};

private _reader = uiNamespace getVariable [QGVAR(reader), displayNull];
private _host = HOST_DISPLAY;

// Off both displays first - one banner, wherever it ends up.
{
    if (!isNull _x) then {
        private _old = _x displayCtrl IDC_RD_FLASH;
        if (!isNull _old) then {ctrlDelete _old};
    };
} forEach [_reader, _host];

GVAR(readerFlashEntry) params [["_entry", createHashMap, [createHashMap]], ["_msg", createHashMap, [createHashMap]]];
if (_entry isEqualTo createHashMap) exitWith {};

private _threadId = _entry getOrDefault ["threadId", ""];

// Reading it is answering the banner - open in the reader now, or read since
// it arrived (nothing on it is unread any more).
private _unread = EGVAR(messaging,index) findIf {
    _x isEqualType createHashMap
    && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
    && {(_x getOrDefault ["unread", 0]) > 0}
};
if (_unread < 0 || {!isNull _reader && _threadId isEqualTo GVAR(readerThread)}) exitWith {
    GVAR(readerFlashEntry) = [];
};

private _display = [_host, _reader] select !(isNull _reader);
if (isNull _display) exitWith {};

// The view it covers: the reader's screen, or the host rectangle.
private _view = if (isNull _reader) then {HOST_RECT} else {ctrlPosition (_reader displayCtrl IDC_RD_ROOT)};
_view params ["_vx", "_vy", "_vw", "_vh"];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _muted = ["muted"] call FUNC(theme);
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _side = READER_INSET * _pad;
private _btnH = ([READER_BTN_SIZE] call FUNC(textH)) + 3 * _padY;
private _stripH = _rowH * 1.2;

private _w = _vw * READER_FLASH_W;
private _h = _stripH + READER_INSET * _padY + _rowH * 1.2 + _rowH + _padY * 2 + _btnH + READER_INSET * _padY;
private _bx = _vx + (_vw - _w) * 0.5;
private _by = _vy + _vh - _h - READER_INSET * _padY * 2;

private _group = _display ctrlCreate [QGVAR(panel), IDC_RD_FLASH];
_group ctrlSetPosition [_bx, _by, _w, _h];
_group ctrlCommit 0;

[_group, [0, 0, _w, _h], _solid] call FUNC(drawFill);
[_group, [0, 0, _w, _stripH], _accent] call FUNC(drawFill);

private _net = (_entry getOrDefault ["boxId", ""]) select [2];
// A support asset's box by its call sign (2026-11-01, design D1).
private _asset = "";
if (!isNil QEFUNC(support,boxName)) then {_asset = [_entry getOrDefault ["boxId", ""]] call EFUNC(support,boxName)};
private _strip = if (_asset isNotEqualTo "") then {
    format ["FLASH - INCOMING FROM %1", _asset]
} else {
    format ["FLASH - INCOMING ON %1 NET", toUpper _net]
};
[_group, [_side, 0, _w * 0.7, _stripH], _strip, _ground, READER_K_SIZE, true, "left", true] call FUNC(drawText);
[_group, [_w * 0.7, 0, _w * 0.3 - _side, _stripH], [_entry getOrDefault ["lastActivity", 0]] call FUNC(clock), _ground, READER_K_SIZE, true, "right", true] call FUNC(drawText);

private _cy = _stripH + READER_INSET * _padY;
[_group, [_side, _cy, _w - 2 * _side, _rowH * 1.2], toUpper (_entry getOrDefault ["subject", ""]), _ink, READER_SUBJECT_SIZE, true] call FUNC(drawText);
_cy = _cy + _rowH * 1.2;
[
    _group, [_side, _cy, _w - 2 * _side, _rowH],
    format ["%1 - %2", _msg getOrDefault ["fromCallsign", "?"], [_msg] call FUNC(readerPreview)],
    _muted, READER_PREVIEW_SIZE
] call FUNC(drawText);
_cy = _cy + _rowH + _padY * 2;

// ---------------------------------------------------------------- actions ---
private _btnW = (_w - 2 * _side - _pad * 4) / 3;

// THE PRIMARY ACTION: the first one-tap reply the thread will take now, sent
// into it on the press - the design's SMOKE OUT. None legal, no button.
// FUNC(threadLegal) (2026-11-02): never the asset's words to a player.
// THE MESSAGE TEMPLATES (2026-11-09): an asset's question offers its first
// answer (answer-only cards are its to offer); anything else the first one-tap
// card that is not one of the asset thread's commands - ABORT or RTB is never
// the banner's one press.
private _legal = [_threadId] call FUNC(threadLegal);
if ((_msg getOrDefault ["templateId", ""]) isEqualTo QUICK_PROMPT) then {
    private _answerKey = ([QUICK_PROMPT, QUICK_PROMPT_ANSWERS] call EFUNC(messaging,fieldKeys)) param [0, ""];
    private _answers = (createHashMapFromArray (_msg getOrDefault ["payload", []])) getOrDefault [_answerKey, ""];
    if !(_answers isEqualType "") then {_answers = ""};
    private _answering = [_threadId, createHashMap, true] call FUNC(threadLegal);
    _legal = ((_answers splitString QUICK_ANSWER_SEP) apply {toLower (trim _x)}) select {_x in _answering};
} else {
    _legal = _legal select {(([_x] call EFUNC(messaging,template)) getOrDefault ["assetThread", false]) isNotEqualTo true};
};
private _quick = _legal findIf {((([_x] call EFUNC(messaging,template)) getOrDefault ["order", []]) isEqualTo [])};
if (_quick >= 0) then {
    private _id = _legal # _quick;
    [_group, [_side, _cy, _btnW, _btnH], _accent] call FUNC(drawFill);
    [_group, [_side, _cy, _btnW, _btnH], toUpper (([_id] call EFUNC(messaging,template)) getOrDefault ["short", _id]), _ground, READER_BTN_SIZE, true, "center"] call FUNC(drawText);
    private _hit = [_group, [_side, _cy, _btnW, _btnH], {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(flashReply), ""], [], [], _ctrl getVariable [QGVAR(threadId), ""]] call EFUNC(messaging,submit);
        GVAR(readerFlashEntry) = [];
        {[] call FUNC(readerFlash)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(flashReply), _id];
    _hit setVariable [QGVAR(threadId), _threadId];
};

// OPEN THREAD: the reader, on this thread.
private _openX = _side + _btnW + _pad * 2;
[_group, [_openX, _cy, _btnW, _btnH], _ink, RULE_THIN] call FUNC(drawFrame);
[_group, [_openX, _cy, _btnW, _btnH], format ["OPEN THREAD %1", _threadId], _ink, READER_BTN_SIZE, true, "center"] call FUNC(drawText);
private _open = [_group, [_openX, _cy, _btnW, _btnH], {
    params ["_ctrl"];
    private _id = _ctrl getVariable [QGVAR(threadId), ""];
    GVAR(readerFlashEntry) = [];

    // Deferred: this handler belongs to a control the banner is about to lose.
    [{
        params ["_id"];
        [] call FUNC(readerFlash);
        if (isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {[] call FUNC(openReader)};
        GVAR(composeOn) = false;
        GVAR(readerThread) = _id;
        [_id, {{[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame}] call EFUNC(messaging,open);
        [] call FUNC(readerDraw);
    }, [_id]] call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);
_open setVariable [QGVAR(threadId), _threadId];

// SNOOZE 60S: away now, back in a minute if the thread is still unread.
private _snoozeX = _w - _side - _btnW;
[_group, [_snoozeX, _cy, _btnW, _btnH], _ink, RULE_THIN] call FUNC(drawFrame);
[_group, [_snoozeX, _cy, _btnW, _btnH], format ["SNOOZE %1S", READER_FLASH_SNOOZE], _ink, READER_BTN_SIZE, true, "center"] call FUNC(drawText);
private _snooze = [_group, [_snoozeX, _cy, _btnW, _btnH], {
    params ["_ctrl"];
    private _pair = _ctrl getVariable [QGVAR(flashPair), []];
    GVAR(readerFlashEntry) = [];
    {[] call FUNC(readerFlash)} call CBA_fnc_execNextFrame;

    [{
        params ["_pair"];
        private _id = (_pair # 0) getOrDefault ["threadId", ""];
        private _unread = EGVAR(messaging,index) findIf {
            _x isEqualType createHashMap
            && {(_x getOrDefault ["threadId", ""]) isEqualTo _id}
            && {(_x getOrDefault ["unread", 0]) > 0}
        };
        if (_unread >= 0 && {GVAR(readerFlashEntry) isEqualTo []}) then {[_pair] call FUNC(readerFlash)};
    }, [_pair], READER_FLASH_SNOOZE] call CBA_fnc_waitAndExecute;
}] call FUNC(drawHit);
_snooze setVariable [QGVAR(flashPair), GVAR(readerFlashEntry)];

// The frame last, around everything.
[_group, [0, 0, _w, _h], _ink, RULE_THICK] call FUNC(drawFrame);
