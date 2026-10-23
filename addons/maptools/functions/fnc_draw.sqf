#include "script_component.hpp"
/*
 * Author: JMSB
 * The tools' Draw handler, every frame on every map they are attached to.
 * Everything is drawn from world positions, so a ruler laid on the tablet is
 * the same ruler on the paper map.
 *
 * Bottom up: the viewshed's cells, the route, the ruler, the protractor, and
 * the cursor's own readout (GRID's ten digits, MARK's preview) on top, and
 * under GRID's a line with your own GPS grid (jmfsb_ew_fnc_gpsState when EW
 * is loaded): the false grid when spoofed, SUSPECT, or NO FIX.
 *
 * IN THE SCHEME'S COLOURS, from EFUNC(tacpad,theme) and nothing else: lines and
 * labels in the accent, and the viewshed in accent (seen) over ink (not seen).
 * Labels shrink with the host - a tablet screen two thirds the monitor's width
 * gets two-thirds type, never below TEXT_MIN_K.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map] call jmfsb_maptools_fnc_draw
 *
 * Public: No
 */

params ["_map"];

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];

private _k = (((ctrlPosition _map) # 2) / safeZoneW) min 1 max TEXT_MIN_K;
private _size = LABEL_SIZE * _k;
private _cursor = GVAR(cursor);
private _tool = GVAR(tool);

[_map, _ink, _accent, _size] call FUNC(drawViewshed);

// ROUTE: every leg with its own distance and bearing, the total at the last
// waypoint, and - while ROUTE is running - the leg to the cursor that the next
// press would add.
private _route = GVAR(route);
if (_route isNotEqualTo []) then {
    private _total = 0;
    {
        if (_forEachIndex > 0) then {
            private _from = _route # (_forEachIndex - 1);
            [_map, _from, _x, _accent, _size] call FUNC(drawLeg);
            _total = _total + (_from distance2D _x);
        };
        _map drawIcon [GVAR(dotIcon), _accent, _x, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    } forEach _route;

    if (count _route > 1) then {
        [_map, _route # (count _route - 1), format ["  TOTAL %1", [_total] call FUNC(distanceText)], _accent, _size] call FUNC(label);
    };

    if (_tool isEqualTo TOOL_ROUTE && {_cursor isNotEqualTo []}) then {
        [_map, _route # (count _route - 1), _cursor, _accent, _size] call FUNC(drawLeg);
    };
};

// RULER: the measured pair, or the rubber band from a waiting anchor.
if (GVAR(ruler) isNotEqualTo []) then {
    GVAR(ruler) params ["_from", "_to"];
    [_map, _from, _to, _accent, _size] call FUNC(drawLeg);
    _map drawIcon [GVAR(dotIcon), _accent, _from, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    _map drawIcon [GVAR(dotIcon), _accent, _to, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
};
if (GVAR(anchor) isNotEqualTo []) then {
    _map drawIcon [GVAR(dotIcon), _accent, GVAR(anchor), ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    if (_cursor isNotEqualTo []) then {
        [_map, GVAR(anchor), _cursor, _accent, _size] call FUNC(drawLeg);
    };
};

[_map, _accent, _size] call FUNC(drawProtractor);

// The cursor's own readout. GRID is the ten digits under it; MARK previews the
// grid its marker will carry.
if (_cursor isNotEqualTo [] && {_tool in [TOOL_GRID, TOOL_MARK]}) then {
    private _prefix = ["  ", "  MARK "] select (_tool isEqualTo TOOL_MARK);
    [_map, _cursor, _prefix + ([_cursor] call FUNC(gridText)), _accent, _size] call FUNC(label);
};

if (_cursor isNotEqualTo [] && _tool isEqualTo TOOL_GRID) then {
    private _state = "";
    private _own = getPosASL player;
    if (!isNil QEFUNC(ew,gpsState)) then {
        ([] call EFUNC(ew,gpsState)) params ["_gpsState", "", "_gpsPos"];
        _state = _gpsState;
        _own = _gpsPos;
    };
    private _text = GPS_PREFIX + ([([_own] call FUNC(gridText)), GPS_STATE_NOFIX] select (_state isEqualTo GPS_STATE_NOFIX));
    if (_state isEqualTo GPS_STATE_SUSPECT) then {_text = _text + " " + GPS_STATE_SUSPECT};
    private _screen = _map ctrlMapWorldToScreen _cursor;
    private _under = _map ctrlMapScreenToWorld [_screen select 0, (_screen select 1) + _size * GPS_LINE_K];
    [_map, _under, _text, _accent, _size] call FUNC(label);
};
