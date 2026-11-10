#include "script_component.hpp"
/*
 * Author: YonV
 * Server: one tick of a transport's lift job (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 5.4 and step 7), from its watch
 * (FUNC(transportTick)) before the leg is flown. What the asset says and asks
 * on the way:
 *
 *   a new leg          WHEELS UP "TO <grid>" for every leg after the first
 *                      (the first one's is at the launch), not the leg home
 *   on station         an extraction (user, 2026-11-02): at its STATION it
 *                      holds, orbiting, and asks ON STATION - READY FOR
 *                      EXTRACTION (extractnow / abort) until EXTRACT
 *   on the way in      to the pickup (the job's first point - not the LIFT
 *                      REQUEST's, always safe, 2026-11-02) and the card's
 *                      LZ: INBOUND - ETA m:ss - <grid> every minute, and a
 *                      minute out 1 MIN OUT - POP SMOKE (the card's marking),
 *                      FLASH, with the issuer's popup (EFUNC(support,inbound),
 *                      user 2026-11-01)
 *   on the card's LZ   the 1 MIN OUT asks LZ STATUS? (cold / hot) in the same
 *                      message; unanswered - or HOT and not yet CONFIRMed - it
 *                      holds short, LZ_HOLD_SHORT m out, orbiting
 *   at the point       every landing (user, 2026-11-02): it circles while the
 *                      support core verifies the mark - I SEE RED SMOKE
 *                      (correct / wrong), CIRCLING - NO SMOKE SEEN - POP SMOKE
 *                      (nosmoke) - and asks READY TO LAND - CLEARED?
 *                      (clearedland / hold / abort, EFUNC(support,lzClear));
 *                      it lands only when cleared (FUNC(liftCleared))
 *                      - every landing but the LIFT REQUEST's pickup, which
 *                      it lands on as it is (2026-11-02: "always safe")
 *   wheels down        WHEELS DOWN; at a LAND (the hlz's LZ, a casevac's
 *                      destination): WHEELS DOWN - PAX OFF? (paxoff / hold);
 *                      at a casevac's PICKUP it loads; at a lift's or an
 *                      extraction's pickup WHEELS DOWN AT PICKUP <grid>, then
 *                      TROOP LOAD - ALL IN? (allin / abort, no D9) - the
 *                      helicopter marked for the ALL IN actions (scroll and
 *                      ACE) while it loads (QGVAR(allIn)); it holds there
 *                      until ALL IN or ABORT
 *   loading            the patients aboard (or the wait up): PATIENTS ABOARD -
 *                      DESTINATION? (destination / freetext)
 *   the stick out      an airdrop's PARADROP done, going home: PACKAGE AWAY -
 *                      CONFIRM RECEIPT (received / notfound); the thread is
 *                      held open past the sortie's end (QGVAR(threadHold))
 *
 * An order without the job's thread in it is someone else's (the board's): the
 * job's thread is closed RE-TASKED and the job ends. The leg home is the job's
 * whoever wrote it (bingo fuel, a finished paradrop, the issuer's RTB).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 * 2: The watch's state <HASHMAP>
 *
 * Return Value:
 * Hold this tick - the watch flies nothing else <BOOL>
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_liftTick
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]]];

// WHY IT HOLDS THE WATCH, in the RPT once each time it starts (2026-11-05:
// RAVEN hovered and the RPT could not say whether this held it). A tick that
// does not hold clears it.
private _heldFor = _st getOrDefault ["holdWhy", ""];
_st set ["holdWhy", ""];
private _fnc_hold = {
    params ["_why"];
    _st set ["holdWhy", _why];
    if (_why isNotEqualTo _heldFor) then {
        INFO_2("liftTick: %1 holds the watch - %2",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_why);
    };
    true
};

private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
private _phase = _st getOrDefault ["phase", ""];
// THE ACE SELF ACTION ALL IN is offered only while it loads at a pickup
// (FUNC(canAllIn)): the mark comes off the helicopter once it is not.
private _loading = _veh getVariable [QGVAR(allIn), []];
if (_loading isNotEqualTo [] && (count _job isEqualTo 0 || _phase isNotEqualTo "down")) then {
    _veh setVariable [QGVAR(allIn), nil, true];
};
if (count _job isEqualTo 0) exitWith {false};
private _step = _job get "step";
if (_step in [JOB_CONFIRM, JOB_RECEIPT]) exitWith {false};

private _threadId = _job get "thread";
private _task = _st getOrDefault ["task", TASK_HOME];
private _target = _st getOrDefault ["target", getPosATL _veh];
private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];

// SOMEONE ELSE'S ORDER: the job is over.
if (_task isNotEqualTo TASK_HOME && {((_st getOrDefault ["opts", createHashMap]) getOrDefault ["job", ""]) isNotEqualTo _threadId}) exitWith {
    INFO_2("liftTick: %1 re-tasked - thread %2 closed",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_threadId);
    [_logic, "CLOSED", SAID_RETASKED, _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(liftJob), nil];
    _logic setVariable [QGVAR(sortieThread), nil];
    false
};

// THE PLAYERS ARE OUT at an RTB's landing (2026-11-09): home, closed RTB.
if ((_job getOrDefault ["rtbLand", false]) && _step isEqualTo JOB_PAX && {((fullCrew [_veh, "cargo", false]) findIf {isPlayer (_x select 0) && {alive (_x select 0)}}) < 0}) exitWith {
    [_logic, SAID_RTB] call FUNC(liftEnd);
    false
};

// HELD OR ABORTED (2026-11-09, FUNC(liftHold)): it orbits where it stopped, or
// sits where it is, and says nothing until the next order.
if (_step in [JOB_HELD, JOB_ABORTED]) exitWith {
    _job set ["leg", _task];
    false
};

// A NEW LEG.
private _was = _job get "leg";
if (_was isNotEqualTo _task) then {
    _job set ["leg", _task];
    _job set ["asked", false];
    _job set ["down", false];
    _job set ["landing", ""];
    // Lifted from the pickup: the troop load is over.
    if (_step isEqualTo JOB_ALL_IN) then {
        _step = JOB_FLYING;
        _job set ["step", _step];
    };
    // Off the pickup leg: its zone leaves the side's AiTR (FUNC(liftZones)).
    if (_was in PICKUP_LEGS) then {
        _job set ["lifted", true];
        [_logic] call FUNC(liftZones);
    };
    private _legs = _job get "legs";
    _job set ["legs", _legs + 1];
    if (_legs > 0 && _task isNotEqualTo TASK_HOME && _step isNotEqualTo JOB_MOVE) then {
        private _name = _job get "destName";
        _job set ["destName", ""];
        [_logic, CARD_WHEELS_UP, trim format ["TO %1 %2", _name, mapGridPosition _target]] call FUNC(threadCard);
    };
};

// THE STICK IS OUT - the paradrop turned for home with an empty cabin: the
// receipt.
if ((_job get "kind") isEqualTo ORDER_DROP && _task isEqualTo TASK_HOME && _was isEqualTo TASK_PARADROP && (fullCrew [_veh, "cargo"]) isEqualTo []) exitWith {
    _job set ["step", JOB_RECEIPT];
    _logic setVariable [QGVAR(threadHold), _threadId];
    [_logic, _threadId, PROMPT_RECEIPT, ANSWERS_RECEIPT] call FUNC(threadPrompt);
    false
};

// A MOVE (2026-11-09, FUNC(liftMove)): at its altitude when it gave one; there,
// AT <grid> - <what it does>; its TIME up, STATE INTENTIONS. A LAND circles
// for the clearance below, as every landing.
if (_step isEqualTo JOB_MOVE) then {
    private _move = _job getOrDefault ["move", createHashMap];
    private _altitude = _move getOrDefault ["altitude", -1];
    if (_altitude > 0 && _phase isEqualTo "transit") then {[_veh, _altitude] call EFUNC(support,flyAt)};
    if ((_move getOrDefault ["arrived", -1]) < 0 && {_phase in ["hold", "down"]}) then {
        _move set ["arrived", CBA_missionTime];
        [_logic, _threadId, format [SAID_ARRIVED, mapGridPosition _veh, _move getOrDefault ["arrival", ""]]] call FUNC(liftSay);
    };
    // AN RTB'S LANDING FOR THE PLAYERS ABOARD (2026-11-09): down, PAX OFF?.
    if ((_job getOrDefault ["rtbLand", false]) && _phase isEqualTo "down") exitWith {
        _job set ["step", JOB_PAX];
        [_logic, _threadId, PROMPT_PAX, ANSWERS_PAX] call FUNC(threadPrompt);
    };
    private _minutes = _move getOrDefault ["minutes", -1];
    private _arrived = _move getOrDefault ["arrived", -1];
    if (_minutes > 0 && _arrived >= 0 && !(_move getOrDefault ["said", false]) && {CBA_missionTime > _arrived + _minutes * SECONDS_PER_MINUTE}) then {
        _move set ["said", true];
        [_logic, _threadId, format [SAID_TIME_UP, mapGridPosition _veh]] call FUNC(liftIntentions);
    };
};

// THE PARADROP'S RUN-IN (FM 3-21.38 Table 3-3, 2026-11-09): STAND BY -
// EXECUTE? (execute / nodrop), FLASH, PARADROP_STANDBY_RING m out; not
// cleared by PARADROP_HOLD_RING m, closed traffic round the DZ until EXECUTE
// (FUNC(liftReply)). NO DROP is another pass.
if ((_job get "kind") isEqualTo ORDER_DROP && _task isEqualTo TASK_PARADROP && _phase isEqualTo "transit" && !(_job getOrDefault ["dropCleared", false])) then {
    private _dist = _veh distance2D _target;
    if (_dist < PARADROP_STANDBY_RING && {!(_job getOrDefault ["standbyAsked", false])}) then {
        _job set ["standbyAsked", true];
        _job set ["step", JOB_STANDBY];
        _step = JOB_STANDBY;
        [_assetId, _threadId, format [PROMPT_STANDBY, mapGridPosition _target], ANSWERS_STANDBY, _callsign, {_this call FUNC(threadTimeout)}, true, true] call EFUNC(support,prompt);
    };
};
if ((_job get "kind") isEqualTo ORDER_DROP && _task isEqualTo TASK_PARADROP && _phase isEqualTo "transit" && !(_job getOrDefault ["dropCleared", false]) && {_veh distance2D _target < PARADROP_HOLD_RING}) exitWith {
    if !(_job getOrDefault ["closedTraffic", false]) then {
        _job set ["closedTraffic", true];
        [_veh, _target, "LIMITED", "LOITER", PARADROP_ORBIT] call FUNC(moveTo);
        _logic setVariable [QGVAR(status), "closed traffic", true];
    };
    ["closed traffic round the DZ, waiting for EXECUTE"] call _fnc_hold
};

// THE EXTRACTION IS ON STATION FIRST (user, 2026-11-02: "extraction: 1) on
// station 2) extraction"): its STATION is the order's first leg. There it
// holds - an orbit, dark, nap of the earth - and says ON STATION - READY FOR
// EXTRACTION (extract / abort) once, without D9: it waits to be called in.
// EXTRACT (FUNC(liftReply)) takes it on to the HLZ, where the landing is the
// full procedure below. Nothing is said on the way to the station.
private _station = _job getOrDefault ["station", []];
private _legsLeft = _st getOrDefault ["legs", []];
private _stationLeg = false;
if (_phase isEqualTo "transit" && _station isNotEqualTo [] && _legsLeft isNotEqualTo []) then {
    _stationLeg = (_legsLeft select 0) isEqualTo _station;
};
if (_stationLeg) exitWith {
    private _issuer = _job get "issuer";
    if (_step isNotEqualTo JOB_STATION) exitWith {
        _legsLeft deleteAt 0;
        _job set ["station", []];
        [_veh, _legsLeft param [0, _target], _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
        _logic setVariable [QGVAR(status), "to extract", true];
        [_logic, format ["called in, inbound to %1", mapGridPosition _target], "normal", _issuer] call FUNC(say);
        ["called in off its station"] call _fnc_hold
    };
    if (_veh distance2D _station > ARRIVE_RING) exitWith {false};
    if !(_job getOrDefault ["onStation", false]) then {
        _job set ["onStation", true];
        [_veh, _station, "LIMITED", "LOITER", LZ_HOLD_ORBIT] call FUNC(moveTo);
        _logic setVariable [QGVAR(status), STATUS_ON_STATION, true];
        [_logic, format ["on station at %1, ready for extraction", mapGridPosition _station], "normal", _issuer] call FUNC(say);
        [_assetId, _threadId, PROMPT_ON_STATION, ANSWERS_ON_STATION, _callsign, {_this call FUNC(threadTimeout)}, false] call EFUNC(support,prompt);
    };
    ["on station, waiting for EXTRACT"] call _fnc_hold
};

// ON THE WAY IN (user, 2026-11-01: "need more information like after rw
// inbound eta etc etc and an alert to pop smoke when its close"): to the
// pickup and the card's LZ, INBOUND - ETA every minute, and a minute out (or
// LZ_HOLD_SHORT m) 1 MIN OUT - POP <the card's marking>, FLASH, with the
// issuer's popup - at the card's LZ in one message with LZ STATUS? (cold /
// hot) - then short of the LZ until its status is known
// (EFUNC(support,inbound)).
if (_phase isEqualTo "transit" && !(_job get "asked") && _task in (_job getOrDefault ["inboundTo", []])) then {
    private _askHere = _task isEqualTo (_job get "askAt");
    private _said = [
        format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
        _threadId,
        _logic getVariable [QGVAR(callsign), "AIR"],
        _veh,
        _target,
        _job getOrDefault ["marking", ""],
        ["", PROMPT_LZ_STATUS] select _askHere,
        ["", ANSWERS_LZ_STATUS] select _askHere,
        {_this call FUNC(threadTimeout)},
        LZ_HOLD_SHORT
    ] call EFUNC(support,inbound);
    if (_said) then {
        _job set ["asked", true];
        if (_askHere) then {
            _job set ["step", JOB_LZ_STATUS];
            _step = JOB_LZ_STATUS;
        };
    };
};
if (_phase isEqualTo "transit" && _step in [JOB_LZ_STATUS, JOB_HOT] && _veh distance2D _target < LZ_HOLD_SHORT) exitWith {
    if !(_job get "holding") then {
        _job set ["holding", true];
        // The go-in (COLD, CONFIRM) flies straight to the LZ: a route point
        // still ahead inside the hold-short ring would be waited on for ever
        // and the circle never begun (2026-11-05).
        private _legs = _st getOrDefault ["legs", []];
        _st set ["legs", _legs select {_x distance2D _target >= LZ_HOLD_SHORT}];
        [_veh, _target getPos [LZ_HOLD_SHORT, _target getDir _veh], "LIMITED", "LOITER", LZ_HOLD_ORBIT] call FUNC(moveTo);
        _logic setVariable [QGVAR(status), "holding short", true];
        [_logic, format ["holding short of %1 for the LZ status", mapGridPosition _target], "normal", _job get "issuer"] call FUNC(say);
    };
    ["holding short for the LZ status"] call _fnc_hold
};

// CIRCLE TILL THE MARK IS VERIFIED, THEN CLEARED TO LAND (user, 2026-11-02:
// "support trans needs to circle till smoke is verified, caller pops smoke
// helo verifies color, either way transport needs final permission to land").
// Every landing of the job - the hlz's pickup and LZ, the casevac's pickup and
// destination: the board's land-on-the-signal is not flown
// (FUNC(transportTick)); at the point it circles while the support core
// verifies the caller's mark and asks READY TO LAND - CLEARED?
// (EFUNC(support,lzClear)); CLEARED TO LAND (FUNC(liftCleared)) lands it on
// the verified mark, or on the grid after NO SMOKE. A hot LZ has had its
// CONFIRM by now (holding short, above) and needs this as well.
// THE LIFT REQUEST'S PICKUP IS ALWAYS SAFE (user, 2026-11-02: "pick up site
// (always safe)"): no circle, no mark, no clearance - it lands (the board's
// land-on-the-signal is not flown there either) and says WHEELS DOWN AT
// PICKUP (below).
// A MOVE's LAND is a landing too (2026-11-09).
private _clearTask = _task in LZ_CLEAR_TASKS || {_step isEqualTo JOB_MOVE && _task isEqualTo TASK_LAND_OFF};
if (_phase isEqualTo "transit" && _clearTask) then {_st set ["signalLooked", true]};
private _landing = _job getOrDefault ["landing", ""];
private _safe = (_job getOrDefault ["safePickup", false]) && _task isEqualTo TASK_LIFT;
private _final = _phase isEqualTo "transit" && _clearTask && !_safe && (_st getOrDefault ["legs", []]) isEqualTo [];
if (_final && (_landing isNotEqualTo "" || _veh distance2D _target < ARRIVE_RING)) exitWith {
    private _issuer = _job get "issuer";
    if (_landing isEqualTo LANDING_CLEARED) then {
        private _at = _job getOrDefault ["landAt", []];
        if (count _at < 2) then {_at = _target};
        _st set ["target", _at];
        [_logic, _veh, _st] call FUNC(transportArrive);
        [_logic, format ["cleared to land, landing at %1", mapGridPosition _at], "normal", _issuer] call FUNC(say);
    };
    if (_landing isEqualTo "") then {
        _job set ["landing", LANDING_CIRCLING];
        [_veh, LZ_CIRCLE_HEIGHT] call EFUNC(support,flyAt);
        [_veh, _target, "LIMITED", "LOITER", LZ_CIRCLE_RADIUS] call FUNC(moveTo);
        _logic setVariable [QGVAR(status), "circling", true];
        private _pop = toLower ([_job getOrDefault ["marking", ""]] call EFUNC(support,popWord));
        [_logic, format ["circling %1, looking for your %2", mapGridPosition _target, _pop], "normal", _issuer] call FUNC(say);
        [
            format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
            _threadId,
            _logic getVariable [QGVAR(callsign), "AIR"],
            _veh,
            _target,
            _job getOrDefault ["marking", ""],
            {_this call FUNC(liftCleared)},
            {_this call FUNC(threadTimeout)}
        ] call EFUNC(support,lzClear);
    };
    ["circling the LZ for the mark and clearance"] call _fnc_hold
};

// WHEELS DOWN.
if (_phase isEqualTo "down" && !(_job get "down")) then {
    _job set ["down", true];
    switch (_task) do {
        case TASK_PICKUP: {
            [_logic, CARD_WHEELS_DOWN, mapGridPosition _veh] call FUNC(threadCard);
            _job set ["step", JOB_LOADING];
            _job set ["loadUntil", CBA_missionTime + (_st getOrDefault ["wait", 0])];
        };
        case TASK_LAND: {
            // down on the LZ: too late to wave it off (2026-11-08)
            _veh setVariable [QGVAR(waveOff), nil, true];
            [_logic, CARD_WHEELS_DOWN, mapGridPosition _veh] call FUNC(threadCard);
            _job set ["step", JOB_PAX];
            [_logic, _threadId, PROMPT_PAX, ANSWERS_PAX] call FUNC(threadPrompt);
        };
        // THE TROOP LOAD (user, 2026-11-02: "troop load, all in (need an ace
        // interaction while in heli for all in)"): WHEELS DOWN AT PICKUP, then
        // TROOP LOAD - ALL IN? (allin / abort) - without D9 or any timeout.
        // ALL IN - the reply, or the scroll or ACE action aboard
        // (FUNC(canAllIn), FUNC(srvAllIn)) - lifts it, and nothing else does
        // (2026-11-06, FUNC(transportStep)).
        // An extraction never touches down (2026-11-08): IN THE HOVER.
        case TASK_EXTRACT: {
            [_logic, CARD_IN_HOVER, format [WHEELS_DOWN_PICKUP, mapGridPosition _veh]] call FUNC(threadCard);
            [_logic] call FUNC(liftLoad);
        };
        // THE PICKUP (user, 2026-11-08: the pickup report split from the
        // insertion): down and shut down; with no INSERTION yet it asks for
        // one (JOB_INSERT) and waits for it - FUNC(liftReply) merges it and
        // asks the troop load.
        case TASK_LIFT: {
            [_logic, CARD_WHEELS_DOWN, format [WHEELS_DOWN_PICKUP, mapGridPosition _veh]] call FUNC(threadCard);
            _job set ["onDeck", true];
            if ((_job getOrDefault ["lz", []]) isEqualTo []) exitWith {
                _job set ["step", JOB_INSERT];
                [_logic, _threadId, PROMPT_INSERT, ANSWERS_INSERT] call FUNC(threadPrompt);
            };
            [_logic] call FUNC(liftLoad);
        };
        // A MOVE's LAND (2026-11-09): down and shut down, till told.
        case TASK_LAND_OFF: {
            if (_step isEqualTo JOB_MOVE) then {[_logic, CARD_WHEELS_DOWN, mapGridPosition _veh] call FUNC(threadCard)};
        };
        default {};
    };
};

// LOADING PATIENTS: aboard, or the wait up - where to?
if (_phase isEqualTo "down" && (_job get "step") isEqualTo JOB_LOADING) then {
    private _aboard = count ((fullCrew [_veh, "cargo"]) select {alive (_x select 0)});
    private _full = _aboard >= (_job get "patients");
    if (!_full && CBA_missionTime < (_job get "loadUntil")) exitWith {};
    _job set ["step", JOB_DEST];
    [_logic, _threadId, [format [PROMPT_DEST_COUNT, _aboard], PROMPT_DEST] select _full, ANSWERS_DEST] call FUNC(threadPrompt);
};

false
