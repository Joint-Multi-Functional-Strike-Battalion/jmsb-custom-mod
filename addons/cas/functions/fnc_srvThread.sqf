#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a card filed to a CAS drone's box - the "thread" code this addon
 * hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING step 3). The
 * core has asked the issuer's tasking gate and his side already; this finds
 * the drone by its id (a dedicated server has no `player` for FUNC(assets))
 * and asks its own questions again.
 *
 * A DRONE NEEDS NO ON-STATION STEP (doc 1.1): a `cas` card tasks it at once.
 * A REQUEST ON STATION is its LOITER: it orbits over the area - the map
 * marker the card requires since 2026-11-02 - dark,
 * at 4000 m, its camera on the grid (user, 2026-11-01: drones are exempt from
 * the off-map hold) - the issuer's position when no area is given. It is an
 * order to get in the air, never a strike (user, 2026-11-02: "on station is
 * not a fire mission its just an order to get in the air"): no danger close,
 * no target, no laser, no stores asked; nothing is released until a `cas`
 * card. Its WILCO: "LAUNCHING - ON STATION IN m:ss" (EFUNC(support,
 * stationWilco)) - the drone is made over the module now and flies there
 * (user, 2026-11-02: "all support aircraft needs to be virtual till tasked").
 * The last drone gone (the respawn count): CANTCO "UNABLE - NO AIRFRAME".
 *
 * THE CARD, field by field (EFUNC(support,readOrder)):
 *   Line 1 target          the grid; none - CANTCO "NO TARGET LOCATION"
 *   Line 3 / 4             ingress / egress; empty - the run picks (FUNC(request))
 *   Line 5 description     repeated in the WILCO
 *   Line 6                 danger close (EFUNC(support,dangerClose)) - CANTCO
 *                          "DANGER CLOSE NOT ACKNOWLEDGED"
 *   Line 7 LASER + code    a laser-guided store or CANTCO "CANNOT LASE <code>"
 *                          (FUNC(orderStore)); the run already looks for the
 *                          side's laser spot inside the terminal search radius
 *   PREFERRED MUNITIONS    the store, when carried (FUNC(orderStore))
 * Busy, rearming or expended: the reach card's word (FUNC(reach)) - TASKED,
 * COOLDOWN n S, EXPENDED; nothing hung on it: NO STORES.
 *
 * ACCEPTED: WILCO "ETA m:ss - <description>" in the thread, and the run flies
 * (FUNC(request), the server's own call naming the issuer). A strike HOLDS over
 * the grid until it is cleared (FUNC(threadReply)). 2026-11-09 (the CAS flow,
 * docs/DESIGN_MESSAGE_TEMPLATES.md tree 3): after the WILCO it asks the
 * READBACK (FUNC(casAsk)); CORRECT - IP INBOUND, and over the grid IN asks
 * CLEARED HOT (CLEARED TO ENGAGE on Type 3 control) - FUNC(runTick); the
 * order's TOT holds the pass (FUNC(runOrder)). Munitions are in the 9-line's
 * remarks since 2026-11-09: no PREFERRED MUNITIONS line is read.
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fly <ARRAY>
 *
 * Example:
 * ["cas:0", _thread, _message, _issuer] call jmfsb_cas_fnc_srvThread
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

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {[false, WHY_LOST]};
if (_logic getVariable [QGVAR(gone), false]) exitWith {[false, WHY_NO_AIRFRAME]};

private _order = [_thread, _message] call EFUNC(support,readOrder);
private _kind = _order getOrDefault ["kind", ""];
if !(_kind in [ORDER_STRIKE, ORDER_STATION]) exitWith {[]};
private _strike = _kind isEqualTo ORDER_STRIKE;

private _pos = _order getOrDefault [["area", "target"] select _strike, []];
if (_pos isEqualTo [] && !_strike) then {
    (getPosATL _issuer) params ["_ix", "_iy"];
    _pos = [_ix, _iy, 0];
};
if (_pos isEqualTo []) exitWith {[false, WHY_NO_TARGET]};

([_assetId, _pos] call FUNC(reach)) params ["_can", "_eta", "_why"];
if (!_can) exitWith {[false, _why]};

private _safe = [true, ""];
private _store = [true, "", ""];
if (_strike) then {
    _safe = [_order, _logic getVariable [QGVAR(side), west]] call EFUNC(support,dangerClose);
    _store = [_logic getVariable [QGVAR(cls), ""], _order] call FUNC(orderStore);
};
_safe params ["_isSafe", "_unsafeWhy"];
if (!_isSafe) exitWith {[false, _unsafeWhy]};
_store params ["_armed", "_unarmedWhy", "_mag"];
if (!_armed) exitWith {[false, _unarmedWhy]};

// WILCO's words: the ETA, then what it is going for. A REQUEST ON STATION is
// an order to get in the air (user, 2026-11-02): LAUNCHING - ON STATION IN m:ss.
private _wilco = [_eta] call EFUNC(support,stationWilco);
if (_strike) then {
    private _words = [[_eta] call EFUNC(support,etaText)];
    private _what = _order getOrDefault ["description", ""];
    private _label = _order getOrDefault ["label", ""];
    if (_label isNotEqualTo "") then {_what = trim format ["%1 (%2)", _what, _label]};
    if (_what isNotEqualTo "") then {_words pushBack (_what select [0, DESCRIPTION_MAX])};
    _wilco = (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP;
};

private _refused = [
    _logic, _pos,
    _order getOrDefault ["ingress", []],
    _order getOrDefault ["egress", []],
    _mag,
    [MODE_LOITER, MODE_STRIKE] select _strike,
    _issuer,
    createHashMapFromArray [["thread", _thread getOrDefault ["id", ""]], ["wilco", _wilco], ["clear", _strike]]
] call FUNC(request);
if (_refused isNotEqualTo "") exitWith {[false, _refused]};

// THE READBACK (2026-11-09, docs/DESIGN_MESSAGE_TEMPLATES.md tree 3): after
// the WILCO the drone reads the target and the restrictions back - CORRECT
// lets it run in (FUNC(runTick) asks IN and the clearance over the grid),
// WRONG asks a FRAGO. The run carries the type of control and the TOT. The
// next frame, so the WILCO is out first.
if (_strike) then {
    [_logic, _thread getOrDefault ["id", ""], _order] call FUNC(runOrder);
    [{
        params ["_assetId", "_threadId", "_logic", "_order"];
        [_assetId, _threadId, CAS_ASK_READBACK, [mapGridPosition (_order getOrDefault ["target", [0, 0, 0]]), _order getOrDefault ["remarks", ""]], _logic getVariable [QGVAR(callsign), "CAS"], {_this call FUNC(threadTimeout)}] call FUNC(casAsk);
    }, [_assetId, _thread getOrDefault ["id", ""], _logic, _order]] call CBA_fnc_execNextFrame;
};

[true, ""]
