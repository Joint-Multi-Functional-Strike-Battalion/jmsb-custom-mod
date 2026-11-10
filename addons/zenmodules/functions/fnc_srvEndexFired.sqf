#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a player fired during endex (FUNC(endexFired), by remoteExec). The
 * shot is logged, and everyone is told "Hold your fire" once per muzzle.
 *
 * Review R1: the client used to post the warning to every screen itself, and
 * a client's post is now refused. The shooter is the sender, never a name the
 * arguments carry, and nothing is said unless the server's own endex flag is
 * up.
 *
 * Arguments:
 * 0: Weapon <STRING>
 * 1: Muzzle <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_weapon, _muzzle] remoteExecCall ["jmfsb_zenmodules_fnc_srvEndexFired", 2]
 *
 * Public: No
 */

params [["_weapon", "", [""]], ["_muzzle", "", [""]]];

if (!isServer) exitWith {};
if !(localNamespace getVariable [QEGVAR(Mission,Endex), false]) exitWith {};
([] call EFUNC(common,sender)) params ["", "_unit", "_uid"];
if (isNull _unit) exitWith {};

INFO_3("ENDEX","Player %1 have discharge his weapon (%2; %3) during endex.",name _unit,_weapon,_muzzle);

// Once per muzzle, not once per round.
private _last = localNamespace getVariable [QGVAR(endexFiredMuzzle), createHashMap];
if ((_last getOrDefault [_uid, ""]) isEqualTo _muzzle) exitWith {};
_last set [_uid, _muzzle];
localNamespace setVariable [QGVAR(endexFiredMuzzle), _last];

private _rank = [_unit, "USA"] call EFUNC(players,getRank);
["ENDEX", format ["Hold your fire %1 %2!", _rank, name _unit], NOTE_WARN] call JMFSBFUNC(notify,broadcast);
