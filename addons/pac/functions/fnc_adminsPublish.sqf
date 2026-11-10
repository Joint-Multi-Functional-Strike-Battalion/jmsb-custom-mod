#include "script_component.hpp"
/*
 * Author: YonV
 * Server: gives the server's admin list (jmfsb_common_fnc_adminSource) the
 * Steam ids in TAC//PAC's admins section, as the server holds it - after boot
 * and whenever the section or the whole structure changes (review S1/S5). The
 * server's admin checks read only that list, never the structure a client
 * could publish over.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_pac_fnc_adminsPublish
 *
 * Public: No
 */

if (!isServer || {isNil QGVAR(structure)}) exitWith {};

[ADMIN_SOURCE_PAC, keys (GVAR(structure) getOrDefault ["admins", createHashMap])] call EFUNC(common,adminSource);
