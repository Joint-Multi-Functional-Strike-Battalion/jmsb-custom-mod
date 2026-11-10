#include "script_component.hpp"
/*
 * Author: YonV
 * SHOW ON MAP: closes the app and pans the map to the patient, keeping the
 * player's zoom. The patient stays selected and is flagged to be kept, so the
 * tile reopens on his page - unless someone else has since gone into arrest or
 * started bleeding heavily (FUNC(app)).
 *
 * The map is the host display's own - idc 51 on the vanilla map, or whatever
 * map control a device host carries.
 *
 * THE TEAM IS ON IT (user, 2026-11-01: "the medical app show on map should
 * have the team markers on it"). jmfsb_bft hangs its member icons on the
 * vanilla map only, so the tablet's map showed the casualty's ground and
 * nobody on it. The same draw - jmfsb_bft_fnc_drawMembers, under BFT's own
 * settings and GPS denial - is hung on this map once, flagged on the control
 * with BFT's own flag so the vanilla map never gets it twice. The map keeps
 * it while the control lives.
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

if (!isNil QEFUNC(bft,drawMembers) && {!(_map getVariable [QEGVAR(bft,memberDraw), false])}) then {
    _map setVariable [QEGVAR(bft,memberDraw), true];
    _map ctrlAddEventHandler ["Draw", {_this call EFUNC(bft,drawMembers)}];
};

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [MAP_ANIM_TIME, ctrlMapScale _map, _at];
ctrlMapAnimCommit _map;
