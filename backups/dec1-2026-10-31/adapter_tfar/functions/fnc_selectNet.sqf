#include "script_component.hpp"
/*
 * Author: JMSB
 * PICK A NET, NOT A NUMBER: puts the player's active set of that kind on the
 * channel that carries the net (fnc_radioNets) - as its active net, or as its
 * alternate (TFAR's additional channel, our monitor net, keyed by the
 * alternate PTT). An empty net with alternate set takes the alternate off.
 * Only nets in the set's fill can be picked; load the fill first (fnc_fill).
 *
 * Arguments:
 * 0: Net id, "" (alternate only) for none <STRING>
 * 1: Kind of set "sr" | "lr" <STRING> (default: "sr")
 * 2: As the alternate (monitor) net <BOOL> (default: false)
 *
 * Return Value:
 * Done: the net is in the fill and is now selected <BOOL>
 *
 * Example:
 * ["C2"] call jmfsb_adapter_tfar_fnc_selectNet
 * ["A2G", "sr", true] call jmfsb_adapter_tfar_fnc_selectNet
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_kind", NODE_SR, [""]], ["_alternate", false, [false]]];

if (!hasInterface || {isNull player} || {isNil "TFAR_fnc_activeSwRadio"}) exitWith {false};

private _isSr = _kind isEqualTo NODE_SR;
private _radio = if (_isSr) then {call TFAR_fnc_activeSwRadio} else {call TFAR_fnc_activeLrRadio};
if (isNil "_radio") exitWith {false};
if (_radio isEqualTo "" || _radio isEqualTo []) exitWith {false};

private _current = if (_alternate) then {
    _radio call ([TFAR_fnc_getAdditionalLrChannel, TFAR_fnc_getAdditionalSwChannel] select _isSr)
} else {
    _radio call ([TFAR_fnc_getLrChannel, TFAR_fnc_getSwChannel] select _isSr)
};

// No alternate: TFAR's setter toggles the additional channel off when it is
// set to the one it already is.
if (_net isEqualTo "") exitWith {
    if (!_alternate) exitWith {false};
    if (_current > NO_CHANNEL) then {
        [_radio, _current] call ([TFAR_fnc_setAdditionalLrChannel, TFAR_fnc_setAdditionalSwChannel] select _isSr);
        [[], -1] call FUNC(poll);
    };
    true
};

private _channel = (([_radio, _kind] call FUNC(radioNets)) select 0) find _net;
if (_channel < 0) exitWith {false};
if (_channel == _current) exitWith {true};

if (_alternate) then {
    [_radio, _channel] call ([TFAR_fnc_setAdditionalLrChannel, TFAR_fnc_setAdditionalSwChannel] select _isSr);
} else {
    [_radio, _channel] call ([TFAR_fnc_setLrChannel, TFAR_fnc_setSwChannel] select _isSr);
};
[[], -1] call FUNC(poll);
true
