#include "script_component.hpp"
/*
 * Author: YonV
 * One tick of a strike card flown from station (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 1.1: "it comes in from the hold at 4,000 m ATL,
 * strikes after CLEARED HOT, and returns to the hold"). Run by FUNC(casTick)
 * while the sortie is on station with a strike booked by FUNC(srvThread), and
 * in the phases this sets:
 *
 * THE 2026-11-09 FLOW (docs/DESIGN_MESSAGE_TEMPLATES.md, the trees' tree 3):
 *
 *   "station"  at the hold until the READBACK is CORRECT (FUNC(threadReply));
 *              then IP INBOUND with its ETA, at the attack height, for the
 *              IP - the card's IP / BP (Line 1), else CAS_IP_DEFAULT m out
 *              from the target on the hold's side
 *   "jobIn"    to the IP. There, cleared already - in; not - IN asks the
 *              clearance (CLEARED HOT, CONTINUE, ABORT, ALL ATTACK; Type 3
 *              CLEARED TO ENGAGE), once a pass
 *   "jobIp"    orbiting the IP for the clearance, or for the TOT (the pass
 *              begins at the order's TOT less CAS_TOT_LEAD s)
 *   "jobDry"   CONTINUE: a dry pass to CAS_DRY_RING m of the target, then
 *              back to the IP and IN again
 *   "jobRun"   the pass (FUNC(casStrike) - 2026-11-05, the CAS drones' pass,
 *              modelled on Simplex Support Services: lined up on the bearing
 *              from the IP, dived on the aim, the card's store released on a
 *              solution, its DC tick lifting the module's Friendly Range),
 *              ticked until it is over; then OFF - REQUEST BDA, or after a
 *              CLEARED TO ENGAGE, ATTACK COMPLETE - REQUEST BDA
 *   "jobOut"   to the card's egress point (Line 9), then back to the hold
 *   "jobHold"  HOLD: it orbits where it was told until the next order
 *
 * Back at the hold it holds for the BDA (FUNC(threadReply)): RE-ATTACK is this
 * again from "station" - IP INBOUND, IN, a new clearance.
 *
 * ALL ATTACK (user, 2026-11-02): cleared that way, a fixed-wing flight's
 * escort drones go in on the target area as it leaves the hold
 * (FUNC(allAttack)) and it says ALL ATTACK - FLIGHT IN HOT; its OFF waits for
 * the drones (area clear, Winchester, or ALL_ATTACK_BDA_WAIT s) and counts
 * what they destroyed: OFF - RETURNING TO STATION - DRONES DESTROYED <n> -
 * REQUEST BDA.
 *
 * Back at the hold (FUNC(casTick) "back") a strike that began and never
 * released closes its thread; one ABORTED is dropped, its thread kept for the
 * intentions it asked. Off the card, before it runs in: nothing left aboard - CANTCO
 * "NO STORES" and Winchester home; held for friendlies inside the module's
 * Friendly Range - CANTCO "DANGER CLOSE NOT ACKNOWLEDGED", back to the hold.
 * A pass that put nothing down - broken off at the floor, never lined up,
 * the store would not fire - CANTCO "NO RELEASE", back to the hold. The
 * issuer standing it down (CLOSE in its thread) ends it where it is:
 * at the hold it is dropped, in the air the pass is ended and the aircraft
 * turns back.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The sortie's state <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st] call jmfsb_support_air_fnc_casJob
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]]];

private _job = _logic getVariable [QGVAR(job), createHashMap];
if (count _job isEqualTo 0) exitWith {};

private _phase = _st getOrDefault ["phase", ""];
private _target = _job get "pos";
private _ingress = _job getOrDefault ["ingress", []];
private _egress = _job getOrDefault ["egress", []];
private _threadId = _job getOrDefault ["thread", ""];
private _requester = _job getOrDefault ["requester", objNull];
private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];

// THE IP (2026-11-09): the card's IP / BP (its Line 1), else CAS_IP_DEFAULT m
// out from the target towards the hold - a helicopter's run-in distance.
private _ip = _job getOrDefault ["ipPos", []];
if (_ip isEqualTo []) then {
    _ip = _ingress;
    if (_ip isEqualTo []) then {
        private _out = [_logic getVariable [QGVAR(runIn), CAS_IP_DEFAULT], CAS_IP_DEFAULT] select (_st getOrDefault ["fw", false]);
        _ip = _target getPos [_out, _target getDir (_st get "hold")];
    };
    _job set ["ipPos", _ip];
};

private _fnc_back = {
    [_veh, "back to the hold", "", true] call EFUNC(cas,passEnd);
    [_veh, _st get "hold", "FULL"] call FUNC(moveTo);
    _st set ["phase", "back"];
    _logic setVariable [QGVAR(status), "off target", true];
};
private _fnc_said = {
    params ["_state", "_said"];
    [_logic, _state, _said, _threadId] call FUNC(threadState);
};
private _fnc_ask = {
    params ["_what", ["_values", []]];
    [_assetId, _threadId, _what, _values, _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
};
// THE PASS BEGINS (2026-11-05): on the bearing from the IP. What keeps it
// from beginning is said in the thread.
private _fnc_begin = {
    private _res = [_logic, _veh, _target, _logic getVariable [QGVAR(searchRadius), 0], "run", _requester, _job getOrDefault ["danger", false], _target getDir _ip] call FUNC(casStrike);
    switch (_res) do {
        case "begun": {_st set ["phase", "jobRun"]};
        case "dry": {
            ["DECLINED", WHY_NO_STORES] call _fnc_said;
            _logic setVariable [QGVAR(job), nil];
            [_logic, _st, _requester] call FUNC(casWinchester);
        };
        case "unsafe": {
            ["DECLINED", WHY_DANGER_CLOSE] call _fnc_said;
            _job set ["over", true];
            call _fnc_back;
        };
        default {
            ["DECLINED", WHY_NO_TARGET] call _fnc_said;
            _job set ["over", true];
            call _fnc_back;
        };
    };
};
// CLEARED, AT THE IP: in - IN said now when it was cleared before it asked
// (step 5), the clearance spent on this pass, the ALL ATTACK's drones with it.
private _fnc_go = {
    _job set ["again", false];
    _job set ["begun", true];
    _logic setVariable [QGVAR(status), "attacking", true];
    // ALL ATTACK (user, 2026-11-02): its escort drones go in on the target
    // area with it (FUNC(allAttack)) - ALL ATTACK - FLIGHT IN HOT. A flight
    // whose escorts are gone by now goes in alone, as CLEARED HOT.
    if ((_job getOrDefault ["allAttack", false]) && {([_logic, _veh, _job] call FUNC(allAttack)) > 0}) then {
        ["IN_PROGRESS", ALL_ATTACK_IN] call _fnc_said;
    } else {
        _job set ["allAttack", false];
        ["IN_PROGRESS", format ["in hot on %1", mapGridPosition _target]] call _fnc_said;
    };
    if !(_job getOrDefault ["inAsked", false]) then {[_logic, _threadId, CAS_IN, []] call FUNC(casSay)};
    call _fnc_begin;
};
// At the IP and not cleared: IN asks the clearance (2026-11-09), once a pass,
// and it orbits the IP for the answer.
private _fnc_atIp = {
    if (_job getOrDefault ["cleared", false]) exitWith {
        if (CBA_missionTime < (_job getOrDefault ["leaveAt", -1])) exitWith {
            if (_phase isNotEqualTo "jobIp") then {
                [_veh, _ip, "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
                _st set ["phase", "jobIp"];
            };
        };
        call _fnc_go;
    };
    if !(_job getOrDefault ["inAsked", false]) then {
        _job set ["inAsked", true];
        [CAS_ASK_IN, [mapGridPosition _target, _job getOrDefault ["control", 0], [_veh] call FUNC(canAllAttack)]] call _fnc_ask;
    };
    if (_phase isNotEqualTo "jobIp") then {
        [_veh, _ip, "NORMAL", "LOITER", RADIUS_MIN] call FUNC(moveTo);
        _st set ["phase", "jobIp"];
        _logic setVariable [QGVAR(status), "holding", true];
    };
};

// STOOD DOWN by the issuer, or no answer to its prompt (step 5): dropped at the
// hold, turned back on the way in. One already on its way out carries on out.
if ((_job getOrDefault ["stop", false]) && _phase isNotEqualTo "jobOut") exitWith {
    ["CLOSED", _job getOrDefault ["said", "stood down"]] call _fnc_said;
    if (_phase isEqualTo "station") exitWith {
        _logic setVariable [QGVAR(job), nil];
    };
    call _fnc_back;
};
// HELD (2026-11-09, HOLD in the thread - FUNC(threadReply)): it orbits where it
// was told until the next order.
if (_job getOrDefault ["held", false]) exitWith {};

switch (_phase) do {
    case "station": {
        // THE READBACK FIRST (2026-11-09): nothing runs in before CORRECT.
        if ((_job getOrDefault ["rb", RB_OK]) isNotEqualTo RB_OK) exitWith {};
        // IP INBOUND: off the hold for the IP, at the attack height, its ETA.
        _veh setVariable [QEGVAR(cas,ordnance), _job getOrDefault ["mag", ""]];
        [_veh, FLY_ATTACK] call EFUNC(support,flyAt);
        _job set ["ip", true];
        _job set ["inAsked", false];
        private _eta = [typeOf _veh, [getPosATL _veh, _ip], SPEED_FULL] call FUNC(flightTime);
        [CAS_ASK_IP_INBOUND, [format [CAS_IP_ETA, [_eta] call EFUNC(support,etaText)]]] call _fnc_ask;
        [_veh, _ip, "FULL"] call FUNC(moveTo);
        _st set ["phase", "jobIn"];
        _logic setVariable [QGVAR(status), "inbound", true];
    };
    case "jobIn": {
        if (_veh distance2D _ip > CAS_ENTRY_RING) exitWith {};
        call _fnc_atIp;
    };
    case "jobIp": {call _fnc_atIp};
    // A CONTINUE'S DRY PASS (2026-11-09): run in to CAS_DRY_RING of the
    // target, nothing released, then back to the IP to ask IN again.
    case "jobDry": {
        if (_veh distance2D _target > CAS_DRY_RING) exitWith {};
        _job set ["dry", false];
        _job set ["inAsked", false];
        [_veh, _ip, "FULL"] call FUNC(moveTo);
        _st set ["phase", "jobIn"];
    };
    case "jobRun": {
        private _res = [_veh] call EFUNC(cas,passTick);
        if (_res in ["line", "dive"]) exitWith {};
        INFO_2("%1 strike from station - pass %2",_callsign,_res);
        if (_res isNotEqualTo "fired") exitWith {
            ["DECLINED", WHY_NO_RELEASE] call _fnc_said;
            _job set ["over", true];
            call _fnc_back;
        };
        // OFF and REQUEST BDA (step 5) - or, cleared to engage (Type 3,
        // 2026-11-09), ATTACK COMPLETE - REQUEST BDA; it holds at the hold for
        // the answers (FUNC(casTick) "back"). The pass is over: a FRAGO is
        // taken again.
        _job set ["struck", true];
        _job set ["ip", false];
        private _engaged = _job getOrDefault ["engaged", false];
        _job set ["engaged", false];
        if (_job getOrDefault ["allAttack", false]) then {
            // AFTER AN ALL ATTACK (user, 2026-11-02) the OFF waits for the
            // drones to be done - area clear, Winchester, or
            // ALL_ATTACK_BDA_WAIT s - and counts what they destroyed.
            private _fnc_off = {
                params ["_logic", "_threadId", "_veh", "_engaged", "_assetId", "_callsign"];
                private _hits = _veh getVariable [QEGVAR(support,escortHits), 0];
                if (_engaged) exitWith {
                    [_assetId, _threadId, CAS_ASK_COMPLETE, [_hits], _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
                };
                [_logic, _threadId, CAS_OFF, [_hits]] call FUNC(casSay);
            };
            [
                {count ((_this select 2) getVariable [QEGVAR(support,escortAttack), createHashMap]) isEqualTo 0},
                _fnc_off,
                [_logic, _threadId, _veh, _engaged, _assetId, _callsign],
                ALL_ATTACK_BDA_WAIT,
                _fnc_off
            ] call CBA_fnc_waitUntilAndExecute;
        } else {
            if (_engaged) exitWith {[CAS_ASK_COMPLETE] call _fnc_ask};
            [_logic, _threadId, CAS_OFF, []] call FUNC(casSay);
        };
        if (_egress isEqualTo []) exitWith {call _fnc_back};
        [_veh, _egress, "FULL"] call FUNC(moveTo);
        _st set ["phase", "jobOut"];
        _logic setVariable [QGVAR(status), "off target", true];
    };
    case "jobOut": {
        if (_veh distance2D _egress > CAS_ENTRY_RING) exitWith {};
        call _fnc_back;
    };
    // The HOLD released (a clearance, CORRECT, a new card): it runs in again
    // from where it is - IP INBOUND (2026-11-09).
    case "jobHold": {_st set ["phase", "station"]};
};
