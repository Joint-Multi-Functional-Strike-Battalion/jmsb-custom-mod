#include "script_component.hpp"
/*
 * Author: JMSB
 * Writes a panel's header readout - the right-aligned line the design puts
 * opposite every title. "13 / 16" on the squad rail, "3 NETS MONITORED" on the
 * reader.
 *
 * It belongs to the frame rather than to the body, so a panel redrawing its
 * content does not have to redraw its own title bar - and so the readout cannot
 * scroll away with the content underneath it.
 *
 * Arguments:
 * 0: Panel id <STRING>
 * 1: Text, "" to clear <STRING>
 * 2: Draw it in the accent <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["squad", "13 / 16"] call jmfsb_tacpad_fnc_headerMeta
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_text", "", [""]], ["_alert", false, [false]]];

private _entry = GVAR(open) getOrDefault [_id, []];
if (_entry isEqualTo []) exitWith {};
_entry params ["_group"];
if (isNull _group) exitWith {};

private _panel = GVAR(panels) get _id;
if (isNil "_panel") exitWith {};

private _meta = _group controlsGroupCtrl IDC_META(_panel get "slot");
if (isNull _meta) exitWith {};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _color = [[_ink # 0, _ink # 1, _ink # 2, 0.62], _accent] select _alert;

_meta ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='0.7' align='right' color='%1'>%2</t>",
    _color call BIS_fnc_colorRGBAtoHTML,
    [toUpper _text] call FUNC(xmlSafe)
];
_meta ctrlCommit 0;
