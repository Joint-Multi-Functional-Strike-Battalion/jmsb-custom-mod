#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the Zeus "Drop Patrol Base Kits" module's request
 * (FUNC(addZeusModule)), by remoteExec (review S7). Taken only from an admin
 * by the server's records or a player who holds a curator module. The number
 * of kits is the server's own "Kits required" setting and the Zeus told is
 * the sender - neither is read from the request.
 *
 * Arguments:
 * 0: Position ATL <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_pos] remoteExecCall ["jmfsb_patrol_base_fnc_dropKits", 2]
 *
 * Public: No
 */

params [["_pos", [], [[]]]];

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_who"];
if (!([] call EFUNC(common,senderIsAdmin)) && {isNull getAssignedCuratorLogic _who}) exitWith {
    WARNING_1("dropKits: refused - machine %1 is no admin and no Zeus",_owner);
};

private _n = missionNamespace getVariable [QGVAR(kitCount), 4];
private _made = [_pos, _n] call FUNC(spawnKits);
INFO_3("zeus drop: %1 of %2 kit(s) created at %3",count _made,_n,mapGridPosition _pos);

if (isNull _who) exitWith {};
private _msg = if (_made isEqualTo []) then {
    "No kits could be placed there."
} else {
    format ["%1 Patrol Base Kit(s) dropped.", count _made]
};
private _col = [NOTE_DONE, NOTE_FAIL] select (_made isEqualTo []);
["Patrol Base", _msg, _col] remoteExecCall [QEFUNC(notify,notify), _who];
