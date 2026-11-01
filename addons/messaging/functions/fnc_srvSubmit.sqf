#include "script_component.hpp"
/*
 * Author: JMSB
 * Accepts or refuses a submitted message. This is the only function that writes
 * a message into the store, so every rule about who may say what runs here or
 * in srvThreadFor, and nowhere else. The client validated first as a courtesy
 * to the player; this is the validation that decides.
 *
 * A client sends it by remoteExecCall to the server (FUNC(submit)). The unit
 * handed in must be the sending machine's own (review S7: a CBA event carries
 * no sender, so anyone could file as anyone), checked at the top before
 * anything else. The server's own calls - the counter-battery radar, the msg.*
 * test commands - pass as the server's.
 *
 * Arguments:
 * 0: Sending player <OBJECT>
 * 1: Draft nonce, one per press of send <STRING>
 * 2: Template id <STRING>
 * 3: Payload <ARRAY> - [fieldKey, value] pairs
 * 4: Addressees <ARRAY> - mailbox ids or bare names
 * 5: Thread to reply in, "" to open a new one <STRING>
 * 6: Message being replied to, "" for the thread root <STRING>
 * 7: File it under another call sign, "" to use the sender's <STRING>
 * 8: Audience tags <ARRAY> of <STRING>
 * 9: Map pin, [x, y, z] for a thread that should mark the map, [] for none <ARRAY>
 *
 * THE CALL SIGN OVERRIDE IS FOR TESTING ALONE, and it is here rather than in a
 * second write path because a test that files messages through code the live
 * system does not use proves nothing about the live system. A message filed
 * under another call sign is also NOT pre-read by the sender, so it arrives
 * unread with a notification - which is the half of the system a man testing on
 * his own can otherwise never see. See the msg.* admin commands. Only the
 * server and an admin by the server's records may use it (review S7); from
 * anyone else it is dropped and the message is filed under his own call sign.
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _nonce, "freetext", [["Text.A", "hello"]], ["B:HQ"], "", "", "", [], []] remoteExecCall ["jmfsb_messaging_fnc_srvSubmit", 2]
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_nonce", "", [""]],
    ["_templateId", "", [""]],
    ["_payload", [], [[]]],
    ["_addressees", [], [[]]],
    ["_threadId", "", [""]],
    ["_parentId", "", [""]],
    ["_asCallsign", "", [""]],
    ["_tags", [], [[]]],
    ["_pin", [], [[]]]
];

if (!isServer) exitWith {};
// WHO SENT IT, from the engine (review S7) - before anything else reads _unit.
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("srvSubmit: refused - machine %1 tried to file as %2",remoteExecutedOwner,_unit);
};
if (_asCallsign isNotEqualTo "" && {!([] call EFUNC(common,senderIsAdmin))}) then {
    WARNING_2("srvSubmit: call sign '%1' from machine %2 dropped - not an admin",_asCallsign,remoteExecutedOwner);
    _asCallsign = "";
};

// The client tidies these, but the client is not who decides. A tag that
// arrives as a number or an empty string would go on to be asked of every
// player on the server once per delivery.
_tags = (_tags select {_x isEqualType ""}) apply {toUpper (trim _x)};
_tags = _tags select {_x isNotEqualTo ""};
if (count _tags > TAG_MAX) then {_tags resize TAG_MAX};

if (!GVAR(enabled)) exitWith {};
if (!isPlayer _unit || {!alive _unit}) exitWith {};

// The nonce is what makes a double-click harmless: a repeat is dropped rather
// than filed as a second CASEVAC.
if (_nonce == "" || {_nonce in GVAR(nonces)}) exitWith {};
GVAR(nonces) set [_nonce, CBA_missionTime];

private _uid = getPlayerUID _unit;

private _fnc_refuse = {
    params ["_why"];
    [_templateId, _why] remoteExecCall [QFUNC(cltReject), _unit];
    INFO_3("refused '%1' from %2 - %3",_templateId,_uid,_why);
};

private _template = [_templateId] call FUNC(template);
if (_template isEqualTo createHashMap) exitWith {["no such template"] call _fnc_refuse};

([_templateId, _payload] call FUNC(validate)) params ["_ok", "_why"];
if (!_ok) exitWith {[_why] call _fnc_refuse};

([_unit, _template, _payload, _threadId, _pin] call FUNC(srvThreadFor)) params ["_thread", "_threadWhy", "_isRoot"];
if (_threadWhy != "") exitWith {[_threadWhy] call _fnc_refuse};

if (_isRoot && {_addressees isEqualTo []}) exitWith {
    GVAR(threads) deleteAt (_thread get "id");
    ["no addressee"] call _fnc_refuse
};

private _priority = _template get "priority";
private _transition = _template get "transitionsTo";
private _messageId = ["M"] call FUNC(srvNextId);

private _message = createHashMapFromArray [
    ["id", _messageId],
    // Ordering is the sequence a thread was written in, never the clock. Two
    // messages a frame apart have the same time and would sort at random.
    ["seq", count (_thread get "messages")],
    ["threadId", _thread get "id"],
    ["parentId", _parentId],
    ["fromUid", _uid],
    ["fromCallsign", [format ["%1 %2", groupId (group _unit), name _unit], _asCallsign] select (_asCallsign isNotEqualTo "")],
    // THE TAGS, STAMPED AT SEND TIME. Squad, job and urgency travel WITH the
    // message rather than being looked up when it is read: a man who was the
    // medic in ALPHA when he sent a CASEVAC is still that when it is read an
    // hour later, after he has been promoted and cross-posted. A tag worked out
    // at read time is a tag that lies about old traffic.
    //
    // Urgency is the template's own priority - see FUNC(registerTemplate) - so a
    // CASEVAC is FLASH because it is a CASEVAC, not because somebody ticked it.
    ["fromGroup", groupId (group _unit)],
    ["fromRole", [_unit] call FUNC(roleTag)],
    // WHO WAS CALLED OUT BY NAME. These travel with the message so the reader
    // can show them and so a client can tell it was one of the people meant -
    // see FUNC(cltReceive), which raises its own alert off exactly this.
    ["tags", _tags],
    ["templateId", _templateId],
    ["payload", _payload],
    ["sentTime", CBA_missionTime],
    ["gameTime", date],
    ["priority", _priority],
    ["transition", _transition],
    // A man has read what he just wrote. One filed under somebody else's call
    // sign he has not - so it arrives unread, with a notification, like traffic.
    ["readBy", [[_uid], []] select (_asCallsign isNotEqualTo "")]
];

GVAR(messages) set [_messageId, _message];
(_thread get "messages") pushBack _messageId;
_thread set ["lastActivity", CBA_missionTime];

// The thread carries every tag anybody has put on it, not just the root's. Tag
// a squad into a conversation halfway down and they stay in it - being called
// for once is not a thing that expires when the next message arrives.
private _threadTags = _thread getOrDefault ["tags", []];
{_threadTags pushBackUnique _x} forEach _tags;
_thread set ["tags", _threadTags];

if (_priority == "high") then {
    _thread set ["priority", "high"];
};

// A root template's transition is the thread's opening state and was applied
// when the thread was made; a reply's transition moves it.
if (!_isRoot && _transition != "") then {
    _thread set ["status", _transition];
    if (_transition in ["CLOSED", "ABORTED"]) then {
        _thread set ["closed", true];
    };
};

[_unit, _thread, _message, _addressees] call FUNC(srvDeliver);

if ((_template get "reportable") != "") then {
};

if ((_template get "broadcast") == "tic") then {
    [_unit, _thread, _payload] call FUNC(srvTic);
};
