#include "script_component.hpp"
/*
 * Author: JMSB
 * The noise a receiver hears on a band at a point: the band's floor plus
 * every contribution the noise-source hooks return (jmfsb_rf_fnc_addNoiseSource),
 * summed as powers. A contribution flagged spreadApplies is first reduced by
 * the receiver's spread gain - the key-holder's processing gain against
 * barrage jamming (SPEC rf.ew.EA.jam). RF does not know what makes the noise;
 * with no hooks registered it is the floor.
 *
 * Arguments:
 * 0: Position ASL <ARRAY>
 * 1: Band <STRING>
 * 2: Net id (optional, default "") <STRING>
 * 3: Receiver spread gain dB (optional, default 0) <NUMBER>
 *
 * Return Value:
 * Noise dBm <NUMBER>
 *
 * Example:
 * [eyePos player, "UHF"] call jmfsb_rf_fnc_noise
 *
 * Public: Yes
 */

params [["_pos", [0, 0, 0], [[]], 3], ["_band", "VHF", [""]], ["_net", "", [""]], ["_spread", 0, [0]]];

private _floor = (GVAR(bands) getOrDefault [_band, [VHF_EXP, VHF_REF, VHF_FLOOR]]) select 2;
if (GVAR(noiseSources) isEqualTo []) exitWith {_floor};

private _mw = 10 ^ (_floor / 10);
{
    private _parts = [_pos, _band, _net] call _x;
    if (isNil "_parts" || {!(_parts isEqualType [])}) then {continue};
    {
        _x params [["_dbm", -1000, [0]], ["_spreadApplies", true, [true]]];
        if (_spreadApplies) then {_dbm = _dbm - _spread};
        _mw = _mw + 10 ^ (_dbm / 10);
    } forEach _parts;
} forEach GVAR(noiseSources);

10 * log _mw
