#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, by remoteExec from GRANT ADMIN (admp_fnc_grantAdminAccess): gives or
 * takes a man's console access for this mission (review S2). The client used
 * to edit admp_authorisedIDs and publish it, so any client could publish a
 * list with its own id. Now only the server changes its list: the sender must
 * be the logged-in admin (#login) or the host, as the button always asked; the
 * grants are a source of the server's list (jmfsb_common_fnc_adminSource),
 * kept in localNamespace. Only a grant made here can be taken back here - the
 * mod's list and TAC//PAC's admins are changed where they live.
 *
 * Arguments:
 * 0: Steam id <STRING>
 * 1: Give (true) or take (false) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [getPlayerUID _man, true] remoteExecCall ["jmfsb_adminpanel_fnc_adminGrant", 2]
 *
 * Public: No
 */

params [["_uid", "", [""]], ["_give", true, [true]]];

if (!isServer || _uid isEqualTo "") exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_admin"];
private _fnc_tell = {
    params ["_text", "_bad"];
    if (isNull _admin) exitWith {INFO_1("adminGrant: %1",_text)};
    ["Admin Panel", _text, [NOTE_DONE, NOTE_FAIL] select _bad] remoteExecCall [QEFUNC(notify,notify), _admin];
};

if (_owner isNotEqualTo ADMIN_SERVER && {(admin _owner) isNotEqualTo ADMIN_LOGGED}) exitWith {
    ["You must be the currently logged in admin to perform this action!", true] call _fnc_tell;
};

private _grants = localNamespace getVariable [QGVAR(grants), []];
private _man = (allPlayers select {(getPlayerUID _x) isEqualTo _uid}) param [0, objNull];
private _name = [_uid, name _man] select !isNull _man;

if (!_give && {!(_uid in _grants)}) exitWith {
    [format ["%1 is an admin by the mod's list or TAC//PAC's admins, not by a grant here - change it there.", _name], true] call _fnc_tell;
};

if (_give) then {
    _grants pushBackUnique _uid;
} else {
    _grants deleteAt (_grants find _uid);
};
localNamespace setVariable [QGVAR(grants), _grants];
[ADMIN_SOURCE_GRANT, _grants] call EFUNC(common,adminSource);
private _did = ["revoked", "granted"] select _give;
INFO_3("adminGrant: %1 %2 by %3",_name,_did,name _admin);

[format [["Removed %1's admin access!", "Granted %1 admin access!"] select _give, _name], false] call _fnc_tell;
if (!isNull _man && _man isNotEqualTo _admin) then {
    ["Admin Panel", format [["%1 revoked your admin access!", "%1 granted you admin access!"] select _give, name _admin], NOTE_INFO] remoteExecCall [QEFUNC(notify,notify), _man];
};
