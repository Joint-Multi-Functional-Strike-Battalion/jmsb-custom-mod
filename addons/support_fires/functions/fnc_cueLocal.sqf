#include "script_component.hpp"
/*
 * Author: YonV
 * Client: plays the SHOT or SPLASH cue on the caller's machine (user,
 * 2026-11-02; FUNC(cue)) - CUE_SOUNDS, vanilla Arma 3 sounds. Sent by the
 * server by remoteExec and taken only from it (review S7).
 *
 * Arguments:
 * 0: The card, CARD_SHOT or CARD_SPLASH <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["shot"] remoteExecCall ["jmfsb_support_fires_fnc_cueLocal", _caller]
 *
 * Public: No
 */

params [["_card", "", [""]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("cueLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

private _at = CUE_SOUNDS findIf {(_x select 0) isEqualTo _card};
if (_at < 0) exitWith {};

playSoundUI [(CUE_SOUNDS select _at) select 1];
