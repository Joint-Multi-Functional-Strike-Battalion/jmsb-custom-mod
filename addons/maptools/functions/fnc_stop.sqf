#include "script_component.hpp"
/*
 * Author: JMSB
 * Stops the running tool. The map stops answering to it; everything it drew
 * stays where it is until CLEAR.
 *
 * Two things in flight are settled rather than left hanging: a ruler waiting
 * for its second point is dropped, and a protractor arm still following the
 * cursor is locked where it last pointed (or dropped with no cursor to point
 * at), so what is left on the map is a reading rather than a half-gesture.
 * A viewshed still filling carries on - it was asked for and is coming.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_maptools_fnc_stop
 *
 * Public: Yes
 */

GVAR(tool) = "";
GVAR(anchor) = [];
uiNamespace setVariable [QGVAR(pressMap), controlNull];

GVAR(protractor) params [["_centre", []], ["_arm", -1]];
if (_centre isNotEqualTo [] && _arm < 0) then {
    GVAR(protractor) = if (GVAR(cursor) isEqualTo []) then {[]} else {[_centre, _centre getDir GVAR(cursor)]};
};
