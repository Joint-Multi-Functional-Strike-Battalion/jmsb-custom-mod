#include "script_component.hpp"
/*
 * Author: YonV
 * Builds `admp_authorisedIDs` - who this mission lets into the panel.
 *
 * TWO LISTS, TWO JOBS (user, 2026-09-09: "#defined admins should just be for
 * the cba and the other admin in the description.ext, the pac admins are for
 * accessing the pac").
 *
 *   description.ext   #define ADMINS - the DEBUG CONSOLE and the CBA settings
 *                     whitelist. The engine and CBA read those two arrays out
 *                     of the mission file before any script runs, so that id
 *                     has to be there and it is the only thing it does.
 *
 *   <unit>.admins     WHO MAY OPEN TAC//PAC AND TAC//ADMIN. Edited on the PAC
 *                     admin page or the website, checked by FUNC(isAdmin).
 *
 * This function no longer reads the mission's CfgJmfsbAdmins class: a name in
 * description.ext is not a grant of the admin console. What is left in
 * `admp_authorisedIDs` is the mod's own list and whatever GRANT ADMIN handed
 * out during the mission.
 *
 * Nothing here writes back to the mission.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The uids <ARRAY>
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_adminList
 *
 * Public: Yes
 */

private _ids = [];

// The mod's own list - the uids jmfsb_admin already trusts with the debug
//    console. A mission with no admin list at all still has whoever the mod is
//    set up for, which is what stops a fresh mission locking everybody out of
//    the panel that would fix it.
{
    if (_x isEqualType "" && _x isNotEqualTo "") then {_ids pushBackUnique _x};
} forEach (getArray (configFile >> "enableDebugConsole"));

_ids
