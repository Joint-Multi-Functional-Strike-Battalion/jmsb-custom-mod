#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, on TFAR's OnBeforeTangent and OnTangent: a set is keyed or released.
 *
 *   before, down - the sending lever is set for the net being keyed (the
 *                  set's active net, or its monitor net on the additional
 *                  tangent) from that net's RF quality, before TFAR reads it
 *                  to price the transmission;
 *   after        - the set's RF state "tx" follows the tangent (fnc_poll
 *                  sends it now, not on the next poll), so RF knows who is
 *                  emitting; on release the levers go back to fnc_applyVoice.
 *                  The key edge is also PUSHED to the other players of his
 *                  side (jmfsb_adapter_tfar_keyed [speaker, net, on], one
 *                  event per edge), so their voice API lists him as talking
 *                  on that net (fnc_talking); his own "ptt" hook reads
 *                  [true, net] while it is down.
 *
 * Direct speech (TFAR OnSpeak) is not radio and is not reported.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Radio <STRING or ARRAY>
 * 2: TFAR radio type, 0 short range, 1 long range <NUMBER>
 * 3: Additional (monitor) channel <BOOL>
 * 4: Tangent down <BOOL>
 * 5: Before the transmission is priced (OnBeforeTangent) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _radio, 0, false, true, true] call jmfsb_adapter_tfar_fnc_tangent
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_radio", "", ["", []]],
    ["_type", TFAR_TYPE_SR, [0]],
    ["_additional", false, [false]],
    ["_down", false, [false]],
    ["_before", false, [false]]
];

private _kind = [_radio, _type] call FUNC(radioKind);
private _id = format [NODE_ID_FORMAT, getPlayerUID player, _kind];
private _state = (GVAR(sent) getOrDefault [_id, [[], []]]) select 1;
private _net = (_state param [[1, 2] select _additional, []]) param [1, ""];

if (_before) exitWith {
    if (!_down || {!GVAR(voiceEnabled)}) exitWith {};
    private _quality = if (_net isEqualTo "") then {QUALITY_UNKNOWN} else {[_id, _net] call EFUNC(rf,quality)};
    private _factor = [_quality] call FUNC(voiceFactor);
    _unit setVariable [TF_SEND_VAR, sqrt (_factor max VOICE_CUT_FACTOR)];
    TRACE_3("keyed",_id,_net,_factor);
};

// the key edge to his side's players (the release names the net that was keyed)
private _sent = [GVAR(txNet), _net] select _down;
if (_sent isNotEqualTo "") then {
    private _side = side group player;
    private _targets = allPlayers select {_x isNotEqualTo player && side group _x isEqualTo _side};
    if (_targets isNotEqualTo []) then {
        [QGVAR(keyed), [_unit, _sent, _down], _targets] call CBA_fnc_targetEvent;
    };
};

GVAR(txKind) = ["", _kind] select _down;
GVAR(txNet) = ["", _net] select _down;
[[], -1] call FUNC(poll);
