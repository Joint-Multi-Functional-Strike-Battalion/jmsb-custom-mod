#include "script_component.hpp"
/*
 * Author: JMSB
 * Where this man's GPS says he is: the EW addon's fix when it is loaded
 * (jmfsb_ew_fnc_gpsHere - the false fix when spoofed, nothing when denied),
 * his real position without it. Point Man navigates by the GPS, so a jammed
 * set leaves him without a distance rather than with a true one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Position ATL, [] with no fix <ARRAY>
 *
 * Example:
 * private _here = [] call jmfsb_pointman_fnc_gpsPos
 *
 * Public: No
 */

if (!isNil QEFUNC(ew,gpsHere)) exitWith {[false] call EFUNC(ew,gpsHere)};

getPosATL (call CBA_fnc_currentUnit)
