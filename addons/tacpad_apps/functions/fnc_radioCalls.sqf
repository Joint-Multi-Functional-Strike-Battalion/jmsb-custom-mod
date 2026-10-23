#include "script_component.hpp"
/*
 * Author: JMSB
 * Keeps the last state a call reached (GVAR(radioLast), [state, time]) for the
 * LIVE CALL panel's line - a failure reason, the priority warning, the end -
 * and the player's recent contacts - the people of each call that went live,
 * newest first, at most RADIO_RECENT_MAX - for the RECENT row of the live call
 * and the walking view's quick add (FUNC(radioQuick)). Hung on the voice API's
 * jmfsb_voice_callState event (XEH_postInit); the members are read from
 * jmfsb_voice_fnc_calls while the call is still listed.
 *
 * Arguments (jmfsb_voice_callState):
 * 0: Call id <STRING>
 * 1: Its new state <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [QEGVAR(voice,callState), {_this call FUNC(radioCalls)}] call CBA_fnc_addEventHandler
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_state", "", [""]]];

GVAR(radioLast) = [_state, CBA_missionTime];

if (_state isNotEqualTo CALL_LIVE || {isNil QEFUNC(voice,calls)}) exitWith {};

private _calls = [] call EFUNC(voice,calls);
private _i = _calls findIf {(_x param [0, ""]) isEqualTo _callId};
if (_i < 0) exitWith {};

private _me = call CBA_fnc_currentUnit;
private _members = ((_calls select _i) param [2, [], [[]]]) select {!isNull _x && _x isNotEqualTo _me};
private _recent = _members + ((missionNamespace getVariable [QGVAR(radioRecent), []]) select {!isNull _x});
_recent = _recent arrayIntersect _recent;
_recent resize ((count _recent) min RADIO_RECENT_MAX);
GVAR(radioRecent) = _recent;
