#include "script_component.hpp"
/*
 * Author: YonV
 * Every CAS module this side owns, as support-page rows.
 *
 * REGISTERED AS A PROVIDER OF THE SUPPORT CORE (addons/support), the "assets"
 * code of provider "cas". The core merges every provider's rows for the page,
 * so the page never learns this addon's name.
 *
 * SIDE IS THE VIEWER'S. A support page is drawn for the man looking at it, and
 * he may not task another side's aircraft.
 *
 * Arguments: None
 *
 * Return Value:
 * Rows <ARRAY>
 *
 * Public: No
 */

private _side = side group player;

// The last drone gone (the respawn count, user 2026-11-02): off the list.
(GVAR(entities) select {
    !isNull _x && {(_x getVariable [QGVAR(side), sideUnknown]) isEqualTo _side} && {!(_x getVariable [QGVAR(gone), false])}
}) apply {
    [_x] call FUNC(entityRow)
} select {
    _x isNotEqualTo []
}
