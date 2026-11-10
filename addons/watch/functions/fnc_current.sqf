#include "script_component.hpp"
/*
 * Author: YonV
 * The profile the panel and the F-keys work on: the one last added to or
 * cycled to while it has slots, else the first that has any. "" when nothing
 * is watched - the watch is off.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Profile id, "" when off <STRING>
 *
 * Example:
 * [] call jmfsb_watch_fnc_current
 *
 * Public: No
 */

if ((GVAR(slots) getOrDefault [GVAR(current), []]) isNotEqualTo []) exitWith {GVAR(current)};
private _hit = "";
{
    if (_y isNotEqualTo []) exitWith {_hit = _x};
} forEach GVAR(slots);
GVAR(current) = _hit;
_hit
