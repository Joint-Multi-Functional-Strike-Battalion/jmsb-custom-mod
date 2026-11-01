#include "script_component.hpp"
/*
 * Author: JMSB
 * Posts a notification to other players: everyone, one side, one player, one
 * machine or a list of players. The server works out who is told and sends it
 * by remoteExec to FUNC(notify) on their machines, which takes a remote call
 * only from the server.
 *
 * Review R1: this was the jmfsb_notify_post CBA event, and any client could
 * raise that one to put any text on every screen. On the server this posts
 * (the server's own systems); on a client it goes to FUNC(srvBroadcast),
 * which posts only for an admin by the server's records. A client telling
 * itself something calls FUNC(notify) directly.
 *
 * Arguments:
 * 0: Title <STRING>
 * 1: Text <STRING> (optional, default "")
 * 2: Colour, RGBA <ARRAY> (optional, default ember)
 * 3: Who: sideUnknown for everyone, a side, a player, a machine id, or a list
 *    of players <SIDE, OBJECT, NUMBER or ARRAY> (optional, default sideUnknown)
 * 4: Position the reader's LOG centres on <ARRAY> (optional, default [])
 *
 * Return Value:
 * Sent (server) or forwarded (client) <BOOL>
 *
 * Example:
 * ["Intel", "Signal intercept plotted.", [0.91, 0.65, 0.24, 1], west] call jmfsb_notify_fnc_broadcast
 *
 * Public: Yes
 */

params [
    ["_title", "", [""]],
    ["_text", "", [""]],
    ["_colour", NOTE_DEFAULT, [[]], 4],
    ["_target", sideUnknown, [sideUnknown, objNull, 0, []]],
    ["_pos", [], [[]]]
];

if (_title isEqualTo "" && _text isEqualTo "") exitWith {false};

if (!isServer) exitWith {
    [_title, _text, _colour, _target, _pos] remoteExecCall [QFUNC(srvBroadcast), SERVER_OWNER];
    true
};

// Who: worked out here, from the server's own view of the groups. A side is
// the side of each player's group, as the old receiving filter read it.
private _to = switch (true) do {
    case (_target isEqualType sideUnknown): {
        if (_target isEqualTo sideUnknown) then {
            0
        } else {
            allPlayers select {(side group _x) isEqualTo _target}
        }
    };
    case (_target isEqualType objNull): {[_target] select {!isNull _x}};
    case (_target isEqualType []): {_target select {_x isEqualType objNull && {!isNull _x}}};
    default {_target};
};
if (_to isEqualTo []) exitWith {false};

[_title, _text, _colour, _pos] remoteExecCall [QFUNC(notify), _to];
true
