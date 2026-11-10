#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a secret an admin entered in game (FUNC(secretSet); code review R4,
 * 2026-10-31), from the server's own profile - never a CBA setting (every
 * setting reaches every player) and never published. "" when none was set;
 * the caller then falls back to the server's environment.
 *
 * Arguments:
 * 0: Name, one of SECRET_NAMES <STRING>
 *
 * Return Value:
 * The secret, or "" <STRING>
 *
 * Example:
 * ["livekitSecret"] call jmfsb_common_fnc_secret
 *
 * Public: Yes
 */

params [["_name", "", [""]]];

if (!isServer || {!(_name in SECRET_NAMES)}) exitWith {""};

private _value = profileNamespace getVariable [SECRET_PREFIX + _name, ""];
[_value, ""] select !(_value isEqualType "")
