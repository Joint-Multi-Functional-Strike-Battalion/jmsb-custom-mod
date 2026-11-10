#include "script_component.hpp"
/*
 * Author: Reeveli
 * Where an object sits in the point list, or -1 if it is not one. The server
 * reads its own list (localNamespace), a client the published copy (review S7).
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value:
 * Index <NUMBER>
 *
 * Example:
 * [_object] call jmfsb_teleport_fnc_listCheck
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

// -1, NOT false. Every caller compares this to -1, and a boolean there reads
// as "found at the front of the list" on a type-loose comparison.
if (isNull _object) exitWith {-1};

private _list = ([missionNamespace, localNamespace] select isServer) getVariable [QTP_LIST, []];
_list findIf {(_x # 0) isEqualTo _object}
