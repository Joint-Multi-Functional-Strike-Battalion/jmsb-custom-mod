#include "script_component.hpp"
/*
 * Author: JMSB
 * Issues one tasking to an ALiVE combat-support asset, the way ALiVE's own
 * tablet does: the asset's FSM watches a variable on the vehicle, so tasking
 * is one setVariable in the FSM's exact shape.
 *
 * VERIFIED AGAINST THE WORKSHOP BUILD THE GAME LOADS - sup_combatsupport.pbo,
 * unpacked - not against the ALiVE.OS checkout, which is a newer dev tree
 * that has drifted from the release. Both were read; where they differ, the
 * pbo wins, because the pbo is what answers.
 *
 *   CAS:       NEO_radioCasNewTask [task, pos, radius, height, weapon, ROE, player, loiter]
 *   transport: NEO_radioTransportNewTask [task, pos, amnt, player]
 *              (the ARRAY registry keeps ALiVE's missing-n "Trasport"; the
 *              task variable is spelt correctly - both checked in the pbo)
 *   arty:      NEO_radioArtyNewTask [type, ordnance, rate, count, dispersion,
 *              pos, group, magazine, player callsign, player] and the status
 *              flipped to "MISSION" so the row reads busy at once
 *   RTB:       air - task "RTB"; arty - the NEO_radioArtyGoToBase flag
 *
 * EVERY PRESS LANDS IN THE RPT, AND EVERY ACCEPTED ORDER IS RECEIPTED. The
 * FSM nils the task variable the moment it takes the order, so a watcher on
 * that variable IS the delivery receipt - raised back to the app as the
 * support core's ack (EFUNC(support,ack), the jmfsb_support_ack event) with
 * the callsign, or a no-ack warning after 20s. The old QGVAR(supportAck)
 * event still fires beside it for any mission script listening to it.
 * A day of testing produced "nothing happened" with nothing in the log on
 * either side of the handoff; silence was the bug on top of the bug.
 *
 * The request is also read out on the side channel through ALiVE's own
 * NEO_fnc_messageBroadcast, exactly as the tablet's confirm buttons do, so an
 * accepted order is heard in-world and not only in the app.
 *
 * Artillery gets a range pre-check with inRangeOfArtillery - the same call
 * the FSM validates with AFTER consuming the task. ALiVE answers an
 * out-of-range mission with a radio "cannot comply" and nothing else; the
 * app says it up front, with the distance, before the order is sent.
 *
 * Arguments:
 * 0: Asset id from FUNC(supportAssets), "alive:type:index" or "alive:ato"
 *    <STRING>. THE "alive" PROVIDER'S TASK CODE: EFUNC(support,request) gates
 *    and validates, then calls this.
 * 1: Task token <STRING>
 * 2: Position <ARRAY> (optional for AIR - defaults to the caller's own
 *    position, "overhead me". REQUIRED for artillery: a fire mission is
 *    never defaulted onto the caller's own grid.)
 * 3: Parameters [radius, alt, roeIdx (0 RED, 1 GREEN, 2 WHITE, 3 YELLOW,
 *    4 BLUE), speedIdx, ordIdx, countIdx,
 *    dispersion, guns] <ARRAY> - air reads the first four, arty the last
 *    four (guns 0 or absent = the whole battery)
 *
 * Return Value:
 * 0: Accepted <BOOL>
 * 1: Why not, "" when accepted <STRING>
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [500, 150, 0], [[]]]];
_prm params [["_radius", 500], ["_alt", 150], ["_roeIdx", 0]];

INFO_4("supportTask: asset '%1' task '%2' pos %3 prm %4",_assetId,_task,_pos,_prm);

// THE ATO. Not a NEO asset: a CAS request raised on the server, which holds
// ALiVE's event log - see the GVAR(supportRequest) handler in XEH_postInit.
if (_assetId isEqualTo SUPPORT_ATO_ID) exitWith {
    if (_task isEqualTo "rtb") exitWith {[false, "the ATO cannot be recalled"]};
    // No point means "overhead me", as on the NEO air path below: the ATO
    // declares no needsPoint, so the screen offers TARGET as optional and a
    // refusal here would contradict it.
    if (_pos isEqualTo []) then {_pos = getPosATL player};
    _pos set [2, 0];
    [QGVAR(supportRequest), ["cas", side group player, _pos, name player]] call CBA_fnc_serverEvent;
    [true, "CAS requested from the ATO."]
};

if (isNil "NEO_radioLogic") exitWith {
    WARNING("supportTask: refused - NEO_radioLogic is nil, combat support is not running");
    [false, "ALiVE combat support is not running"]
};

(_assetId splitString ":") params ["", ["_type", ""], ["_idxText", "-1"]];
private _idx = parseNumber _idxText;

private _arrName = switch (_type) do {
    case "cas": {"NEO_radioCasArray_%1"};
    case "arty": {"NEO_radioArtyArray_%1"};
    default {"NEO_radioTrasportArray_%1"};
};
private _entry = (NEO_radioLogic getVariable [format [_arrName, side group player], []]) param [_idx, []];
_entry params [["_veh", objNull], ["_grp", grpNull], ["_callsign", ""]];

if (isNull _veh || {!alive _veh}) exitWith {
    WARNING_2("supportTask: refused - entry %1 of %2 is null or dead",_idx,_arrName);
    [false, "that unit is gone"]
};

if (_task isEqualTo "" || {_pos isEqualTo [] && _task isNotEqualTo "rtb" && {isNull player}}) exitWith {
    WARNING("supportTask: refused - no task");
    [false, "no task"]
};

// The callsign the net reads back, through NEO's own fixer when compiled.
private _me = format ["%1", group player];
if (!isNil "NEO_fnc_callsignFix") then {_me = _me call NEO_fnc_callsignFix};

// The side-channel callout ALiVE's own confirm buttons broadcast - the
// in-world half of the feedback, so an accepted order is heard, not only
// flashed. Guarded: no combat support, no radio net.
private _fnc_radio = {
    params ["_text"];
    if (isNil "NEO_fnc_messageBroadcast") exitWith {};
    [[player, _text, "side"], "NEO_fnc_messageBroadcast", true, false] spawn BIS_fnc_MP;
};

// THE DELIVERY RECEIPT. Every FSM nils its task variable the moment it takes
// the order - verified in the pbo for all three NewTask variables and both
// RTB flags - so "went nil" is the acknowledgement, raised to the app as an
// event. The FSMs check every tick when receptive; 20s covers an aircraft
// mid-manoeuvre in one of the few states that do not watch the variable.
private _fnc_watchAck = {
    params ["_obj", "_var", "_assetId", "_said"];
    [
        {isNil {(_this select 0) getVariable (_this select 1)}},
        {
            params ["", "_var", "_assetId", "_said"];
            INFO_2("supportTask: ACK - %1 consumed for %2",_var,_assetId);
            [_assetId, true, _said] call EFUNC(support,ack);
            [QGVAR(supportAck), [_assetId, true, _said]] call CBA_fnc_localEvent;
        },
        [_obj, _var, _assetId, _said],
        20,
        {
            params ["_obj", "_var", "_assetId"];
            WARNING_3("supportTask: NO ACK - %1 still set on %2 after 20s (%3)",_var,_obj,_assetId);
            private _said = "Not acknowledged yet - the unit is mid-task and will take the order when it can";
            [_assetId, false, _said] call EFUNC(support,ack);
            [QGVAR(supportAck), [_assetId, false, _said]] call CBA_fnc_localEvent;
        }
    ] call CBA_fnc_waitUntilAndExecute;
};

if (_task isEqualTo "rtb") exitWith {
    if (_type isEqualTo "arty") exitWith {
        _veh setVariable ["NEO_radioArtyGoToBase", true, true];
        INFO_1("supportTask: sent - arty RTB flag on %1",_veh);
        [format ["%1, return to base. Over.", _callsign]] call _fnc_radio;
        [_veh, "NEO_radioArtyGoToBase", _assetId, format ["%1 acknowledged - returning to base", _callsign]] call _fnc_watchAck;
        [true, ""]
    };

    // The FSMs consume task "RTB" and fly THEMSELVES home - ALiVE's own
    // tablet sends it with whatever position is lying around. The base
    // lookup this used to insist on refused the order whenever the
    // variable was absent, which was always.
    private _here = getPosATL _veh;
    private _watchVar = "";
    if (_type isEqualTo "cas") then {
        _watchVar = "NEO_radioCasNewTask";
        _veh setVariable [_watchVar, ["RTB", _here, 0, 0, "", "RED", player, -1], true];
    } else {
        _watchVar = "NEO_radioTransportNewTask";
        _veh setVariable [_watchVar, ["RTB", _here, 0, player], true];
    };
    INFO_2("supportTask: sent - %1 RTB on %2",_type,_veh);
    [format ["%1, return to base. Over.", _callsign]] call _fnc_radio;
    [_veh, _watchVar, _assetId, format ["%1 acknowledged - RTB", _callsign]] call _fnc_watchAck;
    [true, ""]
};

if (_type isEqualTo "arty") exitWith {
    // A fire mission with no point falls on nobody - never on the caller's
    // own grid. The air default of "overhead me" is a rescue; the same
    // default here is a danger-close accident, so the point is required.
    if (_pos isEqualTo []) exitWith {
        WARNING("supportTask: refused - arty with no task point");
        [false, "artillery needs a map point"]
    };
    _pos set [2, 0];

    private _ordTypes = (_veh getVariable ["NEO_radioArtyBatteryRounds", []]) select {(_x param [1, 0]) >= 1};
    if (_ordTypes isEqualTo []) exitWith {
        WARNING_1("supportTask: refused - %1 has no rounds left",_callsign);
        [false, "the battery has no rounds left"]
    };

    // BY NAME FIRST, INDEX ONLY AS A FALLBACK. The app and this function each
    // build the ordnance list from NEO_radioArtyBatteryRounds and each filter it
    // to types with rounds left - but at DIFFERENT MOMENTS. Fire a mission that
    // empties a type and every index after it shifts, so the number the app
    // stored now points at a different shell than the one it drew. That is a
    // wrong-ordnance bug that only shows up after the first mission, which is
    // exactly when nobody is looking for it.
    //
    // The app writes the name it displayed at index 11 - NOT 10, which is the
    // CAS ordnance index in the same shared parameter set. The index at 4 stays
    // for a
    // stored parameter set written before this, and for the case where the named
    // type has genuinely run dry.
    private _ordIdx = ((_prm param [4, 0]) max 0) min (count _ordTypes - 1);
    private _ordName = _prm param [11, ""];
    if !(_ordName isEqualType "") then { _ordName = "" };

    private _ordnanceType = "";
    if (_ordName isNotEqualTo "") then {
        private _i = _ordTypes findIf { (_x param [0, ""]) isEqualTo _ordName };
        if (_i > -1) then {
            _ordnanceType = _ordName;
        } else {
            WARNING_1("supportTask: '%1' has no rounds left - falling back to the stepper's index",_ordName);
        };
    };
    if (_ordnanceType isEqualTo "") then {
        _ordnanceType = (_ordTypes param [_ordIdx, []]) param [0, ""];
    };
    private _ord = [_veh, _ordnanceType] call ALIVE_fnc_getArtyMagazineType;
    private _count = [1, 3, 6, 12, 24] param [_prm param [5, 1], 3];
    private _dispersion = _prm param [6, 100];

    // The same check the FSM validates with AFTER consuming the task - same
    // units, same magazine, target lifted to ASL the way the FSM lifts it.
    // ALiVE answers an out-of-range mission with a radio "cannot comply" and
    // nothing else; said here instead, with the distance, before it is sent.
    private _asl = [_pos select 0, _pos select 1, getTerrainHeightASL _pos];
    if (!(_asl inRangeOfArtillery [units _grp, _ord])) exitWith {
        private _dist = round (_veh distance2D _pos);
        WARNING_3("supportTask: refused - target %1m out of range for %2 with %3",_dist,_callsign,_ord);
        [false, format ["out of range - the target is %1 m from %2", _dist, _callsign]]
    };

    // HOW MANY TUBES ANSWER. ALiVE's ExecuteMission splits the round count
    // round-robin across the first supportWeaponCount guns, and reads that
    // variable live off the group at fire time - so the app's GUNS stepper
    // is one setVariable on ALiVE's own knob (registration sets it to the
    // full battery). Two ALiVE rules ride along: a 1-round mission is its
    // special case - the lead gun alone fires it whatever this says - and
    // fewer rounds than guns leaves the surplus tubes silent. Mortar
    // PACKING is the only ALiVE path that rewrites the count; a battery
    // that cannot move never packs.
    private _gunsAll = {alive _x} count (_entry param [3, []]);
    private _guns = _prm param [7, 0];
    if (_guns < 1 || _guns > _gunsAll) then {_guns = _gunsAll};
    if (_guns > 0) then {
        _grp setVariable ["supportWeaponCount", _guns, true];
        INFO_2("supportTask: %1 of %2 guns will answer",_guns,_gunsAll);
    };

    // ui/arty/fn_artyConfirmButton, element for element: type is always
    // IMMEDIATE in ALiVE's own UI and rate 0 is RAPID.
    _veh setVariable ["NEO_radioArtyNewTask", ["IMMEDIATE", _ordnanceType, 0, _count, _dispersion, _pos, _grp, _ord, _me, player], true];
    _veh setVariable ["NEO_radioArtyUnitStatus", "MISSION", true];
    // THE RESOLVED MAGAZINE IS LOGGED, not just the ordnance name. The name is
    // what the player picked; _ord is what the guns actually put in the tube,
    // and ALIVE_fnc_getArtyMagazineType picks the FIRST magazine on the vehicle
    // whose config ancestry matches the name - over a list collected across
    // every turret. When a battery reports firing the wrong shell, the only way
    // to tell a bad pick from a bad name is to have both in the log.
    //
    // The split is logged too, because ALiVE divides the count round-robin
    // across supportWeaponCount guns (fn_ExecuteMission.sqf:53-80) - the total
    // is what was asked for, but "12 rounds" arriving as 4+4+4 from three tubes
    // is what the player sees, and it has been read as the wrong count before.
    INFO_4("supportTask: sent - fire mission to %1: %2x %3 at %4",_callsign,_count,_ordnanceType,_pos);
    private _perGun = ceil (_count / (_guns max 1));
    INFO_3("supportTask: %1 resolves to magazine '%2', %3 round(s) per gun",_ordnanceType,_ord,_perGun);
    [format ["%1, %2, fire mission, %3 rounds %4, grid %5, %6 m dispersion. Over.", _callsign, _me, _count, _ordnanceType, mapGridPosition _pos, round _dispersion]] call _fnc_radio;
    // WHAT ACTUALLY LEAVES THE TUBES. Reading the source settles what we SEND
    // and what ALiVE PLANS - the FSM passes the count through uncapped and
    // ExecuteMission splits it round-robin - but not what the guns do with a
    // doArtilleryFire, which is engine and AI behaviour. A mission of 12 across
    // three guns put three rounds on the ground once, and nothing in any log
    // could say whether nine were never fired or never arrived.
    //
    // So the guns are watched. One Fired handler per tube, counting only this
    // magazine, removed on a timer whether or not the battery ever fires - it
    // costs a handler for the length of a fire mission and it turns "only three
    // landed" from a report into a number.
    private _fired = [0];
    private _tubes = (units _grp) select {alive _x && {!isNull objectParent _x}} apply {objectParent _x};
    _tubes = _tubes arrayIntersect _tubes;
    {
        // The counter and the magazine ride on the gun, not in the handler's
        // args: extra-args event handlers expose _thisArgs, which the SQF lint
        // does not accept here, and a getVariable off the firing unit is the
        // same information with nothing exotic in it.
        _x setVariable [QGVAR(artyWatch), [_fired, _ord]];
        private _ehId = _x addEventHandler ["Fired", {
            params ["_unit", "", "", "", "", "_mag"];
            (_unit getVariable [QGVAR(artyWatch), []]) params [["_box", []], ["_want", ""]];
            if (_box isNotEqualTo [] && _mag isEqualTo _want) then {
                _box set [0, (_box select 0) + 1];
            };
        }];
        _x setVariable [QGVAR(artyWatchEh), _ehId];
    } forEach _tubes;

    [{
        params ["_tubes", "_fired", "_count", "_callsign", "_ordnanceType"];
        {
            private _id = _x getVariable [QGVAR(artyWatchEh), -1];
            if (_id > -1) then { _x removeEventHandler ["Fired", _id] };
            _x setVariable [QGVAR(artyWatchEh), nil];
            _x setVariable [QGVAR(artyWatch), nil];
        } forEach _tubes;

        private _out = _fired select 0;
        if (_out isEqualTo _count) then {
            INFO_3("supportTask: %1 fired all %2 %3 round(s)",_callsign,_out,_ordnanceType);
        } else {
            WARNING_4("supportTask: %1 was asked for %2 %3 round(s) and fired %4 - the shortfall is in doArtilleryFire, not in what was sent",_callsign,_count,_ordnanceType,_out);
        };
    }, [_tubes, _fired, _count, _callsign, _ordnanceType], ARTY_WATCH_WINDOW] call CBA_fnc_waitAndExecute;

    [_veh, "NEO_radioArtyNewTask", _assetId, format ["%1 acknowledged - rounds inbound shortly", _callsign]] call _fnc_watchAck;
    [true, ""]
};

if (_pos isEqualTo []) then {_pos = getPosATL player};
_pos set [2, 0];

// ALiVE's ROE tokens are COMBAT MODES - cas.fsm runs `_grp setCombatMode
// _ROE` - so the free/hold choice must arrive as RED/GREEN. "FREE" was an
// invalid enum and the whole tasking died quietly on it.
// FIVE MODES NOW, the five the engine has - the support app lists them all.
// 0 and 1 keep the meaning the old free/hold pair gave them.
private _modes = ["RED", "GREEN", "WHITE", "YELLOW", "BLUE"];
private _roe = _modes param [((round _roeIdx) max 0) min (count _modes - 1), "RED"];

private _watchVar = "";
if (_type isEqualTo "cas") then {
    // ALiVE merged its attack tasks: everything dispatches as "ATTACK
    // GROUND" - the maintained path that handles auto-detection, empty
    // vehicles and manual lasing. Loiter duration -1 = indefinite, and it
    // is what every non-LOITER task carries in ALiVE's own array.
    if (_task isEqualTo "ATTACK RUN") then {_task = "ATTACK GROUND"};
    _watchVar = "NEO_radioCasNewTask";
    _veh setVariable [_watchVar, [_task, _pos, _radius, _alt, "", _roe, player, -1], true];
} else {
    // CIRCLE (and INSERTION) carry their height in the third slot in
    // ALiVE's own confirm; everything else sends 0 there.
    private _amnt = [0, _alt] select (_task in ["CIRCLE", "INSERTION"]);
    _watchVar = "NEO_radioTransportNewTask";
    _veh setVariable [_watchVar, [_task, _pos, _amnt, player], true];

    // Behaviour commands take LOCAL arguments and the airframe is not
    // ours - run them where it lives or they are silent no-ops.
    [_veh, _alt] remoteExec ["flyInHeight", _veh];
    [_veh, ["LIMITED", "NORMAL", "FULL"] select (_prm param [3, 1])] remoteExec ["setSpeedMode", _veh];
    [group _veh, _roe] remoteExec ["setCombatMode", group _veh];
};

INFO_4("supportTask: sent - %1 '%2' to %3 at %4",_type,_task,_callsign,_pos);
[format ["%1, %2, %3 at grid %4. Over.", _callsign, _me, toLower _task, mapGridPosition _pos]] call _fnc_radio;
[_veh, _watchVar, _assetId, format ["%1 acknowledged - wilco", _callsign]] call _fnc_watchAck;

[true, ""]
