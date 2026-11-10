#include "script_component.hpp"
/*
 * Author: YonV
 * The TO picker's SUPPORT group (user, 2026-11-01: "make the cas units
 * selectable as message receivers"; docs/DESIGN_SUPPORT_MESSAGING.md 6.1):
 * a heading, then one row per asset - call sign, then type, state and ETA
 * (FUNC(composeToSupportLine)). Pressing a row addresses the message to the
 * asset's own mailbox, "B:SUPPORT:<assetId>" - the box the server answers as
 * the asset (support README, "Threads") - like pressing a man addresses him.
 *
 * A ROW THAT CANNOT TAKE A TASK IS STILL PRESSABLE. It is dim and says why;
 * whether it takes the request is the asset's answer in the thread, not the
 * picker's.
 *
 * LIVE IN PLACE (code review R8). The group stores its rows' lines
 * (FUNC(liveStore)) and arms the two-second poll (FUNC(composeToSupportTick)),
 * which rewrites state and ETA in those lines - a scrolled list stays where
 * the player scrolled it, and a press is never lost to the refresh.
 *
 * Arguments:
 * 0: The picker's scrolling body <CONTROL>
 * 1: Top of the group, in the body's coordinates <NUMBER>
 * 2: Row width <NUMBER>
 * 3: The card being written goes to support <BOOL>
 * 4: Rows, as FUNC(composeToSupport) gives them <ARRAY>
 *
 * Return Value:
 * Bottom of the group <NUMBER>
 *
 * Example:
 * _y = [_body, _y, _listW, false, _rows] call jmfsb_tacpad_fnc_composeToSupportDraw
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_top", 0, [0]],
    ["_listW", 0, [0]],
    ["_forCard", false, [false]],
    ["_rows", [], [[]]]
];

if (isNull _body) exitWith {_top};

([] call FUNC(theme)) params ["", "", "_accent", "_line"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _valueSize = TO_VALUE_SIZE;
private _nameSize = TEXT_TITLE max _valueSize;
private _nameW = _listW * TO_SUPPORT_NAME_W;

// The heading: a short label, tracked; the count is a value, and is not.
private _y = _top;
[_body, [_pad, _y, _nameW, _rowH], "SUPPORT", _muted, TEXT_LABEL, true, "left", true] call FUNC(drawText);
private _count = count _rows;
[
    _body, [_nameW, _y, _listW - _nameW - _pad, _rowH],
    format ["%1 %2", _count, ["ASSETS", "ASSET"] select (_count isEqualTo 1)],
    _muted, _valueSize, false, "right"
] call FUNC(drawText);
_y = _y + _rowH;
[_body, [0, _y - RULE_THICK * pixelH, _listW, RULE_THICK * pixelH], _line] call FUNC(drawFill);

if (_rows isEqualTo []) then {
    [_body, [_pad, _y, _listW - 2 * _pad, _rowH], "NO SUPPORT ASSETS ON YOUR SIDE", _dim, TEXT_BODY] call FUNC(drawText);
    _y = _y + _rowH;
};

private _entries = [];
{
    private _id = _x select 0;
    private _on = GVAR(composeTo) isEqualTo _id;

    if (_on) then {
        [_body, [0, _y, _listW, _rowH], _accent] call FUNC(drawFill);
    };

    ([_x, _on] call FUNC(composeToSupportLine)) params ["_name", "_meta"];
    // A call sign and a state line are a name and values: untracked
    // (tablet review 2026-11-01, 2.3).
    private _nameCtrl = [_body, [_pad, _y, _nameW - _pad, _rowH], _name select 0, _name select 1, _nameSize, _on, "left", false] call FUNC(drawText);
    private _metaCtrl = [_body, [_nameW, _y, _listW - _nameW - _pad, _rowH], _meta select 0, _meta select 1, _valueSize, false, "right", false] call FUNC(drawText);
    _entries pushBack [[_nameCtrl], [_nameSize, _on, "left", false, ""]];
    _entries pushBack [[_metaCtrl], [_valueSize, false, "right", false, ""]];

    [_body, [0, _y + _rowH - RULE_THIN * pixelH, _listW, RULE_THIN * pixelH], _line] call FUNC(drawFill);

    private _hit = [_body, [0, _y, _listW, _rowH], {
        params ["_ctrl"];

        // Harvest first, like every other press on this pane: the redraw
        // rebuilds the content group whole and takes every edit with it.
        [] call FUNC(composeHarvest);

        GVAR(composeTo) = _ctrl getVariable [QGVAR(toBox), ""];
        GVAR(composeToPick) = false;
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);
    _hit setVariable [QGVAR(toBox), _id];

    _y = _y + _rowH;
} forEach _rows;

// THE SHAPE IS WHAT THE POLL MAY NOT CHANGE IN PLACE: which rows, in which
// order, which one is the address, and whether the card leads with them.
[_body, [_forCard, _rows apply {_x select 0}, GVAR(composeTo)], _entries] call FUNC(liveStore);
uiNamespace setVariable [QGVAR(toSupportBody), _body];
[true] call FUNC(composeToSupportTick);

_y
