#include "script_component.hpp"
/*
 * Author: YonV
 * The waiting questions changed: the walking view redraws its strip now, not
 * on its next tick (the devices listen to QGVAR(askChanged)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_askChanged
 *
 * Public: No
 */

[QGVAR(askChanged), []] call CBA_fnc_localEvent;
