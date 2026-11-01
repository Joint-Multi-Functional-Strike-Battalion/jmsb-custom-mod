#include "script_component.hpp"
/*
 * Author: JMSB
 * Registers a voice adapter: a backend that can carry the audio. adapter_von
 * registers "von" and adapter_livekit "livekit", each in its preInit; every
 * one is kept, and the one in use is the system's (FUNC(applyAdapter): under
 * VON the last registered that is not LiveKit's, else "von"; under LiveKit
 * the one of that id). A registration after the system was chosen is applied
 * at once when it is the one wanted.
 *
 * An adapter's required hooks (code): "join" [unit, net] and "leave"
 * [unit, net] (server: membership), "quality" [unit, net, q 0..1] (client:
 * how loud the local player hears that speaker on that net, grace and mute
 * applied), "talking" [] -> [[unit, net], ...] (client, every frame).
 * Optional: "channel" [net] -> voice channel number (-1 none), "setActive"
 * [net] -> bool (make it what the PTT sends on), "current" [] -> net the PTT
 * sends on now, "block" [level] (0 none, 1 radio silence: radio nets closed,
 * 2 unconscious: every radio and the vehicle intercom closed, 3 dead / no
 * air: Direct closed too), "ptt" [] -> [down, net] (the local player's own
 * push-to-talk, every frame), "keyed" [unit, net, on] (a remote speaker's
 * pushed key event: apply his volume, count him as talking until key-up),
 * "audience" [unit, net] -> units (who can hear him on that net; default the
 * net's members), "selfTest" [].
 *
 * Arguments:
 * 0: Adapter id <STRING>
 * 1: Hooks <HASHMAP>: "join" {[unit, net]}, "leave" {[unit, net]},
 *    "quality" {[unit, net, q 0..1]}, "talking" {-> [[unit, net], ...]}
 *
 * Return Value:
 * true when registered (kept; in use once it is the system's) <BOOL>
 *
 * Example:
 * ["von", _hooks] call jmfsb_voice_fnc_registerAdapter
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_hooks", createHashMap, [createHashMap]]];

if (_id isEqualTo "") exitWith {false};
private _missing = HOOKS_REQUIRED select {!((_hooks getOrDefault [_x, 0]) isEqualType {})};
if (_missing isNotEqualTo []) exitWith {
    WARNING_2("adapter %1 refused: no %2",_id,_missing);
    false
};

GVAR(adapters) set [_id, _hooks];
GVAR(adapterIds) pushBackUnique _id;
INFO_1("voice adapter %1 registered",_id);
[] call FUNC(applyAdapter);
true
