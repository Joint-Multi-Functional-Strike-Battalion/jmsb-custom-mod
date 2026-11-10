#include "script_component.hpp"
/*
 * Author: YonV
 * Client: what a support thread's pin draws off its card (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 6.3, build step 8), as marker specs for
 * FUNC(pinMarker):
 *
 *   the card's points   the target (cas; callforfire, cffpolar and cffshift -
 *                       the point the reader worked out), the area
 *                       (onstation), the LZ and pickup (hlz), the pickup
 *                       (extract - no destination, 2026-11-08), the pickup
 *                       (casevac), the DZ (airdrop), the delivery point
 *                       (resupply), the link-up (qrf) - PIN_POINTS, each
 *                       read as the asset's call sign, the word and the
 *                       point's name on the card (HOG TARGET OBJ RAVEN)
 *   the legs            a line from the card's ingress to the first point,
 *                       and from it to the egress, IN / OUT at their ends;
 *                       a lift's flight path instead (PIN_ROUTES, user
 *                       2026-11-02): the LIFT REQUEST's ROUTE from the pickup
 *                       to the LZ and its EGRESS after it, the EXTRACTION's
 *                       EGRESS from the HLZ on the way home - one line
 *                       through the points, each read RTE n / EGR n; the
 *                       EXTRACTION's STATION is a point of its own
 *   danger close        a red ring of the card's danger-close distance (its
 *                       `dangerClose` option, else 300 m CAS, 600 m
 *                       artillery - FUNC(readOrder)) round the target, only
 *                       while a friendly the blue force tracker shows is
 *                       inside it, read DANGER CLOSE n M - FRIENDLY n M
 *
 * Arguments:
 * 0: The order, from FUNC(readOrder) <HASHMAP>
 * 1: The asset's call sign, "" none <STRING>
 * 2: The friendlies <ARRAY of OBJECTs>
 *
 * Return Value:
 * Marker specs <ARRAY>
 *
 * Example:
 * [_order, "HOG", [] call jmfsb_bft_fnc_friendlies] call jmfsb_support_fnc_pinCard
 *
 * Public: No
 */

params [["_order", createHashMap, [createHashMap]], ["_callsign", "", [""]], ["_friends", [], [[]]]];

private _at = PIN_POINTS findIf {(_x select 0) isEqualTo (_order getOrDefault ["kind", ""])};
if (_at < 0) exitWith {[]};

// NO PIN ON TOP OF A MARKER (user, 2026-11-02: "when using a marker with
// support no need to place a marker on top of the marker"): a point that
// sits on a map marker already there - the one it was picked from - is not
// drawn again; its legs and danger-close ring still are. The pin's own
// markers do not count.
private _pinPrefix = QGVAR(pin_);
private _others = (allMapMarkers select {
    (_x find _pinPrefix) isNotEqualTo 0 && {(markerShape _x) isEqualTo PIN_SHAPE_ICON}
}) apply {getMarkerPos _x};

private _specs = [];
private _centre = [];
{
    _x params ["_key", "_icon", "_word", "_nameKey"];
    private _pos = _order getOrDefault [_key, []];
    if (count _pos < 2) then {continue};
    if (_centre isEqualTo []) then {_centre = _pos};
    if ((_others findIf {(_x distance2D _pos) <= PIN_ON_MARKER_M}) >= 0) then {continue};

    private _name = _order getOrDefault [_nameKey, ""];
    if !(_name isEqualType "") then {_name = ""};
    private _text = ([_callsign, _word, _name] select {_x isNotEqualTo ""}) joinString " ";
    _specs pushBack [PIN_ICON, _pos, PIN_COLOUR_INK, _icon, toUpper _text, PIN_ICON_SIZE];
} forEach ((PIN_POINTS select _at) select 1);

if (_centre isEqualTo []) exitWith {_specs};

// THE CARD'S FLIGHT PATH (user, 2026-11-02): a lift's ROUTE and EGRESS points,
// one line through them in order from the point they leave to the point they
// reach, each a dot - RTE 1, EGR 2. A kind that has them draws no IN / OUT.
private _routeAt = PIN_ROUTES findIf {(_x select 0) isEqualTo (_order getOrDefault ["kind", ""])};
if (_routeAt >= 0) then {
    {
        _x params ["_key", "_fromKey", "_toKey", "_word"];
        private _points = (_order getOrDefault [_key, []]) select {_x isEqualType [] && {count _x >= 2}};
        if (_points isEqualTo []) then {continue};
        private _line = [_order getOrDefault [_fromKey, []]] + _points;
        if (_toKey isNotEqualTo "") then {_line pushBack (_order getOrDefault [_toKey, []])};
        _line = _line select {count _x >= 2};
        if (count _line >= 2) then {_specs pushBack [PIN_LINE, _line, PIN_COLOUR_INK]};
        {
            _specs pushBack [PIN_ICON, _x, PIN_COLOUR_INK, PIN_ICON_LEG, format [PIN_ROUTE_TEXT, _word, _forEachIndex + 1], PIN_LEG_SIZE];
        } forEach _points;
    } forEach ((PIN_ROUTES select _routeAt) select 1);
} else {
    {
        _x params ["_key", "_word"];
        private _end = _order getOrDefault [_key, []];
        if (count _end < 2) then {continue};
        _specs pushBack [PIN_LINE, [_end, _centre], PIN_COLOUR_INK];
        _specs pushBack [PIN_ICON, _end, PIN_COLOUR_INK, PIN_ICON_LEG, _word, PIN_LEG_SIZE];
    } forEach PIN_LEGS;
};

// DANGER CLOSE, only while somebody is inside it: a ring nobody is in is the
// card's number, already on the card.
private _target = _order getOrDefault ["target", []];
private _threshold = _order getOrDefault ["dangerClose", 0];
if !(_threshold isEqualType 0) then {_threshold = 0};
if (_threshold <= 0 || count _target < 2) exitWith {_specs};

private _near = (_friends apply {_x distance2D _target}) select {_x < _threshold};
if (_near isEqualTo []) exitWith {_specs};

_specs pushBack [PIN_RING, _target, PIN_COLOUR_ALARM, _threshold, PIN_BRUSH_EDGE, PIN_ALPHA_FULL];
_specs pushBack [
    PIN_ICON, [_target select 0, (_target select 1) + _threshold, 0], PIN_COLOUR_ALARM, PIN_ICON_LABEL,
    format [PIN_DC_TEXT, round _threshold, round selectMin _near], PIN_ICON_SIZE
];

_specs
