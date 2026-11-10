#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a card filed to a CAS module's box - the "thread" code this addon
 * hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING step 3 and
 * 1.1). The core has asked the issuer's tasking gate and his side already;
 * this finds the module by its id (a dedicated server has no `player` for
 * FUNC(assets)) and asks its own questions again. A transport's card is
 * FUNC(liftThread)'s, a QRF's FUNC(qrfThread)'s (step 7, 2026-11-01).
 *
 * FIXED-WING: ON STATION FIRST, THEN THE STRIKE (user, 2026-11-01: "need a
 * request for on station fixed wing, then use the strike request we have").
 *   REQUEST ON STATION   the aircraft launches - a class jet made over the
 *                        module at 4000 m (user, 2026-11-02: virtual until
 *                        tasked) - flies dark to its hold 8 km
 *                        off the map edge nearest the AREA - the map marker
 *                        the card requires since 2026-11-02 (an older deck's
 *                        empty area: the issuer's own position), answers WILCO
 *                        "LAUNCHING - ON STATION IN m:ss" - an order to get
 *                        in the air, no strike checks (user, 2026-11-02) -
 *                        and, on arrival, files a check-in in
 *                        the thread (FUNC(checkIn)). Time on station is the
 *                        one asked, no longer than the module's.
 *   `cas`                to an aircraft on station: a strike from the hold
 *                        (FUNC(casJob)) - in at 4000 m ATL after CLEARED HOT,
 *                        back to the hold after. Not on station: CANTCO
 *                        "NOT ON STATION".
 * HELICOPTER: no on-station step - a `cas` card is an ATTACK RUN that holds
 * short of the target until CLEARED HOT; a REQUEST ON STATION is a LOITER
 * over the area's marker, dark, weapons tight. Either way it checks in when it gets
 * there (FUNC(checkIn), user 2026-11-02). Any aircraft already on station
 * takes a strike from there.
 *
 * THE CARD, field by field (EFUNC(support,readOrder)): Line 1 the target (none:
 * "NO TARGET LOCATION"); Line 3 / 4 ingress / egress, empty - the aircraft
 * picks; Line 5 the description, repeated in the WILCO; Line 6 danger close
 * (EFUNC(support,dangerClose), and the DC tick lets the release near
 * friendlies through the module's Friendly Range too); Line 7 LASER - a
 * laser-guided store or "CANNOT LASE <code>", and PREFERRED MUNITIONS - the
 * store when carried (EFUNC(cas,orderStore)). Busy, rearming or spent: the
 * reach card's word (FUNC(reach)).
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
 * ["air:0", _thread, _message, _issuer] call jmfsb_support_air_fnc_srvThread
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
// The support core's own call, from its messaging hook - never a client's.
if (isRemoteExecuted) exitWith {
    WARNING_1("srvThread: refused - remote call from machine %1",remoteExecutedOwner);
    []
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, WHY_LOST]};
// ITS LAST AIRFRAME GONE (user, 2026-11-02: "make sure there is a respawn count
// for each support, default no respawns"): every card, every kind.
if (_logic getVariable [QGVAR(dead), false]) exitWith {[false, WHY_NO_AIRFRAME]};
// Transport and QRF by message (step 7, 2026-11-01).
private _moduleKind = _logic getVariable [QGVAR(kind), ""];
if (_moduleKind isEqualTo KIND_TRANSPORT) exitWith {_this call FUNC(liftThread)};
if (_moduleKind isEqualTo KIND_QRF) exitWith {_this call FUNC(qrfThread)};
if (_moduleKind isNotEqualTo KIND_CAS) exitWith {[]};

private _order = [_thread, _message] call EFUNC(support,readOrder);
private _kind = _order getOrDefault ["kind", ""];
if !(_kind in [ORDER_STRIKE, ORDER_STATION]) exitWith {[]};

private _threadId = _thread getOrDefault ["id", ""];
private _synced = _logic getVariable [QGVAR(synced), objNull];
private _what = [_logic getVariable [QGVAR(cls), ""], _synced] select (alive _synced);
private _fw = !(_what isKindOf "Helicopter");
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _status = _logic getVariable [QGVAR(status), STATUS_IDLE];
private _out = _logic getVariable [QGVAR(ticking), false];
private _onStation = _out && (_logic getVariable [QGVAR(onStation), false]);
private _busyWhy = [WHY_TASKED, WHY_RTB] select (_status isEqualTo STATUS_RTB);

// WILCO's words: the ETA, then what it is for.
private _fnc_wilco = {
    params ["_eta", "_what"];
    private _words = [[_eta] call EFUNC(support,etaText)];
    if (_what isNotEqualTo "") then {_words pushBack (_what select [0, DESCRIPTION_MAX])};
    [_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _logic getVariable [QGVAR(callsign), "AIR"], false, _threadId] call EFUNC(support,state);
};

// --- REQUEST ON STATION ------------------------------------------------------
if (_kind isEqualTo ORDER_STATION) exitWith {
    // How long it holds: what was asked, never longer than the module's.
    private _full = _logic getVariable [QGVAR(stationTime), 600];
    private _minutes = _order getOrDefault ["minutes", 0];
    private _station = [_full, _full min (_minutes * SECONDS_PER_MINUTE)] select (_minutes > 0);
    private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];

    // VIRTUAL UNTIL TASKED (user, 2026-11-02): this is its task - the airframe
    // is made over the module at the WILCO and flies to its station. One out
    // on a task already is busy.
    if (_out) exitWith {[false, _busyWhy]};
    private _area = _order getOrDefault ["area", []];
    if (_area isEqualTo []) then {
        (getPosATL _issuer) params ["_ix", "_iy"];
        _area = [_ix, _iy, 0];
    };
    // AN ORDER TO GET IN THE AIR, NOT A FIRE MISSION (user, 2026-11-02): no
    // danger close, target, laser or stores is asked of it - those are the
    // `cas` card's, when one comes.
    ([_assetId, _area] call FUNC(reach)) params ["_can", "_reachEta", "_why"];
    if (!_can) exitWith {[false, _why]};

    // The ETA to the station - a jet's hold off the map: from the module (a
    // class jet is made over it now) or from its stand, at cruise.
    private _eta = _reachEta;
    if (_fw) then {
        private _hold = [_what, _area] call EFUNC(support,holdPoint);
        private _from = [_logic getVariable [QGVAR(home), getPosATL _logic], getPosATL _synced] select (alive _synced);
        _eta = [_logic getVariable [QGVAR(cls), ""], [_from, _hold], SPEED_NORMAL] call FUNC(flightTime);
    };
    // ROGER, WILCO - LAUNCHING - ON STATION IN m:ss (user, 2026-11-02).
    [_assetId, "ACCEPTED", [_eta] call EFUNC(support,stationWilco), _callsign, false, _threadId] call EFUNC(support,state);

    [_logic, TASK_LOITER, _area, [], _issuer, createHashMapFromArray [
        ["thread", _threadId],
        ["stationTime", _station]
    ]] call FUNC(casOrder);
    [true, ""]
};

// --- A STRIKE ------------------------------------------------------------------
private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {[false, WHY_NO_TARGET]};
([_order, _logic getVariable [QGVAR(side), west]] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy"];
if (!_safe) exitWith {[false, _unsafeWhy]};

private _desc = _order getOrDefault ["description", ""];
private _label = _order getOrDefault ["label", ""];
if (_label isNotEqualTo "") then {_desc = trim format ["%1 (%2)", _desc, _label]};

// ON STATION, ANY AIRCRAFT: in from the hold (FUNC(casJob)) - the WILCO, the
// strike booked and D9's 60 s wait are FUNC(casRetask)'s (step 5, 2026-11-01).
if (_onStation) exitWith {
    if (!alive _veh) exitWith {[false, WHY_NOT_ON_STATION]};
    if (count (_logic getVariable [QGVAR(job), createHashMap]) > 0) exitWith {[false, WHY_TASKED]};
    private _retaskWhy = [_logic, _threadId, _order, _issuer] call FUNC(casRetask);
    [_retaskWhy isEqualTo "", _retaskWhy]
};

// A FIXED-WING NOT ON STATION is asked for it first (doc 1.1).
// Still flying out to its hold is NOT ON STATION too, as WORKFLOWS 3.2 says
// (2026-11-05: it answered TASKED); going home is RTB.
if (_fw) exitWith {[false, [WHY_NOT_ON_STATION, WHY_RTB] select (_out && _status isEqualTo STATUS_RTB)]};

// A HELICOPTER: an ATTACK RUN, held short until CLEARED HOT.
([_assetId, _target] call FUNC(reach)) params ["_can", "_eta", "_why"];
if (!_can) exitWith {[false, _why]};
([_what, _order] call EFUNC(cas,orderStore)) params ["_armed", "_unarmedWhy", "_mag"];
if (!_armed) exitWith {[false, _unarmedWhy]};

// The board's parameter array, padded as the board pads it, with the card's
// points and its DC tick in the slots this provider reads.
private _prm = [];
for "_i" from 0 to SLOT_DANGER do {_prm pushBack []};
_prm set [SLOT_INGRESS, _order getOrDefault ["ingress", []]];
_prm set [SLOT_EGRESS, _order getOrDefault ["egress", []]];
_prm set [SLOT_DANGER, [0, 1] select (_order getOrDefault ["dcTick", false])];
([_logic, TASK_RUN, _target, _prm, _issuer] call FUNC(check)) params ["_ok", "_checkWhy", "_at"];
if (!_ok) exitWith {[false, _checkWhy]};

[_eta, _desc] call _fnc_wilco;
[_logic, TASK_RUN, _at, _prm, _issuer, createHashMapFromArray [
    ["thread", _threadId],
    ["mag", _mag],
    ["clear", true],
    ["flow", [_order] call FUNC(casFlow)]
]] call FUNC(casOrder);
// THE READBACK (2026-11-09, tree 3): the target and the restrictions read back
// after the WILCO - CORRECT lets it run in, held short it asks IN and the
// clearance (FUNC(casRun)). The next frame, so the WILCO is out first.
[{
    params ["_assetId", "_threadId", "_callsign", "_order"];
    [_assetId, _threadId, CAS_ASK_READBACK, [mapGridPosition (_order getOrDefault ["target", [0, 0, 0]]), _order getOrDefault ["remarks", ""]], _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
}, [_assetId, _threadId, _logic getVariable [QGVAR(callsign), "AIR"], _order]] call CBA_fnc_execNextFrame;
[true, ""]
