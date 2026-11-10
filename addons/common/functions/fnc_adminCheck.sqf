#include "script_component.hpp"
/*
 * Author: YonV
 * Server: whether a connected machine is an admin, from the server's own
 * records only (review S1/S2, R2). Never a flag or list a client can write:
 * - the server's own machine (the host);
 * - logged in as the server's admin (#login);
 * - its Steam id on the server's admin list, kept in localNamespace, which
 *   is not networked (FUNC(adminSource): the mod's list, TAC//PAC's admins,
 *   grants made in this mission);
 * - the Everyone is an admin testing switch, as the server read it once
 *   when its settings loaded (XEH_postInit).
 *
 * Arguments:
 * 0: Owner (machine id) <NUMBER>
 * 1: Steam id <STRING>
 *
 * Return Value:
 * Is an admin <BOOL>
 *
 * Example:
 * [owner _unit, getPlayerUID _unit] call jmfsb_common_fnc_adminCheck
 *
 * Public: No
 */

params [["_owner", 0, [0]], ["_uid", "", [""]]];

if (!isServer) exitWith {false};
if (_owner isEqualTo SERVER_OWNER) exitWith {true};
if (_owner > 0 && {(admin _owner) isEqualTo ADMIN_LOGGED_IN}) exitWith {true};
if (localNamespace getVariable [QGVAR(everyoneAdmin), false]) exitWith {true};

_uid isNotEqualTo "" && {_uid in (localNamespace getVariable [QGVAR(adminUids), createHashMap])}
