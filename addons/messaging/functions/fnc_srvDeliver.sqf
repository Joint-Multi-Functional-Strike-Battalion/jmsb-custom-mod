#include "script_component.hpp"
/*
 * Author: YonV
 * Files a thread into the mailboxes it was addressed to and pushes the new
 * message to everyone who should see it now.
 *
 * Addressees are only read on the message that opened the thread plus any the
 * sender adds later; a reply inherits the thread's mailboxes, so answering a
 * report cannot quietly narrow who can still read it.
 *
 * THE THREAD LIVES IN ONE BOX AND EVERY ROW SAYS SO. This is the fix for "I
 * send a message to HQ and I cannot see it in HQ", and the previous attempt at
 * it - reordering the wanted list so the personal box came last - did nothing,
 * because it was aimed at the wrong half of the problem.
 *
 * What actually happened: a shared mailbox has no members (see
 * FUNC(srvMembers) - a filing box delivers to nobody, by design), so the only
 * box that ever REACHED the sender was their own personal one, whatever order
 * the list was in. The row they got was therefore stamped P:<uid>, the reader
 * filters the net tabs on B:<net>, and the sender's own traffic was visible on
 * ALL and on no net at all. Everybody else got theirs stamped B:HQ from the
 * shared fallback at the bottom, which is why it looked like the sender
 * specifically was cursed.
 *
 * So the box on the row is no longer "whichever mailbox happened to reach you
 * first". It is the thread's own box - the net it was posted to - for every
 * recipient alike. The personal box still exists and still catches a sender no
 * addressed box reached; it just no longer decides how anything is filed.
 *
 * The ROUTING tick that DEFREP carries is resolved here rather than in the
 * template, because "the command group" is a mission setting and a template is
 * content.
 *
 * Arguments:
 * 0: Sending player <OBJECT>
 * 1: Thread <HASHMAP>
 * 2: Message <HASHMAP>
 * 3: Addressees <ARRAY> - mailbox ids or bare names
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_addressees", [], [[]]]
];

private _boxes = _thread get "boxes";
private _template = [_message get "templateId"] call FUNC(template);

private _wanted = [];
{
    if (_x isEqualType "") then {_wanted pushBack _x};
} forEach _addressees;

// ROUTING: a ticked box on the report means "and the command group too".
private _routingKey = _template getOrDefault ["routing", ""];
if (_routingKey != "" && GVAR(commandGroup) != "") then {
    private _ticked = (createHashMapFromArray (_message get "payload")) getOrDefault [_routingKey, false];
    if (_ticked isEqualType false && _ticked) then {
        _wanted pushBack (format ["G:%1", GVAR(commandGroup)]);
    };
};

// Last, so it only catches a sender no addressed box reached.
_wanted pushBack (format ["P:%1", getPlayerUID _unit]);

{
    ([_x] call FUNC(srvBox)) params ["_boxId", "_box"];
    if (_boxId != "") then {
        _boxes pushBackUnique _boxId;

        private _threads = _box get "threads";
        _threads pushBackUnique (_thread get "id");
        if (count _threads > BOX_THREAD_MAX) then {
            _threads deleteAt 0;
        };
    };
} forEach _wanted;

// --- the thread's own box ---------------------------------------------------
// Decided once, on the root, and kept: a reply must not be able to move a
// conversation onto a different net halfway through. A shared box wins because
// that is the net somebody chose to speak on; a group box is the next best
// answer; the personal box is what is left when a message was addressed to
// nobody but its sender.
if ((_thread getOrDefault ["box", ""]) isEqualTo "") then {
    private _shared = _boxes findIf {(_x select [0, 2]) == "B:"};
    if (_shared < 0) then {
        _shared = _boxes findIf {(_x select [0, 2]) == "G:"};
    };
    if (_shared < 0) then {
        _shared = 0;
    };
    _thread set ["box", _boxes param [_shared, ""]];
};

private _primary = _thread get "box";

// --- who hears it now -------------------------------------------------------
// One push per player, not one per mailbox they happen to share with it - being
// in both the addressed group and the command group is not two messages.
//
// PAIRS, NOT [KEYS, VALUES]. Unary `toArray` on a HashMap gives
// [[all keys], [all values]] - two parallel arrays - and createHashMapFromArray
// wants [[k,v],[k,v],...]. Fed the unary form it reads the first ten keys as ONE
// key/value pair and the ten values as another, so the row arriving on the
// client was {"priority": "boxId", "normal": "P:765..."} and every real field
// was gone. THIS is what the "Type Nothing, expected Number, Bool, Array,
// String" errors were: `_entry get "threadId"` answered nil and the nil went on
// to be used as a HashMap key.
private _messageArray = _message toArray false;

private _seen = [];

// Kept apart from _seen because the quiet pass at the bottom reaches every
// player on the server, and a pin is not for them - see the pin block below.
private _bodySeen = [];

private _fnc_push = {
    params ["_who", ["_body", true]];
    if (_who in _seen) exitWith {};
    _seen pushBack _who;
    if (_body) then {_bodySeen pushBack _who};

    // ONLY THE PEOPLE IT WAS ACTUALLY FOR. The quiet pass below reaches every
    // player on the server, and adding them here would make the whole server a
    // participant of every net thread within one message - which is the list
    // srvThreadFor reads to decide who may reply. Anyone who can read a shared
    // mailbox may already answer into it without being on this list.
    if (_body) then {
        (_thread get "participants") pushBackUnique (getPlayerUID _who);
    };

    private _entry = [_thread, _primary, _who] call FUNC(srvIndexFor);
    // By remoteExecCall, which the client takes only from the server (review
    // S7) - a CBA target event could be raised by any client at anyone.
    [[[], _messageArray] select _body, _entry toArray false] remoteExecCall [QFUNC(cltReceive), _who];
};

{
    {[_x] call _fnc_push} forEach ([_x] call FUNC(srvMembers));
} forEach _boxes;

// --- THE PEOPLE CALLED OUT BY NAME ------------------------------------------
// The tags, resolved now, delivered the loud way. They are FIRST after the
// mailboxes and before the quiet fallback below, because a man named in a
// message must get the message itself and not a silent line in an index he was
// not looking at.
//
// Being pushed the body is also what makes their tablet speak: the alert is
// raised client-side off the tags on the message, so a tagged man is told even
// when the traffic is routine and the net is one he never reads. See
// FUNC(cltReceive).
//
// This is ALSO the permission. srvThreadFor lets a participant reply, and
// _fnc_push adds every recipient to the thread's participants - so tagging
// NOMAD into a C2 conversation is what allows Nomad to answer in it, without
// the thread leaving C2 or being copied anywhere.
{[_x] call _fnc_push} forEach ([_message getOrDefault ["tags", []]] call FUNC(srvTagged));

// A shared mailbox delivers to nobody, so a report filed only there would never
// show up until the reader next reconnected. They get the one row instead of a
// rebuilt index: a shared box is readable by everybody, and rebuilding forty
// indexes per filed report is how a message system becomes the thing that
// stutters the server.
//
// EVERY shared box, not just the first. A report filed to HQ and to Fires used
// to reach only the readers of whichever of the two was found first - which,
// with one box on the thread now, would have been a thread visible on a net
// that half the people on it never heard about.
if (_boxes findIf {(_x select [0, 2]) == "B:"} >= 0) then {
    {[_x, false] call _fnc_push} forEach allPlayers;
};

// --- the pin ----------------------------------------------------------------
// A THREAD THE SENDER PINNED MARKS THE MAP, ONCE, FOR THE PEOPLE IT REACHED.
// Set by FUNC(srvThreadFor) when the composer sent a position beside the
// payload; a template's own `anchor` does not set it, so the deck's reports go
// on anchoring without marking.
//
// _bodySeen, NOT _seen AND NOT allPlayers. The quiet pass above hands an index
// row to everybody on the server so a shared mailbox is readable, and marking
// all of them would put a friendly tasking on the other side's map - the same
// reason FUNC(srvTic) targets its own side rather than creating a global
// marker. These are the people the message was actually pushed to.
//
// ONCE: the guard is the marker name already being on the thread, so a reply
// does not drop a second pin on top of the first.
if ((_thread getOrDefault ["pinned", false]) && {(_thread getOrDefault ["marker", ""]) isEqualTo ""}) then {
    private _pos = _thread getOrDefault ["anchorPos", []];
    if (_pos isNotEqualTo []) then {
        private _name = format [QGVAR(pin_%1), _thread get "id"];
        private _label = _thread getOrDefault ["subject", ""];
        if (_label isEqualTo "") then {_label = "MESSAGE"};

        {
            if (isNull _x) then {continue};
            [_name, _pos, _label] remoteExecCall [QFUNC(cltMarker), _x];
        } forEach _bodySeen;

        // The thread carries its marker name so FUNC(srvSweep) takes it away
        // with the thread. A marker nobody removes is how a map ends up
        // wallpapered in old traffic.
        _thread set ["marker", _name];
    };
};
