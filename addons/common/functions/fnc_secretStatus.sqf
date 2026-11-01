#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, by remoteExec from the SECRETS dialog (and after FUNC(secretSet)):
 * sends the sender, if he is the logged-in admin or the host, which secrets
 * are set - [name, set, last four characters] each, never the value - to his
 * dialog (jmfsb_adminpanel_fnc_secretsShow), by remoteExec (review R4).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_common_fnc_secretStatus", 2]
 *
 * Public: No
 */

if (!isServer) exitWith {};
([] call FUNC(sender)) params ["_owner"];
if (_owner isNotEqualTo SERVER_OWNER && {(admin _owner) isNotEqualTo ADMIN_LOGGED_IN}) exitWith {};

private _rows = SECRET_NAMES apply {
    private _v = [_x] call FUNC(secret);
    private _n = count _v;
    [_x, _n > 0, [_v select [(_n - SECRET_SHOWN) max 0], ""] select (_n <= SECRET_SHOWN)]
};
[_rows] remoteExecCall ["jmfsb_adminpanel_fnc_secretsShow", _owner];
