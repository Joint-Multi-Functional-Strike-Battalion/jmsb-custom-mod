#include "script_component.hpp"
/*
 * Author: YonV
 * A contact's short name: its class's display name, or what it is when that
 * is empty.
 *
 * Arguments:
 * 0: The contact <OBJECT>
 * 1: Kind - "recon" or "threat" <STRING>
 *
 * Return Value:
 * Name <STRING>
 *
 * Example:
 * [_obj, "recon"] call jmfsb_watch_fnc_contactName
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_kind", "recon", [""]]];

if (isNull _obj) exitWith {["CONTACT", "THREAT"] select (_kind isEqualTo "threat")};
private _name = getText (configOf _obj >> "displayName");
if (_name isEqualTo "") then {_name = ["CONTACT", "THREAT"] select (_kind isEqualTo "threat")};
_name
