#include "script_component.hpp"
/*
 * Author: YonV
 * The altitude a jump type is flown at, metres over the ground: the jump
 * aircraft's own for the type (user, 2026-11-02: HALO, HAHO and static line
 * each on the JMSB - Jump Aircraft module; the settings' for a side's own
 * aircraft - FUNC(asset)).
 *
 * Arguments:
 * 0: Jump type <STRING>
 * 1: The jump aircraft, FUNC(asset) <HASHMAP>
 *
 * Return Value:
 * Altitude, m <NUMBER>
 *
 * Example:
 * ["STATIC", _asset] call jmfsb_jumpmaster_fnc_typeAlt
 *
 * Public: No
 */

params [["_type", TYPE_HALO, [""]], ["_asset", createHashMap, [createHashMap]]];

private _alts = _asset getOrDefault ["alts", [ALT_FREEFALL_DEFAULT, ALT_FREEFALL_DEFAULT, ALT_STATIC_DEFAULT]];
_alts param [(TYPES find _type) max 0, ALT_FREEFALL_DEFAULT]
