#include "script_component.hpp"
/*
 * Author: YonV
 * Follows, mutes, or forgets one thread for THIS player.
 *
 * The per-thread override the handoff puts in the thread view: it beats the
 * net's subscription level either way, so a man can follow one CASEVAC on a
 * net he keeps muted, or silence one long argument on a net he keeps loud.
 *
 * Session-scoped on purpose. Thread ids are born and die with the mission -
 * persisting a follow for T0007 would follow a different conversation next
 * week - so this lives in missionNamespace while net levels persist in the
 * profile. See FUNC(setNetLevel).
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: State - 0 follow, 1 mute, -1 back to the net's own level <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["T0007", 0] call jmfsb_messaging_fnc_follow
 *
 * Public: Yes
 */

params [["_threadId", "", [""]], ["_state", -1, [0]]];

if (_threadId == "") exitWith {};

if (_state < 0) then {
    GVAR(threadFollow) deleteAt _threadId;
} else {
    GVAR(threadFollow) set [_threadId, _state min 1];
};
