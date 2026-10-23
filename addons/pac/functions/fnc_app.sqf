#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//PAC - the unit, as a player sees it. Four views under one tab row:
 * RECORD (their own), ROSTER (everybody), OPORD (the list and the open one),
 * REQUESTS (their PAC requests, and a form to raise one - 2026-09-09).
 *
 * READ-ONLY BUT FOR ONE THING. Ranks, skills, awards and status are set by
 * admins in TAC//PAC, and the roster a client draws is the copy the server
 * published - see FUNC(publish). A player can look at their record and cannot
 * touch it, which is what makes the record worth looking at. The one write is
 * a PAC request (FUNC(ticketRaise)), which is theirs to make.
 *
 * AND ANY MAN'S RECORD, from the ROSTER tab: tap a name and the RECORD tab
 * shows his published row. NOT HIS NOTES - FUNC(publish) never sends them,
 * because a note is written by an admin ABOUT a player; they live on the
 * admin page and nowhere else (user, 2026-09-05). The tab row clears whoever
 * was open, so MY RECORD is always your own.
 *
 * THE STRUCTURE IS READ LOCALLY. Every rank, skill and OPORD is compiled config
 * and identical on every machine, so an id is turned into a name here rather
 * than the server sending names down - FUNC(lookup) is that, and it also says
 * when an id points at nothing any more.
 *
 * IT IS DRAWN IN THE SUITE'S OWN HAND. The same appFrame, the same drawText,
 * the same rule weights as every other app, because a unit management screen
 * that looked like a different mod would be read as one.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

// AN OPEN ORDER GETS A TALLER FRAME. An OPORD is nine blocks of prose, and the
// record's height cut it off after FRIENDLY (user, 2026-09-05: "this is
// missing information and rows").
// NIL-SAFE ON BOTH SIDES, AND NO BRACES. `a && b` evaluates b whatever a is;
// only `a && {b}` short-circuits. The braces this line had were taken off for
// a lint help (L-S26) on 2026-09-05, after which openOpord - unset until an
// order has ever been opened - was read on every open, the draw aborted on
// the undefined variable, and every tab came up blank ("the my record button
// does not work"). getVariable with a default never errors, so this is safe
// without the braces the lint objects to.
private _view0 = missionNamespace getVariable [QGVAR(view), "record"];
private _tall = (_view0 isEqualTo "opord" && (missionNamespace getVariable [QGVAR(openOpord), ""]) isNotEqualTo "")
    || _view0 in ["request", "raise", "apply"];
([_display, "PAC", 0.62, [0.58, 0.88] select _tall] call jmfsb_tacpad_fnc_appFrame) params ["", "_body"];
if (isNull _body) exitWith {};

([] call jmfsb_tacpad_fnc_theme) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * jmfsb_tacpad_textScale * jmfsb_tacpad_uiScale * safeZoneH;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _h = _pos # 3;
private _pad = PAD * safeZoneW;
private _padY = PAD * safeZoneH;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

private _view = GVAR(view);
private _uid = [player] call FUNC(uid);
private _roster = missionNamespace getVariable [QGVAR(roster), []];

