#include "script_component.hpp"
/*
 * Author: JMSB
 * SHOW ON MAP from the ES tab: closes the app and pans the host's map to a
 * track's fix (or the sensor end of its latest DF line), keeping the zoom -
 * the medic app's SHOW ON MAP, on the vanilla map or the device host alike.
 *
 * Arguments:
 * 0: Position [x, y] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[4500, 5200]] call jmfsb_ew_fnc_showOnMap
 *
 * Public: No
 */

params [["_at", [], [[]]]];

if (count _at < 2) exitWith {};

[] call EFUNC(tacpad,appClose);

private _display = HOST_DISPLAY;
if (isNull _display) exitWith {};
private _map = _display displayCtrl IDC_HOST_MAP;
if (isNull _map) then {
    _map = ((allControls _display) select {ctrlType _x isEqualTo MAP_CTRL_TYPE}) param [0, controlNull];
};
if (isNull _map) exitWith {};

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [MAP_ANIM_TIME, ctrlMapScale _map, [_at select 0, _at select 1, 0]];
ctrlMapAnimCommit _map;
