#include "script_component.hpp"
/*
 * Author: YonV
 * A message arrived for this player. Updates the index row, appends to the
 * thread cache if the thread is open, and tells the player once.
 *
 * The notification is the whole point of the seam: a warning from messaging has
 * to look like a warning from anything else in the mod, so it goes through
 * FUNC(notify) and never touches the widget directly.
 *
 * An empty message is the quiet form: something was filed to a shared mailbox
 * this player can read but was not addressed to them. The row is updated and
 * nothing is said, because a filing cabinet does not ring.
 *
 * Sent by remoteExecCall from the server (FUNC(srvDeliver)), and taken only
 * from the server (review S7): otherwise any client could put a message from
 * anyone in another player's reader.
 *
 * Arguments:
 * 0: Message <ARRAY> - array form of a message HashMap, [] for a row-only update
 * 1: Index entry <ARRAY> - array form of an index HashMap
 *
 * Return Value:
 * None
 *
 * Example:
 * [_messageArray, _entryArray] remoteExecCall ["jmfsb_messaging_fnc_cltReceive", _unit]
 *
 * Public: No
 */

params [["_messageArray", [], [[]]], ["_entryArray", [], [[]]]];

if (!hasInterface || {_entryArray isEqualTo []}) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

// READ THROUGH THE NAMESPACE, NOT OFF THE VARIABLE. Both containers are
// preInit's, and both were still arriving as Nothing here on a live client -
// twice over, because an `isNil` guard in front of them did not stop it either.
// Whatever leaves them undefined on that machine, `getVariable` with a default
// cannot throw: it answers the default and this function carries on delivering
// the message, which is the only thing the player cares about.
//
// They are written back at the end of each block, so a client that started with
// nothing ends up holding a real index and a real cache rather than editing a
// copy that is thrown away.
private _index = missionNamespace getVariable [QGVAR(index), []];
private _cache = missionNamespace getVariable [QGVAR(cache), createHashMap];

private _quiet = _messageArray isEqualTo [];
private _message = createHashMapFromArray _messageArray;
private _entry = createHashMapFromArray _entryArray;

// THE KEY, NOT THE MAP. The type list in the "Type Nothing, expected Number,
// Bool, Array, String, Namespace..." error is the list of things a HashMap KEY
// may be - it was a nil threadId being used as one, not a hashmap that was
// missing.
//
// This guard is what found the real cause, by writing the row down: unary
// `toArray` on a HashMap gives [[keys], [values]], not pairs, so
// createHashMapFromArray was reading the ten keys as one key/value pair and the
// ten values as another. Fixed at the sending end - see FUNC(srvDeliver). The
// guard stays as the seatbelt: a malformed row is dropped with its contents
// logged, rather than throwing on every delivery for the rest of the mission.
private _threadId = _entry getOrDefault ["threadId", ""];
if (!(_threadId isEqualType "") || _threadId isEqualTo "") exitWith {
    diag_log text format ["[jmfsb_messaging] malformed index row, no threadId: %1", _entryArray];
};

// Replace the row rather than push a second one - a thread has exactly one row
// per mailbox and the server has just sent the current version of it.
// getOrDefault, and a type check first: one malformed row already in the index
// made this findIf throw on every later delivery - the guard above protects
// the row ARRIVING, not the ones already filed.
private _i = _index findIf {
    _x isEqualType createHashMap
    && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
    && {(_x getOrDefault ["boxId", ""]) isEqualTo (_entry getOrDefault ["boxId", ""])}
};
if (_i < 0) then {
    _index pushBack _entry;
} else {
    _index set [_i, _entry];
};

