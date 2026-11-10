#include "script_component.hpp"
/*
 * Author: YonV
 * Client: the local player's own push-to-talk, on its edges (fnc_frame reads
 * the adapter's "ptt" hook every frame). SPEAKER-PUSHED KEYING: on key-down
 * the speaker himself tells everyone who can hear him on that net (the
 * adapter's "audience" hook, without him) with ONE event, jmfsb_voice_keyed
 * [speaker, net, on], and the same people again on key-up - so listeners set
 * his volume, show him talking and play the squelch without waiting for the
 * engine to report a remote speaker. Direct is not sent (it is never
 * touched).
 * Key-down on a net the block level closes (fnc_blockNeed): the blocked tone
 * and the reason, nothing sent. On a radio net he holds no set for: the
 * blocked tone, but the event still goes out so his voice is muted at the
 * listeners. Otherwise jmfsb_voice_talk [player, net, true], the TX click (or
 * the blocked tone with no route) and RF's tx state.
 *
 * Arguments:
 * 0: Key down <BOOL>
 * 1: Net id the key sends on, "" when none of ours <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, "C2"] call jmfsb_voice_fnc_transmit
 *
 * Public: No
 */

params [["_on", false, [false]], ["_net", "", [""]]];

if (isNull player) exitWith {};

// --- key-up: undo what the key-down did ---------------------------------------
if (!_on) exitWith {
    private _was = GVAR(keyNet);
    if (_was isEqualTo "") exitWith {};
    if (GVAR(keyLive)) then {
        [QGVAR(talk), [player, _was, false]] call CBA_fnc_localEvent;
        if (([_was] call FUNC(netKind)) in MESH_KINDS) then {
            ["rogerBeep", _was] call FUNC(playCue);
            {
                [_x, [["tx", false]]] call EFUNC(rf,setState);
            } forEach GVAR(myNodes);
        };
    };
    if (GVAR(keyAudience) isNotEqualTo []) then {
        [QGVAR(keyed), [player, _was, false], GVAR(keyAudience)] call CBA_fnc_targetEvent;
    };
    GVAR(keyNet) = "";
    GVAR(keyLive) = false;
    GVAR(keyAudience) = [];
};

// --- key-down -----------------------------------------------------------------
GVAR(keyNet) = "";
GVAR(keyLive) = false;
GVAR(keyAudience) = [];
if (_net isEqualTo "") exitWith {};

private _kind = [_net] call FUNC(netKind);
private _mesh = _kind in MESH_KINDS;
if (GVAR(level) >= ([_net] call FUNC(blockNeed))) exitWith {
    ["blocked", _net] call FUNC(playCue);
    [BLOCK_TITLE, GVAR(blockReason)] call EFUNC(notify,notify);
};

GVAR(keyNet) = _net;
if (_kind isNotEqualTo KIND_DIRECT) then {
    GVAR(keyAudience) = [player, _net] call HOOK("audience");
    if (GVAR(keyAudience) isNotEqualTo []) then {
        [QGVAR(keyed), [player, _net, true], GVAR(keyAudience)] call CBA_fnc_targetEvent;
    };
};

if !(_net in (GVAR(myNets) apply {_x select 0})) exitWith {
    if (_mesh) then {
        ["blocked", _net] call FUNC(playCue);
        [BLOCK_TITLE, format [REASON_NO_SET, [_net] call FUNC(netName)]] call EFUNC(notify,notify);
    };
};

GVAR(keyLive) = true;
[QGVAR(talk), [player, _net, true]] call CBA_fnc_localEvent;
if (!_mesh) exitWith {};
// THE BUSY TONE (user, 2026-10-30, the MPU5's): keying a net someone else is
// already talking on plays the busy cue in place of the TX chirp. The key
// still goes through - it is a warning, not a lockout.
private _busy = (GVAR(talkers) findIf {(_x select 1) isEqualTo _net && {(_x select 0) isNotEqualTo player}}) >= 0;
private _cue = switch (true) do {
    case (!([_net] call FUNC(reachable))): {"blocked"};
    case (_busy): {"busy"};
    default {"txChirp"};
};
[_cue, _net] call FUNC(playCue);
private _rfNet = [_net] call FUNC(rfNet);
{
    [_x, [["tx", true], ["activeNet", _rfNet]]] call EFUNC(rf,setState);
} forEach GVAR(myNodes);
