#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a client asks to post a notification to other players
 * (FUNC(broadcast) on a client - the admin panel's messages). Posted only when
 * the sender is an admin by the server's records or a headless client
 * (review R1: the
 * jmfsb_notify_post CBA event it replaced let any client put any text on
 * every screen).
 *
 * Arguments:
 * 0: Title <STRING>
 * 1: Text <STRING>
 * 2: Colour, RGBA <ARRAY>
 * 3: Who, as FUNC(broadcast) takes it <SIDE, OBJECT, NUMBER or ARRAY>
 * 4: Position <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Admin Panel", "Healed.", _colour, _man, []] remoteExecCall ["jmfsb_notify_fnc_srvBroadcast", 2]
 *
 * Public: No
 */

params [
    ["_title", "", [""]],
    ["_text", "", [""]],
    ["_colour", NOTE_DEFAULT, [[]], 4],
    ["_target", sideUnknown, [sideUnknown, objNull, 0, []]],
    ["_pos", [], [[]]]
];

if (!isServer) exitWith {};
// A headless client runs the server's own systems, so it passes too.
private _isHeadless = ((entities "HeadlessClient_F") findIf {(owner _x) isEqualTo remoteExecutedOwner}) > -1;
if (!_isHeadless && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_1("srvBroadcast: refused - machine %1 is neither an admin nor a headless client",remoteExecutedOwner);
};

[_title, _text, _colour, _target, _pos] call FUNC(broadcast);
