#include "script_component.hpp"
/*
 * Author: JMSB
 * Repaints one TAC//SUPPORT cell for a pointer state - the fill and every
 * label on it. Called from the hover and press handlers FUNC(supportHover)
 * hangs; the cell's colours and its labels' text travel on the hit control.
 *
 * Labels are structured text with the colour inside the markup, so a repaint
 * is a re-set of the text, built the way EFUNC(tacpad,drawText) builds it.
 *
 * Arguments:
 * 0: The hit control, or a label claimed by it <CONTROL>
 * 1: State - "rest", "hover" or "press" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_hit, "hover"] call jmfsb_tacpad_apps_fnc_supportTint
 *
 * Public: No
 */

params [["_ctrl", controlNull, [controlNull]], ["_state", "rest", [""]]];

if (isNull _ctrl) exitWith {};

private _hit = _ctrl getVariable [QGVAR(tintHit), _ctrl];
(_hit getVariable [QGVAR(tint), []]) params [
    ["_fill", controlNull],
    ["_labels", []],
    ["_restFill", []],
    ["_hoverFill", []],
    ["_hoverText", []]
];
if (isNull _fill) exitWith {};

// PRESSED IS THE SAME EVERYWHERE: accent-600 under a ground-colour label.
private _ground = +(["ground"] call EFUNC(tacpad,theme));
_ground set [3, 1];

private _fillColour = switch (_state) do {
    case "hover": {_hoverFill};
    case "press": {["accentHover"] call EFUNC(tacpad,theme)};
    default {_restFill};
};
_fill ctrlSetBackgroundColor _fillColour;

{
    _x params ["_label", "_text", "_size", "_bold", "_align", "_restText"];
    if (isNull _label) then {continue};

    private _colour = switch (_state) do {
        case "hover": {[_hoverText, _restText] select (_hoverText isEqualTo [])};
        case "press": {_ground};
        default {_restText};
    };
    _label ctrlSetStructuredText parseText format [
        "<t font='%1' size='%2' align='%3' color='%4'>%5</t>",
        ["RobotoCondensed", "RobotoCondensedBold"] select _bold,
        _size,
        _align,
        _colour call BIS_fnc_colorRGBAtoHTML,
        _text
    ];
} forEach _labels;
