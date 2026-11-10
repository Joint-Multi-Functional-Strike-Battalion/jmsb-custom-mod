#include "script_component.hpp"
/*
 * Author: YonV
 * Empties this client's thread cache. The server sends it when the store is
 * emptied under the clients (msg.clear): the cache then holds threads that no
 * longer exist, and an index refresh alone would not clear them.
 *
 * Sent by remoteExecCall from the server and taken only from the server
 * (review S7). It was a global CBA event, which any client could raise to wipe
 * every player's cache at once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_messaging_fnc_cltCacheClear", 0]
 *
 * Public: No
 */

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

GVAR(cache) = createHashMap;
