#include "script_component.hpp"
/*
 * Author: YonV
 * Puts both slots on or off the screen to match FUNC(hidden).
 *
 * HIDDEN, NOT TORN DOWN. ctrlShow rather than ctrlDelete, for the reason the map
 * handler already gave: rebuilding the slots every time a screen opens is how a
 * HUD starts flickering. The controls stay where they are and stop drawing.
 *
 * IT ONLY ACTS ON A CHANGE. This runs every frame, and setting ctrlShow to the
 * value it already holds sixty times a second is sixty pointless UI commands -
 * so the last answer is remembered and the controls are touched only when it
 * turns over.
 *
 * COMING BACK, IT REDRAWS. A slot hidden behind the admin console for two
 * minutes still holds the readings it had when the console opened; showing that
 * again is worse than showing nothing, because a stale scanner sweep is read as
 * a current one. The redraw is on the un-hide only - going away needs no work.
 *
 * Arguments:
 * 0: Apply even if the answer has not changed <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_force", false, [false]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
if (isNull _display) exitWith {};

private _show = !([] call FUNC(hidden));
if (!_force && {_show isEqualTo (uiNamespace getVariable [QGVAR(shown), true])}) exitWith {};

uiNamespace setVariable [QGVAR(shown), _show];

{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlShow _show};
} forEach [IDC_HUD_LEFT, IDC_HUD_RIGHT];

if (_show) then {[] call FUNC(draw)};
