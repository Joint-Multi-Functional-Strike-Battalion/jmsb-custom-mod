#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a card is one only the asset sends in a support thread (2026-11-02):
 * a reply moving the thread to THREAD_ASSET_STATES - ROGER, WILCO, ON TASK,
 * CANTCO - that is not one of the issuer's own calls, or a card marked as
 * what the asset says (assetOnly, 2026-11-09: SHOT, SPLASH, WHEELS DOWN,
 * STATUS REPLY, IP INBOUND ... - "never in the requester's menu"). FFE also
 * moves a fire mission to IN_PROGRESS and is the observer's; CLEARED HOT, the
 * stops and every follow-up word are the issuer's (FUNC(srvReply)'s own
 * exclusion). The same answer on the server, which refuses such a card from a
 * player (FUNC(srvThreadCard)), and on the client, whose reader does not
 * offer it (jmfsb_tacpad_fnc_threadLegal).
 *
 * Arguments:
 * 0: Card id <STRING>
 *
 * Return Value:
 * Only the asset sends it <BOOL>
 *
 * Example:
 * ["inprogress"] call jmfsb_support_fnc_assetCard
 *
 * Public: Yes
 */

params [["_cardId", "", [""]]];

if (_cardId isEqualTo "") exitWith {false};
if (_cardId in ([CARD_CLEARED_HOT] + CARDS_STOP + (FOLLOW_UP_WORDS apply {_x select 0}))) exitWith {false};

private _card = [_cardId] call EFUNC(messaging,template);
if ((_card getOrDefault ["assetOnly", false]) isEqualTo true) exitWith {true};
(_card getOrDefault ["kind", CARD_KIND_ROOT]) isNotEqualTo CARD_KIND_ROOT
    && (_card getOrDefault ["transitionsTo", ""]) in THREAD_ASSET_STATES
