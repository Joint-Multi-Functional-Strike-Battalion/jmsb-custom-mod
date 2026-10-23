#include "script_component.hpp"
/*
 * Author: JMSB
 * THE ZONES AS RF NOISE. Registered with jmfsb_rf_fnc_addNoiseSource on the
 * server; RF calls it for every receiver it prices, per net, every tick.
 *
 *   radio zones - noise on the voice bands (JAM_RF_RADIO_BANDS)
 *   data zones  - noise on the band of RF's DATA net (jmfsb_rf_fnc_netBand),
 *                 so on that band every net hears it, not only DATA
 *   gps zones   - nothing here; GPS stays FUNC(gpsApply)'s
 *
 * The strength is FUNC(jamFactor)'s, so the zone's shape - core, falloff,
 * curve, duty, cone, terrain - is the same in RF as on the meter: the module's
 * dBm at the core plus 10 log10 of the factor. Barrage, so the receiver's
 * spread gain applies. jamFactor walks every zone, so its answer is memoised
 * per position and domain for the frame the RF tick runs in.
 *
 * Arguments:
 * 0: Receiver position ASL <ARRAY>
 * 1: Band <STRING>
 * 2: Net id <STRING>
 *
 * Return Value:
 * Contributions [[dBm at the receiver, spreadApplies], ...] <ARRAY>
 *
 * Example:
 * [eyePos player, "UHF", "DATA"] call jmfsb_jamming_fnc_rfNoise
 *
 * Public: No
 */

params [["_pos", [0, 0, 0], [[]], 3], ["_band", "", [""]], ["_net", "", [""]]];

if (GVAR(jammers) isEqualTo []) exitWith {[]};

if (diag_frameNo != GVAR(rfNoiseFrame)) then {
    GVAR(rfNoiseFrame) = diag_frameNo;
    GVAR(rfNoiseMemo) = createHashMap;
};

private _domains = [];
if (_band in JAM_RF_RADIO_BANDS) then {_domains pushBack DOM_RADIO};
if (_band isEqualTo ([JAM_RF_DATA_NET] call EFUNC(rf,netBand))) then {_domains pushBack DOM_DATA};

private _out = [];
{
    private _key = [_pos, _x];
    private _factor = GVAR(rfNoiseMemo) getOrDefault [_key, -1];
    if (_factor < 0) then {
        _factor = ([_pos, 0, _x] call FUNC(jamFactor)) select 0;
        GVAR(rfNoiseMemo) set [_key, _factor];
    };
    if (_factor > 0) then {
        _out pushBack [GVAR(rfNoiseDbm) + 10 * log _factor, true];
    };
} forEach _domains;

_out
