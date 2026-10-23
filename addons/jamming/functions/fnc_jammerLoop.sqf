#include "script_component.hpp"
/*
 * Author: JMSB
 * Client-local jam evaluation (CBA PFH). Publishes this player's jam factor per
 * domain for the meter and the handset, applies the GPS denial, and drives ACRE.
 * Levers + falloff adapted from Crows-EW (APL-SA).
 *
 * Game voice is not touched here (2026-10-20). Radio and data zones are RF
 * noise (FUNC(rfNoise)); RF's link quality reaches game voice through
 * jmfsb_voice (mesh-set volume). ACRE keeps the old direct lever until its
 * adapter carries voice.
 *
 * Arguments (CBA PFH): unused
 *
 * Return Value: None
 *
 * Public: No
 */

if (isNil QGVAR(jammers)) exitWith {};

private _ppos = getPosASL player;

// Everything about WHERE a jammer reaches now lives in FUNC(jamFactor); this
// loop only decides what to do with the answer. With the model attributes at
// their defaults the factor is the old inline maths exactly, so ACRE sees the
// values it always saw.
private _radioPower = 0;
if (GVAR(hasACRE) && GVAR(jamBurnthrough)) then {
    private _cur = call acre_api_fnc_getCurrentRadio;
    if (_cur != "") then {
        private _i = _cur find "_ID_";
        private _base = if (_i > 0) then { _cur select [0, _i] } else { _cur };
        private _p = [_base, [_cur] call acre_api_fnc_getPreset, [_cur] call acre_api_fnc_getRadioChannel, "power"] call acre_api_fnc_getPresetChannelField;
        if (_p isEqualType 0) then { _radioPower = _p };
    };
};

// DOM_RADIO, explicitly. This loop drives ACRE and nothing else;
// the hub that denies TAC//MSG must not quieten anybody's voice net.
private _factor = ([_ppos, _radioPower, DOM_RADIO] call FUNC(jamFactor)) select 0;

private _bestAcre = ACRE_JAM_FAR;        // 0 = no jam (fraction of ACRE signal removed)

if (_factor > 0) then {
    // factor 1 == inside the core; anything less is the falloff band, where
    // _p is the old 0..1 position across it.
    private _inCore = _factor >= 1;
    private _p = 1 - _factor;

    if (GVAR(hasACRE)) then {
        _bestAcre = if (_inCore) then {
            ACRE_JAM_FULL
        } else {
            [ACRE_JAM_NEAR, ACRE_JAM_FAR, _p] call BIS_fnc_lerp
        };
    };
};

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

// ACRE2: the registered custom signal func (see clientInit) reads this live jam
// fraction (0 = clear .. ~0.98 = smothered) and scales received strength by it.
if (GVAR(hasACRE)) then {
    GVAR(acreJam) = _bestAcre;
};

// The ACRE DF hunt that used to live here is gone, for two verified
// reasons: its QGVAR(detection) serverEvent had no listener anywhere - a
// dead raise - and the reaction addon already polls the same rising edge
// with the SATCOM exemption and the watts threshold this raw raise skipped.
// One transmission watch, in one addon, on one gate.
