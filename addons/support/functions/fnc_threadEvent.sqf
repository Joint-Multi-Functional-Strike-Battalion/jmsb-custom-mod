#include "script_component.hpp"
/*
 * Author: YonV
 * Server: something happened to an asset that the man who called it should
 * read in its thread (user, 2026-11-05: "needs messaging to notify of events
 * like that" - a transport under missile fire, flaring, shot down, had only
 * said so in the RPT and on the side rail). The asset files a MESSAGE card
 * with the line in the thread, FLASH when it matters, and the issuer gets the
 * upper-right popup (FUNC(alertLocal)). A thread that is not the asset's, or
 * closed, takes nothing.
 *
 * The providers reach it through the CBA event EVENT_AIRCRAFT [aircraft,
 * line, flash] (raised by the core's escort watch and their own hit watches)
 * - each maps the aircraft to its asset and open threads and calls this.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: The line, without the call sign <STRING>
 * 3: FLASH <BOOL> (optional, default false)
 * 4: The asset's call sign <STRING> (optional, default "")
 *
 * Return Value:
 * Filed <BOOL>
 *
 * Example:
 * ["air:0", "T0042", "MISSILE - FLARES OUT", true, "RAVEN"] call jmfsb_support_fnc_threadEvent
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]], ["_line", "", [""]], ["_flash", false, [false]], ["_callsign", "", [""]]];

if (!isServer || _threadId isEqualTo "" || _line isEqualTo "") exitWith {false};
if (((localNamespace getVariable [QGVAR(threadAssets), createHashMap]) getOrDefault [_threadId, ""]) isNotEqualTo _assetId) exitWith {false};
private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap || {_thread getOrDefault ["closed", false]}) exitWith {false};

[_assetId, _threadId, CARD_FREETEXT, [[FREETEXT_KEY, _line]], _callsign, ["", "high"] select _flash] call FUNC(fileCard);

private _issuerUid = [_thread] call FUNC(threadIssuer);
private _at = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
if (_at >= 0) then {
    [format ["%1 %2", _callsign, _line]] remoteExecCall [QFUNC(alertLocal), allPlayers select _at];
};
INFO_3("thread %1: %2 - %3",_threadId,_assetId,_line);
true
