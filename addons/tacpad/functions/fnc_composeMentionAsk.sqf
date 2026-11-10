#include "script_component.hpp"
/*
 * Author: YonV
 * The question an @ mention asks before it drops typed text (user,
 * 2026-11-01): the asset wants another card, and fields already filled have
 * no line on it.
 *
 *   HOG TAKES THE ON STATION CARD - 2 TYPED FIELDS ARE NOT ON IT  [SWITCH] [KEEP]
 *
 * SWITCH puts the composer on that card and lets them go
 * (FUNC(composeMentionSwitch)); KEEP stays on the card being written. The
 * asset stays addressed either way. Drawn under the CC line while
 * GVAR(composeMentionAsk) holds a card other than the one being written.
 *
 * Arguments:
 * 0: [x, width, top y] of the pane, in the content group's own coordinates <ARRAY>
 *
 * Return Value:
 * Bottom of the row <NUMBER>
 *
 * Example:
 * _y = [[_dx, _dw, _y]] call jmfsb_tacpad_fnc_composeMentionAsk
 *
 * Public: No
 */

params [["_pane", [0, 0, 0], [[]], 3]];

_pane params ["_dx", "_dw", "_top"];

GVAR(composeMentionAsk) params [["_card", "", [""]], ["_callsign", "", [""]], ["_lost", 0, [0]]];
if (_card isEqualTo "" || _card isEqualTo GVAR(composeTemplate)) exitWith {_top};

private _display = uiNamespace getVariable [QGVAR(reader), displayNull];
if (isNull _display) exitWith {_top};

private _root = (_display displayCtrl IDC_RD_ROOT) controlsGroupCtrl IDC_RD_CONTENT;
if (isNull _root) exitWith {_top};

([] call FUNC(theme)) params ["", "_ink", "_accent", "_line"];
private _muted = ["muted"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = ([TEXT_TITLE] call FUNC(textH)) + 2 * _padY;
private _btnW = _dw * MENTION_ASK_BTN_K;
private _keepX = _dx + _dw - _btnW - _pad;
private _switchX = _keepX - _btnW - _pad;

private _short = toUpper (([_card] call EFUNC(messaging,template)) getOrDefault ["short", _card]);
// A call sign is a name: untracked (tablet review 2026-11-01, 2.3).
[
    _root, [_dx + _pad, _top, _switchX - _dx - 2 * _pad, _btnH],
    format ["%1 TAKES THE %2 CARD - %3 TYPED %4 NOT ON IT", _callsign, _short, _lost, ["FIELDS ARE", "FIELD IS"] select (_lost isEqualTo 1)],
    _accent, TEXT_LABEL, false, "left", false
] call FUNC(drawText);

[_root, [_switchX, _top, _btnW, _btnH], _ink, RULE_THICK] call FUNC(drawFrame);
[_root, [_switchX + _pad, _top, _btnW - 2 * _pad, _btnH], "SWITCH", _ink, TEXT_BODY, true, "center"] call FUNC(drawText);
[_root, [_switchX, _top, _btnW, _btnH], {
    [] call FUNC(composeHarvest);
    [GVAR(composeMentionAsk) param [0, ""], true] call FUNC(composeMentionSwitch);
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);

[_root, [_keepX, _top, _btnW, _btnH], _line, RULE_THIN] call FUNC(drawFrame);
[_root, [_keepX + _pad, _top, _btnW - 2 * _pad, _btnH], "KEEP", _muted, TEXT_BODY, true, "center"] call FUNC(drawText);
[_root, [_keepX, _top, _btnW, _btnH], {
    [] call FUNC(composeHarvest);
    GVAR(composeMentionAsk) = [];
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);

_top + _btnH + _padY * 0.5
