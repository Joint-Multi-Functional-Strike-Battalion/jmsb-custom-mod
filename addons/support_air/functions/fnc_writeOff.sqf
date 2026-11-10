#include "script_component.hpp"
/*
 * Author: YonV
 * Server, on a sortie's watch: is the airframe still one - or disabled, and
 * so lost? (user, 2026-11-02: an airframe "destroyed / crew dead / disabled
 * and abandoned" uses a respawn). Was the transport watch's own test
 * (2026-11-01); every kind runs it now.
 *
 * NOT ON ONE TICK, AND NEVER WITHOUT A REASON (2026-11-01). RAVEN was written
 * off two minutes into an orbit with "cannot fly" and "lost to ''" - the RPT
 * could not say which test failed. The verdict must hold for FAULT_GRACE
 * seconds (a seat empty for a moment, a reading taken mid-change, is not a
 * lost airframe), and both lines name the failed test (FUNC(flightFault)),
 * the airframe's state and the last thing that hit it, which is also the
 * killer passed on. THE SAFETY NET (2026-11-02, the user's RPT 07:37:53): a
 * helicopter whose only damage is a rotor, before it has left its airfield,
 * is repaired once instead (FUNC(rotorRepair)).
 *
 * Written off: the loss is counted (FUNC(lost) - the respawn count) and the
 * airframe is let go of, so a later wreck is not counted twice. Never swept
 * here: players may be aboard.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The airframe <OBJECT>
 * 2: The watch's state <HASHMAP>
 *
 * Return Value:
 * WRITE_OFF_NONE flying, WRITE_OFF_PENDING within the grace, WRITE_OFF_DONE written off <NUMBER>
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_writeOff
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]]];

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
if (!(_st getOrDefault ["away", false]) && _veh distance2D (_logic getVariable [QGVAR(home), getPosATL _logic]) > HOME_RING) then {
    _st set ["away", true];
};
([_veh] call FUNC(flightFault)) params ["_fault", "_faultState", "_hitBy"];
if (_fault isNotEqualTo "" && {[_logic, _veh, _st] call FUNC(rotorRepair)}) then {
    WARNING_2("%1: %2 - repaired, not written off",_callsign,_faultState);
    _fault = "";
};
private _faultSince = _st getOrDefault ["faultSince", -1];
if (_fault isEqualTo "") exitWith {
    if (_faultSince >= 0) then {
        _st set ["faultSince", -1];
        INFO_1("%1 can fly again - not written off",_callsign);
    };
    WRITE_OFF_NONE
};
if (_faultSince < 0) then {
    _faultSince = CBA_missionTime;
    _st set ["faultSince", _faultSince];
    WARNING_4("%1 cannot fly - %2 (%3) - written off in %4 s unless it recovers",_callsign,_fault,_faultState,FAULT_GRACE);
    // Said in its threads at once (user, 2026-11-05).
    [QEGVAR(support,aircraftEvent), [_veh, format [EVENT_CANNOT_FLY, toUpper _fault, mapGridPosition _veh], true]] call CBA_fnc_localEvent;
};
if (CBA_missionTime - _faultSince < FAULT_GRACE) exitWith {WRITE_OFF_PENDING};

WARNING_3("%1 cannot fly - sortie written off: %2 (%3)",_callsign,_fault,_faultState);
[_logic, _veh, _hitBy] call FUNC(lost);
_veh setVariable [QGVAR(owner), objNull, true];
WRITE_OFF_DONE
