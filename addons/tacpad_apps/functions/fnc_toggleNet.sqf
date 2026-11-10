#include "script_component.hpp"
/*
 * Author: YonV
 * Flips one shared net between ALERT and MUTED for this player and redraws the
 * settings page it was pressed on.
 *
 * The level itself is the messaging addon's - see
 * jmfsb_messaging_fnc_setNetLevel, which also persists it to the profile -
 * this only owns the press.
 *
 * Arguments:
 * 0: Net name, e.g. "HQ" <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_net", "", [""]]];

if (_net == "" || {isNil QEFUNC(messaging,setNetLevel)}) exitWith {};

private _level = (missionNamespace getVariable [QEGVAR(messaging,netLevels), createHashMap]) getOrDefault [_net, 0];
[_net, parseNumber (_level == 0)] call EFUNC(messaging,setNetLevel);

{["settings", ["nets"]] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
