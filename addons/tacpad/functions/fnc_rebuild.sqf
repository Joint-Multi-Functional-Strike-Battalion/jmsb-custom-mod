#include "script_component.hpp"
/*
 * Author: JMSB
 * Redraws a panel's contents in place, without touching its frame or its
 * position. A panel that has changed what it is showing - a reader that has
 * opened a thread, a roster that has lost a man - asks for this rather than
 * rebuilding itself, so the frame and its placement all
 * survive the redraw.
 *
 * With no id it redraws every open panel, which is what a theme change and a
 * settings change both want.
 *
 * Arguments:
 * 0: Panel id, "" for all of them <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["reader"] call jmfsb_tacpad_fnc_rebuild
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

if (!hasInterface) exitWith {};
if (isNull (HOST_DISPLAY)) exitWith {};

private _wanted = [GVAR(order), [_id]] select (_id != "");

{
    private _entry = GVAR(open) getOrDefault [_x, []];
    if (_entry isEqualTo []) then {continue};

    _entry params ["", "_body"];
    if (isNull _body) then {continue};

    private _panel = GVAR(panels) get _x;
    if (isNil "_panel") then {continue};

    // Nothing to unregister. A panel's handlers live on the controls it is
    // about to delete and go with them, which is the point of putting them
    // there rather than in a list the shell has to keep pruning.
    [_body, _x] call (_panel get "builder");
} forEach _wanted;
