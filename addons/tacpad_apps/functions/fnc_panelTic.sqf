#include "script_component.hpp"
/*
 * Author: JMSB
 * TROOPS IN CONTACT. One press, under everything else on the right rail, and the
 * only control in the suite that is loud on purpose.
 *
 * IT IS ONE PRESS BECAUSE OF WHEN IT IS PRESSED. A man who is being shot at is
 * not filling in a five-line card, and a contact nobody hears about because the
 * form took too long is the failure this exists to prevent. Everything it can
 * work out on its own it works out: where you are, who you are, what time it is.
 * The card is still there in the reader for the man who has a moment to say what
 * he is being shot at BY - this is the one that goes out first.
 *
 * NO TITLE BAR. Registered chromeless, like the three buttons above it - a
 * header reading CONTACT over a cell reading TROOPS IN CONTACT is a label for a
 * label, and this is the one control on the map screen that has to be pressed
 * without being read first.
 *
 * THE ENGINE ALREADY DOES THE THREE THINGS. Submitting the deck's own TIC report
 * marks the map, alerts the side and files the thread on the command net, all
 * from the template's own broadcast flag - see EFUNC(messaging,srvTic). So this
 * sends a report rather than doing any of it itself, which is what keeps a TIC
 * fired from here identical to a TIC filled in by hand.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];

if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

// A TIC is a shout, not a bulletin. The cell is deliberately the tallest thing
// on the rail and filled solid in the accent - the design gives one loud control
// per screen and this is the suite's.
private _cellH = _rowH * 2.2;
private _cellY = _padY * 1.5;
private _cellX = _pad;
private _cellW = _w - _cellX - _pad;

// FIRED ONCE, then held down for a moment. A man under fire presses a big red
// button more than once - that is what a big red button is for - and without
// this the section files three contact reports, three markers and three alerts
// for one contact. The engine's own nonce cannot help here: each press is a
// different draft.
private _last = missionNamespace getVariable [QGVAR(ticLast), -1e9];
private _left = TIC_COOLDOWN - (CBA_missionTime - _last);
private _ready = _left <= 0;

// Nothing to send it TO is the one state that has to be said before the press
// rather than after it, because the refusal would otherwise arrive as a
// notification behind whatever screen is open.
private _nets = ((EGVAR(messaging,namedBoxes) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
private _live = !isNil QEFUNC(messaging,submit) && {_nets isNotEqualTo []};

private _fill = [_accent, _line] select (!_ready || {!_live});
[_body, [_cellX, _cellY, _cellW, _cellH], _fill] call EFUNC(tacpad,drawFill);

[
    _body, [_cellX + _pad, _cellY + _padY * 0.5, _cellW - 2 * _pad, _rowH],
    "TROOPS IN CONTACT",
    ([_mute, _ground] select (_ready && _live)),
    TEXT_TITLE, true, "center"
] call EFUNC(tacpad,drawText);

[
    _body, [_cellX + _pad, _cellY + _rowH * 1.2, _cellW - 2 * _pad, _rowH * 0.8],
    switch (true) do {
        case (!_live): {"NO COMMAND NET CONFIGURED"};
        case (!_ready): {format ["SENT - %1s", ceil _left]};
        default {format ["MARKS THE MAP, ALERTS THE SIDE, FILES ON %1", toUpper (_nets # 0)]};
    },
    ([_mute, _ground] select (_ready && _live)),
    TEXT_LABEL, true, "center", true
] call EFUNC(tacpad,drawText);

if (_ready && _live) then {
    // THE SEND LIVES IN FUNC(ticSend), not here. It is also on a keybind now -
    // unbound by default, see initKeybinds.inc.sqf - and a contact report that
    // could be filed two ways by two copies of the same code is a contact
    // report that will eventually be filed two DIFFERENT ways. The cooldown
    // stamp both paths read is the reason that matters.
    //
    // QUIET FROM HERE: the cell above has already drawn every refusal this can
    // return, so a notification saying it again would be the second time the
    // player has been told.
    [_body, [_cellX, 0, _w - _cellX, _cellH + 3 * _padY], {
        [false] call FUNC(ticSend);
    }] call EFUNC(tacpad,drawHit);
};

[_id, 0, (_cellH + 3 * _padY) / HOST_H] call EFUNC(tacpad,fit);

// UNDER THE STRIPS, WHEREVER THE STRIPS ACTUALLY END. The default y was
// measured at the default text size, but the strips above are sized off the
// type - at a larger scale they grow straight down over this band. Their real
// bottom edge is on their groups, so it is read back, and this band keeps the
// same air under them that the reader keeps above them. Absolute, not nudged,
// so the 2-second refresh lands it in the same place every time.
private _open = missionNamespace getVariable [QEGVAR(tacpad,open), createHashMap];
private _bottom = -1;
{
    (_open getOrDefault [_x, []]) params [["_g", controlNull]];
    if (isNull _g) then {continue};
    (ctrlPosition _g) params ["", "_gy", "", "_gh"];
    _bottom = _bottom max (_gy + _gh);
} forEach ["settings", "admin", "hide"];

if (_bottom > -1) then {
    (_open getOrDefault [_id, []]) params [["_group", controlNull]];
    if (!isNull _group) then {
        (ctrlPosition _group) params ["_gx", "_gy", "_gw", "_gh"];
        private _gap = ((DEFAULT_SETTINGS # 1) - ((DEFAULT_READER # 1) + (DEFAULT_READER # 3))) * HOST_H;
        private _want = _bottom + _gap;
        if (abs (_gy - _want) > pixelH) then {
            _group ctrlSetPosition [_gx, _want, _gw, _gh];
            _group ctrlCommit 0;
        };
    };
};
