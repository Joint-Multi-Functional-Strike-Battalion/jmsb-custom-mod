#include "script_component.hpp"
/*
 * Author: JMSB
 * The verdict before CONFIRM - the "preview" code of provider "fires", the
 * way Simplex shows its ETA and a red or green verdict beside its confirm.
 * Asked on every redraw with exactly the parameters CONFIRM would send, so it
 * reads published variables only, changes nothing and loops over nothing
 * bigger than an asset's own stock.
 *
 * FALSE ONLY FOR WHAT THE ORDER WOULD BE REFUSED FOR: busy or cooling down,
 * nothing left, out of range. Fewer rounds left than asked is a true verdict
 * that says so - the battery fires what it has.
 *
 *   artillery  "ETA 70 S - 4 GUNS x 3 HE"  (+ volleys, + nearby batteries)
 *   cruise     "TIME TO TARGET 95 S - 2 MISSILES"
 *   loitering  "ON STATION IN 120 S - 2 MUNITIONS"
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: Task token <STRING>
 * 2: Target position <ARRAY>
 * 3: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * 0: The order would be accepted <BOOL>
 * 1: The verdict line <STRING>
 *
 * Example:
 * ["fires:0", "FFE", [1000, 2000, 0], []] call jmfsb_support_fires_fnc_preview
 *
 * Public: No
 */

params [["_assetId", "", [""]], "", ["_pos", [], [[]]], ["_prm", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "THAT ASSET IS GONE"]};

([_logic] call FUNC(available)) params ["_ok", "", "_why"];
if (!_ok) exitWith {[false, toUpper _why]};
if (_pos isEqualTo []) exitWith {[false, "NO TARGET POINT"]};

private _opts = [_logic, _prm] call FUNC(readOpts);
if (_opts isEqualTo []) exitWith {[false, "NOTHING LEFT TO FIRE"]};

private _dist = (_logic getVariable [QGVAR(origin), getPosATL _logic]) distance2D _pos;
([_logic] call FUNC(gunRanges)) params ["_min", "_max"];
if (_dist > _max) exitWith {[false, format ["OUT OF RANGE - %1, MAX %2", toUpper ([_dist] call FUNC(fmtDist)), toUpper ([_max] call FUNC(fmtDist))]]};
if (_dist < _min) exitWith {[false, format ["TOO CLOSE - %1, MIN %2", toUpper ([_dist] call FUNC(fmtDist)), toUpper ([_min] call FUNC(fmtDist))]]};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0], ["_respMax", 0]];
private _fmtEta = {
    params ["_t"];
    if (round (_t + _respMax - _respMin) > round _t) exitWith {format ["%1-%2 S", round (_t + _respMin), round (_t + _respMax)]};
    format ["%1 S", round (_t + _respMin)]
};

switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {
        _opts params ["_kind", "_rounds", "", "_want", "_name", "", "_delay", "", "_repeat", "_coord"];
        private _ball = [_dist, _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV], _logic getVariable [QGVAR(highAngle), true]] call FUNC(ballistics);
        private _tof = (_ball param [1, 0]) max VA_DESCENT_TIME;

        private _stock = _logic getVariable [QGVAR(stock), []];
        private _index = _stock findIf {(_x select 3) isEqualTo _kind};
        private _left = if (_index < 0) then {0} else {(_stock select _index) select 1};
        private _guns = _logic getVariable [QGVAR(gunCount), 1];
        if (_want > 0) then {_guns = _want min _guns};
        private _asked = _guns * _rounds * (1 + _repeat);

        [[false, "NO FIRING SOLUTION"], [true, format [
            "ETA %1 - %2 GUNS x %3 %4%5%6%7",
            [_delay + _tof] call _fmtEta,
            _guns, _rounds, _name,
            ["", format [" x %1 VOLLEYS", 1 + _repeat]] select (_repeat > 0),
            ["", " + NEARBY"] select (_coord > 0),
            ["", format [" - ONLY %1 LEFT", _left]] select (_left >= 0 && _left < _asked)
        ]]] select (_ball isNotEqualTo [])
    };
    case TYPE_CRUISE: {
        _opts params ["_count", "_delay"];
        private _tof = CM_BOOST_TIME + _dist / (_logic getVariable [QGVAR(speed), 1]);
        [true, format ["TIME TO TARGET %1 - %2 MISSILE%3", [_delay + _tof] call _fmtEta, _count, ["", "S"] select (_count > 1)]]
    };
    case TYPE_LOITER: {
        _opts params ["_count", "_radius"];
        private _reach = _logic getVariable [QGVAR(reach), 0];
        private _line = format ["%1 MUNITION%2, SEARCH %3 M", _count, ["", "S"] select (_count > 1), _radius];
        if (_reach > 0 && _reach < 1e7) then {
            _line = format ["ON STATION IN %1 S - %2", round (_dist / (_reach / LM_TRANSIT_MAX)), _line];
        };
        [true, _line]
    };
    default {[false, "UNKNOWN ASSET TYPE"]};
}
