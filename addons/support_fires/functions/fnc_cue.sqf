#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the SHOT or SPLASH cue (user, 2026-11-02; a splash cue is Tun
 * Firesupport's idea, by Tuntematon / Armafinland) - as the battery files SHOT
 * or SPLASH in the thread a call for fire tasked it with (FUNC(threadVolley)),
 * the caller hears a short sound on his own machine: the issuer and the
 * card's observer, each once. By remoteExec to FUNC(cueLocal), which takes
 * it only from the server (review S7).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The card, CARD_SHOT or CARD_SPLASH <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "splash"] call jmfsb_support_fires_fnc_cue
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_card", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};

private _order = _logic getVariable [QGVAR(threadOrder), createHashMap];
private _to = [_order getOrDefault ["issuer", objNull], _order getOrDefault ["observer", objNull]] select {isPlayer _x};
_to = _to arrayIntersect _to;
if (_to isEqualTo []) exitWith {};

[_card] remoteExecCall [QFUNC(cueLocal), _to];
