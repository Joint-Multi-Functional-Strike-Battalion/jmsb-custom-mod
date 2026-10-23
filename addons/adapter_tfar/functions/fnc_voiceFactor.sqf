#include "script_component.hpp"
/*
 * Author: JMSB
 * RF link quality -> the share of TFAR's normal range a net keeps:
 *
 *   unknown (-1)        1           RF has no word on it: TFAR's own range
 *   quality <= cut      0           cut
 *   cut < quality <= 1  floor + (1 - floor) * (quality - cut) / (1 - cut)
 *
 * cut and floor are the settings (Cut at quality, at most 0.5, and Range at
 * the weakest link).
 *
 * Arguments:
 * 0: Quality 0..1, or -1 for unknown <NUMBER>
 *
 * Return Value:
 * Range factor 0..1 (0 = cut) <NUMBER>
 *
 * Example:
 * [0.6] call jmfsb_adapter_tfar_fnc_voiceFactor
 *
 * Public: No
 */

params [["_quality", QUALITY_UNKNOWN, [0]]];

if (_quality < 0) exitWith {1};

private _cut = GVAR(voiceCut);
if (_quality <= _cut) exitWith {0};

private _floor = GVAR(voiceFloor);
_floor + (1 - _floor) * (((_quality - _cut) / (1 - _cut)) min 1)
