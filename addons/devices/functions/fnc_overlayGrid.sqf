#include "script_component.hpp"
/*
 * Author: JMSB
 * The grid square the player is in, for the walking view's readout - an 8 or
 * 10 figure grid, the player's choice (GVAR(gridDigits); user, 2026-10-21:
 * "8 or 10 player choice"). The map's
 * own edge numbers were too small to read.
 *
 * THE DEVICE IS THE RECEIVER. With EW loaded the position is the GPS's own
 * (jmfsb_ew_fnc_gpsState) - a spoofed set shows where the spoofer put it, an
 * anti-spoof set in a spoofer's field is flagged, and with no fix there is no
 * grid. The ten figures come from jmfsb_maptools_fnc_gridText when map tools
 * is loaded, so the readout agrees with its GRID tool; otherwise from the
 * engine's own square.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [text, GPS state - "" good, GPS_STATE_SUSPECT or GPS_STATE_NOFIX] <ARRAY>
 *
 * Example:
 * ([] call jmfsb_devices_fnc_overlayGrid) params ["_text", "_state"]
 *
 * Public: No
 */

private _unit = call CBA_fnc_currentUnit;
private _pos = getPosASL _unit;
private _state = "";
if (!isNil QEFUNC(ew,gpsState)) then {
    ([] call EFUNC(ew,gpsState)) params [["_gps", ""], "", ["_gpsPos", _pos]];
    if (_gps in [GPS_STATE_NOFIX, GPS_STATE_SUSPECT]) then {_state = _gps};
    _pos = _gpsPos;
};
if (_state isEqualTo GPS_STATE_NOFIX) exitWith {[GRID_NO_FIX, _state]};

private _perAxis = (GVAR(gridDigits) max (GRID_DIGIT_CHOICES select 0) min (GRID_DIGIT_CHOICES select 1)) / 2;
private _full = if (isNil QEFUNC(maptools,gridText)) then {""} else {[_pos] call EFUNC(maptools,gridText)};
private _axes = _full splitString " ";

// The engine's square when map tools could not refine it: as many figures as
// it gives, never more than asked for.
if (count _axes != 2 || {count (_axes select 0) != GRID_AXIS_FULL}) then {
    private _cell = mapGridPosition _pos;
    private _half = floor (count _cell / 2);
    _axes = [_cell select [0, _half], _cell select [_half, _half]];
};

[(_axes apply {_x select [0, _perAxis]}) joinString " ", _state]
