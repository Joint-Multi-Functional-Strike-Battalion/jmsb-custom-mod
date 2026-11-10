#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the leader's follow-up in a run's thread - the "reply" code this
 * addon hands the support core (2026-11-02, the jump by message). The core
 * passes the issuer's replies (and the observer's or a FIRES net man's of
 * the same side, gated again) as one word; only the thread a run flies for
 * moves it:
 *
 *   "stop"  ABORT, RTB, or CLOSE: stood down - holds over the DZ while men
 *           are aboard, JUMP open, then leaves (FUNC(srvAbort))
 *   "go"    GO, the answer to MEN STILL ABOARD - HOLDING OVER THE DZ: the
 *           rest out over the DZ (FUNC(srvGo))
 *   "board" BOARD (user, 2026-11-02: "have team leader send a board message
 *           then move the team to cargo"), the answer to ON STATION - SEND
 *           BOARD WHEN READY: the stick put aboard a module's airframe and
 *           the run started (FUNC(srvBoard))
 *
 * 2026-11-09 (docs/DESIGN_MESSAGE_TEMPLATES.md tree 2): "abort" (no longer a
 * stop word, the same stand-down), "go" also at the red light (the green
 * light now), "nodrop" (NO DROP - another pass, or hold, FUNC(srvNoDrop)),
 * "frago" (the run changed before it starts, FUNC(srvFrago)), "escort"
 * (EFUNC(support_air,escortCall)).
 *
 * A manual stick needs no reply: each man jumps from his action menu.
 *
 * Arguments:
 * 0: Asset id, "jump:<n>" or "jump:<side>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: The reply <HASHMAP>
 * 3: Who sent it <OBJECT>
 * 4: What it is <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jump:west", _thread, _message, _leader, "go"] call jmfsb_jumpmaster_fnc_srvReply
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_who", objNull, [objNull]],
    ["_word", "", [""]]
];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvReply: refused - remote call from machine %1",remoteExecutedOwner);
};

private _threadId = _thread getOrDefault ["id", ""];
private _at = GVAR(runs) findIf {(_x get "thread") isEqualTo _threadId};
if (_at < 0) exitWith {};
private _st = GVAR(runs) select _at;
INFO_3("srvReply: %1 '%2' from %3",_st get "callsign",_word,name _who);

switch (_word) do {
    // RTB stands the run down as ever; ABORT too (2026-11-09: no longer a
    // stop word, the same meaning here - holding over the DZ, JUMP when ready).
    // RTB WITH A LAND AT POINT while players are aboard (user, 2026-11-09):
    // it lands there and lets them out, then goes home (FUNC(srvRtbLand));
    // no point, no players - stood down as before.
    case WORD_STOP: {
        private _land = [_message, _st get "veh"] call EFUNC(support,rtbLanding);
        // Men standing in the bay are attached to the hull, not in a seat, so
        // the core does not see them aboard: asked here (FUNC(aboard)).
        if (_land isEqualTo [] && {(_st get "bay") isEqualTo BAY_STAND} && {([_st] call FUNC(aboard)) findIf {isPlayer _x} >= 0}) then {
            _land = ([createHashMap, _message] call EFUNC(support,readOrder)) getOrDefault ["land", []];
        };
        if (_land isEqualTo [] || {!([_st, _land] call FUNC(srvRtbLand))}) then {
            if ((_st get "phase") isNotEqualTo PHASE_LAND) then {[_st] call FUNC(srvAbort)};
        };
    };
    case WORD_ABORT: {[_st] call FUNC(srvAbort)};
    case WORD_GO: {[_st] call FUNC(srvGo)};
    case WORD_BOARD: {[_st, _who] call FUNC(srvBoard)};
    case WORD_NO_DROP: {[_st] call FUNC(srvNoDrop)};
    case WORD_FRAGO: {[_st, _thread, _message] call FUNC(srvFrago)};
    // ESCORT (user, 2026-11-09: "a way to call in escorts to all transports no
    // mater the phase or tasking"): a module's aircraft takes the module's
    // escort classes (EFUNC(support_air,escortCall)); a side's own has none.
    case WORD_ESCORT: {
        private _logic = _st getOrDefault ["logic", objNull];
        if (isNull _logic) exitWith {
            [_st get "assetId", _st get "thread", SAID_NO_ESCORT_MODULE, false, _st get "callsign"] call EFUNC(support,threadEvent);
        };
        private _veh = _st get "veh";
        if (isNull _veh) then {_veh = _logic getVariable [QGVAR(veh), objNull]};
        [_logic, _veh, _st get "green", _st get "assetId", _st get "side", _st get "thread", _st get "callsign"] call EFUNC(support_air,escortCall);
    };
    default {};
};
