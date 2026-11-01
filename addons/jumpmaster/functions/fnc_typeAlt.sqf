#include "script_component.hpp"
/*
 * Author: JMSB
 * The altitude a jump type is flown at, metres over the ground: the HALO /
 * HAHO setting for the freefall types, the static line's for the rest.
 *
 * Arguments:
 * 0: Jump type <STRING>
 *
 * Return Value:
 * Altitude, m <NUMBER>
 *
 * Example:
 * ["STATIC"] call jmfsb_jumpmaster_fnc_typeAlt
 *
 * Public: No
 */

params [["_type", TYPE_HALO, [""]]];

[GVAR(staticAltitude), GVAR(haloAltitude)] select (_type in FREEFALL_TYPES)
