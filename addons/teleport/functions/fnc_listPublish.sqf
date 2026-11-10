#include "script_component.hpp"
/*
 * Author: YonV
 * Server: publishes a copy of the point list for the menus. The server's own
 * list lives in localNamespace, which is not networked, and server code reads
 * only that (review S7): any client can publicVariable over the public copy,
 * and the server then publishes its own again (XEH_postInit).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_teleport_fnc_listPublish
 *
 * Public: No
 */

if (!isServer) exitWith {};

missionNamespace setVariable [QTP_LIST, +(localNamespace getVariable [QTP_LIST, []]), true];
