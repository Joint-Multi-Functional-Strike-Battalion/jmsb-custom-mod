#include "script_component.hpp"
/*
 * Author: YonV
 * How long an aircraft takes to reach a point from where it is now, seconds,
 * straight over the ground (user, 2026-11-01: "need more information like
 * after rw inbound eta"). Its speed now, never slower than ETA_CRUISE_SHARE of
 * its class's top speed - an aircraft spooling up on its stand is not taken to
 * crawl there - and never slower than ETA_MIN_MS.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: The point <ARRAY>
 *
 * Return Value:
 * Seconds, -1 unknown <NUMBER>
 *
 * Example:
 * [_heli, _lz] call jmfsb_support_fnc_etaTo
 *
 * Public: Yes
 */

params [["_vehicle", objNull, [objNull]], ["_point", [], [[]]]];

if (isNull _vehicle || count _point < 2) exitWith {ETA_UNKNOWN};

private _cruise = getNumber ((configOf _vehicle) >> "maxSpeed") / ETA_KMH_PER_MS * ETA_CRUISE_SHARE;
private _ms = ((speed _vehicle) / ETA_KMH_PER_MS) max _cruise max ETA_MIN_MS;

(_vehicle distance2D _point) / _ms
