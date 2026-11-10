#include "script_component.hpp"
/*
 * Author: YonV
 * The JMSB - Jump Aircraft modules on a side (user, 2026-11-02), in placement
 * order - from the published list, so the client's row and the server's card
 * read the same. Any at all: the side's own jump aircraft from the settings
 * is not there (FUNC(asset)).
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Return Value:
 * Module logics <ARRAY>
 *
 * Example:
 * [west] call jmfsb_jumpmaster_fnc_modules
 *
 * Public: No
 */

params [["_side", west, [west]]];

(missionNamespace getVariable [QGVAR(entities), []]) select {
    !isNull _x && {(_x getVariable [QGVAR(side), sideUnknown]) isEqualTo _side}
}
