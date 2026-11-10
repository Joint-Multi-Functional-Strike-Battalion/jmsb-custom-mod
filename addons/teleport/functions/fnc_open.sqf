#include "script_component.hpp"
/*
 * Author: YonV
 * Opens the teleport menu.
 *
 * A FUNCTION RATHER THAN A CLASS NAME. The mission opened this with
 * createDialog on a literal class, from an ACE interaction, a ZEN module and
 * every point's action - four places that would all have to be found again if
 * the dialog were ever renamed.
 *
 * Arguments: None
 *
 * Return Value:
 * It opened <BOOL>
 *
 * Example:
 * [] call jmfsb_teleport_fnc_open
 *
 * Public: Yes
 */

if (!hasInterface) exitWith {false};

createDialog QGVAR(dialog)
