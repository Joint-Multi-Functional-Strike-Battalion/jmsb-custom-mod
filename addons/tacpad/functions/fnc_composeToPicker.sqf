#include "script_component.hpp"
/*
 * Author: YonV
 * The addressee picker, drawn into the compose pane: every net, squad and man
 * this message can be sent to, one per row - and the support assets, in a
 * SUPPORT group of their own (2026-11-01, FUNC(composeToSupportDraw)).
 *
 * THE RAIL IS THE SELECTOR, THIS IS THE REST. Pressing a net on the left rail
 * retargets an open message - see the rail handler in FUNC(readerDraw) - and that
 * is how a net is chosen, which is what the rail is already a list of. It cannot
 * offer a PERSON, though, and it cannot offer a net this player is not currently
 * reading, so CHANGE opens the full set here rather than putting fourteen chips
 * back across the top of the pane.
 *
 * ONE ADDRESSEE. A press replaces the address rather than adding to it, because
 * "who is this for" has one answer and everybody else on it is a CC - which is
 * the row directly under the TO line.
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

[
    _root, [_dx + _pad, _top, _dw - 2 * _pad, _rowH],
    "SEND TO - PRESS ONE. EVERYBODY ELSE GOES ON THE CC LINE.",
    _mute, TEXT_LABEL, true, "left", true
] call FUNC(drawText);

private _bodyTop = _top + _rowH;

// The list scrolls: a platoon is thirty men and a picker that only shows what
// fits is a picker that hides most of them.
private _bodyW = _dw - 2 * _pad;
private _bodyH = _h - _bodyTop - _padY * 2;

private _body = _display ctrlCreate [QGVAR(body), -1, _root];
_body ctrlSetPosition [_dx + _pad, _bodyTop, _bodyW, _bodyH];
_body ctrlSetBackgroundColor [0, 0, 0, 0];
_body ctrlCommit 0;

// The scrollbar owns the right edge of a scrolling group, so the rows stop short
// of it rather than running under it.
private _scrollW = 14 * pixelW;
private _listW = _bodyW - _scrollW - _pad;

private _targets = [] call FUNC(composeTargets);

// THE SUPPORT ASSETS, IN THEIR OWN GROUP (user, 2026-11-01: "make the cas units
// selectable as message receivers"; docs/DESIGN_SUPPORT_MESSAGING.md 6.1) -
// under the nets, squads and men, for a man the Support tasking tag lets task
// them. A card that goes to support - `cas` - opens the picker on that group,
// narrowed to its type, so it comes first. See FUNC(composeToSupport).
([] call FUNC(composeToSupport)) params ["_supShow", "_supFirst", "_supRows"];

if (_targets isEqualTo [] && !_supShow) exitWith {
    [_body, [0, 0, _listW, _rowH], "NOTHING TO ADDRESS - NO NETS AND NOBODY ON", _dim, TEXT_TITLE] call FUNC(drawText);
};

private _ry = 0;
if (_supShow && _supFirst) then {
    _ry = [_body, _ry, _listW, true, _supRows] call FUNC(composeToSupportDraw);
    [_body, [0, _ry, _listW, RULE_THICK * pixelH], _line] call FUNC(drawFill);
    _ry = _ry + _rowH * 0.5;
};

{
    _x params ["_id", "_label"];

    private _on = GVAR(composeTo) isEqualTo _id;

    if (_on) then {
        [_body, [0, _ry, _listW, _rowH], _accent] call FUNC(drawFill);
    };

    // NET, SQUAD or MAN. Two of them can carry the same word - a squad called HQ
    // and a mailbox called HQ are different rows and different tablets.
    private _kind = switch (_id select [0, 2]) do {
        case "G:": {"SQUAD"};
        case "P:": {"MAN"};
        default {"NET"};
    };

    [_body, [_pad, _ry, _listW * 0.68, _rowH], _label, ([_ink, _ground] select _on), TEXT_TITLE, _on] call FUNC(drawText);
    [_body, [_listW * 0.7, _ry, _listW * 0.3 - _pad, _rowH], _kind, ([_mute, _ground] select _on), TEXT_LABEL, true, "right", true] call FUNC(drawText);
    [_body, [0, _ry + _rowH - RULE_THIN * pixelH, _listW, RULE_THIN * pixelH], _line] call FUNC(drawFill);

    private _hit = [_body, [0, _ry, _listW, _rowH], {
        params ["_ctrl"];

        // Harvest first, like every other press on this pane: the redraw below
        // rebuilds the content group whole and takes every edit with it.
        [] call FUNC(composeHarvest);

        GVAR(composeTo) = _ctrl getVariable [QGVAR(toBox), ""];
        GVAR(composeToPick) = false;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(toBox), _id];
    _ry = _ry + _rowH;
} forEach _targets;

if (_supShow && !_supFirst) then {
    _ry = _ry + _rowH * 0.5;
    [_body, _ry, _listW, false, _supRows] call FUNC(composeToSupportDraw);
};
