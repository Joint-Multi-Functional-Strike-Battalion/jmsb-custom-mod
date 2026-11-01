#include "script_component.hpp"
/*
 * Author: veteran29, JMSB
 * Client: respawn this player now if he is dead. Sent by the server
 * (FUNC(forceRespawn), FUNC(forceRespawnRequest)) and taken only from it
 * (review S7) - it was a CBA event any client could raise.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_respawn_fnc_forceLocal", _units]
 *
 * Public: No
 */

if (!hasInterface || {alive player}) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

setPlayerRespawnTime TIME_MINIMUM;
