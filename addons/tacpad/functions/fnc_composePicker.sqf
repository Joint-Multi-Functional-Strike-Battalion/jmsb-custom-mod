#include "script_component.hpp"
/*
 * Author: JMSB
 * The template picker, drawn into the compose pane: the deck as cards, two up,
 * with what each one will ask you for.
 *
 * CARDS, NOT A LIST OF NAMES. "CASEVAC" and "CONTACT REPORT" are not choices a
 * player can weigh from the words alone under contact - the card says what it
 * is for and how much of it there is to fill in, which is the whole of the
 * decision.
 *
 * A REPLY IS OFFERED ONLY WHAT THE THREAD WILL TAKE. The list comes off the
 * engine's own legality check, so the picker can never show a report the server
 * would refuse - the thread's state (allowedFrom) and, where the cached thread
 * says who issued and who claimed it, the registry's senderMustBe: WILCO, ON
 * TASK and CANTCO are the assignee's, CLOSE the issuer's.
 *
 * A REPLY WITH NOTHING TO FILL IN IS A TILE, NOT A FORM (the handoff's 1b):
 * ROGER, WILCO and ON TASK send on the one press and move the thread. The
 * rest - CANTCO, MESSAGE, CLOSE - open their card as before.
 *
 * Arguments:
 * 0: [x, width, top y] of the pane, in the content group's own coordinates <ARRAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_pane", [0, 0, 0], [[]], 3]];

_pane params ["_dx", "_dw", "_top"];

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _h = (ctrlPosition _root) # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

private _threadId = GVAR(composeThread);

private _thread = createHashMap;
private _ids = if (_threadId isEqualTo "") then {
    ["root"] call EFUNC(messaging,templateIds)
} else {
    private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []];
    if (_cached isNotEqualTo []) then {_thread = _cached # 0};
    ["reply", _thread getOrDefault ["status", ""]] call EFUNC(messaging,templateIds)
};

// THE SENDER RULE, as the server reads it (EFUNC(messaging,srvThreadFor)): an
// unclaimed thread may be answered by anyone it reached, and a thread whose
// issuer this copy does not know is left for the server to decide.
if (_threadId isNotEqualTo "") then {
    private _uid = getPlayerUID player;
    private _issuer = _thread getOrDefault ["issuerUid", ""];
    private _claimed = _thread getOrDefault ["claimedBy", ""];
    _ids = _ids select {
        switch (([_x] call EFUNC(messaging,template)) getOrDefault ["senderMustBe", "any"]) do {
            case "issuer": {_issuer in ["", _uid]};
            case "assignee": {_claimed in ["", _uid]};
            default {true};
        }
    };
};

// The deck scrolls. It is fifteen cards and counting, and a picker that only
// shows what fits is a picker that hides half the deck.
private _bodyW = _dw - 2 * _pad;
private _bodyH = _h - _top - _padY * 2;

private _body = _display ctrlCreate [QGVAR(body), -1, _root];
_body ctrlSetPosition [_dx + _pad, _top, _bodyW, _bodyH];
_body ctrlSetBackgroundColor [0, 0, 0, 0];
_body ctrlCommit 0;

// The scrollbar owns the right edge of a scrolling group, so the cards stop
// short of it rather than being clipped in half by it.
private _scrollW = 14 * pixelW;
private _colW = (_bodyW - _scrollW - _pad) / 2;
private _cardH = _rowH * 2.7;

// NO PLAIN-MESSAGE CARDS. The plain box is the composer's DEFAULT state -
// asked in red: "is not the default a plain text message window" - so the
// picker offers only the forms. The way back to plain is the REMOVE button,
// which is already there whenever a template is on.
// A TEMPLATE ONLY A LEADER MAY SEND IS NOT OFFERED TO ANYONE ELSE. The server
// refuses it anyway (senderMustBe, FUNC(srvThreadFor)); hiding it here is so a
// rifleman does not fill in a METT-TC and learn at SEND that it was not his.
private _isLeader = (player getVariable ["isLeader", false]) isEqualTo true;
_ids = _ids select {
    ((([_x] call EFUNC(messaging,template)) getOrDefault ["senderMustBe", "any"]) isNotEqualTo "leader") || _isLeader
};
private _cards = (_ids select {_x isNotEqualTo "freetext"}) apply {[_x, [_x] call EFUNC(messaging,template)]};

// ------------------------------------------------------------ one-tap tiles --
private _tiles = [];
if (_threadId isNotEqualTo "") then {
    _tiles = _cards select {((_x # 1) getOrDefault ["order", []]) isEqualTo []};
    _cards = _cards select {((_x # 1) getOrDefault ["order", []]) isNotEqualTo []};
};

private _tileY = [_body, _tiles, _bodyW - _scrollW] call FUNC(composeTiles);

private _tagH = ([CARD_TAG_SIZE] call FUNC(textH)) + _padY;
private _glyph = ([CARD_TAG_SIZE] call FUNC(textH)) / 1.25 * CARD_GLYPH_W * pixelW / pixelH;

{
    _x params ["_id", "_t"];

    private _col = _forEachIndex % 2;
    private _cx = _col * (_colW + _pad);
    private _cy = _tileY + floor (_forEachIndex / 2) * (_cardH + _pad);

    private _on = _id isEqualTo GVAR(composeTemplate);
    private _plain = _id isEqualTo "";
    private _fields = count (_t getOrDefault ["order", []]);
    private _flash = (_t getOrDefault ["priority", "normal"]) isEqualTo CARD_PRIORITY_HIGH;

    if (_on) then {
        [_body, [_cx, _cy, _colW, _cardH], [_accent # 0, _accent # 1, _accent # 2, 0.12]] call FUNC(drawFill);
    };
    [_body, [_cx, _cy, _colW, _cardH], ([_line, _accent] select _on), ([RULE_THIN, RULE_THICK] select _on)] call FUNC(drawFrame);

    // The tag: what the report is called on the net, in the card header's
    // box - ink, or the accent when sending it makes somebody's screen go red.
    private _short = toUpper (_t getOrDefault ["short", _id]);
    private _tagW = ((count _short) * _glyph + 2 * _pad) min (_colW * CARD_TAG_MAX_W * 2);
    private _tagY = _cy + _padY * 0.5 + (_rowH * 0.7 - _tagH) * 0.5;
    [_body, [_cx + _pad, _tagY, _tagW, _tagH], [_ink, _accent] select _flash] call FUNC(drawFill);
    [_body, [_cx + _pad, _tagY, _tagW, _tagH], _short, _ground, CARD_TAG_SIZE, true, "center"] call FUNC(drawText);

    [
        _body, [_cx + _pad, _cy + _rowH * 0.85, _colW - 2 * _pad, _rowH],
        [_t getOrDefault ["title", _id], "PLAIN MESSAGE"] select _plain,
        _ink, TEXT_TITLE, true
    ] call FUNC(drawText);

    [
        _body, [_cx + _pad, _cy + _rowH * 1.85, _colW - 2 * _pad, _rowH * 0.8],
        if (_plain) then {
            "Type it yourself - no form"
        } else {
            [format ["%1 fields to fill", _fields], "Nothing to fill in - one press"] select (_fields isEqualTo 0)
        },
        _mute, TEXT_BODY
    ] call FUNC(drawText);

    private _hit = [_body, [_cx, _cy, _colW, _cardH], {
        params ["_ctrl"];
        GVAR(composeTemplate) = _ctrl getVariable [QGVAR(pick), ""];
        GVAR(composePick) = false;
        GVAR(composeMarker) = "";
        GVAR(composePin) = [];
        GVAR(composePinPick) = false;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(pick), _id];
} forEach _cards;

// Under the cards, never over them: with no legal report the deck is one card
// long - PLAIN MESSAGE - and this says why.
if (_ids isEqualTo []) then {
    [
        _body, [0, _tileY + _cardH + _pad + _padY, _bodyW - _scrollW, _rowH],
        "NO REPORT CAN BE SENT INTO THIS THREAD", _dim, TEXT_TITLE
    ] call FUNC(drawText);
};
