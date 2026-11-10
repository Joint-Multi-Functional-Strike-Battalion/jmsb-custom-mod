#include "script_component.hpp"
/*
 * Author: YonV
 * A NET, AS ONE CONVERSATION. Everything filed to this net in the order it was
 * said, with the composer under it addressed to the same net.
 *
 * THIS IS WHAT A NET SHOULD ALWAYS HAVE BEEN. It was a filter: picking HQ
 * narrowed a list of separate threads and you clicked one to read it - so a
 * message sent to HQ was two clicks away from being visible in HQ, which is not
 * how anybody expects a channel to behave. A radio net is everything said on it,
 * in order.
 *
 * THE REPORT'S STATE IS ON THE LINE, not behind it. A CASEVAC is a thing said on
 * the net; its OPEN or CLAIMED state is a chip beside it rather than a folder to
 * open. That was the choice made when this was designed and it is why there is
 * no second level here at all.
 *
 * THE TAGS TRAVEL WITH THE MESSAGE - squad, job and urgency, stamped when it was
 * sent (see EFUNC(messaging,srvSubmit)). Read off the sender now, they would
 * change every time he was promoted or moved.
 *
 * SIDES ARE WHO SPOKE. Incoming sets right, your own sets left, with the indent
 * moving too - so the conversation can be followed without reading a call sign
 * on every line.
 *
 * Arguments:
 * 0: Stream, [[message, thread], ...] oldest first <ARRAY>
 * 1: Threads still being fetched <NUMBER>
 * 2: Pane geometry [x, w] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_stream, 0, [_detailX, _detailW]] call jmfsb_tacpad_fnc_readerNetView
 *
 * Public: No
 */

params [["_stream", [], [[]]], ["_pending", 0, [0]], ["_geom", [0, 0], [[]], 2]];

_geom params ["_dx", "_dw"];

// The same root the thread view uses - the reader's own content group, not a
// uiNamespace variable that nothing writes.
private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _h = (ctrlPosition _root) # 3;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = ([TEXT_TITLE] call FUNC(textH)) + 2 * _padY;
private _mute = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _net = GVAR(readerNet);
private _title = [_net, "ALL NETS"] select (_net isEqualTo "ALL");

// NOTHING ON THE NET, NOTHING IN THIS PANE (tablet review 2026-11-01, 3.1):
// the list says "No traffic on <net>"; a second empty state here, beside it,
// read as two answers to one question. Only a fetch still running is said.
if (_stream isEqualTo []) exitWith {
    if (_pending > 0) then {
        [_root, [_dx + _pad, _h * 0.4, _dw - 2 * _pad, _rowH], "FETCHING...", _dim, TEXT_TITLE, true, "center"] call FUNC(drawText);
    };
};

private _y = _padY;
// The title stops short of the CLOSE button FUNC(readerDraw) puts in the
// pane's top-right corner (user, 2026-09-05).
[_root, [_dx + _pad, _y, _dw - _dw * 0.15 - 3 * _pad, _rowH * 1.2], toUpper _title, _ink, TEXT_TITLE, true] call FUNC(drawText);
_y = _y + _rowH * 1.3;

// A count is a value, untracked, and singular at one (tablet review
// 2026-11-01, 2.3 / 2.7).
private _fnc_messages = {
    params ["_n"];
    format ["%1 MESSAGE%2", _n, ["S", ""] select (_n isEqualTo 1)]
};
[
    _root, [_dx + _pad, _y, _dw - 2 * _pad, _rowH],
    if (_pending > 0) then {
        format ["%1 - FETCHING %2 MORE", [count _stream] call _fnc_messages, _pending]
    } else {
        [count _stream] call _fnc_messages
    },
    _mute, TEXT_LABEL, true
] call FUNC(drawText);
_y = _y + _rowH;

