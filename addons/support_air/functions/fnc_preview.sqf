#include "script_component.hpp"
/*
 * Author: YonV
 * The verdict before CONFIRM - the "preview" code of provider "air" (support
 * core README), the line Simplex shows beside its confirm. Asked on every
 * redraw of the board with exactly the parameters CONFIRM would send, so it
 * reads only what the server published on the module, changes nothing and
 * walks nothing bigger than the route.
 *
 *   CAS        "ETA 3 MIN - ON STATION 10 MIN - 2 SPARE AIRFRAMES"
 *              on station, a SAD or LOITER: "REPOSITION - ETA 40 S"
 *   TRANSPORT  "ETA 2 MIN 40 S TO PICKUP" - from where it is when it is out
 *   QRF       "ETA 5 MIN - LAST AIRFRAME"
 * (the respawn count, user 2026-11-02)
 *
 * THE ETA IS AN ESTIMATE: no delay - a class airframe is made over the module
 * when it is tasked (user, 2026-11-02: virtual until tasked), a synced one
 * takes off at once - then the route the order will fly from the module, the
 * stand or where it is - the CAS ingress, the VIA legs and the final
 * approach - at the SPEED asked (FUNC(flightTime)).
 *
 * FALSE ONLY FOR WHAT THE ORDER WOULD BE REFUSED FOR (FUNC(task) on this
 * machine, the order functions on the server): the asset gone, busy,
 * launching, turning round, replacing its aircraft or spent
 * (FUNC(available)); a task this asset does not fly; no grid where "on me"
 * does not apply; PICKUP > LZ or SLINGLOAD without its second point; a
 * HELOCAST over land; an ATTACK RUN on an aircraft out on a task and not on
 * station. A
 * SLINGLOAD with nothing liftable round the load is flown and then held
 * there, not refused, so it is a true verdict that says so.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Task token <STRING>
 * 2: Target position, [] for none <ARRAY>
 * 3: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * 0: The order would be accepted <BOOL>
 * 1: The verdict line <STRING>
 *
 * Example:
 * ["air:0", "PICKUP", [1000, 2000, 0], []] call jmfsb_support_air_fnc_preview
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "THAT ASSET IS GONE"]};

([_logic] call FUNC(available)) params ["_ok", "_status", "_why"];
if (!_ok) exitWith {[false, toUpper _why]};

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _kind = _logic getVariable [QGVAR(kind), ""];
private _cls = _logic getVariable [QGVAR(cls), ""];

// The task as this provider declares it, and whether THIS asset offers it -
// the rule FUNC(tasks) narrows the screen by.
private _decls = ((SUPPORT_TYPES select {(_x select 0) isEqualTo _kind}) param [0, []]) param [5, []];
private _decl = (_decls select {(_x select 0) isEqualTo _task}) param [0, []];
if (_decl isEqualTo [] || (_kind in [KIND_TRANSPORT, KIND_QRF] && !(_task in (_logic getVariable [QGVAR(allowed), []])))) exitWith {
    [false, format ["%1 DOES NOT FLY %2", _callsign, _task]]
};

// NO GRID IS "ON ME" only where FUNC(task) makes it so.
private _onMe = _pos isEqualTo [] && _task in [TASK_PICKUP, TASK_EXTRACT, TASK_LIFT];
if (_onMe) then {_pos = getPosATL player};
if (_pos isEqualTo []) exitWith {[false, "NO TARGET GRID"]};
_pos = [_pos select 0, _pos select 1, 0];

if (_task in [TASK_LIFT, TASK_SLING] && {([_prm, SLOT_LZ] call FUNC(readPoint)) isEqualTo []}) exitWith {
    [false, format ["%1 NEEDS %2", _task, ["AN LZ", "A SET-DOWN POINT"] select (_task isEqualTo TASK_SLING)]]
};
if (_task isEqualTo TASK_HELOCAST && !surfaceIsWater _pos) exitWith {
    [false, format ["HELOCAST NEEDS WATER - %1 IS LAND", mapGridPosition _pos]]
};

// WHERE IT FLIES FROM. Out on a sortie, it goes from where it is, now;
// otherwise from its base, at once (user, 2026-11-02: virtual until tasked - a
// class airframe is made over the module when it is tasked).
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _out = _status isNotEqualTo STATUS_IDLE && alive _veh;
private _from = [_home, getPosATL _veh] select _out;

// " - 2 SPARE AIRFRAMES", " - LAST AIRFRAME" - the respawn count (user,
// 2026-11-02: "make sure there is a respawn count for each support, default
// no respawns").
private _fnc_left = {
    private _left = _logic getVariable [QGVAR(respawnsLeft), 0];
    [format [" - %1 SPARE AIRFRAMES", _left], " - 1 SPARE AIRFRAME", " - LAST AIRFRAME"] select (2 - (_left min 2))
};
private _fnc_eta = {
    params ["_route", "_speed"];
    [[_cls, _route, _speed] call FUNC(flightTime)] call EFUNC(cas,fmtEta)
};

switch (_kind) do {
    case KIND_CAS: {
        // ON STATION a SAD or a LOITER moves it, and an ATTACK RUN is flown
        // from there (FUNC(casOrder), user 2026-11-02); out on anything else it
        // takes no run.
        if (_out && _status isNotEqualTo STATUS_ON_STATION && _task isEqualTo TASK_RUN) exitWith {[false, "ON A TASK - RTB FIRST FOR A RUN"]};

        private _speed = [SPEED_NORMAL, SPEED_FULL] select (_task isEqualTo TASK_RUN);
        private _route = [_from, _pos];
        if (!_out) then {
            // FUNC(casLaunch): from its stand or over the module, to the
            // run-in point first, at full speed, when an INGRESS is set.
            private _ingress = [_prm, SLOT_INGRESS] call FUNC(readPoint);
            if (_ingress isEqualTo []) exitWith {};
            _route = [_home, _pos getPos [_logic getVariable [QGVAR(runIn), 3000], _pos getDir _ingress], _pos];
            _speed = SPEED_FULL;
        };

        private _line = format [["ETA %1", "REPOSITION - ETA %1"] select _out, [_route, _speed] call _fnc_eta];
        if (!_out && _task in [TASK_SAD, TASK_LOITER]) then {
            _line = _line + format [" - ON STATION %1", [_logic getVariable [QGVAR(stationTime), 600]] call EFUNC(cas,fmtEta)];
        };
        // DANGER CLOSE is declared only while the module holds releases near
        // friendlies at all (FUNC(tasks)).
        if (_task in [TASK_RUN, TASK_SAD] && (_logic getVariable [QGVAR(friendlyRange), 0]) > 0 && {([_prm, SLOT_DANGER, 0, 1] call FUNC(readParam)) isEqualTo 1}) then {
            _line = _line + " - DANGER CLOSE";
        };
        _line = _line + (call _fnc_left);
        [true, _line]
    };
    case KIND_TRANSPORT: {
        // The route FUNC(transportPlan) flies: the VIA legs, then the final
        // approach leg when the task takes one and it is set.
        private _route = [_from] + ([_prm, SLOT_VIA, true] call FUNC(readPoint));
        if (((_decl param [4, []]) findIf {(_x param [1, -1]) isEqualTo SLOT_APPROACH}) > -1) then {
            private _approach = [_prm, SLOT_APPROACH, 0, count APPROACH_WORDS - 1] call FUNC(readParam);
            if (_approach > 0) then {_route pushBack (_pos getPos [APPROACH_LEG, (_approach - 1) * APPROACH_STEP])};
        };
        _route pushBack _pos;
        private _speed = if (((_decl param [4, []]) findIf {(_x param [1, -1]) isEqualTo SLOT_SPEED}) > -1) then {
            [_prm, SLOT_SPEED, 0, count SPEED_WORDS - 1] call FUNC(readParam)
        } else {SPEED_NORMAL};

        private _where = _decl param [6, ""];
        if (_where isEqualTo "") then {_where = "TARGET"};
        private _line = format ["ETA %1 TO %2%3", [_route, _speed] call _fnc_eta, _where, ["", " ON YOU"] select _onMe];

        // Nothing it can lift there: flown, then held over the load
        // (FUNC(transportArrive)). Only an airframe on the map can be asked.
        if (_task isEqualTo TASK_SLING && alive _veh) then {
            private _loads = nearestObjects [_pos, SLING_LOAD_KINDS, SLING_SEARCH];
            if ((_loads findIf {_x isNotEqualTo _veh && alive _x && !(_x isKindOf "CAManBase") && {_veh canSlingLoad _x}}) < 0) then {
                _line = _line + format [" - NOTHING LIFTABLE WITHIN %1 M", SLING_SEARCH];
            };
        };
        [true, _line]
    };
    case KIND_QRF: {
        [true, format ["ETA %1%2", [[_from, _pos], SPEED_NORMAL] call _fnc_eta, call _fnc_left]]
    };
    default {[false, "UNKNOWN ASSET TYPE"]};
}
