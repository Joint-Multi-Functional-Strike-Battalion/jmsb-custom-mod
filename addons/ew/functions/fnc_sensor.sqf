#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: whether an emitting RF node can also listen and take a DF cut, and
 * how well (DESIGN_EW "ES: DF"). The set's own class first - handheld 15 deg,
 * manpack (TFAR / ACRE) and relay 10, vehicle 5 - then the kit of whoever runs it: an EW
 * Receiver makes it the dedicated 2 deg set that hears every band, and an ISR
 * operator (the man, or anyone in the vehicle) is one class better. Drone
 * links and legacy commercial sets cannot DF.
 *
 * Arguments:
 * 0: Emitter, as FUNC(collect) builds it <HASHMAP>
 *
 * Return Value:
 * [bearing error deg, bands heard, RX sensitivity dBm, antenna gain dBi],
 * [] when it cannot DF <ARRAY>
 *
 * Example:
 * [_emitter] call jmfsb_ew_fnc_sensor
 *
 * Public: No
 */

params [["_e", createHashMap, [createHashMap]]];

if ((_e get "source") isNotEqualTo SRC_RF) exitWith {[]};
if ((_e get "intent") isEqualTo INTENT_DECOY) exitWith {[]};

private _profileId = _e get "profile";
private _i = DF_PROFILES findIf {(_x select 0) isEqualTo _profileId};
if (_i < 0) exitWith {[]};
private _err = (DF_PROFILES select _i) select 1;
private _prof = [_profileId] call EFUNC(rf,profile);
private _bands = _e get "bands";

private _obj = _e get "object";
private _men = if (_obj isKindOf "CAManBase") then {[_obj]} else {crew _obj};
private _receiver = false;
private _isr = false;
{
    private _kit = [_x] call FUNC(kit);
    _receiver = _receiver || {_kit get "receiver"};
    _isr = _isr || {_kit get "isr"};
} forEach _men;
if (!(_obj isKindOf "CAManBase") && {ITEM_RECEIVER in (itemCargo _obj)}) then {_receiver = true};

if (_receiver) then {
    _err = DF_ERR_DEDICATED;
    _bands = BANDS_ALL;
};
if (_isr) then {
    private _classes = DF_CLASSES;
    private _c = _classes find _err;
    if (_c >= 0) then {_err = _classes select ((_c + 1) min (count _classes - 1))};
};

[_err, _bands, _prof getOrDefault ["rxSensDbm", EXPOSURE_SENS_DBM], _prof getOrDefault ["antennaGainDb", 0]]
