#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT's overlay on the real map - the Draw handler of the board's
 * map control, in both hosts (the dialog's own map on the vanilla map, the
 * tablet's map under the board's hole). Only the handoff's overlay language,
 * every colour from the theme. Two layers:
 *
 * WHAT IS FLYING (FUNC(supportMapLive)) - every asset out, and the plan it is
 * flying as Simplex-style task markers joined by a line - and, in ink, the
 * shapes the picked asset's provider asks for (EFUNC(support,overlay)): a
 * battery's range rings.
 *
 * WHAT IS BEING ASKED FOR, over it - the request on the form, live as it is
 * set, the way Simplex's visual aids follow its request menu:
 *   task point    - an 18px accent square inside a 7px accent halo
 *   other points  - accent arrows for each point the task declares (task
 *                   declaration field 7): "in" legs (INGRESS, each VIA)
 *                   chained into the task point, "out" legs (EGRESS, an LZ,
 *                   a set-down point) leaving it
 *   effect radius - a 2px accent square outline with a micro-label caption
 *                   above it ("SAD · 500 M") that reads the stepper's slot
 *                   every frame, so it follows each step live
 *   approach      - the final approach bearing, a leg drawn out from the
 *                   point with an arrow pointing in (a ["bearing"] aid)
 *   danger close  - the friendly range a release is held inside, a ring,
 *                   while DANGER CLOSE is off (a ["ring"] aid)
 *
 * The square outline is a world-space rectangle, so it is the real ground the
 * radius covers; the 2px weight is two 1px outlines a screen pixel apart.
 *
 * Arguments:
 * 0: The map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_tacpad_apps_fnc_supportMapDraw}]
 *
 * Public: No
 */

#define SQUARE_TEX "#(argb,8,8,3)color(1,1,1,1)"
#define EMPTY_TEX "#(argb,8,8,3)color(0,0,0,0)"
#define ARROW_TEX "\a3\ui_f\data\map\markers\military\arrow_CA.paa"
#define POINT_PX 18
#define HALO_PX 7
#define HALO_ALPHA 0.22
#define CAPTION_PX 10
#define ARROW_PX 20
#define CAPTION_SIZE 0.04

params [["_map", controlNull, [controlNull]]];

if (isNull _map) exitWith {};

private _accent = ["accent"] call EFUNC(tacpad,theme);
private _halo = [_accent select 0, _accent select 1, _accent select 2, HALO_ALPHA];

// Metres per screen pixel at the current zoom, for everything that is sized
// in pixels but placed in the world.
private _mpp = abs (((_map ctrlMapScreenToWorld [pixelW, 0]) select 0) - ((_map ctrlMapScreenToWorld [0, 0]) select 0));

// ----------------------------------------------- what is already flying ---
[_map, _mpp] call FUNC(supportMapLive);

// ---------------------------------------------- the provider's own shapes --
// Whatever the picked asset's provider asks for (EFUNC(support,overlay),
// already checked there) - a battery's minimum and maximum range rings - in
// ink, under the request.
private _ink = ["ink"] call EFUNC(tacpad,theme);
{
    switch (_x select 0) do {
        case "ring": {
            _x params ["", "_c", "_r", "_label"];
            _map drawEllipse [_c, _r, _r, 0, _ink, ""];
            if (_label isNotEqualTo "") then {
                _map drawIcon [EMPTY_TEX, _ink, [_c select 0, (_c select 1) + _r + _mpp * CAPTION_PX, 0], 1, 1, 0, toUpper _label, 0, CAPTION_SIZE, "RobotoCondensedBold", "center"];
            };
        };
        case "line": {
            _x params ["", "_a", "_b", "_label"];
            _map drawLine [_a, _b, _ink];
            if (_label isNotEqualTo "") then {
                _map drawIcon [EMPTY_TEX, _ink, _b, 1, 1, 0, toUpper _label, 0, CAPTION_SIZE, "RobotoCondensedBold", "right"];
            };
        };
        case "point": {
            _x params ["", "_at", "_label"];
            _map drawIcon [SQUARE_TEX, _ink, _at, POINT_PX / 2, POINT_PX / 2, 0, toUpper _label, 0, CAPTION_SIZE, "RobotoCondensedBold", "right"];
        };
    };
} forEach (uiNamespace getVariable [QGVAR(supportShapes), []]);

private _pt = missionNamespace getVariable [QGVAR(supportPoint), []];

