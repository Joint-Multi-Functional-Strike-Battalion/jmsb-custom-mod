#include "script_component.hpp"
/*
 * Author: YonV
 * A player stops watching a contact; with nobody left watching, the server
 * forgets it. Server only.
 *
 * Arguments:
 * 0: The contact <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_obj, player] call jmfsb_watch_fnc_contactDrop
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_who", objNull, [objNull]]];

if (!isServer) exitWith {};

private _entry = GVAR(contacts) getOrDefault [hashValue _obj, []];
if (_entry isEqualTo []) exitWith {};
private _watchers = (_entry # 8) - [_who];
_entry set [8, _watchers];
if (_watchers isEqualTo []) then {GVAR(contacts) deleteAt (hashValue _obj)};
