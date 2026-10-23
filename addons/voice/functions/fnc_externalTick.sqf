#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, EXTERNAL-RADIO mode only (TFAR or ACRE loaded, jmfsb_voice_system
 * "tfar" / "acre"), every EXTERNAL_TICK_S: mirrors that radio's adapter for
 * the UIs, so they read the same API as under VON.
 *
 *   - every CLIENT_TICK_S: his nets (hook "nets") and the active net (hook
 *     "current"); jmfsb_voice_netsChanged when either moved;
 *   - every tick: who talks (hook "talking": the others; hook "ptt": himself
 *     while his key is down), and jmfsb_voice_talk [unit, net, on] for each
 *     speaker who started or stopped.
 *
 * Nothing of VON is touched: no channel, volume, block, call or sound.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_voice_fnc_externalTick
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (GVAR(active) || {isNull player}) exitWith {};

if (CBA_missionTime >= GVAR(extNetsAt)) then {
    GVAR(extNetsAt) = CBA_missionTime + CLIENT_TICK_S;
    private _nets = [] call HOOK("nets");
    private _active = [] call HOOK("current");
    if (_nets isNotEqualTo GVAR(myNets) || _active isNotEqualTo GVAR(activeNetId)) then {
        GVAR(myNets) = _nets;
        GVAR(activeNetId) = _active;
        [QGVAR(netsChanged), []] call CBA_fnc_localEvent;
    };
};

private _now = +([] call HOOK("talking"));
([] call HOOK("ptt")) params [["_down", false, [false]], ["_keyNet", "", [""]]];
if (_down && _keyNet isNotEqualTo "") then {_now pushBack [player, _keyNet]};

{
    _x params ["_unit", "_net"];
    [QGVAR(talk), [_unit, _net, false]] call CBA_fnc_localEvent;
} forEach (GVAR(talkers) - _now);
{
    _x params ["_unit", "_net"];
    [QGVAR(talk), [_unit, _net, true]] call CBA_fnc_localEvent;
} forEach (_now - GVAR(talkers));
GVAR(talkers) = _now;
