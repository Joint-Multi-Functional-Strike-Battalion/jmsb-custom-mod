#include "script_component.hpp"
/*
 * Author: YonV
 * Sends a message. This is the only entry point a caller needs: it validates
 * locally so the player is told what is wrong before anything leaves the
 * machine, then hands it to the server, which validates again and decides.
 *
 * Addressees are mailbox ids. Three forms are understood and anything else is
 * treated as a shared mailbox name:
 *   P:<uid>       one player
 *   G:<groupId>   every player in that group, e.g. G:Alpha 1-2
 *   B:<name>      a shared mailbox, e.g. B:HQ
 *
 * TAGS ARE NOT ADDRESSEES. An addressee decides which net the thread is filed
 * on; a tag decides whose tablet goes off about it. A message to HQ tagged NOMAD
 * is filed on HQ and stays there - Nomad are woken up and allowed to answer into
 * it. See FUNC(srvTagged).
 *
 * Arguments:
 * 0: Template id <STRING>
 * 1: Payload <ARRAY> - [fieldKey, value] pairs
 * 2: Addressees <ARRAY> (optional, default [])
 * 3: Thread to reply in, "" to open a new one <STRING> (optional, default "")
 * 4: Message being replied to, "" for the thread root <STRING> (optional, default "")
 * 5: Audience tags <ARRAY> of <STRING> (optional, default [])
 * 6: Map pin, [x, y, z] for a thread that should mark the map, [] for none
 *    <ARRAY> (optional, default [])
 *
 * Return Value:
 * 0: Sent <BOOL>
 * 1: Why not, "" when sent <STRING>
 *
 * Example:
 * ["tic", [["Location.A", getPosATL player], ["Enemy.A", "Two technicals"]], ["B:HQ"], "", "", ["NOMAD"]] call jmfsb_messaging_fnc_submit
 *
 * Public: Yes
 */

params [
    ["_templateId", "", [""]],
    ["_payload", [], [[]]],
    ["_addressees", [], [[]]],
    ["_threadId", "", [""]],
    ["_parentId", "", [""]],
    ["_tags", [], [[]]],
    // THE PIN IS NOT A FIELD. A report anchors on a `grid` field named in the
    // template's `anchor`; a plain message has no fields, and FUNC(validate)
    // drops any payload key the template does not declare - so a pin sent as
    // one would be thrown away here. It travels beside the payload instead.
    ["_pin", [], [[]]]
];

if (isNull player) exitWith {[false, "no player"]};

// NOT SENT IS SAID AND LOGGED (user, 2026-11-02: "arty never replied"). A send
// refused here never reaches the server, so the server's RPT has nothing; the
// composer said why on its status line alone. Every refusal below is a
// NOT SENT popup upper right and one INFO line: the card and the reason.
private _fnc_notSent = {
    params ["_reason"];
    INFO_2("not sent '%1' - %2",_templateId,_reason);
    [NOT_SENT_TITLE, _reason, "high"] call FUNC(notify);
    [false, _reason]
};

if (!GVAR(enabled)) exitWith {["messaging is disabled"] call _fnc_notSent};

([_templateId, _payload] call FUNC(validate)) params ["_ok", "_why"];
if (!_ok) exitWith {[_why] call _fnc_notSent};

if (_addressees isEqualTo [] && _threadId == "") exitWith {["no addressee"] call _fnc_notSent};

// THE EW GATE. The spectrum gets an opinion about the data link: inside a
// jammer's core nothing leaves this set, and inside its falloff the send goes
// out late. One read, at the single door every sender walks through, so the
// TIC button, the ACE report and the composer cannot disagree about whether
// the net is up. RECEIVING IS NEVER GATED - the server still pushes, the same
// way a jammed radio still crackles; going quiet on receive would be
// indistinguishable from the engine being broken.
([] call FUNC(linkState)) params ["_link", "_factor"];
if (_link >= 2) exitWith {["link denied - your position is jammed"] call _fnc_notSent};

// The nonce is what makes a double-click harmless: the server keeps the ones it
// has seen and drops a repeat, so a laggy send button cannot file two CASEVACs.
private _nonce = format ["%1:%2:%3", getPlayerUID player, round diag_tickTime, floor random 1e6];

// Tidied here rather than on the server, so the tag a man sees on his own sent
// message is the tag everybody else's copy carries.
_tags = (_tags select {_x isEqualType ""}) apply {toUpper (trim _x)};
_tags = _tags select {_x isNotEqualTo ""};

if (count _pin < 2) then {_pin = []};

private _event = [player, _nonce, _templateId, _payload, _addressees, _threadId, _parentId, "", _tags, _pin];

if (_link isEqualTo 1) then {
    // DEGRADED TRANSMITS LATE, NOT NEVER. A message that silently vanishes is
    // indistinguishable from a bug; a message that arrives seconds late is
    // jamming a player can feel and move out of. The delay scales with the
    // field strength at the moment of the press, and the set says what it is
    // doing rather than looking slow.
    private _delay = 1 + ceil (_factor * 9);
    [{_this remoteExecCall [QFUNC(srvSubmit), SERVER_OWNER]}, _event, _delay] call CBA_fnc_waitAndExecute;
    [_templateId, format ["Link degraded - transmitting in %1 s.", _delay]] call FUNC(notify);
} else {
    // By remoteExecCall, so the server knows which machine sent it and files
    // it under that machine's player (review S7).
    _event remoteExecCall [QFUNC(srvSubmit), SERVER_OWNER];
};

// Where it went, for the RPT (2026-11-02): a card filed on a net rather than
// to an asset's box is answered by nobody, and this is the line that says so.
INFO_3("sent '%1' to %2 (thread '%3')",_templateId,_addressees,_threadId);

[true, ""]
