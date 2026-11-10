#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an asset asks STATE INTENTIONS in its thread (docs/DESIGN_MESSAGE_
 * TEMPLATES.md, 2026-11-09: after an ABORT - "the asset then asks for
 * intentions" - or wherever a provider has nothing left to do and is not
 * going home). An ASSET ASKS (FUNC(prompt)) whose answers are MOVE, HOLD,
 * FRAGO and RTB plus what the provider adds (the starters it flies, so the
 * next tasking is one press); the reader offers them as quick replies. The
 * D9 waits run on it as on every prompt; with no answer the provider's own
 * end runs.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: Call sign <STRING>
 * 3: What it says first - "ABORTED", "HOLDING" - "" for nothing <STRING> (optional, default "")
 * 4: More answers, comma separated - card ids <STRING> (optional, default "")
 * 5: No answer for PROMPT_END s, [assetId, threadId] <CODE> (optional, default {})
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:0", "T0042", "RAVEN", "ABORTED", "cas"] call jmfsb_support_fnc_askIntentions
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_callsign", "", [""]],
    ["_first", "", [""]],
    ["_more", "", [""]],
    ["_onEnd", {}, [{}]]
];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "") exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("askIntentions: refused - remote call from machine %1",remoteExecutedOwner);
};

private _text = [PROMPT_INTENTIONS, format [PROMPT_INTENTIONS_WHY, _first]] select (_first isNotEqualTo "");
private _answers = [ANSWERS_INTENTIONS, _more] select {_x isNotEqualTo ""};
[_assetId, _threadId, _text, _answers joinString ",", _callsign, _onEnd] call FUNC(prompt);
