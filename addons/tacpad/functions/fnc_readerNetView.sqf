#include "script_component.hpp"
/*
 * Author: JMSB
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

private _y = _padY;
// The title stops short of the CLOSE button FUNC(readerDraw) puts in the
// pane's top-right corner (user, 2026-09-05).
[_root, [_dx + _pad, _y, _dw - _dw * 0.15 - 3 * _pad, _rowH * 1.2], toUpper _title, _ink, TEXT_TITLE, true] call FUNC(drawText);
_y = _y + _rowH * 1.3;

[
    _root, [_dx + _pad, _y, _dw - 2 * _pad, _rowH],
    if (_pending > 0) then {
        format ["%1 MESSAGE(S) - FETCHING %2 MORE", count _stream, _pending]
    } else {
        format ["%1 MESSAGE(S)", count _stream]
    },
    _mute, TEXT_LABEL, true, "left", true
] call FUNC(drawText);
_y = _y + _rowH;

[_root, [_dx + _pad, _y, _dw - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);
_y = _y + _padY;

// The composer keeps the bottom of the pane whatever the traffic does, so the
// place you type is not somewhere that moves.
private _quickRows = 1;
private _composerH = _rowH + _quickRows * (_btnH + _padY) + 2 * (_btnH + _padY) + _padY;
private _floor = _h - _composerH;

if (_stream isEqualTo []) exitWith {
    [
        _root, [_dx + _pad, _h * 0.4, _dw - 2 * _pad, _rowH],
        ["NOTHING ON THIS NET", "FETCHING..."] select (_pending > 0),
        _dim, TEXT_TITLE, true, "center"
    ] call FUNC(drawText);

    // NOTHING TO ANSWER, so a quick phrase opens a thread - which is the only
    // time it should. See FUNC(readerComposer).
    [[_dx, _dw], _floor] call FUNC(readerComposer);
};

// WHAT A QUICK PHRASE ANSWERS: the newest thread on the net, which is the one at
// the bottom of the pane the player is looking at. The stream is already sorted
// oldest first - see EFUNC(messaging,netStream) - so it is the last row.
private _replyTo = "";
{
    _x params ["", ["_t", createHashMap]];
    private _id = _t getOrDefault ["id", ""];
    if (_id isEqualType "" && _id isNotEqualTo "") then {_replyTo = _id};
} forEach _stream;

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

    [
        _root, [_tx, _y, _tw, _rowH * 0.8],
        format ["%1  %2", toUpper (_msg getOrDefault ["fromCallsign", "?"]), _tags joinString "  "],
        ([_mute, _accent] select _urgent), TEXT_LABEL, true, _align, true
    ] call FUNC(drawText);

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

[[_dx, _dw], _floor, _replyTo] call FUNC(readerComposer);
