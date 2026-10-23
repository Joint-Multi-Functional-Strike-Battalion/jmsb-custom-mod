#include "script_component.hpp"
/*
 * Author: JMSB
 * Registers a voice adapter: the backend that carries the audio. adapter_von
 * registers "von", the default; any other adapter registered replaces it, and
 * the default never replaces another. Required hooks (code): "join" [unit,
 * net] and "leave" [unit, net] (server: membership), "quality" [unit, net, q
 * 0..1] (client: how loud the local player hears that speaker on that net,
 * grace and mute applied), "talking" [] -> [[unit, net], ...] (client, every
 * frame). Optional: "channel" [net] -> voice channel number (-1 none),
 * "setActive" [net] -> bool (make it what the PTT sends on), "current" [] ->
 * net the PTT sends on now, "block" [level] (0 none, 1 radio silence: radio
 * nets closed, 2 unconscious: every radio and the vehicle intercom closed,
 * 3 dead / no air: Direct closed too), "ptt" [] -> [down, net] (the local
 * player's own push-to-talk, every frame), "keyed" [unit, net, on] (a remote
 * speaker's pushed key event: apply his volume, count him as talking until
 * key-up), "audience" [unit, net] -> units (who can hear him on that net;
 * default the net's members), "selfTest" [].
 *
 * UNDER TFAR / ACRE (jmfsb_voice_system "tfar" / "acre") only the adapter of
 * that id is taken, and its required hooks are the external radio's:
 * "nets" [] -> [[net, name, kind, -1], ...], "netState" [] -> [[net, name,
 * kind, active, muted, ear, reachable], ...], "talking" [] -> [[unit, net],
 * ...] (others); optional "current", "setActive", "ptt", "setEar" [net,
 * ear] -> bool, "setMute" [net, muted] -> bool, "linkQuality" [speaker,
 * net] -> 0..1, "selfTest". VON's adapter is refused there, and a radio
 * adapter under VON.
 *
 * Arguments:
 * 0: Adapter id <STRING>
 * 1: Hooks <HASHMAP>: "join" {[unit, net]}, "leave" {[unit, net]},
 *    "quality" {[unit, net, q 0..1]}, "talking" {-> [[unit, net], ...]}
 *
 * Return Value:
 * true when registered <BOOL>
 *
 * Example:
 * ["von", _hooks] call jmfsb_voice_fnc_registerAdapter
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_hooks", createHashMap, [createHashMap]]];

if (_id isEqualTo "") exitWith {false};
private _external = !GVAR(active);
if (_external && _id isNotEqualTo GVAR(system)) exitWith {false};
if (!_external && _id in [SYSTEM_TFAR, SYSTEM_ACRE]) exitWith {false};
private _missing = ([HOOKS_REQUIRED, HOOKS_REQUIRED_EXTERNAL] select _external) select {!((_hooks getOrDefault [_x, 0]) isEqualType {})};
if (_missing isNotEqualTo []) exitWith {
    WARNING_2("adapter %1 refused: no %2",_id,_missing);
    false
};
// the default never displaces an adapter a mission or mod chose
if (_id isEqualTo DEFAULT_ADAPTER && GVAR(adapterId) isNotEqualTo "" && GVAR(adapterId) isNotEqualTo DEFAULT_ADAPTER) exitWith {false};

private _adapter = +GVAR(adapterDefaults);
{
    if (_y isEqualType {}) then {_adapter set [_x, _y]};
} forEach _hooks;
GVAR(adapter) = _adapter;
GVAR(adapterId) = _id;
INFO_1("voice adapter %1",_id);
true
