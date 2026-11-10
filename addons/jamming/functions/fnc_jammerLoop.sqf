#include "script_component.hpp"
/*
 * Author: YonV
 * Client-local jam evaluation (CBA PFH). Publishes this player's jam factor per
 * domain for the meter and the handset, and applies the GPS denial.
 * Levers + falloff adapted from Crows-EW (APL-SA).
 *
 * Game voice is not touched here (2026-10-20). Radio and data zones are RF
 * noise (FUNC(rfNoise)); RF's link quality reaches game voice through
 * jmfsb_voice (mesh-set volume). The ACRE lever this loop drove went with ACRE
 * (DEC1, 2026-10-31).
 *
 * Arguments (CBA PFH): unused
 *
 * Return Value: None
 *
 * Public: No
 */

if (isNil QGVAR(jammers)) exitWith {};

private _ppos = getPosASL player;

// Everything about WHERE a jammer reaches lives in FUNC(jamFactor); this
// loop only publishes the answer. DOM_RADIO, explicitly: the hub that denies
// TAC//MSG must not quieten anybody's voice net.
private _factor = ([_ppos, 0, DOM_RADIO] call FUNC(jamFactor)) select 0;

// Published for the jamming meter - no second evaluation there. FOUR
// NUMBERS SINCE THE SPLIT: one per domain, so the meter can show which
// service is down rather than one bar that could mean any of them, plus
// DOM_ANY for "is the spectrum dirty at all". Without the last one a
// player under a data-only hub would read a clean meter while TAC//MSG
// was dead.
//
// All four come off the one calculator, in the one place, on the one
// cadence - the meter, the radios, the handset and the map cannot
// disagree about the sky because they are reading the same four numbers.
GVAR(localJamFactor) = _factor;
GVAR(localJamData) = ([_ppos, 0, DOM_DATA] call FUNC(jamFactor)) select 0;
GVAR(localJamGps) = ([_ppos, 0, DOM_GPS] call FUNC(jamFactor)) select 0;
GVAR(localJamAny) = _factor max GVAR(localJamData) max GVAR(localJamGps);

// The GPS denial is the only one that has to TAKE something off the
// player rather than scale a number, so it is applied here, on the same
// tick that measured it.
[GVAR(localJamGps)] call FUNC(gpsApply);

// One transmission watch: the reaction addon polls the rising edge with the
// SATCOM exemption and the watts threshold. No DF hunt lives here.
