#include "script_component.hpp"
/*
 * Author: JMSB
 * The task declarations one asset type offers, with the steppers sized for one
 * asset - or generic ranges when no asset is given (the "types" declaration,
 * shown before a unit is picked). Shape: addons/support/README.md
 *
 *   task    [token, label, meta, guidance, steppers, needsPoint, pointLabel]
 *   stepper [label, slot, step, min, max, display, list, bar]
 *
 * A FIRE MISSION IS SIMPLEX'S, ON THE BOARD'S STEPPERS: the ordnance, rounds
 * per gun, the sheaf type and its size, how many guns, the interval between
 * rounds, a delay before the first, more volleys, and whether nearby
 * batteries join. A stepper whose top the module set to 0 is not offered, and
 * COORDINATE only when another battery is close enough to join.
 *
 * SLOTS 12-19 AND 32-35 ARE THIS ADDON'S. A slot the player never touched
 * reads as its minimum - which is what the page shows for it - so every
 * minimum is a real order: the first ordnance type, one round, the first
 * sheaf type offered, a tight sheaf, ALL guns, no extra interval, no delay, no
 * repeat, alone, one missile, one munition, the smallest search.
 *
 * Arguments:
 * 0: Asset type <STRING>
 * 1: The module logic, objNull for the generic declaration <OBJECT>
 *
 * Return Value:
 * Task declarations <ARRAY>
 *
 * Example:
 * ["arty", _logic] call jmfsb_support_fires_fnc_taskDecls
 *
 * Public: No
 */

params [["_type", "", [""]], ["_logic", objNull, [objNull]]];

// "ALL" at 0, then 1..n - a value list the page indexes by the slot's value.
private _counted = {
    params ["_n", "_zero"];
    private _words = [_zero];
    for "_i" from 1 to _n do {_words pushBack str _i};
    _words
};

// The DELAY stepper, for the two asset types that take one.
private _delayStep = {
    params ["_max"];
    [["DELAY", SLOT_DELAY, DELAY_STEP, 0, _max, "%1 S", [], true]] select {_max > 0}
};

switch (_type) do {
    case TYPE_ARTY: {
        private _ord = [_logic] call FUNC(ordnance);
        private _words = _ord apply {
            _x params ["_name", "_rounds"];
            format ["%1 · %2", _name, [str _rounds, "UNL"] select (_rounds < 0)]
        };
        private _guns = _logic getVariable [QGVAR(gunCount), 0];
        private _sheafs = _logic getVariable [QGVAR(sheafs), [SHEAF_CONVERGED, SHEAF_PARALLEL, SHEAF_BOX, SHEAF_CREEPING]];
        private _maxInterval = _logic getVariable [QGVAR(maxInterval), VA_DEF_MAX_INTERVAL];
        private _maxRepeat = _logic getVariable [QGVAR(maxRepeat), VA_DEF_MAX_REPEAT];

        private _steps = [
            ["ORDNANCE", SLOT_ORD, 1, 0, (count _ord - 1) max 0, [_words, "%1"] select (_words isEqualTo []), [], false],
            ["ROUNDS PER GUN", SLOT_ROUNDS, 1, 1, _logic getVariable [QGVAR(maxRounds), VA_DEF_MAX_ROUNDS], "%1", [], true],
            ["SHEAF TYPE", SLOT_SHEAF_TYPE, 1, selectMin _sheafs, selectMax _sheafs, SHEAF_WORDS, _sheafs, false],
            ["SHEAF", SLOT_SHEAF, SHEAF_STEP, 0, SHEAF_MAX, "%1 M", [], true],
            ["GUNS", SLOT_GUNS, 1, 0, _guns, [_guns, "ALL"] call _counted, [], true]
        ];
        if (_maxInterval > 0) then {
            _steps pushBack ["INTERVAL", SLOT_INTERVAL, INTERVAL_STEP, 0, _maxInterval, "+%1 S", [], true];
        };
        _steps append ([_logic getVariable [QGVAR(maxDelay), VA_DEF_MAX_DELAY]] call _delayStep);
        if (_maxRepeat > 0) then {
            _steps pushBack ["REPEAT", SLOT_REPEAT, 1, 0, _maxRepeat, [_maxRepeat, "NONE"] call _counted, [], true];
        };
        if (([_logic] call FUNC(partners)) isNotEqualTo []) then {
            _steps pushBack ["COORDINATE", SLOT_COORD, 1, 0, 1, ["ALONE", "WITH NEARBY"], [], false];
        };

        [[
            TASK_FIRE, "FIRE MISSION", "FFE",
            "Guns fire their rounds into the sheaf round the target point; DELAY holds the first round, REPEAT fires more volleys",
            _steps,
            true
        ]]
    };
    case TYPE_CRUISE: {
        private _max = 1 max ((_logic getVariable [QGVAR(salvo), 1]) min (_logic getVariable [QGVAR(left), 1]));
        [[
            TASK_STRIKE, "STRIKE", "CRUISE MISSILE STRIKE",
            "Missiles fly the whole route at cruise altitude and dive on the target point",
            [["MISSILES", SLOT_MISSILES, 1, 1, _max, "%1", [], true]] + ([_logic getVariable [QGVAR(maxDelay), 0]] call _delayStep),
            true
        ]]
    };
    case TYPE_LOITER: {
        private _max = 1 max ((_logic getVariable [QGVAR(salvo), 1]) min (_logic getVariable [QGVAR(left), 1]));
        [[
            TASK_HUNT, "HUNT", "LOITER AND STRIKE",
            "Munitions orbit the target point, hunt inside the radius, and dive on the best target",
            [
                ["MUNITIONS", SLOT_MUNITIONS, 1, 1, _max, "%1", [], true],
                ["SEARCH RADIUS", SLOT_SEARCH, SEARCH_STEP, SEARCH_MIN, SEARCH_MAX, "%1 M", [], true]
            ],
            true
        ]]
    };
    default {[]};
}
