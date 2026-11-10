#include "..\script_component.hpp"
/*
 * Author: YonV
 * The run's settings in a few words - what the menu, the results and the PAC
 * record show next to the mode.
 *
 * Arguments:
 * 0: Mode <NUMBER>
 * 1: Duration, seconds <NUMBER>
 * 2: Target number <NUMBER>
 * 3: Exposure, seconds <NUMBER>
 * 4: Targets on the range <NUMBER>
 *
 * Return Value:
 * e.g. "60 s, 3 s up" <STRING>
 *
 * Public: No
 */

params [["_mode", MODE_TIMED, [0]], ["_duration", 0, [0]], ["_count", 0, [0]], ["_exposure", 0, [0]], ["_total", 0, [0]]];

switch (_mode) do {
    case MODE_COUNT: {format ["%1 targets, %2 s up", _count, _exposure]};
    case MODE_RAMPAGE: {format ["%1 targets, %2 s limit", _total, _duration]};
    default {format ["%1 s, %2 s up", _duration, _exposure]};
}
