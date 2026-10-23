#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every CLIENT_TICK_S: tells the network when this man's GPS loses
 * or regains its lock. Denial is worked out on his own machine (the jamming
 * addon's GPS field, jmfsb_jamming_gpsDenied); the BFT dots other men draw
 * of him need it too (FUNC(gpsOf)), so it is hung on him - on the EDGE only,
 * compared with what he carries, so a respawned body starts clean.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [LINKFUNC(gpsWatch), CLIENT_TICK_S, []] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (isNull player) exitWith {};

private _denied = (missionNamespace getVariable [QEGVAR(jamming,gpsDenied), false]) && alive player;
if ((player getVariable [QGVAR(gpsDenied), false]) isEqualTo _denied) exitWith {};
player setVariable [QGVAR(gpsDenied), _denied, true];
