#include "script_component.hpp"
/*
 * Author: YonV
 * A manual RF burst, asked for from the map panel (server, the one arbiter).
 * The same conditions the automatic burst needs - the vehicle is crewed,
 * running and not too badly hit, and the emitter is off its cooldown - and
 * nothing else: RF HOLD stops the emitter firing on its OWN, not the crew
 * firing it. A request the emitter cannot honour is dropped, and the panel
 * already shows why.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * Fired <BOOL>
 *
 * Example:
 * [_tank] remoteExec ["jmfsb_aps_fnc_burstNow", 2]
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];
if (!isServer || {isNull _veh} || {!alive _veh}) exitWith { false };
if !(_veh getVariable [QGVAR(rf), false]) exitWith { false };

private _live = (crew _veh) isNotEqualTo [] && {isEngineOn _veh}
    && {CBA_missionTime >= (_veh getVariable [QGVAR(rfReady), 0])}
    && {damage _veh < GVAR(rfDamage)} && {(_veh getHitPointDamage "HitEngine") < 0.9};
if (!_live) exitWith {
    if (GVAR(debug)) then { INFO_1("%1: manual burst refused - emitter not live",typeOf _veh) };
    false
};

[_veh] call FUNC(burst);
true
