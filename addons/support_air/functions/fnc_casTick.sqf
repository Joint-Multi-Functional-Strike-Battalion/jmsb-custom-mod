#include "script_component.hpp"
/*
 * Author: YonV
 * The watch on one CAS sortie, every AIR_TICK seconds. Phases:
 *
 *   "entry"    a synced aircraft flying to its ingress point before it
 *              turns in (FUNC(casLaunch))
 *   "in"       inbound. A RUN is a pass (FUNC(casStrike) - 2026-11-05, the
 *              CAS drones' pass, modelled on Simplex Support Services: the
 *              aircraft lined up on the ingress bearing, dived on the aim,
 *              the salvo released on a solution, handed back) and then turns
 *              out the run-in distance past the grid; a SAD or LOITER enters
 *              an orbit at its hold and goes on station
 *   "out"      turning out after a pass on the egress bearing (straight
 *              through without one); far enough, it comes round for the
 *              next one - by the ingress point when there is one - or goes
 *              home when the passes are flown
 *   "station"  orbiting. A SAD looks for something to hit every CAS_SAD_EVERY
 *              seconds; a LOITER holds weapons tight. A new SAD or LOITER
 *              moves the orbit (FUNC(casOrder)); a minute before the time
 *              on station is up the side is told, and then it leaves
 *   "strike"   a SAD's pass: a fixed-wing's from its hold at the attack
 *              altitude, a helicopter's from its orbit - then back
 *   "back"     a fixed-wing on its way back to the hold - a strike from
 *              station closes its thread there
 *   "short"    a thread's ATTACK RUN holding the run-in distance short of the
 *              target until CLEARED HOT (2026-11-01) - and after each pass
 *              (step 5): IN when it runs in cleared, OFF and REQUEST BDA when
 *              the pass is over, then back here for the BDA, RE-ATTACK? and
 *              FURTHER TASKING? (FUNC(threadReply)), its time on station the
 *              module's from the first pass
 *   "jobIn", "jobRun", "jobOut"
 *              a strike card flown from station (FUNC(casJob), 2026-11-01);
 *              2026-11-09 "jobIp" (orbiting the IP for the clearance or the
 *              TOT), "jobDry" (a CONTINUE's dry pass), "jobHold" (a HOLD)
 *   "dry"      a helicopter run's dry pass after CONTINUE (FUNC(casRun))
 *   "egressOut" the BDA said EGRESS (user, 2026-11-02: "reattack or egress";
 *              EGRESS = LEAVE): out by the strike's egress point - the card's
 *              Line 4, else the sortie's - then home; its threads closed
 *              EGRESS - RTB (FUNC(threadReply))
 *   home legs  FUNC(homeTick)
 *
 * OFF STATION (DESIGN_SUPPORT_MESSAGING 1.1): recalled (the board's RTB, or
 * the issuer closing the REQUEST ON STATION thread), its time on station run
 * out or Winchester - the threads it was answering close with RTB, BINGO or
 * WINCHESTER. On arrival on station - at the hold, over the grid, or a
 * helicopter's run held short - it checks in, once (FUNC(checkIn), user
 * 2026-11-02).
 *
 * BINGO (step 5, 2026-11-01): a sortie answering a thread says BINGO IN 2 MIN
 * (FLASH) in each of them CAS_BINGO_LEAD s before its time runs out, or when
 * its fuel is down to CAS_BINGO_FUEL of a tank, and leaves CAS_BINGO_LEAD s
 * later.
 *
 * THE HOLD (user, 2026-11-01: "loiter or on station needs to be 8k meters off
 * map, atack alt need to be 4k m atl"). A helicopter holds over the grid, nap
 * of the earth, as before. A fixed-wing holds OFF_MAP_HOLD outside the map
 * edge nearest the grid (EFUNC(support,holdPoint)), FW_HOLD_ORBIT round, and a
 * SAD comes in from there only for something to hit: a laser or smoke inside
 * the radius, or an enemy the requester knows there. The crew's own eyes are
 * not enough from off the map. After the pass it goes back to the hold.
 *
 * Recall, the sortie running out of time and the aircraft running dry all
 * send it home; a wreck ends the sortie where it lies. A release held for
 * friendlies near the aim (no DANGER CLOSE) is said once and flown dry. A
 * pass under way is finished before the time on station ends the sortie; a
 * recall ends it at once (EFUNC(cas,passEnd)).
 *
 * Arguments:
 * 0: [logic, aircraft, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(casTick), 1, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st"];

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh] call FUNC(sweep);
};

// A wreck, or DISABLED - written off once it has not flown for FAULT_GRACE s
// (user, 2026-11-02: a disabled airframe is a lost one; FUNC(writeOff)).
if (!alive _veh || {([_logic, _veh, _st] call FUNC(writeOff)) isEqualTo WRITE_OFF_DONE}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh, "written off", "", true] call EFUNC(cas,passEnd);
    [_logic] call FUNC(finish);
};

private _phase = _st get "phase";
// ALL ATTACK (user, 2026-11-02): leaving, the escort drones' attack is over -
// they rejoin and come home with it (EFUNC(support,escortAttackEnd)).
if (_phase in ["home", "homing", "parking", "egressOut"]) then {[_veh] call EFUNC(support,escortAttackEnd)};
if (_phase in ["home", "homing", "parking"]) exitWith {
    if ([_logic, _veh, _st] call FUNC(homeTick)) then {[_handle] call CBA_fnc_removePerFrameHandler};
};
// EGRESS (user, 2026-11-02: "reattack or egress"; EGRESS = LEAVE): out by the
// strike's egress point, then the leg home. Its threads are closed already.
if (_phase isEqualTo "egressOut") exitWith {
    private _egressTo = _st getOrDefault ["egressTo", []];
    private _out = false;
    if (count _egressTo >= 2) then {_out = _veh distance2D _egressTo > CAS_ENTRY_RING};
    if (_out && CBA_missionTime < (_st getOrDefault ["egressBy", 0])) exitWith {};
    _st set ["phase", "home"];
};

private _requester = _st get "requester";
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];

// BINGO (step 5, 2026-11-01, doc 5.4): a sortie answering a thread, its time
// on station or its fuel short - BINGO IN 2 MIN (FLASH) in each thread, and it
// leaves CAS_BINGO_LEAD s on.
private _threads = [
    (_logic getVariable [QGVAR(job), createHashMap]) getOrDefault ["thread", ""],
    _logic getVariable [QGVAR(sortieThread), ""]
] select {_x isNotEqualTo ""};
if (_threads isNotEqualTo [] && !(_st getOrDefault ["bingo", false]) && (((_st get "until") - CBA_missionTime) <= CAS_BINGO_LEAD || fuel _veh <= CAS_BINGO_FUEL)) then {
    _st set ["bingo", true];
    _st set ["until", (_st get "until") min (CBA_missionTime + CAS_BINGO_LEAD)];
    INFO_1("%1 bingo - leaving in two minutes",_callsign);
    {[_logic, _x, CAS_BINGO, []] call FUNC(casSay)} forEach _threads;
};

// A pass under way is finished first when the time runs out (2026-11-05: the
// strike was cut off mid-run); a recall still ends it at once. A pass to tick
// is one under way or one over whose result the watch has not read yet.
private _passing = [_veh] call EFUNC(cas,passActive);
private _striking = _passing || _phase in ["jobIn", "jobRun", "strike"];
if ((_logic getVariable [QGVAR(abort), false]) || {!_striking && {CBA_missionTime > (_st get "until")}}) exitWith {
    private _recalled = _logic getVariable [QGVAR(abort), false];
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(onStation), false];
    if (_passing) then {[_veh, "recalled", "", true] call EFUNC(cas,passEnd)};
    // VIRTUAL UNTIL TASKED (user, 2026-11-02): the task is over - it RTBs to
    // the module, by the egress point when the BDA said EGRESS, and a class
    // aircraft is removed there, virtual again (FUNC(homeTick)).
    [_logic, "off station, returning to base", "normal", _requester] call FUNC(say);
    // OFF STATION (doc 1.1, 2026-11-01): the threads it was answering close -
    // RTB when it was recalled or its thread closed, BINGO when its time ran
    // out; a thread's own words when its answer sent it (step 5: WINCHESTER,
    // NO RESPONSE - RTB).
    [_logic, "CLOSED", _st getOrDefault ["said", [OFF_BINGO, OFF_RTB] select _recalled]] call FUNC(threadState);
    // EGRESS (user, 2026-11-02): the BDA said so - out by the strike's egress
    // point first (FUNC(threadReply)), then home.
    private _egressTo = _st getOrDefault ["egressTo", []];
    if (count _egressTo < 2) exitWith {_st set ["phase", "home"]};
    [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
    [_veh, _egressTo, "FULL"] call FUNC(moveTo);
    _st set ["egressBy", CBA_missionTime + SORTIE_TIMEOUT];
    _st set ["phase", "egressOut"];
    _logic setVariable [QGVAR(status), STATUS_RTB, true];
};

private _fw = _st getOrDefault ["fw", false];
private _fnc_orbit = {
    // A JET DOES NOT ORBIT AT "LIMITED". The first loiter flown (RPT 2026-10-20)
    // put an A-164 down 87 s after it came on station with no killer: slow and
    // tight in a turn is a stall. Planes orbit their off-map hold at normal
    // speed, FW_HOLD_ORBIT round; helicopters keep the slow orbit of the grid.
    [_veh, _st get "hold", ["LIMITED", "NORMAL"] select _fw, "LOITER", [_st get "radius", FW_HOLD_ORBIT] select _fw] call FUNC(moveTo);
};

// REPOSITIONED ON STATION (FUNC(casOrder)): the same sortie, a new grid. The
// time on station keeps running. A fixed-wing's hold moves with the grid.
private _move = _logic getVariable [QGVAR(reposition), []];
if (_move isNotEqualTo [] && _phase isEqualTo "station") then {
    _logic setVariable [QGVAR(reposition), nil];
    _move params ["_newMode", "_newPos", "_newRadius", "_newMag", "_newDanger", "_who"];
    private _newHold = [_veh, _newPos] call EFUNC(support,holdPoint);
    {_st set _x} forEach [["mode", _newMode], ["pos", _newPos], ["hold", _newHold], ["radius", _newRadius], ["danger", _newDanger], ["requester", _who], ["next", 0]];
    _logic setVariable [QGVAR(heldSaid), false];
    _requester = _who;
    [group driver _veh, _newMode] call FUNC(casPosture);
    _veh setVariable [QEGVAR(cas,ordnance), _newMag];
    [_veh, FLY_STATION] call EFUNC(support,flyAt);
    call _fnc_orbit;
    private _plan = [[_newPos, toUpper _newMode]];
    if (_fw) then {_plan = [[_newHold, PLAN_HOLD]] + _plan};
    _logic setVariable [QGVAR(plan), _plan, true];
};

private _mode = _st get "mode";
private _pos = _st get "pos";
private _radius = _st get "radius";

switch (_phase) do {
    case "entry": {
        if (_veh distance2D (_st get "entry") > CAS_ENTRY_RING) exitWith {};
        [_veh, [_st get "hold", _pos] select (_mode isEqualTo "run"), ["NORMAL", "FULL"] select (_mode isEqualTo "run")] call FUNC(moveTo);
        _st set ["phase", "in"];
        _logic setVariable [QGVAR(status), ["inbound", "attacking"] select (_mode isEqualTo "run"), true];
    };
    // AN ATTACK RUN'S OWN PHASES (FUNC(casRun)): inbound, held short, out.
    case "short": {[_logic, _veh, _st, _passing] call FUNC(casRun)};
    case "out": {[_logic, _veh, _st, _passing] call FUNC(casRun)};
    // A CONTINUE's dry pass (2026-11-09).
    case "dry": {[_logic, _veh, _st, _passing] call FUNC(casRun)};
    case "in": {
        if (_mode isEqualTo "run") exitWith {[_logic, _veh, _st, _passing] call FUNC(casRun)};

        if (_veh distance2D (_st get "hold") > ([_radius, FW_HOLD_ORBIT] select _fw) + CAS_STATION_EXTRA) exitWith {};
        [_veh, FLY_STATION] call EFUNC(support,flyAt);
        call _fnc_orbit;
        _st set ["phase", "station"];
        _st set ["until", CBA_missionTime + (_st getOrDefault ["stationTime", _logic getVariable [QGVAR(stationTime), 600]])];
        _logic setVariable [QGVAR(status), STATUS_ON_STATION, true];
        // ON STATION (2026-11-01): a strike card may now be flown from here
        // (FUNC(srvThread)), and it checks in in its thread (doc 1.1) - a
        // helicopter too (user, 2026-11-02).
        _logic setVariable [QGVAR(onStation), true];
        [_logic, _veh, _st] call FUNC(checkIn);
        [_logic, format [["on station over %1", "on station off the map for %1"] select _fw, mapGridPosition _pos], "normal", _requester] call FUNC(say);
    };
    case "station": {
        if (!(_st getOrDefault ["warned", false]) && {(_st get "until") - CBA_missionTime < STATION_WARNING}) then {
            _st set ["warned", true];
            [_logic, "leaving the area in one minute", "normal", _requester] call FUNC(say);
        };
        // A STRIKE FROM STATION (2026-11-01) comes first: FUNC(casJob).
        if (count (_logic getVariable [QGVAR(job), createHashMap]) > 0) exitWith {
            [_logic, _veh, _st] call FUNC(casJob);
        };
        if (_mode isNotEqualTo "sad" || {CBA_missionTime < (_st get "next")}) exitWith {};
        _st set ["next", CBA_missionTime + CAS_SAD_EVERY];
        // A SAD'S PASS (2026-11-05): a helicopter's from its orbit, from where
        // it is; a fixed-wing's from off the map - in only for a painted
        // target or one the requester knows, the crew cannot see the grid
        // from out here - on the bearing from its hold.
        private _inDir = -1;
        if (_fw) then {
            ([_pos, _radius, _logic getVariable [QGVAR(side), west]] call EFUNC(cas,acquire)) params ["", "_by"];
            private _known = !isNull _requester && {((_requester targets [true, _radius, [], 0, _pos]) findIf {alive _x}) > -1};
            if (_by isNotEqualTo "grid" || _known) then {
                [_veh, FLY_ATTACK] call EFUNC(support,flyAt);
                _inDir = _pos getDir (_st get "hold");
            };
        };
        if (_fw && _inDir < 0) exitWith {};
        private _res = [_logic, _veh, _pos, _radius, "sad", _requester, _st getOrDefault ["danger", false], _inDir] call FUNC(casStrike);
        if (_res isEqualTo "dry") exitWith {[_logic, _st, _requester] call FUNC(casWinchester)};
        if (_res isNotEqualTo "begun") exitWith {};
        _st set ["phase", "strike"];
        _logic setVariable [QGVAR(status), "attacking", true];
    };
    case "strike": {
        private _res = [_veh] call EFUNC(cas,passTick);
        if (_res in ["line", "dive"]) exitWith {};
        INFO_2("%1 SAD pass over - %2",_callsign,_res);
        if (_fw) exitWith {
            [_veh, _st get "hold", "FULL"] call FUNC(moveTo);
            _st set ["phase", "back"];
            _logic setVariable [QGVAR(status), "off target", true];
        };
        // A helicopter back to its orbit over the grid.
        [_veh, FLY_STATION] call EFUNC(support,flyAt);
        call _fnc_orbit;
        _st set ["phase", "station"];
        _logic setVariable [QGVAR(status), STATUS_ON_STATION, true];
    };
    case "back": {
        if (_veh distance2D (_st get "hold") > FW_HOLD_ORBIT + CAS_STATION_EXTRA) exitWith {};
        [_veh, FLY_STATION] call EFUNC(support,flyAt);
        call _fnc_orbit;
        _st set ["phase", "station"];
        _logic setVariable [QGVAR(status), STATUS_ON_STATION, true];
        // A strike from station that released holds at the hold for its
        // answers (step 5, 2026-11-01: the BDA, RE-ATTACK?, FURTHER TASKING? -
        // FUNC(threadReply)); one that did not is over.
        private _job = _logic getVariable [QGVAR(job), createHashMap];
        if (count _job > 0) then {
            // A board's strike from station has no thread to hold for: over
            // (user, 2026-11-02 - a class aircraft on station takes a board's
            // ATTACK RUN this way, FUNC(casOrder)).
            if ((_job getOrDefault ["thread", ""]) isEqualTo "") exitWith {
                _logic setVariable [QGVAR(job), nil];
                _veh setVariable [QEGVAR(cas,ordnance), ""];
            };
            // ABORTED (2026-11-09): dropped - its thread stays for the
            // intentions it asked (FUNC(threadReply)).
            if (_job getOrDefault ["aborted", false]) exitWith {
                _logic setVariable [QGVAR(job), nil];
                _veh setVariable [QEGVAR(cas,ordnance), ""];
            };
            if ((_job getOrDefault ["struck", false]) && !(_job getOrDefault ["over", false])) exitWith {
                // A re-attack cleared on the way back goes straight back in.
                _job set ["cleared", _job getOrDefault ["again", false]];
                _job set ["again", false];
            };
            // Not begun yet - re-tasked on the way in, a RE-ATTACK, a FRAGO
            // (2026-11-09): kept, it runs in again from the hold.
            if !(_job getOrDefault ["begun", false]) exitWith {};
            [_logic, "CLOSED", "back at the hold", _job getOrDefault ["thread", ""]] call FUNC(threadState);
            _logic setVariable [QGVAR(job), nil];
            _veh setVariable [QEGVAR(cas,ordnance), ""];
        };
    };
    // A strike from station on its way in, its pass, and out.
    case "jobIn": {[_logic, _veh, _st] call FUNC(casJob)};
    case "jobRun": {[_logic, _veh, _st] call FUNC(casJob)};
    case "jobOut": {[_logic, _veh, _st] call FUNC(casJob)};
    // The 2026-11-09 flow's (FUNC(casJob)): orbiting the IP, a dry pass, a HOLD.
    case "jobIp": {[_logic, _veh, _st] call FUNC(casJob)};
    case "jobDry": {[_logic, _veh, _st] call FUNC(casJob)};
    case "jobHold": {[_logic, _veh, _st] call FUNC(casJob)};
};
