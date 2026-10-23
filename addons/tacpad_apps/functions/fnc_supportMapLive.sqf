#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT's live layer on its map: every support asset that is out,
 * where it is now, and the plan it is flying - the task markers and route
 * lines Simplex draws for its transports, for every asset the core lists
 * (row field 7, the airframe; row field 8, the plan, [[pos, label], ...]).
 *
 *   the airframe  - a square with its callsign, ink for the picked unit,
 *                   muted for the rest
 *   the plan      - a line from the airframe through each point in order,
 *                   each point a small diamond captioned "CALLSIGN · LZ"
 *
 * Drawn under the request layer (FUNC(supportMapDraw)), so what is being
 * asked for reads over what is already flying. Positions are read every
 * frame - the airframe moves on the map as it flies.
 *
 * Arguments:
 * 0: The map control <CONTROL>
 * 1: Metres per screen pixel at the current zoom <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, _mpp] call jmfsb_tacpad_apps_fnc_supportMapLive
 *
 * Public: No
 */

#define SQUARE_TEX "#(argb,8,8,3)color(1,1,1,1)"
#define EMPTY_TEX "#(argb,8,8,3)color(0,0,0,0)"
#define DIAMOND_TEX "\a3\ui_f\data\map\markers\military\dot_CA.paa"
#define MARKER_PX 26
#define OTHER_PX 16
#define STEM_PX 20
#define LABEL_PX 12
#define PLAN_PX 14
#define CAPTION_SIZE 0.04
#define LABEL_SIZE 0.05

params [["_map", controlNull, [controlNull]], ["_mpp", 1, [0]]];

if (isNull _map) exitWith {};

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _sel = uiNamespace getVariable [QGVAR(supportSelId), ""];

{
    private _row = _x;
    if !(_row isEqualType []) then {continue};
    private _id = _row param [0, ""];
    private _label = toUpper (_row param [2, ""]);
    private _veh = _row param [7, objNull];
    private _plan = _row param [8, []];
    if !(_veh isEqualType objNull) then {_veh = objNull};
    if !(_plan isEqualType []) then {_plan = []};
    private _picked = _id isEqualTo _sel && _id isNotEqualTo "";
    private _colour = [_muted, _ink] select _picked;

    // THE PLAN: airframe, then each point in order.
    private _from = if (alive _veh) then {getPosATL _veh} else {[]};
    {
        _x params [["_p", [], [[]]], ["_what", "", [""]]];
        if (count _p < 2) then {continue};
        if (_from isNotEqualTo []) then {_map drawLine [_from, _p, ([_colour, _accent] select _picked)]};
        _map drawIcon [DIAMOND_TEX, ([_colour, _accent] select _picked), _p, PLAN_PX, PLAN_PX, 0, format ["%1 · %2", _label, toUpper _what], 0, CAPTION_SIZE, "RobotoCondensedBold", "right"];
        _from = _p;
    } forEach _plan;

    // THE AIRFRAME, the picked one larger with its stem and type label.
    if (alive _veh) then {
        private _vp = getPosATL _veh;
        if (_picked) then {
            _map drawIcon [SQUARE_TEX, _ink, _vp, MARKER_PX, MARKER_PX, 0, "", 0];
            private _stemFoot = _vp vectorAdd [0, _mpp * MARKER_PX / 2, 0];
            private _stemHead = _vp vectorAdd [0, _mpp * (MARKER_PX / 2 + STEM_PX), 0];
            _map drawLine [_stemFoot, _stemHead, _ink];
            _map drawLine [_stemFoot vectorAdd [_mpp, 0, 0], _stemHead vectorAdd [_mpp, 0, 0], _ink];
            _map drawIcon [
                EMPTY_TEX, _ink, _stemHead vectorAdd [0, _mpp * LABEL_PX, 0], 1, 1, 0,
                _label, 0, LABEL_SIZE, "RobotoCondensedBold", "center"
            ];
        } else {
            _map drawIcon [SQUARE_TEX, _muted, _vp, OTHER_PX, OTHER_PX, 0, _label, 0, CAPTION_SIZE, "RobotoCondensedBold", "right"];
        };
    };
} forEach (uiNamespace getVariable [QGVAR(supportRows), []]);
