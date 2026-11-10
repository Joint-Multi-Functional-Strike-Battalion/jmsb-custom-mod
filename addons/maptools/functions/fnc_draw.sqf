#include "script_component.hpp"
/*
 * Author: YonV
 * The tools' Draw handler, every frame on every map they are attached to.
 * Everything is drawn from world positions, so a ruler laid on the tablet is
 * the same ruler on the paper map.
 *
 * Bottom up: the viewshed's cells, the range rings, the route, the ruler, the
 * LOS line, the protractor, and the cursor's own readout (GRID's ten digits,
 * MARK's preview) on top, and under GRID's a line with your own GPS grid
 * (jmfsb_ew_fnc_gpsState when EW is loaded): the false grid when spoofed,
 * SUSPECT, or NO FIX.
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

// RINGS: the setting's count about the centre, a step apart, each read at
// its north.
if (GVAR(rings) isNotEqualTo []) then {
    private _centre = GVAR(rings);
    _map drawIcon [GVAR(dotIcon), _accent, _centre, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    for "_i" from 1 to GVAR(ringCount) do {
        private _r = _i * GVAR(ringStep);
        _map drawEllipse [_centre, _r, _r, 0, _accent, ""];
        [_map, _centre vectorAdd [0, _r, 0], "  " + ([_r] call FUNC(distanceText)), _accent, _size] call FUNC(label);
    };
};

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

// LOS: the measured pair, in the accent when clear and in ink when not, with
// a dot where the ground or a building stops it; or the rubber band from a
// first point waiting for its second.
if (GVAR(los) isNotEqualTo []) then {
    GVAR(los) params ["_from", "_to", "_clear", "_where"];
    private _colour = [_ink, _accent] select _clear;
    [_map, _from, _to, _colour, _size] call FUNC(drawLeg);
    _map drawIcon [GVAR(dotIcon), _colour, _from, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    _map drawIcon [GVAR(dotIcon), _colour, _to, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    private _text = if (_clear) then {LOS_CLEAR} else {format [LOS_BLOCKED, [_from distance2D _where] call FUNC(distanceText)]};
    if (!_clear) then {
        _map drawIcon [GVAR(dotIcon), _accent, _where, ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    };
    [_map, _to, _text, _colour, _size, "left"] call FUNC(label);
};
if (GVAR(losFrom) isNotEqualTo []) then {
    _map drawIcon [GVAR(dotIcon), _accent, GVAR(losFrom), ICON_SIZE_DOT, ICON_SIZE_DOT, 0];
    if (_cursor isNotEqualTo []) then {
        [_map, GVAR(losFrom), _cursor, _accent, _size] call FUNC(drawLeg);
    };
};

[_map, _accent, _size] call FUNC(drawProtractor);

// THE MARKER CARD'S POINT: the picked icon in the picked colour, size and
// direction (2026-11-02), as the game's dialog shows its marker while it is
// open. Dropped when the card has gone without closing itself - its display
// went first.
if (GVAR(cardPreview) isNotEqualTo []) then {
    if (isNull (uiNamespace getVariable [QGVAR(card), controlNull])) then {
        GVAR(cardPreview) = [];
    } else {
        GVAR(cardPreview) params ["_at", "_icon", "_colour", ["_scale", CARD_SIZE_NORMAL], ["_dir", 0]];
        _map drawIcon [_icon, _colour, _at, CARD_PREVIEW_PX * _scale, CARD_PREVIEW_PX * _scale, _dir];
    };
};

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
