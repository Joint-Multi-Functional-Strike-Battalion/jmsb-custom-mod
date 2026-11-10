#include "script_component.hpp"
/*
 * Author: YonV
 * The route on a map, every frame it is drawn (FUNC(attach)): a numbered dot
 * at each waypoint and each leg measured, in ink, the way the map tools draw
 * a route; the waypoint being walked to and the leg to it from where the GPS
 * says the player is, in the accent. A FOLLOW waypoint is drawn where its man
 * is now (FUNC(wpPos)). World positions, so the tablet and the paper map
 * show the same route.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map] call jmfsb_pointman_fnc_draw
 *
 * Public: No
 */

params ["_map"];

private _wps = GVAR(waypoints);
if (_wps isEqualTo []) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];
private _k = (((ctrlPosition _map) select 2) / safeZoneW) min 1 max TEXT_MIN_K;
private _size = LABEL_SIZE * _k;
([] call FUNC(state)) params ["_nav", "_next", "", "", "_dist"];

private _points = _wps apply {[_x] call FUNC(wpPos)};
{
    private _pos = _x;
    private _live = _nav && _forEachIndex isEqualTo _next;
    private _colour = [_ink, _accent] select _live;
    if (_forEachIndex > 0) then {
        [_map, _points select (_forEachIndex - 1), _pos, _ink, _size] call EFUNC(maptools,drawLeg);
    };
    _map drawIcon [GVAR(dotIcon), _colour, _pos, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    [_map, _pos, format ["  %1", _forEachIndex + 1], _colour, _size] call EFUNC(maptools,label);
} forEach _points;

if (_nav && _dist >= 0) then {
    [_map, [] call FUNC(gpsPos), _points select _next, _accent, _size] call EFUNC(maptools,drawLeg);
};