// DIAGNOSTIC (2026-09-05, "the my record button does not work"): every draw
// says which view it drew and whether this player's own row was on the roster,
// so the .rpt answers the question the screen cannot. Hoisted into one string
// - a comma inside a macro argument reads as an argument separator.
private _found = (_roster findIf {(_x # 0) isEqualTo _uid}) >= 0;
private _diag = format ["PAC app drawn: view '%1', %2 on the roster, uid %3, own record %4", _view, count _roster, _uid, ["NOT found", "found"] select _found];
INFO_1("%1",_diag);

// ---- the tab row -------------------------------------------------------------
// MY RECORD, ROSTER, OPORD, REQUESTS - the member's pages, the website's My
// details and PAC requests. The dashboard and everything an admin edits are
// TAC//PAC itself (FUNC(uiOpen)): one dialog laid out like the website,
// opened from the admin panel (user, 2026-09-09: "pac requests need to be on
// the live tile there is a roster and my info there, in pac a page for admins
// to work pac requests").
// APPLICATION INSTEAD OF MY RECORD for somebody not on the roster when the
// unit makes new players apply (settings newPlayers = "apply", 2026-09-10).
// Once an admin accepts them the roster carries them and MY RECORD is back.
private _mustApply = (toLower (GVAR(settings) getOrDefault ["newPlayers", "auto"])) isEqualTo "apply"
    && (_roster findIf {(_x # 0) isEqualTo _uid}) < 0;
if (_mustApply && _view isEqualTo "record") then {
    _view = "apply";
    GVAR(view) = "apply";
};
if (!_mustApply && _view isEqualTo "apply") then {
    _view = "record";
    GVAR(view) = "record";
};
private _tabs = [[["record", "MY RECORD"], ["apply", "APPLICATION"]] select _mustApply, ["roster", "ROSTER"], ["opord", "OPORD"], ["requests", "REQUESTS"]];

private _y = 0;
{
    _x params ["_id", "_label"];
    // DIVIDED BY HOW MANY THERE ARE, not by three. This was `_w / 3` from when
    // there were exactly three, so the admin's fourth tab was drawn off the
    // right-hand edge of the panel (2026-09-09).
    private _tw = _w / (count _tabs);
    private _tx = _forEachIndex * _tw;
    private _on = _id isEqualTo _view || (_id isEqualTo "requests" && _view in ["request", "raise"]);

    if (_on) then {
        [_body, [_tx, _y, _tw - _pad, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.14]] call jmfsb_tacpad_fnc_drawFill;
    };
    [_body, [_tx, _y, _tw - _pad, _rowH], ([_line, _accent] select _on), ([RULE_THIN, RULE_THICK] select _on)] call jmfsb_tacpad_fnc_drawFrame;
    [_body, [_tx, _y, _tw - _pad, _rowH], _label, ([_mute, _ink] select _on), TEXT_BODY, _on, "center", true] call jmfsb_tacpad_fnc_drawText;

    private _hit = [_body, [_tx, _y, _tw - _pad, _rowH], {
        params ["_ctrl"];
        GVAR(view) = _ctrl getVariable [QGVAR(tab), "record"];
        // A TAB IS A FRESH START. Pressing MY RECORD while reading somebody
        // else's must show your own, so the tab row clears whoever was open.
        GVAR(viewUid) = "";
        // DIAGNOSTIC (2026-09-05): the press itself, so a tab that does nothing
        // on screen can be told apart from a press that never arrived.
        INFO_1("PAC tab pressed: '%1' - reopening the app",GVAR(view));
        // NEXT FRAME, UNSCHEDULED - the way every other app reopens itself
        // (squad, hack, timer, intel: `{...} call CBA_fnc_execNextFrame`). This
        // was a scheduled `spawn`, the one app in the suite that reopened that
        // way (aligned 2026-09-05 while chasing "the my record button does not
        // work"; not proven to be the cause, but the odd one out is gone).
        {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
    }] call jmfsb_tacpad_fnc_drawHit;
    _hit setVariable [QGVAR(tab), _id];
} forEach _tabs;

_y = _y + _rowH + _padY;
[_body, [0, _y, _w, RULE_THICK * pixelH], _ink] call jmfsb_tacpad_fnc_drawFill;
_y = _y + _padY * 2;

// TWO COLUMNS THAT MEET IN THE MIDDLE. The label was pinned to the left edge
// and its value to the right, so a word and its answer sat a whole panel
// apart with nothing between them and the eye had to cross the screen for
// every line. The label is right-aligned against the gutter now and the value
// left-aligned just past it (user, 2026-09-06: "justified right", "justified
// left to make it easier to read").
private _labW = _w * 0.30;
private _valX = _w * 0.34;
private _valW = _w * 0.66 - _pad;

private _fnc_row = {
    params ["_label", "_value", ["_colour", _ink]];
    [_body, [_pad, _y, _labW - _pad, _rowH], _label, _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
    [_body, [_valX, _y, _valW, _rowH], _value, _colour, TEXT_TITLE, false, "left"] call jmfsb_tacpad_fnc_drawText;
    _y = _y + _rowH;
};

// THE SAME ROW WHERE THE VALUE WRAPS, MEASURED RATHER THAN GUESSED. Every
// wrapped block in this app sized itself by counting characters and dividing
// by a guess at how many fit on a line, which is wrong at any text size but
// the one it was tuned on - so the tail of a long block was drawn outside its
// own box and clipped (user, 2026-09-06: "text cut off"). ctrlTextHeight
// reports what the engine actually laid out at this width; the box is grown
// to that and the next row starts below it, so nothing can be cut.
private _fnc_wrapped = {
    params ["_label", "_text", ["_colour", _ink], ["_size", TEXT_BODY]];
    if (_label isNotEqualTo "") then {
        [_body, [_pad, _y, _labW - _pad, _rowH], _label, _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
    };
    private _c = [_body, [_valX, _y, _valW, _rowH], _text, _colour, _size, false, "left"] call jmfsb_tacpad_fnc_drawText;
    private _th = (ctrlTextHeight _c) max _rowH;
    _c ctrlSetPosition [_valX, _y, _valW, _th];
    _c ctrlCommit 0;
    _y = _y + _th;
};

switch (_view) do {

    // ---- RECORD: your own, or a man tapped on the ROSTER tab ----------------
    // ANOTHER MAN'S RECORD IS THE PUBLISHED ROW AND NOTHING MORE. That row is
    // name, rank, role, group, status, skills, awards and attendance - see
    // FUNC(publish), which deliberately keeps notes and saved loadouts on the
    // server because a note is written by an admin ABOUT a player and is
    // nobody else's business. So this view cannot show a note: the client has
    // never been sent one. Notes stay on the admin page (user, 2026-09-05:
    // "let players click on a name to see their record except notes, notes
    // are for admin in pac only").
    case "record": {
        private _who = [GVAR(viewUid), _uid] select (GVAR(viewUid) isEqualTo "");
        private _self = _who isEqualTo _uid;
        private _me = _roster select {(_x # 0) isEqualTo _who};

        if (_me isEqualTo []) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NO RECORD", _dim, TEXT_TITLE, false] call jmfsb_tacpad_fnc_drawText;
            [
                _body, [_pad, _y + _rowH, _w - 2 * _pad, _rowH * 2],
                ["That player is no longer on the published roster.", "The server has not seen you yet, or has not published the roster."] select _self,
                _dim, TEXT_BODY, false
            ] call jmfsb_tacpad_fnc_drawText;
        };

        // Reading somebody else: a way back to the list, and the roster row is
        // the whole of what there is to read.
        if (!_self) then {
            [_body, [_pad, _y, _w * 0.3, _rowH], "< BACK TO ROSTER", _accent, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
            [_body, [_pad, _y, _w * 0.3, _rowH], {
                GVAR(viewUid) = "";
                GVAR(view) = "roster";
                {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
            }] call jmfsb_tacpad_fnc_drawHit;
            [_body, [_w * 0.3, _y, _w * 0.7 - _pad, _rowH], "PERSONNEL RECORD", _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
            _y = _y + _rowH * 1.2;
        };

        (_me # 0) params ["", "_name", "_rankId", "_roleId", "_groupId", "_statusId", "_skillIds", "_awards", "_updated", ["_time", [0, 0]]];

        private _abbrev = ["ranks", _rankId, "abbrev"] call FUNC(lookup);
        [_body, [_pad, _y, _w - 2 * _pad, _rowH * 1.3], format ["%1 %2", _abbrev, _name], _ink, TEXT_TITLE, true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 1.4;

        ["RANK", ["ranks", _rankId] call FUNC(lookup)] call _fnc_row;
        ["ROLE", ["roles", _roleId] call FUNC(lookup)] call _fnc_row;
        ["GROUP", _groupId] call _fnc_row;
        ["STATUS", ["statuses", _statusId] call FUNC(lookup), _accent] call _fnc_row;
        _y = _y + _padY;

        // ONE WRAPPED LINE EACH, in the value column with everything else -
        // skills were a column a screen tall once (user, 2026-09-05: "line
        // these up horizontally") and awards a second little table of their own.
        if (_skillIds isEqualTo []) then {
            ["SKILLS", "None assigned", _dim] call _fnc_wrapped;
        } else {
            ["SKILLS", (_skillIds apply {["skills", _x] call FUNC(lookup)}) joinString "   ·   "] call _fnc_wrapped;
        };
        _y = _y + _padY;

        if (_awards isEqualTo []) then {
            ["AWARDS", "None", _dim] call _fnc_wrapped;
        } else {
            ["AWARDS", (_awards apply {
                _x params [["_awardId", ""], ["_date", ""]];
                private _n = ["awards", _awardId] call FUNC(lookup);
                [_n, format ["%1  (%2)", _n, _date select [0, 10]]] select (_date isNotEqualTo "")
            }) joinString "   ·   "] call _fnc_wrapped;
        };

        _y = _y + _padY;
        // Attendance, all time - the server totals it from the sessions when it
        // publishes, so the client never sees the sessions themselves. It is on
        // the published row, so it reads the same for a man you tapped.
        _time params [["_mins", 0], ["_joins", 0]];
        ["TIME ON", format ["%1h %2m  ·  %3 session%4", floor (_mins / 60), _mins mod 60, _joins, ["s", ""] select (_joins isEqualTo 1)], _ink] call _fnc_row;
        _y = _y + _rowH * 0.5;

        [_body, [_pad, _y, _w - 2 * _pad, _rowH], format ["UPDATED %1", _updated], _dim, TEXT_LABEL, false, "right"] call jmfsb_tacpad_fnc_drawText;
    };

    // ---- ROSTER: everybody ------------------------------------------------------
    case "roster": {
        if (_roster isEqualTo []) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NO ROSTER", _dim, TEXT_TITLE, false] call jmfsb_tacpad_fnc_drawText;
        };

        // Column heads once, then one row a player. Rank abbrev, name, role, and
        // the status in the accent because it is the thing an admin set on
        // purpose and the thing a player looking down the list is checking.
        [_body, [_pad, _y, _w - 2 * _pad, _rowH * 0.8], "TAP A NAME TO READ THAT MAN'S RECORD", _dim, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 0.8;

        [_body, [_pad, _y, _w * 0.12, _rowH], "RANK", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.12, _y, _w * 0.38, _rowH], "NAME", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.50, _y, _w * 0.30, _rowH], "ROLE", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.80, _y, _w * 0.20 - _pad, _rowH], "STATUS", _mute, TEXT_LABEL, true, "right", true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH;
        [_body, [_pad, _y, _w - 2 * _pad, RULE_THIN * pixelH], _line] call jmfsb_tacpad_fnc_drawFill;
        _y = _y + _padY - _rowH;          // each row steps down onto itself before it draws

        {
            _y = _y + _rowH;
            if (_y > _h - _rowH) exitWith {};
            _x params ["_rUid", "_name", "_rankId", "_roleId", "", "_statusId"];
            private _mine = _rUid isEqualTo _uid;

            [_body, [_pad, _y, _w * 0.12, _rowH], ["ranks", _rankId, "abbrev"] call FUNC(lookup), _mute, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.12, _y, _w * 0.38, _rowH], _name, _ink, TEXT_TITLE, _mine] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.50, _y, _w * 0.30, _rowH], ["roles", _roleId] call FUNC(lookup), _mute, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.80, _y, _w * 0.20 - _pad, _rowH], ["statuses", _statusId] call FUNC(lookup), _accent, TEXT_BODY, false, "right"] call jmfsb_tacpad_fnc_drawText;

            // The row opens that man's record - the published row, no notes.
            private _rowHit = [_body, [_pad, _y, _w - 2 * _pad, _rowH], {
                params ["_ctrl"];
                GVAR(viewUid) = _ctrl getVariable [QGVAR(rowUid), ""];
                GVAR(view) = "record";
                {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
            }] call jmfsb_tacpad_fnc_drawHit;
            _rowHit setVariable [QGVAR(rowUid), _rUid];
        } forEach _roster;
    };

    // ---- OPORD: the list, or the open one ----------------------------------------
    case "opord": {
        // The mission's orders first, then every one the server has cached that
        // the mission no longer carries - those read dim, and open the same way.
        private _live = GVAR(structure) getOrDefault ["opords", createHashMap];
        private _opords = +_live;
        {
            if !(_x in _opords) then {_opords set [_x, _y]};
        } forEach (missionNamespace getVariable [QGVAR(opordArchive), createHashMap]);
        private _open = GVAR(openOpord);

        if (_open isNotEqualTo "" && {!(_open in _opords)}) then { _open = "" };

        // The list. Newest first by the header date, which is a plain string
        // the mission maker typed - sorted as text, which is right if they wrote
        // dates that sort and wrong if they did not, and the fix is theirs.
        if (_open isEqualTo "") exitWith {
            if (count _opords isEqualTo 0) exitWith {
                [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NO OPORDS", _dim, TEXT_TITLE, false] call jmfsb_tacpad_fnc_drawText;
            };

            private _list = (keys _opords) apply {
                [((_opords get _x) get "header") getOrDefault ["date", ""], _x]
            };
            _list sort false;

            private _current = GVAR(settings) getOrDefault ["currentOpord", ""];

            {
                if (_y > _h - _rowH) exitWith {};
                _x params ["_date", "_id"];
                private _hdr = (_opords get _id) get "header";
                private _isCurrent = _id isEqualTo _current;
                private _isLive = _id in _live;
                private _orderId = _hdr getOrDefault ["id", ""];

                if (_isCurrent) then {
                    [_body, [_pad, _y, _w - 2 * _pad, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.14]] call jmfsb_tacpad_fnc_drawFill;
                };
                [_body, [_pad * 2, _y, _w * 0.6, _rowH], _hdr getOrDefault ["title", _id], ([[_dim, _ink] select _isLive, _accent] select _isCurrent), TEXT_TITLE, _isCurrent] call jmfsb_tacpad_fnc_drawText;
                [_body, [_w * 0.6, _y, _w * 0.4 - _pad * 2, _rowH], ([_orderId, _date] select {_x isNotEqualTo ""}) joinString "  -  ", _mute, TEXT_BODY, false, "right"] call jmfsb_tacpad_fnc_drawText;

                private _hit = [_body, [_pad, _y, _w - 2 * _pad, _rowH], {
                    params ["_ctrl"];
                    GVAR(openOpord) = _ctrl getVariable [QGVAR(id), ""];
                    // NEXT FRAME, UNSCHEDULED - the way every other app reopens itself
        // (squad, hack, timer, intel: `{...} call CBA_fnc_execNextFrame`). This
        // was a scheduled `spawn`, the one app in the suite that reopened that
        // way (aligned 2026-09-05 while chasing "the my record button does not
        // work"; not proven to be the cause, but the odd one out is gone).
        {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
                }] call jmfsb_tacpad_fnc_drawHit;
                _hit setVariable [QGVAR(id), _id];
                _y = _y + _rowH;
            } forEach _list;
        };

        // The open one. One section after another, the way the handoff lays it
        // out - flat, no annexes. BACK is the first row so it is never off the
        // bottom of a long order.
        private _o = _opords get _open;
        private _hdr = _o get "header";

        [_body, [_pad, _y, _w * 0.2, _rowH], "< BACK", _accent, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
        ([_body, [_pad, _y, _w * 0.2, _rowH], {
            GVAR(openOpord) = "";
            // NEXT FRAME, UNSCHEDULED - the way every other app reopens itself
        // (squad, hack, timer, intel: `{...} call CBA_fnc_execNextFrame`). This
        // was a scheduled `spawn`, the one app in the suite that reopened that
        // way (aligned 2026-09-05 while chasing "the my record button does not
        // work"; not proven to be the cause, but the odd one out is gone).
        {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
        }] call jmfsb_tacpad_fnc_drawHit);
        private _headline = [_hdr getOrDefault ["id", ""], "DATED " + (_hdr getOrDefault ["date", ""])] select {_x isNotEqualTo "" && _x isNotEqualTo "DATED "};
        [_body, [_w * 0.2, _y, _w * 0.8 - _pad, _rowH], _headline joinString "  -  ", _ink, TEXT_TITLE, true, "right"] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH;

        [_body, [_pad, _y, _w - 2 * _pad, _rowH * 1.3], _hdr getOrDefault ["title", _open], _ink, TEXT_TITLE, true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 1.4;

        // MEASURED, NOT COUNTED. This sized each block by dividing its length
        // by a guess at characters-per-line, which is wrong at every text size
        // but the one it was tuned on: too small and the block ran off its own
        // box and was clipped mid-sentence (user, 2026-09-06: "text cut off"),
        // too large and the later sections fell off the panel. ctrlTextHeight
        // asks the engine what it actually laid out at this width.
        private _fnc_block = {
            params ["_label", "_text"];
            if (_text isEqualTo "" || {_y > _h - _rowH * 2}) exitWith {};
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], _label, _mute, TEXT_BODY, true, "left", true] call jmfsb_tacpad_fnc_drawText;
            _y = _y + _rowH;

            private _c = [_body, [_pad * 2, _y, _w - 3 * _pad, _rowH], _text, _ink, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
            private _th = (ctrlTextHeight _c) max _rowH;
            _c ctrlSetPosition [_pad * 2, _y, _w - 3 * _pad, _th];
            _c ctrlCommit 0;
            _y = _y + _th + _padY;
        };

        private _sit = _o get "situation";
        private _msn = _o get "mission";
        private _adm = _o get "adminLogistics";
        private _cs = _o get "commandSignal";
        private _roe = _o get "roe";

        ["SITUATION", _sit getOrDefault ["overview", ""]] call _fnc_block;
        ["ENEMY", _sit getOrDefault ["enemy", ""]] call _fnc_block;
        ["FRIENDLY", _sit getOrDefault ["friendly", ""]] call _fnc_block;
        ["CIVIL / TERRAIN", _sit getOrDefault ["civilTerrain", ""]] call _fnc_block;
        ["MISSION", _msn getOrDefault ["mission", ""]] call _fnc_block;
        ["EXECUTION", _msn getOrDefault ["execution", ""]] call _fnc_block;
        ["ADMIN", _adm getOrDefault ["admin", ""]] call _fnc_block;
        ["LOGISTICS", _adm getOrDefault ["logistics", ""]] call _fnc_block;
        ["SIGNAL", _cs getOrDefault ["signal", ""]] call _fnc_block;
        ["COMMAND", _cs getOrDefault ["command", ""]] call _fnc_block;
        ["ROE", _roe getOrDefault ["roeText", ""]] call _fnc_block;
    };

    // ---- REQUESTS: the website's PAC requests, on the tile ----------------------
    // THREE SCREENS, as the website has them: the LIST of this player's
    // requests (here), ONE request with its thread and a reply box
    // ("request"), and the form to RAISE one ("raise") - the list first, a
    // row opens the request, and the kind and the man it is about are
    // dropdowns (user, 2026-09-10: "should open to a list of the players
    // requests", "could not open that request", "drops downs please").
    // The list is asked of the server (FUNC(ticketMine)) at most once a
    // minute; the answer redraws whichever of the three is open.
    case "requests": {
        private _svc = "service" in ((missionNamespace getVariable [QGVAR(summary), createHashMap]) getOrDefault ["backend", ""]);
        if (!_svc) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NO DATABASE", _dim, TEXT_TITLE, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_pad, _y + _rowH, _w - 2 * _pad, _rowH * 2], "PAC requests are kept in the unit's database, and this server has none.", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };
        if (GVAR(myTicketsAt) < 0 || {diag_tickTime - GVAR(myTicketsAt) > 60}) then {
            GVAR(myTicketsAt) = diag_tickTime;
            [player] remoteExec [QFUNC(ticketMine), 2];
        };

        [_body, [_pad, _y, _w * 0.6, _rowH], format ["MY REQUESTS  %1", count GVAR(myTickets)], _mute, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
        // RAISE A REQUEST, top right, where the website's card is
        [_body, [_w * 0.72, _y, _w * 0.28 - _pad, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.14]] call jmfsb_tacpad_fnc_drawFill;
        [_body, [_w * 0.72, _y, _w * 0.28 - _pad, _rowH], _accent, RULE_THICK] call jmfsb_tacpad_fnc_drawFrame;
        [_body, [_w * 0.72, _y, _w * 0.28 - _pad, _rowH], "RAISE A REQUEST", _ink, TEXT_BODY, true, "center", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.72, _y, _w * 0.28 - _pad, _rowH], {
            GVAR(view) = "raise";
            {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
        }] call jmfsb_tacpad_fnc_drawHit;
        _y = _y + _rowH + _padY;

        if (GVAR(myTickets) isEqualTo []) exitWith {
            private _said = switch (true) do {
                case (!GVAR(myTicketsSeen)): {"Asking the server ..."};
                case (!GVAR(myTicketsOk)): {"The database did not answer."};
                default {"None yet - RAISE A REQUEST is how one starts."};
            };
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], _said, _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };

        // the website's table: Id | Subject | Kind | State | Replies - tap a row to read it
        [_body, [_pad, _y, _w * 0.14, _rowH], "ID", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.14, _y, _w * 0.42, _rowH], "SUBJECT", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.56, _y, _w * 0.18, _rowH], "KIND", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.74, _y, _w * 0.14, _rowH], "STATE", _mute, TEXT_LABEL, true, "left", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_w * 0.88, _y, _w * 0.12 - _pad, _rowH], "REPLIES", _mute, TEXT_LABEL, true, "right", true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH;
        [_body, [_pad, _y, _w - 2 * _pad, RULE_THIN * pixelH], _line] call jmfsb_tacpad_fnc_drawFill;
        _y = _y + _padY - _rowH;          // each row steps down onto itself before it draws
        private _kinds = GVAR(ticketKinds);
        {
            _y = _y + _rowH;
            if (_y > _h - _rowH) exitWith {};
            private _t = _x;
            private _kid = _t getOrDefault ["kind", ""];
            private _kindName = (_kinds getOrDefault [_kid, createHashMap]) getOrDefault ["label", _kid];
            [_body, [_pad, _y, _w * 0.14, _rowH], _t getOrDefault ["id", ""], _mute, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.14, _y, _w * 0.42, _rowH], _t getOrDefault ["subject", ""], _ink, TEXT_TITLE, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.56, _y, _w * 0.18, _rowH], _kindName, _mute, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.74, _y, _w * 0.14, _rowH], toUpper (_t getOrDefault ["status", "open"]), _accent, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_w * 0.88, _y, _w * 0.12 - _pad, _rowH], str (count (_t getOrDefault ["replies", []])), _mute, TEXT_BODY, false, "right"] call jmfsb_tacpad_fnc_drawText;
            private _hit = [_body, [_pad, _y, _w - 2 * _pad, _rowH], {
                params ["_ctrl"];
                GVAR(reqOpen) = _ctrl getVariable [QGVAR(id), ""];
                GVAR(view) = "request";
                {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
            }] call jmfsb_tacpad_fnc_drawHit;
            _hit setVariable [QGVAR(id), _t getOrDefault ["id", ""]];
        } forEach GVAR(myTickets);
    };

    // ---- ONE REQUEST: what it is, the thread, a reply box ------------------------
    case "request": {
        private _id = GVAR(reqOpen);
        private _found = GVAR(myTickets) select {(_x getOrDefault ["id", ""]) isEqualTo _id};

        [_body, [_pad, _y, _w * 0.3, _rowH], "< BACK TO REQUESTS", _accent, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_pad, _y, _w * 0.3, _rowH], {
            GVAR(view) = "requests";
            {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
        }] call jmfsb_tacpad_fnc_drawHit;
        if (_found isEqualTo []) exitWith {
            [_body, [_w * 0.3, _y, _w * 0.7 - _pad, _rowH], "NOT ON THE LIST", _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
            [_body, [_pad, _y + _rowH * 1.5, _w - 2 * _pad, _rowH], "That request is not on your list any more.", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };
        private _t = _found # 0;
        [_body, [_w * 0.3, _y, _w * 0.7 - _pad, _rowH], format ["%1  -  %2", _id, toUpper (_t getOrDefault ["status", "open"])], _accent, TEXT_TITLE, true, "right", true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 1.2;

        [_body, [_pad, _y, _w - 2 * _pad, _rowH * 1.3], _t getOrDefault ["subject", ""], _ink, TEXT_TITLE, true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 1.4;
        private _kid = _t getOrDefault ["kind", ""];
        ["KIND", (GVAR(ticketKinds) getOrDefault [_kid, createHashMap]) getOrDefault ["label", _kid]] call _fnc_row;
        private _about = _t getOrDefault ["about", ""];
        private _aboutRow = _roster select {(_x # 0) isEqualTo _about};
        ["ABOUT", [[_about, "-"] select (_about isEqualTo ""), (_aboutRow # 0) # 1] select (_aboutRow isNotEqualTo [])] call _fnc_row;
        ["RAISED", (_t getOrDefault ["createdAt", ""]) select [0, 16]] call _fnc_row;
        ["UPDATED", (_t getOrDefault ["updatedAt", ""]) select [0, 16]] call _fnc_row;
        _y = _y + _padY;
        [_body, [0, _y, _w, RULE_THIN * pixelH], _dim] call jmfsb_tacpad_fnc_drawFill;
        _y = _y + _padY * 2;

        // THE THREAD, oldest first, the reply box kept clear of at the foot.
        private _replies = _t getOrDefault ["replies", []];
        if !(_replies isEqualType []) then {_replies = []};
        [_body, [_pad, _y, _w - 2 * _pad, _rowH], format ["THREAD  %1", count _replies], _mute, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH;
        private _foot = _h - _rowH * 4;
        // each post steps over the gap above it before it draws; the gap after the last one is added below the loop
        {
            _y = _y + _padY;
            if (_y > _foot - _rowH * 2) exitWith {
                [_body, [_pad, _y, _w - 2 * _pad, _rowH], "... more on the website", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
                _y = _y + _rowH - _padY;
            };
            private _r = _x;
            private _head = format ["%1   %2%3", _r getOrDefault ["byName", ""], (_r getOrDefault ["at", ""]) select [0, 16],
                ["", "   marked " + toUpper (_r getOrDefault ["status", ""])] select ((_r getOrDefault ["status", ""]) isNotEqualTo "")];
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], _head, _mute, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
            _y = _y + _rowH * 0.9;
            private _text = _r getOrDefault ["text", ""];
            if !(_text isEqualType "") then {_text = str _text};
            if (_text isNotEqualTo "") then {["", _text] call _fnc_wrapped};
        } forEach (_replies select {_x isEqualType createHashMap});

        // the reply box - a real edit control in the body, its text kept
        // across the tile's redraws in GVAR(reqReply)
        _y = _foot max (_y + _padY);
        [_body, [_pad, _y, _labW - _pad, _rowH], "REPLY", _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
        private _multi = ["RscEdit", "RscEditMulti"] select (isClass (configFile >> "RscEditMulti"));
        private _e = _display ctrlCreate [_multi, -1, _body];
        _e ctrlSetPosition [_valX, _y, _valW, _rowH * 2];
        _e ctrlSetBackgroundColor [_ink # 0, _ink # 1, _ink # 2, 0.08];
        _e ctrlSetTextColor _ink;
        _e ctrlSetFontHeight (_rowH * 0.72);
        _e ctrlSetText GVAR(reqReply);
        _e ctrlCommit 0;
        _e ctrlAddEventHandler ["KeyUp", {GVAR(reqReply) = ctrlText (_this select 0); false}];
        _y = _y + _rowH * 2 + _padY;
        [_body, [_valX, _y, _w * 0.24, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.14]] call jmfsb_tacpad_fnc_drawFill;
        [_body, [_valX, _y, _w * 0.24, _rowH], _accent, RULE_THICK] call jmfsb_tacpad_fnc_drawFrame;
        [_body, [_valX, _y, _w * 0.24, _rowH], "SEND", _ink, TEXT_TITLE, true, "center", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_valX, _y, _w * 0.24, _rowH], {
            private _text = trim GVAR(reqReply);
            if (_text isEqualTo "") exitWith {["TAC//PAC", "Nothing to send.", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify)};
            [player, GVAR(reqOpen), _text] remoteExec [QFUNC(ticketReply), 2];
            GVAR(reqReply) = "";
            GVAR(myTicketsAt) = -1;
            {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
        }] call jmfsb_tacpad_fnc_drawHit;
    };

    // ---- RAISE ONE: the form, with real dropdowns ---------------------------------
    case "raise": {
        [_body, [_pad, _y, _w * 0.3, _rowH], "< BACK TO REQUESTS", _accent, TEXT_BODY, true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_pad, _y, _w * 0.3, _rowH], {
            GVAR(view) = "requests";
            {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
        }] call jmfsb_tacpad_fnc_drawHit;
        [_body, [_w * 0.3, _y, _w * 0.7 - _pad, _rowH], "RAISE A PAC REQUEST", _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 1.4;

        private _kinds = keys GVAR(ticketKinds);
        _kinds sort true;
        if (_kinds isEqualTo []) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH * 2], "The unit has no request kinds yet - an admin adds them in TAC//PAC under Templates, System.", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };

        // A DROPDOWN (RscCombo) in the body, drawn in the suite's colours. What
        // is picked is kept by index in GVAR(reqKind) / GVAR(reqAbout) so a
        // redraw puts it back.
        private _fnc_combo = {
            params ["_label", "_options", "_var"];
            [_body, [_pad, _y, _labW - _pad, _rowH], _label, _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
            private _c = _display ctrlCreate ["RscCombo", -1, _body];
            _c ctrlSetPosition [_valX, _y, _valW, _rowH];
            _c ctrlSetBackgroundColor [_ink # 0, _ink # 1, _ink # 2, 0.08];
            _c ctrlSetTextColor _ink;
            _c ctrlSetFontHeight (_rowH * 0.72);
            {
                private _i = _c lbAdd (_x # 1);
                _c lbSetData [_i, _x # 0];
            } forEach _options;
            private _sel = ((missionNamespace getVariable [_var, 0]) max 0) min ((count _options) - 1);
            missionNamespace setVariable [_var, _sel];
            _c lbSetCurSel _sel;
            _c setVariable [QGVAR(reqVar), _var];
            _c ctrlAddEventHandler ["LBSelChanged", {
                params ["_ctrl", "_i"];
                missionNamespace setVariable [_ctrl getVariable [QGVAR(reqVar), ""], _i];
            }];
            _c ctrlCommit 0;
            _y = _y + _rowH + _padY;
        };
        ["KIND", _kinds apply {
            private _k = GVAR(ticketKinds) get _x;
            if !(_k isEqualType createHashMap) then {_k = createHashMap};
            private _hint = _k getOrDefault ["hint", ""];
            [_x, (_k getOrDefault ["label", _x]) + (["", "  -  " + _hint] select (_hint isNotEqualTo ""))]
        }, QGVAR(reqKind)] call _fnc_combo;
        ["ABOUT", [["", "-"]] + (_roster apply {[_x # 0, _x # 1]}), QGVAR(reqAbout)] call _fnc_combo;

        // the two typed boxes - real edit controls in the body, the way the
        // composer makes them (tacpad's composeCard)
        private _multi = ["RscEdit", "RscEditMulti"] select (isClass (configFile >> "RscEditMulti"));
        private _fnc_box = {
            params ["_label", "_var", "_lines", "_class"];
            [_body, [_pad, _y, _labW - _pad, _rowH], _label, _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
            private _e = _display ctrlCreate [_class, -1, _body];
            _e ctrlSetPosition [_valX, _y, _valW, _rowH * _lines];
            _e ctrlSetBackgroundColor [_ink # 0, _ink # 1, _ink # 2, 0.08];
            _e ctrlSetTextColor _ink;
            _e ctrlSetFontHeight (_rowH * 0.72);
            _e ctrlSetText (missionNamespace getVariable [_var, ""]);
            _e setVariable [QGVAR(reqVar), _var];
            _e ctrlCommit 0;
            _e ctrlAddEventHandler ["KeyUp", {
                params ["_ctrl"];
                missionNamespace setVariable [_ctrl getVariable [QGVAR(reqVar), ""], ctrlText _ctrl];
                false
            }];
            _y = _y + _rowH * _lines + _padY;
        };
        ["SUBJECT", QGVAR(reqSubject), 1, "RscEdit"] call _fnc_box;
        ["DETAILS", QGVAR(reqBody), 4, _multi] call _fnc_box;

        [_body, [_valX, _y, _w * 0.24, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.14]] call jmfsb_tacpad_fnc_drawFill;
        [_body, [_valX, _y, _w * 0.24, _rowH], _accent, RULE_THICK] call jmfsb_tacpad_fnc_drawFrame;
        [_body, [_valX, _y, _w * 0.24, _rowH], "RAISE IT", _ink, TEXT_TITLE, true, "center", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_valX, _y, _w * 0.24, _rowH], {
            private _kinds = keys GVAR(ticketKinds);
            _kinds sort true;
            private _kid = _kinds param [GVAR(reqKind), ""];
            private _subject = trim GVAR(reqSubject);
            if (_subject isEqualTo "") exitWith {["TAC//PAC", "Give it a one-line subject.", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify)};
            private _roster = missionNamespace getVariable [QGVAR(roster), []];
            private _about = if (GVAR(reqAbout) >= 1 && GVAR(reqAbout) <= count _roster) then {(_roster # (GVAR(reqAbout) - 1)) # 0} else {""};
            [player, _kid, _subject, GVAR(reqBody), _about] remoteExec [QFUNC(ticketRaise), 2];
            GVAR(reqSubject) = "";
            GVAR(reqBody) = "";
            GVAR(reqAbout) = 0;
            GVAR(myTicketsAt) = -1;
            GVAR(view) = "requests";
            {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
        }] call jmfsb_tacpad_fnc_drawHit;
    };
    // ---- APPLICATION: the website's Apply page, on the tile ---------------------
    // The unit's questions (<unit>.web.questions), one control each, and SEND;
    // what has been typed lives in GVAR(applyAnswers) across the tile's
    // redraws. A decided application shows its decision and no form.
    case "apply": {
        private _svc = "service" in ((missionNamespace getVariable [QGVAR(summary), createHashMap]) getOrDefault ["backend", ""]);
        if (!_svc) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NO DATABASE", _dim, TEXT_TITLE, false] call jmfsb_tacpad_fnc_drawText;
            [_body, [_pad, _y + _rowH, _w - 2 * _pad, _rowH * 2], "Applications are kept in the unit's database, and this server has none - ask an admin to add you.", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };
        if (GVAR(applyAt) < 0 || {diag_tickTime - GVAR(applyAt) > 60}) then {
            GVAR(applyAt) = diag_tickTime;
            [player] remoteExec [QFUNC(applyAsk), 2];
        };
        private _app = GVAR(myApplication);
        private _status = _app getOrDefault ["status", "none"];
        private _faction = ([] call jmfsb_groups_fnc_orbat) # 2;

        [_body, [_pad, _y, _w - 2 * _pad, _rowH * 1.3], format ["APPLY TO JOIN %1", toUpper ([_faction, "THE UNIT"] select (_faction isEqualTo ""))], _ink, TEXT_TITLE, true] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH * 1.4;
        if (!GVAR(applySeen)) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH], "Asking the server what the unit wants to know ...", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };
        private _said = switch (_status) do {
            case "new": {format ["Your application is IN, sent %1 - an admin decides it. You may change your answers until then.", (_app getOrDefault ["submittedAt", ""]) select [0, 16]]};
            case "accepted": {"ACCEPTED - your record is on its way; MY RECORD comes back when the roster carries you."};
            case "rejected": {"Not this time. Ask an admin if you want it reopened."};
            case "nodb": {"This server has no database."};
            default {"You are not on the roster. Answer the unit's questions and SEND; an admin accepts you under APPLICATIONS."};
        };
        [_body, [_pad, _y, _w - 2 * _pad, _rowH], _said, [_mute, _accent] select (_status in ["new", "accepted"]), TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        _y = _y + _rowH + _padY;
        if (_status in ["accepted", "rejected", "nodb"]) exitWith {};

        private _questions = GVAR(applyQuestions);
        if (_questions isEqualTo []) exitWith {
            [_body, [_pad, _y, _w - 2 * _pad, _rowH * 2], "The unit has not written its questions yet - an admin sets them on the website (Applications, Edit the questions).", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
        };
        [_body, [0, _y, _w, RULE_THIN * pixelH], _dim] call jmfsb_tacpad_fnc_drawFill;
        _y = _y + _padY;

        private _multi = ["RscEdit", "RscEditMulti"] select (isClass (configFile >> "RscEditMulti"));
        private _drawn = 0;
        // each question steps over the gap above it before it draws; the gap after the last one is added below the loop
        {
            _y = _y + _padY;
            private _q = _x;
            private _qid = _q getOrDefault ["id", ""];
            private _type = toLower (_q getOrDefault ["type", "text"]);
            private _lines = [1, 3] select (_type isEqualTo "textarea");
            // a "skills" question: an "I'm interested in" line, then the checkboxes, APPLY_SKILL_COLUMNS to a line
            private _choices = _q getOrDefault ["choices", []];
            if !(_choices isEqualType []) then {_choices = []};
            if (_type isEqualTo "skills") then {_lines = 1 + ceil ((count _choices max 1) / APPLY_SKILL_COLUMNS)};
            private _help = _q getOrDefault ["help", ""];
            if (_y > _h - _rowH * (_lines + 3)) exitWith {
                [_body, [_pad, _y, _w - 2 * _pad, _rowH], format ["... %1 more question(s) - the website's Apply page has them all", (count _questions) - _drawn], _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
                _y = _y + _rowH - _padY;
            };
            private _label = _q getOrDefault ["label", _qid];
            if ((_q getOrDefault ["required", false]) in [true, 1, "1", "true"]) then {_label = _label + " *"};
            [_body, [_pad, _y, _labW - _pad, _rowH], _label, _mute, TEXT_BODY, true, "right", true] call jmfsb_tacpad_fnc_drawText;
            switch (_type) do {
                case "skills": {
                    // the answer is the ticked skill ids; a press ticks or unticks one and redraws the tab
                    [_body, [_valX, _y, _valW, _rowH], "I'm interested in", _dim, TEXT_BODY, false] call jmfsb_tacpad_fnc_drawText;
                    if (_choices isEqualTo []) exitWith {
                        [_body, [_valX, _y + _rowH, _valW, _rowH], "The unit has no skills listed yet.", _dim, TEXT_LABEL, false] call jmfsb_tacpad_fnc_drawText;
                    };
                    private _ticked = GVAR(applyAnswers) getOrDefault [_qid, []];
                    if !(_ticked isEqualType []) then {_ticked = []};
                    private _colW = _valW / APPLY_SKILL_COLUMNS;
                    {
                        _x params [["_sid", "", [""]], ["_sname", "", [""]]];
                        private _on = _sid in _ticked;
                        private _cell = [
                            _valX + (_forEachIndex % APPLY_SKILL_COLUMNS) * _colW,
                            _y + _rowH * (1 + floor (_forEachIndex / APPLY_SKILL_COLUMNS)),
                            _colW, _rowH
                        ];
                        [_body, _cell, format ["%1  %2", ["[   ]", "[ X ]"] select _on, _sname], [_mute, _ink] select _on, TEXT_BODY, _on] call jmfsb_tacpad_fnc_drawText;
                        private _hit = [_body, _cell, {
                            params ["_ctrl"];
                            private _qid = _ctrl getVariable [QGVAR(qid), ""];
                            private _sid = _ctrl getVariable [QGVAR(sid), ""];
                            private _now = GVAR(applyAnswers) getOrDefault [_qid, []];
                            if !(_now isEqualType []) then {_now = []};
                            _now = [_now + [_sid], _now - [_sid]] select (_sid in _now);
                            GVAR(applyAnswers) set [_qid, _now];
                            {["pac"] call jmfsb_tacpad_fnc_openApp} call CBA_fnc_execNextFrame;
                        }] call jmfsb_tacpad_fnc_drawHit;
                        _hit setVariable [QGVAR(qid), _qid];
                        _hit setVariable [QGVAR(sid), _sid];
                    } forEach _choices;
                };
                case "select": {
                    private _c = _display ctrlCreate ["RscCombo", -1, _body];
                    _c ctrlSetPosition [_valX, _y, _valW, _rowH];
                    _c ctrlSetBackgroundColor [_ink # 0, _ink # 1, _ink # 2, 0.08];
                    _c ctrlSetTextColor _ink;
                    _c ctrlSetFontHeight (_rowH * 0.72);
                    private _opts = _q getOrDefault ["options", []];
                    if !(_opts isEqualType []) then {_opts = []};
                    _c lbAdd "-";
                    _c lbSetData [0, ""];
                    private _cur = GVAR(applyAnswers) getOrDefault [_qid, ""];
                    private _sel = 0;
                    {
                        private _o = if (_x isEqualType "") then {_x} else {str _x};
                        private _i = _c lbAdd _o;
                        _c lbSetData [_i, _o];
                        if (_o isEqualTo _cur) then {_sel = _i};
                    } forEach _opts;
                    _c lbSetCurSel _sel;
                    _c setVariable [QGVAR(qid), _qid];
                    _c ctrlAddEventHandler ["LBSelChanged", {
                        params ["_ctrl", "_i"];
                        GVAR(applyAnswers) set [_ctrl getVariable [QGVAR(qid), ""], _ctrl lbData _i];
                    }];
                    _c ctrlCommit 0;
                };
                default {
                    private _e = _display ctrlCreate [[_multi, "RscEdit"] select (_lines isEqualTo 1), -1, _body];
                    _e ctrlSetPosition [_valX, _y, _valW, _rowH * _lines];
                    _e ctrlSetBackgroundColor [_ink # 0, _ink # 1, _ink # 2, 0.08];
                    _e ctrlSetTextColor _ink;
                    _e ctrlSetFontHeight (_rowH * 0.72);
                    _e ctrlSetTooltip _help;
                    _e ctrlSetText (GVAR(applyAnswers) getOrDefault [_qid, ""]);
                    _e setVariable [QGVAR(qid), _qid];
                    _e ctrlAddEventHandler ["KeyUp", {
                        params ["_ctrl"];
                        GVAR(applyAnswers) set [_ctrl getVariable [QGVAR(qid), ""], ctrlText _ctrl];
                        false
                    }];
                    _e ctrlCommit 0;
                };
            };
            _y = _y + _rowH * _lines;
            if (_help isNotEqualTo "" && _type isNotEqualTo "textarea") then {
                [_body, [_valX, _y, _valW, _rowH * 0.8], _help, _dim, TEXT_LABEL, false] call jmfsb_tacpad_fnc_drawText;
                _y = _y + _rowH * 0.8;
            };
            _drawn = _drawn + 1;
        } forEach _questions;
        _y = _y + _padY;

        private _btn = ["SEND APPLICATION", "UPDATE MY APPLICATION"] select (_status isEqualTo "new");
        [_body, [_valX, _y, _w * 0.30, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.14]] call jmfsb_tacpad_fnc_drawFill;
        [_body, [_valX, _y, _w * 0.30, _rowH], _accent, RULE_THICK] call jmfsb_tacpad_fnc_drawFrame;
        [_body, [_valX, _y, _w * 0.30, _rowH], _btn, _ink, TEXT_TITLE, true, "center", true] call jmfsb_tacpad_fnc_drawText;
        [_body, [_valX, _y, _w * 0.30, _rowH], {
            [player, +GVAR(applyAnswers)] remoteExec [QFUNC(applySubmit), 2];
            ["TAC//PAC", "Sending your application ...", [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
        }] call jmfsb_tacpad_fnc_drawHit;
    };
};

nil
