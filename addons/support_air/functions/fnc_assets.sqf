#include "script_component.hpp"
/*
 * Author: JMSB
 * Every air module this viewer's side owns, as TAC//SUPPORT rows - the
 * "assets" code of provider "air" (addons/support/README.md). Called on the
 * viewer's machine every two seconds while the page is open, so it only reads
 * what the server already published on each logic.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Rows <ARRAY>
 *
 * Example:
 * call jmfsb_support_air_fnc_assets
 *
 * Public: No
 */

private _side = side group player;

((missionNamespace getVariable [QGVAR(entities), []]) select {
    !isNull _x && {(_x getVariable [QGVAR(side), sideUnknown]) isEqualTo _side}
}) apply {
    [_x] call FUNC(entityRow)
} select {
    _x isNotEqualTo []
}
