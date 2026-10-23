#include "script_component.hpp"
/*
 * Author: JMSB
 * Per net of the local player, its state for the device net rows and the
 * RADIO app. reachable false = the red outline (on the net, no route).
 * talkers includes the player himself while he transmits (quality 1).
 * Under TFAR / ACRE the rows are that radio's adapter's (hook "netState":
 * active = the set in hand, muted / ear = the radio's own volume and stereo
 * side, reachable = the set is on), talkers added here.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[netId, name, kind, active, muted, ear "L"|"B"|"R", reachable, talkers [[unit, quality], ...],
 *   net quality 0-1 (FUNC(netQuality); under TFAR / ACRE 1 when reachable)], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_netState
 *
 * Public: Yes
 */

if (!hasInterface || isNull player) exitWith {[]};

private _talking = GVAR(talkers);
if (!GVAR(active)) exitWith {
    ([] call HOOK("netState")) apply {
        private _net = _x param [0, ""];
        private _talkers = (_talking select {(_x select 1) isEqualTo _net}) apply {
            [_x select 0, [_x select 0, _net] call FUNC(quality)]
        };
        (_x select [0, EXTERNAL_STATE_COLS]) + [_talkers, parseNumber ((_x param [6, false]) isEqualTo true)]
    }
};
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
