#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_adminLogAdd

Description:
    A log line for something an admin did on THEIR machine - a kick, a ban
    - relayed to the server's log. Admin-checked like every door; the
    caller is who the line is written against, never who they claim.

Parameters:
    0: Caller <OBJECT>
    1: Type <STRING>
    2: Target uid <STRING>
    3: Detail <STRING>

Returns:
    The log id, "" when refused <STRING>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_caller", objNull, [objNull]], ["_type", "", [""]], ["_targetUid", "", [""]], ["_detail", "", [""]]];

if (!isServer) exitWith {""};
if (isNull _caller || {!([_caller] call FUNC(isAdminCaller))}) exitWith {""};

private _id = [getPlayerUID _caller, name _caller, _type, _targetUid, _detail] call FUNC(logAction);
[] call FUNC(storeSave);

_id
