#include "script_component.hpp"
/*
 * Author: YonV
 * How high a support aircraft flies now, m ATL - the one answer every provider
 * flies by (user, 2026-11-01).
 *
 * HELICOPTERS FLY NAP OF THE EARTH: NOE_HEIGHT above the ground in every phase,
 * from leaving the airfield to the task point and back ("nap of the earth for
 * helos"). Only a task's own height breaks it, and the provider asks for that
 * itself (a landing, a hover, a set-down, a jump - FUNC(approachHeight)).
 * A LOAD ON THE HOOK LIFTS IT ("make sure to add alt for helos that have a
 * sling load"): NOE_HEIGHT plus the longest rope, the load's own height and
 * SLING_CLEARANCE; SLING_TRANSIT_HEIGHT when the rope cannot be read. Back to
 * NOE_HEIGHT once the load is let go - the provider asks again then.
 *
 * FIXED-WING ("loiter or on station needs to be 8k meters off map, atack alt
 * need to be 4k m atl"): FW_ATTACK_ALT on an attack, FW_HOLD_ALT on station
 * (off the map, FUNC(holdPoint)), FW_TRANSIT_ALT between.
 *
 * A class name answers like the aircraft would without a load, so a provider
 * can ask before the aircraft is made.
 *
 * Arguments:
 * 0: The aircraft, or its class <OBJECT or STRING>
 * 1: Phase: "transit", "station" or "attack" (optional, default "transit") <STRING>
 *
 * Return Value:
 * Height above the terrain, m <NUMBER>
 *
 * Example:
 * [_veh, "attack"] call jmfsb_support_fnc_flightHeight
 *
 * Public: Yes
 */

params [["_what", objNull, [objNull, ""]], ["_phase", PHASE_TRANSIT, [""]]];

// A VTOL IS A PLANE BETWEEN POINTS (user, 2026-11-08: "helo only in landing
// and take off, needs to use flight mode over distances over 1k"): it cruises
// at VTOL_CRUISE_ALT; the approach, the hover and the landing are the
// provider's (FUNC(approachHeight), jmfsb_support_air_fnc_heliTake).
if (_what isKindOf "VTOL_Base_F") exitWith {
    switch (_phase) do {
        case PHASE_ATTACK: {FW_ATTACK_ALT};
        case PHASE_STATION: {FW_HOLD_ALT};
        default {VTOL_CRUISE_ALT};
    }
};
if !([_what] call FUNC(isRotary)) exitWith {
    switch (_phase) do {
        case PHASE_ATTACK: {FW_ATTACK_ALT};
        case PHASE_STATION: {FW_HOLD_ALT};
        default {FW_TRANSIT_ALT};
    }
};

if (_what isEqualType "") exitWith {NOE_HEIGHT};
private _load = getSlingLoad _what;
if (isNull _load) exitWith {NOE_HEIGHT};

private _rope = 0;
{
    _rope = _rope max (ropeLength _x);
} forEach (ropes _what);
if (_rope <= 0) exitWith {SLING_TRANSIT_HEIGHT};

(boundingBoxReal _load) params ["_low", "_high"];
NOE_HEIGHT + _rope + ((_high select 2) - (_low select 2)) + SLING_CLEARANCE
