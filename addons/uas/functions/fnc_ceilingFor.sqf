#include "script_component.hpp"
/*
 * Author: YonV
 * How many airframes one patrol may have up RIGHT NOW.
 *
 * IT USED TO BE A SIDE'S CEILING, and it is a patrol's cap now. One module is
 * one patrol and carries its own count, so "how many does this side own" stopped
 * being a question anybody asks - what is left is the one thing that IS still
 * map-wide: a side whose supply cache has been killed flies fewer of everything.
 *
 * The whole point of the caches: while a killed one's outage runs, every patrol
 * that side has thins to UAS_OUTAGE_MAX, and the sky visibly empties. Then the
 * window closes and it fills again. Outages extend rather than stack, so supply
 * raids are raids and not a win button.
 *
 * A PATROL NEVER GROWS PAST ITS OWN NUMBER. The cap only ever reduces - a
 * module asking for one airframe flies one whatever the supply state.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: What the patrol asked for <NUMBER>
 *
 * Return Value:
 * What it may actually have up <NUMBER>
 *
 * Example:
 * [east, 3] call jmfsb_uas_fnc_ceilingFor
 */

params [["_side", sideUnknown, [sideUnknown]], ["_want", 0, [0]]];

if (_side isEqualTo sideUnknown) exitWith {0};

private _until = GVAR(outages) getOrDefault [str _side, -1];
if (CBA_missionTime < _until) exitWith { UAS_OUTAGE_MAX min _want };

_want
