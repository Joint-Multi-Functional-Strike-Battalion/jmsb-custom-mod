#include "script_component.hpp"
/*
 * Author: JMSB
 * GO TO GRID: pans the map to a typed grid at the zoom it is at - CENTRE,
 * but on a grid rather than on the player. A grid the map cannot read
 * (FUNC(gridToPos)) moves nothing.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: Grid reference, 6 to 10 figures <STRING>
 *
 * Return Value:
 * The map moved <BOOL>
 *
 * Example:
 * [(findDisplay 12) displayCtrl 51, "043118"] call jmfsb_maptools_fnc_goTo
 *
 * Public: Yes
 */

params [["_map", controlNull, [controlNull]], ["_grid", "", [""]]];

if (isNull _map) exitWith {false};

private _pos = [trim _grid] call FUNC(gridToPos);
if (_pos isEqualTo []) exitWith {false};

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [CENTRE_ANIM, ctrlMapScale _map, _pos];
ctrlMapAnimCommit _map;

true
