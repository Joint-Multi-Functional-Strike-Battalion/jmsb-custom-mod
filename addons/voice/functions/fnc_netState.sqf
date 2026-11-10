#include "script_component.hpp"
/*
 * Author: YonV
 * Per net of the local player, its state for the device net rows and the
 * RADIO app. reachable false = the red outline (on the net, no route).
 * talkers includes the player himself while he transmits (quality 1).
 * No rows while no game-voice system runs (system "none").
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[netId, name, kind, active, muted, ear "L"|"B"|"R", reachable, talkers [[unit, quality], ...],
 *   net quality 0-1 (FUNC(netQuality))], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_netState
 *
 * Public: Yes
 */

if (!hasInterface || isNull player || !GVAR(active)) exitWith {[]};

private _talking = GVAR(talkers);
GVAR(myNets) apply {
    _x params ["_net", "_name", "_kind"];
    private _talkers = (_talking select {(_x select 1) isEqualTo _net}) apply {
        [_x select 0, [_x select 0, _net] call FUNC(quality)]
    };
    private _quality = [_net] call FUNC(netQuality);
    [
        _net, _name, _kind,
        _net isEqualTo GVAR(activeNetId),
        GVAR(muted) getOrDefault [_net, false],
        GVAR(ears) getOrDefault [_net, EAR_BOTH],
        _quality > 0,
        _talkers,
        _quality
    ]
}
