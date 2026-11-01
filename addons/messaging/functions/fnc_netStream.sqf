#include "script_component.hpp"
/*
 * Author: JMSB
 * Everything filed in one net, as ONE conversation in time order.
 *
 * A NET IS A CONVERSATION, NOT A FOLDER. It was a filter: picking HQ narrowed a
 * list of separate threads and you clicked one to read it, so a message sent to
 * HQ was two clicks from being visible in HQ. A radio net does not work like
 * that - everything said on it is said in order, and a report is a thing said on
 * it rather than a folder hung off it.
 *
 * THE REPORT'S STATE TRAVELS WITH THE MESSAGE. Each entry carries the thread it
 * came from, so a CASEVAC line can still show OPEN or CLAIMED without the reader
 * having to go and look it up - and without the player having to leave the net
 * to see it.
 *
 * WHAT IS NOT CACHED IS ASKED FOR, ONCE. The index holds summaries, not bodies;
 * the bodies arrive per thread. Anything missing is requested here and the count
 * is handed back, so the reader can say it is still fetching rather than drawing
 * a conversation with holes in it.
 *
 * Arguments:
 * 0: Box id, e.g. "B:HQ". "" for every box this player can see <STRING>
 *
 * Return Value:
 * 0: [[message <HASHMAP>, thread <HASHMAP>], ...] oldest first <ARRAY>
 * 1: Threads still being fetched <NUMBER>
 *
 * Example:
 * (["B:HQ"] call jmfsb_messaging_fnc_netStream) params ["_stream", "_pending"]
 *
 * Public: Yes
 */

params [["_boxId", "", [""]]];

private _index = missionNamespace getVariable [QGVAR(index), []];
private _cache = missionNamespace getVariable [QGVAR(cache), createHashMap];

private _rows = _index select {
    _x isEqualType createHashMap
    && {_boxId isEqualTo "" || {(_x getOrDefault ["boxId", ""]) isEqualTo _boxId}}
};

// ASKED FOR ONCE PER DRAW AT MOST. The reader redraws on every arriving message,
// and a request per thread per redraw would be a request storm the moment a net
// got busy.
private _asked = missionNamespace getVariable [QGVAR(asked), []];

private _keyed = [];
private _pending = 0;

{
    private _threadId = _x getOrDefault ["threadId", ""];
    if !(_threadId isEqualType "") then {continue};
    if (_threadId isEqualTo "") then {continue};

    private _cached = _cache getOrDefault [_threadId, []];
    if (_cached isEqualTo []) then {
        _pending = _pending + 1;
        if !(_threadId in _asked) then {
            _asked pushBack _threadId;
            [player, _threadId] remoteExecCall [QFUNC(srvRequestThread), SERVER_OWNER];
        };
        continue;
    };

    _cached params ["_thread", ["_messages", []]];
    {
        if (_x isEqualType createHashMap) then {
            // Time first, then the sequence within the thread: two messages a
            // frame apart carry the same clock and would otherwise sort at
            // random - which on a conversation is a conversation out of order.
            _keyed pushBack [
                (_x getOrDefault ["sentTime", 0]) * 1000 + (_x getOrDefault ["seq", 0]),
                [_x, _thread]
            ];
        };
    } forEach _messages;
} forEach _rows;

GVAR(asked) = _asked;

_keyed sort true;

[_keyed apply {_x # 1}, _pending]
