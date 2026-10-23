#include "script_component.hpp"
/*
 * Author: JMSB
 * The support page's parameter array read into the options an order of this
 * asset carries - the one reading the order (FUNC(task)) and the verdict
 * before CONFIRM (FUNC(preview)) share, so the preview describes exactly the
 * order CONFIRM sends.
 *
 * Each slot is clamped into its stepper's range; unset reads as the minimum.
 * The ordnance index becomes the round kind it points at now, so a list that
 * changes before the server reads it cannot turn HE into smoke.
 *
 *   artillery [kind, rounds per gun, sheaf, guns, name, sheaf type, delay, interval, repeat, coordinate]
 *   cruise    [missiles, delay]
 *   loiter    [munitions, search radius]
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * Options, [] when there is nothing to order <ARRAY>
 *
 * Example:
 * [_logic, _params] call jmfsb_support_fires_fnc_readOpts
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_prm", [], [[]]]];

if (isNull _logic) exitWith {[]};

private _slot = {
    params ["_i", "_min", "_max"];
    private _v = _prm param [_i, _min];
    if (isNil "_v" || {!(_v isEqualType 0)}) then {_v = _min};
    (round _v) max _min min _max
};

switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {
        private _ord = [_logic] call FUNC(ordnance);
        if (_ord isEqualTo []) then {_ord = [["", 0, ""]]};
        (_ord select ([SLOT_ORD, 0, count _ord - 1] call _slot)) params ["_name", "", "_key"];
        private _sheafs = _logic getVariable [QGVAR(sheafs), [SHEAF_CONVERGED]];
        private _sheafType = [SLOT_SHEAF_TYPE, selectMin _sheafs, selectMax _sheafs] call _slot;
        if !(_sheafType in _sheafs) then {_sheafType = _sheafs select 0};
        private _opts = [
            _key,
            [SLOT_ROUNDS, 1, _logic getVariable [QGVAR(maxRounds), 1]] call _slot,
            [SLOT_SHEAF, 0, SHEAF_MAX] call _slot,
            [SLOT_GUNS, 0, _logic getVariable [QGVAR(gunCount), 0]] call _slot,
            _name,
            _sheafType,
            [SLOT_DELAY, 0, _logic getVariable [QGVAR(maxDelay), 0]] call _slot,
            [SLOT_INTERVAL, 0, _logic getVariable [QGVAR(maxInterval), 0]] call _slot,
            [SLOT_REPEAT, 0, _logic getVariable [QGVAR(maxRepeat), 0]] call _slot,
            [SLOT_COORD, 0, 1] call _slot
        ];
        // Nothing left to fire is no order at all.
        [[], _opts] select (_key isNotEqualTo "")
    };
    case TYPE_CRUISE: {
        private _max = 1 max ((_logic getVariable [QGVAR(salvo), 1]) min (_logic getVariable [QGVAR(left), 1]));
        [[SLOT_MISSILES, 1, _max] call _slot, [SLOT_DELAY, 0, _logic getVariable [QGVAR(maxDelay), 0]] call _slot]
    };
    case TYPE_LOITER: {
        private _max = 1 max ((_logic getVariable [QGVAR(salvo), 1]) min (_logic getVariable [QGVAR(left), 1]));
        [[SLOT_MUNITIONS, 1, _max] call _slot, [SLOT_SEARCH, SEARCH_MIN, SEARCH_MAX] call _slot]
    };
    default {[]};
}
