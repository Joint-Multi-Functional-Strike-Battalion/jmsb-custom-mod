#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether a unit may open the panel - FOR SCREENS ONLY (review S1, 2026-10-31).
 * Everything here can be written by a client: the flag, the published list,
 * the switch. No server door reads this any more; the server decides from its
 * own records (jmfsb_common_fnc_senderIsAdmin / fnc_adminCheck), and the
 * flag and the list a client sees are the server's copies.
 *
 * TWO WAYS IN, AND BOTH ARE DELIBERATE. The panel's own list - the mission's,
 * see FUNC(adminList) - and jmfsb's admin flag, which is what `#login` and the
 * server host already set for the `#jmfsb` command surface. A mod with two
 * different ideas of who an admin is has one idea too many.
 *
 * Arguments:
 * 0: Unit <OBJECT> (default: player)
 *
 * Return Value:
 * Is admin <BOOL>
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_isAdmin
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

if (isNull _unit) exitWith {false};
// The testing switch - see initSettings. Read through a default so a call
// before CBA settings are in is "no", not an undefined variable.
if (missionNamespace getVariable [QGVAR(everyoneAdmin), false]) exitWith {true};
// THE EDITOR / SP HOST is the mission maker testing: getPlayerUID is "" there,
// so no admin list can ever name them. A local, non-multiplayer session is
// trusted (user, 2026-09-05: testing from the editor).
if (!isMultiplayer && {_unit isEqualTo player} && {(getPlayerUID _unit) isEqualTo ""}) exitWith {true};
// TAC//PAC's admin list - a section of the structure the unit keeps in its
// database (or the profile), edited from the PAC page. Guarded: no pac, no list.
private _pacAdmins = (missionNamespace getVariable ["jmfsb_pac_structure", createHashMap]) getOrDefault ["admins", createHashMap];
if ((getPlayerUID _unit) in _pacAdmins) exitWith {true};

if ((missionNamespace getVariable [QGVAR(honourJmfsbAdmin), true]) && {_unit getVariable [QEGVAR(common,isAdmin), false]}) exitWith {true};

(getPlayerUID _unit) in (missionNamespace getVariable ["admp_authorisedIDs", []])
