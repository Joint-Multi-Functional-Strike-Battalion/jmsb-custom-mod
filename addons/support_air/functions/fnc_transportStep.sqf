#include "script_component.hpp"
/*
 * Author: YonV
 * One tick of a transport that has reached its point (FUNC(transportArrive)
 * started the phase):
 *
 *   "landing"     coming down - an EXTRACT into its low hover (2026-11-08);
 *                 one that has not settled in LANDING_PATIENCE is ordered
 *                 again
 *   "down"        on the ground - an EXTRACT in its hover, never down.
 *                 PICKUP waits; LAND puts AI passengers out and waits; LAND
 *                 ENG OFF sits shut down; PICKUP > LZ sits shut down too
 *                 (2026-11-08) and EXTRACT hovers: a lift by message holds
 *                 for its ALL IN alone (the reply, or the scroll or ACE
 *                 action aboard - 2026-11-06); a board order waits for the
 *                 requester's group or the wait; then the insertion to the
 *                 LZ (started up by its order) or, the extraction, home
 *   "unload"      home, a class helicopter waiting for its last player to get
 *                 out before it is removed
 *   "ropeIn"      settling into the rope hover; over it, ropes out (a lift
 *                 request's insertion: the cabin empty, or INSERT_ROPE_WAIT,
 *                 and it is gone on its egress - 2026-11-08)
 *   "rappelIn"    settling into the rappel hover; over it, its own ropes out
 *   "rappelling"  a man down each rope in turn every RAPPEL_INTERVAL s; the
 *                 last off his rope, ropes in - the insertion's egress
 *   "roping"      ropes out until the cabin is empty or the wait is up, then
 *                 ropes cut and a hover held
 *   "castIn"      settling over the water; there, AI passengers out and a
 *                 slow drift forward
 *   "casting"     drifting until the cabin is empty or the wait is up, then
 *                 a climb back to the hover
 *   "jumping"     one jumper out per tick on a static line, players as well
 *                 (on their own machines); the stick out, home
 *   "hook"        settling over the load; low and close, it is hooked
 *   "slingCarry"  carrying it to the set-down point, nap of the earth plus
 *                 the rope and the load (EFUNC(support,flightHeight))
 *   "slingLower"  lowering it there; low enough, or out of patience, cut
 *   "hold"        nothing to do until the next order; held nap of the earth
 *
 * AI passengers are put out where a task puts them out; players get out
 * themselves - except on a PARADROP, which is the requester asking for the
 * whole cabin to jump.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 * 2: The watch's state <HASHMAP>
 * 3: The watch's PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st, _handle] call jmfsb_support_air_fnc_transportStep
 *
 * Public: No
 */

// Where a sling helicopter starts coming down, m from the set-down point.
#define CARRY_APPROACH 200
// Clearance over the hook height that counts as low enough to hook or cut.
#define HOOK_SLACK 8

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_handle", -1, [0]]];

private _task = _st getOrDefault ["task", TASK_HOME];
private _target = _st getOrDefault ["target", getPosATL _veh];
private _requester = _st getOrDefault ["requester", objNull];
private _since = _st getOrDefault ["since", CBA_missionTime];

