#include "script_component.hpp"
/*
 * Author: JMSB
 * The leg home every sortie ends with, one tick at a time - shared by the
 * CAS, drop and QRF watches so the four kinds of aircraft go home the same
 * way. Phases, in the sortie's state hashmap:
 *
 *   "home"     turn for the module (or the synced aircraft's stand)
 *   "homing"   on the way. A CLASS aircraft is removed over the module; a
 *              synced helicopter lands on its stand, a synced plane at the
 *              nearest airfield
 *   "parking"  a synced aircraft settling. Down, it is shut down, refuelled
 *              and re-armed for the next sortie - it IS the asset
 *
 * Patience: a leg home that has not finished by "homeBy" ends anyway - a
 * class aircraft is removed where it is, a synced one is left where it is.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The sortie's state <HASHMAP>
 *
 * Return Value:
 * The sortie is over <BOOL>
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_homeTick
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]]];

private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _synced = !isNull (_logic getVariable [QGVAR(synced), objNull]);
private _phase = _st getOrDefault ["phase", "home"];

private _fnc_done = {
    if (!_synced) then {[_veh] call FUNC(sweep)};
    [_logic] call FUNC(finish);
    true
};

// A CLASS AIRCRAFT WITH AN EXIT (a CAS sortie flown Simplex-style, in on
// the ingress and out on the egress) leaves by it and is removed there
// rather than flying back to the module.
private _exit = _st getOrDefault ["exit", []];
if (!_synced && {_exit isNotEqualTo []}) then {_home = _exit};

if (_phase isEqualTo "home") exitWith {
    _st set ["phase", "homing"];
    _st set ["homeBy", CBA_missionTime + SORTIE_TIMEOUT];
    _logic setVariable [QGVAR(status), "rtb", true];
    _logic setVariable [QGVAR(plan), [[_home, [PLAN_BASE, PLAN_EGRESS] select (!_synced && {_exit isNotEqualTo []})]], true];
    _veh flyInHeight (((getPos _veh) select 2) max HOME_HEIGHT);
    if (_synced && {!(_veh isKindOf "Helicopter")}) then {
        if ([_veh, _home] call FUNC(landAt)) then {_st set ["phase", "parking"]};
    } else {
        [_veh, _home, "FULL"] call FUNC(moveTo);
    };
    false
};

if (CBA_missionTime > (_st getOrDefault ["homeBy", 1e10])) exitWith {
    WARNING_1("%1 did not make it home in time - sortie ended where it is",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")]);
    call _fnc_done
};

if (_phase isEqualTo "homing") exitWith {
    if (!_synced) exitWith {
        if (_veh distance2D _home < HOME_RING) exitWith {call _fnc_done};
        false
    };
    if (_veh distance2D _home < ARRIVE_RING) then {
        [_veh, _home, "LAND"] call FUNC(landAt);
        _st set ["phase", "parking"];
    };
    false
};

if (_phase isEqualTo "parking") exitWith {
    if !(isTouchingGround _veh && {speed _veh < SETTLED_SPEED}) exitWith {false};
    [_logic, _veh] call FUNC(rearm);
    [_logic, "is down at base", "normal"] call FUNC(say);
    [_logic] call FUNC(finish);
    true
};

false
