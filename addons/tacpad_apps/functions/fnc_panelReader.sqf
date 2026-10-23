#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//MSG reader, built to the design: a net selector across the top, traffic
 * as three-line entries with a precedence badge and a time, and OPEN FULL / NEW
 * across the bottom.
 *
 * A THREAD OPENS IN THE RAIL, not over the map. Reading a report and looking at
 * the ground it is about are the same act - a MEDEVAC grid means nothing
 * without the map under it. Nothing here can send: REPLY and NEW hand off to
 * the full app, because composing wants room this rail has not got and wants to
 * be a deliberate act.
 *
 * THE TAB CARRIES ITS OWN COUNT. The design puts the unread number in the tab -
 * CMD 3, MED 1 - because the point of a net selector is deciding which net to
 * look at, and a selector that will not say where the traffic is makes you open
 * all five to find out.
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

private _scale = EGVAR(tacpad,textScale);
private _rowH = ROW_H * _scale * HOST_H;
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

// A row of air under the title bar. The tabs and the thread view both started
// at y0, flush against the header rule, and a strip touching the chrome reads
// as part of the chrome rather than as the panel's content. Row indices are
// fractional on purpose - FUNC(row) multiplies, it does not count.
private _row = _padY / _rowH;

if (isNil QEGVAR(messaging,index)) exitWith {
    [_body, _row, "MESSAGING NOT LOADED", "", [], true] call FUNC(row);
    [_id, ""] call EFUNC(tacpad,headerMeta);
};

