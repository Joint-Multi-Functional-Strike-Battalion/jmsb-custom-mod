#include "script_component.hpp"
/*
 * Author: YonV
 * A contact for the shared visibility system (recon contacts, engineer
 * threats): the server keeps one entry per object with the players watching
 * it. Server only, raised by the spotter's machine. Re-adding adds a watcher.
 *
 *     entry: [object, kind, side, spotter group, last known ASL, last seen,
 *             LOS now, shared until, watchers]
 *
 * Arguments:
 * 0: The contact <OBJECT>
 * 1: Kind - "recon" or "threat" <STRING>
 * 2: The spotter <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_obj, "recon", player] call jmfsb_watch_fnc_contactAdd
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_kind", "recon", [""]], ["_spotter", objNull, [objNull]]];

if (!isServer || {isNull _obj} || {isNull _spotter}) exitWith {};

private _entry = GVAR(contacts) getOrDefault [hashValue _obj, []];
if (_entry isEqualTo []) then {
    _entry = [_obj, _kind, side group _spotter, group _spotter, getPosASL _obj, serverTime, true, -1, []];
    GVAR(contacts) set [hashValue _obj, _entry];
};
(_entry # 8) pushBackUnique _spotter;