private _cargo = (fullCrew [_veh, "cargo"]) apply {_x select 0};
// A lift request's rope insertion (2026-11-08): out at once when it is done.
private _insertion = count (_logic getVariable [QGVAR(liftJob), createHashMap]) > 0;
private _over = {_veh distance2D _target < HOVER_RING && {speed _veh < HOVER_SPEED}};
private _low = {((getPos _veh) select 2) < _this + HOOK_SLACK};
private _fnc_hold = {
    params ["_line"];
    [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
    [_veh, _target, "LIMITED"] call FUNC(moveTo);
    _st set ["phase", "hold"];
    _logic setVariable [QGVAR(status), "holding", true];
    [_logic, _line, "normal", _requester] call FUNC(say);
};
private _fnc_putOut = {
    {
        if (!isPlayer _x) then {[_x] remoteExecCall [QFUNC(putOut), _x]};
    } forEach _cargo;
};
private _fnc_waitDone = {CBA_missionTime > (_st getOrDefault ["waitUntil", 0])};

switch (_st get "phase") do {
    case "landing": {
        // AN EXTRACTION IS IN ONCE THE FLIGHT CONTROL HOLDS ITS LOW HOVER
        // (2026-11-08, FUNC(transportArrive)); the rest are in on the ground.
        private _hover = _task isEqualTo TASK_EXTRACT;
        private _settled = if (_hover) then {
            ((_veh getVariable [QGVAR(flight), createHashMap]) getOrDefault ["phase", ""]) isEqualTo HELI_PHASE_HOVER
        } else {
            isTouchingGround _veh && {speed _veh < SETTLED_SPEED}
        };
        if (!_settled) exitWith {
            if (CBA_missionTime - _since > LANDING_PATIENCE) then {
                if (_hover) then {
                    [_veh, _target, EXTRACT_HOVER, false, true, HELI_APPROACH_SPEED, "the extraction hover"] call FUNC(heliTake);
                } else {
                    [_veh, _target, _st get "mode", _st getOrDefault ["clearPad", true]] call FUNC(landAt);
                };
                _st set ["since", CBA_missionTime];
            };
        };
        _st set ["phase", "down"];
        _st set ["waitUntil", CBA_missionTime + (_st getOrDefault ["wait", 0])];
        if (_task in [TASK_LAND, TASK_HOME]) then {call _fnc_putOut};
        // THE PASSENGERS ARE THOSE AT THE PICKUP (step 7, 2026-11-01): a lift
        // tasked by message waits for the side's men on foot round it at
        // touchdown, not the requester's group (FUNC(liftGo)) - an extraction
        // too (2026-11-02: everyone in range is loaded, then it lifts).
        if (_task in [TASK_LIFT, TASK_EXTRACT] && {(_st getOrDefault ["opts", createHashMap]) getOrDefault ["paxNear", false]}) then {
            private _side = _logic getVariable [QGVAR(side), west];
            _st set ["pax", (_veh nearEntities ["CAManBase", PICKUP_PAX_RADIUS]) select {alive _x && {(side group _x) isEqualTo _side}}];
        };

        switch (_task) do {
            case TASK_PICKUP: {
                _logic setVariable [QGVAR(status), "waiting", true];
                [_logic, format ["on the ground at %1, waiting", mapGridPosition _veh], "high", _requester] call FUNC(say);
            };
            case TASK_LAND: {
                _logic setVariable [QGVAR(status), "waiting", true];
                [_logic, format ["on the ground at %1, passengers out", mapGridPosition _veh], "high", _requester] call FUNC(say);
            };
            case TASK_LAND_OFF: {
                _veh engineOn false;
                _logic setVariable [QGVAR(status), "shut down", true];
                [_logic, format ["on the ground at %1, shut down", mapGridPosition _veh], "high", _requester] call FUNC(say);
            };
            case TASK_EXTRACT;
            case TASK_LIFT: {
                _logic setVariable [QGVAR(status), "waiting", true];
                private _where = format [["on the ground at %1, shut down", "in a low hover at %1"] select _hover, mapGridPosition _veh];
                private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
                if (count _job > 0) exitWith {
                    private _for = ["ALL IN", "the insertion"] select (_task isEqualTo TASK_LIFT && {(_job getOrDefault ["lz", []]) isEqualTo []});
                    [_logic, format ["%1, holding for %2", _where, _for], "high", _requester] call FUNC(say);
                };
                [_logic, format ["%1, waiting %2 sec for %3", _where, round (_st getOrDefault ["wait", 0]), groupId group _requester], "high", _requester] call FUNC(say);
            };
            default {
                if (!isNull (_logic getVariable [QGVAR(synced), objNull])) exitWith {
                    [_logic, _veh] call FUNC(rearm);
                    [_handle] call CBA_fnc_removePerFrameHandler;
                    [_logic, "down at base", "normal"] call FUNC(say);
                    [_logic] call FUNC(finish);
                };
                _st set ["phase", "unload"];
                _logic setVariable [QGVAR(status), "unloading", true];
                [_logic, "down at base", "normal"] call FUNC(say);
            };
        };
    };
    case "down": {
        if !(_task in [TASK_EXTRACT, TASK_LIFT]) exitWith {};
        // ALL IN AND NOTHING ELSE (user, 2026-11-06: "transport and pick up need
        // to hold the landing till told all in via message or scroll action").
        // A lift by message lifts on its ALL IN - the issuer's `allin` reply,
        // or the scroll or ACE action aboard (FUNC(liftReply), FUNC(srvAllIn))
        // - and only then: not when the men there look aboard, not when the
        // module's wait is up. It sits shut down (a PICKUP > LZ) or held in
        // its low hover by the flight control (an EXTRACT, FUNC(heliFrame))
        // for as long as that takes (2026-11-08); the ALL IN
        // prompt has no timeout. A board order has no job and nobody to say
        // ALL IN: every man there aboard, or the wait up, as before.
        private _liftJob = _logic getVariable [QGVAR(liftJob), createHashMap];
        private _go = if (count _liftJob > 0) then {
            _liftJob getOrDefault ["allIn", false]
        } else {
            private _group = (_st getOrDefault ["pax", units group _requester]) select {alive _x};
            private _aboard = _group isNotEqualTo [] && {_group findIf {vehicle _x isNotEqualTo _veh} < 0};
            _aboard || {call _fnc_waitDone}
        };
        if (!_go) exitWith {};
        private _n = count (_cargo select {alive _x});
        if (_task isEqualTo TASK_EXTRACT) exitWith {
            // Home by the extraction's EGRESS (user, 2026-11-02).
            [_logic, _st, format ["lifting with %1 aboard, returning to base", _n], (_st getOrDefault ["opts", createHashMap]) getOrDefault ["lzVia", []]] call FUNC(transportHome);
        };
        // PICKUP > LZ: the second leg is a LAND on the LZ, flown as an order
        // of its own - same height, speed, door guns, lights, approach - by the
        // flight path a message gave for it (step 7, "lzVia", FUNC(liftGo)): the
        // LIFT REQUEST's ROUTE, the EXTRACTION's EGRESS (2026-11-02).
        // ON ROPES (user, 2026-11-08: the INSERT line): FAST ROPE is ACE's
        // where the airframe takes FRIES, the rappel where it does not; a rope
        // insertion flies the leg at FULL.
        private _insert = _liftJob getOrDefault ["insertTask", TASK_LAND];
        if (_insert isEqualTo TASK_FASTROPE && {!([typeOf _veh] call FUNC(canRope))}) then {_insert = TASK_RAPPEL};
        private _order = +(_logic getVariable [QGVAR(order), []]);
        private _opts = +(_order param [7, createHashMap]);
        // The LZ and route are the job's when it has one: a PICKUP's come with
        // the INSERTION filed after it (2026-11-08, FUNC(liftReply)).
        private _jobLz = _liftJob getOrDefault ["lz", []];
        _opts set ["via", [_opts getOrDefault ["lzVia", []], _liftJob getOrDefault ["lzVia", []]] select (_jobLz isNotEqualTo [])];
        _opts set ["lz", []];
        // The INSERTION's LAND HEADING comes in on the LZ (2026-11-09).
        if (count _liftJob > 0) then {_opts set ["approach", _liftJob getOrDefault ["approach", -1]]};
        _order set [0, _insert];
        _order set [1, [_st getOrDefault ["lz", _target], _jobLz] select (_jobLz isNotEqualTo [])];
        if (_insert isNotEqualTo TASK_LAND) then {_order set [4, (SPEED_WORDS find "FULL") max 0]};
        _order set [7, _opts];
        _logic setVariable [QGVAR(order), _order];
        _logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
        // WAVE OFF is offered aboard from here (2026-11-08, FUNC(canWaveOff)).
        if (count _liftJob > 0) then {
            _veh setVariable [QGVAR(waveOff), [_liftJob getOrDefault ["thread", ""], getPlayerUID (_liftJob getOrDefault ["issuer", objNull])], true];
        };
        [_logic, format ["lifting with %1 aboard for the LZ at %2%3", _n, mapGridPosition (_order select 1),
            ["", [" - fast rope", " - rappel"] select (_insert isEqualTo TASK_RAPPEL)] select (_insert isNotEqualTo TASK_LAND)], "high", _requester] call FUNC(say);
    };
    case "unload": {
        if ((crew _veh) findIf {isPlayer _x} > -1) exitWith {};
        // A player's AI squadmate is put out on his client - ask again and wait
        // for him to be out rather than sweep him with the airframe.
        private _theirs = _cargo select {alive _x && {isPlayer leader group _x}};
        if (_theirs isNotEqualTo []) exitWith {
            {[_x] remoteExecCall [QFUNC(putOut), _x]} forEach _theirs;
        };
        [_handle] call CBA_fnc_removePerFrameHandler;
        [_veh] call FUNC(sweep);
        [_logic] call FUNC(finish);
    };
    case "ropeIn": {
        if (!(call _over) && {CBA_missionTime - _since < LANDING_PATIENCE}) exitWith {};
        [_veh, false, false] call ace_fastroping_fnc_deployAI;
        _st set ["phase", "roping"];
        _st set ["waitUntil", CBA_missionTime + ([_st getOrDefault ["wait", 0], (_st getOrDefault ["wait", 0]) min INSERT_ROPE_WAIT] select _insertion)];
        [_logic, format ["ropes out over %1%2", mapGridPosition _veh, ["", " - fast rope now"] select _insertion], "high", _requester] call FUNC(say);
    };
    case "roping": {
        if (_cargo isNotEqualTo [] && {!(call _fnc_waitDone)}) exitWith {};
        if ((_veh getVariable ["ace_fastroping_deployedRopes", []]) isNotEqualTo []) then {
            [_veh] call ace_fastroping_fnc_cutRopes;
        };
        // A LIFT REQUEST'S INSERTION LEAVES AT ONCE (user, 2026-11-08), on its
        // EGRESS (FUNC(liftEnd)).
        if (_insertion) exitWith {[_logic, SAID_EGRESS] call FUNC(liftEnd)};
        ["ropes cut, holding a hover"] call _fnc_hold;
    };
    case "rappelIn": {
        if (!(call _over) && {CBA_missionTime - _since < LANDING_PATIENCE}) exitWith {};
        [_veh, true] call FUNC(rappelRopes);
        _st set ["phase", "rappelling"];
        _st set ["out", []];
        _st set ["nextOut", 0];
        _st set ["waitUntil", CBA_missionTime + ([_st getOrDefault ["wait", 0], (_st getOrDefault ["wait", 0]) min INSERT_ROPE_WAIT] select _insertion)];
        [_logic, format ["ropes out over %1 - rappel", mapGridPosition _veh], "high", _requester] call FUNC(say);
    };
    // A MAN DOWN EACH ROPE IN TURN, everyone in the cabin - the requester asked
    // for it, as for a paradrop - on his own machine (FUNC(rappel)); the ropes
    // come in once the last one out is off his rope.
    case "rappelling": {
        private _out = _st getOrDefault ["out", []];
        private _left = _cargo select {alive _x && {!(_x getVariable [QGVAR(rappelled), false])}};
        if (_left isNotEqualTo [] && {!(call _fnc_waitDone)}) exitWith {
            if (CBA_missionTime < (_st getOrDefault ["nextOut", 0])) exitWith {};
            private _man = _left select 0;
            _man setVariable [QGVAR(rappelled), true];
            [_man, _veh, count _out mod 2] remoteExecCall [QFUNC(rappel), _man];
            _out pushBack [_man, CBA_missionTime];
            _st set ["nextOut", CBA_missionTime + RAPPEL_INTERVAL];
        };
        private _sliding = _out select {
            _x params ["_man", "_at"];
            alive _man && {vehicle _man isEqualTo _man} && {((getPos _man) select 2) > RAPPEL_FOOT} && {CBA_missionTime - _at < RAPPEL_MAX_S}
        };
        if (_sliding isNotEqualTo []) exitWith {};
        [_veh, false] call FUNC(rappelRopes);
        {(_x select 0) setVariable [QGVAR(rappelled), nil]} forEach _out;
        if (_insertion) exitWith {[_logic, SAID_EGRESS] call FUNC(liftEnd)};
        ["ropes in, holding a hover"] call _fnc_hold;
    };
    case "castIn": {
        if (!(call _over) && {CBA_missionTime - _since < LANDING_PATIENCE}) exitWith {};
        call _fnc_putOut;
        private _drift = HELOCAST_SPEED / KMH_PER_MS * ((_st getOrDefault ["wait", 0]) max 1);
        // The drift is the flight control's too (2026-11-05): HELOCAST_HEIGHT
        // over the water at HELOCAST_SPEED to the point, then held there.
        [_veh, _target getPos [_drift, getDir _veh], HELOCAST_HEIGHT, false, true, HELOCAST_SPEED / KMH_PER_MS, "the cast drift"] call FUNC(heliTake);
        _st set ["phase", "casting"];
        _st set ["waitUntil", CBA_missionTime + (_st getOrDefault ["wait", 0])];
        [_logic, format ["on the water at %1 - go", mapGridPosition _veh], "high", _requester] call FUNC(say);
    };
    case "casting": {
        if (_cargo isNotEqualTo [] && {!(call _fnc_waitDone)}) exitWith {};
        _target = getPosATL _veh;
        _st set ["target", _target];
        ["cabin is out, climbing to a hover"] call _fnc_hold;
    };
    case "jumping": {
        // Marked here, on the server: the jump happens on the jumper's own
        // machine and he may still read as aboard on the next tick.
        private _next = _cargo param [_cargo findIf {alive _x && {!(_x getVariable [QGVAR(jumped), false])}}, objNull];
        if (!isNull _next) exitWith {
            _next setVariable [QGVAR(jumped), true];
            [_next, _veh] remoteExecCall [QFUNC(jump), _next];
        };
        [_logic, _st, "stick is out, returning to base"] call FUNC(transportHome);
    };
    case "hook": {
        private _load = _st getOrDefault ["load", objNull];
        if (!alive _load) exitWith {["the load is gone - holding"] call _fnc_hold};
        if (!(call _over && {SLING_HOOK_HEIGHT call _low}) && {CBA_missionTime - _since < SLING_PATIENCE}) exitWith {};
        if !(_veh setSlingLoad _load) exitWith {["cannot lift it - holding"] call _fnc_hold};
        // Nap of the earth with the load under it: the support core adds the
        // rope and the load to the height (user, 2026-11-01).
        [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
        _target = _st getOrDefault ["lz", _target];
        _st set ["target", _target];
        [_veh, _target, _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
        _st set ["phase", "slingCarry"];
        _logic setVariable [QGVAR(status), "carrying", true];
        [_logic, format ["load hooked, carrying it to %1", mapGridPosition _target], "normal", _requester] call FUNC(say);
    };
    case "slingCarry": {
        if (isNull getSlingLoad _veh) exitWith {["has lost the load - holding"] call _fnc_hold};
        if (_veh distance2D _target > CARRY_APPROACH) exitWith {
            // Asked again each tick: the ropes are read once they are out.
            [_veh, FLY_TRANSIT] call EFUNC(support,flyAt);
        };
        [_veh, SLING_SET_DOWN] call EFUNC(support,flyAt);
        [_veh, _target, "LIMITED"] call FUNC(moveTo);
        _st set ["phase", "slingLower"];
        _st set ["since", CBA_missionTime];
        _logic setVariable [QGVAR(status), "setting down", true];
    };
    case "slingLower": {
        if (!(_veh distance2D _target < SLING_RING && {SLING_SET_DOWN call _low}) && {CBA_missionTime - _since < SLING_PATIENCE}) exitWith {};
        _veh setSlingLoad objNull;
        [format ["load set down at %1, holding", mapGridPosition _veh]] call _fnc_hold;
    };
};
