#include "script_component.hpp"
/*
 * Author: JMSB
 * LAUNCH: the leader's plan to the server (FUNC(srvLaunch)) - type, path,
 * passes, exit and his squad as the stick - once it is his to run, the path
 * is set and every man is ready.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_launch
 *
 * Public: No
 */

private _me = call CBA_fnc_currentUnit;

if !([] call FUNC(isJumpmaster)) exitWith {
    ["Squad leaders only.", "high"] call FUNC(say);
    false
};
if (GVAR(red) isEqualTo [] || {GVAR(green) isEqualTo []}) exitWith {
    ["No flight path: PICK PATH ON MAP first.", "high"] call FUNC(say);
    false
};
if ((_me getVariable [QGVAR(run), []]) isNotEqualTo []) exitWith {
    ["A jump is already running for your squad.", "high"] call FUNC(say);
    false
};
([GVAR(type)] call FUNC(ready)) params ["_rows", "_ready", "_missing"];
if (!_ready) exitWith {
    [format ["Not ready: %1 without a mask or a parachute.", _missing], "high"] call FUNC(say);
    false
};

private _passes = [GVAR(passes), GVAR(passesDefault)] select (GVAR(passes) < 0);
private _exit = [GVAR(exit), GVAR(exitDefault)] select (GVAR(exit) isEqualTo "");
// By remoteExec, so the server knows who sent it (review S7).
[_me, GVAR(type), GVAR(red), GVAR(green), _passes, _exit, _rows apply {_x select 0}] remoteExecCall [QFUNC(srvLaunch), SERVER_OWNER];
[format ["%1 launched: %2 men, %3 pass%4, %5 exit.", GVAR(type), count _rows, _passes, ["", "es"] select (_passes > 1), _exit]] call FUNC(say);
true
