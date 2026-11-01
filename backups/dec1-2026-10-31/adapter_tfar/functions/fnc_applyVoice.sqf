#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: RF link quality onto TFAR's range levers for this player.
 *
 * RECEIVING is one lever per unit in TFAR, so it takes the best quality among
 * the nets he listens to - the active and the monitor net of every set he
 * holds (jmfsb_rf_fnc_quality, from his slice). He loses reception only when
 * every one of them is weak; a net he hears well is never cut by one he does
 * not.
 *
 * SENDING is per net: fnc_tangent sets it for the net being keyed, as the
 * tangent goes down. Here it is set for the short-range set's active net, so
 * the lever is never stale when nothing is keyed.
 *
 * THE RANGE FACTOR IS SPLIT between the two ends: sending sqrt(f) on the
 * talker, receiving 1/sqrt(f) on the listener. A link's quality is the same
 * from both ends (RF takes the weaker direction), so across one link the
 * range TFAR uses is f of normal - not f squared. Cut (f = 0) is
 * VOICE_CUT_FACTOR at either end.
 *
 * Raised by jmfsb_rf_linkChanged, by fnc_poll when a set's state changed, and
 * by the settings. Off (setting): both levers back to 1.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_applyVoice
 *
 * Public: No
 */

if (!hasInterface || {isNull player}) exitWith {};

private _unit = missionNamespace getVariable ["TFAR_currentUnit", player];
if (isNull _unit) then {_unit = player};

if (!GVAR(voiceEnabled)) exitWith {
    _unit setVariable [TF_SEND_VAR, 1];
    _unit setVariable [TF_RECV_VAR, 1];
};

private _srId = format [NODE_ID_FORMAT, getPlayerUID player, NODE_SR];
private _best = QUALITY_UNKNOWN;
private _sendFactor = 1;
{
    private _id = _x;
    (_y param [1, []]) params [["_on", []], ["_active", []], ["_monitor", []]];
    if !(_on param [1, false]) then {continue};
    {
        private _net = _x param [1, ""];
        if (_net isEqualTo "") then {continue};
        private _quality = [_id, _net] call EFUNC(rf,quality);
        _best = _best max _quality;
        if (_id isEqualTo _srId && _forEachIndex == 0) then {
            _sendFactor = [_quality] call FUNC(voiceFactor);
        };
    } forEach [_active, _monitor];
} forEach GVAR(sent);

private _recvFactor = [_best] call FUNC(voiceFactor);

if (GVAR(txKind) isEqualTo "") then {
    _unit setVariable [TF_SEND_VAR, sqrt (_sendFactor max VOICE_CUT_FACTOR)];
};
_unit setVariable [TF_RECV_VAR, 1 / sqrt (_recvFactor max VOICE_CUT_FACTOR)];
TRACE_2("voice levers",_sendFactor,_recvFactor);
