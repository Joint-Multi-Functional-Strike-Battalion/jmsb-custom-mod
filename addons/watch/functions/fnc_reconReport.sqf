#include "script_component.hpp"
/*
 * Author: YonV
 * The recon profile's REPORT: the unit's SALUTE card (its spot report) on the
 * tablet, filled from the contact - size, last known grid, type, equipment.
 * Activity and remarks are the spotter's; sending is his press.
 *
 * Arguments:
 * 0: The contact <OBJECT>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [_obj] call jmfsb_watch_fnc_reconReport
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj || {isNil QEFUNC(tacpad,composeOpen)}) exitWith {false};

private _entry = GVAR(contactList) param [GVAR(contactList) findIf {(_x # 0) isEqualTo _obj}, []];
private _pos = ASLToAGL (_entry param [4, getPosASL _obj]);
private _man = _obj isKindOf "CAManBase";
private _weapon = getText (configFile >> "CfgWeapons" >> primaryWeapon _obj >> "displayName");
_obj setVariable [QGVAR(reportedAt), serverTime];

["", SPOTREP_TEMPLATE, false, "", [
    ["S.A", [format ["%1 vehicle, %2 crew", 1, count crew _obj], "1 man"] select _man],
    ["L.A", mapGridPosition _pos],
    ["U.A", [_obj, "recon"] call FUNC(contactName)],
    ["E.A", [[_obj, "recon"] call FUNC(contactName), _weapon] select _man]
]] call EFUNC(tacpad,composeOpen)
