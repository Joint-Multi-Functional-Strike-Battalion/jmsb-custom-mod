#include "script_component.hpp"
/*
 * Author: YonV
 * Server: what a support aircraft says on its way in to a point of the
 * request, called by the provider's watch every tick of the leg (user,
 * 2026-11-01: "need more information like after rw inbound eta etc etc and an
 * alert to pop smoke when its close"). One place for the words, so transport,
 * casevac, airdrop, resupply and QRF say the same:
 *
 *   every TRANSPORT_ETA_UPDATE_S   INBOUND "ETA m:ss - <grid of the aircraft>"
 *                                  (the `inbound` card) - the launch's WHEELS
 *                                  UP said the first ETA
 *   ONE_MIN_OUT s out              1 MIN OUT - POP SMOKE (or the card's
 *   (or inside the provider's      marking: POP IR, POP FLARE), FLASH, as a
 *   ring)                          `prompt` - folded with what the asset asks
 *                                  there into one message ("1 MIN OUT - POP
 *                                  SMOKE - 1 MIN - LZ STATUS?", its answers and
 *                                  the D9 waits) - and the issuer's own popup
 *                                  "<CALLSIGN> 1 MIN OUT - POP SMOKE"
 *                                  (FUNC(alertLocal), upper right). Said once
 *                                  per leg; nothing more on it after that
 *
 * A NEW LEG is a new point: the counts start again. Quiet when the thread is
 * no longer the asset's or is over.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: Call sign <STRING>
 * 3: The aircraft <OBJECT>
 * 4: The point it flies to <ARRAY>
 * 5: The card's marking words, "" for none - SMOKE <STRING>
 * 6: What it asks at 1 MIN OUT, "" for nothing <STRING> (optional, default "")
 * 7: The answers to that, reply ids comma-separated <STRING> (optional, default "")
 * 8: What it does after PROMPT_END s with no answer, [assetId, threadId] - for
 *    an ask only (FUNC(prompt)) <CODE> (optional, default {})
 * 9: 1 MIN OUT inside this many metres too, 0 for the ETA alone <NUMBER> (optional, default 0)
 *
 * Return Value:
 * 1 MIN OUT was said on this call <BOOL>
 *
 * Example:
 * [_assetId, _threadId, "RAVEN", _heli, _lz, "SMOKE", "1 MIN - LZ STATUS?", "cold,hot", _onEnd, 1000] call jmfsb_support_fnc_inbound
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_callsign", "", [""]],
    ["_vehicle", objNull, [objNull]],
    ["_point", [], [[]]],
    ["_marking", "", [""]],
    ["_ask", "", [""]],
    ["_answers", "", [""]],
    ["_onEnd", {}, [{}]],
    ["_near", 0, [0]]
];

if (!isServer || _threadId isEqualTo "") exitWith {false};
if (isRemoteExecuted) exitWith {
    WARNING_2("inbound: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_assetId);
    false
};
if (!alive _vehicle || count _point < 2) exitWith {false};
if (((localNamespace getVariable [QGVAR(threadAssets), createHashMap]) getOrDefault [_threadId, ""]) isNotEqualTo _assetId) exitWith {false};
private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {false};
if (_thread getOrDefault ["closed", false]) exitWith {false};
if ((_thread getOrDefault ["status", ""]) in STATES_OVER) exitWith {false};

// The leg: [point, next ETA update, 1 MIN OUT said].
private _legs = localNamespace getVariable [QGVAR(inboundLegs), createHashMap];
localNamespace setVariable [QGVAR(inboundLegs), _legs];
private _leg = _legs getOrDefault [_threadId, []];
if ((_leg param [0, []]) isNotEqualTo _point) then {
    _leg = [_point, CBA_missionTime + TRANSPORT_ETA_UPDATE_S, false];
    _legs set [_threadId, _leg];
};
if (_leg select 2) exitWith {false};

private _eta = [_vehicle, _point] call FUNC(etaTo);
private _close = _near > 0 && _vehicle distance2D _point < _near;

// --- 1 MIN OUT ----------------------------------------------------------------
if ((_eta >= 0 && _eta <= ONE_MIN_OUT) || _close) exitWith {
    _leg set [2, true];

    // The marking the card asks for, by its words; SMOKE without one.
    private _line = format [ONE_MIN_OUT_TEXT, [_marking] call FUNC(popWord)];

    private _asks = _ask isNotEqualTo "";
    private _text = [_line, format [ONE_MIN_OUT_ASKS, _line, _ask]] select _asks;
    [_assetId, _threadId, _text, _answers, _callsign, _onEnd, _asks, true] call FUNC(prompt);

    // The issuer's popup, upper right.
    private _issuerUid = [_thread] call FUNC(threadIssuer);
    private _at = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
    if (_at >= 0) then {
        [format ["%1 %2", _callsign, _line]] remoteExecCall [QFUNC(alertLocal), allPlayers select _at];
    };
    INFO_3("thread %1: %2 - %3",_threadId,_assetId,_text);
    true
};

// --- INBOUND, every TRANSPORT_ETA_UPDATE_S ----------------------------------------
if (CBA_missionTime < (_leg select 1)) exitWith {false};
_leg set [1, CBA_missionTime + TRANSPORT_ETA_UPDATE_S];
private _said = [[_eta] call FUNC(etaText), mapGridPosition _vehicle] select {_x isNotEqualTo ""};
[_assetId, _threadId, CARD_INBOUND, [[INBOUND_TEXT_KEY, _said joinString INBOUND_SEP]], _callsign] call FUNC(fileCard);
false
