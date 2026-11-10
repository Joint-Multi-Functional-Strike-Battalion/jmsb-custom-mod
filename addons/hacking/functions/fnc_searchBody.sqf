#include "script_component.hpp"
/*
 * Author: YonV
 * Takes the intel off a body, INTO THE SEARCHER'S INVENTORY.
 *
 * Nothing is banked here. The item is worth nothing until it is deposited at
 * an intel drop, which is what makes carrying a pocketful of them home a
 * thing worth doing - and worth stopping.
 *
 * Arguments:
 * 0: The body <OBJECT>
 * 1: The searcher <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_body", objNull, [objNull]], ["_searcher", objNull, [objNull]]];

if (isNull _body || {isNull _searcher}) exitWith {};

// Cleared first, so a double-click cannot loot the same body twice while the
// broadcast is still in flight.
_body setVariable [QGVAR(bodyIntel), false, true];

// WHAT HE WAS CARRYING. A man flagged as a phone carrier yields his phone;
// anyone else yields the paperwork a soldier actually has on him - a marked
// map or a GPS. The kind is decided here and once, so the body cannot be
// searched into a different answer.
private _kind = if ([_body] call FUNC(hasPhone)) then {
    QGVAR(intelItem)
} else {
    selectRandom [QGVAR(intelMap), QGVAR(intelGps)]
};

private _name = getText (configFile >> "CfgWeapons" >> _kind >> "displayName");

if (_searcher canAdd _kind) then {
    _searcher addItem _kind;
    ["Intel", format ["%1 taken. Worthless until you deposit it.", _name]] call EFUNC(notify,notify);
} else {
    // No room: on the ground rather than into thin air.
    private _holder = createVehicle ["GroundWeaponHolder", getPosATL _body, [], 0, "CAN_COLLIDE"];
    _holder addItemCargoGlobal [_kind, 1];
    ["Intel", format ["No room - the %1 is on the ground.", _name]] call EFUNC(notify,notify);
};
