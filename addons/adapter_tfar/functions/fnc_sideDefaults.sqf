#include "script_component.hpp"
/*
 * Author: JMSB
 * TFAR's side default frequency lists from the net plan - the TFAR path of
 * jmfsb_gear_fnc_setupRadios. TFAR's client init reads these when it issues a
 * radio (TFAR_defaultFrequencies_sr_* / lr_*, set for west, east and
 * independent alike), so a set is on the plan's nets from the start. Per
 * channel: the plan net on it (fnc_netFrequency), else the plan's own TFAR
 * frequency list entry, else a frequency hashed from the channel's name. Left
 * as TFAR has them when the plan has no nets.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_sideDefaults
 *
 * Public: Yes
 */

private _plan = [] call FUNC(planNets);
if (_plan isEqualTo []) exitWith {};

{
    _x params ["_kind", "_listVar", "_targets"];
    private _count = [LR_CHANNELS, SR_CHANNELS] select (_kind isEqualTo NODE_SR);
    private _list = missionNamespace getVariable [_listVar, []];
    if !(_list isEqualType []) then {_list = []};
    private _freqs = [];
    for "_c" from 0 to (_count - 1) do {
        private _channel = _c;
        private _at = _plan findIf {(_x select 2) isEqualTo _kind && (_x select 3) isEqualTo _channel};
        private _freq = _list param [_c, ""];
        if (_freq isEqualType 0) then {_freq = str _freq};
        if (_at >= 0) then {
            _freq = [(_plan select _at) select 0, _kind, _plan] call FUNC(netFrequency);
        };
        if !(_freq isEqualType "") then {_freq = ""};
        if (_freq isEqualTo "") then {
            _freq = [format [CHANNEL_NAME_FORMAT, toUpper _kind, _c + 1], _kind, _plan] call FUNC(netFrequency);
        };
        _freqs pushBack _freq;
    };
    {missionNamespace setVariable [_x, +_freqs]} forEach _targets;
} forEach [[NODE_SR, PLAN_SR_FREQS, TFAR_DEFAULTS_SR], [NODE_LR, PLAN_LR_FREQS, TFAR_DEFAULTS_LR]];

INFO_1("TFAR side default frequencies set from the net plan (%1 nets)",count _plan);
