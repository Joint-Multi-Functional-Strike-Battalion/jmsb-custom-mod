#include "script_component.hpp"
/*
 * Author: JMSB
 * Programs one TFAR set from a fill: each channel named in the fill gets that
 * net's frequency (fnc_netFrequency) through TFAR's own
 * TFAR_fnc_setChannelFrequency. Channels the fill leaves "" keep what they
 * have, and the active and additional channel are not moved.
 *
 * The default fill is the plan's: every plan net of this kind on its plan
 * channel (fnc_planNets) - the same fill fnc_tune loads at login.
 *
 * Arguments:
 * 0: Radio: an SR class, or an LR [object, id] <STRING or ARRAY>
 * 1: Kind of set "sr" | "lr" <STRING>
 * 2: Net id per channel, first = channel 1; "" leaves a channel <ARRAY> (default: the plan's)
 * 3: The plan, if the caller already has it <ARRAY> (default: read it)
 *
 * Return Value:
 * Nets programmed onto it <ARRAY of STRING>
 *
 * Example:
 * [call TFAR_fnc_activeSwRadio, "sr", ["ALPHA", "C2", "A2G"]] call jmfsb_adapter_tfar_fnc_program
 *
 * Public: No
 */

params [["_radio", "", ["", []]], ["_kind", NODE_SR, [""]], ["_nets", [], [[]]], ["_plan", nil, [[]]]];

if (_radio isEqualTo "" || {_radio isEqualTo []}) exitWith {[]};
if (isNil "_plan") then {_plan = [] call FUNC(planNets)};

private _channels = [LR_CHANNELS, SR_CHANNELS] select (_kind isEqualTo NODE_SR);

if (_nets isEqualTo []) then {
    _nets = [];
    _nets resize _channels;
    _nets = _nets apply {""};
    {
        _x params ["_id", "", "_netKind", "_channel"];
        if (_netKind isEqualTo _kind && _channel > NO_CHANNEL && _channel < _channels) then {_nets set [_channel, _id]};
    } forEach _plan;
};

private _done = [];
{
    if (_forEachIndex >= _channels) then {break};
    if !(_x isEqualType "") then {continue};
    if (_x isEqualTo "") then {continue};
    [_radio, _forEachIndex + 1, [_x, _kind, _plan] call FUNC(netFrequency)] call TFAR_fnc_setChannelFrequency;
    _done pushBackUnique _x;
} forEach _nets;

TRACE_3("programmed",_radio,_kind,_done);
_done