[_root, [_dx + _pad, _y, _dw - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);
_y = _y + _padY;

// WHAT A QUICK PHRASE ANSWERS: the newest thread on the net, which is the one at
// the bottom of the pane the player is looking at. The stream is already sorted
// oldest first - see EFUNC(messaging,netStream) - so it is the last row.
private _replyTo = "";
private _replyThread = createHashMap;
{
    _x params ["", ["_t", createHashMap]];
    private _id = _t getOrDefault ["id", ""];
    if (_id isEqualType "" && _id isNotEqualTo "") then {
        _replyTo = _id;
        _replyThread = _t;
    };
} forEach _stream;

// THE QUICK REPLIES ANSWER THAT THREAD, AND ONLY WITH WHAT IT TAKES (tablet
// review 2026-11-01, 3.1) - the opened thread's rule (FUNC(readerQuick)). ALL
// is a view with no send target, so it has no composer at all; a net with no
// thread to answer has none either - NEW, at the top of the list, starts one.
// FUNC(threadLegal) (2026-11-02): none once it is over, never the asset's
// words to a player.
private _legal = [];
if (_replyTo isNotEqualTo "") then {
    _legal = [_replyTo, _replyThread] call FUNC(threadLegal);
};
private _composer = _net isNotEqualTo "ALL" && _legal isNotEqualTo [];

// The composer keeps the bottom of the pane whatever the traffic does, so the
// place you type is not somewhere that moves: its header and one row of tiles.
private _composerH = [0, _rowH + _btnH + 2 * _padY] select _composer;
private _floor = _h - _composerH;

// NEWEST LAST, AND THE NEWEST IS WHAT FITS. A conversation is read at its
// bottom; when there is more than the pane holds it is the OLD end that goes,
// which is the opposite of a list and the right way round for this.
private _lineH = _rowH * 2.1;
private _room = floor ((_floor - _y) / _lineH) max 1;
private _shown = _stream;
if (count _shown > _room) then {
    _shown = _shown select [count _shown - _room, _room];
    [
        _root, [_dx + _pad, _y, _dw - 2 * _pad, _rowH * 0.8],
        format ["%1 EARLIER", count _stream - _room], _dim, TEXT_LABEL, true, "center", true
    ] call FUNC(drawText);
    _y = _y + _rowH * 0.8;
};

private _myUid = getPlayerUID player;

{
    _x params ["_msg", ["_thread", createHashMap]];

    private _mine = (_msg getOrDefault ["fromUid", ""]) isEqualTo _myUid;
    private _align = ["right", "left"] select _mine;

    private _tx = _dx + _pad;
    private _tw = _dw - 2 * _pad;
    if (!_mine) then {
        _tx = _dx + _dw * 0.18;
        _tw = _dw * 0.82 - _pad;
    } else {
        _tw = _dw * 0.82 - _pad;
    };

    // --- the tag line ------------------------------------------------------
    // Squad, job and urgency, in that order, because that is the order a man
    // says them in: who I am with, what I do, how much you should care.
    private _tags = [];
    private _squad = _msg getOrDefault ["fromGroup", ""];
    if (_squad isNotEqualTo "") then {_tags pushBack toUpper _squad};

    private _role = _msg getOrDefault ["fromRole", ""];
    if (_role isNotEqualTo "") then {_tags pushBack _role};

    private _priority = toUpper (_msg getOrDefault ["priority", ""]);
    private _urgent = _priority in ["FLASH", "IMMEDIATE", "HIGH"];
    if (_priority isNotEqualTo "" && _priority isNotEqualTo "ROUTINE" && _priority isNotEqualTo "NORMAL") then {
        _tags pushBack _priority;
    };

    // WHO WAS CALLED OUT ON IT, with the arrow that means somebody was spoken to
    // by name rather than described. A line naming YOU reads as urgent whatever
    // the traffic's own priority was - the same escalation the notification
    // made when it arrived, so the alert and the line agree.
    private _called = _msg getOrDefault ["tags", []];
    if (_called isEqualType []) then {
        {
            if (_x isEqualType "") then {
                _tags pushBack (">" + _x);
                if ([player, _x] call EFUNC(messaging,tagMatch)) then {_urgent = true};
            };
        } forEach _called;
    };

    // A report that is still open says so here rather than behind a click.
    private _status = toUpper (_thread getOrDefault ["status", ""]);
    if (_status isNotEqualTo "" && _status isNotEqualTo "OPEN") then {_tags pushBack _status};

    // The sender's call sign and his tags: names, so untracked (tablet review
    // 2026-11-01, 2.3).
    [
        _root, [_tx, _y, _tw, _rowH * 0.8],
        format ["%1  %2", toUpper (_msg getOrDefault ["fromCallsign", "?"]), _tags joinString "  "],
        ([_mute, _accent] select _urgent), TEXT_LABEL, true, _align
    ] call FUNC(drawText);
    // THE SENDER'S LINE IS A BUTTON: press it to write to that player alone
    // (user, 2026-10-24: "click on a player to send them a message").
    private _fromUid = _msg getOrDefault ["fromUid", ""];
    if (!_mine && _fromUid isEqualType "" && _fromUid isNotEqualTo "") then {
        private _fromHit = [_root, [_tx, _y, _tw, _rowH * 0.8], {
            params ["_ctrl"];
            private _uid = _ctrl getVariable [QGVAR(uid), ""];
            if (_uid isEqualTo "") exitWith {};
            ["", "", false, format ["P:%1", _uid]] call FUNC(composeOpen);
        }] call FUNC(drawHit);
        _fromHit setVariable [QGVAR(uid), _fromUid];
    };

    [
        _root, [_tx, _y, _tw, _rowH * 0.8],
        [_msg getOrDefault ["sentTime", 0]] call FUNC(clock),
        _dim, TEXT_LABEL, false, ["left", "right"] select _mine
    ] call FUNC(drawText);

    // --- the subject, not the words ---------------------------------------
    // The whole report flattened into one line was a preview nobody could
    // read (user, 2026-09-05: "again remove this preview"). Under the tags
    // goes the thread's subject; the words are one click away in the thread.
    private _subject = _thread getOrDefault ["subject", ""];
    if !(_subject isEqualType "" && _subject isNotEqualTo "") then {
        _subject = ([_msg getOrDefault ["templateId", ""]] call EFUNC(messaging,template)) getOrDefault ["title", "MESSAGE"];
    };

    [
        _root, [_tx, _y + _rowH * 0.8, _tw, _rowH],
        _subject, ([_ink, _accent] select _urgent), TEXT_TITLE, true, _align
    ] call FUNC(drawText);

    _y = _y + _lineH;
} forEach _shown;

if (_composer) then {
    [[_dx, _dw], _floor, _replyTo, _legal] call FUNC(readerComposer);
};
