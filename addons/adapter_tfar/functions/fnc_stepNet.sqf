#include "script_component.hpp"
/*
 * Author: JMSB
 * Net up / down (keybind): the active set of that kind moves to the next or
 * previous net of its fill, skipping channels that carry none - "cycle the
 * fill on the active radio" (SPEC_TACNET voice_tfrs keybinds).
 *
 * Arguments:
 * 0: Kind of set "sr" | "lr" <STRING>
 * 1: Step, 1 next or -1 previous <NUMBER>
 *
 * Return Value:
 * The net now active, "" when nothing changed <STRING>
 *
 * Example:
 * ["sr", 1] call jmfsb_adapter_tfar_fnc_stepNet
 *
 * Public: No
 */

params [["_kind", NODE_SR, [""]], ["_step", 1, [0]]];

if (!hasInterface || {isNull player} || {isNil "TFAR_fnc_activeSwRadio"}) exitWith {""};

private _isSr = _kind isEqualTo NODE_SR;
private _radio = if (_isSr) then {call TFAR_fnc_activeSwRadio} else {call TFAR_fnc_activeLrRadio};
if (isNil "_radio") exitWith {""};
if (_radio isEqualTo "" || _radio isEqualTo []) exitWith {""};

private _nets = ([_radio, _kind] call FUNC(radioNets)) select 0;
private _count = count _nets;
if (_count == 0) exitWith {""};

private _current = _radio call ([TFAR_fnc_getLrChannel, TFAR_fnc_getSwChannel] select _isSr);
private _next = "";
for "_i" from 1 to (_count - 1) do {
    private _channel = (_current + _step * _i) mod _count;
    if (_channel < 0) then {_channel = _channel + _count};
    if ((_nets select _channel) isNotEqualTo "") exitWith {_next = _nets select _channel};
};
if (_next isEqualTo "") exitWith {""};

[_next, _kind] call FUNC(selectNet);
_next
