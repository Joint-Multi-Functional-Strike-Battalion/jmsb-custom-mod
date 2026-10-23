#include "script_component.hpp"
/*
 * Author: JMSB
 * SHOW ON MAP: closes the app and pans the map to the patient, keeping the
 * player's zoom. The patient stays selected and is flagged to be kept, so the
 * tile reopens on his page - unless someone else has since gone into arrest or
 * started bleeding heavily (FUNC(app)).
 *
 * The map is the host display's own - idc 51 on the vanilla map, or whatever
 * map control a device host carries.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_showOnMap
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {};

private _at = getPosATL _unit;
GVAR(keepPatient) = true;

[] call EFUNC(tacpad,appClose);

private _display = HOST_DISPLAY;
if (isNull _display) exitWith {};

private _map = _display displayCtrl MAP_IDC;
if (isNull _map) then {
    private _maps = (allControls _display) select {ctrlType _x isEqualTo MAP_CTRL_TYPE};
    _map = _maps param [0, controlNull];
};
if (isNull _map) exitWith {};

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [MAP_ANIM_TIME, ctrlMapScale _map, _at];
ctrlMapAnimCommit _map;
