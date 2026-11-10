#include "script_component.hpp"
/*
 * Author: YonV
 * Server: sets every player's public admin flag (QGVAR(isAdmin)) from the
 * server's own decision (FUNC(adminCheck)). The flag is for screens and
 * client-side gates only - who sees the console, the (ADMIN) chat tag. A client
 * can still set it on himself; no server check ever reads it (review S1).
 *
 * Arguments:
 * 0: Only this unit <OBJECT> (default: every player)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_common_fnc_adminFlags
 *
 * Public: No
 */

params [["_only", objNull, [objNull]]];

if (!isServer) exitWith {};

private _units = [[_only], allPlayers] select (isNull _only);
{
    private _is = [owner _x, getPlayerUID _x] call FUNC(adminCheck);
    if ((_x getVariable [QGVAR(isAdmin), false]) isNotEqualTo _is) then {
        _x setVariable [QGVAR(isAdmin), _is, true];
    };
} forEach (_units select {!isNull _x});
