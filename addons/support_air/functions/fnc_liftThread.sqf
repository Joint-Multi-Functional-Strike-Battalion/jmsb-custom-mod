#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a card filed to a transport module's box (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 7; user: "per the doc i want to use the
 * messaging system to call ai support") - from FUNC(srvThread). The core has
 * asked the issuer's tasking gate and his side already; this asks the
 * module's own questions again (FUNC(reach), FUNC(check)).
 *
 * THE CARDS, field by field (EFUNC(support,readOrder)):
 *   `pickup`   PICKUP (user, 2026-11-08: the pickup report split from the
 *              insertion): lands at its Pickup line (none - the issuer's
 *              position), always safe, shuts down, and asks ON DECK AT
 *              PICKUP, SHUT DOWN - SEND THE INSERTION (JOB_INSERT). The
 *              `hlz` filed in this thread gives the LZ (FUNC(liftReply)):
 *              then TROOP LOAD - ALL IN?, and on ALL IN the insertion below
 *   `hlz`      INSERTION (HLZ), filed alone: PICKUP > LZ from the issuer's
 *              position - always safe (user, 2026-11-02): no 1 MIN OUT, no
 *              circle, no clearance - WHEELS DOWN AT PICKUP, TROOP LOAD - ALL
 *              IN?; it holds on the ground and lifts on ALL IN alone (the
 *              reply, or the scroll or ACE action aboard - 2026-11-06), the
 *              men on foot there (PICKUP_PAX_RADIUS at touchdown) its
 *              passengers; flies
 *              them to Line 1 (none, and no marker on Line 2: "NO TARGET
 *              LOCATION") through the ROUTE points (Line 6 A-D, in order, nap
 *              of the earth; none - direct), lands with the full procedure,
 *              puts them out; PAX OFF - the EGRESS points (Line 7 A-D), home,
 *              CLOSED EGRESS - RTB. Line 3 is repeated in the WILCO; Line 5's
 *              marking is what 1 MIN OUT tells the issuer to pop at the LZ
 *   `casevac`  PICKUP at Line 1 (none: "NO TARGET LOCATION"), engine running;
 *              the patients (Line 2, or Line 3's sum) are loaded, then it asks
 *              the destination (FUNC(liftReply))
 *   `airdrop`  the PARADROP card (report-card review, 2026-11-02: supplies
 *              go by RESUPPLY): over Line 1 at the module's jump height - the
 *              cabin jumps; Contents is repeated in the WILCO; its Marking is
 *              what the 1 MIN OUT alert asks to be popped. A module that does
 *              not offer it: "CANNOT PARADROP"
 *   `extract`  EXTRACTION (HLZ) (user, 2026-11-02: "need a pick up version
 *              where the pick up is the hot zone"): first ON STATION at the
 *              card's STATION marker (none - STATION_SHORT m short of the
 *              HLZ), holding till EXTRACT (2026-11-02: "1) on station 2)
 *              extraction"); then the whole landing at the pickup HLZ - 1 MIN
 *              OUT - POP SMOKE with LZ STATUS?, holding short of a hot one
 *              until CONFIRM, circling while the mark is verified, CLEARED TO
 *              LAND - the troop load as `hlz`'s (ALL IN), then its EGRESS
 *              points (A-D) and the destination with the same clearance, or
 *              home base without one. The WILCO says LAUNCHING - ON STATION
 *              IN m:ss and the passengers ("4 PAX")
 *   Line 4 (`hlz`, `casevac`; the extraction's LZ SECURITY) RED: a HOT LZ
 *              (doc 5.3) - WILCO "HOT LZ -
 *              REPLY CONFIRM TO LAUNCH" (user, 2026-11-01: it says what to do),
 *              and it lifts only after the issuer's CONFIRM; RTB or ABORT
 *              instead: CANTCO "HOT LZ NOT ACKNOWLEDGED"
 * The ROGER comes in the WILCO's text when the WILCO is this quick (the
 * support core's RECEIPT_HOLD): "ROGER, WILCO - ETA 2:40 - 4 PAX".
 * It flies nap of the earth and dark (the support core's tactical flight).
 * Busy or spent: the reach card's words; a second thread while one is flown:
 * "TASKED". The rest is FUNC(liftGo), FUNC(liftTick) and FUNC(liftReply).
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fly <ARRAY>
 *
 * Example:
 * ["air:1", _thread, _message, _issuer] call jmfsb_support_air_fnc_liftThread
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]]
];

if (!isServer) exitWith {[]};
if (isRemoteExecuted) exitWith {
    WARNING_1("liftThread: refused - remote call from machine %1",remoteExecutedOwner);
    []
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, WHY_LOST]};

