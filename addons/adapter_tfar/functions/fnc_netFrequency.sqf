#include "script_component.hpp"
/*
 * Author: JMSB
 * A net's TFAR frequency - the number TFAR needs and the player never sees.
 *
 *   1. The plan's own: a slotted net of the PAC plan (fnc_planNets) sits on
 *      its slot, and the plan's TFAR frequency list for that band
 *      (jmfsbFR_radio_tfarSrFreqs / tfarLrFreqs) names that channel's
 *      frequency - the same list the side defaults are set from
 *      (fnc_sideDefaults), so a fill and an issued set never disagree.
 *   2. Otherwise derived from the net id: a string hash onto one 0.1 MHz slot
 *      of TFAR's band for that kind of set. Every machine derives the same
 *      number from the same name, so two sets filled with the same net hear
 *      each other with no list anywhere. TFAR's per-side radio code still
 *      keeps the other side out.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Kind of set "sr" | "lr" <STRING>
 * 2: The plan, if the caller already has it (fnc_planNets) <ARRAY> (default: read it)
 *
 * Return Value:
 * Frequency, as TFAR writes them ("51.1", "64") <STRING>
 *
 * Example:
 * ["ALPHA", "sr"] call jmfsb_adapter_tfar_fnc_netFrequency
 *
 * Public: No
 */

params [["_net", "", [""]], ["_kind", NODE_SR, [""]], ["_plan", nil, [[]]]];

if (isNil "_plan") then {_plan = [] call FUNC(planNets)};

private _isSr = _kind isEqualTo NODE_SR;
private _planFreq = "";
private _i = _plan findIf {(_x select 0) isEqualTo _net && {(_x select 2) isEqualTo _kind}};
if (_i >= 0 && {(_plan select _i) select 5}) then {
    private _channel = (_plan select _i) select 3;
    private _list = missionNamespace getVariable [[PLAN_LR_FREQS, PLAN_SR_FREQS] select _isSr, []];
    if !(_list isEqualType []) then {_list = []};
    private _freq = _list param [_channel, ""];
    if (_freq isEqualType 0) then {_freq = str _freq};
    if (_freq isEqualType "" && {FREQ_KEY(_freq) > 0}) then {_planFreq = _freq};
};
if (_planFreq isNotEqualTo "") exitWith {_planFreq};

private _hash = 0;
{
    _hash = (_hash * HASH_MUL + _x) mod HASH_MOD;
} forEach (toArray _net);

private _min = [LR_FREQ_MIN, SR_FREQ_MIN] select _isSr;
private _max = [LR_FREQ_MAX, SR_FREQ_MAX] select _isSr;
private _slot = _hash mod ((_max - _min) * FREQ_STEPS);
private _freq = _min + _slot / FREQ_STEPS;

// TFAR's own format (QTFAR_ROUND_FREQUENCY): no decimal on a whole number.
[_freq toFixed 1, _freq toFixed 0] select (_slot mod FREQ_STEPS == 0)
