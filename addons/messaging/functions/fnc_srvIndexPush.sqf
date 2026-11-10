#include "script_component.hpp"
/*
 * Author: YonV
 * Sends a player every index row they are entitled to. Bodies are not included
 * and are fetched per thread when one is opened.
 *
 * Newest first and capped, because a client that joins four hours in wants the
 * last hour of traffic, not all of it.
 *
 * Server only and never sent to: the client's request goes to
 * FUNC(srvRequestIndex), which checks the sender first (review S7). This is the
 * push the server makes on its own account too - a claim changing a row, the
 * msg.clear test command - for players other than the one who asked.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit] call jmfsb_messaging_fnc_srvIndexPush
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit} || {!isPlayer _unit}) exitWith {};

private _visible = [_unit] call FUNC(srvBoxesFor);
private _rows = [];

// ONE ROW PER THREAD, FILED UNDER THE THREAD'S OWN BOX. Walking the mailboxes
// and stamping each row with the mailbox it was found in gave a player TWO rows
// for their own traffic - one B:HQ from the net, one P:<uid> from their personal
// box - so a reconnect doubled every report they had ever sent, and the reader
// had no way to tell the copies apart. The box a thread lives in is the thread's
// own answer now; a mailbox is only how we found it. See FUNC(srvDeliver).
private _done = [];

{
    private _box = GVAR(boxes) getOrDefault [_x, createHashMap];
    {
        if (_x in _done) then {continue};
        _done pushBack _x;

        private _thread = GVAR(threads) getOrDefault [_x, createHashMap];
        if (_thread isEqualTo createHashMap) then {continue};

        // A thread out of the archive, or one written before the box was
        // recorded, still has to be filed somewhere - its first shared mailbox
        // is the same answer srvDeliver would reach.
        private _boxId = _thread getOrDefault ["box", ""];
        if (_boxId isEqualTo "") then {
            private _threadBoxes = _thread getOrDefault ["boxes", []];
            private _i = _threadBoxes findIf {(_x select [0, 2]) == "B:"};
            _boxId = _threadBoxes param [0 max _i, ""];
        };

        _rows pushBack ([_thread, _boxId, _unit] call FUNC(srvIndexFor));
    } forEach (_box getOrDefault ["threads", []]);
} forEach _visible;

// AND THE CONVERSATIONS HE WAS CALLED INTO. A man tagged into a thread on a net
// he is not a member of is a participant of it - he was pushed the message, he
// may read it and he may answer it - but he cannot see the mailbox it lives in,
// so walking mailboxes alone would lose it the moment he reconnected. Being
// asked for by name is not a thing that should expire on a disconnect.
private _uid = getPlayerUID _unit;
{
    if (_x in _done) then {continue};
    if !(_uid in (_y getOrDefault ["participants", []])) then {continue};

    _done pushBack _x;
    _rows pushBack ([_y, _y getOrDefault ["box", ""], _unit] call FUNC(srvIndexFor));
} forEach GVAR(threads);

// Sorted on a pair of numbers rather than through BIS_fnc_sortBy: the engine's
// own sort is faster, and a sort algorithm passed as a code block hides the fact
// that it depends on _x being injected for it.
private _keyed = [];
{_keyed pushBack [_x get "lastActivity", _forEachIndex]} forEach _rows;
_keyed sort false;
_rows = _keyed apply {_rows # (_x # 1)};

if (count _rows > INDEX_MAX) then {
    _rows resize INDEX_MAX;
};

// Pairs, not [keys, values] - see FUNC(srvDeliver). By remoteExecCall, which
// the client takes only from the server (review S7).
[_rows apply {_x toArray false}] remoteExecCall [QFUNC(cltIndex), _unit];
