#include "script_component.hpp"
/*
 * Author: YonV
 * Server, by remoteExec from the admin console's SECRETS dialog: stores (or,
 * with "", clears) one secret in the server's own profile (code review R4,
 * 2026-10-31). The sender must be the logged-in admin (#login) or the host -
 * the same bar as GRANT ADMIN. The value travels from his machine to the
 * server only, is never published, and is never echoed back: the answer is
 * the status list (FUNC(secretStatus)), SET or NOT SET and the last four
 * characters.
 *
 * Arguments:
 * 0: Name, one of SECRET_NAMES <STRING>
 * 1: Value, "" to clear <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["livekitSecret", _typed] remoteExecCall ["jmfsb_common_fnc_secretSet", 2]
 *
 * Public: No
 */

params [["_name", "", [""]], ["_value", "", [""]]];

if (!isServer) exitWith {};
([] call FUNC(sender)) params ["_owner", "_admin"];
if (_owner isNotEqualTo SERVER_OWNER && {(admin _owner) isNotEqualTo ADMIN_LOGGED_IN}) exitWith {
    WARNING_1("secretSet refused: machine %1 is not the logged-in admin",_owner);
};
if !(_name in SECRET_NAMES) exitWith {};

_value = trim _value;
profileNamespace setVariable [SECRET_PREFIX + _name, _value];
saveProfileNamespace;
private _did = ["set", "cleared"] select (_value isEqualTo "");
INFO_3("secret %1 %2 by %3",_name,_did,name _admin);

[] call FUNC(secretStatus);
