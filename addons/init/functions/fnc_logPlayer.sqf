#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A -- Tinkered with by YonV
 * Server: a player connected - his entry in the connection log the
 * attendance list is read from (jmfsb_systems_fnc_getAttendance).
 *
 * Called by the server's own PlayerConnected handler only (review R1). It was
 * the "jmfsb_log_player" CBA event, so any client could write any name under
 * any Steam id into the attendance. Local calls only: a remote-executed call
 * is dropped.
 *
 * Arguments:
 * 0: Steam id <STRING>
 * 1: Name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_uid, _name] call jmfsb_init_fnc_logPlayer
 *
 * Public: No
 */

params [["_guid", "", [""]], ["_name", "", [""]]];

if (!isServer || isRemoteExecuted || _guid isEqualTo "") exitWith {};

private _unit = [_guid] call BIS_fnc_getUnitByUID;
private _playerLog = missionNamespace getVariable [QEGVAR(log,players), createHashMap];
INFO_3("PlayerLog","Connected %1 [%2] (GUID: %3)",_name,_unit,_guid);

// HOISTED. This was computed inside the "existing entry" branch and read
// inside the "new entry" one, so every player logging in for the first time
// got a nil loadout written to their record.
private _loadout = [_unit getVariable [QEGVAR(Gear,LoadoutClass), typeOf _unit], "Trooper"] select (isNull _unit);

if (!isNil {_playerLog get _guid}) then {
    INFO_1("PlayerLog","Updating Log Entry [%1]",isNil {_playerLog get _guid});
    private _data = _playerLog get _guid;

    private _connections = _data get "connections";
    _connections pushBack systemTimeUTC;
    _data set ["connections", _connections];

    _data set ["loadout", _loadout];

    _playerLog set [_guid, _data];
} else {
    INFO_1("PlayerLog","Creating Log Entry [%1]",isNil {_playerLog get _guid});
    private _entry = createHashMapFromArray [
        ["name", _name],
        ["loadout", _loadout],
        ["connectTime", systemTimeUTC],
        ["connections", [systemTimeUTC]]
    ];
    _playerLog set [_guid, _entry];
};
missionNamespace setVariable [QEGVAR(log,players), _playerLog];
