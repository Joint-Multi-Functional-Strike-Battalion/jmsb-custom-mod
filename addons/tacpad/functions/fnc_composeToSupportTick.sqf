#include "script_component.hpp"
/*
 * Author: YonV
 * The TO picker's SUPPORT group, polled: every TO_SUPPORT_POLL seconds while
 * the picker is up, on either host (the map's reader dialog or the tablet),
 * the assets' rows are asked again (FUNC(composeToSupport)) and their state
 * and ETA written into the lines already drawn (FUNC(liveApply); code review
 * R8). The board polls its rows the same way, every two seconds.
 *
 * ONE POLL AT A TIME. Every draw of the group arms it; an armed poll is not
 * armed again, so redraws on arriving traffic do not stack timers. It stops
 * by itself once the picker is gone - closed, picked from, or the reader shut.
 *
 * A CHANGE OF SHAPE IS A REDRAW: an asset listed or gone, a reorder. The
 * reader is drawn again next frame (FUNC(nextFrameOnce)), and that draw arms
 * the next poll. Nothing is typed on the pane while the picker is up, so
 * there is nothing to harvest first.
 *
 * Arguments:
 * 0: Only arm the poll, if it is not armed <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call jmfsb_tacpad_fnc_composeToSupportTick
 *
 * Public: No
 */

params [["_arm", false, [false]]];

if (_arm) exitWith {
    if (GVAR(toSupportArmed)) exitWith {};
    GVAR(toSupportArmed) = true;
    [{[] call FUNC(composeToSupportTick)}, [], TO_SUPPORT_POLL] call CBA_fnc_waitAndExecute;
};

GVAR(toSupportArmed) = false;

if (isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) exitWith {};
if (!GVAR(composeOn) || !GVAR(composeToPick) || GVAR(composeThread) isNotEqualTo "") exitWith {};

private _body = uiNamespace getVariable [QGVAR(toSupportBody), controlNull];
if (isNull _body) exitWith {};

([true] call FUNC(composeToSupport)) params ["_show", "_forCard", "_rows"];
if (!_show) exitWith {};

private _values = [];
{
    ([_x, GVAR(composeTo) isEqualTo (_x select 0)] call FUNC(composeToSupportLine)) params ["_name", "_meta"];
    _values pushBack _name;
    _values pushBack _meta;
} forEach _rows;

if ([_body, [_forCard, _rows apply {_x select 0}, GVAR(composeTo)], _values] call FUNC(liveApply)) exitWith {
    [true] call FUNC(composeToSupportTick);
};

[QGVAR(readerDraw), {[] call FUNC(readerDraw)}] call FUNC(nextFrameOnce);
