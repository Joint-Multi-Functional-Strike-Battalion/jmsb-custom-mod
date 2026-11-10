#include "script_component.hpp"
/*
 * Author: YonV
 * Client: a message is being filed to asset mailboxes - tell the server each
 * asset's call sign first, so its answers in the thread (RECEIPT at once,
 * then the providers' states) come under the name the sender picked it by,
 * not its id (2026-11-01, DESIGN_SUPPORT_MESSAGING build step 2). TAC//MSG's
 * SEND calls it with the root's addressees before it submits.
 *
 * THE SAME PATH AN ACCEPTED ORDER USES (FUNC(request)): FUNC(srvCallsign) by
 * remoteExec, which the server checks (the sender's own player, the tasking
 * tag gate, a registered kind) and keeps apart from what providers tell it.
 * Sent before the message, so it is on the server before the receipt is
 * filed. Only a name a row gave is sent - never the upper-cased id
 * FUNC(boxName) falls back to.
 *
 * Arguments:
 * 0: Addressees - mailbox ids or bare names; the ones that are not an asset's are passed over <ARRAY of STRINGs>
 *
 * Return Value:
 * Assets whose call sign was sent <NUMBER>
 *
 * Example:
 * [["B:SUPPORT:cas:0", "B:FIRES"]] call jmfsb_support_fnc_mailboxFiled
 *
 * Public: Yes
 */

params [["_boxIds", [], [[]]]];

if (!hasInterface) exitWith {0};

private _head = count SUPPORT_BOX_PREFIX;
private _sent = 0;
{
    if !(_x isEqualType "") then {continue};
    if (([_x] call FUNC(boxName)) isEqualTo "") then {continue};

    private _box = _x;
    if !((_box select [0, 2]) in BOX_PREFIXES) then {
        _box = BOX_PREFIX_SHARED + _box;
    };
    private _assetId = _box select [_head];
    private _callsign = GVAR(boxNames) getOrDefault [_assetId, ""];
    if (_callsign isEqualTo "") then {continue};

    [_assetId, _callsign] remoteExecCall [QFUNC(srvCallsign), SERVER_OWNER];
    _sent = _sent + 1;
} forEach _boxIds;

_sent
