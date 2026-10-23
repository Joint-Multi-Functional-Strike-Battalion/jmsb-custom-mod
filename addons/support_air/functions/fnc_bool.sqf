#include "script_component.hpp"
/*
 * Author: JMSB
 * An Eden checkbox value as a BOOL. Eden hands a checkbox over as a BOOL, a
 * NUMBER or a STRING depending on where it was saved from; every one of
 * them means the same thing to a module.
 *
 * Arguments:
 * 0: The value <BOOL, NUMBER or STRING>
 *
 * Return Value:
 * Ticked <BOOL>
 *
 * Example:
 * [_logic getVariable ["allowStatic", true]] call jmfsb_support_air_fnc_bool
 *
 * Public: No
 */

params [["_v", true, [true, 0, ""]]];

switch (true) do {
    case (_v isEqualType true): {_v};
    case (_v isEqualType 0): {_v != 0};
    default {(toLower _v) in ["true", "1"]};
}
