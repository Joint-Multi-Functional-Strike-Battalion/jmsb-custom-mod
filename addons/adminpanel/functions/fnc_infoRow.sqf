#include "script_component.hpp"
/*
 * Author: YonV
 * One label-and-value row, the way the rest of the suite draws them.
 *
 * The panel wrote "Name: YonV" into a plain text control, which is one colour,
 * one weight and one alignment for two things that are not the same thing. The
 * design puts a muted kicker hard left and the value in full ink hard right, and
 * the whole reason a readout can be scanned rather than read is that the labels
 * fall away and the values line up.
 *
 * ONE FUNCTION so twelve rows across four blocks cannot drift, and so the two
 * colours come off the theme rather than out of a hex literal.
 *
 * Arguments:
 * 0: The control <CONTROL>
 * 1: Label <STRING>
 * 2: Value <STRING> - may carry its own <t> markup, e.g. the FPS colour
 * 3: Value in the accent rather than the ink <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ctrl, "SIDE", "WEST"] call jmfsb_adminpanel_fnc_infoRow
 *
 * Public: No
 */

params [["_ctrl", controlNull, [controlNull]], ["_label", "", [""]], ["_value", "", [""]], ["_hot", false, [false]]];

if (isNull _ctrl) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];

private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62] call BIS_fnc_colorRGBAtoHTML;
private _strong = ([_ink, _accent] select _hot) call BIS_fnc_colorRGBAtoHTML;

_ctrl ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensed' size='0.75' color='%1'>%2</t><t font='RobotoCondensedBold' size='0.85' align='right' color='%3'>%4</t>",
    _mute,
    toUpper ([_label] call EFUNC(tacpad,xmlSafe)),
    _strong,
    _value
];
