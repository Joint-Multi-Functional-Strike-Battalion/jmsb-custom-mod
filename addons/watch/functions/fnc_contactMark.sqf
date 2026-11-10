#include "script_component.hpp"
/*
 * Author: YonV
 * MAP: a permanent map marker at the contact's last known position, for
 * everyone - what it is and when it was marked.
 *
 * Arguments:
 * 0: The contact <OBJECT>
 * 1: Kind - "recon" or "threat" <STRING>
 *
 * Return Value:
 * Marker name <STRING>
 *
 * Example:
 * [_obj, "recon"] call jmfsb_watch_fnc_contactMark
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_kind", "recon", [""]]];

private _entry = GVAR(contactList) param [GVAR(contactList) findIf {(_x # 0) isEqualTo _obj}, []];
private _pos = ASLToAGL (_entry param [4, getPosASL _obj]);
private _name = format ["%1_%2_%3", QGVAR(mark), getPlayerUID player, round (CBA_missionTime * 10)];
createMarkerLocal [_name, _pos];
_name setMarkerTypeLocal MARKER_SEEN;
_name setMarkerColorLocal ([MARKER_RECON, MARKER_THREAT] select (_kind isEqualTo "threat"));
// local setters, then one global one: the marker goes to everyone once, whole
_name setMarkerText format ["%1 %2", [_obj, _kind] call FUNC(contactName), [dayTime, "HH:MM"] call BIS_fnc_timeToString];
_name
