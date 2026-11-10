#include "script_component.hpp"
/*
 * Author: YonV
 * Builds one index row - what a client is told about a thread before it opens
 * it. Deliberately small: a subject, a state and an unread count, no bodies.
 * A client that has been connected all evening still holds only this.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: Box id the row is filed under <STRING>
 * 2: Player the count is for <OBJECT>
 *
 * Return Value:
 * Index entry <HASHMAP>
 *
 * Example:
 * private _row = [_thread, "B:HQ", _unit] call jmfsb_messaging_fnc_srvIndexFor
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]], ["_boxId", "", [""]], ["_unit", objNull, [objNull]]];

private _uid = if (isNull _unit) then {""} else {getPlayerUID _unit};

private _unread = 0;
{
    private _message = GVAR(messages) getOrDefault [_x, createHashMap];
    if (_message isNotEqualTo createHashMap && {!(_uid in (_message get "readBy"))}) then {
        _unread = _unread + 1;
    };
} forEach (_thread get "messages");

// templateId and the reply count ride along because a reader row shows the
// report's type and how much traffic is on it - "9-LINE ... 6 REPLIES" - and
// both are already here. Fetching a thread to find out what kind of thread it is
// would defeat the point of an index.
// getOrDefault, NOT get, ON EVERY FIELD. `get` answers nil for a key a thread
// happens not to carry - an older thread out of the archive, one written by a
// build that had one field fewer - and a nil value has no business travelling.
// A row with a default in it is a row; a row with a hole in it is nonsense.
//
// This is NOT what caused the "Type Nothing, expected Number, Bool, Array,
// String" errors, though it was read that way for two builds. That was the
// transport: unary `toArray` on a HashMap gives [[keys], [values]] and
// createHashMapFromArray wants pairs, so every field on every row was lost in
// flight - see FUNC(srvDeliver). The hardening here is still right, and it is
// not the fix.
//
// THE ANCHOR RIDES ALONG TOO (2026-11-01, TAC//SUPPORT v2 step 4): the support
// board's IN FLIGHT rail names where each mission is and files its BDA on that
// point, from the index alone. The subject already carries the same grid, so
// the row tells nobody anything new.
createHashMapFromArray [
    ["threadId", _thread getOrDefault ["id", ""]],
    ["boxId", _boxId],
    ["subject", _thread getOrDefault ["subject", ""]],
    ["status", _thread getOrDefault ["status", "OPEN"]],
    ["priority", _thread getOrDefault ["priority", "normal"]],
    ["templateId", _thread getOrDefault ["rootTemplateId", ""]],
    ["replies", (count (_thread getOrDefault ["messages", []])) - 1 max 0],
    ["claimedBy", _thread getOrDefault ["claimedBy", ""]],
    ["lastActivity", _thread getOrDefault ["lastActivity", 0]],
    ["anchorPos", _thread getOrDefault ["anchorPos", []]],
    ["unread", _unread]
]
