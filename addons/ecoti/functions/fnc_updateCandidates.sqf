#include "script_component.hpp"
/*
 * Author: JMSB
 * Rebuilds the two lists Draw3D draws from: men in range on foot, and the
 * vehicles and animals in range, and the colour each is drawn in. Runs twice a
 * second.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_updateCandidates
 *
 * Public: No
 */

if (isNull player) exitWith {};

if !([] call FUNC(isActive)) exitWith {
    GVAR(men) = [];
    GVAR(vehicles) = [];
};

private _range = GVAR(range);
private _own = vehicle player;

// Every vehicle and animal in range, hot or not (user, 2026-10-15: a vehicle
// with its engine off drew nothing; empty vehicles and animals are wanted in
// white). Both are drawn as a box (FUNC(vehicleBox)).
private _vehicles = (player nearEntities [VEHICLE_TYPES + ANIMAL_TYPES, _range]) select {
    _x != _own
    && {alive _x}
};

private _men = (player nearEntities [MAN_TYPES, _range]) select {
    _x != player
    && {alive _x}
    && {isNull objectParent _x}
    && {!isObjectHidden _x}
};

// A NEWCOMER STARTS UNSEEN. Its visibility is from whenever it was last in
// range, and drawing on that for up to 0.2 s would show a man through a wall.
// Every target's side colour is settled here too, not per frame.
private _old = GVAR(men) + GVAR(vehicles);
{
    if !(_x in _old) then {_x setVariable [QGVAR(seen), false]};
    _x setVariable [QGVAR(rgb), [_x] call FUNC(targetColour)];
    _x setVariable [QGVAR(hex), (_x getVariable QGVAR(rgb)) call BIS_fnc_colorRGBtoHTML];
    _x setVariable [QGVAR(label), [_x] call FUNC(targetLabel)];
    _x setVariable [QGVAR(card), [_x] call FUNC(targetCard)];
} forEach (_men + _vehicles);

GVAR(men) = _men;
GVAR(vehicles) = _vehicles;
