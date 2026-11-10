#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a unit holds the jmfsb admin flag. One place, because the flag is set
 * by jmfsb_common on #login and BFT must never invent its own idea of who is an
 * admin - a second definition is how the chat gate and the map gate drift apart.
 *
 * Arguments:
 * 0: Unit <OBJECT> (default: player)
 *
 * Return Value:
 * Is admin <BOOL>
 *
 * Example:
 * [] call jmfsb_bft_fnc_isAdmin
 *
 * Public: No
 */

params [["_unit", player, [objNull]]];

_unit getVariable [QEGVAR(common,isAdmin), false]
