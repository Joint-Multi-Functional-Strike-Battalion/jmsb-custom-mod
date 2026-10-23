#include "script_component.hpp"
/*
 * Author: JMSB
 * The landing signal a transport is looking for round its LZ: the nearest
 * smoke, IR strobe or flare of the kind the requester asked for (any of them
 * for ANY) inside SIGNAL_RADIUS of the point. Simplex has the requester
 * confirm one off a list; here the crew takes the nearest, the way the CAS
 * terminal search takes the nearest smoke - a man under fire marks his LZ,
 * he does not then pick it out of a menu.
 *
 * Arguments:
 * 0: The LZ, ATL <ARRAY>
 * 1: SIGNAL_ANY, SIGNAL_SMOKE, SIGNAL_IR or SIGNAL_FLARE <NUMBER>
 *
 * Return Value:
 * Where the signal is, [x, y, 0], or [] when none is seen <ARRAY>
 *
 * Example:
 * [_lz, 2] call jmfsb_support_air_fnc_findSignal
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_kind", SIGNAL_NONE, [0]]];

if (_pos isEqualTo []) exitWith {[]};

private _classes = switch (_kind) do {
    case SIGNAL_SMOKE: {SIGNAL_SMOKE_CLASSES};
    case SIGNAL_IR: {SIGNAL_IR_CLASSES};
    case SIGNAL_FLARE: {SIGNAL_FLARE_CLASSES};
    case SIGNAL_ANY: {SIGNAL_SMOKE_CLASSES + SIGNAL_IR_CLASSES + SIGNAL_FLARE_CLASSES};
    default {[]};
};
if (_classes isEqualTo []) exitWith {[]};

private _seen = nearestObjects [_pos, _classes, SIGNAL_RADIUS];
if (_seen isEqualTo []) exitWith {[]};

(getPosATL (_seen select 0)) params ["_x0", "_y0"];
[_x0, _y0, 0]
