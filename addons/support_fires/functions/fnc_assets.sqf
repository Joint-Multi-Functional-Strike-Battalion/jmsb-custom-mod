#include "script_component.hpp"
/*
 * Author: JMSB
 * Every fires module this side owns, as support-page rows - the "assets" code
 * of provider "fires". Called every two seconds on the viewer's machine while
 * the page is open, so it reads only published variables.
 *
 * NO MODULE, NO ROW. The rows are the placed modules and nothing else.
 *
 * Arguments: None
 *
 * Return Value:
 * Rows <ARRAY>
 *
 * Example:
 * [] call jmfsb_support_fires_fnc_assets
 *
 * Public: No
 */

private _side = side group player;

(GVAR(entities) select {
    !isNull _x && {(_x getVariable [QGVAR(side), sideUnknown]) isEqualTo _side}
}) apply {
    [_x] call FUNC(entityRow)
} select {
    _x isNotEqualTo []
}
