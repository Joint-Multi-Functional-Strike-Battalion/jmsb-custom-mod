#include "script_component.hpp"
/*
 * Author: YonV
 * Receives this player's whole index from the server and replaces the local one.
 * A replace rather than a merge: the server's answer is the truth, and a merge
 * would keep rows for threads the player has since lost access to.
 *
 * Sent by remoteExecCall from the server (FUNC(srvIndexPush)), and taken only
 * from the server (review S7): a CBA event any client could raise would let
 * it overwrite another player's index.
 *
 * Arguments:
 * 0: Index entries <ARRAY> - each the array form of an index HashMap
 *
 * Return Value:
 * None
 *
 * Example:
 * [_rows] remoteExecCall ["jmfsb_messaging_fnc_cltIndex", _unit]
 *
 * Public: No
 */

params [["_entries", [], [[]]]];

if !([] call EFUNC(common,fromServer)) exitWith {};

GVAR(index) = _entries apply {createHashMapFromArray _x};

[QGVAR(indexRefreshed), []] call CBA_fnc_localEvent;
