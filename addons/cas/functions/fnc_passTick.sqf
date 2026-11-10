#include "script_component.hpp"
/*
 * Author: YonV
 * One tick of a pass (FUNC(passBegin)) from its owner's watch, every second
 * or so: the line-up, the commit to the dive, and the word when it is over.
 *
 *   PASS_LINE   the AI flies it (the owner's order, FUNC(passBegin)): to the
 *               aim while it is on the ingress bearing, else to the prep
 *               point out on that bearing; ordered again when it is idle or
 *               the point moved. On the line inside the line-up distance its
 *               speed is capped at the run speed. The grid is looked at for
 *               a laser or smoke while that is all it has (FUNC(acquire)),
 *               never one with the side's own men inside the friendly range
 *               unless danger close was acknowledged. Inside the commit
 *               distance, on the line, nosed in and fast enough - or late
 *               and anywhere inside the line-up distance - the dive takes
 *               over (FUNC(passFrame)); late and further out, missed
 *   PASS_DIVE   flown each frame; here only its patience
 *   PASS_DONE   over: the result is handed back once and the pass forgotten
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * "line" or "dive" while it flies; then once "fired", "missed" (never lined up), "aborted" (broken off before a release), "dry" (the store would not fire) or "lost" (the airframe); "none" with no pass <STRING>
 *
 * Example:
 * [_veh] call jmfsb_cas_fnc_passTick
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];

private _st = _veh getVariable [QGVAR(pass), createHashMap];
if (count _st isEqualTo 0) exitWith {PASS_NONE};

// Over: the result once, then forgotten.
private _fnc_result = {
    private _result = _st getOrDefault ["result", PASS_LOST];
    _veh setVariable [QGVAR(pass), nil];
    _result
};
if ((_st get "phase") isEqualTo PASS_DONE) exitWith {call _fnc_result};
if (!alive _veh || !local _veh || !canMove _veh || isNull driver _veh) exitWith {
    [_veh, "the airframe is lost"] call FUNC(passEnd);
    call _fnc_result
};

if ((_st get "phase") isEqualTo PASS_DIVE) exitWith {
    if (CBA_missionTime - (_st get "diveAt") > PASS_DIVE_MAX_S) exitWith {
        [_veh, "out of time in the dive"] call FUNC(passEnd);
        call _fnc_result
    };
    PASS_DIVE
};

// THE LINE-UP.
private _dummy = _st get "dummy";
private _aim = if (alive _dummy) then {ASLToAGL getPosASL _dummy} else {_st get "aim"};
private _inDir = _st get "inDir";
private _d = _veh distance2D _aim;
private _fnc_turn = {
    params ["_from", "_to"];
    abs ((_to - _from + PASS_HALF_TURN + PASS_FULL_TURN) mod PASS_FULL_TURN - PASS_HALF_TURN)
};
private _onLine = ([_inDir, _aim getDir _veh] call _fnc_turn) < PASS_LINE_TOL;
private _nosed = ([getDir _veh, _veh getDir _aim] call _fnc_turn) < PASS_NOSE_TOL;
private _fast = (speed _veh) / KMH_PER_MS >= (_st get "minSpeed");
private _late = CBA_missionTime - (_st get "began") > PASS_LINE_MAX_S;
private _lineUp = _st get "lineUp";

// THE COMMIT.
if ((_d <= (_st get "commit") && _d >= (_st get "nearest") && _onLine && _nosed && _fast) || (_late && _d <= _lineUp && _nosed && _fast)) exitWith {
    private _dir = vectorDir _veh;
    private _heading = getDir _veh;
    private _right = [cos _heading, -(sin _heading), 0];
    {_st set _x} forEach [
        ["phase", PASS_DIVE],
        ["diveAt", CBA_missionTime],
        ["heading", _heading],
        ["pitch", asin ((_dir select 2) max -1 min 1)],
        ["bank", asin (((vectorUp _veh) vectorDotProduct _right) max -1 min 1)],
        ["speed", (speed _veh) / KMH_PER_MS],
        ["solution", 0],
        ["solvedAt", -1],
        ["alignedAt", -1],
        ["ready", false],
        ["burstAt", -1],
        ["nextPull", 0],
        ["lastPull", -1],
        ["checked", false]
    ];
    // The owner drops any order of its own: the dive has the airframe.
    [_veh, []] call (_st get "order");
    _veh limitSpeed PASS_NO_SPEED_CAP;
    private _turret = _st get "turret";
    if (_turret isNotEqualTo TURRET_PILOT) then {_veh lockCameraTo [_dummy, _turret, false]};
    {_veh animateBay [_forEachIndex + 1, 1, false]} forEach (getPylonMagazines _veh);
    _st set ["pfh", [FUNC(passFrame), 0, [_veh]] call CBA_fnc_addPerFrameHandler];
    private _lateText = ["", " - late, from where it is"] select _late;
    INFO_6("pass: '%1' commits %2 m out, %3 m up, %4 km/h%5 - %6",typeOf _veh,round _d,round ((getPosATL _veh) select 2),round speed _veh,_lateText,mapGridPosition _aim);
    PASS_DIVE
};
if (_late) exitWith {
    [_veh, "never lined up"] call FUNC(passEnd);
    call _fnc_result
};

// A LASER OR SMOKE ON THE WAY IN, while the grid is all it has.
private _search = _st get "search";
if ((_st get "by") isEqualTo "grid" && count _search >= 3 && CBA_missionTime >= (_st get "nextLook")) then {
    _st set ["nextLook", CBA_missionTime + PASS_LOOK_EVERY];
    _search params ["_grid", "_radius", "_side", ["_friendly", 0, [0]], ["_danger", false, [false]]];
    ([_grid, _radius, _side] call FUNC(acquire)) params ["_found", "_by", "_track"];
    private _safe = _by isNotEqualTo "grid";
    if (_safe && !_danger && _friendly > 0) then {
        _safe = ((_found nearEntities [["CAManBase", "LandVehicle", "Ship", "StaticWeapon"], _friendly]) findIf {alive _x && (side group _x) isEqualTo _side}) < 0;
    };
    if (_safe) then {
        if (isNull _track) then {
            detach _dummy;
            _dummy setPosATL (_found vectorAdd [0, 0, CAS_DUMMY_UP]);
        } else {
            _dummy attachTo [_track, [0, 0, CAS_DUMMY_UP]];
        };
        {_st set _x} forEach [["aim", [_found select 0, _found select 1, 0]], ["aimASL", ATLToASL _found], ["by", _by], ["track", _track]];
        INFO_3("pass: '%1' takes the %2 at %3 on the way in",typeOf _veh,_by,mapGridPosition _found);
    };
};

// THE SPEED CAP, once on the line inside the line-up distance.
if (_onLine && _d <= _lineUp && !(_st get "capped")) then {
    _st set ["capped", true];
    _veh limitSpeed ((_st get "runSpeed") * KMH_PER_MS);
};

// THE ORDER: the aim from the line, the prep point from anywhere else.
private _want = [_aim getPos [_lineUp * PASS_LINE_OUT, _inDir], _aim] select _onLine;
private _ordered = _st get "ordered";
private _moved = (_st get "orderTo") isEqualTo [] || {_want distance2D (_st get "orderTo") > PASS_ORDER_MOVED};
if (_ordered < 0 || {CBA_missionTime - _ordered >= PASS_ORDER_EVERY && (_moved || unitReady _veh)}) then {
    [_veh, _want] call (_st get "order");
    _st set ["ordered", CBA_missionTime];
    _st set ["orderTo", _want];
    if (CBA_missionTime - (_st get "orderLogged") >= PASS_ORDER_LOG_S) then {
        _st set ["orderLogged", CBA_missionTime];
        private _where = ["the prep point", "the aim"] select _onLine;
        private _line = ["off", "on"] select _onLine;
        private _off = round ([getDir _veh, _veh getDir _aim] call _fnc_turn);
        INFO_6("pass: '%1' lining up - sent to %2 (%3), %4 m from the aim, %5 the line, %6 deg off the nose",typeOf _veh,mapGridPosition _want,_where,round _d,_line,_off);
    };
};

PASS_LINE
