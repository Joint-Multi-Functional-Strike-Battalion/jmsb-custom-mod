#include "script_component.hpp"
/*
 * Author: JMSB
 * Closes the tablet if it is open. The dialog's onUnload does the rest - see
 * FUNC(onUnload) - so ESC and this are the same close.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Was open <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_close
 *
 * Public: Yes
 */

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
if (isNull _display) exitWith {false};

_display closeDisplay 1;
true
