#include "script_component.hpp"
/*
 * Author: YonV
 * Sets off a delivered item's marking once it is on the ground - smoke, an
 * IR strobe, a chemlight or a flare, as the module or the requester chose -
 * so the section that asked for it can find it in the trees (Simplex signals
 * its drops on touchdown the same way). "" is no marking. Moved here from
 * support_air with the Logistics Drop (2026-11-01, was markCrate); it marks
 * any item now, a vehicle as much as a crate.
 *
 * Arguments:
 * 0: The item <OBJECT>
 * 1: Marking class <STRING> (optional, default "" - none)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_item, "SmokeShellBlue"] call jmfsb_support_logistics_fnc_markItem
 *
 * Public: No
 */

// How long the item has to reach the ground before nobody waits for it.
#define MARK_PATIENCE 300
// Height above the ground that counts as down.
#define MARK_DOWN 1

params [["_item", objNull, [objNull]], ["_signal", "", [""]]];

if (isNull _item || _signal isEqualTo "") exitWith {};

[
    {
        params ["_item"];
        isNull _item || {isNull attachedTo _item && {((getPos _item) select 2) < MARK_DOWN}}
    },
    {
        params ["_item", "_signal"];
        if (isNull _item) exitWith {};
        createVehicle [_signal, getPosATL _item, [], 0, "CAN_COLLIDE"];
        INFO_2("delivered '%1' down at %2",typeOf _item,mapGridPosition _item);
    },
    [_item, _signal],
    MARK_PATIENCE
] call CBA_fnc_waitUntilAndExecute;