// ------------------------------------------- the task's other points ---
// Drawn before a target exists - they are the only feedback that a press
// landed in the row the player meant. "in" legs chain into the task point
// in order (VIA, VIA, ..., INGRESS); "out" legs leave it (EGRESS, the LZ,
// a set-down point).
private _fnc_arrow = {
    params ["_at", "_dir", "_text"];
    _map drawIcon [ARROW_TEX, _accent, _at, ARROW_PX, ARROW_PX, _dir, _text, 0, CAPTION_SIZE, "RobotoCondensedBold"];
};
{
    _x params ["_label", "", "", "", "_many", "_leg", "_key"];
    private _v = missionNamespace getVariable [([_key] call FUNC(supportPointVars)) select 0, []];
    private _list = if (_v isNotEqualTo [] && {(_v select 0) isEqualType []}) then {_v} else {[_v] select {_x isNotEqualTo []}};
    if (_list isEqualTo []) then {continue};
    if (_leg isEqualTo "in") then {
        {
            private _next = _list param [_forEachIndex + 1, _pt];
            private _dir = [0, _x getDir _next] select (_next isNotEqualTo []);
            [_x, _dir, [_label, format ["%1 %2", _label, _forEachIndex + 1]] select (_many > 1)] call _fnc_arrow;
            if (_next isNotEqualTo []) then {_map drawLine [_x, _next, _accent]};
        } forEach _list;
    } else {
        private _p = _list select 0;
        [_p, [0, _pt getDir _p] select (_pt isNotEqualTo []), _label] call _fnc_arrow;
        if (_pt isNotEqualTo []) then {_map drawLine [_pt, _p, _accent]};
    };
} forEach (uiNamespace getVariable [QGVAR(supportPointDecls), []]);

if (_pt isEqualTo []) exitWith {};

// ---------------------------------------------------------- the task point --
_map drawIcon [SQUARE_TEX, _halo, _pt, POINT_PX + 2 * HALO_PX, POINT_PX + 2 * HALO_PX, 0, "", 0];
_map drawIcon [SQUARE_TEX, _accent, _pt, POINT_PX, POINT_PX, 0, "", 0];

(missionNamespace getVariable [QGVAR(supportSel), ["cas", "", ""]]) params [["_type", "cas"], "", ["_task", ""]];
private _prm = missionNamespace getVariable [QGVAR(supportParams), SUP_PARAMS_DEFAULT];
private _fnc_value = {
    params ["_slot", "_min", "_max"];
    private _v = _prm param [_slot, _min];
    if !(_v isEqualType 0) then {_v = _min};
    (round _v) max _min min _max
};

// ---------------------------------------------- approach and danger close --
// A bearing aid is the final approach: a leg drawn out from the point on the
// bearing it comes in from, an arrow on it pointing in. A ring aid is the
// friendly range a release is held inside while DANGER CLOSE is off.
{
    _x params ["_aid", "_slot", "_min", "_max", "_label"];
    private _v = [_slot, _min, _max] call _fnc_value;
    switch (_aid param [0, ""]) do {
        case "bearing": {
            if (_v <= 0) exitWith {};
            private _from = (_v - 1) * (_aid param [1, 0]);
            private _end = _pt getPos [_mpp * SUP_APPROACH_PX, _from];
            _map drawLine [_end, _pt, _accent];
            [_end, _from + 180, format ["%1 %2", toUpper _label, round _from]] call _fnc_arrow;
        };
        case "ring": {
            private _rm = _aid param [1, 0];
            if (_v > 0 || _rm <= 0) exitWith {};
            _map drawEllipse [_pt, _rm, _rm, 0, _accent, ""];
            _map drawIcon [
                EMPTY_TEX, _accent, _pt vectorAdd [0, -_rm - _mpp * CAPTION_PX, 0], 1, 1, 0,
                format ["NO RELEASE INSIDE · %1 M", round _rm], 0, CAPTION_SIZE, "RobotoCondensedBold", "center"
            ];
        };
    };
} forEach (uiNamespace getVariable [QGVAR(supportAids), []]);

// ------------------------------------------------------- the effect radius --
// CAS draws its search radius, artillery the dispersion its rounds land in;
// a transport has no radius to show.
//
// THE SLOT IS THE PICKED TASK'S, NOT THE TYPE'S. support_air's RADIUS and the
// fires battery's SHEAF live in their own slots under the same "cas" and
// "arty" types ALiVE uses, so FUNC(appSupport) hands over the declared
// stepper that sizes the area - [slot, min, max, label], [] for none - and
// the type's ALiVE slot is read only while that is unset (the legacy layout).
private _step = uiNamespace getVariable QGVAR(supportRadiusStep);
private _word = ["RADIUS", "DISPERSION"] select (_type isEqualTo "arty");
private _r = if (isNil "_step") then {
    switch (_type) do {
        case "cas": {_prm param [0, 500]};
        case "arty": {_prm param [6, 100]};
        default {0};
    }
} else {
    if (_step isEqualTo []) exitWith {0};
    _step params ["_slot", "_min", "_max", "_label"];
    _word = _label;
    [_slot, _min, _max] call _fnc_value
};
if (_r <= 0) exitWith {};

_map drawRectangle [_pt, _r, _r, 0, _accent, ""];
_map drawRectangle [_pt, _r + _mpp, _r + _mpp, 0, _accent, ""];

// The caption sits on the square's top-left corner, lifted clear of the edge,
// and names the task when one is picked.
if (_task isNotEqualTo "") then {_word = _task};
_map drawIcon [
    EMPTY_TEX, _accent, (_pt vectorAdd [-_r, _r + _mpp * CAPTION_PX, 0]), 1, 1, 0,
    format ["%1 · %2 M", toUpper _word, round _r], 0, CAPTION_SIZE, "RobotoCondensedBold", "right"
];
