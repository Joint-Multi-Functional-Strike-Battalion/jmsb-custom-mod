#include "script_component.hpp"
/*
 * Author: YonV
 * Server: publishes a copy of the building marks for every AiTR (FUNC(markSet)).
 * Server code reads only its own list (localNamespace); a client that
 * publishes over the copy gets the server's back (XEH_postInit).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_markPublish
 *
 * Public: No
 */

if (!isServer) exitWith {};

missionNamespace setVariable [QGVAR(marks), +(localNamespace getVariable [QGVAR(marks), []]), true];
