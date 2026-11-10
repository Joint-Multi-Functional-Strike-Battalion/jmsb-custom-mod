#include "script_component.hpp"
/*
 * Author: YonV
 * The composer's preview of a call for fire to a battery, before SEND (user,
 * 2026-11-02; the range verdict before firing is Tun Firesupport's idea, by
 * Tuntematon / Armafinland) - the "cardPreview" code of provider "fires"
 * (EFUNC(support,cardPreview)). Run on the composing player's machine on a
 * change of the card, never per frame; it reads only what the server
 * published on the module and changes nothing. THE SERVER STAYS THE
 * AUTHORITY: it reads the card again when it is filed (FUNC(srvThread)) and
 * still answers CANTCO.
 *
 * THE SAME READS THE SERVER DECIDES WITH, in its order: busy, rearming, spent
 * and the range (FUNC(reach)); the shell carried; the shape (FUNC(threadShape));
 * each of its points in range (FUNC(inRange)) and clear of friendlies or
 * ticked (EFUNC(support,dangerClose), the card's threshold); the method
 * (FUNC(threadMethod)); the time of flight (FUNC(ballistics)); a TOT
 * (FUNC(threadTot)).
 *
 *   would fire    "IN RANGE 8.4 KM (MIN 2 KM, MAX 24 KM) - TOF 32 S - AREA
 *                 150 M", and "DANGER CLOSE - FRIENDLY 420 M" when a friendly
 *                 is inside the threshold and the card ticks it
 *   would not     "CANTCO - <the server's word>"
 *
 * THE FOOTPRINT, as marker specs for the support core's pinMarker: the target
 * with the battery's call sign; a POINT's scatter - the first salvo's aiming
 * error (FUNC(aimError)) and the dispersion, an ellipse along the line of fire
 * (DISP_DEFLECTION_SHARE across); an AREA's circle; a LINEAR target's line; a
 * CREEPING walk from the point to its end; the danger-close ring while a
 * friendly is inside it. Orange when it would fire, red when not.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: The order, EFUNC(support,readOrder)'s <HASHMAP>
 *
 * Return Value:
 * [would fire, line, marker specs], [] for no battery or no call for fire <ARRAY>
 *
 * Example:
 * ["fires:0", _order] call jmfsb_support_fires_fnc_cardPreview
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_order", createHashMap, [createHashMap]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};
if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY) exitWith {[]};
if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_FIRE) exitWith {[]};

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {[false, format [PREVIEW_CANTCO, WHY_NO_TARGET], []]};

private _fnc_icon = {
    params ["_at", "_colour", "_words"];
    [PREVIEW_ICON, _at, _colour, PREVIEW_ICON_TARGET, format [PREVIEW_LABEL, _callsign, _words], PREVIEW_ICON_SIZE]
};
private _fnc_refuse = {
    params ["_why", ["_specs", []]];
    [false, format [PREVIEW_CANTCO, _why], [[_target, PREVIEW_COLOUR_BAD, _why] call _fnc_icon] + _specs]
};
// An ellipse round a centre, its long axis along the bearing, as a closed line.
private _fnc_ellipse = {
    params ["_centre", "_along", "_across", "_dir"];
    _centre params ["_cx", "_cy"];
    private _ring = [];
    for "_i" from 0 to PREVIEW_ELLIPSE_POINTS do {
        private _t = _i * DEG_FULL / PREVIEW_ELLIPSE_POINTS;
        private _a = _along * (cos _t);
        private _c = _across * (sin _t);
        _ring pushBack [
            _cx + _a * (sin _dir) + _c * (sin (_dir + RIGHT_ANGLE)),
            _cy + _a * (cos _dir) + _c * (cos (_dir + RIGHT_ANGLE)),
            0
        ];
    };
    _ring
};

// BUSY, REARMING, SPENT, OUT OF RANGE - the reach card's words.
([_assetId, _target] call FUNC(reach)) params ["_can", "", "_reachWhy"];
if (!_can) exitWith {[_reachWhy] call _fnc_refuse};

// THE SHELL: the card's when the battery carries it, else its first.
private _ordnance = [_logic] call FUNC(ordnance);
if (_ordnance isEqualTo []) exitWith {[WHY_NO_STORES] call _fnc_refuse};
private _shell = _order getOrDefault ["shell", ""];
private _ordIndex = 0;
if (_shell isNotEqualTo "") then {
    private _kindAt = SHELL_KINDS findIf {(_x select 0) isEqualTo _shell};
    private _kind = "";
    if (_kindAt >= 0) then {_kind = (SHELL_KINDS select _kindAt) select 1};
    _ordIndex = _ordnance findIf {(_x select 2) isEqualTo _kind};
};
if (_ordIndex < 0) exitWith {[format [WHY_NO_STORES_OF, _shell]] call _fnc_refuse};

// THE SHAPE, for the guns the card asks for.
private _gunCount = _logic getVariable [QGVAR(gunCount), 1];
private _gunsWanted = _order getOrDefault ["guns", 0];
private _guns = [_gunCount, _gunsWanted min _gunCount] select (_gunsWanted > 0);
([_logic, _order, _guns] call FUNC(threadShape)) params ["_shapeWhy", ["_aim", []], ["_sheafType", SHEAF_CONVERGED], ["_sheaf", 0], "", ["_length", 0], ["_shapeWords", ""], ["_points", []]];
if (_shapeWhy isNotEqualTo "") exitWith {[_shapeWhy] call _fnc_refuse};

// THE FOOTPRINT, its colour set once the verdict is known.
private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _fire = _origin getDir _aim;
private _footprint = switch (true) do {
    case (_sheafType isEqualTo SHEAF_LINEAR): {[[PREVIEW_LINE, _points select [1, 2]]]};
    case (_sheafType isEqualTo SHEAF_CREEPING && _length > 0): {
        private _end = _points param [1, _aim];
        [[PREVIEW_LINE, [_aim, _end]], [PREVIEW_ICON, _end, PREVIEW_ICON_END, PREVIEW_WALK_END, PREVIEW_END_SIZE]]
    };
    case (_sheaf > 0): {[[PREVIEW_RING, _aim, _sheaf]]};
    default {
        private _along = ([_logic] call FUNC(aimError)) + (_logic getVariable [QGVAR(dispersion), 0]);
        [[PREVIEW_LINE, [_aim, _along, _along * DISP_DEFLECTION_SHARE, _fire] call _fnc_ellipse]]
    };
};
private _fnc_paint = {
    params ["_colour"];
    _footprint apply {
        _x params ["_kind", "_at", ["_a", ""], ["_b", ""], ["_c", PREVIEW_ICON_SIZE]];
        switch (_kind) do {
            case PREVIEW_RING: {[PREVIEW_RING, _at, _colour, _a, PREVIEW_BRUSH, PREVIEW_ALPHA]};
            case PREVIEW_ICON: {[PREVIEW_ICON, _at, _colour, _a, _b, _c]};
            default {[PREVIEW_LINE, _at, _colour]};
        };
    }
};

// EACH POINT OF THE SHAPE in range, and clear of friendlies or ticked.
private _side = _logic getVariable [QGVAR(side), west];
private _pointWhy = "";
private _nearest = -1;
{
    private _range = [_logic, _x] call FUNC(inRange);
    if (_range isNotEqualTo "") exitWith {_pointWhy = toUpper _range};
    private _check = +_order;
    _check set ["target", _x];
    ([_check, _side] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy", ["_near", -1]];
    if (_near >= 0 && (_nearest < 0 || _near < _nearest)) then {_nearest = _near};
    if (!_safe) exitWith {
        _pointWhy = [_unsafeWhy, format [PREVIEW_DC_REFUSED, _unsafeWhy, _near]] select (_near >= 0);
    };
} forEach _points;

// The danger-close ring, while a friendly is inside it.
private _threshold = _order getOrDefault ["dangerClose", 0];
private _dcSpecs = [];
if (_nearest >= 0 && _threshold > 0) then {
    _aim params ["_ax", "_ay"];
    _dcSpecs = [
        [PREVIEW_RING, _aim, PREVIEW_COLOUR_BAD, _threshold, PREVIEW_BRUSH, PREVIEW_ALPHA],
        [PREVIEW_ICON, [_ax, _ay + _threshold, 0], PREVIEW_COLOUR_BAD, PREVIEW_ICON_LABEL, format [PREVIEW_DC, _nearest], PREVIEW_ICON_SIZE]
    ];
};
if (_pointWhy isNotEqualTo "") exitWith {[_pointWhy, ([PREVIEW_COLOUR_BAD] call _fnc_paint) + _dcSpecs] call _fnc_refuse};

([_logic, _order] call FUNC(threadMethod)) params ["_methodWhy"];
if (_methodWhy isNotEqualTo "") exitWith {[_methodWhy, [PREVIEW_COLOUR_BAD] call _fnc_paint] call _fnc_refuse};

// THE TIME OF FLIGHT, and a TOT the battery could not make.
private _dist = _origin distance2D _aim;
private _ball = [_dist, _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV], _logic getVariable [QGVAR(highAngle), true], RISE(_origin,_aim)] call FUNC(ballistics);
private _tof = (_ball param [1, 0]) max VA_DESCENT_TIME;
if ((_order getOrDefault ["control", ""]) isEqualTo CONTROL_TOT) then {
    (_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0]];
    ([_order getOrDefault ["tot", ""], _tof, _respMin] call FUNC(threadTot)) params ["", "", ["_totWhy", ""]];
    _methodWhy = _totWhy;
};
if (_methodWhy isNotEqualTo "") exitWith {[_methodWhy, [PREVIEW_COLOUR_BAD] call _fnc_paint] call _fnc_refuse};

([_logic] call FUNC(gunRanges)) params ["_min", "_max"];
private _tofWords = format [PREVIEW_TOF, round _tof];
private _words = [
    format [PREVIEW_IN_RANGE, toUpper ([_dist] call FUNC(fmtDist)), toUpper ([_min] call FUNC(fmtDist)), toUpper ([_max] call FUNC(fmtDist))],
    _tofWords,
    _shapeWords
];
if (_nearest >= 0) then {_words pushBack format [PREVIEW_DC, _nearest]};

[
    true,
    (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP,
    [[_aim, PREVIEW_COLOUR_OK, _tofWords] call _fnc_icon] + ([PREVIEW_COLOUR_OK] call _fnc_paint) + _dcSpecs
]
