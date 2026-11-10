#include "script_component.hpp"
/*
 * Author: YonV
 * Server: registers code that rules on a card a player files into a thread
 * that is already open (FUNC(srvThreadFor)) - for a system that owns some
 * threads without this addon knowing it. The support core rules on the
 * threads its assets answer (2026-11-02): the asset's own cards it takes as a
 * new task there (a re-task, a NEXT LIFT), and the states that are the
 * asset's to send (ROGER, WILCO, ON TASK, CANTCO), never the issuer's.
 *
 * ASKED IN THE CALL, NOT THE FRAME AFTER. Unlike FUNC(onFiled), the answer
 * decides whether the card is filed at all, so each hook runs inside
 * FUNC(srvThreadFor) and must be quick and change nothing. Only a player's
 * card is ruled on - the server's own filings (an asset's states, through the
 * call sign override) are never put to the hooks. The first hook with an
 * answer decides:
 *
 *   ""                  no opinion - the thread is not the hook's
 *   THREAD_CARD_TAKE    taken: a ROOT card may go into this thread
 *   anything else       refused, with that as the reason
 *
 * A root card (kind "root") that no hook takes is refused: it opens a thread.
 *
 * Not a CBA event: the hooks live in localNamespace, which is not networked.
 * Server only, local calls only: a remote-executed call is dropped.
 *
 * Arguments:
 * 0: Code, run with [thread <HASHMAP>, template <HASHMAP>, sender <OBJECT>],
 *    answering a STRING <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_thread", "_template", "_unit"]; ""}] call jmfsb_messaging_fnc_onThreadCard
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (!isServer || isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(threadCardHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(threadCardHooks), _hooks];
