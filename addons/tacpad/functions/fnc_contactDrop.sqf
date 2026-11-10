#include "script_component.hpp"
/*
 * Author: YonV
 * Ends the watch on the sender's TIC (FUNC(contactArm)): his group's event
 * handlers off, the thread and CONTACT OVER? forgotten. He sent a SITREP, the
 * thread closed or left his index, or a newer TIC of his is watched instead.
 * A quiet check still queued finds no thread and does nothing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_contactDrop
 *
 * Public: No
 */

{
    _x params ["_unit", "_type", "_id"];
    if (!isNull _unit) then {_unit removeEventHandler [_type, _id]};
} forEach GVAR(contactHandlers);
GVAR(contactHandlers) = [];

private _was = GVAR(contactPrompted);
GVAR(contactThread) = "";
GVAR(contactPrompted) = false;
GVAR(contactSeen) = [];

if (!_was) exitWith {};
if (!isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {
    [QGVAR(readerDraw), {[] call FUNC(readerDraw)}] call FUNC(nextFrameOnce);
};
