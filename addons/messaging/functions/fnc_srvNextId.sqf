#include "script_component.hpp"
/*
 * Author: YonV
 * Allocates the next id for a record kind. Ids are sequential and padded so a
 * log sorts the way it was written; they are never reused, because a reused id
 * means an old reply lands in a new thread.
 *
 * Arguments:
 * 0: Prefix - "M" for a message, "T" for a thread <STRING>
 *
 * Return Value:
 * Id <STRING>
 *
 * Example:
 * private _id = ["T"] call jmfsb_messaging_fnc_srvNextId
 *
 * Public: No
 */

params [["_prefix", "M", [""]]];

private _n = (GVAR(counters) getOrDefault [_prefix, 0]) + 1;
GVAR(counters) set [_prefix, _n];

format ["%1%2", _prefix, [_n, ID_PAD] call CBA_fnc_formatNumber]
