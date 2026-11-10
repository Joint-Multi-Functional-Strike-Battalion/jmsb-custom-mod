#include "script_component.hpp"
/*
 * Author: YonV
 * The effective notification level for one arriving row: 0 rings, 1 badges.
 *
 * A thread the player has explicitly followed or muted answers with that -
 * the per-thread override beats the net's own level either way, which is what
 * the handoff asks of it. Otherwise a shared net answers with its subscription
 * level, and anything personal or group is always loud: your own name and your
 * own squad are not subscriptions, they are you.
 *
 * Levels are 0 ALERT / 1 MUTED. The handoff's BADGE and MUTE collapse into
 * one level here because the badge IS the rail's unread count, which moves on
 * every delivery regardless - the only thing a level can grant or withhold on
 * this surface is the banner. FLASH and being called out by name break
 * through a mute at the call site, not here - see FUNC(cltReceive).
 *
 * Arguments:
 * 0: Box id the row is filed under <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * Level - 0 alert, 1 muted <NUMBER>
 *
 * Example:
 * private _muted = (["B:HQ", "T0007"] call jmfsb_messaging_fnc_netLevel) > 0
 *
 * Public: Yes
 */

params [["_boxId", "", [""]], ["_threadId", "", [""]]];

private _override = GVAR(threadFollow) getOrDefault [_threadId, -1];
if (_override >= 0) exitWith {_override};

if ((_boxId select [0, 2]) != "B:") exitWith {0};

GVAR(netLevels) getOrDefault [_boxId select [2], 0]
