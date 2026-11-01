#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: sets one source of the server's admin list - the mod's list, TAC//PAC's
 * admins, the grants made in this mission - and rebuilds the list (review S1/S2,
 * R2). The list lives in localNamespace, which is not networked, so no client can
 * write it. Clients get a copy for their screens only (QGVAR(adminList)); the
 * server never reads that copy back. Every player's admin flag is set again from
 * it, and QGVAR(adminsChanged) is raised on the server.
 *
 * Arguments:
 * 0: Source <STRING>
 * 1: Steam ids <ARRAY of STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["pac", keys _admins] call jmfsb_common_fnc_adminSource
 *
 * Public: Yes
 */

params [["_source", "", [""]], ["_uids", [], [[]]]];

if (!isServer || _source isEqualTo "") exitWith {};

private _sources = localNamespace getVariable [QGVAR(adminSources), createHashMap];
_sources set [_source, _uids select {_x isEqualType "" && _x isNotEqualTo ""}];
localNamespace setVariable [QGVAR(adminSources), _sources];

private _all = createHashMap;
{
    {_all set [_x, true]} forEach _y;
} forEach _sources;
localNamespace setVariable [QGVAR(adminUids), _all];

GVAR(adminList) = keys _all;
publicVariable QGVAR(adminList);

[] call FUNC(adminFlags);
[QGVAR(adminsChanged), []] call CBA_fnc_localEvent;
