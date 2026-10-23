#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, on the targeted event jmfsb_adapter_tfar_keyed: another player keyed
 * or released one of his TFAR sets on a net (sent by him, fnc_tangent). Kept
 * until his key-up, death or respawn (fnc_talking reads it).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Net id <STRING>
 * 2: Key down <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "ALPHA", true] call jmfsb_adapter_tfar_fnc_keyed
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_net", "", [""]], ["_on", false, [false]]];

if (isNull _unit || {_unit isEqualTo player}) exitWith {};
private _uid = getPlayerUID _unit;
if (_on && _net isNotEqualTo "") exitWith {GVAR(heard) set [_uid, [_unit, _net]]};
GVAR(heard) deleteAt _uid;
