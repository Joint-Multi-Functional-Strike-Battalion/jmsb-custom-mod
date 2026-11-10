#include "script_component.hpp"
/*
 * Author: YonV
 * Turns the net rows to the next or previous page of net buttons that has a
 * net on it (FUNC(netButtons)), round from the last to the first - the
 * device arrows on the walking view (numpad 0 / ., FUNC(voiceAction)) and the
 * tablet net row's < > buttons (FUNC(tabletNets)). Pages with no nets are
 * skipped.
 *
 * Not consumed with one page or none, so the key falls through to the game.
 *
 * Arguments:
 * 0: Step, -1 left or 1 right <NUMBER>
 *
 * Return Value:
 * Turned <BOOL>
 *
 * Example:
 * [1] call jmfsb_devices_fnc_netPageStep
 *
 * Public: No
 */

params [["_step", 1, [0]]];

([] call FUNC(netButtons)) params ["", "_page", "_pages"];
private _count = count _pages;
if (_count < 2) exitWith {false};

private _at = (_pages find _page) max 0;
GVAR(netPage) = _pages select ((_at + _step + _count) mod _count);
[] call FUNC(overlayTick);
true
