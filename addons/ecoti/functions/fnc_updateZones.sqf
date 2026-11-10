#include "script_component.hpp"
/*
 * Author: YonV
 * The LZs and DZs Draw3D highlights (user, 2026-11-02: "in AiTR lz and drop
 * zones need to be highlighted"): the open zones of the player's side's support
 * threads, as the server published them to this machine (jmfsb_support
 * FUNC(zonesLocal), localNamespace - read softly, nothing without the support
 * core). Runs twice a second, so Draw3D only projects:
 *
 *   on a new list   each zone's ring of ZONE_RING_DOTS points on the ground, and
 *                   its label words - LZ | PICKUP | RAVEN | (the range per frame)
 *   every tick      the nearest ZONE_MAX of them, and the TAC//PAD accent they
 *                   are drawn in (white without the TAC//PAD, as the compass)
 *
 * None while the AiTR is not drawing (FUNC(isActive)) or with the player's
 * "AiTR LZ / DZ highlight" setting off.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_updateZones
 *
 * Public: No
 */

if (isNull player) exitWith {};

private _list = [];
if (GVAR(zoneHighlight) && {[] call FUNC(isActive)}) then {
    (localNamespace getVariable [QEGVAR(support,zonesSeen), []]) params [["_side", sideUnknown], ["_zones", []]];
    // Kept for the side he was on when it came; another side's is not his.
    if (_side isEqualTo (side group player)) then {_list = _zones};
};

if (_list isNotEqualTo GVAR(zoneSource)) then {
    GVAR(zoneSource) = _list;
    GVAR(zoneCache) = _list apply {
        _x params [["_kind", "", [""]], ["_pos", ORIGIN, [[]]], ["_radius", 0, [0]], ["_callsign", "", [""]]];
        _pos params [["_cx", 0, [0]], ["_cy", 0, [0]]];
        private _ring = [];
        for "_i" from 0 to (ZONE_RING_DOTS - 1) do {
            private _dir = _i * FULL_CIRCLE / ZONE_RING_DOTS;
            _ring pushBack [_cx + _radius * sin _dir, _cy + _radius * cos _dir, 0];
        };
        private _at = ZONE_LABELS findIf {(_x select 0) isEqualTo _kind};
        private _words = if (_at < 0) then {[ZONE_WORD, toUpper _kind]} else {(ZONE_LABELS select _at) select [1, 2]};
        if (_callsign isNotEqualTo "" && count _callsign <= ZONE_CALLSIGN_FITS) then {_words pushBack _callsign};
        [[_cx, _cy, 0], _ring, (_words joinString LABEL_SEPARATOR) + LABEL_SEPARATOR]
    };
};

// The nearest, re-picked as he moves.
private _draw = GVAR(zoneCache);
if (count _draw > ZONE_MAX) then {
    private _byRange = [];
    {
        _byRange pushBack [player distance2D (_x select 0), _forEachIndex];
    } forEach _draw;
    _byRange sort true;
    private _cache = _draw;
    _draw = (_byRange select [0, ZONE_MAX]) apply {_cache select (_x select 1)};
};
GVAR(zoneDraw) = _draw;

// The compass's accent (FUNC(drawCompass)).
GVAR(zoneAccent) = if (isNil QEFUNC(tacpad,theme)) then {COMPASS_WHITE} else {["accent"] call EFUNC(tacpad,theme)};