if (count _index > INDEX_MAX) then {
    private _keyed = [];
    {_keyed pushBack [_x get "lastActivity", _forEachIndex]} forEach _index;
    _keyed sort false;

    private _sorted = _keyed apply {_index # (_x # 1)};
    _sorted resize INDEX_MAX;
    _index = _sorted;
};

missionNamespace setVariable [QGVAR(index), _index];
missionNamespace setVariable [QGVAR(cache), _cache];

if (_quiet) exitWith {
    // A quiet row can be about a thread this client has OPEN. Bodies are not
    // pushed to shared-box readers by design - see srvDeliver - so the cached
    // copy sat stale under the reader while the row's unread count climbed,
    // and nothing ever asked again: the cache is only refetched when it is
    // empty. A thread that is cached is a thread somebody opened, so ask for
    // it again; cltThread replaces the cache and wakes whatever is watching.
    if (_threadId in _cache) then {
        [player, _threadId] remoteExecCall [QFUNC(srvRequestThread), SERVER_OWNER];
    };
    [QGVAR(indexRefreshed), []] call CBA_fnc_localEvent;
};

private _cached = _cache getOrDefault [_threadId, []];
if (_cached isNotEqualTo []) then {
    (_cached # 1) pushBack _message;

    // THE CACHED HEADER MOVES WITH THE TRAFFIC. A reply that carried a
    // transition changed the thread's status on the server, and the reply
    // buttons are computed off the cached copy - left alone, a thread a WILCO
    // had moved to ACCEPTED still read ISSUED here, and the rail kept offering
    // replies the server now refuses. The index row was built fresh by the
    // server for exactly this delivery, so it is the truth about the header.
    private _cachedThread = _cached # 0;
    {
        _cachedThread set [_x, _entry getOrDefault [_x, _cachedThread getOrDefault [_x, ""]]];
    } forEach ["status", "priority", "claimedBy", "lastActivity", "subject"];
    _cachedThread set ["closed", (_entry getOrDefault ["status", ""]) in ["CLOSED", "ABORTED"]];
};

// The screens' hooks (FUNC(onReceive)), not a CBA event: any client could
// raise that one on every machine and fake a FLASH banner (review S7).
{
    [_message, _entry] call _x;
} forEach (localNamespace getVariable [QGVAR(receiveHooks), []]);

private _template = [_message get "templateId"] call FUNC(template);
private _title = format ["%1 %2", _template getOrDefault ["short", "MSG"], _message get "fromCallsign"];
private _priority = _message getOrDefault ["priority", "normal"];

// CALLED OUT BY NAME. The tags are asked of THIS player with the same rule the
// server used to decide to send it here at all - see FUNC(tagMatch) - so a man
// tagged into a conversation is told loudly whatever the traffic's own urgency
// was, and the tag that reached him is on the notification rather than left for
// him to work out by opening it.
//
// This is what a tag is FOR. Without it a tag is a decoration on a line in an
// index nobody was looking at.
private _tags = _message getOrDefault ["tags", []];
private _mine = [];
if (_tags isEqualType []) then {
    _mine = _tags select {_x isEqualType "" && {[player, _x] call FUNC(tagMatch)}};
};

// ONE TAG ON THE BANNER, not every tag that happened to name him (user,
// 2026-09-03: "do not double notify"). A lead carries isLeader, isISR and
// isJFO, so three of the six job chips name the same man and the title read
// like three notifications stacked. FUNC(tagCallout) picks the most specific -
// his name, then his squad, then his platoon, then a job - because that is the
// one telling him something he did not already know.
//
// The other tags are untouched: they still reached everyone they name and are
// still on the message. This is the banner only.
if (_mine isNotEqualTo []) then {
    _title = format ["%1 - %2", [player, _mine] call FUNC(tagCallout), _title];
    _priority = "high";
};

// YOUR OWN TRAFFIC DOES NOT RING BACK. A message this player wrote arrives
// already read by them - srvSubmit's mark - so it is told apart from the
// msg.* test traffic, which files under another call sign UNREAD precisely so
// the notification path can be watched working.
if ((getPlayerUID player) in (_message getOrDefault ["readBy", []])) exitWith {};

// THE SUBSCRIPTION GATE. A muted net or thread badges - the row and its
// unread count have already moved above - and only FLASH traffic and being
// called out by name break through, which is the handoff's mute rule.
if (([_entry getOrDefault ["boxId", ""], _threadId] call FUNC(netLevel)) > 0
    && _priority != "high") exitWith {};

[_title, _entry get "subject", _priority] call FUNC(notify);
