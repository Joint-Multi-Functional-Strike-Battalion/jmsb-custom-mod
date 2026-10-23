#include "script_component.hpp"
/*
 * Author: JMSB
 * The composer under a NET conversation: quick phrases, and the way into the
 * full card.
 *
 * DELIBERATELY NOT THE THREAD COMPOSER. That one answers a thread - its quick
 * replies are the ones the thread's own template says are legal. This one
 * addresses a NET, so every phrase is free text rather than a template the
 * thread's state has to allow.
 *
 * A QUICK REPLY ANSWERS WHAT IS ON THE SCREEN (user, 2026-09-03: "quick replies
 * start new messages"). A net view is a conversation - the whole net in the
 * order it was said - so pressing ROGER under it means ROGER TO THAT, the way it
 * means it on a radio. It opened a new thread instead, which put a bare "ROGER"
 * on the net attached to nothing and left the message it was answering
 * unanswered.
 *
 * So the newest thread on the net comes in and the phrases reply into it. With
 * NOTHING on the net there is nothing to answer and a new thread is right - that
 * is the empty-stream call in FUNC(readerNetView), which passes "".
 *
 * Arguments:
 * 0: Pane geometry [x, w] <ARRAY>
 * 1: Y the composer starts at <NUMBER>
 * 2: Thread the quick phrases answer, "" to open a new one <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_geom", [0, 0], [[]], 2], ["_cy", 0, [0]], ["_replyTo", "", [""]]];

_geom params ["_dx", "_dw"];

// The same root the thread view uses - the reader's own content group, not a
// uiNamespace variable that nothing writes.
private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = ([TEXT_TITLE] call FUNC(textH)) + 2 * _padY;
private _mute = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

// WHICH BOX THIS TALKS TO. ALL is a view rather than a net, so it falls back to
// the first mailbox the mission named - FUNC(netBox) is that rule, shared with the
// compose pane and the reader's own stream lookup, so a message sent from any of
// them lands in the same place. A SQUAD'S NET IS A G: BOX: this said B:<name> for
// every net on the rail, so + MESSAGE under a squad conversation addressed a
// shared mailbox that does not exist.
private _box = [GVAR(readerNet), true] call FUNC(netBox);
private _net = _box select [2];

[_root, [_dx + _pad, _cy - _padY, _dw - 2 * _pad, RULE_THICK * pixelH], _ink] call FUNC(drawFill);

// SAY WHICH IT IS. A phrase that answers the conversation and a phrase that
// starts one are the same button, so the header is the only thing that can tell
// the player which he is about to do.
[
    _root, [_dx + _pad, _cy, _dw - 2 * _pad, _rowH],
    format [["SEND TO %1", "REPLY ON %1"] select (_replyTo isNotEqualTo ""), toUpper _net],
    _mute, TEXT_LABEL, true, "left", true
] call FUNC(drawText);
_cy = _cy + _rowH;

// The player's own phrases - see the quickReplies setting. Free text on a net,
// because there is no thread here for a reply template to move the state of.
// OUR OWN setting - the EGVAR(tacpad_apps,...) read was the wrong-component
// classic: nothing defines it, nil split threw, and everything from the
// quick-reply row down never drew under a net conversation.
private _quick = ((GVAR(quickReplies) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
private _perRow = 5;

if (_quick isEqualTo []) then {
    [_root, [_dx + _pad, _cy, _dw - 2 * _pad, _btnH], "NO QUICK REPLIES SET", _dim, TEXT_BODY, true] call FUNC(drawText);
} else {
    if (count _quick > _perRow) then {_quick = _quick select [0, _perRow]};
    private _qw = (_dw - 2 * _pad) / (count _quick);

    {
        private _qx = _dx + _pad + _forEachIndex * _qw;

        [_root, [_qx, _cy, _qw - _pad, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
        [_root, [_qx + _pad, _cy, _qw - 3 * _pad, _btnH], toUpper _x, _ink, TEXT_BODY, true, "center"] call FUNC(drawText);

        private _hit = [_root, [_qx, _cy, _qw - _pad, _btnH], {
            params ["_ctrl"];
            private _text = _ctrl getVariable [QGVAR(quickText), ""];
            if (_text isEqualTo "") exitWith {};

            private _key = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];

            // INTO THE CONVERSATION, when there is one. An addressee opens a
            // thread and a thread id continues one; passing both is how a reply
            // would be filed twice, so the addressee goes empty the moment
            // there is something to answer.
            private _into = _ctrl getVariable [QGVAR(quickThread), ""];
            private _to = [[_ctrl getVariable [QGVAR(quickBox), ""]], []] select (_into isNotEqualTo "");

            ["freetext", [[_key, _text]], _to, _into] call EFUNC(messaging,submit);
        }] call FUNC(drawHit);
        _hit setVariable [QGVAR(quickText), _x];
        _hit setVariable [QGVAR(quickBox), _box];
        _hit setVariable [QGVAR(quickThread), _replyTo];
    } forEach _quick;
};

_cy = _cy + _btnH + _padY;

// The full card, addressed to this net. Composing is a state of this pane - see
// FUNC(composePane) - so the conversation stays on screen behind it.
private _actW = _dw * 0.24;
[_root, [_dx + _pad, _cy, _actW, _btnH], _ink, RULE_THIN] call FUNC(drawFrame);
[_root, [_dx + _pad * 2, _cy, _actW - 3 * _pad, _btnH], "+ TEMPLATE", _ink, TEXT_BODY, true, "center"] call FUNC(drawText);

private _tmpl = [_root, [_dx + _pad, _cy, _actW, _btnH], {
    params ["_ctrl"];
    GVAR(composeTo) = _ctrl getVariable [QGVAR(quickBox), ""];
    ["", "", true] call FUNC(composeOpen);
}] call FUNC(drawHit);
_tmpl setVariable [QGVAR(quickBox), _box];

// And the plain message, which is what most traffic on a net actually is.
private _msgX = _dx + _pad * 2 + _actW;
[_root, [_msgX, _cy, _actW, _btnH], _accent, RULE_THICK] call FUNC(drawFrame);
[_root, [_msgX + _pad, _cy, _actW - 3 * _pad, _btnH], "+ MESSAGE", _accent, TEXT_BODY, true, "center"] call FUNC(drawText);

private _new = [_root, [_msgX, _cy, _actW, _btnH], {
    params ["_ctrl"];
    GVAR(composeTo) = _ctrl getVariable [QGVAR(quickBox), ""];
    ["", "", false] call FUNC(composeOpen);
}] call FUNC(drawHit);
_new setVariable [QGVAR(quickBox), _box];
