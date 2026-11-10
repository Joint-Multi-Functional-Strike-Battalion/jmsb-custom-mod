#include "script_component.hpp"
/*
 * Author: YonV
 * The composer under a NET conversation: the quick phrases that answer the
 * newest thread on it.
 *
 * A QUICK REPLY ANSWERS WHAT IS ON THE SCREEN (user, 2026-09-03: "quick replies
 * start new messages"). A net view is a conversation - the whole net in the
 * order it was said - so pressing ROGER under it means ROGER TO THAT, the way it
 * means it on a radio. It opened a new thread instead, which put a bare "ROGER"
 * on the net attached to nothing and left the message it was answering
 * unanswered.
 *
 * ONLY WHAT THAT THREAD TAKES, AND ONLY WHEN THERE IS ONE (tablet review
 * 2026-11-01, 3.1). The phrases are the thread composer's rule
 * (FUNC(readerQuick)): an entry naming a reply template is that template and
 * is drawn only when the thread will take it; any other entry is free text,
 * drawn only when the thread takes free text. FUNC(readerNetView) draws no
 * composer under ALL (no send target) or on a net with nothing to answer, and
 * + TEMPLATE / + MESSAGE are gone from here: NEW at the top of the list starts
 * a message, + TEMPLATE lives under an opened thread.
 *
 * Arguments:
 * 0: Pane geometry [x, w] <ARRAY>
 * 1: Y the composer starts at <NUMBER>
 * 2: Thread the quick phrases answer <STRING>
 * 3: Reply template ids that thread will take now <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_dx, _dw], _floor, _replyTo, _legal] call jmfsb_tacpad_fnc_readerComposer
 *
 * Public: No
 */

params [["_geom", [0, 0], [[]], 2], ["_cy", 0, [0]], ["_replyTo", "", [""]], ["_legal", [], [[]]]];

_geom params ["_dx", "_dw"];

if (_replyTo isEqualTo "") exitWith {};

// The same root the thread view uses - the reader's own content group, not a
// uiNamespace variable that nothing writes.
private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

([] call FUNC(theme)) params ["", "_ink"];

private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = ([TEXT_TITLE] call FUNC(textH)) + 2 * _padY;
private _mute = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

// WHICH NET THIS ANSWERS ON - FUNC(netBox) is the rule, shared with the compose
// pane and the reader's own stream lookup. A SQUAD'S NET IS A G: BOX.
private _net = ([GVAR(readerNet), true] call FUNC(netBox)) select [2];

[_root, [_dx + _pad, _cy - _padY, _dw - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);
[
    _root, [_dx + _pad, _cy, _dw - 2 * _pad, _rowH],
    format ["REPLY ON %1", toUpper _net],
    _mute, TEXT_LABEL, true
] call FUNC(drawText);
_cy = _cy + _rowH;

// The player's own phrases - see the quickReplies setting - as [template id or
// "", words]: a template id the thread takes, else free text where it takes it.
private _free = "freetext" in _legal;
private _known = missionNamespace getVariable [QEGVAR(messaging,templateIds), []];
private _quick = [];
{
    private _entry = trim _x;
    private _id = toLower _entry;
    if (_entry isEqualTo "") then {continue};
    if (_id in _known) then {
        if (_id in _legal) then {_quick pushBack [_id, _entry]};
        continue;
    };
    if (_free) then {_quick pushBack ["", _entry]};
} forEach (GVAR(quickReplies) splitString ",");
private _perRow = 5;

if (_quick isEqualTo []) exitWith {
    [_root, [_dx + _pad, _cy, _dw - 2 * _pad, _btnH], "No quick reply fits this thread", _dim, TEXT_BODY] call FUNC(drawText);
};

if (count _quick > _perRow) then {_quick = _quick select [0, _perRow]};
private _qw = (_dw - 2 * _pad) / (count _quick);
private _freeKey = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];

{
    _x params ["_id", "_words"];
    private _qx = _dx + _pad + _forEachIndex * _qw;

    [_root, [_qx, _cy, _qw - _pad, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
    [_root, [_qx + _pad, _cy, _qw - 3 * _pad, _btnH], toUpper _words, _ink, TEXT_BODY, true, "center"] call FUNC(drawText);

    private _hit = [_root, [_qx, _cy, _qw - _pad, _btnH], {
        params ["_ctrl"];
        private _into = _ctrl getVariable [QGVAR(quickThread), ""];
        if (_into isEqualTo "") exitWith {};

        // A template id is the template, so the thread's state still moves;
        // a phrase is a free-text reply carrying the words on the tile.
        private _id = _ctrl getVariable [QGVAR(quickId), ""];
        if (_id isEqualTo "") then {
            ["freetext", [[_ctrl getVariable [QGVAR(quickKey), ""], _ctrl getVariable [QGVAR(quickText), ""]]], [], _into] call EFUNC(messaging,submit);
        } else {
            [_id, [], [], _into] call EFUNC(messaging,submit);
        };
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(quickId), _id];
    _hit setVariable [QGVAR(quickText), _words];
    _hit setVariable [QGVAR(quickKey), _freeKey];
    _hit setVariable [QGVAR(quickThread), _replyTo];
} forEach _quick;
