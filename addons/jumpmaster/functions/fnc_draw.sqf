#include "script_component.hpp"
/*
 * Author: JMSB
 * The leader's flight path on a map, every frame it is drawn (FUNC(attach)):
 * the run-in from where the aircraft appears to the RED LIGHT point in ink,
 * the drop run from RED to GREEN in the accent with its length and heading,
 * the run-out past it, and LAND - where the wind carries a stick released at
 * the green light (FUNC(drift)) - in ink. World positions, so the tablet and
 * the paper map show the same path.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map] call jmfsb_jumpmaster_fnc_draw
 *
 * Public: No
 */

params ["_map"];

private _red = GVAR(red);
if (_red isEqualTo []) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];
private _k = (((ctrlPosition _map) select 2) / safeZoneW) min 1 max TEXT_MIN_K;
private _size = LABEL_SIZE * _k;

_map drawIcon [GVAR(dotIcon), _accent, _red, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
[_map, _red, "  RED LIGHT", _accent, _size] call EFUNC(maptools,label);

private _green = GVAR(green);
if (_green isEqualTo []) exitWith {};

private _dir = _red getDir _green;
_map drawLine [_red getPos [RUN_IN, _dir + 180], _red, _ink];
[_map, _red, _green, _accent, _size] call EFUNC(maptools,drawLeg);
_map drawLine [_green, _green getPos [RUN_OUT, _dir], _ink];
_map drawIcon [GVAR(dotIcon), _accent, _green, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
[_map, _green, "  GREEN LIGHT", _accent, _size] call EFUNC(maptools,label);

// WHERE THE STICK LANDS: the green light carried by the wind.
([GVAR(type)] call FUNC(drift)) params ["_dx", "_dy"];
private _drift = [_dx, _dy, 0];
private _driftLen = vectorMagnitude _drift;
if (_driftLen >= WIND_MIN_M) then {
    private _land = _green vectorAdd _drift;
    _map drawLine [_green, _land, _ink];
    _map drawIcon [GVAR(dotIcon), _ink, _land, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    [_map, _land, format [LAND_LABEL, [_driftLen] call EFUNC(maptools,distanceText), [_green getDir _land] call EFUNC(maptools,bearingText)], _ink, _size] call EFUNC(maptools,label);
};
