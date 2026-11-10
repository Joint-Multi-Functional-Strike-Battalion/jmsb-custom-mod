#include "script_component.hpp"
/*
 * Author: YonV
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
    GVAR(buildings) = [];
};

// ONE RANGE PER CLASS, the Vector's for everything while he looks through one
// (user, 2026-10-24). The scan reaches the widest of them; each target is then
// kept or dropped by its own, and carries it for the contrast fade.
private _vector = [] call FUNC(vectorView);
private _rangeAi = [GVAR(rangeAi), GVAR(rangeVector)] select _vector;
private _rangePlayer = [GVAR(rangePlayer), GVAR(rangeVector)] select _vector;
private _rangeVehicle = [GVAR(rangeVehicle), GVAR(rangeVector)] select _vector;
private _range = (_rangeAi max _rangePlayer) max _rangeVehicle;
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
// NOTHING RIGHT BESIDE HIM (user, 2026-10-25: "turn off the boxes within
// 10 m"): inside hideNearDistance nothing is boxed while hideNear is on.
private _near = [0, GVAR(hideNearDistance)] select GVAR(hideNear);
_vehicles = _vehicles select {(player distance _x) <= _rangeVehicle && {(player distance _x) > _near}};
_men = _men select {(player distance _x) <= ([_rangeAi, _rangePlayer] select (isPlayer _x)) && {(player distance _x) > _near}};
{
    _x setVariable [QGVAR(far), _rangeVehicle];
} forEach _vehicles;
{
    _x setVariable [QGVAR(far), [_rangeAi, _rangePlayer] select (isPlayer _x)];
} forEach _men;

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

// THE MARKED BUILDINGS IN RANGE (2026-11-06), from the server's published list
// (FUNC(markSet)): [building, rgb, label], out to MARK_RANGE.
GVAR(buildings) = ((missionNamespace getVariable [QGVAR(marks), []]) select {
    !isNull (_x select 0) && {(player distance (_x select 0)) <= MARK_RANGE}
}) apply {
    _x params ["_building", "_colour", "_label"];
    [_building, (MARK_COLOURS param [_colour, MARK_COLOURS select 0]) select 1, _label]
};
