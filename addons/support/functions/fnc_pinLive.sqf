#include "script_component.hpp"
/*
 * Author: YonV
 * Client: what a support thread's pin draws while the thread is IN_PROGRESS
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3, build step 8), as marker specs
 * for FUNC(pinMarker), from what the asset's provider already publishes:
 *
 *   its overlay   FUNC(overlay) - rings, lines and points in ink, each with
 *                 its label (a CAS search ring, the legs, a battery and its
 *                 ranges); and a fire mission's rounds by salvo: a salvo in
 *                 the air is a filled red ring round where it lands, read
 *                 HOG - SPLASH m:ss to its next round, one down is a red dot
 *                 per round, the first numbered with its salvo
 *   its route     the row's plan (field 8), joined from the airframe (field
 *                 7) while it flies, a dot with its word at each point
 *
 * The countdown moves with the poll that asks (FUNC(pinTick), 2 s).
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: The asset's row, [] none <ARRAY>
 * 2: The asset's call sign <STRING>
 *
 * Return Value:
 * Marker specs <ARRAY>
 *
 * Example:
 * ["fires:0", _row, "STEEL"] call jmfsb_support_fnc_pinLive
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_row", [], [[]]], ["_callsign", "", [""]]];

if (_assetId isEqualTo "") exitWith {[]};

private _specs = [];
private _salvos = createHashMap;
{
    _x params ["_shape", "_at"];
    switch (_shape) do {
        case OVERLAY_RING: {
            _x params ["", "", "_radius", "_label"];
            _specs pushBack [PIN_RING, _at, PIN_COLOUR_INK, _radius, PIN_BRUSH_EDGE, PIN_ALPHA_FULL];
            if (_label isNotEqualTo "") then {
                _specs pushBack [PIN_ICON, [_at select 0, (_at select 1) + _radius, 0], PIN_COLOUR_INK, PIN_ICON_LABEL, _label, PIN_ICON_SIZE];
            };
        };
        case OVERLAY_LINE: {
            _x params ["", "", "_to", "_label"];
            _specs pushBack [PIN_LINE, [_at, _to], PIN_COLOUR_INK];
            if (_label isNotEqualTo "") then {
                _specs pushBack [PIN_ICON, _to, PIN_COLOUR_INK, PIN_ICON_LEG, _label, PIN_LEG_SIZE];
            };
        };
        case OVERLAY_POINT: {
            _x params ["", "", "_label"];
            _specs pushBack [PIN_ICON, _at, PIN_COLOUR_INK, PIN_ICON_LEG, _label, PIN_LEG_SIZE];
        };
        case OVERLAY_ROUND: {
            _x params ["", "", "_n", "_lands", "_salvo"];
            private _rounds = _salvos getOrDefault [_salvo, []];
            _rounds pushBack [_at, _n, _lands];
            _salvos set [_salvo, _rounds];
        };
    };
} forEach ([_assetId, _row] call FUNC(overlay));

// --- the rounds, by salvo, in salvo order so a marker keeps its name -------
private _now = CBA_missionTime;
private _salvoOrder = keys _salvos;
_salvoOrder sort true;
{
    private _salvo = _x;
    private _rounds = _salvos get _salvo;
    private _due = (_rounds apply {_x select 2}) select {_x > _now};
    if (_due isEqualTo []) then {
        {
            _specs pushBack [PIN_ICON, _x select 0, PIN_COLOUR_ALARM, PIN_ICON_LEG, ["", str _salvo] select (_forEachIndex isEqualTo 0), PIN_LEG_SIZE];
        } forEach _rounds;
        continue;
    };

    private _sx = 0;
    private _sy = 0;
    {
        _sx = _sx + ((_x select 0) select 0);
        _sy = _sy + ((_x select 0) select 1);
    } forEach _rounds;
    private _centre = [_sx / count _rounds, _sy / count _rounds, 0];
    private _left = round ((selectMin _due) - _now);
    private _splash = format [PIN_SPLASH_TEXT, floor (_left / ETA_MINUTE), [_left mod ETA_MINUTE, 2] call CBA_fnc_formatNumber];
    _specs pushBack [PIN_RING, _centre, PIN_COLOUR_ALARM, PIN_IMPACT_M, PIN_BRUSH_FILL, PIN_IMPACT_ALPHA];
    _specs pushBack [PIN_RING, _centre, PIN_COLOUR_ALARM, PIN_IMPACT_M, PIN_BRUSH_EDGE, PIN_ALPHA_FULL];
    _specs pushBack [
        PIN_ICON, [_centre select 0, (_centre select 1) + PIN_IMPACT_M, 0], PIN_COLOUR_ALARM, PIN_ICON_LABEL,
        ([_callsign, _splash] select {_x isNotEqualTo ""}) joinString PIN_SEP, PIN_ICON_SIZE
    ];
} forEach _salvoOrder;

// --- the route --------------------------------------------------------------
private _plan = _row param [PIN_ROW_PLAN, []];
if !(_plan isEqualType []) exitWith {_specs};
private _points = [];
{
    if !(_x isEqualType []) then {continue};
    private _p = _x param [0, []];
    if !(_p isEqualType []) then {continue};
    if (count _p < 2) then {continue};
    _points pushBack _p;
    private _word = _x param [1, ""];
    if !(_word isEqualType "") then {_word = ""};
    _specs pushBack [PIN_ICON, _p, PIN_COLOUR_INK, PIN_ICON_LEG, _word, PIN_LEG_SIZE];
} forEach _plan;

private _vehicle = _row param [PIN_ROW_VEHICLE, objNull];
if !(_vehicle isEqualType objNull) then {_vehicle = objNull};
if (alive _vehicle) then {
    _points = [getPosATL _vehicle] + _points;
};
if (count _points > 1) then {
    _specs pushBack [PIN_LINE, _points, PIN_COLOUR_INK];
};

_specs
