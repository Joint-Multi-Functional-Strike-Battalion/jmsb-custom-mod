#include "script_component.hpp"
/*
 * Author: JMSB
 * The net an ACRE radio is on: the label of its current channel in the PAC
 * plan's ACRE tier for its base class (jmfsbFR_radio_sr/mr/lrRadios and
 * their Channels rows [channel, freq, label] - what jmfsb_gear_fnc_setupRadios
 * programs), upper case; else "<TIER> CH <n>" (the 343's block channels
 * come from the group setup, not from rows). Its kind is the PAC net plan's
 * when the label names a plan net (team, c2, a2g), else c2 on the long range
 * tier and team on the others. Works for another player's radio too: ACRE
 * shares radio data (acre_api_fnc_getRadioChannel).
 *
 * Arguments:
 * 0: ACRE radio id <STRING>
 *
 * Return Value:
 * [net id, kind] - ["", ""] when the radio has no channel <ARRAY>
 *
 * Example:
 * ["ACRE_PRC152_ID_1"] call jmfsb_adapter_acre_fnc_radioNet
 *
 * Public: No
 */

params [["_radioId", "", [""]]];

if (_radioId isEqualTo "") exitWith {["", ""]};
private _channel = [_radioId] call acre_api_fnc_getRadioChannel;
if !(_channel isEqualType 0) then {_channel = 0};
if (_channel <= 0) exitWith {["", ""]};

private _base = [_radioId] call acre_api_fnc_getBaseRadio;
private _tier = TIER_NONE;
private _label = "";
{
    _x params ["_name", "_radiosVar", "_channelsVar"];
    private _radios = missionNamespace getVariable [_radiosVar, []];
    if (_radios isEqualType [] && {_base in _radios}) exitWith {
        _tier = _name;
        private _rows = missionNamespace getVariable [_channelsVar, []];
        if !(_rows isEqualType []) then {_rows = []};
        private _at = _rows findIf {_x isEqualType [] && {(_x param [0, -1]) isEqualTo _channel}};
        if (_at >= 0) then {
            private _text = (_rows select _at) param [2, ""];
            if (_text isEqualType "") then {_label = toUpper trim _text};
        };
    };
} forEach TIERS;

private _net = [_label, format [NET_FORMAT, toUpper _tier, _channel]] select (_label isEqualTo "");
private _kind = [KIND_TEAM, KIND_C2] select (_tier isEqualTo TIER_LR);
if (!isNil QEFUNC(pac,netPlan)) then {
    private _plan = [] call EFUNC(pac,netPlan);
    private _at = _plan findIf {(_x select 0) isEqualTo _net};
    if (_at >= 0) then {
        _kind = switch ((_plan select _at) select 2) do {
            case PLAN_SR: {KIND_TEAM};
            case PLAN_A2G: {KIND_A2G};
            default {KIND_C2};
        };
    };
};
[_net, _kind]
