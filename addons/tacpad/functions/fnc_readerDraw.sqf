#include "script_component.hpp"
/*
 * Author: JMSB
 * Draws the reader - handoff 1a, three panes: the nets and roster rail
 * (FUNC(readerRail)), the thread list (FUNC(readerList)), and the right pane,
 * which is the opened thread (FUNC(readerThreadView)), the net as one
 * conversation (FUNC(readerNetView)) or the composer (FUNC(composePane)).
 * Called once on open and again on every selection, so it is the whole screen
 * every time rather than a set of partial updates that can disagree.
 *
 * Laid out in fractions of the reader's own rectangle, which is a fraction of
 * the host - the vanilla map's safe zone in native mode, the device screen in
 * tablet mode - so the same layout serves both.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_readerDraw
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _shell = _display displayCtrl IDC_RD_ROOT;
if (isNull _shell) exitWith {};

// THE CONTENT IS ITS OWN GROUP, thrown away whole and rebuilt - a group has an
// idc and no opinion about creation order.
private _old = _shell controlsGroupCtrl IDC_RD_CONTENT;
if (!isNull _old) then {ctrlDelete _old};

([] call FUNC(theme)) params ["", "_ink"];
private _dim = ["dim"] call FUNC(theme);

private _pos = ctrlPosition _shell;
private _w = _pos # 2;
private _h = _pos # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;

private _content = _display ctrlCreate [QGVAR(panel), IDC_RD_CONTENT, _shell];
_content ctrlSetPosition [0, 0, _w, _h];
_content ctrlCommit 0;

// Everything below draws into the content group rather than the shell, so the
// frame and the ground survive a redraw untouched.
private _root = _content;

private _ruleW = RULE_THICK * pixelW;
private _railW = _w * READER_RAIL_W;
private _listW = _w * READER_LIST_W;
private _lx = _railW + _ruleW;
private _detailX = _lx + _listW + _ruleW;
// One pad short of the edge, as the compose pane has always been laid out against.
private _detailW = _w - _detailX - _pad;

[_root, _railW, _h] call FUNC(readerRail);
[_root, _lx, _listW, _h] call FUNC(readerList);

[_root, [_railW, 0, _ruleW, _h], _dim] call FUNC(drawFill);
[_root, [_lx + _listW, 0, _ruleW, _h], _dim] call FUNC(drawFill);

// CLOSE, top-right of the window, on every view (user, 2026-09-05), and the
// FLASH banner back on top of the redraw. DRAWN LAST, AFTER THE VIEW - a label
// drawn across a button AFTER the button is a hole in it (FUNC(drawHit)) - so
// this is a block each branch below ends on.
private _fnc_finish = {
    private _closeH = ([READER_BTN_SIZE] call FUNC(textH)) + 3 * _padY;
    private _closeW = _detailW * READER_HEAD_BTN_W;
    private _closeX = _detailX + _detailW - _closeW - READER_INSET * _pad;
    private _closeY = READER_INSET * _padY;
    [_root, [_closeX, _closeY, _closeW, _closeH], _ink, RULE_THIN] call FUNC(drawFrame);
    [_root, [_closeX, _closeY, _closeW, _closeH], "CLOSE", _ink, READER_BTN_SIZE, true, "center"] call FUNC(drawText);
    // FUNC(readerClose), not closeDisplay: inside the tablet the reader's
    // display is the device dialog, and closing that closes the tablet.
    [_root, [_closeX, _closeY, _closeW, _closeH], {
        [] call FUNC(readerClose);
    }] call FUNC(drawHit);

    [] call FUNC(readerFlash);
};

// ============================================================== the detail ==
private _input = _display displayCtrl IDC_RD_INPUT;

// COMPOSING IS A STATE OF THIS PANE. NEW and + TEMPLATE switch what the right
// third of the screen is showing; the nets, the list and the thread you are
// answering all stay on screen while you write.
if (GVAR(composeOn)) exitWith {
    [[_detailX, _detailW]] call FUNC(composePane);
    [] call _fnc_finish;
};

// A NET IS A CONVERSATION, NOT A FOLDER OF THEM. With no single thread picked,
// the pane shows the whole net in the order it was said.
if (GVAR(readerThread) == "") exitWith {
    // The reply box is a child of the content group, so a rebuilt group has
    // already taken it away; parked here only if one somehow survives.
    if (!isNull _input) then {
        _input ctrlSetPosition [0, 0, 0, 0];
        _input ctrlCommit 0;
    };

    // ALL is a VIEW - every box at once - so it asks for "" and gets the whole
    // stream. The name-to-box rule lives in FUNC(netBox).
    private _boxId = [GVAR(readerNet)] call FUNC(netBox);
    ([_boxId] call EFUNC(messaging,netStream)) params ["_stream", "_pending"];

    [_stream, _pending, [_detailX, _detailW]] call FUNC(readerNetView);
    [] call _fnc_finish;
};

private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [GVAR(readerThread), []];
if (_cached isEqualTo []) exitWith {
    if (!isNull _input) then {
        _input ctrlSetPosition [0, 0, 0, 0];
        _input ctrlCommit 0;
    };
    [_root, [_detailX, _h * 0.45, _detailW, _rowH], "FETCHING...", _dim, READER_K_SIZE, true, "center", true] call FUNC(drawText);
    [] call _fnc_finish;
};

_cached params ["_thread", "_messages"];
[_thread, _messages, [_detailX, _detailW]] call FUNC(readerThreadView);
[] call _fnc_finish;
