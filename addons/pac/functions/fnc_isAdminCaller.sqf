#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the door check of every PAC admin request (review S5). The caller
 * a request names must be the machine that sent it (a client could pass a
 * real admin's unit), and that machine an admin by the server's own records
 * (jmfsb_common_fnc_senderIsAdmin: #login, the host, the server's admin list
 * with TAC//PAC's admins in it - FUNC(adminsPublish)). Called at the top of
 * the remote-executed function, never inside spawned code, where the sender
 * is no longer known.
 *
 * Arguments:
 * 0: The caller the request names <OBJECT>
 *
 * Return Value:
 * The request may be served <BOOL>
 *
 * Example:
 * if !([_caller] call jmfsb_pac_fnc_isAdminCaller) exitWith {false}
 *
 * Public: No
 */

params [["_caller", objNull, [objNull]]];

!isNull _caller
    && {[_caller] call EFUNC(common,senderIs)}
    && {[] call EFUNC(common,senderIsAdmin)}
