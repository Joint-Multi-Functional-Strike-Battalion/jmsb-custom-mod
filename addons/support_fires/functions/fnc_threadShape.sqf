#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a call for fire's TARGET SHAPE as the battery's sheaf (user,
 * 2026-11-02) - FUNC(srvThread)'s. The card's Shape and End lines, as the
 * support core reads them (EFUNC(support,readOrder): shape, size, end,
 * attitude), against what the module offers (its Sheaf Types) and its Max
 * Sheaf Length (QGVAR(sheafMax)), which caps every size:
 *
 *   POINT, none   every round on the point - no sheaf, as before
 *   AREA          CONVERGED round the point (BOX when only that is offered),
 *                 the size its radius; none: SHAPE_AREA_DEF m
 *   LINEAR        the guns along a line (PARALLEL offered): the point to the
 *                 far end (End.A), the mission aimed at its middle; or the
 *                 size long (none: SHAPE_LENGTH_DEF m) at the attitude (End.B,
 *                 deg), the point its middle - no attitude: square to the
 *                 line of fire
 *   CREEPING      the barrage walks from the point to the far end, or the size
 *                 along the attitude - none: away from the guns (CREEPING
 *                 offered); the guns side by side CREEP_LANE m apart
 *
 * Not offered: WHY_NO_SHEAF. The points it returns are those the battery must
 * reach and keep clear of friendlies - the point, and a line's or a walk's
 * ends.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The order, EFUNC(support,readOrder)'s <HASHMAP>
 * 2: Guns firing <NUMBER>
 *
 * Return Value:
 * 0: Why not, "" when it can <STRING>
 * 1: The mission's point, ATL <ARRAY>
 * 2: Sheaf type, SHEAF_* <NUMBER>
 * 3: Sheaf (m) - a radius, half a line, half the guns' width on a walk <NUMBER>
 * 4: Attitude (deg), -1 none <NUMBER>
 * 5: Length of a line or a walk (m), 0 none <NUMBER>
 * 6: WILCO's words, "" for a point <STRING>
 * 7: The points to check <ARRAY>
 *
 * Example:
 * [_logic, _order, 4] call jmfsb_support_fires_fnc_threadShape
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_order", createHashMap, [createHashMap]], ["_guns", 1, [0]]];

private _target = _order getOrDefault ["target", []];
private _shape = _order getOrDefault ["shape", ""];
private _size = _order getOrDefault ["size", -1];
private _end = _order getOrDefault ["end", []];
private _attitude = _order getOrDefault ["attitude", -1];
private _sheafs = _logic getVariable [QGVAR(sheafs), [SHEAF_CONVERGED]];
private _max = _logic getVariable [QGVAR(sheafMax), SHEAF_MAX];
private _fire = (_logic getVariable [QGVAR(origin), getPosATL _logic]) getDir _target;
private _fnc_bearing = {
    params ["_deg"];
    [round (_deg mod DEG_FULL), DEG_FIGURES] call CBA_fnc_formatNumber
};
private _fnc_ground = {
    params ["_pos"];
    _pos params ["_px", "_py"];
    [_px, _py, 0]
};

// What the module must offer for the shape.
private _need = switch (_shape) do {
    case SHAPE_AREA: {[SHEAF_CONVERGED, SHEAF_BOX]};
    case SHAPE_LINEAR: {[SHEAF_PARALLEL]};
    case SHAPE_CREEPING: {[SHEAF_CREEPING]};
    default {[]};
};
private _offered = _need select {_x in _sheafs};
if (_need isNotEqualTo [] && _offered isEqualTo []) exitWith {[WHY_NO_SHEAF]};

if (_shape isEqualTo SHAPE_AREA) exitWith {
    private _radius = ([SHAPE_AREA_DEF, _size] select (_size > 0)) min _max;
    ["", _target, _offered select 0, _radius, -1, 0, format [WORDS_AREA, round _radius], [_target]]
};

// A line or a walk: from the point to the far end, else the size along the
// attitude.
private _length = [SHAPE_LENGTH_DEF, _size] select (_size > 0);
private _axis = _attitude;
if (_end isNotEqualTo []) then {
    _length = _target distance2D _end;
    _axis = _target getDir _end;
};
_length = _length min _max;

if (_shape isEqualTo SHAPE_LINEAR) exitWith {
    if (_axis < 0) then {_axis = _fire + RIGHT_ANGLE};
    _axis = _axis mod DEG_FULL;
    private _centre = +_target;
    if (_end isNotEqualTo []) then {_centre = [_target getPos [_length / 2, _axis]] call _fnc_ground};
    private _ends = [[_centre getPos [_length / 2, _axis]] call _fnc_ground, [_centre getPos [_length / 2, _axis + HALF_TURN]] call _fnc_ground];
    ["", _centre, SHEAF_LINEAR, _length / 2, _axis, _length, format [WORDS_LINEAR, round _length, [_axis] call _fnc_bearing], [_centre] + _ends]
};

if (_shape isEqualTo SHAPE_CREEPING) exitWith {
    if (_axis < 0) then {_axis = _fire};
    _axis = _axis mod DEG_FULL;
    private _far = [_target getPos [_length, _axis]] call _fnc_ground;
    ["", _target, SHEAF_CREEPING, CREEP_LANE * (1 max _guns) / 2, _axis, _length, format [WORDS_CREEPING, round _length, [_axis] call _fnc_bearing], [_target, _far]]
};

["", _target, SHEAF_CONVERGED, 0, -1, 0, "", [_target]]
