#include "script_component.hpp"
/*
 * Author: JMSB
 * Stops a viewshed that is still filling. What it has drawn so far stays -
 * FUNC(clear) is what wipes it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_maptools_fnc_viewshedCancel
 *
 * Public: No
 */

if (GVAR(vsHandle) >= 0) then {
    [GVAR(vsHandle)] call CBA_fnc_removePerFrameHandler;
};
GVAR(vsHandle) = -1;
