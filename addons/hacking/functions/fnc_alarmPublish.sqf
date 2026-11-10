#include "script_component.hpp"
/*
 * Author: YonV
 * Server: publishes a copy of the armed alarm list for the screens (the
 * scanner, the HUD timer, the tacpad's TIMER app). The server's own list is
 * in localNamespace and is the only one it reads (review S7): a client that
 * publicVariables the copy changes screens until the next publish, never
 * which alarm rings.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_hacking_fnc_alarmPublish
 *
 * Public: No
 */

if (!isServer) exitWith {};

missionNamespace setVariable [QGVAR(alarms), +(localNamespace getVariable [QGVAR(alarms), []]), true];
