#include "script_component.hpp"
/*
 * Author: JMSB
 * The key, and the tablet's SETTINGS > DEVICES row: hides the walking view,
 * or shows it again. A side device comes back on the edge it was last on
 * (FUNC(overlaySetEdge)). The choice is kept in the profile
 * (FUNC(overlaySetShown)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Now shown <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_overlayToggle
 *
 * Public: Yes
 */

[!GVAR(overlayShown)] call FUNC(overlaySetShown);

[] call FUNC(overlayTick);

GVAR(overlayShown)
