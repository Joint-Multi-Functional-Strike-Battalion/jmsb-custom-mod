#include "script_component.hpp"
/*
 * Author: YonV
 * This addon's own flight control takes a helicopter: from where it is to a
 * hover over a point, held there, or on down to a landing (2026-11-05 -
 * modelled on how Simplex Support Services pilots a helicopter in to a
 * landing, a hover and a fast-rope: not the AI's; no code of it used). The
 * airframe is flown by velocity every frame (FUNC(heliFrame)) and handed back
 * to the AI after (FUNC(heliRelease)); the HELI_ defines in
 * script_component.hpp say how. One RPT line here, one when it is handed back.
 *
 * THE POINT'S SURFACE is the highest thing from HELI_SURFACE_UP m above the
 * terrain down - a roof, a deck, the ground, the sea - and the hover is the
 * height asked above that. An object to look past (the load a sling hover
 * hooks) is not a surface.
 *
 * Only the server's own airframe with an AI pilot in it, able to move, is
 * taken; a player at the controls is left alone. An order under way
 * (FUNC(heliOrder)) is dropped; a control already on it is replaced.
 *
 * Arguments:
 * 0: The helicopter <OBJECT>
 * 1: The point, [x, y] or [x, y, z] <ARRAY>
 * 2: Hover height over its surface, m <NUMBER>
 * 3: Land there after the hover <BOOL> (optional, default false)
 * 4: Engine left running once down <BOOL> (optional, default true)
 * 5: The most it flies at, m/s <NUMBER> (optional, default HELI_APPROACH_SPEED)
 * 6: Why, for the RPT <STRING> (optional, default "")
 * 7: An object that is not a surface - the load under a sling hover <OBJECT> (optional, default objNull)
 * 8: How far below the airframe the lowest thing hangs, m - a sling's rope and
 *    load; the floor on the way in keeps that off the surface ahead, not only
 *    the airframe (2026-11-05, logistics) <NUMBER> (optional, default 0)
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [_veh, _lz, 10, true, true, 20, "landing"] call jmfsb_support_air_fnc_heliTake
 *
 * Public: No
 */

params [
    ["_veh", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_height", 0, [0]],
    ["_land", false, [false]],
    ["_engine", true, [false]],
    ["_cap", HELI_APPROACH_SPEED, [0]],
    ["_why", "", [""]],
    ["_ignore", objNull, [objNull]],
    ["_hang", 0, [0]]
];

if (!alive _veh || count _pos < 2 || !local _veh || !canMove _veh) exitWith {false};
private _pilot = driver _veh;
if (isNull _pilot || !alive _pilot || isPlayer _pilot) exitWith {false};

_veh setVariable [QGVAR(order), nil];
if (count (_veh getVariable [QGVAR(flight), createHashMap]) > 0) then {
    [_veh, "replaced"] call FUNC(heliRelease);
};

_pos params ["_px", "_py"];
private _terrain = (getTerrainHeightASL [_px, _py]) max HELI_SEA_Z;
private _hits = lineIntersectsSurfaces [[_px, _py, _terrain + HELI_SURFACE_UP], [_px, _py, _terrain - HELI_SCAN_BODY], _veh, _ignore, true, 1, "GEOM", "FIRE"];
private _surface = if (_hits isEqualTo []) then {_terrain} else {((_hits select 0) select 0) select 2};

doStop _veh;
_pilot disableAI "PATH";
_veh engineOn true;
// The gear is FUNC(heliFrame)'s to put down and keep down on the way in.

_veh setVariable [QGVAR(flight), createHashMapFromArray [
    ["phase", HELI_PHASE_APPROACH],
    ["goal", [_px, _py, _surface + _height]],
    ["land", _land],
    ["engine", _engine],
    // a VTOL comes down from its cruise on a glide (FUNC(heliFrame))
    ["vtol", _veh isKindOf "VTOL_Base_F"],
    // the speed it is taken at is kept and braked off level (2026-11-08: no
    // rise to slow down - FUNC(heliFrame))
    ["cap", _cap max ((vectorMagnitude [(velocity _veh) select 0, (velocity _veh) select 1, 0]) min HELI_CARRY_MAX)],
    ["ignore", _ignore],
    ["hang", _hang max 0],
    ["heading", getDir _veh],
    ["pitch", 0],
    ["bank", 0],
    ["since", CBA_missionTime],
    ["took", CBA_missionTime]
]];
_veh setVariable [QGVAR(flightPfh), [FUNC(heliFrame), 0, [_veh]] call CBA_fnc_addPerFrameHandler];

private _what = if (_land) then {format ["landing, engine %1 after", ["off", "on"] select _engine]} else {"a hover"};
private _far = round (_veh distance2D _pos);
INFO_6("heliTake: '%1' takes the airframe %2 m from %3 - %4 %5 m over it - %6",typeOf _veh,_far,mapGridPosition _pos,_what,_height,_why);
true
