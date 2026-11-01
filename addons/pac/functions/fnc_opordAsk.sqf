#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_opordAsk

Description:
    Decides whether the player who just spawned should be the one to post
    the current OPORD to C2 messaging, and tells them to if so. Server only;
    asked by every player's machine on spawn (FUNC(applyOnClient)).

    THE SERVER CANNOT POST. Messaging accepts a message only from a live
    player - srvSubmit checks isPlayer, and rightly, because a message with
    no sender has no mailbox and no call sign. So the OPORD goes up through
    the normal path, from the first ADMIN to spawn, once per mission. An
    admin, because that is who HQ is; once, because the second admin does
    not need to post it again.

    NOTHING TO POST IS THE COMMON CASE: no currentOpord, no messaging
    addon, or already posted.

    POSTED ON CONFIRMATION (review L1). The flag is set when the asked
    admin's machine says the message went out (FUNC(opordPost) calls back
    with arg 1 true), not when it is asked - an admin who never posts (no
    link, left at once) used to leave the OPORD unposted for the mission.
    While one admin is asked, nobody else is, for PAC_OPORD_ASK_WAIT seconds.

Parameters:
    0: The unit <OBJECT>
    1: Posted - the asked admin reporting it went out <BOOL> (optional, default false)

Returns:
    Whether this unit was told to post <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]], ["_posted", false, [false]]];

if (!isServer || isNull _unit) exitWith {false};
if (GVAR(opordPosted)) exitWith {false};
if ((GVAR(settings) getOrDefault ["currentOpord", ""]) isEqualTo "") exitWith {false};
if (isNil "jmfsb_messaging_fnc_submit") exitWith {false};
if !([_unit] call FUNC(isAdminCaller)) exitWith {false};

if (_posted) exitWith {
    GVAR(opordPosted) = true;
    INFO_1("%1 posted the OPORD",name _unit);
    false
};

if (time < GVAR(opordAskedAt) + PAC_OPORD_ASK_WAIT) exitWith {false};
GVAR(opordAskedAt) = time;
[] remoteExec [QFUNC(opordPost), owner _unit];

INFO_1("%1 asked to post the OPORD",name _unit);
true
