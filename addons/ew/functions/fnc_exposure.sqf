#include "script_component.hpp"
/*
 * Author: JMSB
 * How far a set is heard (DESIGN_EW "Exposure", shown in the EP tab): the
 * clear-ground distance at which a generic enemy receiver (EXPOSURE_SENS_DBM,
 * EXPOSURE_GAIN_DBI, without the key - so the set's spread gain comes off)
 * still hears it, on its best band, with RF's band table. EMCON 1 and above
 * caps the power at 2 W; SILENT is not heard at all.
 *
 * Arguments:
 * 0: Profile id <STRING>
 * 1: EMCON level 0..3 <NUMBER>
 *
 * Return Value:
 * Metres <NUMBER>
 *
 * Example:
 * ["handheld", 1] call jmfsb_ew_fnc_exposure
 *
 * Public: Yes
 */

params [["_profileId", "", [""]], ["_emcon", 0, [0]]];

if (_emcon >= EMCON_SILENT) exitWith {0};
private _prof = [_profileId] call EFUNC(rf,profile);
if (count _prof == 0) exitWith {0};

private _tx = _prof get "txPowerDbm";
if (_emcon > 0) then {_tx = _tx min EMCON_POWER_CAP_DBM};
private _budget = _tx + (_prof get "antennaGainDb") + EXPOSURE_GAIN_DBI - EXPOSURE_SENS_DBM - (_prof get "spreadGainDb");

private _best = 0;
{
    ([_x] call EFUNC(rf,bandInfo)) params [["_exp", 0], ["_ref", 0]];
    if (_exp <= 0) then {continue};
    _best = _best max (10 ^ ((_budget - _ref) / (10 * _exp)));
} forEach (_prof get "bands");

(round _best) min DETECT_MAX_M
