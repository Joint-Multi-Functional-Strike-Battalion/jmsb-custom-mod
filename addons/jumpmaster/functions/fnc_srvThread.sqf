#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a JUMP REQUEST filed to the jump aircraft's box - the "thread" code
 * this addon hands the support core (user, 2026-11-02: "also want to change
 * the halo/haho/static app in to a message based one" ... "it also needs a
 * work flow"). The core has asked the issuer's tasking gate and his side
 * already, and answers the ROGER; this asks the jump's own questions:
 *
 *   who        the issuer leads his group, or is an admin - "SQUAD LEADERS
 *              ONLY" (the role words the TO picker goes by are the client's)
 *   aircraft   the asset is there (FUNC(asset): a JMSB - Jump Aircraft
 *              module, or a side's own while it has none) - "NO JUMP
 *              AIRCRAFT"; a module's is ready (2026-11-02: virtual, not
 *              tasked, out of its cooldown) - "UNABLE - NO AIRFRAME" (no
 *              respawn left), "REPLACING IN n S" (after a loss), "RTB",
 *              "TASKED", "COOLDOWN n S"
 *   the card   a TYPE ticked, a RED LIGHT and a GREEN LIGHT at least
 *              JUMP_RUN_MIN apart; PASSES empty - the aircraft's passes by
 *              default; EXIT unticked - its exit by default (the module's,
 *              or the settings' for a side's own)
 *   his squad  no run up for it already - "TASKED"
 *   the stick  the living men of his group within JUMP_PICKUP_RADIUS of the
 *              PICKUP (empty: where he is) - none: "NOBODY AT THE PICKUP"
 *   ready      each with a parachute, and for HALO / HAHO a mask
 *              (FUNC(ready)) - "2 MEN WITHOUT A PARACHUTE - 1 MAN WITHOUT A
 *              MASK"
 *   the class  exists on this server
 *
 * Any of those: [false, why] - the core files the CANTCO. Else the WIND: the
 * lights are shifted upwind by the stick's drift (FUNC(windShift); the app's
 * SHIFT PATH FOR WIND, automatic now), and the WILCO says the type and
 * altitude, the men, passes and exit, RED LIGHT IN m:ss, the shift and who is
 * not at the pickup - one message with the ROGER (the core's RECEIPT_HOLD):
 * "ROGER, WILCO - HALO 6000 M - 8 MEN - 2 PASSES - AUTO EXIT - RED LIGHT IN
 * 1:12 - SHIFTED 240 M FOR WIND", under the aircraft's call sign. The run is
 * booked here - a module's aircraft BUSY - so a second card the same frame is
 * TASKED.
 *
 * A SIDE'S OWN AIRCRAFT launches the next frame, after the WILCO
 * (FUNC(srvLaunch): made at the run-in, the stick put aboard). A MODULE'S IS
 * VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"): the JUMP REQUEST is the task - its aircraft is made now over the
 * module, AIR_ALT m up, and orbits it (FUNC(airUp)); not made - "COULD NOT
 * LAUNCH". Its WILCO says BOARD TO RED LIGHT m:ss, from the module at cruise,
 * and BOARD_PROMPT_DELAY s on it asks ON STATION - SEND BOARD WHEN READY
 * (FUNC(srvAskBoard); user, 2026-11-02: "have team leader send a board message
 * then move the team to cargo"); the run waits in PHASE_BOARD for the
 * leader's BOARD (FUNC(srvBoard)), BOARD_WAIT_MAX s at most.
 *
 * Arguments:
 * 0: Asset id, "jump:<n>" or "jump:<side>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fly <ARRAY>
 *
 * Example:
 * ["jump:west", _thread, _message, _issuer] call jmfsb_jumpmaster_fnc_srvThread
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

private _order = [_thread, _message] call EFUNC(support,readOrder);
if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_JUMP) exitWith {[]};
if (!alive _issuer) exitWith {[false, WHY_LEADERS]};

// SQUAD LEADERS AND ADMINS (user, 2026-10-30: "for squad leaders only").
private _admin = _issuer getVariable [QEGVAR(common,isAdmin), false];
if (!_admin && {leader group _issuer isNotEqualTo _issuer}) exitWith {[false, WHY_LEADERS]};

// THE AIRCRAFT (user, 2026-11-02: "Jump aircraft module").
private _asset = [_assetId] call FUNC(asset);
if ((count _asset) isEqualTo 0) exitWith {[false, WHY_NO_AIRCRAFT]};
if ((_asset get "why") isNotEqualTo "") exitWith {[false, _asset get "why"]};
private _logic = _asset get "logic";
private _callsign = _asset get "callsign";

// THE CARD.
private _type = _order getOrDefault ["type", ""];
if !(_type in TYPES) exitWith {[false, WHY_NO_TYPE]};
private _red = _order getOrDefault ["red", []];
private _green = _order getOrDefault ["green", []];
if (_red isEqualTo []) exitWith {[false, WHY_NO_RED]};
if (_green isEqualTo []) exitWith {[false, WHY_NO_GREEN]};
if ((_red distance2D _green) < JUMP_RUN_MIN) exitWith {[false, WHY_RUN_SHORT]};
private _passes = _order getOrDefault ["passes", -1];
if (_passes < PASSES_MIN) then {_passes = _asset get "passes"};
_passes = (round _passes) max PASSES_MIN min PASSES_MAX;
private _exit = _order getOrDefault ["exit", ""];
if !(_exit in EXITS) then {_exit = _asset get "exit"};

// HIS SQUAD, ONE RUN AT A TIME.
private _group = group _issuer;
if ((GVAR(runs) findIf {(_x get "group") isEqualTo _group}) >= 0) exitWith {[false, WHY_TASKED]};

// THE STICK: his men at the pickup.
private _pickup = _order getOrDefault ["pickup", []];
if (_pickup isEqualTo []) then {
    (getPosATL _issuer) params ["_px", "_py"];
    _pickup = [_px, _py, 0];
};
private _squad = (units _group) select {alive _x};
private _men = _squad select {(_x distance2D _pickup) <= JUMP_PICKUP_RADIUS};
if (_men isEqualTo []) exitWith {[false, WHY_NOBODY]};

// READY: a parachute each, and a mask for HALO / HAHO.
([_men, _type] call FUNC(ready)) params ["_noChute", "_noMask"];
private _whys = [];
if (_noChute > 0) then {_whys pushBack format [WHY_NO_CHUTE, _noChute, [WORD_MAN, WORD_MEN] select (_noChute > 1)]};
if (_noMask > 0) then {_whys pushBack format [WHY_NO_MASK, _noMask, [WORD_MAN, WORD_MEN] select (_noMask > 1)]};
if (_whys isNotEqualTo []) exitWith {[false, _whys joinString WILCO_SEP]};

private _cls = _asset get "cls";
if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {
    WARNING_1("jump aircraft '%1' is not a class on this server",_cls);
    [false, WHY_NO_AIRCRAFT]
};

// THE WIND, and the WILCO.
private _alt = [_type, _asset] call FUNC(typeAlt);
([_type, _red, _green, _alt] call FUNC(windShift)) params ["_redFlown", "_greenFlown", "_shift"];
// A MODULE'S IS MADE NOW, OVER THE MODULE (user, 2026-11-02: virtual until
// tasked): the ETA from the module at cruise, counted from the BOARD; a side's
// own: WHEELS UP at the run-in.
private _module = !isNull _logic;
private _eta = if (_module) then {[_cls, _logic distance2D _redFlown] call FUNC(runEta)} else {[_cls] call FUNC(runEta)};
private _threadId = _thread getOrDefault ["id", ""];
private _words = [
    format [WILCO_TYPE, _type, round _alt],
    format [WILCO_MEN, count _men, [WORD_MAN, WORD_MEN] select (count _men > 1)],
    format [WILCO_PASSES, _passes, ["", "ES"] select (_passes > 1)],
    ((WILCO_EXITS select {(_x select 0) isEqualTo _exit}) param [0, ["", ""]]) select 1,
    [_eta, [ETA_RED, ETA_BOARD] select _module] call EFUNC(support,etaText)
];
if (_shift > 0) then {_words pushBack format [WILCO_WIND, _shift]};
private _left = count _squad - count _men;
if (_left > 0) then {_words pushBack format [WILCO_LEFT, _left]};

private _st = createHashMapFromArray [
    ["assetId", _assetId],
    ["logic", _logic],
    ["callsign", _callsign],
    ["thread", _threadId],
    ["leader", _issuer],
    ["group", _group],
    ["side", _asset get "side"],
    ["cls", _cls],
    ["bay", _asset get "bay"],
    ["flown", false],
    ["type", _type],
    ["red", _redFlown],
    ["green", _greenFlown],
    ["dir", _redFlown getDir _greenFlown],
    ["alt", _alt],
    ["passes", _passes],
    ["exit", _exit],
    ["jumpers", _men],
    ["stick", [_men, _passes] call FUNC(stick)],
    ["veh", objNull],
    // A module's aircraft, made now over the module, flown when the leader
    // sends BOARD (FUNC(srvBoard) counts the stick at the pickup again).
    ["module", _module],
    ["pickup", _pickup],
    ["phase", [PHASE_IN, PHASE_BOARD] select _module],
    ["pass", 0],
    ["lastOut", 0],
    ["go", false],
    ["started", CBA_missionTime]
];
// THE TASK MAKES THE AIRCRAFT (user, 2026-11-02: virtual until tasked): over
// the module, AIR_ALT m up, orbiting it for the BOARD (FUNC(airUp)).
if (_module && {isNull ([_logic] call FUNC(airUp))}) exitWith {[false, WHY_NO_LAUNCH]};
GVAR(runs) pushBack _st;
// A MODULE'S AIRCRAFT FLIES ONE RUN AT A TIME (FUNC(srvRelease) frees it).
if (_module) then {_logic setVariable [QGVAR(busy), true, true]};

[_st, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP] call FUNC(threadState);
INFO_4("srvThread: %1 %2 for %3, %4 men",_callsign,_type,name _issuer,count _men);
// THE DZ IN THE SIDE'S AiTR from the WILCO (user, 2026-11-02): the green light
// the stick lands on, and the release point when the wind moved it - held past
// the thread's close until the stick is down (FUNC(threadState)).
private _zones = [[toLower _type, _green, _callsign]];
if (_shift > 0) then {_zones pushBack [ZONE_RELEASE, _greenFlown, _callsign]};
[_threadId, _zones, side group _issuer] call EFUNC(support,zones);
if (_module) exitWith {
    [{_this call FUNC(srvAskBoard)}, [_st, ""], BOARD_PROMPT_DELAY] call CBA_fnc_waitAndExecute;
    // Never boarded: stood down, the aircraft goes home (FUNC(srvRelease)).
    [{
        params ["_st"];
        if ((GVAR(runs) findIf {(_x get "thread") isEqualTo (_st get "thread")}) < 0) exitWith {};
        if ((_st get "phase") isNotEqualTo PHASE_BOARD) exitWith {};
        [_st] call FUNC(srvAbort);
    }, [_st], BOARD_WAIT_MAX] call CBA_fnc_waitAndExecute;
    [true, ""]
};
[{_this call FUNC(srvLaunch)}, [_st]] call CBA_fnc_execNextFrame;

[true, ""]
