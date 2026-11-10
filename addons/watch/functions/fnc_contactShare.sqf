#include "script_component.hpp"
/*
 * Author: YonV
 * SHARE (decided 2026-11-07): a contact nobody has in sight is pushed to every
 * friendly within SHARE_RANGE for the share time (server setting), as a
 * dashed box and a map track. Server only.
 *
 * Arguments:
 * 0: The contact <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_obj] call jmfsb_watch_fnc_contactShare
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (!isServer) exitWith {};
private _entry = GVAR(contacts) getOrDefault [hashValue _obj, []];
if (_entry isEqualTo []) exitWith {};
_entry set [7, serverTime + GVAR(shareSeconds)];
