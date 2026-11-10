#include "script_component.hpp"
/*
 * Author: YonV
 * One CAS run, server side: the order checked and booked here, the run flown
 * by FUNC(launch) and watched by FUNC(runTick).
 *
 * VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"): no drone is up between runs. The run starts at once - the drone
 * is made in the air over the module (FUNC(launch)) - and when it is over the
 * drone flies home and is removed (FUNC(recover)).
 *
 * THE GEOMETRY IS THE PLAYER'S AND IT IS THE WHOLE FEATURE. Ingress and egress
 * are POINTS ON THE MAP, so a section puts the run-in behind the ridge they
 * are looking at rather than converting it into a heading first. Either may be
 * unset: ingress then comes from the module's side of the target, where the
 * drone is made; egress carries straight on through. THE
 * RUN-IN DISTANCE IS A FLOOR, NOT A FIXED RANGE (FUNC(launch)).
 *
 * THE AI IS NOT FLYING THIS AND IS NOT SHOOTING IT. CARELESS, BLUE, targeting
 * off, driver locked: the group follows its waypoints and nothing else, and
 * the pass (FUNC(passBegin), 2026-11-05) is the only thing that puts a round
 * down - the drone lined up, dived and fired by script, Simplex's reason and
 * means (its method, no code of it).
 *
 * A LOITER IS THE SAME FLIGHT WITH A DIFFERENT ENDING: it holds an orbit over
 * the grid, nothing is released, and the gunner's seat is handed to the drone
 * controller who asked for it (FUNC(onStation)).
 *
 * TACTICAL (user, 2026-11-01). A strike runs in at the support core's attack
 * altitude (4000 m ATL); a loiter orbits OVER THE GRID at the hold altitude -
 * a drone is exempt from the off-map hold. Dark throughout
 * (EFUNC(support,tactical)).
 *
 * FROM A THREAD (2026-11-01, DESIGN_SUPPORT_MESSAGING step 3). A card filed
 * to the drone's box reaches here from FUNC(srvThread) - the server's own
 * call, which names the issuer; a remote-executed call never can. Its order
 * names the thread every state is said in, the WILCO text, and whether the
 * strike waits for CLEARED HOT (FUNC(threadReply)). The thread's strike stays
 * for its answers (step 5): IN, OFF and REQUEST BDA, back over the grid for the
 * BDA; BINGO from its time on station or its fuel (FUNC(runTick)).
 *
 * IT IS A REAL AIRCRAFT AND IT CAN BE LOST. MPKilled is wired to FUNC(killed);
 * the module's Respawns decide what comes after (FUNC(gone)).
 *
 * WHO ASKED IS THE SENDING MACHINE (review S6). FUNC(task) sends this by
 * remoteExec; the caller is that machine's player, his side must be the
 * module's and the support tasking gate must let him (FUNC(mayTask)), all
 * before the start a frame later, where the sender is no longer known. The store
 * must be one this airframe carries and the mode one FUNC(task) sends.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target grid <ARRAY> - ATL
 * 2: Ingress position, [] for auto <ARRAY> - ATL
 * 3: Egress position, [] for auto <ARRAY> - ATL
 * 4: Store to use, "" for the heaviest thing aboard <STRING> (optional, default "")
 * 5: "strike" or "loiter" <STRING> (optional, default "strike")
 * 6: The issuer - only on the server's own call (FUNC(srvThread)) <OBJECT> (optional, default objNull)
 * 7: The thread's order - "thread" id, "wilco" text, "clear" (wait for CLEARED HOT) - only on the server's own call <HASHMAP> (optional, default empty)
 *
 * Return Value:
 * Why it was not flown, "" when it is <STRING>
 *
 * Example:
 * [_logic, _pos, [], [], "", "strike"] remoteExecCall ["jmfsb_cas_fnc_request", 2]
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_ingress", [], [[]]],
    ["_egress", [], [[]]],
    ["_mag", "", [""]],
    ["_mode", MODE_STRIKE, [""]],
    ["_issuer", objNull, [objNull]],
    ["_order", createHashMap, [createHashMap]]
];

if (!isServer || isNull _logic) exitWith {"no asset"};
if (_pos isEqualTo []) exitWith {WHY_NO_TARGET};

// WHO ASKED. A client's call (remote executed, nested or not) is the sending
// machine's player, whatever the arguments say (FUNC(mayTask)), and names no
// thread. Only the server's own call - a thread filed to the drone's box -
// names its issuer, and he is held to the same three questions.
private _may = false;
private _caller = objNull;
private _whyNot = "";
if (!isRemoteExecuted && !isNull _issuer) then {
    _caller = _issuer;
    _may = alive _issuer && _logic in GVAR(entities);
    if (_may) then {_may = (_logic getVariable [QGVAR(side), sideUnknown]) isEqualTo (side group _issuer)};
    if (_may) then {_may = ([_issuer] call EFUNC(support,canTask)) select 0};
    if (!_may) then {_whyNot = format ["%1 may not task %2", name _issuer, _logic getVariable [QGVAR(callsign), "CAS"]]};
} else {
    ([_logic] call FUNC(mayTask)) params ["_sentOk", "_sender", "_sentWhy"];
    _may = _sentOk;
    _caller = _sender;
    _whyNot = _sentWhy;
    _order = createHashMap;
};
if (!_may) exitWith {
    WARNING_2("request: refused from machine %1 - %2",remoteExecutedOwner,_whyNot);
    _whyNot
};
if !(_mode in [MODE_STRIKE, MODE_LOITER]) exitWith {
    WARNING_1("request: refused - unknown mode '%1'",_mode);
    "unknown task"
};
if (_mag isNotEqualTo "" && {([_logic getVariable [QGVAR(cls), ""]] call FUNC(stores)) findIf {(_x param [0, ""]) isEqualTo _mag} < 0}) exitWith {
    WARNING_1("request: refused - '%1' is not a store this airframe carries",_mag);
    WHY_NO_STORES
};

private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
// What the side is told: the flight from the module, where the drone is made
// (user, 2026-11-02), by the ingress point when one was given.
private _ms = (_logic getVariable [QGVAR(speed), REACH_DEF_SPEED]) / KMH_PER_MS;
private _route = _logic distance2D _pos;
if (count _ingress >= 2) then {_route = (_logic distance2D _ingress) + (_ingress distance2D _pos)};
private _inboundIn = _route / (_ms max 1);

// THE SERVER'S COPY IS THE ONE THAT COUNTS. FUNC(task) gated on the client's
// replicated status, so two orders inside one network round trip both pass it.
// This runs unscheduled with the status write below, so the second is dropped
// here rather than putting the drone on two runs. The last drone gone: UNABLE
// - NO AIRFRAME (user, 2026-11-02, the respawn count).
([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {
    INFO_2("request dropped for %1 - %2",_callsign,_why);
    [WHY_TASKED, WHY_NO_AIRFRAME] select (_logic getVariable [QGVAR(gone), false])
};

// THE THREAD THIS RUN ANSWERS (2026-11-01), "" for the asset's open one, and
// whether its strike waits for CLEARED HOT - server only, read by the run
// watch and by FUNC(threadReply).
private _threadId = _order getOrDefault ["thread", ""];
_logic setVariable [QGVAR(thread), _threadId];
_logic setVariable [QGVAR(cleared), !(_order getOrDefault ["clear", false])];
// THE RUN'S STATE (step 5, 2026-11-01), server only: what a thread's answers
// move - set when the run starts, read by the run watch every tick, written
// by FUNC(threadReply) and FUNC(threadTimeout).
private _run = createHashMap;
_logic setVariable [QGVAR(run), _run];

// A recall left over from before this run is not a recall of it.
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(status), "inbound", true];
// THE PLAN THE BOARD DRAWS (row field 8): the run as the player set it.
private _plan = [];
if (_ingress isNotEqualTo []) then {_plan pushBack [_ingress, PLAN_IN]};
_plan pushBack [_pos, toUpper _mode];
if (_egress isNotEqualTo []) then {_plan pushBack [_egress, PLAN_OUT]};
_logic setVariable [QGVAR(plan), _plan, true];

private _fromText = ["auto", mapGridPosition _ingress] select (_ingress isNotEqualTo []);
INFO_4("%1 tasked to %2 (%3), ingress %4",_callsign,mapGridPosition _pos,_mode,_fromText);
// WILCO in the asset's thread, if one was filed to it (2026-11-01) - with the
// ETA when the thread asked (FUNC(srvThread)). The run watch moves it on: ON
// TASK at the release or on station, CLOSE when it is over, CANTCO when it
// ended before either.
[format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], "ACCEPTED", _order getOrDefault ["wilco", ""], _callsign, false, _threadId] call EFUNC(support,state);
// To the side by remoteExec, taken only from the server (review S7).
[_logic, _pos, _inboundIn, _mode] remoteExecCall [QFUNC(inbound), _logic getVariable [QGVAR(side), west]];

// The next frame, so the order's own answer (the thread's WILCO, the core's
// reply to the board) is out before the drone is.
[FUNC(launch), [_logic, _pos, _ingress, _egress, _caller, _mag, _mode, _threadId, _run]] call CBA_fnc_execNextFrame;

""
