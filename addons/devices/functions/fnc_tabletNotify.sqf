#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet's notification line: how many notifications have come in since
 * the log was last opened, the newest one, and its time. Clicking it opens the
 * reader's LOG view (FUNC(tabletLog)).
 *
 * A MIRROR, NOT A ROUTE (user, 2026-10-18). The popups stay upper right in
 * every display mode; this line shows the newest entry of the notify addon's
 * own history - the same thing that just popped up - and nothing else.
 *
 * DRAWN AS THE DESIGN DRAWS IT (art/images/tablet_screen.png): the unseen
 * count is a solid accent cell with the number in it, nothing while there is
 * nothing new; the newest entry's title in the accent, its text in ink.
 *
 * Redrawn only when the history or the unseen count has changed, so the
 * button under it is not pulled out from under a press.
 *
 * Arguments:
 * 0: The line's body <CONTROL>
 * 1: The rows' last drawn keys <HASHMAP>
 *
 * Return Value:
 * Redrawn <BOOL>
 *
 * Example:
 * [_body, _keys] call jmfsb_devices_fnc_tabletNotify
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_keys", createHashMap, [createHashMap]]];
if (isNull _body) exitWith {false};

private _history = missionNamespace getVariable [QEGVAR(notify,history), []];
if !(_history isEqualType []) then {_history = []};
private _unseen = {(_x param [3, 0]) > GVAR(notifySeen)} count _history;
private _newest = _history param [count _history - 1, []];

private _key = str [count _history, _newest, _unseen];
if (_key isEqualTo (_keys getOrDefault ["notify", ""])) exitWith {false};
_keys set ["notify", _key];

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = _w * TABLET_GAP / TABLET_DESIGN_W;
private _countW = _w * TABLET_NOTIFY_COUNT_W;
private _timeW = _w * TABLET_NOTIFY_TIME_W;
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _ground = +(["ground"] call EFUNC(tacpad,theme));
_ground set [3, 1];

// The count: the row's left edge, flush, as the design's red block is.
if (_unseen > 0) then {
    [_body, [0, 0, _countW, _h], ["accent"] call EFUNC(tacpad,theme)] call EFUNC(tacpad,drawFill);
    [_body, [0, 0, _countW, _h], str _unseen, _ground, TABLET_TEXT_NOTIFY, true, "center"] call EFUNC(tacpad,drawText);
};

private _lineRect = [_countW + _pad, 0, _w - _countW - _timeW - 3 * _pad, _h];
private _when = "";
if (_newest isEqualTo []) then {
    [_body, _lineRect, "NO TRAFFIC", _muted, TABLET_TEXT_NOTIFY] call EFUNC(tacpad,drawText);
} else {
    _newest params [["_title", "", [""]], ["_text", "", [""]], "", ["_time", 0, [0]]];
    // drawText sizes and centres the line; the two colours are structured
    // text, set on it once it is placed.
    private _ctrl = [_body, _lineRect, "", _ink, TABLET_TEXT_NOTIFY] call EFUNC(tacpad,drawText);
    _ctrl ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensedBold' size='%1' color='%2'>%3</t>   <t font='RobotoCondensed' size='%1' color='%4'>%5</t>",
        TABLET_TEXT_NOTIFY,
        (["accentText"] call EFUNC(tacpad,theme)) call BIS_fnc_colorRGBAtoHTML,
        [toUpper _title] call EFUNC(tacpad,xmlSafe),
        _ink call BIS_fnc_colorRGBAtoHTML,
        [_text] call EFUNC(tacpad,xmlSafe)
    ];
    // The history is stamped with `time`, which starts at zero on a client
    // that joined late; the clock wants CBA_missionTime. The age carries over.
    _when = [CBA_missionTime - (time - _time)] call EFUNC(tacpad,clock);
};
[_body, [_w - _timeW - _pad, 0, _timeW, _h], _when, _muted, TABLET_TEXT_NOTIFY, false, "right"] call EFUNC(tacpad,drawText);

[_body, [0, 0, _w, _h], {[] call FUNC(tabletLog)}] call EFUNC(tacpad,drawHit);

true
