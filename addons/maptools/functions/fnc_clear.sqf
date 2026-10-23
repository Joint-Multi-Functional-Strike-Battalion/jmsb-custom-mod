#include "script_component.hpp"
/*
 * Author: JMSB
 * Wipes everything the tools drew: ruler, protractor, route, viewshed (and the
 * computation still filling it), and this client's own local MARK markers.
 * The running tool keeps running, onto a clean map.
 *
 * A SHARED MARK IS NOT TAKEN BACK. Once it is on the group channel it is the
 * group's marker, and deleting it from under them is not CLEAR's to do - any
 * of them removes it the ordinary way.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_maptools_fnc_clear
 *
 * Public: Yes
 */

[] call FUNC(viewshedCancel);

GVAR(anchor) = [];
GVAR(ruler) = [];
GVAR(protractor) = [];
GVAR(route) = [];
GVAR(viewshed) = [];
GVAR(vsSeen) = [];
GVAR(vsHidden) = [];

{deleteMarkerLocal _x} forEach GVAR(marks);
GVAR(marks) = [];