private _order = [_thread, _message] call EFUNC(support,readOrder);
private _kind = _order getOrDefault ["kind", ""];
if !(_kind in [ORDER_PICKUP, ORDER_LIFT, ORDER_CASEVAC, ORDER_DROP, ORDER_EXTRACT]) exitWith {[]};

private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];

// ONE THREAD AT A TIME. A thread left waiting for a receipt is closed.
private _was = _logic getVariable [QGVAR(liftJob), createHashMap];
private _held = _was getOrDefault ["thread", ""];
if (_held isNotEqualTo "" && _held isNotEqualTo _threadId) then {
    if ((_was getOrDefault ["step", ""]) isNotEqualTo JOB_RECEIPT) exitWith {};
    [_logic, "CLOSED", SAID_RETASKED, _held] call FUNC(threadState);
    _logic setVariable [QGVAR(liftJob), nil];
    _logic setVariable [QGVAR(threadHold), nil];
};
if (count (_logic getVariable [QGVAR(liftJob), createHashMap]) > 0) exitWith {[false, WHY_TASKED]};
// OUT ON A TASK it is busy (user, 2026-11-02: virtual until tasked - a
// helicopter flies only for a task; the next card is NEXT LIFT's, above).
if (_logic getVariable [QGVAR(ticking), false]) exitWith {[false, WHY_TASKED]};

([_logic, _order, _issuer] call FUNC(liftLegs)) params ["_task", "_first", "_why"];
if (_why isNotEqualTo "") exitWith {[false, _why]};

([_assetId, _first] call FUNC(reach)) params ["_can", "_eta", "_reachWhy"];
if (!_can) exitWith {[false, _reachWhy]};

private _job = [_logic, _order, _issuer, _threadId, _task, _first] call FUNC(liftJob);
([_logic, _task, _first, _job get "prm", _issuer] call FUNC(check)) params ["_ok", "_checkWhy"];
if (!_ok) exitWith {[false, toUpper _checkWhy]};

// WILCO: the ETA and what it is for - or the hot LZ it wants confirmed.
private _what = switch (_kind) do {
    // THE 9-LINE (2026-11-09): how many, the litters, what the crew brings.
    case ORDER_CASEVAC: {
        private _parts = [format ["%1 PATIENTS", (_order getOrDefault ["patients", 0]) max 1]];
        private _litter = _order getOrDefault ["litter", -1];
        if (_litter > 0) then {_parts pushBack format [WILCO_LITTER, _litter]};
        private _kit = _order getOrDefault ["equipment", ""];
        if !(_kit in ["", CASEVAC_NO_EQUIPMENT]) then {_parts pushBack _kit};
        _parts joinString WILCO_SEP
    };
    case ORDER_DROP: {toUpper (_order getOrDefault ["contents", ""])};
    case ORDER_EXTRACT: {
        private _pax = _order getOrDefault ["passengers", -1];
        ["", format [WILCO_PAX, _pax]] select (_pax > 0)
    };
    default {toUpper (_order getOrDefault ["carry", ""])};
};
private _hot = (_order getOrDefault ["security", ""]) isEqualTo LZ_RED;
private _words = [[_eta] call EFUNC(support,etaText), _what select [0, DESCRIPTION_MAX]];
// AN EXTRACTION GOES ON STATION FIRST (user, 2026-11-02): LAUNCHING - ON
// STATION IN m:ss, the ETA to its STATION (FUNC(liftJob)).
if (_kind isEqualTo ORDER_EXTRACT) then {
    private _stationEta = ([_assetId, _job get "station"] call FUNC(reach)) param [1, _eta];
    _words set [0, [_stationEta] call EFUNC(support,stationWilco)];
};
if (_hot) then {_words = [WILCO_HOT] + _words};
[_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);

_logic setVariable [QGVAR(liftJob), _job];
INFO_4("liftThread: %1 %2 at %3 for %4",_callsign,_task,mapGridPosition _first,name _issuer);
// Its LZs and DZs in the side's AiTR from the WILCO (user, 2026-11-02).
[_logic] call FUNC(liftZones);

if (_hot) exitWith {
    _job set ["step", JOB_CONFIRM];
    [_logic, _threadId, "", ANSWERS_HOT] call FUNC(threadPrompt);
    [true, ""]
};

[_logic] call FUNC(liftGo);
[true, ""]
