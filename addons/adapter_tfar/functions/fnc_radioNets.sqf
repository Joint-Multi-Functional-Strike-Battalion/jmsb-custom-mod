#include "script_component.hpp"
/*
 * Author: JMSB
 * NETS OVER FREQUENCIES, read back: which net each channel of a TFAR set
 * carries. A channel's frequency is looked up in the net table
 * (fnc_netTable); a channel whose frequency names no net falls back to the
 * plan's channel number (a set tuned before any fill - TFAR's own or the
 * mission's frequencies - still reads as the plan's nets, as it did before
 * fills existed). "" for a channel that carries neither.
 *
 * Arguments:
 * 0: Radio: an SR class, or an LR [object, id] <STRING or ARRAY>
 * 1: Kind of set "sr" | "lr" <STRING>
 * 2: The plan, if the caller already has it <ARRAY> (default: read it)
 *
 * Return Value:
 * [net per channel <ARRAY of STRING>, channels matched by frequency <NUMBER>] <ARRAY>
 *
 * Example:
 * [call TFAR_fnc_activeSwRadio, "sr"] call jmfsb_adapter_tfar_fnc_radioNets
 *
 * Public: Yes - the walking view's net row reads it (jmfsb_devices_fnc_overlayNets)
 */

params [["_radio", "", ["", []]], ["_kind", NODE_SR, [""]], ["_plan", nil, [[]]]];

if (_radio isEqualTo "" || {_radio isEqualTo []}) exitWith {[[], 0]};
if (isNil "_plan") then {_plan = [] call FUNC(planNets)};

private _table = [_kind, _plan] call FUNC(netTable);
private _channels = [LR_CHANNELS, SR_CHANNELS] select (_kind isEqualTo NODE_SR);
private _nets = [];
private _byFreq = 0;

for "_c" from 0 to (_channels - 1) do {
    private _freq = [_radio, _c + 1] call TFAR_fnc_getChannelFrequency;
    if (isNil "_freq" || {!(_freq isEqualType "")}) then {_freq = ""};
    private _key = FREQ_KEY(_freq);
    private _i = if (_key > 0) then {_table findIf {(_x select 1) == _key}} else {-1};
    if (_i >= 0) then {
        _byFreq = _byFreq + 1;
    } else {
        _i = _table findIf {(_x select 2) == _c};
    };
    _nets pushBack (if (_i < 0) then {""} else {(_table select _i) select 0});
};

[_nets, _byFreq]
