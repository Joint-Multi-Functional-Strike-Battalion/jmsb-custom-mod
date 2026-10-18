#include "script_component.hpp"
/*
 * Author: JMSB
 * The power key. Flips the clip-on on or off and says which.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_togglePower
 *
 * Public: Yes
 */

GVAR(powered) = !GVAR(powered);
hintSilent (["ECOTI OFF", "ECOTI ON"] select GVAR(powered));

true