// ------------------------------------------------------------ thread view ---
if (GVAR(readerThread) != "") exitWith {
    private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [GVAR(readerThread), []];

    // NEXT FRAME, always. A rebuild deletes every control in the panel -
    // including the button whose handler is running - so it is deferred out of
    // its own event rather than pulled out from under it.
    [_body, _row, "< BACK", "", [], true, {
        GVAR(readerThread) = "";
        {["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
    }] call FUNC(row);
    _row = _row + 1;

    if (_cached isEqualTo []) exitWith {
        [_body, _row, "FETCHING...", "", [], false] call FUNC(row);
        [_id, "OPEN"] call EFUNC(tacpad,headerMeta);
    };

    _cached params ["_thread", "_messages"];

    [_id, _thread get "status"] call EFUNC(tacpad,headerMeta);

    [_body, _row, _thread get "subject", _thread get "status", [], true] call FUNC(row);
    _row = _row + 1;

    {
        private _message = _x;
        [
            _body, _row,
            _message get "fromCallsign",
            ([_message get "templateId"] call EFUNC(messaging,template)) getOrDefault ["short", ""],
            [], (_message get "priority") == "high"
        ] call FUNC(row);
        _row = _row + 1;

        {
            if (_x != "") then {
                [_body, _row, _x, "", [], false] call FUNC(row);
                // AIR BETWEEN THE LINES. A report read as one dense slab was
                // "hard to read" (user, 2026-09-05); a third of a row between
                // lines keeps the sections apart without doubling the height.
                _row = _row + 1.35;
            };
        } forEach ([_message get "templateId", _message get "payload", false] call EFUNC(messaging,render) splitString endl);
        _row = _row + 0.5;      // and half a row between messages
    } forEach _messages;

    // A long thread runs past the foot of the rail and scrolls, which is what
    // the body being a scrolling controls group is for. The panel does not
    // resize itself to the thread - see the note at the end of this function.
    // Replying wants the full screen: the rail can show a thread beside the map,
    // and the composer is the right third of the reader - see
    // EFUNC(tacpad,composeOpen). It opens straight onto the template picker,
    // because a player who pressed REPLY on a card has a card in mind.
    [_body, _row, "REPLY - OPENS TAC//MSG", "", [], true, {
        [GVAR(readerThread), "", true] call EFUNC(tacpad,composeOpen);
    }] call FUNC(row);
};

// ------------------------------------------------------------- net tabs -----
// The design's CMD / PLT / MED / FSC / ALL strip. The nets are the shared
// mailboxes the messaging engine already has, so the tabs are not a second list
// that can disagree with the first - ALL is always last and always present.
private _index = EGVAR(messaging,index);

// FROM THE MAILBOXES THAT EXIST, not from the ones that happen to have traffic.
// Reading the nets off the index meant a quiet net had no tab, so a fresh
// mission showed one tab called ALL and the strip looked broken - and a player
// could not select the net they were about to send on.
//
// FILTERED TO THIS MAN (user, 2026-09-03) - the mission's JMFSBFR_Nets narrowed
// by his role, plus his own squad. It used to be the addon setting, unfiltered,
// with every squad in the task force appended. See EFUNC(messaging,railNets).
private _nets = +([player] call EFUNC(messaging,railNets));

// Anything the index knows about that is not configured still gets a tab, so a
// mission that files somewhere unusual is not hidden.
//
// TYPE-GUARDED, and walking the index directly rather than through an apply.
// The reader is redrawn from a per-frame handler and from inside the receive
// event, so it can be looking at the index while the engine is still filling it;
// a row that is not yet a HashMap, or a boxId that is not yet a string, is a
// tab this draw does not know about rather than an error every second.
{
    if !(_x isEqualType createHashMap) then {continue};

    private _box = _x getOrDefault ["boxId", ""];
    if (_box isEqualType "" && {(_box select [0, 2]) == "B:"}) then {
        _nets pushBackUnique (_box select [2]);
    };
} forEach _index;

// EVERY DECLARED SQUAD IS A NET, on this rail too - the platoon's traffic,
// not private mail. Own group leads even when the mission declares nothing.
// THE LOG VIEW. A page back through every notification that scrolled past -
// the request was a button to see past notifications, and this is where the
// traffic already lives. An entry filed with a position (a capture, a spot
// report) is clickable and centres the map on it; the rest just read.
if (GVAR(readerLog)) exitWith {
    private _row = _padY / _rowH;
    [_id, "LOG"] call EFUNC(tacpad,headerMeta);
    [_body, _row, "< BACK", "", [], true, {
        GVAR(readerLog) = false;
        {["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
    }] call FUNC(row);
    _row = _row + 1;
    private _hist = missionNamespace getVariable [QEGVAR(notify,history), []];
    if (_hist isEqualTo []) then {
        [_body, _row, "NOTHING LOGGED", "", [], false] call FUNC(row);
    } else {
        private _n = count _hist;
        for "_k" from (_n - 1) to ((_n - TRAFFIC_MAX) max 0) step -1 do {
            (_hist select _k) params ["_ht", "_hx", "_hc", ["_htime", 0], ["_hpos", []]];
            private _ago = round ((time - _htime) / 60);
            private _val = if (_hpos isEqualTo []) then {
                format ["%1m", _ago]
            } else {
                format ["%1 >", mapGridPosition _hpos]
            };
            private _rc = [_body, _row, toUpper _ht, _val, [], (_hpos isNotEqualTo []), {
                params ["", "_ctrl"];
                private _p = _ctrl getVariable [QGVAR(logPos), []];
                if (_p isEqualTo []) exitWith {};
                private _map = (ctrlParent _ctrl) displayCtrl 51;
                if (isNull _map) exitWith {};
                ctrlMapAnimClear _map;
                _map ctrlMapAnimAdd [0.3, ctrlMapScale _map, _p];
                ctrlMapAnimCommit _map;
            }] call FUNC(row);
            _rc setVariable [QGVAR(logPos), _hpos];
            _row = _row + 1;
            if (_hx isNotEqualTo "") then {
                [_body, _row, _hx, "", [], false] call FUNC(row);
                _row = _row + 1;
            };
        };
    };
};

// His own squad's net, which the strip below always keeps a tab for, and the
// same name as a box id for the legacy SQUAD key older saved state may hold.
private _ownNet = groupId (group player);
private _squadBox = format ["G:%1", _ownNet];
_nets pushBack "ALL";

// THE RAIL SHOWS THE NETS THAT MATTER RIGHT NOW. Fourteen tabs of two
// clipped letters was unreadable - said so in yellow. Here a net earns its
// tab by holding traffic; ALL, your own squad and the net you are reading
// are always present. The FULL reader's vertical list is where all of them
// are browsed and picked.
private _busy = [];
{
    if !(_x isEqualType createHashMap) then {continue};
    private _box = _x getOrDefault ["boxId", ""];
    if (_box isEqualType "" && {(_box select [0, 2]) in ["B:", "G:"]}) then {
        _busy pushBackUnique (_box select [2]);
    };
} forEach _index;

_nets = _nets select {
    _x isEqualTo "ALL"
    || _x isEqualTo _ownNet
    || _x isEqualTo GVAR(readerNet)
    || {_x in _busy}
};

private _active = GVAR(readerNet);
if !(_active in _nets) then {_active = "ALL"; GVAR(readerNet) = "ALL"};

// With no shared mailboxes configured there is only ALL, and "0 NETS" is a
// count of a thing the player never asked about. Say how much traffic there is.
//
// UNLESS THE SPECTRUM HAS SOMETHING TO SAY. Inside a jammer's field the link
// state takes the readout - a man whose rail has gone quiet reads WHY in the
// same place he reads how busy it is when it has not.
([] call EFUNC(messaging,linkState)) params ["_link"];
if (_link > 0) then {
    [_id, ["LINK DEGRADED", "LINK NONET"] select (_link > 1), true] call EFUNC(tacpad,headerMeta);
} else {
    [_id, [format ["%1 NETS", count _nets - 1], format ["%1 THREADS", count _index]] select (count _nets < 2)] call EFUNC(tacpad,headerMeta);
};

// DROPDOWN, NOT A ROW OF TABS. Five squads plus ALL made a strip too narrow to
// read; the net selector is one chip now - the active net and its unread count,
// a caret, and a click that drops the full list over the traffic (drawn last,
// at the end of this function, so it sits on top). The open state is UI-scoped:
// it closes on its own when the panel is rebuilt for any other reason.
private _tabH = _rowH * 0.95;
private _tabY = _padY;

private _netCount = {
    params ["_net"];
    private _c = 0;
    {
        if (_net == "ALL"
            || {(_x get "boxId") in [format ["B:%1", _net], format ["G:%1", _net]]}
            || {_net == "SQUAD" && {(_x get "boxId") == _squadBox}}) then {
            _c = _c + (_x get "unread");
        };
    } forEach _index;
    _c
};

private _activeLabel = _active;
private _adot = _activeLabel find ".";
if (_adot > -1) then {_activeLabel = _activeLabel select [_adot + 1]};
private _activeCount = [_active] call _netCount;

[_body, [0, _tabY, _w, _tabH], _accent] call EFUNC(tacpad,drawFill);
[
    _body, [_pad, _tabY, _w * 0.12, _tabH],
    ([">", "v"] select (uiNamespace getVariable [QGVAR(readerNetOpen), false])),
    _ground, TEXT_TITLE, true, "center"
] call EFUNC(tacpad,drawText);
[
    _body, [_w * 0.12, _tabY, _w * 0.88 - _pad, _tabH],
    toUpper (format ["%1%2", _activeLabel, [format [" (%1)", _activeCount], ""] select (_activeCount == 0)]),
    _ground, TEXT_TITLE, true, "left"
] call EFUNC(tacpad,drawText);
[_body, [0, _tabY, _w, _tabH], {
    uiNamespace setVariable [QGVAR(readerNetOpen), !(uiNamespace getVariable [QGVAR(readerNetOpen), false])];
    {["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

[_body, [0, _tabY + _tabH, _w, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

private _top = _tabY + _tabH + RULE_THICK * pixelH;
_row = _top / _rowH;

// -------------------------------------------------------------- traffic -----
private _rows = _index select {
    if (_active == "ALL") then {
        // ALL is the feed of what you have NOT muted - subscriptions are the
        // way a man hides the nets he does not need, the user's rule. The
        // muted net's own tab still shows everything, and a followed thread
        // still breaks through here.
        ([_x get "boxId", _x getOrDefault ["threadId", ""]] call EFUNC(messaging,netLevel)) isEqualTo 0
    } else {
        (_x get "boxId") in [format ["B:%1", _active], format ["G:%1", _active]]
        || {_active == "SQUAD" && {(_x get "boxId") == _squadBox}}
    }
};

// One row per thread, not one per mailbox it was filed in - see the same note in
// EFUNC(tacpad,readerDraw). A report sent to a shared net is in that net and in
// the sender's own box, and under ALL that is the same thread twice.
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

private _keyed = [];
{_keyed pushBack [_x get "lastActivity", _forEachIndex]} forEach _rows;
_keyed sort false;
_rows = _keyed apply {_rows # (_x # 1)};

private _unread = 0;
private _flash = 0;
{
    _unread = _unread + (_x get "unread");
    if ((_x get "priority") == "high" && {!((_x get "status") in ["CLOSED", "ABORTED"])}) then {_flash = _flash + 1};
} forEach _rows;

if (_rows isEqualTo []) then {
    [_body, _row, "NO TRAFFIC", "", [], false] call FUNC(row);
    _row = _row + 1;
} else {
    {
        _row = _row + ([_body, _row, _x, {
            params ["_ctrl"];
            private _threadId = _ctrl getVariable [QGVAR(threadId), ""];
            if (_threadId == "") exitWith {};

            GVAR(readerThread) = _threadId;
            [_threadId, {["reader"] call EFUNC(tacpad,rebuild)}] call EFUNC(messaging,open);
            {["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
        }] call FUNC(readerRow));
    } forEach (_rows select [0, TRAFFIC_MAX]);
};

// ------------------------------------------------------------- the feet -----
// OPEN FULL is the accent action, NEW is the outlined one - the design gives
// exactly one loud button per screen. The tally sits opposite them, which is
// where the design puts the thing you read rather than press.
//
// PINNED TO THE BOTTOM OF THE PANEL, not placed after the last thread. The
// reader is a docked rail at a fixed height - see the end of this function - so
// its controls belong at its foot the way the design draws them, rather than
// floating up under the tabs whenever the net is quiet.
private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
private _btnW = _w * 0.28;
private _bodyH = (ctrlPosition _body) # 3;
private _footY = _bodyH - _btnH - _padY * 2;

[_body, [_pad, _footY - _padY * 1.5, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

// Both buttons sit inside the panel's own margin rather than against its edge -
// a control touching the frame reads as part of the frame.
private _btnX = _pad * 2;
[_body, [_btnX, _footY, _btnW, _btnH], _accent] call EFUNC(tacpad,drawFill);
[_body, [_btnX + _pad, _footY, _btnW - 2 * _pad, _btnH], "OPEN FULL", _ground, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
[_body, [_btnX, _footY, _btnW, _btnH], {[] call EFUNC(tacpad,openReader)}] call EFUNC(tacpad,drawHit);

private _newX = _btnX + _btnW + _pad * 2;
[_body, [_newX, _footY, _btnW, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[_body, [_newX + _pad, _footY, _btnW - 2 * _pad, _btnH], "NEW", _ink, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
[_body, [_newX, _footY, _btnW, _btnH], {["", "", false] call EFUNC(tacpad,composeOpen)}] call EFUNC(tacpad,drawHit);

// LOG opens the page-back over past notifications; the unread/flash tally
// rides just above it, small, so the button still says what is waiting.
private _logX = _newX + _btnW + _pad * 2;
private _logW = _w - _logX - _pad * 2;
[_body, [_logX, _footY, _logW, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[_body, [_logX, _footY, _logW, _btnH], "LOG", _ink, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
[_body, [_logX, _footY, _logW, _btnH], {
    GVAR(readerLog) = true;
    uiNamespace setVariable [QGVAR(readerNetOpen), false];
    {["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

private _tally = [];
if (_unread > 0) then {_tally pushBack format ["%1 UNREAD", _unread]};
if (_flash > 0) then {_tally pushBack format ["%1 FLASH", _flash]};
[
    _body, [_logX, _footY - _btnH * 0.9, _logW, _btnH * 0.8],
    _tally joinString " - ",
    ([_mute, _accent] select (_flash > 0)),
    TEXT_LABEL, true, "center", true
] call EFUNC(tacpad,drawText);

// THE OPEN DROPDOWN, DRAWN LAST so it overlays the traffic beneath it. One row
// per net, the active one accented; a click picks it and closes the list.
if (uiNamespace getVariable [QGVAR(readerNetOpen), false]) then {
    private _optH = _rowH * 0.95;
    {
        private _net = _x;
        private _oy = _tabY + _tabH + RULE_THICK * pixelH + _forEachIndex * _optH;
        private _on = _net == _active;
        [_body, [0, _oy, _w, _optH], ([_ground, _accent] select _on)] call EFUNC(tacpad,drawFill);
        [_body, [0, _oy, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
        private _lab = _net;
        private _d = _lab find ".";
        if (_d > -1) then {_lab = _lab select [_d + 1]};
        private _c = [_net] call _netCount;
        [
            _body, [_pad * 2, _oy, _w - _pad * 3, _optH],
            toUpper (format ["%1%2", _lab, [format ["  (%1)", _c], ""] select (_c == 0)]),
            ([_ink, _ground] select _on), TEXT_TITLE, true, "left"
        ] call EFUNC(tacpad,drawText);
        private _hit = [_body, [0, _oy, _w, _optH], {
            params ["_ctrl"];
            GVAR(readerNet) = _ctrl getVariable [QGVAR(net), "ALL"];
            uiNamespace setVariable [QGVAR(readerNetOpen), false];
            {["reader"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(net), _net];
    } forEach _nets;
};

// NO fit. The reader keeps the height it was placed at - it is the docked rail
// down the right of the design, and a rail that shrinks to its contents is a
// panel that moves its own buttons every time a message arrives.
