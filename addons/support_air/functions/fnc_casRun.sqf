#include "script_component.hpp"
/*
 * Author: YonV
 * One tick of an ATTACK RUN's own phases, from FUNC(casTick) (2026-11-05,
 * factored out of it with the pass):
 *
 *   "in"     inbound. A thread's run holds the run-in distance short of the
 *            target until CLEARED HOT (2026-11-01, FUNC(threadReply)) and
 *            says IN once a pass when it runs in cleared. The pass
 *            (FUNC(casStrike) - the CAS drones' pass, modelled on Simplex
 *            Support Services: lined up on the run's ingress bearing, dived
 *            on the aim, the salvo released on a solution) is begun and
 *            ticked until it is over; then it turns out the run-in distance
 *            past the grid on the egress bearing. A thread's run whose pass
 *            released says OFF and REQUEST BDA; one that released nothing
 *            says so on the side's rail and comes round
 *   "short"  holding short - its IP (2026-11-09): once the READBACK was
 *            CORRECT, IN asks the clearance (EFUNC(cas,casAsk)); CLEARED HOT
 *            (CLEARED TO ENGAGE on Type 3) sends it in, not before the TOT
 *   "dry"    a CONTINUE's dry pass to CAS_DRY_RING m, back short, IN again
 *   "out"    turning out. A thread's run holds short again for its answers
 *            (the BDA, RE-ATTACK?, FURTHER TASKING?), its time on station
 *            the module's from the first pass; a board's run counts its
 *            passes and comes round - by the ingress point when there is one
 *            - or goes home when they are flown
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The sortie's state <HASHMAP>
 * 3: A pass is under way <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st, false] call jmfsb_support_air_fnc_casRun
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_passing", false, [false]]];

private _phase = _st getOrDefault ["phase", ""];
private _pos = _st get "pos";
private _requester = _st get "requester";
private _runIn = _logic getVariable [QGVAR(runIn), 3000];
private _d = _veh distance2D _pos;
private _thread = _st getOrDefault ["clear", false];
private _threadId = _logic getVariable [QGVAR(sortieThread), ""];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
private _short = _pos getPos [_runIn, _pos getDir _veh];
// IN ASKS THE CLEARANCE (2026-11-09, tree 3): held short - its IP - once the
// READBACK was CORRECT, once a pass, not after a HOLD, an ABORT or a MOVE
// (it waits for the next order) nor while it waits for a BDA.
private _fnc_askIn = {
    if (!_thread || {(_st getOrDefault ["rb", RB_OK]) isNotEqualTo RB_OK}) exitWith {};
    if ((_st getOrDefault ["inAsked", false]) || (_st getOrDefault ["moved", false]) || (_st getOrDefault ["struck", false])) exitWith {};
    _st set ["inAsked", true];
    [_assetId, _threadId, CAS_ASK_IN, [mapGridPosition _pos, _st getOrDefault ["control", 0], false], _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
};

switch (_phase) do {
    case "in": {
        // HELD SHORT FOR CLEARED HOT (2026-11-01, a thread's run): it orbits
        // the run-in distance out on its side of the target until the issuer
        // clears it (FUNC(threadReply)).
        if (_thread && !(_logic getVariable [QGVAR(cleared), true])) exitWith {
            if (_d > _runIn) exitWith {};
            [_veh, _short, "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
            _st set ["phase", "short"];
            _logic setVariable [QGVAR(status), "holding", true];
            // Held short is on station for its strike: it checks in, once
            // (user, 2026-11-02).
            [_logic, _veh, _st, _short] call FUNC(checkIn);
            call _fnc_askIn;
        };
        // IN (step 5): a thread's run, cleared, says it once a pass.
        if (_thread && !(_st getOrDefault ["inSaid", false])) then {
            _st set ["inSaid", true];
            // The clearance it waited for is spent on this pass.
            _st set ["again", false];
            // IN was said when it asked the clearance (2026-11-09).
            if !(_st getOrDefault ["inAsked", false]) then {[_logic, _threadId, CAS_IN, []] call FUNC(casSay)};
        };
        // THE PASS (2026-11-05): begun on the run's ingress bearing, then
        // ticked until it is over.
        private _res = if (_passing) then {[_veh] call EFUNC(cas,passTick)} else {
            [_logic, _veh, _pos, _logic getVariable [QGVAR(searchRadius), 0], "run", _requester, _st getOrDefault ["danger", false], _st getOrDefault ["inDir", -1]] call FUNC(casStrike)
        };
        if (_res in ["begun", "line", "dive"]) exitWith {};
        if (_res isEqualTo "dry") exitWith {[_logic, _st, _requester] call FUNC(casWinchester)};
        // OFF and REQUEST BDA (step 5): a thread's run whose pass released.
        if (_res isEqualTo "fired") then {
            if (_thread) then {
                _st set ["struck", true];
                // The pass is over: a FRAGO is taken again. Cleared to engage
                // (Type 3, 2026-11-09): ATTACK COMPLETE - REQUEST BDA.
                _st set ["ip", false];
                if (_st getOrDefault ["engaged", false]) exitWith {
                    _st set ["engaged", false];
                    [_assetId, _threadId, CAS_ASK_COMPLETE, [], _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
                };
                [_logic, _threadId, CAS_OFF, []] call FUNC(casSay);
            };
        } else {
            if (_res isNotEqualTo "unsafe") then {[_logic, "no release, coming round", "normal", _requester, false] call FUNC(say)};
        };
        INFO_2("%1 pass over - %2 - turning out",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_res);
        private _outDir = _st getOrDefault ["outDir", -1];
        if (_outDir < 0) then {_outDir = _veh getDir _pos};
        [_veh, _pos getPos [_runIn, _outDir], "FULL"] call FUNC(moveTo);
        _st set ["phase", "out"];
        _logic setVariable [QGVAR(status), "off target", true];
    };
    case "short": {
        if !(_logic getVariable [QGVAR(cleared), true]) exitWith {call _fnc_askIn};
        // THE TOT (2026-11-09): not in before the order's time on target, less
        // the dive (FUNC(casFlow)).
        if (CBA_missionTime < (_st getOrDefault ["leaveAt", -1])) exitWith {};
        [_veh, _pos, "FULL"] call FUNC(moveTo);
        _st set ["phase", "in"];
        _logic setVariable [QGVAR(status), "attacking", true];
    };
    case "out": {
        if (_d < OUT_SHARE * _runIn) exitWith {};
        // A THREAD'S RUN HOLDS SHORT FOR ITS ANSWERS (step 5, 2026-11-01): the
        // BDA, RE-ATTACK?, FURTHER TASKING? (FUNC(threadReply)), not the
        // passes. From its first pass its time on station is the module's
        // Time on Station.
        if (_thread) exitWith {
            [_veh, _pos getPos [_runIn, _pos getDir _veh], "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
            _st set ["phase", "short"];
            _st set ["inSaid", false];
            // A new clearance each pass (2026-11-09): IN asks again.
            _st set ["inAsked", false];
            // A re-attack cleared on the way out goes straight back in.
            _logic setVariable [QGVAR(cleared), _st getOrDefault ["again", false]];
            _st set ["again", false];
            _logic setVariable [QGVAR(status), "holding", true];
            if !(_st getOrDefault ["stationed", false]) then {
                _st set ["stationed", true];
                _st set ["until", (_st get "until") min (CBA_missionTime + (_logic getVariable [QGVAR(stationTime), SORTIE_TIMEOUT]))];
            };
            // One cleared before it first held short checks in here (user,
            // 2026-11-02); one that has checked in does not again.
            [_logic, _veh, _st, _pos getPos [_runIn, _pos getDir _veh]] call FUNC(checkIn);
        };
        private _passes = (_st get "passes") - 1;
        _st set ["passes", _passes];
        if (_passes <= 0) exitWith {
            [_logic, "run complete, returning to base", "normal", _requester] call FUNC(say);
            _st set ["phase", "home"];
        };
        private _entry = _st getOrDefault ["entry", []];
        if (_entry isNotEqualTo []) exitWith {
            [_veh, _entry, "FULL"] call FUNC(moveTo);
            _st set ["phase", "entry"];
            _logic setVariable [QGVAR(status), "re-attacking", true];
        };
        [_veh, _pos, "FULL"] call FUNC(moveTo);
        _st set ["phase", "in"];
        _logic setVariable [QGVAR(status), "attacking", true];
    };
    // A CONTINUE'S DRY PASS (2026-11-09, FUNC(threadReply)): in to CAS_DRY_RING
    // m of the target, nothing released, then back to its short hold and IN
    // again.
    case "dry": {
        if (_d > CAS_DRY_RING) exitWith {};
        [_veh, _short, "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
        _st set ["phase", "short"];
        _st set ["inAsked", false];
        _logic setVariable [QGVAR(status), "holding", true];
    };
};
