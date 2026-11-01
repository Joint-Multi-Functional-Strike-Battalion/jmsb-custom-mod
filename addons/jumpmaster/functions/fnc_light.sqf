#include "script_component.hpp"
/*
 * Author: JMSB
 * The light, on the machine a man is local to: whether he may exit himself
 * from now, and - for the player himself - the word on the notify rail. An
 * AI's light sets his flag and says nothing.
 *
 * Sent by the server (FUNC(srvLight)) by remoteExec and taken only from the
 * server (review S7: it was the `light` CBA event, which any client could
 * raise to put words on another man's rail).
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: What is said <STRING>
 * 2: May exit himself from now <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "GREEN LIGHT. GO.", true] remoteExecCall ["jmfsb_jumpmaster_fnc_light", _unit]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_text", "", [""]], ["_mayJump", false, [false]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("light: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _unit) exitWith {};

_unit setVariable [QGVAR(mayJump), _mayJump];
if (_unit isEqualTo (call CBA_fnc_currentUnit)) then {
    [_text, "high"] call FUNC(say);
};
