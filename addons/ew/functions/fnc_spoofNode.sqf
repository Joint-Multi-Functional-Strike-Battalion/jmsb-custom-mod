#include "script_component.hpp"
/*
 * Author: JMSB
 * Spoofs a broken net's GPS (DESIGN_EW "Hacking: SPOOF") - the hacking
 * addon's SPOOF action lands here when the hack completes. Every man of the
 * group walks off his true position through the same engine as a spoofer's
 * field (FUNC(spoof)), for the hack-spoof setting's length, then walks back.
 * An anti-spoof set among them reads SUSPECT instead. What follows the false
 * fix is whatever reads the GPS: their BFT dots, and the DF cuts their sets
 * take, so the fixes their side makes - and the patrols it sends - land off
 * target.
 *
 * On a client this forwards to the server.
 *
 * Arguments:
 * 0: The hacked net's group <GROUP>
 * 1: The hacker <OBJECT>
 *
 * Return Value:
 * Accepted (server), forwarded (client) <BOOL>
 *
 * Example:
 * [group _device, player] call jmfsb_ew_fnc_spoofNode
 *
 * Public: Yes
 */

params [["_group", grpNull, [grpNull]], ["_hacker", objNull, [objNull]]];

if (!isServer) exitWith {
    [QGVAR(spoofNode), [_group, _hacker]] call CBA_fnc_serverEvent;
    true
};
if (isNull _group || {(units _group) isEqualTo []}) exitWith {false};

GVAR(spoofNodes) set [hashValue _group, [_group, CBA_missionTime + GVAR(spoofHackTime), str side group _hacker]];
INFO_3("GPS of %1 (%2) spoofed by %3",groupId _group,side _group,name _hacker);
[QGVAR(spoofed), [_group, _hacker]] call CBA_fnc_localEvent;
true
