#include "script_component.hpp"
/*
 * Author: YonV
 * A C2 measure type's row from MEASURE_TYPES.
 *
 * Arguments:
 * 0: Type id <STRING>
 *
 * Return Value:
 * [id, label, kind, marker colour, point marker type], [] for no such type <ARRAY>
 *
 * Example:
 * ["phase_line"] call jmfsb_c2_fnc_typeOf
 *
 * Public: No
 */

params [["_type", "", [""]]];

MEASURE_TYPES param [MEASURE_TYPES findIf {(_x # 0) isEqualTo _type}, []]
