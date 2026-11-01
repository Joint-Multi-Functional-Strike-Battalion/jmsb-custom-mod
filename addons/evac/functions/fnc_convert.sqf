#include "script_component.hpp"
/*
 * Author: JMSB
 * Performs the evac once the progress bar completes. Marks the casualty
 * claimed (so the action is not offered twice in the round trip) and hands
 * off to the server by remoteExec (FUNC(evacServer)), which knows who sent
 * it and checks him (review S6), snapshots the casualty's injuries, spawns
 * the matching AI casualty clone, then fully heals the real player onto the
 * medic.
 *
 * Arguments:
 * 0: The medic performing the evac - this machine's player <OBJECT>
 * 1: The downed player being evacuated <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget] call jmfsb_evac_fnc_convert
 *
 * Public: No
 */

params [["_medic", objNull, [objNull]], ["_casualty", objNull, [objNull]]];

_casualty setVariable [QGVAR(claimed), true, true];

// The medic is not sent: the server takes him from the sending machine.
[_casualty] remoteExecCall [QFUNC(evacServer), SERVER_OWNER];
