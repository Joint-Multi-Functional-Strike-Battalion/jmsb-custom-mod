#include "script_component.hpp"
/*
 * Author: YonV
 * A range as an AiTR label reads it: whole metres, past LABEL_KM kilometres to
 * a tenth - 240 m, 1.2 km. The boxes' labels (FUNC(labelText)) and the LZ / DZ
 * labels (FUNC(drawZones), user 2026-11-02) read alike.
 *
 * Arguments:
 * 0: Range, metres <NUMBER>
 *
 * Return Value:
 * Range text <STRING>
 *
 * Example:
 * [1240] call jmfsb_ecoti_fnc_rangeText
 *
 * Public: No
 */

params [["_dist", 0, [0]]];

if (_dist < LABEL_KM) exitWith {format ["%1 m", round _dist]};
format ["%1 km", (round (_dist / LABEL_KM_TENTH)) / TENTHS]
