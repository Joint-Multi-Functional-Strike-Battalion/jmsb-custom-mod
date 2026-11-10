#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the safety net under a clear spot for the rotor (2026-11-02, the
 * user's RPT 07:37:53: "RAVEN transport cannot fly - canMove false - too
 * damaged to fly (damage 0.00; hit points hithrotor 1.00 ... never hit)", the
 * second write-off of that kind). A transport helicopter that cannot fly only
 * because a rotor is wrecked - no other hit point past FAULT_HIT_FLOOR, no
 * damage to speak of - that nothing has hit and that has not yet been
 * HOME_RING m from its airfield is repaired once a sortie and logged, not
 * written off. A second time it is written off as before (FUNC(transportTick)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 * 2: The watch's state <HASHMAP>
 *
 * Return Value:
 * Repaired <BOOL>
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_rotorRepair
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]]];

if (!alive _veh || !(_veh isKindOf "Helicopter")) exitWith {false};
if (_st getOrDefault ["rotorFixed", false]) exitWith {false};
if (_st getOrDefault ["away", false]) exitWith {false};
if ((_veh getVariable [QGVAR(lastHit), []]) isNotEqualTo []) exitWith {false};
if (damage _veh > FAULT_HIT_FLOOR) exitWith {false};
if (!alive driver _veh) exitWith {false};

(getAllHitPointsDamage _veh) params [["_names", []], "", ["_values", []]];
private _rotors = [];
private _other = false;
{
    if (_x > FAULT_HIT_FLOOR) then {
        private _name = _names param [_forEachIndex, ""];
        if (ROTOR_WORD in toLower _name) then {_rotors pushBack _name} else {_other = true};
    };
} forEach _values;
if (_other || _rotors isEqualTo []) exitWith {false};

{
    _veh setHitPointDamage [_x, 0];
} forEach _rotors;
_st set ["rotorFixed", true];
WARNING_4("%1 transport: %2 wrecked at %3 before it left its airfield, nothing hit it - repaired once, not written off (%4)",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_rotors joinString ", ",mapGridPosition _veh,typeOf _veh);
true
