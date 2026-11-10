#include "script_component.hpp"
/*
 * Author: YonV
 * The watch panel on the tablets (decided 2026-11-07: the vehicle tablet shows
 * the overlay too): a tablet shell panel that exists while a profile is on
 * and draws FUNC(panelText) - the same header, slots and key hints as the
 * side device or phone. Builder and refresher both.
 *
 * Arguments:
 * 0: The panel's body <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body] call jmfsb_watch_fnc_panel
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]]];

if (isNull _body) exitWith {};
private _id = [] call FUNC(current);
private _ctrl = _body getVariable [QGVAR(panelCtrl), controlNull];
if (isNull _ctrl) then {
    _ctrl = (ctrlParent _body) ctrlCreate ["RscStructuredText", -1, _body];
    _body setVariable [QGVAR(panelCtrl), _ctrl];
};
(ctrlPosition _body) params ["", "", "_w", "_h"];
_ctrl ctrlSetPosition [0, 0, _w, _h];
_ctrl ctrlSetStructuredText parseText (if (_id isEqualTo "") then {""} else {([_id] call FUNC(panelText)) # 0});
_ctrl ctrlCommit 0;
