#include "script_component.hpp"
/*
 * Author: YonV
 * APS: the active protection on the vehicle you are in - the system's name,
 * its charges by side as two bars, the RF emitter's state, and the last
 * thing it did. Reads the variables jmfsb_aps publishes on the vehicle, by
 * name, so this tile draws its own absence when that addon is not loaded
 * or the vehicle carries nothing.
 *
 * Arguments:
 * 0: Draw ops, appended to - see FUNC(paint) <ARRAY>
 * 1: Y to start at <NUMBER>
 * 2: Slot width <NUMBER>
 * 3: Slot height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ops, _y, _w, _h] call jmfsb_hud_fnc_widgetAps
 *
 * Public: No
 */

params [["_ops", [], [[]]], ["_y", 0, [0]], ["_w", 0, [0]], ["_h", 0, [0]]];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _base = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * safeZoneH;
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / 5);
private _kw = (_w / (10 * (((safeZoneW / safeZoneH) min 1.2) / 40))) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _pad = PAD * safeZoneW;
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _amber = [0.85, 0.65, 0.15, 1];
private _green = [0.35, 0.8, 0.35, 1];

private _veh = vehicle player;
private _fit = _veh getVariable ["jmfsb_aps_fit", "NONE"];
private _rf = _veh getVariable ["jmfsb_aps_rf", false];
if (_veh == player || {_fit isEqualTo "NONE" && {!_rf}}) exitWith {
    _ops pushBack [HUD_OP_TEXT, [[_pad, _y, _w - 2 * _pad, _rowH], "NO APS", _dim, (0.9 * _k), true]];
};

// the system, named the way the crew names it
private _name = _veh getVariable ["jmfsb_aps_name", "APS"];
_ops pushBack [HUD_OP_TEXT, [[_pad, _y, _w - 2 * _pad, _rowH * 1.2], _name, _ink, (1.15 * _k), true]];
private _row = _y + _rowH * 1.3;

// THE CHARGES, LEFT AND RIGHT, AS TWO BARS - a launcher that is out on one
// side is what the crew has to know, and a number does not show it at a glance
private _max = _veh getVariable ["jmfsb_aps_ammoMax", 0];
if (_fit isNotEqualTo "NONE" && _max > 0) then {
    private _l = _veh getVariable ["jmfsb_aps_ammoL", 0];
    private _r = _veh getVariable ["jmfsb_aps_ammoR", 0];
    private _barW = (_w - 3 * _pad) / 2;
    private _barH = _rowH * 0.45;
    {
        _x params ["_side", "_n", "_x0"];
        private _colour = switch (true) do {
            case (_n <= 0): {_accent};
            case (_n < _max / 2): {_amber};
            default {_green};
        };
        _ops pushBack [HUD_OP_TEXT, [[_x0, _row, _barW, _rowH], format ["%1 %2/%3", _side, _n, _max], _colour, (0.68 * _k), true, "left", true]];
        _ops pushBack [HUD_OP_FILL, [[_x0, _row + _rowH, _barW, _barH], _line]];
        if (_n > 0) then {
            _ops pushBack [HUD_OP_FILL, [[_x0, _row + _rowH, _barW * (_n / _max), _barH], _colour]];
        };
    } forEach [["L", _l, _pad], ["R", _r, _pad * 2 + _barW]];
    _row = _row + _rowH * 1.7;
    // the crew's own hold, set from the map panel
    if (_veh getVariable ["jmfsb_aps_hkHold", false]) then {
        _ops pushBack [HUD_OP_TEXT, [[_pad, _row, _w - 2 * _pad, _rowH], "LAUNCHERS   HOLD", _amber, (0.68 * _k), true, "left", true]];
        _row = _row + _rowH;
    };
};

// THE EMITTER: ready, or counting down its cooldown - the one resource it has
if (_rf) then {
    private _ready = _veh getVariable ["jmfsb_aps_rfReady", 0];
    private _left = _ready - CBA_missionTime;
    private _live = alive _veh && {isEngineOn _veh} && {(crew _veh) isNotEqualTo []};
    private _hold = _veh getVariable ["jmfsb_aps_rfHold", false];
    private _text = switch (true) do {
        case (!_live): {"RF EMITTER   COLD"};
        case (_left > 0): {format ["RF EMITTER   %1s", ceil _left]};
        case (_hold): {"RF EMITTER   HOLD"};
        default {"RF EMITTER   READY"};
    };
    private _colour = switch (true) do {
        case (!_live): {_dim};
        case (_left > 0 || _hold): {_amber};
        default {_green};
    };
    _ops pushBack [HUD_OP_TEXT, [[_pad, _row, _w - 2 * _pad, _rowH], _text, _colour, (0.68 * _k), true, "left", true]];
    _row = _row + _rowH;
};

// THE LAST THING IT DID, for a few seconds - an intercept, a rearm, a burst
private _last = missionNamespace getVariable ["jmfsb_aps_lastEvent", []];
if (_last isNotEqualTo []) then {
    _last params ["_what", "_rel", "_at"];
    if (CBA_missionTime - _at < 8) then {
        private _text = _what;
        if (_rel >= 0) then {
            private _clock = round (_rel / 30) mod 12;
            if (_clock == 0) then {_clock = 12};
            _text = format ["%1  %2 o'clock", _what, _clock];
        };
        _ops pushBack [HUD_OP_TEXT, [[_pad, _row, _w - 2 * _pad, _rowH], _text, _accent, (0.68 * _k), true, "left", true]];
    };
};
